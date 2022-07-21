/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

pragma solidity ^0.8.15;

//File: valensasWallet/voting.sol

//SPDX-License-Identifier: UNLICENSED

contract MultiSigWallet {
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    uint constant public MAX_OWNER_COUNT = 50;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    mapping (bytes32 => address) private recOwner;
    address[] public owners;
    address factoryAddress;
    uint public required;
    uint public transactionCount;
    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }
    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }
    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }
    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }
    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }
    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }
    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }
    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }
    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }
    modifier onlyFactory() {
        require(msg.sender == factoryAddress);
        _;
    }
    modifier seedLenEqualOwnerLen(uint256 x, uint256 y) {
        require(x == y);
        _;
    }
    fallback() external
        payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }
    constructor(address[] memory _owners, string[] memory _seedPharses, uint _required, address _factoryAddress)
        public
        validRequirement(_owners.length, _required)
        seedLenEqualOwnerLen(_owners.length, _seedPharses.length)
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
            isOwner[_owners[i]] = true;
            recOwner[sha256(abi.encodePacked(_seedPharses[i]))] = _owners[i];
        }
        owners = _owners;
        required = _required;
        factoryAddress = _factoryAddress;
    }
    function recover(string memory seedPhrase, address msgSender) onlyFactory() public {
        bool x = false;
        for (uint i = 0; i < owners.length; i++) {
            if (recOwner[sha256(abi.encodePacked(seedPhrase))] == owners[i]){
                x = true;
                break;
            }
        }
        if (x) {
            replaceOwner(recOwner[sha256(abi.encodePacked(seedPhrase))], msgSender);
        }
    }
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAddition(owner);
    }

    function removeOwner(address owner)
        private
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
    }


    function replaceOwner(address owner, address newOwner)
        private
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }
    
    function submitTransaction(address destination, uint value, bytes memory data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

    function executeTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

    function external_call(address destination, uint value, uint dataLength, bytes memory data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   
            let d := add(data, 32) 
            result := call(
                sub(gas(), 34710),   
                                   
                                   
                destination,
                value,
                d,
                dataLength,        
                x,
                0                  
            )
        }
        return result;
    }
    
    function isConfirmed(uint transactionId)
        public
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }
    
    function addTransaction(address destination, uint value, bytes memory data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }
    
    function getConfirmationCount(uint transactionId)
        public
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }
    
    function getTransactionCount(bool pending, bool executed)
        public
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }
    
    function getOwners()
        public
        returns (address[] memory)
    {
        return owners;
    }
    
    function getConfirmations(uint transactionId)
        public
        returns (address[] memory _confirmations)
    {
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
    }

    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        returns (uint[] memory _transactionIds)
    {
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
    }
}