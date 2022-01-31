/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BlockNumberTest{
    uint256 number;
    function isBlock(uint256 targetBlock) public{
        uint256 currentBlock = block.number;
        require(currentBlock == targetBlock);
        number = number + 1;
    }
}