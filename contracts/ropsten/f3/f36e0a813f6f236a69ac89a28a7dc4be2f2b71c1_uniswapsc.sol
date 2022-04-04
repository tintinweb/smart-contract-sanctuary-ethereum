/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

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

contract uniswapsc
{
  
   address private  USDC;
   address private USDT;
   address private DAI;

   uint public X;
   uint public Y;
   uint public Z;
   uint public Ether;
  
   
    IUniswap private uniswap;
    
    constructor() payable{

        uniswap = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        USDC=0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        USDT=0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
        DAI=0x31F42841c2db5173425b5223809CF3A38FEde360;
        Ether=address(this).balance;
    
    
    }

    function SwapExactETHForUSDC_USDT_DAI() public {
       
        X=Ether/3;
        address[] memory path = new address[](2);
        path[0] = uniswap.WETH();
        path[1] = USDC;
        uniswap.swapExactETHForTokens{value: X}(
            0,
            path,
            msg.sender,
            (block.timestamp+150)
        );

        Y=Ether/3;
        path[1] = USDT;
        uniswap.swapExactETHForTokens{value: Y}(
            0,
            path,
            msg.sender,
            (block.timestamp+150)
        );

        Z=((Ether)-(X+Y));
        path[1] = DAI; 
        uniswap.swapExactETHForTokens{value: Z}(
            0,
            path,
            msg.sender,
            (block.timestamp+150)
        );


    }

}