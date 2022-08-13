/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface CErc20 {
  function balanceOf(address) external view returns (uint);

  function mint(uint) external returns (uint);

  function exchangeRateCurrent() external returns (uint);

  function supplyRatePerBlock() external returns (uint);

  function balanceOfUnderlying(address) external returns (uint);

  function redeem(uint) external returns (uint);

  function redeemUnderlying(uint) external returns (uint);

  function borrow(uint) external returns (uint);

  function borrowBalanceCurrent(address) external returns (uint);

  function borrowRatePerBlock() external view returns (uint);

  function repayBorrow(uint) external returns (uint);

  function liquidateBorrow(
    address borrower,
    uint amount,
    address collateral
  ) external returns (uint);
}

interface CEth {
  function balanceOf(address) external view returns (uint);

  function mint() external payable;

  function exchangeRateCurrent() external returns (uint);

  function supplyRatePerBlock() external returns (uint);

  function balanceOfUnderlying(address) external returns (uint);

  function redeem(uint) external returns (uint);

  function redeemUnderlying(uint) external returns (uint);

  function borrow(uint) external returns (uint);

  function borrowBalanceCurrent(address) external returns (uint);

  function borrowRatePerBlock() external view returns (uint);

  function repayBorrow() external payable;
}

interface Comptroller {
  function markets(address)
    external
    view
    returns (
      bool,
      uint,
      bool
    );

  function enterMarkets(address[] calldata) external returns (uint[] memory);

  function getAccountLiquidity(address)
    external
    view
    returns (
      uint,
      uint,
      uint
    );

  function closeFactorMantissa() external view returns (uint);

  function liquidationIncentiveMantissa() external view returns (uint);

  function liquidateCalculateSeizeTokens(
    address cTokenBorrowed,
    address cTokenCollateral,
    uint actualRepayAmount
  ) external view returns (uint, uint);
}

interface PriceFeed {
  function getUnderlyingPrice(address cToken) external view returns (uint);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/AutoLiq.sol

pragma solidity 0.8.15;



contract AutoLiq {

    Comptroller public comptroller = Comptroller(0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152);

    IERC20 public token;
    CErc20 public cToken;
    address public borrower;


    event Log(address message, uint amount);


    constructor(address _token, address _cToken, address _borrower){
        token = IERC20(_token);
        cToken = CErc20(_cToken);
        borrower = _borrower;
    }

    function getBorrowBalance() external returns (uint) {
        return cToken.borrowBalanceCurrent(borrower);
    }

    // close factor
    function getCloseFactor() external view returns (uint) {
        return comptroller.closeFactorMantissa();
    }

    // liquidation incentive
    function getLiquidationIncentive() external view returns (uint) {
        return comptroller.liquidationIncentiveMantissa();
    }

    // transFrom
    function transferFrom(uint repayAmount) external {
        token.transferFrom(msg.sender, address(this), repayAmount);
    }

    // approve
    function approveToCompound(uint repayAmount) external {
        token.approve(address(cToken), repayAmount);
        emit Log(address(cToken), repayAmount );
    }

    // autoLiquidate
    function liquidate(uint repayAmount, address _cTokenCollateral) external returns (uint){
        uint code = cToken.liquidateBorrow(borrower, repayAmount, _cTokenCollateral);
//        require(
//            code == 0,
//            "liquidate failed"
//        );
        return code;
    }

    function getAccountLiquidity()
    external
    view
    returns (uint liquidity, uint shortfall)
    {
        // liquidity and shortfall in USD scaled up by 1e18
        (uint error, uint _liquidity, uint _shortfall) = comptroller.getAccountLiquidity(
            borrower
        );
        require(error == 0, "error");
        return (_liquidity, _shortfall);
    }


    // get amount of collateral to be liquidated
    function getAmountToBeLiquidated(
        address _cTokenBorrowed,
        address _cTokenCollateral,
        uint _actualRepayAmount
    ) external view returns (uint) {
        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        (uint error, uint cTokenCollateralAmount) = comptroller
        .liquidateCalculateSeizeTokens(
            _cTokenBorrowed,
            _cTokenCollateral,
            _actualRepayAmount
        );

        require(error == 0, "error");

        return cTokenCollateralAmount;
    }

    // autoLiquidate
    function autoLiquidate(address _cTokenCollateral) external {
        uint closeFactor = this.getCloseFactor();
        uint repayAmount = this.getBorrowBalance() * closeFactor / (10 ** 18);

        token.transferFrom(msg.sender, address(this), repayAmount);
        token.approve(address(cToken), repayAmount);

        require(
            cToken.liquidateBorrow(borrower, repayAmount, _cTokenCollateral) == 0,
            "liquidate failed"
        );
    }
}