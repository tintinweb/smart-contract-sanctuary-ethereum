/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: SimPL 2.0
pragma solidity 0.8.13;

contract Proof {
    //建立FileDetail結構，裡面包含兩個參數：timestamp為時間戳記，owner為持有者
    struct FileDetail{ 
        uint256 timestamp; 
        string owner;
    }

    //以檔案雜湊映射FileDetail結構
    mapping(string => FileDetail) files; 

    //宣告logFileAddedStatus事件，監控增添文件的狀態，當有人新增文件時會廣播給log
    event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash); 

    //新增文件
    function set(string memory _owner, string memory _fileHash) public{
        //當時間戳記為0表示文件未建立過
        if( files[_fileHash].timestamp == 0){ 
            //建立文件
            files[_fileHash] = FileDetail({ timestamp:block.timestamp, owner:_owner}); 
            //回傳event目前的狀態
            emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash); 
        }else{
            //此文件已存在，回傳event目前的狀態
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash);
        }
    }
    //查詢文件
    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {
        //傳回該文件被建立時的時間戳及文件持有者
        return (files[_fileHash].timestamp, files[_fileHash].owner); 
    }
}