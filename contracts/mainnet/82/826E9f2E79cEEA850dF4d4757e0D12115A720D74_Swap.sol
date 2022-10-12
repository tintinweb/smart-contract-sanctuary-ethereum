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

  function swapTokens(
    SwapData calldata swapData
  ) public returns (uint256) {
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