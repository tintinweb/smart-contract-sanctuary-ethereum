/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register {
    //Mapping for storing urls of manufacturers
    mapping(address => string) public register;
    //Array containing manufacturers addresses
    address[] public manufacturers;

    //Function that adds manufacturer
    function addManufacturer(string memory url) public returns (bool) {
        register[msg.sender] = url;
        manufacturers.push(msg.sender);
        return true;
    }
}