/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
 contract CrowdFunding
 {
     address public owner;
     uint public target;
     uint public minimumContribution;
     uint public deadline;
     uint public raisedFund;
     mapping(address=>uint) public contributors;
     uint public noOfContributors;
     struct Request
     {
         string description;
         address payable recipient;
         uint value;
         bool completed;
         uint noOfVoters;
         mapping(address=>bool) voter;
     }
     mapping(uint=>Request) public request;
     uint public numRequest;
     constructor(uint _target, uint _deadline)
     {
         target = _target*1000000000000000000;
         deadline = block.timestamp+_deadline;
         owner = msg.sender;
         minimumContribution = 1 ether;
     }
     function DonateToAgency() payable public
     {
         require(block.timestamp<deadline, "Deadline has passed");
         require(msg.value>=minimumContribution, "Minimum contribution does not matched");
         if (contributors[msg.sender] == 0){
             noOfContributors++;
         }
         contributors[msg.sender] += msg.value;
         raisedFund += msg.value;
     }
     function checkAgencyBalance() public view returns(uint)
     {
         return address(this).balance;
     }
     function refund() public
     {
         require(contributors[msg.sender]>0, "You have No contribution in our agency");
         require(block.timestamp>=deadline, "You cannot request refund before deadline reached");
         require(raisedFund<target, "Raised fund meet the target demand, Your contribution cannot be refunded");
         address payable refundContributor = payable(msg.sender);
         refundContributor.transfer(contributors[msg.sender]);
         raisedFund -= contributors[msg.sender];
         contributors[msg.sender] = 0;
         noOfContributors--;
     }
     modifier onlyOwner()
     {
         require(msg.sender == owner, "Only owner is allowed for this action");
         _;
     }
     function createRequest(string memory _description, address payable _recipient, uint _value) public onlyOwner
     {
         require(raisedFund>=target, "Agency's balance is less than required targer, Request cannot be created");
         require((_value*1000000000000000000)<=address(this).balance, "Required amount for this Request must be less than or equal to our Agency's current funds");
         Request storage newRequest = request[numRequest];
         numRequest++;
         newRequest.description = _description;
         newRequest.recipient = _recipient;
         newRequest.value = _value*1000000000000000000;
     }
     modifier onlyContributers()
     {
          require(contributors[msg.sender]>0, "You are not eligle to vote, You must be contributor");
          _;
     }
     function vote(uint _requestNo) public onlyContributers
     {
         Request storage thisRequest = request[_requestNo];
         require(thisRequest.voter[msg.sender] == false, "You already voted for this");
         require(thisRequest.completed == false, "Cannot vote for this request, it has already been completed");
         thisRequest.voter[msg.sender] = true;
         thisRequest.noOfVoters++;
     }
     function transferFundsRequest(uint _requestNo) public onlyOwner
     {
         Request storage payRequest = request[_requestNo];
         require(payRequest.completed == false, "This Request has already been completed, cannot make payment again");
         require(payRequest.noOfVoters > noOfContributors/2, "Majority has not agreed on this payment");
         require(address(this).balance>=payRequest.value, "Agency's balance is less than required amount for this Request");
         payRequest.recipient.transfer(payRequest.value);
         payRequest.completed = true;
         raisedFund -= payRequest.value;
     }
 }