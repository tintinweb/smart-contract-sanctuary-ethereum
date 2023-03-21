// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../../interfaces/LinkTokenInterface.sol";
import "../../interfaces/automation/2_0/AutomationRegistryInterface2_0.sol";
import "../../interfaces/TypeAndVersionInterface.sol";
import "../../ConfirmedOwner.sol";
import "../../interfaces/ERC677ReceiverInterface.sol";

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract KeeperRegistrar2_0 is TypeAndVersionInterface, ConfirmedOwner, ERC677ReceiverInterface {
  /**
   * DISABLED: No auto approvals, all new upkeeps should be approved manually.
   * ENABLED_SENDER_ALLOWLIST: Auto approvals for allowed senders subject to max allowed. Manual for rest.
   * ENABLED_ALL: Auto approvals for all new upkeeps subject to max allowed.
   */
  enum AutoApproveType {
    DISABLED,
    ENABLED_SENDER_ALLOWLIST,
    ENABLED_ALL
  }

  bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

  mapping(bytes32 => PendingRequest) private s_pendingRequests;

  LinkTokenInterface public immutable LINK;

  /**
   * @notice versions:
   * - KeeperRegistrar 2.0.0: Remove source from register
   *                          Breaks our example of "Register an Upkeep using your own deployed contract"
   * - KeeperRegistrar 1.1.0: Add functionality for sender allowlist in auto approve
   *                        : Remove rate limit and add max allowed for auto approve
   * - KeeperRegistrar 1.0.0: initial release
   */
  string public constant override typeAndVersion = "KeeperRegistrar 2.0.0";

  struct RegistrarConfig {
    AutoApproveType autoApproveConfigType;
    uint32 autoApproveMaxAllowed;
    uint32 approvedCount;
    AutomationRegistryBaseInterface keeperRegistry;
    uint96 minLINKJuels;
  }

  struct PendingRequest {
    address admin;
    uint96 balance;
  }

  struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
  }

  RegistrarConfig private s_config;
  // Only applicable if s_config.configType is ENABLED_SENDER_ALLOWLIST
  mapping(address => bool) private s_autoApproveAllowedSenders;

  event RegistrationRequested(
    bytes32 indexed hash,
    string name,
    bytes encryptedEmail,
    address indexed upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes checkData,
    uint96 amount
  );

  event RegistrationApproved(bytes32 indexed hash, string displayName, uint256 indexed upkeepId);

  event RegistrationRejected(bytes32 indexed hash);

  event AutoApproveAllowedSenderSet(address indexed senderAddress, bool allowed);

  event ConfigChanged(
    AutoApproveType autoApproveConfigType,
    uint32 autoApproveMaxAllowed,
    address keeperRegistry,
    uint96 minLINKJuels
  );

  error InvalidAdminAddress();
  error RequestNotFound();
  error HashMismatch();
  error OnlyAdminOrOwner();
  error InsufficientPayment();
  error RegistrationRequestFailed();
  error OnlyLink();
  error AmountMismatch();
  error SenderMismatch();
  error FunctionNotPermitted();
  error LinkTransferFailed(address to);
  error InvalidDataLength();

  /*
   * @param LINKAddress Address of Link token
   * @param autoApproveConfigType setting for auto-approve registrations
   * @param autoApproveMaxAllowed max number of registrations that can be auto approved
   * @param keeperRegistry keeper registry address
   * @param minLINKJuels minimum LINK that new registrations should fund their upkeep with
   */
  constructor(
    address LINKAddress,
    AutoApproveType autoApproveConfigType,
    uint16 autoApproveMaxAllowed,
    address keeperRegistry,
    uint96 minLINKJuels
  ) ConfirmedOwner(msg.sender) {
    LINK = LinkTokenInterface(LINKAddress);
    setRegistrationConfig(autoApproveConfigType, autoApproveMaxAllowed, keeperRegistry, minLINKJuels);
  }

  //EXTERNAL

  /**
   * @notice register can only be called through transferAndCall on LINK contract
   * @param name string of the upkeep to be registered
   * @param encryptedEmail email address of upkeep contact
   * @param upkeepContract address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when performing upkeep
   * @param adminAddress address to cancel upkeep and withdraw remaining funds
   * @param checkData data passed to the contract when checking for upkeep
   * @param amount quantity of LINK upkeep is funded with (specified in Juels)
   * @param offchainConfig offchainConfig for upkeep in bytes
   * @param sender address of the sender making the request
   */
  function register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    bytes calldata offchainConfig,
    uint96 amount,
    address sender
  ) external onlyLINK {
    _register(
      RegistrationParams({
        name: name,
        encryptedEmail: encryptedEmail,
        upkeepContract: upkeepContract,
        gasLimit: gasLimit,
        adminAddress: adminAddress,
        checkData: checkData,
        offchainConfig: offchainConfig,
        amount: amount
      }),
      sender
    );
  }

  /**
   * @notice Allows external users to register upkeeps; assumes amount is approved for transfer by the contract
   * @param requestParams struct of all possible registration parameters
   */
  function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256) {
    if (requestParams.amount < s_config.minLINKJuels) {
      revert InsufficientPayment();
    }

    LINK.transferFrom(msg.sender, address(this), requestParams.amount);

    return _register(requestParams, msg.sender);
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function approve(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    bytes calldata offchainConfig,
    bytes32 hash
  ) external onlyOwner {
    PendingRequest memory request = s_pendingRequests[hash];
    if (request.admin == address(0)) {
      revert RequestNotFound();
    }
    bytes32 expectedHash = keccak256(abi.encode(upkeepContract, gasLimit, adminAddress, checkData, offchainConfig));
    if (hash != expectedHash) {
      revert HashMismatch();
    }
    delete s_pendingRequests[hash];
    _approve(
      RegistrationParams({
        name: name,
        encryptedEmail: "",
        upkeepContract: upkeepContract,
        gasLimit: gasLimit,
        adminAddress: adminAddress,
        checkData: checkData,
        offchainConfig: offchainConfig,
        amount: request.balance
      }),
      expectedHash
    );
  }

  /**
   * @notice cancel will remove a registration request and return the refunds to the request.admin
   * @param hash the request hash
   */
  function cancel(bytes32 hash) external {
    PendingRequest memory request = s_pendingRequests[hash];
    if (!(msg.sender == request.admin || msg.sender == owner())) {
      revert OnlyAdminOrOwner();
    }
    if (request.admin == address(0)) {
      revert RequestNotFound();
    }
    delete s_pendingRequests[hash];
    bool success = LINK.transfer(request.admin, request.balance);
    if (!success) {
      revert LinkTransferFailed(request.admin);
    }
    emit RegistrationRejected(hash);
  }

  /**
   * @notice owner calls this function to set if registration requests should be sent directly to the Keeper Registry
   * @param autoApproveConfigType setting for auto-approve registrations
   *                   note: autoApproveAllowedSenders list persists across config changes irrespective of type
   * @param autoApproveMaxAllowed max number of registrations that can be auto approved
   * @param keeperRegistry new keeper registry address
   * @param minLINKJuels minimum LINK that new registrations should fund their upkeep with
   */
  function setRegistrationConfig(
    AutoApproveType autoApproveConfigType,
    uint16 autoApproveMaxAllowed,
    address keeperRegistry,
    uint96 minLINKJuels
  ) public onlyOwner {
    uint32 approvedCount = s_config.approvedCount;
    s_config = RegistrarConfig({
      autoApproveConfigType: autoApproveConfigType,
      autoApproveMaxAllowed: autoApproveMaxAllowed,
      approvedCount: approvedCount,
      minLINKJuels: minLINKJuels,
      keeperRegistry: AutomationRegistryBaseInterface(keeperRegistry)
    });

    emit ConfigChanged(autoApproveConfigType, autoApproveMaxAllowed, keeperRegistry, minLINKJuels);
  }

  /**
   * @notice owner calls this function to set allowlist status for senderAddress
   * @param senderAddress senderAddress to set the allowlist status for
   * @param allowed true if senderAddress needs to be added to allowlist, false if needs to be removed
   */
  function setAutoApproveAllowedSender(address senderAddress, bool allowed) external onlyOwner {
    s_autoApproveAllowedSenders[senderAddress] = allowed;

    emit AutoApproveAllowedSenderSet(senderAddress, allowed);
  }

  /**
   * @notice read the allowlist status of senderAddress
   * @param senderAddress address to read the allowlist status for
   */
  function getAutoApproveAllowedSender(address senderAddress) external view returns (bool) {
    return s_autoApproveAllowedSenders[senderAddress];
  }

  /**
   * @notice read the current registration configuration
   */
  function getRegistrationConfig()
    external
    view
    returns (
      AutoApproveType autoApproveConfigType,
      uint32 autoApproveMaxAllowed,
      uint32 approvedCount,
      address keeperRegistry,
      uint256 minLINKJuels
    )
  {
    RegistrarConfig memory config = s_config;
    return (
      config.autoApproveConfigType,
      config.autoApproveMaxAllowed,
      config.approvedCount,
      address(config.keeperRegistry),
      config.minLINKJuels
    );
  }

  /**
   * @notice gets the admin address and the current balance of a registration request
   */
  function getPendingRequest(bytes32 hash) external view returns (address, uint96) {
    PendingRequest memory request = s_pendingRequests[hash];
    return (request.admin, request.balance);
  }

  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @param sender Address of the sender transfering LINK
   * @param amount Amount of LINK sent (specified in Juels)
   * @param data Payload of the transaction
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  )
    external
    override
    onlyLINK
    permittedFunctionsForLINK(data)
    isActualAmount(amount, data)
    isActualSender(sender, data)
  {
    if (data.length < 292) revert InvalidDataLength();
    if (amount < s_config.minLINKJuels) {
      revert InsufficientPayment();
    }
    (bool success, ) = address(this).delegatecall(data);
    // calls register
    if (!success) {
      revert RegistrationRequestFailed();
    }
  }

  //PRIVATE

  /**
   * @dev verify registration request and emit RegistrationRequested event
   */
  function _register(RegistrationParams memory params, address sender) private returns (uint256) {
    if (params.adminAddress == address(0)) {
      revert InvalidAdminAddress();
    }
    bytes32 hash = keccak256(
      abi.encode(params.upkeepContract, params.gasLimit, params.adminAddress, params.checkData, params.offchainConfig)
    );

    emit RegistrationRequested(
      hash,
      params.name,
      params.encryptedEmail,
      params.upkeepContract,
      params.gasLimit,
      params.adminAddress,
      params.checkData,
      params.amount
    );

    uint256 upkeepId;
    RegistrarConfig memory config = s_config;
    if (_shouldAutoApprove(config, sender)) {
      s_config.approvedCount = config.approvedCount + 1;

      upkeepId = _approve(params, hash);
    } else {
      uint96 newBalance = s_pendingRequests[hash].balance + params.amount;
      s_pendingRequests[hash] = PendingRequest({admin: params.adminAddress, balance: newBalance});
    }

    return upkeepId;
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function _approve(RegistrationParams memory params, bytes32 hash) private returns (uint256) {
    AutomationRegistryBaseInterface keeperRegistry = s_config.keeperRegistry;

    // register upkeep
    uint256 upkeepId = keeperRegistry.registerUpkeep(
      params.upkeepContract,
      params.gasLimit,
      params.adminAddress,
      params.checkData,
      params.offchainConfig
    );
    // fund upkeep
    bool success = LINK.transferAndCall(address(keeperRegistry), params.amount, abi.encode(upkeepId));
    if (!success) {
      revert LinkTransferFailed(address(keeperRegistry));
    }

    emit RegistrationApproved(hash, params.name, upkeepId);

    return upkeepId;
  }

  /**
   * @dev verify sender allowlist if needed and check max limit
   */
  function _shouldAutoApprove(RegistrarConfig memory config, address sender) private view returns (bool) {
    if (config.autoApproveConfigType == AutoApproveType.DISABLED) {
      return false;
    }
    if (
      config.autoApproveConfigType == AutoApproveType.ENABLED_SENDER_ALLOWLIST && (!s_autoApproveAllowedSenders[sender])
    ) {
      return false;
    }
    if (config.approvedCount < config.autoApproveMaxAllowed) {
      return true;
    }
    return false;
  }

  //MODIFIERS

  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier onlyLINK() {
    if (msg.sender != address(LINK)) {
      revert OnlyLink();
    }
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `register` function selector
   * @param _data The data payload of the request
   */
  modifier permittedFunctionsForLINK(bytes memory _data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(_data, 32)) // First 32 bytes contain length of data
    }
    if (funcSelector != REGISTER_REQUEST_SELECTOR) {
      revert FunctionNotPermitted();
    }
    _;
  }

  /**
   * @dev Reverts if the actual amount passed does not match the expected amount
   * @param expected amount that should match the actual amount
   * @param data bytes
   */
  modifier isActualAmount(uint256 expected, bytes calldata data) {
    // decode register function arguments to get actual amount
    (, , , , , , , uint96 amount, ) = abi.decode(
      data[4:],
      (string, bytes, address, uint32, address, bytes, bytes, uint96, address)
    );
    if (expected != amount) {
      revert AmountMismatch();
    }
    _;
  }

  /**
   * @dev Reverts if the actual sender address does not match the expected sender address
   * @param expected address that should match the actual sender address
   * @param data bytes
   */
  modifier isActualSender(address expected, bytes calldata data) {
    // decode register function arguments to get actual sender
    (, , , , , , , , address sender) = abi.decode(
      data[4:],
      (string, bytes, address, uint32, address, bytes, bytes, uint96, address)
    );
    if (expected != sender) {
      revert SenderMismatch();
    }
    _;
  }
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

