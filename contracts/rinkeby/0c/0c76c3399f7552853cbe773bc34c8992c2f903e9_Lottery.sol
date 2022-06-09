/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: contracts/FinalProject1.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;

    uint256 public entranceFee;
    
    address private _owner;    

    // 建立onlyOwner的modifier - ok
    modifier onlyOwner()
    {
        require(msg.sender == _owner, "You are not permitted to use this function.");
        _;
    }//modifier onlyOwner

    // 定義enum - ok
    enum LOTTERY_STATE { CLOSED, STARTED, PICKING }

    // 宣告enum - ok
    LOTTERY_STATE lotteryState;

    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE - ok
    // 2. assign msg.sender給_owner variable - ok
    constructor()
    {
        lotteryState = LOTTERY_STATE.CLOSED;
        _owner = msg.sender;
    }//constructor

    function currentPlayersNum() public view returns (uint256)
    {
        return players.length;
    }//currentPlayersNum

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始 - ok
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂) - ok
    // 3. 把msg.sender記錄到players的array當中 - ok
    function enter() public payable
    {
        require(lotteryState == LOTTERY_STATE.STARTED, "The lottery is not started yet. Please try again later.");
        require(msg.value >= entranceFee, "Not enough money for entry fee.");
        players.push(msg.sender);
    }//enter

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態 - ok
    // 2. 將LOTTERY_STATE改為開啟 - ok
    // 3. 並且設定入場費金額 - ok
    function startLottery(uint256 _entranceFee) public onlyOwner
    {
        require(lotteryState == LOTTERY_STATE.CLOSED, "The lottery is already started.");
        lotteryState = LOTTERY_STATE.STARTED;
        entranceFee = _entranceFee;
    }//startLottery

    // 實作endLottery function, 此function是讓合約擁有者(eg. _owner)呼叫
    // 1. 把LOTTERY_STATE改為“正在計算贏家”狀態 - ok
    // 2. 透過加密雜湊演算法產生隨機數, 用來選擇這次賭盤的贏家 (程式碼如下) - ok
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
    // 3. 透過indexOfWinner選出players array中的Address, 並assign給recentWinner value - ok
    // 4. 把合約內所有的ETH傳給贏家 - ok
    // 5. 清空players array (⭐️) - ok
    // 6. 把LOTTERY_STATE改為關閉狀態 - ok
    function endLottery() public onlyOwner
    {
        if (players.length == 0)
        {
            lotteryState = LOTTERY_STATE.CLOSED;
            return;
        }//if

        lotteryState = LOTTERY_STATE.PICKING;
        uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;
        recentWinner = players[indexOfWinner];
        (bool sendSucc, ) = payable (recentWinner).call{value: address(this).balance}("Congratulations, you are the winner!!!");
        delete players;
        lotteryState = LOTTERY_STATE.CLOSED;
    }//endLottery
}