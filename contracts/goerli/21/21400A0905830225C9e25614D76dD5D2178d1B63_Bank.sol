/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Bank {
    mapping(address => uint256) public balance;

    receive() external payable {
        balance[msg.sender] += msg.value;
    }

    fallback() external payable {
        balance[msg.sender] += msg.value;
    }

    function balanceOf() public view returns (uint256) {
        return balance[msg.sender];
    }

    function withdraw() public {
        uint256 amount = balance[msg.sender];
        balance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}