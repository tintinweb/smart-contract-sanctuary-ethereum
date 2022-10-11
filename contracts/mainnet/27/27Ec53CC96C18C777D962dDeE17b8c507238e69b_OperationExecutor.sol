//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { ServiceRegistry } from "./ServiceRegistry.sol";
import { OperationStorage } from "./OperationStorage.sol";
import { OperationsRegistry } from "./OperationsRegistry.sol";
import { DSProxy } from "../libs/DS/DSProxy.sol";
import { Address } from "../libs/Address.sol";
import { TakeFlashloan } from "../actions/common/TakeFlashloan.sol";
import { IERC3156FlashBorrower } from "../interfaces/flashloan/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "../interfaces/flashloan/IERC3156FlashLender.sol";
import { SafeERC20, IERC20 } from "../libs/SafeERC20.sol";
import { SafeMath } from "../libs/SafeMath.sol";
import { FlashloanData, Call } from "./types/Common.sol";
import { OPERATION_STORAGE, OPERATIONS_REGISTRY, OPERATION_EXECUTOR } from "./constants/Common.sol";
import { FLASH_MINT_MODULE } from "./constants/Maker.sol";

contract OperationExecutor is IERC3156FlashBorrower {
  using Address for address;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ServiceRegistry public immutable registry;

  /**
   * @dev Emitted once an Operation has completed execution
   * @param name The address initiating the deposit
   * @param calls The call data for the actions the operation must executes
   **/
  event Operation(string name, Call[] calls);

  constructor(ServiceRegistry _registry) {
    registry = _registry;
  }

  function executeOp(Call[] memory calls, string calldata operationName) public payable {
    OperationStorage opStorage = OperationStorage(registry.getRegisteredService(OPERATION_STORAGE));
    opStorage.lock();
    OperationsRegistry opRegistry = OperationsRegistry(
      registry.getRegisteredService(OPERATIONS_REGISTRY)
    );

    opStorage.clearStorage();
    opStorage.setOperationActions(opRegistry.getOperation(operationName));
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
        opStorage.verifyAction(calls[current].targetHash);
      }

      address target = registry.getServiceAddress(calls[current].targetHash);

      target.functionDelegateCall(
        calls[current].callData,
        "OpExecutor: low-level delegatecall failed"
      );
    }
  }

  function callbackAggregate(Call[] memory calls) external {
    require(msg.sender == registry.getRegisteredService(OPERATION_EXECUTOR), "OpExecutor: Caller forbidden");
    aggregate(calls);
  }

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

    if (flData.dsProxyFlashloan) {
      IERC20(asset).safeTransfer(initiator, flData.amount);

      DSProxy(payable(initiator)).execute(
        address(this),
        abi.encodeWithSelector(this.callbackAggregate.selector, flData.calls)
      );
    } else {
      OperationStorage opStorage = OperationStorage(registry.getRegisteredService(OPERATION_STORAGE));
      opStorage.setInitiator(initiator);
      aggregate(flData.calls);
    }

    uint256 paybackAmount = amount.add(fee);
    require(IERC20(asset).balanceOf(address(this)) >= paybackAmount, "Insufficient funds for payback");

    IERC20(asset).safeApprove(lender, paybackAmount);

    return keccak256("ERC3156FlashBorrower.onFlashLoan");
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.1;

