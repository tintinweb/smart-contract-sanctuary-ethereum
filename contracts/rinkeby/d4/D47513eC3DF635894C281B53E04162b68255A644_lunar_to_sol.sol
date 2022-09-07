// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;


contract lunar_to_sol {
    mapping(address => string) eth_to_sol;
    string[] addresses;
    
    function manipulateMapOfMap(string calldata spender) external {
        eth_to_sol[msg.sender] = spender;
    }

    function getAll(address eth_addr) public view returns (string memory){
        return eth_to_sol[eth_addr];
    }
}