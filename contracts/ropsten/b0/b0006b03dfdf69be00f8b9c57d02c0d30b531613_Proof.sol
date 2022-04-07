/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: SimPL-2.0

pragma solidity 0.8.13; //使用0.8.13的版本

contract Proof { //合約宣告
    struct FileDetail{ //定義FileDetail型態 包含哪些資料型別
        uint256 timestamp; //時間戳
        string owner;
    }

    mapping (string => FileDetail) files; //根據檔案雜湊值找檔案擁有者和時間戳 fils是變數

    event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash); //定義事件

    function set(string memory _owner, string memory  _fileHash) public { //輸入檔案擁有者和檔案Hash值
        if (files[_fileHash].timestamp == 0){ //如果檔案的時間戳為0
            files[_fileHash] = FileDetail({timestamp:block.timestamp, owner:_owner}); //寫入時間戳跟擁有者
            emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash); //表示事件成功 用廣播
        }else{
            emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash); //表示事件失敗 用廣播
        }
    }

    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner){
        return (files[_fileHash].timestamp,files[_fileHash].owner);
    } //透過Hash值 查看時間戳和擁有者


}