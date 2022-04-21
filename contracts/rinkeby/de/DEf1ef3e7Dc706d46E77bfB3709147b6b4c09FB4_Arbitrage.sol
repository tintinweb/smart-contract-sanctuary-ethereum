pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IKyberNetworkProxy.sol';
import './IUniswap.sol';

contract Arbitrage {
  address kyberAddress = 0x0d5371e5EE23dec7DF251A8957279629aa79E9C5;
  address uniswapAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function runTokenKyberUniswap(
    uint amount, 
    address srcTokenAddress, 
    address dstTokenAddress
  ) onlyOwner() external {
    //Kyber srcToken => dstToken 
    //Uniswap dstToken => srcToken 
    IERC20 srcToken = IERC20(srcTokenAddress);
    IERC20 dstToken = IERC20(dstTokenAddress);
    srcToken.transfer(address(this), amount);

    //Kyber srcToken => dstToken 
    IKyberNetworkProxy kyber = IKyberNetworkProxy(kyberAddress);
    srcToken.approve(address(kyber), amount);
    (uint rate, ) = kyber.getExpectedRate(srcToken, dstToken, amount);
    kyber.swapTokenToToken(srcToken, amount, dstToken, rate);

    //Uniswap dstToken => srcToken 
    IUniswap uniswap = IUniswap(uniswapAddress);
    uint balanceDstToken = dstToken.balanceOf(address(this));
    dstToken.approve(address(uniswap), balanceDstToken);
    address[] memory path = new address[](2);
    path[0] = address(dstToken);
    path[1] = address(srcToken);
    uint[] memory minOuts = uniswap.getAmountsOut(balanceDstToken, path); 
    uniswap.swapExactTokensForTokens(
      balanceDstToken,
      minOuts[0], 
      path, 
      address(this), 
      now
    );
  }

  function runTokenUniswapKyber(uint amount, address srcTokenAddress, address dstTokenAddress) onlyOwner() external {
    //Kyber srcToken => dstToken 
    //Uniswap dstToken => srcToken 
    IERC20 srcToken = IERC20(srcTokenAddress);
    IERC20 dstToken = IERC20(dstTokenAddress);
    srcToken.transfer(address(this), amount);

    //Uniswap srcToken => dstToken 
    IUniswap uniswap = IUniswap(uniswapAddress);
    srcToken.approve(address(uniswap), amount);
    address[] memory path = new address[](2);
    path[0] = address(srcToken);
    path[1] = address(dstToken);
    uint[] memory minOuts = uniswap.getAmountsOut(amount, path); 
    uniswap.swapExactTokensForTokens(
      amount,
      minOuts[0], 
      path, 
      address(this), 
      now
    );

    //Kyber dstToken => srcToken
    IKyberNetworkProxy kyber = IKyberNetworkProxy(kyberAddress);
    uint balanceDstToken = dstToken.balanceOf(address(this));
    srcToken.approve(address(kyber), balanceDstToken);
    (uint rate, ) = kyber.getExpectedRate(dstToken, srcToken, balanceDstToken);
    kyber.swapTokenToToken(dstToken, balanceDstToken, srcToken, rate);
  }

  function withdrawETHAndTokens(address tokenAddress) external onlyOwner() {
    msg.sender.transfer(address(this).balance);
    IERC20 token = IERC20(tokenAddress);
    uint256 currentTokenBalance = token.balanceOf(address(this));
    token.transfer(msg.sender, currentTokenBalance);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'only owner');
    _;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity ^0.6.0;

// Note: Kyber uses it owns ERC20 interface
// See: https://github.com/KyberNetwork/smart-contracts/blob/master/contracts/ERC20Interface.sol
import { IERC20 as ERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKyberNetworkProxy {
    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) external returns(uint);
    function swapEtherToToken(ERC20 token, uint minConversionRate) external payable returns(uint);
    function swapTokenToEther(ERC20 token, uint srcAmount, uint minConversionRate) external returns(uint);
}

pragma solidity ^0.6.0;

interface IUniswap {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}