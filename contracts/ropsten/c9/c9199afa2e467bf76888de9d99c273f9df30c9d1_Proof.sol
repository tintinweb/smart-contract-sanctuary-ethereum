/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

contract Proof {
    // use struct to store FileDetail
    struct FileDetail {
        uint256 timestamp;
        address owner;
    }

    mapping(string => FileDetail) files;    // file hash => FileDetail

    // an event that records if a file is added, when, who added it, and its fileHash
    event logFileAddedStatus(bool status, uint256 timestamp, address owner, string fileHash);

    // set FileDetail
    function set(string memory _fileHash) public {
        if(files[_fileHash].timestamp == 0) {   // add file if the file doesn't exist, and emit logFileAddedStatus with true
            // set the one who calls this function to be the owner of this file
            files[_fileHash] = FileDetail({timestamp:block.timestamp, owner:msg.sender});
            emit logFileAddedStatus(true, block.timestamp, msg.sender, _fileHash);
        }
        else {  // if the file already exists, emit logFileAddedStatus with false
            emit logFileAddedStatus(false, block.timestamp, msg.sender, _fileHash);
        }
    }

    // get FileDetail by fileHash
    function get(string memory _fileHash) public view returns(uint256 timestamp, address owner) {
        require(files[_fileHash].timestamp != 0, "file not exist"); // check if the file exists
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }
}