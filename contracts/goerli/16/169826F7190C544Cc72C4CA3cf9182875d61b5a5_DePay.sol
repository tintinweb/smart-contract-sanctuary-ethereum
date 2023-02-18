/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract DePay{
    
    struct Request {
        string description;
        uint value;
        bool complete;
        address from;
    }
    
    mapping(address=>Request[]) public requests;
    mapping(address => uint) public balance;
   mapping(address=> mapping(address => uint)) public given;
   mapping(address=> mapping(address => uint)) public borrowed;
 

    function pay(address payable _to,uint amount) public payable {
        require(amount*10**18<balance[msg.sender]);
        require(amount*10**18>0);
        _to.transfer(amount*10**18);
        balance[_to]+=amount*10**18;
        balance[msg.sender]-=amount*10**18;
    }

    function addFund() public payable {
        require(msg.value>0);
        balance[msg.sender]+=msg.value;
    }

    function withdrawFund(uint amount) public payable {
       require(amount*10**18<balance[msg.sender]);
       require(amount*10**18>0);
      (payable (msg.sender)).transfer(amount*10**18);
        balance[msg.sender]-=amount*10**18;
    }

   function lend(uint amount, address payable _to) public payable {
      require(amount*10**18<balance[msg.sender]);
      require(amount*10**18>0);
       balance[msg.sender]-=amount*10**18;
      given[msg.sender][_to]+=amount*10**18;
      borrowed[_to][msg.sender]+=amount*10**18;
    }

    function takeBack(uint amount, address payable _to) public payable {
      require(given[msg.sender][_to]>=amount*10**18);
       balance[msg.sender]+=amount*10**18;
      given[msg.sender][_to]-=amount*10**18;
      borrowed[_to][msg.sender]-=amount*10**18;
      (payable (msg.sender)).transfer(amount*10**18);
    }

function createRequest(string memory description, uint value,address _to) public {
    require(given[_to][msg.sender]>0);
     require(given[_to][msg.sender]>=value*10**18);
        Request storage newRequest = requests[_to].push(); 
        newRequest.description = description;
        newRequest.value= value;
        newRequest.complete= false;
        newRequest.from= msg.sender;
    }

    function approveRequest(uint index) public payable{
        Request storage request = requests[msg.sender][index];
        require(request.complete==false);
        require(given[msg.sender][request.from]>0);
        (payable (request.from)).transfer((request.value)*10**18);
        request.complete=true;
        balance[request.from]+=request.value*10**18;
      given[msg.sender][request.from]-=request.value*10**18;
      borrowed[request.from][msg.sender]-=request.value*10**18;
    }

    function rejectRequest(uint index) public payable{
        Request storage request = requests[msg.sender][index];
        require(request.complete==false);
        request.complete=true;
    }

}