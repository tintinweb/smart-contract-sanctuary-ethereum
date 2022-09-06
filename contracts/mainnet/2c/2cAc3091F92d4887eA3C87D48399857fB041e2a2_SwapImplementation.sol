// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./SwapGovernance.sol";
import "./SwapStructs.sol";
/**
 * @title AtlasDexSwap
 * @dev Proxy contract to swap first by redeeming from wormhole and then call 1inch router to swap assets
 * successful.
 */
contract Swap is SwapGovernance  {

    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    using SafeMath for uint256;

    // Event for locked amount.
    event AmountLocked (address indexed dstReceiver, uint256 amountReceived);

    /**
     * @dev Withdraw Tokens on Wrapped. 
     * @param _tokenAmount to be used for withdrawing in native currency from wrapped.
     * @param _isUserFundUsed is used either we need to get fund from user address and then call swap or direct use smart contract balance.   
     */
    function withdrawToUnWrappedToken(uint256 _tokenAmount, bool _isUserFundUsed) internal returns (uint256) {
        IWETH wrapped = IWETH(NATIVE_WRAPPED_ADDRESS);
        if (_isUserFundUsed) {
            require(wrapped.balanceOf(msg.sender) >= _tokenAmount, "Atlas DEX: You have insufficient balance to UnWrap");
            wrapped.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        }
        wrapped.withdraw(_tokenAmount);
        // First Calculating here deduct 0.15 percent.
        uint256 feeDeductionAmount = (_tokenAmount.mul(FEE_PERCENT)).div(FEE_PERCENT_DENOMINATOR);
        payable(FEE_COLLECTOR).transfer(feeDeductionAmount);
        payable(msg.sender).transfer((_tokenAmount.sub(feeDeductionAmount)));
        return  _tokenAmount;
    } // end of deposit ToWrappedToken.    
    /**
     * @dev Deposit Tokens on Wrapped. 
     */
    function depositToWrappedToken() internal returns (uint256) {
        require(msg.value > 0, "Atlas Dex: Amount should be greater than 0 to deposit for wrapped.");
        IWETH wrapped = IWETH(NATIVE_WRAPPED_ADDRESS);
        wrapped.deposit{value: msg.value}();
        // First Calculating here deduct 0.15 percent.
        uint256 feeDeductionAmount = (msg.value * FEE_PERCENT) / FEE_PERCENT_DENOMINATOR;
        wrapped.transfer(FEE_COLLECTOR, feeDeductionAmount);

        wrapped.transfer(msg.sender, (msg.value - feeDeductionAmount));
        return  msg.value - feeDeductionAmount;
    } // end of deposit ToWrappedToken.
    /**
     * @dev Swap Tokens on 0x. 
     * @param _0xData a 0x data to call aggregate router to swap assets.
     */
    function _swapToken0x(bytes calldata _0xData) internal returns (uint256) {

        ( SwapStructs._0xSwapDescription memory swapDescriptionObj) = abi.decode(_0xData[4:], (SwapStructs._0xSwapDescription));
         if (swapDescriptionObj.inputToken == 0x0000000000000000000000000000000000000080) { // this is because as sometime 0x send data like sellToPancakeSwap or sellToUniswapSwap
                ( address[] memory tokens, uint256 sellAmount,, ) = abi.decode(_0xData[4:], (address[], uint256, uint256, uint8));
                swapDescriptionObj.inputToken = tokens[0];
                swapDescriptionObj.outputToken = tokens[tokens.length - 1];
                swapDescriptionObj.inputTokenAmount = sellAmount;
        }
        uint256 outputCurrencyBalanceBeforeSwap = 0;

        // this if else is to save output token balance
        if (address(swapDescriptionObj.outputToken) == NATIVE_ADDRESS) {
            outputCurrencyBalanceBeforeSwap = address(this).balance;
        } else {
            IERC20 swapOutputToken = IERC20(swapDescriptionObj.outputToken);
            outputCurrencyBalanceBeforeSwap = swapOutputToken.balanceOf(address(this));
        } // end of else

        
        if (address(swapDescriptionObj.inputToken) == NATIVE_ADDRESS) {
            // It means we are trying to transfer with Native amount
            require(msg.value >= swapDescriptionObj.inputTokenAmount, "Atlas DEX: Amount Not match with Swap Amount.");
        } else {
            IERC20 swapSrcToken = IERC20(swapDescriptionObj.inputToken);
            if (swapSrcToken.allowance(address(this), OxAggregatorRouter) < swapDescriptionObj.inputTokenAmount) {
                swapSrcToken.safeApprove(OxAggregatorRouter, MAX_INT);
            }

            require(swapSrcToken.balanceOf(msg.sender) >= swapDescriptionObj.inputTokenAmount, "Atlas DEX: You have insufficent balance to swap");
            swapSrcToken.safeTransferFrom(msg.sender, address(this), swapDescriptionObj.inputTokenAmount);
        }

        (bool success, ) = address(OxAggregatorRouter).call{ value: msg.value }(_0xData);
        require(success, "Atlas Dex: Swap Return Failed");
        uint256 outputCurrencyBalanceAfterSwap = 0;
        // Again this check is to maintain for sending receiver balance to msg.sender
        if (address(swapDescriptionObj.outputToken) == NATIVE_ADDRESS) {
            outputCurrencyBalanceAfterSwap = address(this).balance ;
            outputCurrencyBalanceAfterSwap = outputCurrencyBalanceAfterSwap - outputCurrencyBalanceBeforeSwap;
            require(outputCurrencyBalanceAfterSwap > 0, "Atlas DEX: Transfer output amount should be greater than 0.");
            payable(msg.sender).transfer(outputCurrencyBalanceAfterSwap);
        } else {
            IERC20 swapOutputToken = IERC20(swapDescriptionObj.outputToken);
            outputCurrencyBalanceAfterSwap = swapOutputToken.balanceOf(address(this));
            outputCurrencyBalanceAfterSwap = outputCurrencyBalanceAfterSwap - outputCurrencyBalanceBeforeSwap;
            require(outputCurrencyBalanceAfterSwap > 0, "Atlas DEX: Transfer output amount should be greater than 0.");
            swapOutputToken.safeTransfer(msg.sender, outputCurrencyBalanceAfterSwap);
        } // end of else
        // Now need to transfer fund to destination address. 
        return outputCurrencyBalanceAfterSwap;
    } // end of swap function
    /**
     * @dev Swap Tokens on 1inch. 
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     * @param _isUserFundUsed is used either we need to get fund from user address and then call swap or direct use smart contract balance.
     */
    function _swapToken1Inch(bytes calldata _1inchData, bool _isUserFundUsed) internal returns (uint256) {
        (, SwapStructs._1inchSwapDescription memory swapDescriptionObj,) = abi.decode(_1inchData[4:], (address, SwapStructs._1inchSwapDescription, bytes));

        uint256 amountForNative = 0;
        if (address(swapDescriptionObj.srcToken) == NATIVE_ADDRESS) {
            // It means we are trying to transfer with Native amount
            require(msg.value >= swapDescriptionObj.amount, "Atlas DEX: Amount Not match with Swap Amount.");
            amountForNative = swapDescriptionObj.amount;
        } else {
            IERC20 swapSrcToken = IERC20(swapDescriptionObj.srcToken);
            if (swapSrcToken.allowance(address(this), oneInchAggregatorRouter) < swapDescriptionObj.amount) {
                swapSrcToken.safeApprove(oneInchAggregatorRouter, MAX_INT);
            }

            // when calling from unlock by payload, need to use smart contract fund.
            if (_isUserFundUsed) {
                require(swapSrcToken.balanceOf(msg.sender) >= swapDescriptionObj.amount, "Atlas DEX: You have insufficient balance to swap");
                swapSrcToken.safeTransferFrom(msg.sender, address(this), swapDescriptionObj.amount);
            }
        } // end of else


        (bool success, bytes memory _returnData ) = address(oneInchAggregatorRouter).call{ value: amountForNative }(_1inchData);
        require(success, "Atlas Dex: Swap Return Failed");


        (uint returnAmount, ) = abi.decode(_returnData, (uint, uint));
        return returnAmount;
    } // end of swap function

    /**
     * @dev Swap Tokens on Chain. 
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     */
    function swapTokens(bytes calldata _1inchData, bytes calldata _0xData, bool _IsWrapped, bool _IsUnWrapped, uint256 _amount) external payable returns (uint256) {
        if(_1inchData.length > 1) {
            return _swapToken1Inch(_1inchData, true);
        } else if (_0xData.length > 1) {
            return _swapToken0x(_0xData);
        } else if (_IsWrapped) {
            return depositToWrappedToken();
        } else if ( _IsUnWrapped) {
            return withdrawToUnWrappedToken(_amount, true);
        }
        return 0;

    }

    /**
     * @dev Initiate a wormhole bridge redeem call to unlock asset and then call 1inch router to swap tokens with unlocked balance.
     * @param _wormholeTokenBridgeToken  a wormhole bridge where fromw need to redeem token
     * @param _encodedVAA  VAA for redeeming to get from wormhole guardians
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     * @param _0xData a 1inch data to call aggregate router to swap assets.
     */
    function unlockTokens(address _wormholeTokenBridgeToken, bytes memory _encodedVAA,  bytes calldata _1inchData, bytes calldata _0xData, bool _IsWrapped, bool _IsUnWrapped, uint256 _amount) external payable returns (uint256) {
        // initiate wormhole bridge contract  
        require(_wormholeTokenBridgeToken != address(0), "Atlas Dex: Wormhole Token Bride Address can't be null");      
        ITokenBridgeWormhole wormholeTokenBridgeContract =  ITokenBridgeWormhole(_wormholeTokenBridgeToken);

        // initiate wormhole contract        
        IWormhole wormholeContract = IWormhole(wormholeTokenBridgeContract.wormhole());

        (WormholeStructs.VM memory vm, ,) = wormholeContract.parseAndVerifyVM(_encodedVAA);

        WormholeStructs.Transfer memory transfer = wormholeTokenBridgeContract.parseTransfer(vm.payload);

        
        IERC20 transferToken;
        if (transfer.tokenChain == wormholeTokenBridgeContract.chainId()) {
            transferToken = IERC20(address(uint160(uint256(transfer.tokenAddress))));
        } else {
            address wrapped = wormholeTokenBridgeContract.wrappedAsset(transfer.tokenChain, transfer.tokenAddress);
            require(wrapped != address(0), "AtlasDex: no wrapper for this token created yet");

            transferToken = IERC20(wrapped);
        }
        wormholeTokenBridgeContract.completeTransfer(_encodedVAA);


        uint256 amountTransfer;
        if(_1inchData.length > 1) {
            (, SwapStructs._1inchSwapDescription memory swapDescriptionObj,) = abi.decode(_1inchData[4:], (address, SwapStructs._1inchSwapDescription, bytes));
            require(swapDescriptionObj.srcToken == transferToken, "Atlas DEX: Token Not Matched");
            amountTransfer = _swapToken1Inch(_1inchData, true);
        } else if (_0xData.length > 1) {
            ( SwapStructs._0xSwapDescription memory swapDescriptionObj) = abi.decode(_0xData[4:], (SwapStructs._0xSwapDescription));
 

            if (swapDescriptionObj.inputToken == 0x0000000000000000000000000000000000000080) { // this is because as sometime 0x send data like sellToPancakeSwap or sellToUniswapSwap
                ( address[] memory tokens, uint256 sellAmount,, ) = abi.decode(_0xData[4:], (address[], uint256, uint256, uint8));
                swapDescriptionObj.inputToken = tokens[0];
                swapDescriptionObj.outputToken = tokens[tokens.length - 1];
                swapDescriptionObj.inputTokenAmount = sellAmount;
            }
            require(swapDescriptionObj.inputToken == address(transferToken), "Atlas DEX: Token Not Matched");

            amountTransfer = _swapToken0x(_0xData);
        }
        else if (_IsWrapped) {
            amountTransfer =  depositToWrappedToken();
        } else if ( _IsUnWrapped) {
            amountTransfer = withdrawToUnWrappedToken(_amount, true);
        }
        return amountTransfer;

    } // end of unlock Token

    /**
     * @dev Initiate a wormhole bridge redeem call to unlock asset with payload and then call 1inch router to swap tokens with unlocked balance.
     * @param _wormholeTokenBridgeToken  a wormhole bridge where fromw need to redeem token
     * @param _encodedVAA  VAA for redeeming to get from wormhole guardians
     * @param _1inchData a 1inch data to call aggregate router to swap assets.
     * @param _IsUnWrapped to decide if redeem is wrapped asset and user want to be unwrapped so that we should save fee.
     */
    function unlockTokensWithPayload(address _wormholeTokenBridgeToken, bytes memory _encodedVAA,  bytes calldata _1inchData, bool _IsUnWrapped) external payable returns (uint256) {
        // initiate wormhole bridge contract  
        require(_wormholeTokenBridgeToken != address(0), "Atlas Dex: Wormhole Token Bride Address can't be null");      
        ITokenBridgeWormhole wormholeTokenBridgeContract =  ITokenBridgeWormhole(_wormholeTokenBridgeToken);


        // initiate wormhole contract        
        IWormhole wormholeContract = IWormhole(wormholeTokenBridgeContract.wormhole());

        (WormholeStructs.VM memory vm, ,) = wormholeContract.parseAndVerifyVM(_encodedVAA);

        WormholeStructs.TransferWithPayload memory transfer = wormholeTokenBridgeContract.parseTransferWithPayload(vm.payload);

                
        // verify that correct VAA is passed for relayer.
        require(transfer.payloadID == 3, "Atlas Dex: Invalid Payload ID for Unlock");
        
        // as its payload 3 so must be redeemed by the address (this)
        require(address(uint160(uint256(transfer.to))) == address(this), "Atlas Dex: Invalid Recipient Address");
        
        IERC20 transferToken;
        {/// bypass stack too deep
            if (transfer.tokenChain == wormholeTokenBridgeContract.chainId()) {
                transferToken = IERC20(address(uint160(uint256(transfer.tokenAddress))));
            } else {
                address wrapped = wormholeTokenBridgeContract.wrappedAsset(transfer.tokenChain, transfer.tokenAddress);
                require(wrapped != address(0), "AtlasDex: no wrapper for this token created yet");

                transferToken = IERC20(wrapped);
            }
        }

        uint256 amountRedeemed;
        {/// bypass stack too deep
            (, bytes memory queriedBalanceBefore) = address(transferToken).staticcall(
                abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
            );
            uint256 balanceBefore = abi.decode(queriedBalanceBefore, (uint256));

            // call wormhole bridge  to redeem token to this contract.
            wormholeTokenBridgeContract.completeTransfer(_encodedVAA);


            /// query own token balance after transfer
            (, bytes memory queriedBalanceAfter) = address(transferToken).staticcall(
                abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
            );
            uint256 balanceAfter = abi.decode(queriedBalanceAfter, (uint256));
    
            // instead of trusting on payload amount. we will trust on balance after transfer.
            amountRedeemed = balanceAfter.sub(balanceBefore);
        }
        address userRecipient;
        address destiationToken;
        uint256 fee;
        {/// bypass stack too deep
            SwapStructs.CrossChainRelayerPayload memory relayerPayload = parseUnlockWithPayload(transfer.payload);
            userRecipient = address(uint160(uint256(relayerPayload.receiver)));
            require(userRecipient != address(0), "Atlas Dex: Invalid Payload");
            fee = relayerPayload.fee;
            destiationToken = address(uint160(uint256(relayerPayload.token)));
            // query tokens decimals to normalize amount. as transfer.amount is already normalized.
            (,bytes memory queriedDecimals) = address(transferToken).staticcall(abi.encodeWithSignature("decimals()"));
            uint8 decimals = abi.decode(queriedDecimals, (uint8));

            uint256 amountRedeemedNormalized = normalizeAmount(amountRedeemed, decimals);
            // amount transfer to our contract should be same as in payload. as we are checking with normalized because wormhole support transfer up to 8 decimals
            require(amountRedeemed.sub(fee) > 0 && transfer.amount == amountRedeemedNormalized, "Atlas Dex: Invalid Balance After complete Transfer");
        }

        // this is track exact output amount of token to be sent to user.
        uint256 amountTransfer;
        // First tranfer fee of wormhole unlocked to collector. 
        transferToken.safeTransfer(FEE_COLLECTOR, fee);

        if(_1inchData.length > 1) {
            {/// bypass stack too deep
                (, SwapStructs._1inchSwapDescription memory swapDescriptionObj,) = abi.decode(_1inchData[4:], (address, SwapStructs._1inchSwapDescription, bytes));
                require(swapDescriptionObj.srcToken == transferToken, "Atlas DEX: Token Not Matched");
                require(address(swapDescriptionObj.dstToken) == destiationToken, "Atlas DEX: Destination Token Not Matched");

                require(swapDescriptionObj.amount == amountRedeemed.sub(fee), "Atlas DEX: 1inch Swap Token  Amount Not Matched");
                require(userRecipient == swapDescriptionObj.dstReceiver, "Atlas Dex: Invalid Balance Reciever");
                amountTransfer = _swapToken1Inch(_1inchData, false);
            }
        }
        else if (_IsUnWrapped) {
            require(NATIVE_WRAPPED_ADDRESS == address(transferToken), "Atlas DEX: Token Not Matched");
            amountTransfer = withdrawToUnWrappedToken(amountRedeemed.sub(fee), false);
        } else {
            // here means user want to get wormhole unlocked token.
            transferToken.safeTransfer(userRecipient, amountRedeemed.sub(fee));
        }
        return amountTransfer;

    } // end of unlock Token with payload

    /**
     * @dev Initiate a 1inch/_0x router to swap tokens and then wormhole bridge call to lock asset.
     * @param lockedTokenData  a wormhole bridge where need to lock token
     */
    function lockedTokens( SwapStructs.LockedToken calldata lockedTokenData) external payable returns (uint64) {
        // initiate wormhole bridge contract        
        require(lockedTokenData._wormholeBridgeToken != address(0), "Atlas Dex: Wormhole Token Bride Address can't be null");      

        ITokenBridgeWormhole wormholeTokenBridgeContract =  ITokenBridgeWormhole(lockedTokenData._wormholeBridgeToken);
        IERC20 wormholeWrappedToken = IERC20(lockedTokenData._token);
        uint256 amountToLock = lockedTokenData._amount; 
        if(lockedTokenData._1inchData.length > 1) { // it means user need to first convert token to wormhole token.
            (, SwapStructs._1inchSwapDescription memory swapDescriptionObj,) = abi.decode(lockedTokenData._1inchData[4:], (address,SwapStructs._1inchSwapDescription, bytes));
            require(swapDescriptionObj.dstToken == wormholeWrappedToken, "Atlas DEX: Dest Token Not Matched");        
            amountToLock = _swapToken1Inch(lockedTokenData._1inchData, true);
        } // end of if for 1 inch data. 
        else if(lockedTokenData._0xData.length > 1) { // it means user need to first convert token to wormhole token.
            ( SwapStructs._0xSwapDescription memory swapDescriptionObj) = abi.decode(lockedTokenData._0xData[4:], (SwapStructs._0xSwapDescription));
            if (swapDescriptionObj.inputToken == 0x0000000000000000000000000000000000000080) { // this is because as sometime 0x send data like sellToPancakeSwap or sellToUniswapSwap
                ( address[] memory tokens, uint256 sellAmount,, ) = abi.decode(lockedTokenData._0xData[4:], (address[], uint256, uint256, uint8));
                swapDescriptionObj.inputToken = tokens[0];
                swapDescriptionObj.outputToken = tokens[tokens.length - 1];
                swapDescriptionObj.inputTokenAmount = sellAmount;
            }
            require(swapDescriptionObj.outputToken == address(wormholeWrappedToken), "Atlas DEX: Dest Token Not Matched");        
            amountToLock = _swapToken0x(lockedTokenData._0xData);
        } // end of if for 1 inch data. 
        else if (lockedTokenData._IsWrapped) {
            amountToLock =  depositToWrappedToken();
        } else if ( lockedTokenData._IsUnWrapped) {
            amountToLock = withdrawToUnWrappedToken(lockedTokenData._amountToUnwrap, true);
        }


        require(wormholeWrappedToken.balanceOf(msg.sender) >= amountToLock, "Atlas DEX: You have low balance to lock.");

        wormholeWrappedToken.safeTransferFrom(msg.sender, address(this), amountToLock);

        // query tokens decimals
        (,bytes memory queriedDecimals) = address(wormholeWrappedToken).staticcall(abi.encodeWithSignature("decimals()"));
        uint8 decimals = abi.decode(queriedDecimals, (uint8));

        uint256 amountForWormhole = deNormalizeAmount(normalizeAmount(amountToLock, decimals), decimals);

        if (wormholeWrappedToken.allowance(address(this), lockedTokenData._wormholeBridgeToken) < amountToLock) {
            wormholeWrappedToken.safeApprove(lockedTokenData._wormholeBridgeToken, MAX_INT);
        }
        emit AmountLocked(msg.sender, amountForWormhole);
        uint64 sequence = 0;
        if (lockedTokenData._payload.length > 1) {
            sequence = wormholeTokenBridgeContract.transferTokensWithPayload(lockedTokenData._token, amountForWormhole, lockedTokenData._recipientChain, lockedTokenData._recipient, lockedTokenData._nonce, lockedTokenData._payload);
        } else{
            sequence = wormholeTokenBridgeContract.transferTokens(lockedTokenData._token, amountForWormhole, lockedTokenData._recipientChain, lockedTokenData._recipient, 0, lockedTokenData._nonce);

        }
        return sequence;

    } // end of redeem Token

    receive() external payable {}
} // end of class

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SwapState.sol";
import "./SwapStructs.sol";
import "../libraries/external/BytesLib.sol";

