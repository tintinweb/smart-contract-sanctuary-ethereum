/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Issue {
    bool open;
    mapping(address => bool) voted ;
    mapping(address => uint) ballot;
    uint[] scores;
}

contract Election{
    address _admin;
    mapping(uint => Issue) _issues;
    uint _issueId;
    uint _min;
    uint _max;

    event StatusChange(uint indexed _issueId, bool open);
    event Vote(uint indexed _issueId, address voter, uint indexed option);
    

    constructor(uint min,uint max){
        _admin = msg.sender;
        _min = min;
        _max = max;
    }

    modifier onlyAdmin {
        require(msg.sender == _admin,"unauthorized");
        _;
    }

    function open() public onlyAdmin {
        require(!_issues[_issueId].open,"election opening");
        _issueId++;
        _issues[_issueId].open = true;
        _issues[_issueId].scores = new uint[](_max+1);
        emit StatusChange(_issueId,true);
    }

    function close() public onlyAdmin {
        require(_issues[_issueId].open,"election closed");
        _issues[_issueId].open = false;
        emit StatusChange(_issueId,false);
    }

    function vote(uint option) public {
        require(_issues[_issueId].open,"election closed");
        require(!_issues[_issueId].voted[msg.sender],"yor are voted");
        require(option >= _min && option <= _max,"incorrect option");
        _issues[_issueId].scores[option]++;
        _issues[_issueId].voted[msg.sender] = true;
        _issues[_issueId].ballot[msg.sender] = option;
        emit Vote(_issueId,msg.sender,option);
    }

    function status() public view returns(bool open_){
        return _issues[_issueId].open;
    }

    function ballto()public view returns(uint option){
        require(_issues[_issueId].voted[msg.sender],"you are not vote");
        return _issues[_issueId].ballot[msg.sender];
    }

    function scores() public view returns(uint[] memory){
        return _issues[_issueId].scores;
    }


}