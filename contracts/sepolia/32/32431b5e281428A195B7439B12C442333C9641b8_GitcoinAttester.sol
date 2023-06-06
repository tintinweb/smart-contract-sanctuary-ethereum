// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import { AttestationRequest, AttestationRequestData, IEAS, Attestation, MultiAttestationRequest } from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";

/**
 * @title GitcoinAttester
 * @dev A contract that allows a Verifier contract to add passport information for users using Ethereum Attestation Service.
 */
contract GitcoinAttester is Ownable {
  // An allow-list of Verifiers that are authorized and trusted to call the addPassport function.
  mapping(address => bool) public verifiers;

  // The instance of the EAS contract.
  IEAS eas;

  // Emitted when a verifier is added to the allow-list.
  event VerifierAdded(address verifier);

  // Emitted when a verifier is removed from the allow-list.
  event VerifierRemoved(address verifier);

  /**
   * @dev Adds a verifier to the allow-list.
   * @param _verifier The address of the verifier to add. It must be a Gnosis Safe contract.
   */
  function addVerifier(address _verifier) public onlyOwner {
    require(!verifiers[_verifier], "Verifier already added");
    verifiers[_verifier] = true;
    emit VerifierAdded(_verifier);
  }

  /**
   * @dev Removes a verifier from the allow-list.
   * @param _verifier The address of the verifier to remove.
   */
  function removeVerifier(address _verifier) public onlyOwner {
    require(verifiers[_verifier], "Verifier does not exist");
    verifiers[_verifier] = false;
    emit VerifierRemoved(_verifier);
  }

  /**
   * @dev Sets the address of the EAS contract.
   * @param _easContractAddress The address of the EAS contract.
   */
  function setEASAddress(address _easContractAddress) public onlyOwner {
    eas = IEAS(_easContractAddress);
  }

  /**
   * @dev Adds passport information for a user using EAS
   * @param multiAttestationRequest An array of `MultiAttestationRequest` structures containing the user's passport information.
   */
  function addPassport(
    MultiAttestationRequest[] calldata multiAttestationRequest
  ) public payable virtual returns (bytes32[] memory) {
    require(
      verifiers[msg.sender],
      "Only authorized verifiers can call this function"
    );

    return eas.multiAttest(multiAttestationRequest);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISchemaRegistry } from "./ISchemaRegistry.sol";
import { Attestation, EIP712Signature } from "./Types.sol";

/**
 * @dev A struct representing the arguments of the attestation request.
 */
struct AttestationRequestData {
    address recipient; // The recipient of the attestation.
    uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
    bool revocable; // Whether the attestation is revocable.
    bytes32 refUID; // The UID of the related attestation.
    bytes data; // Custom attestation data.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/**
 * @dev A struct representing the full arguments of the attestation request.
 */
struct AttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the full delegated attestation request.
 */
struct DelegatedAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
    EIP712Signature signature; // The EIP712 signature data.
    address attester; // The attesting account.
}

/**
 * @dev A struct representing the full arguments of the multi attestation request.
 */
struct MultiAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi attestation request.
 */
struct MultiDelegatedAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation requests.
    EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address attester; // The attesting account.
}

/**
 * @dev A struct representing the arguments of the revocation request.
 */
struct RevocationRequestData {
    bytes32 uid; // The UID of the attestation to revoke.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/**
 * @dev A struct representing the full arguments of the revocation request.
 */
struct RevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the arguments of the full delegated revocation request.
 */
struct DelegatedRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
    EIP712Signature signature; // The EIP712 signature data.
    address revoker; // The revoking account.
}

/**
 * @dev A struct representing the full arguments of the multi revocation request.
 */
struct MultiRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi revocation request.
 */
struct MultiDelegatedRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation requests.
    EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address revoker; // The revoking account.
}

/**
 * @title EAS - Ethereum Attestation Service interface.
 */
interface IEAS {
    /**
     * @dev Emitted when an attestation has been made.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param uid The UID the revoked attestation.
     * @param schema The UID of the schema.
     */
    event Attested(address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schema);

    /**
     * @dev Emitted when an attestation has been revoked.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param schema The UID of the schema.
     * @param uid The UID the revoked attestation.
     */
    event Revoked(address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schema);

    /**
     * @dev Emitted when a data has been timestamped.
     *
     * @param data The data.
     * @param timestamp The timestamp.
     */
    event Timestamped(bytes32 indexed data, uint64 indexed timestamp);

