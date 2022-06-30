/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Test {
    function random() public returns(uint256) {
        return uint256(blockhash(block.number));
    }

    function random1() public returns(uint256) {
        return uint256(blockhash(block.number - 1));
    }
}