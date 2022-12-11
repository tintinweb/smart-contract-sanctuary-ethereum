/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyBank {
    mapping (address => uint256) public balances;

    address[] public accounts;

    function deposit() public payable {
        if (balances[msg.sender] == 0) {
            accounts.push(msg.sender);
        }
        balances[msg.sender] += msg.value;
    }

   function withdraw(uint256 amount) public returns (uint256) {
        require(balances[msg.sender] >= amount,"balance is not enough");
        balances[msg.sender] -= amount;

        payable(msg.sender).transfer(amount);

        return balances[msg.sender];
    }
}