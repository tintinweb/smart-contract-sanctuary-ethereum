/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;  //編譯器宣告

contract Proof {   //建立合約
    struct FileDetail{    //建立一個名為FileDetail的結構，裡面包含timestamp和owner
        uint256 timestamp;
        string owner;
    }

    mapping( string => FileDetail) files;    //建立一個映列，key為string對應到FileDetail

    event logFileAddedStatus( bool status,uint256 timestamp, string owner, string fileHash);    //建立一個事件儲存當新增檔案時的資訊。

    function set(string memory _owner, string memory _fileHash) public {    //建立新增function，傳入owner和檔案的hash值。
        if( files[_fileHash].timestamp == 0) {         //如果檔案的時間戳為0的話，代表傳入的檔案還沒被set
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});      //將新增的檔案細節加入files結構
            emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash);        //建立事件，紀錄成功新增的檔案細節
        } else {
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash);    //如果這個檔案已經set過了，就新增一個事件，此事件為新增失敗的檔案細節
        }
    } 

    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner){    //建立一個名為get的function，傳入fileHash
        return (files[_fileHash].timestamp, files[_fileHash].owner);     //回傳此file的timestamp和owner
    }
}