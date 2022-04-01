/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract Proof {
    struct FileDetail{
        uint256 timestamp;
        string owner;
    }

mapping(string => FileDetail) files; //可直接用雜湊值找到檔案資訊

event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash); //宣告一個事件

function set(string memory _owner, string memory _fileHash) public {
    if(files [_fileHash].timestamp == 0) { //若時間戳記為0，代表資料沒被上傳過
        files [_fileHash] = FileDetail({timestamp:block.timestamp, owner:_owner}); //紀錄檔案的資訊
        emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash); //若資料為第一次被上傳，則判斷為true，並紀錄在區塊鏈上
    } else{


        emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash); //若回傳值為false，代表這個資料已經被別人上傳過，鏈上會發出通知
    }
}

function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {
    return (files[_fileHash].timestamp, files[_fileHash].owner); //可以查看檔案的時間戳記和owner，證明owner是自己
    }
}