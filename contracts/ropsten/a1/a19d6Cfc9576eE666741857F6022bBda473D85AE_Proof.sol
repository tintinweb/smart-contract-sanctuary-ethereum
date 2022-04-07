/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT 
//代表MIT開源許可
pragma solidity ^0.8.13; //0.8.13以上的compiler 
// pragma solidity 0.4.24; 

contract Proof {
    struct FileDetail { //宣告一個struct
        uint256 timestamp;
        string owner;
    }

    mapping(string => FileDetail) files; //用hash map 到 FileDetail (含timestamp owner) 來找

    event logFileAddedStatus(bool status, uint256 timestamp, string owner, string fileHash); //宣告一個事件

    function set(string memory _owner, string memory _fileHash) public {
        if(files[_fileHash].timestamp == 0) {
            files[_fileHash] = FileDetail({ timestamp:block.timestamp, owner:_owner}); //把資料存到map裡面
            emit logFileAddedStatus(true, block.timestamp, _owner, _fileHash); //觸發logFileAddedStatus事件
            //emit: 歷史資料可以用此方式監聽
        }else { //已經存在
            emit logFileAddedStatus(false, block.timestamp, _owner, _fileHash); //status回傳false
        }
    }

    //output
    function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {
        return (files[_fileHash].timestamp, files[_fileHash].owner); //用hash從map中找出對應的timpstamp and owner 回傳出去
    }

    //合約編譯完成 會產生abi(JSON格式的資料) 與 bit code
    //靠第三方驗證(ex. etherscan) 因abi相同不代表合約相同 
}