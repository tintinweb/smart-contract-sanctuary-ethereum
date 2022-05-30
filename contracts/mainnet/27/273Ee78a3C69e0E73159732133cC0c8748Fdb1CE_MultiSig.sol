/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract IERC20 {
  function transfer(address _to, uint256 _value) public virtual returns (bool success);
  function balanceOf(address owner) public virtual view returns (uint256 balance);  
} 

contract MultiSig {

    // events
    event WalletCreated(address creator, address[] owners);
    event SubmitTransaction (address indexed owner, address indexed destination, uint id, uint value, bytes data);
    event ConfirmTransaction( address indexed owner, uint id);
    event ExecteTransaction(address indexed owner, uint id);
    event SubmitTokenTransaction(address indexed token, address indexed owner, address indexed destination, uint256 value, uint id);
    event ConfirmTokenTransaction(address indexed owner, uint256 id);
    event ExecteTokenTransaction(address indexed token, address indexed owner, uint id);

    // Types
    struct Transaction{
        uint id;
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
        address creator;
    }

    struct TokenTransaction{
        uint id;
        address token;
        address to;
        uint256 value;
        bool executed;
        uint numConfirmations;
        address creator;
    }

    address[] public  owners;
    Transaction[] transactions;
    TokenTransaction[] tokenTransactions;
    mapping(address => bool) public isOwner;
    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isTxnConfirmed;
    mapping(uint => mapping(address => bool)) public isTokenTxnConfirmed;
    uint public numConfirmationsRequired;

    constructor(uint _confirmations, address[] memory _owners) payable {
        require(_owners.length > 0, "owners required");
        require(
            _confirmations > 0 &&
                _confirmations <= _owners.length,
            "invalid number of required confirmations"
        );
         for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        
        numConfirmationsRequired = _confirmations;
        emit WalletCreated(msg.sender, _owners);
    }   

    receive() external payable {
    }

    function getOwners() public virtual view returns(address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex) public virtual view returns (uint id, address to, uint value, bytes memory data, bool executed, uint numConfirmations, address creator){
        Transaction storage transaction = transactions[_txIndex];

        return (transaction.id, transaction.to, transaction.value, transaction.data, transaction.executed, transaction.numConfirmations, transaction.creator);
    }

    function getTokenTransactionCount() public view returns (uint) {
        return tokenTransactions.length;
    }

    function getTokenTransaction(uint _txIndex) public virtual view returns (uint id, address token, address to, uint value, bool executed, uint numConfirmations){
        TokenTransaction storage tokenTransaction = tokenTransactions[_txIndex];

        return (tokenTransaction.id, tokenTransaction.token, tokenTransaction.to, tokenTransaction.value, tokenTransaction.executed, tokenTransaction.numConfirmations);
    }

    //modifier
    modifier onlyOwner(){
       require(isOwner[msg.sender],"Not owner");
       _;
    }

    modifier txExists(uint _txIndex){
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    modifier tokenTxExists(uint _txIndex){
        require(_txIndex < tokenTransactions.length);
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
    modifier notTokenTxnExecuted(uint _txIndex) {
        require(!tokenTransactions[_txIndex].executed, "tx already executed");
        _;
    }
    modifier notConfirmed(uint _txIndex) {
        require(!isTxnConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier notTokenTxnConfirmed(uint _txIndex) {
        require(!isTokenTxnConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    function submitTransaction (address _to, uint256 _value, bytes memory _data) public onlyOwner returns (bool){
        uint txIndex = transactions.length;
        transactions.push(Transaction({
            id: txIndex,
            to:_to,
            value:_value,
            data:_data,
            executed:false,
            numConfirmations:0,
            creator:msg.sender
        }));
        
        emit SubmitTransaction(msg.sender, _to, txIndex, _value, _data);
        return true;
    }

    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) returns (bool){
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations +=1;
        isTxnConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
        return true;
    }

    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) returns (bool) {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.numConfirmations >= numConfirmationsRequired, "can not execute transaction");

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value:transaction.value}(transaction.data);
        require(success,"transaction failed");
        emit ExecteTransaction(msg.sender, _txIndex);

        return true;
    }

    function submitTokenTransaction(address _token, address _to, uint256 _value) public onlyOwner returns (bool){
        uint txIndex = tokenTransactions.length;
        tokenTransactions.push(TokenTransaction({
            id: txIndex,
            token: _token,
            to: _to,
            value: _value,
            executed: false,
            creator: msg.sender,
            numConfirmations: 0
        }));
        emit SubmitTokenTransaction(_token, msg.sender, _to, _value, txIndex);
        return true;
    }

    function confirmTokenTransaction(uint _txIndex) public onlyOwner tokenTxExists(_txIndex) notTokenTxnExecuted(_txIndex) notTokenTxnConfirmed(_txIndex) returns(bool){
        TokenTransaction storage tokenTransaction = tokenTransactions[_txIndex];
        tokenTransaction.numConfirmations +=1;
        isTokenTxnConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTokenTransaction(msg.sender, _txIndex);
        return true;
    }

    function executeTokenTransaction(uint _txIndex) public onlyOwner tokenTxExists(_txIndex) notTokenTxnExecuted(_txIndex) returns(bool){
        TokenTransaction storage tokenTransaction = tokenTransactions[_txIndex];
        require(tokenTransaction.numConfirmations >= numConfirmationsRequired, "can not execute token transaction");

        uint256 tokenBal = IERC20(tokenTransaction.token).balanceOf(address(this));
        require (tokenTransaction.value <= tokenBal, "insufficient token balance");
        IERC20(tokenTransaction.token).transfer(tokenTransaction.to, tokenTransaction.value);
        tokenTransaction.executed = true;

        emit ExecteTokenTransaction(tokenTransaction.token, msg.sender, _txIndex);
        return true;
    }
}