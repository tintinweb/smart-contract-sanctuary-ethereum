pragma solidity ^0.8.13;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./interfaces/IExecutor.sol";

/// @author Matter Labs
/// @notice Intermediate smart contract between the validator EOA account and the zkSync smart contract.
/// @dev The primary purpose of this contract is to provide a trustless means of delaying block execution without
/// modifying the main zkSync contract. As such, even if this contract is compromised, it will not impact the main contract.
/// @dev zkSync actively monitors the chain activity and reacts to any suspicious activity by freezing the chain.
/// This allows time for investigation and mitigation before resuming normal operations.
/// @dev The contract overloads all of the 4 methods, that are used in state transition. When the block is committed, the
/// timestamp is stored for it. Later, when the owner calls the block execution, the contract checks that block
/// was committed not earlier than X time ago.
contract ValidatorTimelock is IExecutor, Ownable2Step {
    /// @notice The delay between committing and executing blocks is changed.
    event NewExecutionDelay(uint256 _newExecutionDelay);

    /// @notice The validator address is changed.
    event NewValidator(address _oldValidator, address _newValidator);

    /// @dev The main zkSync smart contract.
    address public immutable zkSyncContract;

    /// @dev The mapping of L2 block number => timestamp when it was commited.
    mapping(uint256 => uint256) public committedBlockTimestamp;

    /// @dev The address that can commit/revert/validate/execute blocks.
    address public validator;

    /// @dev The delay between committing and executing blocks.
    uint256 public executionDelay;

    constructor(
        address _initialOwner,
        address _zkSyncContract,
        uint256 _executionDelay,
        address _validator
    ) {
        _transferOwnership(_initialOwner);
        zkSyncContract = _zkSyncContract;
        executionDelay = _executionDelay;
        validator = _validator;
    }

    /// @dev Set new validator address.
    function setValidator(address _newValidator) external onlyOwner {
        address oldValidator = validator;
        validator = _newValidator;
        emit NewValidator(oldValidator, _newValidator);
    }

    /// @dev Set the delay between committing and executing blocks.
    function setExecutionDelay(uint256 _executionDelay) external onlyOwner {
        executionDelay = _executionDelay;
        emit NewExecutionDelay(_executionDelay);
    }

    /// @notice Checks if the caller is a validator.
    modifier onlyValidator() {
        require(msg.sender == validator, "8h");
        _;
    }

    /// @dev Records the timestamp for all provided committed blocks and make
    /// a call to the zkSync contract with the same calldata.
    function commitBlocks(StoredBlockInfo calldata, CommitBlockInfo[] calldata _newBlocksData) external onlyValidator {
        for (uint256 i = 0; i < _newBlocksData.length; ++i) {
            committedBlockTimestamp[_newBlocksData[i].blockNumber] = block.timestamp;
        }

        _propagateToZkSync();
    }

    /// @dev Make a call to the zkSync contract with the same calldata.
    /// Note: If the block is reverted, it needs to be committed first before the execution.
    /// So it's safe to not override the committed blocks.
    function revertBlocks(uint256) external onlyValidator {
        _propagateToZkSync();
    }

    /// @dev Make a call to the zkSync contract with the same calldata.
    /// Note: We don't track the time when blocks are proven, since all information about
    /// the block is known on the commit stage and the proved is not finalized (may be reverted).
    function proveBlocks(
        StoredBlockInfo calldata,
        StoredBlockInfo[] calldata,
        ProofInput calldata
    ) external onlyValidator {
        _propagateToZkSync();
    }

    /// @dev Check that blocks were committed at least X time ago and
    /// make a call to the zkSync contract with the same calldata.
    function executeBlocks(StoredBlockInfo[] calldata _newBlocksData) external onlyValidator {
        for (uint256 i = 0; i < _newBlocksData.length; ++i) {
            uint256 commitBlockTimestamp = committedBlockTimestamp[_newBlocksData[i].blockNumber];

            // Note: if the `commitBlockTimestamp` is zero, that means either:
            // * The block was committed, but not though this contract.
            // * The block wasn't committed at all, so execution will fail in the zkSync contract.
            // We allow executing such blocks.

            require(block.timestamp > commitBlockTimestamp + executionDelay, "5c"); // The delay is not passed
        }

        _propagateToZkSync();
    }

    /// @dev Call the zkSync contract with the same calldata as this contract was called.
    /// Note: it is called the zkSync contract, not delegatecalled!
    function _propagateToZkSync() internal {
        address contractAddress = zkSyncContract;
        assembly {
            // Copy function signature and arguments from calldata at zero position into memory at pointer position
            calldatacopy(0, 0, calldatasize())
            // Call method of the zkSync contract returns 0 on error
            let result := call(gas(), contractAddress, 0, 0, calldatasize(), 0, 0)
            // Get the size of the last return data
            let size := returndatasize()
            // Copy the size length of bytes from return data at zero position to pointer position
            returndatacopy(0, 0, size)
            // Depending on the result value
            switch result
            case 0 {
                // End execution and revert state changes
                revert(0, size)
            }
            default {
                // Return data with length of size at pointers position
                return(0, size)
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

pragma solidity ^0.8.13;

// SPDX-License-Identifier: MIT



interface IExecutor {
    /// @notice Rollup block stored data
    /// @param blockNumber Rollup block number
    /// @param blockHash Hash of L2 block
    /// @param indexRepeatedStorageChanges The serial number of the shortcut index that's used as a unique identifier for storage keys that were used twice or more
    /// @param numberOfLayer1Txs Number of priority operations to be processed
    /// @param priorityOperationsHash Hash of all priority operations from this block
    /// @param l2LogsTreeRoot Root hash of tree that contains L2 -> L1 messages from this block
    /// @param timestamp Rollup block timestamp, have the same format as Ethereum block constant
    /// @param commitment Verified input for the zkSync circuit
    struct StoredBlockInfo {
        uint64 blockNumber;
        bytes32 blockHash;
        uint64 indexRepeatedStorageChanges;
        uint256 numberOfLayer1Txs;
        bytes32 priorityOperationsHash;
        bytes32 l2LogsTreeRoot;
        uint256 timestamp;
        bytes32 commitment;
    }

    /// @notice Data needed to commit new block
    /// @param blockNumber Number of the committed block
    /// @param timestamp Unix timestamp denoting the start of the block execution
    /// @param indexRepeatedStorageChanges The serial number of the shortcut index that's used as a unique identifier for storage keys that were used twice or more
    /// @param newStateRoot The state root of the full state tree
    /// @param numberOfLayer1Txs Number of priority operations to be processed
    /// @param l2LogsTreeRoot The root hash of the tree that contains all L2 -> L1 logs in the block
    /// @param priorityOperationsHash Hash of all priority operations from this block
    /// @param initialStorageChanges Storage write access as a concatenation key-value
    /// @param repeatedStorageChanges Storage write access as a concatenation index-value
    /// @param l2Logs concatenation of all L2 -> L1 logs in the block
    /// @param l2ArbitraryLengthMessages array of hash preimages that were sent as value of L2 logs by special system L2 contract
    /// @param factoryDeps array of l2 bytecodes that were marked as known on L2
    struct CommitBlockInfo {
        uint64 blockNumber;
        uint64 timestamp;
        uint64 indexRepeatedStorageChanges;
        bytes32 newStateRoot;
        uint256 numberOfLayer1Txs;
        bytes32 l2LogsTreeRoot;
        bytes32 priorityOperationsHash;
        bytes32 initialStorageChangesHash;
        bytes32 repeatedStorageChangesHash;
        bytes l2Logs;
    }

    /// @notice Recursive proof input data (individual commitments are constructed onchain)
    struct ProofInput {
        uint256[] recursiveAggregationInput;
        uint256[] serializedProof;
    }

    function commitBlocks(StoredBlockInfo calldata _lastCommittedBlockData, CommitBlockInfo[] calldata _newBlocksData)
        external;

    function proveBlocks(
        StoredBlockInfo calldata _prevBlock,
        StoredBlockInfo[] calldata _committedBlocks,
        ProofInput calldata _proof
    ) external;

    function executeBlocks(StoredBlockInfo[] calldata _blocksData) external;

    function revertBlocks(uint256 _newLastBlock) external;

    /// @notice Event emitted when a block is committed
    event BlockCommit(uint256 indexed blockNumber, bytes32 indexed blockHash, bytes32 indexed commitment);

    /// @notice Event emitted when blocks are verified
    event BlocksVerification(uint256 indexed previousLastVerifiedBlock, uint256 indexed currentLastVerifiedBlock);

    /// @notice Event emitted when a block is executed
    event BlockExecution(uint256 indexed blockNumber, bytes32 indexed blockHash, bytes32 indexed commitment);

    /// @notice Event emitted when blocks are reverted
    event BlocksRevert(uint256 totalBlocksCommitted, uint256 totalBlocksVerified, uint256 totalBlocksExecuted);
}