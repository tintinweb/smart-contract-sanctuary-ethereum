/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

contract Proof {
    struct FileDetail {     // struct for file, saving timestamp, owner
        uint256 timestamp;
        string owner;
    }
    // file hash => file detail
    mapping(string => FileDetail) files;

    event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash);    // event for adding file status (true or false)

    function set(string memory _owner, string memory _fileHash) public {    // save file hash and set owner, return success or not
        if (files[_fileHash].timestamp == 0) {
            files[_fileHash] = FileDetail({timestamp:block.timestamp, owner: _owner});
            emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash);
        } else {
            emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash);
        }
    }

    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {    // return timestamp and owner with file hash
        return (files[_fileHash].timestamp, files[_fileHash].owner); 
    }
}