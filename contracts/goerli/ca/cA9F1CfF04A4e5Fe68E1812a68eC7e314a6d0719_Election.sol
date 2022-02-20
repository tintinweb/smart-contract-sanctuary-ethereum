/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

struct Issue {
    bool open;
    mapping(address => bool) voted;
    mapping(address => uint) ballots;
    uint[] scores;
}

contract Election {
    address _admin;
    mapping(uint => Issue) _issues;
    uint _issueId = 0;
    uint _min;
    uint _max;

    event StatusChange(uint issueId, bool open);
    event Vote(uint issueId, address voter, uint indexed option);

    constructor(uint min, uint max) {
        _admin = msg.sender;
        _max = max;
        _min = min;
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "unauthorized");
        _;
    }

    function open() public onlyAdmin {
        require(!_issues[_issueId].open, "election opening");

        _issueId++;
        _issues[_issueId].open = true;
        _issues[_issueId].scores = new uint[](_max+1);

        emit StatusChange(_issueId, true);
    }

    function close() public onlyAdmin {
        require(_issues[_issueId].open, "election closed");
        _issues[_issueId].open = false;

        emit StatusChange(_issueId, false);
    }

    function vote(uint option) public {
        require(_issues[_issueId].open, "election closed");
        require(!_issues[_issueId].voted[msg.sender], "you are voted");
        require(option >= _min && option <= _max, "incorrect option");

        _issues[_issueId].scores[option]++;
        _issues[_issueId].voted[msg.sender] = true;
        _issues[_issueId].ballots[msg.sender] = option;

        emit Vote(_issueId, msg.sender, option);
    }

    function getStatus() public view returns(bool electionStatus) {
        return _issues[_issueId].open;
    }

    function getBallot(uint issueId) public view returns(uint ballot) {
        require(issueId <= _issueId, "no have issue");
        require(_issues[issueId].voted[msg.sender], "not vote yet");
        return _issues[issueId].ballots[msg.sender];
    }

    function getScore(uint issueId) public view returns(uint[] memory scores) {
        require(issueId <= _issueId, "no have issue");
        return _issues[issueId].scores;
    }
}