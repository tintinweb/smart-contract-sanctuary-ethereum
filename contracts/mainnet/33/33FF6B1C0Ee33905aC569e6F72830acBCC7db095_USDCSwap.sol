// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;


//import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

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
  
  
  //Uniswap - Ethereum - Mainnet
  address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //WETH
  address public usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  /*
  //Uniswap - Ethereum - Rinkeby
  address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  address public usdcAddress = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
  */

  /*
  //Pangolin - AVAX - Mainnet
  address public constant UNISWAP_ROUTER_ADDRESS = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
  address public constant WETH = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; //WAWAX
  address public usdcAddress = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
  */

  /*
  //Quickswap - Polygon - Mainnet
  address public constant UNISWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
  address public constant WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //WMATIC
  address public usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  */

  /*
  //PancakeSwap - BSC - Mainnet
  address public constant UNISWAP_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
  address public constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB
  address public usdcAddress = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
  */

  address public owner;
  address public receiverAddress = 0xA7684CDEC9f90E2f352e120861555D234a714cDf;

  IUniswapV2Router02 public uniswapRouter;

  IERC20 usdc = IERC20(usdcAddress);
  
  IERC20 wethToken = IERC20(WETH);

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor() {
    owner = msg.sender;
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
  }

  /*
  function depositMatic() public payable returns(bool){ //swapEthToToken
    wethToken.deposit{value:msg.value}();
    wethToken.approve(UNISWAP_ROUTER_ADDRESS,wethToken.balanceOf(address(this)));
    return true;
  }

  function swapMaticToUSDC() public payable returns(bool){ //swapEthToToken 
    address _tokenOut = usdcAddress; 
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
    uniswapRouter.swapExactTokensForTokens(wethToken.balanceOf(address(this)), 0, getPathForTokenToToken(WETH,_tokenOut), receiverAddress, deadline);
    return true;
  }
  */

  function swapEthToUSDC() public payable returns(bool){ //swapEthToToken
    address _tokenOut = usdcAddress; 
    
    wethToken.deposit{value:msg.value}();
    wethToken.approve(UNISWAP_ROUTER_ADDRESS,wethToken.balanceOf(address(this)));
    
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
    uniswapRouter.swapExactTokensForTokens(wethToken.balanceOf(address(this)), 0, getPathForTokenToToken(WETH,_tokenOut), receiverAddress, deadline);
    return true;
  }

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
  
  function setReceiverAddress(address _newReceiverAddress) public onlyOwner{
    receiverAddress = _newReceiverAddress;
  }

  function withdrawETH() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "Transfer failed.");
  }

  function withdrawTokens(address _tokenAddress) external onlyOwner {
      IERC20 token =  IERC20(_tokenAddress);
      bool success = token.transfer(msg.sender, token.balanceOf(address(this)));
      require(success, "Token Transfer failed.");
  }

  function transferOwnership(address _newOwner) public onlyOwner{
    owner = _newOwner;
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