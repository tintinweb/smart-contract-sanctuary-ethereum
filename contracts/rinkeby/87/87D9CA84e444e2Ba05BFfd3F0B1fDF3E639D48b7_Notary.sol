// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract Notary {
    mapping(string => string) private _timestamps;

    function AddTimestamp(string memory hash, string memory datetime) public {
        _timestamps[hash] = datetime;
    }

    function GetTimestamp(string memory hash) public view returns(string memory) {
        return _timestamps[hash];
    }
}