// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract CrowdFunding
{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;


    struct Request
    {
        string description;
        address payable recipent;
        uint value;
        bool completed;
        uint noOfVoter;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint public numRequests;

    constructor()
    {
        target = 1000;
        deadline = 36000;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    function sendETH() public payable
    {
        require(block.timestamp<deadline,"Deadline has Passed");
        require(msg.value >= minimumContribution,"Minimum Contribution is not met");
        if(contributors[msg.sender]==0)
        {
            noOfContributors ++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount +=msg.value;

    }

    function GetBalance() public view returns(uint)
    {
        return address(this).balance;
    }

    function Refund() public 
    {
        require(block.timestamp>deadline && raisedAmount<target,"You are not Eligible for refund");
        require(contributors[msg.sender]>0,"You didn't contribute");
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;

    }

    modifier OnlyManager()
    {
        require(msg.sender==manager, "Only manager can call this.");
        _;
    }

    function CreateRequest(string memory _description, address payable _recipent, uint _value) public OnlyManager
    {
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipent = _recipent;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoter = 0;
    }
    function voterRequest(uint _requestNo) public 
    {
        require(contributors[msg.sender]>0,"you must be contributors");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"you have already Voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoter++;
    }
    function makePayment(uint _requestNo) public OnlyManager
    {
        require(raisedAmount>=target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false,"The request has been Completed ");
        require(thisRequest.noOfVoter>noOfContributors/2,"Majority does not support");
        thisRequest.recipent.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}