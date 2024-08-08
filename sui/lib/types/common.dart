

import 'package:sui/serialization/base64_buffer.dart';

/// Base64 string representing the object digest
typedef TransactionDigest = String;
typedef SuiAddress = String;

class Shared {
  int initialSharedVersion;

  Shared(this.initialSharedVersion);

  factory Shared.fromJson(dynamic data) {
    return Shared(data['initial_shared_version']);
  }
}

class ObjectOwner {
  SuiAddress? addressOwner;
  SuiAddress? objectOwner;
  Shared? shared;
  bool? immutable;

  ObjectOwner(this.addressOwner, this.objectOwner, this.shared, this.immutable);

  factory ObjectOwner.fromJson(dynamic data) {
    if (data is String && data == 'Immutable') {
      return ObjectOwner(null, null, null, true);
    }
    
    return ObjectOwner(
      data['AddressOwner'],
      data['ObjectOwner'],
      data['shared'] != null ? Shared.fromJson(data['shared']) : null,
      null
    );
  }
}

// source of truth is
// https://github.com/MystenLabs/sui/blob/acb2b97ae21f47600e05b0d28127d88d0725561d/crates/sui-types/src/base_types.rs#L171
const TX_DIGEST_LENGTH = 32;

// taken from https://rgxdb.com/r/1NUN74O6
final VALID_BASE64_REGEX = RegExp(r'^(?:[a-zA-Z0-9+/]{4})*(?:|(?:[a-zA-Z0-9+/]{3}=)|(?:[a-zA-Z0-9+/]{2}==)|(?:[a-zA-Z0-9+/]{1}===))$');
  

bool isValidTransactionDigest(
  String value
) {
  return
    Base64DataBuffer.fromBase64String(value).getLength() == TX_DIGEST_LENGTH &&
    VALID_BASE64_REGEX.hasMatch(value);
}

// TODO - can we automatically sync this with rust length definition?
// Source of truth is
// https://github.com/MystenLabs/sui/blob/acb2b97ae21f47600e05b0d28127d88d0725561d/crates/sui-types/src/base_types.rs#L67
// which uses the Move account address length
// https://github.com/move-language/move/blob/67ec40dc50c66c34fd73512fcc412f3b68d67235/language/move-core/types/src/account_address.rs#L23 .

const SUI_ADDRESS_LENGTH = 32;

bool isValidSuiAddress(String value) {
  return isHex(value) && getHexByteLength(value) == SUI_ADDRESS_LENGTH;
}

bool isValidSuiObjectId(String value) {
  return isValidSuiAddress(value);
}

/// Perform the following operations:
/// 1. Make the address lower case
/// 2. Prepend `0x` if the string does not start with `0x`.
/// 3. Add more zeros if the length of the address(excluding `0x`) is less than `SUI_ADDRESS_LENGTH`
///
/// WARNING: if the address value itself starts with `0x`, e.g., `0x0x`, the default behavior
/// is to treat the first `0x` not as part of the address. The default behavior can be overridden by
/// setting `forceAdd0x` to true
String normalizeSuiAddress(
  String value,
  [bool forceAdd0x = false]
) {
  String address = value.toLowerCase();
  if (!forceAdd0x && address.startsWith('0x')) {
    address = address.substring(2);
  }
  return "0x${address.padLeft(SUI_ADDRESS_LENGTH * 2, '0')}";
}

String normalizeSuiObjectId(
  String value,
  [bool forceAdd0x = false]
) {
  return normalizeSuiAddress(value, forceAdd0x);
}

bool isHex(String value) {
  return RegExp(r'^(0x|0X)?[a-fA-F0-9]+$').hasMatch(value) && value.length % 2 == 0;
}

int getHexByteLength(String value) {
  return RegExp(r'^(0x|0X)').hasMatch(value) ? (value.length - 2) ~/ 2 : value.length ~/ 2;
}
