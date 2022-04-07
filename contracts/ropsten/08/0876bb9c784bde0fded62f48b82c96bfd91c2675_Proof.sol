/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

//SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.8.13; //編譯器的宣告

contract Proof {             //建立合約
    struct FileDetail{       //宣告一個名字為"FileDetail"的結構
        uint256 timestamp;   //設定timestamp為數值類別
        string owner;        //設定owner為字串類別
    }

    mapping (string => FileDetail) files;   //把mapping的名稱設為files

    event logFileAddedStatus ( bool status, uint256 timestamp, string owner, string fileHash);  //宣告事件logFileAddidStatus
                                                                                                //設定status為布林類別、timestamp為無號數
                                                                                                //設定owner為字串類別、fileHash為字串類別

    function set ( string memory _owner, string memory _fileHash) public {               //建立一個名字為set的function，接收"owner"和"fileHash"
        if( files[_fileHash].timestamp == 0){                                            //如果timestamp為0，代表這個檔案不存在
            files[_fileHash] = FileDetail({ timestamp:block.timestamp, owner:_owner});      
            emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash);          //則可以成功set一個檔案
        } else {                                                                         //若timestamp不為0，代表檔案已經存在
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash);         //則不能夠set一個檔案
        }
    }

    function get(string memory _fileHash) public view returns ( uint256 timestamp, string memory owner){  //建立一個名字為get的function，只要接收到"fileHash"
        return (files[_fileHash].timestamp, files[_fileHash].owner);                                      //就會回傳對應的"timestamp和"owner"  
    }
}