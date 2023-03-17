/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

contract MultiSigWallet {
    /*
     * Data types and variables
     */

    uint public constant MAX_OWNER_COUNT = 10;

    string public constant login = "xhladk15";

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event NotEnoughBalance(uint balance, uint requestedBalance);
    event Deposit(address indexed sender, uint value);

    struct Transaction {
        address destination; // receiver of crypto-tokens (Ether) sent
        uint value; // amount to sent from contract
    }

    mapping(uint => address) senderNonces;
    mapping(uint => bool) public executedTransactions;
    mapping(uint => Transaction) public transactions; // Mapping of Txn IDs to Transaction objects
    mapping(uint => mapping(address => bool)) public signatures; // Mapping of Txn IDs to owners who already signed them
    mapping(address => bool) public isOwner;

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

        // if(_requiredSigs != 2 || ownerCount != 2){
        //      revert("Validation of 2-of-2 multisig setting failed");
        // }
        if (ownerCount > MAX_OWNER_COUNT) revert("Exceeded MAX_OWNER_COUNT");

        if (_requiredSigs == 0) revert("Required number of signs cannot be 0");

        if (_requiredSigs > MAX_OWNER_COUNT)
            revert(
                "Required number of signs cannot be greater than maximum owner count"
            );

        if (ownerCount == 0) revert("Owner count cannot be 0");
        _;
    }
    modifier ownerExists(address owner) {
        if (!isOwner[owner]) revert("Owner does not exist.");
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
    // modifier nameOfModifier(uint transactionId){
    //     ... body ...
    //     _;
    // }

    modifier repayCheck(uint transactionId) {
        // if (executedTransactions[transactionId])
        // revert("Transaction has already been executed");
        if (senderNonces[transactionId] != address(0x0))
            revert("Invalid nonce");
        _;
    }

    /**
     * Public functions - functions can be called by anybody, so access controll must be implemented within their bodies
     */

    /// @dev Receive function -- allows to deposit Ether by anybody just by sending the value to the address of the contract
    // 'msg.value' holds the amount of Ether sent in the current transaction and 'msg.sender' is the address of the sender of a transaction
    receive() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value); // emiting of the event is stored at the blockchain as well. So, UI knows that Ether was deposited.
        }
    }

    /// @dev Constructor of n-of-m multisig wallet. It sets initial owners (i.e., signers) and minimal required number of signatures.
    /// @param _owners List of owners.
    /// @param _requiredSigs - the minimal number of required signatures.
    constructor(
        address[] memory _owners,
        uint _requiredSigs
    ) checkValidSettings(_owners.length, _requiredSigs) {
        // TASK 2: Modify this constructor to fit n-of-m scheme, i.e., an arbitrary number of owners and required signatures (max. is MAX_OWNER_COUNT)
        // do not allow repeating addresses or zero addresses to be passed in _owners

        uint ownerCount = _owners.length;

        for (uint i = 0; i < ownerCount; i++) {
            // Check if owner address is valid
            checkNotNull(_owners[i]);

            // Check for repeated owner address
            for (uint j = i + 1; j < ownerCount - 1; j++) {
                if (_owners[i] == _owners[j])
                    revert("A repeated owner passed.");
            }
        }

        // save owners (m) and the minimum number of signatures (n) to the storage variables of the contract
        for (uint i = 0; i < ownerCount; i++) {
            isOwner[_owners[i]] = true;
        }

        owners = _owners;
        minSignatures = _requiredSigs;
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId - transaction ID.
    function submitTransaction(
        address destination,
        uint value
    ) public returns (uint transactionId) {
        transactionId = addTransaction(destination, value);
        confirmTransaction(transactionId);
        return transactionId;
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(
        uint transactionId
    )
        public
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
    function executeTransaction(
        uint transactionId
    ) public repayCheck(transactionId) {
        // TASK 3: check whether the contract has enough balance and if not emit a new event called NotEnoughBalance(curBalance, requestedBalance)
        if (isTxConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];

            if (!checkContractBalance(txn.value))
                emit NotEnoughBalance(address(this).balance, txn.value);

            if (payable(address(uint160(txn.destination))).send(txn.value)) {
                // sending the Ether to destination address
                
                senderNonces[transactionId] = msg.sender;

                emit Execution(transactionId);
                executedTransactions[transactionId] = true;
            } else {
                emit ExecutionFailure(transactionId);
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction - do we have enough signatures already?
    /// @param transactionId -- Transaction ID.
    /// @return Confirmation status: true means that TX can be executed; false - TX cannot be exectued as there are not enough signatures
    function isTxConfirmed(uint transactionId) public view returns (bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (signatures[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == minSignatures) {
                return true;
            }
        }
        return false;
    }

    function checkContractBalance(uint amount) public view returns (bool) {
        if (address(this).balance >= amount) {
            return true;
        } else {
            return false;
        }
    }

    /*
     * Internal functions - called only from inside of the smart contract
     */

    function checkNotNull(address _address) internal pure {
        if (_address == address(0x0)) {
            revert("Null address.");
        }
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @return transactionId - transaction ID.
    function addTransaction(
        address destination,
        uint value
    ) internal returns (uint transactionId) {
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
    function getSignatureCount(
        uint transactionId
    ) public view returns (uint count) {
        for (uint i = 0; i < owners.length; i++)
            if (signatures[transactionId][owners[i]]) {
                count += 1;
            }
        return count;
    }

    /// @dev Returns total number of transactions
    function getTransactionCount() public view returns (uint) {
        return transactionCount;
    }

    /// @dev Returns list of all owners.
    /// @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    // TASK 4: write a public read-only (not modifying the state) function that retrieves addresses of owners who signed a passed transaction

    /// @dev Returns array with owners that confirmed a transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getOwnersWhoSignedTx(
        uint transactionId
    ) public view returns (address[] memory) {
        address[] memory ownerSigns = new address[](minSignatures);
        uint idx_counter = 0;

        for (uint i = 0; i < owners.length; i++) {
            if (signatures[transactionId][owners[i]])
                ownerSigns[idx_counter] = owners[i];
            idx_counter++;
        }
        return ownerSigns;
    }
}