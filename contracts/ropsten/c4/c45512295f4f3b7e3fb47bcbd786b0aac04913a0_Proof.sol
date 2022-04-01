/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract Proof {  //自定義contract
    struct FileDetail{  //自定義檔案細節
        uint256 timestamp;  //變數型別為整數
        string owner;   //變數型別為字串
    }

    mapping( string => FileDetail) files; //利用Key值(FileHash)去找到Value(FileDetail)整個結構

    event logFileAddesStatus( bool status, uint256 timestamp, string owner, string fileHash); //在區塊鏈上發布事件

    function set( string memory _owner, string memory _fileHash) public {
        if( files[_fileHash].timestamp == 0) { //判斷是否已經被使用
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});
            emit logFileAddesStatus( true, block.timestamp, _owner, _fileHash); //如果沒有被使用過則回傳True
        } else{ 
            emit logFileAddesStatus( false, block.timestamp, _owner, _fileHash); //若被使用則回傳false
        }
    }

    function get( string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {
        return (files[_fileHash].timestamp, files[_fileHash].owner); //回傳檔案的時間戳記及Owner
    }
}