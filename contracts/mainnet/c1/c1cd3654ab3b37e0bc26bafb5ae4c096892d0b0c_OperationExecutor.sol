//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { ServiceRegistry } from "./ServiceRegistry.sol";
import { OperationStorage } from "./OperationStorage.sol";
import { OperationsRegistry } from "./OperationsRegistry.sol";
import { DSProxy } from "../libs/DS/DSProxy.sol";
import { ActionAddress } from "../libs/ActionAddress.sol";
import { TakeFlashloan } from "../actions/common/TakeFlashloan.sol";
import { Executable } from "../actions/common/Executable.sol";
import { IERC3156FlashBorrower } from "../interfaces/flashloan/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "../interfaces/flashloan/IERC3156FlashLender.sol";
import { SafeERC20, IERC20 } from "../libs/SafeERC20.sol";
import { SafeMath } from "../libs/SafeMath.sol";
import { FlashloanData, Call } from "./types/Common.sol";
import { OPERATION_STORAGE, OPERATIONS_REGISTRY, OPERATION_EXECUTOR } from "./constants/Common.sol";
import { FLASH_MINT_MODULE } from "./constants/Maker.sol";

/**
 * @title Operation Executor
 * @notice Is responsible for executing sequences of Actions (Operations)
 */
contract OperationExecutor is IERC3156FlashBorrower {
  using ActionAddress for address;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ServiceRegistry public immutable registry;

  /**
   * @dev Emitted once an Operation has completed execution
   * @param name The address initiating the deposit
   * @param calls An array of Action calls the operation must execute
   **/
  event Operation(string indexed name, Call[] calls);

  constructor(ServiceRegistry _registry) {
    registry = _registry;
  }

  /**
   * @notice Executes an operation
   * @dev
   * There are operations stored in the OperationsRegistry which guarantee the order of execution of actions for a given Operation.
   * There is a possibility to execute an arrays of calls that don't form an official operation.
   *
   * Operation storage is cleared before and after an operation is executed.
   *
   * To avoid re-entrancy attack, there is a lock implemented on OpStorage.
   * A standard reentrancy modifier is not sufficient because the second call via the onFlashloan handler
   * calls aggregateCallback via DSProxy once again but this breaks the special modifier _ behaviour
   * and the modifier cannot return the execution flow to the original function.
   * This is why re-entrancy defence is immplemented here using an external storage contract via the lock/unlock functions
   * @param calls An array of Action calls the operation must execute
   * @param operationName The name of the Operation being executed
   */
  function executeOp(Call[] memory calls, string calldata operationName) public payable {
    OperationStorage opStorage = OperationStorage(registry.getRegisteredService(OPERATION_STORAGE));
    opStorage.lock();
    OperationsRegistry opRegistry = OperationsRegistry(
      registry.getRegisteredService(OPERATIONS_REGISTRY)
    );

    opStorage.clearStorage();
    (bytes32[] memory actions, bool[] memory optional) = opRegistry.getOperation(operationName);
    opStorage.setOperationActions(actions, optional);
    aggregate(calls);

    opStorage.clearStorage();
    opStorage.unlock();
    emit Operation(operationName, calls);
  }

  function aggregate(Call[] memory calls) internal {
    OperationStorage opStorage = OperationStorage(registry.getRegisteredService(OPERATION_STORAGE));
    bool hasActionsToVerify = opStorage.hasActionsToVerify();
    for (uint256 current = 0; current < calls.length; current++) {
      if (hasActionsToVerify) {
        opStorage.verifyAction(calls[current].targetHash, calls[current].skipped);
      }
      if (!calls[current].skipped) {
        address target = registry.getServiceAddress(calls[current].targetHash);
        target.execute(calls[current].callData);
      }
    }
  }

  /**
   * @notice Not to be called directly
   * @dev Is called by the Operation Executor via a user's proxy to execute Actions nested in the FlashloanAction
   * @param calls An array of Action calls the operation must execute
   */
  function callbackAggregate(Call[] memory calls) external {
    require(
      msg.sender == registry.getRegisteredService(OPERATION_EXECUTOR),
      "OpExecutor: Caller forbidden"
    );
    aggregate(calls);
  }

  /**
   * @notice Not to be called directly.
   * @dev Callback handler for use by a flashloan lender contract.
   * If the isProxyFlashloan flag is supplied we reestablish the calling context as the user's proxy (at time of writing DSProxy). Although stored values will
   * We set the initiator on Operation Storage such that calls originating from other contracts EG Oasis Automation Bot (see https://github.com/OasisDEX/automation-smartcontracts)
   * The initiator address will be used to store values against the original msg.sender.
   * This protects against the Operation Storage values being polluted by malicious code from untrusted 3rd party contracts.

   * @param initiator Is the address of the contract that initiated the flashloan (EG Operation Executor)
   * @param asset The address of the asset being flash loaned
   * @param amount The size of the flash loan
   * @param fee The Fee charged for the loan
   * @param data Any calldata sent to the contract for execution later in the callback
   */
  function onFlashLoan(
    address initiator,
    address asset,
    uint256 amount,
    uint256 fee,
    bytes calldata data
  ) external override returns (bytes32) {
    address lender = registry.getRegisteredService(FLASH_MINT_MODULE);

    require(msg.sender == lender, "Untrusted flashloan lender");

    FlashloanData memory flData = abi.decode(data, (FlashloanData));

    require(IERC20(asset).balanceOf(address(this)) >= flData.amount, "Flashloan inconsistency");

    if (flData.isProxyFlashloan) {
      IERC20(asset).safeTransfer(initiator, flData.amount);

      DSProxy(payable(initiator)).execute(
        address(this),
        abi.encodeWithSelector(this.callbackAggregate.selector, flData.calls)
      );
    } else {
      OperationStorage opStorage = OperationStorage(
        registry.getRegisteredService(OPERATION_STORAGE)
      );
      opStorage.setInitiator(initiator);
      aggregate(flData.calls);
    }

    uint256 paybackAmount = amount.add(fee);
    require(
      IERC20(asset).balanceOf(address(this)) >= paybackAmount,
      "Insufficient funds for payback"
    );

    IERC20(asset).safeApprove(lender, paybackAmount);

    return keccak256("ERC3156FlashBorrower.onFlashLoan");
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.1;

/**
 * @title Service Registry
 * @notice Stores addresses of deployed contracts
 */
contract ServiceRegistry {
  uint256 public constant MAX_DELAY = 30 days;

  mapping(bytes32 => uint256) public lastExecuted;
  mapping(bytes32 => address) private namedService;
  address public owner;
  uint256 public requiredDelay;

  modifier validateInput(uint256 len) {
    require(msg.data.length == len, "registry/illegal-padding");
    _;
  }

  modifier delayedExecution() {
    bytes32 operationHash = keccak256(msg.data);
    uint256 reqDelay = requiredDelay;

    /* solhint-disable not-rely-on-time */
    if (lastExecuted[operationHash] == 0 && reqDelay > 0) {
      // not called before, scheduled for execution
      lastExecuted[operationHash] = block.timestamp;
      emit ChangeScheduled(operationHash, block.timestamp + reqDelay, msg.data);
    } else {
      require(block.timestamp - reqDelay > lastExecuted[operationHash], "registry/delay-too-small");
      emit ChangeApplied(operationHash, block.timestamp, msg.data);
      _;
      lastExecuted[operationHash] = 0;
    }
    /* solhint-enable not-rely-on-time */
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "registry/only-owner");
    _;
  }

  constructor(uint256 initialDelay) {
    require(initialDelay <= MAX_DELAY, "registry/invalid-delay");
    requiredDelay = initialDelay;
    owner = msg.sender;
  }

  /**
   * @param newOwner Transfers ownership of the registry to a new address
   */
  function transferOwnership(address newOwner)
    external
    onlyOwner
    validateInput(36)
    delayedExecution
  {
    owner = newOwner;
  }

  /**
   * @param newDelay Updates the required delay before an change can be confirmed with a follow up t/x
   */
  function changeRequiredDelay(uint256 newDelay)
    external
    onlyOwner
    validateInput(36)
    delayedExecution
  {
    require(newDelay <= MAX_DELAY, "registry/invalid-delay");
    requiredDelay = newDelay;
  }

  /**
   * @param name Hashes the supplied name
   * @return Returns the hash of the name
   */
  function getServiceNameHash(string memory name) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(name));
  }

  /**
   * @param serviceNameHash The hashed name
   * @param serviceAddress The address stored for a given name
   */
  function addNamedService(bytes32 serviceNameHash, address serviceAddress)
    external
    onlyOwner
    validateInput(68)
    delayedExecution
  {
    require(namedService[serviceNameHash] == address(0), "registry/service-override");
    namedService[serviceNameHash] = serviceAddress;
  }

  /**
   * @param serviceNameHash The hashed name
   * @param serviceAddress The address to update for a given name
   */
  function updateNamedService(bytes32 serviceNameHash, address serviceAddress)
    external
    onlyOwner
    validateInput(68)
    delayedExecution
  {
    require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
    namedService[serviceNameHash] = serviceAddress;
  }

  /**
   * @param serviceNameHash The hashed service name to remove
   */
  function removeNamedService(bytes32 serviceNameHash) external onlyOwner validateInput(36) {
    require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
    namedService[serviceNameHash] = address(0);
    emit NamedServiceRemoved(serviceNameHash);
  }

  /**
   * @param serviceName Get a service address by its name
   */
  function getRegisteredService(string memory serviceName) external view returns (address) {
    return namedService[keccak256(abi.encodePacked(serviceName))];
  }

  /**
   * @param serviceNameHash Get a service address by the hash of its name
   */
  function getServiceAddress(bytes32 serviceNameHash) external view returns (address) {
    return namedService[serviceNameHash];
  }

  /**
   * @dev Voids any submitted changes that are yet to be confirmed by a follow-up transaction
   * @param scheduledExecution Clear any scheduled changes
   */
  function clearScheduledExecution(bytes32 scheduledExecution)
    external
    onlyOwner
    validateInput(36)
  {
    require(lastExecuted[scheduledExecution] > 0, "registry/execution-not-scheduled");
    lastExecuted[scheduledExecution] = 0;
    emit ChangeCancelled(scheduledExecution);
  }

  event ChangeScheduled(bytes32 dataHash, uint256 scheduledFor, bytes data);
  event ChangeApplied(bytes32 dataHash, uint256 appliedAt, bytes data);
  event ChangeCancelled(bytes32 dataHash);
  event NamedServiceRemoved(bytes32 nameHash);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { ServiceRegistry } from "./ServiceRegistry.sol";

