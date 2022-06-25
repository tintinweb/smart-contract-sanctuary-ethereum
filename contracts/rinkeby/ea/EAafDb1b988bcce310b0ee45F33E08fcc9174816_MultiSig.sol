// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error MultiSig__NotOwner();
error MultiSig__TxDoesNotExist();
error MultiSig__TxAlreadyExecuted();
error MultiSig__TxAlreadyConfirmed();
error MultiSig__OwnersRequired();
error MultiSig__InvalidNumConfirmationsRequired();
error MultiSig__InvalidAddress();
error MultiSig__AlreadyOwner();
error MultiSig__NotEnoughConfirmations();
error MultiSig__TxFailed();
error MultiSig__TxNotConfirmed();

contract MultiSig {
    struct Transaction {
        address payable to;
        uint256 value;
        bytes data;
        uint256 numConfirmations;
        bool isExecuted;
    }

    /////////////////////
    // State Variables //
    /////////////////////
    Transaction[] public transactions;
    address payable[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;
    // Transaction ID -> owner -> transaction confirmation
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    ////////////
    // Events //
    ////////////
    event Deposit(address indexed sender, uint256 amount);
    event TransactionSubmitted(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event TransactionConfirmed(address indexed owner, uint256 indexed txIndex);
    event TransactionRevoked(address indexed owner, uint256 indexed txIndex);
    event TransactionExecuted(address indexed owner, uint256 indexed txIndex);

    ///////////////
    // Modifiers //
    ///////////////
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert MultiSig__NotOwner();
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= transactions.length) revert MultiSig__TxDoesNotExist();
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (transactions[_txIndex].isExecuted) revert MultiSig__TxAlreadyExecuted();
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) revert MultiSig__TxAlreadyConfirmed();
        _;
    }

    ///////////////
    // Functions //
    ///////////////
    constructor(address payable[] memory _owners, uint256 _numConfirmationsRequired) {
        if (_owners.length == 0) revert MultiSig__OwnersRequired();
        if (_numConfirmationsRequired == 0 || _numConfirmationsRequired > _owners.length)
            revert MultiSig__InvalidNumConfirmationsRequired();

        for (uint256 i = 0; i < _owners.length; i++) {
            address payable owner = _owners[i];

            if (owner == address(0)) revert MultiSig__InvalidAddress();
            if (isOwner[owner]) revert MultiSig__AlreadyOwner();

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(
        address payable _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                numConfirmations: 0,
                isExecuted: false
            })
        );

        emit TransactionSubmitted(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit TransactionConfirmed(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        if (transaction.numConfirmations < numConfirmationsRequired)
            revert MultiSig__NotEnoughConfirmations();

        transaction.isExecuted = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        if (!success) revert MultiSig__TxFailed();

        emit TransactionExecuted(msg.sender, _txIndex);
    }

    function revokeTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        if (!isConfirmed[_txIndex][msg.sender]) revert MultiSig__TxNotConfirmed();

        Transaction storage transaction = transactions[_txIndex];

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit TransactionRevoked(msg.sender, _txIndex);
    }

    function getOwners() external view returns (address payable[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex) external view returns (Transaction memory) {
        return transactions[_txIndex];
    }
}