/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//alice wana to deploy this contract 
contract FindThisHash {
    bytes32 constant hash = 0x564ccaf7594d66b1eaaea24fe01f0585bf52ee70852af4eac0cc4b04711cd0e2;

    constructor() payable {}

    function solve(string memory solution) public {
        require(hash == keccak256(abi.encodePacked(solution)), "Incorrect answer");
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
        
    }
}

// I change the 10 ether to address(this).balance for simplicity!