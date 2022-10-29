// SPDX-License-Identifier: MIT
// https://github.com/exfluency/TrustChain

pragma solidity ^0.8.9;

contract TrustChain {
    address private _owner;

    event TrustChainDataStored (
        uint indexed version,
        uint indexed dateFrom,
        uint indexed dateTo,
        string hash
    );

    constructor () {
        _owner = msg.sender;
    }

    function storeTrustChainData(uint version, uint fromDate, uint toDate, string memory hash) public {
        require(msg.sender == _owner, "contract owner required");
        emit TrustChainDataStored(version, fromDate, toDate, hash);
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == _owner, "contract owner required");
        _owner = newOwner;
    }
}