/**
 * @notice OnchainConfig of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
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
struct OnchainConfig {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint32 maxCheckDataSize;
  uint32 maxPerformDataSize;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member totalPremium the total premium collected on registry so far
 * @member numUpkeeps total number of upkeeps on the registry
 * @member configCount ordinal number of current config, out of all configs applied to this contract so far
 * @member latestConfigBlockNumber last block at which this config was set
 * @member latestConfigDigest domain-separation tag for current config
 * @member latestEpoch for which a report was transmitted
 * @member paused freeze on execution scoped to the entire registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint96 totalPremium;
  uint256 numUpkeeps;
  uint32 configCount;
  uint32 latestConfigBlockNumber;
  bytes32 latestConfigDigest;
  uint32 latestEpoch;
  bool paused;
}

/**
 * @notice all information about an upkeep
 * @dev only used in return values
 * @member target the contract which needs to be serviced
 * @member executeGas the gas limit of upkeep execution
 * @member checkData the checkData bytes for this upkeep
 * @member balance the balance of this upkeep
 * @member admin for this upkeep
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 * @member amountSpent the amount this upkeep has spent
 * @member paused if this upkeep has been paused
 * @member skipSigVerification skip signature verification in transmit for a low security low cost model
 */
struct UpkeepInfo {
  address target;
  uint32 executeGas;
  bytes checkData;
  uint96 balance;
  address admin;
  uint64 maxValidBlocknumber;
  uint32 lastPerformBlockNumber;
  uint96 amountSpent;
  bool paused;
  bytes offchainConfig;
}

