// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Modifier's errors
error MultiSigWallet__NotOwner();
error MultiSigWallet__NonExistingTx();
error MultiSigWallet__AlreadyExecutedTx();
error MultiSigWallet__AlreadyConfirmedTx();

error MultiSigWallet__InsufficientNumberOfOwners();
error MultiSigWallet__InvalidNumberOfRequiredConfirmations();
error MultiSigWallet__InvalidOwnerAddress();
error MultiSigWallet__NotUniqueOwnerAddress();
error MultiSigWallet__InsufficientFunds();
error MultiSigWallet__NotEnoughConfirmations();
error MultiSigWallet__TxFailed();
error MultiSigWallet__TxNotConfirmed();

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numberOfConfirmations;
    }

    mapping(address => bool) public s_owners;
    // mapping from tx index => owner => bool, check if tx is confirmed by that particular owner
    mapping(uint256 => mapping(address => bool)) public s_isConfirmed;
    Transaction[] public s_transactions;
    uint256 public immutable i_numberOfConfirmationsRequired;

    modifier onlyOwner() {
        if (!(s_owners[msg.sender])) {
            revert MultiSigWallet__NotOwner();
        }
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (!(_txIndex < s_transactions.length)) {
            revert MultiSigWallet__NonExistingTx();
        }
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (s_transactions[_txIndex].executed) {
            revert MultiSigWallet__AlreadyExecutedTx();
        }
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (s_isConfirmed[_txIndex][msg.sender]) {
            revert MultiSigWallet__AlreadyConfirmedTx();
        }
        _;
    }

    constructor(address[] memory owners, uint256 numberConfirmationsRequired) {
        if (!(owners.length > 0)) {
            revert MultiSigWallet__InsufficientNumberOfOwners();
        }

        if (
            numberConfirmationsRequired == 0 ||
            numberConfirmationsRequired > owners.length
        ) {
            revert MultiSigWallet__InvalidNumberOfRequiredConfirmations();
        }
        for (uint256 i = 0; i < owners.length; i++) {
            address owner = owners[i];

            if (owner == address(0)) {
                revert MultiSigWallet__InvalidOwnerAddress();
            }

            if (s_owners[owner]) {
                revert MultiSigWallet__NotUniqueOwnerAddress();
            }

            s_owners[owner] = true;
        }

        i_numberOfConfirmationsRequired = numberConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner {
        if (_value > address(this).balance) {
            revert MultiSigWallet__InsufficientFunds();
        }

        uint256 txIndex = s_transactions.length;
        s_transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numberOfConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        s_transactions[_txIndex].numberOfConfirmations += 1;
        s_isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = s_transactions[_txIndex];

        if (
            transaction.numberOfConfirmations < i_numberOfConfirmationsRequired
        ) {
            revert MultiSigWallet__NotEnoughConfirmations();
        }

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );

        if (!success) {
            revert MultiSigWallet__TxFailed();
        }

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = s_transactions[_txIndex];

        if (!(s_isConfirmed[_txIndex][msg.sender])) {
            revert MultiSigWallet__TxNotConfirmed();
        }

        transaction.numberOfConfirmations -= 1;
        s_isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getTransactionCount() public view returns (uint256) {
        return s_transactions.length;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}