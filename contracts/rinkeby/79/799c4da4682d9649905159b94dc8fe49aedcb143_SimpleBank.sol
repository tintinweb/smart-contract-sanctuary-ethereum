/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// File: hw2.sol


pragma solidity ^0.8.10;

contract SimpleBank {

    mapping(address => uint) private balance;

    function withdraw(uint amount) external payable {
	    assert(balance[msg.sender] >= amount);
	    balance[msg.sender] -= amount;
        (bool sent, ) = (payable(msg.sender)).call{value: amount}(""); // return true or false.
        require(sent, "Send failed.");
    }

    function deposit() external payable {
	    balance[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
	    return balance[msg.sender];
    }
}