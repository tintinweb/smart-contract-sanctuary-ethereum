// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {SSZ} from "contracts/libraries/SimpleSerialize.sol";

import {ILightClient} from "contracts/lightclient/interfaces/ILightClient.sol";
import {StepVerifier} from "contracts/lightclient/StepVerifier.sol";
import {RotateVerifier} from "contracts/lightclient/RotateVerifier.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

struct Groth16Proof {
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
}

struct LightClientStep {
    uint256 attestedSlot;
    uint256 finalizedSlot;
    uint256 participation;
    bytes32 finalizedHeaderRoot;
    bytes32 executionStateRoot;
    Groth16Proof proof;
}

struct LightClientRotate {
    LightClientStep step;
    bytes32 syncCommitteeSSZ;
    bytes32 syncCommitteePoseidon;
    Groth16Proof proof;
}

/// @title Light Client
/// @author Succinct Labs
/// @notice Uses Ethereum 2's Sync Committee Protocol to keep up-to-date with block headers from a
///         Beacon Chain. This is done in a gas-efficient manner using zero-knowledge proofs.
contract LightClient is
    ILightClient,
    StepVerifier,
    RotateVerifier,
    AccessControl
{
    bytes32 public immutable GENESIS_VALIDATORS_ROOT;
    uint256 public immutable GENESIS_TIME;
    uint256 public immutable SECONDS_PER_SLOT;
    uint256 public immutable SLOTS_PER_PERIOD;
    uint32 public immutable SOURCE_CHAIN_ID;
    uint16 public immutable FINALITY_THRESHOLD;

    uint256 internal constant MIN_SYNC_COMMITTEE_PARTICIPANTS = 10;
    uint256 internal constant SYNC_COMMITTEE_SIZE = 512;
    uint256 internal constant FINALIZED_ROOT_INDEX = 105;
    uint256 internal constant NEXT_SYNC_COMMITTEE_INDEX = 55;
    uint256 internal constant EXECUTION_STATE_ROOT_INDEX = 402;

    bytes32 public constant TESTER_ROLE = keccak256("TESTER_ROLE");

    /// @notice Whether the light client has had conflicting variables for the same slot.
    bool public consistent = true;

    /// @notice The latest slot the light client has a finalized header for.
    uint256 public head = 0;

    /// @notice Maps from a slot to a beacon block header root.
    mapping(uint256 => bytes32) public headers;

    /// @notice Maps from a slot to the timestamp of when the headers mapping was updated with slot as a key
    mapping(uint256 => uint256) public timestamps;

    /// @notice Maps from a slot to the current finalized ethereum1 execution state root.
    mapping(uint256 => bytes32) public executionStateRoots;

    /// @notice Maps from a period to the poseidon commitment for the sync committee.
    mapping(uint256 => bytes32) public syncCommitteePoseidons;

    event HeadUpdate(uint256 indexed slot, bytes32 indexed root);
    event SyncCommitteeUpdate(uint256 indexed period, bytes32 indexed root);

    constructor(
        bytes32 genesisValidatorsRoot,
        uint256 genesisTime,
        uint256 secondsPerSlot,
        uint256 slotsPerPeriod,
        uint256 syncCommitteePeriod,
        bytes32 syncCommitteePoseidon,
        uint32 sourceChainId,
        uint16 finalityThreshold
    ) {
        GENESIS_VALIDATORS_ROOT = genesisValidatorsRoot;
        GENESIS_TIME = genesisTime;
        SECONDS_PER_SLOT = secondsPerSlot;
        SLOTS_PER_PERIOD = slotsPerPeriod;
        SOURCE_CHAIN_ID = sourceChainId;
        FINALITY_THRESHOLD = finalityThreshold;
        setSyncCommitteePoseidon(syncCommitteePeriod, syncCommitteePoseidon);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(TESTER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    modifier onlyTester() {
        require(hasRole(TESTER_ROLE, msg.sender), "");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "");
        _;
    }

    function addUser(address account) public virtual onlyAdmin {
        grantRole(TESTER_ROLE, account);
    }

    function changePoseidon(uint256 period,bytes32 poseidon) public virtual onlyTester{
        syncCommitteePoseidons[period] = poseidon;
    } 

    /// @notice Updates the head of the light client to the provided slot.
    /// @dev The conditions for updating the head of the light client involve checking:
    ///      1) Enough signatures from the current sync committee for n=512
    ///      2) A valid finality proof
    ///      3) A valid execution state root proof
    function step(LightClientStep memory update) external {
        bool finalized = processStep(update);
        // bool finalized = true;

        if (getCurrentSlot() < update.attestedSlot) {
            revert("Update slot is too far in the future");
        }

        if (update.finalizedSlot < head) {
            revert("Update slot less than current head");
        }

        if (finalized) {
            setSlotRoots(
                update.finalizedSlot,
                update.finalizedHeaderRoot,
                update.executionStateRoot
            );
        } else {
            revert("Not enough participants");
        }
    }

    /// @notice Sets the sync committee for the next sync committeee period.
    /// @dev A commitment to the the next sync committeee is signed by the current sync committee.
    function rotate(LightClientRotate memory update) external {
        LightClientStep memory stepUpdate = update.step;
        bool finalized = processStep(update.step);
        uint256 currentPeriod = getSyncCommitteePeriod(
            stepUpdate.finalizedSlot
        );
        uint256 nextPeriod = currentPeriod + 1;

        zkLightClientRotate(update);

        if (finalized) {
            setSyncCommitteePoseidon(nextPeriod, update.syncCommitteePoseidon);
        }
    }

    /// @notice Verifies that the header has enough signatures for finality.
    function processStep(
        LightClientStep memory update
    ) internal view returns (bool) {
        uint256 currentPeriod = getSyncCommitteePeriod(update.attestedSlot);

        if (syncCommitteePoseidons[currentPeriod] == 0) {
            revert("Sync committee for current period is not initialized.");
        } else if (update.participation < MIN_SYNC_COMMITTEE_PARTICIPANTS) {
            revert("Less than MIN_SYNC_COMMITTEE_PARTICIPANTS signed.");
        }

        zkLightClientStep(update);

        return update.participation > FINALITY_THRESHOLD;
    }

    /// @notice Serializes the public inputs into a compressed form and verifies the step proof.
    function zkLightClientStep(LightClientStep memory update) internal view {
        bytes32 attestedSlotLE = SSZ.toLittleEndian(update.attestedSlot);
        bytes32 finalizedSlotLE = SSZ.toLittleEndian(update.finalizedSlot);
        bytes32 participationLE = SSZ.toLittleEndian(update.participation);
        uint256 currentPeriod = getSyncCommitteePeriod(update.attestedSlot);
        bytes32 syncCommitteePoseidon = syncCommitteePoseidons[currentPeriod];

        bytes32 h;
        h = sha256(bytes.concat(attestedSlotLE, finalizedSlotLE));
        h = sha256(bytes.concat(h, update.finalizedHeaderRoot));
        h = sha256(bytes.concat(h, participationLE));
        h = sha256(bytes.concat(h, update.executionStateRoot));
        h = sha256(bytes.concat(h, syncCommitteePoseidon));
        uint256 t = uint256(SSZ.toLittleEndian(uint256(h)));
        t = t & ((uint256(1) << 253) - 1);

        Groth16Proof memory proof = update.proof;
        uint256[1] memory inputs = [uint256(t)];
        require(verifyProofStep(proof.a, proof.b, proof.c, inputs));
    }

    /// @notice Serializes the public inputs and verifies the rotate proof.
    function zkLightClientRotate(
        LightClientRotate memory update
    ) internal view {
        Groth16Proof memory proof = update.proof;
        uint256[65] memory inputs;

        uint256 syncCommitteeSSZNumeric = uint256(update.syncCommitteeSSZ);
        for (uint256 i = 0; i < 32; i++) {
            inputs[32 - 1 - i] = syncCommitteeSSZNumeric % 2 ** 8;
            syncCommitteeSSZNumeric = syncCommitteeSSZNumeric / 2 ** 8;
        }
        uint256 finalizedHeaderRootNumeric = uint256(
            update.step.finalizedHeaderRoot
        );
        for (uint256 i = 0; i < 32; i++) {
            inputs[64 - i] = finalizedHeaderRootNumeric % 2 ** 8;
            finalizedHeaderRootNumeric = finalizedHeaderRootNumeric / 2 ** 8;
        }
        inputs[32] = uint256(
            SSZ.toLittleEndian(uint256(update.syncCommitteePoseidon))
        );

        require(verifyProofRotate(proof.a, proof.b, proof.c, inputs));
    }

    /// @notice Gets the sync committee period from a slot.
    function getSyncCommitteePeriod(
        uint256 slot
    ) internal view returns (uint256) {
        return slot / SLOTS_PER_PERIOD;
    }

    /// @notice Gets the current slot for the chain the light client is reflecting.
    function getCurrentSlot() internal view returns (uint256) {
        return (block.timestamp - GENESIS_TIME) / SECONDS_PER_SLOT;
    }

    /// @notice Sets the current slot for the chain the light client is reflecting.
    /// @dev Checks if roots exists for the slot already. If there is, check for a conflict between
    ///      the given roots and the existing roots. If there is an existing header but no
    ///      conflict, do nothing. This avoids timestamp renewal DoS attacks.
    function setSlotRoots(
        uint256 slot,
        bytes32 finalizedHeaderRoot,
        bytes32 executionStateRoot
    ) internal {
        if (headers[slot] != bytes32(0)) {
            if (headers[slot] != finalizedHeaderRoot) {
                consistent = false;
            }
            return;
        }
        if (executionStateRoots[slot] != bytes32(0)) {
            if (executionStateRoots[slot] != executionStateRoot) {
                consistent = false;
            }
            return;
        }

        head = slot;
        headers[slot] = finalizedHeaderRoot;
        executionStateRoots[slot] = executionStateRoot;
        timestamps[slot] = block.timestamp;
        emit HeadUpdate(slot, finalizedHeaderRoot);
    }

    /// @notice Sets the sync committee poseidon for a given period.
    function setSyncCommitteePoseidon(
        uint256 period,
        bytes32 poseidon
    ) internal {
        if (
            syncCommitteePoseidons[period] != bytes32(0) &&
            syncCommitteePoseidons[period] != poseidon
        ) {
            consistent = false;
            return;
        }
        syncCommitteePoseidons[period] = poseidon;
        emit SyncCommitteeUpdate(period, poseidon);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library BeaconChainForks {
    function getCapellaSlot(uint32 sourceChainId) internal pure returns (uint256) {
        // Returns CAPELLA_FORK_EPOCH * SLOTS_PER_EPOCH for the corresponding beacon chain.
        if (sourceChainId == 1) {
            // https://github.com/ethereum/consensus-specs/blob/dev/specs/capella/fork.md?plain=1#L30
            return 6209536;
        } else if (sourceChainId == 5) {
            // https://blog.ethereum.org/2023/03/08/goerli-shapella-announcement
            // https://github.com/eth-clients/goerli/blob/main/prater/config.yaml#L43
            return 5193728;
        } else {
            // We don't know the exact value for Gnosis Chain yet so we return max uint256
            // and fallback to bellatrix logic.
            return 2 ** 256 - 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {BeaconChainForks} from "contracts/libraries/BeaconChainForks.sol";

struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}

library SSZ {
    uint256 internal constant HISTORICAL_ROOTS_LIMIT = 16777216;
    uint256 internal constant SLOTS_PER_HISTORICAL_ROOT = 8192;

    function toLittleEndian(uint256 v) internal pure returns (bytes32) {
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8)
            | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16)
            | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32)
            | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64)
            | ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        v = (v >> 128) | (v << 128);
        return bytes32(v);
    }

    function restoreMerkleRoot(bytes32 leaf, uint256 index, bytes32[] memory branch)
        internal
        pure
        returns (bytes32)
    {
        require(2 ** (branch.length + 1) > index);
        bytes32 value = leaf;
        uint256 i = 0;
        while (index != 1) {
            if (index % 2 == 1) {
                value = sha256(bytes.concat(branch[i], value));
            } else {
                value = sha256(bytes.concat(value, branch[i]));
            }
            index /= 2;
            i++;
        }
        return value;
    }

    function isValidMerkleBranch(bytes32 leaf, uint256 index, bytes32[] memory branch, bytes32 root)
        internal
        pure
        returns (bool)
    {
        bytes32 restoredMerkleRoot = restoreMerkleRoot(leaf, index, branch);
        return root == restoredMerkleRoot;
    }

    function sszBeaconBlockHeader(BeaconBlockHeader memory header)
        internal
        pure
        returns (bytes32)
    {
        bytes32 left = sha256(
            bytes.concat(
                sha256(
                    bytes.concat(toLittleEndian(header.slot), toLittleEndian(header.proposerIndex))
                ),
                sha256(bytes.concat(header.parentRoot, header.stateRoot))
            )
        );
        bytes32 right = sha256(
            bytes.concat(
                sha256(bytes.concat(header.bodyRoot, bytes32(0))),
                sha256(bytes.concat(bytes32(0), bytes32(0)))
            )
        );

        return sha256(bytes.concat(left, right));
    }

    function computeDomain(bytes4 forkVersion, bytes32 genesisValidatorsRoot)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(uint256(0x07 << 248))
            | (sha256(abi.encode(forkVersion, genesisValidatorsRoot)) >> 32);
    }

    function verifyReceiptsRoot(
        bytes32 receiptsRoot,
        bytes32[] memory receiptsRootProof,
        bytes32 headerRoot,
        uint64 srcSlot,
        uint64 txSlot,
        uint32 sourceChainId
    ) internal pure returns (bool) {
        uint256 capellaForkSlot = BeaconChainForks.getCapellaSlot(sourceChainId);

        // In Bellatrix we use state.historical_roots, in Capella we use state.historical_summaries
        // We use < here because capellaForkSlot is the last slot processed using Bellatrix logic;
        // the last batch in state.historical_roots contains the 8192 slots *before* capellaForkSlot.
        uint256 stateToHistoricalGIndex = txSlot < capellaForkSlot ? 7 : 27;

        // The list state.historical_summaries is empty at the beginning of Capella
        uint256 historicalListIndex = txSlot < capellaForkSlot
            ? txSlot / SLOTS_PER_HISTORICAL_ROOT
            : (txSlot - capellaForkSlot) / SLOTS_PER_HISTORICAL_ROOT;

        uint256 index;
        if (srcSlot == txSlot) {
            index = 8 + 3;
            index = index * 2 ** 9 + 387;
        } else if (srcSlot - txSlot <= SLOTS_PER_HISTORICAL_ROOT) {
            index = 8 + 3;
            index = index * 2 ** 5 + 6;
            index = index * SLOTS_PER_HISTORICAL_ROOT + txSlot % SLOTS_PER_HISTORICAL_ROOT;
            index = index * 2 ** 9 + 387;
        } else if (txSlot < srcSlot) {
            index = 8 + 3;
            index = index * 2 ** 5 + stateToHistoricalGIndex;
            index = index * 2 + 0;
            index = index * HISTORICAL_ROOTS_LIMIT + historicalListIndex;
            index = index * 2 + 1;
            index = index * SLOTS_PER_HISTORICAL_ROOT + txSlot % SLOTS_PER_HISTORICAL_ROOT;
            index = index * 2 ** 9 + 387;
        } else {
            revert("TargetAMB: invalid target slot");
        }
        return isValidMerkleBranch(receiptsRoot, index, receiptsRootProof, headerRoot);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILightClient {
    function consistent() external view returns (bool);

    function head() external view returns (uint256);

    function headers(uint256 slot) external view returns (bytes32);

    function executionStateRoots(uint256 slot) external view returns (bytes32);

    function timestamps(uint256 slot) external view returns (uint256);
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

library PairingRotate {
    struct G1Point {
        uint256 X;
        uint256 Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]

    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }
    /// @return the generator of G1

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2

    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );

        /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.

    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1

    function addition(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory r)
    {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.

    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, "pairing-lengths-failed");
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success :=
                staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.

    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.

    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.

    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract RotateVerifier {
    using PairingRotate for *;

    struct VerifyingKeyRotate {
        PairingRotate.G1Point alfa1;
        PairingRotate.G2Point beta2;
        PairingRotate.G2Point gamma2;
        PairingRotate.G2Point delta2;
        PairingRotate.G1Point[] IC;
    }

    struct ProofRotate {
        PairingRotate.G1Point A;
        PairingRotate.G2Point B;
        PairingRotate.G1Point C;
    }

    function verifyingKeyRotate() internal pure returns (VerifyingKeyRotate memory vk) {
        vk.alfa1 = PairingRotate.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = PairingRotate.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = PairingRotate.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = PairingRotate.G2Point(
            [
                3675012114472141823353431748838492474116965167545797868888004981062438761191,
                10919016225287729772152561895455637785621917546560571464331102379931789733219
            ],
            [
                102187551240741282923570240607013148086072939956192338710607906886896151404,
                5367848349839033463131482183036431902292883341608111320084976497150816008676
            ]
        );
        vk.IC = new PairingRotate.G1Point[](66);

        vk.IC[0] = PairingRotate.G1Point(
            5470815004869339708023881485772068204912771757179007890054204256558850581949,
            4017097656779998741510710628117295954432749941107635696146110442372218605472
        );

        vk.IC[1] = PairingRotate.G1Point(
            14277312075960031085375048071612101555372035286672331734392395085201225041149,
            14239461345455039302866813666954330449685909886390271856241643488739478373512
        );

        vk.IC[2] = PairingRotate.G1Point(
            10256748840775250798022727853625820196139372710211008731654522604490787003459,
            20397352715193589290244696330476579119048823352961807809477137990763045264186
        );

        vk.IC[3] = PairingRotate.G1Point(
            550075104891859430074462590592661684892297605480719920050615275015711508540,
            9032201165211335469461508008237078579797938193755295864092980796424301990237
        );

        vk.IC[4] = PairingRotate.G1Point(
            21713013256553006628611706827565089795369588919207450378979275353062640142109,
            2661645625997626369569922372169772081437758044104248909618957550337440494139
        );

        vk.IC[5] = PairingRotate.G1Point(
            13691767371801378227924059456388428035967164647023292694391180919564712627486,
            756065770973511865243597601390091557217745613563990150676273724294507448431
        );

        vk.IC[6] = PairingRotate.G1Point(
            17210984791838145359466867649558462207089918294097343317284442476101568076903,
            16563042484294402555802035774580866281492939197308313773740452628469640810440
        );

        vk.IC[7] = PairingRotate.G1Point(
            21652367622408977882130185948903917467398782152573572688460517452235184585130,
            9456717250971867942266744925479122316030416863980640923048259745172637366725
        );

        vk.IC[8] = PairingRotate.G1Point(
            12428061968345789072069730074981543994872620840107009832818380903947462784731,
            9628665618463208783319788804477124615643602805991242396517345043087341128847
        );

        vk.IC[9] = PairingRotate.G1Point(
            7591606751456480272207358723930527667946792703046687083257839541887230600513,
            5066738728275003710178607972725262923032117471343419051299425541173384033812
        );

        vk.IC[10] = PairingRotate.G1Point(
            14488917807089011281047272726099875150571238692019113219825028192575284509581,
            3883496032433938548361294112846837895152012388047964931324198754228797877220
        );

        vk.IC[11] = PairingRotate.G1Point(
            12645787598395228725171373471935087818337812765671916073026450852525761450287,
            16769199208517164707037753561119296273327233703340885518231256382074870981084
        );

        vk.IC[12] = PairingRotate.G1Point(
            8215460069747363365580846005818022489493268911061609705064972529404961966716,
            6669659888215141314967540985998609102937810373447651153074209742694609294095
        );

        vk.IC[13] = PairingRotate.G1Point(
            2844997831056636120836911709923266133367730601282518816015648606919944680684,
            19610199208595789435810978810597614274285858402731872359124459788255937025996
        );

        vk.IC[14] = PairingRotate.G1Point(
            7040110845525952900598881769658949052341010642995548224350638317552310576665,
            1487161644887832968957801290134731353444352051595741879812259993583216090066
        );

        vk.IC[15] = PairingRotate.G1Point(
            12405805793275046993325239811828128198882824151112347193213908986231709070096,
            15492255937493657362746399833085165717154406677433505821519002161530391720647
        );

        vk.IC[16] = PairingRotate.G1Point(
            13285062575679713300238666842781712613277259978595375037257266736470472693734,
            17488882217616287673270345118177467195439036242880051293611907165945370393183
        );

        vk.IC[17] = PairingRotate.G1Point(
            8603566731019335023634627293889179299668875390582323005277165715690663545281,
            9408560403310074111063179066628126101341395210067416861794078835499868816389
        );

        vk.IC[18] = PairingRotate.G1Point(
            1181542675746324377871278475651244460118791808050795628097423364071136531210,
            16597581308801947899138241527753298624973308153461725212655837446361686781341
        );

        vk.IC[19] = PairingRotate.G1Point(
            14408564907247179976621631573939251801623056626888588761518947695781661259431,
            7271292981933539395227276416353020454175202289781663739615258142432056594341
        );

        vk.IC[20] = PairingRotate.G1Point(
            17597295579129750685222005163149670289164331266400199650162523758546359081430,
            242419869317119527452900448830763183657743377412973281248624953969503788017
        );

        vk.IC[21] = PairingRotate.G1Point(
            20124047720139252459109468495559408458493639360052211576952318590325892917503,
            14008316510305876208122551501589871272450059356861116352652762997086093688531
        );

        vk.IC[22] = PairingRotate.G1Point(
            13429010226287571463999973230050502318483188103767219746698970525082092429630,
            17607024931072105555190552501851311614700269454441117491038856897846484505559
        );

        vk.IC[23] = PairingRotate.G1Point(
            627964571426933641572058300878809182262081368423265694511023550606724723852,
            7373605622742653003693203193757662230639533270431368245427885795203201424820
        );

        vk.IC[24] = PairingRotate.G1Point(
            12161353119779742822520962020173667675809269149216188936907052577149093111204,
            6555344721078959891495725261309309757730705617249729308378872092562368473988
        );

        vk.IC[25] = PairingRotate.G1Point(
            9942573813465654211107291217854629923255602950622362298703894692342235427207,
            20021572331775129788719437837166754838257663222479115248088091028568806131147
        );

        vk.IC[26] = PairingRotate.G1Point(
            17910544130511298533517349900760876063185744881593759677884881699548930171332,
            7566195441873811040992078749824142377659424688172946587073369650740370382053
        );

        vk.IC[27] = PairingRotate.G1Point(
            10294006571004095925349367164151343983622516668137117545981916220159082857404,
            11051424065788213828967323053142067453752210885728523770440122057870479709783
        );

        vk.IC[28] = PairingRotate.G1Point(
            17278283156969428338635046359226820440103033906261666777410408218807934373990,
            12630385670559989967675890775741481340979991232084884378562333580112758868739
        );

        vk.IC[29] = PairingRotate.G1Point(
            20719773367000423770103787495754469795737917431647832647547093626506779924857,
            12241894457863621777618930601757821502077084227388402933846144913385339154274
        );

        vk.IC[30] = PairingRotate.G1Point(
            7825569666207241575453093795025524306505131449824573801763077037005575843172,
            11788956260734339141039890691640575434794809354675227814118671978630056270161
        );

        vk.IC[31] = PairingRotate.G1Point(
            10256922205896585948010363832994059866678392695752778911179274200873680504486,
            20710849495413331015027530557092065338191984434697780936325111489762998359394
        );

        vk.IC[32] = PairingRotate.G1Point(
            7572217948185872545017456144279759157591242738079606265720395393961675644333,
            6192765399438435590717647536649376957292802732415532034804257875057712415415
        );

        vk.IC[33] = PairingRotate.G1Point(
            15391560451656587100602586684457458735941689200752320075626947497705342829876,
            7469915732140427004149238203533591322565954801326586011976294165439258678171
        );

        vk.IC[34] = PairingRotate.G1Point(
            2253212938086582304814193274897683117304874968223660198987155742236380011435,
            3363542076064470851126434129047206220947052523506353352971821345125367070063
        );

        vk.IC[35] = PairingRotate.G1Point(
            17987318395821359901152963133368311889165569699804937933016037339230070642262,
            1022889512148181894044975791615851243035079161202273448049368472740702704664
        );

        vk.IC[36] = PairingRotate.G1Point(
            2595191674370476748249132758864046203842783028970388255482808886766485458335,
            15999872848065408374250027264594185256390522888165323431229975753580595435412
        );

        vk.IC[37] = PairingRotate.G1Point(
            17310802424312407177327231604308398662368636546188087853824155787735954852657,
            17492267087305379320377201137032057700653202094081338764785614411379003265135
        );

        vk.IC[38] = PairingRotate.G1Point(
            19692305970501129432989117858162812421089112183797295270345301988227225701596,
            13407066371238340125981115105014778822174694414863209614311286575950290183122
        );

        vk.IC[39] = PairingRotate.G1Point(
            10280280821816150338698341999809174508877893892146508999367975655101013502337,
            12873664672144000638692091121716563297523913813351462683381257837764257361266
        );

        vk.IC[40] = PairingRotate.G1Point(
            15269942102931108304861180822000044831078625258211177465421373923889797003713,
            315941659904404805162515697500885926641592106285202599044695865981944934148
        );

        vk.IC[41] = PairingRotate.G1Point(
            18720117707393600985668734258470788963109345994486804125334415623779965685579,
            17610066291159506858109565731510415537915008213026426702411450752803499563945
        );

        vk.IC[42] = PairingRotate.G1Point(
            17473387575701915793165316810554838264284294799431693872192608671518586775589,
            11046638250273238988420881477549685125663400537658322931163724522834081071681
        );

        vk.IC[43] = PairingRotate.G1Point(
            1131444062811679831409684930556592770674157096923417994117545757895843843257,
            14806880463376902602792568628979400757229760418808213797901706596473177402855
        );

        vk.IC[44] = PairingRotate.G1Point(
            3333565255438508727133914474431341407114665924124016209746252498172716323458,
            1349287382207655945922193622904780432125650897659617214713798793227947453335
        );

        vk.IC[45] = PairingRotate.G1Point(
            13940028459121008532016253983362465702704402122643253107590554855038192214997,
            3225433852783273107896062941479423211005648219618800554123220051023809342710
        );

        vk.IC[46] = PairingRotate.G1Point(
            19717004403074439755349281295381478852157253003797216955970992000449301302719,
            3186328678318977319722138906369583685190567800290840806157855829071842708219
        );

        vk.IC[47] = PairingRotate.G1Point(
            16642147433186556950008995817628233060579719469362516887521909650865254862277,
            17897379145764357424229771761211803103403399226293603355593766947402488749261
        );

        vk.IC[48] = PairingRotate.G1Point(
            14166167796010346344607806834057017465158432711277897940882635412943787832957,
            1466421523646102279306143855466046078434093416565439179577859342596077968495
        );

        vk.IC[49] = PairingRotate.G1Point(
            9121323577197934089656479126834443288009296095992819343687934158311952648102,
            20838803026465071526824216109672143097735131861681728912431346891805254673021
        );

        vk.IC[50] = PairingRotate.G1Point(
            16527506110553414978978752440663074476403014249564253944322759266695960317283,
            20784110511802989598239803900829001702846512565882851871209620824570342959741
        );

        vk.IC[51] = PairingRotate.G1Point(
            21239710915708343421769893254944423412302146109622846670164778866011467089334,
            21673205856698640090132731274991397146356957558897797067201376224645693508319
        );

        vk.IC[52] = PairingRotate.G1Point(
            8077054060841997795055664844350639621813278263496855282589846327672529047441,
            7836528458814616258001093258469921488745632058376319287462221490756158150755
        );

        vk.IC[53] = PairingRotate.G1Point(
            14516329420235345440149324792936235254195325657174837822744049638896307191009,
            20722856186071063267009035722206599642529515584360229343481151178919568667656
        );

        vk.IC[54] = PairingRotate.G1Point(
            2669418772363680637663665025335332245703927178960036706320145551701239085099,
            21877663481941323417151526405025523153611074545818563846226114918852433289787
        );

        vk.IC[55] = PairingRotate.G1Point(
            5741991653539626114303961719014055119659011005869852659937084977252640589389,
            18376104754519076330669694554115737208000577444106874582540891451657284147033
        );

        vk.IC[56] = PairingRotate.G1Point(
            8028575798791411367183643439532739195517530885357926087717772517691790990720,
            18883759566594356674404094589651421579134482900437360695545733243237480747440
        );

        vk.IC[57] = PairingRotate.G1Point(
            16855740526826858784404294435476672051544769847039765832010554156813731500735,
            659320399176788531847946680054100455785626824551846564053384763521994791623
        );

        vk.IC[58] = PairingRotate.G1Point(
            19988225821830608710578630073688777389429278183733539199536068639850161003968,
            13955046145626853781355698616181858322515747170102298011267491749553021068605
        );

        vk.IC[59] = PairingRotate.G1Point(
            15410537293735377459773895058434203425750985393204437521319290173095968032576,
            12169824789351460419228154813849731234386233054285207598923427959734874612330
        );

        vk.IC[60] = PairingRotate.G1Point(
            2159062713955330031251957758273078405414148150460871899054446806500793547230,
            5879182752663104625737625098296688013210189092653213235878521327556194561168
        );

        vk.IC[61] = PairingRotate.G1Point(
            4174895122075502369038039999781532490288044058012153099254766261447417221242,
            10002098427920629174530381032587014535008462144357498361035555806129992916818
        );

        vk.IC[62] = PairingRotate.G1Point(
            15335284926841897062681527472356815727299146551895045501122685010036931177370,
            15836442636274538856030584403981280347198833751029912415192018487311436469357
        );

        vk.IC[63] = PairingRotate.G1Point(
            15162884727148196758524310643047361429630186986459976124858953592650939212470,
            21420261991093949703915232730226827651029889087964456544705761681774879713164
        );

        vk.IC[64] = PairingRotate.G1Point(
            11897567539623576790784466821129399882362071349295534039069611825756071290043,
            13382525927073502847360453300076919468700768256030677349337425404866209364848
        );

        vk.IC[65] = PairingRotate.G1Point(
            1770704955919074560139787492400225011230234734329412973959714160679435405051,
            1103550123340193874347219466412240366118503028463942223452924232215815583842
        );
    }

    function verifyRotate(uint256[] memory input, ProofRotate memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKeyRotate memory vk = verifyingKeyRotate();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        PairingRotate.G1Point memory vk_x = PairingRotate.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
            vk_x = PairingRotate.addition(vk_x, PairingRotate.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = PairingRotate.addition(vk_x, vk.IC[0]);
        if (
            !PairingRotate.pairingProd4(
                PairingRotate.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid

    function verifyProofRotate(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[65] memory input
    ) public view returns (bool r) {
        ProofRotate memory proof;
        proof.A = PairingRotate.G1Point(a[0], a[1]);
        proof.B = PairingRotate.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingRotate.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verifyRotate(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

library PairingStep {
    struct G1Point {
        uint256 X;
        uint256 Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]

    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }
    /// @return the generator of G1

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2

    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );

        /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.

    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1

    function addition(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory r)
    {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.

    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, "pairing-lengths-failed");
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success :=
                staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.

    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.

    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.

    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract StepVerifier {
    using PairingStep for *;

    struct VerifyingKeyStep {
        PairingStep.G1Point alfa1;
        PairingStep.G2Point beta2;
        PairingStep.G2Point gamma2;
        PairingStep.G2Point delta2;
        PairingStep.G1Point[] IC;
    }

    struct ProofStep {
        PairingStep.G1Point A;
        PairingStep.G2Point B;
        PairingStep.G1Point C;
    }

    function verifyingKeyStep() internal pure returns (VerifyingKeyStep memory vk) {
        vk.alfa1 = PairingStep.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = PairingStep.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = PairingStep.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = PairingStep.G2Point(
            [
                9148034046527158989101020029579194033324545680690921079621927354300102378298,
                10428510773771669101337698551840898995662926411592295461427040701160903222524
            ],
            [
                2059005959130125518966387482690762396878640026867853728991912122619823366140,
                8608655831713798153467395128429618873818784843644748205739399791673552717322
            ]
        );
        vk.IC = new PairingStep.G1Point[](2);

        vk.IC[0] = PairingStep.G1Point(
            21097338684422677437460982984988891660959866360162656316176294386916372703826,
            3398895913860087272363404566039149647887053857985313627926493221433540324753
        );

        vk.IC[1] = PairingStep.G1Point(
            17453610618095138353005253409143141334272691316524473752585732650144486997453,
            17395545982498249053105146333634640028536711052867181025149351332882425139542
        );
    }

    function verifyStep(uint256[] memory input, ProofStep memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKeyStep memory vk = verifyingKeyStep();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        PairingStep.G1Point memory vk_x = PairingStep.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
            vk_x = PairingStep.addition(vk_x, PairingStep.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = PairingStep.addition(vk_x, vk.IC[0]);
        if (
            !PairingStep.pairingProd4(
                PairingStep.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid

    function verifyProofStep(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {
        ProofStep memory proof;
        proof.A = PairingStep.G1Point(a[0], a[1]);
        proof.B = PairingStep.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingStep.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verifyStep(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}