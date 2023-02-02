/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.18;

contract RandomNumber{

    function getRandomNumber() external view returns(uint) {
            return block.prevrandao;
    }

}