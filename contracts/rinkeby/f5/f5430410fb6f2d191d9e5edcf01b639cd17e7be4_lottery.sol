/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: tests/final_project1.sol


pragma solidity ^0.8.10;

contract lottery {
    address payable[] public players;
    address public recentWinner;
    address private _owner;
    uint256 private entranceFee;

    // 建立onlyOwner的modifier
    modifier onlyOwner(){
        require(msg.sender == _owner,"You are not the owner, byebye");
        _;
    }
    // 定義enum
    enum State {Started, Closed, Calculating}

    // 宣告enum
    State state;

    // 實作constructor
    // 1. 宣告一開始LOTTERY_STATE
    // 2. assign msg.sender給_owner variable
    constructor(){
        state = State.Started;
        _owner = msg.sender;
    }

    // 實作enter function, 此function要讓使用者下注, 將下注金額存入合約中
    // 並且任何人都可以使用且呼叫enter function
    // 1. 檢查目前LOTTERY_STATE是否已經開始
    // 2. 檢查msg.value有沒有大於規定的入場費 (金額自訂)
    // 3. 把msg.sender記錄到players的array當中
    function enter() public payable {
        require(state == State.Started,"The lottery is not available now.");
        require(msg.value == entranceFee,"Your lottery is less than entranceFee, sorry.");
        players.push(payable(msg.sender));
    }

    // 實作startLottery function, 此function是讓合約擁有者(eg. _owner)呼叫, 並開始賭盤
    // 1. 檢查目前LOTTERY_STATE是否為關閉狀態
    // 2. 將LOTTERY_STATE改為開啟
    // 3. 並且設定入場費金額
    function startLottery(uint256 _entranceFee) public onlyOwner{
        if( state == State.Closed) state = State.Started;
        entranceFee = _entranceFee;
    }
    // 回傳 entranceFee
    function getEntraneFee() public view returns(uint256){
        return entranceFee;
    }
    // 回傳目前player 數量
    function NumofPlayer() public view returns(uint256){
        return players.length;
    }


    event Winner(address _winner);
    function endLottery() public onlyOwner{
        require(state == State.Started,"The lottery doesn't open.");//確認lottery是否開啟
        require(players.length != 0,"There is no player in this turn of lottery.");//確認玩家數量是否為0
        state = State.Calculating;//將lottery 設置成calculating.
        //藉由keccak256 求出一個winner 的index值
        uint256 indexOfWinner = uint256( keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;
        //將winner 的address 設給recentWinner 這個variable
        recentWinner = players[indexOfWinner];
        //轉移此次合約所擁有的彩金
        payable(recentWinner).transfer(address(this).balance);
        emit Winner(recentWinner);
        players = new address payable[](0);
        entranceFee = 0;
        state = State.Closed;
    }
}