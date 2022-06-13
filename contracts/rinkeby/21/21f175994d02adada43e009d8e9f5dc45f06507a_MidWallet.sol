// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Address.sol";
import "./IERC20.sol";

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

interface INSIFactory{
    function hasRole(bytes32 role, address account) external view returns (bool);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract MidWallet is AccessControl {
    using Address for address;

    bytes32 constant public OWNER_ROLE = keccak256("Owner ");
    bytes32 constant public ADMIN_ROLE = keccak256("Admin ");
    bytes32 constant public TRADER_ROLE = keccak256("Trader ");

     //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;


    /////////////////////////////
    //My testtoken: 0xDEe385185Cc3D2e1425F48F50641Ae444562EF9b
    //BNB Address: 0xc778417E063141139Fce010982780140Aa0cD5Ab
    //This contract: 0xc722554b4fB53dD373661e2F9094C0B92D3d17d6

    IUniswapV2Router02 public uniswapV2Router;

    address public owner;
    address public factoryAddress = msg.sender;

    mapping(address => bool) public enabled;

    event Trade(address indexed user, uint256 amount, address[] path);
    event Withdraw(address indexed user, uint256 amount, address token);

    modifier onlyOwner(){
        require(hasRole(OWNER_ROLE, msg.sender), "Just Owner!");
        _;
    }

    modifier onlyTrader(){
        require(INSIFactory(factoryAddress).hasRole(TRADER_ROLE, msg.sender), "Just Trader!");
        _;
    }

    constructor(address _owner) {

        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(OWNER_ROLE, _owner); 
        //pancakeswap v2 router mainnet: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    	//                      testnet : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        //https://pcs.nhancv.com v2testnet:0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0
        // uniswap v2 router testnet/mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        //sushiswap v2 router tetnet: 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        


        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Testnet

        owner = _owner;
    }

    receive() payable external{}

 function enable(address tokenContractAddress) public onlyOwner{
        IERC20 token = IERC20(tokenContractAddress);
        address pair = IPancakeFactory(uniswapV2Router.factory()).getPair(uniswapV2Router.WETH(), tokenContractAddress);
        token.approve(address(uniswapV2Router), type(uint256).max);
        token.approve(pair, type(uint256).max);
        token.approve(address(this), type(uint256).max);
        enabled[tokenContractAddress] = true;
    }
    
/*
    function approve(address token, uint256 amount) public onlyOwner{

        IERC20(token).approve(address(this), type(uint256).max);
        IERC20(token).approve(UNISWAP_V2_ROUTER, amount);

        //IERC20(token).approve(address(this), amount);

        //IERC20(token).transferFrom(msg.sender, address(this), amount);
       //IERC20(token).transfer(address(this), amount);
      // IERC20(token).approve(UNISWAP_V2_ROUTER, amount);

    }
    */

    function trade(uint256 amount, uint256 amountOutMin, address[] memory path) public onlyTrader{

        address wbnb = uniswapV2Router.WETH();
        uint deadline = block.timestamp + 200;

        if(path[0] == wbnb){
            uniswapV2Router.swapExactETHForTokens{value: amount}(amountOutMin, path, address(this), deadline);
        }else if(path[path.length-1] == wbnb){
            uniswapV2Router.swapExactTokensForETH(amount, amountOutMin, path, address(this), deadline);
        }else{
            uniswapV2Router.swapExactTokensForTokens(amount, amountOutMin, path, address(this), deadline);
        }
        emit Trade(owner, amount, path);
    }


    function tradeSupportingFee(uint256 amount, uint256 amountOutMin, address[] memory path) public {

        address wbnb = uniswapV2Router.WETH();
        uint deadline = block.timestamp + 200;

        if(path[0] == wbnb){
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens {value: amount}(amountOutMin, path, address(this), deadline);
        }else if(path[path.length-1] == wbnb){
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, amountOutMin, path, address(this), deadline);
        }else{
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, amountOutMin, path, address(this), deadline);
        }
        emit Trade(owner, amount, path);
    }


    function ownerWithdraw(uint256 amount, address _tokenAddr) public onlyOwner {
        if(_tokenAddr == address(0)){
          payable(msg.sender).transfer(amount);
        }else{
          IERC20(_tokenAddr).transfer(msg.sender, amount);
        }
        emit Withdraw(owner, amount, _tokenAddr);
    
    }


    function Trade_Token(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin) public {

         address _to = address(this);
      
        //first we need to transfer the amount in tokens from the msg.sender to this contract
        //this contract will have the amount of in tokens
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
    
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
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
            //then we will call swapExactTokensForTokens
            //for the deadline we will pass in block.timestamp
            //the deadline is the latest time the trade is valid for
            IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, _amountOutMin, path, _to, block.timestamp);
    }
        
    //this function will return the minimum amount from a swap
    //input the 3 parameters below and it will return the minimum amount out
    //this is needed for the swap function above
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
            address[] memory path;
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
            
            uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
            return amountOutMins[path.length -1];  
    }  

}