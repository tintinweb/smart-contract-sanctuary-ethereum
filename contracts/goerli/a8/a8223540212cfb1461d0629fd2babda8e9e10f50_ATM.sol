/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ATM {

 receive() external payable {}

 function getBalance() public view returns (uint){
     return address(this).balance;
 }

 function withdraw(address to) public {
    uint256 balance = address(this).balance;
    payable(to).transfer(balance);
  }
}