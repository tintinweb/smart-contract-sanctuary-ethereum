/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: SimpleBank.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private bank;

    function withdraw(uint amount) external payable {
        // Implement withdraw function…… 
        require(bank[msg.sender] >= amount, "Insufficient balance");
        (bool sent, ) = payable(msg.sender).call{value: amount}(" ");
        require(sent, "Send failed.");
        bank[msg.sender] -= amount;
    }

    function deposit() external payable {
        // Implement deposit function……
        bank[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        // Implement getBalance function……
        return bank[msg.sender];
    }
}