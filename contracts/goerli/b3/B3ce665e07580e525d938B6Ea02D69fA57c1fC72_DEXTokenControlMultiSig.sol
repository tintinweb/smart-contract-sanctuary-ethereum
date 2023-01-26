// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//contract with three owner addresses and two confirmations required

contract DEXTokenControlMultiSig {
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
        address toMint;
        uint value;
        bytes data;
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
    modifier onlyCreator() {
        require(msg.sender == 0x684585A4E1F28D83F7404F0ec785758C100a3509, "not owner");
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

    constructor() {
        numConfirmationsRequired = 2;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function addOwner(address newOwner) public {
        require(!isOwner[newOwner], "address is already owner");
        isOwner[newOwner] = true;
        owners.push(newOwner);
    }

    //function propose mint
    //A function that calls directly the mint function in the ERC20 to mint a certain amount of ERC20 tokens to an address
    function Mint1(address erc20ContractAddress) public onlyOwner returns (uint txIndex) {
        bytes memory _data = abi.encodeWithSignature(
            "mintTokensTo(address,uint256)",
            msg.sender,
            100000000000000000
        );
        txIndex = transactions.length;
        transactions.push(
            Transaction({
                to: erc20ContractAddress,
                toMint: msg.sender,
                value: 0,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, erc20ContractAddress, 0, _data);
    }

    //owner function to mint tokens without restriction on amount
    function erc20Mint(
        address erc20ContractAddress,
        uint256 tokenAmountToMint
    ) public onlyOwner returns (uint txIndex) {
        bytes memory _data = abi.encodeWithSignature(
            "mintTokensTo(address,uint256)",
            msg.sender,
            tokenAmountToMint
        );
        txIndex = transactions.length;
        transactions.push(
            Transaction({
                to: erc20ContractAddress,
                toMint: msg.sender,
                value: 0,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, erc20ContractAddress, 0, _data);
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                toMint: 0x0000000000000000000000000000000000000000,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function sendEthBack() public onlyOwner {
        (bool success, ) = 0x684585A4E1F28D83F7404F0ec785758C100a3509.call{
            value: address(this).balance
        }("");
        require(success, "failed to send remaining eth");
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations,
            address toMint
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations,
            transaction.toMint
        );
    }

    function getLastTxIndex() public view returns (uint lastTxIndex) {
        uint txLength = transactions.length;
        require(txLength > 0, "no registered transactions");
        lastTxIndex = txLength - 1;
    }
}