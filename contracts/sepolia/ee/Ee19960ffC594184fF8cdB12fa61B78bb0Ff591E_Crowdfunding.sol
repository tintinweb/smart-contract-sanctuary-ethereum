// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Crowdfunding {

struct Request{
    string description;
    address payable recipient; //pay garna 
    uint value;
    bool completed;
    uint noOfVoters;
    mapping(address=>bool) voters; //voters pugyo ya pugena
}

mapping (address=>uint) public contributors;
mapping(uint=>Request) public requests;
uint public numRequests;
address public manager;
uint public minimunContributions; //min contribution amt
uint public deadline;
uint public target;
uint public raisedAmount;
uint public noOfContributors; //kati jana
//this is for campaing creation descrription ,name not given yet can be added later
constructor(uint _target,uint _deadline){
    target = _target;
    deadline = block.timestamp+_deadline;
    minimunContributions= 10 wei;
    manager = msg.sender; // address of the person who does transaction


}
modifier onlyManager(){
    require(msg.sender==manager,"you are not manager");
    _;
    
}
function createRequests(string calldata  _description,address payable  _recipient,uint _value) public onlyManager{
    Request storage newRequest = requests[numRequests];
    numRequests++;
    newRequest.description=_description;
    newRequest.recipient=_recipient;
    newRequest.value=_value;
    newRequest.completed=false;
    newRequest.noOfVoters=0;   
}
function contribution() public payable{
    require(block.timestamp<deadline,"Deadline has passed");
    require(msg.value>=minimunContributions,"Minimum contribution requied is 10 wei");
    if(contributors[msg.sender]==0){
        noOfContributors++;
    }
    contributors[msg.sender]+=msg.value;
    raisedAmount+=msg.value;
}

function getContractBalance() public view returns(uint){
return address(this).balance;
}

function refund() public {
    require(block.timestamp>deadline && raisedAmount<target,"You are not eligible for a refund");
    require(contributors[msg.sender]>0,"you are not a contributor");
    payable(msg.sender).transfer(contributors[msg.sender]);
    contributors[msg.sender]=0;
}

function voteRequest(uint _requestNo) public {
    require(contributors[msg.sender]>0,"you are not a contributor");
    Request storage thisRequest= requests[_requestNo];
    require(thisRequest.voters[msg.sender]==false,"you have already voted");
    thisRequest.voters[msg.sender]= true;
    thisRequest.noOfVoters++;
}

function makePayment(uint _requestNo) public onlyManager{   //manager who is campagin creater directs this money to recipient
    require(raisedAmount>=target,"Target is not reached");
    Request storage thisRequest= requests[_requestNo];
    require(thisRequest.completed==false,"This request has been completed");
    require(thisRequest.noOfVoters>noOfContributors/2,"Majority does not support the request");
    thisRequest.recipient.transfer(thisRequest.value);
    thisRequest.completed=true;
}}