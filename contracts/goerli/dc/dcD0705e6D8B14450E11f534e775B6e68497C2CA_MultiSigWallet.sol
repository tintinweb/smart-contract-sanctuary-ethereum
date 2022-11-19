pragma solidity ^0.5.16;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        mapping(address => bool) isConfirmed;
        uint numConfirmations;
    }

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(
            !transactions[_txIndex].isConfirmed[msg.sender],
            "tx already confirmed"
        );
        _;
    }

    /*
    Exercise
    1. Validate that the _owner is not empty
    2. Validate that _numConfirmationsRequired is greater than 0
    3. Validate that _numConfirmationsRequired is less than or equal to the number of _owners
    4. Set the state variables owners from the input _owners.
        - each owner should not be the zero address
        - validate that the owners are unique using the isOwner mapping
    5. Set the state variable numConfirmationsRequired from the input.
    */
    constructor(address[] memory _owners, uint _numConfirmationsRequired)
        public
    {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /*
    Exercise
    1. Declare a payable fallback function
        - it should emit the Deposit event with
            - msg.sender
            - msg.value
            - current amount of ether in the contract (address(this).balance)
    */
    function() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /* Exercise
    1. Complete the onlyOwner modifier defined above.
        - This modifier should require that msg.sender is an owner
    2. Inside submitTransaction, create a new Transaction struct from the inputs
       and append it the transactions array
        - executed should be initialized to false
        - numConfirmations should be initialized to 0
    3. Emit the SubmitTransaction event
        - txIndex should be the index of the newly created transaction
    */
    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /* Exercise
    1. Complete the modifier txExists
        - it should require that the transaction at txIndex exists
    2. Complete the modifier notExecuted
        - it should require that the transaction at txIndex is not yet executed
    3. Complete the modifier notConfirmed
        - it should require that the transaction at txIndex is not yet
          confirmed by msg.sender
    4. Confirm the transaction
        - update the isConfirmed to true for msg.sender
        - increment numConfirmation by 1
        - emit ConfirmTransaction event for the transaction being confirmed
    */
    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        transaction.isConfirmed[msg.sender] = true;
        transaction.numConfirmations += 1;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /* Exercise
    1. Execute the transaction
        - it should require that number of confirmations >= numConfirmationsRequired
        - set executed to true
        - execute the transaction using the low level call method
        - require that the transaction executed successfully
        - emit ExecuteTransaction
    */
    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call.value(transaction.value)(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /* Exercise
    1. Add appropriate modifiers
        - only owner should be able to call this function
        - transaction at _txIndex must exist
        - transaction at _txIndex must be executed
    2. Revoke the confirmation
        - require that msg.sender has confirmed the transaction
        - set isConfirmed to false for msg.sender
        - decrement numConfirmations by 1
        - emit RevokeConfirmation
    */
    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.isConfirmed[msg.sender], "tx not confirmed");

        transaction.isConfirmed[msg.sender] = false;
        transaction.numConfirmations -= 1;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function isConfirmed(uint _txIndex, address _owner)
        public
        view
        returns (bool)
    {
        Transaction storage transaction = transactions[_txIndex];

        return transaction.isConfirmed[_owner];
    }
}