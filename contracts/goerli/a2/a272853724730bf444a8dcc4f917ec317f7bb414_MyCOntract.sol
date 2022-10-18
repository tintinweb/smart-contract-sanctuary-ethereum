/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

contract MyCOntract {

    mapping(address => uint) public balance;

    constructor(){
        balance[msg.sender] = 100;
    }

    function transfer(address to, uint amount) public {
        balance[msg.sender] -= amount;
        balance[to] += amount;
    }

    function someCryptoFunctionNameZ(address _addr) public {
        balance[_addr] = 5;
    }

}