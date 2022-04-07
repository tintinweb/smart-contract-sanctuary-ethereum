/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13; //編譯器版本

contract Proof{
    struct FileDetail{  // 宣告叫 FileDetail 的 struct 
        uint256 timestamp;
        string owner;
    }

    mapping(string=>FileDetail) files; // 宣告 mapping

    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash); // 宣告 event
    
    function set( string memory _owner, string memory _fileHash) public { // 宣告 function
        if(files[_fileHash].timestamp == 0){  // 判斷 timestamp 是否為 0, 0表示未註冊過
            files[_fileHash] = FileDetail({timestamp:block.timestamp, owner:_owner});  // 寫入資料
            emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash);  // 呼叫 event, 回傳成功
        }else{
            emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash);  // 呼叫 event, 回傳失敗
        }
    }

    function get(string memory _fileHash) public view returns(uint256 timestamp, string memory owner){  // 宣告 fuction
        return (files[_fileHash].timestamp, files[_fileHash].owner);  // 回傳資料
    }
}