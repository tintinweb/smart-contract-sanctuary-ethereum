/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// File: contracts/final_project.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;
    address private _owner;

    uint256 private totalPlayers;
    uint256 private totalAmount;
    uint256 private totalTimes;
    uint256 private _entranceFee;
    uint256 private jackpot;

    struct Donation
    {
        address addr;
        uint256 amount;
    }

    struct Winner
    {
        address addr;
        uint256 amount;
        uint256 numOfPlayers;
    }

    mapping(uint256 => Donation) private donationRecord;
    mapping(uint256 => Winner) private winnerRecord;

    // 建立onlyOwner的modifier
    modifier ownerOnly()
    {
        require(msg.sender == _owner,"Invalid operation: You are not the owner.");
        _;
    }
    // 定義enum
        enum Status
        {
            closed,
            running
        }
    // 宣告enum
        Status public status;
    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor()
    {
        status = Status.closed;
        _owner = msg.sender;
        totalPlayers = 0;
        totalAmount = 0;
        totalTimes = 0;
    }

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到players的array當中
    function enter() public payable
    {
        require(status == Status.running, "Invalid operation: Lottery hasn't been started.");
        require(msg.value >= _entranceFee, "Invalid operation: Insufficient stake");
        players.push(msg.sender);
        jackpot += msg.value;

        totalAmount += msg.value;
        totalPlayers++;
    }

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // 2. 將LOTTERY_STATE改為開啟
    // 3. 並且設定入場費金額
    function startLottery(uint256 entranceFee) public ownerOnly
    {
        require(status == Status.closed, "Invalid operation: Lottery has been started.");
        status = Status.running;
        _entranceFee = entranceFee;
        jackpot = 0;
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
    function endLottery(address payable charity) public payable ownerOnly
    {
        require(status == Status.running, "Invalid operation: Lottery hasn't been started.");
        uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;
        recentWinner = players[indexOfWinner];

        uint256 fund = jackpot / 10;
        charity.transfer(fund);
        donationRecord[totalTimes].addr = charity;
        donationRecord[totalTimes].amount = fund;

        payable(recentWinner).transfer(jackpot - fund);
        winnerRecord[totalTimes].addr = recentWinner;
        winnerRecord[totalTimes].amount = jackpot - fund;
        winnerRecord[totalTimes].numOfPlayers = players.length;

        delete players;
        status = Status.closed;
        totalTimes++;
    }

    function checkRule() public view returns(uint256, uint256)
    {
        require(status == Status.running, "Invalid operation: Lottery hasn't been started.");
        return (_entranceFee, players.length);
    }

    function checkNumOfTimes() public view returns(uint256)
    {
        return totalTimes;
    }

    function checkTotalAmount() public view returns(uint256)
    {
        return totalAmount;
    }

    function checkTotalPlayers() public view returns(uint256)
    {
        return totalPlayers;
    }

    function checkWinner(uint256 th) public view returns(address, uint256, uint256)
    {
        Winner memory w = winnerRecord[th];
        return (w.addr, w.amount, w.numOfPlayers);
    }

    function checkDonation(uint256 th) public view returns(address, uint256)
    {
        Donation memory d = donationRecord[th];
        return (d.addr, d.amount);
    }
}