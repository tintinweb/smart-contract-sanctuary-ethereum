/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;
contract Proof {
    struct FileDetail{ //宣告結構
        uint256 timestamp;
        string owner;

    }

    mapping(string => FileDetail) files; //設計mapping

    event logFileAddedStatus(bool status,uint256 timestamp ,string owner,string fileHash); // 記錄logging

    function set(string memory  _owner , string memory  _fileHash) public { //設定檔案資料hash、owner

        if(files[_fileHash].timestamp == 0){ //如果時間戳記不存在
            files[_fileHash] = FileDetail({timestamp:block.timestamp,owner:_owner}); //設定資料
            emit logFileAddedStatus(true,block.timestamp,_owner,_fileHash); //增加成功log

        }else{
            emit logFileAddedStatus(false,block.timestamp,_owner,_fileHash); //增加失敗log
        }
    }

    function get(string memory _fileHash) public view returns(uint256 timestamp,string memory  owner){ //get資料
        return (files[_fileHash].timestamp,files[_fileHash].owner); // 回傳資料
    }

}