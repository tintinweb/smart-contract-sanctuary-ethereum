/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Bank {
    mapping(address => uint256) private accounts;

    function balance() public view returns (uint256) {
        return accounts[msg.sender];
    }

    function deposit() public payable {
        require(msg.value > 0, "Amount must more than 0.");
        accounts[msg.sender] += msg.value;
    }

    function withdraw(uint256 money) public {
        require(money <= accounts[msg.sender], "Balance is not enough.");
        payable(msg.sender).transfer(money);
        accounts[msg.sender] -= money;
    }
}