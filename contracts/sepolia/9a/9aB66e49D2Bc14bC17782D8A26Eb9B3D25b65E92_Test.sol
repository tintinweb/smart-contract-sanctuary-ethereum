/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    
    function buy(address a, address b) public payable {
        (bool success1, ) = payable(a).call{value: msg.value/2}("");
        (bool success2, ) = payable(b).call{value: msg.value/2}("");
    }
}