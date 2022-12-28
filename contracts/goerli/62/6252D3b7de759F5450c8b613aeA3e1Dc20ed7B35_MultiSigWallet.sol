/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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
        bool expired;
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

    modifier notExpired(uint _txIndex) {
        require(!transactions[_txIndex].expired, "tx already expired");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
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

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

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
        expired: false,
        numConfirmations: 0
        })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notExpired(_txIndex)
    notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function confirmAllTransaction() public onlyOwner
    {
        for(uint i = 0; i < transactions.length; i++){
            if(transactions[i].executed != true && transactions[i].expired != true){
                confirmTransaction(i);
            }
        }
    }

    function cancelSubmitTransaction(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notExpired(_txIndex)
    {
        transactions[_txIndex].expired = true;
    }


    function revokeConfirmation(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notExpired(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        //return transactions.length;
        uint j = 0;
        for(uint i = 0; i<transactions.length; i++){
            if(transactions[i].expired != true){
                j++;
            }
        }
        return j;
    }

    function getUnExcuteTransactionCount() public view returns (uint) {
        uint j = 0;
        for(uint i = 0; i<transactions.length; i++){
            if(transactions[i].executed != true){
                j++;
            }
        }
        return j;

    }

    function getTransaction(uint _txIndex)
    public
    view
    returns (
        address to,
        uint value,
        bytes memory data,
        bool executed,
        bool expired,
        uint numConfirmations
    )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
        transaction.to,
        transaction.value,
        transaction.data,
        transaction.executed,
        transaction.expired,
        transaction.numConfirmations
        );
    }

    function getTotalSendingAmount(uint256[] memory _amounts) private pure returns (uint totalSendingAmount) {
        for (uint i = 0; i < _amounts.length; i++) {
            require(_amounts[i] > 0);
            totalSendingAmount += _amounts[i];
        }
    }

    function submitMultiTransaction(address[] memory receivers, uint256[] memory amounts) public onlyOwner {
        uint txIndex = transactions.length;

        //require(msg.value != 0 && msg.value >= getTotalSendingAmount(amounts));
        for (uint256 j = 0; j < amounts.length; j++) {
            address payable receiver = payable(receivers[j]);

            transactions.push(
                Transaction({
            to: receiver,
            value: amounts[j],
            data: "0x0",
            executed: false,
            expired: false,
            numConfirmations: 0
            })
            );
            emit SubmitTransaction(msg.sender, txIndex, receiver, amounts[j], "0x0");
        }

    }
}