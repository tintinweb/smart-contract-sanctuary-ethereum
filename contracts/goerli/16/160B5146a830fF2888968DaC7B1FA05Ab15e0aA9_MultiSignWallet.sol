// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Function to create a transaction
//Function to approve the transaction for our owners
//Function send transaction if Threshold is met
error NOTOwner(address sender);
error RequireThreshold(uint threshold);
error transactionFailed();

contract MultiSignWallet {
    event TransactionCreate(uint value, address to, bytes data);

    mapping(address => bool) public isOwner;
    mapping(uint => mapping(address => bool)) public WhichProposal;

    address[] public Owners;
    uint public threshold;

    struct Transaction {
        uint value;
        address to;
        bytes data;
        bool executed;
    }
    Transaction[] private transaction;

    constructor(uint _threshold, address[] memory sender) {
        threshold = _threshold;
        for (uint i; i < sender.length; i++) {
            isOwner[sender[i]] = true;
            Owners.push(sender[i]);
        }
    }

    function CreateTransaction(
        uint _value,
        address _to,
        bytes calldata _data
    ) external {
        if (!isOwner[msg.sender]) {
            revert NOTOwner(msg.sender);
        }
        Transaction memory trans = Transaction({
            value: _value,
            to: _to,
            data: _data,
            executed: false
        });
        transaction.push(trans);
        emit TransactionCreate(_value, _to, _data);
    }

    function Approve(uint index) external {
        if (!isOwner[msg.sender]) revert NOTOwner(msg.sender);
        WhichProposal[index][msg.sender] = true;
    }

    function executeTransaction(uint index) external {
        if (!isOwner[msg.sender]) revert NOTOwner(msg.sender);
        uint count;
        for (uint i; i < Owners.length; i++) {
            if (WhichProposal[index][Owners[i]]) {
                count += 1;
            }
        }
        if (count < threshold) revert RequireThreshold(count);
        (bool sucess, bytes memory data) = payable(transaction[index].to).call{
            value: transaction[index].value
        }(transaction[index].data);
        if (!sucess) revert transactionFailed();
    }

    receive() external payable {}

    function checkIsOwner(address sender) public view returns (bool) {
        return isOwner[sender];
    }

    function getTransaction(uint index)
        public
        view
        returns (Transaction memory)
    {
        return transaction[index];
    }

    function ProposalVoted(uint index) public view returns (bool) {
        return WhichProposal[index][msg.sender];
    }
}