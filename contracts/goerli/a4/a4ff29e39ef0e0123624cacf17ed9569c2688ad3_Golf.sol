/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Golf {
    function test(uint256 num) public pure returns (bytes memory) {
        return (abi.encodePacked(num));
    }
}