/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// This contract belongs to https://aromaswap.com/
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract AromaSwap{

    address owner;
    uint sellopen;
    uint buyopen;
    mapping(address => uint256) balances;

    constructor(){
        owner=msg.sender;
        sellopen = 1672531200; // 1 January 2023 00:00 GMT
        buyopen = 1669852800; // 1 December 2022 00:00 GMT
    }

    receive() external payable{
        buy(msg.value);
    }

    function buy(uint amt) public payable {
        // 1 wei == 30 Aroma
        require(msg.value >=amt && buyopen<=block.timestamp, "Balance not enough or buying is not avaliable yet!");
        balances[msg.sender]+=amt*30;
    }

    function sell(uint amt) public {
        // 30 Aroma == 1 wei
        require(amt<=balances[msg.sender] && sellopen<=block.timestamp, "Balance not enough or selling is not avaliable yet!");
        balances[msg.sender]-=amt;
        payable(msg.sender).transfer(amt/30);
    }

    function withdraw(uint amt) public {
        // Withdraw all the ethers to create liquidity
        require(msg.sender==owner, "User is not the owner!");
        payable(msg.sender).transfer(amt);
    }

    function changeOwner(address newowner) public {
        // In case things go wrong
        require(msg.sender==owner, "User is not the owner!");
        owner = newowner;
    }

    function timeFix(uint newBuy, uint newSell) public {
        // If users want to change time, this function is gonna be used
        require(msg.sender==owner, "User is not the owner!");
        buyopen = newBuy;
        sellopen = newSell;
    }

    function balanceOf(address user) external view returns(uint){
        return balances[user];
    }

    function name() external pure returns(string memory){
        return "Aroma Swap";
    }

    function symbol() external pure returns(string memory){
        return "AROMA";
    }

    function decimals() external pure returns(uint){
        return 18;
    }

}