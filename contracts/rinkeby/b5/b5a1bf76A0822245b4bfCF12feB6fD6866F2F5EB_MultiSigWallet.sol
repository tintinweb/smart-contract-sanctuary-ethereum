/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

contract MultiSigWallet {
    address[] public owners;
    uint256 public required;
    uint256 public txnCount;

    mapping(address => bool) public isOwner;
    mapping(uint256 => mapping(address => bool)) public approved;

    event SubmitTransaction(
        address indexed owner,
        address indexed to,
        uint256 value
    );
    event Deposit(address indexed sender, uint amount, uint balance);
    event ApproveTransaction(address indexed owner, uint indexed txnId);
    event RevokeApproval(address indexed owner, uint indexed txnId);
    event ExecuteTransaction(address indexed owner, uint indexed txnId);

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
    }

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "You are not the owner");
        _;
    }

    modifier txnExists(uint256 _txnId) {
        require(_txnId < transactions.length, "Transaction does not exist!");
        _;
    }

    modifier notApproved(uint256 _txnId) {
        require(!approved[_txnId][msg.sender], "Transaction already approved!");
        _;
    }

    modifier notExecuted(uint256 _txnId) {
        require(
            !transactions[_txnId].executed,
            "Transaction already executed!"
        );
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners Required");
        require(
            _required > 0 && _required <= _owners.length,
            "Please provide valid required number"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Please provide a valid address");
            require(!isOwner[owner], "Provide unique owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submit(address _to, uint256 _value) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, executed: false})
        );

        txnCount++;

        emit SubmitTransaction(msg.sender, _to, _value);
    }

    function approve(uint256 _txnId)
        external
        onlyOwner
        txnExists(_txnId)
        notApproved(_txnId)
        notExecuted(_txnId)
    {
        approved[_txnId][msg.sender] = true;

        emit ApproveTransaction(msg.sender, _txnId);
    }

    function getApprovalCount(uint256 _txnId) private view returns (uint256) {
        uint256 approvalCount;
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txnId][owners[i]]) {
                approvalCount = approvalCount + 1;
            }
        }

        return approvalCount;
    }

    function execute(uint256 _txnId)
        external
        onlyOwner
        txnExists(_txnId)
        notExecuted(_txnId)
    {
        require(
            getApprovalCount(_txnId) >= required,
            "Required Signature not met!"
        );

        Transaction storage transaction = transactions[_txnId];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "transaction failed!");

        emit ExecuteTransaction(msg.sender, _txnId);
    }

    function revoke(uint _txnId)
        external
        onlyOwner
        txnExists(_txnId)
        notApproved(_txnId)
        notExecuted(_txnId)
    {
        require(approved[_txnId][msg.sender], "Transaction not approved yet");

        approved[_txnId][msg.sender] = false;

        emit RevokeApproval(msg.sender, _txnId);
    }

    function getTransactions() external view returns (Transaction[] memory) {
        return transactions;
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getWalletBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getWalletAddress() external view returns (address) {
        return address(this);
    }
}