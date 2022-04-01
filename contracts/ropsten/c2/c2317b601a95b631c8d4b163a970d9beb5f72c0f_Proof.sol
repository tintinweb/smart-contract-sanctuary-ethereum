/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT 
//0.6.8版本後需引入SPDX-License
pragma solidity 0.8.13;

contract Proof{
    struct FileDetail{
        uint256 timestamp;
        string owner;
    }

    mapping( string => FileDetail) files; //映射型別 : Files  

    event logFileAddedStatus( bool status, uint256 timestamp, string owner ,string FileHash); //宣告事件  status ,timestamp: 時間戳記, owner: 擁有者, FileHash: 檔案雜湊值
    
    
    function set ( string memory _owner , string memory _fileHash) public {  //function set : 輸入參數為 owner, FileHash
        if( files[_fileHash].timestamp == 0){                                
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});
            emit logFileAddedStatus( true, block.timestamp,_owner,_fileHash);
        } else {
            emit logFileAddedStatus( false, block.timestamp,_owner,_fileHash);
        } /*該檔案的在區塊上的時間戳記若不存在，則新增檔案並建立時間戳記，再透過事件宣告擁有者，回傳true。
            如果該檔案已經存在時間戳記以及擁有者，則回傳false*/
    }

    function get( string memory _fileHash) public view returns ( uint256 timestamp, string memory owner){ //function: get
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }
    /*根據 fileHash 檔案雜湊值去get 該檔案的時間戳記跟擁有者是誰，回傳該結果*/
}