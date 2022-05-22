/**
 *Submitted for verification at Etherscan.io on 2022-05-22
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
    event matchAdded(Match _match);

    function addMatch(string memory competition, string memory teamA, string memory teamB, uint8  tie, uint8  teamAWin, uint8  teamBWin, string memory gameDay) external;



}




contract Betting is IBetting{
    uint ID;
    Match[] public matches;
    address private adminAdress;
    bool private canPlaceBets;

    constructor(){
        ID=0;
        adminAdress=msg.sender;
        canPlaceBets=true;
    }


    modifier adminOnly {
        require(msg.sender==adminAdress, "Only admin can use this function");
        _;
    }


    function addMatch(string memory competition, string memory teamA, string memory teamB, uint8  tie, uint8  teamAWin, uint8  teamBWin, string memory gameDay) override external adminOnly{
        Match memory tmp = Match(competition,teamA,teamB,tie,teamAWin,teamBWin,gameDay);
        matches[ID]=tmp;
        incrementID();
        emit matchAdded(tmp);

    }


    function incrementID() private{
        ID++;
    }

    


}