/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX license identifier: SimPL 2.0
pragma solidity 0.8.13; 

contract proof {
    //透過struct宣告FileDetail資料型態組成有:timestamp時間戳記、owner檔案持有者
    struct FileDetail{ 
        uint256 timestamp;
        string owner;
    }
    //雜湊資料表mapping:透過檔案雜湊值(fileHash)對應FileDetail資料
    mapping (string => FileDetail) files; 
    //增加檔案的事件:監控紀錄增添檔案的狀態(status(成功/失敗),timestamp(時間戳記),owner(檔案持有者)，fileHash(檔案雜湊值))
    event logFileAddStatus(bool status, uint256 timestamp, string owner, string fileHash);
    
    //新增檔案
    function set(string memory _owner, string  memory _fileHash) public {
        //files[_fileHash].timestamp == 0(時間戳記=0):代表尚未有這筆資料,進行新增
        if(files[_fileHash].timestamp == 0) {
            //進行新增檔案
            files[_fileHash] = FileDetail({ timestamp:block.timestamp , owner:_owner});
            //回傳event事件的狀態(成功,時間戳記,檔案持有者,檔案雜湊值)
            emit logFileAddStatus(true, block.timestamp, _owner, _fileHash);
        } else{ //有這筆資料存在，回傳event失敗事件(失敗,時間戳記,檔案持有者,檔案雜湊值)
            emit logFileAddStatus(false, block.timestamp, _owner, _fileHash);
        }
    }
    //查詢檔案
    function get(string memory _fileHash) public view returns(uint256 timestamp, string memory owner){
        return(files[_fileHash].timestamp, files[_fileHash].owner); //回傳檔案被建立的資料(時間戳記,檔案持有者)
    }
}