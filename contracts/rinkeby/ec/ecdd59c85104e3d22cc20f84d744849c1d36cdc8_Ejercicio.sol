/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Ejercicio{
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Peinate!!");
        _;
    }
    
    function getBalance() view external isOwner returns(string memory) {
        return "hola";
    }
}