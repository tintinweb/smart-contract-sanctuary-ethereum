/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: final_project2.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address payable recentWinner;
    address private _owner;
    uint256 public entranceFee; 
    uint256 public AllMoney; //總投注金額
    uint256 public AllPeople; //總投注人數
    uint256 public PlayerNumber; 
    uint256 public total; //開彩總次數
    uint256 public charityfund; //慈善基金

    struct data{
        address winneraddr; //歷史中獎人的Address
        uint256 money;  //歷史中獎金額的金額
        uint256 people; //歷史總人數
    }
    mapping(uint256 => data) public datas;


    uint256 public withdrawtimes; //慈善家提領紀錄
    //建立一個struct紀錄每次提領的慈善家address及提領金額
    struct Charity{
        address charityaddr; //慈善家的Address
        uint256 money;  //提領金額
    }
    mapping(uint256 => Charity) public charityrecord;


   // 建立onlyOwner的modifier
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    // 定義enum
    enum STATUS{
        CLOSED,
        STARTED,
        COUNTING
    }
    // 宣告enum
    STATUS public LOTTERY_STATE;
    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor() {
        LOTTERY_STATE = STATUS.CLOSED;
        _owner = msg.sender;
        charityfund = 0;
        total = 0;
        AllPeople = 0;
        AllMoney = 0;
        withdrawtimes = 0;
    }
    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到players的array當中
    function enter() public payable{
        require(LOTTERY_STATE == STATUS.STARTED,"The game has not started yet!");
        require(msg.value == entranceFee,"The entrance fee is not correct!");
        players.push(msg.sender);
        PlayerNumber += 1;
        AllMoney += entranceFee;
        AllPeople += 1;
    }

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // 2. 將LOTTERY_STATE改為開啟
    // 3. 並且設定入場費金額
    function startLottery(uint256 fee) public onlyOwner{
        data storage d = datas[total];
        require(LOTTERY_STATE == STATUS.CLOSED,"The game has started already!");
        LOTTERY_STATE = STATUS.STARTED;
        entranceFee = fee;
        d.people = 0; //初始化累積人數
        d.money = 0;  //初始化累積金額
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
    function endLottery() public payable onlyOwner returns (address payable RecentWinner){
        uint256 Money;
        LOTTERY_STATE = STATUS.COUNTING;
        uint256 indexOfWinner = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.difficulty, block.timestamp)
                )
            )%players.length;
        data storage d = datas[total];
        
        Money = entranceFee*PlayerNumber*9/10; //90%的獎金給中獎人
        d.people = PlayerNumber; //紀錄本次Lottery的總投注數
        d.money = Money; //紀錄本次Lottery的總金額
        d.winneraddr = players[indexOfWinner]; //紀錄本次中獎者的address
        charityfund += entranceFee*PlayerNumber - Money;  //累積給慈善家的金額
        RecentWinner = payable(players[indexOfWinner]);
        RecentWinner.transfer(Money);  //傳送本次獎金給中獎人
        delete players; //清除
        LOTTERY_STATE = STATUS.CLOSED;
        PlayerNumber = 0; //初始化人數
        total+=1; //總開獎次數+1
    }


    //慈善家提領
    function charitytransfor(address payable caddress) public payable onlyOwner{
        caddress.transfer(charityfund);  //將金額轉給慈善家
        Charity storage c = charityrecord[withdrawtimes];
        c.charityaddr = caddress;  //慈善家地址提領紀錄
        c.money = charityfund;  //慈善家提領金額
        withdrawtimes+=1;  //提領次數+1
        charityfund = 0;
    }
}