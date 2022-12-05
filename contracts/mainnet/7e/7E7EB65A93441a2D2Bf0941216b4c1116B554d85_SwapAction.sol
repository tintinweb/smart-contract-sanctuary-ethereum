// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { SafeERC20, IERC20 } from "../../libs/SafeERC20.sol";
import { IWETH } from "../../interfaces/tokens/IWETH.sol";
import { SwapData } from "../../core/types/Common.sol";
import { UseStore, Write } from "../../actions/common/UseStore.sol";
import { Swap } from "./Swap.sol";
import { WETH, SWAP } from "../../core/constants/Common.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { SWAP } from "../../core/constants/Common.sol";

/**
 * @title SwapAction Action contract
 * @notice Call the deployed Swap contract which handles swap execution
 */
contract SwapAction is Executable, UseStore {
  using SafeERC20 for IERC20;
  using Write for OperationStorage;

  constructor(address _registry) UseStore(_registry) {}

  /**
   * @dev The swap contract is pre-configured to use a specific exchange (EG 1inch)
   * @param data Encoded calldata that conforms to the SwapData struct
   */
  function execute(bytes calldata data, uint8[] memory) external payable override {
    address swapAddress = registry.getRegisteredService(SWAP);

    SwapData memory swap = parseInputs(data);

    IERC20(swap.fromAsset).safeApprove(swapAddress, swap.amount);

    uint256 received = Swap(swapAddress).swapTokens(swap);

    store().write(bytes32(received));

    emit Action(SWAP, bytes(abi.encode(received)));
  }

  function parseInputs(bytes memory _callData) public pure returns (SwapData memory params) {
    return abi.decode(_callData, (SwapData));
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

import "./IERC20.sol";

interface IWETH {
  function allowance(address, address) external returns (uint256);

  function balanceOf(address) external returns (uint256);

  function approve(address, uint256) external;

  function transfer(address, uint256) external returns (bool);

  function transferFrom(
    address,
    address,
    uint256
  ) external returns (bool);

  function deposit() external payable;

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { OperationStorage } from "../../core/OperationStorage.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { OPERATION_STORAGE } from "../../core/constants/Common.sol";

/**
 * @title UseStore contract
 * @notice Provides access to the OperationStorage contract
 * @dev Is used by Action contracts to store and retrieve values from Operation Storage.
 * @dev Previously stored values are used to override values passed to Actions during Operation execution
 */
abstract contract UseStore {
  ServiceRegistry internal immutable registry;

  constructor(address _registry) {
    registry = ServiceRegistry(_registry);
  }

  function store() internal view returns (OperationStorage) {
    return OperationStorage(registry.getRegisteredService(OPERATION_STORAGE));
  }
}

library Read {
  function read(
    OperationStorage _storage,
    bytes32 param,
    uint256 paramMapping,
    address who
  ) internal view returns (bytes32) {
    if (paramMapping > 0) {
      return _storage.at(paramMapping - 1, who);
    }

    return param;
  }

  function readUint(
    OperationStorage _storage,
    bytes32 param,
    uint256 paramMapping,
    address who
  ) internal view returns (uint256) {
    return uint256(read(_storage, param, paramMapping, who));
  }
}

library Write {
  function write(OperationStorage _storage, bytes32 value) internal {
    _storage.push(value);
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { IERC20 } from "../../interfaces/tokens/IERC20.sol";
import { SafeMath } from "../../libs/SafeMath.sol";
import { SafeERC20 } from "../../libs/SafeERC20.sol";
import { ONE_INCH_AGGREGATOR } from "../../core/constants/Common.sol";
import { SwapData } from "../../core/types/Common.sol";

contract Swap {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public feeBeneficiaryAddress;
  uint256 public constant feeBase = 10000;
  mapping(uint256 => bool) public feeTiers;
  mapping(address => bool) public authorizedAddresses;
  ServiceRegistry internal immutable registry;

  error ReceivedLess(uint256 receiveAtLeast, uint256 received);
  error Unauthorized();
  error FeeTierDoesNotExist(uint256 fee);
  error FeeTierAlreadyExists(uint256 fee);
  error SwapFailed();

  constructor(
    address authorisedCaller,
    address feeBeneficiary,
    uint256 _initialFee,
    address _registry
  ) {
    authorizedAddresses[authorisedCaller] = true;
    authorizedAddresses[feeBeneficiary] = true;
    _addFeeTier(_initialFee);
    feeBeneficiaryAddress = feeBeneficiary;
    registry = ServiceRegistry(_registry);
  }

  event AssetSwap(
    address indexed assetIn,
    address indexed assetOut,
    uint256 amountIn,
    uint256 amountOut
  );

  event FeePaid(address indexed beneficiary, uint256 amount, address token);
  event SlippageSaved(uint256 minimumPossible, uint256 actualAmount);
  event FeeTierAdded(uint256 fee);
  event FeeTierRemoved(uint256 fee);

  modifier onlyAuthorised() {
    if (!authorizedAddresses[msg.sender]) {
      revert Unauthorized();
    }
    _;
  }

  function _addFeeTier(uint256 fee) private {
    if (feeTiers[fee]) {
      revert FeeTierAlreadyExists(fee);
    }
    feeTiers[fee] = true;
    emit FeeTierAdded(fee);
  }

  function addFeeTier(uint256 fee) public onlyAuthorised {
    _addFeeTier(fee);
  }

  function removeFeeTier(uint256 fee) public onlyAuthorised {
    if (!feeTiers[fee]) {
      revert FeeTierDoesNotExist(fee);
    }
    feeTiers[fee] = false;
    emit FeeTierRemoved(fee);
  }

  function verifyFee(uint256 feeId) public view returns (bool valid) {
    valid = feeTiers[feeId];
  }

  function _swap(
    address fromAsset,
    address toAsset,
    uint256 amount,
    uint256 receiveAtLeast,
    address callee,
    bytes calldata withData
  ) internal returns (uint256 balance) {
    IERC20(fromAsset).safeApprove(callee, amount);

    (bool success, ) = callee.call(withData);

    if (!success) {
      revert SwapFailed();
    }

    balance = IERC20(toAsset).balanceOf(address(this));

    emit SlippageSaved(receiveAtLeast, balance);

    if (balance < receiveAtLeast) {
      revert ReceivedLess(receiveAtLeast, balance);
    }
    emit SlippageSaved(receiveAtLeast, balance);
    emit AssetSwap(fromAsset, toAsset, amount, balance);
  }

  function _collectFee(
    address asset,
    uint256 fromAmount,
    uint256 fee
  ) internal returns (uint256 amount) {
    bool isFeeValid = verifyFee(fee);
    if (!isFeeValid) {
      revert FeeTierDoesNotExist(fee);
    }

    uint256 feeToTransfer = fromAmount.mul(fee).div(fee.add(feeBase));

    if (fee > 0) {
      IERC20(asset).safeTransfer(feeBeneficiaryAddress, feeToTransfer);
      emit FeePaid(feeBeneficiaryAddress, feeToTransfer, asset);
    }

    amount = fromAmount.sub(feeToTransfer);
  }

  function swapTokens(SwapData calldata swapData) public returns (uint256) {
    IERC20(swapData.fromAsset).safeTransferFrom(msg.sender, address(this), swapData.amount);

    uint256 amountFrom = swapData.amount;

    if (swapData.collectFeeInFromToken) {
      amountFrom = _collectFee(swapData.fromAsset, swapData.amount, swapData.fee);
    }

    address oneInch = registry.getRegisteredService(ONE_INCH_AGGREGATOR);

    uint256 toTokenBalance = _swap(
      swapData.fromAsset,
      swapData.toAsset,
      amountFrom,
      swapData.receiveAtLeast,
      oneInch,
      swapData.withData
    );

    if (!swapData.collectFeeInFromToken) {
      toTokenBalance = _collectFee(swapData.toAsset, toTokenBalance, swapData.fee);
    }

    uint256 fromTokenBalance = IERC20(swapData.fromAsset).balanceOf(address(this));
    if (fromTokenBalance > 0) {
      IERC20(swapData.fromAsset).safeTransfer(msg.sender, fromTokenBalance);
    }

    IERC20(swapData.toAsset).safeTransfer(msg.sender, toTokenBalance);
    return toTokenBalance;
  }
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
string constant PULL_TOKEN_ACTION = "PullToken_2";
string constant SEND_TOKEN_ACTION = "SendToken_2";
string constant SET_APPROVAL_ACTION = "SetApproval_2";
string constant TAKE_FLASH_LOAN_ACTION = "TakeFlashloan_2";
string constant WRAP_ETH = "WrapEth_2";
string constant UNWRAP_ETH = "UnwrapEth_2";
string constant RETURN_FUNDS_ACTION = "ReturnFunds_2";

string constant UNISWAP_ROUTER = "UniswapRouter";
string constant SWAP = "Swap";

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

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
    if(skipped) {
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