// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

//Interface for interacting with erc20

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



interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) view external returns (uint256);


}

contract MigrateLp {

    address constant RouterV1 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;//addr panckeyc or uni
    address constant CELL = 0x09757DabaC779e8420b40df0315962Bbc9833C73; // addr old cell token
    address constant Lp = 0xEA3Be96d4Cf64110D5C9eE5e6c788f460eD3aCa6; // addr old lp token
    address WETH = IUniswapV2Router01(RouterV1).WETH();
    address constant nCELL = 0x014C1E4029B0a24Ddd337A93385FEB8c293240F2; // addr new cell token

    

    mapping(address => mapping(address => uint)) balanceSender;
    mapping(address => uint) balanceLP;

    
    function sendlp(uint amountLP) external {


        IERC20(Lp).transferFrom(msg.sender,address(this),amountLP);
        IERC20(Lp).approve(RouterV1,amountLP);

        (uint token0,uint token1) = migrateLP(amountLP);

        balanceSender[msg.sender][CELL]= token0;
        balanceSender[msg.sender][WETH]= token1;

        
        IERC20(nCELL).approve(RouterV1,token0);
        IERC20(WETH).approve(RouterV1,token1);
        
                 
        IUniswapV2Router01(RouterV1).addLiquidity(
            nCELL,
            WETH,
            token0,
            token1,
            0,
            0,
            msg.sender,
            block.timestamp + 5000
        );
        
        IERC20(CELL).transfer(address(1),balanceSender[msg.sender][CELL]);

        }
    

    function _approve(uint amountLP) external{
        IERC20(Lp).approve(RouterV1,amountLP);
        
    }


    function seebalanace(address token) public view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }


    function migrateLP(uint amountLP) internal returns(uint256 token0,uint256 token1) {

        
        
        //(bool success, ) = RouterV1.delegatecall(abi.encodeWithSignature("removeLiquidity(address,address,uint,uint,uint,address,uint)",
        //        CELL,WETH,amountLP,1,1,address(this),block.timestamp + 5000));
        //require(success,"not");
        
        
        //чтобы выполнилась надо сделать апрув lp для routerv1
        
        

        return IUniswapV2Router01(RouterV1).removeLiquidity(
            CELL,
            WETH,
            amountLP,
            1,
            1,
            address(this),
            block.timestamp + 5000
        );
       
    
        /*uint amountCell =  seebalanace(CELL);
        uint amountnCELL =  seebalanace(CELLNEW);

        


        /*чтобы выполнелась надо сделать
        1.approve ncell разрешить снимать routerv1 с контракта
        2.approve cell разрешить снимать routerv1 с контракта
        */
        
      
        
       
        

        
    }


    receive () external payable{

    }



}