/**
 * @title AtlasDexSwap
 */
contract SwapGetters is SwapState {
    using BytesLib for bytes;

    function normalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256){
        if (decimals > 8) {
            amount /= 10 ** (decimals - 8);
        }
        return amount;
    }

    function deNormalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256){
        if (decimals > 8) {
            amount *= 10 ** (decimals - 8);
        }
        return amount;
    }

    /*
     * @dev Parse a token transfer with payload (payload id 3).
     *
     * @params encoded The byte array corresponding to the token transfer (not
     *                 the whole VAA, only the payload)
     */
    function parseUnlockWithPayload(bytes memory encoded) public pure returns (SwapStructs.CrossChainRelayerPayload memory relayerPayload) {
        uint index = 0;

        relayerPayload.receiver = encoded.toBytes32(index);
        index += 32;

        relayerPayload.token = encoded.toBytes32(index);
        index += 32;

        relayerPayload._id = encoded.toBytes32(index);
        index += 32;

        relayerPayload.slippage = encoded.toUint256(index);
        index += 32;

        relayerPayload.fee = encoded.toUint256(index);
        index += 32;
    }

    function isInitialized(address impl) public view returns (bool) {
        return initializedImplementations[impl];
    }
} // end of class

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./SwapSetters.sol";
import "./SwapGetters.sol";

