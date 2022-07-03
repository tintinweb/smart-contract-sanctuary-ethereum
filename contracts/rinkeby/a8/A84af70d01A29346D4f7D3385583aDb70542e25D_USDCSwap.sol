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
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

contract USDCSwap {
  
  //Uniswap - Ethereum - Rinkeby
  address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  address public usdcAddress = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
  
  /*
  //Pangolin - AVAX - Mainnet
  address public constant UNISWAP_ROUTER_ADDRESS = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
  address public constant WETH = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
  address public usdcAddress = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
  */
  
  address public receiverAddress = 0x7201200bFA3Da6E229AF8c3454d935016c5A3BBb;

  IUniswapV2Router02 public uniswapRouter;

  IERC20 usdc = IERC20(usdcAddress);
  
  IERC20 wethToken = IERC20(WETH);

  constructor() {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }

  function swapEthToUSDC() public payable returns(bool){ //swapEthToToken
    address _tokenOut = usdcAddress; 
    //UniswapV2Router02.swapExactETHForTokens{value: msg.value}(0, getPathForETHtoToken(UniswapV2Router02.WETH()), address(this), deadline);
    //WETHToken.deposit.value();
    // WETHToken.deposit.value(msg.value)();
    wethToken.deposit{value:msg.value}();
    wethToken.approve(UNISWAP_ROUTER_ADDRESS,wethToken.balanceOf(address(this)));
    //swapWETHToUSDC();
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
    uniswapRouter.swapExactTokensForTokens(wethToken.balanceOf(address(this)), 0, getPathForTokenToToken(WETH,_tokenOut), receiverAddress, deadline);
    return true;
  }
  
  function swapWETHToUSDC() public returns(bool){ //swapTokenToEth
  
    IERC20 token =  wethToken;
    address _tokenOut = usdcAddress; 
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!

    /*    
    uint256 allownace = token.allowance(_sender,address(this));
    require( allownace >= _amount, "Not enough allownace to transfer the tokens");
    token.transferFrom(_sender, address(this),_amount);
    */
    
    token.approve(UNISWAP_ROUTER_ADDRESS, token.balanceOf(address(this)));
  
    uniswapRouter.swapExactTokensForTokens(token.balanceOf(address(this)), 0, getPathForTokenToToken(WETH,_tokenOut), receiverAddress, deadline);
  
    return true;
  }

  /*
  function swapEthToUSDC() public payable returns(bool){
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
   
    uniswapRouter.swapExactETHForTokens{value: msg.value}(0, getPathForETHtoToken(usdcAddress), receiverAddress, deadline);

    // refund leftover ETH to user
    //(bool success,) = msg.sender.call{ value: address(this).balance }("");
    //require(success, "refund failed");
    
    return true;
  }
  */

  function swapTokenToUSDC(address _sender, address _tokenIn, uint256 _amount) public returns(bool){ //swapTokenToEth
  
    IERC20 token =  IERC20(_tokenIn);
    address _tokenOut = usdcAddress; 
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        
    uint256 allownace = token.allowance(_sender,address(this));
    require( allownace >= _amount, "Not enough allownace to transfer the tokens");
    token.transferFrom(_sender, address(this),_amount);
    
    
    token.approve(UNISWAP_ROUTER_ADDRESS, token.balanceOf(address(this)));
  
    uniswapRouter.swapExactTokensForTokens(token.balanceOf(address(this)), 0, getPathForTokenToToken(_tokenIn,_tokenOut), receiverAddress, deadline);
  
    return true;
  }
  
  function getPathForETHtoToken(address _token) public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = _token;
    
    return path;
  }

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