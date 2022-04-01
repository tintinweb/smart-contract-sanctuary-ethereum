/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract Proof {    //定義Proof結構
    struct FileDetail{
        uint256 timestamp;
        string owner;
    }

mapping(string => FileDetail) files; //建構一個mapping，利用_fileHash值尋找FileDetail結構

event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash); //宣告一個event

function set(string memory _owner, string memory _fileHash) public { 
    if(files [_fileHash].timestamp == 0) {  //利用時間戳記判斷是否被使用過
        files [_fileHash] = FileDetail({timestamp:block.timestamp, owner:_owner}); //將時間、擁有者寫入檔案
        emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash); //觸發事件將事件設為使用
    } 
    else {
        emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash); //如果不是第一次執行，回傳False。
    }
}

function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner) { 
    return (files[_fileHash].timestamp, files[_fileHash].owner);    //回傳時間戳記及擁有者資訊
    }
}