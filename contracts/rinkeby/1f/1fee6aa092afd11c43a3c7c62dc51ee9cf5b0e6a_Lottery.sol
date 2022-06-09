/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: project1.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;
    address private _owner;
    uint256 public entranceFee;

    // 建立onlyOwner的modifier
    modifier onlyOwner(){
        require(msg.sender == _owner, "Not owner.");
        _;         //回到function繼續執行
    }

    // 定義enum
    enum STATUS {
        Running,     //已經開始
        Choosing,   //計算贏家
        Pause         //關閉狀態
    }
    
    // 宣告enum
    STATUS public status;

    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor() public {
        status = STATUS.Pause;  //1.
        _owner = msg.sender;      //2.
    }

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到players的array當中
    function enter() payable public {
        require(status == STATUS.Running, "Have not start.");       //1.
        require(msg.value >= entranceFee, "The value need to bigger than the entranceFee.");    //2.
        players.push(msg.sender);                                                  //3.
    }

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // 2. 將LOTTERY_STATE改為開啟
    // 3. 並且設定入場費金額
     function startLottery() public onlyOwner{
        require(status == STATUS.Pause ,"Going.");  //1.
        status = STATUS.Running;                             //2.
        entranceFee = 0.00001 ether;                        //3.
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
    function endLottery() public onlyOwner{
        require(status == STATUS.Running ,"Have not start.");   //確認遊戲狀態
        require(players.length > 0 ,"No player.");                          //確認玩家狀態
        status = STATUS.Choosing;                                             //1.
        uint256 indexOfWinner = uint256(                                    //2.
                keccak256(
                    abi.encodePacked(msg.sender, block.difficulty, block.timestamp)
                )
        ) % players.length;
        recentWinner = players[indexOfWinner];                         //3.
        payable(recentWinner).transfer(address(this).balance);  //4.
        delete players;                                         //5.
        status = STATUS.Pause;                         //6.
    }
}