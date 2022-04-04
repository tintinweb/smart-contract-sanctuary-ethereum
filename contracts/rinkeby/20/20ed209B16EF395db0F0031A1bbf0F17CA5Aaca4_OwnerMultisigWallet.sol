// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
* @dev interface to interact with the reward and treasury pool
*/
interface Pool {
    function addTeamMember(address _addr) external;
    function removeTeamMember(address _addr) external;
    function changeNumberConfirmations(uint _numConfirmations) external;
}

contract OwnerMultisigWallet {

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
    event TransactionDeclined(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    Pool public rewardPool;
    Pool public treasuryPool;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        bool declined;
        uint numConfirmations;
        uint numDeclined;
        uint txnType;

    }

    // mapping from tx index => owner => bool, to check if the owner has accepted a proposed transaction
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // mapping from tx index => owner => bool, to check if the owner has declined a proposed transaction
    mapping(uint => mapping(address => bool)) public isDeclined;

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

    modifier hasNotConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier hasNotDeclined(uint _txIndex) {
        require(!isDeclined[_txIndex][msg.sender], "tx already declined");
        _;
    }

    modifier notDeclined(uint _txIndex) {
        require(!transactions[_txIndex].declined, "tx is declined");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired, address _rewardPool, address _treasuryPool) {
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

        rewardPool = Pool(_rewardPool);
        treasuryPool = Pool(_treasuryPool);
    }

    /**
    * @dev propose a transaction, will only execute if the proposal recieves enough votes
    * Requires the caller to be a owner/team member
    * @notice _txnType determines if the proposal is a external encoded transaction, or if its to manage internal state of the contract
    */
    function submitTransaction(
        address _to,
        uint _value,
        bytes calldata _data,
        uint _txnType
    ) external onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                declined: false,
                numConfirmations: 1,
                numDeclined: 0,
                txnType : _txnType
            })
        );

        isConfirmed[txIndex][msg.sender] = true;

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /**
    * @dev A team member votes that a proposed transaction should execute, if enough votes have been reached this call will execute the transaction
    */
    function confirmTransaction(uint _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        hasNotConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);

        if(transaction.numConfirmations >= numConfirmationsRequired && !transaction.declined) {
            executeTransaction(_txIndex);
        }
    }

    /**
    * @dev Executes a valid transaction
    */
    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notDeclined(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        uint txnType = transaction.txnType;

        ///@notice if the transaction type is 0, then this is an external transaction
        if(transaction.txnType == 0) {

            (bool success, ) = transaction.to.call{value: transaction.value}(
                transaction.data
            );
            require(success, "tx failed");

        } 
        ///@notice this transaction will either add or remove remove a team member, or update confirmations required to execute a transaction
        else if(txnType == 1) {

            removeTeamMember(transaction.to);

        }

        else if(txnType == 2) {

            addTeamMember(transaction.to);

        } else {

            changeNumberConfirmations(transaction.value);

        }

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /**
    * @dev Team member cancels their confirmation
    */
    function revokeConfirmation(uint _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }


    /**
    * @dev Votes no on a transaction, if enough have voted no then it invalidates the transaction, preventing it from executing
    */
    function declineTransaction(uint _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        hasNotDeclined(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        transaction.numDeclined += 1;
        isDeclined[_txIndex][msg.sender] = true;

        if(transaction.numDeclined >= owners.length - numConfirmationsRequired) {

            ///@notice transaction can't execute with this number of declines
            transaction.declined = true;

        }

        emit TransactionDeclined(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        external
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            bool declined,
            uint numConfirmations,
            uint numDeclined,
            uint txnType

        )
    {
        Transaction memory transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.declined,
            transaction.numConfirmations,
            transaction.numDeclined,
            transaction.txnType
        );
    }

    /**
    * @dev Removes a team member from being able to vote on/propose transactions, it will also remove the team member from the treasury and reward pool
    * @notice this is called internally by submitting and executing a txnType of 1, it will also reduce the number of confirmations required by 1
    */
    function removeTeamMember(address _addr) internal  {

        require(isOwner[_addr], "The input address is not an owner");

        require(numConfirmationsRequired > 1, "can't reduce confirmations required to zero if a team mamber is removed");

        for(uint256 i = 0; i < owners.length; i++) {
            if(owners[i] == _addr) {
                owners[i] = owners[owners.length - 1];
                delete isOwner[_addr];
                owners.pop();
                numConfirmationsRequired -= 1;
                
                break;
            }
        }

        rewardPool.removeTeamMember(_addr);
        treasuryPool.removeTeamMember(_addr);
    }

    /**
    * @dev Adds a team member allowing them to vote on/propose transactions, it will also add the team member to the treasury and reward pool
    * @notice this is called internally by submitting and executing a txnType of 2, it will also increase the number of confirmations required by 1
    */
    function addTeamMember(address _addr) internal  {
        owners.push(_addr);
        isOwner[_addr] = true;
        numConfirmationsRequired += 1;

        rewardPool.addTeamMember(_addr);
        treasuryPool.addTeamMember(_addr);
    }

     /**
    * @dev Changes the number of confirmations required to execute a proposed transaction, it will also set this for the reward and treasury pool
    * @notice this is called internally by submitting and executing a txnType of 3
    */
    function changeNumberConfirmations(uint _numConfirmations) internal {

        require(_numConfirmations <= owners.length, "Can't make it impossible to confirm");
        require(_numConfirmations > 0, "Need at least 1 confirmation");

        numConfirmationsRequired = _numConfirmations;

        rewardPool.changeNumberConfirmations(_numConfirmations);
        treasuryPool.changeNumberConfirmations(_numConfirmations);

    }

}