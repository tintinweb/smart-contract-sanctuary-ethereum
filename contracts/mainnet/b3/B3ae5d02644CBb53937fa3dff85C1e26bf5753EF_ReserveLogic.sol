// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './types/DataTypes.sol';
import './helpers/Errors.sol';
import './math/WadRayMath.sol';
import './math/PercentageMath.sol';

import '../interfaces/IOpenSkyInterestRateStrategy.sol';
import '../interfaces/IOpenSkyOToken.sol';
import '../interfaces/IOpenSkyMoneyMarket.sol';

/**
 * @title ReserveLogic library
 * @author OpenSky Labs
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Implements the deposit feature.
     * @param sender The address that called deposit function
     * @param amount The amount of deposit
     * @param onBehalfOf The address that will receive otokens
     **/
    function deposit(
        DataTypes.ReserveData storage reserve,
        address sender,
        uint256 amount,
        address onBehalfOf
    ) external {
        updateState(reserve, 0);

        updateLastMoneyMarketBalance(reserve, amount, 0);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.mint(onBehalfOf, amount, reserve.lastSupplyIndex);

        IERC20(reserve.underlyingAsset).safeTransferFrom(sender, reserve.oTokenAddress, amount);
        oToken.deposit(amount);
    }

    /**
     * @dev Implements the withdrawal feature.
     * @param sender The address that called withdraw function
     * @param amount The withdrawal amount
     * @param onBehalfOf The address that will receive token
     **/
    function withdraw(
        DataTypes.ReserveData storage reserve,
        address sender,
        uint256 amount,
        address onBehalfOf
    ) external {
        updateState(reserve, 0);

        updateLastMoneyMarketBalance(reserve, 0, amount);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.burn(sender, amount, reserve.lastSupplyIndex);
        oToken.withdraw(amount, onBehalfOf);
    }

    /**
     * @dev Implements the borrow feature.
     * @param loan the loan data
     **/
    function borrow(DataTypes.ReserveData storage reserve, DataTypes.LoanData memory loan) external {
        updateState(reserve, 0);
        updateInterestPerSecond(reserve, loan.interestPerSecond, 0);
        updateLastMoneyMarketBalance(reserve, 0, loan.amount);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.withdraw(loan.amount, msg.sender);

        reserve.totalBorrows = reserve.totalBorrows + loan.amount;
    }

    /**
     * @dev Implements the repay function.
     * @param loan The loan data
     * @param amount The amount that will be repaid, including penalty
     * @param borrowBalance The borrow balance
     **/
    function repay(
        DataTypes.ReserveData storage reserve,
        DataTypes.LoanData memory loan,
        uint256 amount,
        uint256 borrowBalance
    ) external {
        updateState(reserve, amount - borrowBalance);
        updateInterestPerSecond(reserve, 0, loan.interestPerSecond);
        updateLastMoneyMarketBalance(reserve, amount, 0);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);

        IERC20(reserve.underlyingAsset).safeTransferFrom(msg.sender, reserve.oTokenAddress, amount);
        oToken.deposit(amount);

        reserve.totalBorrows = reserve.totalBorrows > borrowBalance ? reserve.totalBorrows - borrowBalance : 0;
    }

    /**
     * @dev Implements the extend feature.
     * @param oldLoan The data of old loan
     * @param newLoan The data of new loan
     * @param borrowInterestOfOldLoan The borrow interest of old loan
     * @param inAmount The amount of token that will be deposited
     * @param outAmount The amount of token that will be withdrawn
     * @param additionalIncome The additional income
     **/
    function extend(
        DataTypes.ReserveData storage reserve,
        DataTypes.LoanData memory oldLoan,
        DataTypes.LoanData memory newLoan,
        uint256 borrowInterestOfOldLoan,
        uint256 inAmount,
        uint256 outAmount,
        uint256 additionalIncome
    ) external {
        updateState(reserve, additionalIncome);
        updateInterestPerSecond(reserve, newLoan.interestPerSecond, oldLoan.interestPerSecond);
        updateLastMoneyMarketBalance(reserve, inAmount, outAmount);

        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        if (inAmount > 0) {
            IERC20(reserve.underlyingAsset).safeTransferFrom(msg.sender, reserve.oTokenAddress, inAmount);
            oToken.deposit(inAmount);
        }
        if (outAmount > 0) oToken.withdraw(outAmount, msg.sender);

        uint256 sum1 = reserve.totalBorrows + newLoan.amount;
        uint256 sum2 = oldLoan.amount + borrowInterestOfOldLoan;
        reserve.totalBorrows = sum1 > sum2 ? sum1 - sum2 : 0;
    }

    /**
     * @dev Implements start liquidation mechanism.
     * @param loan Loan data
     **/
    function startLiquidation(DataTypes.ReserveData storage reserve, DataTypes.LoanData memory loan) external {
        updateState(reserve, 0);
        updateLastMoneyMarketBalance(reserve, 0, 0);
        updateInterestPerSecond(reserve, 0, loan.interestPerSecond);
    }

    /**
     * @dev Implements end liquidation mechanism.
     * @param amount The amount of token paid
     * @param borrowBalance The borrow balance of loan
     **/
    function endLiquidation(
        DataTypes.ReserveData storage reserve,
        uint256 amount,
        uint256 borrowBalance
    ) external {
        updateState(reserve, amount - borrowBalance);
        updateLastMoneyMarketBalance(reserve, amount, 0);

        IERC20(reserve.underlyingAsset).safeTransferFrom(msg.sender, reserve.oTokenAddress, amount);
        IOpenSkyOToken oToken = IOpenSkyOToken(reserve.oTokenAddress);
        oToken.deposit(amount);

        reserve.totalBorrows = reserve.totalBorrows > borrowBalance ? reserve.totalBorrows - borrowBalance : 0;
    }

    /**
     * @dev Updates the liquidity cumulative index and total borrows
     * @param reserve The reserve object
     * @param additionalIncome The additional income
     **/
    function updateState(DataTypes.ReserveData storage reserve, uint256 additionalIncome) internal {
        (
            uint256 newIndex,
            ,
            uint256 treasuryIncome,
            uint256 borrowingInterestDelta,

        ) = calculateIncome(reserve, additionalIncome);

        require(newIndex <= type(uint128).max, Errors.RESERVE_INDEX_OVERFLOW);
        reserve.lastSupplyIndex = uint128(newIndex);

        // treasury
        treasuryIncome = treasuryIncome / WadRayMath.ray();
        if (treasuryIncome > 0) {
            IOpenSkyOToken(reserve.oTokenAddress).mintToTreasury(treasuryIncome, reserve.lastSupplyIndex);
        }

        reserve.totalBorrows = reserve.totalBorrows + borrowingInterestDelta / WadRayMath.ray();
        reserve.lastUpdateTimestamp = uint40(block.timestamp);
    }

    /**
     * @dev Updates the interest per second, when borrowing and repaying
     * @param reserve The reserve object
     * @param amountToAdd The amount to be added
     * @param amountToRemove The amount to be subtracted
     **/
    function updateInterestPerSecond(
        DataTypes.ReserveData storage reserve,
        uint256 amountToAdd,
        uint256 amountToRemove
    ) internal {
        reserve.borrowingInterestPerSecond = reserve.borrowingInterestPerSecond + amountToAdd - amountToRemove;
    }

    /**
     * @dev Updates last money market balance, after updating the liquidity cumulative index.
     * @param reserve The reserve object
     * @param amountToAdd The amount to be added
     * @param amountToRemove The amount to be subtracted
     **/
    function updateLastMoneyMarketBalance(
        DataTypes.ReserveData storage reserve,
        uint256 amountToAdd,
        uint256 amountToRemove
    ) internal {
        uint256 moneyMarketBalance = getMoneyMarketBalance(reserve);
        reserve.lastMoneyMarketBalance = moneyMarketBalance + amountToAdd - amountToRemove;
    }

    function openMoneyMarket(
        DataTypes.ReserveData storage reserve
    ) internal {
        reserve.isMoneyMarketOn = true;

        uint256 amount = IERC20(reserve.underlyingAsset).balanceOf(reserve.oTokenAddress);
        IOpenSkyOToken(reserve.oTokenAddress).deposit(amount);
    }

    function closeMoneyMarket(
        DataTypes.ReserveData storage reserve
    ) internal {
        address oTokenAddress = reserve.oTokenAddress;
        uint256 amount = IOpenSkyMoneyMarket(reserve.moneyMarketAddress).getBalance(reserve.underlyingAsset, oTokenAddress);
        IOpenSkyOToken(oTokenAddress).withdraw(amount, oTokenAddress);

        reserve.isMoneyMarketOn = false;
    }

    /**
     * @dev Updates last money market balance, after updating the liquidity cumulative index.
     * @param reserve The reserve object
     * @param additionalIncome The amount to be added
     * @return newIndex The new liquidity cumulative index from the last update
     * @return usersIncome The user's income from the last update
     * @return treasuryIncome The treasury income from the last update
     * @return borrowingInterestDelta The treasury income from the last update
     * @return moneyMarketDelta The money market income from the last update
     **/
    function calculateIncome(DataTypes.ReserveData memory reserve, uint256 additionalIncome)
        internal
        view
        returns (
            uint256 newIndex,
            uint256 usersIncome,
            uint256 treasuryIncome,
            uint256 borrowingInterestDelta,
            uint256 moneyMarketDelta
        )
    {
        moneyMarketDelta = getMoneyMarketDelta(reserve) * WadRayMath.ray();
        borrowingInterestDelta = getBorrowingInterestDelta(reserve);
        // ray
        uint256 totalIncome = additionalIncome * WadRayMath.ray() + moneyMarketDelta + borrowingInterestDelta;
        treasuryIncome = totalIncome.percentMul(reserve.treasuryFactor);
        usersIncome = totalIncome - treasuryIncome;

        // index
        newIndex = reserve.lastSupplyIndex;
        uint256 scaledTotalSupply = IOpenSkyOToken(reserve.oTokenAddress).scaledTotalSupply();
        if (scaledTotalSupply > 0) {
            newIndex = usersIncome / scaledTotalSupply + reserve.lastSupplyIndex;
        }

        return (newIndex, usersIncome, treasuryIncome, borrowingInterestDelta, moneyMarketDelta);
    }

    /**
     * @dev Returns the ongoing normalized income for the reserve
     * A value of 1e27 means there is no income. As time passes, the income is accrued
     * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
     * @param reserve The reserve object
     * @return The normalized income. expressed in ray
     **/
    function getNormalizedIncome(DataTypes.ReserveData storage reserve) external view returns (uint256) {
        (uint256 newIndex, , , , ) = calculateIncome(reserve, 0);
        return newIndex;
    }

    /**
     * @dev Returns the available liquidity of the reserve
     * @param reserve The reserve object
     * @return The available liquidity
     **/
    function getMoneyMarketBalance(DataTypes.ReserveData memory reserve) internal view returns (uint256) {
        if (reserve.isMoneyMarketOn) {
            return IOpenSkyMoneyMarket(reserve.moneyMarketAddress).getBalance(reserve.underlyingAsset, reserve.oTokenAddress);
        } else {
            return IERC20(reserve.underlyingAsset).balanceOf(reserve.oTokenAddress);
        }
    }

    /**
     * @dev Returns the money market income of the reserve from the last update
     * @param reserve The reserve object
     * @return The income from money market
     **/
    function getMoneyMarketDelta(DataTypes.ReserveData memory reserve) internal view returns (uint256) {
        uint256 timeDelta = block.timestamp - reserve.lastUpdateTimestamp;

        if (timeDelta == 0) return 0;

        if (reserve.lastMoneyMarketBalance == 0) return 0;

        // get MoneyMarketBalance
        uint256 currentMoneyMarketBalance = getMoneyMarketBalance(reserve);
        if (currentMoneyMarketBalance < reserve.lastMoneyMarketBalance) return 0;

        return currentMoneyMarketBalance - reserve.lastMoneyMarketBalance;
    }

    /**
     * @dev Returns the borrow interest income of the reserve from the last update
     * @param reserve The reserve object
     * @return The income from the NFT loan
     **/
    function getBorrowingInterestDelta(DataTypes.ReserveData memory reserve) internal view returns (uint256) {
        uint256 timeDelta = uint256(block.timestamp) - reserve.lastUpdateTimestamp;
        if (timeDelta == 0) return 0;
        return reserve.borrowingInterestPerSecond * timeDelta;
    }

    /**
     * @dev Returns the total borrow balance of the reserve
     * @param reserve The reserve object
     * @return The total borrow balance
     **/
    function getTotalBorrowBalance(DataTypes.ReserveData memory reserve) public view returns (uint256) {
        return reserve.totalBorrows + getBorrowingInterestDelta(reserve) / WadRayMath.ray();
    }

    /**
     * @dev Returns the total value locked (TVL) of the reserve
     * @param reserve The reserve object
     * @return The total value locked (TVL)
     **/
    function getTVL(DataTypes.ReserveData memory reserve) external view returns (uint256) {
        (, , uint256 treasuryIncome, , ) = calculateIncome(reserve, 0);
        return treasuryIncome / WadRayMath.RAY + IOpenSkyOToken(reserve.oTokenAddress).totalSupply();
    }

    /**
     * @dev Returns the borrow rate of the reserve
     * @param reserve The reserve object
     * @param liquidityAmountToAdd The liquidity amount will be added
     * @param liquidityAmountToRemove The liquidity amount will be removed
     * @param borrowAmountToAdd The borrow amount will be added
     * @param borrowAmountToRemove The borrow amount will be removed
     * @return The borrow rate
     **/
    function getBorrowRate(
        DataTypes.ReserveData memory reserve,
        uint256 liquidityAmountToAdd,
        uint256 liquidityAmountToRemove,
        uint256 borrowAmountToAdd,
        uint256 borrowAmountToRemove
    ) external view returns (uint256) {
        uint256 liquidity = getMoneyMarketBalance(reserve);
        uint256 totalBorrowBalance = getTotalBorrowBalance(reserve);
        return
            IOpenSkyInterestRateStrategy(reserve.interestModelAddress).getBorrowRate(
                reserve.reserveId,
                liquidity + totalBorrowBalance + liquidityAmountToAdd - liquidityAmountToRemove,
                totalBorrowBalance + borrowAmountToAdd - borrowAmountToRemove
            );
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
pragma solidity 0.8.10;

library DataTypes {
    struct ReserveData {
        uint256 reserveId;
        address underlyingAsset;
        address oTokenAddress;
        address moneyMarketAddress;
        uint128 lastSupplyIndex;
        uint256 borrowingInterestPerSecond;
        uint256 lastMoneyMarketBalance;
        uint40 lastUpdateTimestamp;
        uint256 totalBorrows;
        address interestModelAddress;
        uint256 treasuryFactor;
        bool isMoneyMarketOn;
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        uint40 borrowBegin;
        uint40 borrowDuration;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        uint40 extendableTime;
        uint40 borrowEnd;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        EXTENDABLE,
        OVERDUE,
        LIQUIDATABLE,
        LIQUIDATING
    }

    struct WhitelistInfo {
        bool enabled;
        string name;
        string symbol;
        uint256 LTV;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 extendableDuration;
        uint256 overdueDuration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Errors {
    // common
    string public constant MATH_MULTIPLICATION_OVERFLOW = '100';
    string public constant MATH_ADDITION_OVERFLOW = '101';
    string public constant MATH_DIVISION_BY_ZERO = '102';

    string public constant ETH_TRANSFER_FAILED = '110';
    string public constant RECEIVE_NOT_ALLOWED = '111';
    string public constant FALLBACK_NOT_ALLOWED = '112';
    string public constant APPROVAL_FAILED = '113';

    // setting/factor
    string public constant SETTING_ZERO_ADDRESS_NOT_ALLOWED = '115';
    string public constant SETTING_RESERVE_FACTOR_NOT_ALLOWED = '116';
    string public constant SETTING_WHITELIST_INVALID_RESERVE_ID = '117';
    string public constant SETTING_WHITELIST_NFT_ADDRESS_IS_ZERO = '118';
    string public constant SETTING_WHITELIST_NFT_DURATION_OUT_OF_ORDER = '119';
    string public constant SETTING_WHITELIST_NFT_NAME_EMPTY = '120';
    string public constant SETTING_WHITELIST_NFT_SYMBOL_EMPTY = '121';
    string public constant SETTING_WHITELIST_NFT_LTV_NOT_ALLOWED = '122';

    // settings/acl
    string public constant ACL_ONLY_GOVERNANCE_CAN_CALL = '200';
    string public constant ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL = '201';
    string public constant ACL_ONLY_POOL_ADMIN_CAN_CALL = '202';
    string public constant ACL_ONLY_LIQUIDATOR_CAN_CALL = '203';
    string public constant ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL = '204';
    string public constant ACL_ONLY_POOL_CAN_CALL = '205';

    // lending & borrowing
    // reserve
    string public constant RESERVE_DOES_NOT_EXIST = '300';
    string public constant RESERVE_LIQUIDITY_INSUFFICIENT = '301';
    string public constant RESERVE_INDEX_OVERFLOW = '302';
    string public constant RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR = '303';
    string public constant RESERVE_TREASURY_FACTOR_NOT_ALLOWED = '304';
    string public constant RESERVE_TOKEN_CAN_NOT_BE_CLAIMED = '305';

    // token
    string public constant AMOUNT_SCALED_IS_ZERO = '310';
    string public constant AMOUNT_TRANSFER_OVERFLOW = '311';

    //deposit
    string public constant DEPOSIT_AMOUNT_SHOULD_BE_BIGGER_THAN_ZERO = '320';

    // withdraw
    string public constant WITHDRAW_AMOUNT_NOT_ALLOWED = '321';
    string public constant WITHDRAW_LIQUIDITY_NOT_SUFFICIENT = '322';

    // borrow
    string public constant BORROW_DURATION_NOT_ALLOWED = '330';
    string public constant BORROW_AMOUNT_EXCEED_BORROW_LIMIT = '331';
    string public constant NFT_ADDRESS_IS_NOT_IN_WHITELIST = '332';

    // repay
    string public constant REPAY_STATUS_ERROR = '333';
    string public constant REPAY_MSG_VALUE_ERROR = '334';

    // extend
    string public constant EXTEND_STATUS_ERROR = '335';
    string public constant EXTEND_MSG_VALUE_ERROR = '336';

    // liquidate
    string public constant START_LIQUIDATION_STATUS_ERROR = '360';
    string public constant END_LIQUIDATION_STATUS_ERROR = '361';
    string public constant END_LIQUIDATION_AMOUNT_ERROR = '362';

    // loan
    string public constant LOAN_DOES_NOT_EXIST = '400';
    string public constant LOAN_SET_STATUS_ERROR = '401';
    string public constant LOAN_REPAYER_IS_NOT_OWNER = '402';
    string public constant LOAN_LIQUIDATING_STATUS_CAN_NOT_BE_UPDATED = '403';
    string public constant LOAN_CALLER_IS_NOT_OWNER = '404';
    string public constant LOAN_COLLATERAL_NFT_CAN_NOT_BE_CLAIMED = '405';

    string public constant FLASHCLAIM_EXECUTOR_ERROR = '410';
    string public constant FLASHCLAIM_STATUS_ERROR = '411';

    // money market
    string public constant MONEY_MARKET_DEPOSIT_AMOUNT_NOT_ALLOWED = '500';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_ALLOWED = '501';
    string public constant MONEY_MARKET_APPROVAL_FAILED = '502';
    string public constant MONEY_MARKET_DELEGATE_CALL_ERROR = '503';
    string public constant MONEY_MARKET_REQUIRE_DELEGATE_CALL = '504';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_MATCH = '505';

    // price oracle
    string public constant PRICE_ORACLE_HAS_NO_PRICE_FEED = '600';
    string public constant PRICE_ORACLE_INCORRECT_TIMESTAMP = '601';
    string public constant PRICE_ORACLE_PARAMS_ERROR = '602';
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Errors} from '../helpers/Errors.sol';

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @return One ray, 1e27
     **/
    function ray() internal pure returns (uint256) {
        return RAY;
    }

    /**
     * @return One wad, 1e18
     **/

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    /**
     * @return Half ray, 1e27/2
     **/
    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    /**
     * @return Half ray, 1e18/2
     **/
    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfWAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * WAD + halfB) / b;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * b + halfRAY) / RAY;
    }

    /**
     * @dev Multiplies two ray, truncating the mantissa
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMulTruncate(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return (a * b) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

        return (a * RAY + halfB) / b;
    }

    /**
     * @dev Divides two ray, truncating the mantissa
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDivTruncate(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        return (a * RAY) / b;
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

        return result / WAD_RAY_RATIO;
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../helpers/Errors.sol';

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfPercentage = percentage / 2;

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title IOpenSkyInterestRateStrategy
 * @author OpenSky Labs
 * @notice Interface for the calculation of the interest rates
 */
