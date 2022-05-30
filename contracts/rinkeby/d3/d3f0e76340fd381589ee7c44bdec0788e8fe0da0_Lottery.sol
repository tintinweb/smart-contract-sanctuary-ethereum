/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// File: finalProject.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;

    address public _owner;
    uint256 public NumberOfLottery;
    uint256 public NumberOfMoney;
    uint256 public NumberOfPlayer;
    uint256 public entranceFee;
    uint256 public lottery_state;
    uint256 public indexOfWinner;

    struct Winner {
        address addr; // 贏家的Address
        uint256 amount; // 贏家獲得的金額
        uint256 people; // 該屆投注人數
    }

    struct Charity {
        address addr; // 慈善機構的Address
        uint256 amount; // 慈善機構獲得的慈善基金
        uint256 lottery; // 第幾次投注
    }



    mapping(uint256 => Winner) public winner;
    mapping(uint256 => Charity) public charity;

    // 建立onlyOwner的modifier
    modifier onlyOwner{
        require(msg.sender == _owner, "Only owner can call this function.");
        _;
    }

    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor()  {
        lottery_state = 0;
        _owner = msg.sender;
    }

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到players的array當中
    function enter() public payable {
        require(lottery_state == 1, "No lottery started yet.");
        require(msg.value >= entranceFee, "Insufficient amount.");
        players.push(msg.sender);
        
    }

    function playersNum() public view returns(uint256){
        return players.length;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // 2. 將LOTTERY_STATE改為開啟
    // 3. 並且設定入場費金額
    function startLottery(uint256 fee) onlyOwner public{
        require(lottery_state == 0, "There is an lottery going on.");
        lottery_state = 1;
        entranceFee = fee;
    }

    // function getLotteryData() view public returns(uint256, uint256){
    //     return(entranceFee, players.length);
    // }

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
    function endLottery(address payable to) onlyOwner public payable returns(uint256){
        require(lottery_state == 1, "No lottery started yet.");//檢查lottery_state是否為開啟的狀態
        lottery_state = 0;//將lottery_state設為關閉
        indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;//隨機產生贏家
        uint256 money = address(this).balance;//這裡的money是合約中所有的錢
        NumberOfMoney += money;//第二部分的功能，紀錄歷史總投注金額
        uint256 donate = (money / 10) * 1;//配合第二部分的功能，計算要給慈善機構的錢
        money = (money / 10) * 9;//配合第二部分的功能，計算要給贏家的錢
        NumberOfPlayer += players.length;//第二部分的功能，紀錄歷史總投注人數
        uint256 lotteryID = NumberOfLottery++; // 第二部分的功能，NumberOfLottery紀錄歷史開彩總次數
        Winner storage w = winner[lotteryID]; // 第二部分的功能，複製一個名稱為w的指標，指向storage中winner[lotteryID]的空間
        Charity storage c = charity[lotteryID]; // 第二部分的功能，複製一個名稱為c的指標，指向storage中charity[lotteryID]的空間
        w.addr = players[indexOfWinner]; // 第二部分的功能，將players[indexOfWinner] assgin給winner[lotteryID]的addr
        w.amount = money;//第二部分的功能，將money assgin給winner[lotteryID]的amount
        w.people = players.length;//第二部分的功能，將players.length assgin給winner[lotteryID]的people
        c.addr = to;//第二部分的功能，將慈善機構地址to assgin給charity[lotteryID]的addr
        c.amount = donate;//第二部分的功能，將給慈善機構錢(10%)donate assgin給charity[lotteryID]的amount
        c.lottery = lotteryID;//第二部分的功能，將該次開彩編號(從0開始)lotteryID assgin給charity[lotteryID]的lottery
        recentWinner = players[indexOfWinner];//第二部分的功能，提供玩家查詢最近一次贏家地址
        to.transfer(donate);//第二部分的功能，將給慈善機構錢(donate)轉給慈善機構
        payable(players[indexOfWinner]).transfer(money);//第一部分功能，將開彩金額(90%)轉給該次贏家
        delete players;//第一部分功能，該次投注結束，要把紀錄players陣列清空
        return indexOfWinner;
    }
}