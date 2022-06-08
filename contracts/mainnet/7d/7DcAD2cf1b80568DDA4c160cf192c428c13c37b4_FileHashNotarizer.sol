// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract FileHashNotarizer is Ownable {
    struct FileDetails {
        string owner;
        string provider;
        string requestTimestamp;
    }
    mapping(bytes32 => FileDetails[]) public document;

    event Notarization(bytes32 hash, string owner, string provider);

    function notarize(bytes32 hash, string memory owner, string memory provider, string memory timestamp) public {
        require((bytes(owner)).length>0);
        require((bytes(provider)).length>0);
        require((bytes(timestamp)).length>0);

        document[hash].push(FileDetails({
            owner : owner,
            provider : provider,
            requestTimestamp : timestamp
        }));
        emit Notarization(hash, owner, provider);
    }

    function checkHash(bytes32 hash) public view returns(uint) {
        return document[hash].length;
    }
}