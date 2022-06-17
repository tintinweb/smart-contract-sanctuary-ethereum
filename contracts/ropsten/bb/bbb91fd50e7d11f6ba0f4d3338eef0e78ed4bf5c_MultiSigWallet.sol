/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MultiSigWallet {
    event Deposite(address indexed sender, uint256 amount);
    event Submit(IERC20 indexed token, uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 txId);
    event Execute(uint256 indexed txId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], 'Not owner');
        _;
    }

    modifier transactionExists(uint256 _txId) {
        require(_txId < transactions.length, 'Transaction does not exist');
        _;
    }

    modifier Unapproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], 'Transaction already approved');
        _;
    }

    modifier Unexecuted(uint256 _txId) {
        require(!transactions[_txId].executed, 'Transaction already executed');
        _;
    }

    struct Transaction {
        IERC20 token;
        address to;
        uint256 value;
        bool executed;
    }

    address[] private owners;
    mapping(address => bool) private isOwner;
    uint256 private required;

    Transaction[] private transactions;

    mapping(uint256 => mapping(address => bool)) private approved;

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, 'Owners can not be 0');
        require(_required > 0 && _required <= _owners.length, 'Invalid required number of owners');

        for(uint256 i ; i<_owners.length ; i++) {
            address owner = _owners[i];
            require(owner != address(0), 'Invalid owner');
            require(!isOwner[owner], 'Owner is not unique');

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    /**
     * 仅接收 ETH 时触发
     * Emit only when eth is received
     */
    receive() external payable {
        emit Deposite(msg.sender, msg.value);
    }

    /**
     * 任何 owner 都可以取回 ETH
     * Any owner can retrieve eth
     */
    function withdraw() external payable onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getTransactionExecutedOwner(uint256 _txId) external view onlyOwner() transactionExists(_txId) returns (address[] memory) {
        address[] memory executedOwner = new address[](required);
        for(uint256 i ; i<owners.length ; i++) {
            if(approved[_txId][owners[i]]) {
                executedOwner[i] = owners[i];
            }
        }
        return executedOwner;
    }

    function getTotalTransactions() external view onlyOwner() returns (Transaction[] memory) {
        return transactions;
    }

    function submit(IERC20 _token, address _to, uint256 _value) external onlyOwner() {
        require(_value != 0, 'Invalid value');
        require(_token.balanceOf(address(this)) >= _value, 'Value is not enough');

        transactions.push(Transaction({
            token: _token,
            to: _to,
            value: _value,
            executed: false
        }));
        if(getApprovalCount(transactions.length - 1) >= required) {
            execute(transactions.length - 1);
        }

        emit Submit(_token, transactions.length - 1);
    }

    function approve(uint256 _txId) external onlyOwner() transactionExists(_txId) Unapproved(_txId) Unexecuted(_txId) {
        approved[_txId][msg.sender] = true;
        if(getApprovalCount(_txId) >= required) {
            execute(_txId);
        }

        emit Approve(msg.sender, _txId);
    }

    function revoke(uint256 _txId) external onlyOwner() transactionExists(_txId) Unexecuted(_txId) {
        require(approved[_txId][msg.sender], 'Transaction is not approved');

        approved[_txId][msg.sender] = false;

        emit Revoke(msg.sender, _txId);
    }

    function getApprovalCount(uint256 _txId) private view returns (uint256 count) {
        for(uint256 i ; i<owners.length ; i++) {
            if(approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint256 _txId) private onlyOwner() transactionExists(_txId) Unexecuted(_txId) {
        require(getApprovalCount(_txId) >= required, 'Approvals are not enough');

        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        IERC20(transaction.token).transfer(transaction.to, transaction.value);
        
        emit Execute(_txId);
    }
}