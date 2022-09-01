/// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '@gnosis.pm/zodiac/contracts/core/Module.sol';
import './ProposalRelayer.sol';

/**
 * @title Snapshot X L1 execution Zodiac module
 * @author @Orland0x - <[email protected]>
 * @notice Trustless L1 execution of Snapshot X decisions via a Gnosis Safe
 * @dev Work in progress
 */
contract SnapshotXL1Executor is Module, SnapshotXProposalRelayer {
  /// @dev keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
  bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
    0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

  /// @dev keccak256("Transaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)");
  bytes32 public constant TRANSACTION_TYPEHASH =
    0x72e9670a7ee00f5fbf1049b8c38e3f22fab7e9b85029e85cf9412f17fdd5c2ad;

  /// Counter that is incremented each time a proposal is received.
  uint256 public proposalIndex;

  /// Mapping of whitelisted contracts (addresses should be L2 space contracts)
  mapping(uint256 => bool) public whitelistedSpaces;

  /// The state of a proposal index exists in one of the 5 categories. This can be queried using the getProposalState view function
  enum ProposalState {
    NotReceived,
    Received,
    Executing,
    Executed,
    Cancelled
  }

  /// Stores the execution details and execution progress of each proposal received
  struct ProposalExecution {
    // array of Transaction Hashes for each transaction in the proposal
    bytes32[] txHashes;
    // counter which stores the index of the next transaction in the proposal that should be executed
    uint256 executionCounter;
    // whether the proposal has been cancelled. Required to fully define the proposal state as a function of this struct
    bool cancelled;
  }

  /// Map of proposal index to the corresponding proposal execution struct
  mapping(uint256 => ProposalExecution) public proposalIndexToProposalExecution;

  /* EVENTS */

  /**
   * @dev Emitted when a new module proxy instance has been deployed
   * @param initiator Address of contract deployer
   * @param _owner Address of the owner of this contract
   * @param _avatar Address that will ultimately execute function calls
   * @param _target Address that this contract will pass transactions to
   * @param _l2ExecutionRelayer Address of the StarkNet contract that will send execution details to this contract in a L2 -> L1 message
   * @param _starknetCore Address of the StarkNet Core contract
   */
  event SnapshotXL1ExecutorSetUpComplete(
    address indexed initiator,
    address indexed _owner,
    address indexed _avatar,
    address _target,
    uint256 _l2ExecutionRelayer,
    address _starknetCore
  );

  /**
   * @dev Emitted when a new proposal is received from StarkNet
   * @param proposalIndex Index of proposal
   */
  event ProposalReceived(uint256 proposalIndex);

  /**
   * @dev Emitted when a Transaction in a proposal is executed.
   * @param proposalIndex Index of proposal
   * @param txHash The transaction hash
   * @notice Could remove to save some gas and only emit event when all txs are executed
   */
  event TransactionExecuted(uint256 proposalIndex, bytes32 txHash);

  /**
   * @dev Emitted when all transactions in a proposal have been executed
   * @param proposalIndex Index of proposal
   */
  event ProposalExecuted(uint256 proposalIndex);

  /**
   * @dev Emitted when a proposal get cancelled
   * @param proposalIndex Index of proposal
   */
  event ProposalCancelled(uint256 proposalIndex);

  /* Constructor */

  /**
   * @dev Constructs the master contract
   * @param _owner Address of the owner of this contract
   * @param _avatar Address that will ultimately execute function calls
   * @param _target Address that this contract will pass transactions to
   * @param _starknetCore Address of the StarkNet Core contract
   * @param _l2ExecutionRelayer Address of the StarkNet contract that will send execution details to this contract in a L2 -> L1 message
   * @param _l2SpacesToWhitelist Array of spaces deployed on L2 that are allowed to interact with this contract
   */
  constructor(
    address _owner,
    address _avatar,
    address _target,
    address _starknetCore,
    uint256 _l2ExecutionRelayer,
    uint256[] memory _l2SpacesToWhitelist
  ) {
    bytes memory initParams = abi.encode(
      _owner,
      _avatar,
      _target,
      _starknetCore,
      _l2ExecutionRelayer,
      _l2SpacesToWhitelist
    );
    setUp(initParams);
  }

  /**
   * @dev Proxy constructor
   * @param initParams Initialization parameters
   */
  function setUp(bytes memory initParams) public override initializer {
    (
      address _owner,
      address _avatar,
      address _target,
      address _starknetCore,
      uint256 _l2ExecutionRelayer,
      uint256[] memory _l2SpacesToWhitelist
    ) = abi.decode(initParams, (address, address, address, address, uint256, uint256[]));
    __Ownable_init();
    transferOwnership(_owner);
    avatar = _avatar;
    target = _target;
    setUpSnapshotXProposalRelayer(_starknetCore, _l2ExecutionRelayer);

    for (uint256 i = 0; i < _l2SpacesToWhitelist.length; i++) {
      whitelistedSpaces[_l2SpacesToWhitelist[i]] = true;
    }

    emit SnapshotXL1ExecutorSetUpComplete(
      msg.sender,
      _owner,
      _avatar,
      _target,
      _l2ExecutionRelayer,
      _starknetCore
    );
  }

  /* External */

  /**
   * @dev Updates the list of accepted spaces on l2. Only callable by the `owner`.
   * @param toAdd List of addresses to add to the whitelist.
   * @param toRemove List of addressess to remove from the whitelist.
   */
  function editWhitelist(uint256[] memory toAdd, uint256[] calldata toRemove) external onlyOwner {
    // Add the requested entries
    for (uint256 i = 0; i < toAdd.length; i++) {
      whitelistedSpaces[toAdd[i]] = true;
    }

    // Remove the requested entries
    for (uint256 i = 0; i < toRemove.length; i++) {
      whitelistedSpaces[toRemove[i]] = false;
    }
  }

  /**
   * @dev Initializes a new proposal execution struct on the receival of a completed proposal from StarkNet
   * @param executionHashLow Lowest 128 bits of the hash of all the transactions in the proposal
   * @param executionHashHigh Highest 128 bits of the hash of all the transactions in the proposal
   * @param proposalOutcome Whether the proposal was accepted / rejected / cancelled
   * @param _txHashes Array of transaction hashes in proposal
   */
  function receiveProposal(
    uint256 callerAddress,
    uint256 proposalOutcome,
    uint256 executionHashLow,
    uint256 executionHashHigh,
    bytes32[] memory _txHashes
  ) external {
    require(proposalOutcome != 0, 'Proposal did not pass');
    require(_txHashes.length > 0, 'proposal must contain transactions');
    require(whitelistedSpaces[callerAddress] == true, 'Invalid caller');

    //External call will fail if finalized proposal message was not received on L1.
    _receiveFinalizedProposal(callerAddress, proposalOutcome, executionHashLow, executionHashHigh);

    // Re-assemble the lowest and highest bytes to get the full execution hash
    uint256 executionHash = (executionHashHigh << 128) + executionHashLow;
    require(bytes32(executionHash) == keccak256(abi.encode(_txHashes)), 'Invalid execution');

    proposalIndexToProposalExecution[proposalIndex].txHashes = _txHashes;
    proposalIndex++;
    emit ProposalReceived(proposalIndex);
  }

  /**
   * @dev Initializes a new proposal execution struct (To test execution without actually receiving message)
   * @param executionHash Hash of all the transactions in the proposal
   * @param proposalOutcome Whether proposal was accepted / rejected / cancelled
   * @param _txHashes Array of transaction hashes in proposal
   */
  function receiveProposalTest(
    uint256 callerAddress,
    uint256 executionHash,
    uint256 proposalOutcome,
    bytes32[] memory _txHashes
  ) external {
    require(callerAddress != 0);
    require(proposalOutcome == 1, 'Proposal did not pass');
    require(_txHashes.length > 0, 'proposal must contain transactions');
    require(bytes32(executionHash) == keccak256(abi.encode(_txHashes)), 'Invalid execution');
    proposalIndexToProposalExecution[proposalIndex].txHashes = _txHashes;
    proposalIndex++;
    emit ProposalReceived(proposalIndex);
  }

  /**
   * @dev Cancels a set of proposals
   * @param _proposalIndexes Array of proposal indexes that should be cancelled
   */
  function cancelProposals(uint256[] memory _proposalIndexes) external onlyOwner {
    for (uint256 i = 0; i < _proposalIndexes.length; i++) {
      require(
        getProposalState(_proposalIndexes[i]) != ProposalState.NotReceived,
        'Proposal not received, nothing to cancel'
      );
      require(
        getProposalState(_proposalIndexes[i]) != ProposalState.Executed,
        'Execution completed, nothing to cancel'
      );
      require(
        proposalIndexToProposalExecution[_proposalIndexes[i]].cancelled == false,
        'proposal is already cancelled'
      );
      //to cancel a proposal, we can set the execution counter for the proposal to the number of transactions in the proposal.
      //We must also set a boolean in the Proposal Execution struct to true, without this there would be no way for the state to differentiate between a cancelled and an executed proposal.
      proposalIndexToProposalExecution[_proposalIndexes[i]]
        .executionCounter = proposalIndexToProposalExecution[_proposalIndexes[i]].txHashes.length;
      proposalIndexToProposalExecution[_proposalIndexes[i]].cancelled = true;
      emit ProposalCancelled(_proposalIndexes[i]);
    }
  }

  /**
   * @dev Executes a single transaction in a proposal
   * @param _proposalIndex Index of proposal
   * @param to the contract to be called by the avatar
   * @param value ether value to pass with the call
   * @param data the data to be executed from the call
   * @param operation Call or DelegateCall indicator
   */
  function executeProposalTx(
    uint256 _proposalIndex,
    address to,
    uint256 value,
    bytes memory data,
    Enum.Operation operation
  ) public {
    bytes32 txHash = getTransactionHash(to, value, data, operation);
    require(
      proposalIndexToProposalExecution[_proposalIndex].txHashes[
        proposalIndexToProposalExecution[_proposalIndex].executionCounter
      ] == txHash,
      'Invalid transaction or invalid transaction order'
    );
    proposalIndexToProposalExecution[_proposalIndex].executionCounter++;
    require(exec(to, value, data, operation), 'Module transaction failed');
    emit TransactionExecuted(_proposalIndex, txHash);
    if (getProposalState(_proposalIndex) == ProposalState.Executed) {
      emit ProposalExecuted(_proposalIndex);
    }
  }

  /**
   * @dev Wrapper function around executeProposalTx that will execute all transactions in a proposal
   * @param _proposalIndex Index of proposal
   * @param tos Array of contracts to be called by the avatar
   * @param values Array of ether values to pass with the calls
   * @param data Array of data to be executed from the calls
   * @param operations Array of Call or DelegateCall indicators
   */
  function executeProposalTxBatch(
    uint256 _proposalIndex,
    address[] memory tos,
    uint256[] memory values,
    bytes[] memory data,
    Enum.Operation[] memory operations
  ) external {
    for (uint256 i = 0; i < tos.length; i++) {
      executeProposalTx(_proposalIndex, tos[i], values[i], data[i], operations[i]);
    }
  }

  /* VIEW FUNCTIONS */

  /**
   * @dev Returns state of proposal
   * @param _proposalIndex Index of proposal
   */
  function getProposalState(uint256 _proposalIndex) public view returns (ProposalState) {
    ProposalExecution storage proposalExecution = proposalIndexToProposalExecution[_proposalIndex];
    if (proposalExecution.txHashes.length == 0) {
      return ProposalState.NotReceived;
    } else if (proposalExecution.cancelled) {
      return ProposalState.Cancelled;
    } else if (proposalExecution.executionCounter == 0) {
      return ProposalState.Received;
    } else if (proposalExecution.txHashes.length == proposalExecution.executionCounter) {
      return ProposalState.Executed;
    } else {
      return ProposalState.Executing;
    }
  }

  /**
   * @dev Gets number of transactions in a proposal
   * @param _proposalIndex Index of proposal
   * @return numTx Number of transactions in the proposal
   */
  function getNumOfTxInProposal(uint256 _proposalIndex) public view returns (uint256 numTx) {
    require(_proposalIndex < proposalIndex, 'Invalid Proposal Index');
    return proposalIndexToProposalExecution[_proposalIndex].txHashes.length;
  }

  /**
   * @dev Gets hash of transaction in a proposal
   * @param _proposalIndex Index of proposal
   * @param txIndex Index of transaction in proposal
   * @param txHash Transaction Hash
   */
  function getTxHash(uint256 _proposalIndex, uint256 txIndex) public view returns (bytes32 txHash) {
    require(_proposalIndex < proposalIndex, 'Invalid Proposal Index');
    require(txIndex < proposalIndexToProposalExecution[_proposalIndex].txHashes.length);
    return proposalIndexToProposalExecution[_proposalIndex].txHashes[txIndex];
  }

  /**
   * @dev Gets whether transaction has been executed
   * @param _proposalIndex Index of proposal
   * @param txIndex Index of transaction in proposal
   * @param isExecuted Is transaction executed
   */
  function isTxExecuted(uint256 _proposalIndex, uint256 txIndex)
    public
    view
    returns (bool isExecuted)
  {
    require(_proposalIndex < proposalIndex, 'Invalid Proposal Index');
    require(txIndex < proposalIndexToProposalExecution[_proposalIndex].txHashes.length);
    return proposalIndexToProposalExecution[_proposalIndex].executionCounter > txIndex;
  }

  /**
   * @dev Generates the data for the module transaction hash (required for signing)
   * @param to the contract to be called by the avatar
   * @param value ether value to pass with the call
   * @param data the data to be executed from the call
   * @param operation Call or DelegateCall indicator
   * @return txHashData Transaction hash data
   */
  function generateTransactionHashData(
    address to,
    uint256 value,
    bytes memory data,
    Enum.Operation operation,
    uint256 nonce
  ) public view returns (bytes memory txHashData) {
    uint256 chainId = block.chainid;
    bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, chainId, this));
    bytes32 transactionHash = keccak256(
      abi.encode(TRANSACTION_TYPEHASH, to, value, keccak256(data), operation, nonce)
    );
    return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, transactionHash);
  }

  /**
   * @dev Generates transaction hash
   * @param to the contract to be called by the avatar
   * @param value ether value to pass with the call
   * @param data the data to be executed from the call
   * @param operation Call or DelegateCall indicator
   * @return txHash Transaction hash
   */
  function getTransactionHash(
    address to,
    uint256 value,
    bytes memory data,
    Enum.Operation operation
  ) public view returns (bytes32 txHash) {
    return keccak256(generateTransactionHashData(to, value, data, operation, 0));
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "../factory/FactoryFriendly.sol";
import "../guard/Guardable.sol";

abstract contract Module is FactoryFriendly, Guardable {
    /// @dev Address that will ultimately execute function calls.
    address public avatar;
    /// @dev Address that this module will pass transactions to.
    address public target;

    /// @dev Emitted each time the avatar is set.
    event AvatarSet(address indexed previousAvatar, address indexed newAvatar);
    /// @dev Emitted each time the Target is set.
    event TargetSet(address indexed previousTarget, address indexed newTarget);

    /// @dev Sets the avatar to a new avatar (`newAvatar`).
    /// @notice Can only be called by the current owner.
    function setAvatar(address _avatar) public onlyOwner {
        address previousAvatar = avatar;
        avatar = _avatar;
        emit AvatarSet(previousAvatar, _avatar);
    }

    /// @dev Sets the target to a new target (`newTarget`).
    /// @notice Can only be called by the current owner.
    function setTarget(address _target) public onlyOwner {
        address previousTarget = target;
        target = _target;
        emit TargetSet(previousTarget, _target);
    }

    /// @dev Passes a transaction to be executed by the avatar.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function exec(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        /// Check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
        }
        success = IAvatar(target).execTransactionFromModule(
            to,
            value,
            data,
            operation
        );
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return success;
    }

    /// @dev Passes a transaction to be executed by the target and returns data.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execAndReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success, bytes memory returnData) {
        /// Check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
        }
        (success, returnData) = IAvatar(target)
            .execTransactionFromModuleReturnData(to, value, data, operation);
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return (success, returnData);
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '@gnosis.pm/zodiac/contracts/guard/Guardable.sol';
// import '../Interfaces/IStarknetCore.sol';

