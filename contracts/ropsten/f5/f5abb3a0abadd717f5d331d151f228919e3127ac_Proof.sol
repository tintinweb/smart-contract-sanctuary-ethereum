/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: SimPL-2.0

pragma solidity 0.8.13;

contract Proof{

    struct FileDetail{
        uint256 timestamp;
        string owner;
    }

    mapping ( string => FileDetail) files;

    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash);

    function set( string memory _owner, string memory _filehash) public {
        if (files[_filehash].timestamp==0){
          files[_filehash]=FileDetail({ timestamp:block.timestamp, owner: _owner});  
          emit logFileAddedStatus( true , block.timestamp, _owner, _filehash);
        } else {
            emit logFileAddedStatus( false, block.timestamp, _owner, _filehash);
        }
    }

    function get(string memory _filehash) public view returns (uint256 timestamp, string memory owner) {
        return (files[_filehash].timestamp, files[_filehash].owner);

    }

}