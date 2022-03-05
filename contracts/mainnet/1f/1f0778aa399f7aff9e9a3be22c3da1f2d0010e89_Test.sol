/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    mapping(address => bool) public whitelist;
    address public owner;

    constructor () {
        owner = msg.sender;
    }

    
    function addToWhitelist(address _address) external {
        require(msg.sender == owner, "Auth Error!");
        whitelist[_address] = true;
    }
}