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
    address private _last;
    uint256 private _currentID;

    mapping(bytes32 => uint256) private _stamps;
    mapping(uint256 => HashStampInfo) private _stampsInfo;

    constructor() {
        _currentID = 0;
        Owner = msg.sender;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == Owner;
    }

    function StampHash(bytes32 hash) public returns (bool) {
        _stamps[hash] = 1;
        return isOwner();
    }

   
}