import 'contracts/ethereum/TestContracts/MockStarknetMessaging.sol';

/**
 * @title Snapshot X L1 Proposal Relayer
 * @author @Orland0x - <[email protected]>
 * @dev Work in progress
 */
contract SnapshotXProposalRelayer is Guardable {
  /// The StarkNet Core contract
  // IStarknetCore public starknetCore;

  MockStarknetMessaging public starknetCore;

  /// Address of the StarkNet contract that will send execution details to this contract in a L2 -> L1 message
  uint256 public l2ExecutionRelayer;

  /**
   * @dev Emitted when the StarkNet execution relayer contract is changed
   * @param _l2ExecutionRelayer The new execution relayer contract
   */
  event ChangedL2ExecutionRelayer(uint256 _l2ExecutionRelayer);

  // /**
  //  * @dev Initialization of the functionality. Called internally by the setUp function
  //  * @param _starknetCore Address of the StarkNet Core contract
  //  * @param _l2ExecutionRelayer Address of the new execution relayer contract
  //  */
  // function setUpSnapshotXProposalRelayer(address _starknetCore, uint256 _l2ExecutionRelayer)
  //   internal
  // {
  //   starknetCore = IStarknetCore(_starknetCore);
  //   l2ExecutionRelayer = _l2ExecutionRelayer;
  // }

  function setUpSnapshotXProposalRelayer(address _starknetCore, uint256 _l2ExecutionRelayer)
    internal
  {
    starknetCore = MockStarknetMessaging(_starknetCore);
    l2ExecutionRelayer = _l2ExecutionRelayer;
  }

  /**
   * @dev Changes the StarkNet execution relayer contract
   * @param _l2ExecutionRelayer Address of the new execution relayer contract
   */
  function changeL2ExecutionRelayer(uint256 _l2ExecutionRelayer) public onlyOwner {
    l2ExecutionRelayer = _l2ExecutionRelayer;
    emit ChangedL2ExecutionRelayer(_l2ExecutionRelayer);
  }

  /**
   * @dev Receives L2 -> L1 message containing proposal execution details
   * @param executionHashLow Lowest 128 bits of the hash of all the transactions in the proposal
   * @param executionHashHigh Highest 128 bits of the hash of all the transactions in the proposal
   * @param proposalOutcome Whether the proposal has been accepted / rejected / cancelled
   */
  function _receiveFinalizedProposal(
    uint256 callerAddress,
    uint256 proposalOutcome,
    uint256 executionHashLow,
    uint256 executionHashHigh
  ) internal {
    uint256[] memory payload = new uint256[](4);
    payload[0] = callerAddress;
    payload[1] = proposalOutcome;
    payload[2] = executionHashLow;
    payload[3] = executionHashHigh;

    /// Returns the message Hash. If proposal execution message did not exist/not received yet, then this will fail
    starknetCore.consumeMessageFromL2(l2ExecutionRelayer, payload);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./BaseGuard.sol";

/// @title Guardable - A contract that manages fallback calls made to this contract
contract Guardable is OwnableUpgradeable {
    address public guard;

    event ChangedGuard(address guard);

    /// `guard_` does not implement IERC165.
    error NotIERC165Compliant(address guard_);

    /// @dev Set a guard that checks transactions before execution.
    /// @param _guard The address of the guard to be used or the 0 address to disable the guard.
    function setGuard(address _guard) external onlyOwner {
        if (_guard != address(0)) {
            if (!BaseGuard(_guard).supportsInterface(type(IGuard).interfaceId))
                revert NotIERC165Compliant(_guard);
        }
        guard = _guard;
        emit ChangedGuard(guard);
    }

    function getGuard() external view returns (address _guard) {
        return guard;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// @dev Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// @notice This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.6;

import './StarknetMessaging.sol';

contract MockStarknetMessaging is StarknetMessaging {
  /**
      Mocks a message from L2 to L1.
    */
  function mockSendMessageFromL2(
    uint256 from_address,
    uint256 to_address,
    uint256[] calldata payload
  ) external {
    bytes32 msgHash = keccak256(
      abi.encodePacked(from_address, to_address, payload.length, payload)
    );
    l2ToL1Messages()[msgHash] += 1;
  }

  /**
      Mocks consumption of a message from L1 to L2.
    */
  function mockConsumeMessageToL2(
    uint256 from_address,
    uint256 to_address,
    uint256 selector,
    uint256[] calldata payload,
    uint256 nonce
  ) external {
    bytes32 msgHash = keccak256(
      abi.encodePacked(from_address, to_address, nonce, selector, payload.length, payload)
    );

    require(l1ToL2Messages()[msgHash] > 0, 'INVALID_MESSAGE_TO_CONSUME');
    l1ToL2Messages()[msgHash] -= 1;
  }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.6;

import './IStarknetMessaging.sol';
import './NamedStorage.sol';

/**
  Implements sending messages to L2 by adding them to a pipe and consuming messages from L2 by
  removing them from a different pipe. A deriving contract can handle the former pipe and add items
  to the latter pipe while interacting with L2.
*/
contract StarknetMessaging is IStarknetMessaging {
  /**
      Random slot storage elements and accessors.
    */
  string constant L1L2_MESSAGE_MAP_TAG = 'STARKNET_1.0_MSGING_L1TOL2_MAPPPING_V2';
  string constant L2L1_MESSAGE_MAP_TAG = 'STARKNET_1.0_MSGING_L2TOL1_MAPPPING';

  string constant L1L2_MESSAGE_NONCE_TAG = 'STARKNET_1.0_MSGING_L1TOL2_NONCE';

  function l1ToL2Messages(bytes32 msgHash) external view returns (uint256) {
    return l1ToL2Messages()[msgHash];
  }

  function l2ToL1Messages(bytes32 msgHash) external view returns (uint256) {
    return l2ToL1Messages()[msgHash];
  }

  function l1ToL2Messages() internal pure returns (mapping(bytes32 => uint256) storage) {
    return NamedStorage.bytes32ToUint256Mapping(L1L2_MESSAGE_MAP_TAG);
  }

  function l2ToL1Messages() internal pure returns (mapping(bytes32 => uint256) storage) {
    return NamedStorage.bytes32ToUint256Mapping(L2L1_MESSAGE_MAP_TAG);
  }

  function l1ToL2MessageNonce() public view returns (uint256) {
    return NamedStorage.getUintValue(L1L2_MESSAGE_NONCE_TAG);
  }

  /**
      Sends a message to an L2 contract.
    */
  function sendMessageToL2(
    uint256 to_address,
    uint256 selector,
    uint256[] calldata payload
  ) external override returns (bytes32) {
    uint256 nonce = l1ToL2MessageNonce();
    NamedStorage.setUintValue(L1L2_MESSAGE_NONCE_TAG, nonce + 1);
    emit LogMessageToL2(msg.sender, to_address, selector, payload, nonce);
    bytes32 msgHash = keccak256(
      abi.encodePacked(
        uint256(uint160(address(msg.sender))),
        to_address,
        nonce,
        selector,
        payload.length,
        payload
      )
    );
    l1ToL2Messages()[msgHash] += 1;

    return msgHash;
  }

  /**
      Consumes a message that was sent from an L2 contract.
      Returns the hash of the message.
    */
  function consumeMessageFromL2(uint256 from_address, uint256[] calldata payload)
    external
    override
    returns (bytes32)
  {
    bytes32 msgHash = keccak256(
      abi.encodePacked(from_address, uint256(uint160(address(msg.sender))), payload.length, payload)
    );

    require(l2ToL1Messages()[msgHash] > 0, 'INVALID_MESSAGE_TO_CONSUME');
    emit ConsumedMessageToL1(from_address, msg.sender, payload);
    l2ToL1Messages()[msgHash] -= 1;
    return msgHash;
  }
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.6;

interface IStarknetMessaging {
  event LogMessageToL1(uint256 indexed from_address, address indexed to_address, uint256[] payload);

  // An event that is raised when a message is sent from L1 to L2.
  event LogMessageToL2(
    address indexed from_address,
    uint256 indexed to_address,
    uint256 indexed selector,
    uint256[] payload,
    uint256 nonce
  );

  // An event that is raised when a message from L2 to L1 is consumed.
  event ConsumedMessageToL1(
    uint256 indexed from_address,
    address indexed to_address,
    uint256[] payload
  );

  // An event that is raised when a message from L1 to L2 is consumed.
  event ConsumedMessageToL2(
    address indexed from_address,
    uint256 indexed to_address,
    uint256 indexed selector,
    uint256[] payload,
    uint256 nonce
  );

  /**
      Sends a message to an L2 contract.
      Returns the hash of the message.
    */
  function sendMessageToL2(
    uint256 to_address,
    uint256 selector,
    uint256[] calldata payload
  ) external returns (bytes32);

  /**
      Consumes a message that was sent from an L2 contract.
      Returns the hash of the message.
    */
  function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
    external
    returns (bytes32);
}

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.6;

/*
  Library to provide basic storage, in storage location out of the low linear address space.
  New types of storage variables should be added here upon need.
*/
library NamedStorage {
  function bytes32ToUint256Mapping(string memory tag_)
    internal
    pure
    returns (mapping(bytes32 => uint256) storage randomVariable)
  {
    bytes32 location = keccak256(abi.encodePacked(tag_));
    assembly {
      randomVariable.slot := location
    }
  }

  function bytes32ToAddressMapping(string memory tag_)
    internal
    pure
    returns (mapping(bytes32 => address) storage randomVariable)
  {
    bytes32 location = keccak256(abi.encodePacked(tag_));
    assembly {
      randomVariable.slot := location
    }
  }

  function addressToBoolMapping(string memory tag_)
    internal
    pure
    returns (mapping(address => bool) storage randomVariable)
  {
    bytes32 location = keccak256(abi.encodePacked(tag_));
    assembly {
      randomVariable.slot := location
    }
  }

  function getUintValue(string memory tag_) internal view returns (uint256 retVal) {
    bytes32 slot = keccak256(abi.encodePacked(tag_));
    assembly {
      retVal := sload(slot)
    }
  }

  function setUintValue(string memory tag_, uint256 value) internal {
    bytes32 slot = keccak256(abi.encodePacked(tag_));
    assembly {
      sstore(slot, value)
    }
  }

  function setUintValueOnce(string memory tag_, uint256 value) internal {
    require(getUintValue(tag_) == 0, 'ALREADY_SET');
    setUintValue(tag_, value);
  }

  function getAddressValue(string memory tag_) internal view returns (address retVal) {
    bytes32 slot = keccak256(abi.encodePacked(tag_));
    assembly {
      retVal := sload(slot)
    }
  }

  function setAddressValue(string memory tag_, address value) internal {
    bytes32 slot = keccak256(abi.encodePacked(tag_));
    assembly {
      sstore(slot, value)
    }
  }

  function setAddressValueOnce(string memory tag_, address value) internal {
    require(getAddressValue(tag_) == address(0x0), 'ALREADY_SET');
    setAddressValue(tag_, value);
  }

  function getBoolValue(string memory tag_) internal view returns (bool retVal) {
    bytes32 slot = keccak256(abi.encodePacked(tag_));
    assembly {
      retVal := sload(slot)
    }
  }

  function setBoolValue(string memory tag_, bool value) internal {
    bytes32 slot = keccak256(abi.encodePacked(tag_));
    assembly {
      sstore(slot, value)
    }
  }
}