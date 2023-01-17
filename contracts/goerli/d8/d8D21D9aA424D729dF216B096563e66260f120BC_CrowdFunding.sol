/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CrowdFunding {

    mapping(address => Users) funders;
    uint public goal;
    uint public minAmount;
    uint public noOfFunders;
    uint public fundRaised;
    uint public timePeriod; //TimeStamp

    // Fetch Owner Data
    struct OwnerData{
        address OwnerAdd;
        bool requestCreated;
    }
    OwnerData public getOwnerData;

    // Validation for eliminating multiple votes from same user
    struct Users{
        uint noOfFunder;
        bool isVoted;
    }

    //Create Request for Using Fund Object 
    struct Request{
        string description;
        uint amount;
        address payable receiver;
        uint noOfVotes;
        mapping(address=>bool) votes;
        bool completed;
        bool reqCreated;
    }

    mapping (uint => Request) public AllRequest;
    uint public numReq;

    constructor(uint _goal, uint _timePeriod){
        goal = _goal;
        timePeriod = block.timestamp + _timePeriod;
        getOwnerData.OwnerAdd = msg.sender;
        getOwnerData.requestCreated = false;
        minAmount = 1000 wei;
    }

    //Validation Modifires
    modifier isOwner{
        require(msg.sender == getOwnerData.OwnerAdd, "You are not owner!");
        _;
    }

    //Adding Fund 
    function contribution() public payable{
        require(block.timestamp<timePeriod, "Funding time is Over.");
        require(msg.value >= minAmount, "Minimum amount criteria not matched.");

        if (funders[msg.sender].noOfFunder == 0){
            noOfFunders++;
        }

        funders[msg.sender].noOfFunder += msg.value;
        funders[msg.sender].isVoted = false;
        fundRaised += msg.value;
    }

    receive() payable external{
        contribution();
    }

    //Get Refund
    function getRefund() public{
        require(block.timestamp > timePeriod, "Funding time not over.");
        require(fundRaised < goal, "Funding was successful");
        require(funders[msg.sender].noOfFunder > 0, "Not a funder");

        payable(msg.sender).transfer(funders[msg.sender].noOfFunder);
        fundRaised -= funders[msg.sender].noOfFunder;
        funders[msg.sender].noOfFunder = 0;
    }
  
    //Request to use gained fund
    function createRequest(string memory _description, uint _amount, address payable _receiver) public isOwner{
       
        Request storage newRequest = AllRequest[numReq];
        
        numReq++;
        newRequest.reqCreated = true;
        newRequest.description = _description;
        newRequest.amount = _amount;
        newRequest.receiver = _receiver;
        newRequest.noOfVotes = 0;
        newRequest.completed = false;

        getOwnerData.requestCreated = true;
    }

    //Voting Validations
    function votingRequest(uint reqNum) public{

        require(getOwnerData.requestCreated == true, "Request is not created yet");
        require(funders[msg.sender].noOfFunder > 0, "You are not a funder.");//Will check that user has given fund or not 
        require(funders[msg.sender].isVoted == false, "You have already voted");

        Request storage thisReq = AllRequest[reqNum];
        funders[msg.sender].isVoted = true;
        thisReq.votes[msg.sender] = true;
        thisReq.noOfVotes++;
    }

    //Goal not achived -> revert money to funders
    //MAKE PAYMENT
    function makePayment(uint reqNum) public isOwner{
        Request storage thisReq = AllRequest[reqNum];
        require(thisReq.completed == false, "Already completed!");
        require(thisReq.noOfVotes >= noOfFunders/2, "Voting is not in favour!");

        thisReq.receiver.transfer(thisReq.amount);
        thisReq.completed = true;
        
        delete funders[msg.sender].isVoted;

    }

}