/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// File: Homework0512.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private account;

    function withdraw(uint amount) external payable {
        require(account[msg.sender] >= amount, "Not enough.");
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
		require(sent, "send fail");
        account[msg.sender] -= amount;
    }

    function deposit() external payable {
		account[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return account[msg.sender];
    }
}