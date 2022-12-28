// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library SafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x + y) >= x);
        }
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x);
        }
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @param message The error msg
    /// @return z The difference of x and y
    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x, message);
        }
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require(x == 0 || (z = x * y) / x == y);
        }
    }

    /// @notice Returns x / y, reverts if overflows - no specific check, solidity reverts on division by 0
    /// @param x The numerator
    /// @param y The denominator
    /// @return z The product of x and y
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;
pragma abicoder v2;

import {IExecutorWithTimelock} from "../interfaces/IExecutorWithTimelock.sol";
import {SafeMath} from "../dependencies/openzeppelin/contracts/SafeMath.sol";

/**
 * @title Time Locked Executor Contract
 * @dev Contract that can queue, execute, cancel transactions voted by Governance
 * Queued transactions can be executed after a delay and until
 * Grace period is not over.
 **/
contract ExecutorWithTimelock is IExecutorWithTimelock {
    using SafeMath for uint256;

    uint256 public immutable override GRACE_PERIOD;
    uint256 public immutable override MINIMUM_DELAY;
    uint256 public immutable override MAXIMUM_DELAY;

    address private _admin;
    address private _pendingAdmin;
    uint256 private _delay;

    mapping(bytes32 => bool) private _queuedTransactions;

    /**
     * @dev Constructor
     * @param admin admin address, that can call the main functions, (Governance)
     * @param delay minimum time between queueing and execution of proposal
     * @param gracePeriod time after `delay` while a proposal can be executed
     * @param minimumDelay lower threshold of `delay`, in seconds
     * @param maximumDelay upper threshold of `delay`, in seconds
     **/
    constructor(
        address admin,
        uint256 delay,
        uint256 gracePeriod,
        uint256 minimumDelay,
        uint256 maximumDelay
    ) {
        require(delay >= minimumDelay, "DELAY_SHORTER_THAN_MINIMUM");
        require(delay <= maximumDelay, "DELAY_LONGER_THAN_MAXIMUM");
        _delay = delay;
        _admin = admin;

        GRACE_PERIOD = gracePeriod;
        MINIMUM_DELAY = minimumDelay;
        MAXIMUM_DELAY = maximumDelay;

        emit NewDelay(delay);
        emit NewAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ONLY_BY_ADMIN");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(this), "ONLY_BY_THIS_TIMELOCK");
        _;
    }

    modifier onlyPendingAdmin() {
        require(msg.sender == _pendingAdmin, "ONLY_BY_PENDING_ADMIN");
        _;
    }

    /**
     * @dev Set the delay
     * @param delay delay between queue and execution of proposal
     **/
    function setDelay(uint256 delay) public onlyTimelock {
        _validateDelay(delay);
        _delay = delay;

        emit NewDelay(delay);
    }

    /**
     * @dev Function enabling pending admin to become admin
     **/
    function acceptAdmin() public onlyPendingAdmin {
        _admin = msg.sender;
        _pendingAdmin = address(0);

        emit NewAdmin(msg.sender);
    }

    /**
     * @dev Setting a new pending admin (that can then become admin)
     * Can only be called by this executor (i.e via proposal)
     * @param newPendingAdmin address of the new admin
     **/
    function setPendingAdmin(address newPendingAdmin) public onlyTimelock {
        _pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(newPendingAdmin);
    }

    /**
     * @dev Function, called by Governance, that queue a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     * @return the action Hash
     **/
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) public override onlyAdmin returns (bytes32) {
        require(
            executionTime >= block.timestamp.add(_delay),
            "EXECUTION_TIME_UNDERESTIMATED"
        );

        bytes32 actionHash = keccak256(
            abi.encode(
                target,
                value,
                signature,
                data,
                executionTime,
                withDelegatecall
            )
        );
        _queuedTransactions[actionHash] = true;

        emit QueuedAction(
            actionHash,
            target,
            value,
            signature,
            data,
            executionTime,
            withDelegatecall
        );
        return actionHash;
    }

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     * @return the action Hash of the canceled tx
     **/
    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) public override onlyAdmin returns (bytes32) {
        bytes32 actionHash = keccak256(
            abi.encode(
                target,
                value,
                signature,
                data,
                executionTime,
                withDelegatecall
            )
        );
        _queuedTransactions[actionHash] = false;

        emit CancelledAction(
            actionHash,
            target,
            value,
            signature,
            data,
            executionTime,
            withDelegatecall
        );
        return actionHash;
    }

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     * @return the callData executed as memory bytes
     **/
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) public payable override onlyAdmin returns (bytes memory) {
        bytes32 actionHash = keccak256(
            abi.encode(
                target,
                value,
                signature,
                data,
                executionTime,
                withDelegatecall
            )
        );
        require(_queuedTransactions[actionHash], "ACTION_NOT_QUEUED");
        require(block.timestamp >= executionTime, "TIMELOCK_NOT_FINISHED");
        require(
            block.timestamp <= executionTime.add(GRACE_PERIOD),
            "GRACE_PERIOD_FINISHED"
        );

        _queuedTransactions[actionHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        bool success;
        bytes memory resultData;
        if (withDelegatecall) {
            require(msg.value >= value, "NOT_ENOUGH_MSG_VALUE");
            // solium-disable-next-line security/no-call-value
            (success, resultData) = target.delegatecall(callData);
        } else {
            // solium-disable-next-line security/no-call-value
            (success, resultData) = target.call{value: value}(callData);
        }

        require(success, "FAILED_ACTION_EXECUTION");

        emit ExecutedAction(
            actionHash,
            target,
            value,
            signature,
            data,
            executionTime,
            withDelegatecall,
            resultData
        );

        return resultData;
    }

    /**
     * @dev Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view override returns (address) {
        return _admin;
    }

    /**
     * @dev Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view override returns (address) {
        return _pendingAdmin;
    }

    /**
     * @dev Getter of the delay between queuing and execution
     * @return The delay in seconds
     **/
    function getDelay() external view override returns (uint256) {
        return _delay;
    }

    /**
     * @dev Returns whether an action (via actionHash) is queued
     * @param actionHash hash of the action to be checked
     * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
     * @return true if underlying action of actionHash is queued
     **/
    function isActionQueued(bytes32 actionHash)
        external
        view
        override
        returns (bool)
    {
        return _queuedTransactions[actionHash];
    }

    function _validateDelay(uint256 delay) internal view {
        require(delay >= MINIMUM_DELAY, "DELAY_SHORTER_THAN_MINIMUM");
        require(delay <= MAXIMUM_DELAY, "DELAY_LONGER_THAN_MAXIMUM");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;
pragma abicoder v2;

interface IExecutorWithTimelock {
    /**
     * @dev emitted when a new pending admin is set
     * @param newPendingAdmin address of the new pending admin
     **/
    event NewPendingAdmin(address newPendingAdmin);

    /**
     * @dev emitted when a new admin is set
     * @param newAdmin address of the new admin
     **/
    event NewAdmin(address newAdmin);

    /**
     * @dev emitted when a new delay (between queueing and execution) is set
     * @param delay new delay
     **/
    event NewDelay(uint256 delay);

    /**
     * @dev emitted when a new (trans)action is Queued.
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    event QueuedAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bool withDelegatecall
    );

    /**
     * @dev emitted when an action is Cancelled
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    event CancelledAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bool withDelegatecall
    );

    /**
     * @dev emitted when an action is Cancelled
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     * @param resultData the actual callData used on the target
     **/
    event ExecutedAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bool withDelegatecall,
        bytes resultData
    );

    /**
     * @dev Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view returns (address);

    /**
     * @dev Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view returns (address);

    /**
     * @dev Getter of the delay between queuing and execution
     * @return The delay in seconds
     **/
    function getDelay() external view returns (uint256);

    /**
     * @dev Returns whether an action (via actionHash) is queued
     * @param actionHash hash of the action to be checked
     * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
     * @return true if underlying action of actionHash is queued
     **/
    function isActionQueued(bytes32 actionHash) external view returns (bool);

    /**
     * @dev Getter of grace period constant
     * @return grace period in seconds
     **/
    function GRACE_PERIOD() external view returns (uint256);

    /**
     * @dev Getter of minimum delay constant
     * @return minimum delay in seconds
     **/
    function MINIMUM_DELAY() external view returns (uint256);

    /**
     * @dev Getter of maximum delay constant
     * @return maximum delay in seconds
     **/
    function MAXIMUM_DELAY() external view returns (uint256);

    /**
     * @dev Function, called by Governance, that queue a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) external returns (bytes32);

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) external payable returns (bytes memory);

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) external returns (bytes32);
}