// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TrustChain {
    address private _owner;

    event TrustChainDataStored (
        uint indexed version,
        uint indexed fromDate,
        uint indexed toDate,
        string hash
    );

    constructor () {
        _owner = msg.sender;
    }

    function storeTrustChainData(uint version, uint fromDate, uint toDate, string memory hash) public {
        require(msg.sender == _owner, "contract owner required");
        emit TrustChainDataStored(version, fromDate, toDate, hash);
    }
}