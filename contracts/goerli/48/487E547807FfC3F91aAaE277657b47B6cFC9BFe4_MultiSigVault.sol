// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MultiSigVault {
    address[] public owners;
    uint256 public minRequired;
    mapping(address => bool) public isOwner;
    mapping(uint256 => mapping(address => bool)) public approved;
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender] == true);
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId >= 0 && _txId < transactions.length, "Invalid txId");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "Transaction already approved");
        _;
    }

    constructor(address[] memory _owners, uint256 _minRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _minRequired > 0 && _minRequired <= _owners.length,
            "invalid number of required confirmations"
        );
        owners = _owners;
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "owner is not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }

        minRequired = _minRequired;
    }

    function recieve() external payable {}

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
    }

    function approveTransaction(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notApproved(_txId)
    {
        approved[_txId][msg.sender] = true;
    }

    function _getApprovalCount(uint256 _txId)
        private
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function executeTransaction(uint256 _txId)
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(
            _getApprovalCount(_txId) >= minRequired,
            "Not enough approvals"
        );
        Transaction storage transaction = transactions[_txId];
        address reciever = transaction.to;
        (bool success, ) = reciever.call{value: transaction.value}(
            transaction.data
        );
        transaction.executed = true;
        require(success, "Transaction failed!");
    }

    function revokeTransaction(uint256 _txId)
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(approved[_txId][msg.sender], "Tx is not approved by you!");
        approved[_txId][msg.sender] = false;
    }
}