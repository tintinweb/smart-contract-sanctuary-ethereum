// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title NotarizerWeb
/// @author ZirconTech
/// @notice It allows you to notarize IPFS CIDs in an easy way, charging a pretty small fee.
/// @dev It allows you to notarize IPFS CIDs in an easy way, charging a pretty small fee.

struct Content {
    uint256 contentId;
    string ipfsHash;
    address notary;
}

contract NotarizerWeb {
    // State Variables
    mapping(uint256 => Content) public contents;
    mapping(string => bool) public notarizedHashes;
    uint256 public contentId;
    address constant ZIRCON_WALLET = 0x3099a9d5a86e16Cd363c2CD8867F5b3035f6F5D7; // testing wallet

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

    // Functions

    function _getFee() internal pure returns (uint256) {
        // Logic for updating fee goes here
        // currentFee expressed in wei
        uint currentFee = 100000000000000; // Equivalent to 0.0001 Ether
        return currentFee;
    }

    function notarizeCID(
        string memory _ipfsHash,
        string memory _tag
    ) public payable onlyValidHashed(_ipfsHash) returns (uint256) {
        uint fee = _getFee();
        require(msg.value >= fee, "Must cover fee value");
        require(notarizedHashes[_ipfsHash] == false, "Already notarized");
        contentId++;
        // Notarization logic
        Content memory content;
        content.contentId = contentId;
        content.ipfsHash = _ipfsHash;
        content.notary = msg.sender;

        contents[contentId] = content;
        notarizedHashes[_ipfsHash] = true;

        emit Notarize(msg.sender, _ipfsHash, _tag);

        return contentId;
    }

    function withdrawCollectedFees(uint _amount) external payable {
        require(msg.sender == ZIRCON_WALLET, "only ZirconTech can withdraw");
        require(address(this).balance >= _amount, "request exceeds balance");
        (bool sent, bytes memory data) = ZIRCON_WALLET.call{value: (_amount)}(
            ""
        );
        require(sent, "Failed to send Ether");
    }

    function getIpfsHash(uint _contentId) public view returns (string memory) {
        Content memory content;
        content = contents[_contentId];
        string memory ipfsHash = content.ipfsHash;
        return ipfsHash;
    }

    function isHashNotarized(
        string memory _ipfsHash
    ) public view onlyValidHashed(_ipfsHash) returns (bool) {
        return notarizedHashes[_ipfsHash];
    }
}