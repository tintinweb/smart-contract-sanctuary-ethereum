/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract neko {
    uint public block_time;

    function getTime() public view returns (uint){
        return block.timestamp;
    }

    function getSetted() public view returns (uint) {
        return block_time;
    }

    function setTime(uint timestamp) public {
        block_time = timestamp;
    }

    function checkTime() public view returns (bool) {
        return block_time > block.timestamp;
    }

}