/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Welcome to Destiny.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

88888888ba,                                    88                            
88      `"8b                            ,d     ""                            
88        `8b                           88                                   
88         88   ,adPPYba,  ,adPPYba,  MM88MMM  88  8b,dPPYba,   8b       d8  
88         88  a8P_____88  I8[    ""    88     88  88P'   `"8a  `8b     d8'  
88         8P  8PP"""""""   `"Y8ba,     88     88  88       88   `8b   d8'   
88      .a8P   "8b,   ,aa  aa    ]8I    88,    88  88       88    `8b,d8'    
88888888Y"'     `"Ybbd8"'  `"YbbdP"'    "Y888  88  88       88      Y88'     
                                                                    d8'      
                                                                   d8'       
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Good luck.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*//*

______  ___        ___________ _____ _____________                  ___       __        ____________      _____ 
___   |/  /____  _____  /__  /____(_)__  ___/___(_)_______ _        __ |     / /______ ____  /___  /_____ __  /_
__  /|_/ / _  / / /__  / _  __/__  / _____ \ __  / __  __ `/__________ | /| / / _  __ `/__  / __  / _  _ \_  __/
_  /  / /  / /_/ / _  /  / /_  _  /  ____/ / _  /  _  /_/ / _/_____/__ |/ |/ /  / /_/ / _  /  _  /  /  __// /_  
/_/  /_/   \__,_/  /_/   \__/  /_/   /____/  /_/   _\__, /          ____/|__/   \__,_/  /_/   /_/   \___/ \__/  
                                                   /____/                                                       
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/
/*
* SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.17;
/*
*@dev
*@interface 'ERC20' used for ERC20 token transfer.
*/
interface ERC20 { function transfer(address to, uint256 value) external returns (bool); }

contract DestinyMultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
/*
*@dev Transfer Events>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        string input_data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeTransactionConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex,string input_data,string Signature);
/*
*@dev Transfer Events>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    event SubmitTransfer(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        string input_data
    );
    event ConfirmTransfer(address indexed owner, uint indexed txIndex);
    event RevokeTransferConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransfer(address indexed owner, uint indexed txIndex,string input_data,string Signature);

/*
*@dev Transaction struct>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    struct Transaction {
        address payable to;
        uint value;
        string input_data;
        bool executed;
        uint numConfirmations;
    }

/*
*@dev Transfer struct>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    struct Transfer {
        address contractAddress;
        address to;
        uint value;
        string input_data;
        bool executed;
        uint numConfirmations;
    }
/*
*@dev Signature>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    string public Signature="destinytemple.eth";
/*
*@dev public Variables>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    address[] public owners;

    uint public numConfirmationsRequired;

    mapping(address => bool) public isOwner;
/*
*@dev Transaction Variables>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/

    Transaction[] public transactions;

    /*
    *@dev  mapping from tx index => owner => bool
    */
    mapping(uint => mapping(address => bool)) public transactionIsConfirmed;

    uint public transactionCount;

 /*
 *@dev Transfer Variables>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
 */
    Transfer[] public transfers;

    mapping(uint => mapping(address => bool)) public transferIsConfirmed;

    uint public transferCount;

/*
*@dev Public modifiers>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
/*
*@dev Transaction modifiers>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    modifier TransactionExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }
    modifier TransactionNotExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
    modifier TransactionConfirmed(uint _txIndex) {
        require(transactionIsConfirmed[_txIndex][msg.sender], "msg.sender not confirm this tx");
        _;
    }
    modifier TransactionNotConfirmed(uint _txIndex) {
        require(!transactionIsConfirmed[_txIndex][msg.sender], "msg.sender already confirmed this tx");
        _;
    }
/*
*@dev Transfer modifiers>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    modifier TransferExists(uint _txIndex) {
        require(_txIndex < transfers.length, "tx does not exist");
        _;
    }
    modifier TransferNotExecuted(uint _txIndex) {
        require(!transfers[_txIndex].executed, "tx already executed");
        _;
    }
    modifier TransferConfirmed(uint _txIndex) {
        require(transferIsConfirmed[_txIndex][msg.sender], "msg.sender not confirm this tx");
        _;
    }
    modifier TransferNotConfirmed(uint _txIndex) {
        require(!transferIsConfirmed[_txIndex][msg.sender], "msg.sender already confirmed this tx");
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
/*
*@dev set Signature functions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    function setSignature(string memory newSignature) public onlyOwner returns(bool) {
        Signature=newSignature;
        return true;
    }
/*
*@dev Public view functions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    function getOwners() public view returns (address[] memory) {
        return owners;
    }
/*
*@dev Transaction event functions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    function submitTransaction(
        address _to,
        uint _value,
        string memory input_data
    ) public onlyOwner {
        transactionCount+=1;
        uint _txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: payable( _to),
                value: _value,
                input_data: input_data,
                executed: false,
                numConfirmations: 0
            })
        );

        confirmTransaction(_txIndex);

        emit SubmitTransaction(msg.sender, _txIndex, _to, _value, input_data);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        TransactionExists(_txIndex)
        TransactionNotExecuted(_txIndex)
        TransactionNotConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        transactionIsConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
        if(transaction.numConfirmations>=numConfirmationsRequired){
            executeTransaction(_txIndex);
        }
    }

    function revokeTransactionConfirmation(uint _txIndex)
        public
        onlyOwner
        TransactionExists(_txIndex)
        TransactionConfirmed(_txIndex)
        TransactionNotExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        transactionIsConfirmed[_txIndex][msg.sender] = false;

        emit RevokeTransactionConfirmation(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        TransactionExists(_txIndex)
        TransactionNotExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "tx confirm nums insufficient"
        );

        transaction.executed = true;
        bool success=transaction.to.send(transaction.value);

        require(success, "tx execute failed");

        emit ExecuteTransaction(msg.sender, _txIndex,transaction.input_data,Signature);
    }

/*
*@dev Transfer event functions>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*/
    function submitTransfer(
        address contractAddress,
        address _to,
        uint _value,
        string memory input_data
    ) public onlyOwner {
        transferCount+=1;
        uint _txIndex = transfers.length;

        transfers.push(
            Transfer({
                contractAddress: contractAddress,
                to: _to,
                value: _value,
                input_data: input_data,
                executed: false,
                numConfirmations: 0
            })
        );
        confirmTransfer(_txIndex);
        emit SubmitTransfer(msg.sender, _txIndex, _to, _value, input_data);
    }

    function confirmTransfer(uint _txIndex)
        public
        onlyOwner
        TransferExists(_txIndex)
        TransferNotExecuted(_txIndex)
        TransferNotConfirmed(_txIndex)
    {
        Transfer storage transfer = transfers[_txIndex];
        transfer.numConfirmations += 1;
        transferIsConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransfer(msg.sender, _txIndex);
        if(transfer.numConfirmations>=numConfirmationsRequired){
            executeTransfer(_txIndex);
        }
    }
    
    function revokeTransferConfirmation(uint _txIndex)
        public
        onlyOwner
        TransferExists(_txIndex)
        TransferNotExecuted(_txIndex)
    {
        Transfer storage transfer = transfers[_txIndex];

        require(transferIsConfirmed[_txIndex][msg.sender], "tx not confirmed ");

        transfer.numConfirmations -= 1;
        transferIsConfirmed[_txIndex][msg.sender] = false;

        emit RevokeTransferConfirmation(msg.sender, _txIndex);
    }

    function executeTransfer(uint _txIndex)
        public
        onlyOwner
        TransferExists(_txIndex)
        TransferNotExecuted(_txIndex)
    {
        Transfer storage transfer = transfers[_txIndex];

        require(transfer.numConfirmations >= numConfirmationsRequired,"tx confirm nums insufficient");

        transfer.executed = true;

        ERC20 erc20Token = ERC20(transfer.contractAddress);
        
        bool success =erc20Token.transfer(transfer.to, transfer.value);

        require(success, "transfer failed");

        emit ExecuteTransfer(msg.sender, _txIndex,transfer.input_data,Signature);
    }
}
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Welcome to Destiny.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

