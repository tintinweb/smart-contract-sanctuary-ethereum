/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract CurrentTime {

    function getTime() public view returns (uint) {
        return block.timestamp;
    }

}