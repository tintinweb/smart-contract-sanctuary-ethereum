/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract MultiSigWallet {
    
    /*
     * Data types and variables
     */ 

    uint constant public MAX_OWNER_COUNT = 10;

    event NotEnoughBalance(uint curBalance, uint requestedBalance);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);

    struct Transaction {
        address destination; // receiver of crypto-tokens (Ether) sent
        uint value; // amount to sent from contract
    }

    mapping (uint => Transaction) public transactions; // Mapping of Txn IDs to Transaction objects
    mapping (uint => mapping (address => bool)) public signatures; // Mapping of Txn IDs to owners who already signed them
    mapping (uint => bool) nonceUsedMap;
    mapping (address => bool) public isOwner;
    
    address[] public owners; // all possible signers of each transaction
    uint public minSignatures; // minimum number of signatures required for execution of each transaction
    uint public transactionCount; 


    /*
     * Modifiers serve as macros in C - they are substitued to the place of usage, while placeholder "_" represents the body of the function that "calls" them
     */

    modifier checkValidSettings(uint ownerCount, uint _requiredSigs) {
        if(_requiredSigs == 0 || _requiredSigs > MAX_OWNER_COUNT || ownerCount == 0 || ownerCount > MAX_OWNER_COUNT){
             revert("Validation of n-of-m multisig setting failed");
        }
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
    
    // TASK 1: write here a modifier that will protect against replay attacks. Call it at the correct place
    modifier alreadyExecuted(uint transactionId){           
        if (nonceUsedMap[transactionId])
            revert("Transaction was already executed.");
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
        for(uint i = 0; i < _owners.length; i++){
            checkNotNull(_owners[i]);
            for(uint j = i + 1; j < _owners.length; j++){
                if(_owners[i] == _owners[j]){
                    revert("A repeated owner passed.");
                }
            }
        }

        // save owners (m) and the minimum number of signatures (n) to the storage variables of the contract
        for(uint i = 0; i < _owners.length; i++){
            isOwner[_owners[i]] = true;
        }
        
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
            alreadyExecuted(transactionId)
    {
        if (isTxConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            address origin = msg.sender;
            uint curBalance = origin.balance;
            if( curBalance >= txn.value) {
                if (payable(address(uint160(txn.destination))).send(txn.value)){ // sending the Ether to destination address
                    nonceUsedMap[transactionId] = true;
                    emit Execution(transactionId);              
                }
                else {
                    emit ExecutionFailure(transactionId);                
                }
            } else {
                emit NotEnoughBalance(curBalance, txn.value);
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
            value: value
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
    /// @return confiremed array of owner addresses.
    function getOwnersWhoSignedTx(uint transactionId)
        public view returns (address[] memory)
    {
        // Not smart but i don't know how to create dynamic memory array :)
        uint confirmedOwnersCount = 0;
        for (uint256 j = 0; j < owners.length; j++){
            address owner = owners[j];
            if(signatures[transactionId][owner]){
                confirmedOwnersCount++;
            }
        }


        uint i = 0;
        address[] memory confirmedOwners = new address[](confirmedOwnersCount);
        for (uint256 j = 0; j < owners.length; j++){
            address owner = owners[j];
            if(signatures[transactionId][owner]){
                confirmedOwners[i] = owner;
                i++;
            }
        }

        return confirmedOwners;
    }
}