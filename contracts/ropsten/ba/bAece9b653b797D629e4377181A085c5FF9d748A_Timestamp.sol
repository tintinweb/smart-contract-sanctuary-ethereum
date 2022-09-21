/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract Timestamp{
    uint public Blocktime;
    uint public After2min;
    constructor(){
        Blocktime = block.timestamp;
        After2min = block.timestamp + 2 minutes;
    }
    function hasClosed() public view returns (bool) {
    return Blocktime > After2min;
    }
}