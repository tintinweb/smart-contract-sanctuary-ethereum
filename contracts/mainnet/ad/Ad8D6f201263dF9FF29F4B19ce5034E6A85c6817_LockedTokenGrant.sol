// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "IAccessControl.sol";
import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

// The locked tokens from the grant are released gradually over 4 years.
uint256 constant GRANT_LOCKUP_PERIOD = 1461 days; // 4 years.
uint256 constant DEFAULT_DURATION_GLOBAL_TIMELOCK = 365 days; // 1 years.
uint256 constant MAX_DURATION_GLOBAL_TIMELOCK = 731 days; // 2 years.
uint256 constant MIN_UNLOCK_DELAY = 7 days; // 1 week.
bytes32 constant LOCKED_GRANT_ADMIN_ROLE = keccak256("LOCKED_GRANT_ADMIN_ROLE");
bytes32 constant GLOBAL_TIMELOCK_ADMIN_ROLE = keccak256("GLOBAL_TIMELOCK_ADMIN_ROLE");

// This hash value is used as an ID for `DelegateRegistry`
// If the recipient delegates this ID to an agent address,
// that agent can trigger token release.
bytes32 constant LOCKED_TOKEN_RELEASE_AGENT = keccak256("STARKNET_LOCKED_TOKEN_RELEASE_AGENT");

// This hash value is used as an ID for `DelegateRegistry`
// If the recipient delegates this ID to an agent address,
// that agent can submit delegation related transactions.
bytes32 constant LOCKED_TOKEN_DELEGATION_AGENT = keccak256(
    "STARKNET_LOCKED_TOKEN_DELEGATION_AGENT"
);

// The start time of a LockedGrant (T), at the time of granting (t) must be in the time window
// (t - LOCKED_GRANT_MAX_START_PAST_OFFSET, t + LOCKED_GRANT_MAX_START_FUTURE_OFFSET)
// i.e. t - LOCKED_GRANT_MAX_START_PAST_OFFSET < T < t + LOCKED_GRANT_MAX_START_FUTURE_OFFSET.
uint256 constant LOCKED_GRANT_MAX_START_PAST_OFFSET = 182 days; // 6 months.
uint256 constant LOCKED_GRANT_MAX_START_FUTURE_OFFSET = 31 days; // 1 month.

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

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "CommonConstants.sol";
import "IVotes.sol";

/**
  A subset of the Gnosis DelegateRegistry ABI.
*/
interface IDelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;

    function delegation(address delegator, bytes32 id) external view returns (address);

    function clearDelegate(bytes32 id) external;
}

