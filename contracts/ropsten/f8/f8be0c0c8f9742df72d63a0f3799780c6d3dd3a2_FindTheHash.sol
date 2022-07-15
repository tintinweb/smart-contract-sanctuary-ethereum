/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED

contract FindTheHash {
    bytes32 numberHash = 0xdb81b4d58595fbbbb592d3661a34cdca14d7ab379441400cbfa1b78bc447c365;

    function findHash() public view returns(uint8 solution) {
        for(uint8 i = 0; i < 256; i++) {
            if (keccak256(abi.encodePacked(i)) == numberHash) {
                return i;
            }
        }
    }
}