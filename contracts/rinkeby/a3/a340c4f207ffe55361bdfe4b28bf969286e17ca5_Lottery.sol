/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// File: contracts/final_project1.sol


pragma solidity ^0.8.10;
// EX 1. 10%的彩金累積後當成慈善基金，由owner設定給某慈善單位的Address進行一次性提領。
// EX 2. 能查詢歷史開彩總次數。
// EX 3. 能查詢歷史總投注金額。
// EX 4. 能查詢歷史總投注人次。
// EX 5. 能查詢某屆贏家的Address & 獲得金額 & 該屆投注人數。
// EX 6. 能查詢慈善基金的提領紀錄。
// EX 7. 或是其他，你覺得有意義的功能 (請在報告中說明清楚實作功能)。
// EX 7-1：查詢目前獎金累計多少
// EX 7-2：讓owner查詢各玩家目前之賭注

contract Lottery {
    address[] public players;                                           //當前參與玩家有哪些
    mapping(address => uint256) private player_stake;                   //各玩家之賭注

    address public recentWinner;                                        //本局的勝利者的地址
    address private _owner;                                             //合約擁有者的地址
    uint256 public EntranceFee=0;                                       //單次投注的最小金額
    address private charity=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; //慈善機構的地址

    uint256 private History_Times=0;                                    //歷史開彩總次數
    mapping(uint256 => uint256) private History_Prize;                  //歷史總投注金額
    mapping(uint256 => uint256) private History_People;                 //歷史開彩總投注人次
    mapping(uint256 => address) private History_Winner;                 //歷史贏家地址
    mapping(uint256 => address) private History_charity;                //歷史捐助機構地址

    modifier onlyOwner() {
        require(msg.sender == _owner, "you are not owner,you a bad boy :(");
        _;
    }//只有合約擁有者才能做此動作的的modify

    // 彩券目前狀況
    enum STATE{
        Close,
        Open,
        Calculating
        }

    // 宣告彩券目前的狀況
    STATE LOTTERY_STATE;
    
	constructor() public {
		LOTTERY_STATE=STATE.Close;          // 1. 宣告一開始LOTTERY_STATE
		_owner = msg.sender;                // 2. assign msg.sender給_owner variable
	}// 實作constructor
    
    function enter() public payable {
        require(LOTTERY_STATE == STATE.Open, "The lottery hasn't started yet");     // 1. 檢查目前LOTTERY_STATE是否已經開始
        require(msg.value >= EntranceFee, "EntranceFee doesn't enough");            // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
        players.push(msg.sender);                                                   // 3. 把msg.sender記錄到players的array當中
        player_stake[msg.sender] += msg.value;                       // 7-2：儲存玩家目前之賭注
    }// 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中，並且任何人都可以使用且呼叫enter function
    function Set_charity(address charity_input) public 
    {
        charity=charity_input;
    }// EX 1. 由owner設定給某慈善單位的Address進行一次性提領。
    function stake_Get_player(address player_input) public view onlyOwner returns (uint256)
    {
        return player_stake[player_input];                   
    }// EX 7-2：讓owner查詢各玩家目前之賭注
 
    function Times_Get_History() public view returns (uint256)
    {
        return History_Times;                   
    }// EX 2. 能查詢歷史開彩總次數。
    function Prize_Get_History() public view returns (uint256)
    {
        uint256 num = 0;
        for (uint256 i;i < History_Times;i++)
            num+=History_Prize[i];
        return num;                             
    }// EX 3. 能查詢歷史總投注金額。
    function People_Get_History_() public view returns (uint256)
    {
        uint256 num = 0;
        for (uint256 i;i < History_Times;i++)
            num+=History_People[i];
        return num;                             
    }// EX 4. 能查詢歷史總投注人次。
    function Winner_Get_History(uint256 time) public view returns (address addr,uint256 pirze,uint256 people)
    {
        return (History_Winner[time],History_Prize[time]*9/10,History_People[time]);
    }// EX 5. 能查詢某屆贏家的Address & 獲得金額 & 該屆投注人數。
    function charity_Get_History(uint256 time) public view returns (address TakeCharity, uint256 TakeMoney) 
    {
        return (History_charity[time],History_Prize[time]/10);         
    }// EX 6. 能查詢慈善基金的提領紀錄。
    function Prize_now() public view returns (uint256)
    {
        return address(this).balance;
    }// EX 7-1：查詢目前獎金累計多少
       
    
    function startLottery(uint256 SetEntranceFee) public onlyOwner 
    {
        if(LOTTERY_STATE == STATE.Close)        // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
        {
            LOTTERY_STATE = STATE.Open;         // 2. 將LOTTERY_STATE改為開啟
        }   
            EntranceFee = SetEntranceFee;       // 3. 並且設定入場費金額
    }// 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤

    function Record_History (uint256 H_Prize,uint256 H_People,address H_Winner,address H_charity)private
    {
        History_Prize[History_Times]=H_Prize;         // 紀錄歷史投注金額
        History_People[History_Times]=H_People;       // 紀錄歷史投注人數
        History_Winner[History_Times]=H_Winner;       // 紀錄歷史中獎者
        History_charity[History_Times]=H_charity;     // 紀錄歷史捐贈單位
        History_Times++;                              // 歷史開彩總次數+1
    }//記錄歷史

    function endLottery()public payable onlyOwner returns(uint256) 
    {
        require(msg.sender==_owner,"you are not owner,you a bad boy :(");
        LOTTERY_STATE = STATE.Calculating;      // 1. 把LOTTERY_STATE改為“正在計算贏家”狀態
        
        uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp)))%players.length; // 2. 透過加密雜湊演算法產生隨機數, 用來選擇這次賭盤的贏家
        recentWinner=players[indexOfWinner];    // 3. 透過indexOfWinner選出players array中的Address, 並assign給recentWinner value
        
        Record_History(address(this).balance, players.length, recentWinner,charity); 
        
        players[indexOfWinner].call{value: address(this).balance*9/10}("You won!"); // 4. 把合約內所有的ETH傳給贏家
        charity.call{value: address(this).balance}("You charity!"); // EX 1. 10%的彩金累積後當成慈善基金，由owner設定給某慈善單位的Address進行一次性提領。
        
        for (uint256 i;i < players.length;i++)
            player_stake[players[i]]=0;         // 7-2.清空賭注資料

        delete players;                         // 5. 清空players array (⭐️)

        LOTTERY_STATE = STATE.Close;            // 6. 把LOTTERY_STATE改為關閉狀態
        return indexOfWinner;
        }
    }//實作endLottery function, 此function是讓合約擁有者(eg. _owner)呼叫