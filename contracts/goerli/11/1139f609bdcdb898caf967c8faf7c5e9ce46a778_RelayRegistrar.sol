// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import './interfaces/LinkTokenInterface.sol';
import './interfaces/RelayRegistryInterface.sol';
import './interfaces/TypeAndVersionInterface.sol';
import './ConfirmedOwner.sol';
import './interfaces/ERC677ReceiverInterface.sol';

/**
 * @notice Contract to accept requests for relay registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register relay and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerrelay` function directly on
 * relay registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI for anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract RelayRegistrar is TypeAndVersionInterface, ConfirmedOwner, ERC677ReceiverInterface {
    /**
     * DISABLED: No auto approvals, all new relays should be approved manually.
     * ENABLED_SENDER_ALLOWLIST: Auto approvals for allowed senders subject to max allowed. Manual for rest.
     * ENABLED_ALL: Auto approvals for all new relays subject to max allowed.
     */
    enum AutoApproveType {
        DISABLED,
        ENABLED_SENDER_ALLOWLIST,
        ENABLED_ALL
    }

    address RELAY_REGISTRY;
    bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

    mapping(bytes32 => PendingRequest) private s_pendingRequests;

    LinkTokenInterface public constant LINK =
        LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);

    /**
     * @notice versions:
     * - RelayRegistrar 1.0.0: initial release
     */
    string public constant override typeAndVersion = 'RelayRegistrar 1.0.0';

    struct Config {
        AutoApproveType autoApproveConfigType;
        uint32 autoApproveMaxAllowed;
        uint32 approvedCount;
        RelayRegistryInterfaceBase relayRegistry;
        uint96 minLINKJuels;
    }

    struct PendingRequest {
        address admin;
        uint96 balance;
    }

    Config private s_config;
    // Only applicable if s_config.configType is ENABLED_SENDER_ALLOWLIST
    mapping(address => bool) private s_autoApproveAllowedSenders;

    event RegistrationRequested(
        bytes32 indexed hash,
        string name,
        bytes encryptedEmail,
        address indexed relayContract,
        uint32 gasLimit,
        address adminAddress,
        bytes checkData,
        uint96 amount,
        uint8 indexed source
    );

    event RegistrationApproved(bytes32 indexed hash, string displayName, uint256 indexed relayId);

    event RegistrationRejected(bytes32 indexed hash);

    event AutoApproveAllowedSenderSet(address indexed senderAddress, bool allowed);

    event ConfigChanged(
        AutoApproveType autoApproveConfigType,
        uint32 autoApproveMaxAllowed,
        address relayRegistry,
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

    constructor() ConfirmedOwner(msg.sender) {}

    /*
     * @param LINKAddress Address of Link token
     * @param autoApproveConfigType setting for auto-approve registrations
     * @param autoApproveMaxAllowed max number of registrations that can be auto approved
     * @param relayRegistry relay registry address
     * @param minLINKJuels minimum LINK that new registrations should fund their relay with
     */
    function initialize(
        AutoApproveType autoApproveConfigType,
        uint16 autoApproveMaxAllowed,
        address relayRegistry,
        uint96 minLINKJuels
    ) external onlyOwner {
        setRegistrationConfig(
            autoApproveConfigType,
            autoApproveMaxAllowed,
            relayRegistry,
            minLINKJuels
        );
    }

    //EXTERNAL

    /**
     * @notice register can only be called through transferAndCall on LINK contract
     * @param name string of the relay to be registered
     * @param encryptedEmail email address of relay contact
     * @param relayContract address of the contract to perform relay on
     * @param gasLimit amount of gas to provide the target contract when performing relay
     * @param adminAddress address to cancel relay and withdraw remaining funds
     * @param checkData data passed to the contract when checking for relay
     * @param amount quantity of LINK the relay is funded with (specified in Juels)
     * @param source application sending this request
     * @param sender address of the sender making the request
     */
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address relayContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external onlyLINK {
        if (adminAddress == address(0)) {
            revert InvalidAdminAddress();
        }
        bytes32 hash = keccak256(abi.encode(relayContract, gasLimit, adminAddress, checkData));

        emit RegistrationRequested(
            hash,
            name,
            encryptedEmail,
            relayContract,
            gasLimit,
            adminAddress,
            checkData,
            amount,
            source
        );

        Config memory config = s_config;
        if (_shouldAutoApprove(config, sender)) {
            s_config.approvedCount = config.approvedCount + 1;

            _approve(name, relayContract, gasLimit, adminAddress, checkData, amount, hash);
        } else {
            uint96 newBalance = s_pendingRequests[hash].balance + amount;
            s_pendingRequests[hash] = PendingRequest({admin: adminAddress, balance: newBalance});
        }
    }

    /**
     * @dev register relay on relayRegistry contract and emit RegistrationApproved event
     */
    function approve(
        string memory name,
        address relayContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        bytes32 hash
    ) external onlyOwner {
        PendingRequest memory request = s_pendingRequests[hash];
        if (request.admin == address(0)) {
            revert RequestNotFound();
        }
        bytes32 expectedHash = keccak256(
            abi.encode(relayContract, gasLimit, adminAddress, checkData)
        );
        if (hash != expectedHash) {
            revert HashMismatch();
        }
        delete s_pendingRequests[hash];
        _approve(name, relayContract, gasLimit, adminAddress, checkData, request.balance, hash);
    }

    /**
     * @notice cancel will remove a registration request and return the refunds to the msg.sender
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
        bool success = LINK.transfer(msg.sender, request.balance); //CHECKTHIS transfer??
        if (!success) {
            revert LinkTransferFailed(msg.sender);
        }
        emit RegistrationRejected(hash);
    }

    /**
     * @notice owner calls this function to set if or not registration requests should be sent directly to the Relay Registry
     * @param autoApproveConfigType setting for auto-approve registrations
     *                   note: autoApproveAllowedSenders list persists across config changes irrespective of type
     * @param autoApproveMaxAllowed max number of registrations that can be auto approved
     * @param relayRegistry new relay registry address
     * @param minLINKJuels minimum LINK that new registrations should fund their relay with
     */
    function setRegistrationConfig(
        AutoApproveType autoApproveConfigType,
        uint16 autoApproveMaxAllowed,
        address relayRegistry,
        uint96 minLINKJuels
    ) public onlyOwner {
        uint32 approvedCount = s_config.approvedCount;
        s_config = Config({
            autoApproveConfigType: autoApproveConfigType,
            autoApproveMaxAllowed: autoApproveMaxAllowed,
            approvedCount: approvedCount,
            minLINKJuels: minLINKJuels,
            relayRegistry: RelayRegistryInterfaceBase(relayRegistry)
        });

        emit ConfigChanged(
            autoApproveConfigType,
            autoApproveMaxAllowed,
            relayRegistry,
            minLINKJuels
        );
    }

    /**
     * @notice owner calls this function to set allowlist status for senderAddress
     * @param senderAddress senderAddress to set the allowlist status for
     * @param allowed true if senderAddress needs to be added to allowlist, false if needs to be removed
     */
    //CHECKTHIS - WILL I NEED
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
            address relayRegistry,
            uint256 minLINKJuels
        )
    {
        Config memory config = s_config;
        return (
            config.autoApproveConfigType,
            config.autoApproveMaxAllowed,
            config.approvedCount,
            address(config.relayRegistry),
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
     * @dev register relay on relayRegistry contract and emit RegistrationApproved event
     */
    function _approve(
        string memory name,
        address relayContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        bytes32 hash
    ) private {
        RelayRegistryInterfaceBase relayRegistry = s_config.relayRegistry;

        // register relay
        uint256 relayId = relayRegistry.registerRelay(
            relayContract,
            gasLimit,
            adminAddress,
            checkData
        );
        // fund relay
        bool success = LINK.transferAndCall(address(relayRegistry), amount, abi.encode(relayId)); //CHECKTHIS
        if (!success) {
            revert LinkTransferFailed(address(relayRegistry));
        }

        emit RegistrationApproved(hash, name, relayId);
    }

    /**
     * @dev verify sender allowlist if needed and check max limit
     */
    function _shouldAutoApprove(Config memory config, address sender) private view returns (bool) {
        if (config.autoApproveConfigType == AutoApproveType.DISABLED) {
            return false;
        }
        if (
            config.autoApproveConfigType == AutoApproveType.ENABLED_SENDER_ALLOWLIST &&
            (!s_autoApproveAllowedSenders[sender])
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
    modifier isActualAmount(uint256 expected, bytes memory data) {
        uint256 actual;
        assembly {
            actual := mload(add(data, 228))
        }
        if (expected != actual) {
            revert AmountMismatch();
        }
        _;
    }

    /**
     * @dev Reverts if the actual sender address does not match the expected sender address
     * @param expected address that should match the actual sender address
     * @param data bytes
     */
    modifier isActualSender(address expected, bytes memory data) {
        address actual;
        assembly {
            actual := mload(add(data, 292))
        }
        if (expected != actual) {
            revert SenderMismatch();
        }
        _;
    }
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

import '../../utils/RelayTypes.sol';

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform relay before it will be the next relayer's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an relay must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member registrar address of the registrar contract
 */
struct Config {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
    uint24 blockCountPerTurn;
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minRelaySpend;
    uint32 maxPerformGas;
    uint256 fallbackGasPrice;
    uint256 fallbackLinkPrice;
    address registrar;
}

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @ownerLinkBalance withdrawable balance of LINK by contract owner
 * @numRelays total number of relays on the registry
 */
struct State {
    uint32 nonce;
    uint96 ownerLinkBalance;
    uint256 expectedLinkBalance;
    uint256 numRelays;
}

interface RelayRegistryInterfaceBase {
    function registerRelay(
        address target,
        uint32 gasLimit,
        address client,
        bytes calldata checkData
    ) external returns (uint256 id);

    function performRelay(
        uint256 id,
        RelayTypes.RelayRequest calldata relayRequest,
        bytes calldata performData
    ) external returns (bool success);

    function cancelRelay(uint256 id) external;

    function addFunds(uint256 id, uint96 amount) external;

    function setRelayGasLimit(uint256 id, uint32 gasLimit) external;

    function getRelay(uint256 id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastRelayer,
            address client,
            uint64 maxValidBlocknumber,
            uint96 amountSpent
        );

    function getActiveRelayIDs(uint256 startIndex, uint256 maxCount)
        external
        view
        returns (uint256[] memory);

    function getRelayerInfo(address query)
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
interface RelayRegistryInterface is RelayRegistryInterfaceBase {
    function checkRelay(
        uint256 relayId,
        address from,
        RelayTypes.RelayRequest calldata relayRequest
    )
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

interface RelayRegistryExecutableInterface is RelayRegistryInterfaceBase {
    function checkRelay(
        uint256 relayId,
        address from,
        RelayTypes.RelayRequest calldata relayRequest
    )
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

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
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

library RelayTypes {
    struct RelayRequest {
        address from;
        address to;
        uint256 value; //mgs.value ether sent with contract call (0)
        uint256 gas; //200 gwei
        uint256 nonce; //(0)
        bytes data; //NOTE: abi encoded selector and params (specific func called)
        //need to look 1. signature (bytes) 2. message digest (bytes32??)
    }
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