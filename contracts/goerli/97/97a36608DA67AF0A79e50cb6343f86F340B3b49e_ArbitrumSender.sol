// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IOwnable.sol";

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash,
        uint256 baseFeeL1,
        uint64 timestamp
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed to,
        uint256 value,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    event SequencerInboxUpdated(address newSequencerInbox);

    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function enqueueSequencerMessage(bytes32 dataHash, uint256 afterDelayedMessagesRead)
        external
        returns (
            uint256 seqMessageIndex,
            bytes32 beforeAcc,
            bytes32 delayedAcc,
            bytes32 acc
        );

    function submitBatchSpendingReport(address batchPoster, bytes32 dataHash)
        external
        returns (uint256 msgNum);

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setDelayedInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    function setSequencerInbox(address _sequencerInbox) external;

    // View functions

    function sequencerInbox() external view returns (address);

    function activeOutbox() external view returns (address);

    function allowedDelayedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function delayedInboxAccs(uint256 index) external view returns (bytes32);

    function sequencerInboxAccs(uint256 index) external view returns (bytes32);

    function delayedMessageCount() external view returns (uint256);

    function sequencerMessageCount() external view returns (uint256);

    function rollup() external view returns (IOwnable);

    function acceptFundsFromOldBridge() external payable;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

interface IDelayedMessageProvider {
    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    /// @dev event emitted when a inbox message is added to the Bridge's delayed accumulator
    /// same as InboxMessageDelivered but the batch data is available in tx.input
    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";
import "./IDelayedMessageProvider.sol";

interface IInbox is IDelayedMessageProvider {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        uint256 nonce,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 gasLimit,
        uint256 maxFeePerGas,
        address to,
        bytes calldata data
    ) external payable returns (uint256);

