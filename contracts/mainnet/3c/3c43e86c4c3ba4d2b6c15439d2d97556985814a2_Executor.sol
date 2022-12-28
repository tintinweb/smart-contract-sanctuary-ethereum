// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 _______  _______  _______  _        _        _______  _          _______           _        _        _______
(  ____ \(  ____ )(  ___  )( (    /|| \    /\(  ____ \( (    /|  (  ____ )|\     /|( (    /|| \    /\(  ____ \
| (    \/| (    )|| (   ) ||  \  ( ||  \  / /| (    \/|  \  ( |  | (    )|| )   ( ||  \  ( ||  \  / /| (    \/
| (__    | (____)|| (___) ||   \ | ||  (_/ / | (__    |   \ | |  | (____)|| |   | ||   \ | ||  (_/ / | (_____
|  __)   |     __)|  ___  || (\ \) ||   _ (  |  __)   | (\ \) |  |  _____)| |   | || (\ \) ||   _ (  (_____  )
| (      | (\ (   | (   ) || | \   ||  ( \ \ | (      | | \   |  | (      | |   | || | \   ||  ( \ \       ) |
| )      | ) \ \__| )   ( || )  \  ||  /  \ \| (____/\| )  \  |  | )      | (___) || )  \  ||  /  \ \/\____) |
|/       |/   \__/|/     \||/    )_)|_/    \/(_______/|/    )_)  |/       (_______)|/    )_)|_/    \/\_______)

*/

import "./interfaces/IExecutor.sol";
import { FrankenDAOErrors } from "./errors/FrankenDAOErrors.sol";

/// @notice Executor contract that holds treasury funds and executes passed Governance proposals
/** @dev Loosely forked from NounsDAOExecutor.sol (0x0bc3807ec262cb779b38d65b38158acc3bfede10) with following major modifications:
- DELAY and GRACE_PERIOD are hardcoded
- we move admin check logic into a modifier and rename admin to governance
- governance address cannot be changed (in the event of an upgrade, we will first transfer funds to new Executor)
- we don't allow queueing of identical transactions
- we don't check whether transactions are past their grace period because that is checked in Governance */
contract Executor is IExecutor, FrankenDAOErrors {

    /// @notice The delay between when a tx is queued and when it can be executed
    uint256 public constant DELAY = 2 days;

    /// @notice The amount of time a tx can stay queued without being executed before it expires
    uint256 public constant GRACE_PERIOD = 14 days;

    /// @notice The address of the Governance contract
    address public governance;

    /// @notice The tx hash of each queued transaction that is allowed to be executed
    /// @dev The tx hash is a hash of the target address, value, fx signature, data and eta (time execution is permitted)
    mapping(bytes32 => bool) public queuedTransactions;

    /////////////////////////////////
    ////////// CONSTRUCTOR //////////
    /////////////////////////////////

    /// @param _governance The address of the Governance contract
    constructor(address _governance) {
        governance = _governance;
    }

    /////////////////////////////////
    /////////// MODIFIERS ///////////
    /////////////////////////////////

    /// @notice Modifier for functions that can only be called by the Governance contract (via passed proposals)
    modifier onlyGovernance() {
        if (msg.sender != governance) revert NotAuthorized();
        _;
    }

    /////////////////////////////////
    ////////// TX EXECUTION /////////
    /////////////////////////////////

    /// @notice Queues a transaction to be executed after a delay
    /// @param _target The address of the contract to execute the transaction on
    /// @param _value The amount of ETH to send with the transaction
    /// @param _signature The function signature of the transaction
    /// @param _data The data to send with the transaction
    /// @param _eta The time at which the transaction can be executed (must be at least DELAY in the future)
    /// @dev This function is only called by queue() in the Governance contract
    function queueTransaction(
        uint256 _id,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) public onlyGovernance returns (bytes32 txHash) {
        if (block.timestamp + DELAY > _eta) revert DelayNotSatisfied();

        txHash = keccak256(abi.encode(_id, _target, _value, _signature, _data, _eta));
        if (queuedTransactions[txHash]) revert IdenticalTransactionAlreadyQueued();
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, _id, _target, _value, _signature, _data, _eta);
    }

    /// @notice Cancel a queued transaction, preventing it from being executed
    /// @param _id The unique sequential ID provided for each transaction
    /// @param _target The address of the contract to execute the transaction on
    /// @param _value The amount of ETH to send with the transaction
    /// @param _signature The function signature of the transaction
    /// @param _data The data to send with the transaction
    /// @param _eta The time at which the transaction can be executed
    /** @dev This function is only called by _removeTransactionWithQueuedOrExpiredCheck() in the Governance contract,
            which shows up in cancel(), clear() and veto() */
    function cancelTransaction(
        uint256 _id,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) public onlyGovernance {
        bytes32 txHash = keccak256(abi.encode(_id, _target, _value, _signature, _data, _eta));
        if (!queuedTransactions[txHash]) revert TransactionNotQueued();
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, _id, _target, _value, _signature, _data, _eta);
    }

    /// @notice Executes a queued transaction after the delay has passed
    /// @param _id The unique sequential ID provided for each transaction
    /// @param _target The address of the contract to execute the transaction on
    /// @param _value The amount of ETH to send with the transaction
    /// @param _signature The function signature of the transaction
    /// @param _data The data to send with the transaction
    /// @param _eta The time at which the transaction can be executed
    /// @dev This function is only called by execute() in the Governance contract
    function executeTransaction(
        uint256 _id,
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) public onlyGovernance returns (bytes memory) {
        bytes32 txHash = keccak256(abi.encode(_id, _target, _value, _signature, _data, _eta));

        // We don't need to check if it's expired, because this will be caught by the Governance contract.
        // (ie. If we are past the grace period, proposal state will be Expired and execute() will revert.)
        if (!queuedTransactions[txHash]) revert TransactionNotQueued();
        if (_eta > block.timestamp) revert TimelockNotMet();

        queuedTransactions[txHash] = false;

        if (bytes(_signature).length > 0) {
            _data = abi.encodePacked(bytes4(keccak256(bytes(_signature))), _data);
        }

        (bool success, bytes memory returnData) = _target.call{ value: _value }(_data);
        if (!success) revert TransactionReverted();

        emit ExecuteTransaction(txHash, _id, _target, _value, _signature, _data, _eta);
        return returnData;
    }

    /// @notice Contract can receive ETH (needed to add funds to the treasury)
    receive() external payable {}

    /// @notice Contract can receive ETH (needed to add funds to the treasury)
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FrankenDAOErrors {
    // General purpose
    error NotAuthorized();

    // Staking
    error NonExistentToken();
    error InvalidDelegation();
    error Paused();
    error InvalidParameter();
    error TokenLocked();
    error StakedTokensCannotBeTransferred();

    // Governance
    error ZeroAddress();
    error AlreadyInitialized();
    error ParameterOutOfBounds();
    error InvalidId();
    error InvalidProposal();
    error InvalidStatus();
    error InvalidInput();
    error AlreadyVoted();
    error NotEligible();
    error NotInActiveProposals();
    error NotStakingContract();

    // Executor
    error DelayNotSatisfied();
    error IdenticalTransactionAlreadyQueued();
    error TransactionNotQueued();
    error TimelockNotMet();
    error TransactionReverted();
}

pragma solidity ^0.8.10;

interface IExecutor {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a transaction is cancelled
    event CancelTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a transaction is executed
    event ExecuteTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a new delay value is set
    event NewDelay(uint256 indexed newDelay);
    /// @notice Emited when a transaction is queued
    event QueueTransaction(bytes32 indexed txHash, uint256 id, address indexed target, uint256 value, string signature, bytes data, uint256 eta);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function DELAY() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function cancelTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external;

    function executeTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes memory);

    function queueTransaction(uint256 _id, address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes32 txHash);

    function queuedTransactions(bytes32) external view returns (bool);
}