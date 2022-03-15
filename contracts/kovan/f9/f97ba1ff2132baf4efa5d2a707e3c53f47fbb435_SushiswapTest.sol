/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

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
contract SushiswapTest {
  address private constant ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
  IUniswapV2Router02 public constant uniswapRouter = IUniswapV2Router02(ROUTER);
  address private constant WETH9 = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

   
  function swap(address token_in, address token_out, uint amountIn) external {
    require(amountIn > 0, "Must pass non 0 ETH amount");

    uint amountOutMin = 0;
    address[] memory path = new address[](2);
    path[0]=token_in;
    path[1]=token_out;
    address to = msg.sender;
    uint256 deadline = block.timestamp + 15;

    TransferHelper.safeTransferFrom(token_in, msg.sender, address(this), amountIn);
    TransferHelper.safeApprove(token_in, ROUTER, amountIn);

    //IERC20(token_in).transferFrom(msg.sender, address(this), amountIn);
    //IERC20(token_in).approve(ROUTER, amountIn);

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
    //IERC20(token_in).approve(ROUTER, amountIn);
    //IERC20(token_in).transferFrom(msg.sender, address(this), amountIn);

    TransferHelper.safeTransferFrom(token_in, msg.sender, address(this), amountIn);
    TransferHelper.safeApprove(token_in, ROUTER, amountIn);
    
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
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address token_in) external returns (uint[] memory amounts){
    require(amountOut > 0, "Must pass non 0 token amount");
    address[] memory path = new address[](2);
    path[0] = token_in;
    path[1] = WETH9;
    address to = msg.sender;
    uint256 deadline = block.timestamp + 15;

    TransferHelper.safeTransferFrom(token_in, msg.sender, address(this), amountOut);
    TransferHelper.safeApprove(token_in, ROUTER, amountOut);

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