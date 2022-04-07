/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0
// Contract practiced by 108820003, NTUT.
pragma solidity ^0.8.13;

contract FileProofer {
    struct FileDetail {
        // The update time of this detail
        uint256 updateAt;

        // The owner address of this detail
        address owner;
    }
    
    // A map to store the file details by their checksum hash.
    // Key: (string) checksum; Value: (FileDetail) the fileDetail.
    mapping(string => FileDetail) records;
    
    // An event which describing the file detail at a moment.
    // When the information of a file is published on the chain for the first time, the record will be recorded as the "first" record.
    event logFileDetailRecord(bool isFirstRecord, uint256 updateAt, address indexed owner, string checksum);

    // Comapre if the provided string is same.
    // Using keccak256 hash to compare.
    function strEq(string memory a, string memory b) internal pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        }

        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // A pre-check modifier to check if a string type data is not an empty string.
    modifier shouldNotEmpty(string calldata data) {
        // If the given data is empty, the following operation will be canceled.
        require(!strEq(data, ""));
        _;
    }
    
    // Record the owner of the checksum and broadcast it to the chain.
    function setFileOwner(string calldata _fileHash) public shouldNotEmpty(_fileHash) {
        // For checking if the provided checksum(fileHash) has already exists in the storage.
        bool isFileExists = records[_fileHash].updateAt != 0;

        // The current operation block time.
        uint256 currentBlockTime = block.timestamp;

        // The operator of this action, we always consider the account that initiated this action to be the owner of the file.
        address operator = msg.sender;

        // If the checksum does not exist in the storage, create it.
        if (!isFileExists) {
            records[_fileHash] = FileDetail({
                updateAt: currentBlockTime,
                owner: operator
            });
        }

        // Propagating new records onto the chain.
        emit logFileDetailRecord(!isFileExists, currentBlockTime, operator, _fileHash);
    }
    
    // Obtain the corresponding record according to the provided check code.
    function getFileRecord(string calldata _fileHash) public view shouldNotEmpty(_fileHash) returns (bool isExists, uint256 updateAt, address owner) {
        // Get the saved detail by the given checksum.
        FileDetail memory fileDetail = records[_fileHash];

        isExists = fileDetail.owner != address(0x0);
        updateAt = fileDetail.updateAt;
        owner = fileDetail.owner;
    }

    // Check if the operator is the owner of the record.
    function isBelonsToMe(string calldata _fileHash) public view shouldNotEmpty(_fileHash) returns (bool) {
        // Get the record from storage.
        (bool isExists,, address owner) = getFileRecord(_fileHash);

        return isExists && owner == msg.sender;
    }
}