88888888ba,                                    88                            
88      `"8b                            ,d     ""                            
88        `8b                           88                                   
88         88   ,adPPYba,  ,adPPYba,  MM88MMM  88  8b,dPPYba,   8b       d8  
88         88  a8P_____88  I8[    ""    88     88  88P'   `"8a  `8b     d8'  
88         8P  8PP"""""""   `"Y8ba,     88     88  88       88   `8b   d8'   
88      .a8P   "8b,   ,aa  aa    ]8I    88,    88  88       88    `8b,d8'    
88888888Y"'     `"Ybbd8"'  `"YbbdP"'    "Y888  88  88       88      Y88'     
                                                                    d8'      
                                                                   d8'       
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Good luck.<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<*//*

______  ___        ___________ _____ _____________                  ___       __        ____________      _____ 
___   |/  /____  _____  /__  /____(_)__  ___/___(_)_______ _        __ |     / /______ ____  /___  /_____ __  /_
__  /|_/ / _  / / /__  / _  __/__  / _____ \ __  / __  __ `/__________ | /| / / _  __ `/__  / __  / _  _ \_  __/
_  /  / /  / /_/ / _  /  / /_  _  /  ____/ / _  /  _  /_/ / _/_____/__ |/ |/ /  / /_/ / _  /  _  /  /  __// /_  
/_/  /_/   \__,_/  /_/   \__/  /_/   /____/  /_/   _\__, /          ____/|__/   \__,_/  /_/   /_/   \___/ \__/  
                                                   /____/                                                       
/*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>*/