/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;
// In this version of solidity we must add this line to be able to use an array of structs
pragma experimental ABIEncoderV2;

contract Wallet {
    //array of approver wallets
    address[] public approvers;

    //quorum: number of approvers needed to approve a transfer
    uint256 public quorum;

    //create a struct to take the place of each transfer
    struct Transfer {
        //each transfer will have an id
        uint256 id;
        //the transfer amount
        uint256 amount;
        //address to send to. make address payable so we can send ether to it
        address payable to;
        //the number of approvals that the transfer has receieved
        uint256 approvals;
        //bool to check if the transfer been sent already
        bool sent;
    }
    // an array to hold a list of all the transfers. We must make a function to return the whole list of transfers.
    Transfer[] public transfers;

    //define a mapping to record who has approved what. The key is the id which will map to a bool
    mapping(address => mapping(uint256 => bool)) public approvals;

    // declare the first variables and initialisation logic in the constructor
    constructor(address[] memory _approvers, uint256 _quorum) public {
        approvers = _approvers;
        quorum = _quorum;
    }

    //create a function to get a list of all approvers. Returns an array of addresses. (read-only)
    function getApprovers() external view returns (address[] memory) {
        return approvers;
    }

    //create a function to get a list of all the transfers
    function getTransfers() external view returns (Transfer[] memory) {
        return transfers;
    }

    //create a function for transfers. this will be called by one of the approver addresses when they want to suggest a new transfer
    function createTransfer(uint256 amount, address payable to)
        external
        onlyApprover
    {
        //create a new instance of transfer struct
        transfers.push(
            Transfer(
                //get new id from length
                transfers.length,
                amount,
                to,
                //approvals received
                0,
                //sent
                false
            )
        );
    }

    // a function to approve each transfer. It takes the ID
    function approveTransfer(uint256 id) external onlyApprover {
        //check if the transfer has already been sent
        require(transfers[id].sent == false, "transfer has already been sent");
        //check that the sender of the transaction has not already approved the transfer, because you cannot approve a transaction twice
        require(
            approvals[msg.sender][id] == false,
            "cannot approve transfer twice"
        );
        //set approval for this address to true so that it cannot approve transfer again
        approvals[msg.sender][id] == true;
        //increment the approvals that the transfer has received by one
        transfers[id].approvals++;
        //if we have enough approval then we execute the transaction. Check if approvals meet the quorum.
        if (transfers[id].approvals >= quorum) {
            //update the sent state of the transfer to true
            transfers[id].sent = true;
            //extract the to address
            address payable to = transfers[id].to;
            // extract the amount of the transfer
            uint256 amount = transfers[id].amount;
            //use the solidity transfer method to execute the transfer
            to.transfer(amount);
        }
    }

    //function to be able to receive ether to smart contract using the receive function. This will capture ether sent directly to contract address.
    receive() external payable {}

    //modifier to ensure that only the approved can call functions. logic related to access control often goes inside modifiers.
    modifier onlyApprover() {
        //set a bool for allowed
        bool allowed = false;
        //loop through the approvers array and make sure the calling address is in the approvers
        for (uint256 i = 0; i < approvers.length; i++) {
            //compare the approver to the sender of the transaction
            if (approvers[i] == msg.sender) {
                //set allowed to true
                allowed = true;
            }
        }
        //require that allowed is true before allowing the function to execute
        require(allowed == true, "only approver allowed");
        //execute the rest of the function
        _;
    }
}