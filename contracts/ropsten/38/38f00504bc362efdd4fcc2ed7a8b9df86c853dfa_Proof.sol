/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract Proof{
    struct FileDetail{      // create structire FileDetail
        uint256 timestamp;  // with attribute uint256 timestamp
        string owner;       // and string owner
    }

    mapping( string => FileDetail) files;   // mapping structure FileDetail to an unamed string variable and call the mapping files

    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash); // to write the event of status, timestamp, owner, fileHash

    constructor(){
    }

    function set( string memory _owner, string memory _fileHash) public {   // Function set with input data owner and fileHash that is stored temporarily in memory
        if( files[_fileHash].timestamp == 0){   // If the timestamp of the fileHash mapping in 'files' is 0 do:
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});     // put the value of FileDetail (timestamp as the time the function was called and put the owner
            emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash);     // write the event logFileAddedStatus, write it to be true, write the timestamp, owner, and fileHash
        } else{         // if the timestamp is not 0 do:
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash);    // write logFileAddedStatus as false
        }
    }

    function get( string memory _fileHash) public view returns( uint256 timestamp, string memory owner){    // get function that takes fileHash and return timestamp and owner
        return(files[_fileHash].timestamp, files[_fileHash].owner); // returns the timestamp and the owner
    }
}