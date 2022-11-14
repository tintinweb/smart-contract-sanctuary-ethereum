/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// File: RentPay.sol

pragma solidity ^0.6.0;

contract getRent {

    mapping(address => uint256) public balanceOf; 

    function deposit(uint256 amount) public payable {
        require(msg.value == amount);
        balanceOf[msg.sender] += amount;     
    }

    function withdraw(uint256 amount) public {
        require(amount <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
}