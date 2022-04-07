/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: test
pragma solidity 0.8.13;

contract Proof {

    struct FileDetail{
        uint256 timestamp;
        string owner;
 
    }
 
    mapping (string  => FileDetail) files;
 
    event logFileAddedStatus( bool status, uint256 timestamp, string  owner, string  fileHash);
 
    function set(string memory _owner, string memory _fileHash) public {
        if (files[_fileHash].timestamp == 0){
            files[_fileHash] = FileDetail({ timestamp:block.timestamp, owner:_owner});
            emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash);
        } else{
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash);
        }
    }
 
    function get( string memory _fileHash) public view returns (uint256 timestamp, string memory owner){
        return (files[_fileHash].timestamp, files [_fileHash].owner);
    }
}