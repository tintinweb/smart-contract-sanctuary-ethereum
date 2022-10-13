pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../Types.sol";
import "../interfaces/IEAS.sol";
import "../interfaces/IASRegistry.sol";

/**
 * @title TellerAS - Teller Attestation Service - based on EAS - Ethereum Attestation Service
 */
contract TellerAS is IEAS {
    error AccessDenied();
    error AlreadyRevoked();
    error InvalidAttestation();
    error InvalidExpirationTime();
    error InvalidOffset();
    error InvalidRegistry();
    error InvalidSchema();
    error InvalidVerifier();
    error NotFound();
    error NotPayable();

    string public constant VERSION = "0.8";

    // A terminator used when concatenating and hashing multiple fields.
    string private constant HASH_TERMINATOR = "@";

    // The AS global registry.
    IASRegistry private immutable _asRegistry;

    // The EIP712 verifier used to verify signed attestations.
    IEASEIP712Verifier private immutable _eip712Verifier;

    // A mapping between attestations and their related attestations.
    mapping(bytes32 => bytes32[]) private _relatedAttestations;

    // A mapping between an account and its received attestations.
    mapping(address => mapping(bytes32 => bytes32[]))
        private _receivedAttestations;

    // A mapping between an account and its sent attestations.
    mapping(address => mapping(bytes32 => bytes32[])) private _sentAttestations;

    // A mapping between a schema and its attestations.
    mapping(bytes32 => bytes32[]) private _schemaAttestations;

    // The global mapping between attestations and their UUIDs.
    mapping(bytes32 => Attestation) private _db;

    // The global counter for the total number of attestations.
    uint256 private _attestationsCount;

    bytes32 private _lastUUID;

    /**
     * @dev Creates a new EAS instance.
     *
     * @param registry The address of the global AS registry.
     * @param verifier The address of the EIP712 verifier.
     */
    constructor(IASRegistry registry, IEASEIP712Verifier verifier) {
        if (address(registry) == address(0x0)) {
            revert InvalidRegistry();
        }

        if (address(verifier) == address(0x0)) {
            revert InvalidVerifier();
        }

        _asRegistry = registry;
        _eip712Verifier = verifier;
    }

    /**
     * @inheritdoc IEAS
     */
    function getASRegistry() external view override returns (IASRegistry) {
        return _asRegistry;
    }

    /**
     * @inheritdoc IEAS
     */
    function getEIP712Verifier()
        external
        view
        override
        returns (IEASEIP712Verifier)
    {
        return _eip712Verifier;
    }

    /**
     * @inheritdoc IEAS
     */
    function getAttestationsCount() external view override returns (uint256) {
        return _attestationsCount;
    }

    /**
     * @inheritdoc IEAS
     */
    function attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data
    ) public payable virtual override returns (bytes32) {
        return
            _attest(
                recipient,
                schema,
                expirationTime,
                refUUID,
                data,
                msg.sender
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function attestByDelegation(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable virtual override returns (bytes32) {
        _eip712Verifier.attest(
            recipient,
            schema,
            expirationTime,
            refUUID,
            data,
            attester,
            v,
            r,
            s
        );

        return
            _attest(recipient, schema, expirationTime, refUUID, data, attester);
    }

    /**
     * @inheritdoc IEAS
     */
    function revoke(bytes32 uuid) public virtual override {
        return _revoke(uuid, msg.sender);
    }

    /**
     * @inheritdoc IEAS
     */
    function revokeByDelegation(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        _eip712Verifier.revoke(uuid, attester, v, r, s);

        _revoke(uuid, attester);
    }

    /**
     * @inheritdoc IEAS
     */
    function getAttestation(bytes32 uuid)
        external
        view
        override
        returns (Attestation memory)
    {
        return _db[uuid];
    }

    /**
     * @inheritdoc IEAS
     */
    function isAttestationValid(bytes32 uuid)
        public
        view
        override
        returns (bool)
    {
        return _db[uuid].uuid != 0;
    }

    /**
     * @inheritdoc IEAS
     */
    function isAttestationActive(bytes32 uuid)
        public
        view
        override
        returns (bool)
    {
        return
            isAttestationValid(uuid) &&
            _db[uuid].expirationTime >= block.timestamp &&
            _db[uuid].revocationTime == 0;
    }

    /**
     * @inheritdoc IEAS
     */
    function getReceivedAttestationUUIDs(
        address recipient,
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return
            _sliceUUIDs(
                _receivedAttestations[recipient][schema],
                start,
                length,
                reverseOrder
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function getReceivedAttestationUUIDsCount(address recipient, bytes32 schema)
        external
        view
        override
        returns (uint256)
    {
        return _receivedAttestations[recipient][schema].length;
    }

    /**
     * @inheritdoc IEAS
     */
    function getSentAttestationUUIDs(
        address attester,
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return
            _sliceUUIDs(
                _sentAttestations[attester][schema],
                start,
                length,
                reverseOrder
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function getSentAttestationUUIDsCount(address recipient, bytes32 schema)
        external
        view
        override
        returns (uint256)
    {
        return _sentAttestations[recipient][schema].length;
    }

    /**
     * @inheritdoc IEAS
     */
    function getRelatedAttestationUUIDs(
        bytes32 uuid,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return
            _sliceUUIDs(
                _relatedAttestations[uuid],
                start,
                length,
                reverseOrder
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function getRelatedAttestationUUIDsCount(bytes32 uuid)
        external
        view
        override
        returns (uint256)
    {
        return _relatedAttestations[uuid].length;
    }

    /**
     * @inheritdoc IEAS
     */
    function getSchemaAttestationUUIDs(
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view override returns (bytes32[] memory) {
        return
            _sliceUUIDs(
                _schemaAttestations[schema],
                start,
                length,
                reverseOrder
            );
    }

    /**
     * @inheritdoc IEAS
     */
    function getSchemaAttestationUUIDsCount(bytes32 schema)
        external
        view
        override
        returns (uint256)
    {
        return _schemaAttestations[schema].length;
    }

    /**
     * @dev Attests to a specific AS.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     *
     * @return The UUID of the new attestation.
     */
    function _attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester
    ) private returns (bytes32) {
        if (expirationTime <= block.timestamp) {
            revert InvalidExpirationTime();
        }

        IASRegistry.ASRecord memory asRecord = _asRegistry.getAS(schema);
        if (asRecord.uuid == EMPTY_UUID) {
            revert InvalidSchema();
        }

        IASResolver resolver = asRecord.resolver;
        if (address(resolver) != address(0x0)) {
            if (msg.value != 0 && !resolver.isPayable()) {
                revert NotPayable();
            }

            if (
                !resolver.resolve{ value: msg.value }(
                    recipient,
                    asRecord.schema,
                    data,
                    expirationTime,
                    attester
                )
            ) {
                revert InvalidAttestation();
            }
        }

        Attestation memory attestation = Attestation({
            uuid: EMPTY_UUID,
            schema: schema,
            recipient: recipient,
            attester: attester,
            time: block.timestamp,
            expirationTime: expirationTime,
            revocationTime: 0,
            refUUID: refUUID,
            data: data
        });

        _lastUUID = _getUUID(attestation);
        attestation.uuid = _lastUUID;

        _receivedAttestations[recipient][schema].push(_lastUUID);
        _sentAttestations[attester][schema].push(_lastUUID);
        _schemaAttestations[schema].push(_lastUUID);

        _db[_lastUUID] = attestation;
        _attestationsCount++;

        if (refUUID != 0) {
            if (!isAttestationValid(refUUID)) {
                revert NotFound();
            }

            _relatedAttestations[refUUID].push(_lastUUID);
        }

        emit Attested(recipient, attester, _lastUUID, schema);

        return _lastUUID;
    }

    function getLastUUID() external view returns (bytes32) {
        return _lastUUID;
    }

    /**
     * @dev Revokes an existing attestation to a specific AS.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     */
    function _revoke(bytes32 uuid, address attester) private {
        Attestation storage attestation = _db[uuid];
        if (attestation.uuid == EMPTY_UUID) {
            revert NotFound();
        }

        if (attestation.attester != attester) {
            revert AccessDenied();
        }

        if (attestation.revocationTime != 0) {
            revert AlreadyRevoked();
        }

        attestation.revocationTime = block.timestamp;

        emit Revoked(attestation.recipient, attester, uuid, attestation.schema);
    }

    /**
     * @dev Calculates a UUID for a given attestation.
     *
     * @param attestation The input attestation.
     *
     * @return Attestation UUID.
     */
    function _getUUID(Attestation memory attestation)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    attestation.schema,
                    attestation.recipient,
                    attestation.attester,
                    attestation.time,
                    attestation.expirationTime,
                    attestation.data,
                    HASH_TERMINATOR,
                    _attestationsCount
                )
            );
    }

    /**
     * @dev Returns a slice in an array of attestation UUIDs.
     *
     * @param uuids The array of attestation UUIDs.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function _sliceUUIDs(
        bytes32[] memory uuids,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) private pure returns (bytes32[] memory) {
        uint256 attestationsLength = uuids.length;
        if (attestationsLength == 0) {
            return new bytes32[](0);
        }

        if (start >= attestationsLength) {
            revert InvalidOffset();
        }

        uint256 len = length;
        if (attestationsLength < start + length) {
            len = attestationsLength - start;
        }

        bytes32[] memory res = new bytes32[](len);

        for (uint256 i = 0; i < len; ++i) {
            res[i] = uuids[
                reverseOrder ? attestationsLength - (start + i + 1) : start + i
            ];
        }

        return res;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// A representation of an empty/uninitialized UUID.
bytes32 constant EMPTY_UUID = 0;

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./IASRegistry.sol";
import "./IEASEIP712Verifier.sol";

/**
 * @title EAS - Ethereum Attestation Service interface
 */
interface IEAS {
    /**
     * @dev A struct representing a single attestation.
     */
    struct Attestation {
        // A unique identifier of the attestation.
        bytes32 uuid;
        // A unique identifier of the AS.
        bytes32 schema;
        // The recipient of the attestation.
        address recipient;
        // The attester/sender of the attestation.
        address attester;
        // The time when the attestation was created (Unix timestamp).
        uint256 time;
        // The time when the attestation expires (Unix timestamp).
        uint256 expirationTime;
        // The time when the attestation was revoked (Unix timestamp).
        uint256 revocationTime;
        // The UUID of the related attestation.
        bytes32 refUUID;
        // Custom attestation data.
        bytes data;
    }

    /**
     * @dev Triggered when an attestation has been made.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param uuid The UUID the revoked attestation.
     * @param schema The UUID of the AS.
     */
    event Attested(
        address indexed recipient,
        address indexed attester,
        bytes32 uuid,
        bytes32 indexed schema
    );

    /**
     * @dev Triggered when an attestation has been revoked.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param schema The UUID of the AS.
     * @param uuid The UUID the revoked attestation.
     */
    event Revoked(
        address indexed recipient,
        address indexed attester,
        bytes32 uuid,
        bytes32 indexed schema
    );

    /**
     * @dev Returns the address of the AS global registry.
     *
     * @return The address of the AS global registry.
     */
    function getASRegistry() external view returns (IASRegistry);

    /**
     * @dev Returns the address of the EIP712 verifier used to verify signed attestations.
     *
     * @return The address of the EIP712 verifier used to verify signed attestations.
     */
    function getEIP712Verifier() external view returns (IEASEIP712Verifier);

    /**
     * @dev Returns the global counter for the total number of attestations.
     *
     * @return The global counter for the total number of attestations.
     */
    function getAttestationsCount() external view returns (uint256);

    /**
     * @dev Attests to a specific AS.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     *
     * @return The UUID of the new attestation.
     */
    function attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data
    ) external payable returns (bytes32);

    /**
     * @dev Attests to a specific AS using a provided EIP712 signature.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     *
     * @return The UUID of the new attestation.
     */
    function attestByDelegation(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes32);

    /**
     * @dev Revokes an existing attestation to a specific AS.
     *
     * @param uuid The UUID of the attestation to revoke.
     */
    function revoke(bytes32 uuid) external;

    /**
     * @dev Attests to a specific AS using a provided EIP712 signature.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function revokeByDelegation(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns an existing attestation by UUID.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return The attestation data members.
     */
    function getAttestation(bytes32 uuid)
        external
        view
        returns (Attestation memory);

    /**
     * @dev Checks whether an attestation exists.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return Whether an attestation exists.
     */
    function isAttestationValid(bytes32 uuid) external view returns (bool);

    /**
     * @dev Checks whether an attestation is active.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return Whether an attestation is active.
     */
    function isAttestationActive(bytes32 uuid) external view returns (bool);

    /**
     * @dev Returns all received attestation UUIDs.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getReceivedAttestationUUIDs(
        address recipient,
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of received attestation UUIDs.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     *
     * @return The number of attestations.
     */
    function getReceivedAttestationUUIDsCount(address recipient, bytes32 schema)
        external
        view
        returns (uint256);

    /**
     * @dev Returns all sent attestation UUIDs.
     *
     * @param attester The attesting account.
     * @param schema The UUID of the AS.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getSentAttestationUUIDs(
        address attester,
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of sent attestation UUIDs.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     *
     * @return The number of attestations.
     */
    function getSentAttestationUUIDsCount(address recipient, bytes32 schema)
        external
        view
        returns (uint256);

    /**
     * @dev Returns all attestations related to a specific attestation.
     *
     * @param uuid The UUID of the attestation to retrieve.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getRelatedAttestationUUIDs(
        bytes32 uuid,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of related attestation UUIDs.
     *
     * @param uuid The UUID of the attestation to retrieve.
     *
     * @return The number of related attestations.
     */
    function getRelatedAttestationUUIDsCount(bytes32 uuid)
        external
        view
        returns (uint256);

    /**
     * @dev Returns all per-schema attestation UUIDs.
     *
     * @param schema The UUID of the AS.
     * @param start The offset to start from.
     * @param length The number of total members to retrieve.
     * @param reverseOrder Whether the offset starts from the end and the data is returned in reverse.
     *
     * @return An array of attestation UUIDs.
     */
    function getSchemaAttestationUUIDs(
        bytes32 schema,
        uint256 start,
        uint256 length,
        bool reverseOrder
    ) external view returns (bytes32[] memory);

    /**
     * @dev Returns the number of per-schema  attestation UUIDs.
     *
     * @param schema The UUID of the AS.
     *
     * @return The number of attestations.
     */
    function getSchemaAttestationUUIDsCount(bytes32 schema)
        external
        view
        returns (uint256);
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./IASResolver.sol";

/**
 * @title The global AS registry interface.
 */
interface IASRegistry {
    /**
     * @title A struct representing a record for a submitted AS (Attestation Schema).
     */
    struct ASRecord {
        // A unique identifier of the AS.
        bytes32 uuid;
        // Optional schema resolver.
        IASResolver resolver;
        // Auto-incrementing index for reference, assigned by the registry itself.
        uint256 index;
        // Custom specification of the AS (e.g., an ABI).
        bytes schema;
    }

    /**
     * @dev Triggered when a new AS has been registered
     *
     * @param uuid The AS UUID.
     * @param index The AS index.
     * @param schema The AS schema.
     * @param resolver An optional AS schema resolver.
     * @param attester The address of the account used to register the AS.
     */
    event Registered(
        bytes32 indexed uuid,
        uint256 indexed index,
        bytes schema,
        IASResolver resolver,
        address attester
    );

    /**
     * @dev Submits and reserve a new AS
     *
     * @param schema The AS data schema.
     * @param resolver An optional AS schema resolver.
     *
     * @return The UUID of the new AS.
     */
    function register(bytes calldata schema, IASResolver resolver)
        external
        returns (bytes32);

    /**
     * @dev Returns an existing AS by UUID
     *
     * @param uuid The UUID of the AS to retrieve.
     *
     * @return The AS data members.
     */
    function getAS(bytes32 uuid) external view returns (ASRecord memory);

    /**
     * @dev Returns the global counter for the total number of attestations
     *
     * @return The global counter for the total number of attestations.
     */
    function getASCount() external view returns (uint256);
}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT

/**
 * @title EIP712 typed signatures verifier for EAS delegated attestations interface.
 */
interface IEASEIP712Verifier {
    /**
     * @dev Returns the current nonce per-account.
     *
     * @param account The requested accunt.
     *
     * @return The current nonce.
     */
    function getNonce(address account) external view returns (uint256);

    /**
     * @dev Verifies signed attestation.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The UUID of the AS.
     * @param expirationTime The expiration time of the attestation.
     * @param refUUID An optional related attestation's UUID.
     * @param data Additional custom data.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Verifies signed revocations.
     *
     * @param uuid The UUID of the attestation to revoke.
     * @param attester The attesting account.
     * @param v The recovery ID.
     * @param r The x-coordinate of the nonce R.
     * @param s The signature data.
     */
    function revoke(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT

/**
 * @title The interface of an optional AS resolver.
 */
interface IASResolver {
    /**
     * @dev Returns whether the resolver supports ETH transfers
     */
    function isPayable() external pure returns (bool);

    /**
     * @dev Resolves an attestation and verifier whether its data conforms to the spec.
     *
     * @param recipient The recipient of the attestation.
     * @param schema The AS data schema.
     * @param data The actual attestation data.
     * @param expirationTime The expiration time of the attestation.
     * @param msgSender The sender of the original attestation message.
     *
     * @return Whether the data is valid according to the scheme.
     */
    function resolve(
        address recipient,
        bytes calldata schema,
        bytes calldata data,
        uint256 expirationTime,
        address msgSender
    ) external payable returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Testable } from "./Testable.sol";

import { TellerV2Autopay } from "../TellerV2Autopay.sol";
import { MarketRegistry } from "../MarketRegistry.sol";
import { ReputationManager } from "../ReputationManager.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../TellerV2Storage.sol";

import "../interfaces/IMarketRegistry.sol";
import "../interfaces/IReputationManager.sol";

import "../EAS/TellerAS.sol";

import "../mock/WethMock.sol";

import "../mock/TellerV2SolMock.sol";
import "../mock/MarketRegistryMock.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/ITellerV2Autopay.sol";

import "@mangrovedao/hardhat-test-solidity/test.sol";
import "hardhat/console.sol";

contract TellerV2Autopay_Test is Testable, TellerV2Autopay {
    User private marketOwner;
    User private borrower;
    User private lender;

    WethMock wethMock;

    address marketRegistry;

    constructor() TellerV2Autopay(address(new TellerV2SolMock())) {
        marketRegistry = address(new MarketRegistryMock());
        TellerV2SolMock(address(tellerV2)).setMarketRegistry(marketRegistry);
    }

    function setup_beforeAll() public {
        wethMock = new WethMock();

        marketOwner = new User(
            address(this),
            address(tellerV2),
            address(wethMock)
        );
        borrower = new User(
            address(this),
            address(tellerV2),
            address(wethMock)
        );
        lender = new User(address(this), address(tellerV2), address(wethMock));
    }

    function setAutoPayEnabled_before() public {
        uint256 marketplaceId = 1;
        marketOwner.createMarketWithinRegistry(
            address(marketRegistry),
            8000,
            7000,
            5000,
            500,
            false,
            false,
            V2Calculations.PaymentType.EMI,
            "uri://"
        );

        uint256 bidId = borrower.submitBid(
            address(wethMock),
            marketplaceId,
            100,
            4000,
            300,
            "ipfs://",
            address(borrower)
        );
    }

    function setAutoPayEnabled_test() public {
        uint256 bidId = 0;

        borrower.enableAutoPay(bidId, true);

        Test.eq(
            loanAutoPayEnabled[bidId],
            true,
            "Autopay not enabled after setAutoPayEnabled"
        );
    }

    function autoPayLoanMinimum_before() public {
        uint256 marketplaceId = 1;

        uint256 lenderNewBalance = 50000;

        payable(address(lender)).transfer(lenderNewBalance);

        //lender approves for acceptBid
        lender.depositToWeth(lenderNewBalance);
        lender.approveWeth(address(tellerV2), lenderNewBalance);

        uint256 bidId = borrower.submitBid(
            address(wethMock),
            marketplaceId,
            100,
            4000,
            300,
            "ipfs://",
            address(borrower)
        );

        borrower.enableAutoPay(bidId, true);

        uint256 lenderBalance = ERC20(address(wethMock)).balanceOf(
            address(lender)
        );

        lender.acceptBid(bidId);

        uint256 borrowerNewBalance = 50000;

        payable(address(borrower)).transfer(borrowerNewBalance);

        //borrower approve to do repay
        borrower.depositToWeth(borrowerNewBalance);
        borrower.approveWeth(address(this), borrowerNewBalance);
    }

    function autoPayLoanMinimum_test() public {
        uint256 bidId = 0;

        uint256 lenderBalanceBefore = ERC20(address(wethMock)).balanceOf(
            address(lender)
        );
        uint256 borrowerBalanceBefore = ERC20(address(wethMock)).balanceOf(
            address(borrower)
        );

        lender.autoPayLoanMinimum(bidId);

        uint256 lenderBalanceAfter = ERC20(address(wethMock)).balanceOf(
            address(lender)
        );
        uint256 borrowerBalanceAfter = ERC20(address(wethMock)).balanceOf(
            address(borrower)
        );

        uint256 lenderBalanceDelta = lenderBalanceBefore - lenderBalanceAfter;

        Test.eq(lenderBalanceDelta, 0, "lender balance changed");

        uint256 borrowerBalanceDelta = borrowerBalanceBefore -
            borrowerBalanceAfter;

        Test.eq(borrowerBalanceDelta, 400, "borrower did not autopay");
    }

    function getEstimatedMinimumPayment(uint256 _bidId)
        public
        override
        returns (uint256 _amount)
    {
        return 400; //stub this for this test since there is not a good way to fast forward timestamp
    }
}

contract User {
    address public immutable tellerV2;
    address public immutable wethMock;
    address public immutable tellerV2Autopay;

    constructor(
        address _tellerV2Autopay,
        address _tellerV2,
        address _wethMock
    ) {
        tellerV2Autopay = _tellerV2Autopay;
        tellerV2 = _tellerV2;
        wethMock = _wethMock;
    }

    function enableAutoPay(uint256 bidId, bool enabled) public {
        ITellerV2Autopay(tellerV2Autopay).setAutoPayEnabled(bidId, enabled);
    }

    function createMarketWithinRegistry(
        address marketRegistry,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        V2Calculations.PaymentType _paymentType,
        string calldata _uri
    ) public {
        IMarketRegistry(marketRegistry).createMarket(
            address(this),
            _paymentCycleDuration,
            _paymentDefaultDuration,
            _bidExpirationTime,
            _feePercent,
            _requireLenderAttestation,
            _requireBorrowerAttestation,
            _paymentType,
            _uri
        );
    }

    function autoPayLoanMinimum(uint256 bidId) public {
        ITellerV2Autopay(tellerV2Autopay).autoPayLoanMinimum(bidId);
    }

    function submitBid(
        address _lendingToken,
        uint256 _marketplaceId,
        uint256 _principal,
        uint32 _duration,
        uint16 _APR,
        string calldata _metadataURI,
        address _receiver
    ) public returns (uint256) {
        return
            ITellerV2(tellerV2).submitBid(
                _lendingToken,
                _marketplaceId,
                _principal,
                _duration,
                _APR,
                _metadataURI,
                _receiver
            );
    }

    function acceptBid(uint256 _bidId) public {
        ITellerV2(tellerV2).lenderAcceptBid(_bidId);
    }

    function depositToWeth(uint256 amount) public {
        IWETH(wethMock).deposit{ value: amount }();
    }

    function approveWeth(address to, uint256 amount) public {
        ERC20(wethMock).approve(to, amount);
    }

    receive() external payable {}
}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT

abstract contract Testable {
    receive() external payable {}
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./interfaces/ITellerV2.sol";

import "./interfaces/ITellerV2Autopay.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Helper contract to autopay loans
 */
contract TellerV2Autopay is
    Initializable,
    ContextUpgradeable,
    ITellerV2Autopay
{
    using SafeERC20 for ERC20;

    ITellerV2 public immutable tellerV2;

    //bidId => enabled
    mapping(uint256 => bool) public loanAutoPayEnabled;

    /**
     * @notice This event is emitted when a loan is autopaid.
     * @param bidId The id of the bid/loan which was repaid.
     * @param msgsender The account that called the method
     */
    event AutoPaidLoanMinimum(uint256 indexed bidId, address indexed msgsender);

    /**
     * @notice This event is emitted when loan autopayments are enabled or disabled.
     * @param bidId The id of the bid/loan.
     * @param enabled Whether the autopayments are enabled or disabled
     */
    event AutoPayEnabled(uint256 indexed bidId, bool enabled);

    constructor(address _protocolAddress) {
        tellerV2 = ITellerV2(_protocolAddress);
    }

    /**
     * @notice Function for a borrower to enable or disable autopayments
     * @param _bidId The id of the bid to cancel.
     * @param _autoPayEnabled boolean for allowing autopay on a loan
     */
    function setAutoPayEnabled(uint256 _bidId, bool _autoPayEnabled) external {
        require(
            _msgSender() == tellerV2.getLoanBorrower(_bidId),
            "Only the borrower can set autopay"
        );

        loanAutoPayEnabled[_bidId] = _autoPayEnabled;

        emit AutoPayEnabled(_bidId, _autoPayEnabled);
    }

    /**
     * @notice Function for a minimum autopayment to be performed on a loan
     * @param _bidId The id of the bid to repay.
     */
    function autoPayLoanMinimum(uint256 _bidId) external {
        require(
            loanAutoPayEnabled[_bidId],
            "Autopay is not enabled for that loan"
        );

        address lendingToken = ITellerV2(tellerV2).getLoanLendingToken(_bidId);
        address borrower = ITellerV2(tellerV2).getLoanBorrower(_bidId);

        uint256 amountToRepayMinimum = getEstimatedMinimumPayment(_bidId);

        //pull lendingToken in from the borrower to this smart contract
        ERC20(lendingToken).safeTransferFrom(
            borrower,
            address(this),
            amountToRepayMinimum
        );

        //approve the lendingToken to tellerV2
        ERC20(lendingToken).approve(address(tellerV2), amountToRepayMinimum);

        //use that lendingToken to repay the loan
        tellerV2.repayLoan(_bidId, amountToRepayMinimum);

        emit AutoPaidLoanMinimum(_bidId, msg.sender);
    }

    function getEstimatedMinimumPayment(uint256 _bidId)
        public
        virtual
        returns (uint256 _amount)
    {
        TellerV2Storage.Payment memory estimatedPayment = tellerV2
            .calculateAmountDue(_bidId);

        _amount = estimatedPayment.principal + estimatedPayment.interest;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./EAS/TellerAS.sol";
import "./EAS/TellerASResolver.sol";

//must continue to use this so storage slots are not broken
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Interfaces
import "./interfaces/IMarketRegistry.sol";

// Libraries
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { V2Calculations } from "./TellerV2.sol";

contract MarketRegistry is
    IMarketRegistry,
    Initializable,
    Context,
    TellerASResolver
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /** Constant Variables **/

    uint256 public constant CURRENT_CODE_VERSION = 7;

    /* Storage Variables */

    struct Marketplace {
        address owner;
        string metadataURI;
        uint16 marketplaceFeePercent; // 10000 is 100%
        bool lenderAttestationRequired;
        EnumerableSet.AddressSet verifiedLendersForMarket;
        mapping(address => bytes32) lenderAttestationIds;
        uint32 paymentCycleDuration; //unix time
        uint32 paymentDefaultDuration; //unix time
        uint32 bidExpirationTime; //unix time
        bool borrowerAttestationRequired;
        EnumerableSet.AddressSet verifiedBorrowersForMarket;
        mapping(address => bytes32) borrowerAttestationIds;
        address feeRecipient;
        V2Calculations.PaymentType paymentType;
    }

    bytes32 public lenderAttestationSchemaId;

    mapping(uint256 => Marketplace) internal markets;
    mapping(bytes32 => uint256) internal __uriToId; //DEPRECATED
    uint256 public marketCount;
    bytes32 private _attestingSchemaId;
    bytes32 public borrowerAttestationSchemaId;

    uint256 public version;

    mapping(uint256 => bool) private marketIsClosed;

    TellerAS public tellerAS;

    /* Modifiers */

    modifier ownsMarket(uint256 _marketId) {
        require(markets[_marketId].owner == _msgSender(), "Not the owner");
        _;
    }

    modifier withAttestingSchema(bytes32 schemaId) {
        _attestingSchemaId = schemaId;
        _;
        _attestingSchemaId = bytes32(0);
    }

    /* Events */

    event MarketCreated(address indexed owner, uint256 marketId);
    event SetMarketURI(uint256 marketId, string uri);
    event SetPaymentCycleDuration(uint256 marketId, uint32 duration);
    event SetPaymentDefaultDuration(uint256 marketId, uint32 duration);
    event SetBidExpirationTime(uint256 marketId, uint32 duration);
    event SetMarketFee(uint256 marketId, uint16 feePct);
    event LenderAttestation(uint256 marketId, address lender);
    event BorrowerAttestation(uint256 marketId, address borrower);
    event LenderRevocation(uint256 marketId, address lender);
    event BorrowerRevocation(uint256 marketId, address borrower);
    event MarketClosed(uint256 marketId);
    event LenderExitMarket(uint256 marketId, address lender);
    event BorrowerExitMarket(uint256 marketId, address borrower);
    event SetMarketOwner(uint256 marketId, address newOwner);
    event SetMarketFeeRecipient(uint256 marketId, address newRecipient);
    event SetMarketLenderAttestation(uint256 marketId, bool required);
    event SetMarketBorrowerAttestation(uint256 marketId, bool required);
    event SetMarketPaymentType(
        uint256 marketId,
        V2Calculations.PaymentType paymentType
    );

    /* External Functions */

    function initialize(TellerAS _tellerAS) external initializer {
        tellerAS = _tellerAS;

        lenderAttestationSchemaId = tellerAS.getASRegistry().register(
            "(uint256 marketId, address lenderAddress)",
            this
        );
        borrowerAttestationSchemaId = tellerAS.getASRegistry().register(
            "(uint256 marketId, address borrowerAddress)",
            this
        );
    }

    /**
     * @notice Sets the new tellerAS on upgrade
     */
    function onUpgrade() external {
        require(
            version != CURRENT_CODE_VERSION,
            "Contract already upgraded to latest version!"
        );
        version = CURRENT_CODE_VERSION;
    }

    /**
     * @notice Creates a new market.
     * @param _initialOwner Address who will initially own the market.
     * @param _paymentCycleDuration Length of time in seconds before a bid's next payment is required to be made.
     * @param _paymentDefaultDuration Length of time in seconds before a loan is considered in default for non-payment.
     * @param _bidExpirationTime Length of time in seconds before pending bids expire.
     * @param _requireLenderAttestation Boolean that indicates if lenders require attestation to join market.
     * @param _requireBorrowerAttestation Boolean that indicates if borrowers require attestation to join market.
     * @param _paymentType The payment type for loans in the market.
     * @param _uri URI string to get metadata details about the market.
     * @return marketId_ The market ID of the newly created market.
     */
    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        V2Calculations.PaymentType _paymentType,
        string calldata _uri
    ) external returns (uint256 marketId_) {
        marketId_ = _createMarket(
            _initialOwner,
            _paymentCycleDuration,
            _paymentDefaultDuration,
            _bidExpirationTime,
            _feePercent,
            _requireLenderAttestation,
            _requireBorrowerAttestation,
            _paymentType,
            _uri
        );
    }

    /**
     * @notice Creates a new market.
     * @dev Uses the default EMI payment type.
     * @param _initialOwner Address who will initially own the market.
     * @param _paymentCycleDuration Length of time in seconds before a bid's next payment is required to be made.
     * @param _paymentDefaultDuration Length of time in seconds before a loan is considered in default for non-payment.
     * @param _bidExpirationTime Length of time in seconds before pending bids expire.
     * @param _requireLenderAttestation Boolean that indicates if lenders require attestation to join market.
     * @param _requireBorrowerAttestation Boolean that indicates if borrowers require attestation to join market.
     * @param _uri URI string to get metadata details about the market.
     * @return marketId_ The market ID of the newly created market.
     */
    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        string calldata _uri
    ) external returns (uint256 marketId_) {
        marketId_ = _createMarket(
            _initialOwner,
            _paymentCycleDuration,
            _paymentDefaultDuration,
            _bidExpirationTime,
            _feePercent,
            _requireLenderAttestation,
            _requireBorrowerAttestation,
            V2Calculations.PaymentType.EMI,
            _uri
        );
    }

    /**
     * @notice Creates a new market.
     * @param _initialOwner Address who will initially own the market.
     * @param _paymentCycleDuration Length of time in seconds before a bid's next payment is required to be made.
     * @param _paymentDefaultDuration Length of time in seconds before a loan is considered in default for non-payment.
     * @param _bidExpirationTime Length of time in seconds before pending bids expire.
     * @param _requireLenderAttestation Boolean that indicates if lenders require attestation to join market.
     * @param _requireBorrowerAttestation Boolean that indicates if borrowers require attestation to join market.
     * @param _paymentType The payment type for loans in the market.
     * @param _uri URI string to get metadata details about the market.
     * @return marketId_ The market ID of the newly created market.
     */
    function _createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        V2Calculations.PaymentType _paymentType,
        string calldata _uri
    ) internal returns (uint256 marketId_) {
        require(_initialOwner != address(0), "Invalid owner address");
        // Increment market ID counter
        marketId_ = ++marketCount;

        // Set the market owner
        markets[marketId_].owner = _initialOwner;

        setMarketURI(marketId_, _uri);
        setPaymentCycleDuration(marketId_, _paymentCycleDuration);
        setPaymentDefaultDuration(marketId_, _paymentDefaultDuration);
        setMarketFeePercent(marketId_, _feePercent);
        setBidExpirationTime(marketId_, _bidExpirationTime);
        setMarketPaymentType(marketId_, _paymentType);

        // Check if market requires lender attestation to join
        if (_requireLenderAttestation) {
            markets[marketId_].lenderAttestationRequired = true;
        }
        // Check if market requires borrower attestation to join
        if (_requireBorrowerAttestation) {
            markets[marketId_].borrowerAttestationRequired = true;
        }

        emit MarketCreated(_initialOwner, marketId_);
    }

    /**
     * @notice Closes a market so new bids cannot be added.
     * @param _marketId The market ID for the market to close.
     */

    function closeMarket(uint256 _marketId) public ownsMarket(_marketId) {
        if (!marketIsClosed[_marketId]) {
            marketIsClosed[_marketId] = true;

            emit MarketClosed(_marketId);
        }
    }

    /**
     * @notice Returns the status of a market being open or closed for new bids.
     * @param _marketId The market ID for the market to check.
     */
    function isMarketClosed(uint256 _marketId)
        public
        view
        override
        returns (bool)
    {
        return marketIsClosed[_marketId];
    }

    /**
     * @notice Adds a lender to a market.
     * @dev See {_attestStakeholder}.
     */
    function attestLender(
        uint256 _marketId,
        address _lenderAddress,
        uint256 _expirationTime
    ) external {
        _attestStakeholder(_marketId, _lenderAddress, _expirationTime, true);
    }

    /**
     * @notice Adds a lender to a market via delegated attestation.
     * @dev See {_attestStakeholderViaDelegation}.
     */
    function attestLender(
        uint256 _marketId,
        address _lenderAddress,
        uint256 _expirationTime,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _attestStakeholderViaDelegation(
            _marketId,
            _lenderAddress,
            _expirationTime,
            true,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Removes a lender from an market.
     * @dev See {_revokeStakeholder}.
     */
    function revokeLender(uint256 _marketId, address _lenderAddress) external {
        _revokeStakeholder(_marketId, _lenderAddress, true);
    }

    /**
     * @notice Removes a borrower from a market via delegated revocation.
     * @dev See {_revokeStakeholderViaDelegation}.
     */
    function revokeLender(
        uint256 _marketId,
        address _lenderAddress,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _revokeStakeholderViaDelegation(
            _marketId,
            _lenderAddress,
            true,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Allows a lender to voluntarily leave a market.
     * @param _marketId The market ID to leave.
     */
    function lenderExitMarket(uint256 _marketId) external {
        // Remove lender address from market set
        bool response = markets[_marketId].verifiedLendersForMarket.remove(
            _msgSender()
        );
        if (response) {
            emit LenderExitMarket(_marketId, _msgSender());
        }
    }

    /**
     * @notice Adds a borrower to a market.
     * @dev See {_attestStakeholder}.
     */
    function attestBorrower(
        uint256 _marketId,
        address _borrowerAddress,
        uint256 _expirationTime
    ) external {
        _attestStakeholder(_marketId, _borrowerAddress, _expirationTime, false);
    }

    /**
     * @notice Adds a borrower to a market via delegated attestation.
     * @dev See {_attestStakeholderViaDelegation}.
     */
    function attestBorrower(
        uint256 _marketId,
        address _borrowerAddress,
        uint256 _expirationTime,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _attestStakeholderViaDelegation(
            _marketId,
            _borrowerAddress,
            _expirationTime,
            false,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Removes a borrower from an market.
     * @dev See {_revokeStakeholder}.
     */
    function revokeBorrower(uint256 _marketId, address _borrowerAddress)
        external
    {
        _revokeStakeholder(_marketId, _borrowerAddress, false);
    }

    /**
     * @notice Removes a borrower from a market via delegated revocation.
     * @dev See {_revokeStakeholderViaDelegation}.
     */
    function revokeBorrower(
        uint256 _marketId,
        address _borrowerAddress,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _revokeStakeholderViaDelegation(
            _marketId,
            _borrowerAddress,
            false,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Allows a borrower to voluntarily leave a market.
     * @param _marketId The market ID to leave.
     */
    function borrowerExitMarket(uint256 _marketId) external {
        // Remove borrower address from market set
        bool response = markets[_marketId].verifiedBorrowersForMarket.remove(
            _msgSender()
        );
        if (response) {
            emit BorrowerExitMarket(_marketId, _msgSender());
        }
    }

    /**
     * @notice Verifies an attestation is valid.
     * @dev This function must only be called by the `attestLender` function above.
     * @param recipient Lender's address who is being attested.
     * @param schema The schema used for the attestation.
     * @param data Data the must include the market ID and lender's address
     * @param
     * @param attestor Market owner's address who signed the attestation.
     * @return Boolean indicating the attestation was successful.
     */
    function resolve(
        address recipient,
        bytes calldata schema,
        bytes calldata data,
        uint256, /* expirationTime */
        address attestor
    ) external payable override returns (bool) {
        bytes32 attestationSchemaId = keccak256(
            abi.encodePacked(schema, address(this))
        );
        (uint256 marketId, address lenderAddress) = abi.decode(
            data,
            (uint256, address)
        );
        return
            (_attestingSchemaId == attestationSchemaId &&
                recipient == lenderAddress &&
                attestor == markets[marketId].owner) ||
            attestor == address(this);
    }

    /**
     * @notice Transfers ownership of a marketplace.
     * @param _marketId The ID of a market.
     * @param _newOwner Address of the new market owner.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function transferMarketOwnership(uint256 _marketId, address _newOwner)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].owner = _newOwner;
        emit SetMarketOwner(_marketId, _newOwner);
    }

    /**
     * @notice Updates multiple market settings for a given market.
     * @param _marketId The ID of a market.
     * @param _paymentCycleDuration Delinquency duration for new loans
     * @param _paymentDefaultDuration Default duration for new loans
     * @param _bidExpirationTime Duration of time before a bid is considered out of date
     * @param _metadataURI A URI that points to a market's metadata.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function updateMarketSettings(
        uint256 _marketId,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _borrowerAttestationRequired,
        bool _lenderAttestationRequired,
        string calldata _metadataURI
    ) public ownsMarket(_marketId) {
        setMarketURI(_marketId, _metadataURI);
        setPaymentCycleDuration(_marketId, _paymentCycleDuration);
        setPaymentDefaultDuration(_marketId, _paymentDefaultDuration);
        setBidExpirationTime(_marketId, _bidExpirationTime);
        setMarketFeePercent(_marketId, _feePercent);
        setLenderAttestationRequired(_marketId, _lenderAttestationRequired);
        setBorrowerAttestationRequired(_marketId, _borrowerAttestationRequired);
    }

    /**
     * @notice Sets the fee recipient address for a market.
     * @param _marketId The ID of a market.
     * @param _recipient Address of the new fee recipient.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setMarketFeeRecipient(uint256 _marketId, address _recipient)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].feeRecipient = _recipient;
        emit SetMarketFeeRecipient(_marketId, _recipient);
    }

    /**
     * @notice Sets the metadata URI for a market.
     * @param _marketId The ID of a market.
     * @param _uri A URI that points to a market's metadata.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setMarketURI(uint256 _marketId, string calldata _uri)
        public
        ownsMarket(_marketId)
    {
        //We do string comparison by checking the hashes of the strings against one another
        if (
            keccak256(abi.encodePacked(_uri)) !=
            keccak256(abi.encodePacked(markets[_marketId].metadataURI))
        ) {
            markets[_marketId].metadataURI = _uri;

            emit SetMarketURI(_marketId, _uri);
        }
    }

    /**
     * @notice Sets the duration of new loans for this market before they turn delinquent.
     * @notice Changing this value does not change the terms of existing loans for this market.
     * @param _marketId The ID of a market.
     * @param _duration Delinquency duration for new loans
     */
    function setPaymentCycleDuration(uint256 _marketId, uint32 _duration)
        public
        ownsMarket(_marketId)
    {
        if (_duration != markets[_marketId].paymentCycleDuration) {
            markets[_marketId].paymentCycleDuration = _duration;

            emit SetPaymentCycleDuration(_marketId, _duration);
        }
    }

    /**
     * @notice Sets the duration of new loans for this market before they turn defaulted.
     * @notice Changing this value does not change the terms of existing loans for this market.
     * @param _marketId The ID of a market.
     * @param _duration Default duration for new loans
     */
    function setPaymentDefaultDuration(uint256 _marketId, uint32 _duration)
        public
        ownsMarket(_marketId)
    {
        if (_duration != markets[_marketId].paymentDefaultDuration) {
            markets[_marketId].paymentDefaultDuration = _duration;

            emit SetPaymentDefaultDuration(_marketId, _duration);
        }
    }

    function setBidExpirationTime(uint256 _marketId, uint32 _duration)
        public
        ownsMarket(_marketId)
    {
        if (_duration != markets[_marketId].bidExpirationTime) {
            markets[_marketId].bidExpirationTime = _duration;

            emit SetBidExpirationTime(_marketId, _duration);
        }
    }

    /**
     * @notice Sets the fee for the market.
     * @param _marketId The ID of a market.
     * @param _newPercent The percentage fee in basis points.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setMarketFeePercent(uint256 _marketId, uint16 _newPercent)
        public
        ownsMarket(_marketId)
    {
        require(_newPercent >= 0 && _newPercent <= 10000, "invalid percent");
        if (_newPercent != markets[_marketId].marketplaceFeePercent) {
            markets[_marketId].marketplaceFeePercent = _newPercent;
            emit SetMarketFee(_marketId, _newPercent);
        }
    }

    /**
     * @notice Set the payment type for the market.
     * @param _marketId The ID of the market.
     * @param _newPaymentType The payment type for the market.
     */
    function setMarketPaymentType(
        uint256 _marketId,
        V2Calculations.PaymentType _newPaymentType
    ) public ownsMarket(_marketId) {
        if (_newPaymentType != markets[_marketId].paymentType) {
            markets[_marketId].paymentType = _newPaymentType;
            emit SetMarketPaymentType(_marketId, _newPaymentType);
        }
    }

    /**
     * @notice Enable/disables market whitelist for lenders.
     * @param _marketId The ID of a market.
     * @param _required Boolean indicating if the market requires whitelist.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setLenderAttestationRequired(uint256 _marketId, bool _required)
        public
        ownsMarket(_marketId)
    {
        if (_required != markets[_marketId].lenderAttestationRequired) {
            markets[_marketId].lenderAttestationRequired = _required;
            emit SetMarketLenderAttestation(_marketId, _required);
        }
    }

    /**
     * @notice Enable/disables market whitelist for borrowers.
     * @param _marketId The ID of a market.
     * @param _required Boolean indicating if the market requires whitelist.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setBorrowerAttestationRequired(uint256 _marketId, bool _required)
        public
        ownsMarket(_marketId)
    {
        if (_required != markets[_marketId].borrowerAttestationRequired) {
            markets[_marketId].borrowerAttestationRequired = _required;
            emit SetMarketBorrowerAttestation(_marketId, _required);
        }
    }

    /**
     * @notice Gets the data associated with a market.
     * @param _marketId The ID of a market.
     */
    function getMarketData(uint256 _marketId)
        public
        view
        returns (
            address owner,
            uint32 paymentCycleDuration,
            uint32 paymentDefaultDuration,
            uint32 loanExpirationTime,
            string memory metadataURI,
            uint16 marketplaceFeePercent,
            bool lenderAttestationRequired
        )
    {
        return (
            markets[_marketId].owner,
            markets[_marketId].paymentCycleDuration,
            markets[_marketId].paymentDefaultDuration,
            markets[_marketId].bidExpirationTime,
            markets[_marketId].metadataURI,
            markets[_marketId].marketplaceFeePercent,
            markets[_marketId].lenderAttestationRequired
        );
    }

    /**
     * @notice Gets the attestation requirements for a given market.
     * @param _marketId The ID of the market.
     */
    function getMarketAttestationRequirements(uint256 _marketId)
        public
        view
        returns (
            bool lenderAttestationRequired,
            bool borrowerAttestationRequired
        )
    {
        return (
            markets[_marketId].lenderAttestationRequired,
            markets[_marketId].borrowerAttestationRequired
        );
    }

    /**
     * @notice Gets the address of a market's owner.
     * @param _marketId The ID of a market.
     * @return The address of a market's owner.
     */
    function getMarketOwner(uint256 _marketId)
        public
        view
        override
        returns (address)
    {
        return markets[_marketId].owner;
    }

    /**
     * @notice Gets the fee recipient of a market.
     * @param _marketId The ID of a market.
     * @return The address of a market's fee recipient.
     */
    function getMarketFeeRecipient(uint256 _marketId)
        public
        view
        override
        returns (address)
    {
        address recipient = markets[_marketId].feeRecipient;

        if (recipient == address(0)) {
            return markets[_marketId].owner;
        }

        return recipient;
    }

    /**
     * @notice Gets the metadata URI of a market.
     * @param _marketId The ID of a market.
     * @return URI of a market's metadata.
     */
    function getMarketURI(uint256 _marketId)
        public
        view
        override
        returns (string memory)
    {
        return markets[_marketId].metadataURI;
    }

    /**
     * @notice Gets the loan delinquent duration of a market.
     * @param _marketId The ID of a market.
     * @return Duration of a loan until it is delinquent.
     */
    function getPaymentCycleDuration(uint256 _marketId)
        public
        view
        override
        returns (uint32)
    {
        return markets[_marketId].paymentCycleDuration;
    }

    /**
     * @notice Gets the loan default duration of a market.
     * @param _marketId The ID of a market.
     * @return Duration of a loan repayment interval until it is default.
     */
    function getPaymentDefaultDuration(uint256 _marketId)
        public
        view
        override
        returns (uint32)
    {
        return markets[_marketId].paymentDefaultDuration;
    }

    /**
     * @notice Get the payment type of a market.
     * @param _marketId the ID of the market.
     * @return The type of payment for loans in the market.
     */
    function getPaymentType(uint256 _marketId)
        public
        view
        override
        returns (V2Calculations.PaymentType)
    {
        return markets[_marketId].paymentType;
    }

    function getBidExpirationTime(uint256 marketId)
        public
        view
        override
        returns (uint32)
    {
        return markets[marketId].bidExpirationTime;
    }

    /**
     * @notice Gets the marketplace fee in basis points
     * @param _marketId The ID of a market.
     * @return fee in basis points
     */
    function getMarketplaceFee(uint256 _marketId)
        public
        view
        override
        returns (uint16 fee)
    {
        return markets[_marketId].marketplaceFeePercent;
    }

    /**
     * @notice Checks if a lender has been attested and added to a market.
     * @param _marketId The ID of a market.
     * @param _lenderAddress Address to check.
     * @return isVerified_ Boolean indicating if a lender has been added to a market.
     * @return uuid_ Bytes32 representing the UUID of the lender.
     */
    function isVerifiedLender(uint256 _marketId, address _lenderAddress)
        public
        view
        override
        returns (bool isVerified_, bytes32 uuid_)
    {
        return
            _isVerified(
                _lenderAddress,
                markets[_marketId].lenderAttestationRequired,
                markets[_marketId].lenderAttestationIds,
                markets[_marketId].verifiedLendersForMarket
            );
    }

    /**
     * @notice Checks if a borrower has been attested and added to a market.
     * @param _marketId The ID of a market.
     * @param _borrowerAddress Address of the borrower to check.
     * @return isVerified_ Boolean indicating if a borrower has been added to a market.
     * @return uuid_ Bytes32 representing the UUID of the borrower.
     */
    function isVerifiedBorrower(uint256 _marketId, address _borrowerAddress)
        public
        view
        override
        returns (bool isVerified_, bytes32 uuid_)
    {
        return
            _isVerified(
                _borrowerAddress,
                markets[_marketId].borrowerAttestationRequired,
                markets[_marketId].borrowerAttestationIds,
                markets[_marketId].verifiedBorrowersForMarket
            );
    }

    /**
     * @notice Gets addresses of all attested lenders.
     * @param _marketId The ID of a market.
     * @param _page Page index to start from.
     * @param _perPage Number of items in a page to return.
     * @return Array of addresses that have been added to a market.
     */
    function getAllVerifiedLendersForMarket(
        uint256 _marketId,
        uint256 _page,
        uint256 _perPage
    ) public view returns (address[] memory) {
        EnumerableSet.AddressSet storage set = markets[_marketId]
            .verifiedLendersForMarket;

        return _getStakeholdersForMarket(set, _page, _perPage);
    }

    /**
     * @notice Gets addresses of all attested borrowers.
     * @param _marketId The ID of the market.
     * @param _page Page index to start from.
     * @param _perPage Number of items in a page to return.
     * @return Array of addresses that have been added to a market.
     */
    function getAllVerifiedBorrowersForMarket(
        uint256 _marketId,
        uint256 _page,
        uint256 _perPage
    ) public view returns (address[] memory) {
        EnumerableSet.AddressSet storage set = markets[_marketId]
            .verifiedBorrowersForMarket;
        return _getStakeholdersForMarket(set, _page, _perPage);
    }

    /**
     * @notice Gets addresses of all attested relevant stakeholders.
     * @param _set The stored set of stakeholders to index from.
     * @param _page Page index to start from.
     * @param _perPage Number of items in a page to return.
     * @return stakeholders_ Array of addresses that have been added to a market.
     */
    function _getStakeholdersForMarket(
        EnumerableSet.AddressSet storage _set,
        uint256 _page,
        uint256 _perPage
    ) internal view returns (address[] memory stakeholders_) {
        uint256 len = _set.length();

        uint256 start = _page * _perPage;
        if (start <= len) {
            uint256 end = start + _perPage;
            // Ensure we do not go out of bounds
            if (end > len) {
                end = len;
            }

            stakeholders_ = new address[](end - start);
            for (uint256 i = start; i < end; i++) {
                stakeholders_[i] = _set.at(i);
            }
        }
    }

    /* Internal Functions */

    /**
     * @notice Adds a stakeholder (lender or borrower) to a market.
     * @param _marketId The market ID to add a borrower to.
     * @param _stakeholderAddress The address of the stakeholder to add to the market.
     * @param _expirationTime The expiration time of the attestation.
     * @param _expirationTime The expiration time of the attestation.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     */
    function _attestStakeholder(
        uint256 _marketId,
        address _stakeholderAddress,
        uint256 _expirationTime,
        bool _isLender
    )
        internal
        withAttestingSchema(
            _isLender ? lenderAttestationSchemaId : borrowerAttestationSchemaId
        )
    {
        require(
            _msgSender() == markets[_marketId].owner,
            "Not the market owner"
        );

        // Submit attestation for borrower to join a market
        bytes32 uuid = tellerAS.attest(
            _stakeholderAddress,
            _attestingSchemaId, // set by the modifier
            _expirationTime,
            0,
            abi.encode(_marketId, _stakeholderAddress)
        );
        _attestStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            uuid,
            _isLender
        );
    }

    /**
     * @notice Adds a stakeholder (lender or borrower) to a market via delegated attestation.
     * @dev The signature must match that of the market owner.
     * @param _marketId The market ID to add a lender to.
     * @param _stakeholderAddress The address of the lender to add to the market.
     * @param _expirationTime The expiration time of the attestation.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     * @param _v Signature value
     * @param _r Signature value
     * @param _s Signature value
     */
    function _attestStakeholderViaDelegation(
        uint256 _marketId,
        address _stakeholderAddress,
        uint256 _expirationTime,
        bool _isLender,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
        withAttestingSchema(
            _isLender ? lenderAttestationSchemaId : borrowerAttestationSchemaId
        )
    {
        // NOTE: block scope to prevent stack too deep!
        bytes32 uuid;
        {
            bytes memory data = abi.encode(_marketId, _stakeholderAddress);
            address attestor = markets[_marketId].owner;
            // Submit attestation for stakeholder to join a market (attestation must be signed by market owner)
            uuid = tellerAS.attestByDelegation(
                _stakeholderAddress,
                _attestingSchemaId, // set by the modifier
                _expirationTime,
                0,
                data,
                attestor,
                _v,
                _r,
                _s
            );
        }
        _attestStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            uuid,
            _isLender
        );
    }

    /**
     * @notice Adds a stakeholder (borrower/lender) to a market.
     * @param _marketId The market ID to add a stakeholder to.
     * @param _stakeholderAddress The address of the stakeholder to add to the market.
     * @param _uuid The UUID of the attestation created.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     */
    function _attestStakeholderVerification(
        uint256 _marketId,
        address _stakeholderAddress,
        bytes32 _uuid,
        bool _isLender
    ) internal {
        if (_isLender) {
            // Store the lender attestation ID for the market ID
            markets[_marketId].lenderAttestationIds[
                _stakeholderAddress
            ] = _uuid;
            // Add lender address to market set
            markets[_marketId].verifiedLendersForMarket.add(
                _stakeholderAddress
            );

            emit LenderAttestation(_marketId, _stakeholderAddress);
        } else {
            // Store the lender attestation ID for the market ID
            markets[_marketId].borrowerAttestationIds[
                _stakeholderAddress
            ] = _uuid;
            // Add lender address to market set
            markets[_marketId].verifiedBorrowersForMarket.add(
                _stakeholderAddress
            );

            emit BorrowerAttestation(_marketId, _stakeholderAddress);
        }
    }

    /**
     * @notice Removes a stakeholder from an market.
     * @dev The caller must be the market owner.
     * @param _marketId The market ID to remove the borrower from.
     * @param _stakeholderAddress The address of the borrower to remove from the market.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     */
    function _revokeStakeholder(
        uint256 _marketId,
        address _stakeholderAddress,
        bool _isLender
    ) internal {
        require(
            _msgSender() == markets[_marketId].owner,
            "Not the market owner"
        );

        bytes32 uuid = _revokeStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            _isLender
        );
        // NOTE: Disabling the call to revoke the attestation on EAS contracts
        //        tellerAS.revoke(uuid);
    }

    /**
     * @notice Removes a stakeholder from an market via delegated revocation.
     * @param _marketId The market ID to remove the borrower from.
     * @param _stakeholderAddress The address of the borrower to remove from the market.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     * @param _v Signature value
     * @param _r Signature value
     * @param _s Signature value
     */
    function _revokeStakeholderViaDelegation(
        uint256 _marketId,
        address _stakeholderAddress,
        bool _isLender,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        bytes32 uuid = _revokeStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            _isLender
        );
        // NOTE: Disabling the call to revoke the attestation on EAS contracts
        //        address attestor = markets[_marketId].owner;
        //        tellerAS.revokeByDelegation(uuid, attestor, _v, _r, _s);
    }

    /**
     * @notice Removes a stakeholder (borrower/lender) from a market.
     * @param _marketId The market ID to remove the lender from.
     * @param _stakeholderAddress The address of the stakeholder to remove from the market.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     * @return uuid_ The ID of the previously verified attestation.
     */
    function _revokeStakeholderVerification(
        uint256 _marketId,
        address _stakeholderAddress,
        bool _isLender
    ) internal returns (bytes32 uuid_) {
        if (_isLender) {
            uuid_ = markets[_marketId].lenderAttestationIds[
                _stakeholderAddress
            ];
            // Remove lender address from market set
            markets[_marketId].verifiedLendersForMarket.remove(
                _stakeholderAddress
            );

            emit LenderRevocation(_marketId, _stakeholderAddress);
        } else {
            uuid_ = markets[_marketId].borrowerAttestationIds[
                _stakeholderAddress
            ];
            // Remove borrower address from market set
            markets[_marketId].verifiedBorrowersForMarket.remove(
                _stakeholderAddress
            );

            emit BorrowerRevocation(_marketId, _stakeholderAddress);
        }
    }

    /**
     * @notice Checks if a stakeholder has been attested and added to a market.
     * @param _stakeholderAddress Address of the stakeholder to check.
     * @param _attestationRequired Stored boolean indicating if attestation is required for the stakeholder class.
     * @param _stakeholderAttestationIds Mapping of attested Ids for the stakeholder class.
     */
    function _isVerified(
        address _stakeholderAddress,
        bool _attestationRequired,
        mapping(address => bytes32) storage _stakeholderAttestationIds,
        EnumerableSet.AddressSet storage _verifiedStakeholderForMarket
    ) internal view returns (bool isVerified_, bytes32 uuid_) {
        if (_attestationRequired) {
            isVerified_ =
                _verifiedStakeholderForMarket.contains(_stakeholderAddress) &&
                tellerAS.isAttestationActive(
                    _stakeholderAttestationIds[_stakeholderAddress]
                );
            uuid_ = _stakeholderAttestationIds[_stakeholderAddress];
        } else {
            isVerified_ = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// Interfaces
import "./interfaces/IReputationManager.sol";
import "./interfaces/ITellerV2.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// Libraries
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ReputationManager is IReputationManager, Initializable {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant CONTROLLER = keccak256("CONTROLLER");

    ITellerV2 public tellerV2;
    mapping(address => EnumerableSet.UintSet) private _delinquencies;
    mapping(address => EnumerableSet.UintSet) private _defaults;
    mapping(address => EnumerableSet.UintSet) private _currentDelinquencies;
    mapping(address => EnumerableSet.UintSet) private _currentDefaults;

    event MarkAdded(
        address indexed account,
        RepMark indexed repMark,
        uint256 bidId
    );
    event MarkRemoved(
        address indexed account,
        RepMark indexed repMark,
        uint256 bidId
    );

    /**
     * @notice Initializes the proxy.
     */
    function initialize(address _tellerV2) external initializer {
        tellerV2 = ITellerV2(_tellerV2);
    }

    function getDelinquentLoanIds(address _account)
        public
        override
        returns (uint256[] memory)
    {
        updateAccountReputation(_account);
        return _delinquencies[_account].values();
    }

    function getDefaultedLoanIds(address _account)
        public
        override
        returns (uint256[] memory)
    {
        updateAccountReputation(_account);
        return _defaults[_account].values();
    }

    function getCurrentDelinquentLoanIds(address _account)
        public
        override
        returns (uint256[] memory)
    {
        updateAccountReputation(_account);
        return _currentDelinquencies[_account].values();
    }

    function getCurrentDefaultLoanIds(address _account)
        public
        override
        returns (uint256[] memory)
    {
        updateAccountReputation(_account);
        return _currentDefaults[_account].values();
    }

    function updateAccountReputation(address _account) public override {
        uint256[] memory activeBidIds = tellerV2.getBorrowerActiveLoanIds(
            _account
        );
        for (uint256 i; i < activeBidIds.length; i++) {
            _applyReputation(_account, activeBidIds[i]);
        }
    }

    function updateAccountReputation(address _account, uint256 _bidId)
        public
        override
        returns (RepMark)
    {
        return _applyReputation(_account, _bidId);
    }

    function _applyReputation(address _account, uint256 _bidId)
        internal
        returns (RepMark mark_)
    {
        mark_ = RepMark.Good;

        if (tellerV2.isLoanDefaulted(_bidId)) {
            mark_ = RepMark.Default;

            // Remove delinquent status
            _removeMark(_account, _bidId, RepMark.Delinquent);
        } else if (tellerV2.isPaymentLate(_bidId)) {
            mark_ = RepMark.Delinquent;
        }

        // Mark status if not "Good"
        if (mark_ != RepMark.Good) {
            _addMark(_account, _bidId, mark_);
        }
    }

    function _addMark(
        address _account,
        uint256 _bidId,
        RepMark _mark
    ) internal {
        if (_mark == RepMark.Delinquent) {
            _delinquencies[_account].add(_bidId);
            _currentDelinquencies[_account].add(_bidId);
        } else if (_mark == RepMark.Default) {
            _defaults[_account].add(_bidId);
            _currentDefaults[_account].add(_bidId);
        }

        emit MarkAdded(_account, _mark, _bidId);
    }

    function _removeMark(
        address _account,
        uint256 _bidId,
        RepMark _mark
    ) internal {
        if (_mark == RepMark.Delinquent) {
            _currentDelinquencies[_account].remove(_bidId);
        } else if (_mark == RepMark.Default) {
            _currentDefaults[_account].remove(_bidId);
        }

        emit MarkRemoved(_account, _mark, _bidId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./interfaces/IMarketRegistry.sol";
import "./interfaces/IReputationManager.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract TellerV2Storage_G0 {
    enum BidState {
        NONEXISTENT,
        PENDING,
        CANCELLED,
        ACCEPTED,
        PAID,
        LIQUIDATED
    }

    /**
     * @notice Represents a total amount for a payment.
     * @param principal Amount that counts towards the principal.
     * @param interest  Amount that counts toward interest.
     */
    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    /**
     * @notice Details about the loan.
     * @param lendingToken The token address for the loan.
     * @param principal The amount of tokens initially lent out.
     * @param totalRepaid Payment struct that represents the total principal and interest amount repaid.
     * @param timestamp Timestamp, in seconds, of when the bid was submitted by the borrower.
     * @param acceptedTimestamp Timestamp, in seconds, of when the bid was accepted by the lender.
     * @param lastRepaidTimestamp Timestamp, in seconds, of when the last payment was made
     * @param loanDuration The duration of the loan.
     */
    struct LoanDetails {
        ERC20 lendingToken;
        uint256 principal;
        Payment totalRepaid;
        uint32 timestamp;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        uint32 loanDuration;
    }

    /**
     * @notice Details about a loan request.
     * @param borrower Account address who is requesting a loan.
     * @param receiver Account address who will receive the loan amount.
     * @param lender Account address who accepted and funded the loan request.
     * @param marketplaceId ID of the marketplace the bid was submitted to.
     * @param metadataURI ID of off chain metadata to find additional information of the loan request.
     * @param loanDetails Struct of the specific loan details.
     * @param terms Struct of the loan request terms.
     * @param state Represents the current state of the loan.
     */
    struct Bid {
        address borrower;
        address receiver;
        address lender;
        uint256 marketplaceId;
        bytes32 _metadataURI; // DEPRECATED
        LoanDetails loanDetails;
        Terms terms;
        BidState state;
        V2Calculations.PaymentType paymentType;
    }

    /**
     * @notice Information on the terms of a loan request
     * @param paymentCycleAmount Value of tokens expected to be repaid every payment cycle.
     * @param paymentCycle Duration, in seconds, of how often a payment must be made.
     * @param APR Annual percentage rating to be applied on repayments. (10000 == 100%)
     */
    struct Terms {
        uint256 paymentCycleAmount;
        uint32 paymentCycle;
        uint16 APR;
    }

    /** Storage Variables */

    // Current number of bids.
    uint256 public bidId = 0;

    // Mapping of bidId to bid information.
    mapping(uint256 => Bid) public bids;

    // Mapping of borrowers to borrower requests.
    mapping(address => uint256[]) public borrowerBids;

    // Mapping of volume filled by lenders.
    mapping(address => uint256) public _lenderVolumeFilled; // DEPRECIATED

    // Volume filled by all lenders.
    uint256 public _totalVolumeFilled; // DEPRECIATED

    // List of allowed lending tokens
    EnumerableSet.AddressSet internal lendingTokensSet;

    IMarketRegistry public marketRegistry;
    IReputationManager public reputationManager;

    // Mapping of borrowers to borrower requests.
    mapping(address => EnumerableSet.UintSet) internal _borrowerBidsActive;

    mapping(uint256 => uint32) public bidDefaultDuration;
    mapping(uint256 => uint32) public bidExpirationTime;

    // Mapping of volume filled by lenders.
    // Asset address => Lender address => Volume amount
    mapping(address => mapping(address => uint256)) public lenderVolumeFilled;

    // Volume filled by all lenders.
    // Asset address => Volume amount
    mapping(address => uint256) public totalVolumeFilled;

    uint256 public version;

    // Mapping of metadataURIs by bidIds.
    // Bid Id => metadataURI string
    mapping(uint256 => string) public uris;
}

abstract contract TellerV2Storage_G1 is TellerV2Storage_G0 {
    // market ID => trusted forwarder
    mapping(uint256 => address) internal _trustedMarketForwarders;
    // trusted forwarder => set of pre-approved senders
    mapping(address => EnumerableSet.AddressSet)
        internal _approvedForwarderSenders;
}

abstract contract TellerV2Storage_G2 is TellerV2Storage_G1 {
    address public lenderCommitmentForwarder;
}

abstract contract TellerV2Storage is TellerV2Storage_G2 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { V2Calculations } from "../TellerV2.sol";
import "../EAS/TellerAS.sol";

interface IMarketRegistry {
    function initialize(TellerAS tellerAs) external;

    function isVerifiedLender(uint256 _marketId, address _lender)
        external
        returns (bool, bytes32);

    function isMarketClosed(uint256 _marketId) external returns (bool);

    function isVerifiedBorrower(uint256 _marketId, address _borrower)
        external
        returns (bool, bytes32);

    function getMarketOwner(uint256 _marketId) external returns (address);

    function getMarketFeeRecipient(uint256 _marketId)
        external
        returns (address);

    function getMarketURI(uint256 _marketId) external returns (string memory);

    function getPaymentCycleDuration(uint256 _marketId)
        external
        returns (uint32);

    function getPaymentDefaultDuration(uint256 _marketId)
        external
        returns (uint32);

    function getBidExpirationTime(uint256 _marketId) external returns (uint32);

    function getMarketplaceFee(uint256 _marketId) external returns (uint16);

    function getPaymentType(uint256 _marketId)
        external
        view
        returns (V2Calculations.PaymentType);

    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        V2Calculations.PaymentType _paymentType,
        string calldata _uri
    ) external returns (uint256 marketId_);

    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        string calldata _uri
    ) external returns (uint256 marketId_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum RepMark {
    Good,
    Delinquent,
    Default
}

interface IReputationManager {
    function initialize(address protocolAddress) external;

    function getDelinquentLoanIds(address _account)
        external
        returns (uint256[] memory);

    function getDefaultedLoanIds(address _account)
        external
        returns (uint256[] memory);

    function getCurrentDelinquentLoanIds(address _account)
        external
        returns (uint256[] memory);

    function getCurrentDefaultLoanIds(address _account)
        external
        returns (uint256[] memory);

    function updateAccountReputation(address _account) external;

    function updateAccountReputation(address _account, uint256 _bidId)
        external
        returns (RepMark);
}

/**
 *Submitted for verification at Etherscan.io on 2017-12-12
 */

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract WethMock {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "insufficient balance");

        if (src != msg.sender) {
            require(
                allowance[src][msg.sender] >= wad,
                "insufficient allowance"
            );
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../TellerV2.sol";
import "../interfaces/ITellerV2.sol";
import "../TellerV2Context.sol";

/*
This is only used for sol test so its named specifically to avoid being used for the typescript tests.
*/
contract TellerV2SolMock is ITellerV2, TellerV2Storage {
    function setMarketRegistry(address _marketRegistry) public {
        marketRegistry = IMarketRegistry(_marketRegistry);
    }

    function submitBid(
        address _lendingToken,
        uint256 _marketId,
        uint256 _principal,
        uint32 _duration,
        uint16,
        string calldata,
        address _receiver
    ) public returns (uint256 bidId_) {
        bidId_ = bidId;

        Bid storage bid = bids[bidId];
        bid.borrower = msg.sender;
        bid.receiver = _receiver != address(0) ? _receiver : bid.borrower;
        bid.marketplaceId = _marketId;
        bid.loanDetails.lendingToken = ERC20(_lendingToken);
        bid.loanDetails.principal = _principal;
        bid.loanDetails.loanDuration = _duration;
        bid.loanDetails.timestamp = uint32(block.timestamp);

        bidId++;
    }

    function repayLoanMinimum(uint256 _bidId) external {}

    function repayLoanFull(uint256 _bidId) external {}

    function repayLoan(uint256 _bidId, uint256 _amount) public {
        Bid storage bid = bids[_bidId];

        IERC20(bid.loanDetails.lendingToken).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    /*
     * @notice Calculates the minimum payment amount due for a loan.
     * @param _bidId The id of the loan bid to get the payment amount for.
     */
    function calculateAmountDue(uint256 _bidId)
        public
        view
        returns (Payment memory due)
    {
        if (bids[_bidId].state != BidState.ACCEPTED) return due;

        (, uint256 duePrincipal, uint256 interest) = V2Calculations
            .calculateAmountOwed(bids[_bidId], block.timestamp);
        due.principal = duePrincipal;
        due.interest = interest;
    }

    /**
     * @notice Calculates the minimum payment amount due for a loan at a specific timestamp.
     * @param _bidId The id of the loan bid to get the payment amount for.
     * @param _timestamp The timestamp at which to get the due payment at.
     */
    function calculateAmountDue(uint256 _bidId, uint256 _timestamp)
        public
        view
        returns (Payment memory due)
    {
        Bid storage bid = bids[_bidId];
        if (
            bids[_bidId].state != BidState.ACCEPTED ||
            bid.loanDetails.acceptedTimestamp >= _timestamp
        ) return due;

        (, uint256 duePrincipal, uint256 interest) = V2Calculations
            .calculateAmountOwed(bid, _timestamp);
        due.principal = duePrincipal;
        due.interest = interest;
    }

    function lenderAcceptBid(uint256 _bidId)
        public
        returns (
            uint256 amountToProtocol,
            uint256 amountToMarketplace,
            uint256 amountToBorrower
        )
    {
        Bid storage bid = bids[_bidId];

        bid.lender = msg.sender;

        //send tokens to caller
        IERC20(bid.loanDetails.lendingToken).transferFrom(
            bid.lender,
            bid.receiver,
            bid.loanDetails.principal
        );
        //for the reciever

        return (0, bid.loanDetails.principal, 0);
    }

    function getBidState(uint256 _bidId)
        public
        view
        returns (TellerV2Storage.BidState)
    {
        return bids[_bidId].state;
    }

    function getLoanDetails(uint256 _bidId)
        public
        view
        returns (TellerV2Storage.LoanDetails memory)
    {
        return bids[_bidId].loanDetails;
    }

    function getBorrowerActiveLoanIds(address _borrower)
        public
        view
        returns (uint256[] memory)
    {}

    function isLoanDefaulted(uint256 _bidId) public view returns (bool) {}

    function isPaymentLate(uint256 _bidId) public view returns (bool) {}

    function getLoanBorrower(uint256 _bidId)
        external
        view
        returns (address borrower_)
    {
        borrower_ = bids[_bidId].borrower;
    }

    function getLoanLender(uint256 _bidId)
        external
        view
        returns (address lender_)
    {
        lender_ = bids[_bidId].lender;
    }

    function getLoanLendingToken(uint256 _bidId)
        external
        view
        returns (address token_)
    {
        token_ = address(bids[_bidId].loanDetails.lendingToken);
    }

    function setLastRepaidTimestamp(uint256 _bidId, uint32 _timestamp) public {
        bids[_bidId].loanDetails.lastRepaidTimestamp = _timestamp;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "../interfaces/IMarketRegistry.sol";

contract MarketRegistryMock is IMarketRegistry {
    address marketOwner;

    function initialize(TellerAS _tellerAS) external {}

    function isVerifiedLender(uint256 _marketId, address _lenderAddress)
        public
        returns (bool isVerified_, bytes32 uuid_)
    {
        isVerified_ = true;
    }

    function isMarketClosed(uint256 _marketId) public returns (bool) {
        return false;
    }

    function isVerifiedBorrower(uint256 _marketId, address _borrower)
        public
        returns (bool isVerified_, bytes32 uuid_)
    {
        isVerified_ = true;
    }

    function getMarketOwner(uint256 _marketId) public returns (address) {
        return address(marketOwner);
    }

    function getMarketFeeRecipient(uint256 _marketId) public returns (address) {
        return address(marketOwner);
    }

    function getMarketURI(uint256 _marketId) public returns (string memory) {
        return "url://";
    }

    function getPaymentCycleDuration(uint256 _marketId)
        public
        returns (uint32)
    {
        return 1000;
    }

    function getPaymentDefaultDuration(uint256 _marketId)
        public
        returns (uint32)
    {
        return 1000;
    }

    function getBidExpirationTime(uint256 _marketId) public returns (uint32) {
        return 1000;
    }

    function getMarketplaceFee(uint256 _marketId) public returns (uint16) {
        return 1000;
    }

    function setMarketOwner(address _owner) public {
        marketOwner = _owner;
    }

    function getPaymentType(uint256 _marketId)
        public
        view
        returns (V2Calculations.PaymentType)
    {}

    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        V2Calculations.PaymentType _paymentType,
        string calldata _uri
    ) public returns (uint256) {}

    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        string calldata _uri
    ) public returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice It is the interface of functions that we use for the canonical WETH contract.
 *
 * @author [email protected]
 */
interface IWETH {
    /**
     * @notice It withdraws ETH from the contract by sending it to the caller and reducing the caller's internal balance of WETH.
     * @param amount The amount of ETH to withdraw.
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice It deposits ETH into the contract and increases the caller's internal balance of WETH.
     */
    function deposit() external payable;

    /**
     * @notice It gets the ETH deposit balance of an {account}.
     * @param account Address to get balance of.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice It transfers the WETH amount specified to the given {account}.
     * @param to Address to transfer to
     * @param value Amount of WETH to transfer
     */
    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITellerV2Autopay {
    function setAutoPayEnabled(uint256 _bidId, bool _autoPayEnabled) external;

    function autoPayLoanMinimum(uint256 _bidId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// Should be kept in sync with ./lib.js

library Test {
  /* 
   * Expect events from contracts
   */
  event ExpectFrom(address from);
  event StopExpecting();

  // Usage: from a test contract `t`, call `expectFrom(a)`. 
  // Any subsequent non-special event emitted by `t` will mean 
  // "I expect `a` to emit the exact same event". 
  // The order of expectations must be respected.
  function expectFrom(address from) internal {
    emit ExpectFrom(from);
  }

  // After using `expectFrom` and emitting some events you expect
  // to see emitted elsewhere, you can use `stopExpecting` to emit 
  // further, normal events from your test.
  function stopExpecting() internal {
    emit StopExpecting();
  }


  /* 
   * Boolean test
   */
  event TestTrue(bool success, string message);

  // Succeed iff success is true
  function check(bool success, string memory message) internal {
    emit TestTrue(success, message);
  }


  /* 
   * Always fail, always succeed
   */
  function fail(string memory message) internal {
    emit TestTrue(false, message);
  }

  function succeed() internal {
    emit TestTrue(true, "Success");
  }

  /* 
   * Equality testing
   * ! overloaded as `eq` for everything except for bytes use `eq0`.
   */

  // Bytes
  event TestEqBytes(bool success, bytes actual, bytes expected, string message);

  function eq0(
    bytes memory actual,
    bytes memory expected,
    string memory message
  ) internal returns (bool) {
    bool success = keccak256((actual)) == keccak256((expected));
    emit TestEqBytes(success, actual, expected, message);
    return success;
  }

   // Byte32
  event TestEqBytes32(
    bool success,
    bytes32 actual,
    bytes32 expected,
    string message
  );

  function eq(
    bytes32 actual,
    bytes32 expected,
    string memory message
  ) internal returns (bool) {
    bool success = (actual == expected);
    emit TestEqBytes32(success, actual, expected, message);
    return success;
  }

  // Bool
  event TestEqBool(bool success, bool actual, bool expected, string message);
  function eq(
    bool actual,
    bool expected,
    string memory message
  ) internal returns (bool) {
    bool success = (actual == expected);
    emit TestEqBool(success, actual, expected, message);
    return success;
  }

  // uints
  event TestEqUint(bool success, uint actual, uint expected, string message);

  function eq(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual == expected;
    emit TestEqUint(success, actual, expected, message);
    return success;
  }

  // strings
  event TestEqString(
    bool success,
    string actual,
    string expected,
    string message
  );

  function eq(
    string memory actual,
    string memory expected,
    string memory message
  ) internal returns (bool) {
    bool success = keccak256(bytes((actual))) == keccak256(bytes((expected)));
    emit TestEqString(success, actual, expected, message);
    return success;
  }

  // addresses
  event TestEqAddress(
    bool success,
    address actual,
    address expected,
    string message
  );


  function eq(
    address actual,
    address expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual == expected;
    emit TestEqAddress(success, actual, expected, message);
    return success;
  }

  /* 
   * Inequality testing
   */
  event TestLess(bool success, uint actual, uint expected, string message);
  function less(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual < expected;
    emit TestLess(success, actual, expected, message);
    return success;
  }

  event TestLessEq(bool success, uint actual, uint expected, string message);
  function lessEq(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual <= expected;
    emit TestLessEq(success, actual, expected, message);
    return success;
  }

  event TestMore(bool success, uint actual, uint expected, string message);
  function more(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual > expected;
    emit TestMore(success, actual, expected, message);
    return success;
  }

  event TestMoreEq(bool success, uint actual, uint expected, string message);
  function moreEq(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual >= expected;
    emit TestMoreEq(success, actual, expected, message);
    return success;
  }
}

// /* Either cast your arguments to address when you call balanceOf logging functions
//    or add `is address` to your ERC20s
//    or use the overloads with `address` types */
interface ERC20BalanceOf {
  function balanceOf(address account) view external returns (uint);
}


library Display {
  /* ****************************************************************
   * Register/read address->name mappings to make logs easier to read.
   *****************************************************************/
  /* 
   * Names are stored in the contract using the library.
   */

  // Disgusting hack so a library can manipulate storage refs.
  bytes32 constant NAMES_POS = keccak256("Display.NAMES_POS");
  // Store mapping in library caller's storage.
  // That's quite fragile.
  struct Registers {
    mapping(address => string) map;
  }

  // Also send mapping to javascript test interpreter.  The interpreter COULD
  // just make an EVM call to map every name but that would probably be very
  // slow.  So we cache locally.
  event Register(address addr, string name);

  function registers() internal view returns (Registers storage) {
    this; // silence warning about pure mutability
    Registers storage regs;
    bytes32 _slot = NAMES_POS;
    assembly {
      regs.slot := _slot
    }
    return regs;
  }

  /*
   * Give a name to an address for logging purposes
   * @example
   * ```solidity
   * address addr = address(new Contract());
   * register(addr,"My Contract instance");
   * ```
   */

  function register(address addr, string memory name) internal {
    registers().map[addr] = name;
    emit Register(addr, name);
  }

  /*
   * Read the name of a registered address. Default: "<not found>". 
   */
  function nameOf(address addr) internal view returns (string memory) {
    string memory s = registers().map[addr];
    if (keccak256(bytes(s)) != keccak256(bytes(""))) {
      return s;
    } else {
      return "<not found>";
    }
  }

  /* 1 arg logging (string/uint) */

  event LogString(string a);

  function log(string memory a) internal {
    emit LogString(a);
  }

  event LogUint(uint a);

  function log(uint a) internal {
    emit LogUint(a);
  }

  /* 2 arg logging (string/uint) */

  event LogStringString(string a, string b);

  function log(string memory a, string memory b) internal {
    emit LogStringString(a, b);
  }

  event LogStringUint(string a, uint b);

  function log(string memory a, uint b) internal {
    emit LogStringUint(a, b);
  }

  event LogUintUint(uint a, uint b);

  function log(uint a, uint b) internal {
    emit LogUintUint(a, b);
  }

  event LogUintString(uint a, string b);

  function log(uint a, string memory b) internal {
    emit LogUintString(a, b);
  }

  /* 3 arg logging (string/uint) */

  event LogStringStringString(string a, string b, string c);

  function log(
    string memory a,
    string memory b,
    string memory c
  ) internal {
    emit LogStringStringString(a, b, c);
  }

  event LogStringStringUint(string a, string b, uint c);

  function log(
    string memory a,
    string memory b,
    uint c
  ) internal {
    emit LogStringStringUint(a, b, c);
  }

  event LogStringUintUint(string a, uint b, uint c);

  function log(
    string memory a,
    uint b,
    uint c
  ) internal {
    emit LogStringUintUint(a, b, c);
  }

  event LogStringUintString(string a, uint b, string c);

  function log(
    string memory a,
    uint b,
    string memory c
  ) internal {
    emit LogStringUintString(a, b, c);
  }

  event LogUintUintUint(uint a, uint b, uint c);

  function log(
    uint a,
    uint b,
    uint c
  ) internal {
    emit LogUintUintUint(a, b, c);
  }

  event LogUintStringUint(uint a, string b, uint c);

  function log(
    uint a,
    string memory b,
    uint c
  ) internal {
    emit LogUintStringUint(a, b, c);
  }

  event LogUintStringString(uint a, string b, string c);

  function log(
    uint a,
    string memory b,
    string memory c
  ) internal {
    emit LogUintStringString(a, b, c);
  }

  /* End of register/read section */
  event ERC20Balances(address[] tokens, address[] accounts, uint[] balances);

  function logBalances(
    address[1] memory _tokens, 
    address _a0
  ) internal {
    address[] memory tokens = new address[](1);
    tokens[0] = _tokens[0];
    address[] memory accounts = new address[](1);
    accounts[0] = _a0;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[1] memory _tokens,
    address _a0,
    address _a1
  ) internal {
    address[] memory tokens = new address[](1);
    tokens[0] = _tokens[0];
    address[] memory accounts = new address[](2);
    accounts[0] = _a0;
    accounts[1] = _a1;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[1] memory _tokens,
    address _a0,
    address _a1,
    address _a2
  ) internal {
    address[] memory tokens = new address[](1);
    tokens[0] = _tokens[0];
    address[] memory accounts = new address[](3);
    accounts[0] = _a0;
    accounts[1] = _a1;
    accounts[2] = _a2;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[2] memory _tokens,
    address _a0
  ) internal {
    address[] memory tokens = new address[](2);
    tokens[0] = _tokens[0];
    tokens[1] = _tokens[1];
    address[] memory accounts = new address[](1);
    accounts[0] = _a0;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[2] memory _tokens,
    address _a0,
    address _a1
  ) internal {
    address[] memory tokens = new address[](2);
    tokens[0] = _tokens[0];
    tokens[1] = _tokens[1];
    address[] memory accounts = new address[](2);
    accounts[0] = _a0;
    accounts[1] = _a1;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[2] memory _tokens,
    address _a0,
    address _a1,
    address _a2
  ) internal {
    address[] memory tokens = new address[](2);
    tokens[0] = _tokens[0];
    tokens[1] = _tokens[1];
    address[] memory accounts = new address[](3);
    accounts[0] = _a0;
    accounts[1] = _a1;
    accounts[2] = _a2;
    logBalances(tokens, accounts);
  }

  /* takes [t1,...,tM], [a1,...,aN]
       logs also [...b(t1,aj) ... b(tM,aj) ...] */

  function logBalances(address[] memory tokens, address[] memory accounts)
    internal
  {
    uint[] memory balances = new uint[](tokens.length * accounts.length);
    for (uint i = 0; i < tokens.length; i++) {
      for (uint j = 0; j < accounts.length; j++) {
        uint bal = ERC20BalanceOf(tokens[i]).balanceOf(accounts[j]);
        balances[i * accounts.length + j] = bal;
        //console.log(tokens[i].symbol(),nameOf(accounts[j]),bal);
      }
    }
    emit ERC20Balances(tokens, accounts, balances);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../TellerV2Storage.sol";

interface ITellerV2 {
    /**
     * @notice Function for a borrower to create a bid for a loan.
     * @param _lendingToken The lending token asset requested to be borrowed.
     * @param _marketplaceId The unique id of the marketplace for the bid.
     * @param _principal The principal amount of the loan bid.
     * @param _duration The recurrent length of time before which a payment is due.
     * @param _APR The proposed interest rate for the loan bid.
     * @param _metadataURI The URI for additional borrower loan information as part of loan bid.
     * @param _receiver The address where the loan amount will be sent to.
     */
    function submitBid(
        address _lendingToken,
        uint256 _marketplaceId,
        uint256 _principal,
        uint32 _duration,
        uint16 _APR,
        string calldata _metadataURI,
        address _receiver
    ) external returns (uint256 bidId_);

    /**
     * @notice Function for a lender to accept a proposed loan bid.
     * @param _bidId The id of the loan bid to accept.
     */
    function lenderAcceptBid(uint256 _bidId)
        external
        returns (
            uint256 amountToProtocol,
            uint256 amountToMarketplace,
            uint256 amountToBorrower
        );

    function calculateAmountDue(uint256 _bidId)
        external
        view
        returns (TellerV2Storage.Payment memory due);

    /**
     * @notice Function for users to make the minimum amount due for an active loan.
     * @param _bidId The id of the loan to make the payment towards.
     */
    function repayLoanMinimum(uint256 _bidId) external;

    /**
     * @notice Function for users to repay an active loan in full.
     * @param _bidId The id of the loan to make the payment towards.
     */
    function repayLoanFull(uint256 _bidId) external;

    /**
     * @notice Function for users to make a payment towards an active loan.
     * @param _bidId The id of the loan to make the payment towards.
     * @param _amount The amount of the payment.
     */
    function repayLoan(uint256 _bidId, uint256 _amount) external;

    /**
     * @notice Checks to see if a borrower is delinquent.
     * @param _bidId The id of the loan bid to check for.
     */
    function isLoanDefaulted(uint256 _bidId) external view returns (bool);

    /**
     * @notice Checks to see if a borrower is delinquent.
     * @param _bidId The id of the loan bid to check for.
     */
    function isPaymentLate(uint256 _bidId) external view returns (bool);

    function getBidState(uint256 _bidId)
        external
        view
        returns (TellerV2Storage.BidState);

    function getBorrowerActiveLoanIds(address _borrower)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Returns the borrower address for a given bid.
     * @param _bidId The id of the bid/loan to get the borrower for.
     * @return borrower_ The address of the borrower associated with the bid.
     */
    function getLoanBorrower(uint256 _bidId)
        external
        view
        returns (address borrower_);

    /**
     * @notice Returns the lender address for a given bid.
     * @param _bidId The id of the bid/loan to get the lender for.
     * @return lender_ The address of the lender associated with the bid.
     */
    function getLoanLender(uint256 _bidId)
        external
        view
        returns (address lender_);

    function getLoanLendingToken(uint256 _bidId)
        external
        view
        returns (address token_);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// Contracts
import "./ProtocolFee.sol";
import "./TellerV2Storage.sol";
import "./TellerV2Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

// Interfaces
import "./interfaces/IMarketRegistry.sol";
import "./interfaces/IReputationManager.sol";
import "./interfaces/ITellerV2.sol";

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/NumbersLib.sol";

/* Errors */
/**
 * @notice This error is reverted when the action isn't allowed
 * @param bidId The id of the bid.
 * @param action The action string (i.e: 'repayLoan', 'cancelBid', 'etc)
 * @param message The message string to return to the user explaining why the tx was reverted
 */
error ActionNotAllowed(uint256 bidId, string action, string message);

/**
 * @notice This error is reverted when repayment amount is less than the required minimum
 * @param bidId The id of the bid the borrower is attempting to repay.
 * @param payment The payment made by the borrower
 * @param minimumOwed The minimum owed value
 */
error PaymentNotMinimum(uint256 bidId, uint256 payment, uint256 minimumOwed);

contract TellerV2 is
    ITellerV2,
    OwnableUpgradeable,
    ProtocolFee,
    PausableUpgradeable,
    TellerV2Storage,
    TellerV2Context
{
    using Address for address;
    using SafeERC20 for ERC20;
    using NumbersLib for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /** Events */

    /**
     * @notice This event is emitted when a new bid is submitted.
     * @param bidId The id of the bid submitted.
     * @param borrower The address of the bid borrower.
     * @param metadataURI URI for additional bid information as part of loan bid.
     */
    event SubmittedBid(
        uint256 indexed bidId,
        address indexed borrower,
        address receiver,
        bytes32 indexed metadataURI
    );

    /**
     * @notice This event is emitted when a bid has been accepted by a lender.
     * @param bidId The id of the bid accepted.
     * @param lender The address of the accepted bid lender.
     */
    event AcceptedBid(uint256 indexed bidId, address indexed lender);

    /**
     * @notice This event is emitted when a previously submitted bid has been cancelled.
     * @param bidId The id of the cancelled bid.
     */
    event CancelledBid(uint256 indexed bidId);

    /**
     * @notice This event is emitted when market owner has cancelled a pending bid in their market.
     * @param bidId The id of the bid funded.
     *
     * Note: The `CancelledBid` event will also be emitted.
     */
    event MarketOwnerCancelledBid(uint256 indexed bidId);

    /**
     * @notice This event is emitted when a payment is made towards an active loan.
     * @param bidId The id of the bid/loan to which the payment was made.
     */
    event LoanRepayment(uint256 indexed bidId);

    /**
     * @notice This event is emitted when a loan has been fully repaid.
     * @param bidId The id of the bid/loan which was repaid.
     */
    event LoanRepaid(uint256 indexed bidId);

    /**
     * @notice This event is emitted when a loan has been fully repaid.
     * @param bidId The id of the bid/loan which was repaid.
     */
    event LoanLiquidated(uint256 indexed bidId, address indexed liquidator);

    /**
     * @notice This event is emitted when a fee has been paid related to a bid.
     * @param bidId The id of the bid.
     * @param feeType The name of the fee being paid.
     * @param amount The amount of the fee being paid.
     */
    event FeePaid(
        uint256 indexed bidId,
        string indexed feeType,
        uint256 indexed amount
    );

    /** Modifiers */

    /**
     * @notice This modifier is used to check if the state of a bid is pending, before running an action.
     * @param _bidId The id of the bid to check the state for.
     * @param _action The desired action to run on the bid.
     */
    modifier pendingBid(uint256 _bidId, string memory _action) {
        if (bids[_bidId].state != BidState.PENDING) {
            revert ActionNotAllowed(_bidId, _action, "Bid must be pending");
        }

        _;
    }

    /**
     * @notice This modifier is used to check if the state of a loan has been accepted, before running an action.
     * @param _bidId The id of the bid to check the state for.
     * @param _action The desired action to run on the bid.
     */
    modifier acceptedLoan(uint256 _bidId, string memory _action) {
        if (bids[_bidId].state != BidState.ACCEPTED) {
            revert ActionNotAllowed(_bidId, _action, "Loan must be accepted");
        }

        _;
    }

    /** Constant Variables **/

    uint256 public constant CURRENT_CODE_VERSION = 7;

    /** Constructor **/

    constructor(address trustedForwarder) TellerV2Context(trustedForwarder) {}

    /** External Functions **/

    /**
     * @notice Initializes the proxy.
     * @param _protocolFee The fee collected by the protocol for loan processing.
     * @param _lendingTokens The list of tokens allowed as lending assets on the protocol.
     */
    function initialize(
        uint16 _protocolFee,
        address _marketRegistry,
        address _reputationManager,
        address _lenderCommitmentForwarder,
        address[] calldata _lendingTokens
    ) external initializer {
        __ProtocolFee_init(_protocolFee);

        __Pausable_init();

        lenderCommitmentForwarder = _lenderCommitmentForwarder;
        marketRegistry = IMarketRegistry(_marketRegistry);
        reputationManager = IReputationManager(_reputationManager);

        require(_lendingTokens.length > 0, "No lending tokens specified");
        for (uint256 i = 0; i < _lendingTokens.length; i++) {
            require(
                _lendingTokens[i].isContract(),
                "lending token not contract"
            );
            addLendingToken(_lendingTokens[i]);
        }
    }

    function onUpgrade() external {
        require(
            version != CURRENT_CODE_VERSION,
            "Contract already upgraded to latest version!"
        );
        version = CURRENT_CODE_VERSION;
    }

    /**
     * @notice Gets the metadataURI for a bidId.
     * @param _bidId The id of the bid to return the metadataURI for
     * @return metadataURI_ The metadataURI for the bid, as a string.
     */
    function getMetadataURI(uint256 _bidId)
        public
        view
        returns (string memory metadataURI_)
    {
        // Check uri mapping first
        metadataURI_ = uris[_bidId];
        // If the URI is not present in the mapping
        if (
            keccak256(abi.encodePacked(metadataURI_)) ==
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 // hardcoded constant of keccak256('')
        ) {
            // Return depreciated bytes32 uri as a string
            uint256 convertedURI = uint256(bids[_bidId]._metadataURI);
            metadataURI_ = StringsUpgradeable.toHexString(convertedURI, 32);
        }
    }

    /**
     * @notice Lets the DAO/owner of the protocol to set a new reputation manager contract.
     * @param _reputationManager The new contract address.
     */
    function setReputationManager(address _reputationManager) public onlyOwner {
        reputationManager = IReputationManager(_reputationManager);
    }

    /**
     * @notice Function for a borrower to create a bid for a loan.
     * @param _lendingToken The lending token asset requested to be borrowed.
     * @param _marketplaceId The unique id of the marketplace for the bid.
     * @param _principal The principal amount of the loan bid.
     * @param _duration The recurrent length of time before which a payment is due.
     * @param _APR The proposed interest rate for the loan bid.
     * @param _metadataURI The URI for additional borrower loan information as part of loan bid.
     * @param _receiver The address where the loan amount will be sent to.
     */
    function submitBid(
        address _lendingToken,
        uint256 _marketplaceId,
        uint256 _principal,
        uint32 _duration,
        uint16 _APR,
        string calldata _metadataURI,
        address _receiver
    ) public override whenNotPaused returns (uint256 bidId_) {
        address sender = _msgSenderForMarket(_marketplaceId);
        (bool isVerified, ) = marketRegistry.isVerifiedBorrower(
            _marketplaceId,
            sender
        );
        require(isVerified, "Not verified borrower");
        require(
            !marketRegistry.isMarketClosed(_marketplaceId),
            "Market is closed"
        );
        require(
            lendingTokensSet.contains(_lendingToken),
            "Lending token not authorized"
        );

        // Set response bid ID.
        bidId_ = bidId;

        // Create and store our bid into the mapping
        Bid storage bid = bids[bidId];
        bid.borrower = sender;
        bid.receiver = _receiver != address(0) ? _receiver : bid.borrower;
        bid.marketplaceId = _marketplaceId;
        bid.loanDetails.lendingToken = ERC20(_lendingToken);
        bid.loanDetails.principal = _principal;
        bid.loanDetails.loanDuration = _duration;
        bid.loanDetails.timestamp = uint32(block.timestamp);

        bid.terms.paymentCycle = marketRegistry.getPaymentCycleDuration(
            _marketplaceId
        );
        bid.terms.APR = _APR;

        bidDefaultDuration[bidId] = marketRegistry.getPaymentDefaultDuration(
            _marketplaceId
        );

        bidExpirationTime[bidId] = marketRegistry.getBidExpirationTime(
            _marketplaceId
        );

        bid.paymentType = marketRegistry.getPaymentType(_marketplaceId);

        bid.terms.paymentCycleAmount = V2Calculations
            .calculatePaymentCycleAmount(
                bid.paymentType,
                _principal,
                _duration,
                bid.terms.paymentCycle,
                _APR
            );

        uris[bidId] = _metadataURI;
        bid.state = BidState.PENDING;

        emit SubmittedBid(
            bidId,
            bid.borrower,
            bid.receiver,
            keccak256(abi.encodePacked(_metadataURI))
        );

        // Store bid inside borrower bids mapping
        borrowerBids[bid.borrower].push(bidId);

        // Increment bid id counter
        bidId++;
    }

    /**
     * @notice Function for a borrower to cancel their pending bid.
     * @param _bidId The id of the bid to cancel.
     */
    function cancelBid(uint256 _bidId) external {
        if (
            _msgSenderForMarket(bids[_bidId].marketplaceId) !=
            bids[_bidId].borrower
        ) {
            revert ActionNotAllowed({
                bidId: _bidId,
                action: "cancelBid",
                message: "Only the bid owner can cancel!"
            });
        }
        _cancelBid(_bidId);
    }

    /**
     * @notice Function for a market owner to cancel a bid in the market.
     * @param _bidId The id of the bid to cancel.
     */
    function marketOwnerCancelBid(uint256 _bidId) external {
        if (
            _msgSender() !=
            marketRegistry.getMarketOwner(bids[_bidId].marketplaceId)
        ) {
            revert ActionNotAllowed({
                bidId: _bidId,
                action: "marketOwnerCancelBid",
                message: "Only the market owner can cancel!"
            });
        }
        _cancelBid(_bidId);
        emit MarketOwnerCancelledBid(_bidId);
    }

    /**
     * @notice Function for users to cancel a bid.
     * @param _bidId The id of the bid to be cancelled.
     */
    function _cancelBid(uint256 _bidId)
        internal
        pendingBid(_bidId, "cancelBid")
    {
        // Set the bid state to CANCELLED
        bids[_bidId].state = BidState.CANCELLED;

        // Emit CancelledBid event
        emit CancelledBid(_bidId);
    }

    /**
     * @notice Function for a lender to accept a proposed loan bid.
     * @param _bidId The id of the loan bid to accept.
     */
    function lenderAcceptBid(uint256 _bidId)
        external
        override
        pendingBid(_bidId, "lenderAcceptBid")
        whenNotPaused
        returns (
            uint256 amountToProtocol,
            uint256 amountToMarketplace,
            uint256 amountToBorrower
        )
    {
        // Retrieve bid
        Bid storage bid = bids[_bidId];

        address sender = _msgSenderForMarket(bid.marketplaceId);
        (bool isVerified, ) = marketRegistry.isVerifiedLender(
            bid.marketplaceId,
            sender
        );
        require(isVerified, "Not verified lender");

        require(
            !marketRegistry.isMarketClosed(bid.marketplaceId),
            "Market is closed"
        );

        require(!isLoanExpired(_bidId), "Bid has expired");

        // Set timestamp
        bid.loanDetails.acceptedTimestamp = uint32(block.timestamp);
        bid.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);

        // Mark borrower's request as accepted
        bid.state = BidState.ACCEPTED;

        // Declare the bid acceptor as the lender of the bid
        bid.lender = sender;

        // Transfer funds to borrower from the lender
        amountToProtocol = bid.loanDetails.principal.percent(protocolFee());
        amountToMarketplace = bid.loanDetails.principal.percent(
            marketRegistry.getMarketplaceFee(bid.marketplaceId)
        );
        amountToBorrower =
            bid.loanDetails.principal -
            amountToProtocol -
            amountToMarketplace;
        //transfer fee to protocol
        bid.loanDetails.lendingToken.safeTransferFrom(
            bid.lender,
            owner(),
            amountToProtocol
        );

        //transfer fee to marketplace
        bid.loanDetails.lendingToken.safeTransferFrom(
            bid.lender,
            marketRegistry.getMarketFeeRecipient(bid.marketplaceId),
            amountToMarketplace
        );

        //transfer funds to borrower
        bid.loanDetails.lendingToken.safeTransferFrom(
            bid.lender,
            bid.receiver,
            amountToBorrower
        );

        // Record volume filled by lenders
        lenderVolumeFilled[address(bid.loanDetails.lendingToken)][
            bid.lender
        ] += bid.loanDetails.principal;
        totalVolumeFilled[address(bid.loanDetails.lendingToken)] += bid
            .loanDetails
            .principal;

        // Add borrower's active bid
        _borrowerBidsActive[bid.borrower].add(_bidId);

        // Emit AcceptedBid
        emit AcceptedBid(_bidId, bid.lender);

        emit FeePaid(_bidId, "protocol", amountToProtocol);
        emit FeePaid(_bidId, "marketplace", amountToMarketplace);
    }

    /**
     * @notice Function for users to make the minimum amount due for an active loan.
     * @param _bidId The id of the loan to make the payment towards.
     */
    function repayLoanMinimum(uint256 _bidId)
        external
        acceptedLoan(_bidId, "repayLoan")
    {
        (
            uint256 owedPrincipal,
            uint256 duePrincipal,
            uint256 interest
        ) = V2Calculations.calculateAmountOwed(bids[_bidId], block.timestamp);
        _repayLoan(
            _bidId,
            Payment({ principal: duePrincipal, interest: interest }),
            owedPrincipal + interest
        );
    }

    /**
     * @notice Function for users to repay an active loan in full.
     * @param _bidId The id of the loan to make the payment towards.
     */
    function repayLoanFull(uint256 _bidId)
        external
        acceptedLoan(_bidId, "repayLoan")
    {
        (uint256 owedPrincipal, , uint256 interest) = V2Calculations
            .calculateAmountOwed(bids[_bidId], block.timestamp);
        _repayLoan(
            _bidId,
            Payment({ principal: owedPrincipal, interest: interest }),
            owedPrincipal + interest
        );
    }

    // function that the borrower (ideally) sends to repay the loan
    /**
     * @notice Function for users to make a payment towards an active loan.
     * @param _bidId The id of the loan to make the payment towards.
     * @param _amount The amount of the payment.
     */
    function repayLoan(uint256 _bidId, uint256 _amount)
        external
        acceptedLoan(_bidId, "repayLoan")
    {
        (
            uint256 owedPrincipal,
            uint256 duePrincipal,
            uint256 interest
        ) = V2Calculations.calculateAmountOwed(bids[_bidId], block.timestamp);
        uint256 minimumOwed = duePrincipal + interest;

        // If amount is less than minimumOwed, we revert
        if (_amount < minimumOwed) {
            revert PaymentNotMinimum(_bidId, _amount, minimumOwed);
        }

        _repayLoan(
            _bidId,
            Payment({ principal: _amount - interest, interest: interest }),
            owedPrincipal + interest
        );
    }

    /**
     * @notice Lets the DAO/owner of the protocol implement an emergency stop mechanism.
     */
    function pauseProtocol() public virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Lets the DAO/owner of the protocol undo a previously implemented emergency stop.
     */
    function unpauseProtocol() public virtual onlyOwner whenPaused {
        _unpause();
    }

    //TODO: add an incentive for liquidator
    /**
     * @notice Function for users to liquidate a defaulted loan.
     * @param _bidId The id of the loan to make the payment towards.
     */
    function liquidateLoanFull(uint256 _bidId)
        external
        acceptedLoan(_bidId, "liquidateLoan")
    {
        require(isLoanDefaulted(_bidId), "Loan must be defaulted.");

        Bid storage bid = bids[_bidId];

        (uint256 owedPrincipal, , uint256 interest) = V2Calculations
            .calculateAmountOwed(bid, block.timestamp);
        _repayLoan(
            _bidId,
            Payment({ principal: owedPrincipal, interest: interest }),
            owedPrincipal + interest
        );

        bid.state = BidState.LIQUIDATED;

        emit LoanLiquidated(_bidId, _msgSenderForMarket(bid.marketplaceId));
    }

    /**
     * @notice Internal function to make a loan payment.
     * @param _bidId The id of the loan to make the payment towards.
     * @param _payment The Payment struct with payments amounts towards principal and interest respectively.
     * @param _owedAmount The total amount owed on the loan.
     */
    function _repayLoan(
        uint256 _bidId,
        Payment memory _payment,
        uint256 _owedAmount
    ) internal {
        Bid storage bid = bids[_bidId];
        uint256 paymentAmount = _payment.principal + _payment.interest;

        RepMark mark = reputationManager.updateAccountReputation(
            bid.borrower,
            _bidId
        );

        // Check if we are sending a payment or amount remaining
        if (paymentAmount >= _owedAmount) {
            paymentAmount = _owedAmount;
            bid.state = BidState.PAID;

            // Remove borrower's active bid
            _borrowerBidsActive[bid.borrower].remove(_bidId);

            emit LoanRepaid(_bidId);
        } else {
            emit LoanRepayment(_bidId);
        }
        // Send payment to the lender
        bid.loanDetails.lendingToken.safeTransferFrom(
            _msgSenderForMarket(bid.marketplaceId),
            bid.lender,
            paymentAmount
        );

        // update our mappings
        bid.loanDetails.totalRepaid.principal += _payment.principal;
        bid.loanDetails.totalRepaid.interest += _payment.interest;
        bid.loanDetails.lastRepaidTimestamp = uint32(block.timestamp);

        // If the loan is paid in full and has a mark, we should update the current reputation
        if (mark != RepMark.Good) {
            reputationManager.updateAccountReputation(bid.borrower, _bidId);
        }
    }

    /**
     * @notice Calculates the total amount owed for a bid.
     * @param _bidId The id of the loan bid to calculate the owed amount for.
     */
    function calculateAmountOwed(uint256 _bidId)
        public
        view
        returns (Payment memory owed)
    {
        if (bids[_bidId].state != BidState.ACCEPTED) return owed;

        (uint256 owedPrincipal, , uint256 interest) = V2Calculations
            .calculateAmountOwed(bids[_bidId], block.timestamp);
        owed.principal = owedPrincipal;
        owed.interest = interest;
    }

    /**
     * @notice Calculates the total amount owed for a loan bid at a specific timestamp.
     * @param _bidId The id of the loan bid to calculate the owed amount for.
     * @param _timestamp The timestamp at which to calculate the loan owed amount at.
     */
    function calculateAmountOwed(uint256 _bidId, uint256 _timestamp)
        public
        view
        returns (Payment memory owed)
    {
        Bid storage bid = bids[_bidId];
        if (
            bid.state != BidState.ACCEPTED ||
            bid.loanDetails.acceptedTimestamp >= _timestamp
        ) return owed;

        (uint256 owedPrincipal, , uint256 interest) = V2Calculations
            .calculateAmountOwed(bid, _timestamp);
        owed.principal = owedPrincipal;
        owed.interest = interest;
    }

    /**
     * @notice Calculates the minimum payment amount due for a loan.
     * @param _bidId The id of the loan bid to get the payment amount for.
     */
    function calculateAmountDue(uint256 _bidId)
        public
        view
        returns (Payment memory due)
    {
        if (bids[_bidId].state != BidState.ACCEPTED) return due;

        (, uint256 duePrincipal, uint256 interest) = V2Calculations
            .calculateAmountOwed(bids[_bidId], block.timestamp);
        due.principal = duePrincipal;
        due.interest = interest;
    }

    /**
     * @notice Calculates the minimum payment amount due for a loan at a specific timestamp.
     * @param _bidId The id of the loan bid to get the payment amount for.
     * @param _timestamp The timestamp at which to get the due payment at.
     */
    function calculateAmountDue(uint256 _bidId, uint256 _timestamp)
        public
        view
        returns (Payment memory due)
    {
        Bid storage bid = bids[_bidId];
        if (
            bids[_bidId].state != BidState.ACCEPTED ||
            bid.loanDetails.acceptedTimestamp >= _timestamp
        ) return due;

        (, uint256 duePrincipal, uint256 interest) = V2Calculations
            .calculateAmountOwed(bid, _timestamp);
        due.principal = duePrincipal;
        due.interest = interest;
    }

    /**
     * @notice Returns the next due date for a loan payment.
     * @param _bidId The id of the loan bid.
     */
    function calculateNextDueDate(uint256 _bidId)
        public
        view
        returns (uint32 dueDate_)
    {
        Bid storage bid = bids[_bidId];
        if (bids[_bidId].state != BidState.ACCEPTED) return dueDate_;

        // Start with the original due date being 1 payment cycle since bid was accepted
        dueDate_ = bid.loanDetails.acceptedTimestamp + bid.terms.paymentCycle;

        // Calculate the cycle number the last repayment was made
        uint32 delta = lastRepaidTimestamp(_bidId) -
            bid.loanDetails.acceptedTimestamp;
        if (delta > 0) {
            uint32 repaymentCycle = 1 + (delta / bid.terms.paymentCycle);
            dueDate_ += (repaymentCycle * bid.terms.paymentCycle);
        }

        //if we are in the last payment cycle, the next due date is the end of loan duration
        if (
            dueDate_ >
            bid.loanDetails.acceptedTimestamp + bid.loanDetails.loanDuration
        ) {
            dueDate_ =
                bid.loanDetails.acceptedTimestamp +
                bid.loanDetails.loanDuration;
        }
    }

    /**
     * @notice Checks to see if a borrower is delinquent.
     * @param _bidId The id of the loan bid to check for.
     */
    function isPaymentLate(uint256 _bidId) public view override returns (bool) {
        if (bids[_bidId].state != BidState.ACCEPTED) return false;
        return uint32(block.timestamp) > calculateNextDueDate(_bidId);
    }

    /**
     * @notice Checks to see if a borrower is delinquent.
     * @param _bidId The id of the loan bid to check for.
     */
    function isLoanDefaulted(uint256 _bidId)
        public
        view
        override
        returns (bool)
    {
        Bid storage bid = bids[_bidId];

        // Make sure loan cannot be liquidated if it is not active
        if (bid.state != BidState.ACCEPTED) return false;

        if (bidDefaultDuration[_bidId] == 0) return false;

        return (uint32(block.timestamp) - lastRepaidTimestamp(_bidId) >
            bidDefaultDuration[_bidId]);
    }

    function getBidState(uint256 _bidId)
        external
        view
        override
        returns (BidState)
    {
        return bids[_bidId].state;
    }

    function getBorrowerActiveLoanIds(address _borrower)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _borrowerBidsActive[_borrower].values();
    }

    function getBorrowerLoanIds(address _borrower)
        external
        view
        returns (uint256[] memory)
    {
        return borrowerBids[_borrower];
    }

    /**
     * @notice Checks to see if a pending loan has expired so it is no longer able to be accepted.
     * @param _bidId The id of the loan bid to check for.
     */
    function isLoanExpired(uint256 _bidId) public view returns (bool) {
        Bid storage bid = bids[_bidId];

        if (bid.state != BidState.PENDING) return false;
        if (bidExpirationTime[_bidId] == 0) return false;

        return (uint32(block.timestamp) >
            bid.loanDetails.timestamp + bidExpirationTime[_bidId]);
    }

    /**
     * @notice Returns the last repaid timestamp for a loan.
     * @param _bidId The id of the loan bid to get the timestamp for.
     */
    function lastRepaidTimestamp(uint256 _bidId) public view returns (uint32) {
        return V2Calculations.lastRepaidTimestamp(bids[_bidId]);
    }

    /**
     * @notice Returns the list of authorized tokens on the protocol.
     */
    function getLendingTokens() public view returns (address[] memory) {
        return lendingTokensSet.values();
    }

    /**
     * @notice Lets the DAO/owner of the protocol add an authorized lending token.
     * @param _lendingToken The contract address of the lending token.
     */
    function addLendingToken(address _lendingToken) public onlyOwner {
        require(_lendingToken.isContract(), "Incorrect lending token address");
        lendingTokensSet.add(_lendingToken);
    }

    /**
     * @notice Lets the DAO/owner of the protocol remove an authorized lending token.
     * @param _lendingToken The contract address of the lending token.
     */
    function removeLendingToken(address _lendingToken) public onlyOwner {
        lendingTokensSet.remove(_lendingToken);
    }

    /**
     * @notice Returns the borrower address for a given bid.
     * @param _bidId The id of the bid/loan to get the borrower for.
     * @return borrower_ The address of the borrower associated with the bid.
     */
    function getLoanBorrower(uint256 _bidId)
        external
        view
        returns (address borrower_)
    {
        borrower_ = bids[_bidId].borrower;
    }

    /**
     * @notice Returns the lender address for a given bid.
     * @param _bidId The id of the bid/loan to get the lender for.
     * @return lender_ The address of the lender associated with the bid.
     */
    function getLoanLender(uint256 _bidId)
        external
        view
        returns (address lender_)
    {
        lender_ = bids[_bidId].lender;
    }

    function getLoanLendingToken(uint256 _bidId)
        external
        view
        returns (address token_)
    {
        token_ = address(bids[_bidId].loanDetails.lendingToken);
    }

    /** OpenZeppelin Override Functions **/

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (address sender)
    {
        sender = ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextUpgradeable, ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}

library V2Calculations {
    using NumbersLib for uint256;

    enum PaymentType {
        EMI,
        Bullet
    }

    /**
     * @notice Returns the timestamp of the last payment made for a loan.
     * @param _bid The loan bid struct to get the timestamp for.
     */
    function lastRepaidTimestamp(TellerV2.Bid storage _bid)
        internal
        view
        returns (uint32)
    {
        return
            _bid.loanDetails.lastRepaidTimestamp == 0
                ? _bid.loanDetails.acceptedTimestamp
                : _bid.loanDetails.lastRepaidTimestamp;
    }

    /**
     * @notice Calculates the amount owed for a loan.
     * @param _bid The loan bid struct to get the owed amount for.
     * @param _timestamp The timestamp at which to get the owed amount at.
     */
    function calculateAmountOwed(TellerV2.Bid storage _bid, uint256 _timestamp)
        internal
        view
        returns (
            uint256 owedPrincipal_,
            uint256 duePrincipal_,
            uint256 interest_
        )
    {
        // Total principal left to pay
        return
            calculateAmountOwed(
                _bid.loanDetails.principal,
                _bid.loanDetails.totalRepaid.principal,
                _bid.terms.APR,
                _bid.terms.paymentCycleAmount,
                _bid.terms.paymentCycle,
                lastRepaidTimestamp(_bid),
                _timestamp,
                _bid.loanDetails.acceptedTimestamp,
                _bid.loanDetails.loanDuration,
                _bid.paymentType
            );
    }

    function calculateAmountOwed(
        uint256 principal,
        uint256 totalRepaidPrincipal,
        uint16 _interestRate,
        uint256 _paymentCycleAmount,
        uint256 _paymentCycle,
        uint256 _lastRepaidTimestamp,
        uint256 _timestamp,
        uint256 _startTimestamp,
        uint256 _loanDuration,
        PaymentType _paymentType
    )
        internal
        pure
        returns (
            uint256 owedPrincipal_,
            uint256 duePrincipal_,
            uint256 interest_
        )
    {
        owedPrincipal_ = principal - totalRepaidPrincipal;

        uint256 interestOwedInAYear = owedPrincipal_.percent(_interestRate);
        uint256 owedTime = _timestamp - uint256(_lastRepaidTimestamp);
        interest_ = (interestOwedInAYear * owedTime) / 365 days;

        // Cast to int265 to avoid underflow errors (negative means loan duration has passed)
        int256 durationLeftOnLoan = int256(_loanDuration) -
            (int256(_timestamp) - int256(_startTimestamp));
        bool isLastPaymentCycle = durationLeftOnLoan < int256(_paymentCycle) || // Check if current payment cycle is within or beyond the last one
            owedPrincipal_ + interest_ <= _paymentCycleAmount; // Check if what is left to pay is less than the payment cycle amount

        if (_paymentType == PaymentType.Bullet) {
            if (isLastPaymentCycle) {
                duePrincipal_ = owedPrincipal_;
            }
        } else {
            // Default to PaymentType.EMI
            // Max payable amount in a cycle
            // NOTE: the last cycle could have less than the calculated payment amount
            uint256 maxCycleOwed = isLastPaymentCycle
                ? owedPrincipal_ + interest_
                : _paymentCycleAmount;

            // Calculate accrued amount due since last repayment
            uint256 owedAmount = (maxCycleOwed * owedTime) / _paymentCycle;
            duePrincipal_ = Math.min(owedAmount - interest_, owedPrincipal_);
        }
    }

    /**
     * @notice Calculates the amount owed for a loan for the next payment cycle.
     * @param _type The payment type of the loan.
     * @param _principal The starting amount that is owed on the loan.
     * @param _duration The length of the loan.
     * @param _paymentCycle The length of the loan's payment cycle.
     * @param _apr The annual percentage rate of the loan.
     */
    function calculatePaymentCycleAmount(
        PaymentType _type,
        uint256 _principal,
        uint32 _duration,
        uint32 _paymentCycle,
        uint16 _apr
    ) internal returns (uint256) {
        if (_type == PaymentType.Bullet) {
            return
                _principal.percent(_apr).percent(
                    uint256(_paymentCycle).ratioOf(365 days, 10),
                    10
                );
        }
        // Default to PaymentType.EMI
        return NumbersLib.pmt(_principal, _duration, _paymentCycle, _apr);
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ProtocolFee is OwnableUpgradeable {
    // Protocol fee set for loan processing.
    uint16 private _protocolFee;

    /**
     * @notice This event is emitted when the protocol fee has been updated.
     * @param newFee The new protocol fee set.
     * @param oldFee The previously set protocol fee.
     */
    event ProtocolFeeSet(uint16 newFee, uint16 oldFee);

    /**
     * @notice Initialized the protocol fee.
     * @param initFee The initial protocol fee to be set on the protocol.
     */
    function __ProtocolFee_init(uint16 initFee) internal onlyInitializing {
        __Ownable_init();
        __ProtocolFee_init_unchained(initFee);
    }

    function __ProtocolFee_init_unchained(uint16 initFee)
        internal
        onlyInitializing
    {
        setProtocolFee(initFee);
    }

    /**
     * @notice Returns the current protocol fee.
     */
    function protocolFee() public view virtual returns (uint16) {
        return _protocolFee;
    }

    /**
     * @notice Lets the DAO/owner of the protocol to set a new protocol fee.
     * @param newFee The new protocol fee to be set.
     */
    function setProtocolFee(uint16 newFee) public virtual onlyOwner {
        // Skip if the fee is the same
        if (newFee == _protocolFee) return;

        uint16 oldFee = _protocolFee;
        _protocolFee = newFee;
        emit ProtocolFeeSet(newFee, oldFee);
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./TellerV2Storage.sol";
import "./ERC2771ContextUpgradeable.sol";

/**
 * @dev This contract should not use any storage
 */

abstract contract TellerV2Context is
    ERC2771ContextUpgradeable,
    TellerV2Storage
{
    using EnumerableSet for EnumerableSet.AddressSet;

    event TrustedMarketForwarderSet(
        uint256 indexed marketId,
        address forwarder,
        address sender
    );
    event MarketForwarderApproved(
        uint256 indexed marketId,
        address indexed forwarder,
        address sender
    );

    constructor(address trustedForwarder)
        ERC2771ContextUpgradeable(trustedForwarder)
    {}

    /**
     * @notice Checks if an address is a trusted forwarder contract for a given market.
     * @param _marketId An ID for a lending market.
     * @param _trustedMarketForwarder An address to check if is a trusted forwarder in the given market.
     * @return A boolean indicating the forwarder address is trusted in a market.
     */
    function isTrustedMarketForwarder(
        uint256 _marketId,
        address _trustedMarketForwarder
    ) public view returns (bool) {
        return
            _trustedMarketForwarders[_marketId] == _trustedMarketForwarder ||
            lenderCommitmentForwarder == _trustedMarketForwarder;
    }

    /**
     * @notice Checks if an account has approved a forwarder for a market.
     * @param _marketId An ID for a lending market.
     * @param _forwarder A forwarder contract address.
     * @param _account The address to verify set an approval.
     * @return A boolean indicating if an approval was set.
     */
    function hasApprovedMarketForwarder(
        uint256 _marketId,
        address _forwarder,
        address _account
    ) public view returns (bool) {
        return
            isTrustedMarketForwarder(_marketId, _forwarder) &&
            _approvedForwarderSenders[_forwarder].contains(_account);
    }

    /**
     * @notice Sets a trusted forwarder for a lending market.
     * @notice The caller must owner the market given. See {MarketRegistry}
     * @param _marketId An ID for a lending market.
     * @param _forwarder A forwarder contract address.
     */
    function setTrustedMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        require(
            marketRegistry.getMarketOwner(_marketId) == _msgSender(),
            "Caller must be the market owner"
        );
        _trustedMarketForwarders[_marketId] = _forwarder;
        emit TrustedMarketForwarderSet(_marketId, _forwarder, _msgSender());
    }

    /**
     * @notice Approves a forwarder contract to use their address as a sender for a specific market.
     * @notice The forwarder given must be trusted by the market given.
     * @param _marketId An ID for a lending market.
     * @param _forwarder A forwarder contract address.
     */
    function approveMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        require(
            isTrustedMarketForwarder(_marketId, _forwarder),
            "Forwarder must be trusted by the market"
        );
        _approvedForwarderSenders[_forwarder].add(_msgSender());
        emit MarketForwarderApproved(_marketId, _forwarder, _msgSender());
    }

    /**
     * @notice Retrieves the function caller address by checking the appended calldata if the _actual_ caller is a trusted forwarder.
     * @param _marketId An ID for a lending market.
     * @return sender The address to use as the function caller.
     */
    function _msgSenderForMarket(uint256 _marketId)
        internal
        view
        virtual
        returns (address)
    {
        if (isTrustedMarketForwarder(_marketId, _msgSender())) {
            address sender;
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
            // Ensure the appended sender address approved the forwarder
            require(
                _approvedForwarderSenders[_msgSender()].contains(sender),
                "Sender must approve market forwarder"
            );
            return sender;
        }

        return _msgSender();
    }

    /**
     * @notice Retrieves the actual function calldata from a trusted forwarder call.
     * @param _marketId An ID for a lending market to verify if the caller is a trusted forwarder.
     * @return calldata The modified bytes array of the function calldata without the appended sender's address.
     */
    function _msgDataForMarket(uint256 _marketId)
        internal
        view
        virtual
        returns (bytes calldata)
    {
        if (isTrustedMarketForwarder(_marketId, _msgSender())) {
            return msg.data[:msg.data.length - 20];
        } else {
            return _msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./WadRayMath.sol";

/**
 * @dev Utility library for uint256 numbers
 *
 * @author [email protected]
 */
library NumbersLib {
    using WadRayMath for uint256;

    /**
     * @dev It represents 100% with 2 decimal places.
     */
    uint16 internal constant PCT_100 = 10000;

    function percentFactor(uint256 decimals) internal pure returns (uint256) {
        return 100 * (10**decimals);
    }

    /**
     * @notice Returns a percentage value of a number.
     * @param self The number to get a percentage of.
     * @param percentage The percentage value to calculate with 2 decimal places (10000 = 100%).
     */
    function percent(uint256 self, uint16 percentage)
        internal
        pure
        returns (uint256)
    {
        return percent(self, percentage, 2);
    }

    /**
     * @notice Returns a percentage value of a number.
     * @param self The number to get a percentage of.
     * @param percentage The percentage value to calculate with.
     * @param decimals The number of decimals the percentage value is in.
     */
    function percent(
        uint256 self,
        uint256 percentage,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (self * percentage) / percentFactor(decimals);
    }

    /**
     * @notice it returns the absolute number of a specified parameter
     * @param self the number to be returned in it's absolute
     * @return the absolute number
     */
    function abs(int256 self) internal pure returns (uint256) {
        return self >= 0 ? uint256(self) : uint256(-1 * self);
    }

    /**
     * @notice Returns a ratio percentage of {num1} to {num2}.
     * @dev Returned value is type uint16.
     * @param num1 The number used to get the ratio for.
     * @param num2 The number used to get the ratio from.
     * @return Ratio percentage with 2 decimal places (10000 = 100%).
     */
    function ratioOf(uint256 num1, uint256 num2)
        internal
        pure
        returns (uint16)
    {
        return SafeCast.toUint16(ratioOf(num1, num2, 2));
    }

    /**
     * @notice Returns a ratio percentage of {num1} to {num2}.
     * @param num1 The number used to get the ratio for.
     * @param num2 The number used to get the ratio from.
     * @param decimals The number of decimals the percentage value is returned in.
     * @return Ratio percentage value.
     */
    function ratioOf(
        uint256 num1,
        uint256 num2,
        uint256 decimals
    ) internal pure returns (uint256) {
        if (num2 == 0) return 0;
        return (num1 * percentFactor(decimals)) / num2;
    }

    /**
     * @notice Calculates the payment amount for a cycle duration.
     *  The formula is calculated based on the standard Estimated Monthly Installment (https://en.wikipedia.org/wiki/Equated_monthly_installment)
     *  EMI = [P x R x (1+R)^N]/[(1+R)^N-1]
     * @param principal The starting amount that is owed on the loan.
     * @param loanDuration The length of the loan.
     * @param cycleDuration The length of the loan's payment cycle.
     * @param apr The annual percentage rate of the loan.
     */
    function pmt(
        uint256 principal,
        uint32 loanDuration,
        uint32 cycleDuration,
        uint16 apr
    ) internal pure returns (uint256) {
        uint256 n = loanDuration / cycleDuration;
        if (apr == 0) return (principal / n);

        uint256 one = WadRayMath.wad();
        uint256 r = WadRayMath.pctToWad(apr).wadMul(cycleDuration).wadDiv(
            365 days
        );
        uint256 exp = (one + r).wadPow(n);
        uint256 numerator = principal.wadMul(r).wadMul(exp);
        uint256 denominator = exp - one;

        return numerator.wadDiv(denominator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 * @dev This is modified from the OZ library to remove the gap of storage variables at the end.
 */
abstract contract ERC2771ContextUpgradeable is
    Initializable,
    ContextUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title WadRayMath library
 * @author Multiplier Finance
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */
library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;
    uint256 internal constant PCT_WAD_RATIO = 1e14;
    uint256 internal constant PCT_RAY_RATIO = 1e23;

    function ray() internal pure returns (uint256) {
        return RAY;
    }

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(WAD)).div(b);
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB = b / 2;

        return halfB.add(a.mul(RAY)).div(b);
    }

    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;

        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    function rayToPct(uint256 a) internal pure returns (uint16) {
        uint256 halfRatio = PCT_RAY_RATIO / 2;

        uint256 val = halfRatio.add(a).div(PCT_RAY_RATIO);
        return SafeCast.toUint16(val);
    }

    function wadToPct(uint256 a) internal pure returns (uint16) {
        uint256 halfRatio = PCT_WAD_RATIO / 2;

        uint256 val = halfRatio.add(a).div(PCT_WAD_RATIO);
        return SafeCast.toUint16(val);
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }

    function pctToRay(uint16 a) internal pure returns (uint256) {
        return uint256(a).mul(RAY).div(1e4);
    }

    function pctToWad(uint16 a) internal pure returns (uint256) {
        return uint256(a).mul(WAD).div(1e4);
    }

    /**
     * @dev calculates base^duration. The code uses the ModExp precompile
     * @return z base^duration, in ray
     */
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256) {
        return _pow(x, n, RAY, rayMul);
    }

    function wadPow(uint256 x, uint256 n) internal pure returns (uint256) {
        return _pow(x, n, WAD, wadMul);
    }

    function _pow(
        uint256 x,
        uint256 n,
        uint256 p,
        function(uint256, uint256) internal pure returns (uint256) mul
    ) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : p;

        for (n /= 2; n != 0; n /= 2) {
            x = mul(x, x);

            if (n % 2 != 0) {
                z = mul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../interfaces/IASResolver.sol";

/**
 * @title A base resolver contract
 */
abstract contract TellerASResolver is IASResolver {
    error NotPayable();

    function isPayable() public pure virtual override returns (bool) {
        return false;
    }

    receive() external payable virtual {
        if (!isPayable()) {
            revert NotPayable();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@mangrovedao/hardhat-test-solidity/test.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "hardhat/console.sol";

import "./Testable.sol";
import "../TellerV2.sol";

contract V2Calculations_Test is Testable {
    using Arrays for uint256[];
    using EnumerableSet for EnumerableSet.UintSet;

    TellerV2.Bid __bid;
    EnumerableSet.UintSet cyclesToSkip;
    uint256[] cyclesWithExtraPayments;
    uint256[] cyclesWithExtraPaymentsAmounts;

    constructor() {
        __bid.loanDetails.principal = 100000e6; // 100k
        __bid.loanDetails.loanDuration = 365 days * 3; // 3 years
        __bid.terms.paymentCycle = 365 days / 12; // 1 month
        __bid.terms.APR = 1000; // 10.0%
    }

    function setup_beforeAll() public {
        delete cyclesToSkip;
        delete cyclesWithExtraPayments;
        delete cyclesWithExtraPaymentsAmounts;
    }

    // EMI loan
    function _01_calculateAmountOwed_test() public {
        cyclesToSkip.add(2);
        cyclesWithExtraPayments = [3, 4];
        cyclesWithExtraPaymentsAmounts = [25000e6, 25000e6];

        calculateAmountOwed_runner(18, V2Calculations.PaymentType.EMI);
    }

    // EMI loan
    function _02_calculateAmountOwed_test() public {
        cyclesToSkip.add(3);
        cyclesToSkip.add(4);
        cyclesToSkip.add(5);

        calculateAmountOwed_runner(36, V2Calculations.PaymentType.EMI);
    }

    // EMI loan
    function _03_calculateAmountOwed_test() public {
        cyclesWithExtraPayments = [3, 7];
        cyclesWithExtraPaymentsAmounts = [35000e6, 20000e6];

        calculateAmountOwed_runner(16, V2Calculations.PaymentType.EMI);
    }

    // Bullet loan
    function _04_calculateAmountOwed_test() public {
        cyclesToSkip.add(6);
        calculateAmountOwed_runner(36, V2Calculations.PaymentType.Bullet);
    }

    // Bullet loan
    function _05_calculateAmountOwed_test() public {
        cyclesToSkip.add(12);
        cyclesWithExtraPayments = [1, 8];
        cyclesWithExtraPaymentsAmounts = [15000e6, 10000e6];
        calculateAmountOwed_runner(36, V2Calculations.PaymentType.Bullet);
    }

    function calculateAmountOwed_runner(
        uint256 expectedTotalCycles,
        V2Calculations.PaymentType _paymentType
    ) private {
        // Calculate payment cycle amount
        uint256 paymentCycleAmount = V2Calculations.calculatePaymentCycleAmount(
            _paymentType,
            __bid.loanDetails.principal,
            __bid.loanDetails.loanDuration,
            __bid.terms.paymentCycle,
            __bid.terms.APR
        );

        // Set the bid's payment cycle amount
        __bid.terms.paymentCycleAmount = paymentCycleAmount;
        // Set accepted bid timestamp to now
        __bid.loanDetails.acceptedTimestamp = uint32(block.timestamp);

        uint256 nowTimestamp = block.timestamp;
        uint256 skippedPaymentCounter;
        uint256 owedPrincipal = __bid.loanDetails.principal;
        uint256 cycleCount = Math.ceilDiv(
            __bid.loanDetails.loanDuration,
            __bid.terms.paymentCycle
        );
        uint256 cycleIndex;
        while (owedPrincipal > 0) {
            // Increment cycle index
            cycleIndex++;

            // Increase timestamp
            nowTimestamp += __bid.terms.paymentCycle;

            uint256 duePrincipal;
            uint256 interest;
            (owedPrincipal, duePrincipal, interest) = V2Calculations
                .calculateAmountOwed(__bid, nowTimestamp);

            // Check if we should skip this cycle for payments
            if (cyclesToSkip.length() > 0) {
                if (cyclesToSkip.contains(cycleIndex)) {
                    // Add this cycle's payment amount to the next cycle's expected payment
                    skippedPaymentCounter++;
                    continue;
                }
            }

            skippedPaymentCounter = 0;

            uint256 extraPaymentAmount;
            // Add additional payment amounts for cycles
            if (cyclesWithExtraPayments.length > 0) {
                uint256 index = cyclesWithExtraPayments.findUpperBound(
                    cycleIndex
                );
                if (
                    index < cyclesWithExtraPayments.length &&
                    cyclesWithExtraPayments[index] == cycleIndex
                ) {
                    extraPaymentAmount = cyclesWithExtraPaymentsAmounts[index];
                }
            }

            // Mark repayment amounts
            uint256 principalPayment;
            principalPayment = duePrincipal + extraPaymentAmount;
            if (principalPayment > 0) {
                __bid.loanDetails.totalRepaid.principal += principalPayment;
                // Subtract principal owed for while loop execution check
                owedPrincipal -= principalPayment;
            }

            __bid.loanDetails.totalRepaid.interest += interest;

            // Set last repaid time
            __bid.loanDetails.lastRepaidTimestamp = uint32(nowTimestamp);
        }
        Test.eq(
            cycleIndex,
            expectedTotalCycles,
            "Expected number of cycles incorrect"
        );
        Test.eq(
            cycleIndex <= cycleCount + 1,
            true,
            "Payment cycle exceeded agreed terms"
        );
    }

    function calculateAmountOwed_test() public {
        uint256 principal = 24486571879936808846;
        uint256 repaidPrincipal = 23410087846643631232;
        uint16 interestRate = 3000;

        (uint256 _owedPrincipal, uint256 _duePrincipal, uint256 _interest) = V2Calculations
            .calculateAmountOwed(
                principal, //owed principal
                repaidPrincipal,
                interestRate,
                8567977538702439153, //payment cycle amount
                2592000, ///payment Cycle
                1658159355, // last repaid timestamp
                1663189241, //timestamp
                1646159355, // accepted timestamp
                __bid.loanDetails.loanDuration, // duration
                V2Calculations.PaymentType.EMI // market payment type
            );

        console.log("calc amt owed test ");
        console.log(_owedPrincipal);
        console.log(_duePrincipal);

        Test.eq(
            _owedPrincipal,
            1076484033293177614,
            "Expected number of cycles incorrect"
        );
        Test.eq(
            _duePrincipal,
            1076484033293177614,
            "Expected number of cycles incorrect"
        );
    }

    function calculateBulletAmountOwed_test() public {
        uint256 _principal = 100000e6;
        uint256 _repaidPrincipal = 0;
        uint16 _apr = 3000;
        uint256 _paymentCycleAmount = V2Calculations
            .calculatePaymentCycleAmount(
                V2Calculations.PaymentType.Bullet,
                _principal,
                365 days,
                365 days / 12,
                _apr
            );
        uint256 _acceptedTimestamp = 1646159355;
        uint256 _lastRepaidTimestamp = _acceptedTimestamp;

        // Within the first payment cycle
        uint256 _timestamp = _acceptedTimestamp + ((365 days / 12) / 2);

        (uint256 _owedPrincipal, uint256 _duePrincipal, uint256 _interest) = V2Calculations
            .calculateAmountOwed(
                _principal,
                _repaidPrincipal,
                _apr,
                _paymentCycleAmount,
                365 days / 12, // paymentCycle
                _lastRepaidTimestamp,
                _timestamp,
                _acceptedTimestamp,
                365 days, // loan duration
                V2Calculations.PaymentType.Bullet
            );

        Test.eq(
            _owedPrincipal,
            _principal,
            "First cycle bullet owed principal incorrect"
        );
        Test.eq(_duePrincipal, 0, "First cycle bullet due principal incorrect");
        Test.eq(_interest, 1250000000, "First cycle bullet interest incorrect");

        // Within random payment cycle
        _timestamp = _acceptedTimestamp + ((365 days / 12) * 3);

        (_owedPrincipal, _duePrincipal, _interest) = V2Calculations
            .calculateAmountOwed(
                _principal,
                _repaidPrincipal,
                _apr,
                _paymentCycleAmount,
                365 days / 12, // paymentCycle
                _lastRepaidTimestamp,
                _timestamp,
                _acceptedTimestamp,
                365 days, // loan duration
                V2Calculations.PaymentType.Bullet
            );

        Test.eq(
            _owedPrincipal,
            _principal,
            "Second cycle bullet Owed principal incorrect"
        );
        Test.eq(_duePrincipal, 0, "Second cycle bullet principal incorrect");
        Test.eq(
            _interest,
            7500000000,
            "Second cycle bullet interest incorrect"
        );

        // Last payment cycle
        _timestamp = _acceptedTimestamp + 360 days;

        (_owedPrincipal, _duePrincipal, _interest) = V2Calculations
            .calculateAmountOwed(
                _principal,
                _repaidPrincipal,
                _apr,
                _paymentCycleAmount,
                365 days / 12, // paymentCycle
                _lastRepaidTimestamp,
                _timestamp,
                _acceptedTimestamp,
                365 days, // loan duration
                V2Calculations.PaymentType.Bullet
            );

        Test.eq(
            _owedPrincipal,
            _principal,
            "Final cycle bullet Owed principal incorrect"
        );
        Test.eq(
            _duePrincipal,
            _principal,
            "Final cycle bullet principal incorrect"
        );
        Test.eq(
            _interest,
            29589041095,
            "Final cycle bullet interest incorrect"
        );

        // Beyond last payment cycle (checks for overflow protection)
        _timestamp = _acceptedTimestamp + 365 days * 2;

        (_owedPrincipal, _duePrincipal, _interest) = V2Calculations
            .calculateAmountOwed(
                _principal,
                _repaidPrincipal,
                _apr,
                _paymentCycleAmount,
                365 days / 12, // paymentCycle
                _lastRepaidTimestamp,
                _timestamp,
                _acceptedTimestamp,
                365 days, // loan duration
                V2Calculations.PaymentType.Bullet
            );

        Test.eq(
            _owedPrincipal,
            _principal,
            "Final cycle bullet Owed principal incorrect"
        );
        Test.eq(
            _duePrincipal,
            _principal,
            "Final cycle bullet principal incorrect"
        );
        Test.eq(
            _interest,
            ((_principal * _apr) / 10000) * 2,
            "Final cycle bullet interest incorrect"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Testable } from "./Testable.sol";

import { TellerV2 } from "../TellerV2.sol";
import { MarketRegistry } from "../MarketRegistry.sol";
import { ReputationManager } from "../ReputationManager.sol";

import "../TellerV2Storage.sol";

import "../interfaces/IMarketRegistry.sol";
import "../interfaces/IReputationManager.sol";

import "../EAS/TellerAS.sol";

import "../mock/WethMock.sol";
import "../interfaces/IWETH.sol";

contract TellerV2_Test is Testable, TellerV2 {
    User private marketOwner;
    User private borrower;
    User private lender;

    WethMock wethMock;

    constructor() TellerV2(address(address(0))) {}

    function setup_beforeAll() public {
        wethMock = new WethMock();

        marketOwner = new User(this, wethMock);
        borrower = new User(this, wethMock);
        lender = new User(this, wethMock);

        lenderCommitmentForwarder = address(0);
        marketRegistry = IMarketRegistry(new MarketRegistry());
        reputationManager = IReputationManager(new ReputationManager());
    }
}

contract User {
    TellerV2 public immutable tellerV2;
    WethMock public immutable wethMock;

    constructor(TellerV2 _tellerV2, WethMock _wethMock) {
        tellerV2 = _tellerV2;
        wethMock = _wethMock;
    }

    function depositToWeth(uint256 amount) public {
        wethMock.deposit{ value: amount }();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Testable } from "./Testable.sol";

import { TellerV2 } from "../TellerV2.sol";
import { MarketRegistry } from "../MarketRegistry.sol";
import { ReputationManager } from "../ReputationManager.sol";

import "../TellerV2Storage.sol";

import "../interfaces/IMarketRegistry.sol";
import "../interfaces/IReputationManager.sol";

import "../EAS/TellerAS.sol";

import "../mock/WethMock.sol";
import "../interfaces/IWETH.sol";

contract MarketRegistry_Test is Testable, TellerV2 {
    User private marketOwner;
    User private borrower;
    User private lender;

    WethMock wethMock;

    constructor() TellerV2(address(address(0))) {}

    function setup_beforeAll() public {
        wethMock = new WethMock();

        marketOwner = new User(this, wethMock);
        borrower = new User(this, wethMock);
        lender = new User(this, wethMock);

        lenderCommitmentForwarder = address(0);
        marketRegistry = IMarketRegistry(new MarketRegistry());
        reputationManager = IReputationManager(new ReputationManager());

        marketOwner.createMarket(
            address(marketRegistry),
            8000,
            7000,
            5000,
            500,
            false,
            false,
            V2Calculations.PaymentType.EMI,
            "uri://"
        );
    }
}

contract User {
    TellerV2 public immutable tellerV2;
    WethMock public immutable wethMock;

    constructor(TellerV2 _tellerV2, WethMock _wethMock) {
        tellerV2 = _tellerV2;
        wethMock = _wethMock;
    }

    function depositToWeth(uint256 amount) public {
        wethMock.deposit{ value: amount }();
    }

    function createMarket(
        address marketRegistry,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        V2Calculations.PaymentType _paymentType,
        string calldata _uri
    ) public {
        IMarketRegistry(marketRegistry).createMarket(
            address(this),
            _paymentCycleDuration,
            _paymentDefaultDuration,
            _bidExpirationTime,
            _feePercent,
            _requireLenderAttestation,
            _requireBorrowerAttestation,
            _paymentType,
            _uri
        );
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// Contracts
import "../MarketRegistry.sol";

contract MarketRegistry__Goerli_TellerAS_Fix is MarketRegistry {
    function setTellerAS(address _tellerAS) external {
        require(
            address(tellerAS) == address(0),
            "MarketRegistry: TellerAS already set"
        );
        tellerAS = TellerAS(_tellerAS);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@mangrovedao/hardhat-test-solidity/test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Testable } from "./Testable.sol";
import { TellerV2Context } from "../TellerV2Context.sol";
import { IMarketRegistry } from "../interfaces/IMarketRegistry.sol";
import { TellerV2MarketForwarder } from "../TellerV2MarketForwarder.sol";
import { LenderCommitmentForwarder } from "../LenderCommitmentForwarder.sol";

contract TellerV2Context_Test is Testable, TellerV2Context {
    uint256 private marketId;
    /*User private marketOwner;
    User private user1;
    User private user2;*/
    User private marketOwner;
    User private user1;

    constructor() TellerV2Context(address(0)) {}

    function setup_beforeAll() public {
        marketOwner = new User(TellerV2Context(this));

        marketRegistry = IMarketRegistry(
            address(new MockMarketRegistry(marketOwner))
        );

        Test.eq(
            marketRegistry.getMarketOwner(5),
            address(marketOwner),
            "should have set marketOwner"
        );
    }

    function isTrustedMarketForwarder_test() public returns (bool) {
        Test.eq(
            super.isTrustedMarketForwarder(89, lenderCommitmentForwarder),
            true,
            "lenderCommitmentForwarder should be a trusted forwarder for all markets"
        );
        //Test.eq(super.isTrustedMarketForwarder(1,  address(0)) , false, "by default address(0) should not be a trusted forwarder");

        address stubbedMarketForwarder = address(
            0xB11ca87E32075817C82Cc471994943a4290f4a14
        );
        Test.eq(
            super.isTrustedMarketForwarder(7, stubbedMarketForwarder),
            false,
            "by default an address should not be a trusted forwarder"
        );

        marketOwner.setTrustedMarketForwarder(7, stubbedMarketForwarder);

        Test.eq(
            super.isTrustedMarketForwarder(7, stubbedMarketForwarder),
            true,
            " address should  be a trusted forwarder after setting "
        );
    }
}

contract User {
    TellerV2Context public immutable context;

    constructor(TellerV2Context _context) {
        context = _context;
    }

    function setTrustedMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        context.setTrustedMarketForwarder(_marketId, _forwarder);
    }

    function approveMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        context.approveMarketForwarder(_marketId, _forwarder);
    }
}

contract MockMarketRegistry {
    User private immutable marketOwner;

    constructor(User _marketOwner) {
        marketOwner = _marketOwner;
    }

    function getMarketOwner(uint256) external view returns (address) {
        return address(marketOwner);
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./TellerV2.sol";

import "./interfaces/IMarketRegistry.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @dev Simple helper contract to forward an encoded function call to the TellerV2 contract. See {TellerV2Context}
 */
abstract contract TellerV2MarketForwarder is Initializable, ContextUpgradeable {
    using AddressUpgradeable for address;

    address public immutable _tellerV2;
    address public immutable _marketRegistry;

    struct CreateLoanArgs {
        uint256 marketId;
        address lendingToken;
        uint256 principal;
        uint32 duration;
        uint16 interestRate;
        string metadataURI;
        address recipient;
    }

    constructor(address _protocolAddress, address _marketRegistryAddress) {
        _tellerV2 = _protocolAddress;
        _marketRegistry = _marketRegistryAddress;
    }

    function getTellerV2() public view returns (TellerV2) {
        return TellerV2(_tellerV2);
    }

    function getMarketRegistry() public view returns (address) {
        return _marketRegistry;
    }

    function getTellerV2MarketOwner(uint256 marketId) public returns (address) {
        return IMarketRegistry(getMarketRegistry()).getMarketOwner(marketId);
    }

    /**
     * @dev Performs function call to the TellerV2 contract by appending an address to the calldata.
     * @param _data The encoded function calldata on TellerV2.
     * @param _msgSender The address that should be treated as the underlying function caller.
     * @return The encoded response from the called function.
     *
     * Requirements:
     *  - The {_msgSender} address must set an approval on TellerV2 for this forwarder contract __before__ making this call.
     */
    function _forwardCall(bytes memory _data, address _msgSender)
        internal
        returns (bytes memory)
    {
        return
            address(_tellerV2).functionCall(
                abi.encodePacked(_data, _msgSender)
            );
    }

    /**
     * @notice Creates a new loan using the TellerV2 lending protocol.
     * @param _createLoanArgs Details describing the loan agreement.]
     * @param _borrower The borrower address for the new loan.
     */
    function _submitBid(
        CreateLoanArgs memory _createLoanArgs,
        address _borrower
    ) internal virtual returns (uint256 bidId) {
        bytes memory responseData;

        responseData = _forwardCall(
            abi.encodeWithSelector(
                ITellerV2.submitBid.selector,
                _createLoanArgs.lendingToken,
                _createLoanArgs.marketId,
                _createLoanArgs.principal,
                _createLoanArgs.duration,
                _createLoanArgs.interestRate,
                _createLoanArgs.metadataURI,
                _createLoanArgs.recipient
            ),
            _borrower
        );

        return abi.decode(responseData, (uint256));
    }

    /**
     * @notice Accepts a new loan using the TellerV2 lending protocol.
     * @param _bidId The id of the new loan.
     * @param _lender The address of the lender who will provide funds for the new loan.
     */
    function _acceptBid(uint256 _bidId, address _lender)
        internal
        virtual
        returns (bool)
    {
        // Approve the borrower's loan
        _forwardCall(
            abi.encodeWithSelector(ITellerV2.lenderAcceptBid.selector, _bidId),
            _lender
        );

        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./TellerV2MarketForwarder.sol";

contract LenderCommitmentForwarder is TellerV2MarketForwarder {
    /**
     * @notice Details about a lender's capital commitment.
     * @param amount Amount of tokens being committed by the lender.
     * @param expiration Expiration time in seconds, when the commitment expires.
     * @param maxDuration Length of time, in seconds that the lender's capital can be lent out for.
     * @param minAPR Minimum Annual percentage to be applied for loans using the lender's capital.
     */
    struct Commitment {
        uint256 maxPrincipal;
        uint32 expiration;
        uint32 maxDuration;
        uint16 minInterestRate;
    }

    modifier onlyMarketOwner(uint256 marketId) {
        require(_msgSender() == getTellerV2MarketOwner(marketId));
        _;
    }

    // Mapping of lender address => market ID => lending token => commitment
    mapping(address => mapping(uint256 => mapping(address => Commitment)))
        public lenderMarketCommitments;

    /**
     * @notice This event is emitted when a lender's commitment is submitted.
     * @param lender The address of the lender.
     * @param marketId The Id of the market the commitment applies to.
     * @param lendingToken The address of the asset being committed.
     * @param tokenAmount The amount of the asset being committed.
     */
    event UpdatedCommitment(
        address indexed lender,
        uint256 indexed marketId,
        address indexed lendingToken,
        uint256 tokenAmount
    );

    /**
     * @notice This event is emitted when a lender's commitment has been removed.
     * @param lender The address of the lender.
     * @param marketId The Id of the market the commitment removal applies to.
     * @param lendingToken The address of the asset the commitment removal applies to.
     */
    event DeletedCommitment(
        address indexed lender,
        uint256 indexed marketId,
        address indexed lendingToken
    );

    /**
     * @notice This event is emitted when a lender's commitment is exercised for a loan.
     * @param lender The address of the lender.
     * @param marketId The Id of the market the commitment applies to.
     * @param lendingToken The address of the asset being committed.
     * @param tokenAmount The amount of the asset being committed.
     * @param bidId The bid id for the loan from TellerV2.
     */
    event ExercisedCommitment(
        address indexed lender,
        uint256 indexed marketId,
        address indexed lendingToken,
        uint256 tokenAmount,
        uint256 bidId
    );

    /** External Functions **/

    constructor(address _protocolAddress, address _marketRegistry)
        TellerV2MarketForwarder(_protocolAddress, _marketRegistry)
    {}

    /**
     * @notice Updates the commitment of a lender to a market.
     * @param _tokenAddress The address of the asset being committed.
     * @param _marketId The Id of the market the commitment applies to.
     * @param _maxPrincipal Amount of tokens being committed by the lender.
     * @param _maxLoanDuration Length of time, in seconds that the lender's capital can be lent out for.
     * @param _minInterestRate Minimum Annual percentage to be applied for loans using the lender's capital.
     * @param _expiration Expiration time in seconds, when the commitment expires.
     */
    function updateCommitment(
        uint256 _marketId,
        address _tokenAddress,
        uint256 _maxPrincipal,
        uint32 _maxLoanDuration,
        uint16 _minInterestRate,
        uint32 _expiration
    ) public {
        address lender = _msgSender();
        require(_expiration > uint32(block.timestamp));

        Commitment storage commitment = lenderMarketCommitments[lender][
            _marketId
        ][_tokenAddress];
        commitment.maxPrincipal = _maxPrincipal;
        commitment.expiration = _expiration;
        commitment.maxDuration = _maxLoanDuration;
        commitment.minInterestRate = _minInterestRate;

        emit UpdatedCommitment(lender, _marketId, _tokenAddress, _maxPrincipal);
    }

    /**
     * @notice Removes the commitment of a lender to a market.
     * @param _marketId The Id of the market the commitment removal applies to.
     * @param _tokenAddress The address of the asset for which the commitment is being removed.
     */
    function deleteCommitment(uint256 _marketId, address _tokenAddress) public {
        _deleteCommitment(_msgSender(), _marketId, _tokenAddress);
    }

    /**
     * @notice Removes the commitment of a lender to a market.
     * @param _lender The address of the lender of the commitment.
     * @param _marketId The Id of the market the commitment removal applies to.
     * @param _tokenAddress The address of the asset for which the commitment is being removed.
     */
    function _deleteCommitment(
        address _lender,
        uint256 _marketId,
        address _tokenAddress
    ) internal {
        if (
            lenderMarketCommitments[_lender][_marketId][_tokenAddress]
                .maxPrincipal > 0
        ) {
            delete lenderMarketCommitments[_lender][_marketId][_tokenAddress];
            emit DeletedCommitment(_lender, _marketId, _tokenAddress);
        }
    }

    /**
     * @notice Reduces the commitment amount for a lender to a market.
     * @param _lender The address of the lender of the commitment.
     * @param _marketId The Id of the market the commitment removal applies to.
     * @param _tokenAddress The address of the asset for which the commitment is being removed.
     * @param _tokenAmountDelta The amount of change in the maxPrincipal.
     */
    function _decrementCommitment(
        address _lender,
        uint256 _marketId,
        address _tokenAddress,
        uint256 _tokenAmountDelta
    ) internal {
        lenderMarketCommitments[_lender][_marketId][_tokenAddress]
            .maxPrincipal -= _tokenAmountDelta;
    }

    /**
     * @notice Accept the commitment to submitBid and acceptBid using the funds
     * @param _marketId The Id of the market the commitment removal applies to.
     * @param _lender The address of the lender of the commitment.
     * @param _tokenAddress The address of the asset for which the commitment is being removed.
     * @param _principal The amount of currency to borrow for the loan.
     * @param _loanDuration The loan duration for the TellerV2 loan.
     * @param _interestRate The interest rate for the TellerV2 loan.
     */
    function acceptCommitment(
        uint256 _marketId,
        address _lender,
        address _tokenAddress,
        uint256 _principal,
        uint32 _loanDuration,
        uint16 _interestRate
    ) external onlyMarketOwner(_marketId) returns (uint256 bidId) {
        address borrower = _msgSender();

        Commitment storage commitment = lenderMarketCommitments[_lender][
            _marketId
        ][_tokenAddress];

        require(
            _principal <= commitment.maxPrincipal,
            "Commitment principal insufficient"
        );
        require(
            _loanDuration <= commitment.maxDuration,
            "Commitment duration insufficient"
        );
        require(
            _interestRate >= commitment.minInterestRate,
            "Interest rate insufficient for commitment"
        );
        require(
            block.timestamp < commitment.expiration,
            "Commitment has expired"
        );

        CreateLoanArgs memory createLoanArgs;
        createLoanArgs.marketId = _marketId;
        createLoanArgs.lendingToken = _tokenAddress;
        createLoanArgs.principal = _principal;
        createLoanArgs.duration = _loanDuration;
        createLoanArgs.interestRate = _interestRate;

        bidId = _submitBid(createLoanArgs, borrower);

        _acceptBid(bidId, _lender);

        _decrementCommitment(_lender, _marketId, _tokenAddress, _principal);

        emit ExercisedCommitment(
            _lender,
            _marketId,
            _tokenAddress,
            _principal,
            bidId
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@mangrovedao/hardhat-test-solidity/test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../TellerV2MarketForwarder.sol";
import { Testable } from "./Testable.sol";
import { LenderCommitmentForwarder } from "../LenderCommitmentForwarder.sol";

contract LenderCommitmentForwarder_Test is Testable, LenderCommitmentForwarder {
    LenderCommitmentTester private tester;
    MockMarketRegistry mockMarketRegistry;

    User private marketOwner;
    User private lender;
    User private borrower;

    address tokenAddress;
    uint256 marketId;
    uint256 maxAmount;
    uint32 maxLoanDuration;
    uint16 minInterestRate;
    uint32 expiration;

    bool acceptBidWasCalled;
    bool submitBidWasCalled;

    constructor()
        LenderCommitmentForwarder(
            address(new LenderCommitmentTester()),
            address(new MockMarketRegistry(address(0)))
        )
    {}

    function setup_beforeAll() public {
        tester = LenderCommitmentTester(address(getTellerV2()));
        mockMarketRegistry = MockMarketRegistry(address(getMarketRegistry()));

        marketOwner = new User(tester, (this));
        borrower = new User(tester, (this));
        lender = new User(tester, (this));
        tester.__setMarketOwner(marketOwner);

        mockMarketRegistry.setMarketOwner(address(marketOwner));

        tokenAddress = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        marketId = 2;
        maxAmount = 100000000000000000000;
        maxLoanDuration = 2480000;
        minInterestRate = 3000;
        expiration = uint32(block.timestamp) + uint32(64000);

        marketOwner.setTrustedMarketForwarder(marketId, address(this));
        lender.approveMarketForwarder(marketId, address(this));

        delete acceptBidWasCalled;
        delete submitBidWasCalled;
    }

    function updateCommitment_before() public {
        super.updateCommitment(
            marketId,
            tokenAddress,
            maxAmount,
            maxLoanDuration,
            minInterestRate,
            expiration
        );
    }

    function updateCommitment_test() public {
        Commitment memory existingCommitment = lenderMarketCommitments[
            address(this)
        ][marketId][tokenAddress];

        //make sure the commitment exists
        //        Test.eq(existingCommitment.amount, maxAmount, "Commitment not recorded!" );
    }

    function deleteCommitment_test() public {
        //make sure the commitment exists
        //Test.eq( ,  ,"" );
        //        super.deleteCommitment(tokenAddress, marketId);
        //        Commitment memory existingCommitment = lenderMarketCommitments[address(this)][marketId][tokenAddress];
        //make sure the commitment has been removed
        //Test.eq( ,  ,"" );
    }

    function acceptCommitment_before() public {
        lender._updateCommitment(
            marketId,
            tokenAddress,
            maxAmount,
            maxLoanDuration,
            minInterestRate,
            expiration
        );
    }

    function acceptCommitment_test() public {
        Commitment storage commitment = lenderMarketCommitments[
            address(lender)
        ][marketId][tokenAddress];

        Test.eq(
            acceptBidWasCalled,
            false,
            "Expect accept bid not called before exercise"
        );

        uint256 bidId = marketOwner._acceptCommitment(
            marketId,
            address(lender),
            tokenAddress,
            maxAmount - 100,
            maxLoanDuration,
            minInterestRate
        );

        Test.eq(
            acceptBidWasCalled,
            true,
            "Expect accept bid called after exercise"
        );

        Test.eq(
            commitment.maxPrincipal == 100,
            true,
            "commitment not accepted"
        );

        bidId = marketOwner._acceptCommitment(
            marketId,
            address(lender),
            tokenAddress,
            100,
            maxLoanDuration,
            minInterestRate
        );

        Test.eq(commitment.maxPrincipal == 0, true, "commitment not accepted");
    }

    /*
        Overrider methods for exercise 
    */

    function _submitBid(CreateLoanArgs memory, address)
        internal
        override
        returns (uint256 bidId)
    {
        submitBidWasCalled = true;
        return 1;
    }

    function _acceptBid(uint256, address) internal override returns (bool) {
        acceptBidWasCalled = true;

        Test.eq(
            submitBidWasCalled,
            true,
            "Submit bid must be called before accept bid"
        );

        return true;
    }
}

contract User {
    TellerV2Context public immutable context;
    LenderCommitmentForwarder public immutable commitmentForwarder;

    constructor(
        TellerV2Context _context,
        LenderCommitmentForwarder _commitmentForwarder
    ) {
        context = _context;
        commitmentForwarder = _commitmentForwarder;
    }

    function setTrustedMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        context.setTrustedMarketForwarder(_marketId, _forwarder);
    }

    function approveMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        context.approveMarketForwarder(_marketId, _forwarder);
    }

    function _updateCommitment(
        uint256 marketId,
        address tokenAddress,
        uint256 principal,
        uint32 loanDuration,
        uint16 interestRate,
        uint32 expiration
    ) public {
        commitmentForwarder.updateCommitment(
            marketId,
            tokenAddress,
            principal,
            loanDuration,
            interestRate,
            expiration
        );
    }

    function _acceptCommitment(
        uint256 marketId,
        address lender,
        address tokenAddress,
        uint256 principal,
        uint32 loanDuration,
        uint16 interestRate
    ) public returns (uint256) {
        return
            commitmentForwarder.acceptCommitment(
                marketId,
                lender,
                tokenAddress,
                principal,
                loanDuration,
                interestRate
            );
    }
}

contract LenderCommitmentTester is TellerV2Context {
    constructor() TellerV2Context(address(0)) {}

    function __setMarketOwner(User _marketOwner) external {
        marketRegistry = IMarketRegistry(
            address(new MockMarketRegistry(address(_marketOwner)))
        );
    }

    function getSenderForMarket(uint256 _marketId)
        external
        view
        returns (address)
    {
        return _msgSenderForMarket(_marketId);
    }

    function getDataForMarket(uint256 _marketId)
        external
        view
        returns (bytes calldata)
    {
        return _msgDataForMarket(_marketId);
    }
}

contract MockMarketRegistry {
    address private marketOwner;

    constructor(address _marketOwner) {
        marketOwner = _marketOwner;
    }

    function setMarketOwner(address _marketOwner) public {
        marketOwner = _marketOwner;
    }

    function getMarketOwner(uint256) external view returns (address) {
        return address(marketOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@mangrovedao/hardhat-test-solidity/test.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./Testable.sol";
import "../TellerV2.sol";

contract PMT_Test is Testable, TellerV2 {
    Bid __bid;

    constructor() TellerV2(address(0)) {}

    function _01_pmt_test() public {
        __bid.loanDetails.principal = 10000e6; // 10k USDC
        __bid.loanDetails.loanDuration = 365 days * 3; // 3 years
        __bid.terms.paymentCycle = 365 days / 12; // 1 month
        __bid.terms.APR = 300; // 3.0%
        pmt_runner(290812096);
    }

    function _02_pmt_test() public {
        __bid.loanDetails.principal = 100000e6; // 100x USDC
        __bid.loanDetails.loanDuration = 365 days * 10; // 10 years
        __bid.terms.paymentCycle = 365 days / 12; // 1 month
        __bid.terms.APR = 800; // 8.0%
        pmt_runner(1213275944);
    }

    function _03_pmt_test() public {
        __bid.loanDetails.principal = 100000e6; // 100x USDC
        __bid.loanDetails.loanDuration = 365 days * 10; // 10 years
        __bid.terms.paymentCycle = 365 days / 12; // 1 month
        __bid.terms.APR = 0; // 0.0%
        pmt_runner(833333333);
    }

    function pmt_runner(uint256 _expected) private {
        uint256 pmt = NumbersLib.pmt(
            __bid.loanDetails.principal,
            __bid.loanDetails.loanDuration,
            __bid.terms.paymentCycle,
            __bid.terms.APR
        );
        Test.eq(pmt, _expected, "Loan payment for cycle incorrect");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "./draft-ERC20Permit.sol";
import "../../../utils/math/Math.sol";
import "../../../governance/utils/IVotes.sol";
import "../../../utils/math/SafeCast.sol";
import "../../../utils/cryptography/ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is IVotes, ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20Token is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@mangrovedao/hardhat-test-solidity/test.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Testable } from "./Testable.sol";
import { TellerV2Context } from "../TellerV2Context.sol";
import { IMarketRegistry } from "../interfaces/IMarketRegistry.sol";
import { TellerV2MarketForwarder } from "../TellerV2MarketForwarder.sol";

contract MarketForwarder_Test is Testable, TellerV2MarketForwarder {
    MarketForwarderTester private tester;

    MockMarketRegistry mockMarketRegistry;

    uint256 private marketId;
    User private marketOwner;
    User private user1;
    User private user2;

    constructor()
        TellerV2MarketForwarder(
            address(new MarketForwarderTester()),
            address(new MockMarketRegistry(address(0)))
        )
    {}

    function setup_beforeAll() public {
        mockMarketRegistry = MockMarketRegistry(address(getMarketRegistry()));
        tester = MarketForwarderTester(address(getTellerV2()));

        marketOwner = new User(tester);
        user1 = new User(tester);
        user2 = new User(tester);

        tester.__setMarketOwner(marketOwner);

        mockMarketRegistry.setMarketOwner(address(marketOwner));

        delete marketId;
    }

    function setTrustedMarketForwarder_before() public {
        marketOwner.setTrustedMarketForwarder(marketId, address(this));
    }

    function setTrustedMarketForwarder_test() public {
        Test.eq(
            tester.isTrustedMarketForwarder(marketId, address(this)),
            true,
            "Trusted forwarder was not set"
        );
    }

    function approveMarketForwarder_before() public {
        setTrustedMarketForwarder_before();

        user1.approveMarketForwarder(marketId, address(this));
        user2.approveMarketForwarder(marketId, address(this));
    }

    function approveMarketForwarder_test() public {
        Test.eq(
            tester.hasApprovedMarketForwarder(
                marketId,
                address(this),
                address(user1)
            ),
            true,
            "Borrower did not set market forwarder approval"
        );
        Test.eq(
            tester.hasApprovedMarketForwarder(
                marketId,
                address(this),
                address(user2)
            ),
            true,
            "Lender did not set market forwarder approval"
        );
    }

    function forwardUserCall_before() public {
        approveMarketForwarder_before();
    }

    function forwardUserCall_test() public {
        address expectedSender = address(user1);
        address sender = abi.decode(
            _forwardCall(
                abi.encodeWithSelector(
                    MarketForwarderTester.getSenderForMarket.selector,
                    marketId
                ),
                expectedSender
            ),
            (address)
        );
        Test.eq(
            sender,
            expectedSender,
            "Sender address for market does not match expected"
        );

        bytes memory expectedData = abi.encodeWithSelector(
            MarketForwarderTester.getDataForMarket.selector,
            marketId
        );
        bytes memory data = abi.decode(
            _forwardCall(expectedData, expectedSender),
            (bytes)
        );
        Test.eq0(
            data,
            expectedData,
            "Function calldata for market does not match expected"
        );
    }
}

contract User {
    TellerV2Context public immutable context;

    constructor(TellerV2Context _context) {
        context = _context;
    }

    function setTrustedMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        context.setTrustedMarketForwarder(_marketId, _forwarder);
    }

    function approveMarketForwarder(uint256 _marketId, address _forwarder)
        external
    {
        context.approveMarketForwarder(_marketId, _forwarder);
    }
}

contract MarketForwarderTester is TellerV2Context {
    constructor() TellerV2Context(address(0)) {}

    function __setMarketOwner(User _marketOwner) external {
        marketRegistry = IMarketRegistry(
            address(new MockMarketRegistry(address(_marketOwner)))
        );
    }

    function getSenderForMarket(uint256 _marketId)
        external
        view
        returns (address)
    {
        return _msgSenderForMarket(_marketId);
    }

    function getDataForMarket(uint256 _marketId)
        external
        view
        returns (bytes calldata)
    {
        return _msgDataForMarket(_marketId);
    }
}

contract MockMarketRegistry {
    address private marketOwner;

    constructor(address _marketOwner) {
        marketOwner = _marketOwner;
    }

    function setMarketOwner(address _marketOwner) public {
        marketOwner = _marketOwner;
    }

    function getMarketOwner(uint256) external view returns (address) {
        return address(marketOwner);
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../EAS/TellerASResolver.sol";

/**
 * @title A sample AS resolver that checks whether a specific amount of tokens was approved to be included in an attestation.
 */
contract TestASTokenResolver is TellerASResolver {
    using SafeERC20 for IERC20;

    IERC20 private immutable _targetToken;
    uint256 private immutable _targetAmount;

    constructor(IERC20 targetToken, uint256 targetAmount) {
        _targetToken = targetToken;
        _targetAmount = targetAmount;
    }

    function resolve(
        address, /* recipient */
        bytes calldata, /* schema */
        bytes calldata, /* data */
        uint256, /* expirationTime */
        address msgSender
    ) external payable virtual override returns (bool) {
        _targetToken.safeTransferFrom(msgSender, address(this), _targetAmount);

        return true;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";

/**
 * @title A sample AS resolver that checks whether a specific amount of ETH was sent with an attestation.
 */
contract TestASValueResolver is TellerASResolver {
    uint256 private immutable _targetValue;

    constructor(uint256 targetValue) {
        _targetValue = targetValue;
    }

    function isPayable() public pure override returns (bool) {
        return true;
    }

    function resolve(
        address, /* recipient */
        bytes calldata, /* schema */
        bytes calldata, /* data */
        uint256, /* expirationTime */
        address /* msgSender */
    ) external payable virtual override returns (bool) {
        return msg.value == _targetValue;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";

/**
 * @title A sample AS resolver that checks whether the attestation is to a specific recipient.
 */
contract TestASRecipientResolver is TellerASResolver {
    address private immutable _targetRecipient;

    constructor(address targetRecipient) {
        _targetRecipient = targetRecipient;
    }

    function resolve(
        address recipient,
        bytes calldata, /* schema */
        bytes calldata, /* data */
        uint256, /* expirationTime */
        address /* msgSender */
    ) external payable virtual override returns (bool) {
        return recipient == _targetRecipient;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";

/**
 * @title A sample AS resolver that pays attesters
 */
contract TestASPayingResolver is TellerASResolver {
    uint256 private immutable _incentive;

    constructor(uint256 incentive) {
        _incentive = incentive;
    }

    function isPayable() public pure override returns (bool) {
        return true;
    }

    function resolve(
        address recipient,
        bytes calldata, /* schema */
        bytes calldata, /* data */
        uint256, /* expirationTime */
        address /* msgSender */
    ) external payable virtual override returns (bool) {
        payable(recipient).transfer(_incentive);

        return true;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";

/**
 * @title A sample AS resolver that checks whether the expiration time is later than a specific timestamp.
 */
contract TestASExpirationTimeResolver is TellerASResolver {
    uint256 private immutable _validAfter;

    constructor(uint256 validAfter) {
        _validAfter = validAfter;
    }

    function resolve(
        address, /* recipient */
        bytes calldata, /* schema */
        bytes calldata, /* data */
        uint256 expirationTime,
        address /* msgSender */
    ) external payable virtual override returns (bool) {
        return expirationTime >= _validAfter;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";

/**
 * @title A sample AS resolver that checks whether an attestation data is either \x00 or \x01.
 */
contract TestASDataResolver is TellerASResolver {
    function resolve(
        address, /* recipient */
        bytes calldata, /* schema */
        bytes calldata data,
        uint256, /* expirationTime */
        address /* msgSender */
    ) external payable virtual override returns (bool) {
        // Verifies that the data is either 0 or 1.
        return data.length == 1 && (data[0] == "\x00" || data[0] == "\x01");
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";

/**
 * @title A sample AS resolver that checks whether the attestation is from a specific attester.
 */
contract TestASAttesterResolver is TellerASResolver {
    address private immutable _targetAttester;

    constructor(address targetAttester) {
        _targetAttester = targetAttester;
    }

    function resolve(
        address, /* recipient */
        bytes calldata, /* schema */
        bytes calldata, /* data */
        uint256, /* expirationTime */
        address msgSender
    ) external payable virtual override returns (bool) {
        return msgSender == _targetAttester;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../../EAS/TellerASResolver.sol";
import "../../EAS/TellerAS.sol";

/**
 * @title A sample AS resolver that checks whether an attestations attest to an existing attestation.
 */
contract TestASAttestationResolver is TellerASResolver {
    error Overflow();
    error OutOfBounds();

    TellerAS private immutable _eas;

    constructor(TellerAS eas) {
        _eas = eas;
    }

    function resolve(
        address, /* recipient */
        bytes calldata, /* schema */
        bytes calldata data,
        uint256, /* expirationTime */
        address /* msgSender */
    ) external payable virtual override returns (bool) {
        return _eas.isAttestationValid(_toBytes32(data, 0));
    }

    function _toBytes32(bytes memory data, uint256 start)
        private
        pure
        returns (bytes32)
    {
        if (start + 32 < start) {
            revert Overflow();
        }

        if (data.length < start + 32) {
            revert OutOfBounds();
        }

        bytes32 tempBytes32;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempBytes32 := mload(add(add(data, 0x20), start))
        }

        return tempBytes32;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../Types.sol";
import "../interfaces/IASRegistry.sol";
import "../interfaces/IASResolver.sol";

/**
 * @title The global AS registry.
 */
contract TellerASRegistry is IASRegistry {
    error AlreadyExists();

    string public constant VERSION = "0.8";

    // The global mapping between AS records and their IDs.
    mapping(bytes32 => ASRecord) private _registry;

    // The global counter for the total number of attestations.
    uint256 private _asCount;

    /**
     * @inheritdoc IASRegistry
     */
    function register(bytes calldata schema, IASResolver resolver)
        external
        override
        returns (bytes32)
    {
        uint256 index = ++_asCount;

        ASRecord memory asRecord = ASRecord({
            uuid: EMPTY_UUID,
            index: index,
            schema: schema,
            resolver: resolver
        });

        bytes32 uuid = _getUUID(asRecord);
        if (_registry[uuid].uuid != EMPTY_UUID) {
            revert AlreadyExists();
        }

        asRecord.uuid = uuid;
        _registry[uuid] = asRecord;

        emit Registered(uuid, index, schema, resolver, msg.sender);

        return uuid;
    }

    /**
     * @inheritdoc IASRegistry
     */
    function getAS(bytes32 uuid)
        external
        view
        override
        returns (ASRecord memory)
    {
        return _registry[uuid];
    }

    /**
     * @inheritdoc IASRegistry
     */
    function getASCount() external view override returns (uint256) {
        return _asCount;
    }

    /**
     * @dev Calculates a UUID for a given AS.
     *
     * @param asRecord The input AS.
     *
     * @return AS UUID.
     */
    function _getUUID(ASRecord memory asRecord) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(asRecord.schema, asRecord.resolver));
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../interfaces/IEASEIP712Verifier.sol";

/**
 * @title EIP712 typed signatures verifier for EAS delegated attestations.
 */
contract TellerASEIP712Verifier is IEASEIP712Verifier {
    error InvalidSignature();

    string public constant VERSION = "0.8";

    // EIP712 domain separator, making signatures from different domains incompatible.
    bytes32 public immutable DOMAIN_SEPARATOR; // solhint-disable-line var-name-mixedcase

    // The hash of the data type used to relay calls to the attest function. It's the value of
    // keccak256("Attest(address recipient,bytes32 schema,uint256 expirationTime,bytes32 refUUID,bytes data,uint256 nonce)").
    bytes32 public constant ATTEST_TYPEHASH =
        0x39c0608dd995a3a25bfecb0fffe6801a81bae611d94438af988caa522d9d1476;

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    // keccak256("Revoke(bytes32 uuid,uint256 nonce)").
    bytes32 public constant REVOKE_TYPEHASH =
        0xbae0931f3a99efd1b97c2f5b6b6e79d16418246b5055d64757e16de5ad11a8ab;

    // Replay protection nonces.
    mapping(address => uint256) private _nonces;

    /**
     * @dev Creates a new EIP712Verifier instance.
     */
    constructor() {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("EAS")),
                keccak256(bytes(VERSION)),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @inheritdoc IEASEIP712Verifier
     */
    function getNonce(address account)
        external
        view
        override
        returns (uint256)
    {
        return _nonces[account];
    }

    /**
     * @inheritdoc IEASEIP712Verifier
     */
    function attest(
        address recipient,
        bytes32 schema,
        uint256 expirationTime,
        bytes32 refUUID,
        bytes calldata data,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        ATTEST_TYPEHASH,
                        recipient,
                        schema,
                        expirationTime,
                        refUUID,
                        keccak256(data),
                        _nonces[attester]++
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress == address(0) || recoveredAddress != attester) {
            revert InvalidSignature();
        }
    }

    /**
     * @inheritdoc IEASEIP712Verifier
     */
    function revoke(
        bytes32 uuid,
        address attester,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(REVOKE_TYPEHASH, uuid, _nonces[attester]++)
                )
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress == address(0) || recoveredAddress != attester) {
            revert InvalidSignature();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSAUpgradeable.sol";
import "../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract MinimalForwarderUpgradeable is Initializable, EIP712Upgradeable {
    using ECDSAUpgradeable for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    function __MinimalForwarder_init() internal onlyInitializing {
        __EIP712_init_unchained("MinimalForwarder", "0.0.1");
    }

    function __MinimalForwarder_init_unchained() internal onlyInitializing {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/metatx/MinimalForwarderUpgradeable.sol";

contract MetaForwarder is MinimalForwarderUpgradeable {
    function initialize() external initializer {
        __EIP712_init_unchained("TellerMetaForwarder", "0.0.1");
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./ProtocolFee.sol";

contract ProtocolFeeMock is ProtocolFee {
    bool public setProtocolFeeCalled;

    function initialize(uint16 _initFee) external initializer {
        __ProtocolFee_init(_initFee);
    }

    function setProtocolFee(uint16 newFee) public override onlyOwner {
        setProtocolFeeCalled = true;

        bool _isInitializing;
        assembly {
            _isInitializing := sload(1)
        }

        // Only call the actual function if we are not initializing
        if (!_isInitializing) {
            super.setProtocolFee(newFee);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@mangrovedao/hardhat-test-solidity/test.sol";

import "./Testable.sol";
import "../TellerV2.sol";

contract GetMetaDataURI_Test is Testable, TellerV2 {
    constructor() TellerV2(address(0)) {}

    function setup_beforeAll() public {
        // Old depreciated _metadataURI on bid struct
        bids[0]
            ._metadataURI = 0x0000000000000000000000000000000086004f3f419f88be1cab574b4bd01b6d;
        // New metadataURI from uris mapping
        uris[59] = "ipfs://QmMyDataHash";
    }

    function getMetaDataURI_test() public {
        string memory oldURI = getMetadataURI(0);
        Test.eq(
            oldURI,
            "0x0000000000000000000000000000000086004f3f419f88be1cab574b4bd01b6d",
            "Expected URI does not match stored depreciated value in the Bid struct"
        );
        string memory newURI = getMetadataURI(59);
        Test.eq(
            newURI,
            "ipfs://QmMyDataHash",
            "Expected URI does not match new value in uri mapping"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TLR is ERC20Votes, Ownable {
    uint224 private immutable MAX_SUPPLY;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint224 _supplyCap, address tokenOwner)
        ERC20("Teller", "TLR")
        ERC20Permit("Teller")
    {
        require(_supplyCap > 0, "ERC20Capped: cap is 0");
        MAX_SUPPLY = _supplyCap;
        _transferOwnership(tokenOwner);
    }

    /**
     * @dev Max supply has been overridden to cap the token supply upon initialization of the contract
     * @dev See OpenZeppelin's implementation of ERC20Votes _mint() function
     */
    function _maxSupply() internal view override returns (uint224) {
        return MAX_SUPPLY;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./TellerV2.sol";

contract TellerV2Mock is TellerV2 {
    constructor(address trustedForwarder) TellerV2(trustedForwarder) {}

    function mockBid(Bid calldata _bid) external {
        bids[bidId] = _bid;
        borrowerBids[_msgSender()].push(bidId);
        bidId++;
    }

    function mockAcceptedTimestamp(uint256 _bidId, uint32 _timestamp) external {
        require(_timestamp > 0, "Accepted timestamp 0");
        bids[_bidId].loanDetails.acceptedTimestamp = _timestamp;
    }

    function mockAcceptedTimestamp(uint256 _bidId) external {
        bids[_bidId].loanDetails.acceptedTimestamp = uint32(block.timestamp);
    }

    function mockLastRepaidTimestamp(uint256 _bidId, uint32 _timestamp)
        external
    {
        require(_timestamp > 0, "Repaid timestamp 0");
        bids[_bidId].loanDetails.lastRepaidTimestamp = _timestamp;
    }

    function setVersion(uint256 _version) public {
        version = _version;
    }
}

pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

// Contracts
import "../TellerV2.sol";

contract TellerV2__Goerli_Commitment_Forwarder_Fix is TellerV2 {
    constructor(address _trustedForwarder) TellerV2(_trustedForwarder) {}

    function setLenderCommitmentForwarder(address _lenderCommitmentForwarder)
        external
    {
        require(
            lenderCommitmentForwarder == address(0),
            "Teller: lender commitment forwarder already set"
        );
        lenderCommitmentForwarder = _lenderCommitmentForwarder;
    }
}