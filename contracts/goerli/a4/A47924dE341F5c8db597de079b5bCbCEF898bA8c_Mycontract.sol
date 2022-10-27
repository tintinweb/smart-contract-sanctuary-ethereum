/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Mycontract{
    function getBalance() public view returns(uint256) {
        return address(msg.sender).balance;
    }
    function transfer(address to) public payable {
        require(address(msg.sender).balance>=msg.value,"you ETH not enough");
        payable(to).transfer(msg.value);
    }
}