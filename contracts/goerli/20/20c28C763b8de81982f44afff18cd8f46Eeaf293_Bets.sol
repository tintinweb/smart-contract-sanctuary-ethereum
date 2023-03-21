// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Bets {
    address payable public owner;
    uint256 public minBet;
    uint256 public maxBet;
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
    fallback() external payable {}
    constructor() public {
        payable(msg.sender);
        minBet = 500000000000000;//1usd dollar
        maxBet = minBet * 100;
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
        //The first require is used to check if the player already exist
        require(!checkPlayerExists(msg.sender));
        //The second one is used to see if the value sended by the player is 
        //Higher than the minum value
        require(msg.value >= minBet && msg.value < maxBet);
        
        //We set the player informations : amount of the bet and selected team
        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].teamSelected = _teamSelected;
        
        //then we add the address of the player to the players array
        players.push(payable(msg.sender));
        
        //at the end, we increment the stakes of the team selected with the player bet
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
        address payable[1000] memory winners;
        //We have to create a temporary in memory array with fixed size
        //Let's choose 1000
        uint256 count = 0; // This is the count for the array of winners
        uint256 LoserBet = 0; //This will take the value of all losers bet
        uint256 WinnerBet = 0; //This will take the value of all winners bet
        address add;
        uint256 tbet;
        address payable playerAddress;
    //We loop through the player array to check who selected the winner team
        for(uint256 i = 0; i < players.length; i++){
            playerAddress = players[i];
    //If the player selected the winner team
            //We add his address to the winners array
            if(playerInfo[playerAddress].teamSelected == teamWinner){
                winners[count] = playerAddress;
                count++;
            }
        }
    //We define which bet sum is the Loser one and which one is the winner
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
    //We loop through the array of winners, to give ethers to the winners
        for(uint256 j = 0; j < count; j++){
            // Check that the address in this fixed array is not empty
            if(winners[j] != address(0))
                add = winners[j];
                tbet = playerInfo[add].amountBet;
                //Transfer the money to the user
                winners[j].transfer((tbet*(10000+(LoserBet*10000/WinnerBet)))/10000 );
        }
        
        delete playerInfo[playerAddress]; // Delete all the players
        //players.length = 0; // Delete all the players array
        LoserBet = 0; //reinitialize the bets
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