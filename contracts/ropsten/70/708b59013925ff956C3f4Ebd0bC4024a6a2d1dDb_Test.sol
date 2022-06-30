// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Test {
    event Some(uint256 hash);

    function random() public {
        emit Some(uint256(blockhash(block.number)));
    }

    function random1() public {
        emit Some(uint256(blockhash(block.number - 1)));
    }
}