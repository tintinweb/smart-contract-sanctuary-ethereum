// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;


import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
//import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract USDCSwap {
 
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  //address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  
  IUniswapV2Router02 public uniswapRouter;
  
  //address public usdcAddress = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926; //USDC Rinkeby
  address public usdcAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; //USDC Goerli
  
  address public receiverAddress = 0x7201200bFA3Da6E229AF8c3454d935016c5A3BBb;

  IERC20 usdc = IERC20(usdcAddress);
    
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

  function swapTokenToTokenTest(address _sender, address _tokenAddress, uint256 _amount) public returns(bool){ //swapTokenToEth
    //uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
    //uniswapRouter.swapExactTokensForETH{value: payable(dai.balanceOf(address(this)))}(0, getPathForDAItoETH(), address(this), deadline);
    uint256 allownace = IERC20(_tokenAddress).allowance(_sender,address(this));
    require( allownace >= _amount, "Not enough allownace to transfer the tokens");
    IERC20(_tokenAddress).transferFrom(_sender, address(this),_amount);
    IERC20(_tokenAddress).approve(UNISWAP_ROUTER_ADDRESS, IERC20(_tokenAddress).balanceOf(address(this)));
    //UniswapV2Router02.swapExactTokensForETH(IERC20(tradeTokenAddress).balanceOf(address(this)) , 0, getPathForTokenToETH(tradeTokenAddress), address(this), deadline);
                  //swapExactTokensForETH(amountIn, amountOutMin, address[] calldata path, address to, uint deadline)
    //UniswapV2Router02.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, block.timestamp);
    //uniswapRouter.swapExactTokensForTokens(IERC20(_tokenAddress).balanceOf(address(this)), 0, getPathForTokenToETH(_tokenAddress), receiverAddress, deadline);
    // refund leftover ETH to user
    //(bool success,) = msg.sender.call{ value: address(this).balance }("");
    //require(success, "refund failed");
    return true;
  }
  
  function swapTokenToToken(address _sender, address _tokenAddress, uint256 _amount) public returns(bool){ //swapTokenToEth
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
    //uniswapRouter.swapExactTokensForETH{value: payable(dai.balanceOf(address(this)))}(0, getPathForDAItoETH(), address(this), deadline);
    uint256 allownace = IERC20(_tokenAddress).allowance(_sender,address(this));
    require( allownace >= _amount, "Not enough allownace to transfer the tokens");
    IERC20(_tokenAddress).transferFrom(_sender, address(this),_amount);
    IERC20(_tokenAddress).approve(UNISWAP_ROUTER_ADDRESS, IERC20(_tokenAddress).balanceOf(address(this)));
    //UniswapV2Router02.swapExactTokensForETH(IERC20(tradeTokenAddress).balanceOf(address(this)) , 0, getPathForTokenToETH(tradeTokenAddress), address(this), deadline);
                  //swapExactTokensForETH(amountIn, amountOutMin, address[] calldata path, address to, uint deadline)
    //UniswapV2Router02.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, block.timestamp);
    uniswapRouter.swapExactTokensForTokens(IERC20(_tokenAddress).balanceOf(address(this)), 0, getPathForTokenToETH(_tokenAddress), receiverAddress, deadline);
    // refund leftover ETH to user
    //(bool success,) = msg.sender.call{ value: address(this).balance }("");
    //require(success, "refund failed");
    return true;
  }

  function swapTokenToEth(address _token) public payable returns(uint){
    uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
    //uniswapRouter.swapExactTokensForETH{value: payable(dai.balanceOf(address(this)))}(0, getPathForDAItoETH(), address(this), deadline);
    
    IERC20(usdcAddress).approve(UNISWAP_ROUTER_ADDRESS, usdc.balanceOf(address(this)));
    uniswapRouter.swapExactTokensForETH(IERC20(_token).balanceOf(address(this)) , 0, getPathForTokenToETH(_token), receiverAddress, deadline);
                  //swapExactTokensForETH(amountIn, amountOutMin, address[] calldata path, address to, uint deadline)

    // refund leftover ETH to user
    //(bool success,) = msg.sender.call{ value: address(this).balance }("");
    //require(success, "refund failed");
    
    return address(this).balance;
  }
  
  function getEstimatedETHforToken() public view returns (uint[] memory) {
    return uniswapRouter.getAmountsIn(usdc.balanceOf(address(this)), getPathForETHtoToken(usdcAddress));
  }
  
  function getEstimatedTokenforETH(address _token) public view returns (uint[] memory) {
      return uniswapRouter.getAmountsIn(address(this).balance, getPathForTokenToETH(_token));
  }
  
  function getPathForETHtoToken(address _token) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = _token;
    
    return path;
  }
  
  function getPathForTokenToETH(address _token) public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = _token;
    path[1] = uniswapRouter.WETH();
    return path;
  }

  function setReceiverAddress(address _newReceiverAddress) public {
    receiverAddress = _newReceiverAddress;
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