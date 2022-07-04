/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract MultiSig {
    address[] public approvers;
    uint public quorum;

    struct Transfer {
        uint id;
        uint amount;
        address payable to;
        uint approvals;
        bool sent;
    }

    mapping(uint=> Transfer) transfers;
    uint nextId;
    mapping(address => mapping(uint => bool)) approvals;

    constructor(address[] memory _approvers,uint _quorum) payable {
        require(msg.value>0,"send some ether");
        approvers=_approvers;
        quorum=_quorum;
    }
    function createTransfer(uint amount , address payable to) external  onlyApprover{
        transfers[nextId]= Transfer(nextId,amount,to,0,false);
        nextId++;
    }

    function sendTransfer(uint id) external onlyApprover {
         require(transfers[id].sent == false,"Transfer has already been sent");
          if(approvals[msg.sender][id]==false){
            approvals[msg.sender][id] =true;
            transfers[id].approvals++;
         }
         if(transfers[id].approvals >= quorum){
             transfers[id].sent=true;
             address payable to = transfers[id].to;
             uint amount = transfers[id].amount;
             to.transfer(amount);
             return;
         }
    }

    modifier onlyApprover(){
        bool allowed = false;
        for(uint i =0 ; i< approvers.length;i++){
            if(approvers[i]==msg.sender){
                allowed=true;
            }
        }
        require(allowed==true,"Only Apporver allowed");
        _;
    }
}