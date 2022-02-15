/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract CampaignFactory{
    address[] public deployedCampaigns;

    function createCampaign(uint _minimumContribution) public{
       address newCampaign = address(new Campaign(msg.sender, _minimumContribution));
       deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns(address[] memory){
        return deployedCampaigns;
    }
}

contract Campaign {

    struct Request {
        string description;
        uint value;
        address recipient;
        bool complite;
        uint approvalCount;
    }


    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
    uint public approversCount;
    Request[] public requests;
    mapping(uint => mapping(address => bool)) approvalsOfRequects;

    constructor(address _manager, uint _minimumContribution){
        manager = _manager;
        minimumContribution = _minimumContribution;
    }

    modifier restricted(){
        require(msg.sender == manager, "You are not manager!");
        _;
    }

    modifier requestExist(uint _indexOfRequest){
        require(_indexOfRequest < requests.length, "Such request wasn't created yet!");
        _;
    }

    modifier requestComplite(uint _indexOfRequest){
        require(!requests[_indexOfRequest].complite, "Requset already complite!");
        _;
    }

    function contribute() public payable{
        require(msg.value >= minimumContribution, "Too little money!");
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(string memory _desk, uint _value, address _recipient) public restricted{
        Request memory request = Request({
            description: _desk,
            value: _value,
            recipient: _recipient,
            complite: false,
            approvalCount: 0
        });
        requests.push(request);
    }

    function approveRequest(uint _indexOfRequest) public requestExist(_indexOfRequest) requestComplite(_indexOfRequest){
        require(approvers[msg.sender], "You don't donate this compaign!");
        require(!approvalsOfRequects[_indexOfRequest][msg.sender], "You already vote for this request!");
        approvalsOfRequects[_indexOfRequest][msg.sender] = true;
        requests[_indexOfRequest].approvalCount++;
    }

    function finalizeRequest(uint _indexOfRequest) public restricted requestExist(_indexOfRequest) requestComplite(_indexOfRequest){
        Request storage request = requests[_indexOfRequest]; 
        require(request.approvalCount > approversCount / 2, "Request wasn't approved in voting!");
        payable(request.recipient).transfer(request.value);
        request.complite = true;
    }
    
}