/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

//SPDX-License-Identifier: MIT
// File: https://github.com/jklepatch/eattheblocks/blob/master/screencast/195-compound-leveraged-yield-farming/contracts/IcToken.sol

pragma solidity ^0.8.0;

interface IcToken {
  function mint(uint mintAmount) external returns (uint);
  function redeem(uint redeemTokens) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function balanceOf(address owner) external view returns (uint);
}

// File: https://github.com/jklepatch/eattheblocks/blob/master/screencast/195-compound-leveraged-yield-farming/contracts/Icomptroller.sol


pragma solidity ^0.8.0;

interface Icomptroller {
  function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
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

// File: contracts/yeildFarmer.sol

pragma solidity ^0.8.7;




contract YieldFarmer {
  Icomptroller comptroller;
  IcToken cDai;
  IERC20 dai;
  uint borrowFactor = 70;

  constructor(
    address daiAddress
  )  {
    comptroller = Icomptroller(0x3cBe63aAcF6A064D32072a630A3eab7545C54d78);
    cDai = IcToken(0x0545a8eaF7ff6bB6F708CbB544EA55DBc2ad7b2a);
    dai = IERC20(daiAddress);
    address[] memory cTokens = new address[](1);
    cTokens[0] = 0x0545a8eaF7ff6bB6F708CbB544EA55DBc2ad7b2a; 
    comptroller.enterMarkets(cTokens);
  }

  function openPosition(uint initialAmount) external {
    uint nextCollateralAmount = initialAmount;
    for(uint i = 0; i < 5; i++) {
      nextCollateralAmount = _supplyAndBorrow(nextCollateralAmount);
    }
  }

  function _supplyAndBorrow(uint collateralAmount) internal returns(uint) {
    dai.approve(address(cDai), collateralAmount);
    cDai.mint(collateralAmount);
    uint borrowAmount = (collateralAmount * 70) / 100;
    cDai.borrow(borrowAmount);
    return borrowAmount;
  }

  function closePosition() external {
    uint balanceBorrow = cDai.borrowBalanceCurrent(address(this));
    dai.approve(address(cDai), balanceBorrow);
    cDai.repayBorrow(balanceBorrow);
    uint balancecDai = cDai.balanceOf(address(this));
    cDai.redeem(balancecDai);
  }
}