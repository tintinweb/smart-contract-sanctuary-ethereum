/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// File: contracts/Wallet.sol


pragma solidity ^0.8.7;

contract AccessRegistory {
    address public admin;

    address[] public signatories;
    mapping(address => bool) public isSignatory;

    modifier isAdmin {
        require(msg.sender == admin, "not authorised");
        _;
    }

    constructor (address[] memory _signatories){
        require(_signatories.length > 0, "signatories required");

        admin = msg.sender;

        for (uint i = 0; i < _signatories.length; i++) {
            address signatory = _signatories[i];

            require(signatory != address(0), "invalid signatory");
            require(!isSignatory[signatory], "signatory not unique");

            isSignatory[signatory] = true;
            signatories.push(signatory);
        }
    }

    // recieves an array of signatories to add
    function addSignatories(address[] memory _signatories) external isAdmin{
        require(_signatories.length > 0, "signatories required");

        for (uint i = 0; i < _signatories.length; i++) {
            address signatory = _signatories[i];

            require(signatory != address(0), "invalid signatory");
            require(!isSignatory[signatory], "signatory not unique");

            isSignatory[signatory] = true;
            signatories.push(signatory);
        }
    }

    // renounces signatory rights of the caller of the function
    function renounceSignatory() external {
        require(isSignatory[msg.sender], "not a signatory");
        isSignatory[msg.sender] = false;
        uint index = 0;
        bool found = false;
        while(!found){
            if(signatories[index]==msg.sender){
                found = true;
            }
            index++;
        }
        signatories[index] = signatories[signatories.length - 1];
        signatories.pop();
    }

    // transfers signatories rights to the address passed to the function _to
    function transferRights(address _to) external {
        require(isSignatory[msg.sender], "not a signatory");
        require(!isSignatory[_to], "already a signatory");
        isSignatory[msg.sender] = false;
        uint index = 0;
        bool found = false;
        while(!found){
            if(signatories[index]==msg.sender){
                found = true;
            }
            index++;
        }
        isSignatory[_to] = true;
        signatories[index] = _to;
    }
}

contract MultiSigWallet is AccessRegistory{
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

    uint public percentConfirmationsRequired = 60;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isSignatory[msg.sender], "not owner");
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

    constructor (address[] memory _signatories) AccessRegistory(_signatories){}

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
            transaction.numConfirmations > (signatories.length * percentConfirmationsRequired)/100,
            "cannot execute tx"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");

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

    function getSignatories() public view returns (address[] memory) {
        return signatories;
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
}