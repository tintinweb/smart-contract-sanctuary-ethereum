// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract charrity{
    address internal manager;
    uint public minimumcontribution;
    uint public noofcontributor;
    

    struct person{
        address payable recipient;
        string detail;
        uint amount_needed;
        bool completed;
        mapping(address=>bool) voters;
        uint noofvoter;
    }
    address[] data;
    mapping(address=>person) public pay;
    mapping(uint=>person) public request;
    
    mapping(address=>uint) contributor;
    uint public numrequests;

    constructor(){
        manager=msg.sender;
        minimumcontribution =1 ether;
    }

    function info(string memory _detail,uint _amount,address payable _name) public {
        person storage newperson=request[numrequests];
        numrequests++;
        newperson.recipient=_name;
        newperson.detail=_detail;
        newperson.amount_needed=_amount;
    }

    function sendmoney(uint _no) public payable{
        require(msg.value >= minimumcontribution,"Amount Not Matching!");
        data.push(payable(msg.sender));
        if(contributor[msg.sender]==0){
            noofcontributor++;
        }
        contributor[msg.sender]+=msg.value;
    }

    function totalfund() public view returns(uint){
        return address(this).balance;
    }
    
    function refund() public {
        require(contributor[msg.sender]>0);
        require(noofcontributor<3);
        address payable user=payable(msg.sender);
        user.transfer(contributor[msg.sender]);
        contributor[msg.sender]=0;
    }

    function voting(uint _no) public{
        
        require(noofcontributor>3,"Contributor Is Not Enough To Start Voting");
        person storage newperson=request[_no];
        require(newperson.voters[msg.sender]==false,"Not Eligible To Vote");
        newperson.voters[msg.sender]=true;
        newperson.noofvoter++;
    } 

    function fund_transfer(uint _no) public payable{
        require(msg.sender==manager,"You Are Not Manger!");
        person storage newperson=request[_no];
        require(newperson.noofvoter>noofcontributor/2,"Majority Not Supported!");
        require(newperson.completed==false,"Fund Transfer Already");
        newperson.recipient.transfer(newperson.amount_needed);
        newperson.completed=true;
    }
}