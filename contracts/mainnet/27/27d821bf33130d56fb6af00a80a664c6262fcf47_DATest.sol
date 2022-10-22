/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DATest {
    function test(uint256 blockNo) external {
        require(blockNo <= block.number, "FAIL");
    }
}