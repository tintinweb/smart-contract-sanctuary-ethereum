/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract TestTimestamp {

    function Test() public view returns (uint) {
        return block.timestamp;
    }

}