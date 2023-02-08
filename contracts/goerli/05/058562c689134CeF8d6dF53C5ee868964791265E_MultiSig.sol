//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error MultiSig__InvalidAddress();
error MultiSig__DuplicateAddress(address duplicateAddr);
error MultiSig__OnlyOwner();
error MultiSig__InsufficientAmount();
error MultiSig__AlreadyConfirmed(uint256 txId);
error MultiSig__InvalidTransactionId(uint256 txId);
error MultiSig__TransactionAlreadyExecuted(uint256 txId);
error MultiSig__TxNotConfirmed(uint256 txId);
error MultiSig__NeedsMoreConfirmations(
    uint256 confirmations,
    uint256 confirmationsNeeded
);
error MultiSig__TransactionExecutionFailed(uint256 txId);
error MultiSig__NeedMoreSharedFunds(uint256 sharedFunds, uint256 txValue);
error MultiSig__InsufficientBalance(uint256 userBalance, uint256 value);
error MultiSig__WithdrawFailed();

/**
 * @title Mutli Sig
 * @author Rohan Nero
 * @notice wish this contract a group of individuals or accounts may control funds/function calls as a collective
 */
contract MultiSig {
    // Type declarations

    struct Transaction {
        address proposer;
        address to;
        bool executed;
        bytes data;
        uint256 transactionId;
        uint256 value;
        uint256 confirmations;
    }
    // I'm confused about these two lines of logic but I know they are used a lot
    //Transaction public transaction;     <---

    struct Deposit {
        address depositor;
        uint256 depositId;
        uint256 value;
    }
    //Deposit public deposit;      <----

    // State Variables
    address[] public owners;
    uint256 public s_confirmationsRequired;
    uint256 public s_transactionCounter;
    uint256 public s_depositCounter;
    uint256 public s_sharedFunds;
    Transaction[] public transactionArray;
    Deposit[] public depositArray;
    Deposit[] public nonOwnerDepositArray;
    mapping(address => uint256) public balances;
    mapping(address => mapping(uint256 => bool)) public hasConfirmed;
    mapping(address => bool) public isOwner;
    mapping(address => Transaction[]) public addressToTxArray;
    mapping(address => Deposit[]) public addressToDepositArray;

    event OwnerAdded(address indexed owner);
    event DepositSubmitted(
        address indexed depositor,
        uint256 indexed depositId,
        uint256 indexed value
    );
    event TransactionProposed(
        address indexed proposer,
        address to,
        uint256 indexed transactionId,
        uint256 indexed value
    );
    event SharedFundsAdded(address indexed owner, uint256 indexed amount);
    event TransactionConfirmed(
        address indexed owner,
        uint256 indexed txId,
        uint256 indexed confirmations
    );
    event ConfirmationRevoked(
        address indexed owner,
        uint256 indexed txId,
        uint256 indexed confirmations
    );
    event TransactionExecuted(address indexed owner, uint256 indexed txId);
    event Withdraw(address indexed owner, uint256 indexed amount);

    modifier onlyOwner() {
        if (isOwner[msg.sender] == false) {
            revert MultiSig__OnlyOwner();
        }
        _;
    }

    modifier exists(uint256 _txId) {
        if (_txId >= transactionArray.length) {
            revert MultiSig__InvalidTransactionId(_txId);
        }
        _;
    }

    modifier isExecuted(uint256 _txId) {
        if (transactionArray[_txId].executed == true) {
            revert MultiSig__TransactionAlreadyExecuted(_txId);
        }
        _;
    }

    /*
     * Function ordering:
     * constructor
     * receive function (if exists)
     * fallback function (if exists)
     * external
     * public
     * internal
     * private
     */
    /**
     * @param _owners array of the addresses that will have access to contracts functions
     * @param _confirmationsRequired number of confirmations that are needed in order to execute a proposed tx
     */
    constructor(address[] memory _owners, uint256 _confirmationsRequired) {
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) {
                revert MultiSig__InvalidAddress();
            } else {
                if (!isOwner[owner]) {
                    owners.push(owner);
                    isOwner[owner] = true;
                    emit OwnerAdded(owner);
                } else {
                    revert MultiSig__DuplicateAddress(owner);
                }
            }
        }
        s_confirmationsRequired = _confirmationsRequired;
        s_transactionCounter = 0;
        s_depositCounter = 0;
    }

    receive() external payable {
        submitDeposit();
    }

    function submitDeposit() public payable {
        if (msg.value <= 0) {
            revert MultiSig__InsufficientAmount();
        }
        Deposit memory newDeposit = Deposit(
            tx.origin,
            s_depositCounter,
            msg.value
        );
        depositArray.push(newDeposit);

        if (isOwner[msg.sender] == true) {
            balances[msg.sender] += msg.value;
            addressToDepositArray[msg.sender].push(newDeposit);
        } else {
            nonOwnerDepositArray.push(newDeposit);
            s_sharedFunds += msg.value;
        }
        emit DepositSubmitted(msg.sender, s_depositCounter, msg.value);
        s_depositCounter++;
    }

    function addSharedFunds(uint256 value) public onlyOwner {
        if (balances[msg.sender] < value) {
            revert MultiSig__InsufficientBalance(balances[msg.sender], value);
        }
        balances[msg.sender] -= value;
        s_sharedFunds += value;
        emit SharedFundsAdded(msg.sender, value);
    }

    function proposeTransaction(
        address payable _to,
        uint256 _amount,
        bytes memory _data
    ) public onlyOwner {
        Transaction memory newTransaction = Transaction(
            msg.sender,
            _to,
            false,
            _data,
            s_transactionCounter,
            _amount,
            0
        );
        transactionArray.push(newTransaction);
        addressToTxArray[msg.sender].push(newTransaction);
        emit TransactionProposed(
            msg.sender,
            _to,
            s_transactionCounter,
            _amount
        );
        s_transactionCounter++;
    }

    function confirmTransaction(uint256 _txId)
        public
        onlyOwner
        exists(_txId)
        isExecuted(_txId)
    {
        if (hasConfirmed[msg.sender][_txId] == true) {
            revert MultiSig__AlreadyConfirmed(_txId);
        }
        hasConfirmed[msg.sender][_txId] = true;
        transactionArray[_txId].confirmations += 1;
        emit TransactionConfirmed(
            msg.sender,
            _txId,
            transactionArray[_txId].confirmations
        );
    }

    /**
     *
     * @param _txId transactionArray index
     */
    function revokeConfirmation(uint256 _txId)
        public
        onlyOwner
        exists(_txId)
        isExecuted(_txId)
    {
        if (hasConfirmed[msg.sender][_txId] == false) {
            revert MultiSig__TxNotConfirmed(_txId);
        }
        hasConfirmed[msg.sender][_txId] = false;
        transactionArray[_txId].confirmations -= 1;
        emit ConfirmationRevoked(
            msg.sender,
            _txId,
            transactionArray[_txId].confirmations
        );
    }

    /**
     *
     * @param _txId transactionArray index
     */
    function executeTransaction(uint256 _txId)
        public
        onlyOwner
        exists(_txId)
        isExecuted(_txId)
    {
        if (transactionArray[_txId].confirmations < s_confirmationsRequired) {
            revert MultiSig__NeedsMoreConfirmations(
                transactionArray[_txId].confirmations,
                s_confirmationsRequired
            );
        }
        Transaction storage transaction = transactionArray[_txId];
        if (transaction.value > s_sharedFunds) {
            revert MultiSig__NeedMoreSharedFunds(
                s_sharedFunds,
                transaction.value
            );
        }
        transaction.executed = true;
        (bool sent, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if (!sent) {
            revert MultiSig__TransactionExecutionFailed(_txId);
        }
        emit TransactionExecuted(msg.sender, _txId);
    }

    /**
     *
     * @param amount wei value to be withdrawn
     */
    function withdraw(uint256 amount) public onlyOwner {
        if (balances[msg.sender] < amount) {
            revert MultiSig__InsufficientBalance(balances[msg.sender], amount);
        }
        balances[msg.sender] -= amount;
        (bool sent, ) = msg.sender.call{value: amount}("");
        if (!sent) {
            revert MultiSig__WithdrawFailed();
        }
        emit Withdraw(msg.sender, amount);
    }

    /// view / pure functions

    /**
     * @notice returns total amount of eth in this contract
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice returns length of transactionArray
     */
    function getTransactionArrayLength() public view returns (uint256) {
        return transactionArray.length;
    }
}