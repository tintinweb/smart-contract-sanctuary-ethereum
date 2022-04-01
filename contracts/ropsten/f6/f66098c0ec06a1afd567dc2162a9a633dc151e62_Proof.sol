/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract Proof {
    struct FileDetail{      //自訂檔案細節 結構
        uint256 timestamp;  //變數型別為整數數值
        string owner;       //變數型別為字串
    }

    mapping( string => FileDetail) files;   //映射型別

    event logFileAddesStatus( bool status, uint256 timestamp, string owner, string fileHash);   //宣告事件

    function set( string  memory _owner, string memory _fileHash) public {
        if( files [_fileHash].timestamp == 0) {     //代表檔案未被上傳過
            files [_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});    //寫入檔案時間戳記、擁有者
            emit logFileAddesStatus( true, block.timestamp, _owner, _fileHash);     //觸發事件 代表是第一次執行
        } else{
            emit logFileAddesStatus( false, block.timestamp, _owner, _fileHash);    //觸發事件 非第一次執行
        }
    }

    function get( string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {
        return (files[_fileHash].timestamp, files[_fileHash].owner);        //回傳檔案的時間戳記及owner
    }
}