//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FundRaiser{

mapping(address=>uint256) public addressToAmountContributed;

uint256 numOfContributors;

uint public minimumContribution;

address public admin;

// uint startTime;

// uint256 public deadline;

uint256 public goal;

uint256 public totalRaisedAmount;

uint256 public currentBalance;

mapping(uint256 => Request) public requests;

uint numOfRequests;

event CreateRequestEvent(string _description, address _recipient, uint _amount);

struct Request{

    string description;
    uint256 amount;
    address payable recipient;
    bool completed;
    uint256 numOfVotes;
    mapping (address=> bool) voteCount;
}

modifier onlyAdmin(){
    require(msg.sender==admin);
    _;
}

constructor(uint256 _goal) {
    admin =msg.sender;
    goal = _goal;
    // startTime = block.timestamp;
    // deadline = startTime + 3600;
    minimumContribution = 10000000000000000;

}


function contribution() payable public{

    require(msg.value>= minimumContribution, "You need to meet the minimum contribution");
    // require(block.timestamp>startTime && block.timestamp<deadline, "Sorry the fund raising is over");
    addressToAmountContributed[msg.sender]+= msg.value ;
    totalRaisedAmount += msg.value ;
    currentBalance += msg.value;
    numOfContributors++;

} 
//   receive() payable external{
//         contribution(uint256 amount);
//     }


function getBalance( ) public view returns(uint256){
    return currentBalance;
}

function getNoOfContributors() public view returns(uint256){
    return numOfContributors;
 
}


// function remainingTime( ) public view returns (uint256){
//     return deadline - block.timestamp;
// }

function refund( ) public {
    // require(block.timestamp > deadline, "the fund raiser is still open, not possible for refund");
    require(addressToAmountContributed[msg.sender]>0, "You need to be a contributor for refund");
    uint256 amountToRefund = addressToAmountContributed[msg.sender];
    require(totalRaisedAmount<goal, "Refund not possible as goal has been reached");
    require(amountToRefund<=currentBalance,"Insufficent eth for refund");
    payable(msg.sender).transfer(amountToRefund);
    addressToAmountContributed[msg.sender] = 0;
    currentBalance-=amountToRefund;

}


function createRequest(string memory _description, uint256 _amount, address payable _recipient )onlyAdmin public { 
    Request storage newRequest = requests[numOfRequests];
    numOfRequests++;

    newRequest.description = _description;
    newRequest.amount = _amount;
    newRequest.recipient = _recipient;
    newRequest.completed = false;
    newRequest.numOfVotes = 0;
    emit  CreateRequestEvent(_description,  _recipient, _amount);

}


function voteRequest(uint256 indexOfRequest )public{
    require(totalRaisedAmount>=goal, "Voting not possible as goal has not been reached");
    require (addressToAmountContributed[msg.sender] > 0, "Sorry, voting rights for contributors only");
    require (requests[indexOfRequest].completed == false, "Voting closed, This request has been completed");
    require(requests[indexOfRequest].voteCount[msg.sender] == false, "You have voted for this request");
    requests[indexOfRequest].voteCount[msg.sender] = true;
    requests[indexOfRequest].numOfVotes++;


}

function makePayment(uint indexOfRequest)onlyAdmin payable public{
    require (requests[indexOfRequest].completed == false , "Payment has been made, no further action needed");
    require (totalRaisedAmount >= requests[indexOfRequest].amount, "insufficent eth");
    require (requests[indexOfRequest].numOfVotes > numOfContributors/2 , "Not enough votes to approve payment");
    requests[indexOfRequest].completed = true;
    payable(requests[indexOfRequest].recipient).transfer(requests[indexOfRequest].amount);
    totalRaisedAmount -= requests[indexOfRequest].amount;


}

}