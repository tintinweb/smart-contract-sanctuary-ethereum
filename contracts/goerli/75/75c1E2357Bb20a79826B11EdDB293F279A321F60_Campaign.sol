/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

pragma solidity >=0.7.0 <0.9.0;

contract Campaign{
    struct Request{
        string  description;
        uint    value;
        address recipient;
        bool    completed;
        uint    approvalCount;
        mapping(address => bool) approvals;

    }
    Request[]   public requests;     
    address     public owner;
    mapping(address => bool) public approvers;
    uint        public minPrice;

    modifier isOwner(){
        require(msg.sender == owner,"You are not owner");
        _;
    }

    constructor(uint price){
        owner = msg.sender;
        minPrice =  price;
    }

    function contribute() public payable{
        require(msg.value >=  minPrice,  "Not enough minumum price");
        approvers[msg.sender] = true;
    }

    function createRequest(string memory description, uint value, address recipient) public  isOwner {
         Request storage newRequest = requests.push();
         newRequest.description = description;
         newRequest.value = value;
         newRequest.recipient = recipient;
         newRequest.completed = false;
         newRequest.approvalCount = 0;
    }

    function approveRequest(uint index) public{
        Request storage request = requests[index];
        require(approvers[msg.sender],"You are not a aproovers");
        require(!requests[index].approvals[msg.sender],"Already, you used a vote");

        request.approvals[msg.sender]=true;
        request.approvalCount++;

    }


}