// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error Notato_NotOwner();

contract Notato {
    struct Doc {
        uint256 time;
        address notary;
    }

    mapping(bytes32 => Doc) docRecord;

    address private immutable i_owner;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Notato_NotOwner();
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function addHash(
        bytes32 _documentHash,
        address _notary
    ) external onlyOwner {
        docRecord[_documentHash] = Doc(block.timestamp, _notary);
    }

    function getTimestamp(bytes32 _documentHash) public view returns (uint256) {
        return docRecord[_documentHash].time;
    }

    function getNotary(bytes32 _documentHash) public view returns (address) {
        return docRecord[_documentHash].notary;
    }

    function getContractOwner() public view returns (address) {
        return i_owner;
    }
}