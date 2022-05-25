/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;


interface IBetting{

    struct Match{
        string competition;
        string teamA;
        string teamB;
        uint8 tie;
        uint8 teamAWin;
        uint8 teamBWin;
        string gameDay;
    }
    struct Bet{
        address better;
        uint amount;
        uint matchID;
        string betType;
        uint oddForWinning;
    }
    event matchAdded(Match _match);
    event betPlaced(Bet _bet);
    event winningsPayed();

    function addMatch(string memory competition, string memory teamA, string memory teamB, uint8  tie, uint8  teamAWin, uint8  teamBWin, string memory gameDay) external;
    function placeBet(uint matchID, string memory betType, uint8 oddForWinning) external payable;
    function payWinningBets(uint matchID, string memory winningType) external;

}




contract Betting is IBetting{
    uint ID;
    Match[] private matches;
    //Bet[] private bets;
    address private adminAdress;
    mapping(uint => Bet[]) private bets; //key:matchID value:array of bets on that match
    mapping(uint => bool) private closedBets; //key:matchID value:is that match opened for betting
    uint deadline;

    constructor(){
        adminAdress=msg.sender;
        //deadline=block.timestamp+600;
    }

    modifier adminOnly {
        require(msg.sender==adminAdress, "Only admin can use this function");
        _;
    }


    //Adds new match into match pool 
    function addMatch(string memory _competition, string memory _teamA, string memory _teamB, uint8  _tie, uint8  _teamAWin, uint8  _teamBWin, string memory _gameDay) override external adminOnly{
        Match memory tmp = Match(_competition,_teamA,_teamB,_tie,_teamAWin,_teamBWin,_gameDay);
        matches.push(tmp);
        emit matchAdded(tmp);
    }

    //Places a bet on a match using matchID, and takes betType(1- home team wins,2- away team wins,x- match is tied)
    function placeBet(uint _matchID, string memory _betType, uint8 _oddForWinning) override external payable{
        //require(block.timestamp<deadline,"You have passed the deadline.");
        require(msg.value!=0,"Please provide some ether");
        require(
            keccak256(abi.encodePacked('1')) == keccak256(abi.encodePacked(_betType)) ||
            keccak256(abi.encodePacked('2')) == keccak256(abi.encodePacked(_betType)) ||
            keccak256(abi.encodePacked('x')) == keccak256(abi.encodePacked(_betType)),
            "Invalid bet type");
        require(_matchID<matches.length,"Match you are trying to bet on does not exist.");
        require(closedBets[_matchID]==false,"Match you are trying to bet on is over and winnings have already been paid out.");

        Bet memory tmp = Bet(msg.sender,msg.value,_matchID,_betType,_oddForWinning);
        updateMatchOdds(_matchID,_betType,_oddForWinning);
        bets[_matchID].push(tmp);
        emit betPlaced(tmp);
    }

    //Pays out winnings to all betters that were correct, and makes it so noone can bet on this match anymore.
    function payWinningBets(uint _matchID, string memory _winningType) override external adminOnly{
        require(
            keccak256(abi.encodePacked('1')) == keccak256(abi.encodePacked(_winningType)) ||
            keccak256(abi.encodePacked('2')) == keccak256(abi.encodePacked(_winningType)) ||
            keccak256(abi.encodePacked('x')) == keccak256(abi.encodePacked(_winningType)),
            "Invalid bet type");
        require(_matchID<matches.length,"Match you are trying to pay out does not exist.");
        require(closedBets[_matchID]==false,"Match you are trying to pay out is over and winnings have already been paid out.");

        for(uint i=0; i<bets[_matchID].length; i++){
                if(
                    bets[_matchID][i].matchID==_matchID  && 
                    keccak256(abi.encodePacked(bets[_matchID][i].betType)) == keccak256(abi.encodePacked(_winningType))){
                        payable(bets[_matchID][i].better).transfer((bets[_matchID][i].amount*bets[_matchID][i].oddForWinning)*95/100);
                }
            }
        closedBets[_matchID]=true;
        emit winningsPayed();
    }

    //Used to provide ether to our contract in case we need more funds
    function fund() external payable adminOnly{
        //fund the contract
    }

    //Used by owner to collect his profit
    function withdraw(uint amount) external adminOnly {
        amount=amount*1000000000000000000;
        if(amount>address(this).balance){
            amount=address(this).balance;
        }
        payable(msg.sender).transfer(amount);
    }

    //Used for our API to return all matches
    function getMatches() external view returns (Match [] memory) {
        return matches;
    }

    //Used to update match odds for every single bet
    function updateMatchOdds(uint _matchID, string memory _betType, uint8 _oddForWinning) private{
        if(keccak256(abi.encodePacked('1')) == keccak256(abi.encodePacked(_betType))){
            matches[_matchID].teamAWin=_oddForWinning;
        }
        else if(keccak256(abi.encodePacked('x')) == keccak256(abi.encodePacked(_betType))){
            matches[_matchID].tie=_oddForWinning;
        }
        else{
            matches[_matchID].teamBWin=_oddForWinning;
        }
    }
    
    


}