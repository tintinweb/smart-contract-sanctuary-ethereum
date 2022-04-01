/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
// 0.6.8版之後引入SPDX，需在程式碼第一行引入
pragma solidity 0.8.13; //使用0.8.13

contract Proof{ //新增Proof物件
    struct FileDetail{  //新增結構FileDetail
        uint256 timestamp;  //新增uint256參數timestamp
        string owner;   //新增string參數owner
    }

    mapping(string => FileDetail) files;    //利用mapping建立索引值
    //當logFileAddedStatus被觸發時永久記錄status,timestamp,owner,fileHash
    event logFileAddedStatus(bool status,uint256 timestamp,string owner,string fileHash);   
    //新增函數set需要用到參數_owner,_fileHash
    function set( string memory  _owner, string memory  _fileHash) public{
        //如果合約中尚未擁有timestamp
        if(files[_fileHash].timestamp==0){
            //則timestamp和owner寫入FileDetail
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});
            //利用logFileAddedStatus發送通知
            emit logFileAddedStatus(true,block.timestamp,_owner,_fileHash);
        }
        //如果合約中已經擁有timestamp
        else{
            //利用logFileAddedStatus發送有人在亂搞的通知
            emit logFileAddedStatus(false,block.timestamp,_owner,_fileHash);
        }
    }
    //新增函數set需要用到參數_fileHash並回傳timestamp,owner
    function get(string memory  _fileHash) public view returns (uint256 timestamp ,string memory owner) {
        //回傳files中的timestamp,owner
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }
}