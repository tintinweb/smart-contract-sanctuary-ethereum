/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: final_project_40947005S.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract Lottery {
    address[] public players;
    address public recentWinner;
    address private _owner;
    uint256 public entranceFee;
 
    // (V)建立onlyOwner的modifier
    modifier onlyOwner(){
        require(msg.sender == _owner, "Permission denied.");
        _;//回到function繼續執行
    }

    // (V)定義enum
    enum STATUS {
        InProgress, //進行中
        CalculatingWinner, //計算贏家
        EndOrNotStarted    //結束，未開始
    }
   
    // (V)宣告enum
    STATUS public status;
 
    // 實作constructor
    // (V)1. 宣告一開始LOTTERY_STATE
    // (V)2. assign msg.sender給_owner variable
    constructor() public {
        status = STATUS.EndOrNotStarted;
        _owner = msg.sender;
    }
 
    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // (V)1. 檢查目前LOTTERY_STATE是否已經開始
    // (V)2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // (V)3. 把msg.sender記錄到players的array當中
    function enter() payable public {
        require(status == STATUS.InProgress ,"It hasn't started.");
        require(msg.value >= 0.00001 ether ,"The value need to be bigger than the entranceFee.");
        players.push(msg.sender);
    }
 
    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // (V)1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // (V)2. 將LOTTERY_STATE改為開啟
    // (V)3. 並且設定入場費金額
    function startLottery() public onlyOwner{
        require(status == STATUS.EndOrNotStarted ,"Start failed.");
        status = STATUS.InProgress;
        entranceFee = 0.00001 ether;
    }
   
 
    // 實作endLottery function, 此function是讓合約擁有者(eg. _owner)呼叫
    // (V)1. 把LOTTERY_STATE改為“正在計算贏家”狀態
    // (V)2. 透過加密雜湊演算法產生隨機數, 用來選擇這次賭盤的贏家 (程式碼如下)
    //      - 把msg.sender, block.difficulty, block.timestamp這三個input做打包
    //      - 將打包好的資料做keccak256加密雜湊演算法, keccak256會回傳byte32的result value
    //      - 把keccak256回傳的byte32的result value轉換成uint256, 再與players array的長度取餘數
    //      - 最後得到隨機數 "indexOfWinner"
    //      ======================================= Code =======================================
    //      |   uint256 indexOfWinner = uint256(                                               |
    //      |        keccak256(                                                                |
    //      |            abi.encodePacked(msg.sender, block.difficulty, block.timestamp)       |
    //      |       )                                                                          |
    //      |   ) % players.length;                                                            |
    //      ======================================= Code =======================================
    // (V)3. 透過indexOfWinner選出players array中的Address, 並assign給recentWinner value
    // (V)4. 把合約內所有的ETH傳給贏家
    // (V)5. 清空players array (⭐️)
    // (V)6. 把LOTTERY_STATE改為關閉狀態
    function endLottery() public onlyOwner{
        require(status == STATUS.InProgress ,"It's not currently in progress.");
        require( players.length > 0 ,"There is currently no player in the pool.");
        status = STATUS.CalculatingWinner;
 
        uint256 indexOfWinner = uint256(
                keccak256(
                    abi.encodePacked(msg.sender, block.difficulty, block.timestamp)
                )
        ) % players.length;
        recentWinner = players[indexOfWinner];
        payable(recentWinner).transfer(address(this).balance);
        delete players;
        status = STATUS.EndOrNotStarted;
    }
}