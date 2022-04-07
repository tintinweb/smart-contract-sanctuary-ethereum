/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract Proof{
    struct filedetail{
        uint256 timestamp;
        string owner;

    }

    mapping(string => filedetail)files;

    event log(bool status,uint256 timestamp,string owner,string filehash);

    function set(string memory _owner,string memory _fileHash)public {
        if(files[_fileHash].timestamp == 0){
            files[_fileHash] = filedetail({timestamp:block.timestamp,owner:_owner}) ;
            emit log(true,block.timestamp,_owner,_fileHash);

        } 
        else{
            emit log(false,block.timestamp,_owner,_fileHash);
        }
    }

    function get(string memory _filehash)public view returns(uint256 timestamp,string memory owner){
        return(files[_filehash].timestamp,files[_filehash].owner);
    }
}