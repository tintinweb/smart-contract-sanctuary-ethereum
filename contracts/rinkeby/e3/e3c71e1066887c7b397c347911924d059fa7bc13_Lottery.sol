/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// File: final_project1_done.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    uint256 public playerNum; 
    address public recentWinner;

    address private _owner;

    uint256 public entranceFee;
    // 建立onlyOwner的modifier
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    // 定義enum
    enum LOTTERY_STATE{
        OPEN,// 開始
        CALCULATE,// 計算
        CLOSED// 關閉
    }
    // 宣告enum
    LOTTERY_STATE public status; //public
    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor  () public payable {
        status = LOTTERY_STATE.CLOSED; 
        _owner = msg.sender;
    }

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到players的array當中
    function enter() //address add, uint256 money
        external payable 
        {
        require(status==LOTTERY_STATE.OPEN, "Lottery state is not open.");
        require(msg.value<entranceFee, "No money to pay entrance fee.");
        players.push(msg.sender);
        playerNum=players.length;
    }

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // 2. 將LOTTERY_STATE改為開啟
    // 3. 並且設定入場費金額
    function startLottery () public onlyOwner{
        // if(_owner!=msg.sender) return; 
        require(status==LOTTERY_STATE.CLOSED, "Lottery state is not closed.");
        status=LOTTERY_STATE.OPEN;
        entranceFee=20;
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
    // 5. 清空players array (⭐️)，上網查
    // 6. 把LOTTERY_STATE改為關閉狀態
    function endLottery() public onlyOwner{
        status=LOTTERY_STATE.CALCULATE;
        uint256 indexOfWinner = uint256(                                              
            keccak256(                                                                
            abi.encodePacked(msg.sender, block.difficulty, block.timestamp)       
            )                                                                          
        ) % players.length;
        recentWinner=players[indexOfWinner];
        payable(recentWinner).transfer(address(this).balance);
        delete players;
        status=LOTTERY_STATE.CLOSED;       
    }
}