/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: SimPL-2.0

pragma solidity 0.8.13;

contract Proof {
    struct FileDetail{
        uint256 timestamp;
        string owner;
    }

    mapping( string => FileDetail) files;

    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash);

    function set( string memory _owner, string memory _fileHash) public{ // 文件雜湊值
        if( files[_fileHash].timestamp == 0){
            files[_fileHash] = FileDetail({timestamp:block.timestamp, owner:_owner}); //block.timestamp時間雜湊區塊
            emit logFileAddedStatus( true,block.timestamp,_owner,_fileHash);
        } else{
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash); //雜湊失敗
        }
    }

    function get( string memory _fileHash) public view returns (uint256 timestamp,string memory owner){ //函數行為設定為 view 效能較好
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }
}