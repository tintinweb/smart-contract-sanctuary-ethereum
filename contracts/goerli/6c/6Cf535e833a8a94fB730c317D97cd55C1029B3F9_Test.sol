/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Test {
    enum AgendaState { Voting, Accepted, Dismissed }
    struct Agenda {
        uint no;
        string title;
        string content;
        address proposer;
        uint agree;
        uint disagree;
        AgendaState state;
    }

    enum Vote { Idle, Agree, Disagree }// Default: Idle
    struct User {
        string name;
        string[] proposedAgendas;
        mapping(string => Vote) voteMap;
    }

    uint latestAgendaNo = 0;
    mapping(string => Agenda) agendaMap;// Agenda.title => Agenda
    mapping(address => User) userMap;

    function propose(string memory title, string memory content) public {
        require(agendaMap[title].no == 0, "has already been proposed");

        agendaMap[title] = Agenda(++latestAgendaNo, title, content, msg.sender, 0, 0, AgendaState.Voting);
        userMap[msg.sender].proposedAgendas.push(title);
    }

    function vote(string memory title, bool agree) public {
        require(userMap[msg.sender].voteMap[title] == Vote.Idle, "already voted");
        require(agendaMap[title].state == AgendaState.Voting, "already been closed");

        // 투표 처리
        if(agree) agendaMap[title].agree++;
        else agendaMap[title].disagree++;
        userMap[msg.sender].voteMap[title] = agree ? Vote.Agree : Vote.Disagree;

        // 투표 결과 처리
        uint _agree = agendaMap[title].agree;
        uint _disagree = agendaMap[title].disagree;
        if((_agree + _disagree) >= 10) {
            // (_agree / (_agree + _disagree)) * 100 >= 70
            agendaMap[title].state = (_agree >= 7 ? AgendaState.Accepted : AgendaState.Dismissed );
        }
    }

    function getVote(string memory title) public view returns (uint, uint) {
        Agenda memory target = agendaMap[title];
        return (target.agree, target.disagree);
    }

    function getAgenda(string memory title) public view returns (Agenda memory) {
        return agendaMap[title];
    }
}