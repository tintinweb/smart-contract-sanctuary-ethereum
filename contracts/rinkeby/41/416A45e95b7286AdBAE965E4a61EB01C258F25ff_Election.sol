/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Issue {
    bool open;
    mapping(address => bool) voted;
    mapping(address => uint) ballots;
    uint[] scores;
}

contract Election {
    address _admin;
    mapping(uint => Issue) _issues;
    uint _issueId;
    uint _min;
    uint _max;

    event StatusChange(uint indexed IssueId, bool open);
    event Vote(uint indexed IssueID, address indexed voter, uint indexed selected);

    constructor(uint min, uint max) {
        _admin = msg.sender;
        _issueId = 0;
        _min = min;
        _max = max;
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "unautorized");
        _;
    }

    function open() public onlyAdmin {
        require(!_issues[_issueId].open, "Election opened");
        _issueId += 1;
        _issues[_issueId].open = true;
        _issues[_issueId].scores = new uint[](_max + 1);

        emit StatusChange(_issueId, true);
    }

    function close() public onlyAdmin {
        require(_issues[_issueId].open, "Election closed");
        _issues[_issueId].open = false;

        emit StatusChange(_issueId, false);
    }

    function vote(uint selected) public {
        require(_issues[_issueId].open, "Election closed");
        require(!_issues[_issueId].voted[msg.sender], "You are voted");
        require(selected >= _min && selected <= _max, "incorrect vote");
        _issues[_issueId].scores[selected] += 1;
        _issues[_issueId].voted[msg.sender] = true;
        _issues[_issueId].ballots[msg.sender] = selected;

        emit Vote(_issueId, msg.sender, selected);
    }

    function status() public view returns(bool status_) {
        return _issues[_issueId].open;
    }

    function ballot() public view returns(uint selected_) {
        require(_issues[_issueId].voted[msg.sender], "You are not voted");
        return _issues[_issueId].ballots[msg.sender];
    }

    function scores() public view returns(uint[] memory) {
        return _issues[_issueId].scores;
    }
}