/**
 * @title Operation Storage
 * @notice Stores the return values from Actions during an Operation's execution
 * @dev valuesHolders is an array of t/x initiators (msg.sender) who have pushed values to Operation Storage
 * returnValues is a mapping between a msg.sender and an array of Action return values generated by that senders transaction
 */
contract OperationStorage {
  uint8 internal action = 0;
  bytes32[] public actions;
  bool[] public optionals;
  mapping(address => bytes32[]) public returnValues;
  address[] public valuesHolders;
  bool private locked;
  address private whoLocked;
  address public initiator;
  address immutable operationExecutorAddress;

  ServiceRegistry internal immutable registry;

  constructor(ServiceRegistry _registry, address _operationExecutorAddress) {
    registry = _registry;
    operationExecutorAddress = _operationExecutorAddress;
  }

  /**
   * @dev Locks storage to protect against re-entrancy [email protected]
   */
  function lock() external {
    locked = true;
    whoLocked = msg.sender;
  }

  /**
   * @dev Only the original locker can unlock the contract at the end of the transaction
   */
  function unlock() external {
    require(whoLocked == msg.sender, "Only the locker can unlock");
    require(locked, "Not locked");
    locked = false;
    whoLocked = address(0);
  }

  /**
   * @dev Sets the initiator of the original call
   * Is used by Automation Bot branch in the onFlashloan callback in Operation Executor
   * Ensures that third party calls to Operation Storage do not maliciously override values in Operation Storage
   * @param _initiator Sets the initiator to Operation Executor contract when storing return values from flashloan nested Action
   */
  function setInitiator(address _initiator) external {
    require(msg.sender == operationExecutorAddress);
    initiator = _initiator;
  }

  /**
   * @param _actions Stores the Actions currently being executed for a given Operation and their optionality
   */
  function setOperationActions(bytes32[] memory _actions, bool[] memory _optionals) external {
    actions = _actions;
    optionals = _optionals;
  }

  /**
   * @param actionHash Checks the current action has against the expected action hash
   */
  function verifyAction(bytes32 actionHash, bool skipped) external {
    if (skipped) {
      require(optionals[action], "Action cannot be skipped");
    }
    require(actions[action] == actionHash, "incorrect-action");
    registry.getServiceAddress(actionHash);
    action++;
  }

  /**
   * @dev Custom operations have no Actions stored in Operation Registry
   * @return Returns true / false depending on whether the Operation has any actions to verify the Operation against
   */
  function hasActionsToVerify() external view returns (bool) {
    return actions.length > 0;
  }

  /**
   * @param value Pushes a bytes32 to end of the returnValues array
   */
  function push(bytes32 value) external {
    address who = msg.sender;
    if (who == operationExecutorAddress) {
      who = initiator;
    }

    if (returnValues[who].length == 0) {
      valuesHolders.push(who);
    }
    returnValues[who].push(value);
  }

  /**
   * @dev Values are stored against an address (who)
   * This ensures that malicious actors looking to push values to Operation Storage mid transaction cannot overwrite values
   * @param index The index of the desired value
   * @param who The msg.sender address responsible for storing values
   */
  function at(uint256 index, address who) external view returns (bytes32) {
    if (who == operationExecutorAddress) {
      who = initiator;
    }
    return returnValues[who][index];
  }

  /**
   * @param who The msg.sender address responsible for storing values
   * @return The length of return values stored against a given msg.sender address
   */
  function len(address who) external view returns (uint256) {
    if (who == operationExecutorAddress) {
      who = initiator;
    }
    return returnValues[who].length;
  }

  /**
   * @dev Clears storage in preparation for the next Operation
   */
  function clearStorage() external {
    delete action;
    delete actions;
    for (uint256 i = 0; i < valuesHolders.length; i++) {
      delete returnValues[valuesHolders[i]];
    }
    delete valuesHolders;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Operation } from "./types/Common.sol";
import { OPERATIONS_REGISTRY } from "./constants/Common.sol";

struct StoredOperation {
  bytes32[] actions;
  bool[] optional;
  string name;
}

/**
 * @title Operation Registry
 * @notice Stores the Actions that constitute a given Operation and information if an Action can be skipped

 */
contract OperationsRegistry {
  mapping(string => StoredOperation) private operations;
  address public owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "only-owner");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  /**
   * @notice Stores the Actions that constitute a given Operation
   * @param newOwner The address of the new owner of the Operations Registry
   */
  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  /**
   * @dev Emitted when a new operation is added or an existing operation is updated
   * @param name The Operation name
   **/
  event OperationAdded(string indexed name);

  /**
   * @notice Adds an Operation's Actions keyed to a an operation name
   * @param operation Struct with Operation name, actions and their optionality
   */
  function addOperation(StoredOperation calldata operation) external onlyOwner {
    operations[operation.name] = operation;
    emit OperationAdded(operation.name);
  }

  /**
   * @notice Gets an Operation from the Registry
   * @param name The name of the Operation
   * @return actions Returns an array of Actions and array for optionality of coresponding Actions
   */
  function getOperation(string memory name)
    external
    view
    returns (bytes32[] memory actions, bool[] memory optional)
  {
    if (keccak256(bytes(operations[name].name)) == keccak256(bytes(""))) {
      revert("Operation doesn't exist");
    }
    actions = operations[name].actions;
    optional = operations[name].optional;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./DSAuth.sol";
import "./DSNote.sol";

abstract contract DSProxy is DSAuth, DSNote {
  DSProxyCache public cache; // global cache for contracts

  constructor(address _cacheAddr) {
    require(setCache(_cacheAddr), "Cache not set");
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  // use the proxy to execute calldata _data on contract _code
  function execute(bytes memory _code, bytes memory _data)
    public
    payable
    virtual
    returns (address target, bytes32 response);

  function execute(address _target, bytes memory _data)
    public
    payable
    virtual
    returns (bytes32 response);

  //set new cache
  function setCache(address _cacheAddr) public payable virtual returns (bool);
}

contract DSProxyCache {
  mapping(bytes32 => address) cache;

  function read(bytes memory _code) public view returns (address) {
    bytes32 hash = keccak256(_code);
    return cache[hash];
  }

  function write(bytes memory _code) public returns (address target) {
    assembly {
      target := create(0, add(_code, 0x20), mload(_code))
      switch iszero(extcodesize(target))
      case 1 {
        // throw if contract failed to deploy
        revert(0, 0)
      }
    }
    bytes32 hash = keccak256(_code);
    cache[hash] = target;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;
import "./Address.sol";
import "../actions/common/Executable.sol";

library ActionAddress {
  using Address for address;

  function execute(address action, bytes memory callData) internal {
    require(isCallingAnExecutable(callData), "OpExecutor: illegal call");
    action.functionDelegateCall(callData, "OpExecutor: low-level delegatecall failed");
  }

  function isCallingAnExecutable(bytes memory callData) private pure returns (bool) {
    bytes4 executeSelector = convertBytesToBytes4(
      abi.encodeWithSelector(Executable.execute.selector)
    );
    bytes4 selector = convertBytesToBytes4(callData);
    return selector == executeSelector;
  }

  function convertBytesToBytes4(bytes memory inBytes) private pure returns (bytes4 outBytes4) {
    if (inBytes.length == 0) {
      return 0x0;
    }

    assembly {
      outBytes4 := mload(add(inBytes, 32))
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { IERC3156FlashBorrower } from "../../interfaces/flashloan/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "../../interfaces/flashloan/IERC3156FlashLender.sol";
import { FlashloanData } from "../../core/types/Common.sol";
import { OPERATION_EXECUTOR, DAI, TAKE_FLASH_LOAN_ACTION } from "../../core/constants/Common.sol";
import { FLASH_MINT_MODULE } from "../../core/constants/Maker.sol";
import { ProxyPermission } from "../../libs/DS/ProxyPermission.sol";

/**
 * @title TakeFlashloan Action contract
 * @notice Executes a sequence of Actions after flashloaning funds
 */
contract TakeFlashloan is Executable, ProxyPermission {
  ServiceRegistry internal immutable registry;
  address internal immutable dai;

  constructor(ServiceRegistry _registry, address _dai) {
    registry = _registry;
    dai = _dai;
  }

  /**
   * @dev When the Flashloan lender calls back the Operation Executor we may need to re-establish the calling context.
   * @dev The isProxyFlashloan flag is used to give the Operation Executor temporary authority to call the execute method on a user"s proxy. Refers to any proxy wallet (DSProxy or DPMProxy at time of writing)
   * @dev isDPMProxy flag switches between regular DSPRoxy and DPMProxy
   * @param data Encoded calldata that conforms to the FlashloanData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    FlashloanData memory flData = parseInputs(data);

    address operationExecutorAddress = registry.getRegisteredService(OPERATION_EXECUTOR);

    if (flData.isProxyFlashloan) {
      givePermission(flData.isDPMProxy, operationExecutorAddress);
    }

    IERC3156FlashLender(registry.getRegisteredService(FLASH_MINT_MODULE)).flashLoan(
      IERC3156FlashBorrower(operationExecutorAddress),
      dai,
      flData.amount,
      data
    );

    if (flData.isProxyFlashloan) {
      removePermission(flData.isDPMProxy, operationExecutorAddress);
    }

    emit Action(TAKE_FLASH_LOAN_ACTION, bytes(abi.encode(flData.amount)));
  }

  function parseInputs(bytes memory _callData) public pure returns (FlashloanData memory params) {
    return abi.decode(_callData, (FlashloanData));
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

/**
 * @title Shared Action Executable interface
 * @notice Provides a common interface for an execute method to all Action
 */
interface Executable {
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable;

  /**
   * @dev Emitted once an Action has completed execution
   * @param name The Action name
   * @param returned The bytes value returned by the Action
   **/
  event Action(string indexed name, bytes returned);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

interface IERC3156FlashBorrower {
  /**
   * @dev Receive a flash loan.
   * @param initiator The initiator of the loan.
   * @param token The loan currency.
   * @param amount The amount of tokens lent.
   * @param fee The additional amount of tokens to repay.
   * @param data Arbitrary data structure, intended to contain user-defined parameters.
   * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
   */
  function onFlashLoan(
    address initiator,
    address token,
    uint256 amount,
    uint256 fee,
    bytes calldata data
  ) external returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
  /**
   * @dev The amount of currency available to be lent.
   * @param token The loan currency.
   * @return The amount of `token` that can be borrowed.
   */
  function maxFlashLoan(address token) external view returns (uint256);

  /**
   * @dev The fee to be charged for a given loan.
   * @param token The loan currency.
   * @param amount The amount of tokens lent.
   * @return The amount of `token` to be charged for the loan, on top of the returned principal.
   */
  function flashFee(address token, uint256 amount) external view returns (uint256);

  /**
   * @dev Initiate a flash loan.
   * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
   * @param token The loan currency.
   * @param amount The amount of tokens lent.
   * @param data Arbitrary data structure, intended to contain user-defined parameters.
   */
  function flashLoan(
    IERC3156FlashBorrower receiver,
    address token,
    uint256 amount,
    bytes calldata data
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import { IERC20 } from "../interfaces/tokens/IERC20.sol";
import { Address } from "./Address.sol";
import { SafeMath } from "./SafeMath.sol";

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {ERC20-approve}, and its usage is discouraged.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

struct FlashloanData {
  uint256 amount;
  bool isProxyFlashloan;
  bool isDPMProxy;
  Call[] calls;
}

struct PullTokenData {
  address asset;
  address from;
  uint256 amount;
}

struct SendTokenData {
  address asset;
  address to;
  uint256 amount;
}

struct SetApprovalData {
  address asset;
  address delegate;
  uint256 amount;
  bool sumAmounts;
}

struct SwapData {
  address fromAsset;
  address toAsset;
  uint256 amount;
  uint256 receiveAtLeast;
  uint256 fee;
  bytes withData;
  bool collectFeeInFromToken;
}

struct Call {
  bytes32 targetHash;
  bytes callData;
  bool skipped;
}

struct Operation {
  uint8 currentAction;
  bytes32[] actions;
}

struct WrapEthData {
  uint256 amount;
}

struct UnwrapEthData {
  uint256 amount;
}

struct ReturnFundsData {
  address asset;
}

struct PositionCreatedData {
  string protocol;
  string positionType;
  address collateralToken;
  address debtToken;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

string constant OPERATION_STORAGE = "OperationStorage_2";
string constant OPERATION_EXECUTOR = "OperationExecutor_2";
string constant OPERATIONS_REGISTRY = "OperationsRegistry_2";
string constant ONE_INCH_AGGREGATOR = "OneInchAggregator";
string constant WETH = "WETH";
string constant DAI = "DAI";
uint256 constant RAY = 10**27;
bytes32 constant NULL = "";

/**
 * @dev We do not include patch versions in contract names to allow
 * for hotfixes of Action contracts
 * and to limit updates to TheGraph
 * if the types encoded in emitted events change then use a minor version and
 * update the ServiceRegistry with a new entry
 * and update TheGraph decoding accordingly
 */
string constant PULL_TOKEN_ACTION = "PullToken_3";
string constant SEND_TOKEN_ACTION = "SendToken_3";
string constant SET_APPROVAL_ACTION = "SetApproval_3";
string constant TAKE_FLASH_LOAN_ACTION = "TakeFlashloan_3";
string constant WRAP_ETH = "WrapEth_3";
string constant UNWRAP_ETH = "UnwrapEth_3";
string constant RETURN_FUNDS_ACTION = "ReturnFunds_3";
string constant POSITION_CREATED_ACTION = "PositionCreated";

string constant UNISWAP_ROUTER = "UniswapRouter";
string constant SWAP = "Swap";

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

string constant FLASH_MINT_MODULE = "McdFlashMintModule";

string constant OPEN_VAULT_ACTION = "MakerOpenVault";
string constant DEPOSIT_ACTION = "MakerDeposit";
string constant GENERATE_ACTION = "MakerGenerate";
string constant PAYBACK_ACTION = "MakerPayback";
string constant WITHDRAW_ACTION = "MakerWithdraw";

string constant MCD_MANAGER = "McdManager";
string constant MCD_JUG = "McdJug";
string constant MCD_JOIN_DAI = "McdJoinDai";
string constant CDP_ALLOW = "MakerCdpAllow";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./DSAuthority.sol";

contract DSAuthEvents {
  event LogSetAuthority(address indexed authority);
  event LogSetOwner(address indexed owner);
}

contract DSAuth is DSAuthEvents {
  DSAuthority public authority;
  address public owner;

  constructor() {
    owner = msg.sender;
    emit LogSetOwner(msg.sender);
  }

  function setOwner(address owner_) public auth {
    owner = owner_;
    emit LogSetOwner(owner);
  }

  function setAuthority(DSAuthority authority_) public auth {
    authority = authority_;
    emit LogSetAuthority(address(authority));
  }

  modifier auth() {
    require(isAuthorized(msg.sender, msg.sig), "Not authorized");
    _;
  }

  function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
    if (src == address(this)) {
      return true;
    } else if (src == owner) {
      return true;
    } else if (authority == DSAuthority(address(0))) {
      return false;
    } else {
      return authority.canCall(src, address(this), sig);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract DSNote {
  event LogNote(
    bytes4 indexed sig,
    address indexed guy,
    bytes32 indexed foo,
    bytes32 indexed bar,
    uint256 wad,
    bytes fax
  ) anonymous;

  modifier note() {
    bytes32 foo;
    bytes32 bar;

    assembly {
      foo := calldataload(4)
      bar := calldataload(36)
    }

    emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

abstract contract DSAuthority {
  function canCall(
    address src,
    address dst,
    bytes4 sig
  ) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

library Address {
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{ value: amount }("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    if (success) {
      return returndata;
    }

    if (returndata.length > 0) {
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    }

    revert(errorMessage);
  }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

import "./DSGuard.sol";
import "./DSAuth.sol";

import { FlashloanData } from "../../core/types/Common.sol";
import { IAccountImplementation } from "../../interfaces/dpm/IAccountImplementation.sol";
import { IAccountGuard } from "../../interfaces/dpm/IAccountGuard.sol";

contract ProxyPermission {
  address internal constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

  bytes4 public constant ALLOWED_METHOD_HASH = bytes4(keccak256("execute(address,bytes)"));

  function givePermission(bool isDPMProxy, address _contractAddr) public {
    if (isDPMProxy) {
      // DPM permission
      IAccountGuard(IAccountImplementation(address(this)).guard()).permit(
        _contractAddr,
        address(this),
        true
      );
    } else {
      // DSProxy permission
      address currAuthority = address(DSAuth(address(this)).authority());
      DSGuard guard = DSGuard(currAuthority);
      if (currAuthority == address(0)) {
        guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
        DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
      }

      if (!guard.canCall(_contractAddr, address(this), ALLOWED_METHOD_HASH)) {
        guard.permit(_contractAddr, address(this), ALLOWED_METHOD_HASH);
      }
    }
  }

  function removePermission(bool isDPMProxy, address _contractAddr) public {
    if (isDPMProxy) {
      // DPM permission
      IAccountGuard(IAccountImplementation(address(this)).guard()).permit(
        _contractAddr,
        address(this),
        false
      );
    } else {
      // DSProxy permission
      address currAuthority = address(DSAuth(address(this)).authority());
      if (currAuthority == address(0)) {
        return;
      }
      DSGuard guard = DSGuard(currAuthority);
      guard.forbid(_contractAddr, address(this), ALLOWED_METHOD_HASH);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

abstract contract DSGuard {
  function canCall(
    address src_,
    address dst_,
    bytes4 sig
  ) public view virtual returns (bool);

  function permit(
    bytes32 src,
    bytes32 dst,
    bytes32 sig
  ) public virtual;

  function forbid(
    bytes32 src,
    bytes32 dst,
    bytes32 sig
  ) public virtual;

  function permit(
    address src,
    address dst,
    bytes32 sig
  ) public virtual;

  function forbid(
    address src,
    address dst,
    bytes32 sig
  ) public virtual;
}

abstract contract DSGuardFactory {
  function newGuard() public virtual returns (DSGuard guard);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.15;

interface IAccountImplementation {
    function guard() external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.15;

interface IAccountGuard {
    function permit(address caller, address target, bool allowance) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20 {
  function totalSupply() external view returns (uint256 supply);

  function balanceOf(address _owner) external view returns (uint256 balance);

  function transfer(address _to, uint256 _value) external returns (bool success);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success);

  function approve(address _spender, uint256 _value) external returns (bool success);

  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  function decimals() external view returns (uint256 digits);
}