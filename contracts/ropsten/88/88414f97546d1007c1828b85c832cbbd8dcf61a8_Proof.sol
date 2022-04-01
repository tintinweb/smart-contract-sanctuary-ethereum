/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: SimPL-2.0

pragma solidity 0.8.13;

 contract Proof{ //文件所有權證明

    struct FileDetail{//建立一個檔案資料的結構
        uint256 timestamp; //時間戳
        string owner; //文件持有人
     }

    mapping(string => FileDetail) files; //輸入檔案雜湊值尋找檔案資料

    event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash); //定義事件,在Ethereum中進行記錄logging的機制


    function set(string memory _owner, string memory _fileHash) public{ //設定文件持有人和合約hash 
        if(files[_fileHash].timestamp == 0){ //如果文件時間戳等於0,建入timestamp,owner
            files[_fileHash] = FileDetail({timestamp:block.timestamp , owner:_owner});
            emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash);//事件成功通知文件持有人
        }else {
            emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash);//不等於0,emit發出失敗事件,通知文件持有人
        }
    }

    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner){//輸入hash回傳文件持有人名稱和時間戳
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }


 }