// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;


//import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract USDCSwap {
 
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  
  IUniswapV2Router02 public uniswapRouter;
  
  address public usdcAddress = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926; //USDC Rinkeby
  //address public usdcAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; //USDC Goerli
  //address public daiTokenAddress = 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa; //DAI Rinkeby
  address public receiverAddress = 0x7201200bFA3Da6E229AF8c3454d935016c5A3BBb;

  IERC20 usdc = IERC20(usdcAddress);
  //IERC20 daiToken = IERC20(daiTokenAddress);
  IERC20 wethToken = IERC20(WETH);

  constructor() {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }
    
  function swapEthToToken() public payable returns(bool){
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
    //uint amount = msg.value - ((msg.value*50)/100);
    uniswapRouter.swapExactETHForTokens{value: msg.value}(0, getPathForETHtoToken(usdcAddress), receiverAddress, deadline);

    // refund leftover ETH to user
    //(bool success,) = msg.sender.call{ value: address(this).balance }("");
    //require(success, "refund failed");
    
    return true;
  }
  
  function swapTokenToUSDC(address _sender, address _tokenIn, uint256 _amount) public returns(bool){ //swapTokenToEth
    //address _tokenIn = daiTokenAddress;
    IERC20 token =  IERC20(_tokenIn);
    address _tokenOut = usdcAddress; 
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
    //uniswapRouter.swapExactTokensForETH{value: payable(dai.balanceOf(address(this)))}(0, getPathForDAItoETH(), address(this), deadline);
    
    
    uint256 allownace = token.allowance(_sender,address(this));
    require( allownace >= _amount, "Not enough allownace to transfer the tokens");
    token.transferFrom(_sender, address(this),_amount);
    
    
    token.approve(UNISWAP_ROUTER_ADDRESS, token.balanceOf(address(this)));
    //UniswapV2Router02.swapExactTokensForETH(IERC20(tradeTokenAddress).balanceOf(address(this)) , 0, getPathForTokenToETH(tradeTokenAddress), address(this), deadline);
                  //swapExactTokensForETH(amountIn, amountOutMin, address[] calldata path, address to, uint deadline)
    //UniswapV2Router02.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, block.timestamp);
    uniswapRouter.swapExactTokensForTokens(token.balanceOf(address(this)), 0, getPathForTokenToToken(_tokenIn,_tokenOut), receiverAddress, deadline);
    // refund leftover ETH to user
    //(bool success,) = msg.sender.call{ value: address(this).balance }("");
    //require(success, "refund failed");
    return true;
  }
  /*
  function approveUSDC() public{
    usdc.approve(UNISWAP_ROUTER_ADDRESS, usdc.balanceOf(address(this)));
  }

  function approveDAI() public{
    daiToken.approve(UNISWAP_ROUTER_ADDRESS, daiToken.balanceOf(address(this)));
  }

  function approveWETH() public{
    wethToken.approve(UNISWAP_ROUTER_ADDRESS, daiToken.balanceOf(address(this)));
  }

  function getEstimatedETHforToken() public view returns (uint[] memory) {
    return uniswapRouter.getAmountsIn(usdc.balanceOf(address(this)), getPathForETHtoToken(usdcAddress));
  }

  function getEstimatedETHforTokenByAddress(address _tokenAddress) public view returns (uint[] memory) {
    IERC20 token = IERC20(_tokenAddress);
    return uniswapRouter.getAmountsIn(token.balanceOf(address(this)), getPathForETHtoToken(usdcAddress));
  }

  function getEstimatedETHforTokenByAddressAndAmount(address _tokenAddress, uint256 _amount) public view returns (uint[] memory) {
    //IERC20 token = IERC20(_tokenAddress);
    return uniswapRouter.getAmountsIn(_amount, getPathForETHtoToken(_tokenAddress));
  }
  
  function getEstimatedTokenforETH(address _token) public view returns (uint[] memory) {
      return uniswapRouter.getAmountsIn(address(this).balance, getPathForTokenToETH(_token));
  }
  */

  function getPathForETHtoToken(address _token) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = _token;
    
    return path;
  }
  
  /*
  function getPathForTokenToETH(address _tokenIn) public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = _tokenIn;
    path[1] = uniswapRouter.WETH();
    return path;
  }
  */

  function getPathForTokenToToken(address _tokenIn, address _tokenOut) public pure returns (address[] memory) {
    address[] memory path = new address[](3);
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }
    return path;
  }

  function setReceiverAddress(address _newReceiverAddress) public {
    receiverAddress = _newReceiverAddress;
  }

  /*
  function getWETHAmountOutMinForDai(uint _amountIn) external view returns (uint) {
    address[] memory path;
    address _tokenIn = daiTokenAddress;
    address _tokenOut = WETH;
    
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }
    
    
    // same length as path
    uint[] memory amountOutMins =
      IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).getAmountsOut(_amountIn, path);

    return amountOutMins[path.length - 1];
  }
  */

  function getUSDCAmountOutMinForToken(address _tokenIn, uint _amountIn) external view returns (uint) {
    address[] memory path;
    address _tokenOut = usdcAddress;
    
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }

    // same length as path
    uint[] memory amountOutMins = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).getAmountsOut(_amountIn, path);

    return amountOutMins[path.length - 1];
  }
  
  /*
  function getUSDCAmountOutMinForWETH(uint _amountIn) external view returns (uint) {
    address[] memory path;
    address _tokenIn = daiTokenAddress;
    address _tokenOut = WETH;
    
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }

    // same length as path
    uint[] memory amountOutMins =
      IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).getAmountsOut(_amountIn, path);

    return amountOutMins[path.length - 1];
  }
  */
  // important to receive ETH
  receive() payable external {
    
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