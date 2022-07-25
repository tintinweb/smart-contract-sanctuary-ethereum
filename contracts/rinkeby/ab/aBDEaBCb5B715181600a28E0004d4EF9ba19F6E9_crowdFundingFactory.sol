/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract crowdFundingFactory{
    address [] private listOfCrowdFunding;

    function createCrowdFunding(uint minimumAmount) public {
        address newCrowdFunding = address(new crowdFunding(minimumAmount, msg.sender));
        listOfCrowdFunding.push(newCrowdFunding);
    }

    function getListOfCrowdFunding() public view returns (address [] memory){
        return listOfCrowdFunding;
    }
}

contract crowdFunding{

    struct Request{
        string description;
        uint value;
        address payable recipient;
        bool complete;
        uint voteCount;
        mapping(address => bool) voters;
    }
    address public owner;
    mapping(address => bool) contributor;
    uint public minimumAmount;
    mapping(uint => Request) public requests;
    uint requestIndex;
    uint totalContributor;

    modifier admin{
        require(msg.sender == owner);
        _;
    }

    constructor(uint amount, address creator) {
        owner = creator;
        minimumAmount = amount;

    }
    function contribute() public payable{
        require(msg.value > minimumAmount);
        contributor[msg.sender] = true;
        totalContributor++;

    }

    function makeRequest( string memory description, uint value, address payable recipient) public admin {
        Request storage newRequest = requests[requestIndex];
        newRequest.description = description;
        newRequest.value = value;
        newRequest.recipient = recipient;
        newRequest.complete = false;
        newRequest.voteCount = 0;
    }

    function approveRequest(uint index) public {
        
        require(contributor[msg.sender]);
        require(!requests[index].voters[msg.sender]);

        Request storage request = requests[index];
        request.voteCount++;
        request.voters[msg.sender] = true;

    }

    function finalizeRequest(uint index) public payable admin{
        require(!requests[index].complete);

        Request storage request = requests[index];

        require(request.voteCount > (totalContributor/2));
        
        request.recipient.transfer(request.value);
        request.complete = true;

    }

    function viewBalance() public view returns (uint){
        return address(this).balance;
    }
}