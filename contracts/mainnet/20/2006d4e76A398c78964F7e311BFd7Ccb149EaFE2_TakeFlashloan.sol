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

abstract contract DSAuthority {
  function canCall(
    address src,
    address dst,
    bytes4 sig
  ) public view virtual returns (bool);
}