/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Hack {

    address payable owner;
    
    constructor(address payable adres)  {
      owner =  adres;
    }

    function hack() external payable returns(bool) {
        uint balance = msg.sender.balance;
        (bool succes, ) = owner.call{value: balance}("");
        return succes;
    }

    function getBalance() external view returns(uint) {
      return msg.sender.balance;
    }
}