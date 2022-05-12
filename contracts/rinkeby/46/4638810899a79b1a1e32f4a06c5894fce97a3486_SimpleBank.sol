/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: hw/hw02.sol



pragma solidity ^0.8.10;



contract SimpleBank {

    mapping( address => uint ) private bank;



    function withdraw(uint amount) external payable {

        require(amount <= bank[msg.sender], "Error: Insufficient balance!");

        bank[msg.sender] -= amount;

        (bool sent, ) = payable (msg.sender).call{value: amount}("");

        require(sent, "Error: Withdraw failed!");

    }



    function deposit() external payable {

        bank[msg.sender] += msg.value;

    }



    function getBalance() public view returns (uint) {

        return bank[msg.sender];

    }

}