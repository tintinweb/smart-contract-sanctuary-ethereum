/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Merge {

    function happened() public view returns(uint) {
        return block.difficulty;
    }

}