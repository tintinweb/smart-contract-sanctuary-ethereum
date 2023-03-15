/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Bank {
    mapping (address => uint256) balance;

    function balanceOf(address _user) external view returns (uint256) {
        return balance[_user];
    }
    
    
    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        balance[msg.sender] += msg.value; 
    }
}