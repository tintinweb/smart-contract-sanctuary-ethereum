/// @author Venimir Petkov

import "./Wallet.sol";
import "../interfaces/ISocialWallet.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
contract SocialWallet is Wallet, ISocialWallet {
    using ECDSA for bytes32;

    /* -------------------------------------------------------- PRIVATE VARIABLES -------------------------------------------------------- */

    mapping (uint256 => ReplaceOwner) private _changers;
    mapping (address => uint256) private _ownerChangeTimeout;

    uint256 private _changerNonce = 0;

    /* -------------------------------------------------------- PUBLIC VARIABLES -------------------------------------------------------- */
    uint256 public immutable REQUIRED_MINIMUM_CHANGER_VOTES;
    uint256 public immutable REQUIRED_CHANGER_YES_VOTES;
    uint256 public immutable OWNER_CHANGE_TIMEOUT;

    bytes4 public immutable SUBMIT_OWNER_CHANGE_SELECTOR        = 0x878951d0;
    bytes4 public immutable VOTE_CHANGE_SELECTOR                = 0xbb706b2d;
    bytes4 public immutable REVOKE_OWNER_CHANGE_SELECTOR        = 0x7ddf7699;
    /* -------------------------------------------------------- STRUCTURES -------------------------------------------------------- */
    struct ReplaceOwner {
        address createBy;
        address oldOwner;
        address newOwner;
        
        uint256 votesCounter;
        
        bool executed;
        mapping (address => bool) isOwnerVoted;

        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
    }

    /* -------------------------------------------------------- PUBLIC FUNCTIONS -------------------------------------------------------- */

    constructor(
        address[] memory _owners, 
        uint256 _confirmationTimeInSeconds, 
        uint256 _executionTimeInSeconds, 
        uint256 _minimumConfirmations, 
        uint256 _requiredMinimumChangerVotes, 
        uint256 _requiredVotesForPassing,
        uint256 _ownerChangeTimeoutInSeconds
    ) Wallet(
        _owners,
        _confirmationTimeInSeconds,
        _executionTimeInSeconds,
        _minimumConfirmations
    ){
        require(_requiredMinimumChangerVotes > _requiredVotesForPassing, "CO:constructor:minimum votes must be greater than votes for passing");
        require(_ownerChangeTimeoutInSeconds > 0, "CO:constructor:minimum votes must be greater than 0");
        require(_ownerChangeTimeoutInSeconds < _executionTimeInSeconds, "CO:constructor:minimum votes must be greater than 0");
        REQUIRED_MINIMUM_CHANGER_VOTES = _requiredMinimumChangerVotes;
        REQUIRED_CHANGER_YES_VOTES = _requiredVotesForPassing;
        OWNER_CHANGE_TIMEOUT= _ownerChangeTimeoutInSeconds;
    }

    /* -------------------------------------------------------- EXTERNAL FUNCTIONS -------------------------------------------------------- */

    /**
        * @notice submitOwnerChange function will load replacement and will init protocol for replacement.
        * @dev Requirements: 
            * oldOwner must exist as an owner
            * newOwner must not exist as an owner
            * if this is not the first replacement the contract will require previous to be executed.
        * emit event LogSubmitChangeOwner with oldOwner, newOwner and _changerNonce

        * @param signature Owner signature who respond to other params
        * @param oldOwner owner address who is nominated for replacement
        * @param newOwner owner address who is nominated to replace the oldOwner
    */

    function submitOwnerChange(bytes calldata signature, address oldOwner, address newOwner) whenNotPaused external override {
        _pause();
        require(!isOwner[newOwner], "CO::submitOwnerChange:newOwner already exist");
        require(isOwner[oldOwner], "CO::submitOwnerChange:oldOwner do not exist");

        if(!transactions[_nonce].executed){
            transactions[_nonce].blocked = true;
        }

        ReplaceOwner storage replacing = _changers[_changerNonce];
        require(replacing.executed, "CO::submitOwnerChange:active replacement");

        bytes memory payload = abi.encode(address(this), SUBMIT_OWNER_CHANGE_SELECTOR, oldOwner, newOwner, _changerNonce);
        address signatureOwner = verifyAndReturnOwner(signature, payload);

        require(_ownerChangeTimeout[signatureOwner] < block.timestamp, "CO::submitOwnerChange:cannot change owner so soon");

        ReplaceOwner storage r = _changers[_changerNonce];
        r.createBy        = signatureOwner; 
        r.oldOwner        = oldOwner;
        r.newOwner        = newOwner; 
        r.votesCounter    = 0;    
        r.executed        = false;   
        r.yesVotes        = 0;
        r.noVotes         = 0;  
        r.deadline        = block.timestamp+EXECUTION_TIME;  
        
        emit LogSubmitChangeOwner(oldOwner, newOwner, _changerNonce);
    }

    /**
        * @notice vote function will reflect owners vote
        * @dev Requirements: 
            * _changerNonce must be greater than 0
        * @param signature Owner signature who respond to other params
        * @param votePin owner address who is nominated for replacement
        * @param agree owner address who is nominated to replace the oldOwner
    */
    function vote(bytes calldata signature, uint256 votePin, bool agree) whenPaused external override {
        bytes memory payload = abi.encode(address(this), VOTE_CHANGE_SELECTOR, votePin, agree, _changerNonce);
        address signatureOwner = verifyAndReturnOwner(signature, payload);
        _vote(signatureOwner, agree, _changerNonce);
    }

    function revokeChange(bytes calldata signature, uint256 revokePin) whenPaused external override {
        ReplaceOwner storage replacing = _changers[_changerNonce];
        require(replacing.newOwner != address(0), "CO::revokeChange:nothing for vote");
        require(replacing.deadline <= block.timestamp, "CO::revokeChange:deadline is not surpassed");

        bytes memory payload = abi.encode(address(this), REVOKE_OWNER_CHANGE_SELECTOR, revokePin, _changerNonce);
        address signatureOwner = verifyAndReturnOwner(signature, payload);

        emit LogRevoke(signatureOwner, _changerNonce);
        replacing.executed = true;
        _ownerChangeTimeout[replacing.createBy] = block.timestamp + OWNER_CHANGE_TIMEOUT;
    }

    /* -------------------------------------------------------- PRIVATE FUNCTIONS -------------------------------------------------------- */

    /**
        * @notice _vote function will reflect owners vote and if the requirement for REQUIRED_MINIMUM_CHANGER_VOTES is satisfied will execute last protocol for change.
        * @dev Requirements: 
            * _changerNonce must be greater than 0
        * emit event LogVote with owner(who votes), submissionId and agree
        * @param owner owner address which vote
        * @param agree is owner agree or no
        * @param submissionId replacement number
    */
    function _vote(address owner, bool agree, uint256 submissionId) private {
        ReplaceOwner storage replacing = _changers[submissionId];
        
        require(replacing.newOwner != address(0), "CO::_vote:replacement newOwner do not exist");
        require(replacing.oldOwner != address(0), "CO::_vote:replacement oldOwner do not exist");
        require(!replacing.executed, "CO::_vote:replacement already confirmed");
        require(!replacing.isOwnerVoted[owner], "CO::_vote:replacement already confirmed");

        if(agree){
            replacing.yesVotes = replacing.yesVotes + INCREMENT;
        }else{
            replacing.noVotes = replacing.noVotes + INCREMENT;
        }

        replacing.isOwnerVoted[owner] = true;
        replacing.votesCounter = replacing.votesCounter + INCREMENT;
        
        if (replacing.votesCounter == REQUIRED_MINIMUM_CHANGER_VOTES) {
            replaceOwner(submissionId);
        }
        emit LogVote(owner, submissionId, agree);
    }

    /**
        * @notice replaceOwner function will count votes and if yesVotes are greater than noVotes will replace the oldOwner with newOwner.
        * @dev emit event LogOwnerReplacement with oldOwner, newOwner, submissionId and replacementSuccess;
        * @param submissionId replacement number
    */
    function replaceOwner(uint256 submissionId) private {
        ReplaceOwner storage replacing = _changers[submissionId];

        address oldOwner = replacing.oldOwner;
        address newOwner = replacing.newOwner;
        bool replacementSuccess = replacing.yesVotes >= REQUIRED_CHANGER_YES_VOTES;

        if (replacementSuccess) {	
            
            isOwner[oldOwner] = false;
            isOwner[newOwner] = true;
        }

        emit LogOwnerReplacement(oldOwner, newOwner, submissionId, replacementSuccess);
        replacing.executed = true;

        _ownerChangeTimeout[replacing.createBy] = block.timestamp + OWNER_CHANGE_TIMEOUT;
        _unpause();
        _changerNonce = _changerNonce + INCREMENT;
    }

    /* -------------------------------------------------------- VIEWS -------------------------------------------------------- */

    /**
        * @notice get_ChangerNonce function is view function which returns _changerNonce
    */ 
    function getChangerNonce() external override view returns (uint256) {
        return _changerNonce;
    }

    /**
        * @notice getChange function is view function which returns replacing data exept isOwnerVoted
        * @param cNonce replacing number
    */ 
    function getChange(uint256 cNonce) external override view returns (address oldOwner, address newOwner, uint256 votesCounter, bool executed, uint256 yesVotes, uint256 noVotes, uint256 deadline) {
        ReplaceOwner storage replacing = _changers[cNonce];
        return (replacing.oldOwner, replacing.newOwner, replacing.votesCounter, replacing.executed, replacing.yesVotes, replacing.noVotes, replacing.deadline);
    }

    /**
        * @notice getIsOwnerVoted function is view function which returns does owner is already voted 
        * @param cNonce replacement number
        * @param owner owner address
    */ 
    function getIsOwnerVoted(uint256 cNonce, address owner) external override view returns (bool isOwnerVoted){
        return _changers[cNonce].isOwnerVoted[owner];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA::recover:invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA::recover:invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA::recover:invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IWallet {

    function submitTransaction(bytes calldata signature, address payable to, uint256 value, bytes calldata data) external;
    function confirmTransaction(bytes calldata signature, uint256 confirmationPin) external;
    function revokeTransaction(bytes calldata signature, uint256 revocationPin) external;
    function executeTransaction(bytes calldata signature, uint256 executionPin) external returns (bool success, bytes memory result);

    function getNonce() external view returns(uint256 nonce);
    function getTransaction(uint256 nonce_) external view returns (address _to, uint256 _value, bytes memory _data, bool _isBlocked, uint256 _couldConfirmAfter, uint256 _confirmations, uint256 _executeAfter, bool _isExecuted);
    function getIsOwnerConfirmed(uint256 nonce_, address _owner) external view returns (bool _isOwnerConfirmed);

    event Received(address indexed sender, uint256 indexed value, bytes data);
    event Fallback(address indexed sender, uint256 indexed value, bytes data);

    event LogSubmission(address indexed owner, uint256 indexed transactionId, bytes data);
    event LogConfirmation(address indexed owner, uint256 indexed transactionId);
    event LogExecution(address indexed owner, uint256 indexed transactionId, bytes result, bool success);
    event LogRevocation(address indexed owner, uint256 indexed transactionId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISocialWallet {
    function submitOwnerChange(bytes calldata signature, address _oldOwner, address _newOwner) external;
    function vote(bytes calldata signature, uint256 votePin, bool agree) external;
    function revokeChange(bytes calldata signature, uint256 revokePin) external;
    
    function getChangerNonce() external view returns (uint256);
    function getChange(uint256 cNonce) external view returns (address oldOwner, address newOwner, uint256 votesCounter, bool executed, uint256 yesVotes, uint256 noVotes, uint256 deadline);
	function getIsOwnerVoted(uint256 changerNonce_, address _owner) external view returns (bool _isOwnerVoted);
    
    event LogSubmitChangeOwner(address indexed currentOwner, address indexed newOwner, uint256 indexed changerNonce);
    event LogVote(address indexed owner, uint256 indexed _submissionId,  bool _agree);
    event LogRevoke(address indexed owner, uint256 indexed _submissionId);
    event LogOwnerReplacement(address indexed oldOwner, address indexed newOwner, uint256 indexed _submissionId, bool isReplaced);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISocialOwnable {
    function getIsOwner(address _owner) external view returns (bool _isOwner_);
}

/// @author Venimir Petkov
/// @title Social wallet - Allows multiple parties to agree on transactions before execution.

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// wallet => wallet
import "../interfaces/IWallet.sol";
import "./Pausable.sol";
import "./SocialOwnable.sol";

abstract contract Wallet is SocialOwnable, Pausable, IWallet {

    /* -------------------------------------------------------- PRIVATE VARIABLES -------------------------------------------------------- */

    uint256 internal _nonce;
    bool private _locked;
    /* -------------------------------------------------------- INTERNAL VARIABLES -------------------------------------------------------- */
    mapping (uint256 => Transaction) internal transactions;
    /* -------------------------------------------------------- PUBLIC VARIABLES -------------------------------------------------------- */

    uint256 public constant INCREMENT = 1;

    uint256 public immutable CONFIRMATION_TIME;
    uint256 public immutable EXECUTION_TIME;
    uint256 public immutable MINIMUM_CONFIRMATIONS;

    uint256 public immutable subTime;

    bytes4 public immutable SUBMIT_SELECTOR     = 0x85f9202c;
    bytes4 public immutable CONFIRM_SELECTOR    = 0x02548cb3;
    bytes4 public immutable REVOKE_SELECTOR     = 0xb4934ccf;
    bytes4 public immutable EXECUTE_SELECTOR    = 0x92e876cd;
  /* -------------------------------------------------------- STRUCTURES -------------------------------------------------------- */

    struct Transaction {      
        address payable to;
        uint256 value;
        bytes data;
  
        bool blocked;
  
        uint256 couldConfirmAfter;
        mapping (address => bool) isOwnerConfirmed;
        uint256 confirmed;
  
        uint256 couldExecuteAfter;
        bool executed;
    }

    /* -------------------------------------------------------- MODIFIERS -------------------------------------------------------- */

    modifier noReentrancy() {
        require(!_locked, "wallet::noReentrancy:Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    modifier noActiveTransaction() {
        require(transactions[_nonce].executed || transactions[_nonce].blocked, "wallet::noActiveTransaction:active loaded transaction"); 
        _;
    }

	/* -------------------------------------------------------- PUBLIC FUNCTIONS -------------------------------------------------------- */

    constructor(address[] memory _owners_, uint256 confirmationTimeInSeconds, uint256 executionTimeInSeconds, uint256 minimumConfirmations) SocialOwnable(_owners_) {
        require(minimumConfirmations >= INCREMENT, "wallet::constructor:minimumConfirmations must be greater than zero");
        require(confirmationTimeInSeconds >= INCREMENT, "wallet::constructor:confirmationTimeInSeconds must be greater than zero");
        require(executionTimeInSeconds >= INCREMENT, "wallet::constructor:executionTimeInSeconds must be greater than zero");

		require(confirmationTimeInSeconds < executionTimeInSeconds, "wallet::constructor:confirmationTimeInSeconds must be lesser than EXECUTION_TIME");

		require(minimumConfirmations <= _owners_.length, "wallet::constructor:minimumConfirmations must be smaller or equal than owners length");
		require(executionTimeInSeconds % _owners_.length == 0, "wallet::constructor:executionTimeInSeconds reminder");

        subTime = executionTimeInSeconds / _owners_.length;
        _nonce = 0;

        CONFIRMATION_TIME = confirmationTimeInSeconds;
        EXECUTION_TIME = executionTimeInSeconds;
        MINIMUM_CONFIRMATIONS = minimumConfirmations;
    }

	/* -------------------------------------------------------- EXTERNAL FUNCTIONS -------------------------------------------------------- */

    /**
        * @notice submitTransaction function will load transaction.
        * @dev Requirements: 
        * to must be different from zero address.
        * contract allow only one active/loaded transaction at same time so 
        * if it's not the first transaction contract will require previous transaction to be executed.
        * emit event LogSubmiwalletalleton with owner who submit transaction, transaction nonce and data
        *
        * @param signature Owner signature who respond to other params.
        * @param to Address who will be called.
        * @param value Amount of wei which the to address will receive could be 0.
        * @param data Encoded function call if there is no function call just use '0x'.
	*/ 
    function submitTransaction(bytes calldata signature, address payable to, uint256 value, bytes calldata data) whenNotPaused noActiveTransaction external override {
        require(to != address(0), "wallet::submitTransaction:to address is 0");
        bytes memory payload = abi.encode(address(this), SUBMIT_SELECTOR, to, value, data, _nonce);
        address signatureOwner = verifyAndReturnOwner(signature, payload);

        _addTransaction(to, value, data, _nonce);
        emit LogSubmission(signatureOwner, _nonce, data);
    }
  
    /**
        * @notice confirmTransaction function will confirm last active transaction and will reduce the executionTime with owner subTime upon success.
        * @dev Requirements: 
        * transaction to must be different from zero address.
        * transaction must be active, this means not blocked/revoked
        * transaction must be active, this means not executed
        *
        * confirmation slot between submitTransaction and CONFIRMATION_TIME must be surpassed
        * confirmation can be subbmited only one time from each owner
        * emit event LogConfirmation with owner who confirm and transaction nonce
        *
        * @param signature Owner signature who respond to other params.
        * @param confirmationPin uint256 this is onetime pin which is encoded with other parameters and walletgned by the owner.
	*/ 
    function confirmTransaction(bytes calldata signature, uint256 confirmationPin) whenNotPaused noActiveTransaction external override {   
        Transaction storage txn = transactions[_nonce];
        transactionSafeChecks(txn);

		require(txn.couldConfirmAfter <= block.timestamp, "wallet::confirmTransaction:transaction confirmation time is not expired"); 
        bytes memory payload = abi.encode(address(this), CONFIRM_SELECTOR, txn.to, txn.value, txn.data, _nonce, confirmationPin);
        address signatureOwner = verifyAndReturnOwner(signature, payload);

        require(!txn.isOwnerConfirmed[signatureOwner], "wallet::confirmTransaction:you already confirmed");

		txn.confirmed = txn.confirmed + INCREMENT;
		txn.couldExecuteAfter = txn.couldExecuteAfter - subTime;
		txn.isOwnerConfirmed[signatureOwner] = true;
		
        emit LogConfirmation(signatureOwner, _nonce);
    }

    /**
        * @notice revokeTransaction function will revoke/block last active transaction.
        * @dev Requirements: 
        * transaction to must be different from zero address.
        * transaction must be active, this means not blocked/revoked
        * transaction must be active, this means not executed
        *
        * revokation can be subbmited only one time from some of the owners
        * emit event LogRevocation with owner who revoke and transaction nonce
        *
        * @param signature Owner signature who respond to other params.
        * @param revocationPin uint256 this is onetime pin which is encoded with other parameters and walletgned by the owner.
	*/ 
    function revokeTransaction(bytes calldata signature, uint256 revocationPin) whenNotPaused external override {
        Transaction storage txn = transactions[_nonce];
        transactionSafeChecks(txn);
        
        bytes memory payload = abi.encode(address(this), REVOKE_SELECTOR, txn.to, txn.value, txn.data, _nonce, revocationPin);
        address signatureOwner = verifyAndReturnOwner(signature, payload);

        txn.blocked = true;
        
        emit LogRevocation(signatureOwner, _nonce);
    }

    /**
        * @notice executeTransaction function will execute the transaction.
        * @dev Requirements: 
        * transaction to must be different from zero address.
        * transaction must be active, this means not blocked/revoked
        * transaction must be active, this means not executed
        *
        * execution slot between submitTransaction and EXECUTION_TIME must be surpassed
        * execution must satisfy the MINIMUM_CONFIRMATIONS requirement
        * execution can be subbmited only one time
        * emit event LogExecution with owner who confirm, transaction nonce, result and success
        *
        * @param signature Owner signature who respond to other params.
        * @param executionPin uint256 this is onetime pin which is encoded with other parameters and walletgned by the owner.
	*/ 
    function executeTransaction(bytes calldata signature, uint256 executionPin) whenNotPaused external override returns (bool success, bytes memory result) {
        Transaction storage txn = transactions[_nonce];
        transactionSafeChecks(txn);
        
        bytes memory payload = abi.encode(address(this), EXECUTE_SELECTOR, txn.to, txn.value, txn.data, _nonce, executionPin);
        address signatureOwner = verifyAndReturnOwner(signature, payload);

        require(txn.couldExecuteAfter <= block.timestamp, "wallet::executeTransaction:transaction has more time");
		require(txn.confirmed >= MINIMUM_CONFIRMATIONS, "wallet::executeTransaction:transaction has no enough confirmations");
    
		txn.executed = true;

        (success, result) = _invoke(txn.to, txn.value, txn.data);
        
        _nonce = _nonce + INCREMENT;

        emit LogExecution(signatureOwner, _nonce, result, success);
        return (success, result);
    }

    /**
        * @notice receive function is for receiving ethers.
        * @dev emit event Received with msg.sender, msg.value and msg.data
	*/ 
    receive() external payable {
        emit Received(_msgSender(), msg.value, _msgData());
    }
  
    /**
        * @notice fallback function will be invoked if no function signature is founded.
        * @dev emit event Fallback with msg.sender, msg.value and msg.data
	*/ 
    fallback() external payable {
        emit Fallback(_msgSender(), msg.value, _msgData());
    }

	/* -------------------------------------------------------- INTERNAL FUNCTIONS -------------------------------------------------------- */
    
    function transactionSafeChecks(Transaction storage txn) internal view {
        require(txn.to != address(0), "wallet::revokeTransaction:transaction do not exist");
        require(!txn.blocked, "wallet::revokeTransaction:Transaction already blocked");
        require(!txn.executed, "wallet::revokeTransaction:Transaction already executed");
    }

	/* -------------------------------------------------------- PRIVATE FUNCTIONS -------------------------------------------------------- */
  
    /**
        * @notice invoke function is for calling other addresses and execute Transaction instructions.
        * @param to Address who will be called.
        * @param value Amount of wei which the to address will receive.
        * @param data Encoded instructions.
	*/ 
    function _invoke(address payable to, uint256 value, bytes memory data) private noReentrancy() returns (bool success, bytes memory result) {
        (success, result) = to.call{value: value}(data);
            if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
        * @notice _addTransaction function is for saving transaction in the transactions mapping.
        * @param destination Address who will be called.
        * @param value Amount of wei which the to address will receive.
        * @param data Encoded instructions.
        * @param nonce transaction number.
	*/ 
    function _addTransaction(address payable destination, uint256 value, bytes calldata data, uint256 nonce) private {
        Transaction storage t = transactions[nonce];
            t.to                = destination;
            t.value             = value;
            t.data              = data;       
            t.blocked           = false;			
            t.couldConfirmAfter = block.timestamp + CONFIRMATION_TIME;
            t.confirmed         = 0;
            t.couldExecuteAfter = block.timestamp + EXECUTION_TIME;
            t.executed          = false;
    }

  /* -------------------------------------------------------- VIEWS -------------------------------------------------------- */

    /**
        * @notice getNonce function is view function which returns nonce
	*/ 
    function getNonce() public override view returns(uint256 nonce) {
        return _nonce;
    }

    /**
        * @notice getTransaction function is view function which returns transaction data exept isOwnerConfirmed
        * @param nonce transaction number
	*/ 
    function getTransaction(uint256 nonce) external override view returns (address to, uint256 value, bytes memory data, bool isBlocked, uint256 couldConfirmAfter, uint256 confirmations, uint256 executeAfter, bool isExecuted) {
        Transaction storage txn = transactions[nonce];
        return (txn.to, txn.value, txn.data, txn.blocked, txn.couldConfirmAfter, txn.confirmed, txn.couldExecuteAfter, txn.executed);
    }

    /**
        * @notice getIsOwnerConfirmed function is view function which returns does owner is already confirmed the transaction
        * @param nonce transaction number
        * @param owner owner address
	*/ 
    function getIsOwnerConfirmed(uint256 nonce, address owner) external override view returns (bool isOwnerConfirmed){
        return transactions[nonce].isOwnerConfirmed[owner];
    }
}

/// @author Venimir Petkov
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../libraries/ECDSA.sol";
import "../interfaces/ISocialOwnable.sol";

//  SocialOwnable => so

abstract contract SocialOwnable is ISocialOwnable {
    using ECDSA for bytes32;

    // address[] internal owners;
    mapping (address => bool) internal isOwner;

    constructor(address[] memory _owners_) {
		// owners = _owners_;	
        for (uint256 i = 0; i < _owners_.length; i++) {
            require(!isOwner[_owners_[i]] && _owners_[i] != address(0), "so::constructor: TODO");
            isOwner[_owners_[i]] = true;
        }
    }
    
    /* -------------------------------------------------------- VIEWS -------------------------------------------------------- */

    /**
        * @notice getIsOwner function is view function which returns does the input address is owner
        * @param owner owner address
	*/ 
    function getIsOwner(address owner) external override view returns (bool _isOwner_){
        return isOwner[owner];
    }

	/* -------------------------------------------------------- INTERNAL FUNCTIONS -------------------------------------------------------- */
    function verifyAndReturnOwner(bytes calldata signature, bytes memory payload) internal view returns(address signatureOwner){
        signatureOwner = getOwnerAddress(payload, signature);
        require(isOwner[signatureOwner], "so::verifyOwner:Failed to verify signature");
        return signatureOwner;
    }

    /* -------------------------------------------------------- PURE -------------------------------------------------------- */
    /**
        * @notice getOwnerAddress function is pure function which returns owner owner address based on params
        * @param payload encoded transaction data
        * @param signature owner signature
	*/ 
    function getOwnerAddress(bytes memory payload, bytes memory signature) internal pure returns (address){
        return keccak256(payload).toEthSignedMessageHash().recover(signature);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.13;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}