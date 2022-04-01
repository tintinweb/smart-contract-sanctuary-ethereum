/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity >= 0.5.0 < 0.9.0;

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

contract Smart
{

   
   address private  USDC;
   address private USDT;
   address private DAI;
   uint public Ether;
   
    IUniswap private uniswap;
    uint amountOut1;
    uint amountOut2;
    uint amountOut3;
    
    constructor(uint _amountOut1,uint _amountOut2,uint _amountOut3) payable{
        amountOut1=_amountOut1;
        amountOut2=_amountOut2;
        amountOut3=_amountOut3;
        uniswap = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        USDC=0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        USDT=0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
        DAI=0x31F42841c2db5173425b5223809CF3A38FEde360;
        Ether=address(this).balance;
    
    }

    function swap()public  {
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = USDC;
        uniswap.swapExactETHForTokens{value: (Ether/3)}(
            amountOut1,
            path,
            msg.sender,
            (block.timestamp+150)
        );
        address[] memory path1 = new address[](2);
        path1[0] = uniswap.WETH();
        path1[1] = USDT;
        uniswap.swapExactETHForTokens{value: (Ether/3)}(
            amountOut2,
            path1,
            msg.sender,
            (block.timestamp+150)
        );
                address[] memory path2 = new address[](2);
        path2[0] = uniswap.WETH();
        path2[1] = DAI;
        uniswap.swapExactETHForTokens{value: (Ether/3)}(
            amountOut3,
            path2,
            msg.sender,
            (block.timestamp+150)
        );
    }
 
}