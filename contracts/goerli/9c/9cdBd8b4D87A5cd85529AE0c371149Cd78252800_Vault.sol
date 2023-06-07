// SPDX-License-Identifier: MIT

/**
 * Created on: 26/9/2022
 * @summary The contract that is created from LisbonBank and user defined paramters.
 * Allows participants to create and send transactions from an address that no one has control over.
 * @author W3CPI, Inc
 */
pragma solidity ^0.8.0;

import "./VaultManager.sol";
import "./VaultGovernance.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IFee.sol";

contract Vault is IVault, VaultManager, VaultGovernance {
    bool private initialized;
    IFee public feeContract;
    address public intuAddress;


    modifier feeTxGuards() {
        require(msg.value == feeContract.getTransactionFee(), "Fee not sufficient");
        _;
    }

    function initialize(
        address creator,
        address[] memory _proposedAddresses,
        uint256 _rotateThreshold,
        uint256 _transactionThreshold,
        uint256 _adminThreshold,
        string memory _userPublicKeyForEncryption,
        string memory _userDealing,
        address feeContractAddress
    ) external {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        feeContract = IFee(feeContractAddress);
        intuAddress = feeContract.getOwnerAddress();

        _createVault(
            _proposedAddresses,
            _rotateThreshold,
            _transactionThreshold,
            _adminThreshold
        );

        //TODO not efficient
        for (uint256 i; i < _proposedAddresses.length; i++) {
            emit VaultUserInitialized(_proposedAddresses[i]);
        }

        _register(creator);
        emit VaultUserRegistered(creator, _userPublicKeyForEncryption, _userDealing);
    }

    function register(
        string memory _userPublicKeyForEncryption,
        string memory _userDealing
    ) external {
        _register(msg.sender);
        emit VaultUserRegistered(msg.sender, _userPublicKeyForEncryption, _userDealing);
    }


    function userCompleteVault(
        address[] memory userAddresses,
        string[] memory encryptedShares,
        bytes memory _masterPubKey,
        string memory _vaultTranscript
    ) public _isRegisteredUser {
        //TODO get rid of that for loop NOT GAS EFFICIENT
        for (uint256 i; i < userAddresses.length; i++) {
            require(registeredToVault(userAddresses[i]), "User is not registered!");
        }
        _completeVault();
        emit VaultCompleted(userAddresses, encryptedShares, _masterPubKey, _vaultTranscript);
    }

    ///////////////////////////////////////////////////////////////////////////////////

    function _proposalGuard(Proposal storage proposal) private view {
        require(proposal.id != 0, "proposal not found");
        require(registeredToVault(msg.sender), "Voter is not registered to Vault");
    }

    function voteFor(uint256 proposalId) external {
        _proposalGuard(proposals[proposalId]);
        _voteFor(proposalId);
    }

    function voteAgainst(uint256 proposalId) external {
        _proposalGuard(proposals[proposalId]);
        _voteAgainst(proposalId);
    }

    function executeProposal(
        uint256 proposalId
    ) external payable {
        Proposal storage proposal = proposals[proposalId];
        _proposalGuard(proposal);
        require(msg.value == proposal.feeValue);
        (bool success, ) = payable(intuAddress).call{value: msg.value}("");
        require(success, "Transfer failed.");

        _executeProposal(proposalId);
    }

    ////////////////////////////////////////////////////////////////////////////////


    //////////////////////////////////////////  Transaction /////////////////////////////////////////
    function proposeTransaction(
        string memory transactionInfo
    ) external payable _isCompleted _isRegisteredUser feeTxGuards {
        (bool success, ) = payable(intuAddress).call{value: msg.value}("");
        require(success, "Transfer failed.");

        uint256 votesNeeded = _thresholdVotes(vault.transactionThreshold);

        vault.transactionCount++;
        uint256 txId = vault.transactionCount;
        // we start transaction Id at 1
        Transaction storage trans = transactions[txId];
        trans.id = txId;
        trans.votesNeeded = votesNeeded;

        // if transaction not validate by the smart contract, the fee is returned to the user ( or even the intu eoa of the user(s))
        emit TransactionProposed(txId, transactionInfo);
    }

    function userConfirmTx(
        uint256 txId,
        string memory signedTransaction
    ) external _isCompleted _isRegisteredUser {
        Transaction storage trans = transactions[txId];
        require(trans.id != 0, "Vault Error: Tx not found");
        require(!transactionVotes[trans.id][msg.sender], "Vault Error: User already confirmed the Tx");
        transactionVotes[trans.id][msg.sender] = true;
        trans.votesFor++;

        emit TransactionUserConfirmed(
            txId,
            msg.sender,
            signedTransaction
        );
    }

    function transactionInfos(uint256 txId) external view returns (Transaction memory) {
        return transactions[txId];
    }

    function hasUserConfirmedTransaction(uint256 txId, address user) external view returns (bool) {
        return transactionVotes[txId][user];
    }

    /*      one of the owner of the vault : mg.sender instead of the user
    //triggered if the transaction happened
    // sdk will use this
    function withdrawTxFees(uint256 _txId) external {
        require(
            transactions[_txId].votesFor >= transactions[_txId].votesNeeded,
            "Vault Error: Not enough votes"
        );
        if (msg.sender == intuAddress) {
            payable(intuAddress).transfer(address(this).balance);
            emit contractBalance(address(this).balance);
        }
    }

    // need to add txid in the struct of transaction
    // only owner of vault can call this function
    function getFeeBack(uint256 _txId) external _isCompleted _isRegisteredUser {
        require(
            _istransactionPeriodExpired() &&
                transactions[_txId].votesFor < transactions[_txId].votesNeeded,
            "Vault Error: Time Transaction not expired or transaction has enough votes"
        );
        // register there eoa so the user can retreive the money
        // possibilities to give only a %
        payable(msg.sender).transfer(address(this).balance);
        emit contractBalance(address(this).balance);
    } */

    ///////////////////////////////////////////////////// END TRANSACTION /////////////////////////////////////////////////

    ////////////////////////////////////////////////////// PROPOSALS ////////////////////////////////////////////////////
    function proposeAddUserInVault(
        address userToAdd
    ) external _isCompleted _isRegisteredUser {

        uint256 voteForNeeded = _thresholdVotes(vault.rotateThreshold);

        uint256 feeValue = feeContract.getRotationFee();

        bytes memory _calldata = abi.encodeWithSignature("performAddUserToVault(address)", userToAdd);

        bytes memory data = abi.encode(userToAdd);

        _createProposal(voteForNeeded, _calldata, PropositionType.ADD_USER, data, feeValue);
    }

    function proposeRemoveUserInVault(
        address userToRemove
    ) external _isCompleted _isRegisteredUser {

        uint256 voteForNeeded = _thresholdVotes(vault.rotateThreshold);

        uint256 feeValue = feeContract.getRotationFee();

        bytes memory _calldata = abi.encodeWithSignature("performRemoveUserFromVault(address)", userToRemove);

        bytes memory data = abi.encode(userToRemove);

        _createProposal(voteForNeeded, _calldata, PropositionType.REMOVE_USER, data, feeValue);
    }

    function proposeRotationThresholdUpdate(
        uint256 _newThreshold
    ) external _isCompleted _isRegisteredUser {

        uint256 voteForNeeded = _thresholdVotes(vault.adminThreshold);

        bytes memory _calldata = abi.encodeWithSignature("performRotationThresholdUpdate(uint256)", _newThreshold);

        bytes memory data = abi.encode(_newThreshold);


    _createProposal(voteForNeeded, _calldata, PropositionType.ROTATION_THRESHOLD_UPDATE, data, 0);
    }

    function proposeTransactionThresholdUpdate(
        uint256 _newThreshold
    ) external _isCompleted _isRegisteredUser {

        uint256 voteForNeeded = _thresholdVotes(vault.adminThreshold);

        bytes memory _calldata = abi.encodeWithSignature("performTransactionThresholdUpdate(uint256)", _newThreshold);

        bytes memory data = abi.encode(_newThreshold);

        _createProposal(voteForNeeded, _calldata, PropositionType.TRANSACTION_THRESHOLD_UPDATE, data, 0);
    }

    function proposeAdminThresholdUpdate(
        uint256 _newThreshold
    ) external _isCompleted _isRegisteredUser {

        uint256 voteForNeeded = _thresholdVotes(vault.adminThreshold);

        bytes memory _calldata = abi.encodeWithSignature("performAdminThresholdUpdate(uint256)", _newThreshold);

        bytes memory data = abi.encode(_newThreshold);

        _createProposal(voteForNeeded, _calldata, PropositionType.ADMIN_THRESHOLD_UPDATE, data, 0);
    }

    function proposeVaultNameUpdate(
        string memory _newName
    ) external _isCompleted _isRegisteredUser {

        uint256 voteForNeeded = _thresholdVotes(vault.adminThreshold);

        bytes memory _calldata = abi.encodeWithSignature("performVaultNameUpdate(string)", _newName);

        bytes memory data = abi.encode(_newName);

        _createProposal(voteForNeeded, _calldata, PropositionType.VAULT_NAME_UPDATE, data, 0);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////// Proposals Execution /////////////////////////////////////////////

    function performAddUserToVault(address userToRemove) external {
        require(msg.sender == address(this), "Not Authorized");
        _addUserToVault(userToRemove);
    }

    function performRemoveUserFromVault(address userToRemove) external {
        require(msg.sender == address(this), "Not Authorized");
        _removeUserFromVault(userToRemove);
    }

    function performRotationThresholdUpdate(uint256 _newThreshold) external {
        require(msg.sender == address(this), "Not Authorized");
        _performRotationThresholdUpdate(_newThreshold);
    }

    function performTransactionThresholdUpdate(uint256 _newThreshold) external {
        require(msg.sender == address(this), "Not Authorized");
        _performTransactionThresholdUpdate(_newThreshold);
    }

    function performAdminThresholdUpdate(uint256 _newThreshold) external {
        require(msg.sender == address(this), "Not Authorized");
        _performAdminThresholdUpdate(_newThreshold);
    }

    function performVaultNameUpdate(string memory _newName) external {
        require(msg.sender == address(this), "Not Authorized");
        emit VaultNewName(_newName);
    }

    function _thresholdVotes(uint256 thresholdPercentage) private view returns (uint ) {
        return ((( (thresholdPercentage * vault.registeredUsersCount) + 100 - 1) / 100) * 100) / 100; // cheap roundup and divide by 100
    }

    //////////////////////////////////PRIVATE VERIFICATION FUNCTIONS//////////////////////////////////////////
    /*     // here we will verify if the tranasaction is expired or not
    // the idea is to register every date of the transaction that are proposed
    // if the date of the transaction proposed + the period of the transaction is less than the current date
    // then the transaction is not expired
    function _istransactionPeriodExpired() private view returns (bool) {
        //TO DO remove the date it should be registered in the transaction struct
        // the date should be the date of the transaction so dateTx + periodTx
        uint256 datewaiting = 12;
        uint256 dateTx = 16200;

        return dateTx + datewaiting < block.timestamp;
    } */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFee {
    function getTransactionFee() external view returns (uint256);

    function getRotationFee() external view returns (uint256);

    function getOwnerAddress() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVault {

    event VaultCompleted(
        address[] users,
        string[] encryptedShares,
        bytes _masterPubKey,
        string _vaultTranscript
    );

    event VaultUserInitialized(
        address indexed user
    );

    event VaultUserRegistered(
        address indexed user,
        string _userPublicKeyForEncryption,
        string userDealing
    );

    event VaultNewName(
        string name
    );

    event TransactionProposed(uint256 indexed txId, string transactionInfo);

    event TransactionUserConfirmed(
        uint256 indexed txId,
        address indexed user,
        string signedTransaction
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";


abstract contract VaultGovernance {

    using Counters for Counters.Counter;

    event ProposalCreated(
        uint256 indexed id,
        PropositionType _type,
        bytes data
    );

    enum VoteState {
        NO_VOTE, // default status
        VOTE_FOR,
        VOTE_AGAINST
    }

    enum PropositionType {
        ADD_USER,
        REMOVE_USER,
        ROTATION_THRESHOLD_UPDATE,
        TRANSACTION_THRESHOLD_UPDATE,
        ADMIN_THRESHOLD_UPDATE,
        VAULT_NAME_UPDATE
    }

    struct Proposal {
        uint256 id;
        uint256 voteForNeeded;
        uint256 endTime;
        uint256 voteForCount;
        bytes _calldata;
        bool executed;
        uint256 feeValue;
    }

    uint256 public constant PROPOSAL_VOTE_DURATION = 14 days;
    Counters.Counter proposalCounter;
    mapping(uint256 => Proposal) proposals;
    mapping(uint256 => mapping(address => VoteState)) votes; // proposalId => address = VoteState

    function _createProposal(
        uint256 voteForNeeded,
        bytes memory _calldata,
        PropositionType _type,
        bytes memory data,
        uint256 feeValue
    ) internal {
        proposalCounter.increment();
        // we increment first like this first id is 1

        Proposal storage proposal = proposals[proposalCounter.current()];
        uint instant = block.timestamp;

        proposal.id = proposalCounter.current();
        proposal.voteForNeeded = voteForNeeded;
        proposal.endTime = instant + PROPOSAL_VOTE_DURATION;
        proposal._calldata = _calldata;
        proposal.feeValue = feeValue;

        emit ProposalCreated(proposal.id, _type, data);
    }

    function _voteFor(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        require(votes[proposal.id][msg.sender] == VoteState.NO_VOTE, "Voter already voted");
        votes[proposal.id][msg.sender] = VoteState.VOTE_FOR;
        proposal.voteForCount++;
    }

    function _voteAgainst(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        require(votes[proposal.id][msg.sender] == VoteState.NO_VOTE, "Voter already voted");
        votes[proposal.id][msg.sender] = VoteState.VOTE_AGAINST;
    }

    function _executeProposal(
        uint256 proposalId
    ) internal {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "proposal already executed");
        require(!(proposal.endTime < block.timestamp), "proposal expired");
        require(proposal.voteForCount >= proposal.voteForNeeded, "Votes requirement not reached");

        string memory errorMessage = "Executable: execute proposal reverted";

        (bool success,bytes memory data) = address(this).call(proposal._calldata);
        Address.verifyCallResult(success, data, errorMessage);

        proposal.executed = true;

        // don't see the need of emit a dedicated event here
    }

    function proposalInfos(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function proposalVoteUserInfos(uint256 _proposalId, address user) external view returns (VoteState) {
        return votes[_proposalId][user];
    }

    function getProposalCounter() external view returns (uint256) {
        return proposalCounter.current();
    }

}

// SPDX-License-Identifier: MIT
/**
 * Created on: 26/9/2022
 * @summary The library make it possible to create a vault with the base functionalities.
 * Enabling the ability to create a 'vault' which results in a shared EOA with participants of your choosing.
 * @author W3CPI, Inc
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract VaultManager {

    uint256 constant public VAULT_REGISTRATION_PERIOD = 14 days;


    Vault vault;
    mapping(address => User) usersMapping;
    mapping(uint256 => Transaction) transactions;

    mapping(uint256 => mapping(address => bool)) transactionVotes;

    struct Vault {
        address[] users;
        uint256 transactionCount;
        uint256 registeredUsersCount;
        uint256 rotateThreshold;
        uint256 transactionThreshold;
        uint256 adminThreshold;
        uint256 createdDate;
        bool completed;
    }

    struct Transaction {
        uint256 id;
        uint256 votesNeeded;
        uint256 votesFor;
    }

    struct User {
        address userAddress;
        bool isRegistered;
    }

    modifier _isRegisteredUser() {
        require(registeredToVault(msg.sender), "Lisbon: User not registered on given vault");
        _;
    }

    function _partOfVault(address user) internal view returns(bool) {
        return usersMapping[user].userAddress == user;
    }

    modifier _isCompleted() {
        require(vault.completed, "Lisbon: vault is not completed");
        _;
    }

    function registeredToVault(address user) internal view returns(bool) {
        return usersMapping[user].isRegistered;
    }

    function _createVault(
        address[] memory _proposedAddresses,
        uint256 rotateThreshold,
        uint256 transactionThreshold,
        uint256 adminThreshold
    ) internal {

        require(_isValidThreshold(rotateThreshold));
        require(_isValidThreshold(transactionThreshold));
        require(_isValidThreshold(adminThreshold));

        vault.users = _proposedAddresses;
        for(uint i; i < _proposedAddresses.length; i++) {
            usersMapping[_proposedAddresses[i]] = User(_proposedAddresses[i], false);
        }
        vault.createdDate = block.timestamp;
        vault.rotateThreshold = rotateThreshold;
        vault.transactionThreshold = transactionThreshold;
        vault.adminThreshold = adminThreshold;}

    function _register(address user) internal {
        require(!usersMapping[user].isRegistered, "Lisbon: User is already registered");
        require(!_isRegistrationPeriodExpired(vault.createdDate), "Lisbon: registration for this vault is closed");
        usersMapping[user].isRegistered = true;
        vault.registeredUsersCount += 1;
    }

    function _completeVault() internal {
        vault.completed = true;
    }

    function isVaultComplete() internal view returns (bool) {
        return vault.completed;
    }

    function _addUserToVault(address _userAddress) internal {
        vault.users.push(_userAddress);
        usersMapping[_userAddress].userAddress = _userAddress;
    }

    function _removeUserFromVault(address _userAddress) internal {
        // TODO remove user from users array;
        usersMapping[_userAddress].userAddress = address(0);
        usersMapping[_userAddress].isRegistered = false;
        vault.registeredUsersCount--;
    }

    function _performRotationThresholdUpdate(uint256 _newThreshold) internal {
        vault.rotateThreshold = _newThreshold;
    }

    function _performTransactionThresholdUpdate(uint256 _newThreshold) internal {
        vault.transactionThreshold = _newThreshold;
    }

    function _performAdminThresholdUpdate(uint256 _newThreshold) internal {
        vault.adminThreshold = _newThreshold;
    }

    function _isRegistrationPeriodExpired(uint256 _date) private view returns (bool) {
        return (_date + VAULT_REGISTRATION_PERIOD) < block.timestamp;
    }

    // TODO to use in a library maybe
    function _isValidThreshold(uint256 threshold) internal pure returns(bool) {
        return (threshold > 0 && threshold <= 100);
    }

    function vaultInfos() external view returns(Vault memory) {
        return vault;
    }

    function userInfos(address user) external view returns(bool isPartOfVault, bool isRegistered) {
        isPartOfVault = usersMapping[user].userAddress == user;
        isRegistered = usersMapping[user].isRegistered;
    }
}