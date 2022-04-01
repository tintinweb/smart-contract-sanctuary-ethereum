/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: GLP-3.0
pragma solidity 0.8.13;

contract Proof {
    struct FileDetail {
        uint256 timestamp;
        string owner;
    }
    //define FileDetail's struct

    mapping(string => FileDetail) files;
    //mapping file hash to FileDetail

    event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash);
    //add status of data(bool)

    function set(string memory _owner, string memory _fileHash) public {
        if (files[_fileHash].timestamp == 0) {
            files[_fileHash] = FileDetail({timestamp:block.timestamp, owner: _owner});
            emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash);
        } else {
            emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash); 
        }
    }
    //save file and set owner if success set status true if already exist set false

    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {
        return (files[_fileHash].timestamp, files[_fileHash].owner); 
    }
    //get timestamp and owner with filehash
}