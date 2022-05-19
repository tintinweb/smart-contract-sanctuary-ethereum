/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// File: contracts/h.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleBank{
    mapping(address => uint) private bank;

    function withdraw(uint amount) external payable{
        (bool send,)=msg.sender.call{value: amount}("");
        require(amount<=bank[msg.sender] && send, "Insufficient fund");
        bank[msg.sender]=bank[msg.sender]-amount;
    }

    function deposit() external payable {
        bank[msg.sender]=bank[msg.sender]+msg.value;
    }

    function getBalance() public view returns (uint){
        return bank[msg.sender];
    }
}