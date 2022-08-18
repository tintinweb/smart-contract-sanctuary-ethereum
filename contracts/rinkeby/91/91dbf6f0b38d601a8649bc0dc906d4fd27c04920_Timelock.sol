// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {UUPS} from "../../lib/proxy/UUPS.sol";
import {Ownable} from "../../lib/utils/Ownable.sol";
import {ERC721TokenReceiver, ERC1155TokenReceiver} from "../../lib/utils/TokenReceiver.sol";

import {TimelockStorageV1} from "./storage/TimelockStorageV1.sol";
import {ITimelock} from "./ITimelock.sol";
import {IManager} from "../../manager/IManager.sol";

/// @title Timelock
/// @author Rohan Kulkarni
/// @notice This contract represents a DAO treasury that is controlled by a governor
contract Timelock is ITimelock, UUPS, Ownable, TimelockStorageV1 {
    ///                                                          ///
    ///                         CONSTANTS                        ///
    ///                                                          ///

    /// @notice The amount of time to execute an eligible transaction
    uint256 public constant GRACE_PERIOD = 2 weeks;

    /// @dev The timestamp denoting an executed transaction
    uint256 internal constant EXECUTED = 1;

    ///                                                          ///
    ///                         IMMUTABLES                       ///
    ///                                                          ///

    /// @dev The contract upgrade manager
    IManager private immutable manager;

    ///                                                          ///
    ///                         CONSTRUCTOR                      ///
    ///                                                          ///

    /// @param _manager The address of the contract upgrade manager
    constructor(address _manager) payable initializer {
        manager = IManager(_manager);
    }

    ///                                                          ///
    ///                         INITIALIZER                      ///
    ///                                                          ///

    /// @notice Initializes an instance of the timelock
    /// @param _governor The address of the governor
    /// @param _delay The time delay
    function initialize(address _governor, uint256 _delay) external initializer {
        // Ensure the zero address was not
        if (_governor == address(0)) revert INVALID_INIT();

        // Grant ownership to the governor
        __Ownable_init(_governor);

        // Store the
        delay = _delay;

        emit TransactionDelayUpdated(0, _delay);
    }

    ///                                                          ///
    ///                       TRANSACTION STATE                  ///
    ///                                                          ///

    /// @notice If a transaction was previously queued or executed
    /// @param _proposalId The proposal id
    function exists(uint256 _proposalId) public view returns (bool) {
        return timestamps[_proposalId] > 0;
    }

    /// @notice If a transaction is currently queued
    /// @param _proposalId The proposal id
    function isQueued(uint256 _proposalId) public view returns (bool) {
        return timestamps[_proposalId] > EXECUTED;
    }

    /// @notice If a transaction is ready to execute
    /// @param _proposalId The proposal id
    function isReadyToExecute(uint256 _proposalId) public view returns (bool) {
        return timestamps[_proposalId] > EXECUTED && timestamps[_proposalId] <= block.timestamp;
    }

    /// @notice If a transaction was executed
    /// @param _proposalId The proposal id
    function isExecuted(uint256 _proposalId) public view returns (bool) {
        return timestamps[_proposalId] == EXECUTED;
    }

    /// @notice If a transaction was not executed even after the grace period
    /// @param _proposalId The proposal id
    function isExpired(uint256 _proposalId) public view returns (bool) {
        unchecked {
            return block.timestamp > timestamps[_proposalId] + GRACE_PERIOD;
        }
    }

    ///                                                          ///
    ///                         HASH PROPOSAL                    ///
    ///                                                          ///

    /// @notice The proposal id
    function hashProposal(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        bytes32 _descriptionHash
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(_targets, _values, _calldatas, _descriptionHash)));
    }

    ///                                                          ///
    ///                         QUEUE PROPOSAL                   ///
    ///                                                          ///

    /// @notice Queues a proposal to be executed
    /// @param _proposalId The proposal id
    function schedule(uint256 _proposalId) external onlyOwner {
        // Ensure the proposal was not already queued
        if (exists(_proposalId)) revert ALREADY_QUEUED(_proposalId);

        // Used to store the timestamp the proposal will be valid to execute
        uint256 executionTime;

        // Cannot realistically overflow
        unchecked {
            // Add the timelock delay to the current time to get the valid time to execute
            executionTime = block.timestamp + delay;
        }

        // Store the execution timestamp
        timestamps[_proposalId] = executionTime;

        emit TransactionScheduled(_proposalId, executionTime);
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    /// @notice Removes a proposal that was canceled or vetoed
    /// @param _proposalId The proposal id
    function cancel(uint256 _proposalId) external onlyOwner {
        // Ensure the proposal is queued
        if (!isQueued(_proposalId)) revert NOT_QUEUED(_proposalId);

        // Remove the associated timestamp from storage
        delete timestamps[_proposalId];

        emit TransactionCanceled(_proposalId);
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function execute(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _calldatas,
        bytes32 _descriptionHash
    ) external payable onlyOwner {
        uint256 proposalId = hashProposal(_targets, _values, _calldatas, _descriptionHash);

        if (!isReadyToExecute(proposalId)) revert TRANSACTION_NOT_READY(proposalId);

        uint256 numTargets = _targets.length;

        for (uint256 i = 0; i < numTargets; ) {
            _execute(_targets[i], _values[i], _calldatas[i]);

            unchecked {
                ++i;
            }
        }

        timestamps[proposalId] = EXECUTED;

        emit TransactionExecuted(proposalId, _targets, _values, _calldatas);
    }

    function _execute(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) internal {
        (bool success, ) = _target.call{value: _value}(_data);

        if (!success) revert TRANSACTION_FAILED(_target, _value, _data);
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function updateDelay(uint256 _newDelay) external {
        if (msg.sender != address(this)) revert ONLY_TIMELOCK();

        emit TransactionDelayUpdated(delay, _newDelay);

        delay = _newDelay;
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    receive() external payable {}

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function _authorizeUpgrade(address _newImpl) internal view override onlyOwner {
        if (!manager.isValidUpgrade(_getImplementation(), _newImpl)) revert INVALID_UPGRADE(_newImpl);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC1822Proxiable} from "./IERC1822.sol";
import {Address} from "../utils/Address.sol";
import {StorageSlot} from "../utils/StorageSlot.sol";

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol
abstract contract UUPS is IERC1822Proxiable {
    ///                                                          ///
    ///                          CONSTANTS                       ///
    ///                                                          ///

    /// @dev keccak256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /// @dev keccak256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    ///                                                          ///
    ///                          IMMUTABLES                      ///
    ///                                                          ///

    address private immutable __self = address(this);

    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event Upgraded(address indexed impl);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    error INVALID_UPGRADE(address impl);

    error ONLY_DELEGATECALL();

    error NO_DELEGATECALL();

    error ONLY_PROXY();

    error INVALID_UUID();

    error NOT_UUPS();

    error INVALID_TARGET();

    ///                                                          ///
    ///                          MODIFIERS                       ///
    ///                                                          ///

    modifier onlyProxy() {
        if (address(this) == __self) revert ONLY_DELEGATECALL();
        if (_getImplementation() != __self) revert ONLY_PROXY();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __self) revert NO_DELEGATECALL();
        _;
    }

    ///                                                          ///
    ///                          FUNCTIONS                       ///
    ///                                                          ///

    function _authorizeUpgrade(address _impl) internal virtual;

    function proxiableUUID() external view notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    function upgradeTo(address _impl) external onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, "", false);
    }

    function upgradeToAndCall(address _impl, bytes memory _data) external payable onlyProxy {
        _authorizeUpgrade(_impl);
        _upgradeToAndCallUUPS(_impl, _data, true);
    }

    function _upgradeToAndCallUUPS(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(_impl);
        } else {
            try IERC1822Proxiable(_impl).proxiableUUID() returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT) revert INVALID_UUID();
            } catch {
                revert NOT_UUPS();
            }

            _upgradeToAndCall(_impl, _data, _forceCall);
        }
    }

    function _upgradeToAndCall(
        address _impl,
        bytes memory _data,
        bool _forceCall
    ) internal {
        _upgradeTo(_impl);

        if (_data.length > 0 || _forceCall) {
            Address.functionDelegateCall(_impl, _data);
        }
    }

    function _upgradeTo(address _impl) internal {
        _setImplementation(_impl);

        emit Upgraded(_impl);
    }

    function _setImplementation(address _impl) private {
        if (!Address.isContract(_impl)) revert INVALID_TARGET();

        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _impl;
    }

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Initializable} from "../proxy/Initializable.sol";

