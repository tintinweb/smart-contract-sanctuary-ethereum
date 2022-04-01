/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: SPDX-License
pragma solidity ^0.8.13;

contract Proof{
    struct FileDetail{
        uint256 timestamp;  //定義時間戳
        string owner;       //定義管理員
    }

    mapping(string => FileDetail) files;    //映射FileDetail到files

    event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash);    //emit後執行event，確認管理員與時間戳

    function set(string memory _owner, string memory _fileHash) public{
        if (files[_fileHash].timestamp == 0){   //如果某個files的雜湊值等於0，即未紀錄
            files[_fileHash] = FileDetail({timestamp: block.timestamp, owner: _owner}); //寫入此雜湊值對應的時間戳與管理員
            emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash);  //紀錄管理員與時間戳
        }else{
            emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash); //若已記錄，回傳flase與對應的時間戳跟管理員
        }
    }

    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner){
        return (files[_fileHash].timestamp, files[_fileHash].owner);    //得到某雜湊值的時間戳與管理員
    }
}