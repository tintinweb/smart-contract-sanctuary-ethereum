/**
 *Submitted for verification at Etherscan.io on 2022-02-19
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

    event StatusChange(uint indexed issueId, bool open);
    event Vote(uint indexed _issueId, address voter, uint indexed option);

    constructor(uint min, uint max) {
        _admin = msg.sender;
        _min = min;
        _max = max;    
    }

    modifier onlyAdmin {
        require(msg.sender == _admin, "Unauthorized");
        _;
    }

    function open() public onlyAdmin {
        require(!_issues[_issueId].open, "Election is opening.");

        _issueId++;
        _issues[_issueId].open = true;
        _issues[_issueId].scores = new uint[](_max+1);
        emit StatusChange(_issueId, true);
    }

    function close() public onlyAdmin {
        require(_issues[_issueId].open, "Election already closed.");

        _issues[_issueId].open = false;
        emit StatusChange(_issueId, false);
    }

    function vote(uint option) public {
        require(_issues[_issueId].open, "Election closed.");
        require(!_issues[_issueId].voted[msg.sender], "You have already voted.");
        require(option >= _min && option <= _max, "Incorrect option.");

        _issues[_issueId].scores[option]++; // store scores of each candidate option.
        _issues[_issueId].voted[msg.sender] = true; // store value for check sender has been voted.
        _issues[_issueId].ballots[msg.sender] = option; // store vote history of sender. 
        emit Vote(_issueId, msg.sender, option);
    }

    function status() public view returns(bool open_) {
        return _issues[_issueId].open;
    }

    function ballot() public view returns(uint option) {
        require(_issues[_issueId].voted[msg.sender], "You are not vote.");
        return _issues[_issueId].ballots[msg.sender];
    }

    function score() public view returns(uint[] memory) {
        return _issues[_issueId].scores;
    }

}