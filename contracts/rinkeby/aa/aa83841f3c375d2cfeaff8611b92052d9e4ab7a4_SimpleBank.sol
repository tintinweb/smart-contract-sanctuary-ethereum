/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// File: contracts/test1.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private A;

    function withdraw(uint amount) external payable {
        // Implement withdraw function…… 
        require(A[msg.sender]>=amount, "No money to withdraw.");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Send failed.");
        A[msg.sender] -= amount;
    }

    function deposit() external payable {
        // Implement deposit function……
        A[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        // Implement getBalance function……
        // return address(this).balance;
        return A[msg.sender];
    }
}