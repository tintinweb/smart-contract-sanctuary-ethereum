/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors; 
    address public manager; 
    uint public minimumContribution;
    uint public endTime;
    uint public goal;
    uint public receivedAmount;
    uint public totalContributors;
    
    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint public numRequests;
    constructor(uint _goal,uint _endTime){
        goal=_goal;
        endTime=block.timestamp+_endTime; 
        minimumContribution=100 wei;
        manager=msg.sender;
    }
    
    function sendEth() public payable{
        require(block.timestamp < endTime,"The time is ended");
        require(msg.value >=minimumContribution,"The minimum contribution is not done till yet");
        
        if(contributors[msg.sender]==0){
            totalContributors++;
        }
        contributors[msg.sender]+=msg.value;
        receivedAmount+=msg.value;
    }
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    function refund() public{
        require(block.timestamp>endTime && receivedAmount<goal,"You are not eligible for refund");
        require(contributors[msg.sender]>0);
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
        
    }
    modifier onlyManger(){
        require(msg.sender==manager,"Only manager can calll this function");
        _;
    }
    function createRequests(string memory _description,address payable _recipient,uint _value) public onlyManger{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender]>0,"You must be contributor for doing this");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"Voting already done by you");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }
    function makePayment(uint _requestNo) public onlyManger{
        require(receivedAmount>=goal);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters > totalContributors/2,"Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}