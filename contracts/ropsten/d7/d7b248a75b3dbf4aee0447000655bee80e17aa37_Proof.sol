/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13; //宣告編譯器版本

contract Proof { //宣告合約
    struct FileDetail { //宣告結構
        uint256 timestamp; //宣告時間戳為256位元的無號整數
        string owner; //宣告擁有者為字串
    }

    mapping(string => FileDetail) files; //宣告files mapping

    event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash); //宣告事件

    function set(string memory _owner, string memory _fileHash) public { //宣告函式set，傳入擁有者及檔案雜湊
        if(files[_fileHash].timestamp == 0) { //檔案無時間戳，未被記錄過
            files[_fileHash] = FileDetail({timestamp:block.timestamp, owner:_owner}); //寫入時間戳及擁有者
            emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash); //觸發logFileAddedStatus事件，回傳true, 時間戳, 擁有者, 檔案雜湊
        }
        else {
            emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash); //檔案已有時間戳，觸發logFileAddedStatus事件，回傳false, 時間戳, 擁有者, 檔案雜湊
        }
    }

    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner) { //宣告函式get，傳入檔案雜湊，回傳時間戳, 擁有者
        return (files[_fileHash].timestamp, files[_fileHash].owner); //回傳時間戳, 擁有者
    }
}