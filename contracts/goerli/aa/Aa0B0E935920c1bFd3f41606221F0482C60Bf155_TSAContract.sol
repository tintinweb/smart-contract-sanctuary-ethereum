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
    address private _owner;
    address private _last;
    uint256 private _currentID;

    mapping(bytes32 => uint256) private _stamps;
    mapping(uint256 => HashStampInfo) private _stampsInfo;

    constructor() {
        _currentID = 0;
        _owner = msg.sender;
    }

    function StampHash(bytes32 hash) public {
        _last = msg.sender;
        _stamps[hash] = 1;
    }

    function Last() public view returns (address) {
        return _last;
    }
}