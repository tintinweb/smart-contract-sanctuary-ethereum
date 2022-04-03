/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/treasuryGov.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITreasury{
    function withdraw(address _to, uint amount)  external returns(bool success);
}
contract treasuryGov {
//events
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        address treasury,
        uint value,
        string data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
//


    mapping(address=>bool) public isOwner;
    address[] public owners;
    uint public numConfirmationsRequired ;
    mapping(uint256=>mapping(address=>bool)) isConfirmed;
    //address immutable Treasury;
    
    struct WithdrawTX {
        address treasury;
        address to;
        uint value;
        string data;
        bool executed;
        uint numConfirmations;
    }
    WithdrawTX[] public transactions;

//modifier
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
//



    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );
        //Treasury = _Treasury;
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

  function submitTransaction(
        address _treasury,
        address _to,
        uint _value,
        string memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            WithdrawTX({
                treasury: _treasury,
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _treasury, _value, _data);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        WithdrawTX storage transaction = transactions[_txIndex];
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
        WithdrawTX storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        bool success = ITreasury(transaction.treasury).withdraw(transaction.to, transaction.value);
        require(success, "withdraw is failed");
        //call不是个好方法去调用别的合约函数
        //(bool success, ) =address(Treasury).call(abi.encodeWithSignature("withdraw(address,uint256)", transaction.to, transaction.value));

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        WithdrawTX storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }
   
}