contract OwnableStorageV1 {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is Initializable, OwnableStorageV1 {
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    event OwnerPending(address indexed owner, address indexed pendingOwner);

    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    error ONLY_OWNER();

    error ONLY_PENDING_OWNER();

    error INCORRECT_PENDING_OWNER();

    modifier onlyOwner() {
        if (msg.sender != owner) revert ONLY_OWNER();
        _;
    }

    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) revert ONLY_PENDING_OWNER();
        _;
    }

    function __Ownable_init(address _owner) internal onlyInitializing {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerUpdated(owner, _newOwner);

        owner = _newOwner;
    }

    function safeTransferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;

        emit OwnerPending(owner, _newOwner);
    }

    function cancelOwnershipTransfer(address _pendingOwner) public onlyOwner {
        if (_pendingOwner != pendingOwner) revert INCORRECT_PENDING_OWNER();

        emit OwnerCanceled(owner, _pendingOwner);

        delete pendingOwner;
    }

    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(owner, msg.sender);

        owner = pendingOwner;

        delete pendingOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @notice TimelockStorageV1
/// @author Rohan Kulkarni
/// @notice
contract TimelockStorageV1 {
    /// @notice The time between a queued transaction and its execution
    uint256 public delay;

    /// @notice The timestamp that a proposal is ready for execution.
    ///         Executed proposals are stored as 1 second.
    /// @dev Proposal Id => Timestamp
    mapping(uint256 => uint256) public timestamps;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

interface ITimelock {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    event TransactionScheduled(uint256 proposalId, uint256 timestamp);

    event TransactionCanceled(uint256 proposalId);

    event TransactionExecuted(uint256 proposalId, address[] targets, uint256[] values, bytes[] payloads);

    event TransactionDelayUpdated(uint256 prevDelay, uint256 newDelay);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error ALREADY_QUEUED(uint256 proposalId);

    error NOT_QUEUED(uint256 proposalId);

    error TRANSACTION_NOT_READY(uint256 proposalId);

    error TRANSACTION_FAILED(address target, uint256 value, bytes data);

    error ONLY_TIMELOCK();

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function initialize(address governor, uint256 txDelay) external;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    // function isOperation(uint256 proposalId) external view returns (bool);

    // function isOperationPending(uint256 proposalId) external view returns (bool);

    // function isOperationReady(uint256 proposalId) external view returns (bool);

    // function isOperationDone(uint256 proposalId) external view returns (bool);

    // function isOperationExpired(uint256 proposalId) external view returns (bool);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function hashProposal(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        bytes32 descriptionHash
    ) external pure returns (uint256);

    function cancel(uint256 proposalId) external;

    // function schedule(
    //     address target,
    //     uint256 value,
    //     bytes calldata data,
    //     bytes32 predecessor,
    //     bytes32 salt,
    //     uint256 delay
    // ) external;

    // function scheduleBatch(
    //     address[] calldata targets,
    //     uint256[] calldata values,
    //     bytes[] calldata payloads,
    //     bytes32 predecessor,
    //     bytes32 salt,
    //     uint256 delay
    // ) external;

    // function execute(
    //     address target,
    //     uint256 value,
    //     bytes calldata data,
    //     bytes32 predecessor,
    //     bytes32 salt
    // ) external payable;

    // function executeBatch(
    //     address[] calldata targets,
    //     uint256[] calldata values,
    //     bytes[] calldata payloads,
    //     bytes32 predecessor,
    //     bytes32 salt
    // ) external payable;

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function updateDelay(uint256 newDelay) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title IManager
/// @author Rohan Kulkarni
/// @notice The Manager external interface
interface IManager {
    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    /// @notice Emitted when a DAO is deployed
    /// @param token The address of the token
    /// @param metadata The address of the metadata renderer
    /// @param auction The address of the auction
    /// @param timelock The address of the timelock
    /// @param governor The address of the governor
    event DAODeployed(address token, address metadata, address auction, address timelock, address governor);

    /// @notice Emitted when an upgrade is registered
    /// @param baseImpl The address of the previous implementation
    /// @param upgradeImpl The address of the registered upgrade
    event UpgradeRegistered(address baseImpl, address upgradeImpl);

    /// @notice Emitted when an upgrade is unregistered
    /// @param baseImpl The address of the base contract
    /// @param upgradeImpl The address of the upgrade
    event UpgradeUnregistered(address baseImpl, address upgradeImpl);

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    error FOUNDER_REQUIRED();

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    /// @notice The ownership config for each founder
    /// @param wallet A wallet or multisig address
    /// @param allocationFrequency The frequency of tokens minted to them (eg. Every 10 tokens to Nounders)
    /// @param vestingEnd The timestamp that their vesting will end
    struct FounderParams {
        address wallet;
        uint256 allocationFrequency;
        uint256 vestingEnd;
    }

    /// @notice The DAO's ERC-721 token and metadata config
    /// @param initStrings The encoded
    struct TokenParams {
        bytes initStrings; // name, symbol, description, contract image, renderer base
    }

    struct AuctionParams {
        uint256 reservePrice;
        uint256 duration;
    }

    struct GovParams {
        uint256 timelockDelay; // The time between a proposal and its execution
        uint256 votingDelay; // The number of blocks after a proposal that voting is delayed
        uint256 votingPeriod; // The number of blocks that voting for a proposal will take place
        uint256 proposalThresholdBPS; // The number of votes required for a voter to become a proposer
        uint256 quorumVotesBPS; // The number of votes required to support a proposal
    }

    ///                                                          ///
    ///                                                          ///
    ///                                                          ///

    function deploy(
        FounderParams[] calldata _founderParams,
        TokenParams calldata tokenParams,
        AuctionParams calldata auctionParams,
        GovParams calldata govParams
    )
        external
        returns (
            address token,
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function getAddresses(address token)
        external
        returns (
            address metadataRenderer,
            address auction,
            address timelock,
            address governor
        );

    function isValidUpgrade(address _baseImpl, address _upgradeImpl) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC1822Proxiable {
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
library Address {
    error INVALID_TARGET();

    error DELEGATE_CALL_FAILED();

    function isContract(address _account) internal view returns (bool rv) {
        assembly {
            rv := gt(extcodesize(_account), 0)
        }
    }

    function functionDelegateCall(address _target, bytes memory _data) internal returns (bytes memory) {
        if (!isContract(_target)) revert INVALID_TARGET();

        (bool success, bytes memory returndata) = _target.delegatecall(_data);

        return verifyCallResult(success, returndata);
    }

    function verifyCallResult(bool _success, bytes memory _returndata) internal pure returns (bytes memory) {
        if (_success) {
            return _returndata;
        } else {
            if (_returndata.length > 0) {
                assembly {
                    let returndata_size := mload(_returndata)

                    revert(add(32, _returndata), returndata_size)
                }
            } else {
                revert DELEGATE_CALL_FAILED();
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/StorageSlot.sol
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Address} from "../utils/Address.sol";

contract InitializableStorageV1 {
    uint8 internal _initialized;
    bool internal _initializing;
}

/// @notice Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/Initializable.sol
abstract contract Initializable is InitializableStorageV1 {
    event Initialized(uint256 version);

    error ADDRESS_ZERO();

    error INVALID_INIT();

    error NOT_INITIALIZING();

    error ALREADY_INITIALIZED();

    modifier onlyInitializing() {
        if (!_initializing) revert NOT_INITIALIZING();
        _;
    }

    modifier initializer() {
        bool isTopLevelCall = !_initializing;

        if ((!isTopLevelCall || _initialized != 0) && (Address.isContract(address(this)) || _initialized != 1)) revert ALREADY_INITIALIZED();

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

    modifier reinitializer(uint8 _version) {
        if (_initializing || _initialized >= _version) revert ALREADY_INITIALIZED();

        _initialized = _version;

        _initializing = true;

        _;

        _initializing = false;

        emit Initialized(_version);
    }
}