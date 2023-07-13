// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

// The role of this library is to check for a given AuthRequest if there is a matching Auth in the response
// It returns a level of matching between the AuthRequest and the Auth in the response
// The level of matching is a number between 0 and 7 (000 to 111 in binary)
// The level of matching is calculated by adding the following values:
// 1 if the authType in the AuthRequest is the same as the authType in the Auth
// 2 if the isAnon in the AuthRequest is the same as the isAnon in the Auth
// 4 if the userId in the AuthRequest is the same as the userId in the Auth
// The level of matching is then used to determine if the AuthRequest is fulfilled or not
library AuthMatchingLib {
  error AuthInRequestNotFoundInResponse(
    uint8 requestAuthType,
    bool requestIsAnon,
    uint256 requestUserId,
    bytes requestExtraData
  );
  error AuthIsAnonAndUserIdNotFound(bool requestIsAnon, uint256 requestUserId);
  error AuthTypeAndUserIdNotFound(uint8 requestAuthType, uint256 requestUserId);
  error AuthUserIdNotFound(uint256 requestUserId);
  error AuthTypeAndIsAnonNotFound(uint8 requestAuthType, bool requestIsAnon);
  error AuthIsAnonNotFound(bool requestIsAnon);
  error AuthTypeNotFound(uint8 requestAuthType);

  // Check if the AuthRequest is fulfilled by the Auth in the response
  // and return the level of matching between the AuthRequest and the Auth in the response
  function _matchLevel(
    Auth memory auth,
    AuthRequest memory authRequest
  ) internal pure returns (uint8) {
    uint8 matchingPropertiesLevel = 0;

    if (auth.authType == authRequest.authType) {
      matchingPropertiesLevel += 1; // 001
    }
    if (auth.isAnon == authRequest.isAnon) {
      matchingPropertiesLevel += 2; // 010
    }

    if (authRequest.authType == AuthType.VAULT) {
      // If authType is Vault the user can't choose a particular userId
      // It will be always defined as userId = Hash(VaultSecret, AppId)
      // There is then no specific constraint on the isSelectableByUser and userId properties)
      matchingPropertiesLevel += 4; // 100
    } else if ((authRequest.isSelectableByUser == false) && (auth.userId == authRequest.userId)) {
      // if the userId in the auth request can NOT be chosen by the user when generating the proof (isSelectableByUser == true)
      // we check if the userId of the auth in the request matches the userId of the auth in the response
      matchingPropertiesLevel += 4; // 100
    } else if (authRequest.isSelectableByUser == true) {
      // if the userId in the auth request can be chosen by the user when generating the proof (isSelectableByUser == true)
      // we dont check if the userId of the auth in the request matches the userId of the auth in the response
      // the property is considered as matching
      matchingPropertiesLevel += 4; // 100
    }

    return matchingPropertiesLevel;
  }

  function handleAuthErrors(uint8 maxMatchingProperties, AuthRequest memory auth) public pure {
    // if the maxMatchingProperties is equal to 7 (111 in bits), it means that the auth in the request matches with one of the auths in the response
    // otherwise, we can look at the binary representation of the maxMatchingProperties to know which properties are not matching and throw an error (the 0 bits represent the properties that are not matching)
    if (maxMatchingProperties == 0) {
      // 000
      // no property of the auth in the request matches with any property of the auths in the response
      revert AuthInRequestNotFoundInResponse(
        uint8(auth.authType),
        auth.isAnon,
        auth.userId,
        auth.extraData
      );
    } else if (maxMatchingProperties == 1) {
      // 001
      // only the authType property of the auth in the request matches with one of the auths in the response
      revert AuthIsAnonAndUserIdNotFound(auth.isAnon, auth.userId);
    } else if (maxMatchingProperties == 2) {
      // 010
      // only the isAnon property of the auth in the request matches with one of the auths in the response
      revert AuthTypeAndUserIdNotFound(uint8(auth.authType), auth.userId);
    } else if (maxMatchingProperties == 3) {
      // 011
      // only the authType and isAnon properties of the auth in the request match with one of the auths in the response
      revert AuthUserIdNotFound(auth.userId);
    } else if (maxMatchingProperties == 4) {
      // 100
      // only the userId property of the auth in the request matches with one of the auths in the response
      revert AuthTypeAndIsAnonNotFound(uint8(auth.authType), auth.isAnon);
    } else if (maxMatchingProperties == 5) {
      // 101
      // only the authType and userId properties of the auth in the request matches with one of the auths in the response
      revert AuthIsAnonNotFound(auth.isAnon);
    } else if (maxMatchingProperties == 6) {
      // 110
      // only the isAnon and userId properties of the auth in the request matches with one of the auths in the response
      revert AuthTypeNotFound(uint8(auth.authType));
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct SismoConnectRequest {
  bytes16 namespace;
  AuthRequest[] auths;
  ClaimRequest[] claims;
  SignatureRequest signature;
}

struct SismoConnectConfig {
  bytes16 appId;
  VaultConfig vault;
}

struct VaultConfig {
  bool isImpersonationMode;
}

struct AuthRequest {
  AuthType authType;
  uint256 userId; // default: 0
  // flags
  bool isAnon; // default: false -> true not supported yet, need to throw if true
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct ClaimRequest {
  ClaimType claimType; // default: GTE
  bytes16 groupId;
  bytes16 groupTimestamp; // default: bytes16("latest")
  uint256 value; // default: 1
  // flags
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct SignatureRequest {
  bytes message; // default: "MESSAGE_SELECTED_BY_USER"
  bool isSelectableByUser; // default: false
  bytes extraData; // default: ""
}

enum AuthType {
  VAULT,
  GITHUB,
  TWITTER,
  EVM_ACCOUNT,
  TELEGRAM,
  DISCORD
}

enum ClaimType {
  GTE,
  GT,
  EQ,
  LT,
  LTE
}

struct Auth {
  AuthType authType;
  bool isAnon;
  bool isSelectableByUser;
  uint256 userId;
  bytes extraData;
}

struct Claim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  bool isSelectableByUser;
  uint256 value;
  bytes extraData;
}

struct Signature {
  bytes message;
  bytes extraData;
}

struct SismoConnectResponse {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  bytes signedMessage;
  SismoConnectProof[] proofs;
}

struct SismoConnectProof {
  Auth[] auths;
  Claim[] claims;
  bytes32 provingScheme;
  bytes proofData;
  bytes extraData;
}

struct SismoConnectVerifiedResult {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  VerifiedAuth[] auths;
  VerifiedClaim[] claims;
  bytes signedMessage;
}

struct VerifiedAuth {
  AuthType authType;
  bool isAnon;
  uint256 userId;
  bytes extraData;
  bytes proofData;
}

struct VerifiedClaim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  uint256 value;
  bytes extraData;
  uint256 proofId;
  bytes proofData;
}