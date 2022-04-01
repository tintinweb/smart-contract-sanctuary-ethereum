/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: simple-2.0
pragma solidity 0.8.13 ;

contract Proof { //自訂義contract
    struct FileDetail{  //自訂義檔案細節
        uint256 timestamp; //變數型別為整數
        string owner; //變數型別為字串
    }
    mapping( string => FileDetail) files; //利用key(Filehash)值去找到Value(FileDetail)整個結構

    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string FileHash);
    
    function set( string memory _owner, string memory _fileHash) public { //設定合約
        if( files[_fileHash].timestamp ==0) { // 判斷時間戳記是否已被使用
            files[_fileHash] = FileDetail({ timestamp:block.timestamp, owner:_owner}) ;
            emit logFileAddedStatus( true, block.timestamp, _owner,_fileHash); //沒被使用的話傳回ture
        }else {
            emit logFileAddedStatus( false, block. timestamp,_owner,_fileHash); //被使用過的話傳回false
        }
    }    
    function get( string memory _fileHash) public view returns (uint256 timestamp, string memory owner){
        return (files[_fileHash]. timestamp, files[_fileHash].owner); //回傳檔案時間戳記及Owner
    }
}