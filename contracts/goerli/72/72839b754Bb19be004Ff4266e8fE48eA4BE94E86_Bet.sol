/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// File: contracts/Bet.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Bets {
    uint256 winner;
    uint256[2] bettedAmount;
    uint256 dateLimit;
}

contract Bet{
    
    uint256 public totalBets;
    uint256 ownerProffit;
    uint256 ownerProffitComission;
    address public owner;
    // id apuesta            apostador             opcion        cantidad
    // mapping(uint256 => mapping(address => mapping(uint256 => uint256))) userBettedAmount;
    // id apuesta            apostador       [opcion, cantidad]
    mapping(uint256 => mapping(address => uint256[2])) userBettedAmount;

    Bets[] public bets;

    modifier onlyOwner(){
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    modifier betExists(uint256 _index){
        require(_index < bets.length, "that bet does not exists");
        _;
    }

    constructor(uint256 _ownerProffitComission){
        owner = msg.sender;
        if (_ownerProffitComission > 15){
            ownerProffitComission == 15;
        } else {
            ownerProffitComission = _ownerProffitComission;
        }
    }

    function createBet(uint256 _dateLimit) external onlyOwner() {
        require(_dateLimit > block.timestamp, "the timestamp is on the past");
        bets.push(Bets({winner: 0, bettedAmount: [uint256(0), 0], dateLimit: _dateLimit}));
        totalBets++;
    }

    function setWinner(uint256 _index, uint256 _winner) external onlyOwner() betExists(_index) {
        Bets storage bet = bets[_index];
        require(bet.winner == 0, "the winner is already setted");
        require(block.timestamp > bet.dateLimit, "the bet has not endded");
        bet.winner = _winner;
        bet.dateLimit = 0;
    }

    function makeBet(uint256 _index, uint256 _option) payable external betExists(_index) {
        require(( msg.value > 0), "not enough balance");
        Bets storage bet = bets[_index];
        require(((_option == userBettedAmount[_index][msg.sender][0] || userBettedAmount[_index][msg.sender][0] == 0)), "you already bet the other option");
        require((_option != 0 && _option <= bet.bettedAmount.length), "the option does not exists");
        require(block.timestamp <= bet.dateLimit, "time to bet is over");
        userBettedAmount[_index][msg.sender][0] = _option;
        userBettedAmount[_index][msg.sender][1] += msg.value;
        bet.bettedAmount[_option - 1] += msg.value;
    }

    function withdraw(uint256 _index) external betExists(_index) {
        Bets storage bet  = bets[_index];
        require(block.timestamp > bet.dateLimit, "the bet has not endded");
        require(userBettedAmount[_index][msg.sender][bet.winner] > 0, "");
        uint256 amount = userBettedAmount[_index][msg.sender][bet.winner] * (bet.bettedAmount[0] + bet.bettedAmount[1]) / bet.bettedAmount[bet.winner - 1];
        userBettedAmount[_index][msg.sender][1] = 0;
        ownerProffit += amount * (ownerProffitComission) / 100;
        (bool success, ) = owner.call{value: amount * (100 - ownerProffitComission) / 100}("");
        require(success, "");
    }

    function comissionWithdraw() external onlyOwner() {
        require(ownerProffit > 0, "there is no proffit");
        (bool success, ) = owner.call{value: ownerProffit}("");
        require(success, "");
        ownerProffit = 0;
    }

    receive() external payable {
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "");
    }

    fallback() external payable {
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "");
    }
}