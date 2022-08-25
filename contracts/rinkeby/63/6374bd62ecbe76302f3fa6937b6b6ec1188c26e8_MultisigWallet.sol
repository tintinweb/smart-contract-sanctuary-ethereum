/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MultisigWallet{

    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);   

    address[] public owners;
    mapping (address => bool) public isOwner ;
    mapping (uint => mapping(address => bool)) public approved ;
    uint public immutable required;

    struct Transaction{
        address to;
        uint value;
        bytes data;
        uint approvals;
        bool executed;
    }

    Transaction[] public transactions;

    constructor(address[] memory _owners, uint _required){
        require(_owners.length >0, "empty array of owners");
        require(_required > 0, "required cannot be less than 1");
        require(_required <= _owners.length, "required cannot be more than the owners");
        required = _required;

        for(uint i; i<_owners.length; i++){
            require(_owners[i] != address(0));
            require(!isOwner[_owners[i]], "duplicate owners present");
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
        }
    }

    receive() external payable{
        emit Deposit(msg.sender, msg.value);
    }

    modifier onlyOwner(){
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txPresent(uint _txId){
        require(_txId < transactions.length, "Invalid Transaction Number");
        _;
    }

    modifier notExecuted(uint _txId){
        require(transactions[_txId].executed == false, "Transaction already executed");
        _;
    }

    function submit (address _to, uint _value, bytes calldata _data) external onlyOwner{
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            approvals: 0,
            executed: false
        }));

        emit Submit(transactions.length-1);
    }

    function approve (uint _txId) external onlyOwner txPresent(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender] == false, "already approved");
        approved[_txId][msg.sender] = true;
        transactions[_txId].approvals++;

        emit Approve(msg.sender, _txId);
    }

    function revoke (uint _txId) external onlyOwner txPresent(_txId) notExecuted(_txId){
        require(approved[_txId][msg.sender] == true, "already not approved");
        approved[_txId][msg.sender] = false;
        transactions[_txId].approvals--;

        emit Revoke(msg.sender, _txId);
    }

    function execute (uint _txId) external onlyOwner txPresent(_txId) notExecuted(_txId){

        Transaction storage transaction = transactions[_txId];
        require(transaction.approvals >= required, "approvals < required");

        transaction.executed = true;
        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);

        require(success == true, "transaction execution failed");

        emit Execute(_txId);
    }
}