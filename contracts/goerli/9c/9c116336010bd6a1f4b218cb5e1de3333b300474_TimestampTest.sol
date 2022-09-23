/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract TimestampTest {
    uint public timestamp ;
    
    function setTimestamp() public {
        timestamp = block.timestamp;
    }

    function timestamps() public view returns(uint, uint) {
        return (timestamp, block.timestamp);
    }
    function blockTimestamp() public view returns(uint) {
        return block.timestamp;
    }
}