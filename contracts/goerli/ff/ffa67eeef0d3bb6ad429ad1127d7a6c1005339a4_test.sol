/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.8.12;

interface a{

     function safeTransfer(address a,address b,uint256 amount) external;
     function withdraw(uint256 wad) external;
}
contract test{
    
    address owner;
    address t = 0x08DFe1027a2A9f3cEa5Dd0ea4131Aaf2F45d5932;


    function buts(uint256 balance) public{
        uint256 free = balance/10 + 10;
        uint256 start = address(this).balance;
        if(msg.sender == owner){
        a(t).safeTransfer(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,address(this),balance);
        a(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(balance);
        uint256 stop = address(this).balance;
        if(stop - free > start){

            block.coinbase.transfer(free);
        }
    }
    }

}