/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register {
    //mapping for storing urls of manufacturers
    mapping(address => string) public register;
    //array containing manufacturers' addresses
    address[] manufacturers;

    //function that adds a manufacturer to the register
    function addNewManufacturer(string memory url) public returns (bool) {
        register[msg.sender] = url;
        manufacturers.push(msg.sender);
        return true;
    }
}