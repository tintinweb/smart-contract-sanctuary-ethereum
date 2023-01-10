// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultiMultiSignWallet {
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;
    struct Transaction {
        address  to;
        uint256 value;
        bool executed;
        bytes data;
    }
    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations ;

    constructor(address[] memory _owners, uint256 _required){
        require(_required >0, "Confirmations cann't be zero");
        require(_owners.length >= _required, "confirmations should less than owners");
        require(_owners.length >0, "owners should be greater zero");
        owners= _owners;
        required= _required;
    }

    function addTransaction(address _to,uint _value,bytes memory data) internal returns(uint transac_Id ) {
         uint transactionId= transactionCount;
          transactions[transactionId]= Transaction(_to,_value,false, data);
          transactionCount +=1;
          return transactionId;
    }

    function getConfirmationsCount (uint trans_Id) public view returns(uint _confirmations){
        uint confirmCount=0;
        for(uint i=0; i< owners.length; i++){
            if(confirmations[trans_Id][owners[i]]){
                confirmCount++;
            }
        }
        return confirmCount;
    }

    function confirmTransaction(uint trans_Id) public{
        require(isOwner(msg.sender), "You are not Owner member");
        confirmations[trans_Id][msg.sender]= true;
        if(isConfirmed(trans_Id)) {
            executeTransaction(trans_Id);
        }
    }
     function submitTransaction(address _to,uint _value,bytes memory data) external{
        uint Id= addTransaction( _to, _value,data);
        confirmTransaction(Id);
    }

    function executeTransaction(uint _Id) public{
        require(isConfirmed(_Id), "Tx can be Executed");
        Transaction storage transaction = transactions[_Id];
        (bool success,)= transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Execution Failed");
        transaction.executed=true;

    }

    function isOwner(address _address) private view returns(bool){
        for(uint i=0; i<owners.length; i++){
            if(owners[i]==_address){
                return true;
            }
            
        }
        return false;
    }

    function isConfirmed(uint _Id) public view returns(bool){
        return getConfirmationsCount(_Id)>= required;
    }

    receive() external payable {
        
    }

    
    
}