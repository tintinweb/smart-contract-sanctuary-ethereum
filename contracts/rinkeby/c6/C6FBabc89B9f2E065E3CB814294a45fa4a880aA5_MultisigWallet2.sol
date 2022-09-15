/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract MultisigWallet2 {
    event OwnerAdded(address _owner, string _name);
    event TxSubmitted(
        uint256 _txId,
        address _to,
        uint256 _value,
        address _submitter,
        uint256 _timestamp
    );
    event TxApproved(uint256 _txId, address _owner);
    event TxRevoked(uint256 _txId, address _owner);
    event TxExecuted(uint256 _txId, uint256 _timestamp);
    event Deposit(uint256 _value, address _sender, uint256 _newBalance);

    struct Transaction {
        address to;
        address submitter;
        uint256 submittedAt;
        uint256 executedAt;
        uint256 approvals;
        uint256 value;
        bool executed;
    }

    Transaction[] transactions;
    address[] owners;
    string[] names;
    mapping(address => mapping(uint256 => bool)) isApproved;
    mapping(address => bool) isOwner;
    uint256 public required; //will require > 1/2 of total owners to agree

    modifier onlyOwner() {
        require(isOwner[msg.sender], "permission denied");
        _;
    }
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "invalid transaction ID");
        _;
    }
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "transaction already executed");
        _;
    }

    receive() external payable {
        emit Deposit(msg.value, msg.sender, address(this).balance);
    }

    constructor(address[] memory _owners, string[] memory _names) {
        require(_owners.length > 0, "at least one owner required");
        require(
            _owners.length == _names.length,
            "addr & name count don't match"
        );
        address owner;
        for (uint256 i; i < _owners.length; ++i) {
            owner = _owners[i];
            require(owner != address(0), "addr 0 can't be owner");
            require(!isOwner[owner], "owners not unique");
            isOwner[owner] = true;
            owners.push(owner);
            names.push(_names[i]);
        }
        required = owners.length / 2;
    }

    function addOwner(address _owner, string memory _name) external onlyOwner {
        require(_owner != address(0), "addr 0 can't be owner");
        require(!isOwner[_owner], "owner already added");
        isOwner[_owner] = true;
        owners.push(_owner);
        names.push(_name);
        required = owners.length / 2;
        emit OwnerAdded(_owner, _name);
    }

    function submitTx(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "invalid receiver");
        require(_value > 0, "can't make transaction with 0 value");
        transactions.push(
            Transaction(_to, msg.sender, block.timestamp, 0, 0, _value, false)
        );
        emit TxSubmitted(
            transactions.length - 1,
            _to,
            _value,
            msg.sender,
            block.timestamp
        );
    }

    function approveTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(!isApproved[msg.sender][_txId], "transaction already approved");
        isApproved[msg.sender][_txId] = true;
        transactions[_txId].approvals += 1;
        emit TxApproved(_txId, msg.sender);
    }

    function revokeTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(isApproved[msg.sender][_txId], "transaction not approved");
        isApproved[msg.sender][_txId] = false;
        transactions[_txId].approvals -= 1;
        emit TxRevoked(_txId, msg.sender);
    }

    function executeTx(uint256 _txId)
        external
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        require(
            transactions[_txId].approvals > required,
            "insufficient approvals"
        );
        (bool ok, ) = (transaction.to).call{value: transaction.value}("");
        if (!ok) {
            revert("execution failed");
        }
        transaction.executed = true;
        transaction.executedAt = block.timestamp;
        emit TxExecuted(_txId, block.timestamp);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getOwners()
        external
        view
        returns (address[] memory, string[] memory)
    {
        return (owners, names);
    }

    function getTransactions() external view returns (Transaction[] memory) {
        return transactions;
    }

    function getApprovalCount(uint256 _txId)
        external
        view
        txExists(_txId)
        returns (uint256)
    {
        return transactions[_txId].approvals;
    }

    function isOwnerApproved(address _owner, uint256 _txId)
        external
        view
        txExists(_txId)
        returns (bool)
    {
        return isApproved[_owner][_txId];
    }
}