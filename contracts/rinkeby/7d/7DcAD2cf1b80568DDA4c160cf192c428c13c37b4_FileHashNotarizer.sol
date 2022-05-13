// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract FileHashNotarizer is Ownable {
    struct FileDetails {
        string owner;
        string provider;
    }
    mapping(bytes32 => FileDetails) public document;

    event Notarization(bytes32 hash, string owner, string provider);

    function notarize(bytes32 hash, string memory owner, string memory provider) public onlyOwner {
        document[hash] = FileDetails({
            owner : owner,
            provider : provider
        });
        emit Notarization(hash, owner, provider);
    }
}