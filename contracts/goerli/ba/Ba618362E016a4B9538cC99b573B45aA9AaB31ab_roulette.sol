// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract roulette{

    /*
    Picks with numbers:
    -Green:1
    -Blue:2
    */

    address owner;

    modifier onlyOwner{
        require(msg.sender == owner,"You aren't the owner");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    uint256 public roundIndex = 1;
    uint256 public minBet = 0.01 ether;

    mapping(uint256 => bet[]) internal bets;

    struct bet{
        address player;
        uint256 pick;
        uint256 amount;
    }

    struct roundInfo{
        address[] winners;
        uint256 totalBetAmount;
    }

    function placeBet(uint256 pick) public payable{
        require(pick == 1 || pick == 2,"You can't pick outside of Green or Blue.");
        require(msg.value >= minBet,"You are trying to bet less than min bet.");
        bets[roundIndex].push(bet(msg.sender,pick,msg.value));
    }

    function getBets(uint256 round) public view returns(bet[] memory){
        return bets[round];
    }

    function getWinners(uint256 winnerPick)internal view returns(address[] memory){

        address[] memory winnersOfRound;
        uint256 currentWinnerIndex;


        for(uint i = 0; i < bets[roundIndex].length; i++){
            if((bets[roundIndex])[i].pick == winnerPick){
                winnersOfRound[currentWinnerIndex] = (bets[roundIndex])[i].player;
                currentWinnerIndex++;
            }
        }

        return winnersOfRound;


    }

    function payWinners(address[] memory winners) internal {

        uint256 balance = address(this).balance;
        uint256 winnerCount = winners.length;

        
        for(uint256 i = 0; i < winnerCount; i++){
            payable(winners[i]).transfer(balance/winnerCount);
        }


    }

    function finalizeRound(uint256 winnerPick) public onlyOwner{

        payWinners(getWinners(winnerPick));
        roundIndex++;

    }




}