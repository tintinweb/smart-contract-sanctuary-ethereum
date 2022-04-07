/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13; // 按要求選擇最新版之編譯器

contract Proof {    
    struct FileDetail{ // 資料細節的結構
        uint256 timestamp;
        string owner;
    }
    
    mapping( string => FileDetail) files; // mapping 擁有者 => 資料細節
    
    // 宣告事件
    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash);
    
    // 資料上鍊
    function set( string memory _owner, string memory _fileHash) public {
        if( files[_fileHash].timestamp == 0) {
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});
            emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash);
        } else {
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash);
        }
    }
    
    // 從鏈上拿資料
    function get( string memory _fileHash) public view returns (uint256 timestamp, string memory owner) {
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }
}