contract ServiceRegistry {
  mapping(address => bool) public trustedAddresses;
  mapping(bytes32 => uint256) public lastExecuted;
  mapping(bytes32 => address) private namedService;
  address public owner;

  uint256 public requiredDelay = 0; // big enough that any power of miner over timestamp does not matter

  modifier validateInput(uint256 len) {
    require(msg.data.length == len, "illegal-padding");
    _;
  }

  modifier delayedExecution() {
    bytes32 operationHash = keccak256(msg.data);
    uint256 reqDelay = requiredDelay;

    // solhint-disable-next-line not-rely-on-time
    uint256 blockTimestamp = block.timestamp;
    if (lastExecuted[operationHash] == 0 && reqDelay > 0) {
      // not called before, scheduled for execution
      lastExecuted[operationHash] = blockTimestamp;
      emit ChangeScheduled(msg.data, operationHash, blockTimestamp + reqDelay);
    } else {
      require(blockTimestamp - reqDelay > lastExecuted[operationHash], "delay-to-small");
      emit ChangeApplied(msg.data, blockTimestamp);
      _;
      lastExecuted[operationHash] = 0;
    }
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only-owner");
    _;
  }

  constructor(uint256 initialDelay) {
    require(initialDelay < type(uint256).max, "risk-of-overflow");
    requiredDelay = initialDelay;
    owner = msg.sender;
  }

  function transferOwnership(address newOwner) public onlyOwner validateInput(36) delayedExecution {
    owner = newOwner;
  }

  function changeRequiredDelay(uint256 newDelay)
    public
    onlyOwner
    validateInput(36)
    delayedExecution
  {
    requiredDelay = newDelay;
  }

  function addTrustedAddress(address trustedAddress)
    public
    onlyOwner
    validateInput(36)
    delayedExecution
  {
    trustedAddresses[trustedAddress] = true;
  }

  function removeTrustedAddress(address trustedAddress) public onlyOwner validateInput(36) {
    trustedAddresses[trustedAddress] = false;
  }

  function getServiceNameHash(string calldata name) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(name));
  }

  function addNamedService(bytes32 serviceNameHash, address serviceAddress)
    public
    onlyOwner
    validateInput(68)
    delayedExecution
  {
    require(namedService[serviceNameHash] == address(0), "service-override");
    namedService[serviceNameHash] = serviceAddress;
  }

  function updateNamedService(bytes32 serviceNameHash, address serviceAddress)
    public
    onlyOwner
    validateInput(68)
    delayedExecution
  {
    require(namedService[serviceNameHash] != address(0), "service-does-not-exist");
    namedService[serviceNameHash] = serviceAddress;
  }

  function removeNamedService(bytes32 serviceNameHash) public onlyOwner validateInput(36) {
    require(namedService[serviceNameHash] != address(0), "service-does-not-exist");
    namedService[serviceNameHash] = address(0);
    emit RemoveApplied(serviceNameHash);
  }

  function getRegisteredService(string memory serviceName) public view returns (address) {
    return getServiceAddress(keccak256(abi.encodePacked(serviceName)));
  }

  function getServiceAddress(bytes32 serviceNameHash) public view returns (address serviceAddress) {
    serviceAddress = namedService[serviceNameHash];
    require(serviceAddress != address(0), "no-such-service");
  }

  function clearScheduledExecution(bytes32 scheduledExecution) public onlyOwner validateInput(36) {
    require(lastExecuted[scheduledExecution] > 0, "execution-not-scheduled");
    lastExecuted[scheduledExecution] = 0;
    emit ChangeCancelled(scheduledExecution);
  }

  event ChangeScheduled(bytes data, bytes32 dataHash, uint256 firstPossibleExecutionTime);
  event ChangeCancelled(bytes32 data);
  event ChangeApplied(bytes data, uint256 firstPossibleExecutionTime);
  event RemoveApplied(bytes32 nameHash);
}

pragma solidity ^0.8.15;

import { ServiceRegistry } from "./ServiceRegistry.sol";

contract OperationStorage {
  uint8 internal action = 0;
  bytes32[] public actions;
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

  function lock() external{
    locked = true;
    whoLocked = msg.sender;
  }

  function unlock() external {
    require(whoLocked == msg.sender, "Only the locker can unlock");
    require(locked, "Not locked");
    locked = false;
    whoLocked = address(0);
  }

  function setInitiator(address _initiator) external {
    require(msg.sender == operationExecutorAddress);
    initiator = _initiator;
  }

  function setOperationActions(bytes32[] memory _actions) external {
    actions = _actions;
  }

  function verifyAction(bytes32 actionHash) external {
    require(actions[action] == actionHash, "incorrect-action");
    registry.getServiceAddress(actionHash);
    action++;
  }

  function hasActionsToVerify() external view returns (bool) {
    return actions.length > 0;
  }

  function push(bytes32 value) external {
    address who = msg.sender;
    if( who == operationExecutorAddress) {
      who = initiator;
    }

    if(returnValues[who].length ==0){
      valuesHolders.push(who);
    }
    returnValues[who].push(value);
  }

  function at(uint256 index, address who) external view returns (bytes32) {
    if( who == operationExecutorAddress) {
      who = initiator;
    }
    return returnValues[who][index];
  }

  function len(address who) external view returns (uint256) {
    if( who == operationExecutorAddress) {
      who = initiator;
    }
    return returnValues[who].length;
  }

  function clearStorage() external {
    delete action;
    delete actions;
    for(uint256 i = 0; i < valuesHolders.length; i++){
      delete returnValues[valuesHolders[i]];
    }
    delete valuesHolders;
  }
}