contract SwapGovernance is SwapSetters, SwapGetters, ERC1967Upgrade  {
    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    /// @dev upgrade serves to upgrade contract implementations
    function upgrade(address newImplementation) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");

        address currentImplementation = _getImplementation();

        _upgradeTo(newImplementation);

        /// @dev call initialize function of the new implementation
        (bool success, bytes memory reason) = newImplementation.delegatecall(abi.encodeWithSignature("initialize()"));

        require(success, string(reason));

        emit ContractUpgraded(currentImplementation, newImplementation);
    }

    function updateFeePercent(uint256 _feePercent) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(_feePercent <= 3000, "Atlas Dex:  Fee can't be more than 0.3% on one side.");
        FEE_PERCENT = _feePercent;
    }

    function updateFeeCollector(address _feeCollector) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(_feeCollector != address(0), "Atlas Dex: Fee Collector Invalid");         
        FEE_COLLECTOR = _feeCollector;
    }
}

// contracts/Implementation.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import "./Swap.sol";


contract SwapImplementation is Swap {
    function initialize() initializer public virtual {
        /// @dev this function needs to be exposed for an upgrade to pass
    }

    modifier initializer() {
        address impl = ERC1967Upgrade._getImplementation();

        require(
            !isInitialized(impl),
            "already initialized"
        );

        setInitialized(impl);

        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./SwapState.sol";
import "./SwapStructs.sol";

/**
 * @title SwapSetters
 */
contract SwapSetters is SwapState, AccessControl {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    using SafeMath for uint256;
    
    function withdrawIfAnyEthBalance(address payable receiver) external returns (uint256) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        uint256 balance = address(this).balance;
        receiver.transfer(balance);
        return balance;
    }
    
    function withdrawIfAnyTokenBalance(address contractAddress, address receiver) external returns (uint256) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        IERC20 token = IERC20(contractAddress);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(receiver, balance);
        return balance;
    }


    function setFeeCollector(address _feeCollector) internal {
        require(_feeCollector != address(0), "Atlas Dex: Fee Collector Invalid");         
        FEE_COLLECTOR = _feeCollector;
    }

    function setNativeWrappedAddress(address _nativeWrapped) internal {
        require(_nativeWrapped != address(0), "Atlas Dex: _nativeWrapped Invalid");         
        NATIVE_WRAPPED_ADDRESS = _nativeWrapped;
    }

    function set1InchRouter(address _1inchRouter) internal {
        require(_1inchRouter != address(0), "Atlas Dex: _1inchRouter Invalid");         
        oneInchAggregatorRouter = _1inchRouter;
    }

    function set0xRouter(address _0xRouter) internal {
        require(_0xRouter != address(0), "Atlas Dex: _0xRouter Invalid");         
        OxAggregatorRouter = _0xRouter;
    }

    function setInitialized(address implementation) internal {
        initializedImplementations[implementation] = true;
    }
} // end of class

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title AtlasDexSwap
 */
