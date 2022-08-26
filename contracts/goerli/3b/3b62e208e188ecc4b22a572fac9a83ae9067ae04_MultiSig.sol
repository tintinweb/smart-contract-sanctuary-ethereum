/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MultiSig {
    
    address private Owner;
    address[] private Owners;
    uint sign;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }
    Transaction[] public Transactions;
    mapping(address=>bool) isOwner;
    mapping(uint => mapping(address => bool)) public isConfirmed;
    constructor(address[] memory _Owner ,uint _sign) {
       sign=_sign;
       Owner=msg.sender;
        for(uint i ;i<_Owner.length;i++){
            isOwner[_Owner[i]]=true;
            Owners.push(_Owner[i]);
        }
    }

    modifier onlyOwner(){
        require(msg.sender==Owner || isOwner[msg.sender],"NOT Owner");
        _;
    }
  
   
   function send( address _to,uint _value) public onlyOwner  {
        Transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: abi.encodeWithSignature("send(address,uint)",_to,_value),
                executed: false,
                numConfirmations: 0
            })
        );
   }

   receive() external payable {}
   function confirmTransaction(uint _txIndex) public onlyOwner
    {
        Transaction storage transaction = Transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

    }

    function executeTransaction(uint _txIndex) public onlyOwner{
        
        Transaction storage transaction = Transactions[_txIndex];

        require( transaction.numConfirmations >= sign);

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success);
    }

    function getBl()public view returns(uint){
        return msg.sender.balance;
    }


}