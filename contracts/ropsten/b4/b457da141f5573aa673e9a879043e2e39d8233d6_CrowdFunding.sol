/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 < 0.9.0;

contract CrowdFunding {
    mapping(address => uint) public contributors;

    address public manager;

    uint public minContribution;

    uint public deadLine;

    uint public target;

    uint public raisedAmount;

    uint public noOfContributors;

    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;

    uint public numRequests;

    constructor(uint _deadLine, uint _target) {
        target = _target;
        deadLine = block.timestamp + _deadLine;

        manager = msg.sender;

        minContribution = 100 wei;
    }

    function sendMoney() public payable {
        require(block.timestamp < deadLine, "DeadLine Passed");
        require(msg.value >= minContribution, "Must be eqaul or greater from Minimum Contribution");

        if(contributors[msg.sender] == 0){
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;

        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns(uint) {

        return address(this).balance;
    }

    function refund() public {
        require(contributors[msg.sender] > 0, "Not a Valid Contributor");
        require(block.timestamp > deadLine && raisedAmount < target, "You are not eligible for refund");

        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    function createRequests(string memory _desc, address payable _recipient, uint _value) public onlyManager {
        Request storage newRequest = requests[numRequests];
        numRequests++;

        newRequest.description = _desc;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "You must be a contributor");

        Request storage thisRequest = requests[_requestNo];

        require(thisRequest.voters[msg.sender] == false, "You have already voted");

        thisRequest.voters[msg.sender] = true;

        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager {
        require(raisedAmount >= target);

        Request storage thisRequest = requests[_requestNo];

        require(thisRequest.completed == false, "The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2, "Majority does not support");

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}