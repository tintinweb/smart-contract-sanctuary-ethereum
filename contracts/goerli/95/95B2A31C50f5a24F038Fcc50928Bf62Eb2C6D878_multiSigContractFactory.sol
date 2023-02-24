/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex, uint indexed numOfCon);
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
        uint numConfirmations;
        address tokenAddr;
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
        // balance += msg.value;
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function deposit()payable external {
        emit Deposit(msg.sender, msg.value ,address(this).balance);
    }

    // function withdrawERC20(address token, address recipient, uint256 amount) public onlyOwner {
    //     require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");
    //     IERC20(token).transfer(recipient, amount);
    // }

    function balanceOfERC20(address token) public view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function submitTransaction(
        address _to,
        uint _value,
        address _tokenAddress,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0,
                tokenAddr: _tokenAddress
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

        emit ConfirmTransaction(msg.sender, _txIndex, transaction.numConfirmations);
        if(transaction.numConfirmations>= numConfirmationsRequired){
        executeTransaction(_txIndex);
        }
    }

    function executeTransaction(
        uint _txIndex
    ) private onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        if(transaction.tokenAddr == 0x0000000000000000000000000000000000000000){
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
        transaction.executed = true;
        emit ExecuteTransaction(msg.sender, _txIndex);
        return ;
        }
        require(IERC20(transaction.tokenAddr).transfer(transaction.to, transaction.value), "ERC20 Token Transfer failed");

        transaction.executed = true;
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

contract multiSigContractFactory {
    event NewContractCreation(address indexed newContract);

    struct NewContract {
        address newMultisig;
        address[] newOwners;
        uint numReq;
    }

    mapping(address => NewContract) registry;

    NewContract[] public TotalContract;

    function createContract(address[] memory _owners, uint _threshold) public {

        MultiSigWallet newContract = new MultiSigWallet(_owners, _threshold);
        TotalContract.push(
            NewContract({
                newMultisig: address(newContract),
                newOwners: _owners,
                numReq: _threshold
            })
        );
        emit NewContractCreation(address(newContract));
        for (uint i = 0; i < _owners.length; i++){
            registry[_owners[i]] = NewContract ({
                newMultisig: address(newContract),
                newOwners: _owners,
                numReq: _threshold
            });
        }
    }

    function getContractCount() public view returns (uint) {
        return TotalContract.length;
    }

    function getOwnersForContract(uint _index) public view returns (address, address[] memory) {
     NewContract storage contractInstance = TotalContract[_index];
     return (contractInstance.newMultisig, contractInstance.newOwners);
    }

     function OwnersContract(address addr) public view returns (NewContract memory) {
     return (registry[addr]);
    }

}