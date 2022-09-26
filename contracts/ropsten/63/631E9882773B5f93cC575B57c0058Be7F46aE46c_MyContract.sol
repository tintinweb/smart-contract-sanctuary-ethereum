/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    uint public gCount;     
    mapping(uint => g) public _gByIdx;
    
    struct g {
        uint gIdx;
        string gName;
    }

    event gCreated(uint, string, uint, string);  
    function creatG(string memory _gName) public {
        _gByIdx[gCount].gIdx = gCount;
        _gByIdx[gCount].gName = _gName;
        gCount++;
        emit gCreated((gCount-1), _gName, block.timestamp, "Will This Display?");
    }
}