enum UpkeepFailureReason {
  NONE,
  UPKEEP_CANCELLED,
  UPKEEP_PAUSED,
  TARGET_CHECK_REVERTED,
  UPKEEP_NOT_NEEDED,
  PERFORM_DATA_EXCEEDS_LIMIT,
  INSUFFICIENT_BALANCE
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function updateCheckData(uint256 id, bytes calldata newCheckData) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external;

  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo);

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getTransmitterInfo(address query)
    external
    view
    returns (
      bool active,
      uint8 index,
      uint96 balance,
      uint96 lastCollected,
      address payee
    );

  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    view
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ERC677ReceiverInterface {
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

pragma solidity ^0.8.6;

import "../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../automation/2_0/KeeperRegistrar2_0.sol";

contract UpkeepCounterStats {
  using EnumerableSet for EnumerableSet.UintSet;
  event PerformingUpkeep(
    uint256 initialBlock,
    uint256 lastBlock,
    uint256 previousBlock,
    uint256 counter,
    bytes performData
  );

  mapping(uint256 => uint256) public upkeepIdsToIntervals;
  mapping(uint256 => uint256) public upkeepIdsToPreviousPerformBlock;
  mapping(uint256 => uint256) public upkeepIdsToInitialBlock;
  mapping(uint256 => uint256) public upkeepIdsToCounter;
  mapping(uint256 => uint256) public upkeepIdsToPerformGasToBurn;
  mapping(uint256 => uint256) public upkeepIdsToCheckGasToBurn;
  mapping(uint256 => uint256) public upkeepIdsToPerformDataSize;
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup
  mapping(uint256 => uint256[]) private upkeepIdsToDelay;
  EnumerableSet.UintSet internal s_upkeepIDs;
  KeeperRegistrar2_0 public registrar;
  AutomationRegistryBaseInterface public registry;
  LinkTokenInterface public linkToken;

  constructor(address registrarAddress) {
    registrar = KeeperRegistrar2_0(registrarAddress);
    (,,, address registryAddress,) = registrar.getRegistrationConfig();
    registry = AutomationRegistryBaseInterface(registryAddress);
    linkToken = registrar.LINK();
  }

  function registerUpkeep(KeeperRegistrar2_0.RegistrationParams memory params) external returns (uint256) {
    uint256 upkeepId = registrar.registerUpkeep(params);
    s_upkeepIDs.add(upkeepId);
    return upkeepId;
  }

  function batchRegisterUpkeeps(uint8 number, uint32 gasLimit, uint96 amount) external returns (uint256[] memory) {
    KeeperRegistrar2_0.RegistrationParams memory params = KeeperRegistrar2_0.RegistrationParams({
      name: "test",
      encryptedEmail: '0x',
      upkeepContract: address(this),
      gasLimit: gasLimit,
      adminAddress: address(this), // cannot use msg.sender otherwise updateCheckData won't work
      checkData: '0x', // update check data later bc upkeep id is not available now
      offchainConfig: '0x',
      amount: amount
    });

    uint256[] memory upkeepIds = new uint256[](number);
    for (uint8 i = 0; i < number; i++) {
      uint256 upkeepId = this.registerUpkeep(params);
      upkeepIds[i] = upkeepId;
    }
    return upkeepIds;
  }

  function addFunds(uint256 upkeepId, uint96 amount) external {
    linkToken.approve(address(registry), amount);
    registry.addFunds(upkeepId, amount);
  }

  function updateCheckData(uint256 upkeepId, bytes calldata checkData) external {
    registry.updateCheckData(upkeepId, checkData);
  }

  function cancelUpkeep(uint256 upkeepId) external {
    registry.cancelUpkeep(upkeepId);
    s_upkeepIDs.remove(upkeepId);
    // keep data in mappings in case needed afterwards?
  }

  function checkUpkeep(bytes calldata checkData) external returns (bool, bytes memory) {
    uint256 startGas = gasleft();

    (uint256 upkeepId) = abi.decode(
      checkData,
      (uint256)
    );

    uint256 performDataSize = upkeepIdsToPerformDataSize[upkeepId];
    uint256 checkGasToBurn = upkeepIdsToCheckGasToBurn[upkeepId];
    bytes memory pData = abi.encode(upkeepId, new bytes(performDataSize));
    uint256 blockNum = block.number;
    bool needed = eligible(upkeepId);
    while (startGas - gasleft() + 10000 < checkGasToBurn) {
      // 10K margin over gas to burn
      // Hard coded check gas to burn
      dummyMap[blockhash(blockNum)] = false; // arbitrary storage writes
      blockNum--;
    }
    return (needed, pData);
  }

  function performUpkeep(bytes calldata performData) external {
    uint256 startGas = gasleft();
    (uint256 upkeepId, bytes memory performDataPlaceHolder) = abi.decode(
      performData,
      (uint256, bytes)
    );
    uint256 performGasToBurn = upkeepIdsToPerformGasToBurn[upkeepId];
    uint256 initialBlock = upkeepIdsToInitialBlock[upkeepId];
    uint256 blockNum = block.number;
    uint256 interval = upkeepIdsToIntervals[upkeepId];
    if (initialBlock == 0) {
      upkeepIdsToInitialBlock[upkeepId] = blockNum;
      initialBlock = blockNum;
    } else {
      // Calculate and append delay
      uint256 delay = blockNum - upkeepIdsToPreviousPerformBlock[upkeepId] - interval;
      upkeepIdsToDelay[upkeepId].push(delay);
    }

    uint256 counter = upkeepIdsToCounter[upkeepId] + 1;
    upkeepIdsToCounter[upkeepId] = counter;
    emit PerformingUpkeep(initialBlock, blockNum, upkeepIdsToPreviousPerformBlock[upkeepId], counter, performData);
    upkeepIdsToPreviousPerformBlock[upkeepId] = blockNum;

    while (startGas - gasleft() + 10000 < performGasToBurn) {
      // 10K margin over gas to burn
      dummyMap[blockhash(blockNum)] = false; // arbitrary storage writes
      blockNum--;
    }
  }

  function eligible(uint256 upkeepId) public view returns (bool) {
    if (upkeepIdsToInitialBlock[upkeepId] == 0) {
      return true;
    }
    return (block.number - upkeepIdsToPreviousPerformBlock[upkeepId]) >= upkeepIdsToIntervals[upkeepId];
  }

  function setPerformGasToBurn(uint256 upkeepId, uint256 value) public {
    upkeepIdsToPerformGasToBurn[upkeepId] = value;
  }

  function setCheckGasToBurn(uint256 upkeepId, uint256 value) public {
    upkeepIdsToCheckGasToBurn[upkeepId] = value;
  }

  function setPerformDataSize(uint256 upkeepId, uint256 value) public {
    upkeepIdsToPerformDataSize[upkeepId] = value;
  }

  function setSpread(uint256 upkeepId, uint256 _interval) external {
    upkeepIdsToIntervals[upkeepId] = _interval;
    upkeepIdsToInitialBlock[upkeepId] = 0;
    upkeepIdsToCounter[upkeepId] = 0;

    delete upkeepIdsToDelay[upkeepId];
  }

  function getDelaysLength(uint256 upkeepId) public view returns (uint256) {
    return upkeepIdsToDelay[upkeepId].length;
  }

  function getDelays(uint256 upkeepId) public view returns (uint256[] memory) {
    return upkeepIdsToDelay[upkeepId];
  }

  function getSumDelayLastNPerforms(uint256 upkeepId, uint256 n) public view returns (uint256, uint256) {
    uint256[] memory delays = upkeepIdsToDelay[upkeepId];
    uint256 i;
    uint256 len = delays.length;
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256 sum = 0;

    for (i = 0; i < n; i++) sum = sum + delays[len - i - 1];
    return (sum, n);
  }

  function getPxDelayForAllUpkeeps(uint256 p) public view returns (uint256[] memory upkeepIds, uint256[] memory pxDelays) {
    uint256 len = s_upkeepIDs.length();
    uint256[] memory upkeepIds = new uint256[](len);
    uint256[] memory pxDelays = new uint256[](len);

    for (uint256 idx = 0; idx < len; idx++) {
      uint256 upkeepId = s_upkeepIDs.at(idx);
      uint256[] memory delays = upkeepIdsToDelay[upkeepId];
      upkeepIds[idx] = upkeepId;
      pxDelays[idx] = this.getPxDelayLastNPerforms(upkeepId, p, delays.length);
    }

    //return (upkeepIds, pxDelays);
  }

  function getPxDelayLastNPerforms(uint256 upkeepId, uint256 p, uint256 n) public view returns (uint256) {
    uint256[] memory delays = upkeepIdsToDelay[upkeepId];
    uint256 i;
    uint256 len = delays.length;
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256[] memory subArr = new uint256[](n);

    for (i = 0; i < n; i++) subArr[i] = (delays[len - i - 1]);
    quickSort(subArr, int256(0), int256(subArr.length - 1));

    uint256 index = (p * subArr.length) / 100;
    return subArr[index];
  }

  function quickSort(
    uint256[] memory arr,
    int256 left,
    int256 right
  ) private pure {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256 pivot = arr[uint256(left + (right - left) / 2)];
    while (i <= j) {
      while (arr[uint256(i)] < pivot) i++;
      while (pivot < arr[uint256(j)]) j--;
      if (i <= j) {
        (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
        i++;
        j--;
      }
    }
    if (left < j) quickSort(arr, left, j);
    if (i < right) quickSort(arr, i, right);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}