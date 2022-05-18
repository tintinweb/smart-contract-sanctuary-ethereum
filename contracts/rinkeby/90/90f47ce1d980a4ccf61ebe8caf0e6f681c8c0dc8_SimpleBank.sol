/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// File: contracts/homework.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint) private account;

    function withdraw(uint amount) external payable {
		require(account[msg.sender] >= amount);
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Send failed.");
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