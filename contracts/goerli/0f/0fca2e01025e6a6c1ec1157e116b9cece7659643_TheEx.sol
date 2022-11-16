/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;

contract TheEx {

    uint256 amount;
    uint256 depositAmount;
    uint256 withdrawAmount;
    uint256 interestRate;
    uint256 liabilities;

    function setAmount(uint256 num) public {
        amount = num;
    }

    // 存錢
    function getDeposit(uint256 num) public payable {
        
    }

    // check balance of this contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function memeHere() public pure returns (string memory){
        return "hello dummy";
    }

    function retrieveAmount() public view returns (uint256){
        return amount;
    }
    
}