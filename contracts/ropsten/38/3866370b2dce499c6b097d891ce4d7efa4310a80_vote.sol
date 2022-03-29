/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

struct Issue{
    bool open;
    mapping(address=>bool) voted;
    mapping(address=>uint) ballots;
    uint[] scores;
}

contract vote{

    address _admin;
    uint _max;
    uint _min;

    mapping(uint=>Issue) _issues;
    uint _issueID;


    event statuschange(uint indexed issueid,bool open);
    event votewhat(uint indexed _issueid,address voter,uint indexed Number);

    constructor(uint min,uint max){
        _admin= msg.sender;
        _min=min;
        _max=max;
    }

    modifier onlyadmin{
        require(msg.sender==_admin);
        _;
    }

    function Openvote() public onlyadmin{
        require(!_issues[_issueID].open,"Opened!!");

        _issueID++;
        _issues[_issueID].open=true;
        _issues[_issueID].scores=new uint[](_max);
        emit statuschange(_issueID,true);
    }

    function Close() public onlyadmin{
        require(_issues[_issueID].open);
        _issues[_issueID].open=false;
        emit statuschange(_issueID,false);
    }

    function Vote(uint number) public {
        require(_issues[_issueID].open);
        require(!_issues[_issueID].voted[msg.sender]);
        require(number>=_min&&number<=_max);
        _issues[_issueID].scores[number-1]++;
        _issues[_issueID].voted[msg.sender]=true;
        _issues[_issueID].ballots[msg.sender]=number;
        emit votewhat(_issueID,msg.sender,number);
    }

    function status() public view returns(bool){
        return _issues[_issueID].open;
    }

    function ballot() public view returns(uint){
        require(_issues[_issueID].voted[msg.sender]);
        return _issues[_issueID].ballots[msg.sender];
    }

    function score() public view returns(uint[] memory){
            return _issues[_issueID].scores;
    }
}