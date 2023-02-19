/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract TukarToken {
    address PANCAKE_FACTORY = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address PANCAKE_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    function getAddress() public view returns(address){
        return PANCAKE_ROUTER;
    }
}