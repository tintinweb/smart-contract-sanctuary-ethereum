/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

//SPDX-License-Identifier: SimPL-2.0

pragma solidity 0.8.13;


contract Proof{
    struct FileDetail{ //建立一個名為FileDetail的struct，裡面有timestamp & owner
        uint256 timestamp;
        string owner;
    }


mapping(string=>FileDetail) files; //建立一個key為string，value為FileDetail的mapping

//建立一個名為logFileAddedStatus的event裡面有status, timestamp, owner, fileHash
event logFileAddedStatus(bool status,uint timestamp, string owner, string fileHash);

function set(string memory _owner, string memory _fileHash) public{
    //如果輸入的filehash在mapping裡沒有對應值的話（之前沒登錄過），就把這個block.timestamp和owner寫進mapping並寫入log
    if(files[_fileHash].timestamp==0){
        files[_fileHash]=FileDetail({timestamp:block.timestamp, owner:_owner});
        emit logFileAddedStatus(true, block.timestamp,_owner,_fileHash);
    }else{
        emit logFileAddedStatus(false, block.timestamp,_owner,_fileHash);
    }
}

//查找timestamp的時間戳記和擁有者
function get(string memory _fileHash) public view returns (uint256 timestamp, string memory owner){
    return (files[_fileHash].timestamp, files[_fileHash].owner);
}

}