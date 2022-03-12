/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma abicoder v2;

interface IUniswapV2Router02 {
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

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract SushiswapTest {
  address private constant ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
  IUniswapV2Router02 public constant uniswapRouter = IUniswapV2Router02(ROUTER);
  address private constant WETH9 = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  

    // function swapTokensForExactTokens(
    //     uint amountOut,
    //     uint amountInMax,
    //     address[] calldata path,
    //     address to,
    //     uint deadline
    // ) external returns (uint[] memory amounts);
   
    
  function swap(address token_in, address token_out, uint amountIn) external {
    require(amountIn > 0, "Must pass non 0 ETH amount");

    uint amountOutMin = 0;
    address[] memory path = new address[](2);
    path[0]=token_in;
    path[1]=token_out;
    address to = msg.sender;
    uint256 deadline = block.timestamp + 15;

    //TransferHelper.safeTransferFrom(token_in, msg.sender, address(this), amountIn);
    //TransferHelper.safeApprove(token_in, address(uniswapRouter), amountIn);
    IERC20(token_in).transferFrom(msg.sender, address(this), amountIn);
    IERC20(token_in).approve(ROUTER, amountIn);

    uniswapRouter.swapExactTokensForTokens(
        amountIn,
        amountOutMin,
        path,
        to,
        deadline
    );
  }

  function swapToETH(address token_in, uint amountIn) external {
    require(amountIn > 0, "Must pass non 0 token amount");
    uint amountOutMin = 0;
    address[] memory path = new address[](2);
    path[0] = token_in;
    path[1] = WETH9;
    address to = msg.sender;
    uint256 deadline = block.timestamp + 15;
    IERC20(token_in).transferFrom(msg.sender, address(this), amountIn);
    IERC20(token_in).approve(ROUTER, amountIn);
    

    uniswapRouter.swapExactTokensForETH(
      amountIn, 
      amountOutMin, 
      path, 
      to,
      deadline);
  }

    //TransferHelper.safeTransferFrom(token_in, msg.sender, address(this), amountIn);
    //TransferHelper.safeApprove(token_in, address(uniswapRouter), amountIn);

    //first we need to transfer the amount in tokens from the msg.sender to this contract
    //this contract will have the amount of in tokens
    
    
    //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
    //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
    

    // IERC20Uniswap token = IERC20Uniswap(token_in);
    // require(token.balanceOf(msg.sender)>= amountIn, 'you dont have enough balance');
    // require(token.transferFrom(msg.sender, address(this), amountIn),'vida hpta');
    // require(token.balanceOf(address(this))>= amountIn, 'this smart contract hasnt have enough balance');
    // require(token.approve(ROUTER, amountIn),'vida hpta 2');
        
    

  function swapTokensForExactETH(uint amountOut, uint amountInMax, address token_in) external returns (uint[] memory amounts){
    require(amountOut > 0, "Must pass non 0 token amount");
    address[] memory path = new address[](2);
    path[0] = token_in;
    path[1] = WETH9;
    address to = msg.sender;
    uint256 deadline = block.timestamp + 15;

    // IERC20Uniswap token = IERC20Uniswap(token_in);
    // require(token.transferFrom(to, address(this), amountOut),'vida hpta');
    // require(token.balanceOf(address(this))>= amountOut, 'el balance no da mk');
    // require(token.approve(ROUTER, amountOut),'vida hpta 2');
    IERC20(token_in).transferFrom(msg.sender, address(this), amountOut);
    IERC20(token_in).approve(ROUTER, amountOut);

    return uniswapRouter.swapTokensForExactETH(amountOut, amountInMax, path, to, deadline);
  }

  function swapFromExactETH(address token_out) external payable {
    require(msg.value > 0, "Must pass non 0 ETH amount");
    uint amountOutMin = 1;
    address[] memory path = new address[](2);
    path[0]=WETH9;
    path[1]=token_out;
    address to = msg.sender;
    uint256 deadline = block.timestamp + 15;
    uniswapRouter.swapExactETHForTokens{value:msg.value}(
      amountOutMin, 
      path, 
      to,
      deadline);
  }

  function swapFromETHToExactTokens(uint amountOut, address token_out)external payable{
    require(msg.value > 0, "Must pass non 0 ETH amount");
    address[] memory path = new address[](2);
    path[0]=WETH9;
    path[1]=token_out;
    address to = msg.sender;
    uint256 deadline = block.timestamp + 15;
    uniswapRouter.swapETHForExactTokens{value:msg.value}(
      amountOut,
      path, 
      to, 
      deadline);

  }

  function quotes(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB){
    return uniswapRouter.quote(amountA, reserveA, reserveB);
  }

  function getsAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut){
    return uniswapRouter.getAmountOut(amountIn, reserveIn, reserveOut);
  }

  function getsAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn){
    return uniswapRouter.getAmountOut(amountOut, reserveIn, reserveOut);
  }
  
  function getsAmountsOut(uint amountIn, address token_in, address token_out) external view returns (uint[] memory amounts){
    address[] memory path = new address[](2);
    path[0]=token_in;
    path[1]=token_out;
    return uniswapRouter.getAmountsOut(amountIn, path);
  }
    
  function getsAmountsIn(uint amountOut, address token_in, address token_out) external view returns (uint[] memory amounts){
    address[] memory path = new address[](2);
    path[0]=token_in;
    path[1]=token_out;
    return uniswapRouter.getAmountsIn(amountOut, path);
  }
    
}