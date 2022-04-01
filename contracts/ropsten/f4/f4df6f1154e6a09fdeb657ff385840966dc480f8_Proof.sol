/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract Proof {    //自定義一個contract結構
    struct FileDetail{
        uint256 timestamp;
        string owner;
    }

mapping(string => FileDetail) files; //宣告一個mapping，用key值尋找contract的內容

event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash); //宣告一個event

function set(string memory _owner, string memory _fileHash) public { //建立一個set fuction
    if(files [_fileHash].timestamp == 0) {  //判斷是否被使用過
        files [_fileHash] = FileDetail({timestamp:block.timestamp, owner:_owner}); //把現在時間、擁有者寫入檔案
        emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash); //觸發事件將事件設為已被讀取
    } 
    else {
        emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash); //如果不是第一次執行，回傳False。
    }
}

function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner) { //宣告一個get fuction
    return (files[_fileHash].timestamp, files[_fileHash].owner);    //回傳時間戳記及擁有者資訊
    }
}