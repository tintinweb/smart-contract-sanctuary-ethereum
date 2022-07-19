/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Issue { // Issue คือ การเลือกตั้งครั้งนั้น
    bool open; // default ของ boolean เป็น false (closed)
    mapping(address => bool) voted; // เปิดคูหามา จะมี bool เป็น false หรือหมายถึง unvoted และถ้า voted จะมี bool เป็น true และนั่นทำให้ voted ซ้ำไม่ได้แล้ว
    mapping(address => uint) ballots;
    uint[] scores;
}

contract Election {
    address _admin;
    mapping(uint => Issue) _issues;
    uint _issuesId; // การเลือกตั้งครั้งปัจจุบัน
    uint _min;
    uint _max;

    event StatusChange(uint indexed issueId, bool open);
    event Vote(uint indexed issueId, address voter, uint indexed option);

    constructor(uint min, uint max) {
        _admin = msg.sender; // _admin คือ คนสั่งเปิดปิดคูหา
        _min = min;
        _max = max;
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "unauthorized");
        _; 
    }

    function open() public onlyAdmin {
        require(!_issues[_issuesId].open, "election is opening");

        _issuesId++;
        _issues[_issuesId].open = true;
        _issues[_issuesId].scores = new uint[](_max+1);

        emit StatusChange(_issuesId, true);
    }

    function closed() public onlyAdmin {
        require(_issues[_issuesId].open, "election is closing");

        _issues[_issuesId].open = false;

        emit StatusChange(_issuesId, false);
    }

    function vote(uint option) public {
        require(_issues[_issuesId].open, "election is closing");
        require(!_issues[_issuesId].voted[msg.sender], "you've already voted");
        require(option >= _min && option <= _max, "incorrect option");

        _issues[_issuesId].scores[option]++;
        _issues[_issuesId].voted[msg.sender] = true;
        _issues[_issuesId].ballots[msg.sender] = option;

        emit Vote(_issuesId, msg.sender, option);
    }

    function status() public view returns(bool open_) {
        return _issues[_issuesId].open;
    }

    function ballot() public view returns(uint option) {
        require(_issues[_issuesId].voted[msg.sender], "you haven't voted yet");
        return _issues[_issuesId].ballots[msg.sender];
    }

    function checkScores() public view returns(uint[] memory) {
        return _issues[_issuesId].scores;
    }
}