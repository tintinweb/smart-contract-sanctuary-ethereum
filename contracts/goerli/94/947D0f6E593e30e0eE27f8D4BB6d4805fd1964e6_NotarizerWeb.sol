// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Content {
    uint256 contentId;
    string ipfsHash;
    address notary;
}

contract NotarizerWeb {
    // State Variables
    mapping(uint256 => Content) public contents;
    // Events
    event Notarize(
        address indexed _notary,
        string indexed _ipfsHash,
        string indexed _tag
    );
    // Modifiers
    modifier onlyValidHashed(string memory s) {
        bytes memory b = bytes(s);
        require(b.length == 46, "This is not an accepted IpfsHash");
        require(
            (b[0] == "Q" && b[1] == "m"),
            "Invalid IpfsHash, must be a CIDv0"
        );
        _;
    }

    function notarizeCID(
        uint _contentId,
        string memory _ipfsHash,
        string memory _tag
    ) public onlyValidHashed(_ipfsHash) {
        // Notarization logic
        Content memory content;
        content.contentId = _contentId;
        content.ipfsHash = _ipfsHash;
        content.notary = msg.sender;

        contents[_contentId] = content;

        emit Notarize(msg.sender, _ipfsHash, _tag);
    }

    function getIpfsHash(uint _contentId) public view returns (string memory) {
        Content memory content;
        content = contents[_contentId];
        string memory ipfsHash = content.ipfsHash;
        return ipfsHash;
    }
}