/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

//SPDX-License-Identifier: SimPL -2.0
pragma solidity 0.8.13;

contract Proof{
    struct FileDetail{ //資料的細節
        uint256 timestamp; //時間戳
        string owner; //管理員
    }

    mapping(string => FileDetail) files; //資料細節用成陣列

    event logFileAddedStatus(bool status,uint256 timestamp,string owner,string fileHash); //事件（資料的狀態）

    function set(string memory _owner,string memory _fileHash) public{
        if(files[_fileHash].timestamp==0){ //如果時間戳沒有被動過就執行
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner}); //加上時間戳和管理員
            emit logFileAddedStatus(true,block.timestamp,_owner,_fileHash); //觸發事件，給true
        }else{ //時間戳被動過
            emit logFileAddedStatus(false,block.timestamp,_owner,_fileHash); //觸發事件，給false
        }
    }

    function get( string memory _fileHash) public view returns (uint256 timestamp , string memory owner) {
        return (files[_fileHash].timestamp, files[_fileHash].owner); //回傳時間戳和管理員
    }
}