/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/*
*  ------------------------
*         xreinm00
*  ------------------------
*/

contract MultiSigWallet {
    
    /*
     * Data types and variables
     */ 

    uint constant public MAX_OWNER_COUNT = 10;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event NotEnoughBalance(uint curBalance, uint requestedBalance);

    struct Transaction {
        address destination;    // receiver of crypto-tokens (Ether) sent
        uint value;             // amount to sent from contract
        bool sent;              // tx collected enough signatures and was executed
    }

    mapping (uint => Transaction) public transactions;              // Mapping of Txn IDs to Transaction objects
    mapping (uint => mapping (address => bool)) public signatures;  // Mapping of Txn IDs to owners who already signed them
    mapping (address => bool) public isOwner;
    
    address[] public owners;        // all possible signers of each transaction
    uint public minSignatures;      // minimum number of signatures required for execution of each transaction
    uint public transactionCount; 


    /*
     * Modifiers serve as macros in C - they are substitued to the place of usage, while placeholder "_" represents the body of the function that "calls" them
     */

    modifier checkValidSettings(uint ownerCount, uint _requiredSigs) {
        if (ownerCount > MAX_OWNER_COUNT)
            revert("Maximum owner count was exceeded.");
        if (ownerCount == 0)
            revert("There must be at least 1 owner of the wallet.");
        if (_requiredSigs > MAX_OWNER_COUNT || _requiredSigs == 0)
            revert("Required signatures count exceeded maximum owners count or is equal to 0.");
        if (_requiredSigs > ownerCount)
            revert("There can't be more signatures required than owners themselves.");
        _;
    }
    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            revert("Owner does not exist.");
        _;
    }
    modifier txnExists(uint transactionId) {
        if (transactions[transactionId].destination == address(0))
            revert("Transaction does not exit.");
        _;
    }
    modifier confirmed(uint transactionId, address owner) {
        if (!signatures[transactionId][owner])
            revert("Confirmation of transaction by an owner does not exist.");
        _;
    }
    modifier notConfirmed(uint transactionId, address owner) {
        if (signatures[transactionId][owner])
            revert("Transaction was already confirmed.");
        _;
    }    
    
    // Protection agains Replay attack
    modifier txNotSentYet(uint transactionId){
         if (transactions[transactionId].sent)
            revert("Transaction was already sent.");
         _;
    }


    /**
     * Public functions - functions can be called by anybody, so access controll must be implemented within their bodies
     */

    /// @dev Receive function -- allows to deposit Ether by anybody just by sending the value to the address of the contract
    // 'msg.value' holds the amount of Ether sent in the current transaction and 'msg.sender' is the address of the sender of a transaction
    receive() external payable {
        if (msg.value > 0){             
            emit Deposit(msg.sender, msg.value); // emiting of the event is stored at the blockchain as well. So, UI knows that Ether was deposited.
        }
    }

    /// @dev Constructor of n-of-m multisig wallet. It sets initial owners (i.e., signers) and minimal required number of signatures.
    /// @param _owners List of owners.
    /// @param _requiredSigs - the minimal number of required signatures.
    constructor(address[] memory _owners, uint _requiredSigs)
        checkValidSettings(_owners.length, _requiredSigs)
    {        
        for (uint i = 0; i < _owners.length; i++) {
            checkNotNull(_owners[i]);
            if (isOwner[_owners[i]])                    // check for repeated owners
                revert("A repeated owner passed.");
            isOwner[_owners[i]] = true;                 // add new owner
        
        }
        // save owners (m) and the minimum number of signatures (n) to the storage variables of the contract
        owners = _owners;
        minSignatures = _requiredSigs;
    }


    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId - transaction ID.
    function submitTransaction(address destination, uint value) 
        public returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value);
        confirmTransaction(transactionId);
        return transactionId;
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public
        ownerExists(msg.sender)
        txnExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        signatures[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public
        txNotSentYet(transactionId)                
    {
        if (isTxConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];       

            if (txn.value > address(this).balance)
                emit NotEnoughBalance(address(this).balance, txn.value);

            if (payable(address(uint160(txn.destination))).send(txn.value)){ // sending the Ether to destination address
                txn.sent = true;
                emit Execution(transactionId);              
            }
            else {
                emit ExecutionFailure(transactionId);                
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction - do we have enough signatures already?
    /// @param transactionId -- Transaction ID.
    /// @return Confirmation status: true means that TX can be executed; false - TX cannot be exectued as there are not enough signatures
    function isTxConfirmed(uint transactionId) public view returns (bool)
    {
        uint count = 0;
        for (uint i = 0 ; i < owners.length ; i++) {
            if (signatures[transactionId][owners[i]]){
                count += 1;
            }
            if (count == minSignatures){
                return true;   
            }                
        }
        return false;
    }

    /*
     * Internal functions - called only from inside of the smart contract
     */
    
    function checkNotNull(address _address) internal pure {
        if (_address == address(0x0)){
            revert("Null address.");        
        }            
    }
    
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId - transaction ID.
    function addTransaction(address destination, uint value) internal returns (uint transactionId)
    {
        checkNotNull(destination);
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            sent: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
        return transactionId;
    }

    /*
     *  Public functions for DAPP client (i.e., simulated by tests)
     */
    /// @dev Returns number of signatures of a transaction.
    /// @param transactionId Transaction ID.
    /// @return count - the number of signatures.
    function getSignatureCount(uint transactionId) public view returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++)
            if (signatures[transactionId][owners[i]]){
                count += 1;
            }       
        return count;         
    }

    /// @dev Returns total number of transactions
    function getTransactionCount() public view returns (uint)
    {
        return transactionCount;
    }

    /// @dev Returns list of all owners.
    /// @return List of owner addresses.
    function getOwners()
        public view returns (address[] memory)
    {
        return owners;
    }


    /// @dev Returns array with owners that confirmed a transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getOwnersWhoSignedTx(uint transactionId) public view
        txnExists(transactionId) returns (address[] memory)
    {
        address[] memory signedOwners = new address[](getSignatureCount(transactionId));
        uint j = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (signatures[transactionId][owners[i]])
                signedOwners[j] = owners[i];
                j++;
        }
        return signedOwners;
    }
}