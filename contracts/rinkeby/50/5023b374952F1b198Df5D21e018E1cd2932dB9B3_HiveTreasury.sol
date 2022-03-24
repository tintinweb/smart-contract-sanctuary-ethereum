// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract HiveTreasury {

    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed to,
        uint indexed txIndex,
        uint value
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event TransactionDeclined(address indexed owner, uint indexed txIndex);

    address[] public owners;
    address public admin;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        address tokenAddress;
        uint value;
        uint numConfirmations;
        uint numDeclined;
        bool executed;
        bool declined;
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

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
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

     modifier hasNotDeclined(uint _txIndex) {
        require(!isDeclined[_txIndex][msg.sender], "tx already declined");
        _;
    }

    modifier notDeclined(uint _txIndex) {
        require(!transactions[_txIndex].declined, "tx is declined");
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

        admin = msg.sender;
        numConfirmationsRequired = _numConfirmationsRequired;
        
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    modifier checkBalance(uint value, address _tokenAddress) {
        if(_tokenAddress == address(0)) {
            require(address(this).balance >= value, "Insufficient matic balance");
        } else {
            require(IERC20(_tokenAddress).balanceOf(address(this)) >= value, "Insufficient token balance");
        }

        _;
    }


    /**
    * @dev propose a transaction, will only execute if the proposal recieves enough votes
    * Requires the caller to be a owner/team member
    * @notice _tokenAddress is the address of the erc 20 token to use in the transaction, if _tokenAddress is the zero address it will send matic
    */
    function submitTransaction(
        uint _value,
        address _tokenAddress
    ) public onlyOwner checkBalance(_value, _tokenAddress) {

        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: msg.sender,
                tokenAddress : _tokenAddress,
                value: _value,
                numConfirmations: 1,
                numDeclined: 0,
                executed: false,
                declined: false
            })
        );

        isConfirmed[txIndex][msg.sender] = true;
        emit SubmitTransaction(msg.sender, txIndex, _value);
    }

    /**
    * @dev Transfers ownership of the contract
    * @notice ownership will be transfered to the Owner Multisig, and will allow it to update the state of the contract
    */
    function TransferOwnership(address Admin) public onlyAdmin{
        admin=Admin; 
    }

    /**
    * @dev A team member votes that a proposed transaction should execute, if enough votes have been reached this call will execute the transaction
    */
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

        if(transaction.numConfirmations >= numConfirmationsRequired && !transaction.declined) {
            executeTransaction(_txIndex);
        }
    }

    /**
    * @dev Executes a valid transaction
    */
    function executeTransaction(uint _txIndex)
        private
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notDeclined(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require( isOwner[transaction.to], "To address is not the owner!");

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        if(transaction.tokenAddress == address(0)) {
            require(address(this).balance >= transaction.value, "Insufficient matic balance to withdraw");
            payable(transaction.to).transfer(transaction.value);
        } else {
            IERC20 token = IERC20(transaction.tokenAddress);
            require(token.balanceOf(address(this)) >= transaction.value, "Insufficient token balance to withdraw");
            token.transfer(transaction.to, transaction.value);
        }

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /**
    * @dev Votes no on a transaction, if enough have voted no then it invalidates the transaction, preventing it from executing
    */
    function declineTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        hasNotDeclined(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        transaction.numDeclined += 1;
        isDeclined[_txIndex][msg.sender] = true;

        if(transaction.numDeclined >= owners.length - numConfirmationsRequired) {

            ///@notice transaction can't execute with this number of declines, so it is invalidated and can no longer be executed
            transaction.declined = true;

        }

        emit TransactionDeclined(msg.sender, _txIndex);
    }

    /**
    * @dev Adds a team member allowing them to vote on/propose transactions, this is called by the Owner multisig 
    * @notice it will also increase the number of confirmations required by 1
    */
    function addTeamMember(address _addr) public onlyAdmin {
        owners.push(_addr);
        isOwner[_addr] = true;
        numConfirmationsRequired += 1;
    }

    /**
    * @dev Removes a team member from being able to vote on/propose transactions, this is called by the Owner multisig
    * @notice it will also reduce the number of confirmations required by 1
    */
    function removeTeamMember(address _addr) public onlyAdmin {
        require(isOwner[_addr], "The input address is not an owner");

        for(uint256 i = 0; i < owners.length; i++) {
            if(owners[i] == _addr) {
                owners[i] = owners[owners.length - 1];
                delete isOwner[_addr];
                owners.pop();
                numConfirmationsRequired -= 1;
                break;
            }
        }
    }


    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            address tokenAddress,
            uint value,
            uint numConfirmations,
            uint numDeclined,
            bool executed,
            bool declined
        )
    {
        Transaction memory transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.tokenAddress,
            transaction.numConfirmations,
            transaction.numDeclined,
            transaction.value,
            transaction.executed,
            transaction.declined
        );
    }

    /**
    * @dev Changes the number of confirmations required to execute a proposed transaction, this is called by the Owner multisig
    */
    function changeNumberConfirmations(uint _numConfirmations) public onlyAdmin {

        require(_numConfirmations <= owners.length, "Can't have more confirmations required than number of owners");

        numConfirmationsRequired = _numConfirmations;

    }
}