    /**
     * @dev Emitted when a data has been revoked.
     *
     * @param revoker The address of the revoker.
     * @param data The data.
     * @param timestamp The timestamp.
     */
    event RevokedOffchain(address indexed revoker, bytes32 indexed data, uint64 indexed timestamp);

    /**
     * @dev Returns the address of the global schema registry.
     *
     * @return The address of the global schema registry.
     */
    function getSchemaRegistry() external view returns (ISchemaRegistry);

    /**
     * @dev Attests to a specific schema.
     *
     * @param request The arguments of the attestation request.
     *
     * Example:
     *
     * attest({
     *     schema: "0facc36681cbe2456019c1b0d1e7bedd6d1d40f6f324bf3dd3a4cef2999200a0",
     *     data: {
     *         recipient: "0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf",
     *         expirationTime: 0,
     *         revocable: true,
     *         refUID: "0x0000000000000000000000000000000000000000000000000000000000000000",
     *         data: "0xF00D",
     *         value: 0
     *     }
     * })
     *
     * @return The UID of the new attestation.
     */
    function attest(AttestationRequest calldata request) external payable returns (bytes32);

    /**
     * @dev Attests to a specific schema via the provided EIP712 signature.
     *
     * @param delegatedRequest The arguments of the delegated attestation request.
     *
     * Example:
     *
     * attestByDelegation({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
     *         expirationTime: 1673891048,
     *         revocable: true,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x1234',
     *         value: 0
     *     },
     *     signature: {
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     attester: '0xc5E8740aD971409492b1A63Db8d83025e0Fc427e'
     * })
     *
     * @return The UID of the new attestation.
     */
    function attestByDelegation(
        DelegatedAttestationRequest calldata delegatedRequest
    ) external payable returns (bytes32);

    /**
     * @dev Attests to multiple schemas.
     *
     * @param multiRequests The arguments of the multi attestation requests. The requests should be grouped by distinct
     * schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiAttest([{
     *     schema: '0x33e9094830a5cba5554d1954310e4fbed2ef5f859ec1404619adea4207f391fd',
     *     data: [{
     *         recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
     *         expirationTime: 1673891048,
     *         revocable: true,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x1234',
     *         value: 1000
     *     },
     *     {
     *         recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
     *         expirationTime: 0,
     *         revocable: false,
     *         refUID: '0x480df4a039efc31b11bfdf491b383ca138b6bde160988222a2a3509c02cee174',
     *         data: '0x00',
     *         value: 0
     *     }],
     * },
     * {
     *     schema: '0x5ac273ce41e3c8bfa383efe7c03e54c5f0bff29c9f11ef6ffa930fc84ca32425',
     *     data: [{
     *         recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
     *         expirationTime: 0,
     *         revocable: true,
     *         refUID: '0x75bf2ed8dca25a8190c50c52db136664de25b2449535839008ccfdab469b214f',
     *         data: '0x12345678',
     *         value: 0
     *     },
     * }])
     *
     * @return The UIDs of the new attestations.
     */
    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external payable returns (bytes32[] memory);

    /**
     * @dev Attests to multiple schemas using via provided EIP712 signatures.
     *
     * @param multiDelegatedRequests The arguments of the delegated multi attestation requests. The requests should be
     * grouped by distinct schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiAttestByDelegation([{
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: [{
     *         recipient: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
     *         expirationTime: 1673891048,
     *         revocable: true,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x1234',
     *         value: 0
     *     },
     *     {
     *         recipient: '0xdEADBeAFdeAdbEafdeadbeafDeAdbEAFdeadbeaf',
     *         expirationTime: 0,
     *         revocable: false,
     *         refUID: '0x0000000000000000000000000000000000000000000000000000000000000000',
     *         data: '0x00',
     *         value: 0
     *     }],
     *     signatures: [{
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     {
     *         v: 28,
     *         r: '0x487s...67bb',
     *         s: '0x12ad...2366'
     *     }],
     *     attester: '0x1D86495b2A7B524D747d2839b3C645Bed32e8CF4'
     * }])
     *
     * @return The UIDs of the new attestations.
     */
    function multiAttestByDelegation(
        MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests
    ) external payable returns (bytes32[] memory);