contract SwapState {

    address tokenImplementation;

    // we do save 1 inch router in constructor to swap token.
    address public oneInchAggregatorRouter;

    // we do save 0x router in constructor to swap token.
    address public OxAggregatorRouter;

    address public NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    // This Wrapped means each chain wrapped address like WETH, WBNB etc.
    address public NATIVE_WRAPPED_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // bsc address
    uint256 public MAX_INT = 2**256 - 1;
    
    uint256 public FEE_PERCENT = 15; // we will use 15 this 15 is for 0.15.
    
    uint256 public FEE_PERCENT_DENOMINATOR = 10000; // 
    
    address public FEE_COLLECTOR;
   
   // Proxy Implementation.
    mapping(address => bool) initializedImplementations;

} // end of class

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WormholeStructs {
    struct TransferWithPayload {
        // PayloadID uint8 = 3
        uint8 payloadID;
        // Amount being transferred (big-endian uint256)
        uint256 amount;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes
        bytes32 to;
        // Chain ID of the recipient
        uint16 toChain;
        // Address of the message sender. Left-zero-padded if shorter than 32 bytes
        bytes32 fromAddress;
        // An arbitrary payload
        bytes payload;
    }
    struct Transfer {
        // PayloadID uint8 = 1
        uint8 payloadID;
        // Amount being transferred (big-endian uint256)
        uint256 amount;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes
        bytes32 to;
        // Chain ID of the recipient
        uint16 toChain;
        // Amount of tokens (big-endian uint256) that the user is willing to pay as relayer fee. Must be <= Amount.
        uint256 fee;
    }

	struct Signature {
		bytes32 r;
		bytes32 s;
		uint8 v;
		uint8 guardianIndex;
	}

	struct VM {
		uint8 version;
		uint32 timestamp;
		uint32 nonce;
		uint16 emitterChainId;
		bytes32 emitterAddress;
		uint64 sequence;
		uint8 consistencyLevel;
		bytes payload;

		uint32 guardianSetIndex;
		Signature[] signatures;

		bytes32 hash;
	}
    struct AssetMeta {
        // PayloadID uint8 = 2
        uint8 payloadID;
        // Address of the token. Left-zero-padded if shorter than 32 bytes
        bytes32 tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Number of decimals of the token (big-endian uint256)
        uint8 decimals;
        // Symbol of the token (UTF-8)
        bytes32 symbol;
        // Name of the token (UTF-8)
        bytes32 name;
    }
}

