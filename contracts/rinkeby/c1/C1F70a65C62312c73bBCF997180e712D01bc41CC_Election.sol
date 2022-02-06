/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

//SPDX-License-Identifier:MIT;

pragma solidity ^0.8.0 ; 

struct Issue {
    bool open; 
    mapping(address  => bool)  voted ; 
    mapping(address => uint) ballot;
    uint[] score;
}


contract Election {

    address _admin ; 
    mapping(uint => Issue) _issues;
    uint _issueId;
    uint _min;
    uint _max;

    event StatusChange(uint indexed issueId , bool open);
    event Vote(uint issueId , address voter , uint indexed option);

    constructor(uint min , uint max){
        _admin = msg.sender ; 
        _min = min;
        _max = max;

    }
    modifier onlyAdmin{
        require(msg.sender == _admin , "Unauthorize");
        _;
    }

    function open() public onlyAdmin{
        require(!_issues[_issueId].open , "aleready open");

        _issueId++;
        _issues[_issueId].open = true;
        _issues[_issueId].score = new uint[](_max+1);
        emit StatusChange(_issueId ,true);
    }

    function close() public onlyAdmin{
        require(_issues[_issueId].open , "election closeed");
        _issues[_issueId].open = false;
        emit StatusChange(_issueId ,false);
    }

    function vote(uint option) public {
        require(_issues[_issueId].open , "election closed");
        require(!_issues[_issueId].voted[msg.sender] , "you're voted");

        _issues[_issueId].score[option]++ ; 
        _issues[_issueId].voted[msg.sender] = true;
        _issues[_issueId].ballot[msg.sender] = option;

        emit Vote(_issueId , msg.sender , option);

    }
    function  checkStatus() public view returns(bool status){
        return _issues[_issueId].open ;
    } 
    function ballot() public view returns(uint option){
        require(_issues[_issueId].voted[msg.sender] , "You don't have voted");
        return _issues[_issueId].ballot[msg.sender];
    }

    function scores() public view returns(uint[] memory){
        return _issues[_issueId].score;
    }
    

}