    /**
     * @dev Revokes an existing attestation to a specific schema.
     *
     * Example:
     *
     * revoke({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         uid: '0x101032e487642ee04ee17049f99a70590c735b8614079fc9275f9dd57c00966d',
     *         value: 0
     *     }
     * })
     *
     * @param request The arguments of the revocation request.
     */
    function revoke(RevocationRequest calldata request) external payable;

    /**
     * @dev Revokes an existing attestation to a specific schema via the provided EIP712 signature.
     *
     * Example:
     *
     * revokeByDelegation({
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: {
     *         uid: '0xcbbc12102578c642a0f7b34fe7111e41afa25683b6cd7b5a14caf90fa14d24ba',
     *         value: 0
     *     },
     *     signature: {
     *         v: 27,
     *         r: '0xb593...7142',
     *         s: '0x0f5b...2cce'
     *     },
     *     revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992'
     * })
     *
     * @param delegatedRequest The arguments of the delegated revocation request.
     */
    function revokeByDelegation(DelegatedRevocationRequest calldata delegatedRequest) external payable;

    /**
     * @dev Revokes existing attestations to multiple schemas.
     *
     * @param multiRequests The arguments of the multi revocation requests. The requests should be grouped by distinct
     * schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiRevoke([{
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: [{
     *         uid: '0x211296a1ca0d7f9f2cfebf0daaa575bea9b20e968d81aef4e743d699c6ac4b25',
     *         value: 1000
     *     },
     *     {
     *         uid: '0xe160ac1bd3606a287b4d53d5d1d6da5895f65b4b4bab6d93aaf5046e48167ade',
     *         value: 0
     *     }],
     * },
     * {
     *     schema: '0x5ac273ce41e3c8bfa383efe7c03e54c5f0bff29c9f11ef6ffa930fc84ca32425',
     *     data: [{
     *         uid: '0x053d42abce1fd7c8fcddfae21845ad34dae287b2c326220b03ba241bc5a8f019',
     *         value: 0
     *     },
     * }])
     */
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable;

    /**
     * @dev Revokes existing attestations to multiple schemas via provided EIP712 signatures.
     *
     * @param multiDelegatedRequests The arguments of the delegated multi revocation attestation requests. The requests should be
     * grouped by distinct schema ids to benefit from the best batching optimization.
     *
     * Example:
     *
     * multiRevokeByDelegation([{
     *     schema: '0x8e72f5bc0a8d4be6aa98360baa889040c50a0e51f32dbf0baa5199bd93472ebc',
     *     data: [{
     *         uid: '0x211296a1ca0d7f9f2cfebf0daaa575bea9b20e968d81aef4e743d699c6ac4b25',
     *         value: 1000
     *     },
     *     {
     *         uid: '0xe160ac1bd3606a287b4d53d5d1d6da5895f65b4b4bab6d93aaf5046e48167ade',
     *         value: 0
     *     }],
     *     signatures: [{
     *         v: 28,
     *         r: '0x148c...b25b',
     *         s: '0x5a72...be22'
     *     },
     *     {
     *         v: 28,
     *         r: '0x487s...67bb',
     *         s: '0x12ad...2366'
     *     }],
     *     revoker: '0x244934dd3e31bE2c81f84ECf0b3E6329F5381992'
     * }])
     *
     */
    function multiRevokeByDelegation(
        MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests
    ) external payable;

    /**
     * @dev Timestamps the specified bytes32 data.
     *
     * @param data The data to timestamp.
     *
     * @return The timestamp the data was timestamped with.
     */
    function timestamp(bytes32 data) external returns (uint64);

    /**
     * @dev Timestamps the specified multiple bytes32 data.
     *
     * @param data The data to timestamp.
     *
     * @return The timestamp the data was timestamped with.
     */
    function multiTimestamp(bytes32[] calldata data) external returns (uint64);

    /**
     * @dev Revokes the specified bytes32 data.
     *
     * @param data The data to timestamp.
     *
     * @return The timestamp the data was revoked with.
     */
    function revokeOffchain(bytes32 data) external returns (uint64);

    /**
     * @dev Revokes the specified multiple bytes32 data.
     *
     * @param data The data to timestamp.
     *
     * @return The timestamp the data was revoked with.
     */
    function multiRevokeOffchain(bytes32[] calldata data) external returns (uint64);

    /**
     * @dev Returns an existing attestation by UID.
     *
     * @param uid The UID of the attestation to retrieve.
     *
     * @return The attestation data members.
     */
    function getAttestation(bytes32 uid) external view returns (Attestation memory);