pragma solidity ^0.8.15;

import { Operation } from "./types/Common.sol";
import { OPERATIONS_REGISTRY } from "./constants/Common.sol";

struct StoredOperation {
  bytes32[] actions;
  string name;
}

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

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  /**
   * @dev Emitted when a new operation is added or an existing operation is updated
   * @param name The Operation name
   **/
  event OperationAdded(string name);

  function addOperation(string memory name, bytes32[] memory actions) external onlyOwner {
    operations[name] = StoredOperation(actions, name);
    emit OperationAdded(name);
  }

  function getOperation(string memory name) external view returns (bytes32[] memory actions) {
    if(keccak256(bytes(operations[name].name)) == keccak256(bytes(""))) {
      revert("Operation doesn't exist");
    }
    actions = operations[name].actions;
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

pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { IERC3156FlashBorrower } from "../../interfaces/flashloan/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "../../interfaces/flashloan/IERC3156FlashLender.sol";
import { FlashloanData } from "../../core/types/Common.sol";
import { OPERATION_EXECUTOR, DAI, TAKE_FLASH_LOAN_ACTION } from "../../core/constants/Common.sol";
import { FLASH_MINT_MODULE } from "../../core/constants/Maker.sol";
import { ProxyPermission } from "../../libs/DS/ProxyPermission.sol";

contract TakeFlashloan is Executable, ProxyPermission {
  ServiceRegistry internal immutable registry;
  address internal immutable dai;

  constructor(ServiceRegistry _registry, address _dai) {
    registry = _registry;
    dai = _dai;
  }

  function execute(bytes calldata data, uint8[] memory) external payable override {
    FlashloanData memory flData = parseInputs(data);

    address operationExecutorAddress = registry.getRegisteredService(OPERATION_EXECUTOR);

    if (flData.dsProxyFlashloan) {
      givePermission(operationExecutorAddress);
    }
    IERC3156FlashLender(registry.getRegisteredService(FLASH_MINT_MODULE)).flashLoan(
      IERC3156FlashBorrower(operationExecutorAddress),
      dai,
      flData.amount,
      data
    );

    if (flData.dsProxyFlashloan) {
      removePermission(operationExecutorAddress);
    }
    emit Action(TAKE_FLASH_LOAN_ACTION, bytes32(flData.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (FlashloanData memory params) {
    return abi.decode(_callData, (FlashloanData));
  }
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

pragma solidity ^0.8.15;

struct FlashloanData {
  uint256 amount;
  bool dsProxyFlashloan;
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

pragma solidity ^0.8.15;

string constant OPERATION_STORAGE = "OperationStorage";
string constant OPERATION_EXECUTOR = "OperationExecutor";
string constant OPERATIONS_REGISTRY = "OperationsRegistry";
string constant ONE_INCH_AGGREGATOR = "OneInchAggregator";
string constant WETH = "WETH";
string constant DAI = "DAI";
uint256 constant RAY = 10**27;
bytes32 constant NULL = "";

string constant PULL_TOKEN_ACTION = "PullToken";
string constant SEND_TOKEN_ACTION = "SendToken";
string constant SET_APPROVAL_ACTION = "SetApproval";
string constant TAKE_FLASH_LOAN_ACTION = "TakeFlashloan";
string constant WRAP_ETH = "WrapEth";
string constant UNWRAP_ETH = "UnwrapEth";
string constant RETURN_FUNDS_ACTION = "ReturnFunds";

string constant UNISWAP_ROUTER = "UniswapRouter";
string constant SWAP = "Swap";

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

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

pragma solidity ^0.8.15;

interface Executable {
  function execute(bytes calldata data, uint8[] memory paramsMap) external payable;

  /**
   * @dev Emitted once an Action has completed execution
   * @param name The Action name
   * @param returned The value returned by the Action
   **/
  event Action(string name, bytes32 returned);
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

import "./DSGuard.sol";
import "./DSAuth.sol";

contract ProxyPermission {
  address internal constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

  bytes4 public constant ALLOWED_METHOD_HASH = bytes4(keccak256("execute(address,bytes)"));

  function givePermission(address _contractAddr) public {
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

  function removePermission(address _contractAddr) public {
    address currAuthority = address(DSAuth(address(this)).authority());

    if (currAuthority == address(0)) {
      return;
    }

    DSGuard guard = DSGuard(currAuthority);
    guard.forbid(_contractAddr, address(this), ALLOWED_METHOD_HASH);
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