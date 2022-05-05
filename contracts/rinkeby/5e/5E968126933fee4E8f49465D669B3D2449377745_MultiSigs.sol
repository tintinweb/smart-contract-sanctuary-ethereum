// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract MultiSigs {
    // Transaction info
    struct Transaction {
        address to;
        uint8 numConfirmations;
        uint8 numRejects;
        bool executed;
        bool isUrgent;

        uint256 value;
        uint256 delay;
        bytes data;
    }

    // minimum number of confirmations from owner before a transaction can be executed
    uint8 public numConfirmationsRequired;

    // minimum delay time before a transaction can be executed
    uint256 public immutable minDelay;

    // check if an address is owner or not
    mapping(address => bool) public isOwner;

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) public isRejected;

    // a list of owners to this multisigs contract
    address[] public owners;

    // list of all transactions
    Transaction[] public transactions;

    // Events
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        string name,
        uint256 value,
        bytes data,
        uint256 delay
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event RejectTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeRejection(address indexed owner, uint256 indexed txIndex);

    // Modifier
    modifier onlyOwner() {
        require(isOwner[msg.sender], "NOT_OWNER");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "TX_DOES_NOT_EXIST");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "ALREADY_EXECUTED");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "ALREADY_CONFIRMED");
        _;
    }

    /// @param _owners list of address of owners of this contract
    /// @param _numConfirmationsRequired number of confirmation required for a transaction
    /// @param _minDelay minimum duration before a transaction can be executed
    constructor(
        address[] memory _owners,
        uint8 _numConfirmationsRequired,
        uint256 _minDelay
    ) {        
        require(_owners.length > 0, "EMPTY_ARRAY");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "INVALID_NUM_CONFIRMATIONS_REQUIRED"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "INVALID_OWNER_ADDRESS");
            require(!isOwner[owner], "OWNER_NOT_UNIQUE");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        minDelay = _minDelay;
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value, address(this).balance);
        }
    }

    fallback() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value, address(this).balance);
        }
    }

    /// @dev submit a transaction to be voted
    /// @param _to address of the target contract to be called
    /// @param _value value in wei to send the transaction
    /// @param _data payload data when send the transaction
    /// @param _delay The duration required before the transaction can be executed
    /// @param _isUrgent is this transaction urgent or not
    function submitTransaction(
        string memory _name,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _delay,
        bool _isUrgent
    ) external onlyOwner {
        require(_delay >= minDelay, "DELAY_LESS_THAN_MINDELAY");

        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
        to : _to,
        value : _value,
        data : _data,
        executed : false,
        numConfirmations : 1,
        delay : block.timestamp + _delay,
        isUrgent : _isUrgent,
        numRejects : 0
        })
        );

        isConfirmed[txIndex][msg.sender] = true;

        emit SubmitTransaction(msg.sender, txIndex, _to, _name, _value, _data, _delay);
    }

    /// @dev approve a transaction
    /// @param _txIndex index of the transaction
    function confirmTransaction(uint256 _txIndex)
    external
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notConfirmed(_txIndex)
    {
        require(!isRejected[_txIndex][msg.sender], "ALREADY_REJECTED");

        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /// @dev execute a transaction
    /// @param _txIndex index of the transaction to be executed
    function executeTransaction(uint256 _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(address(this).balance >= transaction.value, "NOT_ENOUGH_ETHER");

        if (!transaction.isUrgent) {
            require(transaction.numRejects < numConfirmationsRequired, "TRANSACTION_REJECTED");
            require(transaction.numConfirmations >= numConfirmationsRequired, "NOT_REACH_MIN_CONFIRMATION");
            require(transaction.delay < block.timestamp, "TX_NOT_READY");
        } else {
            require(transaction.numConfirmations >= owners.length - 1, "NOT_REACH_MIN_CONFIRMATION");
        }

        transaction.executed = true;

        (bool success,) = transaction.to.call{value : transaction.value}(transaction.data);
        require(success, "TX_FAILED");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /// @dev revoke confirmation
    /// @param _txIndex index of the transaction
    function revokeConfirmation(uint256 _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "CAN_NOT_REVOKE");

        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /// @dev reject the transaction
    /// @param _txIndex index of the transaction
    function rejectTransaction(uint256 _txIndex)
    external
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notConfirmed(_txIndex)
    {
        require(!isRejected[_txIndex][msg.sender], "ALREADY_REJECTED");

        Transaction storage transaction = transactions[_txIndex];
        transaction.numRejects += 1;
        isRejected[_txIndex][msg.sender] = true;

        emit RejectTransaction(msg.sender, _txIndex);
    }

    /// @dev revoke rejection
    /// @param _txIndex index of the transaction
    function revokeRejection(uint256 _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        require(isRejected[_txIndex][msg.sender], "CAN_NOT_REVOKE");

        Transaction storage transaction = transactions[_txIndex];
        transaction.numRejects -= 1;
        isRejected[_txIndex][msg.sender] = false;

        emit RevokeRejection(msg.sender, _txIndex);
    }

    /// @notice get the list of owners
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /// @notice get the current number of transactions
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    /// @notice get info of a transaction
    /// @param _txIndex index of the transaction
    function getTransaction(uint256 _txIndex) external view returns (Transaction memory transaction) {
        transaction = transactions[_txIndex];
    }

    /// @dev add a new owner, can only be called by this contract
    /// @param _newOwnerAddress address of the new owner
    function addOwner(address _newOwnerAddress) external {
        // only this contract can call this function
        require(msg.sender == address(this), "CALL_DENIED");
        require(!isOwner[_newOwnerAddress], "ALREADY_OWNER");
        require(_newOwnerAddress != address(0), "ADDRESS_ZERO");

        isOwner[_newOwnerAddress] = true;
        owners.push(_newOwnerAddress);
    }

    /// @dev remove an owner, can only be called by this contract
    /// @param _ownerToRemove Address of the owner to be removed
    function removeOwner(address _ownerToRemove) external {
        uint256 ownerLength = owners.length;

        require(msg.sender == address(this), "CALL_DENIED");
        require(ownerLength > 1, "CAN_NOT_REMOVE");
        require(isOwner[_ownerToRemove], "NOT_OWNER");

        isOwner[_ownerToRemove] = false;
        // remove the _ownerToRemove from "owners" array
        for (uint256 i = 0; i < ownerLength; i++) {
            if (owners[i] == _ownerToRemove) {
                owners[i] = owners[ownerLength - 1];
                owners.pop();
                break;
            }
        }

        // change the numConfirmationsRequired = owners.length if
        // the numConfirmationsRequired > owners.length
        // assuming that owners.length is not > uint8.max
        if (numConfirmationsRequired > owners.length) {
            numConfirmationsRequired = uint8(owners.length);
        }
    }

    /// @dev set the number of confirmations required, can only be called by this contract
    /// @param _newNumConfirmationsRequired new number of confirmations to be set
    function setNumConfirmationsRequired(uint8 _newNumConfirmationsRequired) external {
        require(msg.sender == address(this), "CALL_DENIED");
        require(
            _newNumConfirmationsRequired > 0 && _newNumConfirmationsRequired <= owners.length,
            "INVALID_NUM_CONFIRMATION_REQUIRED"
        );

        numConfirmationsRequired = _newNumConfirmationsRequired;
    }
}