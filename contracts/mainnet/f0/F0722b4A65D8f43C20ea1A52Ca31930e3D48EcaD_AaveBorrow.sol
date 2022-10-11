pragma solidity ^0.8.15;

import { Executable } from "../common/Executable.sol";
import { Write, UseStore } from "../common/UseStore.sol";
import { OperationStorage } from "../../core/OperationStorage.sol";
import { IVariableDebtToken } from "../../interfaces/aave/IVariableDebtToken.sol";
import { IWETHGateway } from "../../interfaces/aave/IWETHGateway.sol";
import { BorrowData } from "../../core/types/Aave.sol";
import { AAVE_WETH_GATEWAY, AAVE_LENDING_POOL, BORROW_ACTION } from "../../core/constants/Aave.sol";

contract AaveBorrow is Executable, UseStore {
  using Write for OperationStorage;

  IVariableDebtToken public constant dWETH =
    IVariableDebtToken(0xF63B34710400CAd3e044cFfDcAb00a0f32E33eCf);

  constructor(address _registry) UseStore(_registry) {}

  function execute(bytes calldata data, uint8[] memory) external payable override {
    BorrowData memory borrow = parseInputs(data);

    address wethGatewayAddress = registry.getRegisteredService(AAVE_WETH_GATEWAY);
    dWETH.approveDelegation(wethGatewayAddress, borrow.amount);
    
    IWETHGateway(wethGatewayAddress).borrowETH(
      registry.getRegisteredService(AAVE_LENDING_POOL),
      borrow.amount,
      2,
      0
    );
    address payable to = payable(borrow.to);
    to.transfer(borrow.amount);

    store().write(bytes32(borrow.amount));
    emit Action(BORROW_ACTION, bytes32(borrow.amount));
  }

  function parseInputs(bytes memory _callData) public pure returns (BorrowData memory params) {
    return abi.decode(_callData, (BorrowData));
  }
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

pragma solidity ^0.8.15;

import { OperationStorage } from "../../core/OperationStorage.sol";
import { ServiceRegistry } from "../../core/ServiceRegistry.sol";
import { OPERATION_STORAGE } from "../../core/constants/Common.sol";

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.15;

import { IScaledBalanceToken } from "./IScaledBalanceToken.sol";

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param onBehalfOf The address of the user on which behalf minting has been performed
   * @param value The amount to be minted
   * @param index The last index of the reserve
   **/
  event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

  /**
   * @dev delegates borrowing power to a user on the specific debt token
   * @param delegatee the address receiving the delegated borrowing power
   * @param amount the maximum amount being delegated. Delegation will still
   * respect the liquidation constraints (even if delegated, a delegatee cannot
   * force a delegator HF to go below 1)
   **/
  function approveDelegation(address delegatee, uint256 amount) external;

  /**
   * @dev returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return the current allowance of toUser
   **/
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

  /**
   * @dev Mints debt token to the `onBehalfOf` address
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return `true` if the the previous balance of the user is 0
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted when variable debt is burnt
   * @param user The user which debt has been burned
   * @param amount The amount of debt being burned
   * @param index The index of the user
   **/
  event Burn(address indexed user, uint256 amount, uint256 index);

  /**
   * @dev Burns user variable debt
   * @param user The user which debt is burnt
   * @param index The variable debt index of the reserve
   **/
  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external;
}

pragma solidity ^0.8.15;

interface IWETHGateway {
  function borrowETH(
    address lendingPool,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode
  ) external;
}

pragma solidity ^0.8.15;

struct DepositData {
  address asset;
  uint256 amount;
}

struct BorrowData {
  address asset;
  uint256 amount;
  address to;
}

struct WithdrawData {
  address asset;
  uint256 amount;
  address to;
}

struct PaybackData {
  address asset;
  uint256 amount;
  bool paybackAll;
}

pragma solidity ^0.8.15;

string constant AAVE_LENDING_POOL = "AaveLendingPool";
string constant AAVE_WETH_GATEWAY = "AaveWethGateway";

string constant BORROW_ACTION = "AaveBorrow";
string constant DEPOSIT_ACTION = "AaveDeposit";
string constant WITHDRAW_ACTION = "AaveWithdraw";
string constant PAYBACK_ACTION = "AavePayback";

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.15;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}