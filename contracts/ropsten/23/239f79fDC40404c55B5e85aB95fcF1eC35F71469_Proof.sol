/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13; //solidity編譯器版本

contract Proof {
    struct FileDetail{ //宣告uint256跟string的variable
        uint256 timestamp;
        string owner;
    }

    mapping ( string => FileDetail) files; //宣告存放string FileDetail的mapping

    event logFileAddedStatus( bool status, uint256 timestamp, string owner, string fileHash);

    function set ( string memory _owner, string memory _fileHash) public {
        if( files[_fileHash].timestamp == 0){ //如果file mapping內沒有timestamp的話
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner}); //將現在的timestamp跟輸入的owner放入filehash
            emit logFileAddedStatus( true, block.timestamp, _owner, _fileHash); //觸發事件 回存boolean true以及檔案的資料
        } else{
            emit logFileAddedStatus( false, block.timestamp, _owner, _fileHash); //file mapping內有timestamp的話直接回傳boolean false及檔案的資料
        }
    }

    function get( string memory _fileHash) public view returns (uint256 timestamp, string memory _owner){ //以filehash取得files的time stamp及owner
        return (files[_fileHash].timestamp, files[_fileHash].owner);
    }
}