    /// @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
    function createRetryableTicket(
        address to,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    /// @dev Gas limit and maxFeePerGas should not be set to 1 as that is used to trigger the RetryableData error
    function unsafeCreateRetryableTicket(
        address to,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth() external payable returns (uint256);

    /// @notice deprecated in favour of depositEth with no parameters
    function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);

    function bridge() external view returns (IBridge);

    function postUpgradeInit(IBridge _bridge) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.21 <0.9.0;

interface IOwnable {
    function owner() external view returns (address);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Methods for managing retryables.
 * @notice Precompiled contract in every Arbitrum chain for retryable transaction related data retrieval and interactions. Exists at 0x000000000000000000000000000000000000006e
 */
interface ArbRetryableTx {
    /**
     * @notice Schedule an attempt to redeem a redeemable tx, donating all of the call's gas to the redeem.
     * Revert if ticketId does not exist.
     * @param ticketId unique identifier of retryable message: keccak256(keccak256(ArbchainId, inbox-sequence-number), uint(0) )
     * @return txId that the redeem attempt will have
     */
    function redeem(bytes32 ticketId) external returns (bytes32);

    /**
     * @notice Return the minimum lifetime of redeemable txn.
     * @return lifetime in seconds
     */
    function getLifetime() external view returns (uint256);

    /**
     * @notice Return the timestamp when ticketId will age out, reverting if it does not exist
     * @param ticketId unique ticket identifier
     * @return timestamp for ticket's deadline
     */
    function getTimeout(bytes32 ticketId) external view returns (uint256);

    /**
     * @notice Adds one lifetime period to the life of ticketId.
     * Donate gas to pay for the lifetime extension.
     * If successful, emits LifetimeExtended event.
     * Revert if ticketId does not exist, or if the timeout of ticketId is already at least one lifetime period in the future.
     * @param ticketId unique ticket identifier
     * @return new timeout of ticketId
     */
    function keepalive(bytes32 ticketId) external returns (uint256);

    /**
     * @notice Return the beneficiary of ticketId.
     * Revert if ticketId doesn't exist.
     * @param ticketId unique ticket identifier
     * @return address of beneficiary for ticket
     */
    function getBeneficiary(bytes32 ticketId) external view returns (address);

    /**
     * @notice Cancel ticketId and refund its callvalue to its beneficiary.
     * Revert if ticketId doesn't exist, or if called by anyone other than ticketId's beneficiary.
     * @param ticketId unique ticket identifier
     */
    function cancel(bytes32 ticketId) external;

    /**
     * @notice Gets the redeemer of the current retryable redeem attempt.
     * Returns the zero address if the current transaction is not a retryable redeem attempt.
     * If this is an auto-redeem, returns the fee refund address of the retryable.
     */
    function getCurrentRedeemer() external view returns (address);

    /**
     * @notice Do not call. This method represents a retryable submission to aid explorers.
     * Calling it will always revert.
     */
    function submitRetryable(
        bytes32 requestId,
        uint256 l1BaseFee,
        uint256 deposit,
        uint256 callvalue,
        uint256 gasFeeCap,
        uint64 gasLimit,
        uint256 maxSubmissionFee,
        address feeRefundAddress,
        address beneficiary,
        address retryTo,
        bytes calldata retryData
    ) external;

    event TicketCreated(bytes32 indexed ticketId);
    event LifetimeExtended(bytes32 indexed ticketId, uint256 newTimeout);
    event RedeemScheduled(
        bytes32 indexed ticketId,
        bytes32 indexed retryTxHash,
        uint64 indexed sequenceNum,
        uint64 donatedGas,
        address gasDonor,
        uint256 maxRefund,
        uint256 submissionFeeRefund
    );
    event Canceled(bytes32 indexed ticketId);

    /// @dev DEPRECATED in favour of new RedeemScheduled event after the nitro upgrade
    event Redeemed(bytes32 indexed userTxHash);

    error NoTicketWithID();
    error NotCallable();
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

import { AddressAliasHelper } from "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import { ArbRetryableTx } from "@arbitrum/nitro-contracts/src/precompiles/ArbRetryableTx.sol";

import { Delegator } from "../Delegator.sol";

/**
 * @title Executor
 * @author Railgun Contributors
 * @notice Stores instructions to execute after L1 sender confirms
 */
contract ArbitrumExecutor {
  // Addresses
  ArbRetryableTx public constant ARB_RETRYABLE_TX =
    ArbRetryableTx(0x000000000000000000000000000000000000006E);
  // solhint-disable-next-line var-name-mixedcase
  address public immutable SENDER_L1; // Voting contract on L1
  // solhint-disable-next-line var-name-mixedcase
  Delegator public immutable DELEGATOR; // Delegator contract

  // Action structure
  struct Action {
    address callContract;
    bytes data;
    uint256 value;
  }

  // Task structure
  struct Task {
    bool canExecute; // Starts marked false, is marked true when signalled by L1 voting contract
    // marked false again when executed
    Action[] actions; // Calls to execute
  }

  // Task queue
  Task[] public tasks;

  // Task events
  event TaskCreated(uint256 id);
  event TaskReady(uint256 id);
  event TaskExecuted(uint256 id);

  // Errors event
  error ExecutionFailed(uint256 index, bytes data);

  /**
   * @notice Sets contract addresses
   * @param _senderL1 - sender contract on L1
   * @param _delegator - delegator contract
   */
  constructor(address _senderL1, Delegator _delegator) {
    SENDER_L1 = _senderL1;
    DELEGATOR = _delegator;
  }

  /**
   * @notice Creates new task
   * @param _actions - list of calls to execute for this task
   */
  function createTask(Action[] calldata _actions) external {
    uint256 taskID = tasks.length;

    // Get new task
    Task storage task = tasks.push();

    // Set call list
    // Loop over actions and copy manually as solidity doesn't support copying struct arrays from calldata
    for (uint256 i = 0; i < _actions.length; i += 1) {
      task.actions.push(Action(_actions[i].callContract, _actions[i].data, _actions[i].value));
    }

    // Emit event
    emit TaskCreated(taskID);
  }

  /**
   * @notice Gets actions for a task
   * @param _ticket - ticket to get tasks for
   */
  function getActions(uint256 _ticket) external view returns (Action[] memory) {
    return tasks[_ticket].actions;
  }

  /**
   * @notice Convenience function to get minimum time newly created tickets will be redeemable
   */
  function newTicketTimeout() external view returns (uint256) {
    return ARB_RETRYABLE_TX.getLifetime();
  }

  /**
   * @notice Convenience function to get time left for ticket redemption
   * @param _ticket - ticket ID to redeem
   */
  function ticketTimeLeft(uint256 _ticket) external view returns (uint256) {
    return ARB_RETRYABLE_TX.getTimeout(bytes32(_ticket));
  }

  /**
   * @notice Convenience function to execute retryable ticket redeem
   * @param _ticket - ticket ID to redeem
   */
  function redeem(uint256 _ticket) external {
    ARB_RETRYABLE_TX.redeem(bytes32(_ticket));
  }

  /**
   * @notice Executes task
   * @param _task - task ID to execute
   */
  function readyTask(uint256 _task) external {
    // Check cross chain call
    require(
      msg.sender == AddressAliasHelper.applyL1ToL2Alias(SENDER_L1),
      "ArbitrumExecutor: Caller is not L1 sender contract"
    );

    // Set task can execute
    tasks[_task].canExecute = true;

    // Emit event
    emit TaskReady(_task);
  }

  /**
   * @notice Executes task
   * @param _task - task ID to execute
   */
  function executeTask(uint256 _task) external {
    // Get task
    Task storage task = tasks[_task];

    // Check task can be executed
    require(task.canExecute, "ArbitrumExecutor: Task not marked as executable");

    // Mark task as executed
    task.canExecute = false;

    // Loop over actions and execute
    for (uint256 i = 0; i < task.actions.length; i += 1) {
      // Execute action
      (bool successful, bytes memory returnData) = DELEGATOR.callContract(
        task.actions[i].callContract,
        task.actions[i].data,
        task.actions[i].value
      );

      // If an action fails to execute, catch and bubble up reason with revert
      if (!successful) {
        revert ExecutionFailed(i, returnData);
      }
    }

    // Emit event
    emit TaskExecuted(_task);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IInbox } from "@arbitrum/nitro-contracts/src/bridge/IInbox.sol";

import { ArbitrumExecutor } from "./Executor.sol";

/**
 * @title Sender
 * @author Railgun Contributors
 * @notice Sets tasks on Arbitrum sender to executable
 */
contract ArbitrumSender is Ownable {
  // solhint-disable-next-line var-name-mixedcase
  IInbox public immutable ARBITRUM_INBOX; // Arbitrum Inbox

  address public executor_L2; // Sender contract on L2

  event RetryableTicketCreated(uint256 id);

  /**
   * @notice Sets contract addresses
   * @param _admin - delegator contract
   * @param _executorL2 - sender contract on L1
   * @param _arbitrumInbox - arbitrum inbox address
   */
  constructor(address _admin, address _executorL2, IInbox _arbitrumInbox) {
    Ownable.transferOwnership(msg.sender);
    ARBITRUM_INBOX = _arbitrumInbox;
    setExecutorL2(_executorL2);
    Ownable.transferOwnership(_admin);
  }

  /**
   * @notice Sends ready task instruction to arbitrum executor
   * @param _task - task ID to ready
   */
  function readyTask(uint256 _task) external onlyOwner {
    // Create retryable ticket on arbitrum to set execution for governance task to true
    uint256 ticketID = ARBITRUM_INBOX.createRetryableTicket(
      executor_L2,
      0,
      0,
      msg.sender,
      msg.sender,
      0,
      0,
      abi.encodeWithSelector(ArbitrumExecutor.readyTask.selector, _task)
    );

    // Emit event with ticket ID so EOAs can retry on Arbitrum if need be
    emit RetryableTicketCreated(ticketID);
  }

  /**
   * @notice Sets L2 executor address
   * @param _executorL2 - new executor address
   */
  function setExecutorL2(address _executorL2) public onlyOwner {
    executor_L2 = _executorL2;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Delegator
 * @author Railgun Contributors
 * @notice 'Owner' contract for all railgun contracts
 * delegates permissions to other contracts (voter, role)
 */
contract Delegator is Ownable {
  /*
  Mapping structure is calling address => contract => function signature
  0 is used as a wildcard, so permission for contract 0 is permission for
  any contract, and permission for function signature 0 is permission for
  any function.

  Comments below use * to signify wildcard and . notation to separate address/contract/function.

  caller.*.* allows caller to call any function on any contract
  caller.X.* allows caller to call any function on contract X
  caller.*.Y allows caller to call function Y on any contract
  */
  mapping(address => mapping(address => mapping(bytes4 => bool))) public permissions;

  event GrantPermission(
    address indexed caller,
    address indexed contractAddress,
    bytes4 indexed selector
  );
  event RevokePermission(
    address indexed caller,
    address indexed contractAddress,
    bytes4 indexed selector
  );

  /**
   * @notice Sets initial admin
   */
  constructor(address _admin) {
    Ownable.transferOwnership(_admin);
  }

  /**
   * @notice Sets permission bit
   * @dev See comment on permissions mapping for wildcard format
   * @param _caller - caller to set permissions for
   * @param _contract - contract to set permissions for
   * @param _selector - selector to set permissions for
   * @param _permission - permission bit to set
   */
  function setPermission(
    address _caller,
    address _contract,
    bytes4 _selector,
    bool _permission
  ) public onlyOwner {
    // If permission set is different to new permission then we execute, otherwise skip
    if (permissions[_caller][_contract][_selector] != _permission) {
      // Set permission bit
      permissions[_caller][_contract][_selector] = _permission;

      // Emit event
      if (_permission) {
        emit GrantPermission(_caller, _contract, _selector);
      } else {
        emit RevokePermission(_caller, _contract, _selector);
      }
    }
  }

  /**
   * @notice Checks if caller has permission to execute function
   * @param _caller - caller to check permissions for
   * @param _contract - contract to check
   * @param _selector - function signature to check
   * @return if caller has permission
   */
  function checkPermission(
    address _caller,
    address _contract,
    bytes4 _selector
  ) public view returns (bool) {
    /* 
    See comment on permissions mapping for structure
    Comments below use * to signify wildcard and . notation to separate contract/function
    */
    return (_caller == Ownable.owner() ||
      permissions[_caller][_contract][_selector] || // Owner always has global permissions
      permissions[_caller][_contract][0x0] || // Permission for function is given
      permissions[_caller][address(0)][_selector] || // Permission for _contract.* is given
      permissions[_caller][address(0)][0x0]); // Global permission is given
  }

  /**
   * @notice Calls function
   * @dev calls to functions on this contract are intercepted and run directly
   * this is so the voting contract doesn't need to have special cases for calling
   * functions other than this one.
   * @param _contract - contract to call
   * @param _data - calldata to pass to contract
   * @return success - whether call succeeded
   * @return returnData - return data from function call
   */
  function callContract(
    address _contract,
    bytes calldata _data,
    uint256 _value
  ) public returns (bool success, bytes memory returnData) {
    // Get selector
    bytes4 selector = bytes4(_data);

    // Intercept calls to this contract
    if (_contract == address(this)) {
      if (selector == this.setPermission.selector) {
        // Decode call data
        (address caller, address calledContract, bytes4 _permissionSelector, bool permission) = abi
          .decode(abi.encodePacked(_data[4:]), (address, address, bytes4, bool));

        // Call setPermission
        setPermission(caller, calledContract, _permissionSelector, permission);

        // Return success with empty ReturnData bytes
        bytes memory empty;
        return (true, empty);
      } else if (selector == this.transferOwnership.selector) {
        // Decode call data
        address newOwner = abi.decode(abi.encodePacked(_data[4:]), (address));

        // Call transferOwnership
        Ownable.transferOwnership(newOwner);

        // Return success with empty ReturnData bytes
        bytes memory empty;
        return (true, empty);
      } else if (selector == this.renounceOwnership.selector) {
        // Call renounceOwnership
        Ownable.renounceOwnership();

        // Return success with empty ReturnData bytes
        bytes memory empty;
        return (true, empty);
      } else {
        // Return failed with empty ReturnData bytes
        bytes memory empty;
        return (false, empty);
      }
    }

    // Check permissions
    require(
      checkPermission(msg.sender, _contract, selector),
      "Delegator: Caller doesn't have permission"
    );

    // Call external contract and return
    // solhint-disable-next-line avoid-low-level-calls
    return _contract.call{ value: _value }(_data);
  }
}