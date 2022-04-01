/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: SimPL 2.0
pragma solidity 0.8.13;

contract Proof {

    // 建立fileDetail這個struct，包含時間戳和擁有者兩個參數
    struct FileDetail{
        uint256 timestamp;
        string owner;
    }

    mapping (string => FileDetail) files; // 檔案的雜湊值對應fileDetail

    event logFileAddedStatus(bool status, uint256 timesteamp, string owner, string fileHash); // 宣告一個event，當有人新增文件時會廣播給log

    // 新增文件，輸入文件擁有者與文件的雜湊值
    function set(string memory _owner, string memory _fileHash) public {
        if(files[_fileHash].timestamp == 0) {  // 時間戳等於0表示文件尚未被新增過，才可將fileDetail填入資料
            files[_fileHash] = FileDetail({timestamp:block.timestamp, owner:_owner}); // 將時間戳與文件擁有者填入fileDetail
            emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash); // 回傳event目前的狀態，會顯示在log（時間戳是指監聽event時當下的時間戳）
        } else {
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash);// 回傳event目前的狀態，會顯示在log（時間戳是指監聽event時當下的時間戳）
        } 
    }

    // 查詢文件，傳回該文件被建立時的時間戳與該文件的擁有者
    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {
        return (files[_fileHash].timestamp, files[_fileHash].owner); //進入files這個mapping尋找對應的struct，並填入新增文件時的時間戳和擁有者
    }
}