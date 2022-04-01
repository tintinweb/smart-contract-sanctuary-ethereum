/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: SimPL-2.0

pragma solidity 0.8.13;

contract Proof{

    struct FileDetail{ //build a struct containing 2 attributes of timestamp and owner
        uint256 timestamp;
        string owner;
    }

    mapping ( string => FileDetail) files; //create a mapping with a string key to a FileDetail value, mapping called files

    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash); //create an event to record wether file log is successful, also containing timestamp、owner、filehash

    function set( string memory _owner, string memory _filehash) public {
        if (files[_filehash].timestamp==0){  //to check wether the files in index 「_filehash」has a timestamp recorder already, if timestamp is not 0, this means that the 「_filehash」already has an inputted attribute
          files[_filehash]=FileDetail({ timestamp:block.timestamp, owner: _owner});  //build a new constructor on mapping "files" with index "_filehash" containing current timestamp and owner name
          emit logFileAddedStatus( true , block.timestamp, _owner, _filehash); //emit an event that log that a file has been added successfuly
        } else {
            emit logFileAddedStatus( false, block.timestamp, _owner, _filehash); //emit an event that log that the file add wasn't successful
        }
    }

    function get(string memory _filehash) public view returns (uint256 timestamp, string memory owner) {
        return (files[_filehash].timestamp, files[_filehash].owner); //return the timestamp and owner from mapping "files" with index "_filehash" 

    }

}