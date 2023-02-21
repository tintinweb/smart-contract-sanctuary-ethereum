// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IDeadDrop.sol";
import "./libraries/ErrorCodes.sol";

contract DeadDrop is IDeadDrop, AccessControl {
    using SafeERC20 for IERC20;

    /// @dev Value is the Keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    ISwapRouter public swapRouter;
    ILiquidation public liquidation;

    /// @notice Whitelist for markets allowed as a withdrawal destination.
    mapping(IERC20 => IMToken) public allowedMarkets;

    /// @notice Whitelist for users who can be a withdrawal recipients
    mapping(address => bool) public allowedWithdrawReceivers;

    /// @dev Internal processing state of an address that is used for liquidation purposes
    mapping(address => mapping(uint256 => uint256)) public processingState;

    constructor(address admin_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(TIMELOCK, admin_);
    }

    /************************************************************************/
    /*                          BOT FUNCTIONS                               */
    /************************************************************************/

    /// @inheritdoc IDeadDrop
    function performSwap(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState,
        uint256 targetState,
        IERC20 tokenIn,
        uint256 tokenInAmount,
        IERC20 tokenOut,
        bytes calldata data
    ) external onlyRole(GATEKEEPER) {
        require(address(swapRouter) != address(0), ErrorCodes.DD_SWAP_ROUTER_IS_ZERO);

        require(address(tokenIn) != address(0), ErrorCodes.DD_INVALID_TOKEN_IN_ADDRESS);
        require(address(tokenOut) != address(0), ErrorCodes.DD_INVALID_TOKEN_OUT_ADDRESS);
        require(tokenInAmount > 0, ErrorCodes.DD_INVALID_TOKEN_IN_AMOUNT);

        require(address(allowedMarkets[tokenIn]) != address(0), ErrorCodes.DD_UNSUPPORTED_TOKEN);
        require(address(allowedMarkets[tokenOut]) != address(0), ErrorCodes.DD_UNSUPPORTED_TOKEN);

        require(isProcessingStateValid(validationKey, validationHash, requiredState), ErrorCodes.PRECONDITIONS_NOT_MET);
        updateProcessingStateInternal(validationKey, validationHash, targetState);

        uint256 amountInBefore = tokenIn.balanceOf(address(this));
        uint256 amountOutBefore = tokenOut.balanceOf(address(this));

        // slither-disable-next-line reentrancy-events
        tokenIn.safeApprove(address(swapRouter), tokenInAmount);

        // slither-disable-next-line reentrancy-events
        Address.functionCall(address(swapRouter), data, ErrorCodes.DD_SWAP_CALL_FAILS);

        uint256 amountInAfter = tokenIn.balanceOf(address(this));
        uint256 amountOutAfter = tokenOut.balanceOf(address(this));

        emit Swap(tokenIn, tokenOut, amountInBefore - amountInAfter, amountOutAfter - amountOutBefore);
    }

    /// @inheritdoc IDeadDrop
    function withdrawToProtocolInterest(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState,
        uint256 targetState,
        uint256 amount,
        IERC20 underlying
    ) external onlyRole(GATEKEEPER) {
        IMToken market = allowedMarkets[underlying];
        require(address(market) != address(0), ErrorCodes.DD_UNSUPPORTED_TOKEN);

        require(isProcessingStateValid(validationKey, validationHash, requiredState), ErrorCodes.PRECONDITIONS_NOT_MET);
        updateProcessingStateInternal(validationKey, validationHash, targetState);

        emit WithdrewToProtocolInterest(amount, underlying, market);

        underlying.safeApprove(address(market), amount);
        market.addProtocolInterest(amount);
    }

    /// @inheritdoc IDeadDrop
    function initialiseLiquidation(address target, uint256 hashValue) external {
        require(msg.sender == address(liquidation), ErrorCodes.UNAUTHORIZED);
        require(isProcessingStateValid(target, hashValue, 0), ErrorCodes.PRECONDITIONS_NOT_MET);
        updateProcessingStateInternal(target, hashValue, 1);
    }

    /// @inheritdoc IDeadDrop
    function updateProcessingState(
        address validationKey,
        uint256 validationHash,
        uint256 targetState
    ) external onlyRole(GATEKEEPER) {
        updateProcessingStateInternal(validationKey, validationHash, targetState);
    }

    /// @inheritdoc IDeadDrop
    function finaliseLiquidation(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState
    ) external onlyRole(GATEKEEPER) {
        require(isProcessingStateValid(validationKey, validationHash, requiredState), ErrorCodes.PRECONDITIONS_NOT_MET);
        updateProcessingStateInternal(validationKey, validationHash, 0);
        emit LiquidationFinalised(validationKey, validationHash);
    }

    /************************************************************************/
    /*                        ADMIN FUNCTIONS                               */
    /************************************************************************/

    /* --- LOGIC --- */

    /// @inheritdoc IDeadDrop
    function withdraw(
        uint256 amount,
        IERC20 underlying,
        address to
    ) external onlyRole(DEFAULT_ADMIN_ROLE) allowedReceiversOnly(to) {
        require(underlying.balanceOf(address(this)) >= amount, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        emit Withdraw(address(underlying), to, amount);
        underlying.safeTransfer(to, amount);
    }

    /* --- SETTERS --- */

    /// @inheritdoc IDeadDrop
    function addAllowedMarket(IMToken market) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(market) != address(0), ErrorCodes.DD_MARKET_ADDRESS_IS_ZERO);
        allowedMarkets[market.underlying()] = market;
        emit NewAllowedMarket(market.underlying(), market);
    }

    /// @inheritdoc IDeadDrop
    function setRouterAddress(ISwapRouter router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(router) != address(0), ErrorCodes.DD_ROUTER_ADDRESS_IS_ZERO);
        require(swapRouter != router, ErrorCodes.DD_ROUTER_ALREADY_SET);
        swapRouter = router;
        emit NewSwapRouter(router);
    }

    /// @inheritdoc IDeadDrop
    function setLiquidationAddress(ILiquidation liquidationContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(liquidationContract) != address(0), ErrorCodes.DD_LIQUIDATION_ADDRESS_IS_ZERO);
        require(liquidationContract != liquidation, ErrorCodes.DD_LIQUIDATION_ALREADY_SET);
        liquidation = liquidationContract;
        emit NewLiquidation(liquidationContract);
    }

    /// @inheritdoc IDeadDrop
    function addAllowedReceiver(address receiver) external onlyRole(TIMELOCK) {
        require(receiver != address(0), ErrorCodes.DD_RECEIVER_ADDRESS_IS_ZERO);
        require(!allowedWithdrawReceivers[receiver], ErrorCodes.DD_RECEIVER_ALREADY_SET);
        allowedWithdrawReceivers[receiver] = true;
        emit NewAllowedWithdrawReceiver(receiver);
    }

    /// @inheritdoc IDeadDrop
    function addAllowedBot(address bot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bot != address(0), ErrorCodes.DD_BOT_ADDRESS_IS_ZERO);
        require(!hasRole(GATEKEEPER, bot), ErrorCodes.DD_BOT_ALREADY_SET);
        _grantRole(GATEKEEPER, bot);
        emit NewAllowedBot(bot);
    }

    /* --- REMOVERS --- */

    /// @inheritdoc IDeadDrop
    function removeAllowedMarket(IERC20 underlying) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IMToken market = allowedMarkets[underlying];
        require(address(market) != address(0), ErrorCodes.DD_MARKET_NOT_FOUND);
        delete allowedMarkets[underlying];
        emit AllowedMarketRemoved(underlying, market);
    }

    /// @inheritdoc IDeadDrop
    function removeAllowedReceiver(address receiver) external onlyRole(TIMELOCK) allowedReceiversOnly(receiver) {
        delete allowedWithdrawReceivers[receiver];
        emit AllowedWithdrawReceiverRemoved(receiver);
    }

    /// @inheritdoc IDeadDrop
    function removeAllowedBot(address bot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(GATEKEEPER, bot), ErrorCodes.DD_BOT_NOT_FOUND);
        _revokeRole(GATEKEEPER, bot);
        emit AllowedBotRemoved(bot);
    }

    /************************************************************************/
    /*                          INTERNAL FUNCTIONS                          */
    /************************************************************************/

    function isProcessingStateValid(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState
    ) internal view returns (bool) {
        return (processingState[validationKey][validationHash] == requiredState);
    }

    function updateProcessingStateInternal(
        address validationKey,
        uint256 validationHash,
        uint256 targetState
    ) internal {
        uint256 currentState = processingState[validationKey][validationHash];
        processingState[validationKey][validationHash] = targetState;
        emit NewProcessingState(validationKey, validationHash, currentState, targetState);
    }

    modifier allowedReceiversOnly(address receiver) {
        require(allowedWithdrawReceivers[receiver], ErrorCodes.DD_RECEIVER_NOT_FOUND);
        _;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

library ErrorCodes {
    // Common
    string internal constant ADMIN_ONLY = "E101";
    string internal constant UNAUTHORIZED = "E102";
    string internal constant OPERATION_PAUSED = "E103";
    string internal constant WHITELISTED_ONLY = "E104";
    string internal constant ADDRESS_IS_NOT_IN_AML_SYSTEM = "E105";
    string internal constant ADDRESS_IS_BLACKLISTED = "E106";

    // Invalid input
    string internal constant ADMIN_ADDRESS_CANNOT_BE_ZERO = "E201";
    string internal constant INVALID_REDEEM = "E202";
    string internal constant REDEEM_TOO_MUCH = "E203";
    string internal constant MARKET_NOT_LISTED = "E204";
    string internal constant INSUFFICIENT_LIQUIDITY = "E205";
    string internal constant INVALID_SENDER = "E206";
    string internal constant BORROW_CAP_REACHED = "E207";
    string internal constant BALANCE_OWED = "E208";
    string internal constant UNRELIABLE_LIQUIDATOR = "E209";
    string internal constant INVALID_DESTINATION = "E210";
    string internal constant INSUFFICIENT_STAKE = "E211";
    string internal constant INVALID_DURATION = "E212";
    string internal constant INVALID_PERIOD_RATE = "E213";
    string internal constant EB_TIER_LIMIT_REACHED = "E214";
    string internal constant INVALID_DEBT_REDEMPTION_RATE = "E215";
    string internal constant LQ_INVALID_SEIZE_DISTRIBUTION = "E216";
    string internal constant EB_TIER_DOES_NOT_EXIST = "E217";
    string internal constant EB_ZERO_TIER_CANNOT_BE_ENABLED = "E218";
    string internal constant EB_ALREADY_ACTIVATED_TIER = "E219";
    string internal constant EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT = "E220";
    string internal constant EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER = "E221";
    string internal constant EB_EMISSION_BOOST_IS_NOT_IN_RANGE = "E222";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E223";
    string internal constant INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT = "E224";
    string internal constant VESTING_SCHEDULE_ALREADY_EXISTS = "E225";
    string internal constant INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE = "E226";
    string internal constant NO_VESTING_SCHEDULE = "E227";
    string internal constant SCHEDULE_IS_IRREVOCABLE = "E228";
    string internal constant MNT_AMOUNT_IS_ZERO = "E230";
    string internal constant INCORRECT_AMOUNT = "E231";
    string internal constant MEMBERSHIP_LIMIT = "E232";
    string internal constant MEMBER_NOT_EXIST = "E233";
    string internal constant MEMBER_ALREADY_ADDED = "E234";
    string internal constant MEMBERSHIP_LIMIT_REACHED = "E235";
    string internal constant REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO = "E236";
    string internal constant MTOKEN_ADDRESS_CANNOT_BE_ZERO = "E237";
    string internal constant TOKEN_ADDRESS_CANNOT_BE_ZERO = "E238";
    string internal constant REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO = "E239";
    string internal constant FL_TOKEN_IS_NOT_UNDERLYING = "E240";
    string internal constant FL_AMOUNT_IS_TOO_LARGE = "E241";
    string internal constant FL_CALLBACK_FAILED = "E242";
    string internal constant DD_UNSUPPORTED_TOKEN = "E243";
    string internal constant DD_MARKET_ADDRESS_IS_ZERO = "E244";
    string internal constant DD_ROUTER_ADDRESS_IS_ZERO = "E245";
    string internal constant DD_RECEIVER_ADDRESS_IS_ZERO = "E246";
    string internal constant DD_BOT_ADDRESS_IS_ZERO = "E247";
    string internal constant DD_MARKET_NOT_FOUND = "E248";
    string internal constant DD_RECEIVER_NOT_FOUND = "E249";
    string internal constant DD_BOT_NOT_FOUND = "E250";
    string internal constant DD_ROUTER_ALREADY_SET = "E251";
    string internal constant DD_RECEIVER_ALREADY_SET = "E252";
    string internal constant DD_BOT_ALREADY_SET = "E253";
    string internal constant EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX = "E254";
    string internal constant LQ_INVALID_DRR_ARRAY = "E255";
    string internal constant LQ_INVALID_SEIZE_ARRAY = "E256";
    string internal constant LQ_INVALID_DEBT_REDEMPTION_RATE = "E257";
    string internal constant LQ_INVALID_SEIZE_INDEX = "E258";
    string internal constant LQ_DUPLICATE_SEIZE_INDEX = "E259";
    string internal constant DD_INVALID_TOKEN_IN_ADDRESS = "E260";
    string internal constant DD_INVALID_TOKEN_OUT_ADDRESS = "E261";
    string internal constant DD_INVALID_TOKEN_IN_AMOUNT = "E262";
    string internal constant DD_LIQUIDATION_ADDRESS_IS_ZERO = "E263";
    string internal constant DD_LIQUIDATION_ALREADY_SET = "E264";

    // Protocol errors
    string internal constant INVALID_PRICE = "E301";
    string internal constant MARKET_NOT_FRESH = "E302";
    string internal constant BORROW_RATE_TOO_HIGH = "E303";
    string internal constant INSUFFICIENT_TOKEN_CASH = "E304";
    string internal constant INSUFFICIENT_TOKENS_FOR_RELEASE = "E305";
    string internal constant INSUFFICIENT_MNT_FOR_GRANT = "E306";
    string internal constant TOKEN_TRANSFER_IN_UNDERFLOW = "E307";
    string internal constant NOT_PARTICIPATING_IN_BUYBACK = "E308";
    string internal constant NOT_ENOUGH_PARTICIPATING_ACCOUNTS = "E309";
    string internal constant NOTHING_TO_DISTRIBUTE = "E310";
    string internal constant ALREADY_PARTICIPATING_IN_BUYBACK = "E311";
    string internal constant MNT_APPROVE_FAILS = "E312";
    string internal constant TOO_EARLY_TO_DRIP = "E313";
    string internal constant BB_UNSTAKE_TOO_EARLY = "E314";
    string internal constant INSUFFICIENT_SHORTFALL = "E315";
    string internal constant HEALTHY_FACTOR_NOT_IN_RANGE = "E316";
    string internal constant BUYBACK_DRIPS_ALREADY_HAPPENED = "E317";
    string internal constant EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL = "E318";
    string internal constant NO_VESTING_SCHEDULES = "E319";
    string internal constant INSUFFICIENT_UNRELEASED_TOKENS = "E320";
    string internal constant ORACLE_PRICE_EXPIRED = "E321";
    string internal constant TOKEN_NOT_FOUND = "E322";
    string internal constant RECEIVED_PRICE_HAS_INVALID_ROUND = "E323";
    string internal constant FL_PULL_AMOUNT_IS_TOO_LOW = "E324";
    string internal constant INSUFFICIENT_TOTAL_PROTOCOL_INTEREST = "E325";
    string internal constant BB_ACCOUNT_RECENTLY_VOTED = "E326";
    string internal constant DD_SWAP_ROUTER_IS_ZERO = "E327";
    string internal constant DD_SWAP_CALL_FAILS = "E328";
    string internal constant LL_NEW_ROOT_CANNOT_BE_ZERO = "E329";
    string internal constant RH_PAYOUT_FROM_FUTURE = "E330";
    string internal constant RH_ACCRUE_WITHOUT_UNLOCK = "E331";
    string internal constant RH_LERP_DELTA_IS_GREATER_THAN_PERIOD = "E332";
    string internal constant PRECONDITIONS_NOT_MET = "E333";

    // Invalid input - Admin functions
    string internal constant ZERO_EXCHANGE_RATE = "E401";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant MARKET_ALREADY_LISTED = "E403";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant EC_INVALID_PROVIDER_REPRESENTATIVE = "E406";
    string internal constant EC_PROVIDER_CANT_BE_REPRESENTATIVE = "E407";
    string internal constant OR_ORACLE_ADDRESS_CANNOT_BE_ZERO = "E408";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO = "E409";
    string internal constant OR_REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO = "E410";
    string internal constant INVALID_TOKEN = "E411";
    string internal constant INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA = "E412";
    string internal constant INVALID_REDUCE_AMOUNT = "E413";
    string internal constant LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO = "E414";
    string internal constant INVALID_UTILISATION_FACTOR_MANTISSA = "E415";
    string internal constant INVALID_MTOKENS_OR_BORROW_CAPS = "E416";
    string internal constant FL_PARAM_IS_TOO_LARGE = "E417";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E418";
    string internal constant INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL = "E419";
    string internal constant EC_INVALID_BOOSTS = "E420";
    string internal constant EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER = "E421";
    string internal constant EC_ACCOUNT_HAS_NO_AGREEMENT = "E422";
    string internal constant OR_TIMESTAMP_THRESHOLD_SHOULD_BE_GREATER_THAN_ZERO = "E423";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_TOO_BIG = "E424";
    string internal constant OR_REPORTER_MULTIPLIER_TOO_BIG = "E425";
    string internal constant SHOULD_HAVE_REVOCABLE_SCHEDULE = "E426";
    string internal constant MEMBER_NOT_IN_DELAY_LIST = "E427";
    string internal constant DELAY_LIST_LIMIT = "E428";
    string internal constant NUMBER_IS_NOT_IN_SCALE = "E429";
    string internal constant BB_STRATUM_OF_FIRST_LOYALTY_GROUP_IS_NOT_ZERO = "E430";
    string internal constant INPUT_ARRAY_IS_EMPTY = "E431";
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ILiquidation.sol";
import "./IMToken.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IDeadDrop is IAccessControl {
    event WithdrewToProtocolInterest(uint256 amount, IERC20 token, IMToken market);
    event Withdraw(address token, address to, uint256 amount);
    event NewLiquidation(ILiquidation liquidation);
    event NewSwapRouter(ISwapRouter router);
    event NewAllowedWithdrawReceiver(address receiver);
    event NewAllowedBot(address bot);
    event NewAllowedMarket(IERC20 token, IMToken market);
    event AllowedWithdrawReceiverRemoved(address receiver);
    event AllowedBotRemoved(address bot);
    event AllowedMarketRemoved(IERC20 token, IMToken market);
    event Swap(IERC20 tokenIn, IERC20 tokenOut, uint256 spentAmount, uint256 receivedAmount);
    event NewProcessingState(address target, uint256 hashValue, uint256 oldState, uint256 newState);
    event LiquidationFinalised(address target, uint256 hashValue);

    /**
     * @notice get Uniswap SwapRouter
     */
    function swapRouter() external view returns (ISwapRouter);

    /**
     * @notice get Whitelist for markets allowed as a withdrawal destination.
     */
    function allowedMarkets(IERC20) external view returns (IMToken);

    /**
     * @notice get whitelist for users who can be a withdrawal recipients
     */
    function allowedWithdrawReceivers(address) external view returns (bool);

    /**
     * @notice get keccak-256 hash of gatekeeper role
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice Perform swap on Uniswap DEX
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param requiredState operation code that should precede the current operation
     * @param targetState operation code that will be assigned after successful swap
     * @param tokenIn input token
     * @param tokenInAmount amount of input token
     * @param tokenOut output token
     * @param data Uniswap calldata
     * @dev RESTRICTION: Gatekeeper only
     */
    function performSwap(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState,
        uint256 targetState,
        IERC20 tokenIn,
        uint256 tokenInAmount,
        IERC20 tokenOut,
        bytes calldata data
    ) external;

    /**
     * @notice Withdraw underlying asset to market's protocol interest
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param requiredState operation code that should precede the current operation
     * @param targetState operation code that will be assigned after successful withdrawal
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     * @dev RESTRICTION: Gatekeeper only
     */
    function withdrawToProtocolInterest(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState,
        uint256 targetState,
        uint256 amount,
        IERC20 underlying
    ) external;

    /**
     * @notice Set processing state of started liquidation
     * @param target Address of the account under liquidation
     * @param hashValue Liquidation identity hash
     * @dev RESTRICTION: Liquidator contract only
     */
    function initialiseLiquidation(address target, uint256 hashValue) external;

    /**
     * @notice Update processing state of ongoing liquidation
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param targetState New state value of the liquidation
     * @dev RESTRICTION: Gatekeeper only
     */
    function updateProcessingState(
        address validationKey,
        uint256 validationHash,
        uint256 targetState
    ) external;

    /**
     * @notice Finalise processing state of ongoing liquidation
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param requiredState State value required to complete finalization
     * @dev RESTRICTION: Gatekeeper only
     */
    function finaliseLiquidation(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState
    ) external;

    /**
     * @notice Withdraw tokens to the wallet
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     * @param to Receipient address
     * @dev RESTRICTION: Admin only
     */
    function withdraw(
        uint256 amount,
        IERC20 underlying,
        address to
    ) external;

    /**
     * @notice Add new market to the whitelist
     * @dev RESTRICTION: Admin only
     */
    function addAllowedMarket(IMToken market) external;

    /**
     * @notice Set new ILiquidation contract
     * @dev RESTRICTION: Admin only
     */
    function setLiquidationAddress(ILiquidation liquidationContract) external;

    /**
     * @notice Set new ISwapRouter router
     * @dev RESTRICTION: Admin only
     */
    function setRouterAddress(ISwapRouter router) external;

    /**
     * @notice Add new withdraw receiver address to the whitelist
     * @dev RESTRICTION: TIMELOCK only
     */
    function addAllowedReceiver(address receiver) external;

    /**
     * @notice Add new bot address to the whitelist
     * @dev RESTRICTION: Admin only
     */
    function addAllowedBot(address bot) external;

    /**
     * @notice Remove market from the whitelist
     * @dev RESTRICTION: Admin only
     */
    function removeAllowedMarket(IERC20 underlying) external;

    /**
     * @notice Remove withdraw receiver address from the whitelist
     * @dev RESTRICTION: TIMELOCK only
     */
    function removeAllowedReceiver(address receiver) external;

    /**
     * @notice Remove withdraw bot address from the whitelist
     * @dev RESTRICTION: Admin only
     */
    function removeAllowedBot(address bot) external;
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IInterestRateModel.sol";

interface IMToken is IAccessControl, IERC20, IERC3156FlashLender, IERC165 {
    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalProtocolInterest
    );

    /**
     * @notice Event emitted when tokens are lended
     */
    event Lend(address lender, uint256 lendAmount, uint256 lendTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are seized
     */
    event Seize(
        address borrower,
        address receiver,
        uint256 seizeTokens,
        uint256 accountsTokens,
        uint256 totalSupply,
        uint256 seizeUnderlyingAmount
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is repaid during autoliquidation
     */
    event AutoLiquidationRepayBorrow(
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrowsNew,
        uint256 totalBorrowsNew,
        uint256 TotalProtocolInterestNew
    );

    /**
     * @notice Event emitted when flash loan is executed
     */
    event FlashLoanExecuted(address receiver, uint256 amount, uint256 fee);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the protocol interest factor is changed
     */
    event NewProtocolInterestFactor(
        uint256 oldProtocolInterestFactorMantissa,
        uint256 newProtocolInterestFactorMantissa
    );

    /**
     * @notice Event emitted when the flash loan max share is changed
     */
    event NewFlashLoanMaxShare(uint256 oldMaxShare, uint256 newMaxShare);

    /**
     * @notice Event emitted when the flash loan fee is changed
     */
    event NewFlashLoanFee(uint256 oldFee, uint256 newFee);

    /**
     * @notice Event emitted when the protocol interest are added
     */
    event ProtocolInterestAdded(address benefactor, uint256 addAmount, uint256 newTotalProtocolInterest);

    /**
     * @notice Event emitted when the protocol interest reduced
     */
    event ProtocolInterestReduced(address admin, uint256 reduceAmount, uint256 newTotalProtocolInterest);

    /**
     * @notice Value is the Keccak-256 hash of "TIMELOCK"
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Underlying asset for this MToken
     */
    function underlying() external view returns (IERC20);

    /**
     * @notice EIP-20 token name for this token
     */
    function name() external view returns (string memory);

    /**
     * @notice EIP-20 token symbol for this token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice EIP-20 token decimals for this token
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Model which tells what the current interest rate should be
     */
    function interestRateModel() external view returns (IInterestRateModel);

    /**
     * @notice Initial exchange rate used when lending the first MTokens (used when totalTokenSupply = 0)
     */
    function initialExchangeRateMantissa() external view returns (uint256);

    /**
     * @notice Fraction of interest currently set aside for protocol interest
     */
    function protocolInterestFactorMantissa() external view returns (uint256);

    /**
     * @notice Block number that interest was last accrued at
     */
    function accrualBlockNumber() external view returns (uint256);

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    function borrowIndex() external view returns (uint256);

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    function totalBorrows() external view returns (uint256);

    /**
     * @notice Total amount of protocol interest of the underlying held in this market
     */
    function totalProtocolInterest() external view returns (uint256);

    /**
     * @notice Share of market's current underlying token balance that can be used as flash loan (scaled by 1e18).
     */
    function maxFlashLoanShare() external view returns (uint256);

    /**
     * @notice Share of flash loan amount that would be taken as fee (scaled by 1e18).
     */
    function flashLoanFeeShare() external view returns (uint256);

    /**
     * @notice Returns total token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by supervisor to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Returns the current per-block borrow interest rate for this mToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this mToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external returns (uint256);

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's
     *         borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external returns (uint256);

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this mToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Applies accrued interest to total borrows and protocol interest
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() external;

    /**
     * @notice Sender supplies assets into the market and receives mTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param lendAmount The amount of the underlying asset to supply
     */
    function lend(uint256 lendAmount) external;

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mTokens to redeem into underlying
     */
    function redeem(uint256 redeemTokens) external;

    /**
     * @notice Redeems all mTokens for account in exchange for the underlying asset.
     * Can only be called within the AML system!
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param account An account that is potentially sanctioned by the AML system
     */
    function redeemByAmlDecision(address account) external;

    /**
     * @notice Sender redeems mTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming mTokens
     */
    function redeemUnderlying(uint256 redeemAmount) external;

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */
    function borrow(uint256 borrowAmount) external;

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     */
    function repayBorrow(uint256 repayAmount) external;

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external;

    /**
     * @notice Liquidator repays a borrow belonging to borrower
     * @param borrower_ the account with the debt being payed off
     * @param repayAmount_ the amount of underlying tokens being returned
     */
    function autoLiquidationRepayBorrow(address borrower_, uint256 repayAmount_) external;

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract.
     *         Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     * @dev RESTRICTION: Admin only.
     */
    function sweepToken(IERC20 token, address admin_) external;

    /**
     * @notice Burns collateral tokens at the borrower's address, transfer underlying assets
     to the DeadDrop or Liquidator address.
     * @dev Called only during an auto liquidation process, msg.sender must be the Liquidation contract.
     * @param borrower_ The account having collateral seized
     * @param seizeUnderlyingAmount_ The number of underlying assets to seize. The caller must ensure
     that the parameter is greater than zero.
     * @param isLoanInsignificant_ Marker for insignificant loan whose collateral must be credited to the
     protocolInterest
     * @param receiver_ Address that receives accounts collateral
     */
    function autoLiquidationSeize(
        address borrower_,
        uint256 seizeUnderlyingAmount_,
        bool isLoanInsignificant_,
        address receiver_
    ) external;

    /**
     * @notice The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @notice The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @notice Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice accrues interest and sets a new protocol interest factor for the protocol
     * @dev Admin function to accrue interest and set a new protocol interest factor
     * @dev RESTRICTION: Timelock only.
     */
    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa) external;

    /**
     * @notice Accrues interest and increase protocol interest by transferring from msg.sender
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterest(uint256 addAmount_) external;

    /**
     * @notice Can only be called by liquidation contract. Increase protocol interest by transferring from payer.
     * @dev Calling code should make sure that accrueInterest() was called before.
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestBehalf(address payer_, uint256 addAmount_) external;

    /**
     * @notice Accrues interest and reduces protocol interest by transferring to admin
     * @param reduceAmount Amount of reduction to protocol interest
     * @dev RESTRICTION: Admin only.
     */
    function reduceProtocolInterest(uint256 reduceAmount, address admin_) external;

    /**
     * @notice accrues interest and updates the interest rate model using setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @dev RESTRICTION: Timelock only.
     */
    function setInterestRateModel(IInterestRateModel newInterestRateModel) external;

    /**
     * @notice Updates share of markets cash that can be used as maximum amount of flash loan.
     * @param newMax New max amount share
     * @dev RESTRICTION: Timelock only.
     */
    function setFlashLoanMaxShare(uint256 newMax) external;

    /**
     * @notice Updates fee of flash loan.
     * @param newFee New fee share of flash loan
     * @dev RESTRICTION: Timelock only.
     */
    function setFlashLoanFeeShare(uint256 newFee) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./IMToken.sol";
import "./IDeadDrop.sol";
import "./ILinkageLeaf.sol";
import "./IPriceOracle.sol";

/**
 * This contract provides the liquidation functionality.
 */
interface ILiquidation is IAccessControl, ILinkageLeaf {
    event HealthyFactorLimitChanged(uint256 oldValue, uint256 newValue);
    event NewDeadDrop(address oldDeadDrop, address newDeadDrop);
    event NewInsignificantLoanThreshold(uint256 oldValue, uint256 newValue);
    event ReliableLiquidation(
        bool isManualLiquidation,
        bool isDebtHealthy,
        address liquidator,
        address borrower,
        IMToken[] marketAddresses,
        uint256[] seizeIndexes,
        uint256[] debtRates
    );
    event ProcessingStateUsageChanged(bool newValue);

    /**
     * @dev Local accountState for avoiding stack-depth limits in calculating liquidation amounts.
     */
    struct AccountLiquidationAmounts {
        uint256 accountTotalSupplyUsd;
        uint256 accountTotalCollateralUsd;
        uint256 accountPresumedTotalRepayUsd;
        uint256 accountTotalBorrowUsd;
        uint256[] repayAmounts;
        uint256[] seizeAmounts;
    }

    /**
     * @notice GET The maximum allowable value of a healthy factor after liquidation, scaled by 1e18
     */
    function healthyFactorLimit() external view returns (uint256);

    /**
     * @notice GET Maximum sum in USD for internal liquidation. Collateral for loans that are less
     * than this parameter will be counted as protocol interest, scaled by 1e18
     */
    function insignificantLoanThreshold() external view returns (uint256);

    /**
     * @notice get keccak-256 hash of TRUSTED_LIQUIDATOR role
     */
    function TRUSTED_LIQUIDATOR() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of MANUAL_LIQUIDATOR role
     */
    function MANUAL_LIQUIDATOR() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of TIMELOCK role
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Liquidate insolvent debt position
     * @param borrower_ Account which is being liquidated
     * @param seizeIndexes_ An array with market indexes that will be used as collateral.
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_  An array of debt redemption rates for each debt markets (scaled by 1e18).
     * @dev RESTRICTION: Trusted liquidator only
     */
    function liquidateUnsafeLoan(
        address borrower_,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external;

    /**
     * @notice Accrues interest for all required borrower's markets
     * @dev Accrue is required if market is used as borrow (debtRate > 0)
     *      or collateral (seizeIndex arr contains market index)
     *      The caller must ensure that the lengths of arrays 'accountAssets' and 'debtRates' are the same,
     *      array 'seizeIndexes' does not contain duplicates and none of the indexes exceeds the value
     *      (accountAssets.length - 1).
     * @param accountAssets An array with addresses of markets where the debtor is in
     * @param seizeIndexes_ An array with market indexes that will be used as collateral
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18)
     */
    function accrue(
        IMToken[] memory accountAssets,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external;

    /**
     * @notice For each market calculates the liquidation amounts based on borrower's state.
     * @param account_ The address of the borrower
     * @param marketAddresses An array with addresses of markets where the debtor is in
     * @param seizeIndexes_ An array with market indexes that will be used as collateral
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18)
     * @return accountState Struct that contains all balance parameters
     *         All arrays calculated in underlying assets, all total values calculated in USD.
     *         (the array indexes match each other)
     */
    function calculateLiquidationAmounts(
        address account_,
        IMToken[] memory marketAddresses,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external view returns (AccountLiquidationAmounts memory);

    /**
     * @notice Sets a new value for healthyFactorLimit
     * @dev RESTRICTION: Timelock only
     */
    function setHealthyFactorLimit(uint256 newValue_) external;

    /**
     * @notice Sets a new minterest deadDrop
     * @dev RESTRICTION: Admin only
     */
    function setDeadDrop(address newDeadDrop_) external;

    /**
     * @notice Sets a new insignificantLoanThreshold
     * @dev RESTRICTION: Timelock only
     */
    function setInsignificantLoanThreshold(uint256 newValue_) external;

    /**
     * @notice Sets a new state for useProcessingState
     * @dev RESTRICTION: Admin only
     */
    function setProcessingStateUsage(bool newValue_) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Minterest InterestRateModel Interface
 * @author Minterest
 */
interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @param protocolInterestFactorMantissa The current protocol interest factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest,
        uint256 protocolInterestFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ILinkageRoot.sol";

interface ILinkageLeaf {
    /**
     * @notice Emitted when root contract address is changed
     */
    event LinkageRootSwitched(ILinkageRoot newRoot, ILinkageRoot oldRoot);

    /**
     * @notice Connects new root contract address
     * @param newRoot New root contract address
     */
    function switchLinkageRoot(ILinkageRoot newRoot) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;
import "./IMToken.sol";

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a mToken asset
     * @param mToken The mToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     *
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getUnderlyingPrice(IMToken mToken) external view returns (uint256);

    /**
     * @notice Return price for an asset
     * @param asset address of token
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

interface ILinkageRoot {
    /**
     * @notice Emitted when new root contract connected to all leafs
     */
    event LinkageRootSwitch(ILinkageRoot newRoot);

    /**
     * @notice Emitted when root interconnects its contracts
     */
    event LinkageRootInterconnected();

    /**
     * @notice Connects new root to all leafs contracts
     * @param newRoot New root contract address
     */
    function switchLinkageRoot(ILinkageRoot newRoot) external;

    /**
     * @notice Update root for all leaf contracts
     * @dev Should include only leaf contracts
     */
    function interconnect() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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