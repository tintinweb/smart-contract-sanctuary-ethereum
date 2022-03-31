/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

pragma solidity >= 0.5.0 < 0.9.0;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

contract Assignment2
{

   uint public getEther;
   address private  USDC;
   address private USDT;
   address private DAI;
   
    IUniswap private uniswap;
    
    constructor() public payable{

        uniswap = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        USDC=0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        USDT=0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
        DAI=0x31F42841c2db5173425b5223809CF3A38FEde360;
        getEther=address(this).balance;
    
    }

    function SwapExactETHForUSDC(
        uint amountOut
    ) public {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = USDC;
        uniswap.swapExactETHForTokens{value: (getEther/3)}(
            amountOut,
            path,
            msg.sender,
            (block.timestamp+150)
        );
    }

     function SwapExactETHForUSDT(
        uint amountOut
    ) public  {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = USDT;
        uniswap.swapExactETHForTokens{value: (getEther/3)}(
            amountOut,
            path,
            msg.sender,
            (block.timestamp+150)
        );
    }

     function SwapExactETHForDAI(
        uint amountOut
    ) public {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = DAI;
        uniswap.swapExactETHForTokens{value: (getEther/3)}(
            amountOut,
            path,
            msg.sender,
            (block.timestamp+150)
        );
    }
 
}