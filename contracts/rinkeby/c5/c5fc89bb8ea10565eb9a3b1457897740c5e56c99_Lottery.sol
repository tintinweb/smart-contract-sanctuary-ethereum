/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// File: contracts/finalProject.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;

    address private _owner;

    uint256 public entranceFee;

    //amount of money earned from entrace fee
    uint256 private revenue;

    // 建立onlyOwner的modifier
    modifier onlyOwner {
      require(msg.sender == _owner);
      _;
   }

   //modifier for if currLotState is active
   modifier checkLotState {
       require(currLotState == lotteryState.lotteryActive);
       _;
   }

    // 定義enum
    enum lotteryState {
        lotteryInactive,
        calculatingWinner,
        lotteryActive
    }

    // 宣告enum
    lotteryState currLotState;

    //test getOwner
    function getOwner() public view returns(address){
        return _owner;
    }

    //test get revenue
    function getRevenue() public view returns (uint256) {
        return revenue;
    }

    //test getLoteryState
    function getCurLotState() public view returns (lotteryState) {
        return currLotState;
    }

    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor() public {
        currLotState = lotteryState.lotteryInactive;
        _owner = msg.sender;
    }

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到players的array當中
    function enter(uint amount) external payable checkLotState {
        //use modifier to check if active state
        //check if the player have enough money
        require(amount >= entranceFee);
        //if enought money then pay entrance fee
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Send failed.");
        //record player address
        players.push(msg.sender);
        //add revenue
        revenue += entranceFee;
    }

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // 2. 將LOTTERY_STATE改為開啟
    // 3. 並且設定入場費金額
    function startLottery(uint _entranceFee) public onlyOwner {
        //check if lottery already started
        require(currLotState == lotteryState.lotteryInactive);
        currLotState = lotteryState.lotteryActive;
        //set entrance fee
        entranceFee = _entranceFee;
        //set revenue to 0
        revenue = 0;
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
    function endLottery() public payable onlyOwner {
        currLotState = lotteryState.calculatingWinner;
        //randomize winner
        uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty,block.timestamp)))%players.length; 
        //set recent winner
        recentWinner = players[indexOfWinner];
        //send money to winner
        (bool sent, bytes memory data) = recentWinner.call{value: entranceFee}("");
        require(sent, "Send failed.");
        //clear array
        delete players;
        //reset revenue
        revenue = 0;
        //set currLotSate to inactive
        currLotState = lotteryState.lotteryInactive;
    }
}