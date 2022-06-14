/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
//@ title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
contract MultiSigWallet{
    uint public MAX_OWNERS = 25;
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping(address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public requiredConfirmations;
    uint public transactionCount;
    // transaction
    struct Transaction{
        address destination;
        uint value;
        bytes data;
        bool executed;
    }
    modifier onlyWallet (){
        require(msg.sender == address(this),"Not owner");
        _;
    }
    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "Owner exists");
        _;
    }
    modifier ownerExists(address owner){
        require(isOwner[owner], "Owner not exits");
        _;
    }
    modifier transactionExists(uint transactionId){
        require(transactions[transactionId].destination != address(0), "Transaction does not exists");
        _;
    }
    modifier confirmed(uint transactionId, address owner){
        require(confirmations[transactionId][owner],"Transaction not confirmed!");
        _;
    }
    modifier notConfirmed(uint transactionId, address owner){
        require(!confirmations[transactionId][owner],"Transaction confirmed!");
        _;
    }
    modifier notExecuted(uint transactionId){
        require(!transactions[transactionId].executed,"Transaction already executed!");
        _;
    }
    modifier notNull(address _address){
        require(_address != address(0),"Invalid address");
        _;
    }
     modifier validRequirement(uint ownerCount, uint _required) {
        require(_required > 0 && ownerCount > 0, "Not valid params");
        require(ownerCount < MAX_OWNERS,"Owner count invalid");
        require(_required < ownerCount, "Invalid required value");
        _;
    }
    /// @dev Fallback function allows to deposit ether.
    receive() external payable{
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }
    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required)  validRequirement(_owners.length, _required) {
        for (uint i=0; i<_owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "owner not unique");
            isOwner[owner] = true;
        }
        owners = _owners;
        requiredConfirmations = _required;
    }
    function submitTransaction(address destination, uint value, bytes memory data) public ownerExists(msg.sender) notNull(destination){
        uint transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }
    function confirmTransaction(uint transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender){
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }
    function revokeConfirmation(uint transactionId) public ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId) {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }
    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction memory trx = transactions[transactionId];
            trx.executed = true;
            (bool success, ) = trx.destination.call{value: trx.value}(trx.data);
            if (success){
                transactions[transactionId].executed = true;
                emit Execution(transactionId);
            }
            else {
                emit ExecutionFailure(transactionId);
                trx.executed = false;
            }
        }
    }
    function isConfirmed(uint transactionId) public view returns (bool) {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == requiredConfirmations)
                return true;
        }
        return false;
    }
    function getConfirmationCount(uint transactionId) public view returns (uint count){
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }
    function getTransactionCount(bool pending, bool executed) public view returns (uint count){
        for (uint i=0; i<transactionCount; i++)
            if (pending && !transactions[i].executed || executed && transactions[i].executed)
                count += 1;
    }
    function getOwners() public view returns (address[] memory){
        return owners;
    }
    function getConfirmations(uint transactionId) public view returns (address[] memory _confirmations){
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
        return _confirmations;
    }
    function getTransactionIds(uint from, uint to, bool pending, bool executed) public view returns (uint[] memory _transactionIds) {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
        return _transactionIds;
    }
}