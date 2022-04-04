/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

//00957118蔡翔宇

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract Proof{//建立一個合約可以由合約的雜湊值得出建立合約的時間及合約的擁有者
    struct FileDetail{
        uint256 timestamp;
        string owner;
    }

    mapping (string =>FileDetail)files;//建立一個由fileHash映射到FileDetail的類別

    event logFileAddedStatus(bool status,uint256 timestamp,string owner,string fileHah);//將合約加到區塊戀中的event

    function set(string memory _owner,string memory _fileHash)public{//set
        if(files[_fileHash].timestamp==0){//假如這個fileHash還沒有產生映射類別
            files[_fileHash]=FileDetail({timestamp:block.timestamp,owner:_owner});//set timestamp to 現在的時間 and owner
            emit logFileAddedStatus(true,block.timestamp,_owner,_fileHash);//將他放到區塊鏈中
        }else{//這個fileHash已經產生過映射類別了
            emit logFileAddedStatus(false,block.timestamp,_owner,_fileHash);//將第一個status設為false
        }
    }

    function get (string memory _fileHash)public view returns(uint256 timestamp,string memory owner){//input fileHash and returns timestamp and owner of contract 
        return(files[_fileHash].timestamp,files[_fileHash].owner);
    }
}