    /**
     * @dev Checks whether an attestation exists.
     *
     * @param uid The UID of the attestation to retrieve.
     *
     * @return Whether an attestation exists.
     */
    function isAttestationValid(bytes32 uid) external view returns (bool);

    /**
     * @dev Returns the timestamp that the specified data was timestamped with.
     *
     * @param data The data to query.
     *
     * @return The timestamp the data was timestamped with.
     */
    function getTimestamp(bytes32 data) external view returns (uint64);

    /**
     * @dev Returns the timestamp that the specified data was timestamped with.
     *
     * @param data The data to query.
     *
     * @return The timestamp the data was timestamped with.
     */
    function getRevokeOffchain(address revoker, bytes32 data) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISchemaResolver } from "./resolver/ISchemaResolver.sol";

/**
 * @title A struct representing a record for a submitted schema.
 */
struct SchemaRecord {
    bytes32 uid; // The unique identifier of the schema.
    ISchemaResolver resolver; // Optional schema resolver.
    bool revocable; // Whether the schema allows revocations explicitly.
    string schema; // Custom specification of the schema (e.g., an ABI).
}

/**
 * @title The global schema registry interface.
 */
interface ISchemaRegistry {
    /**
     * @dev Emitted when a new schema has been registered
     *
     * @param uid The schema UID.
     * @param registerer The address of the account used to register the schema.
     */
    event Registered(bytes32 indexed uid, address registerer);

    /**
     * @dev Submits and reserves a new schema
     *
     * @param schema The schema data schema.
     * @param resolver An optional schema resolver.
     * @param revocable Whether the schema allows revocations explicitly.
     *
     * @return The UID of the new schema.
     */
    function register(string calldata schema, ISchemaResolver resolver, bool revocable) external returns (bytes32);

    /**
     * @dev Returns an existing schema by UID
     *
     * @param uid The UID of the schema to retrieve.
     *
     * @return The schema data members.
     */
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Attestation } from "../Types.sol";

/**
 * @title The interface of an optional schema resolver.
 */
interface ISchemaResolver {
    /**
     * @dev Returns whether the resolver supports ETH transfers.
     */
    function isPayable() external pure returns (bool);

    /**
     * @dev Processes an attestation and verifies whether it's valid.
     *
     * @param attestation The new attestation.
     *
     * @return Whether the attestation is valid.
     */
    function attest(Attestation calldata attestation) external payable returns (bool);

    /**
     * @dev Processes multiple attestations and verifies whether they are valid.
     *
     * @param attestations The new attestations.
     * @param values Explicit ETH amounts which were sent with each attestation.
     *
     * @return Whether all the attestations are valid.
     */
    function multiAttest(
        Attestation[] calldata attestations,
        uint256[] calldata values
    ) external payable returns (bool);

    /**
     * @dev Processes an attestation revocation and verifies if it can be revoked.
     *
     * @param attestation The existing attestation to be revoked.
     *
     * @return Whether the attestation can be revoked.
     */
    function revoke(Attestation calldata attestation) external payable returns (bool);

    /**
     * @dev Processes revocation of multiple attestation and verifies they can be revoked.
     *
     * @param attestations The existing attestations to be revoked.
     * @param values Explicit ETH amounts which were sent with each revocation.
     *
     * @return Whether the attestations can be revoked.
     */
    function multiRevoke(
        Attestation[] calldata attestations,
        uint256[] calldata values
    ) external payable returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// A representation of an empty/uninitialized UID.
bytes32 constant EMPTY_UID = 0;

/**
 * @dev A struct representing EIP712 signature data.
 */
struct EIP712Signature {
    uint8 v; // The recovery ID.
    bytes32 r; // The x-coordinate of the nonce R.
    bytes32 s; // The signature data.
}

/**
 * @dev A struct representing a single attestation.
 */
struct Attestation {
    bytes32 uid; // A unique identifier of the attestation.
    bytes32 schema; // The unique identifier of the schema.
    uint64 time; // The time when the attestation was created (Unix timestamp).
    uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint64 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    bytes32 refUID; // The UID of the related attestation.
    address recipient; // The recipient of the attestation.
    address attester; // The attester/sender of the attestation.
    bool revocable; // Whether the attestation is revocable.
    bytes data; // Custom attestation data.
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