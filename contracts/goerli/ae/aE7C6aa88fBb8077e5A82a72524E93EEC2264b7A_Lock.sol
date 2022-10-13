// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    mapping(address => uint) public contributors;

    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;  //total amount get
    uint public noOfContributors ; //check total no. of Contributors

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    mapping(uint=>Request) public requests;
    uint public numRequest;

    modifier onlyManager() {
        require(manager == msg.sender,"Only Manager can do this Action!");
        _;
    }

    // constructor(uint _target, uint _deadline) {
    constructor() {
        target = 1000;
        deadline = block.timestamp + 3600; // 3600 add in timestamp
        minimumContribution = 100 wei;
        manager = msg.sender;
    }

    function sendEth() public payable {
        require(deadline > block.timestamp, "Deadline has end!");
        require(msg.value >= minimumContribution, "Minimum Contribution in not met!");
        if(contributors[msg.sender] == 0){
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    } 

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public {
        require(deadline > block.timestamp && target > raisedAmount, "You are not eligible!");
        require(contributors[msg.sender]>0,"You are not contributed!");

        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequest];
        numRequest++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "You must be contributor");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "Already Vote");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager {
        require(raisedAmount >= target, "Not enough amount to target");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false,"This request already done!");
        require(raisedAmount >= thisRequest.value, "Not enough amount");

        require(thisRequest.noOfVoters > (noOfContributors/2), "Majority not Aggree!");

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true; 
    }
}