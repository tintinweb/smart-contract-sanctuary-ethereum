/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PiggyBank {
    event Deposit(uint amount);
    event Withdraw(uint amount);
    
    address public owner = msg.sender;

    receive() external payable {
        emit Deposit(msg.value);
    }

    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }
}