//SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

contract MultiSigWallet{
    event Deposit (address indexed sender, uint amount);
    event Submit (uint indexed txId);
    event Approve (address indexed owner, uint indexed txId);
    event Revoke (address indexed owner, uint indexed txId);
    event Execute (uint indexed txId);
                    
    struct Transaction{
        address to;
        uint value; //Amount of eth needed to be sent
        bytes data; 
        bool executed; //Transaction is executed > True
    }
    address [] public owners; //Store address in an array
    mapping (address => bool) public isOwner; //The address is owner? Yes > true
    uint public required; //Number of approve required to approve a transaction
    Transaction [] public transactions; //Store the Transaction (struct) into array (transactions)

    mapping (uint => mapping (address => bool)) public approved; //Each transactions can be executed if pass the vote

    //Insert the owners and required no. of approve
    constructor (address [] memory _owners, uint _required){ //Addresses of owners and the required approve of owner
        require (_owners.length > 0, "owners required"); //Need at least one owner. 
                                                         //_owners.length means number of data (owners) in the array
        require (_required > 0 && _required <= _owners.length,
        "invalid required number of owners");

        for (uint i; i < _owners.length; i++) {
            address owner = _owners[i]; //The owner is the data in the _owners array
            require (owner != address (0), "invalid owner");
            require (!isOwner [owner], "owner is not unique"); //Owner needed to be unique. Make sure owner is not inserted into the isOwner mapping yet
            
            
            isOwner[owner] = true; //the owner in isOwner mapping become true
            owners.push(owner); //push owner into owners array
        }
        required = _required;
    } 

    receive() external payable { //This contract can receive Eth
        emit Deposit (msg.sender, msg.value);
    }

    function submit(address _to, uint _value, bytes calldata _data) external onlyOwner
    {
        transactions.push (Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit (transactions.length -1); //txId start from zero, same as array index
    }

    modifier onlyOwner () {
        require (isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txId){
        require(_txId < transactions.length, "tx does not exist"); // In 3 transaction, txId is 0,1,2 and length is 3, so txId must < length
        _;
    }

    modifier notApproved (uint _txId){
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed"); //require (要true先pass)
        _;
    }

    function approve(uint _txId)
    external 
    onlyOwner //Have different owners
    txExists(_txId)
    notApproved(_txId)
    notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount (uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; i++) {
            if (approved [_txId][owners[i]]) {  
                count += 1;
                //no need to type "return count" here.
            } 
        }
    }

    function execute (uint _txId) external txExists(_txId) notExecuted (_txId) {
        require(_getApprovalCount (_txId) >= required, "approvals < required");
        Transaction storage transaction = transactions[_txId]; //New variable -> transaction becomes the same type (struct) as Transaction

        transaction.executed = true;

        (bool success, ) = transaction.to.call {value: transaction.value} (
            transaction.data  //Syntax
        );
        require (success, "tx failed");

        emit Execute(_txId);
    }
    
    function revoke(uint _txId) 
    external 
    onlyOwner 
    txExists(_txId) 
    notExecuted(_txId)
{
    require(approved[_txId][msg.sender], "tx not approved");
    approved[_txId][msg.sender] = false;
    emit Revoke(msg.sender, _txId);
}

    function showBalancec() external view returns(uint){
        return address(this).balance;
    }
}