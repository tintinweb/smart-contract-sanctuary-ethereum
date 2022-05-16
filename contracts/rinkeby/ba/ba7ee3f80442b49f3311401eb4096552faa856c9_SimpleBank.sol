/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// File: contracts/hw02.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private account;//位置

    function withdraw(uint amount) external payable {
        // Implement withdraw function…… 
        require(account[msg.sender] >= amount, "Not enough moneny");
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success, "send fail");
        account[msg.sender] -= amount;

    }

    function deposit() external payable {
        // Implement deposit function……
        account[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        // Implement getBalance function……
        return account[msg.sender];
    }
}