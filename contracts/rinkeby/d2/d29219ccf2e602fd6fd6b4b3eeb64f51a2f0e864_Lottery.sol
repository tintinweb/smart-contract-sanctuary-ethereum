/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address[] private players;
    address public recentWinner;

    address private _owner;

    uint256 public entranceFee;
    uint256 public amount;
    uint256 public numofplayers;

    // 建立onlyOwner的modifier
    modifier onlyOwner()
    {
        require(_owner == msg.sender, "This function can only be called by owner.");
        _;
    }
    // 定義enum
    enum State
    {
        open,
        end
    }
    // 宣告enum
    State state;

    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor() payable{
        _owner = msg.sender;
        state = State.end;
    }

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到players的array當中
    function enter() public payable
    {
        require( state == State.open, "Not open state.");
        require( msg.value >= entranceFee , "Insufficient entry fee");
        amount += msg.value;
        players.push( msg.sender );
        numofplayers++;   //有幾個人投注
    }

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // 2. 將LOTTERY_STATE改為開啟
    // 3. 並且設定入場費金額
    function startLottery(uint256 _entranceFee) public onlyOwner
    {
        require( state == State.end, "Lottery state is not closed.");
        state = State.open;
        entranceFee = _entranceFee;
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
    function endLottery() public onlyOwner
    {
        require( state == State.open,"The game not open yet.");
        uint256 indexOfWinner = uint256( keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;   
        ( bool sent,) = payable(players[indexOfWinner]).call{ value: amount}("");
        require( sent, "fail sent.");
 
        recentWinner = players[indexOfWinner];
        delete players;
        amount  = 0;
        entranceFee = 0;
        
        state == State.end;
    }
}

// Ab8 63893 + 800 = 64693
// 4B2 49526 + 800 = 50326