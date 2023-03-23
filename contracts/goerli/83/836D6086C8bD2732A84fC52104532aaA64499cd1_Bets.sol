// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Bets {
    address payable public owner;
    uint256 public minBet;
    uint256 public maxBett;
    uint256 public betsOnHome;
    uint256 public betsOnTie;
    uint256 public betsOnAway;
    uint256 public numberOfBets;
    uint256 public maxAmountOfBets = 1000;
    address payable[] public players;
    struct Player {
        uint256 amountBet;
        uint16 teamSelected;
    }
    mapping(address => Player) public playerInfo;
    
    receive() external payable {}
    
    constructor() {
        owner = payable(msg.sender);
        minBet = 500000000000000;//1usd dollar
        maxBett = minBet * 100;
    }
    function kill() public {
        if(msg.sender == owner) selfdestruct(owner);
    }

    function checkPlayerExists(address player) public view returns(bool){
        for(uint256 i = 0; i < players.length; i++){
            if(players[i] == player) return true;
        }
        return false;
    }
    function bet(uint8 _teamSelected) public payable {
        require(!checkPlayerExists(msg.sender), "Some condition must be met");
        require(msg.value >= minBet && msg.value <= maxBett, "Some condition must be met2");
        
        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].teamSelected = _teamSelected;
        
        players.push(payable(msg.sender));
        
        if ( _teamSelected == 1){
            betsOnHome += msg.value;
        }
        if ( _teamSelected == 2){
            betsOnAway += msg.value;
        }
        if ( _teamSelected == 0){
            betsOnTie += msg.value;
        }
    }
    
    function distributePrizes(uint16 teamWinner) public {
        address payable[] memory winners = new address payable[](players.length);
        uint256 count = 0;
        uint256 LoserBet = 0;
        uint256 WinnerBet = 0;
        address add;
        uint256 tbet;
        address payable playerAddress;

        for(uint256 i = 0; i < players.length; i++){
            playerAddress = players[i];
            if(playerInfo[playerAddress].teamSelected == teamWinner){
                winners[count] = playerAddress;
                count++;
            }
        }

        if ( teamWinner == 1){
            LoserBet = betsOnAway+betsOnTie;
            WinnerBet = betsOnHome;
        }
        if ( teamWinner == 2){
            LoserBet = betsOnHome+betsOnTie;
            WinnerBet = betsOnAway;
        }
        if ( teamWinner == 0){
            LoserBet = betsOnAway+betsOnHome;
            WinnerBet = betsOnTie;
        }

        for(uint256 j = 0; j < count; j++){
            if(winners[j] != address(0)) {
                add = winners[j];
                tbet = playerInfo[add].amountBet;
                winners[j].transfer((tbet * (10000 + (LoserBet * 10000 / WinnerBet))) / 10000 );
            }
        }
        
        delete playerInfo[playerAddress];
        players = new address payable[](0);
        LoserBet = 0;
        WinnerBet = 0;
        betsOnAway = 0;
        betsOnHome = 0;
        betsOnTie = 0;
    }
    
    function AmountHome() public view returns(uint256){
        return betsOnHome;
    }
    function AmountAway() public view returns(uint256){
        return betsOnAway;
    }
    function AmountTie() public view returns(uint256){
        return betsOnTie;
    }    
}