/**
 * @title IWormhole
 * @dev Wormhole functions to call them for decoding/encoding VAA
 */
abstract contract IWormhole {
function parseAndVerifyVM(bytes calldata encodedVM) public virtual view returns (WormholeStructs.VM memory vm, bool valid, string memory reason);
}
/**
 * @title ITokenBridgeWormhole
 * @dev Wormhole Token bridge functions to call them for swapping
 */
abstract contract ITokenBridgeWormhole {
    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) public view virtual returns (address);
    function tokenImplementation() public view virtual returns (address);
    function chainId() public view virtual returns  (uint16);
    function wormhole() public view virtual returns  (address);
    function isTransferCompleted(bytes32 hash) public virtual view returns (bool);
    function completeTransfer(bytes memory encodedVm) public virtual;
    function parseTransfer(bytes memory encoded) public virtual pure returns (WormholeStructs.Transfer memory transfer);
    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) public virtual payable returns (uint64 sequence) ;
    function transferTokensWithPayload(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint32 nonce,
        bytes memory payload
    ) public virtual payable returns (uint64 sequence);
    function parseTransferWithPayload(bytes memory encoded) public virtual pure returns (WormholeStructs.TransferWithPayload memory transfer);
    function _parseTransferCommon(bytes memory encoded) public virtual pure returns (WormholeStructs.Transfer memory transfer);
}

// A partial WETH interfaec.
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

/**
 * @title AtlasDexSwap
 */
contract SwapStructs {

    struct _1inchSwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    struct _0xSwapDescription {
        address inputToken;
        address outputToken;
        uint256 inputTokenAmount;
    }

    struct LockedToken {
        address _wormholeBridgeToken;
        address _token;
        uint256 _amount;
        uint16 _recipientChain;
        bytes32 _recipient;
        uint32 _nonce;
        bytes _1inchData;
        bytes _0xData;
        bool _IsWrapped;
        bool _IsUnWrapped;
        uint256 _amountToUnwrap;
        bytes _payload;
    }

    struct CrossChainRelayerPayload {
        bytes32 receiver;
        bytes32 token;
        
        bytes32 _id;

        uint256 slippage;

        uint256 fee;
    }
} // end of class