/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// File: contracts/final_project1.sol


pragma solidity ^0.8.10;

contract Lottery {
    
    // Define State enum
    enum State {
        on_progress,
        end,
        close
    } 

    // Define a record struct
    struct RecordLottery {
        address owner;
        address winner;
        address charity;
        uint256 donation;
        uint256 entranceFee;
        uint256 amount;
        uint256 numOfBettors;
    }


    address private _owner;

    State public state;
    uint256 public numOfPlayers;
    uint256 public entranceFee;
    uint256 public amount;
    address public charity;
    address[] private players;

    RecordLottery[] private lotteries;
    uint256 public numOfDraws;
    mapping( address => uint ) private charities;

    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor() payable{
        _owner = msg.sender;
        delete players;
        numOfPlayers = 0;
        entranceFee = 0;
        amount = 0;
        charity = address(0);
        state = State.close;
    }

    // 建立onlyOwner的modifier
    modifier onlyOwner() {
        require( _owner == msg.sender, "This function can only be called by owner.");
        _;
    }

    function resetRecordLottery() private {
        require( state == State.end, "The state of lottery is not over" );
        delete players;
        numOfPlayers = 0;
        entranceFee = 0;
        amount = 0;
        charity = address(0);
        state = State.close;
    }

    /*
        實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
        1. 檢查目前LOTTERY_STATE是否為關閉狀態
        2. 將LOTTERY_STATE改為開啟
        3. 初始化 now lottery ( state, entranceFee, charity, amount, numofBattors )
    */
    function startLottery( uint256 _entranceFee, address _charity ) public onlyOwner{
        require( state == State.close, "Lottery state is not close" );
        state = State.on_progress;
        entranceFee = _entranceFee;
        charity = _charity;
        numOfDraws++;
    }

    /*
        實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
        並且任何人都可以使用且呼叫enter function
        1. 檢查目前LOTTERY_STATE是否已經開始
        2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
        3. 把msg.sender記錄到players的array當中
    */
    function enter() public payable{
        require( state == State.on_progress, "Not ready" );
        require( msg.value >= entranceFee, "Insufficient entry fee" );
        players.push( msg.sender );
        amount += msg.value;
        numOfPlayers++;
    }

    /*
        實作endLottery function, 此function是讓合約擁有者(eg. _owner)呼叫
        1. 把LOTTERY_STATE改為“正在計算贏家”狀態
        2. 透過加密雜湊演算法產生隨機數, 用來選擇這次賭盤的贏家 (程式碼如下)
            - 把msg.sender, block.difficulty, block.timestamp這三個input做打包
            - 將打包好的資料做keccak256加密雜湊演算法, keccak256會回傳byte32的result value
            - 把keccak256回傳的byte32的result value轉換成uint256, 再與players array的長度取餘數
            - 最後得到隨機數 "indexOfWinner"
            ======================================= Code =======================================
            |   uint256 indexOfWinner = uint256(                                               |
            |        keccak256(                                                                |
            |            abi.encodePacked(msg.sender, block.difficulty, block.timestamp)       |
            |       )                                                                          |
            |   ) % players.length;                                                            |
            ======================================= Code =======================================
        3. 透過indexOfWinner選出players array中的Address, 並assign給recentWinner value
        4. 把合約內所有的ETH傳給贏家
        5. 清空players array (⭐️)
        6. 把LOTTERY_STATE改為關閉狀態
    */
    
    event endLotteryEvent( uint256 winnerIndex, address winnerAddress, uint256 amount );
    function endLottery() public onlyOwner {
        require( players.length > 0, "No player" );
        require( state == State.on_progress, "Event not started yet" );
        
        state = State.end;
        
        bool sent;
        uint256 donation = uint256(amount / 10);

        ( sent, ) = payable(charity).call{value: donation}("");
        amount -= donation;

        require( sent, "fail send" );

        uint256 indexOfWinner = uint256( keccak256( abi.encodePacked(msg.sender, block.difficulty, block.timestamp) ) ) % players.length;
        ( sent, ) = payable(players[indexOfWinner]).call{value: amount}("");
        require( sent, "fail send" );
        
        emit endLotteryEvent( indexOfWinner, players[indexOfWinner], amount );
        RecordLottery memory lottery;
        lottery.owner = _owner;
        lottery.winner = players[indexOfWinner];
        lottery.donation = donation;
        lottery.entranceFee = entranceFee;
        lottery.amount = amount;
        lottery.numOfBettors = numOfPlayers;
        lotteries.push( lottery );
        charities[charity] += donation;

        resetRecordLottery();
    }


    modifier Require( uint256 index ) {
        require( (index < lotteries.length), "The index should be smaller than the number of lotto draw" );
        _;
    }

    // Query the historical total bet amount
    function getHistoricalTotalAmount( uint256 index ) public view Require(index) returns( uint256 _amount ) {
        return lotteries[index].amount;
    }

    // Query the historical total number of bettors
    function getHistoricalTotalBettors( uint256 index ) public view Require(index) returns( uint256 _numOfBettors ) {
        return lotteries[index].numOfBettors;
    }

    // Query the address of the winner of a certain session & get the amount & the number of bettors in this session
    function getHistorical( uint256 index ) public view Require(index) returns( address _winner, uint256 _amount, uint256 _numOfBettors ) {
        RecordLottery memory lotto = lotteries[index];
        return (lotto.winner, lotto.amount, lotto.numOfBettors);
    }

    // Enquiry about withdrawal records of charities
    function getWithdrawRecordsOfCharity( address addr ) public view returns( uint256 _numOfBettors ) {
        return charities[addr];
    }

    // transfer the owner to another person
    function transferOwner ( address newOwner ) public onlyOwner {
        _owner = newOwner;
    }
}