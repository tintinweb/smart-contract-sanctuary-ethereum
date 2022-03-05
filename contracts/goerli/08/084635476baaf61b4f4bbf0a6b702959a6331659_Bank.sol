/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint256) accounts;
    uint256 totalAccount;

    receive() external payable {
        accounts[msg.sender] += msg.value;
        totalAccount += msg.value;
    }

    function getAmount(address from) public view 
    returns (uint256){
        return accounts[from];
    }

    function withdraw() public returns (bool){
         (bool successc, )  = msg.sender.call{value: totalAccount}("");
         return successc;
    }
}