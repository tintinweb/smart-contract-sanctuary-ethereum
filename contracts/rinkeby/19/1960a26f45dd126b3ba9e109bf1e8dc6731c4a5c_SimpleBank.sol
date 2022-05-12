/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: SimpleBank.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping(address => uint) private bank;
    
    function withdraw(uint amount) external payable {
        require (bank[msg.sender]>= amount,"NOT ENOUGH BALANCE");
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require (sent,"SENT FAIL");
        bank[msg.sender]-=amount;
    }

    function deposit() external payable {
        bank[msg.sender]+=msg.value;
    }

    function getBalance() public view returns (uint) {
        return bank[msg.sender];
    }
}