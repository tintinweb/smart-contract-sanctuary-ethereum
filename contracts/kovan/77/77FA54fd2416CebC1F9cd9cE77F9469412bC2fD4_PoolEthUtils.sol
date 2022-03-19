// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '../interfaces/IWETH9.sol';
import '../interfaces/IPool.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

contract PoolEthUtils {
    IWETH9 public immutable weth;

    constructor(address _weth) {
        weth = IWETH9(_weth);
    }

    function depositEthAsCollateralToPool(address _pool) external payable {
        _toWETHAndApprove(_pool, msg.value);
        IPool(_pool).depositCollateral(msg.value, false);
    }

    function addEthCollateralInMarginCall(address _pool, address _lender) external payable {
        _toWETHAndApprove(_pool, msg.value);
        IPool(_pool).addCollateralInMarginCall(_lender, msg.value, false);
    }

    function ethLend(
        address _pool,
        address _lender,
        address _strategy
    ) external payable {
        _toWETHAndApprove(_pool, msg.value);
        IPool(_pool).lend(_lender, msg.value, _strategy, false);
    }

    function _toWETHAndApprove(address _address, uint256 _amount) internal {
        weth.deposit{value: _amount}();
        weth.approve(_address, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IPool {
    enum LoanStatus {
        COLLECTION, //denotes collection period
        ACTIVE, // denotes the active loan
        CLOSED, // Loan is repaid and closed
        CANCELLED, // Cancelled by borrower
        DEFAULTED, // Repaymennt defaulted by  borrower
        TERMINATED // Pool terminated by admin
    }
    /**
     * @notice Emitted when pool is cancelled either on borrower request or insufficient funds collected
     */
    event PoolCancelled();

    /**
     * @notice Emitted when pool is terminated by admin
     */
    event PoolTerminated();

    /**
     * @notice Emitted when pool is closed after repayments are complete
     */
    event PoolClosed();

    /**
     * @notice emitted when borrower posts collateral
     * @param borrower address of the borrower
     * @param amount amount denominated in collateral asset
     * @param sharesReceived shares received after transferring collaterla to pool savings strategy
     */
    event CollateralAdded(address indexed borrower, uint256 amount, uint256 sharesReceived);

    /**
     * @notice emitted when borrower posts collateral after a margin call
     * @param borrower address of the borrower
     * @param lender lender who margin called
     * @param amount amount denominated in collateral asset
     * @param sharesReceived shares received after transferring collaterla to pool savings strategy
     */
    event MarginCallCollateralAdded(address indexed borrower, address indexed lender, uint256 amount, uint256 sharesReceived);

    /**
     * @notice emitted when borrower withdraws excess collateral
     * @param borrower address of borrower
     * @param amount amount of collateral withdrawn
     */
    event CollateralWithdrawn(address indexed borrower, uint256 amount);

    /**
     * @notice emitted when lender supplies liquidity to a pool
     * @param amountSupplied amount that was supplied
     * @param lenderAddress address of the lender. allows for delegation of lending
     */
    event LiquiditySupplied(uint256 amountSupplied, address indexed lenderAddress);

    /**
     * @notice emitted when borrower withdraws loan
     * @param amount tokens the borrower withdrew, taking into account the deducted protocol fee
     * @param protocolFee protocol fee deducted when borrower withdrew the amount
     */
    event AmountBorrowed(uint256 amount, uint256 protocolFee);

    /**
     * @notice emitted when lender withdraws from borrow pool
     * @param amount amount that lender withdraws from borrow pool
     * @param lenderAddress address to which amount is withdrawn
     */
    event LiquidityWithdrawn(uint256 amount, address indexed lenderAddress);

    /**
     * @notice emitted when lender exercises a margin/collateral call
     * @param lenderAddress address of the lender who exercises margin calls
     */
    event MarginCalled(address indexed lenderAddress);

    /**
     * @notice emitted when collateral backing lender is liquidated because of a margin call
     * @param liquidator address that calls the liquidateForLender() function
     * @param lender lender who initially exercised the margin call
     * @param _tokenReceived amount received by liquidator denominated in collateral asset
     */
    event LenderLiquidated(address indexed liquidator, address indexed lender, uint256 _tokenReceived);

    /**
     * @notice emitted when a pool is liquidated for missing repayment
     * @param liquidator address of the liquidator
     */
    event PoolLiquidated(address indexed liquidator);

    function getLoanStatus() external view returns (uint256 loanStatus);

    function depositCollateral(uint256 _amount, bool _transferFromSavingsAccount) external;

    function addCollateralInMarginCall(
        address _lender,
        uint256 _amount,
        bool _isDirect
    ) external;

    function withdrawBorrowedAmount() external;

    function borrower() external returns (address poolBorrower);

    function getMarginCallEndTime(address _lender) external returns (uint256 marginCallEndTimeForLender);

    function getBalanceDetails(address _lender) external view returns (uint256 lenderPoolTokens, uint256 totalPoolTokens);

    function totalSupply() external view returns (uint256 totalPoolTokens);

    function closeLoan() external;

    function initialize(
        uint256 _borrowAmountRequested,
        uint256 _borrowRate,
        address _borrower,
        address _borrowAsset,
        address _collateralAsset,
        uint256 _idealCollateralRatio,
        uint64 _repaymentInterval,
        uint64 _noOfRepaymentIntervals,
        address _poolSavingsStrategy,
        uint256 _collateralAmount,
        bool _transferFromSavingsAccount,
        address _lenderVerifier,
        uint256 _loanWithdrawalDuration,
        uint256 _collectionPeriod
    ) external;

    function lend(
        address _lender,
        uint256 _amount,
        address _strategy,
        bool _fromSavingsAccount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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