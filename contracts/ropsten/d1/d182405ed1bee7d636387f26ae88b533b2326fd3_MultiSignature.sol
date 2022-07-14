/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MultiSignature {
    event Deposit (address indexed sender , uint amount);
    event Submit (uint indexed txId);
    event Approve (address indexed owner , uint indexed txId);
    event Revoke (address indexed owner , uint indexed txId);
    event Execute (uint indexed txId);

    struct Transections {
        address to;
        uint value;
        bytes data ;
        bool executed;
    }
    


    address[] public owners ;

    mapping (address => bool) public isOwner;
    uint public required;
    Transections [] public transactions;
    mapping (uint => mapping (address => bool)) public approved;

    modifier onlyOwner {
        require (isOwner[msg.sender] , "Not Owner ");
        _;
    } 
    modifier txExists(uint _txId) {
        require (_txId < transactions.length , " tx does not exists");
         _;
    }

    modifier notApproved (uint _txId) {
        require(!approved[_txId][msg.sender] , "tx alrady approved");
        _;
    }
    modifier notExecuted (uint _txId) {
        require (!transactions[_txId].executed , "tx already executed "); 
        _;
    }

    constructor (address[] memory _owners , uint _required) {
        require(_owners.length >0 , "owners required");
        require(_required >0 && _required <= _owners.length , 
        "invalid required numbers of owners ");
     
      for (uint i ; i < _owners.length ; i++) {
          address owner = _owners[i];
          require(owner != address (0),"invalid owner" );
          require(!isOwner[owner] , "owner is not unique");
          isOwner[owner] = true;
          owners.push(owner);

          required = _required;

      }
       
    }

    receive () external payable {
        emit Deposit (msg.sender , msg.value );
    }

    function submit (address _to , uint _value , bytes calldata _data  ) external onlyOwner{
        transactions.push(Transections({
            to : _to, 
            value : _value,
            data : _data,
            executed : false
        }));
        emit Submit (transactions.length - 1);

    }

    function approve (uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve (msg.sender , _txId);

    }

    function _getApprovalCount (uint _txId) private view returns (uint count) {
        for (uint i ; i < owners.length ; i++) {
            if (approved[_txId][owners[i]] ) {
                count += 1;
            }
        }
        return count ;

    }
    function execute (uint _txId) external txExists(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required);
        Transections storage transection = transactions[_txId];
        transection.executed = true;
      (bool success, ) =   transection.to.call{value : transection.value}(transection.data);
      require(success , "tx failed");

      emit Execute (_txId);
    }

    function revoke (uint _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
         require (approved[_txId][msg.sender] , "tx not approved");
         approved[_txId][msg.sender] = false;
         emit Revoke (msg.sender , _txId );
    }

    
}