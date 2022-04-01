/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

contract Proof {
	struct FileDetail {    //建立一個檔案資料的結構
		uint256 timestamp; //時間戳
		string owner;      //文件持有人
	}
	
    

	mapping ( string => FileDetail) files;  //匯入檔案雜湊值進FileDetail
	
	event logFileAddedStatus ( bool status, uint256 timestamp, string owner, string fileHash);  //事件狀態

    function set (string memory _owner, string memory _fileHash) public {      //輸入文件持有人、hash值
        if(files [_fileHash].timestamp == 0){       // if timestamp=0代表沒人上傳過，就會建立Detail:時間戳及owner
            files[_fileHash] = FileDetail ({ timestamp:block.timestamp , owner:_owner});
            emit logFileAddedStatus (true, block.timestamp, _owner, _fileHash);  //成功的話emit事件會通知持有人
        } else {
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash); //timestamp不等於0 代表已有時間戳，失敗emit事件會紀錄失敗
        }
    }

    function get( string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {  //輸入hash值會回傳files裡面的timestamp&owner
        return (files[ _fileHash].timestamp, files[_fileHash].owner);
    }
}