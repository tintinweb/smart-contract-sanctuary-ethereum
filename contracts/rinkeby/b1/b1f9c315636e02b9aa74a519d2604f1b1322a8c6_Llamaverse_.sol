/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Llamaverse_ {

    string s2 = " @Llamaverse_";

    function concatenate(string memory s1) public view returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }
}