/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identider: SimPL-2.0
pragma solidity 0.8.13;  //合約版本

contract proof {        //合約名稱
    struct FileDetail{      //宣告參數
        uint256 timestamp;
        string owner;
    }

    mapping( string => FileDetail) files;

    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash);   //產生時間戳、合約內容跟使用者資訊
    
    function set( string memory _owner, string memory _fileHash) public{    //要加入MEMORY宣告參數才不會出現警告~ 部屬合約:產生使用者；時間戳、跟檔案內容
        if( files[_fileHash].timestamp ==0){    //若時間戳不存在
            files[_fileHash] = FileDetail({timestamp:block.timestamp , owner:_owner}); //產生合約(內涵時間戳、內容和使用者
            emit logFileAddedStatus( true, block.timestamp, _owner, _owner);
        }else {
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash); //若已經有同樣的時間戳、用同樣的內容在練上有合約的話則傳回錯誤
        }
    }

    function get (string memory _fileHash) public view returns (uint256 timestamp, string memory owner){ //用雜湊確認合約內容
        return(files[_fileHash].timestamp, files[_fileHash].owner); 
    }
}