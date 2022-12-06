/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Objetivo: Smart contract que permita a la gente adivinar el equipo que ganará el mundial.
// Fijar sistema de lock de apuestas, no tiene mucho sentido restringirlo solo para la final.

// * emitir eventos necesarios para indexar datos y mostrar en frontend:
contract WorldCupBet {
    address public owner;
    uint256 START_WORLDCUP_FINALMATCH = 1670324400;
    uint256 public totalBettedAmount = 0;
    uint256 public winnerId = 100;
    TeamInfo[16] public teamList;
    // teamId => user => amount betted
    mapping(uint256 => mapping(address => uint256)) teamUserBets;

    struct TeamInfo {
        uint256 id;
        string name;
        uint256 amountBetted;
    }

    //------- EVENTS -------
    event WorldCupBet__newBet(
        uint256 indexed teamId,
        address indexed user,
        uint256 amountBetted
    );

    event WorldCupBet__withdrawEarnings(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event WorldCupBet__setWinner(uint256 teamId);
    event WorldCup__setDateTheEnd(uint256 newDate);

    constructor(string[16] memory _teamList) {
        owner = msg.sender;
        initializeTeams(_teamList);
    }

    //------- MODIFIERS ----------
    modifier onlyOwner() {
        require(msg.sender == owner, "Onlyowner: user not owner");
        _;
    }

    modifier validTeamId(uint256 teamId) {
        // en octavos de final solo hay 16 equipos
        require(teamId < 16, "team ID must be between 0 and 15");
        _;
    }

    modifier isBettingOpen() {
        require(
            block.timestamp <= START_WORLDCUP_FINALMATCH,
            "Bet out of time range"
        );
        _;
    }

    modifier isDateTheEndEnabled(uint256 newDate) {
        require(newDate > block.timestamp, "Bet out of time range");
        _;
    }

    //------- EXTERNAL FUNCTIONS ---------

    function bet(uint256 teamId)
        external
        payable
        validTeamId(teamId)
        isBettingOpen
    {
        require(msg.value > 0, "nothing to bet");
        require(winnerId > 16);
        teamList[teamId].amountBetted += msg.value;
        teamUserBets[teamId][msg.sender] += msg.value;
        totalBettedAmount += msg.value;
        emit WorldCupBet__newBet(teamId, msg.sender, msg.value);
    }

    //check for reentrancy
    function withdraw() external {
        require(winnerId < 16);
        uint256 userOwedAmount = (teamUserBets[winnerId][msg.sender] *
            totalBettedAmount) / teamList[winnerId].amountBetted;

        require(userOwedAmount > 0, "nothing to withdraw");

        teamUserBets[winnerId][msg.sender] = 0;

        transferEth(userOwedAmount);

        emit WorldCupBet__withdrawEarnings(
            msg.sender,
            userOwedAmount,
            block.timestamp
        );
    }

    //------- INTERNAL -------
    function transferEth(uint256 amount) internal {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "something went wrong");
    }

    function initializeTeams(string[16] memory _teamList) internal {
        for (uint256 i = 0; i < _teamList.length; ) {
            unchecked {
                teamList[i].name = _teamList[i];
                teamList[i].amountBetted = 0;
                teamList[i].id = i;
                ++i;
            }
        }
    }

    //------- ADMIN FUNCTIONS -----------

    function setWinner(uint256 winnerTeamId)
        external
        validTeamId(winnerTeamId)
        onlyOwner
    {
        winnerId = winnerTeamId;
        emit WorldCupBet__setWinner(winnerTeamId);
    }

    //------- EDIT FINAL DATE
    function setDateFinish(uint256 newDate)
        external
        onlyOwner
        isDateTheEndEnabled(newDate)
    {
        START_WORLDCUP_FINALMATCH = newDate;
        emit WorldCup__setDateTheEnd(newDate);
    }

    //------- VIEW FUNCTIONS -------

    function getTeamList() public view returns (TeamInfo[16] memory) {
        return teamList;
    }

    function getAmountBettedToTeam(uint256 _id)
        public
        view
        validTeamId(_id)
        returns (uint256)
    {
        return teamList[_id].amountBetted;
    }
}