// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity 0.8.6;

import "./CheckReceiptsProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SignatureCheck.sol";



contract CheckAura is Initializable {
    bytes1 constant PARENT_HASH_PREFIX = 0xA0;
    bytes1 constant STEP_PREFIX = 0x84;
    bytes2 constant SIGNATURE_PREFIX = 0xB841;

    address[] public validatorSet;
    address validatorSetAddress;
    bytes32 public lastProcessedBlock;


    struct BlockAura {
        bytes3 p0Seal;
        bytes3 p0Bare;

        bytes32 parentHash;
        bytes p2;
        bytes32 receiptHash;
        bytes p3;

        bytes4 step;
        bytes signature;  // todo maybe pass s r v values?

        uint64 finalizedVs;
    }


    struct ValidatorSetChange {
        address deltaAddress;
        int64 deltaIndex; // < 0 ? remove : add
    }

    struct ValidatorSetProof {
        bytes[] receiptProof;
        ValidatorSetChange[] changes;
    }

    struct AuraProof {
        BlockAura[] blocks;
        CommonStructs.TransferProof transfer;
        ValidatorSetProof[] vsChanges;
        uint64 transferEventBlock;
    }


    function __CheckAura_init(
        address[] memory initialValidators_,
        address validatorSetAddress_,
        bytes32 lastProcessedBlock_
    ) internal initializer {
        require(initialValidators_.length > 0, "Length of _initialValidators must be bigger than 0");

        validatorSet = initialValidators_;
        validatorSetAddress = validatorSetAddress_;
        lastProcessedBlock = lastProcessedBlock_;

    }

    function checkAura_(AuraProof calldata auraProof, uint minSafetyBlocks, address sideBridgeAddress) internal {

        bytes32 parentHash;

        bytes32 receiptHash = calcTransferReceiptsHash(auraProof.transfer, sideBridgeAddress);
        require(auraProof.blocks[auraProof.transferEventBlock].receiptHash == receiptHash, "Transfer event validation failed");
        require(auraProof.blocks.length - auraProof.transferEventBlock >= minSafetyBlocks, "Not enough safety blocks");


        for (uint i = 0; i < auraProof.blocks.length; i++) {
            BlockAura calldata block_ = auraProof.blocks[i];

            if (block_.finalizedVs != 0) {// 0 means no events should be finalized, so indexes are shifted by 1
                // vs changes in that block
                ValidatorSetProof memory vsProof = auraProof.vsChanges[block_.finalizedVs - 1];

                // how many block after event validatorSet should be finalized
                uint txsBeforeFinalize = validatorSet.length / 2 + 1;

                // apply vs changes
                for (uint k = 0; k < vsProof.changes.length; k++)
                    applyVsChange(vsProof.changes[k]);

                // check proof
                receiptHash = calcValidatorSetReceiptHash(vsProof.receiptProof, validatorSetAddress, validatorSet);

                // event_block = finalized_block - txsBeforeFinalize
                require(auraProof.blocks[i - txsBeforeFinalize].receiptHash == receiptHash, "Wrong VS receipt hash");

            }

            if (parentHash != bytes32(0))
                require(block_.parentHash == parentHash, "Wrong parent hash");

            parentHash = checkBlock(block_);

            // after proceed vs change event next block in auraProof.blocks can have any parentHash
            // (skipping some blocks) but only if it's not the safety blocks for transfer event
            if (block_.finalizedVs != 0 && i < auraProof.transferEventBlock)
                parentHash = bytes32(0);

        }

        lastProcessedBlock = parentHash;
    }

    function getValidatorSet() public view returns (address[] memory) {
        return validatorSet;
    }

    function applyVsChange(ValidatorSetChange memory vsEvent) internal {
        if (vsEvent.deltaIndex < 0) {
            uint index = uint(int(vsEvent.deltaIndex * (- 1) - 1));
            validatorSet[index] = validatorSet[validatorSet.length - 1];
            validatorSet.pop();
        }
        else {
            uint index = uint(int((vsEvent.deltaIndex)));

            // logic if validatorSet contract will be updated
            // validatorSet.push(validatorSet[index]);
            // validatorSet[index] = vsEvent.deltaAddress;

            // old (current) validatorSet contract logic
            validatorSet.push(vsEvent.deltaAddress);
        }
    }

    function checkBlock(BlockAura calldata block_) internal view returns (bytes32) {
        (bytes32 bareHash, bytes32 sealHash) = calcBlockHash(block_);

        address validator = validatorSet[bytesToUint(block_.step) % validatorSet.length];
        require(ecdsaRecover(bareHash, block_.signature) == validator, "Failed to verify sign");

        return sealHash;
    }

    function calcBlockHash(BlockAura calldata block_) internal pure returns (bytes32, bytes32) {
        bytes memory commonRlp = abi.encodePacked(PARENT_HASH_PREFIX, block_.parentHash, block_.p2, block_.receiptHash, block_.p3);
        return (
        // hash without seal (bare), for signature check
        keccak256(abi.encodePacked(block_.p0Bare, commonRlp)),
        // hash with seal, for prev_hash check
        keccak256(abi.encodePacked(block_.p0Seal, commonRlp, STEP_PREFIX, block_.step, SIGNATURE_PREFIX, block_.signature))
        );
    }


    function calcValidatorSetReceiptHash(bytes[] memory receipt_proof, address validatorSetAddress, address[] memory vSet) private pure returns (bytes32) {
        bytes32 el = keccak256(abi.encodePacked(
                receipt_proof[0],
                validatorSetAddress,
                receipt_proof[1],
                abi.encode(vSet),
                receipt_proof[2]
            ));
        return calcReceiptsHash(receipt_proof, el, 3);
    }

    function bytesToUint(bytes4 b) internal pure returns (uint){
        return uint(uint32(b));
    }

    uint256[15] private ___gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../common/CommonStructs.sol";


// check readme for focs
function calcReceiptsHash(bytes[] memory proof, bytes32 el, uint proofStart) pure returns (bytes32) {
    bytes memory s;

    for (uint i = proofStart; i < proof.length; i += 2) {
        s = abi.encodePacked(proof[i], el, proof[i + 1]);
        el = (s.length > 32) ? keccak256(s) : bytes32(s);
    }

    return el;
}


function calcTransferReceiptsHash(CommonStructs.TransferProof memory p, address eventContractAddress) pure returns (bytes32) {
    bytes32 el = keccak256(abi.encodePacked(
            p.receiptProof[0],
            eventContractAddress,
            p.receiptProof[1],
            toBinary(p.eventId),
            p.receiptProof[2],
            abi.encode(p.transfers),
            p.receiptProof[3]
        ));
    return calcReceiptsHash(p.receiptProof, el, 4);
    // start from proof[4]
}


function toBinary(uint _x) pure returns (bytes memory) {
    bytes memory b = new bytes(32);
    assembly {
        mstore(add(b, 32), _x)
    }
    uint i;
    for (i = 0; i < 32; i++) {
        if (b[i] != 0) {
            break;
        }
    }
    bytes memory res = new bytes(32 - i);
    for (uint j = 0; j < res.length; j++) {
        res[j] = b[i++];
    }
    return res;
}

pragma solidity ^0.8.0;

function ecdsaRecover(bytes32 messageHash, bytes memory signature) pure returns(address) {
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
        r := mload(add(signature, 32))
        s := mload(add(signature, 64))
        v := byte(0, mload(add(signature, 96)))
        if lt(v, 27) {v := add(v, 27)}
    }
    return ecrecover(messageHash, v, r, s);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CommonStructs.sol";
import "../tokens/IWrapper.sol";
import "../checks/SignatureCheck.sol";


contract CommonBridge is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    // OWNER_ROLE must be DEFAULT_ADMIN_ROLE because by default only this role able to grant or revoke other roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant RELAY_ROLE = keccak256("RELAY_ROLE");

    uint private constant SIGNATURE_FEE_TIMESTAMP = 1800;  // 30 min

    // queue to be pushed in another network
    CommonStructs.Transfer[] queue;

    // locked transfers from another network
    mapping(uint => CommonStructs.LockedTransfers) public lockedTransfers;
    uint public oldestLockedEventId;  // head index of lockedTransfers 'queue' mapping


    // this network to side network token addresses mapping
    mapping(address => address) public tokenAddresses;
    address public wrapperAddress;

    address payable transferFeeRecipient;
    address payable bridgeFeeRecipient;

    address public sideBridgeAddress;
    uint public minSafetyBlocks;
    uint public timeframeSeconds;
    uint public lockTime;

    uint public inputEventId; // last processed event from side network
    uint outputEventId;  // last created event in this network. start from 1 coz 0 consider already processed

    uint lastTimeframe;

    uint internal signatureFeeCheckNumber;

    event Withdraw(address indexed from, uint eventId, address tokenFrom, address tokenTo, uint amount,
                   uint transferFeeAmount, uint bridgeFeeAmount);
    event Transfer(uint indexed eventId, CommonStructs.Transfer[] queue);
    event TransferSubmit(uint indexed eventId);
    event TransferFinish(uint indexed eventId);

    function __CommonBridge_init(CommonStructs.ConstructorArgs memory args) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RELAY_ROLE, args.relayAddress);
        _setupRole(ADMIN_ROLE, args.adminAddress);

        // initialise tokenAddresses with start values
        _tokensAddBatch(args.tokenThisAddresses, args.tokenSideAddresses);
        wrapperAddress = args.wrappingTokenAddress;

        sideBridgeAddress = args.sideBridgeAddress;
        transferFeeRecipient = args.transferFeeRecipient;
        bridgeFeeRecipient = args.bridgeFeeRecipient;
        minSafetyBlocks = args.minSafetyBlocks;
        timeframeSeconds = args.timeframeSeconds;
        lockTime = args.lockTime;

        oldestLockedEventId = 1;
        outputEventId = 1;

        signatureFeeCheckNumber = 3;
    }

    function wrapWithdraw(address toAddress, bytes calldata signature, uint transferFee, uint bridgeFee) public payable {
        address tokenSideAddress = tokenAddresses[wrapperAddress];
        require(tokenSideAddress != address(0), "Unknown token address");

        require(msg.value > transferFee + bridgeFee, "Sent value <= fee");

        feeCheck(wrapperAddress, signature, transferFee, bridgeFee);
        transferFeeRecipient.transfer(transferFee);
        bridgeFeeRecipient.transfer(bridgeFee);

        uint amount = msg.value - transferFee - bridgeFee;
        IWrapper(wrapperAddress).deposit{value : amount}();

        //
        queue.push(CommonStructs.Transfer(tokenSideAddress, toAddress, amount));
        emit Withdraw(msg.sender, outputEventId, address(0), tokenSideAddress, amount, transferFee, bridgeFee);

        withdrawFinish();
    }

    function withdraw(
        address tokenThisAddress,
        address toAddress,
        uint amount,
        bool unwrapSide,
        bytes calldata signature,
        uint transferFee,
        uint bridgeFee
    ) payable public {
        address tokenSideAddress;
        if (unwrapSide) {
            require(tokenAddresses[address(0)] == tokenThisAddress, "Token not point to native token");
            // tokenSideAddress will be 0x0000000000000000000000000000000000000000 - for native token
        } else {
            tokenSideAddress = tokenAddresses[tokenThisAddress];
            require(tokenSideAddress != address(0), "Unknown token address");
        }

        require(msg.value == transferFee + bridgeFee, "Sent value != fee");

        require(amount > 0, "Cannot withdraw 0");

        feeCheck(tokenThisAddress, signature, transferFee, bridgeFee);
        transferFeeRecipient.transfer(transferFee);
        bridgeFeeRecipient.transfer(bridgeFee);

        require(IERC20(tokenThisAddress).transferFrom(msg.sender, address(this), amount), "Fail transfer coins");

        queue.push(CommonStructs.Transfer(tokenSideAddress, toAddress, amount));
        emit Withdraw(msg.sender, outputEventId, tokenThisAddress, tokenSideAddress, amount, transferFee, bridgeFee);

        withdrawFinish();
    }


    function feeCheck(
        address token,
        bytes calldata signature,
        uint transferFee,
        uint bridgeFee
    ) internal {
        bytes32 messageHash;
        address signer;
        uint timestampEpoch = block.timestamp / SIGNATURE_FEE_TIMESTAMP;

        for (uint i = 0; i < signatureFeeCheckNumber; i++) {
            messageHash = keccak256(abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(
                        token,
                        timestampEpoch,
                        transferFee,
                        bridgeFee
                    ))
                ));

            signer = ecdsaRecover(messageHash, signature);
            if (hasRole(RELAY_ROLE, signer)) {
                return;
            } else {
                timestampEpoch--;
            }
        }
        revert("Signature check failed");
    }

    function triggerTransfers() public {
        require(queue.length != 0, "Queue is empty");

        emit Transfer(outputEventId++, queue);
        delete queue;
    }

    function withdrawFinish() internal {
        uint nowTimeframe = block.timestamp / timeframeSeconds;
        if (nowTimeframe != lastTimeframe) {
            emit Transfer(outputEventId++, queue);
            delete queue;

            lastTimeframe = nowTimeframe;
        }
    }


    // locked transfers from another network
    function getLockedTransfers(uint eventId) public view returns (CommonStructs.LockedTransfers memory) {
        return lockedTransfers[eventId];
    }


    function proceedTransfers(CommonStructs.Transfer[] memory transfers) internal {
        for (uint i = 0; i < transfers.length; i++) {

            if (transfers[i].tokenAddress == address(0)) {// native token
                IWrapper(wrapperAddress).withdraw(transfers[i].amount);
                payable(transfers[i].toAddress).transfer(transfers[i].amount);
            } else {// ERC20 token
                require(
                    IERC20(transfers[i].tokenAddress).transfer(transfers[i].toAddress, transfers[i].amount),
                    "Fail transfer coins");
            }

        }
    }


    // submitted transfers save here for `lockTime` period
    function lockTransfers(CommonStructs.Transfer[] memory events, uint eventId) internal {
        lockedTransfers[eventId].endTimestamp = block.timestamp + lockTime;
        for (uint i = 0; i < events.length; i++)
            lockedTransfers[eventId].transfers.push(events[i]);
    }

    // after `lockTime` period, transfers can  be unlocked
    function unlockTransfers(uint eventId) public whenNotPaused {
        require(eventId == oldestLockedEventId, "can unlock only oldest event");

        CommonStructs.LockedTransfers memory transfersLocked = lockedTransfers[eventId];
        require(transfersLocked.endTimestamp > 0, "no locked transfers with this id");
        require(transfersLocked.endTimestamp < block.timestamp, "lockTime has not yet passed");

        proceedTransfers(transfersLocked.transfers);

        delete lockedTransfers[eventId];
        emit TransferFinish(eventId);

        oldestLockedEventId = eventId + 1;
    }

    // optimized version of unlockTransfers that unlock all transfer that can be unlocked in one call
    function unlockTransfersBatch() public whenNotPaused {
        uint eventId = oldestLockedEventId;
        for (;; eventId++) {
            CommonStructs.LockedTransfers memory transfersLocked = lockedTransfers[eventId];
            if (transfersLocked.endTimestamp == 0 || transfersLocked.endTimestamp > block.timestamp) break;

            proceedTransfers(transfersLocked.transfers);

            delete lockedTransfers[eventId];
            emit TransferFinish(eventId);
        }
        oldestLockedEventId = eventId;
    }

    // delete transfers with passed eventId and all after it
    function removeLockedTransfers(uint eventId) public onlyRole(ADMIN_ROLE) whenPaused {
        require(eventId >= oldestLockedEventId, "eventId must be >= oldestLockedEventId");
        for (; lockedTransfers[eventId].endTimestamp != 0; eventId++)
            delete lockedTransfers[eventId];
        inputEventId = eventId-1; // pretend like we don't receive that event
    }


    // admin setters

    function changeMinSafetyBlocks(uint minSafetyBlocks_) public onlyRole(ADMIN_ROLE) {
        minSafetyBlocks = minSafetyBlocks_;
    }

    function changeTransferFeeRecipient(address payable feeRecipient_) public onlyRole(ADMIN_ROLE) {
        transferFeeRecipient = feeRecipient_;
    }

    function changeBridgeFeeRecipient(address payable feeRecipient_) public onlyRole(ADMIN_ROLE) {
        bridgeFeeRecipient = feeRecipient_;
    }

    function changeTimeframeSeconds(uint timeframeSeconds_) public onlyRole(ADMIN_ROLE) {
        timeframeSeconds = timeframeSeconds_;
    }

    function changeLockTime(uint lockTime_) public onlyRole(ADMIN_ROLE) {
        lockTime = lockTime_;
    }

    function changeSignatureFeeCheckNumber(uint signatureFeeCheckNumber_) public onlyRole(ADMIN_ROLE) {
        signatureFeeCheckNumber = signatureFeeCheckNumber_;
    }

    // token addressed mapping

    function tokensAdd(address tokenThisAddress, address tokenSideAddress) public onlyRole(ADMIN_ROLE) {
        tokenAddresses[tokenThisAddress] = tokenSideAddress;
    }

    function tokensRemove(address tokenThisAddress) public onlyRole(ADMIN_ROLE) {
        delete tokenAddresses[tokenThisAddress];
    }

    function tokensAddBatch(address[] memory tokenThisAddresses, address[] memory tokenSideAddresses) public onlyRole(ADMIN_ROLE) {
        _tokensAddBatch(tokenThisAddresses, tokenSideAddresses);
    }

    function _tokensAddBatch(address[] memory tokenThisAddresses, address[] memory tokenSideAddresses) private {
        require(tokenThisAddresses.length == tokenSideAddresses.length, "sizes of tokenThisAddresses and tokenSideAddresses must be same");
        uint arrayLength = tokenThisAddresses.length;
        for (uint i = 0; i < arrayLength; i++)
            tokenAddresses[tokenThisAddresses[i]] = tokenSideAddresses[i];
    }

    function tokensRemoveBatch(address[] memory tokenThisAddresses) public onlyRole(ADMIN_ROLE) {
        uint arrayLength = tokenThisAddresses.length;
        for (uint i = 0; i < arrayLength; i++)
            delete tokenAddresses[tokenThisAddresses[i]];
    }

    // pause

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // internal

    function checkEventId(uint eventId) internal {
        require(eventId == ++inputEventId, "EventId out of order");
    }

    receive() external payable {}  // need to receive native token from wrapper contract

    uint256[15] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library CommonStructs {
    struct Transfer {
        address tokenAddress;
        address toAddress;
        uint amount;
    }

    struct TransferProof {
        bytes[] receiptProof;
        uint eventId;
        Transfer[] transfers;
    }

    struct LockedTransfers {
        Transfer[] transfers;
        uint endTimestamp;
    }

    struct ConstructorArgs {
        address sideBridgeAddress; address adminAddress;
        address relayAddress; address wrappingTokenAddress;
        address[] tokenThisAddresses; address[] tokenSideAddresses;
        address payable transferFeeRecipient; address payable bridgeFeeRecipient;
        uint timeframeSeconds; uint lockTime; uint minSafetyBlocks;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../common/CommonBridge.sol";
import "../checks/CheckAura.sol";


contract ETH_EthBridge is CommonBridge, CheckAura {

    function initialize(
        CommonStructs.ConstructorArgs memory args,
        address[] memory initialValidators,
        address validatorSetAddress,
        bytes32 lastProcessedBlock
    ) public initializer {
        __CommonBridge_init(args);
        __CheckAura_init(initialValidators, validatorSetAddress, lastProcessedBlock);
    }

    function submitTransferAura(AuraProof calldata auraProof) public onlyRole(RELAY_ROLE) whenNotPaused {
        emit TransferSubmit(auraProof.transfer.eventId);
        checkEventId(auraProof.transfer.eventId);
        checkAura_(auraProof, minSafetyBlocks, sideBridgeAddress);
        lockTransfers(auraProof.transfer.transfers, auraProof.transfer.eventId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IWrapper {
    event Deposit(address indexed dst, uint amount);
    event Withdrawal(address indexed src, uint amount);

    function deposit() external payable;

    function withdraw(uint amount) external;
}