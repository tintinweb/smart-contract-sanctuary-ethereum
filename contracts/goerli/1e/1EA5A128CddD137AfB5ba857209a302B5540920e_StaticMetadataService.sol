//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

contract StaticMetadataService {
    string private _uri;
    address public owner;

    constructor(string memory _metaDataUri) {
        _uri = _metaDataUri;
        owner = msg.sender;
    }

    function uri(uint256) public view returns (string memory) {
        return _uri;
    }

    function setUri(string memory _metaDataUri) public {
        require(msg.sender == owner, "Only the contract owner can set the URI.");
        _uri = _metaDataUri;
    }
}