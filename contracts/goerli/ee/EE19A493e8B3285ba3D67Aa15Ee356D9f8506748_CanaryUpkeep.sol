// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../interfaces/KeeperCompatibleInterface.sol";
import "../interfaces/KeeperRegistryInterface.sol";
import "../ConfirmedOwner.sol";

error NoKeeperNodes();
error InsufficientInterval();

/**
 * @notice A canary upkeep which requires a different keeper to service its upkeep at an interval. This makes sure that
 * all keepers are in a healthy state.
 */
contract CanaryUpkeep is KeeperCompatibleInterface, ConfirmedOwner {
  uint256 private s_keeperIndex;
  uint256 private s_interval;
  uint256 private s_timestamp;
  KeeperRegistryExecutableInterface private immutable i_keeperRegistry;

  /**
   * @param keeperRegistry address of a keeper registry
   */
  constructor(KeeperRegistryExecutableInterface keeperRegistry, uint256 interval) ConfirmedOwner(msg.sender) {
    i_keeperRegistry = keeperRegistry;
    s_timestamp = block.timestamp;
    s_interval = interval;
    s_keeperIndex = 0;
  }

  /**
   * @return the current keeper index
   */
  function getKeeperIndex() external view returns (uint256) {
    return s_keeperIndex;
  }

  /**
   * @return the current timestamp
   */
  function getTimestamp() external view returns (uint256) {
    return s_timestamp;
  }

  /**
   * @return the current interval
   */
  function getInterval() external view returns (uint256) {
    return s_interval;
  }

  /**
   * @return the keeper registry
   */
  function getKeeperRegistry() external view returns (KeeperRegistryExecutableInterface) {
    return i_keeperRegistry;
  }

  /**
   * @notice updates the interval
   * @param interval the new interval
   */
  function setInterval(uint256 interval) external onlyOwner {
    s_interval = interval;
  }

  /**
   * @notice returns true if keeper array is not empty and sufficient time has passed
   */
  function checkUpkeep(
    bytes calldata /* checkData */
  ) external view override returns (bool, bytes memory) {
    bool upkeepNeeded = block.timestamp >= s_interval + s_timestamp;
    return (upkeepNeeded, bytes(""));
  }

  /**
   * @notice checks keepers array limit, timestamp limit, and requires transaction origin must be the anticipated keeper.
   * If all checks pass, update the keeper index and timestamp. Otherwise, revert this transaction.
   */
  function performUpkeep(
    bytes calldata /* performData */
  ) external override {
    (State memory _s, Config memory _c, address[] memory keepers) = i_keeperRegistry.getState();
    if (keepers.length == 0) {
      revert NoKeeperNodes();
    }
    if (block.timestamp < s_interval + s_timestamp) {
      revert InsufficientInterval();
    }
    // if keepers array is shortened, this statement will make sure keeper index is always valid
    if (s_keeperIndex >= keepers.length) {
      s_keeperIndex = 0;
    }

    require(tx.origin == keepers[s_keeperIndex], "transaction origin is not the anticipated keeper.");
    s_keeperIndex = (s_keeperIndex + 1) % keepers.length;
    s_timestamp = block.timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @ownerLinkBalance withdrawable balance of LINK by contract owner
 * @numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface KeeperRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface KeeperRegistryInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface KeeperRegistryExecutableInterface is KeeperRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}