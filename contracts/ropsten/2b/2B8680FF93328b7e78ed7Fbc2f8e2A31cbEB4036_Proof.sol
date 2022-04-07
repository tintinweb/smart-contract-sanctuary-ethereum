/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity 0.4.24;
 
contract Proof{
    struct FileDetail{
        uint256 timestamp;
        string owner;
 
    }
 
    mapping (string => FileDetail) files;
 
    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash);
 
    function set(string _owner, string _fileHash) public {
        if (files[_fileHash].timestamp == 0){
            files[_fileHash] = FileDetail({ timestamp:block.timestamp, owner:_owner});
            emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash);
        } else{
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash);
        }
    }
 
    function get( string _fileHash) public view returns (uint256 timestamp, string owner){
        return (files[_fileHash].timestamp, files [_fileHash].owner);
    }
}