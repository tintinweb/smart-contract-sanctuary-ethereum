/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract Proof{ //建構合約Proof
    struct FileDetail{ //宣告結構FileDetail
        uint256 timestamp; //
        string owner;
    }

    mapping(string => FileDetail) files;//Mapping 輸入檔案雜湊值

    event logFileAddedStatus(bool status,uint256 timestamp,string owner,string fileHash);

    function set(string memory _owner,string memory _fileHash) public{ //函式set新增檔案資料 傳兩個參數Owner和雜湊值
        if(files[_fileHash].timestamp==0){ //如果timestamp=0沒有資料
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});
            emit logFileAddedStatus(true,block.timestamp,_owner,_fileHash);
        }else{
            emit logFileAddedStatus(false,block.timestamp,_owner,_fileHash);
        }
    }

    function get( string memory _fileHash) public view returns (uint256  timestamp , string memory owner) {
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }
}