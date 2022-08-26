// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function token0() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IERC20 {
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

contract TeachTokenManager {

    address public immutable FACTORY;
    address public immutable WETH;
    address public immutable $TEACH;
    address public immutable ROUTER;
    address public immutable COLD_WALLET;
    // 0x598a008D024cdc94435511b0F337ce4Cf0aA83Ce

    event AddedLiquidity(uint256 amountToken, uint256 amountETH, uint256 liquidity);
    event BoughtTeachToken(address sender, uint256 amountIn, uint256[] amountsOut, string fbId);
    event TrasnferedToGame(uint256 amount, string fbId);

    constructor(address factory_, address router_, address $TEACH_, address weth_, address coldwallet_) public {
      FACTORY = factory_;
      WETH = weth_;
      $TEACH = $TEACH_;
      ROUTER = router_;
      COLD_WALLET = coldwallet_;
    }

    function pairInfo() external view returns (uint reserveA, uint reserveB, uint totalSupply) {
      IUniswapV2Pair pair = IUniswapV2Pair(IUniswapV2Factory(FACTORY).getPair($TEACH, WETH));
      totalSupply = pair.totalSupply();
      (uint reserves0, uint reserves1,) = pair.getReserves();
      (reserveA, reserveB) = $TEACH == pair.token0() ? (reserves0, reserves1) : (reserves1, reserves0);
    }

    function addLiquidity(
        uint teachTokenAmount,
        uint deadline) external payable
    {
      IERC20($TEACH).transferFrom(msg.sender, address(this), teachTokenAmount);
      IERC20($TEACH).approve(ROUTER, teachTokenAmount);

      (uint256 amountToken, uint256 amountETH, uint256 liquidity) = IUniswapV2Router02(ROUTER).addLiquidityETH{
        value: msg.value
      }(
        $TEACH,
        teachTokenAmount,
        1,
        1,
        COLD_WALLET,
        deadline
      );
      
      emit AddedLiquidity(amountToken, amountETH, liquidity);
    }

    function buyTeachToken(uint256 deadline, string calldata fbId)
      external payable
    {
      address[] memory path = new address[](2);
      path[0] = WETH;
      path[1] = $TEACH;
      uint256[] memory amounts = IUniswapV2Router02(ROUTER).swapExactETHForTokens{
        value: msg.value
      }(
        1,
        path,
        COLD_WALLET,
        deadline
      );

      emit BoughtTeachToken(msg.sender, msg.value, amounts, fbId);
    }

    function transferTeachToGame(uint256 amount, string calldata fbId) external {

      IERC20($TEACH).transferFrom(msg.sender, COLD_WALLET, amount);
      emit TrasnferedToGame(amount, fbId);
    }

}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
}