interface IOpenSkyInterestRateStrategy {
    /**
     * @dev Emitted on setBaseBorrowRate()
     * @param reserveId The id of the reserve
     * @param baseRate The base rate has been set
     **/
    event SetBaseBorrowRate(
        uint256 indexed reserveId,
        uint256 indexed baseRate
    );

    /**
     * @notice Returns the borrow rate of a reserve
     * @param reserveId The id of the reserve
     * @param totalDeposits The total deposits amount of the reserve
     * @param totalBorrows The total borrows amount of the reserve
     * @return The borrow rate, expressed in ray
     **/
    function getBorrowRate(uint256 reserveId, uint256 totalDeposits, uint256 totalBorrows) external view returns (uint256); 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IOpenSkyOToken is IERC20 {
    event Mint(address indexed account, uint256 amount, uint256 index);
    event Burn(address indexed account, uint256 amount, uint256 index);
    event MintToTreasury(address treasury, uint256 amount, uint256 index);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);

    function mint(
        address account,
        uint256 amount,
        uint256 index
    ) external;

    function burn(
        address account,
        uint256 amount,
        uint256 index
    ) external;

    function mintToTreasury(uint256 amount, uint256 index) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount, address to) external;

    function scaledBalanceOf(address account) external view returns (uint256);

    function principleBalanceOf(address account) external view returns (uint256);

    function scaledTotalSupply() external view returns (uint256);

    function principleTotalSupply() external view returns (uint256);

    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    function claimERC20Rewards(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyMoneyMarket {

    function depositCall(address asset, uint256 amount) external;

    function withdrawCall(address asset, uint256 amount, address to) external;

    function getMoneyMarketToken(address asset) external view returns (address);

    function getBalance(address asset, address account) external view returns (uint256);

    function getSupplyRate(address asset) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

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