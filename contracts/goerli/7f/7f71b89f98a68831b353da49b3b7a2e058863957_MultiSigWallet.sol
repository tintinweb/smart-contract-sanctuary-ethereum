/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.1 < 0.9.0;

contract MultiSigWallet {

    uint public confirmRequestRequired;
    mapping(address => bool) exsitingOwners; 
    mapping(uint => mapping(address => bool)) public transactionConfirmations;

    struct Transaction {
        address payable to;
        uint amount; 
        uint priority;
        uint hasConfirmRequests;
        bool isExcuted;
        uint id;
    }

    Transaction[] public transactions;

    constructor(address[] memory _owners, uint _requiredConfirmationNumber) payable{
        require(_owners.length > 0, "has no owners");
        require(_requiredConfirmationNumber > 0, "Required no of confirmations should be greater then 1");
        require(_requiredConfirmationNumber > 0, "Required no of confirmations can not be greater than no of owners");

        for(uint i=0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!exsitingOwners[owner], "Owner is not unique");

            exsitingOwners[owner] = true;
        }

            confirmRequestRequired = _requiredConfirmationNumber;
    }

    modifier onlyOwnerCanExecute() {
        require(exsitingOwners[msg.sender], "Owner does not exist");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    function submitTransaction(address payable _to, uint _amount)
    public
    onlyOwnerCanExecute
    validAddress(_to) {

        transactions.push(Transaction({
            to: _to,
            amount: _amount,
            priority: 0,
            isExcuted: false,
            hasConfirmRequests: 0,
            id: transactions.length
        }));
    }

    function confirmTransaction(uint txIndex)
    public
    onlyOwnerCanExecute
    validAddress(msg.sender) {
        require(txIndex < transactions.length, "Transaction does not exist");

        Transaction storage transaction = transactions[txIndex];

        require(!transaction.isExcuted , "Already excuted");

        require(!transactionConfirmations[txIndex][msg.sender], "Owner already confirmed it");
        
        transactionConfirmations[txIndex][msg.sender] = true;

        transaction.hasConfirmRequests += 1;
        transaction.priority += 1;
    }

    function executeTransactions(uint[] memory txs)
    public
    payable
    onlyOwnerCanExecute
    validAddress(msg.sender) {
        for(uint i; i < txs.length; i++) {
            Transaction storage transaction = transactions[i];
            require(!transaction.isExcuted, "Already excuted");
            require(transaction.hasConfirmRequests >= confirmRequestRequired, "Can not execute");

            (bool success, ) = transaction.to.call{value: transaction.amount}("");
            require(success, "Transaction can not be excuted");

            if(success) {
                transaction.isExcuted = true;
            }
        }
    }

}

// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db","0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB"], 3

// 0x17F6AD8Ef982297579C203069C1DbfFE4348c372, 4000
// 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7, 8000