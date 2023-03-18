/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract MultiSigWallet {

    /*
     * Data types and variables
     */

    string constant public login = "xklusa14";
    uint constant public MAX_OWNER_COUNT = 10;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);

    event NotEnoughBalance(uint curBalance, uint requestedBalance);

    struct Transaction {
        address destination; // receiver of crypto-tokens (Ether) sent
        uint value; // amount to sent from contract
    }

    mapping (uint => Transaction) public transactions; // Mapping of Txn IDs to Transaction objects
    mapping (uint => mapping (address => bool)) public signatures; // Mapping of Txn IDs to owners who already signed them
    mapping (address => bool) public isOwner;

    address[] public owners; // all possible signers of each transaction
    uint public minSignatures; // minimum number of signatures required for execution of each transaction
    uint public transactionCount;


    /*
     * Modifiers serve as macros in C - they are substitued to the place of usage, while placeholder "_" represents the body of the function that "calls" them
     */

    modifier checkValidSettings(uint ownerCount, uint _requiredSigs) {
        // TASK: replace the body of this modifier to fit n-of-m multisig scheme while you verify:
        //  1) the maximum number of owners,
        //  2) whether required signatures is not 0 or higher than MAX_OWNER_COUNT
        //  3) the number of owners is not 0

        if(ownerCount > MAX_OWNER_COUNT){
            revert("The maximum number of owners is 10.");
        }
        if(_requiredSigs == 0 || _requiredSigs > MAX_OWNER_COUNT){
            revert("The minimum number of signatures is 1 and the maximum is 10.");
        }
        if(ownerCount == 0){
            revert("The number of owners is 0.");
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

    // If the transaction by an owner does not exist and the owner is not an owner of the contract, revert the transaction -- replay attack
    modifier checkReplayAttack(uint transactionId, address owner){
        if(!signatures[transactionId][owner]){
            if(!isOwner[owner]){
                revert("Replay attack detected.");
            }
        }
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
        // TASK 2: Modify this constructor to fit n-of-m scheme, i.e., an arbitrary number of owners and required signatures (max. is MAX_OWNER_COUNT)
        // do not allow repeating addresses or zero addresses to be passed in _owners

        // Checks for repeated addresses and zero addresses
        for(uint i = 0; i < _owners.length; i++){
            checkNotNull(_owners[i]);
            for(uint j = i + 1; j < _owners.length; j++){
                if(_owners[i] == _owners[j]){
                    revert("A repeated owner passed.");
                }
            }
        }

        checkNotNull(_owners[0]);
        checkNotNull(_owners[1]);

        if(_owners[0] == _owners[1]){
            revert("A repeated owner passed.");
        }

        // save owners (m) and the minimum number of signatures (n) to the storage variables of the contract
        isOwner[_owners[0]] = true;
        isOwner[_owners[1]] = true;
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
        checkReplayAttack(transactionId, msg.sender)
    {
        // TASK 3: check whether the contract has enough balance and if not emit a new event called NotEnoughBalance(curBalance, requestedBalance)

        if (isTxConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];

            if(address(msg.sender).balance < txn.value){
                emit NotEnoughBalance(address(this).balance, txn.value);
            }

            if (payable(address(uint160(txn.destination))).send(txn.value)){ // sending the Ether to destination address
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


    // TASK 4: write a public read-only (not modifying the state) function that retrieves addresses of owners who signed a passed transaction

    /// @dev Returns array with owners that confirmed a transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getOwnersWhoSignedTx(uint transactionId)
        public view returns (address[] memory)
    {
        // Create array, it is easier to create is same size as owners array
        // and then fill it with addresses of owners who signed the transaction,
        // than to compute its length first and then fill it
        address[] memory ownersWhoSignedTx = new address[](owners.length);

        // Fill array with owners who signed the transaction
        for (uint i = 0; i < owners.length; i++) {
            if (signatures[transactionId][owners[i]]) {
                ownersWhoSignedTx[i] = owners[i];
            }
        }
        return ownersWhoSignedTx;
    }
}