/**
  This contract implements the delegations made on behalf of the token grant contract.
  Two types of delegation are supported:
  1. Delegation using Gnosis DelegateRegistry.
  2. IVotes (Compound like) delegation, done directly on the ERC20 token.

  Upon construction, the {LockedTokenGrant} is provided with an address of the
  Gnosis DelegateRegistry. In addition, if a different DelegateRegistry is used,
  it can be passed in explicitly as an argument.

  Compound like vote delegation can be done on the StarkNet token, and on the Staking contract,
  assuming it will support that.
*/
abstract contract DelegationSupport {
    address public immutable recipient;

    // A Gnosis DelegateRegistry contract, provided by the common contract.
    // Used for delegation of votes, and also to permit token release and delegation actions.
    IDelegateRegistry public immutable defaultRegistry;

    // StarkNet Token.
    address public immutable token;

    // StarkNet Token Staking contract.
    address public immutable stakingContract;

    modifier onlyRecipient() {
        require(msg.sender == recipient, "ONLY_RECIPIENT");
        _;
    }

    modifier onlyAllowedAgent(bytes32 agentId) {
        require(
            msg.sender == recipient || msg.sender == defaultRegistry.delegation(recipient, agentId),
            "ONLY_RECIPIENT_OR_APPROVED_AGENT"
        );
        _;
    }

    constructor(
        address defaultRegistry_,
        address recipient_,
        address token_,
        address stakingContract_
    ) {
        defaultRegistry = IDelegateRegistry(defaultRegistry_);
        recipient = recipient_;
        token = token_;
        stakingContract = stakingContract_;
    }

    /*
      Clears the {LockedTokenGrant} Gnosis delegation on the provided DelegateRegistry,
      for the ID provided.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function clearDelegate(bytes32 id, IDelegateRegistry registry)
        public
        onlyAllowedAgent(LOCKED_TOKEN_DELEGATION_AGENT)
    {
        registry.clearDelegate(id);
    }

    /*
      Sets the {LockedTokenGrant} Gnosis delegation on the provided DelegateRegistry,
      for the ID provided.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function setDelegate(
        bytes32 id,
        address delegate,
        IDelegateRegistry registry
    ) public onlyAllowedAgent(LOCKED_TOKEN_DELEGATION_AGENT) {
        registry.setDelegate(id, delegate);
    }

    /*
      Clears the {LockedTokenGrant} Gnosis delegation on the default DelegateRegistry,
      for the ID provided.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function clearDelegate(bytes32 id) external {
        clearDelegate(id, defaultRegistry);
    }

    /*
      Sets the {LockedTokenGrant} Gnosis delegation on the default DelegateRegistry,
      for the ID provided.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function setDelegate(bytes32 id, address delegate) external {
        setDelegate(id, delegate, defaultRegistry);
    }

    /*
      Sets the {LockedTokenGrant} IVotes delegation on the token.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function setDelegateOnToken(address delegatee)
        external
        onlyAllowedAgent(LOCKED_TOKEN_DELEGATION_AGENT)
    {
        _setIVotesDelegation(token, delegatee);
    }

    /*
      Sets the {LockedTokenGrant} IVotes delegation on the staking contract.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function setDelegateOnStaking(address delegatee)
        external
        onlyAllowedAgent(LOCKED_TOKEN_DELEGATION_AGENT)
    {
        _setIVotesDelegation(stakingContract, delegatee);
    }

    function _setIVotesDelegation(address target, address delegatee) private {
        IVotes(target).delegate(delegatee);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "CommonConstants.sol";
import "AccessControl.sol";

/**
  This contract handles the StarkNet Token global timelock.
  The Global Timelock is applied on all the locked token grants.
  Before the global timelock expires, all the locked token grants, are 100% locked,
  regardless of grant size and elapsed time since grant start time.
  Once the timelock expires, the amount of locked tokens in the grant is determined by the size
  of the grant and its start time.

  The global time-lock can be changed by an admin. To perform that,
  the admin must hold the GLOBAL_TIMELOCK_ADMIN_ROLE rights on the `LockedTokenCommon` contract.
  The global time-lock can be reset to a new timestamp as long as the following conditions are met:
  i. The new timestamp is in the future with at least a minimal margin.
  ii. The new timestamp does not exceed the global time-lock upper bound.
  iii. The global time-lock has not expired yet.

  The deployed LockedTokenGrant contracts query this contract to read the global timelock.
*/
abstract contract GlobalUnlock is AccessControl {
    uint256 internal immutable UPPER_LIMIT_GLOBAL_TIME_LOCK;
    uint256 public globalUnlockTime;

    event GlobalUnlockTimeUpdate(
        uint256 oldUnlockTime,
        uint256 newUnlockTime,
        address indexed sender
    );

    constructor() {
        UPPER_LIMIT_GLOBAL_TIME_LOCK = block.timestamp + MAX_DURATION_GLOBAL_TIMELOCK;
        _updateGlobalLock(block.timestamp + DEFAULT_DURATION_GLOBAL_TIMELOCK);
    }

    function updateGlobalLock(uint256 unlockTime) external onlyRole(GLOBAL_TIMELOCK_ADMIN_ROLE) {
        require(unlockTime > block.timestamp + MIN_UNLOCK_DELAY, "SELECTED_TIME_TOO_EARLY");
        require(unlockTime < UPPER_LIMIT_GLOBAL_TIME_LOCK, "SELECTED_TIME_EXCEED_LIMIT");

        require(block.timestamp < globalUnlockTime, "GLOBAL_LOCK_ALREADY_EXPIRED");
        _updateGlobalLock(unlockTime);
    }

    /*
      Setter for the globalUnlockTime.
      See caller function code for update logic, validation and restrictions.
    */
    function _updateGlobalLock(uint256 newUnlockTime) internal {
        emit GlobalUnlockTimeUpdate(globalUnlockTime, newUnlockTime, msg.sender);
        globalUnlockTime = newUnlockTime;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "GlobalUnlock.sol";
import "LockedTokenGrant.sol";
import "Address.sol";

/**
  The {LockedTokenCommon} contract serves two purposes:
  1. Maintain the StarkNetToken global timelock (see {GlobalUnlock})
  2. Allocate locked token grants in {LockedTokenGrant} contracts.

  Roles:
  =====
  1. At initializtion time, the msg.sender of the initialize tx, is defined as DEFAULT_ADMIN_ROLE.
  2. LOCKED_GRANT_ADMIN_ROLE is required to call `grantLockedTokens`.
  3. GLOBAL_TIMELOCK_ADMIN_ROLE is reqiured to call the `updateGlobalLock`.
  Two special roles must be granted

  Grant Locked Tokens:
  ===================
  Locked token grants are granted using the `grantLockedTokens` here.
  The arguments passed are:
  - recipient - The address of the tokens "owner". When the tokens get unlocked, they can be released
                to the recipient address, and only there.
  - amount    - The number of tokens to be transfered onto the grant contract upon creation.
  - startTime - The timestamp of the beginning of the 4 years unlock period over which the tokens
                gradually unlock. The startTime can be anytime within the margins specified in the {CommonConstants}.
  - allocationPool - The {LockedTokenCommon} doesn't hold liquidity from which it can grant the tokens,
                     but rather uses an external LP for that. The `allocationPool` is the address of the LP
                     from which the tokens shall be allocated. The {LockedTokenCommon} must have sufficient allowance
                     on the `allocationPool` so it can transfer funds from it onto the creatred grant contract.

    Flow: The {LockedTokenCommon} deploys the contract of the new {LockedTokenGrant},
          transfer the grant amount from the allocationPool onto the new grant,
          and register the new grant in a mapping.
*/
contract LockedTokenCommon is GlobalUnlock {
    // Maps recipient to its locked grant contract.
    mapping(address => address) public grantByRecipient;
    IERC20 internal immutable tokenContract;
    address internal immutable stakingContract;
    address internal immutable defaultRegistry;

    event LockedTokenGranted(
        address indexed recipient,
        address indexed grantContract,
        uint256 grantAmount,
        uint256 startTime
    );

    constructor(
        address tokenAddress_,
        address stakingContract_,
        address defaultRegistry_
    ) {
        require(Address.isContract(tokenAddress_), "NOT_A_CONTRACT");
        require(Address.isContract(stakingContract_), "NOT_A_CONTRACT");
        require(Address.isContract(defaultRegistry_), "NOT_A_CONTRACT");
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        tokenContract = IERC20(tokenAddress_);
        stakingContract = stakingContract_;
        defaultRegistry = defaultRegistry_;
    }

    /**
      Deploys a LockedTokenGrant and transfers `grantAmount` tokens onto it.
      Returns the address of the LockedTokenGrant contract.

      Tokens owned by the {LockedTokenGrant} are initially locked, and can only be used for staking.
      The tokens gradually unlocked and can be transferred to the `recipient`.
    */
    function grantLockedTokens(
        address recipient,
        uint256 grantAmount,
        uint256 startTime,
        address allocationPool
    ) external onlyRole(LOCKED_GRANT_ADMIN_ROLE) returns (address) {
        require(grantByRecipient[recipient] == address(0x0), "ALREADY_GRANTED");
        require(
            startTime < block.timestamp + LOCKED_GRANT_MAX_START_FUTURE_OFFSET,
            "START_TIME_TOO_LATE"
        );
        require(
            startTime > block.timestamp - LOCKED_GRANT_MAX_START_PAST_OFFSET,
            "START_TIME_TOO_EARLY"
        );

        address grantAddress = address(
            new LockedTokenGrant(
                address(tokenContract),
                stakingContract,
                defaultRegistry,
                recipient,
                grantAmount,
                startTime
            )
        );
        require(
            tokenContract.transferFrom(allocationPool, grantAddress, grantAmount),
            "TRANSFER_FROM_FAILED"
        );
        grantByRecipient[recipient] = grantAddress;
        emit LockedTokenGranted(recipient, grantAddress, grantAmount, startTime);
        return grantAddress;
    }
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "TimeLockedTokens.sol";
import "CommonConstants.sol";
import "DelegationSupport.sol";
import "IERC20.sol";
import "Math.sol";

/**
  This Contract holds a grant of locked tokens and gradually releases the tokens to its recipient.

  This contract should be deployed through the {LockedTokenCommon} contract,
  The global lock expiration time may be adjusted through the {LockedTokenCommon} contract.

  The {LockedTokenGrant} is initialized  with the following parameters:
  `address token_`: The address of StarkNet token ERC20 contract.
  `address stakingContract_`: The address of the contrtact used for staking StarkNet token.
  `address defaultRegistry_`: Address of Gnosis DelegateRegistry.
  `address recipient_`: The owner of the grant.
  `uint256 grantAmount_`: The amount of tokens granted in this grant.
  `uint256 startTime`: The grant time-lock start timestamp.

  Token Gradual Release behavior:
  ==============================
  - Until the global timelock expires all the tokens are locked.
  - After the expiration of the global timelock tokens are gradually unlocked.
  - The amount of token unlocked is proportional to the time passed from startTime.
  - The grant is fully unlocked in 4 years.
  - to sum it up:
  ```
    // 0 <= elapsedTime <= 4_YEARS
    elapsedTime = min(4_YEARS, max(0, currentTime - startTime))
    unlocked = globalTimelockExpired ? grantAmount * (elapsedTime / 4_YEARS): 0;
  ```
  - If the total balance of the grant address is larger than `grantAmount` - then the extra
    tokens on top of the grantAmount is available for release ONLY after the grant is fully
    unlocked.

  Global Time Lock:
  ================
  StarkNet token has a global timelock. Before that timelock expires, all the tokens in the grant
  are fully locked. The global timelock can be modified post-deployment (to some extent).
  Therefore, the lock is maintained on a different contract that is centralized, and serves
  as a "timelock oracle" for all the {LockedTokenGrant} instances. I.e. whenever an instance of this
  contract needs to calculate the available tokens, it checks on the {LockedTokenCommon} contract
  if the global lock expired. See {LockedTokenCommon} for addtional details on the global timelock.

  Token Release Operation:
  ======================
  - Tokens are owned by the `recipient`. They cannot be revoked.
  - At any given time the recipient can release any amount of tokens
    as long as the specified amount is available for release.
  - The amount of tokens available for release is the following:
  ```
  availableAmount = min(token.balanceOf(this), (unlocked - alreadyReleased));
  ```
    The `min` is used here, because a part of the grant balance might be staked.
  - Only the recipient or an appointed {LOCKED_TOKEN_RELEASE_AGENT} are allowed to trigger
    release of tokens.
  - The released tokens can be transferred ONLY to the recipient address.

  Appointing agents for actions:
  ========================
  Certain activities on this contract can be done not only by the grant recipient, but also by a delegate,
  appointed by the recipient.
  The delegation is done on a Gnosis DelegateRegistry contract, that was given to this contract
  in construction. The address of the {DelegateRegistry} is stored in the public variable named
  `defaultRegistry`.
  1. The function `releaseTokens` can be called by the account (we use the term agent for this) whose address
     was delegated for this ID:
     0x07238b05622b6f7e824800927d4f7786fca234153c28aeae2fa6fad5361ef6e7 [= keccak(text="LOCKED_TOKEN_RELEASE_AGENT")]
  2. The functions `setDelegate` `clearDelegate` `setDelegationOnToken` `setDelegationOnStaking` can be called
     by the agent whose address was delegated for this ID:
     0x477b64bf0d3f527eb7f7efeb334cf2ba231a93256d546759ad12a5add2734fb1 [= keccak(text="LOCKED_TOKEN_DELEGATION_AGENT")]

  Staking:
  =======
  Staking of StarkNet tokens are exempted from the lock. I.e. Tokens from the locked grant
  can be staked, even up to the full grant amount, at any given time.
  However, the exect interface of the staking contract is not finalized yet.
  Therefore, the {LockedTokenGrant} way support staking is by a dedicated approval function `approveForStaking`.
  This function can be called only the recipient, and sets the allowace to the specified amount on the staking contract.
  This function is limited such that it approves only the staking contract, and no other address.
  The staking contract will support staking from a {LockedTokenGrant} using a dedicated API.

  Voting Delegation:
  =================
  The {LockedTokenGrant} suports both Compound like delegation and delegation using Gnosis DelegateRegistry.
  These functions set the delegation of the Grant address (the address of the grant contract).
  Only the recipient and a LOCKED_TOKEN_DELEGATION_AGENT (if appointed) can call these functions.
*/
contract LockedTokenGrant is TimeLockedTokens, DelegationSupport {
    uint256 public releasedTokens;

    event TokensSentToRecipient(
        address indexed recipient,
        address indexed grantContract,
        uint256 amountSent,
        uint256 aggregateSent
    );

    event TokenAllowanceForStaking(
        address indexed grantContract,
        address indexed stakingContract,
        uint256 allowanceSet
    );

    constructor(
        address token_,
        address stakingContract_,
        address defaultRegistry_,
        address recipient_,
        uint256 grantAmount_,
        uint256 startTime_
    )
        DelegationSupport(defaultRegistry_, recipient_, address(token_), stakingContract_)
        TimeLockedTokens(grantAmount_, startTime_)
    {}

    /*
      Returns the available tokens for release.
      Once the grant lock is fully expired - the entire balance is always available.
      Until then, only the relative part of the grant grantAmount is available.
      However, given staking, the actual balance may be smaller.
      Note that any excessive tokens (beyond grantAmount) transferred to this contract
      are going to be locked until the grant lock fully expires.
    */
    function availableTokens() public view returns (uint256) {
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        return
            isGrantFullyUnlocked()
                ? currentBalance
                : Math.min(currentBalance, (unlockedTokens() - releasedTokens));
    }

    /*
      Transfers `requestedAmount` tokens (if available) to the `recipient`.
    */
    function releaseTokens(uint256 requestedAmount)
        external
        onlyAllowedAgent(LOCKED_TOKEN_RELEASE_AGENT)
    {
        require(requestedAmount <= availableTokens(), "REQUESTED_AMOUNT_UNAVAILABLE");
        releasedTokens += requestedAmount;
        IERC20(token).transfer(recipient, requestedAmount);
        emit TokensSentToRecipient(recipient, address(this), requestedAmount, releasedTokens);
    }

    /*
      Sets the allowance of the staking contract address to `approvedAmount`.
      to allow staking up to that amount of tokens.
    */
    function approveForStaking(uint256 approvedAmount) external onlyRecipient {
        IERC20(token).approve(stakingContract, approvedAmount);
        emit TokenAllowanceForStaking(address(this), stakingContract, approvedAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "CommonConstants.sol";
import "LockedTokenCommon.sol";
import "Math.sol";

/**
  This contract provides the number of unlocked tokens,
  and indicates if the grant has fully unlocked.
*/
abstract contract TimeLockedTokens {
    // The lockedCommon is the central contract that provisions the locked grants.
    // It also used to maintain the token global timelock.
    LockedTokenCommon immutable lockedCommon;

    // The grant start time. This is the start time of the grant 4 years gradual unlock.
    // Grant can be deployed with startTime in the past or in the future.
    // The range of allowed past/future spread is defined in {CommonConstants}.
    // and validated in the constructor.
    uint256 public immutable startTime;

    // The amount of tokens in the locked grant.
    uint256 public immutable grantAmount;

    constructor(uint256 grantAmount_, uint256 startTime_) {
        lockedCommon = LockedTokenCommon(msg.sender);
        grantAmount = grantAmount_;
        startTime = startTime_;
    }

    /*
      Indicates whether the grant has fully unlocked.
    */
    function isGrantFullyUnlocked() public view returns (bool) {
        return block.timestamp >= startTime + GRANT_LOCKUP_PERIOD;
    }

    /*
      The number of locked tokens that were unlocked so far.
    */
    function unlockedTokens() public view returns (uint256) {
        // Before globalUnlockTime passes, The entire grant is locked.
        if (block.timestamp <= lockedCommon.globalUnlockTime()) return 0;

        uint256 cappedElapsedTime = Math.min(elapsedTime(), GRANT_LOCKUP_PERIOD);
        return (grantAmount * cappedElapsedTime) / GRANT_LOCKUP_PERIOD;
    }

    /*
      Returns the time passed (in seconds) since grant start time.
      Returns 0 if start time is in the future.
    */
    function elapsedTime() public view returns (uint256) {
        return block.timestamp > startTime ? block.timestamp - startTime : 0;
    }
}