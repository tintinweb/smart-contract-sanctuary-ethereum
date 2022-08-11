/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/interface/compound.sol

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

// File: contracts/CompoundLiquidator.sol

pragma solidity 0.8.15;


contract CompoundBorrow {
    Comptroller public comptroller =
    Comptroller(0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152);

    PriceFeed public priceFeed = PriceFeed(0x7BBF806F69ea21Ea9B8Af061AD0C1c41913063A1);

    IERC20 public tokenSupply;
    CErc20 public cTokenSupply;
    IERC20 public tokenBorrow;
    CErc20 public cTokenBorrow;

    event Log(string message, uint val);

    constructor(
        address _tokenSupply,
        address _cTokenSupply,
        address _tokenBorrow,
        address _cTokenBorrow
    ) {
        tokenSupply = IERC20(_tokenSupply);
        cTokenSupply = CErc20(_cTokenSupply);

        tokenBorrow = IERC20(_tokenBorrow);
        cTokenBorrow = CErc20(_cTokenBorrow);
    }

    function supply(uint _amount) external {
        tokenSupply.transferFrom(msg.sender, address(this), _amount);
        tokenSupply.approve(address(cTokenSupply), _amount);
        require(cTokenSupply.mint(_amount) == 0, "mint failed");
    }

    // not view function
    function getSupplyBalance() external returns (uint) {
        return cTokenSupply.balanceOfUnderlying(address(this));
    }

    function getCollateralFactor() external view returns (uint) {
        (, uint colFactor, ) = comptroller.markets(address(cTokenSupply));
        return colFactor; // divide by 1e18 to get in %
    }

    function getAccountLiquidity()
    external
    view
    returns (uint liquidity, uint shortfall)
    {
        // liquidity and shortfall in USD scaled up by 1e18
        (uint error, uint _liquidity, uint _shortfall) = comptroller.getAccountLiquidity(
            address(this)
        );
        require(error == 0, "error");
        return (_liquidity, _shortfall);
    }

    function getPriceFeed(address _cToken) external view returns (uint) {
        // scaled up by 1e18
        return priceFeed.getUnderlyingPrice(_cToken);
    }

    function enterMarket() external {
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cTokenSupply);
        uint[] memory errors = comptroller.enterMarkets(cTokens);
        require(errors[0] == 0, "Comptroller.enterMarkets failed.");
    }

    function borrow(uint _amount) external {
        require(cTokenBorrow.borrow(_amount) == 0, "borrow failed");
    }

    // not view function
    function getBorrowBalance() public returns (uint) {
        return cTokenBorrow.borrowBalanceCurrent(address(this));
    }
}


contract CompoundLiquidator {
    Comptroller public comptroller = Comptroller(0xcfa7b0e37f5AC60f3ae25226F5e39ec59AD26152);

    IERC20 public token;
    CErc20 public cToken;
    constructor(address _token, address _cToken){
        token = IERC20(_token);
        cToken = CErc20(_cToken);
    }

    // close factor
    function getCloseFactor() external view returns (uint) {
        return comptroller.closeFactorMantissa();
    }

    // liquidation incentive
    function getLiquidationIncentive() external view returns (uint) {
        return comptroller.liquidationIncentiveMantissa();
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

    // liquidate
    function liquidate(
        address _borrower,
        uint _repayAmount,
        address _cTokenCollateral
    ) external {
        token.transferFrom(msg.sender, address(this), _repayAmount);
        token.approve(address(cToken), _repayAmount);

        require(
            cToken.liquidateBorrow(_borrower, _repayAmount, _cTokenCollateral) == 0,
            "liquidate failed"
        );
    }

    // get amount liquidated
    // not view function
    function getSupplyBalance(address _cTokenCollateral) external returns (uint) {
        return CErc20(_cTokenCollateral).balanceOfUnderlying(address(this));
    }
}