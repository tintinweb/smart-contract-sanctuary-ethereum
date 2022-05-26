/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private balances;

    function withdraw(uint amount) external {
        // Implement withdraw function…… 
		require(balances[msg.sender] >= amount , "Your balance is insufficient.");
        balances[msg.sender] -= amount;
        (bool send_success,) = payable(msg.sender).call{value:amount}("");
        require(send_success,"Send Failed.");
    }

    function deposit() external payable returns (uint){
        // Implement deposit function……
        balances[msg.sender] += msg.value;
        return balances[msg.sender];
    }

    function getBalance() public view returns (uint) {
        // Implement getBalance function……
        return balances[msg.sender];
    }
}