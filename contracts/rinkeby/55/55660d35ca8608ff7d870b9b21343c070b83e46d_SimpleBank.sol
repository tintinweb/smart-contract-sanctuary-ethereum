/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// File: contracts/hw2.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private balances;

    function withdraw(uint amount) external payable {
        // Implement withdraw function…… 
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Send failed.");
        balances[msg.sender] -= amount;

    }

    function deposit() external payable {
        // Implement deposit function……
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        // Implement getBalance function……
        return balances[msg.sender];
    }
}