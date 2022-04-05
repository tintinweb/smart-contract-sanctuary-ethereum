/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity 0.4.24;
//文件所有權證明有帳戶對Hash和Hash對帳戶兩種
contract Proof { //宣告合約叫Poof
	struct FileDetail{ //宣告一個FileDetail的結構
		uint256 timestamp;//紀錄時間戳，資料紀錄的時間，區塊打包也可以看到時間?
		string owner;
	}

	mapping( string => FileDetail) files;//第一個string是檔案雜湊值，輸入檔案雜湊值就可以知道檔案室什麼時候上傳的
	
	event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash);//event發出資料

	function set( string _owner, string _fileHash) public{//要set檔案資料，傳進owner和filehash
		if( files[_fileHash].timestamp == 0){//根據mapping如果等於0代表沒有人上傳過
			files[_fileHash] = FileDetail({timestamp:block.timestamp , owner:_owner});//根據Hash建立檔案資料
			emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash);//block.timestamp是區塊產生時間戳的意思， owner最好的做法是宣告address
		}else{//emit到底有什麼作用? 根據之後作業會知道它很有效果
			emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash);//如果檔案已經有了就會false
		}
	}


	function get( string _fileHash) public view returns (uint256 timestamp, string owner){
		return (files[_fileHash].timestamp, files[_fileHash].owner);
	}
//合約編譯完會產生ABI和Bycode，在左下，ABI Json檔 大括號和中括號 給工程師看的，可以知道有那些函式
//詐騙合約的ABI會有，實際執行合約和ABI不一樣的狀況，所以需要第三放驗證，但卻要把合約內容公開
}