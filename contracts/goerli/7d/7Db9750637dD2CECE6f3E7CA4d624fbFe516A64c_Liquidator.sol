// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.12;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IVault } from "../interfaces/IVault.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";
import { VaultMath } from "../libraries/VaultMath.sol";
import { GeneralMath } from "../libraries/GeneralMath.sol";

/// @title    Liquidator contract
/// @author   Ithil
/// @notice   Base liquidation contract, can forcefully close base strategy's positions
contract Liquidator is Ownable {
    using SafeERC20 for IERC20;
    using GeneralMath for uint256;

    IERC20 public rewardToken;
    // Token may be released in another moment or can change
    // Double mapping needed
    mapping(address => mapping(address => uint256)) public stakes;
    // maximumStake is always denominated in rewardToken
    uint256 public maximumStake;

    error Liquidator__Not_Enough_Ithil_Allowance(uint256 allowance);
    error Liquidator__Not_Enough_Ithil();
    error Liquidator__Unstaking_Too_Much(uint256 maximum);

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function setMaximumStake(uint256 amount) external onlyOwner {
        maximumStake = amount;
    }

    function setToken(address token) external onlyOwner {
        rewardToken = IERC20(token);
    }

    // Only rewardToken can be staked
    function stake(uint256 amount) external {
        uint256 allowance = rewardToken.allowance(msg.sender, address(this));
        if (rewardToken.balanceOf(msg.sender) < amount) revert Liquidator__Not_Enough_Ithil();
        if (allowance < amount) revert Liquidator__Not_Enough_Ithil_Allowance(allowance);
        stakes[address(rewardToken)][msg.sender] += amount;
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // When the token changes, people must be able to unstake the old one
    function unstake(address token, uint256 amount) external {
        uint256 staked = stakes[token][msg.sender];
        if (staked < amount) revert Liquidator__Unstaking_Too_Much(staked);
        stakes[token][msg.sender] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function liquidateSingle(IStrategy strategy, uint256 positionId) external {
        uint256 reward = rewardPercentage();
        strategy.forcefullyClose(positionId, msg.sender, reward);
    }

    function marginCall(
        IStrategy strategy,
        uint256 positionId,
        uint256 extraMargin
    ) external {
        uint256 reward = rewardPercentage();
        strategy.modifyCollateralAndOwner(positionId, extraMargin, msg.sender, reward);
    }

    function purchaseAssets(
        IStrategy strategy,
        uint256 positionId,
        uint256 price
    ) external {
        uint256 reward = rewardPercentage();
        strategy.transferAllowance(positionId, price, msg.sender, reward);
    }

    // rewardPercentage is computed as of the stakes of rewardTokens
    function rewardPercentage() public view returns (uint256) {
        if (maximumStake > 0) {
            uint256 stakePercentage = (stakes[address(rewardToken)][msg.sender] * VaultMath.RESOLUTION) / maximumStake;
            if (stakePercentage > VaultMath.RESOLUTION) return VaultMath.RESOLUTION;
            else return stakePercentage;
        } else return 0;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.12;

import { VaultState } from "../libraries/VaultState.sol";

/// @title    Interface of Vault contract
/// @author   Ithil
interface IVault {
    /// @notice Checks if a token is supported
    /// @param token the token to check the status against
    function checkWhitelisted(address token) external view;

    /// @notice Get minimum margin data about a specific token
    /// @param token the token to get data from
    function getMinimumMargin(address token) external view returns (uint256);

    /// ==== STAKING ==== ///

    function weth() external view returns (address);

    /// @notice Gets the amount of tokens a user can get back when unstaking
    /// @param token the token to check the claimable amount against
    function claimable(address token) external view returns (uint256);

    /// @notice Add tokens to the vault and updates internal status to register updated claiming powers
    /// @param token the token to deposit
    /// @param amount the amount of tokens to be deposited
    function stake(address token, uint256 amount) external;

    /// @notice Get ETH, wraps them into WETH and adds them to the vault,
    ///         then it updates internal status to register updated claiming powers
    /// @param amount the amount of tokens to be deposited
    function stakeETH(uint256 amount) external payable;

    /// @notice provides liquidity renouncing to the APY, thus effectively boosting the vault
    /// @param token the token to be boosted
    /// @param amount the amount provided
    function boost(address token, uint256 amount) external;

    /// @notice Remove tokens from the vault, and updates internal status to register updated claiming powers
    /// @param token the token to deposit
    /// @param amount the amount of tokens to be withdrawn
    function unstake(address token, uint256 amount) external;

    /// @notice Remove tokens from the vault as boosted amounts
    /// @param token the token to remove
    /// @param amount the amount of tokens to be withdrawn
    function unboost(address token, uint256 amount) external;

    /// @notice Remove WETH from the vault, unwraps them and updates internal status to register updated claiming powers
    /// @param amount the amount of tokens to be withdrawn
    function unstakeETH(uint256 amount) external;

    /// ==== ADMIN ==== ///

    /// @notice Adds a new strategy address to the list
    /// @param strategy the strategy to add
    function addStrategy(address strategy) external;

    /// @notice Removes a strategy address from the list
    /// @param strategy the strategy to remove
    function removeStrategy(address strategy) external;

    /// @notice Locks/unlocks a token
    /// @param status the status to be achieved
    /// @param token the token to apply it to
    function toggleLock(bool status, address token) external;

    /// @notice adds a new supported token
    /// @param token the token to whitelist
    /// @param baseFee the minimum fee
    /// @param fixedFee the constant fee
    /// @param minimumMargin the min margin needed to open a position
    function whitelistToken(
        address token,
        uint256 baseFee,
        uint256 fixedFee,
        uint256 minimumMargin
    ) external;

    /// @notice edits the current min margin for a specific token
    function editMinimumMargin(address token, uint256 minimumMargin) external;

    /// ==== LENDING ==== ///

    /// @notice shows the available balance to borrow in the vault
    /// @param token the token to check
    /// @return available balance
    function balance(address token) external view returns (uint256);

    /// @notice updates state to borrow tokens from the vault
    /// @param token the token to borrow
    /// @param amount the total amount to borrow
    /// @param riskFactor the riskiness of this loan
    /// @param borrower the ultimate requester of the loan
    /// @return interestRate the interest rate calculated for the loan
    function borrow(
        address token,
        uint256 amount,
        uint256 riskFactor,
        address borrower
    ) external returns (uint256 interestRate, uint256 fees);

    /// @notice repays a loan
    /// @param token the token of the loan
    /// @param amount the total amount transfered during the repayment
    /// @param debt the debt of the loan
    /// @param borrower the owner of the loan
    function repay(
        address token,
        uint256 amount,
        uint256 debt,
        uint256 fees,
        uint256 riskFactor,
        address borrower
    ) external;

    /// ==== EVENTS ==== ///

    /// @notice Emitted when the governance changes the min margin requirement for a token
    event MinimumMarginWasUpdated(address indexed token, uint256 minimumMargin);

    /// @notice Emitted when a deposit has been performed
    event Deposit(address indexed user, address indexed token, uint256 amount, uint256 minted);

    /// @notice Emitted when a boost has been performed
    event Boosted(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when a withdrawal has been performed
    event Withdrawal(address indexed user, address indexed token, uint256 amount, uint256 burned);

    /// @notice Emitted when a withdrawal has been performed
    event Unboosted(address indexed user, address indexed token, uint256 amount);

    /// @notice Emitted when the vault has been locked or unlocked
    event VaultLockWasToggled(bool status, address indexed token);

    /// @notice Emitted when a new strategy is added to the vault
    event StrategyWasAdded(address strategy);

    /// @notice Emitted when an existing strategy is removed from the vault
    event StrategyWasRemoved(address strategy);

    /// @notice Emitted when a token is whitelisted
    event TokenWasWhitelisted(address indexed token, uint256 baseFee, uint256 fixedFee, uint256 minimumMargin);

    /// @notice Emitted when a loan is opened and issued
    event LoanTaken(address indexed user, address indexed token, uint256 amount, uint256 baseInterestRate);

    /// @notice Emitted when a loan gets repaid and closed
    event LoanRepaid(address indexed user, address indexed token, uint256 amount);

    /// ==== ERRORS ==== ///

    error Vault__Unsupported_Token(address token);
    error Vault__Token_Already_Supported(address token);
    error Vault__ETH_Callback_Failed();
    error Vault__Restricted_Access();
    error Vault__Insufficient_Funds_Available(address token, uint256 amount, uint256 freeLiquidity);
    error Vault__Locked(address token);
    error Vault__Max_Withdrawal(address user, address token, uint256 amount, uint256 maxWithdrawal);
    error Vault__Null_Amount();
    error Vault__Insufficient_ETH(uint256 value, uint256 amount);
    error Vault__ETH_Unstake_Failed(bytes data);
    error Vault__Only_Guardian();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.12;

/// @title    Interface of the parent Strategy contract
/// @author   Ithil
interface IStrategy {
    /// @param spentToken the token we spend to enter the investment
    /// @param obtainedToken the token obtained as result of the investment
    /// @param collateral the amount of tokens to reserve as collateral
    /// @param collateralIsSpentToken if true collateral is in spentToken,
    //                                if false it is in obtainedToken
    /// @param minObtained the min amount of obtainedToken to obtain
    /// @param maxSpent the max amount of spentToken to spend
    /// @param deadline this order must be executed before deadline
    struct Order {
        address spentToken;
        address obtainedToken;
        uint256 collateral;
        bool collateralIsSpentToken;
        uint256 minObtained;
        uint256 maxSpent;
        uint256 deadline;
    }

    /// @param owner the account who opened the position
    /// @param owedToken the token which must be repayed to the vault
    /// @param heldToken the token held in the strategy as investment effect
    /// @param collateralToken the token used as collateral
    /// @param collateral the amount of tokens used as collateral
    /// @param principal the amount of borrowed tokens on which the interests are calculated
    /// @param allowance the amount of heldToken obtained at the moment the position is opened
    ///                  (without reflections)
    /// @param interestRate the interest rate paid on the loan
    /// @param fees the fees generated by the position so far
    /// @param createdAt the date and time in unix epoch when the position was opened
    struct Position {
        address owedToken;
        address heldToken;
        address collateralToken;
        uint256 collateral;
        uint256 principal;
        uint256 allowance;
        uint256 interestRate;
        uint256 fees;
        uint256 createdAt;
    }

    /// @notice obtain the position at particular id
    /// @param positionId the id of the position
    function getPosition(uint256 positionId) external view returns (Position memory);

    /// @notice open a position by borrowing from the vault and executing external contract calls
    /// @param order the structure with the order parameters
    function openPosition(Order calldata order) external returns (uint256);

    /// @notice close the position and repays the vault and the user
    /// @param positionId the id of the position to be closed
    /// @param maxOrMin depending on the Position structure, either the maximum amount to spend,
    ///                 or the minimum amount obtained while closing the position
    function closePosition(uint256 positionId, uint256 maxOrMin) external;

    /// @notice function allowing the position's owner to top up the position's collateral
    /// @param positionId the id of the position to be modified
    /// @param topUp the extra collateral to be transferred
    function editPosition(uint256 positionId, uint256 topUp) external;

    /// @notice gives the amount of destination tokens the external protocol
    ///         would produce by spending an amount of source token
    /// @param src the token to give to the external strategy
    /// @param dst the token expected from the external strategy
    /// @param amount the amount of src tokens to be given
    function quote(
        address src,
        address dst,
        uint256 amount
    ) external view returns (uint256, uint256);

    /// @notice liquidation method: forcefully close a position and repays the vault and the liquidator
    /// @param positionId the id of the position to be closed
    /// @param liquidatorUser the address of the user performing the liquidation
    /// @param reward the liquidator's reward ratio
    function forcefullyClose(
        uint256 positionId,
        address liquidatorUser,
        uint256 reward
    ) external;

    /// @notice liquidation method: transfers the allowance to the liquidator after
    ///         the liquidator repays the debt with the vault
    /// @param positionId the id of the position to be closed
    /// @param price the amount transferred to the vault by the liquidator
    /// @param liquidatorUser the address of the user performing the liquidation
    /// @param reward the liquidator's reward ratio
    function transferAllowance(
        uint256 positionId,
        uint256 price,
        address liquidatorUser,
        uint256 reward
    ) external;

    /// @notice liquidation method: tops up the collateral of a position and transfers its ownership
    ///         to the liquidator
    /// @param positionId the id of the position to be transferred
    /// @param newCollateral the amount extra collateral transferred to the vault by the liquidator
    /// @param liquidatorUser the address of the user performing the liquidation
    /// @param reward the liquidator's reward ratio
    function modifyCollateralAndOwner(
        uint256 positionId,
        uint256 newCollateral,
        address liquidatorUser,
        uint256 reward
    ) external;

    /// @notice computes the risk factor of the token pair, from the individual risk factors
    /// @param token0 first token of the pair
    /// @param token1 second token of the pair
    function computePairRiskFactor(address token0, address token1) external view returns (uint256);

    /// ==== EVENTS ==== ///

    /// @notice Emitted when a new position has been opened
    event PositionWasOpened(
        uint256 indexed id,
        address indexed owner,
        address owedToken,
        address heldToken,
        address collateralToken,
        uint256 collateral,
        uint256 principal,
        uint256 allowance,
        uint256 interestRate,
        uint256 fees,
        uint256 createdAt
    );

    /// @notice Emitted when a position is closed
    event PositionWasClosed(uint256 indexed id, uint256 amountIn, uint256 amountOut, uint256 fees);

    /// @notice Emitted when a position is liquidated
    event PositionWasLiquidated(uint256 indexed id);

    /// @notice Emitted when the strategy lock toggle is changes
    event StrategyLockWasToggled(bool newLockStatus);

    /// @notice Emitted when the risk factor for a specific token is changed
    event RiskFactorWasUpdated(address indexed token, uint256 newRiskFactor);

    /// ==== ERRORS ==== ///

    error Strategy__Order_Expired(uint256 timestamp, uint256 deadline);
    error Strategy__Source_Eq_Dest(address token);
    error Strategy__Insufficient_Collateral(uint256 collateral);
    error Strategy__Restricted_Access(address owner, address sender);
    error Strategy__Action_Throttled();
    error Strategy__Maximum_Leverage_Exceeded(uint256 interestRate);
    error Strategy__Insufficient_Amount_Out(uint256 amountIn, uint256 minAmountOut);
    error Strategy__Loan_Not_Repaid(uint256 repaid, uint256 debt);
    error Strategy__Only_Liquidator(address sender, address liquidator);
    error Strategy__Position_Not_Liquidable(uint256 id, int256 score);
    error Strategy__Margin_Below_Minimum(uint256 marginProvider, uint256 minimumMargin);
    error Strategy__Insufficient_Margin_Provided(int256 newScore);
    error Strategy__Not_Enough_Liquidity(uint256 balance, uint256 amount);
    error Strategy__Locked();
    error Strategy__Only_Guardian();
    error Strategy__Incorrect_Obtained_Token();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.12;

import { VaultState } from "./VaultState.sol";
import { GeneralMath } from "./GeneralMath.sol";

/// @title    VaultMath library
/// @author   Ithil
/// @notice   A library to calculate vault-related stuff, like APY, lending interests, max withdrawable tokens
library VaultMath {
    using GeneralMath for uint256;

    uint24 internal constant RESOLUTION = 10000;
    uint24 internal constant TIME_FEE_PERIOD = 86400;
    uint24 internal constant MAX_RATE = 500;

    /// @notice Computes the maximum amount of money an investor can withdraw from the pool
    /// @dev Floor(x+y) >= Floor(x) + Floor(y), therefore the sum of all investors'
    /// withdrawals cannot exceed total liquidity
    function maximumWithdrawal(
        uint256 claimingPower,
        uint256 totalClaimingPower,
        uint256 totalBalance
    ) internal pure returns (uint256 maxWithdraw) {
        if (claimingPower <= 0) {
            maxWithdraw = 0;
        } else {
            maxWithdraw = (claimingPower * totalBalance) / totalClaimingPower;
        }
    }

    /// @notice Computes the amount of wrapped token to burn from a staker
    function shareValue(
        uint256 amount,
        uint256 totalSupply,
        uint256 totalBalance
    ) internal pure returns (uint256) {
        return (totalBalance != 0 && totalSupply != 0) ? (totalSupply * amount) / totalBalance : amount;
    }

    function computeTimeFees(
        uint256 principal,
        uint256 interestRate,
        uint256 time
    ) internal pure returns (uint256 dueFees) {
        return (principal * interestRate * time) / (uint32(TIME_FEE_PERIOD) * RESOLUTION);
    }

    /// @notice Computes the interest rate to apply to a position at its opening
    /// @param netLoans the net loans of the vault
    /// @param freeLiquidity the free liquidity of the vault
    /// @param insuranceReserveBalance the insurance reserve balance
    /// @param riskFactor the riskiness of the investment
    /// @param baseFee the base fee of the investment
    function computeInterestRateNoLeverage(
        uint256 netLoans,
        uint256 freeLiquidity,
        uint256 insuranceReserveBalance,
        uint256 riskFactor,
        uint256 baseFee
    ) internal pure returns (uint256 interestRate) {
        uint256 uncovered = netLoans.positiveSub(insuranceReserveBalance);
        interestRate = (netLoans + uncovered) * riskFactor;
        interestRate /= (netLoans + freeLiquidity);
        interestRate += baseFee;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.12;

import { VaultState } from "./VaultState.sol";

/// @title    GeneralMath library
/// @author   Ithil
/// @notice   A library to perform the most common math operations
library GeneralMath {
    function positiveSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a > b) c = a - b;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.12;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { GeneralMath } from "./GeneralMath.sol";
import { VaultMath } from "./VaultMath.sol";

/// @title    VaultState library
/// @author   Ithil
/// @notice   A library to store the vault status
library VaultState {
    using SafeERC20 for IERC20;
    using GeneralMath for uint256;

    error Vault__Insufficient_Free_Liquidity(address token, uint256 requested, uint256 freeLiquidity);
    error Vault__Repay_Failed();

    uint256 internal constant DEGRADATION_COEFFICIENT = 21600; // six hours

    /// @notice store data about whitelisted tokens
    /// @param supported Easily check if a token is supported or not (null VaultData struct)
    /// @param locked Whether the token is locked - can only be withdrawn
    /// @param wrappedToken Address of the corresponding WrappedToken
    /// @param creationTime block timestamp of the subvault and relative WrappedToken creation
    /// @param baseFee
    /// @param fixedFee
    /// @param minimumMargin The minimum margin needed to open a position
    /// @param netLoans Total amount of liquidity currently lent to traders
    /// @param insuranceReserveBalance Total amount of liquidity left as insurance
    /// @param optimalRatio The optimal ratio of the insurance reserve
    /// @param treasuryLiquidity The amount of liquidity owned by the treasury
    struct VaultData {
        bool supported;
        bool locked;
        address wrappedToken;
        uint256 creationTime;
        uint256 baseFee;
        uint256 fixedFee;
        uint256 minimumMargin;
        uint256 boostedAmount;
        uint256 netLoans;
        uint256 insuranceReserveBalance;
        uint256 optimalRatio;
        uint256 latestRepay;
        uint256 currentProfits;
    }

    function addInsuranceReserve(
        VaultState.VaultData storage self,
        uint256 totalBalance,
        uint256 fees
    ) internal returns (uint256 insurancePortion) {
        uint256 availableInsuranceBalance = self.insuranceReserveBalance.positiveSub(self.netLoans);
        insurancePortion =
            (fees * self.optimalRatio * (totalBalance - availableInsuranceBalance)) /
            (totalBalance * VaultMath.RESOLUTION);
        self.insuranceReserveBalance += insurancePortion;
    }

    function takeLoan(
        VaultState.VaultData storage self,
        IERC20 token,
        uint256 amount,
        uint256 riskFactor
    ) internal returns (uint256 freeLiquidity) {
        uint256 totalRisk = self.optimalRatio * self.netLoans;
        self.netLoans += amount;
        self.optimalRatio = (totalRisk + amount * riskFactor) / self.netLoans;

        freeLiquidity = IERC20(token).balanceOf(address(this)) - self.insuranceReserveBalance;

        if (amount > freeLiquidity) revert Vault__Insufficient_Free_Liquidity(address(token), amount, freeLiquidity);

        token.safeTransfer(msg.sender, amount);
    }

    function subtractLoan(VaultState.VaultData storage self, uint256 b) private {
        if (self.netLoans > b) self.netLoans -= b;
        else self.netLoans = 0;
    }

    function subtractInsuranceReserve(VaultState.VaultData storage self, uint256 b) private {
        self.insuranceReserveBalance = self.insuranceReserveBalance.positiveSub(b);
    }

    function repayLoan(
        VaultState.VaultData storage self,
        IERC20 token,
        address borrower,
        uint256 debt,
        uint256 fees,
        uint256 amount,
        uint256 riskFactor
    ) internal {
        uint256 totalRisk = self.optimalRatio * self.netLoans;
        subtractLoan(self, debt);
        self.optimalRatio = self.netLoans != 0 ? totalRisk.positiveSub(riskFactor * debt) / self.netLoans : 0;
        if (amount >= debt + fees) {
            uint256 insurancePortion = addInsuranceReserve(self, token.balanceOf(address(this)), fees);
            self.currentProfits = calculateLockedProfit(self) + fees - insurancePortion;
            self.latestRepay = block.timestamp;

            if (!token.transfer(borrower, amount - debt - fees)) revert Vault__Repay_Failed();
        } else {
            // Bad liquidation: rewards the liquidator with 5% of the amountIn
            // amount is already adjusted in BaseStrategy
            if (amount < debt) subtractInsuranceReserve(self, debt - amount);
            if (!token.transfer(borrower, amount / 19)) revert Vault__Repay_Failed();
        }
    }

    function calculateLockedProfit(VaultState.VaultData memory self) internal view returns (uint256) {
        uint256 profits = self.currentProfits;
        return profits.positiveSub(((block.timestamp - self.latestRepay) * profits) / DEGRADATION_COEFFICIENT);
    }
}