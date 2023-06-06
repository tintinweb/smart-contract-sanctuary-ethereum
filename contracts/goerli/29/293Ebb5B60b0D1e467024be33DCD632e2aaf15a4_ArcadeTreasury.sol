// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IArcadeTreasury.sol";

import {
    T_ZeroAddress,
    T_ZeroAmount,
    T_ThresholdsNotAscending,
    T_ArrayLengthMismatch,
    T_CallFailed,
    T_BlockSpendLimit,
    T_InvalidTarget,
    T_InvalidAllowance,
    T_CoolDownPeriod
} from "./errors/Treasury.sol";

/**
 * @title ArcadeTreasury
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract is used to hold funds for the Arcade treasury. Each token held by this
 * contract has three thresholds associated with it: (1) large amount, (2) medium amount,
 * and (3) small amount. The only way to modify these thresholds is via the governance
 * timelock which holds the ADMIN role.
 *
 * For each spend threshold, there is a corresponding spend function which can be called by
 * only the CORE_VOTING_ROLE. In the Core Voting contract, a custom quorum for each
 * spend function shall be set to the appropriate threshold.
 *
 * In order to enable the GSC to execute smaller spends from the Treasury without going
 * through the entire governance process, the GSC has an allowance for each token. The
 * GSC can spend up to the allowance amount for each token. The GSC allowance can be updated
 * by the contract's ADMIN role. When updating the GSC's allowance for a specific token,
 * the allowance cannot be higher than the small threshold set for the token. This is to
 * force spends larger than the small threshold to always be voted on by governance.
 * Additionally, there is a cool down period between each GSC allowance update of 7 days.
 */
