/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowadFunding {
    address immutable owner;

    struct Campagin{
        address payable receiver;
        uint numCampagins;
        uint fundGoal;
        uint totalAmount;
    }

    struct Funder{
        address addr;
        uint amount;
    }

    uint public numCampagins;
    mapping (uint => Campagin) public campagins;
    mapping (uint => Funder[]) public funders;

    Campagin[] public campaginArray;
    mapping (uint => mapping( address => bool)) public isOver;

    event CampaginLog(uint campaginId, address receiver, uint goal);
    event BidLog(uint campaginId, address bider, uint value);

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function newCampagin(address payable receiver,  uint goal) external isOwner returns (uint campaginId){
        campaginId = numCampagins++;
        Campagin storage c = campagins[campaginId];
        c.receiver = receiver;
        c.fundGoal = goal;

        campaginArray.push(c);
        emit CampaginLog(campaginId, receiver, goal);
    }


    function bid(uint campaginId) payable external {
        Campagin storage c = campagins[campaginId];
        c.totalAmount += msg.value;
        c.numCampagins += 1;

        funders[campaginId].push(Funder({
            addr: msg.sender,
            amount: msg.value
        }));

        // isOver[campaginId][msg.sender] = true;

        emit BidLog(campaginId, msg.sender, msg.value);
    }

}