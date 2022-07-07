// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract USDCSwap {

  address public UNISWAP_FACTORY_ADDRESS;
  address public UNISWAP_ROUTER_ADDRESS;
  address public WETH;
  address public usdcAddress;
  address public receiverAddress;
  
  address public owner;

  IUniswapV2Router02 public uniswapRouter;
  IERC20 usdc;
  IERC20 wethToken;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor(uint256 _chainId) {
    owner = msg.sender;

    if(_chainId == 1){
        //Uniswap - Ethereum - Mainnet
        UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //WETH
        usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        receiverAddress = 0xA7684CDEC9f90E2f352e120861555D234a714cDf; // ETH
    }else if (_chainId == 4){
        //Uniswap - Ethereum - Rinkeby
        UNISWAP_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        usdcAddress = 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926;
        receiverAddress = 0xA7684CDEC9f90E2f352e120861555D234a714cDf; // ETH
    }else if (_chainId == 137){
        //Quickswap - Polygon - Mainnet
        UNISWAP_FACTORY_ADDRESS = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
        UNISWAP_ROUTER_ADDRESS = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //WMATIC
        usdcAddress = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        receiverAddress = 0x5d9daccCe2A7433cd17E6e1A6Ee5f0763D7edE44; // Polygon
    }else if (_chainId == 43114){
        //Pangolin - AVAX - Mainnet
        UNISWAP_FACTORY_ADDRESS = 0xefa94DE7a4656D787667C749f7E1223D71E9FD88;
        UNISWAP_ROUTER_ADDRESS = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
        WETH = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; //WAWAX
        usdcAddress = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
        receiverAddress = 0xE0537229eF14b81598b30c9Da6b84a65E8Fb34bf; // AVAX
    }else if (_chainId == 56){
        //PancakeSwap - BSC - Mainnet
        UNISWAP_FACTORY_ADDRESS = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        UNISWAP_ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB
        usdcAddress = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        receiverAddress = 0xc0f7765363312C5FBf91b093a95B36dE27F61C38; // BSC
    }else if (_chainId == 97){
        //PancakeSwap - BSC - Testnet
        UNISWAP_FACTORY_ADDRESS = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
        UNISWAP_ROUTER_ADDRESS = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //WBNB
        usdcAddress = 0x70Dc5cD633AE263272670735d35F46213ae0CB08;
        receiverAddress = 0xc0f7765363312C5FBf91b093a95B36dE27F61C38; // BSC
    }

    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    usdc = IERC20(usdcAddress);
    wethToken = IERC20(WETH);

  }

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
  
  function getPrice(address _tokenAddress1, address _tokenAddress2, uint256 _amount) public view returns(uint256) {
    address pairAddress = IUniswapV2Factory(UNISWAP_FACTORY_ADDRESS).getPair(_tokenAddress1, _tokenAddress2);
   
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

    IERC20 token1 = IERC20(pair.token1());
    (uint Res0, uint Res1,) = pair.getReserves();

    // decimals
    uint res0 = Res0*(10**token1.decimals());
    return((_amount*res0)/Res1); // return amount of token0 needed to buy token1
  }

  function getPathForETHtoToken(address _token) public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = _token;
    
    return path;
  }

  function getPathForTokenToToken(address _tokenIn, address _tokenOut) public view returns (address[] memory) {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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