contract ArcadeTreasury is IArcadeTreasury, AccessControl, ReentrancyGuard {
    /// @notice access control roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant GSC_CORE_VOTING_ROLE = keccak256("GSC_CORE_VOTING");
    bytes32 public constant CORE_VOTING_ROLE = keccak256("CORE_VOTING");

    /// @notice constant which represents ether
    address internal constant ETH_CONSTANT = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice constant which represents the minimum amount of time between allowance sets
    uint48 public constant SET_ALLOWANCE_COOL_DOWN = 7 days;

    /// @notice the last timestamp when the allowance was set for a token
    mapping(address => uint48) public lastAllowanceSet;

    /// @notice mapping of token address to spend thresholds
    mapping(address => SpendThreshold) public spendThresholds;

    /// @notice mapping of token address to GSC allowance amount
    mapping(address => uint256) public gscAllowance;

    /// @notice mapping storing how much is spent or approved in each block.
    mapping(uint256 => uint256) public blockExpenditure;

    /// @notice event emitted when a token's spend thresholds are updated
    event SpendThresholdsUpdated(address indexed token, SpendThreshold thresholds);

    /// @notice event emitted when a token is spent
    event TreasuryTransfer(address indexed token, address indexed destination, uint256 amount);

    /// @notice event emitted when a token amount is approved for spending
    event TreasuryApproval(address indexed token, address indexed spender, uint256 amount);

    /// @notice event emitted when the GSC allowance is updated for a token
    event GSCAllowanceUpdated(address indexed token, uint256 amount);

    /**
     * @notice contract constructor
     *
     * @param _timelock              address of the timelock contract
     */
    constructor(address _timelock) {
        if (_timelock == address(0)) revert T_ZeroAddress();

        _setupRole(ADMIN_ROLE, _timelock);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(GSC_CORE_VOTING_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CORE_VOTING_ROLE, ADMIN_ROLE);
    }

    // =========== ONLY AUTHORIZED ===========

    // ===== TRANSFERS =====

    /**
     * @notice function for the GSC to spend tokens from the treasury. The amount to be
     *         spent must be less than or equal to the GSC's allowance for that specific token.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       address to send the tokens to
     */
    function gscSpend(
        address token,
        uint256 amount,
        address destination
    ) external onlyRole(GSC_CORE_VOTING_ROLE) nonReentrant {
        if (destination == address(0)) revert T_ZeroAddress();
        if (amount == 0) revert T_ZeroAmount();

        // Will underflow if amount is greater than remaining allowance
        gscAllowance[token] -= amount;

        _spend(token, amount, destination, spendThresholds[token].small);
    }

    /**
     * @notice function to spend a small amount of tokens from the treasury. This function
     *         should have the lowest quorum of the three spend functions.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       address to send the tokens to
     */
    function smallSpend(
        address token,
        uint256 amount,
        address destination
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (destination == address(0)) revert T_ZeroAddress();
        if (amount == 0) revert T_ZeroAmount();

        _spend(token, amount, destination, spendThresholds[token].small);
    }

    /**
     * @notice function to spend a medium amount of tokens from the treasury. This function
     *         should have the middle quorum of the three spend functions.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       address to send the tokens to
     */
    function mediumSpend(
        address token,
        uint256 amount,
        address destination
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (destination == address(0)) revert T_ZeroAddress();
        if (amount == 0) revert T_ZeroAmount();

        _spend(token, amount, destination, spendThresholds[token].medium);
    }

    /**
     * @notice function to spend a large amount of tokens from the treasury. This function
     *         should have the highest quorum of the three spend functions.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       address to send the tokens to
     */
    function largeSpend(
        address token,
        uint256 amount,
        address destination
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (destination == address(0)) revert T_ZeroAddress();
        if (amount == 0) revert T_ZeroAmount();

        _spend(token, amount, destination, spendThresholds[token].large);
    }

    // ===== APPROVALS =====

    /**
     * @notice function for the GSC to approve tokens to be pulled from the treasury. The
     *         amount to be approved must be less than or equal to the GSC's allowance for that specific token.
     *
     * @param token             address of the token to approve
     * @param spender           address which can take the tokens
     * @param amount            amount of tokens to approve
     */
    function gscApprove(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(GSC_CORE_VOTING_ROLE) nonReentrant {
        if (spender == address(0)) revert T_ZeroAddress();
        if (amount == 0) revert T_ZeroAmount();

        // Will underflow if amount is greater than remaining allowance
        gscAllowance[token] -= amount;

        _approve(token, spender, amount, spendThresholds[token].small);
    }

    /**
     * @notice function to approve a small amount of tokens from the treasury. This function
     *         should have the lowest quorum of the three approve functions.
     *
     * @param token             address of the token to approve
     * @param spender           address which can take the tokens
     * @param amount            amount of tokens to approve
     */
    function approveSmallSpend(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (spender == address(0)) revert T_ZeroAddress();
        if (amount == 0) revert T_ZeroAmount();

        _approve(token, spender, amount, spendThresholds[token].small);
    }

    /**
     * @notice function to approve a medium amount of tokens from the treasury. This function
     *         should have the middle quorum of the three approve functions.
     *
     * @param token             address of the token to approve
     * @param spender           address which can take the tokens
     * @param amount            amount of tokens to approve
     */
    function approveMediumSpend(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (spender == address(0)) revert T_ZeroAddress();
        if (amount == 0) revert T_ZeroAmount();

        _approve(token, spender, amount, spendThresholds[token].medium);
    }

    /**
     * @notice function to approve a large amount of tokens from the treasury. This function
     *         should have the highest quorum of the three approve functions.
     *
     * @param token             address of the token to approve
     * @param spender           address which can take the tokens
     * @param amount            amount of tokens to approve
     */
    function approveLargeSpend(
        address token,
        address spender,
        uint256 amount
    ) external onlyRole(CORE_VOTING_ROLE) nonReentrant {
        if (spender == address(0)) revert T_ZeroAddress();
        if (amount == 0) revert T_ZeroAmount();

        _approve(token, spender, amount, spendThresholds[token].large);
    }

    // ============== ONLY ADMIN ==============

    /**
     * @notice function to set the spend/approve thresholds for a token. This function is only
     *         callable by the contract admin.
     *
     * @param token             address of the token to set the thresholds for
     * @param thresholds        struct containing the thresholds to set
     */
    function setThreshold(address token, SpendThreshold memory thresholds) external onlyRole(ADMIN_ROLE) {
        // verify that the token is not the zero address
        if (token == address(0)) revert T_ZeroAddress();
        // verify small threshold is not zero
        if (thresholds.small == 0) revert T_ZeroAmount();

        // verify thresholds are ascending from small to large
        if (thresholds.large < thresholds.medium || thresholds.medium < thresholds.small) {
            revert T_ThresholdsNotAscending();
        }

        // Overwrite the spend limits for specified token
        spendThresholds[token] = thresholds;

        emit SpendThresholdsUpdated(token, thresholds);
    }

    /**
     * @notice function to set the GSC allowance for a token. This function is only callable
     *         by the contract admin. The new allowance must be less than or equal to the small
     *         spend threshold for that specific token. There is a cool down period of 7 days
     *         after this function has been called where it cannot be called again. Once the cooldown
     *         period is over the allowance can be updated by the admin again.
     *
     * @param token             address of the token to set the allowance for
     * @param newAllowance      new allowance amount to set
     */
    function setGSCAllowance(address token, uint256 newAllowance) external onlyRole(ADMIN_ROLE) {
        if (token == address(0)) revert T_ZeroAddress();
        if (newAllowance == 0) revert T_ZeroAmount();

        // enforce cool down period
        if (uint48(block.timestamp) < lastAllowanceSet[token] + SET_ALLOWANCE_COOL_DOWN) {
            revert T_CoolDownPeriod(block.timestamp, lastAllowanceSet[token] + SET_ALLOWANCE_COOL_DOWN);
        }

        uint256 spendLimit = spendThresholds[token].small;

        // new limit cannot be more than the small threshold
        if (newAllowance > spendLimit) {
            revert T_InvalidAllowance(newAllowance, spendLimit);
        }

        // update allowance state
        lastAllowanceSet[token] = uint48(block.timestamp);
        gscAllowance[token] = newAllowance;

        emit GSCAllowanceUpdated(token, newAllowance);
    }

    /**
     * @notice function to execute arbitrary calls from the treasury. This function is only
     *         callable by the contract admin. All calls are executed in order, and if any of them fail
     *         the entire transaction is reverted.
     *
     * @param targets           array of addresses to call
     * @param calldatas         array of bytes data to use for each call
     */
    function batchCalls(
        address[] memory targets,
        bytes[] calldata calldatas
    ) external onlyRole(ADMIN_ROLE) nonReentrant {
        if (targets.length != calldatas.length) revert T_ArrayLengthMismatch();
        // execute a package of low level calls
        for (uint256 i = 0; i < targets.length; ++i) {
            if (spendThresholds[targets[i]].small != 0) revert T_InvalidTarget(targets[i]);
            (bool success, ) = targets[i].call(calldatas[i]);
            // revert if a single call fails
            if (success == false) revert T_CallFailed();
        }
    }

    // =============== HELPERS ===============

    /**
     * @notice helper function to send tokens from the treasury. This function is used by the
     *         transfer functions to send tokens to their destinations.
     *
     * @param token             address of the token to spend
     * @param amount            amount of tokens to spend
     * @param destination       recipient of the transfer
     * @param limit             max tokens that can be spent/approved in a single block for this threshold
     */
    function _spend(address token, uint256 amount, address destination, uint256 limit) internal {
        // check that after processing this we will not have spent more than the block limit
        uint256 spentThisBlock = blockExpenditure[block.number];
        if (amount + spentThisBlock > limit) revert T_BlockSpendLimit();
        blockExpenditure[block.number] = amount + spentThisBlock;

        // transfer tokens
        if (address(token) == ETH_CONSTANT) {
            // will out-of-gas revert if recipient is a contract with logic inside receive()
            payable(destination).transfer(amount);
        } else {
            IERC20(token).transfer(destination, amount);
        }

        emit TreasuryTransfer(token, destination, amount);
    }

    /**
     * @notice helper function to approve tokens from the treasury. This function is used by the
     *         approve functions to approve tokens for a spender.
     *
     * @param token             address of the token to approve
     * @param spender           address to approve
     * @param amount            amount of tokens to approve
     * @param limit             max tokens that can be spent/approved in a single block for this threshold
     */
    function _approve(address token, address spender, uint256 amount, uint256 limit) internal {
        // check that after processing this we will not have spent more than the block limit
        uint256 spentThisBlock = blockExpenditure[block.number];
        if (amount + spentThisBlock > limit) revert T_BlockSpendLimit();
        blockExpenditure[block.number] = amount + spentThisBlock;

        // approve tokens
        IERC20(token).approve(spender, amount);

        emit TreasuryApproval(token, spender, amount);
    }

    /// @notice do not execute code on receiving ether
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

pragma solidity 0.8.18;

/**
 * @title TreasuryErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains all custom errors for the Arcade Treasury contract.
 * All errors are prefixed by  "T_" for Treasury. Errors located in one place
 * to make it possible to holistically look at all the failure cases.
 */

/**
 * @notice Thrown when the zero address is passed as input.
 */
error T_ZeroAddress();

/**
 * @notice Cannot pass zero as an amount.
 */
error T_ZeroAmount();

/**
 * @notice Thresholds must be in ascending order.
 */
error T_ThresholdsNotAscending();

/**
 * @notice Array lengths must match.
 */
error T_ArrayLengthMismatch();

/**
 * @notice External call failed.
 */
error T_CallFailed();

/**
 * @notice Cannot withdraw or approve more than each tokens preset spend limits per block.
 */
error T_BlockSpendLimit();

/**
 * @notice Cannot make calls to addresses which have thresholds set. This is also a way to block
 * calls to unwanted addresses or bypass treasury withdraw functions.
 *
 * @param target               Specified address of the target contract.
 */
error T_InvalidTarget(address target);

/**
 * @notice When setting a new GSC allowance for a token it cannot be more than
 * that tokens small spend threshold.
 *
 * @param newAllowance             New allowance to set.
 * @param smallSpendThreshold      Maximum amount that can be approved for the GSC.
 */
error T_InvalidAllowance(uint256 newAllowance, uint256 smallSpendThreshold);

/**
 * @notice Must wait 7 days since last allowance was set to set a new one.
 *
 * @param currentTime             Current block timestamp.
 * @param coolDownPeriodEnd       Time when an allowance can be set.
 */
error T_CoolDownPeriod(uint256 currentTime, uint256 coolDownPeriodEnd);

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IArcadeTreasury {
    // ====== Structs ======

    /// @notice struct of spend thresholds
    struct SpendThreshold {
        uint256 small;
        uint256 medium;
        uint256 large;
    }

    // ====== Treasury Operations ======

    function gscSpend(address token, uint256 amount, address destination) external;

    function smallSpend(address token, uint256 amount, address destination) external;

    function mediumSpend(address token, uint256 amount, address destination) external;

    function largeSpend(address token, uint256 amount, address destination) external;

    function gscApprove(address token, address spender, uint256 amount) external;

    function approveSmallSpend(address token, address spender, uint256 amount) external;

    function approveMediumSpend(address token, address spender, uint256 amount) external;

    function approveLargeSpend(address token, address spender, uint256 amount) external;

    function setThreshold(address token, SpendThreshold memory thresholds) external;

    function setGSCAllowance(address token, uint256 newAllowance) external;

    function batchCalls(address[] memory targets, bytes[] calldata calldatas) external;
}