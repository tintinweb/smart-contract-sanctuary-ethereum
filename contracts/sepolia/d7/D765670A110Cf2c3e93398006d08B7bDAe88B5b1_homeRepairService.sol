/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract homeRepairService {
    struct Request {
        address user;
        string description;
        bool accepted;
        bool confirmed;
        bool executed;
        uint confirmedTimestamp;
        uint tax;
        uint payment;
        address[] verifiers;
        uint verifications;
    }
    mapping (uint => Request) private requests;
    // address public admin;
    // address payable public repairer;
    address public admin = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address payable public repairer = payable(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
    uint public currentIndex = 1;

    modifier isAdmin{
        require(msg.sender==admin,"Not admin");
        _;
    }

    modifier isExecuted(uint req_id){
        require(!requests[req_id].executed,"Already executed");
        _;
    }

    function addRequest(string memory description) public returns(uint){
        requests[currentIndex] = Request({
            user: msg.sender,
            description: description,
            accepted: false,
            confirmed: false,
            executed: false,
            confirmedTimestamp: 0,
            tax: 0,
            payment: 0,
            verifiers: new address[](0),
            verifications: 0
        });
        //The id is returned so the user knows it and this way there will be no danger for duplication.
        currentIndex++;
        return currentIndex - 1;
    }

    function acceptRequest(uint req_id, uint tax) public isAdmin {
        require(!requests[req_id].accepted,"Already accepted");
        requests[req_id].accepted = true;
        requests[req_id].tax = tax * 1 ether;
    }

    function addPayment(uint req_id) public payable {
        require(msg.sender==requests[req_id].user,"Wrong request");
        require(msg.value==requests[req_id].tax,"Wrong amount of ether");
        require(requests[req_id].payment==0,"Already paid");
        requests[req_id].payment += msg.value;
    }

    function confirmRequest(uint req_id) public isAdmin {
        require(requests[req_id].payment!=0,"Not payed yet");
        requests[req_id].confirmed = true;
        requests[req_id].confirmedTimestamp = block.timestamp;
    }

    function verifyRequest(uint req_id) public payable isExecuted(req_id) {
        require(requests[req_id].confirmed == true,"Job not done");    
        for (uint i = 0; i < requests[req_id].verifiers.length; i++){
            require(requests[req_id].verifiers[i]!=msg.sender,"Already verified by you");
        } 

        requests[req_id].verifiers.push(msg.sender);
        requests[req_id].verifications++;
        
        if (requests[req_id].verifications >= 2) {
            repairer.transfer(requests[req_id].payment);
            requests[req_id].payment = 0;
            requests[req_id].executed = true;
        }
    }

    function moneyBack(uint req_id) public payable isExecuted(req_id){
        require(msg.sender==requests[req_id].user,"Invalid user");
        require(block.timestamp-requests[req_id].confirmedTimestamp>=30 days,"Not enough time passed");
        payable(msg.sender).transfer(requests[req_id].payment);
        requests[req_id].payment = 0;
    }

    function showRequests(uint req_id) public view returns(Request memory){
        return(requests[req_id]);
    }

}