/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

 contract RegisterTest {
    event Foo(address indexed msgSender, address indexed owner, string indexed name);
    
    function register(
        address owner,
        string memory name
    ) external payable returns (bytes32) {
    
        emit Foo(msg.sender, owner, name);
        return keccak256(abi.encodePacked(name));
    }
 }