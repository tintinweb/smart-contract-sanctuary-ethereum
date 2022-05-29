/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT
// File: contracts/final_project2_40871228H.sol


pragma solidity ^0.8.0;

contract Lottery {

    struct Player {
        uint256 count;
        uint256 index;
    }
    address[] public addressIndex;
    mapping(address => Player) player;
    address[] public pool;

    uint256[] public charityLog;
    address public charity = 0x0b548Dd49b9867d3467fAc04fe259e9A1D9A2123;
    address[] public winnerLog;

    uint256[] public historyPool;
    uint256[] public historyPlayer;

    address private _owner;

    uint256 public entranceFee;

    modifier isOwner(){
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    enum LotSet{
        OPEN,
        CLOSED,
        CALCULATING
    }
    LotSet public lotset;

    constructor() {
        _owner = msg.sender;
        lotset = LotSet.CLOSED;
    }

    function enter() public payable{
        require(lotset == LotSet.OPEN, "lot not open yet.");
        require(msg.value >= entranceFee, "fee not enough.");

        if(newPlayer(msg.sender)){
            player[msg.sender].count = 1;
            addressIndex.push(msg.sender);
            player[msg.sender].index = addressIndex.length - 1;
        }else{
            player[msg.sender].count++;
        }

        pool.push(msg.sender);
        
    }

    function newPlayer(address playerAdd) private view returns(bool){
        if(addressIndex.length == 0) return true;
        return(addressIndex[player[playerAdd].index] != playerAdd);
    }

    function startLottery() public isOwner{
        require(lotset == LotSet.CLOSED, "lot already opened.");
        entranceFee = .01 ether;
        lotset = LotSet.OPEN;
    }

    function endLottery() public isOwner{
        require(lotset == LotSet.OPEN, "not open, cannot end");
        require(pool.length > 0, "pool is empty");
        
        lotset = LotSet.CALCULATING;
        uint256 win = randomNum();

        historyPool.push(address(this).balance);
        winnerLog.push(pool[win]);
        (bool sent1, ) = pool[win].call{value: 9*(address(this).balance)/10}("");
        require(sent1, "Sent failed.");
        charityLog.push(address(this).balance);
        (bool sent2, ) = charity.call{value: address(this).balance}("");
        require(sent2, "Sent failed.");

        historyPlayer.push(addressIndex.length);

        pool = new address[](0);
        addressIndex = new address[](0);

        lotset = LotSet.CLOSED;
    }

    function randomNum() private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % pool.length;
    }

    function poolNum() public view returns(uint256){
        require(lotset == LotSet.OPEN, "not open, no player.");
        return pool.length;
    }

    function poolPrice() public view returns(uint256){
        require(lotset == LotSet.OPEN, "not open, no pool price.");
        return address(this).balance;
    }

    function history() public view returns(uint256){ //歷史開彩總次數
        require(charityLog.length > 0, "no history.");
        return charityLog.length;
    }

    function historyPoolTotal() public view returns(uint256){ //歷史總投注金額
        require(historyPool.length > 0, "no history pool.");
        uint256 temp = 0;
        for(uint256 i = 0 ; i < historyPool.length ; i++) temp += historyPool[i];
        return temp;
    }

    function historyPlayerTotal() public view returns(uint256){ //歷史總投注人次
        require(historyPlayer.length > 0, "no history player.");
        uint256 temp = 0;
        for(uint256 i = 0 ; i < historyPlayer.length ; i++) temp += historyPlayer[i];
        return temp;
    }

    function historyWinnerLog(uint256 n) public view returns(address, uint256, uint256){
        //某屆贏家的Address & 獲得金額 & 該屆投注人數
        require(winnerLog.length > 0, "no winner log.");
        require(n <= winnerLog.length, "n not exist (n > winnerLog).");
        require(n > 0, "n not exist (n <= 0).");
        return (winnerLog[n-1], 9*historyPool[n-1]/10, historyPlayer[n-1]);
    }

    function historyCharityLog(uint256 n) public view returns(uint256){
        //慈善基金的提領紀錄
        require(charityLog.length > 0, "no charity log.");
        require(n <= charityLog.length, "n not exist (n > charityLog).");
        require(n > 0, "n not exist (n <= 0).");
        return charityLog[n-1];
    }
}