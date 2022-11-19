/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-16
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-15
*/


//SPDX-License-Identifier: MIT
pragma solidity ^0.4.8;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}







contract MultiSigWallet {

    address public owner;

    mapping (address => bool) public isOwner;
    address[] public owners;

 
     /*
     *  Modifiers
     */


    modifier isAdmin{
        require(owner == msg.sender);
        _;
    }
    
    modifier isManager{
        require(
            msg.sender == owner || isOwner[msg.sender]);
        _;
    }


    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }


    uint public MIN_SIGNATURES = 2;
    uint public transactionIdx;


    struct Transaction {
        address token;
        address from;
        address to;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
        bytes data;
        bool executed;
    }
    
    mapping (uint => Transaction) public transactions;
    uint[] public pendingTransactions;
 
    constructor(address _owner) public{
        owner = _owner;
    }

    event OwnershipTransferred(address owner);   
    event DepositFunds(address from, uint amount);
    event TransferFunds(address token,address to, uint amount);

    event CallTransactions(address to, uint amount,bytes data);


    event TransactionCreated(
        address token,
        address from,
        address to,
        uint amount,
        uint transactionId,
        bytes data,
        bool executed
        );
 


     /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        isAdmin
        ownerDoesNotExist(owner)

    {
        isOwner[owner] = true;
        owners.push(owner);
 
    }






    
    function addATransfer(address token, uint256 amount,bytes data) isManager public{
        transferTo(token,msg.sender, amount,data);
    }



    function transferTo(address token, address to,  uint256 amount,bytes data) isManager public{
        //require(address(this).balance >= amount);
        uint transactionId = transactionIdx++;
        
        Transaction memory  transaction;
        transaction.token = token;
        transaction.from = msg.sender;
        transaction.to = to;
        
        transaction.amount = amount;
        transaction.signatureCount = 0;
        transaction.data = data;
        transactions[transactionId] = transaction;
        pendingTransactions.push(transactionId);

        emit TransactionCreated(token,msg.sender, to, amount, transactionId,transaction.data,false);

    }
    

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addATransaction(address destination, uint256 value, bytes data)
        isManager
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);

    }



    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint256 value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {



        transactionId = transactionIdx++;
        
        Transaction memory  transaction;
        transaction.token = destination;
        transaction.from = msg.sender;
        transaction.to = destination;

        transaction.data = data;
        
        transaction.amount = value;
        transaction.signatureCount = 0;

        transactions[transactionId] = transaction;
        pendingTransactions.push(transactionId);

        emit TransactionCreated(destination,msg.sender, destination, value, transactionId,data,false); 
 
 
    }



    // call has been separated into its own function in order to take advantage
    // of the Solidity's code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas, 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }




    function getPendingTransactions() public isManager view returns(uint[]){
        return pendingTransactions;
    }
    
    function signTransaction(uint transactionId, bool isCall) public isManager{
        Transaction storage transaction = transactions[transactionId];

        Transaction storage txn = transactions[transactionId];

        require(0x0 != transaction.from);
        require(msg.sender != transaction.from,"sender  dont need");
        require(transaction.signatures[msg.sender]!=1,"signed yet");
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        
        if(transaction.signatureCount >= MIN_SIGNATURES && isCall == false ){
            //require(address(this).balance >= transaction.amount);
            //address(uint160((transaction.to))).transfer(transaction.amount);

            //bytes4 callid=bytes4(keccak256("transferFrom(address,address,uint256)"));
            bytes4 callid=bytes4(keccak256("transfer(address,uint256)"));
            transaction.token.call(callid,transaction.to,transaction.amount);

            emit TransferFunds(transaction.token,transaction.to, transaction.amount);
            transaction.executed=true;
        }


         if(transaction.signatureCount >= MIN_SIGNATURES && isCall == true ){
            
            if (external_call(txn.to, txn.amount, txn.data.length, txn.data)) {

            //if (transaction.to.call(bytes4(keccak256(txn.data)),transaction.from,transaction.amount)) {

                emit CallTransactions(transaction.from,transaction.amount, transaction.data);
                transaction.executed=true;
            }
            else {
                transaction.executed=false;

            }

            }


    }
    
    function deleteTransactions(uint transacionId) public isManager{
        uint8 replace = 0;
        for(uint i = 0; i< pendingTransactions.length; i++){
            if(1==replace){
                pendingTransactions[i-1] = pendingTransactions[i];
            }else if(transacionId == pendingTransactions[i]){
                replace = 1;
            }
        } 
        delete pendingTransactions[pendingTransactions.length - 1];
        pendingTransactions.length--;
        delete transactions[transacionId];
    }
    
    function walletBalance() public isManager view returns(uint){
        return address(this).balance;
    }

    function recoverBNB(uint256 tokenAmount) public isAdmin {
         address(msg.sender).transfer(tokenAmount);
        
    }

     function transferOwnership(address newowner ) public  isAdmin {
        emit OwnershipTransferred(newowner);
        owner = newowner;
    }



     function setMinSign(uint256 num ) public isAdmin{

        MIN_SIGNATURES = num;
 
    }    


    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        isAdmin
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (MIN_SIGNATURES > owners.length)    MIN_SIGNATURES = owners.length;

    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        isAdmin
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;

    }
	

    function () public payable{
        emit DepositFunds(msg.sender, msg.value);
    }
 

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }




}