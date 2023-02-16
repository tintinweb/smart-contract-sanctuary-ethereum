// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./interface/IUniswapV2Router02.sol";

contract BuyBack {
  address triflex;
  uint256 minBnbContractBalance;
  address constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  IUniswapV2Router02 public swapRouter;

  mapping (address => uint256) private wards;

  event BoughtAndBurned(uint256 ethValueBurned);

  modifier auth {
    require(wards[msg.sender] == 1, "BuyBack: not-authorized");
    _;
  }

  constructor(address _triflex){
    require(_triflex != address(0), "BuyBack: No null address");
    swapRouter = IUniswapV2Router02(UNISWAP_V2_ROUTER);
    wards[msg.sender] = 1;
    triflex = _triflex;
    minBnbContractBalance = 1 * 10**17; //.1
  }

  function rely(address usr) external auth {
    wards[usr] = 1;
  }

  function deny(address usr) external auth {
    wards[usr] = 0;
  }

  function isAuth(address account) external view returns(uint256){
    return wards[account];
  }

  function setTriflexAddress(address _triflex) external auth {
    require(_triflex != address(0), "BuyBack: No null address");
    triflex = _triflex;
  }

  function setMinBnbAmount(uint256 _minBnbContractBalance) external auth {
    minBnbContractBalance = _minBnbContractBalance;
  }

  receive() external payable {
    buyBackAndBurn();
  }

  function buyBackAndBurn() private {
    if(triflex != address(0) && address(this).balance >= minBnbContractBalance){
      address[] memory path = new address[](2);
      path[0] = swapRouter.WETH();
      path[1] = address(triflex);

      uint256 ethAmount = address(this).balance;

      swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
        1,
        path,
        address(0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD),
        block.timestamp
      );
      emit BoughtAndBurned(ethAmount);
    }
  }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./IUniswapV2Router01.sol";

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

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