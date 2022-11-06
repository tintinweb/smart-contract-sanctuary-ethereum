// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numApprovals;
    }

    address[] public owners;
    mapping(address=>bool) public isOwner;
    uint public required;
    uint public numTransactions;
    uint public timelock;
    uint public timeToEndLock;

    mapping(uint=>Transaction) public transactions;
    mapping(uint=> mapping(address => bool)) public appproved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "You are not the owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < numTransactions, "tx does not exist");
        _;
    }

    modifier notApproved(uint _txId) {
        require(!appproved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required,  uint _timelock) {
        require(_owners.length > 0, "owners required");
        require(_required >=0 && _required <= _owners.length, "Invalid required no of owners");

        for(uint i; i< _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner]=true;
            owners.push(owner);
        }
        required = _required;
        timelock = _timelock;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner {
        transactions[numTransactions] = Transaction(_to, _value, _data, false, 0);
        numTransactions++;
        emit Submit(numTransactions - 1);
    }

    function approve(uint _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        appproved[_txId][msg.sender] = true;
        transactions[_txId].numApprovals++;
        if(getApprovalCount(_txId) >= required){
            timeToEndLock = block.timestamp + (timelock * 1 seconds);
        }

        emit Approve(msg.sender, _txId);
    }

    function checkIfApproved(uint _txId, address _address) public view returns(bool) {
        return appproved[_txId][_address];
    }

    function getApprovalCount(uint _txId) public view returns(uint count) {
        for(uint i; i < owners.length; i++) {
            if(appproved[_txId][owners[i]]){
                count += 1;
            }
        }
    }

    function returnAllOwners() external view returns(address[] memory){
        return owners;
    }

    function setTimeLock(uint _txId) public view returns(uint) {
        require(getApprovalCount(_txId) >= required, "approvals < required");
        return block.timestamp + (timelock * 1 seconds);
    }

    function returnTime()public view returns(uint) {
        return block.timestamp;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }


    function execute(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(getApprovalCount(_txId) >= required, "approvals < required");
        require(block.timestamp >= timeToEndLock ,"not yet");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit Execute(_txId);
    }

    function revoke(uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(appproved[_txId][msg.sender], "tx not approved");
        appproved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    function getTransaction(uint id) public view returns(Transaction memory) {
        return transactions[id];
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./MultiSigWallet.sol";

contract MultiSigWalletFactory {
    MultiSigWallet[] public deployedMultiSig;
    function createNewMultiSig (address[] memory addresses, uint _required, uint _timelock) public {
        MultiSigWallet newWallet = new MultiSigWallet(addresses, _required, _timelock);
        deployedMultiSig.push(newWallet);
    }

    function returnAllWallets() external view returns(MultiSigWallet[] memory){
        return deployedMultiSig;
    }
}