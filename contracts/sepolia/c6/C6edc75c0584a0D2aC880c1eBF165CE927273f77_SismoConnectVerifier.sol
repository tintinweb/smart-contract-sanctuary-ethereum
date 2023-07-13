// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./interfaces/ISismoConnectVerifier.sol";
import {AuthMatchingLib} from "./libs/utils/AuthMatchingLib.sol";
import {ClaimMatchingLib} from "./libs/utils/ClaimMatchingLib.sol";
import {IBaseVerifier} from "./interfaces/IBaseVerifier.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SismoConnectVerifier is ISismoConnectVerifier, Initializable, Ownable {
  using AuthMatchingLib for Auth;
  using ClaimMatchingLib for Claim;

  uint8 public constant IMPLEMENTATION_VERSION = 1;
  bytes32 public immutable SISMO_CONNECT_VERSION = "sismo-connect-v1.1";

  mapping(bytes32 => IBaseVerifier) public _verifiers;

  // struct to store informations about the number of verified auths and claims returned
  // indexes of the first available slot in the arrays of auths and claims are also stored
  // this struct is used to avoid stack to deep errors without using via_ir in foundry
  struct VerifiedArraysInfos {
    uint256 nbOfAuths; // number of verified auths
    uint256 nbOfClaims; // number of verified claims
    uint256 authsIndex; // index of the first available slot in the array of verified auths
    uint256 claimsIndex; // index of the first available slot in the array of verified claims
  }

  // Struct holding the verified Auths and Claims from the snark proofs
  // This struct is used to avoid stack too deep error
  struct VerifiedProofs {
    VerifiedAuth[] auths;
    VerifiedClaim[] claims;
  }

  constructor(address owner) {
    initialize(owner);
  }

  function initialize(address ownerAddress) public reinitializer(IMPLEMENTATION_VERSION) {
    // if proxy did not setup owner yet or if called by constructor (for implem setup)
    if (owner() == address(0) || address(this).code.length == 0) {
      _transferOwnership(ownerAddress);
    }
  }

  function verify(
    SismoConnectResponse memory response,
    SismoConnectRequest memory request,
    SismoConnectConfig memory config
  ) external override returns (SismoConnectVerifiedResult memory) {
    if (response.appId != config.appId) {
      revert AppIdMismatch(response.appId, config.appId);
    }

    _checkResponseMatchesWithRequest(response, request);

    uint256 responseProofsArrayLength = response.proofs.length;
    VerifiedArraysInfos memory infos = VerifiedArraysInfos({
      nbOfAuths: 0,
      nbOfClaims: 0,
      authsIndex: 0,
      claimsIndex: 0
    });

    // Count the number of auths and claims in the response
    for (uint256 i = 0; i < responseProofsArrayLength; i++) {
      infos.nbOfAuths += response.proofs[i].auths.length;
      infos.nbOfClaims += response.proofs[i].claims.length;
    }

    VerifiedProofs memory verifiedProofs = VerifiedProofs({
      auths: new VerifiedAuth[](infos.nbOfAuths),
      claims: new VerifiedClaim[](infos.nbOfClaims)
    });

    for (uint256 i = 0; i < responseProofsArrayLength; i++) {
      (VerifiedAuth memory verifiedAuth, VerifiedClaim memory verifiedClaim) = _verifiers[
        response.proofs[i].provingScheme
      ].verify({
          appId: response.appId,
          namespace: response.namespace,
          isImpersonationMode: config.vault.isImpersonationMode,
          signedMessage: response.signedMessage,
          sismoConnectProof: response.proofs[i]
        });

      // we only want to add the verified auths and claims to the result
      // if they are not empty, for that we check the length of the proofData that should always be different from 0
      if (verifiedAuth.proofData.length != 0) {
        verifiedProofs.auths[infos.authsIndex] = verifiedAuth;
        infos.authsIndex++;
      }
      if (verifiedClaim.proofData.length != 0) {
        verifiedProofs.claims[infos.claimsIndex] = verifiedClaim;
        infos.claimsIndex++;
      }
    }

    return
      SismoConnectVerifiedResult({
        appId: response.appId,
        namespace: response.namespace,
        version: response.version,
        auths: verifiedProofs.auths,
        claims: verifiedProofs.claims,
        signedMessage: response.signedMessage
      });
  }

  function _checkResponseMatchesWithRequest(
    SismoConnectResponse memory response,
    SismoConnectRequest memory request
  ) internal view {
    if (response.version != SISMO_CONNECT_VERSION) {
      revert VersionMismatch(response.version, SISMO_CONNECT_VERSION);
    }

    if (response.namespace != request.namespace) {
      revert NamespaceMismatch(response.namespace, request.namespace);
    }

    // Check if the message of the signature matches between the request and the response
    // if the signature request is NOT selectable by the user
    if (request.signature.isSelectableByUser == false) {
      // Check if the message signature matches between the request and the response
      // only if the content of the signature is different from the hash of "MESSAGE_SELECTED_BY_USER"
      if (
        keccak256(request.signature.message) != keccak256("MESSAGE_SELECTED_BY_USER") &&
        // we hash the messages to be able to compare them (as they are of type bytes)
        keccak256(request.signature.message) != keccak256(response.signedMessage)
      ) {
        revert SignatureMessageMismatch(request.signature.message, response.signedMessage);
      }
    }

    // we store the auths and claims in the response
    uint256 nbOfAuths = 0;
    uint256 nbOfClaims = 0;
    for (uint256 i = 0; i < response.proofs.length; i++) {
      nbOfAuths += response.proofs[i].auths.length;
      nbOfClaims += response.proofs[i].claims.length;
    }

    Auth[] memory authsInResponse = new Auth[](nbOfAuths);
    uint256 authsIndex = 0;
    Claim[] memory claimsInResponse = new Claim[](nbOfClaims);
    uint256 claimsIndex = 0;
    // we store the auths and claims in the response in a single respective array
    for (uint256 i = 0; i < response.proofs.length; i++) {
      // we do a loop on the proofs array and on the auths array of each proof
      for (uint256 j = 0; j < response.proofs[i].auths.length; j++) {
        authsInResponse[authsIndex] = response.proofs[i].auths[j];
        authsIndex++;
      }
      // we do a loop on the proofs array and on the claims array of each proof
      for (uint256 j = 0; j < response.proofs[i].claims.length; j++) {
        claimsInResponse[claimsIndex] = response.proofs[i].claims[j];
        claimsIndex++;
      }
    }

    // Check if the auths and claims in the request match the auths and claims int the response
    _checkAuthsInRequestMatchWithAuthsInResponse({
      authsInRequest: request.auths,
      authsInResponse: authsInResponse
    });
    _checkClaimsInRequestMatchWithClaimsInResponse({
      claimsInRequest: request.claims,
      claimsInResponse: claimsInResponse
    });
  }

  function _checkAuthsInRequestMatchWithAuthsInResponse(
    AuthRequest[] memory authsInRequest,
    Auth[] memory authsInResponse
  ) internal pure {
    // for each auth in the request, we check if it matches with one of the auths in the response
    for (uint256 i = 0; i < authsInRequest.length; i++) {
      AuthRequest memory authRequest = authsInRequest[i];
      if (authRequest.isOptional) {
        // if the auth in the request is optional, we consider that its properties are all matching
        // and we don't need to check for errors
        continue;
      }
      // we store the information about the maximum matching properties in a uint8
      // if the auth in the request matches with an auth in the response, the matchingProperties will be equal to 7 (111)
      // otherwise, we can look at the binary representation of the matchingProperties to know which properties are not matching and throw an error
      uint8 maxMatchingPropertiesLevel = 0;

      for (uint256 j = 0; j < authsInResponse.length; j++) {
        // we store the matching properties for the current auth in the response in a uint8
        // we will store it in the maxMatchingPropertiesLevel variable if it is greater than the current value of maxMatchingPropertiesLevel
        Auth memory auth = authsInResponse[j];
        uint8 matchingPropertiesLevel = auth._matchLevel(authRequest);

        // if the matchingPropertiesLevel are greater than the current value of maxMatchingPropertiesLevel, we update the value of maxMatchingPropertiesLevel
        // by doing so we will be able to know how close the auth in the request is to the auth in the response
        if (matchingPropertiesLevel > maxMatchingPropertiesLevel) {
          maxMatchingPropertiesLevel = matchingPropertiesLevel;
        }
      }
      AuthMatchingLib.handleAuthErrors(maxMatchingPropertiesLevel, authRequest);
    }
  }

  function _checkClaimsInRequestMatchWithClaimsInResponse(
    ClaimRequest[] memory claimsInRequest,
    Claim[] memory claimsInResponse
  ) internal pure {
    // for each claim in the request, we check if it matches with one of the claims in the response
    for (uint256 i = 0; i < claimsInRequest.length; i++) {
      ClaimRequest memory claimRequest = claimsInRequest[i];
      if (claimRequest.isOptional) {
        // if the claim in the request is optional, we consider that its properties are all matching
        continue;
      }
      // we store the information about the maximum matching properties in a uint8
      // if the claim in the request matches with a claim in the response, the matchingProperties will be equal to 7 (111)
      // otherwise, we can look at the binary representation of the matchingProperties to know which properties are not matching and throw an error
      uint8 maxMatchingProperties = 0;

      for (uint256 j = 0; j < claimsInResponse.length; j++) {
        Claim memory claim = claimsInResponse[j];
        uint8 matchingProperties = claim._matchLevel(claimRequest);

        // if the matchingProperties are greater than the current value of maxMatchingProperties, we update the value of maxMatchingProperties
        // by doing so we will be able to know how close the claim in the request is to the claim in the response
        if (matchingProperties > maxMatchingProperties) {
          maxMatchingProperties = matchingProperties;
        }
      }
      ClaimMatchingLib.handleClaimErrors(maxMatchingProperties, claimRequest);
    }
  }

  function registerVerifier(bytes32 provingScheme, address verifierAddress) public onlyOwner {
    _setVerifier(provingScheme, verifierAddress);
  }

  function getVerifier(bytes32 provingScheme) public view returns (address) {
    return address(_verifiers[provingScheme]);
  }

  function _setVerifier(bytes32 provingScheme, address verifierAddress) internal {
    _verifiers[provingScheme] = IBaseVerifier(verifierAddress);
    emit VerifierSet(provingScheme, verifierAddress);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libs/utils/Structs.sol";

interface ISismoConnectVerifier {
  event VerifierSet(bytes32, address);

  error AppIdMismatch(bytes16 receivedAppId, bytes16 expectedAppId);
  error NamespaceMismatch(bytes16 receivedNamespace, bytes16 expectedNamespace);
  error VersionMismatch(bytes32 requestVersion, bytes32 responseVersion);
  error SignatureMessageMismatch(bytes requestMessageSignature, bytes responseMessageSignature);

  function verify(
    SismoConnectResponse memory response,
    SismoConnectRequest memory request,
    SismoConnectConfig memory config
  ) external returns (SismoConnectVerifiedResult memory);

  function SISMO_CONNECT_VERSION() external view returns (bytes32);
}

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

import "./Structs.sol";

library ClaimMatchingLib {
  error ClaimInRequestNotFoundInResponse(
    uint8 responseClaimType,
    bytes16 responseClaimGroupId,
    bytes16 responseClaimGroupTimestamp,
    uint256 responseClaimValue,
    bytes responseExtraData
  );
  error ClaimGroupIdAndGroupTimestampNotFound(
    bytes16 requestClaimGroupId,
    bytes16 requestClaimGroupTimestamp
  );
  error ClaimTypeAndGroupTimestampNotFound(
    uint8 requestClaimType,
    bytes16 requestClaimGroupTimestamp
  );
  error ClaimGroupTimestampNotFound(bytes16 requestClaimGroupTimestamp);
  error ClaimTypeAndGroupIdNotFound(uint8 requestClaimType, bytes16 requestClaimGroupId);
  error ClaimGroupIdNotFound(bytes16 requestClaimGroupId);
  error ClaimTypeNotFound(uint8 requestClaimType);

  // Check if the AuthRequest is fulfilled by the Auth in the response
  // and return the level of matching between the AuthRequest and the Auth in the response
  function _matchLevel(
    Claim memory claim,
    ClaimRequest memory claimRequest
  ) internal pure returns (uint8) {
    uint8 matchingPropertiesLevel = 0;

    if (claim.claimType == claimRequest.claimType) {
      matchingPropertiesLevel += 1; // 001
    }
    if (claim.groupId == claimRequest.groupId) {
      matchingPropertiesLevel += 2; // 010
    }
    if (claim.groupTimestamp == claimRequest.groupTimestamp) {
      matchingPropertiesLevel += 4; // 100
    }

    return matchingPropertiesLevel;
  }

  function handleClaimErrors(uint8 maxMatchingProperties, ClaimRequest memory claim) public pure {
    // if the maxMatchingProperties is equal to 7 (111 in bits), it means that the claim in the request matches with one of the claims in the response
    // otherwise, we can look at the binary representation of the maxMatchingProperties to know which properties are not matching and throw an error (the 0 bits represent the properties that are not matching)
    if (maxMatchingProperties == 0) {
      // 000
      // no property of the claim in the request matches with any property of the claims in the response
      revert ClaimInRequestNotFoundInResponse(
        uint8(claim.claimType),
        claim.groupId,
        claim.groupTimestamp,
        claim.value,
        claim.extraData
      );
    } else if (maxMatchingProperties == 1) {
      // 001
      // only the claimType property of the claim in the request matches with one of the claims in the response
      revert ClaimGroupIdAndGroupTimestampNotFound(claim.groupId, claim.groupTimestamp);
    } else if (maxMatchingProperties == 2) {
      // 010
      // only the groupId property of the claim in the request matches with one of the claims in the response
      revert ClaimTypeAndGroupTimestampNotFound(uint8(claim.claimType), claim.groupTimestamp);
    } else if (maxMatchingProperties == 3) {
      // 011
      // only the claimType and groupId properties of the claim in the request match with one of the claims in the response
      revert ClaimGroupTimestampNotFound(claim.groupTimestamp);
    } else if (maxMatchingProperties == 4) {
      // 100
      // only the groupTimestamp property of the claim in the request matches with one of the claims in the response
      revert ClaimTypeAndGroupIdNotFound(uint8(claim.claimType), claim.groupId);
    } else if (maxMatchingProperties == 5) {
      // 101
      // only the claimType and groupTimestamp properties of the claim in the request matches with one of the claims in the response
      revert ClaimGroupIdNotFound(claim.groupId);
    } else if (maxMatchingProperties == 6) {
      // 110
      // only the groupId and groupTimestamp properties of the claim in the request matches with one of the claims in the response
      revert ClaimTypeNotFound(uint8(claim.claimType));
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {SismoConnectProof, VerifiedAuth, VerifiedClaim} from "src/libs/utils/Structs.sol";

interface IBaseVerifier {
  function verify(
    bytes16 appId,
    bytes16 namespace,
    bool isImpersonationMode,
    bytes memory signedMessage,
    SismoConnectProof memory sismoConnectProof
  ) external returns (VerifiedAuth memory, VerifiedClaim memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}