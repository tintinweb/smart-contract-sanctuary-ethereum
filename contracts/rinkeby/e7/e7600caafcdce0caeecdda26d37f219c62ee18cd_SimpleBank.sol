/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: contracts/bank.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private balance;

    function withdraw(uint amount) external payable {
       require(amount<=balance[msg.sender],"ERROR: YOU'RE POOR. (CRYING EMOJI) ");
       (bool sent, ) = payable (msg.sender).call{value: amount}("ETHER:X WEI:O");
       require(sent,"ERROR: YOU FAIL, SOMEHOW.");
        balance[msg.sender]-=amount;
    }

    function deposit() external payable {
		balance[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
		return balance[msg.sender];
    }
}