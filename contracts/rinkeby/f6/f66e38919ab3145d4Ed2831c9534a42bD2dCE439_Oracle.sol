/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;



contract Oracle {
    address private _owner;
    struct Match{
        string homeTeam;
        string awayTeam;
        uint8 homeGoal;
        uint8 awayGoal;
        string[] goalScorers;
        uint8[] numberOfGoalsScored;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not an owner");
        _;
    }
    
/*
* @author Tahlil
* @dev string -> <LeagueName>-<YYYY> (YYYY -> season i. e. for 2019-2020 session - session=2019)
*/
    mapping (string=>Match[]) private _matches;

    constructor() {
        _owner = msg.sender;
    }
    
    function getMatch(string memory league) public view returns(Match[] memory){
        return _matches[league];
    }

    function addMatch(string memory _league, string memory _homeTeam, string memory _awayTeam, uint8 _homeGoals, uint8 _awayGoals, string[] memory _scorers, uint8[] memory _scores) external onlyOwner {
        _matches[_league].push(Match(_homeTeam, _awayTeam, _homeGoals, _awayGoals, _scorers, _scores));
    }

}