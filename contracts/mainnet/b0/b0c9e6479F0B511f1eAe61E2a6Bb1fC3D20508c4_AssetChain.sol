// SPDX-License-Identifier: MIT
// https://github.com/exfluency/AssetChain

pragma solidity ^0.8.9;

contract AssetChain {
    address private _owner;

    event AssetChainDataStored (
        uint indexed version,
        uint indexed dateFrom,
        uint indexed dateTo,
        string hash
    );

    constructor () {
        _owner = msg.sender;
    }

    function storeAssetChainData(uint version, uint fromDate, uint toDate, string memory hash) public {
        require(msg.sender == _owner, "contract owner required");
        emit AssetChainDataStored(version, fromDate, toDate, hash);
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == _owner, "contract owner required");
        _owner = newOwner;
    }
}