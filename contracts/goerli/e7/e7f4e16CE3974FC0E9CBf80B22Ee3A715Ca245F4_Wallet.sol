// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
// to return an array of structs
contract Wallet {
    address[] private approvers;
    uint public quorum;

    struct Transfer {
    uint id;
    uint amount;
    address payable to;
    uint approver;
    bool sent;
    }
    // mapping(uint => Transfer) public transfers;

    Transfer[] private transfers;
    uint public nextId;
    uint public currentId;
     mapping(address => mapping(uint => bool)) private approvals;
     mapping(address => uint) private checkId;
    constructor (address[] memory _approvers, uint _quorum) {
        approvers = _approvers;
        quorum = _quorum; 
    }

    // function getApprovers () external view returns(address[] memory) {
    //     return approvers;
    // }

    // function getTransfers () external view returns(Transfer[] memory) {
    //     return transfers;
    // }
    // function returnId (address _addr) external view returns(uint) {
    //     for(uint i = 0; i <transfers.length; i++) {
    //         if(transfers[i][msg.sender] == transfers[i]._addr){
    //             currentId = i;
    //         }
    //     }
    // }

    function createTransfer (uint _amount, address payable _to) onlyApprover external {
        transfers.push(Transfer(
            transfers.length,
            _amount,
            _to,
            0,
            false
        ));
        nextId++;
    }
     function approveTransfer (uint id) onlyApprover external{
         require(transfers[id].sent == false, "Transfer has already been sent");
         require(approvals[msg.sender][id] == false, "Cannot approve transfer twice");

         approvals[msg.sender][id] = true;
         transfers[id].approver++;

         if(transfers[id].approver >= quorum) {
             transfers[id].sent = true;
             address payable to = transfers[id].to;
             uint amount = transfers[id].amount;
             to.transfer(amount);
         }
    }

    receive() external payable {}
    modifier onlyApprover () {
        bool allowed = false;
        for (uint i = 0; i<approvers.length; i++) {
            if (approvers[i] == msg.sender) {
                allowed = true;
            }
        }
     require (allowed == true, 'only approver allowed');
     _;
    }
}