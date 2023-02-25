/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @dev Wallet defines a system to store and transact with funds secured by multiple parties.
 * Every owner (signer) has identical privledges, so that any single owner can be compromised 
 * without compromising the funds. Wallet is intended to store a single users funds, as balances
 * are not segregated within the contract.
 * 
 * Any address may deposit funds to the wallet, but withdrawing requires action from multiple
 * owners. To withdraw funds or execute any arbitrary transaction from the wallet, an owner must
 * first submit the transaction, then other owners must approve it until a custom number of 
 * approvals is met. Only after this can the transaction be executed. The required amount of 
 * approvals should always be strictly less than the amount of owners. The amount of owners should
 * be at least 2, and at most 20.
 * 
 * WARNING: Since any arbitrary transaction can be executed if approved, owners must be careful
 * to check that a submitted transaction is safe. A malicious transaction could simply steal funds
 * or possibly even corrupt the contract state. A flag is attached to every transaction so that if 
 * any owner is suspicious of its intent, they can mark this and other owners can be made aware.
 *
 * Special transactions include adding an owner, removing an owner, and changing the required 
 * amount of approvals. These transactions have special submit functions for convenience, but must
 * be approved and executed the same as any other transaction. 
 */
contract Wallet {

    // Once submitted, to, value, and data should not be changed. flagged should be set to true 
    // when an owner is suspicious of the transaction's intent, or if they know a transaction will
    // fail when executed. Setting flagged does not happen automatically, only when an owner 
    // takes initiative.  
    struct Transaction {
        address to; 
        uint value;
        bytes data;
        bool executed;
        bool flagged;
    }

    // Upper bound on owners prevents loops from causing denial of service. 
    // Too many owners increases likleyhood of one being compromised.
    uint public constant MAX_OWNERS = 20;
    
    // Every submitted transaction must be approved >= requiredApprovals before it is executed.
    uint public requiredApprovals;
    // Keeps track of whether an owner has approved a transaction. tx -> owner -> approved
    // Elements are not deleted if an owner is removed.
    mapping(uint => mapping(address => bool)) public approved;
    
    // Provides easy lookup without loops to verify an owner
    mapping(address => bool) public isOwner;
    address[] public owners;
    
    // Records every transaction submitted, none should be deleted. 
    Transaction[] public transactions; 

    error TransactionFailed();
    
    event Approval(address indexed owner, uint indexed txId);
    event Deposit(address indexed sender, uint amount);
    event Execution(uint indexed txId);
    event Flag(address indexed owner, uint indexed txId);
    event OwnerAddition(address indexed owner);
    event OwnerAdditionRequest(address indexed owner, uint indexed txId);
    event OwnerRemoval(address indexed owner);
    event OwnerRemovalRequest(address indexed owner, uint indexed txId);
    event RequirementChange(uint requiredApprovals);
    event RequirementChangeRequest(uint requiredApprovals, uint indexed txId);
    event Revocation(address indexed owner, uint indexed txId);
    event TransactionRequest(address indexed to, uint value, uint indexed txId);

    /** 
     * @dev Restricts a function that would increase the number of owners, so that owners.length
     * stays within an acceptable range. Since 0 < requiredApprovals < numOwners, numOwners >= 2.
     */
    modifier maxOwners(uint _numOwners) {
        require(_numOwners <= MAX_OWNERS, "cannot exceed 20 owners");
        _;  
    }
    
    /** 
     * @dev Prevents a function from operating on a transaction that has already been executed.
     */
    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    /** 
     * @dev Prevents a function from modifing the status of an owner that does not exist.
     */
    modifier ownerExists(address _owner) {
        require(isOwner[_owner], "not owner");
        _;
    }
    
    /** 
     * @dev Restricts a sensitive function so that only an owner may call it.
     */
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    /** 
     * @dev Protects a function that should practically be labeled internal or private. 
     * onlyWallet functions modify sensitive state, and are executed by wallet using a
     * low level call on itself. Since call() requires a function to be included in the contracts
     * ABI, these functions cannot be labeled internal or private.
     */
    modifier onlyWallet() {
        require(msg.sender == address(this), "must be called internaly");
        _;
    }

    /** 
     * @dev Prevents a function from operating on a transaction that does not exist.
     */
    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    /**
     * @dev Ensures that a new owner is not the 0 address, does not already have owner privileges, and
     * that the wallet itself does not become an owner. If wallet has owner priviledge, it could 
     * cause unexpected behavior.
     */
    modifier validOwner(address _owner) {
        require(_owner != address(0), "invalid owner");
        require(!isOwner[_owner], "duplicate owner");
        require(_owner != address(this), "wallet cannot be owner");
        _;
    }

    /**
     * @dev Restricts a function that would modify requiredApprovals or decrement owners.length 
     * so that values stay in desired range.
     */
    modifier validRequiredApprovals(uint _numOwners, uint _requiredApprovals) {
        require(
            _requiredApprovals > 0 
            && _requiredApprovals < _numOwners, 
            "required approvals out of range"
        ); 
        _;
    }

    /**
     * @dev Sets the initial list of owners, and initial approvals required to execute transactions.
     * Accepts msg.value as an initial deposit.
     */
    constructor(address[] memory _owners, uint _requiredApprovals) 
        payable
        maxOwners(_owners.length) 
        validRequiredApprovals(_owners.length, _requiredApprovals) 
    {
        // _addOwner performs additional input verification
        // unchecked for gas optimization, owners.length never > 20
        unchecked { for (uint i; i < _owners.length; i++) _addOwner(_owners[i]); }
        requiredApprovals = _requiredApprovals;
    }

    /**
     * @dev Function to receive ETH that will be handled by the owners.
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /* OWNER ACTIONS */

    /**
     * @dev If called by an owner on a transaction that has been submitted but not executed,
     * and has not already been approved by this owner, then this function approves a pending 
     * transaction.
     */
    function approve(uint _txId) 
        external
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        require(!approved[_txId][msg.sender], "tx already approved");
        _approve(_txId);
    }

    /**
     * @dev If called by an owner on a transaction that has been submitted but not executed,
     * and has been approved by enough owners, then this function executes a pending transaction.
     */
    function execute(uint _txId) 
        external
        onlyOwner
        txExists(_txId) 
        notExecuted(_txId)
    {
        require(getApprovalCount(_txId) >= requiredApprovals, "more approvals needed");

        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success,) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        
        if (!success) revert TransactionFailed();
        emit Execution(_txId);
    }

    /**
     * @dev If called by an owner on a transaction that has been submitted but not executed,
     * and has not already been flagged, then this function marks a pending transaction to 
     * indicate that it should not be executed, or that discussion is needed before executing.
     */
    function flag(uint _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId)
    {
        require(!transactions[_txId].flagged, "tx already flagged");
        transactions[_txId].flagged = true;
        emit Flag(msg.sender, _txId);
    }

    /**
     * @dev If called by an owner on a transaction that has been submitted but not executed,
     * and has already been approved by this owner, then this function revokes the approval
     * previoulsy given.
     */
    function revoke(uint _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revocation(msg.sender, _txId);
    }

    /**
     * @dev Allows an owner to request any arbitrary transaction to be executed by the wallet after
     * the required amount of approvals are given. No input validation is done at this stage.
     */
    function submitTransaction(address _to, uint _value, bytes calldata _data) 
        external 
        onlyOwner 
        returns (uint txId) 
    {
        _constructTransaction(_to, _value, _data);
        txId = transactions.length - 1;

        emit TransactionRequest(_to, _value, txId);
        _approve(txId); 
    }

    /* SPECIAL SUBMITS */ 

    /**
     * @dev Allows an owner to request the addition of a new owner as long as the proposed owner 
     * is valid, and adding another owner would not put amount of owners over the desired range.
     * 
     * Function is provided for convenience and upfront input validation. The same transaction 
     * could be constructed using submitTransaction.
     */
    function submitAddOwner(address _newOwner) 
        external 
        onlyOwner 
        maxOwners(owners.length + 1) 
        validOwner(_newOwner) 
        returns (uint txId) 
    {
        _constructTransaction(
            address(this), 
            0, 
            abi.encodeWithSignature("addOwner(address)", _newOwner)
        );
        txId = transactions.length - 1;

        emit OwnerAdditionRequest(_newOwner, txId);
        _approve(txId);
    }

    /**
     * @dev Allows an owner to request a new amount of required approvals, as long as the proposed
     * required amount remains within the desired range.
     * 
     * Function is provided for convenience and upfront input validation. The same transaction 
     * could be constructed using submitTransaction.
     */
    function submitChangeRequiredApprovals(uint _requiredApprovals) 
        external 
        onlyOwner 
        validRequiredApprovals(owners.length, _requiredApprovals) 
        returns (uint txId) 
    {
        require(_requiredApprovals != requiredApprovals, "new amount is current amount");
        _constructTransaction(
            address(this), 
            0, 
            abi.encodeWithSignature("changeRequiredApprovals(uint256)", _requiredApprovals)
        );
        txId = transactions.length - 1;

        emit RequirementChangeRequest(_requiredApprovals, txId);
        _approve(txId);
    }

    /**
     * @dev Allows an owner to request the removal an existing owner as long as the owner to be 
     * removed exists, and removing an owner would not put amount of owners below the desired 
     * range.
     * 
     * Function is provided for convenience and upfront input validation. The same transaction 
     * could be constructed using submitTransaction.
     */
    function submitRemoveOwner(address _owner) 
        external 
        onlyOwner 
        ownerExists(_owner)
        validRequiredApprovals(owners.length - 1, requiredApprovals - 1) 
        returns (uint txId) 
    {
        _constructTransaction(
            address(this), 
            0,
            abi.encodeWithSignature("removeOwner(address)", _owner)
        );
        txId = transactions.length - 1;

        emit OwnerRemovalRequest(_owner, txId);
        _approve(txId);
    }

    /* WALLET ACTIONS */

    /**
     * @dev If called on a valid new owner, where adding another owner would not put amount of 
     * owners over the desired range, then the address is given owner privledges.
     * 
     * Function can only be called directly from wallet, but must be marked external so it exists
     * in the contract ABI.
     */
    function addOwner(address _newOwner) 
        external
        onlyWallet 
        maxOwners(owners.length + 1) 
    { 
        _addOwner(_newOwner);
        emit OwnerAddition(_newOwner);
    }

    /**
     * @dev If the proposed required amount remains within the desired range, update the amount.
     * 
     * Function can only be called directly from wallet, but must be marked external so it exists
     * in the contract ABI.
     */
    function changeRequiredApprovals(uint _requiredApprovals) 
        external 
        onlyWallet
        validRequiredApprovals(owners.length, _requiredApprovals) 
    {
        requiredApprovals = _requiredApprovals;
        emit RequirementChange(requiredApprovals);
    }

    /**
     * @dev If called by wallet on an existing owner, where removing an owner would not put amount
     * of owners below the desired range, then the owner is removed.
     * 
     * If removing an owner would make owners.length == requiredApprovals, then requiredApprovals
     * is automatically decremented. 
     * 
     * Examples:
     *   BEFORE                AFTER
     *   2 owner 1 required -> 1 owner 0 required (fail)
     *   3 owner 1 required -> 2 owner 1 required 
     *   3 owner 2 required -> 2 owner 1 required
     *   4 owner 1 required -> 3 owner 1 required
     *   4 owner 2 required -> 3 owner 2 required
     *   4 owner 3 required -> 3 owner 2 required
     * 
     * Function can only be called directly from wallet, but must be marked external so it exists
     * in the contract ABI.
     */
    function removeOwner(address _owner) 
        external 
        onlyWallet 
        ownerExists(_owner)
        validRequiredApprovals(owners.length - 1, requiredApprovals - 1) 
    {   
        isOwner[_owner] = false;
        // find owner to delete in array, replace with last owner in array
        uint lengthMinusOne = owners.length - 1;
        unchecked {
            for (uint i; i < lengthMinusOne; i++) {
                address ownerAtIndex = owners[i];
                if (ownerAtIndex == _owner) {
                    ownerAtIndex = owners[lengthMinusOne];
                    break;
                }
            }
        }
        // remove last owner in array
        owners.pop(); 

        // decrement required approvals if necesssary
        if (requiredApprovals == lengthMinusOne) {
            requiredApprovals -= 1; 
            emit RequirementChange(requiredApprovals);
        }
        emit OwnerRemoval(_owner);
    }

    /* VIEW */

    /**
     * @dev Return the amount of approvals a given transaction has received.
     * 
     * Inconsistency: if owner is removed after approving an unexecuted transaction,
     * approved[tx][removed owner] = true, but getApprovalCount will not count this.
     * This is acceptable, potentially malicious past transaction will not be
     * executable without further approval
     */
    function getApprovalCount(uint _txId) public view returns (uint count) {
        mapping(address => bool) storage _approved = approved[_txId];
        uint length = owners.length;
        unchecked { for (uint i; i < length; i++) if (_approved[owners[i]]) count += 1; }
    }

    /* INTERNAL HELPER */

    /**
     * @dev Approve a transaction.
     */
    function _approve(uint _txId) private {
        approved[_txId][msg.sender] = true;
        emit Approval(msg.sender, _txId);
    }

    /**
     * @dev If called on a valid potential address, give it owner privledges.
     */
    function _addOwner(address _newOwner) 
        private 
        validOwner(_newOwner)
    {
        isOwner[_newOwner] = true;
        owners.push(_newOwner);
    }

    /**
     * @dev Create a new transaction struct and record it to the list of transactions.
     */
    function _constructTransaction(address _to, uint _value, bytes memory _data) private {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            flagged: false
        }));
    }
}