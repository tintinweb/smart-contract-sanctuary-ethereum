/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract Wallet {
    event OwnerAdded(uint256 _ownerId, address _owner);
    event TxSubmitted(
        uint256 _txId,
        address _to,
        uint256 _value,
        uint256 _timestamp
    );
    event TxApproved(uint256 _txId, address _owner, uint256 _timestamp);
    event TxRevoked(uint256 _txId, address _owner, uint256 _timestamp);
    event TxExecuted(
        uint256 _txId,
        address _to,
        uint256 _value,
        uint256 _timestamp
    );
    event Deposit(uint256 _value, address _sender);

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
    }

    Transaction[] transactions;
    address[] owners;
    string[] names;
    mapping(address => mapping(uint256 => bool)) isApproved;
    mapping(address => bool) isOwner;
    uint256 required; //will require > 1/2 of total owners to agree

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
        emit Deposit(msg.value, msg.sender);
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
    }

    function submitTx(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "invalid receiver");
        require(_value > 0, "can't make transaction with 0 value");
        transactions.push(Transaction(_to, _value, false));
        emit TxSubmitted(transactions.length - 1, _to, _value, block.timestamp);
    }

    function approveTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(!isApproved[msg.sender][_txId], "transaction already approved");
        isApproved[msg.sender][_txId] = true;
        emit TxApproved(_txId, msg.sender, block.timestamp);
    }

    function revokeTx(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(isApproved[msg.sender][_txId], "transaction not approved");
        isApproved[msg.sender][_txId] = false;
        emit TxRevoked(_txId, msg.sender, block.timestamp);
    }

    function getApprovedCount(uint256 _txId) public view returns (uint256) {
        uint256 res = 0;
        for (uint256 i; i < owners.length; ++i) {
            if (isApproved[owners[i]][_txId]) {
                ++res;
            }
        }
        return res;
    }

    function executeTx(uint256 _txId)
        external
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        require(getApprovedCount(_txId) > required, "insufficient approvals");
        (bool ok, ) = (transaction.to).call{value: transaction.value}("");
        if (!ok) {
            revert("execution failed");
        }
        transaction.executed = true;
        emit TxExecuted(
            _txId,
            transaction.to,
            transaction.value,
            block.timestamp
        );
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
}