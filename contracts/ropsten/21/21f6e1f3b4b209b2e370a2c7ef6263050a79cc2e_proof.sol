/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13;

contract proof{      //創建一個證明程式
    struct filedetail{
        uint256 timestamp;
        string owner;
    }

    mapping(string => filedetail)files;     //創建一個mapping用filedetail去呼叫files

    event log(bool status,uint256 timestamp,string owner,string filehash);   //創建一個event紀錄status,timestamp,owner,filehash

    function set(string memory _owner,string memory _filehash)public{
        if(files[_filehash].timestamp == 0){     //檢查filehash傳入檔案的時間是否=0，若是，則此檔案還未被傳過
            files[_filehash] = filedetail({timestamp:block.timestamp,owner:_owner}) ;
            emit log(true,block.timestamp,_owner,_filehash);

        }
        else{
            emit log(false,block.timestamp,_owner,_filehash);    //若否，表示檔案已被傳過
        }
    }

    function get(string memory _filehash)public view returns(uint256 timestamp,string memory owner){
        return(files[_filehash].timestamp,files[_filehash].owner);
    }
}