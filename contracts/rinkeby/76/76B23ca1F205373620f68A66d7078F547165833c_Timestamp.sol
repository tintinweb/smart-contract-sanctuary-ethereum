/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Timestamp{
    function getTimestamp() public view returns(uint256) {
        return block.timestamp;
    }
}