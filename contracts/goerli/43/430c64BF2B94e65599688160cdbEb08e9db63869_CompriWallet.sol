// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CompriWallet {
    uint public quorum;

    address[] public owners;

    mapping(address => bool) isOwner;

    mapping(uint => mapping(address => bool)) isConfirmed;

    struct Transaction {
        address to;
        uint amount;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    Transaction[] public transactions;

    event ProposedTransaction(
        address sender,
        uint txIndex,
        uint _amount,
        address to,
        bytes data
    );

    event ConfirmedTransaction(address sender, uint txIndex);

    event ExecutedTransaction(address sender, uint txIndex);

    constructor(address[] memory _owners, uint _quorum) {
        require(_owners.length >= _quorum, "multiple owners required.");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner.");
            require(!isOwner[owner], "owner not unique.");

            isOwner[owner] = true;
            owners.push(owner);
        }

        quorum = _quorum;
    }

    modifier onlyContract() {
        require(
            address(this) == msg.sender,
            "only contract can call this method."
        );
        _;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "only owner.");
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

    function propose(
        address _to,
        uint _amount,
        bytes calldata _data
    ) external onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                amount: _amount,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit ProposedTransaction(msg.sender, txIndex, _amount, _to, _data);
    }

    function confirm(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmedTransaction(msg.sender, _txIndex);
    }

    function execute(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= quorum,
            "cannot execute tx: quorum not reached."
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.amount}(
            transaction.data
        );
        require(success, "tx failed");

        emit ExecutedTransaction(msg.sender, _txIndex);
    }

    function updateOwner(address _owner, bool _isAdded) external onlyContract {
        isOwner[_owner] = _isAdded;
    }

    function changeQuorum(uint _newQuorum) external onlyContract {
        quorum = _newQuorum;
    }
}