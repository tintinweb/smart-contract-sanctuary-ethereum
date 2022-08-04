// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

error MultiSigWallet__NotEnoughNumberOfConfirmations();
error MultiSigWallet__NotAnOwner();
error MultiSigWallet__TxNotExist();
error MultiSigWallet__TxExecuted();
error MultiSigWallet__NotConfirmed();
error MultiSigWallet__NotConfirmedByOwner();
error MultiSigWallet__NotEnoughConfirmations();

contract MultiSigWallet {
    // STATE VARIABLES
    address[] private s_owners;
    uint256 private s_numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }
    Transaction[] private s_transactions;

    // MAPPINGS
    mapping(address => bool) private isOwner;
    mapping(uint256 => mapping(address => bool)) private isConfirmed;

    // EVENTS
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event transactionConfirm(address indexed owner, uint256 indexed txIndex);
    event confirmationRevoke(address indexed owner, uint256 indexed txIndex);
    event transactionExecute(address indexed owner, uint256 indexed txIndex);
    event transactionSubmit(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    // MODIFIER

    modifier onlyOwner() {
        if (isOwner[msg.sender]) {
            revert MultiSigWallet__NotAnOwner();
        }
        _;
    }

    modifier txExist(uint256 _txIndex) {
        if (_txIndex < s_transactions.length) {
            revert MultiSigWallet__TxNotExist();
        }
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (!s_transactions[_txIndex].executed) {
            revert MultiSigWallet__TxExecuted();
        }
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (!isConfirmed[_txIndex][msg.sender]) {
            revert MultiSigWallet__NotConfirmed();
        }
        _;
    }

    // CONSTRUCTOR

    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "Not enough owners");
        if (_numConfirmationsRequired > 0 && _numConfirmationsRequired > _owners.length) {
            revert MultiSigWallet__NotEnoughNumberOfConfirmations();
        }
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "Already owner");
            isOwner[owner] = true;
            s_owners.push(owner);
        }
        s_numConfirmationsRequired = _numConfirmationsRequired;
    }

    // RECEIVE / FALLBACK

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // FUNCTIONS

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        uint256 txIndex = s_transactions.length;

        s_transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false, numConfirmations: 0})
        );

        emit transactionSubmit(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 txIndex)
        public
        onlyOwner
        txExist(txIndex)
        notExecuted(txIndex)
        notConfirmed(txIndex)
    {
        Transaction storage transaction = s_transactions[txIndex];

        transaction.numConfirmations++;
        isConfirmed[txIndex][msg.sender] = true;

        emit transactionConfirm(msg.sender, txIndex);
    }

    function revokeConfirmation(uint256 txIndex)
        public
        onlyOwner
        txExist(txIndex)
        notExecuted(txIndex)
    {
        Transaction storage transaction = s_transactions[txIndex];

        if (!isConfirmed[txIndex][msg.sender]) {
            revert MultiSigWallet__NotConfirmedByOwner();
        }

        transaction.numConfirmations--;
        isConfirmed[txIndex][msg.sender] = false;

        emit confirmationRevoke(msg.sender, txIndex);
    }

    function executeTransaction(uint256 txIndex)
        public
        onlyOwner
        txExist(txIndex)
        notExecuted(txIndex)
    {
        Transaction storage transaction = s_transactions[txIndex];

        if (transaction.numConfirmations < s_numConfirmationsRequired) {
            revert MultiSigWallet__NotEnoughConfirmations();
        }

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit transactionExecute(msg.sender, txIndex);
    }

    // VIEW / PURE

    function getNumOfOwners() public view returns (uint256) {
        return s_owners.length;
    }

    function getOwner(uint256 index) public view returns (address) {
        return s_owners[index];
    }

    function getNumberOfConfirmationsRequired() public view returns (uint256) {
        return s_numConfirmationsRequired;
    }

    function getTx(uint256 index)
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = s_transactions[index];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function getTxCount() public view returns (uint256) {
        return s_transactions.length;
    }
}