/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract CampaignFactory {

  Campaign[] public deployedCampaigns;

  function createCampaign(uint minimum) public {
    Campaign contractAddress = new Campaign(minimum, msg.sender);
    deployedCampaigns.push(contractAddress);
  }

  function getDeployedCampaigns() public view returns (Campaign[] memory) {
    return deployedCampaigns;
  }
}

contract Campaign {

  struct Request {
    string description;
    uint value;
    address payable recipient;
    bool complete;
    uint approversCount;
    mapping(address => bool) approvers;
  }
  mapping(uint => Request) public requests;
  address public manager;
  mapping(address => bool) public approvers;
  uint public minumumContribute;

  uint public approversCount;

  uint numRequests = 0;
  constructor(uint min, address creator) {
    manager = creator;
    minumumContribute = min;
  }

  function approveRequest(uint index) public {
    Request storage request = requests[index];
    require(approvers[msg.sender]);
    require(!request.approvers[msg.sender]);

    request.approversCount++;
    request.approvers[msg.sender] = true;

  }

  function finalizeRequest(uint index) public restricted payable {
    Request storage request = requests[index];

    require(!request.complete, 'Request is completed');
    require(request.approversCount > (approversCount / 2), 'Not enough aprrover count');
    request.recipient.transfer(request.value);
    request.complete = true;
    
  }

  function createRequest(string memory description, uint value, address payable recipient) public restricted {
    Request storage newRequest = requests[numRequests++];
    newRequest.description = description;
    newRequest.value = value;
    newRequest.recipient = recipient;
    newRequest.complete = false;
    newRequest.approversCount = 0;
  }

  function contribute() public payable {
    require(msg.value > minumumContribute);
    approvers[msg.sender] = true;
    approversCount++;
  }

  // function random() private view returns(uint) {
  //   return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
  // }

  // function pickWiner() public payable restricted {
  //   uint index = random() % players.length;
  //   payable(players[index]).transfer(address(this).balance);
  //   players = new address[](0);
  // }

  modifier restricted() {
    require(msg.sender == manager);
    _;
  }
}