// SPDX-License-Identifier: No License
pragma solidity ^0.8.4;

// ERC20 Token
contract LoyToken {
    string  public name = "Loy Token";
    string  public symbol = "LOY";
    uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event sendTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    event sendTokenTransaction(address indexed owner, uint indexed txIndex, address indexed to, uint value, bytes data);
    event ConfirmTokenTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTokenTransaction(address indexed owner, uint indexed txIndex);
    event RevokeTokenConfirmation(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    mapping(address => bool) public isSigner;
    uint numOfConfirmationsRequired;

    struct Signer {
        address addr;
        address addedBy;
    }

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool isExecuted;
        uint numOfConfirmations;
    }

    struct TokenTransaction {
        LoyToken token;
        address to;
        uint value;
        bytes data;
        bool isExecuted;
        uint numOfConfirmations;
    }

    mapping(uint => mapping(address => bool)) public isConfirmed;
    mapping(uint => mapping(address => bool)) public isTokenConfirmed;

    Signer[] public signers;
    Transaction[] public transactions;
    TokenTransaction[] public tokenTransactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier allowOwnerAndSigner() {
        require(isOwner[msg.sender] || isSigner[msg.sender], "not an owner or signer");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].isExecuted, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    modifier txTokenExists(uint _txTokenIndex) {
        require(_txTokenIndex < tokenTransactions.length, "token tx does not exist");
        _;
    }

    modifier notTokenExecuted(uint _txTokenIndex) {
        require(!tokenTransactions[_txTokenIndex].isExecuted, "token tx already executed");
        _;
    }

    modifier notTokenConfirmed(uint _txTokenIndex) {
        require(!isTokenConfirmed[_txTokenIndex][msg.sender], "token tx already confirmed");
        _;
    }

    constructor(address[] memory _owners) {
        require(_owners.length > 0, "owners required");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numOfConfirmationsRequired = _owners.length;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function addSigner(address _addr) public onlyOwner {
        signers.push(
            Signer({
                addr: _addr,
                addedBy: msg.sender
            })
        );

        for (uint i = 0; i < signers.length; i++) {
            address signer = signers[i].addr;

            isSigner[signer] = true;
        }
    }

    function createTransaction(address _to, uint _value, bytes memory _data) public allowOwnerAndSigner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                isExecuted: false,
                numOfConfirmations: 0
            })
        );

        emit sendTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function createtokenTransaction(address _tokenAddress, address _to, uint _value, bytes memory _data) public allowOwnerAndSigner {
        uint txIndex = tokenTransactions.length;

        tokenTransactions.push(
            TokenTransaction({
                token: LoyToken(_tokenAddress),
                to: _to,
                value: _value,
                data: _data,
                isExecuted: false,
                numOfConfirmations: 0
            })
        );

        emit sendTokenTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex) public allowOwnerAndSigner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numOfConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function confirmTokenTransaction(uint _txTokenIndex) public allowOwnerAndSigner txTokenExists(_txTokenIndex) notTokenExecuted(_txTokenIndex) notTokenConfirmed(_txTokenIndex) {
        TokenTransaction storage tokenTransaction = tokenTransactions[_txTokenIndex];
        tokenTransaction.numOfConfirmations += 1;
        isTokenConfirmed[_txTokenIndex][msg.sender] = true;

        emit ConfirmTokenTransaction(msg.sender, _txTokenIndex);
    }

    function executeTransaction(uint _txIndex) public allowOwnerAndSigner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        uint majorityApprovers = ((numOfConfirmationsRequired + signers.length) * 75) / 100;
        require(transaction.numOfConfirmations >= majorityApprovers, "not enough approvers.");

        transaction.isExecuted = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function executeTokenTransaction(uint _txTokenIndex) public allowOwnerAndSigner txTokenExists(_txTokenIndex) notTokenExecuted(_txTokenIndex) {
        TokenTransaction storage tokenTransaction = tokenTransactions[_txTokenIndex];
        uint majorityApprovers = ((numOfConfirmationsRequired + signers.length) * 75) / 100;
        require(tokenTransaction.numOfConfirmations >= majorityApprovers, "not enough approvers.");

        // check whether wallet has sufficient balance to send this transaction
        uint256 balance = tokenTransaction.token.balanceOf(address(this));
        require (tokenTransaction.value <= balance, "not enough token balance");

        // Send tokens
        tokenTransaction.token.transfer(tokenTransaction.to, tokenTransaction.value);

        tokenTransaction.isExecuted = true;

        emit ExecuteTokenTransaction(msg.sender, _txTokenIndex);
    }

    function revokeConfirmation(uint _txIndex) public allowOwnerAndSigner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numOfConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function revokeTokenConfirmation(uint _txTokenIndex) public allowOwnerAndSigner txTokenExists(_txTokenIndex) notTokenExecuted(_txTokenIndex) {
        TokenTransaction storage tokenTransaction = tokenTransactions[_txTokenIndex];

        require(isConfirmed[_txTokenIndex][msg.sender], "tx not confirmed");

        tokenTransaction.numOfConfirmations -= 1;
        isTokenConfirmed[_txTokenIndex][msg.sender] = false;

        emit RevokeTokenConfirmation(msg.sender, _txTokenIndex);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getApprovers() public view returns (uint) {
        uint majorityApprovers = ((numOfConfirmationsRequired + signers.length) * 75) / 100;
        return majorityApprovers;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex) public view returns (address to, uint value, bytes memory data, bool isExecuted, uint numOfConfirmations) {
        Transaction storage transaction = transactions[_txIndex];

        return (transaction.to, transaction.value, transaction.data, transaction.isExecuted, transaction.numOfConfirmations);
    }

    function getTokenTransaction(uint _txTokenIndex) public view returns (address to, uint value, bytes memory data, bool isExecuted, uint numOfConfirmations) {
        TokenTransaction storage tokenTransaction = tokenTransactions[_txTokenIndex];

        return (tokenTransaction.to, tokenTransaction.value, tokenTransaction.data, tokenTransaction.isExecuted, tokenTransaction.numOfConfirmations);
    }
}