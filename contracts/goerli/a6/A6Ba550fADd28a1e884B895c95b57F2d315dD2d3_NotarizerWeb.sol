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
    uint256 size; // in bytes
    string mimeType;
    string ISODate;
    string tag;
}

contract NotarizerWeb {
    // State Variables
    mapping(uint256 => Content) public contents;
    mapping(string => bool) public notarizedHashes;
    uint256 public contentId;
    address constant ZIRCON_WALLET = 0x3099a9d5a86e16Cd363c2CD8867F5b3035f6F5D7; // testing wallet

    mapping(address => uint256) public notarizationsPerUser;
    mapping(address => uint256) public storageUsedPerUser;
    mapping(address => uint256) public tagsPerUser;

    mapping(string => mapping(address => bool)) isTagUsedByUser;

    // Events
    event Notarize(
        address indexed notary,
        string indexed ipfsHash,
        string indexed tag,
        Content content
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
    function withdrawCollectedFees(uint _amount) external {
        require(msg.sender == ZIRCON_WALLET, "only ZirconTech can withdraw");
        require(address(this).balance >= _amount, "request exceeds balance");
        (bool sent, ) = ZIRCON_WALLET.call{value: (_amount)}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawAllCollectedFees() external {
        require(msg.sender == ZIRCON_WALLET, "only ZirconTech can withdraw");
        (bool sent, ) = ZIRCON_WALLET.call{value: (address(this).balance)}("");
        require(sent, "Failed to send Ether");
    }

    function notarizeCID(
        string memory _ipfsHash,
        string memory _tag,
        uint256 _size,
        string memory _mimeType,
        string memory _ISODate
    ) public payable onlyValidHashed(_ipfsHash) returns (uint256) {
        uint fee = _getFee();
        require(msg.value >= fee, "Must cover fee value");
        require(notarizedHashes[_ipfsHash] == false, "Already notarized");
        contentId++;

        Content memory content = Content(
            contentId,
            _ipfsHash,
            msg.sender,
            _size,
            _mimeType,
            _ISODate,
            _tag
        );

        contents[contentId] = content;
        notarizedHashes[_ipfsHash] = true;

        emit Notarize(msg.sender, _ipfsHash, _tag, content);

        notarizationsPerUser[msg.sender]++;
        storageUsedPerUser[msg.sender] += _size;
        if (!isTagUsedByUser[_tag][msg.sender]) {
            tagsPerUser[msg.sender]++;
            isTagUsedByUser[_tag][msg.sender] = true;
        }

        return contentId;
    }

    function getIpfsHash(uint _contentId) public view returns (string memory) {
        return contents[_contentId].ipfsHash;
    }

    function getContent(uint _contentId) public view returns (Content memory) {
        return contents[_contentId];
    }

    function isHashNotarized(
        string memory _ipfsHash
    ) public view onlyValidHashed(_ipfsHash) returns (bool) {
        return notarizedHashes[_ipfsHash];
    }

    function _getFee() internal pure returns (uint256) {
        // Logic for updating fee goes here
        // currentFee expressed in wei
        uint currentFee = 100000000000000; // Equivalent to 0.0001 Ether
        return currentFee;
    }
}