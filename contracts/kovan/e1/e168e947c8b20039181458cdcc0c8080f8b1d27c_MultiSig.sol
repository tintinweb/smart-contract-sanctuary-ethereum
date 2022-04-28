/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSig {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    } 

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved; 

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an Owner bastard !");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "Transcation with the following Id Does not Exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!approved[_txId][msg.sender], "You already approved this transaction");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "This Transaction is already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "Atleast 1 Owner required");
        require(_required > 0 && _required <= _owners.length, "Invalid No.of Required Owners");

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Zero address cannot be Owner !!!");
            require(!isOwner[owner], "Owner should be Unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required, "Not Enough No.of Owners Approved this Tx");
        Transaction storage transaction = transactions[_txId];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender], "This transaction is not yet approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    function getBal() external view returns (uint bal) {
        bal = address(this).balance;
    }
}

// address[] owners - ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB", "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"]
// Required - 2
// contract address - 0xE168E947C8B20039181458CDcC0C8080f8B1D27c