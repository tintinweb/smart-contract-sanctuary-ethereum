//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

error AccessRegistry__NotOwner();
error AccessRegistry__AlreadySigner();
error AccessRegistry__AddressNull();
error AccessRegistry__NotSigner();

/**
 * @author Sumit Basak
 * @notice A Contract to manage signes of multi signature wallet
 */

contract AccessRegistry {
    /**
     * EVENTS
     */
    event SignerAdded(address indexed signer, uint totalSigners);
    event SingerRemoved(address indexed signer, uint totalSigners);
    event OwnerChanged(address indexed newOwner);
    event QuorumUpdated(uint indexed quorum);

    /**
     * STATE VARIABLES
     */
    address[] internal s_signers;
    address private s_owner;
    uint private constant MIN_CONFIRMATION = 60;
    uint internal s_quorum;
    mapping(address => bool) private s_isSigner;

    /**
     * MODIFIERS
     */
    modifier onlyOwner(address _sender) {
        if (_sender != s_owner) revert AccessRegistry__NotOwner();
        _;
    }

    modifier isNotSignerMod(address _signer) {
        if (s_isSigner[_signer] == true) revert AccessRegistry__AlreadySigner();
        _;
    }

    modifier isSignerMod(address _signer) {
        if (s_isSigner[_signer] == false) revert AccessRegistry__NotSigner();
        _;
    }

    modifier notNull(address _signer) {
        if (_signer == address(0)) revert AccessRegistry__AddressNull();
        _;
    }

    /** Constructor
     * @param _signers : List of signers in the wallet
     * @dev sets owner to the msg.sender(Deployer)
     */
    constructor(address[] memory _signers) {
        s_signers = _signers;
        s_owner = msg.sender;
        s_quorum = calculateQuorum();
        emit QuorumUpdated(s_quorum);
    }

    /**
     * PUBLIC FUNCTIONS
     */

    /**
     * @dev Allows owner to adds signer
     */
    function addSigner(
        address _signer
    ) public onlyOwner(msg.sender) notNull(_signer) isNotSignerMod(_signer) {
        s_isSigner[_signer] = true;
        s_signers.push(_signer);
        s_quorum = calculateQuorum();
        emit SignerAdded(_signer, s_signers.length);
        emit QuorumUpdated(s_quorum);
    }

    /**
     * @dev Allows onwer to remove signers
     */
    function revokeSigner(
        address _signer
    ) public onlyOwner(msg.sender) notNull(_signer) isSignerMod(_signer) {
        s_isSigner[_signer] = false;
        for (uint i = 0; i < s_signers.length; i++) {
            if (s_signers[i] == _signer) s_signers[i] = s_signers[i + 1];
        }
        s_signers.pop();
        s_quorum = calculateQuorum();
        emit SingerRemoved(_signer, s_signers.length);
    }

    /**
     * @dev Allows owner to Transfer signer functionalities to others
     */
    function transferSigner(
        address _from,
        address _to
    )
        public
        onlyOwner(msg.sender)
        notNull(_from)
        notNull(_to)
        isNotSignerMod(_to)
        isSignerMod(_from)
    {
        s_isSigner[_from] = false;
        s_isSigner[_to] = true;
        for (uint i = 0; i < s_signers.length; i++) {
            if (s_signers[i] == _from) {
                s_signers[i] = _to;
                break;
            }
        }
        emit SignerAdded(_to, s_signers.length);
        emit SingerRemoved(_from, s_signers.length);
    }

    /**
     * @dev Renounces onwer and adds new owner
     */
    function renounceOwner(address _newOwner) public onlyOwner(msg.sender) {
        s_owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    /**
     * VIEW FUNCTIONS
     */

    /**
     * @dev Calculates Quorum
     */
    function calculateQuorum() internal view returns (uint) {
        return ((s_signers.length * 60) / 100);
    }

    /**
     * @dev Returns all signers
     */
    function getSigners() public view returns (address[] memory) {
        return s_signers;
    }

    /**
     * @dev Returns owner
     */
    function getOwner() public view returns (address) {
        return s_owner;
    }

    /**
     * @dev Returns true if the given address is a signer
     */
    function isSigner(address _signer) public view returns (bool) {
        return s_isSigner[_signer];
    }

    /**
     * @dev Returns Quorum of minimum confirmation
     */
    function getQuorum() public view returns (uint) {
        return s_quorum;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./AccessRegistry.sol";

error Wallet__TransactDoesntExist();
error Wallet__TransactionExecuted();
error Wallet__NotConfirmed();

/**
 * @author Sumit Basak
 * @dev value can be changed with msg.value in transactions
 * @notice A contract depicting multi signature wallet
 */

contract Wallet is AccessRegistry {
    /**
     * EVENTS
     */
    event Submitted(uint indexed txId);
    event Confirmed(uint indexed txId, address indexed signer);
    event Executed(uint indexed txId);
    event ExecutionFailed(uint indexed txId);
    event RevokedTransaction(uint indexed txId, address indexed signer);
    event Deposited(address indexed sender, uint value);

    /**
     * STATE VARIABLES
     */
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    uint private s_transactionCounter;
    mapping(uint => Transaction) private s_transactions;
    uint[] private s_validTransactions;
    mapping(uint => mapping(address => bool)) private s_confirmations;

    /**
     * FALLBACK & RECIEVE
     * FUNCTIONS
     */

    fallback() external payable {
        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Deposited(msg.sender, msg.value);
        }
    }

    /**
     * MODIFIERS
     */
    modifier transactionExists(uint _txId) {
        if (_txId <= 0 || _txId > s_transactionCounter)
            revert Wallet__TransactDoesntExist();
        _;
    }

    modifier isNotExecutedMod(uint _txId) {
        if (s_transactions[_txId].executed = false)
            revert Wallet__TransactionExecuted();
        _;
    }

    modifier hasConfirmed(uint _txId, address _signer) {
        if (s_confirmations[_txId][_signer] == false)
            revert Wallet__NotConfirmed();
        _;
    }

    /** Constructor
     * @param _signers : List of signers in the wallet
     * @dev sets signer of AccessRegistry contracts
     */
    constructor(address[] memory _signers) AccessRegistry(_signers) {}

    /**
     * PUBLIC FUNCTIONS
     */

    /**
     * @param _to : transaction to be sent to
     * @param _value : ETH sent with the transaction
     * @param _data: Data sent with transaction
     * @dev : Only authorized signer can submit a transaction
     */
    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public isSignerMod(msg.sender) {
        Transaction memory _transaction = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        });
        s_transactionCounter++;
        s_transactions[s_transactionCounter] = _transaction;
        emit Submitted(s_transactionCounter);

        confirmTransaction(s_transactionCounter);
    }

    /**
     * @param _txId : Transaction to be confirmed
     * @dev : Signer confirms the transaction
     */
    function confirmTransaction(
        uint _txId
    )
        public
        isSignerMod(msg.sender)
        transactionExists(_txId)
        isNotExecutedMod(_txId)
    {
        // Sets confirmation to true
        s_confirmations[_txId][msg.sender] = true;
        emit Confirmed(_txId, msg.sender);
    }

    /**
     * @param _txId : Transaction to be executed
     * @dev Transaction is confirmed after quota is met
     */

    function executeTransaction(
        uint _txId
    )
        public
        isSignerMod(msg.sender)
        transactionExists(_txId)
        isNotExecutedMod(_txId)
    {
        uint _count = 0;
        // Iterates through s_signers array
        for (uint i = 0; i < s_signers.length; i++) {
            // counts total confirmation
            if (s_confirmations[_txId][s_signers[i]] == true) _count++;
        }

        if (_count >= s_quorum) {
            Transaction storage txn = s_transactions[_txId];
            // Executes transaction and sends data
            (bool success, ) = txn.to.call{value: txn.value}(txn.data);
            if (success) {
                // Checks if data is sent
                s_transactions[_txId].executed = true; // Sets executed to true
                emit Executed(_txId);
            } else emit ExecutionFailed(_txId);
        } else {
            emit ExecutionFailed(_txId);
        }
    }

    /**
     * @dev revokes confirmation from particular transaction
     */
    function revokeConfirmation(
        uint _txId
    )
        public
        isSignerMod(msg.sender)
        transactionExists(_txId)
        isNotExecutedMod(_txId)
        hasConfirmed(_txId, msg.sender)
    {
        s_confirmations[_txId][msg.sender] = false;
        emit RevokedTransaction(_txId, msg.sender);
    }

    /**
     * VIEW FUNCTIONS
     */
    /**
     * @dev counts total confirmation
     */
    function getTotalConfirmations(uint _txId) public view returns (uint) {
        uint _count = 0;
        for (uint i = 0; i < s_signers.length; i++) {
            if (s_confirmations[_txId][s_signers[i]] == true) _count++;
        }
        return _count;
    }

    /**
     * @dev returns Transaction
     */
    function getTransaction(
        uint _txId
    ) public view returns (Transaction memory) {
        return s_transactions[_txId];
    }

    /**
     * returns true if signer has confirmed the transaction
     */
    function getConfirmation(uint _txId) public view returns (bool) {
        return s_confirmations[_txId][msg.sender];
    }
}