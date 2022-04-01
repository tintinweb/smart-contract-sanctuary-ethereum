/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

contract Proof {
    struct FileDetall{
        uint256 timestamp;
        string owner;
    }
    mapping( string => FileDetall) files;

    event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash);

    constructor() public{}
    
    function set (string _owner, string _fileHash) public {
        if(files[_fileHash].timestamp == 0) {
            files[_fileHash] = FileDetall({timestamp:block.timestamp, owner:_owner});
            emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash);
        }else{
            emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash);
        }
    }
    function get (string _fileHash) public view returns (uint256 timestamp, string owner){
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }
}