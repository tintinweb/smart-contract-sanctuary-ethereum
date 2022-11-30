/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract Random {

    uint nonce;

    function random () public returns (uint){
        nonce ++;
        return uint(keccak256(abi.encodePacked(nonce, block.timestamp))) % 100;
    }

}