/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// File: contracts/HW8.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private accToAmount;

    function withdraw(uint amount) external payable {
         require(accToAmount[msg.sender] >= amount, "Insufficient balance.");
         bool sent = payable (msg.sender).send(amount);
         require(sent, "Send failed.");
         accToAmount[msg.sender] -= amount;
    }

    function deposit() external payable {
        accToAmount[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        return accToAmount[msg.sender];
    }
}