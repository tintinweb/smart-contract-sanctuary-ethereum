/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

struct HashStampInfo {
    uint blockEth;
    uint timestamp;
}

contract TSAContract {
    address public Owner;

    address public lastCaller;
    bool public lastCheck;
    uint public c;

    uint256 private _currentID;

    

    constructor() {
        _currentID = 0;
        Owner = msg.sender;
    }

    function isOwner(address caller) public view returns (bool) {
        return caller == Owner;
    }

    function StampHash(bytes32 hash) public {
        c = hash.length;
        lastCaller = msg.sender;
        lastCheck = isOwner(msg.sender);
    }

   
}