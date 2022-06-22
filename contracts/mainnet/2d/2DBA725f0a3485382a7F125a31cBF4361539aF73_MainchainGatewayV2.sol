// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
                        Strings.toHexString(uint160(account), 20),
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IQuorum.sol";
import "../interfaces/IWeightedValidator.sol";
import "./HasProxyAdmin.sol";

abstract contract GatewayV2 is HasProxyAdmin, Pausable, IQuorum {
  /// @dev Emitted when the validator contract address is updated.
  event ValidatorContractUpdated(IWeightedValidator);

  uint256 internal _num;
  uint256 internal _denom;

  IWeightedValidator public validatorContract;
  uint256 public nonce;

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   */
  uint256[50] private ______gap;

  /**
   * @dev See {IQuorum-getThreshold}.
   */
  function getThreshold() external view virtual returns (uint256, uint256) {
    return (_num, _denom);
  }

  /**
   * @dev See {IQuorum-checkThreshold}.
   */
  function checkThreshold(uint256 _voteWeight) external view virtual returns (bool) {
    return _voteWeight * _denom >= _num * validatorContract.totalWeights();
  }

  /**
   * @dev See {IQuorum-setThreshold}.
   */
  function setThreshold(uint256 _numerator, uint256 _denominator)
    external
    virtual
    onlyAdmin
    returns (uint256, uint256)
  {
    return _setThreshold(_numerator, _denominator);
  }

  /**
   * @dev Triggers paused state.
   */
  function pause() external onlyAdmin {
    _pause();
  }

  /**
   * @dev Triggers unpaused state.
   */
  function unpause() external onlyAdmin {
    _unpause();
  }

  /**
   * @dev Sets validator contract address.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits the `ValidatorContractUpdated` event.
   *
   */
  function setValidatorContract(IWeightedValidator _validatorContract) external virtual onlyAdmin {
    _setValidatorContract(_validatorContract);
  }

  /**
   * @dev See {IQuorum-minimumVoteWeight}.
   */
  function minimumVoteWeight() public view virtual returns (uint256) {
    return _minimumVoteWeight(validatorContract.totalWeights());
  }

  /**
   * @dev Sets validator contract address.
   *
   * Emits the `ValidatorContractUpdated` event.
   *
   */
  function _setValidatorContract(IWeightedValidator _validatorContract) internal virtual {
    validatorContract = _validatorContract;
    emit ValidatorContractUpdated(_validatorContract);
  }

  /**
   * @dev Sets threshold and returns the old one.
   *
   * Emits the `ThresholdUpdated` event.
   *
   */
  function _setThreshold(uint256 _numerator, uint256 _denominator)
    internal
    virtual
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    require(_numerator <= _denominator, "GatewayV2: invalid threshold");
    _previousNum = _num;
    _previousDenom = _denom;
    _num = _numerator;
    _denom = _denominator;
    emit ThresholdUpdated(nonce++, _numerator, _denominator, _previousNum, _previousDenom);
  }

  /**
   * @dev Returns minimum vote weight.
   */
  function _minimumVoteWeight(uint256 _totalWeight) internal view virtual returns (uint256) {
    return (_num * _totalWeight + _denom - 1) / _denom;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/StorageSlot.sol";

abstract contract HasProxyAdmin {
  // bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
  bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  modifier onlyAdmin() {
    require(msg.sender == _getAdmin(), "HasProxyAdmin: unauthorized sender");
    _;
  }

  /**
   * @dev Returns proxy admin.
   */
  function _getAdmin() internal view returns (address) {
    return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GatewayV2.sol";

abstract contract WithdrawalLimitation is GatewayV2 {
  /// @dev Emitted when the high-tier vote weight threshold is updated
  event HighTierVoteWeightThresholdUpdated(
    uint256 indexed nonce,
    uint256 indexed numerator,
    uint256 indexed denominator,
    uint256 previousNumerator,
    uint256 previousDenominator
  );
  /// @dev Emitted when the thresholds for high-tier withdrawals that requires high-tier vote weights are updated
  event HighTierThresholdsUpdated(address[] tokens, uint256[] thresholds);
  /// @dev Emitted when the thresholds for locked withdrawals are updated
  event LockedThresholdsUpdated(address[] tokens, uint256[] thresholds);
  /// @dev Emitted when the fee percentages to unlock withdraw are updated
  event UnlockFeePercentagesUpdated(address[] tokens, uint256[] percentages);
  /// @dev Emitted when the daily limit thresholds are updated
  event DailyWithdrawalLimitsUpdated(address[] tokens, uint256[] limits);

  uint256 public constant _MAX_PERCENTAGE = 1_000_000;

  uint256 internal _highTierVWNum;
  uint256 internal _highTierVWDenom;

  /// @dev Mapping from mainchain token => the amount thresholds for high-tier withdrawals that requires high-tier vote weights
  mapping(address => uint256) public highTierThreshold;
  /// @dev Mapping from mainchain token => the amount thresholds to lock withdrawal
  mapping(address => uint256) public lockedThreshold;
  /// @dev Mapping from mainchain token => unlock fee percentages for unlocker
  /// @notice Values 0-1,000,000 map to 0%-100%
  mapping(address => uint256) public unlockFeePercentages;
  /// @dev Mapping from mainchain token => daily limit amount for withdrawal
  mapping(address => uint256) public dailyWithdrawalLimit;
  /// @dev Mapping from token address => today withdrawal amount
  mapping(address => uint256) public lastSyncedWithdrawal;
  /// @dev Mapping from token address => last date synced to record the `lastSyncedWithdrawal`
  mapping(address => uint256) public lastDateSynced;

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   */
  uint256[50] private ______gap;

  /**
   * @dev Override {GatewayV2-setThreshold}.
   *
   * Requirements:
   * - The high-tier vote weight threshold must equal to or larger than the normal threshold.
   *
   */
  function setThreshold(uint256 _numerator, uint256 _denominator)
    external
    virtual
    override
    onlyAdmin
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    (_previousNum, _previousDenom) = _setThreshold(_numerator, _denominator);
    _verifyThresholds();
  }

  /**
   * @dev Returns the high-tier vote weight threshold.
   */
  function getHighTierVoteWeightThreshold() external view virtual returns (uint256, uint256) {
    return (_highTierVWNum, _highTierVWDenom);
  }

  /**
   * @dev Checks whether the `_voteWeight` passes the high-tier vote weight threshold.
   */
  function checkHighTierVoteWeightThreshold(uint256 _voteWeight) external view virtual returns (bool) {
    return _voteWeight * _highTierVWDenom >= _highTierVWNum * validatorContract.totalWeights();
  }

  /**
   * @dev Sets high-tier vote weight threshold and returns the old one.
   *
   * Requirements:
   * - The method caller is admin.
   * - The high-tier vote weight threshold must equal to or larger than the normal threshold.
   *
   * Emits the `HighTierVoteWeightThresholdUpdated` event.
   *
   */
  function setHighTierVoteWeightThreshold(uint256 _numerator, uint256 _denominator)
    external
    virtual
    onlyAdmin
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    (_previousNum, _previousDenom) = _setHighTierVoteWeightThreshold(_numerator, _denominator);
    _verifyThresholds();
  }

  /**
   * @dev Sets the thresholds for high-tier withdrawals that requires high-tier vote weights.
   *
   * Requirements:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `HighTierThresholdsUpdated` event.
   *
   */
  function setHighTierThresholds(address[] calldata _tokens, uint256[] calldata _thresholds)
    external
    virtual
    onlyAdmin
  {
    require(_tokens.length > 0, "WithdrawalLimitation: invalid array length");
    _setHighTierThresholds(_tokens, _thresholds);
  }

  /**
   * @dev Sets the amount thresholds to lock withdrawal.
   *
   * Requirements:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `LockedThresholdsUpdated` event.
   *
   */
  function setLockedThresholds(address[] calldata _tokens, uint256[] calldata _thresholds) external virtual onlyAdmin {
    require(_tokens.length > 0, "WithdrawalLimitation: invalid array length");
    _setLockedThresholds(_tokens, _thresholds);
  }

  /**
   * @dev Sets fee percentages to unlock withdrawal.
   *
   * Requirements:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `UnlockFeePercentagesUpdated` event.
   *
   */
  function setUnlockFeePercentages(address[] calldata _tokens, uint256[] calldata _percentages)
    external
    virtual
    onlyAdmin
  {
    require(_tokens.length > 0, "WithdrawalLimitation: invalid array length");
    _setUnlockFeePercentages(_tokens, _percentages);
  }

  /**
   * @dev Sets daily limit amounts for the withdrawals.
   *
   * Requirements:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `DailyWithdrawalLimitsUpdated` event.
   *
   */
  function setDailyWithdrawalLimits(address[] calldata _tokens, uint256[] calldata _limits) external virtual onlyAdmin {
    require(_tokens.length > 0, "WithdrawalLimitation: invalid array length");
    _setDailyWithdrawalLimits(_tokens, _limits);
  }

  /**
   * @dev Checks whether the withdrawal reaches the limitation.
   */
  function reachedWithdrawalLimit(address _token, uint256 _quantity) external view virtual returns (bool) {
    return _reachedWithdrawalLimit(_token, _quantity);
  }

  /**
   * @dev Sets high-tier vote weight threshold and returns the old one.
   *
   * Emits the `HighTierVoteWeightThresholdUpdated` event.
   *
   */
  function _setHighTierVoteWeightThreshold(uint256 _numerator, uint256 _denominator)
    internal
    returns (uint256 _previousNum, uint256 _previousDenom)
  {
    require(_numerator <= _denominator, "WithdrawalLimitation: invalid threshold");
    _previousNum = _highTierVWNum;
    _previousDenom = _highTierVWDenom;
    _highTierVWNum = _numerator;
    _highTierVWDenom = _denominator;
    emit HighTierVoteWeightThresholdUpdated(nonce++, _numerator, _denominator, _previousNum, _previousDenom);
  }

  /**
   * @dev Sets the thresholds for high-tier withdrawals that requires high-tier vote weights.
   *
   * Requirements:
   * - The array lengths are equal.
   *
   * Emits the `HighTierThresholdsUpdated` event.
   *
   */
  function _setHighTierThresholds(address[] calldata _tokens, uint256[] calldata _thresholds) internal virtual {
    require(_tokens.length == _thresholds.length, "WithdrawalLimitation: invalid array length");
    for (uint256 _i; _i < _tokens.length; _i++) {
      highTierThreshold[_tokens[_i]] = _thresholds[_i];
    }
    emit HighTierThresholdsUpdated(_tokens, _thresholds);
  }

  /**
   * @dev Sets the amount thresholds to lock withdrawal.
   *
   * Requirements:
   * - The array lengths are equal.
   *
   * Emits the `LockedThresholdsUpdated` event.
   *
   */
  function _setLockedThresholds(address[] calldata _tokens, uint256[] calldata _thresholds) internal virtual {
    require(_tokens.length == _thresholds.length, "WithdrawalLimitation: invalid array length");
    for (uint256 _i; _i < _tokens.length; _i++) {
      lockedThreshold[_tokens[_i]] = _thresholds[_i];
    }
    emit LockedThresholdsUpdated(_tokens, _thresholds);
  }

  /**
   * @dev Sets fee percentages to unlock withdrawal.
   *
   * Requirements:
   * - The array lengths are equal.
   * - The percentage is equal to or less than 100_000.
   *
   * Emits the `UnlockFeePercentagesUpdated` event.
   *
   */
  function _setUnlockFeePercentages(address[] calldata _tokens, uint256[] calldata _percentages) internal virtual {
    require(_tokens.length == _percentages.length, "WithdrawalLimitation: invalid array length");
    for (uint256 _i; _i < _tokens.length; _i++) {
      require(_percentages[_i] <= _MAX_PERCENTAGE, "WithdrawalLimitation: invalid percentage");
      unlockFeePercentages[_tokens[_i]] = _percentages[_i];
    }
    emit UnlockFeePercentagesUpdated(_tokens, _percentages);
  }

  /**
   * @dev Sets daily limit amounts for the withdrawals.
   *
   * Requirements:
   * - The array lengths are equal.
   *
   * Emits the `DailyWithdrawalLimitsUpdated` event.
   *
   */
  function _setDailyWithdrawalLimits(address[] calldata _tokens, uint256[] calldata _limits) internal virtual {
    require(_tokens.length == _limits.length, "WithdrawalLimitation: invalid array length");
    for (uint256 _i; _i < _tokens.length; _i++) {
      dailyWithdrawalLimit[_tokens[_i]] = _limits[_i];
    }
    emit DailyWithdrawalLimitsUpdated(_tokens, _limits);
  }

  /**
   * @dev Checks whether the withdrawal reaches the daily limitation.
   *
   * Requirements:
   * - The daily withdrawal threshold should not apply for locked withdrawals.
   *
   */
  function _reachedWithdrawalLimit(address _token, uint256 _quantity) internal view virtual returns (bool) {
    if (_lockedWithdrawalRequest(_token, _quantity)) {
      return false;
    }

    uint256 _currentDate = block.timestamp / 1 days;
    if (_currentDate > lastDateSynced[_token]) {
      return dailyWithdrawalLimit[_token] <= _quantity;
    } else {
      return dailyWithdrawalLimit[_token] <= lastSyncedWithdrawal[_token] + _quantity;
    }
  }

  /**
   * @dev Record withdrawal token.
   */
  function _recordWithdrawal(address _token, uint256 _quantity) internal virtual {
    uint256 _currentDate = block.timestamp / 1 days;
    if (_currentDate > lastDateSynced[_token]) {
      lastDateSynced[_token] = _currentDate;
      lastSyncedWithdrawal[_token] = _quantity;
    } else {
      lastSyncedWithdrawal[_token] += _quantity;
    }
  }

  /**
   * @dev Returns whether the withdrawal request is locked or not.
   */
  function _lockedWithdrawalRequest(address _token, uint256 _quantity) internal view virtual returns (bool) {
    return lockedThreshold[_token] <= _quantity;
  }

  /**
   * @dev Computes fee percentage.
   */
  function _computeFeePercentage(uint256 _amount, uint256 _percentage) internal view virtual returns (uint256) {
    return (_amount * _percentage) / _MAX_PERCENTAGE;
  }

  /**
   * @dev Returns high-tier vote weight.
   */
  function _highTierVoteWeight(uint256 _totalWeight) internal view virtual returns (uint256) {
    return (_highTierVWNum * _totalWeight + _highTierVWDenom - 1) / _highTierVWDenom;
  }

  /**
   * @dev Validates whether the high-tier vote weight threshold is larger than the normal threshold.
   */
  function _verifyThresholds() internal view {
    require(_num * _highTierVWDenom <= _highTierVWNum * _denom, "WithdrawalLimitation: invalid thresholds");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuorum {
  /// @dev Emitted when the threshold is updated
  event ThresholdUpdated(
    uint256 indexed nonce,
    uint256 indexed numerator,
    uint256 indexed denominator,
    uint256 previousNumerator,
    uint256 previousDenominator
  );

  /**
   * @dev Returns the threshold.
   */
  function getThreshold() external view returns (uint256 _num, uint256 _denom);

  /**
   * @dev Checks whether the `_voteWeight` passes the threshold.
   */
  function checkThreshold(uint256 _voteWeight) external view returns (bool);

  /**
   * @dev Returns the minimum vote weight to pass the threshold.
   */
  function minimumVoteWeight() external view returns (uint256);

  /**
   * @dev Sets the threshold.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits the `ThresholdUpdated` event.
   *
   */
  function setThreshold(uint256 _numerator, uint256 _denominator)
    external
    returns (uint256 _previousNum, uint256 _previousDenom);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 _wad) external;

  function balanceOf(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IQuorum.sol";

interface IWeightedValidator is IQuorum {
  struct WeightedValidator {
    address validator;
    address governor;
    uint256 weight;
  }

  /// @dev Emitted when the validators are added
  event ValidatorsAdded(uint256 indexed nonce, WeightedValidator[] validators);
  /// @dev Emitted when the validators are updated
  event ValidatorsUpdated(uint256 indexed nonce, WeightedValidator[] validators);
  /// @dev Emitted when the validators are removed
  event ValidatorsRemoved(uint256 indexed nonce, address[] validators);

  /**
   * @dev Returns validator weight of the validator.
   */
  function getValidatorWeight(address _addr) external view returns (uint256);

  /**
   * @dev Returns governor weight of the governor.
   */
  function getGovernorWeight(address _addr) external view returns (uint256);

  /**
   * @dev Returns total validator weights of the address list.
   */
  function sumValidatorWeights(address[] calldata _addrList) external view returns (uint256 _weight);

  /**
   * @dev Returns total governor weights of the address list.
   */
  function sumGovernorWeights(address[] calldata _addrList) external view returns (uint256 _weight);

  /**
   * @dev Returns the validator list attached with governor address and weight.
   */
  function getValidatorInfo() external view returns (WeightedValidator[] memory _list);

  /**
   * @dev Returns the validator list.
   */
  function getValidators() external view returns (address[] memory _validators);

  /**
   * @dev Returns the validator at `_index` position.
   */
  function validators(uint256 _index) external view returns (WeightedValidator memory);

  /**
   * @dev Returns total of validators.
   */
  function totalValidators() external view returns (uint256);

  /**
   * @dev Returns total weights.
   */
  function totalWeights() external view returns (uint256);

  /**
   * @dev Adds validators.
   *
   * Requirements:
   * - The weights are larger than 0.
   * - The validators are not added.
   * - The method caller is admin.
   *
   * Emits the `ValidatorsAdded` event.
   *
   */
  function addValidators(WeightedValidator[] calldata _validators) external;

  /**
   * @dev Updates validators.
   *
   * Requirements:
   * - The weights are larger than 0.
   * - The validators are added.
   * - The method caller is admin.
   *
   * Emits the `ValidatorsUpdated` event.
   *
   */
  function updateValidators(WeightedValidator[] calldata _validators) external;

  /**
   * @dev Removes validators.
   *
   * Requirements:
   * - The validators are added.
   * - The method caller is admin.
   *
   * Emits the `ValidatorsRemoved` event.
   *
   */
  function removeValidators(address[] calldata _validators) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/Token.sol";

interface MappedTokenConsumer {
  struct MappedToken {
    Token.Standard erc;
    address tokenAddr;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SignatureConsumer {
  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IWETH.sol";

library Token {
  enum Standard {
    ERC20,
    ERC721
  }
  struct Info {
    Standard erc;
    // For ERC20:  the id must be 0 and the quantity is larger than 0.
    // For ERC721: the quantity must be 0.
    uint256 id;
    uint256 quantity;
  }

  // keccak256("TokenInfo(uint8 erc,uint256 id,uint256 quantity)");
  bytes32 public constant INFO_TYPE_HASH = 0x1e2b74b2a792d5c0f0b6e59b037fa9d43d84fbb759337f0112fcc15ca414fc8d;

  /**
   * @dev Returns token info struct hash.
   */
  function hash(Info memory _info) internal pure returns (bytes32) {
    return keccak256(abi.encode(INFO_TYPE_HASH, _info.erc, _info.id, _info.quantity));
  }

  /**
   * @dev Validates the token info.
   */
  function validate(Info memory _info) internal pure {
    require(
      (_info.erc == Standard.ERC20 && _info.quantity > 0 && _info.id == 0) ||
        (_info.erc == Standard.ERC721 && _info.quantity == 0),
      "Token: invalid info"
    );
  }

  /**
   * @dev Transfer asset from.
   *
   * Requirements:
   * - The `_from` address must approve for the contract using this library.
   *
   */
  function transferFrom(
    Info memory _info,
    address _from,
    address _to,
    address _token
  ) internal {
    bool _success;
    bytes memory _data;
    if (_info.erc == Standard.ERC20) {
      (_success, _data) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _info.quantity));
      _success = _success && (_data.length == 0 || abi.decode(_data, (bool)));
    } else if (_info.erc == Standard.ERC721) {
      // bytes4(keccak256("transferFrom(address,address,uint256)"))
      (_success, ) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _info.id));
    } else {
      revert("Token: unsupported token standard");
    }

    if (!_success) {
      revert(
        string(
          abi.encodePacked(
            "Token: could not transfer ",
            toString(_info),
            " from ",
            Strings.toHexString(uint160(_from), 20),
            " to ",
            Strings.toHexString(uint160(_to), 20),
            " token ",
            Strings.toHexString(uint160(_token), 20)
          )
        )
      );
    }
  }

  /**
   * @dev Transfers ERC721 token and returns the result.
   */
  function tryTransferERC721(
    address _token,
    address _to,
    uint256 _id
  ) internal returns (bool _success) {
    (_success, ) = _token.call(abi.encodeWithSelector(IERC721.transferFrom.selector, address(this), _to, _id));
  }

  /**
   * @dev Transfers ERC20 token and returns the result.
   */
  function tryTransferERC20(
    address _token,
    address _to,
    uint256 _quantity
  ) internal returns (bool _success) {
    bytes memory _data;
    (_success, _data) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _quantity));
    _success = _success && (_data.length == 0 || abi.decode(_data, (bool)));
  }

  /**
   * @dev Transfer assets from current address to `_to` address.
   */
  function transfer(
    Info memory _info,
    address _to,
    address _token
  ) internal {
    bool _success;
    if (_info.erc == Standard.ERC20) {
      _success = tryTransferERC20(_token, _to, _info.quantity);
    } else if (_info.erc == Standard.ERC721) {
      _success = tryTransferERC721(_token, _to, _info.id);
    } else {
      revert("Token: unsupported token standard");
    }

    if (!_success) {
      revert(
        string(
          abi.encodePacked(
            "Token: could not transfer ",
            toString(_info),
            " to ",
            Strings.toHexString(uint160(_to), 20),
            " token ",
            Strings.toHexString(uint160(_token), 20)
          )
        )
      );
    }
  }

  /**
   * @dev Tries minting and transfering assets.
   *
   * @notice Prioritizes transfer native token if the token is wrapped.
   *
   */
  function handleAssetTransfer(
    Info memory _info,
    address payable _to,
    address _token,
    IWETH _wrappedNativeToken
  ) internal {
    bool _success;
    if (_token == address(_wrappedNativeToken)) {
      // Try sending the native token before transferring the wrapped token
      if (!_to.send(_info.quantity)) {
        _wrappedNativeToken.deposit{ value: _info.quantity }();
        transfer(_info, _to, _token);
      }
    } else if (_info.erc == Token.Standard.ERC20) {
      uint256 _balance = IERC20(_token).balanceOf(address(this));

      if (_balance < _info.quantity) {
        // bytes4(keccak256("mint(address,uint256)"))
        (_success, ) = _token.call(abi.encodeWithSelector(0x40c10f19, address(this), _info.quantity - _balance));
        require(_success, "Token: ERC20 minting failed");
      }

      transfer(_info, _to, _token);
    } else if (_info.erc == Token.Standard.ERC721) {
      if (!tryTransferERC721(_token, _to, _info.id)) {
        // bytes4(keccak256("mint(address,uint256)"))
        (_success, ) = _token.call(abi.encodeWithSelector(0x40c10f19, _to, _info.id));
        require(_success, "Token: ERC721 minting failed");
      }
    } else {
      revert("Token: unsupported token standard");
    }
  }

  /**
   * @dev Returns readable string.
   */
  function toString(Info memory _info) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "TokenInfo(",
          Strings.toHexString(uint160(_info.erc), 1),
          ",",
          Strings.toHexString(_info.id),
          ",",
          Strings.toHexString(_info.quantity),
          ")"
        )
      );
  }

  struct Owner {
    address addr;
    address tokenAddr;
    uint256 chainId;
  }

  // keccak256("TokenOwner(address addr,address tokenAddr,uint256 chainId)");
  bytes32 public constant OWNER_TYPE_HASH = 0x353bdd8d69b9e3185b3972e08b03845c0c14a21a390215302776a7a34b0e8764;

  /**
   * @dev Returns ownership struct hash.
   */
  function hash(Owner memory _owner) internal pure returns (bytes32) {
    return keccak256(abi.encode(OWNER_TYPE_HASH, _owner.addr, _owner.tokenAddr, _owner.chainId));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Token.sol";

library Transfer {
  using ECDSA for bytes32;

  enum Kind {
    Deposit,
    Withdrawal
  }

  struct Request {
    // For deposit request: Recipient address on Ronin network
    // For withdrawal request: Recipient address on mainchain network
    address recipientAddr;
    // Token address to deposit/withdraw
    // Value 0: native token
    address tokenAddr;
    Token.Info info;
  }

  /**
   * @dev Converts the transfer request into the deposit receipt.
   */
  function into_deposit_receipt(
    Request memory _request,
    address _requester,
    uint256 _id,
    address _roninTokenAddr,
    uint256 _roninChainId
  ) internal view returns (Receipt memory _receipt) {
    _receipt.id = _id;
    _receipt.kind = Kind.Deposit;
    _receipt.mainchain.addr = _requester;
    _receipt.mainchain.tokenAddr = _request.tokenAddr;
    _receipt.mainchain.chainId = block.chainid;
    _receipt.ronin.addr = _request.recipientAddr;
    _receipt.ronin.tokenAddr = _roninTokenAddr;
    _receipt.ronin.chainId = _roninChainId;
    _receipt.info = _request.info;
  }

  /**
   * @dev Converts the transfer request into the withdrawal receipt.
   */
  function into_withdrawal_receipt(
    Request memory _request,
    address _requester,
    uint256 _id,
    address _mainchainTokenAddr,
    uint256 _mainchainId
  ) internal view returns (Receipt memory _receipt) {
    _receipt.id = _id;
    _receipt.kind = Kind.Withdrawal;
    _receipt.ronin.addr = _requester;
    _receipt.ronin.tokenAddr = _request.tokenAddr;
    _receipt.ronin.chainId = block.chainid;
    _receipt.mainchain.addr = _request.recipientAddr;
    _receipt.mainchain.tokenAddr = _mainchainTokenAddr;
    _receipt.mainchain.chainId = _mainchainId;
    _receipt.info = _request.info;
  }

  struct Receipt {
    uint256 id;
    Kind kind;
    Token.Owner mainchain;
    Token.Owner ronin;
    Token.Info info;
  }

  // keccak256("Receipt(uint256 id,uint8 kind,TokenOwner mainchain,TokenOwner ronin,TokenInfo info)TokenInfo(uint8 erc,uint256 id,uint256 quantity)TokenOwner(address addr,address tokenAddr,uint256 chainId)");
  bytes32 public constant TYPE_HASH = 0xb9d1fe7c9deeec5dc90a2f47ff1684239519f2545b2228d3d91fb27df3189eea;

  /**
   * @dev Returns token info struct hash.
   */
  function hash(Receipt memory _receipt) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          TYPE_HASH,
          _receipt.id,
          _receipt.kind,
          Token.hash(_receipt.mainchain),
          Token.hash(_receipt.ronin),
          Token.hash(_receipt.info)
        )
      );
  }

  /**
   * @dev Returns the receipt digest.
   */
  function receiptDigest(bytes32 _domainSeparator, bytes32 _receiptHash) internal pure returns (bytes32) {
    return _domainSeparator.toTypedDataHash(_receiptHash);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IWETH.sol";
import "../library/Transfer.sol";
import "../interfaces/SignatureConsumer.sol";
import "../interfaces/MappedTokenConsumer.sol";

interface IMainchainGatewayV2 is SignatureConsumer, MappedTokenConsumer {
  /// @dev Emitted when the deposit is requested
  event DepositRequested(bytes32 receiptHash, Transfer.Receipt receipt);
  /// @dev Emitted when the assets are withdrawn
  event Withdrew(bytes32 receiptHash, Transfer.Receipt receipt);
  /// @dev Emitted when the tokens are mapped
  event TokenMapped(address[] mainchainTokens, address[] roninTokens, Token.Standard[] standards);
  /// @dev Emitted when the wrapped native token contract is updated
  event WrappedNativeTokenContractUpdated(IWETH weth);
  /// @dev Emitted when the withdrawal is locked
  event WithdrawalLocked(bytes32 receiptHash, Transfer.Receipt receipt);
  /// @dev Emitted when the withdrawal is unlocked
  event WithdrawalUnlocked(bytes32 receiptHash, Transfer.Receipt receipt);

  /**
   * @dev Returns the domain seperator.
   */
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @dev Returns deposit count.
   */
  function depositCount() external view returns (uint256);

  /**
   * @dev Sets the wrapped native token contract.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits the `WrappedNativeTokenContractUpdated` event.
   *
   */
  function setWrappedNativeTokenContract(IWETH _wrappedToken) external;

  /**
   * @dev Returns whether the withdrawal is locked.
   */
  function withdrawalLocked(uint256 withdrawalId) external view returns (bool);

  /**
   * @dev Returns the withdrawal hash.
   */
  function withdrawalHash(uint256 withdrawalId) external view returns (bytes32);

  /**
   * @dev Locks the assets and request deposit.
   */
  function requestDepositFor(Transfer.Request calldata _request) external payable;

  /**
   * @dev Withdraws based on the receipt and the validator signatures.
   * Returns whether the withdrawal is locked.
   *
   * Emits the `Withdrew` once the assets are released.
   *
   */
  function submitWithdrawal(Transfer.Receipt memory _receipt, Signature[] memory _signatures)
    external
    returns (bool _locked);

  /**
   * @dev Approves a specific withdrawal.
   *
   * Requirements:
   * - The method caller is a validator.
   *
   * Emits the `Withdrew` once the assets are released.
   *
   */
  function unlockWithdrawal(Transfer.Receipt calldata _receipt) external;

  /**
   * @dev Maps mainchain tokens to Ronin network.
   *
   * Requirement:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `TokenMapped` event.
   *
   */
  function mapTokens(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards
  ) external;

  /**
   * @dev Maps mainchain tokens to Ronin network and sets thresholds.
   *
   * Requirement:
   * - The method caller is admin.
   * - The arrays have the same length and its length larger than 0.
   *
   * Emits the `TokenMapped` event.
   *
   */
  function mapTokensAndThresholds(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards,
    uint256[][4] calldata _thresholds
  ) external;

  /**
   * @dev Returns token address on Ronin network.
   * @notice Reverts for unsupported token.
   */
  function getRoninToken(address _mainchainToken) external view returns (MappedToken memory _token);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../extensions/GatewayV2.sol";
import "../extensions/WithdrawalLimitation.sol";
import "../library/Transfer.sol";
import "./IMainchainGatewayV2.sol";

contract MainchainGatewayV2 is WithdrawalLimitation, Initializable, AccessControlEnumerable, IMainchainGatewayV2 {
  using Token for Token.Info;
  using Transfer for Transfer.Request;
  using Transfer for Transfer.Receipt;

  /// @dev Withdrawal unlocker role hash
  bytes32 public constant WITHDRAWAL_UNLOCKER_ROLE = keccak256("WITHDRAWAL_UNLOCKER_ROLE");

  /// @dev Wrapped native token address
  IWETH public wrappedNativeToken;
  /// @dev Ronin network id
  uint256 public roninChainId;
  /// @dev Total deposit
  uint256 public depositCount;
  /// @dev Domain seperator
  bytes32 internal _domainSeparator;
  /// @dev Mapping from mainchain token => token address on Ronin network
  mapping(address => MappedToken) internal _roninToken;
  /// @dev Mapping from withdrawal id => withdrawal hash
  mapping(uint256 => bytes32) public withdrawalHash;
  /// @dev Mapping from withdrawal id => locked
  mapping(uint256 => bool) public withdrawalLocked;

  fallback() external payable {
    _fallback();
  }

  receive() external payable {
    _fallback();
  }

  /**
   * @dev Initializes contract storage.
   */
  function initialize(
    address _roleSetter,
    IWETH _wrappedToken,
    IWeightedValidator _validatorContract,
    uint256 _roninChainId,
    uint256 _numerator,
    uint256 _highTierVWNumerator,
    uint256 _denominator,
    // _addresses[0]: mainchainTokens
    // _addresses[1]: roninTokens
    // _addresses[2]: withdrawalUnlockers
    address[][3] calldata _addresses,
    // _thresholds[0]: highTierThreshold
    // _thresholds[1]: lockedThreshold
    // _thresholds[2]: unlockFeePercentages
    // _thresholds[3]: dailyWithdrawalLimit
    uint256[][4] calldata _thresholds,
    Token.Standard[] calldata _standards
  ) external payable virtual initializer {
    _setupRole(DEFAULT_ADMIN_ROLE, _roleSetter);
    roninChainId = _roninChainId;

    _setWrappedNativeTokenContract(_wrappedToken);
    _setValidatorContract(_validatorContract);
    _updateDomainSeparator();
    _setThreshold(_numerator, _denominator);
    _setHighTierVoteWeightThreshold(_highTierVWNumerator, _denominator);
    _verifyThresholds();

    if (_addresses[0].length > 0) {
      // Map mainchain tokens to ronin tokens
      _mapTokens(_addresses[0], _addresses[1], _standards);
      // Sets thresholds based on the mainchain tokens
      _setHighTierThresholds(_addresses[0], _thresholds[0]);
      _setLockedThresholds(_addresses[0], _thresholds[1]);
      _setUnlockFeePercentages(_addresses[0], _thresholds[2]);
      _setDailyWithdrawalLimits(_addresses[0], _thresholds[3]);
    }

    // Grant role for withdrawal unlocker
    for (uint256 _i; _i < _addresses[2].length; _i++) {
      _grantRole(WITHDRAWAL_UNLOCKER_ROLE, _addresses[2][_i]);
    }
  }

  /**
   * @dev Receives ether without doing anything. Use this function to topup native token.
   */
  function receiveEther() external payable {}

  /**
   * @dev See {IMainchainGatewayV2-DOMAIN_SEPARATOR}.
   */
  function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
    return _domainSeparator;
  }

  /**
   * @dev See {IMainchainGatewayV2-setWrappedNativeTokenContract}.
   */
  function setWrappedNativeTokenContract(IWETH _wrappedToken) external virtual onlyAdmin {
    _setWrappedNativeTokenContract(_wrappedToken);
  }

  /**
   * @dev See {IMainchainGatewayV2-requestDepositFor}.
   */
  function requestDepositFor(Transfer.Request calldata _request) external payable virtual whenNotPaused {
    _requestDepositFor(_request, msg.sender);
  }

  /**
   * @dev See {IMainchainGatewayV2-submitWithdrawal}.
   */
  function submitWithdrawal(Transfer.Receipt calldata _receipt, Signature[] calldata _signatures)
    external
    virtual
    whenNotPaused
    returns (bool _locked)
  {
    return _submitWithdrawal(_receipt, _signatures);
  }

  /**
   * @dev See {IMainchainGatewayV2-unlockWithdrawal}.
   */
  function unlockWithdrawal(Transfer.Receipt calldata _receipt) external onlyRole(WITHDRAWAL_UNLOCKER_ROLE) {
    bytes32 _receiptHash = _receipt.hash();
    require(withdrawalHash[_receipt.id] == _receipt.hash(), "MainchainGatewayV2: invalid receipt");
    require(withdrawalLocked[_receipt.id], "MainchainGatewayV2: query for approved withdrawal");
    delete withdrawalLocked[_receipt.id];
    emit WithdrawalUnlocked(_receiptHash, _receipt);

    address _token = _receipt.mainchain.tokenAddr;
    if (_receipt.info.erc == Token.Standard.ERC20) {
      Token.Info memory _feeInfo = _receipt.info;
      _feeInfo.quantity = _computeFeePercentage(_receipt.info.quantity, unlockFeePercentages[_token]);
      Token.Info memory _withdrawInfo = _receipt.info;
      _withdrawInfo.quantity = _receipt.info.quantity - _feeInfo.quantity;

      _feeInfo.handleAssetTransfer(payable(msg.sender), _token, wrappedNativeToken);
      _withdrawInfo.handleAssetTransfer(payable(_receipt.mainchain.addr), _token, wrappedNativeToken);
    } else {
      _receipt.info.handleAssetTransfer(payable(_receipt.mainchain.addr), _token, wrappedNativeToken);
    }

    emit Withdrew(_receiptHash, _receipt);
  }

  /**
   * @dev See {IMainchainGatewayV2-mapTokens}.
   */
  function mapTokens(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards
  ) external virtual onlyAdmin {
    require(_mainchainTokens.length > 0, "MainchainGatewayV2: query for empty array");
    _mapTokens(_mainchainTokens, _roninTokens, _standards);
  }

  /**
   * @dev See {IMainchainGatewayV2-mapTokensAndThresholds}.
   */
  function mapTokensAndThresholds(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards,
    // _thresholds[0]: highTierThreshold
    // _thresholds[1]: lockedThreshold
    // _thresholds[2]: unlockFeePercentages
    // _thresholds[3]: dailyWithdrawalLimit
    uint256[][4] calldata _thresholds
  ) external virtual onlyAdmin {
    require(_mainchainTokens.length > 0, "MainchainGatewayV2: query for empty array");
    _mapTokens(_mainchainTokens, _roninTokens, _standards);
    _setHighTierThresholds(_mainchainTokens, _thresholds[0]);
    _setLockedThresholds(_mainchainTokens, _thresholds[1]);
    _setUnlockFeePercentages(_mainchainTokens, _thresholds[2]);
    _setDailyWithdrawalLimits(_mainchainTokens, _thresholds[3]);
  }

  /**
   * @dev See {IMainchainGatewayV2-getRoninToken}.
   */
  function getRoninToken(address _mainchainToken) public view returns (MappedToken memory _token) {
    _token = _roninToken[_mainchainToken];
    require(_token.tokenAddr != address(0), "MainchainGatewayV2: unsupported token");
  }

  /**
   * @dev Maps mainchain tokens to Ronin network.
   *
   * Requirement:
   * - The arrays have the same length.
   *
   * Emits the `TokenMapped` event.
   *
   */
  function _mapTokens(
    address[] calldata _mainchainTokens,
    address[] calldata _roninTokens,
    Token.Standard[] calldata _standards
  ) internal virtual {
    require(
      _mainchainTokens.length == _roninTokens.length && _mainchainTokens.length == _standards.length,
      "MainchainGatewayV2: invalid array length"
    );

    for (uint256 _i; _i < _mainchainTokens.length; _i++) {
      _roninToken[_mainchainTokens[_i]].tokenAddr = _roninTokens[_i];
      _roninToken[_mainchainTokens[_i]].erc = _standards[_i];
    }

    emit TokenMapped(_mainchainTokens, _roninTokens, _standards);
  }

  /**
   * @dev Submits withdrawal receipt.
   *
   * Requirements:
   * - The receipt kind is withdrawal.
   * - The receipt is to withdraw on this chain.
   * - The receipt is not used to withdraw before.
   * - The withdrawal is not reached the limit threshold.
   * - The signer weight total is larger than or equal to the minimum threshold.
   * - The signature signers are in order.
   *
   * Emits the `Withdrew` once the assets are released.
   *
   */
  function _submitWithdrawal(Transfer.Receipt calldata _receipt, Signature[] memory _signatures)
    internal
    virtual
    returns (bool _locked)
  {
    uint256 _id = _receipt.id;
    uint256 _quantity = _receipt.info.quantity;
    address _tokenAddr = _receipt.mainchain.tokenAddr;

    _receipt.info.validate();
    require(_receipt.kind == Transfer.Kind.Withdrawal, "MainchainGatewayV2: invalid receipt kind");
    require(_receipt.mainchain.chainId == block.chainid, "MainchainGatewayV2: invalid chain id");
    MappedToken memory _token = getRoninToken(_receipt.mainchain.tokenAddr);
    require(
      _token.erc == _receipt.info.erc && _token.tokenAddr == _receipt.ronin.tokenAddr,
      "MainchainGatewayV2: invalid receipt"
    );
    require(withdrawalHash[_id] == bytes32(0), "MainchainGatewayV2: query for processed withdrawal");
    require(
      _receipt.info.erc == Token.Standard.ERC721 || !_reachedWithdrawalLimit(_tokenAddr, _quantity),
      "MainchainGatewayV2: reached daily withdrawal limit"
    );

    bytes32 _receiptHash = _receipt.hash();
    bytes32 _receiptDigest = Transfer.receiptDigest(_domainSeparator, _receiptHash);
    IWeightedValidator _validatorContract = validatorContract;

    uint256 _minimumVoteWeight;
    (_minimumVoteWeight, _locked) = _computeMinVoteWeight(_receipt.info.erc, _tokenAddr, _quantity, _validatorContract);

    {
      bool _passed;
      address _signer;
      address _lastSigner;
      Signature memory _sig;
      uint256 _weight;
      for (uint256 _i; _i < _signatures.length; _i++) {
        _sig = _signatures[_i];
        _signer = ecrecover(_receiptDigest, _sig.v, _sig.r, _sig.s);
        require(_lastSigner < _signer, "MainchainGatewayV2: invalid order");
        _lastSigner = _signer;

        _weight += _validatorContract.getValidatorWeight(_signer);
        if (_weight >= _minimumVoteWeight) {
          _passed = true;
          break;
        }
      }
      require(_passed, "MainchainGatewayV2: query for insufficient vote weight");
      withdrawalHash[_id] = _receiptHash;
    }

    if (_locked) {
      withdrawalLocked[_id] = true;
      emit WithdrawalLocked(_receiptHash, _receipt);
      return _locked;
    }

    _recordWithdrawal(_tokenAddr, _quantity);
    _receipt.info.handleAssetTransfer(payable(_receipt.mainchain.addr), _tokenAddr, wrappedNativeToken);
    emit Withdrew(_receiptHash, _receipt);
  }

  /**
   * @dev Requests deposit made by `_requester` address.
   *
   * Requirements:
   * - The token info is valid.
   * - The `msg.value` is 0 while depositing ERC20 token.
   * - The `msg.value` is equal to deposit quantity while depositing native token.
   *
   * Emits the `DepositRequested` event.
   *
   */
  function _requestDepositFor(Transfer.Request memory _request, address _requester) internal virtual {
    MappedToken memory _token;
    address _weth = address(wrappedNativeToken);

    _request.info.validate();
    if (_request.tokenAddr == address(0)) {
      require(_request.info.quantity == msg.value, "MainchainGatewayV2: invalid request");
      _token = getRoninToken(_weth);
      require(_token.erc == _request.info.erc, "MainchainGatewayV2: invalid token standard");
    } else {
      require(msg.value == 0, "MainchainGatewayV2: invalid request");
      _token = getRoninToken(_request.tokenAddr);
      require(_token.erc == _request.info.erc, "MainchainGatewayV2: invalid token standard");
      _request.info.transferFrom(_requester, address(this), _request.tokenAddr);
      // Withdraw if token is WETH
      if (_weth == _request.tokenAddr) {
        IWETH(_weth).withdraw(_request.info.quantity);
      }
    }

    uint256 _depositId = depositCount++;
    Transfer.Receipt memory _receipt = _request.into_deposit_receipt(
      _requester,
      _depositId,
      _token.tokenAddr,
      roninChainId
    );

    emit DepositRequested(_receipt.hash(), _receipt);
  }

  /**
   * @dev Returns the minimum vote weight for the token.
   */
  function _computeMinVoteWeight(
    Token.Standard _erc,
    address _token,
    uint256 _quantity,
    IWeightedValidator _validatorContract
  ) internal virtual returns (uint256 _weight, bool _locked) {
    uint256 _totalWeights = _validatorContract.totalWeights();
    _weight = _minimumVoteWeight(_totalWeights);
    if (_erc == Token.Standard.ERC20) {
      if (highTierThreshold[_token] <= _quantity) {
        _weight = _highTierVoteWeight(_totalWeights);
      }
      _locked = _lockedWithdrawalRequest(_token, _quantity);
    }
  }

  /**
   * @dev Update domain seperator.
   */
  function _updateDomainSeparator() internal {
    _domainSeparator = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("MainchainGatewayV2"),
        keccak256("2"),
        block.chainid,
        address(this)
      )
    );
  }

  /**
   * @dev Sets the WETH contract.
   *
   * Emits the `WrappedNativeTokenContractUpdated` event.
   *
   */
  function _setWrappedNativeTokenContract(IWETH _wrapedToken) internal {
    wrappedNativeToken = _wrapedToken;
    emit WrappedNativeTokenContractUpdated(_wrapedToken);
  }

  /**
   * @dev Receives ETH from WETH or creates deposit request.
   */
  function _fallback() internal virtual whenNotPaused {
    if (msg.sender != address(wrappedNativeToken)) {
      Transfer.Request memory _request;
      _request.recipientAddr = msg.sender;
      _request.info.quantity = msg.value;
      _requestDepositFor(_request, _request.recipientAddr);
    }
  }
}