// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/// @title The Classroom contract
/// @author Wilman D. Vinueza
/// @notice I modified this contract from the example Multisig provided by Smart Contract Programmer, he is awesome.
contract Classroom {
    
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex 
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address payable[] public owners;

    uint public numOfParticipants = 3;
    uint public numConfirmationsRequired = 2;
    uint public sessions;
    uint public reward;
    address public classroomAddress = address(this);

    mapping(address => bool) public isOwner;

    struct Transaction {
        /*address to;
        uint value;
        bytes data;*/
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

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
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address payable _address, uint _sessions) {
        owners.push(_address);
        isOwner[_address] = true;
        sessions = _sessions;
    }

    function submitTransaction() public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                /*to: _to,
                value: _value,
                data: _data,*/
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex);
    }


    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }
   

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

        require(owners.length>0,"There are no participants in the classroom");
        reward = address(this).balance/(owners.length*sessions);
        
        for (uint i = 0; i < owners.length; i++) {
            (bool sent, ) = owners[i].call{value: reward}("");
            require(sent, "Failed to send Ether");
        }
        
        
        /*
        (bool sent, ) = owners[0].call{value: reward}("");
        require(sent, "Failed to send Ether");
        */

        transaction.executed = true;
        
        emit ExecuteTransaction(msg.sender, _txIndex);
    }


    function revokeConfirmation(uint _txIndex)
        public
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

    function register() public {
        require(owners.length < numOfParticipants, "class is full");
        require(!isOwner[msg.sender], "owner not unique");

        owners.push(payable(msg.sender));
        isOwner[msg.sender] = true;
    }

    function getParticipants() public view returns (address payable[] memory) {
        return owners;
    }

    function getBalance() public view returns (uint){
        return address(this).balance;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.executed,
            transaction.numConfirmations
        );
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }


    
}