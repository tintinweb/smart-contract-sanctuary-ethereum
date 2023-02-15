/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.18;

contract Clock {

    function getTimestamp() public view returns(uint) {
        return block.timestamp;
    }

}