/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: contracts/final.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;
    address private _owner;
    uint256 public entranceFee;

    // 建立onlyOwner的modifier
    modifier onlyOwner{
        require(msg.sender == _owner,"this contract is not yours.");
        _;
    }
    // 定義enum
    // 宣告enum
    enum NOW{
      STOP,
      RUNNING,
      PENDING
    }NOW lotterynow;

    // 實作constructor
    // 1. 宣告一開始LOTTERY_NOW
    // 2. assign msg.sender給_owner variable
    constructor(){
      lotterynow = NOW.STOP;
      _owner = msg.sender;
    } 

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_NOW是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到playerss的array當中
     function enter() payable public {
      require(lotterynow == NOW.RUNNING, "lottery isn't running");
      require(msg.value >= entranceFee, "not enough entrance fee");
      players.push(msg.sender);
    }
    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_NOW是否為關閉狀態
    // 2. 將LOTTERY_NOW改為開啟
    // 3. 並且設定入場費金額
    function startLottery(uint256 fee) public {
      require(lotterynow == NOW.STOP, "lottery is running");
      lotterynow = NOW.RUNNING;
      require(fee > 0, "please enter a positive number");
      entranceFee = fee;
    }

    // 實作endLottery function, 此function是讓合約擁有者(eg. _owner)呼叫
    // 1. 把LOTTERY_NOW改為“正在計算贏家”狀態
    // 2. 透過加密雜湊演算法產生隨機數, 用來選擇這次賭盤的贏家 (程式碼如下)
    //      - 把msg.sender, block.difficulty, block.timestamp這三個input做打包
    //      - 將打包好的資料做keccak256加密雜湊演算法, keccak256會回傳byte32的result value
    //      - 把keccak256回傳的byte32的result value轉換成uint256, 再與playerss array的長度取餘數
    //      - 最後得到隨機數 "indexOfWinner"
    //      ======================================= Code =======================================
    //      |   uint256 indexOfWinner = uint256(                                               |
    //      |        keccak256(                                                                |
    //      |            abi.encodePacked(msg.sender, block.difficulty, block.timestamp)       |
    //      |       )                                                                          |
    //      |   ) % playerss.length;                                                            |
    //      ======================================= Code =======================================
    // 3. 透過indexOfWinner選出playerss array中的Address, 並assign給recentWinner value
    // 4. 把合約內所有的ETH傳給贏家
    // 5. 清空playerss array (⭐️)
    // 6. 把LOTTERY_NOW改為關閉狀態
    function endLottery() public onlyOwner{
      require(lotterynow == NOW.RUNNING, "lottery is not running");
      require(players.length > 0, "no players have have lottery at the same time");
      lotterynow = NOW.PENDING;

      uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;
      recentWinner = players[indexOfWinner];
      payable(recentWinner).transfer(address(this).balance);
      delete players;

      lotterynow = NOW.STOP;
    }
}