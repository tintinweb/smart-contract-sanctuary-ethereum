// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {PercentMath} from "../../lib/PercentMath.sol";
import {ERC165Query} from "../../lib/ERC165Query.sol";
import {IStrategy} from "../IStrategy.sol";
import {CustomErrors} from "../../interfaces/CustomErrors.sol";
import {IYearnVault} from "../../interfaces/yearn/IYearnVault.sol";
import {IVault} from "../../vault/IVault.sol";

/**
 * YearnStrategy generates yield by investing into a Yearn vault.
 *
 * @notice This strategy is syncrhonous (supports immediate withdrawals).
 */
contract YearnStrategy is IStrategy, AccessControl, CustomErrors {
    using SafeERC20 for IERC20;
    using PercentMath for uint256;
    using ERC165Query for address;

    /**
     * Emmited when the maxLossOnWithdraw (from Yearn vault) is changed.
     *
     * @param maxLoss new value for max loss withdraw param
     */
    event StrategyMaxLossOnWithdrawChanged(uint256 maxLoss);

    // yearn vault is 0x
    error StrategyYearnVaultCannotBe0Address();
    // max loss on withdraw from yearn > 100%
    error StrategyMaxLossOnWithdrawTooLarge();

    /// role allowed to invest/withdraw from yearn vault
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /// role allowed to change settings such as max loss on withdraw from yearn vault
    bytes32 public constant SETTINGS_ROLE = keccak256("SETTINGS_ROLE");
    // underlying ERC20 token
    IERC20 public immutable underlying;
    /// @inheritdoc IStrategy
    address public immutable override(IStrategy) vault;
    // yearn vault that this strategy is interacting with
    IYearnVault public immutable yVault;
    // multiplier for underlying convertion to shares
    uint128 public immutable conversionMultiplier;
    // used when withdrawing from yearn vault, 1 = 0.01%
    uint128 public maxLossOnWithdraw = 1;

    /**
     * @param _vault address of the vault that will use this strategy
     * @param _admin address of the administrator account for this strategy
     * @param _yVault address of the yearn vault that this strategy is using
     * @param _underlying address of the underlying token
     */
    constructor(
        address _vault,
        address _admin,
        address _yVault,
        address _underlying
    ) {
        if (_admin == address(0)) revert StrategyAdminCannotBe0Address();
        if (_yVault == address(0)) revert StrategyYearnVaultCannotBe0Address();
        if (_underlying == address(0))
            revert StrategyUnderlyingCannotBe0Address();

        if (!_vault.doesContractImplementInterface(type(IVault).interfaceId))
            revert StrategyNotIVault();

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(SETTINGS_ROLE, _admin);
        _setupRole(MANAGER_ROLE, _vault);

        vault = _vault;
        yVault = IYearnVault(_yVault);
        conversionMultiplier = uint128(10**yVault.decimals());

        underlying = IERC20(_underlying);

        underlying.approve(_yVault, type(uint256).max);
    }

    //
    // Modifiers
    //

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, msg.sender))
            revert StrategyCallerNotManager();
        _;
    }

    modifier onlySettings() {
        if (!hasRole(SETTINGS_ROLE, msg.sender))
            revert StrategyCallerNotSettings();
        _;
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert StrategyCallerNotAdmin();
        _;
    }

    /**
     * Transfers administrator rights for the Strategy to another account,
     * revoking current admin roles and setting up the roles for the new admin.
     *
     * @notice Can only be called by the account with the ADMIN role.
     *
     * @param _newAdmin The new Strategy admin account.
     */
    function transferAdminRights(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0x0)) revert StrategyAdminCannotBe0Address();
        if (_newAdmin == msg.sender)
            revert StrategyCannotTransferAdminRightsToSelf();

        _setupRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        _setupRole(SETTINGS_ROLE, _newAdmin);

        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(SETTINGS_ROLE, msg.sender);
    }

    /**
     * Yearn strategy is synchronous meaning it supports immediate withdrawals.
     *
     * @return true always
     */
    function isSync() external pure override(IStrategy) returns (bool) {
        return true;
    }

    /// @inheritdoc IStrategy
    function hasAssets()
        external
        view
        virtual
        override(IStrategy)
        returns (bool)
    {
        return _getShares() != 0;
    }

    /// @inheritdoc IStrategy
    function investedAssets()
        external
        view
        virtual
        override(IStrategy)
        returns (uint256)
    {
        return _sharesToUnderlying(_getShares()) + _getUnderlyingBalance();
    }

    /// @inheritdoc IStrategy
    function invest() external virtual override(IStrategy) onlyManager {
        uint256 beforeBalance = _getUnderlyingBalance();
        if (beforeBalance == 0) revert StrategyNoUnderlying();

        yVault.deposit(type(uint256).max, address(this));

        uint256 afterBalance = _getUnderlyingBalance();

        emit StrategyInvested(beforeBalance - afterBalance);
    }

    /// @inheritdoc IStrategy
    function withdrawToVault(uint256 _amount)
        external
        virtual
        override(IStrategy)
        onlyManager
    {
        if (_amount == 0) revert StrategyAmountZero();
        uint256 uninvestedUnderlying = _getUnderlyingBalance();

        if (_amount > uninvestedUnderlying) {
            uint256 sharesToWithdraw = _underlyingToShares(
                _amount - uninvestedUnderlying
            );

            if (sharesToWithdraw > _getShares())
                revert StrategyNotEnoughShares();

            // burn shares and withdraw required underlying to strategy
            uint256 withdrawnFromYearn = yVault.withdraw(
                sharesToWithdraw,
                address(this),
                maxLossOnWithdraw
            );

            _amount = uninvestedUnderlying + withdrawnFromYearn;
        }

        // transfer underlying to vault
        underlying.safeTransfer(vault, _amount);

        emit StrategyWithdrawn(_amount);
    }

    /**
     * Sets the max loss percentage used when withdrawing from the Yearn vault.
     *
     * @notice Can only be called by the account with settings role.
     *
     * @param _maxLoss The max loss percentage to use when withdrawing from the Yearn vault. Value of 1 equals 0.01% loss.
     */
    function setMaxLossOnWithdraw(uint128 _maxLoss) external onlySettings {
        if (_maxLoss > 10000) revert StrategyMaxLossOnWithdrawTooLarge();

        maxLossOnWithdraw = _maxLoss;

        emit StrategyMaxLossOnWithdrawChanged(_maxLoss);
    }

    /**
     * Get the underlying balance of the strategy.
     *
     * @return underlying balance of the strategy
     */
    function _getUnderlyingBalance() internal view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /**
     * Get the number of yearn vault shares owned by the strategy.
     *
     * @return shares owned by the strategy
     */
    function _getShares() internal view returns (uint256) {
        return yVault.balanceOf(address(this));
    }

    /**
     * Calculates the value of yearn vault shares in underlying.
     *
     * @param _shares number of yearn vault shares
     *
     * @return underlying value of yearn vault shares
     */
    function _sharesToUnderlying(uint256 _shares)
        internal
        view
        returns (uint256)
    {
        return (_shares * yVault.pricePerShare()) / conversionMultiplier;
    }

    /**
     * Calculates the amount of underlying in number of yearn vault shares.
     *
     * @param _underlying amount of underlying
     *
     * @return number of yearn vault shares
     */
    function _underlyingToShares(uint256 _underlying)
        internal
        view
        returns (uint256)
    {
        return (_underlying * conversionMultiplier) / yVault.pricePerShare();
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

library PercentMath {
    // Divisor used for representing percentages
    uint256 public constant PCT_DIVISOR = 10000;

    /**
     * @dev Returns whether an amount is a valid percentage out of PCT_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPct(uint256 _amount) internal pure returns (bool) {
        return _amount <= PCT_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PCT_DIVISOR as the denominator
     */
    function pctOf(uint256 _amount, uint16 _fracNum)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _fracNum) / PCT_DIVISOR;
    }

    /**
     * @dev Checks if a given number corresponds to 100%
     * @param _perc Percentage value to check, with PCT_DIVISOR
     */
    function is100Pct(uint256 _perc) internal pure returns (bool) {
        return _perc == PCT_DIVISOR;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

library ERC165Query {
    bytes4 constant InvalidID = 0xffffffff;
    bytes4 constant ERC165ID = 0x01ffc9a7;

    function doesContractImplementInterface(
        address _contract,
        bytes4 _interfaceId
    ) internal view returns (bool) {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, ERC165ID);
        if ((success == 0) || (result == 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, InvalidID);
        if ((success == 0) || (result != 0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if ((success == 1) && (result == 1)) {
            return true;
        }
        return false;
    }

    function noThrowCall(address _contract, bytes4 _interfaceId)
        internal
        view
        returns (uint256 success, uint256 result)
    {
        bytes4 erc165ID = ERC165ID;

        assembly {
            let x := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(x, erc165ID) // Place signature at beginning of empty storage
            mstore(add(x, 0x04), _interfaceId) // Place first argument directly next to signature

            success := staticcall(
                30000, // 30k gas
                _contract, // To addr
                x, // Inputs are stored at location x
                0x24, // Inputs are 36 bytes long
                x, // Store output over input (saves space)
                0x20
            ) // Outputs are 32 bytes long

            result := mload(x) // Load the result
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * IStrategy defines the interface for pluggable contracts used by vaults to invest funds and generate yield.
 *
 * @notice It's up to the strategy to decide what do to with investable assets provided by a vault.
 *
 * @notice It's up to the vault to decide how much to invest/disinvest from the total pool.
 */
interface IStrategy {
    /**
     * Emmited when funds are invested by the strategy.
     *
     *@param amount amount invested
     */
    event StrategyInvested(uint256 amount);
    /**
     * Emmited when funds are withdrawn (disinvested) by the strategy.
     *
     *@param amount amount withdrawn
     */
    event StrategyWithdrawn(uint256 amount);

    /**
     * Provides information about wether the strategy is synchronous or asynchronous.
     *
     * @notice Synchronous strategies support instant withdrawals,
     * while asynchronous strategies impose a delay before withdrawals can be made.
     *
     * @return true if the strategy is synchronous, false otherwise
     */
    function isSync() external view returns (bool);

    /**
     * The vault linked to this strategy.
     *
     * @return The vault's address
     */
    function vault() external view returns (address);

    /**
     * Withdraws the specified amount back to the vault (disinvests)
     *
     * @param amount Amount to withdraw
     */
    function withdrawToVault(uint256 amount) external;

    /**
     * Amount of the underlying currency currently invested by the strategy.
     *
     * @notice both held and invested amounts are included here, using the
     * latest known exchange rates to the underlying currency
     *
     * @return The total amount of underlying
     */
    function investedAssets() external view returns (uint256);

    /**
     * Indicates if assets are invested into strategy or not.
     *
     * @notice this will be used when removing the strategy from the vault
     * @return true if assets invested, false if nothing invested.
     */
    function hasAssets() external view returns (bool);

    /**
     * Deposits of all the available underlying into the yield generating protocol.
     */
    function invest() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface CustomErrors {
    //
    // Vault Errors
    //

    // Vault: sender is not the owner of the group id
    error VaultSenderNotOwnerOfGroupId();

    // Vault: invalid investPct
    error VaultInvalidInvestpct();

    // Vault: invalid performance fee
    error VaultInvalidPerformanceFee();

    // Vault: no performance fee
    error VaultNoPerformanceFee();

    // Vault: invalid investment fee
    error VaultInvalidLossTolerance();

    // Vault: underlying cannot be 0x0
    error VaultUnderlyingCannotBe0Address();

    // Vault: treasury cannot be 0x0
    error VaultTreasuryCannotBe0Address();

    // Vault: owner cannot be 0x0
    error VaultOwnerCannotBe0Address();

    // Vault: cannot transfer ownership to self
    error VaultCannotTransferOwnershipToSelf();

    // Vault: destination address is 0x
    error VaultDestinationCannotBe0Address();

    // Vault: strategy is not set
    error VaultStrategyNotSet();

    // Vault: invalid minLockPeriod
    error VaultInvalidMinLockPeriod();

    // Vault: invalid lock period
    error VaultInvalidLockPeriod();

    // Vault: cannot deposit 0
    error VaultCannotDeposit0();

    // Vault: cannot sponsor 0
    error VaultCannotSponsor0();

    // Vault: cannot deposit when yield is negative
    error VaultCannotDepositWhenYieldNegative();

    // Vault: cannot deposit when the claimer is in debt
    error VaultCannotDepositWhenClaimerInDebt();

    // Vault: cannot deposit when yield is negative
    error VaultCannotWithdrawWhenYieldNegative();

    // Vault: nothing to do
    error VaultNothingToDo();

    // Vault: not enough to rebalance
    error VaultNotEnoughToRebalance();

    // Vault: invalid vault
    error VaultInvalidVault();

    // Vault: strategy has invested funds
    error VaultStrategyHasInvestedFunds();

    // Vault: not enough funds
    error VaultNotEnoughFunds();

    // Vault: you are not allowed
    error VaultNotAllowed();

    // Vault: amount is locked
    error VaultAmountLocked();

    // Vault: deposit is locked
    error VaultDepositLocked();

    // Vault: token id is not a sponsor
    error VaultNotSponsor();

    // Vault: token id is not a deposit
    error VaultNotDeposit();

    // Vault: claim percentage cannot be 0
    error VaultClaimPercentageCannotBe0();

    // Vault: claimer cannot be address 0
    error VaultClaimerCannotBe0();

    // Vault: claims don't add up to 100%
    error VaultClaimsDontAddUp();

    // Vault: you are not the owner of a deposit
    error VaultNotOwnerOfDeposit();

    // Vault: cannot withdraw more than the available amount
    error VaultCannotWithdrawMoreThanAvailable();

    // Vault: amount received does not match params
    error VaultAmountDoesNotMatchParams();

    // Vault: cannot compute shares when there's no principal
    error VaultCannotComputeSharesWithoutPrincipal();

    // Vault: deposit name for MetaVault too short
    error VaultDepositNameTooShort();

    // Vault: no yield to claim
    error VaultNoYieldToClaim();

    //
    // Strategy Errors
    //

    // Strategy: admin is 0x
    error StrategyAdminCannotBe0Address();

    // Strategy: cannot transfer admin rights to self
    error StrategyCannotTransferAdminRightsToSelf();

    // Strategy: underlying is 0x
    error StrategyUnderlyingCannotBe0Address();

    // Strategy: not an IVault
    error StrategyNotIVault();

    // Strategy: caller is not manager
    error StrategyCallerNotManager();

    // Strategy: caller has no settings role
    error StrategyCallerNotSettings();

    // Strategy: caller is not admin
    error StrategyCallerNotAdmin();

    // Strategy: amount is 0
    error StrategyAmountZero();

    // Strategy: not running
    error StrategyNotRunning();

    // Not Enough Underlying Balance in Strategy contract
    error StrategyNoUnderlying();

    // Not Enough Shares in Strategy Contract
    error StrategyNotEnoughShares();
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IYearnVault {
    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function pricePerShare() external view returns (uint256);

    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function totalAssets() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVault {
    //
    // Structs
    //

    struct ClaimParams {
        uint16 pct;
        address beneficiary;
        bytes data;
    }

    struct DepositParams {
        address inputToken;
        uint64 lockDuration;
        uint256 amount;
        ClaimParams[] claims;
        string name;
        uint256 slippage;
    }

    struct Deposit {
        /// amount of the deposit
        uint256 amount;
        /// wallet of the owner
        address owner;
        /// wallet of the claimer
        address claimerId;
        /// when can the deposit be withdrawn
        uint256 lockedUntil;
    }

    struct Claimer {
        uint256 totalPrincipal;
        uint256 totalShares;
    }

    //
    // Events
    //

    event DepositMinted(
        uint256 indexed id,
        uint256 groupId,
        uint256 amount,
        uint256 shares,
        address indexed depositor,
        address indexed claimer,
        address claimerId,
        uint64 lockedUntil,
        bytes data,
        string name
    );

    event DepositWithdrawn(
        uint256 indexed id,
        uint256 shares,
        uint256 amount,
        address indexed to,
        bool burned
    );

    event Invested(uint256 amount);

    event Disinvested(uint256 amount);

    event YieldClaimed(
        address claimerId,
        address indexed to,
        uint256 amount,
        uint256 burnedShares,
        uint256 perfFee,
        uint256 totalUnderlying,
        uint256 totalShares
    );

    event FeeWithdrawn(uint256 amount);

    //
    // Public API
    //

    /**
     * Update the invested amount;
     */
    function updateInvested() external;

    /**
     * Calculate maximum investable amount and already invested amount
     *
     * @return maxInvestableAmount maximum investable amount
     * @return alreadyInvested already invested amount
     */
    function investState()
        external
        view
        returns (uint256 maxInvestableAmount, uint256 alreadyInvested);

    /**
     * Percentage of the total underlying to invest in the strategy
     */
    function investPct() external view returns (uint16);

    /**
     * Underlying ERC20 token accepted by the vault
     */
    function underlying() external view returns (IERC20Metadata);

    /**
     * Minimum lock period for each deposit
     */
    function minLockPeriod() external view returns (uint64);

    /**
     * Total amount of underlying currently controlled by the
     * vault and the its strategy.
     */
    function totalUnderlying() external view returns (uint256);

    /**
     * Total amount of shares
     */
    function totalShares() external view returns (uint256);

    /**
     * Computes the amount of yield available for an an address.
     *
     * @param _to address to consider.
     *
     * @return claimable yield for @param _to, share of generated yield by @param _to,
     *      and performance fee from generated yield
     */
    function yieldFor(address _to)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * Accumulate performance fee and transfers rest yield generated for the caller to
     *
     * @param _to Address that will receive the yield.
     */
    function claimYield(address _to) external;

    /**
     * Creates a new deposit using the specified group id
     *
     * @param _groupId The group id for the new deposit
     * @param _params Deposit params
     */
    function depositForGroupId(uint256 _groupId, DepositParams calldata _params)
        external
        returns (uint256[] memory);

    /**
     * Creates a new deposit
     *
     * @param _params Deposit params
     */
    function deposit(DepositParams calldata _params)
        external
        returns (uint256[] memory);

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * It fails if the vault is underperforming and there are not enough funds
     * to withdraw the expected amount.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function withdraw(address _to, uint256[] calldata _ids) external;

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * When the vault is underperforming it withdraws the funds with a loss.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function forceWithdraw(address _to, uint256[] calldata _ids) external;

    /**
     * Withdraws any pending performance fee amount back to the treasury
     */
    function withdrawPerformanceFee() external;
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