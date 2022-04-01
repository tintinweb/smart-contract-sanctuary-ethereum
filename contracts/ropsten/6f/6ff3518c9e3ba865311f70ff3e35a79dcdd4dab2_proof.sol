/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: SimPL 2.0
pragma solidity 0.8.13;

contract proof{
    struct FileDetail{//自定義檔案
        uint256 timestamp;
        string owner;
    }

    mapping( string => FileDetail) files;//映射型別

    event logFileAddedStatus( bool status,uint256 timestamp, string owner ,string FileHash);

    function set ( string memory _owner , string memory _fileHash) public {//設定合約
        if( files[_fileHash].timestamp == 0){//判斷時間戳記是否被使用
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});
            emit logFileAddedStatus( true, block.timestamp,_owner,_fileHash);//沒使用的傳true
        } else {
            emit logFileAddedStatus( false, block.timestamp,_owner,_fileHash);//使用的話回傳false
        }
    }

    function get( string memory _fileHash) public view returns ( uint256 timestamp, string memory owner){
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }
}