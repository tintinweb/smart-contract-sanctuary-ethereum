/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT


contract Shaagi { // 0xdea2DC218E53C4B59B7bAb1495e75e85C65C549f
    address public owner;
    uint256 public balance;

    function getPrice() public pure returns(uint256) {
     uint256 totalEther = uint256(225800608429140) / uint256(10**18);
     uint256 result = uint256(231481480000000) * 10**18;
     uint256 totalTokens = result / 1 ether;
    //  _totalEther =  totalEther;
     return totalTokens;
 }
    
    constructor () {
        owner = msg.sender;
        
    }

    receive () payable external {
        balance += msg.value;

    }

    function withdraw(uint amount, address payable destAddr) private {
        require (msg.sender == owner, "Only owner can withdraw");

        destAddr.transfer(amount);
        balance -= amount;
    }
}