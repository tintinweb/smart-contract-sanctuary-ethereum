/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {

    struct roundInfo {
        address winnerAddr;
        uint256 winnerFee;
        uint256 numOfPlayer;        
    }
    
    struct donateInfo {
        address addr;
        uint256 fee;
    }

    uint256 totalRound;
    uint256 totalFee;
    uint256 totalPlayer;
        
    roundInfo[] public roundHistories;
    donateInfo[] public donateHistories;

    address[] public players; 
    address private _owner;

    uint256 public entranceFee;

    // 定義enum
    enum state {open, close}
    // 宣告enum
    state lotteryState;

    // modifier
    modifier onlyOwner() {
        require(msg.sender == _owner, "Sender must be owner.");
        _;
    }
    modifier onlyOpen() {
        require(lotteryState == state.open, "lotteryState must be open.");
        _;
    }
    modifier onlyClose() {
        require(lotteryState == state.close, "lotteryState must be close.");
        _;
    }

    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor() {
        lotteryState = state.close;
        _owner = msg.sender;        
    }

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到players的array當中
    function enter() onlyOpen public payable {

        require(msg.value == entranceFee, "incorrect entrance fee");

        players.push(msg.sender);

        totalFee += entranceFee;
        roundHistories[totalRound-1].winnerFee += entranceFee;

        totalPlayer++;        
        roundHistories[totalRound-1].numOfPlayer++;
        
    }

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // 2. 將LOTTERY_STATE改為開啟
    // 3. 並且設定入場費金額
    function startLottery(uint256 _entranceFee) onlyOwner onlyClose public{
        totalRound++;
        roundHistories.push(roundInfo(address(0), 0, 0));
        entranceFee = _entranceFee;
        lotteryState = state.open;
    }

    // 實作endLottery function, 此function是讓合約擁有者(eg. _owner)呼叫
    // 1. 把LOTTERY_STATE改為“正在計算贏家”狀態
    // 2. 透過加密雜湊演算法產生隨機數, 用來選擇這次賭盤的贏家 (程式碼如下)
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
    // 3. 透過indexOfWinner選出players array中的Address, 並assign給recentWinner value
    // 4. 把合約內所有的ETH傳給贏家
    // 5. 清空players array (⭐️)
    // 6. 把LOTTERY_STATE改為關閉狀態

    function endLottery() onlyOwner onlyOpen public {        
        lotteryState = state.close;

        if(players.length == 0)
            return;
        
        uint256 indexOfWinner = uint256(
                keccak256(
                    abi.encodePacked(msg.sender, block.difficulty, block.timestamp)  
                )
            ) % players.length;
        
        roundInfo storage curRound = roundHistories[totalRound-1];
        curRound.winnerFee = curRound.winnerFee / 10 * 9; // 10% for donation
        curRound.winnerAddr = players[indexOfWinner];

        (bool success, ) = curRound.winnerAddr.call{value: curRound.winnerFee}(""); 

        require(success, "Failed to transfer");

        delete players;
        
    }
    // 1. 10%的彩金累積後當成慈善基金，由owner設定給某慈善單位的Address進行一次性提領。
    function doDonation(address target) onlyOwner public {

        uint256 fee = address(this).balance;
        roundInfo storage curRound = roundHistories[totalRound-1];

        if(lotteryState == state.open)
            fee -= curRound.winnerFee;

        donateHistories.push(donateInfo(target, fee));

        (bool success, ) = target.call {value: fee}(""); 

        require(success, "Failed to transfer");

    }

    // 2. 能查詢歷史開彩總次數。
    function getTotalRound() public view returns(uint256) {
        return totalRound;
    }

    // 3. 能查詢歷史總投注金額。
    function getTotalFee() public view returns(uint256) {
        return totalFee;
    }

    // 4. 能查詢歷史總投注人次。
    function getTotalPlayer() public view returns(uint256) {
        return totalPlayer;
    }

    // 5. 能查詢某屆贏家的Address & 獲得金額 & 該屆投注人數。
    function getRoundHistories(uint256 index) public view returns(roundInfo memory) {
        return roundHistories[index];
    }

    // 6. 能查詢慈善基金的提領紀錄。
    function getDonateHistories(uint256 index) public view returns(donateInfo memory) {
        return donateHistories[index];
    }




}