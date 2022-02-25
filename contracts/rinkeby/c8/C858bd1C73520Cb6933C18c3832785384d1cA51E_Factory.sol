// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./MultiSigWallet.sol";

contract Factory {
    address[] public wallets;
    mapping(address => uint256) public walletIdMapping;
    uint256 internal nextId = 0;
    MultiSigWallet internal multiSigWallet;

    event WalletCreated(address indexed wallet);

    function createWallet(address[] memory _owners, uint _required) public {
        multiSigWallet = new MultiSigWallet(_owners, _required);
        wallets.push(address(multiSigWallet));
        for (uint i = 0; i < _owners.length; i++) {
            walletIdMapping[_owners[i]] = nextId;
        }
        nextId++;
        emit WalletCreated(address(multiSigWallet));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Reject(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    enum Status {
        Pending,
        Executed,
        Rejected
    }

    struct Transaction {
        uint idx;
        address to;
        uint value;
        bytes data;
        Status status;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;

    enum Approval {
        Pending,
        Approved,
        Rejected
    }

    mapping(uint => mapping(address => Approval)) public approval;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!(approval[_txId][msg.sender] == Approval.Approved), "tx already approved");
        _;
    }

    modifier notRejected(uint _txId) {
        require(!(approval[_txId][msg.sender] == Approval.Rejected), "tx already rejected");
        _;
    }

    modifier isPending(uint _txId) {
        require(transactions[_txId].status == Status.Pending, "tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "At least one owner is required");
        require(_required > 0 && _required <= _owners.length, "Invalid number of owners");

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Owner cannot be the zero address");
            require(!isOwner[owner], "Owner cannot be a duplicate");

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
            idx: transactions.length,
            to: _to,
            value: _value,
            data: _data,
            status: Status.Pending
        }));
        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) isPending(_txId) {
        approval[_txId][msg.sender] = Approval.Approved;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approval[_txId][owners[i]] == Approval.Approved) {
                count += 1;
            }
        }
    }

    function execute(uint _txId) external txExists(_txId) isPending(_txId) {
        require(_getApprovalCount(_txId) >= required, "Not enough approvals");
        Transaction storage transaction = transactions[_txId];
        transaction.status = Status.Executed;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction failed");
        emit Execute(_txId);
    }

    // TODO: Update this function to use the transaction status enum for revoking approvals and rejections
    function revoke(uint _txId) external onlyOwner txExists(_txId) isPending(_txId) {
        require(approval[_txId][msg.sender] == Approval.Approved, "tx not approved");
        approval[_txId][msg.sender] = Approval.Pending;
        emit Revoke(msg.sender, _txId);
    }

    function reject(uint _txId) external onlyOwner txExists(_txId) notRejected(_txId) isPending(_txId) {
        approval[_txId][msg.sender] = Approval.Rejected;
        emit Reject(msg.sender, _txId);
    }

    function getTransactions() external view returns (Transaction[] memory) {
        return transactions;
    }
}