// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {UpkeepInfo, State, OnchainConfig, UpkeepFailureReason} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {EnumerableSet} from "@openzeppelin/contractsV4/access/AccessControlEnumerable.sol";
import {AutomationCompatibleWithViewInterface} from "./interfaces/AutomationCompatibleWithViewInterface.sol";
import {AutomationRegistryWithMinANeededAmountInterface} from "./interfaces/AutomationRegistryWithMinANeededAmountInterface.sol";
import {KeeperRegistrarInterface} from "./interfaces/KeeperRegistrarInterface.sol";
import {UpkeepControllerInterface} from "./interfaces/UpkeepControllerInterface.sol";

/**
 * @title UpkeepController contract
 * @notice A contract that manages upkeeps for the Chainlink automation system.
 * @dev This contract implements the UpkeepControllerInterface and provides functionality to register, cancel,
 * pause, and unpause upkeeps, as well as update their check data, gas limits, and off-chain configurations.
 */
contract UpkeepController is UpkeepControllerInterface {
    using EnumerableSet for EnumerableSet.UintSet;

    LinkTokenInterface public immutable i_link;
    KeeperRegistrarInterface public immutable i_registrar;
    AutomationRegistryWithMinANeededAmountInterface public immutable i_registry;

    EnumerableSet.UintSet private activeUpkeeps;
    EnumerableSet.UintSet private pausedUpkeeps;

    /**
     * @notice Constructs the UpkeepController contract.
     * @param link The address of the LinkToken contract.
     * @param registrar The address of the KeeperRegistrar contract.
     * @param registry The address of the AutomationRegistry contract.
     */
    constructor(
        LinkTokenInterface link,
        KeeperRegistrarInterface registrar,
        AutomationRegistryWithMinANeededAmountInterface registry
    ) {
        i_link = link;
        i_registrar = registrar;
        i_registry = registry;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function registerAndPredictID(KeeperRegistrarInterface.RegistrationParams memory params) public {
        i_link.transferFrom(msg.sender, address(this), params.amount);
        i_link.approve(address(i_registrar), params.amount);
        uint256 upkeepId = i_registrar.registerUpkeep(params);
        if (upkeepId != 0) {
            activeUpkeeps.add(upkeepId);
            emit UpkeepCreated(upkeepId);
        } else {
            revert("auto-approve disabled");
        }
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function cancelUpkeep(uint256 upkeepId) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.cancelUpkeep(upkeepId);
        activeUpkeeps.remove(upkeepId);
        emit UpkeepCanceled(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function pauseUpkeep(uint256 upkeepId) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.pauseUpkeep(upkeepId);
        pausedUpkeeps.add(upkeepId);
        activeUpkeeps.remove(upkeepId);
        emit UpkeepPaused(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function unpauseUpkeep(uint256 upkeepId) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.unpauseUpkeep(upkeepId);
        pausedUpkeeps.remove(upkeepId);
        activeUpkeeps.add(upkeepId);
        emit UpkeepUnpaused(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function updateCheckData(uint256 upkeepId, bytes memory newCheckData) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.updateCheckData(upkeepId, newCheckData);
        emit UpkeepUpdated(upkeepId, newCheckData);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function setUpkeepGasLimit(uint256 upkeepId, uint32 gasLimit) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.setUpkeepGasLimit(upkeepId, gasLimit);
        emit UpkeepGasLimitSet(upkeepId, gasLimit);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function setUpkeepOffchainConfig(uint256 upkeepId, bytes calldata config) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_registry.setUpkeepOffchainConfig(upkeepId, config);
        emit UpkeepOffchainConfigSet(upkeepId, config);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function addFunds(uint256 upkeepId, uint96 amount) external {
        require(activeUpkeeps.contains(upkeepId), "Wrong upkeep id");
        i_link.transferFrom(msg.sender, address(this), amount);
        i_link.approve(address(i_registry), amount);
        i_registry.addFunds(upkeepId, amount);
        emit FundsAdded(upkeepId, amount);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getUpkeep(uint256 upkeepId) external view returns (UpkeepInfo memory upkeepInfo) {
        return i_registry.getUpkeep(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getActiveUpkeepIDs(uint256 offset, uint256 limit) public view returns (uint256[] memory upkeeps) {
        uint256 ordersCount = activeUpkeeps.length();
        if (offset >= ordersCount) return new uint256[](0);
        uint256 to = offset + limit;
        if (ordersCount < to) to = ordersCount;
        upkeeps = new uint256[](to - offset);
        for (uint256 i = 0; i < upkeeps.length; i++) upkeeps[i] = activeUpkeeps.at(offset + i);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getUpkeeps(uint256 offset, uint256 limit) public view returns (UpkeepInfo[] memory) {
        uint256[] memory activeIds = getActiveUpkeepIDs(offset, limit); // FIX IT
        UpkeepInfo[] memory upkeepsInfo = new UpkeepInfo[](activeIds.length);
        for (uint256 i = 0; i < upkeepsInfo.length; i++) {
            upkeepsInfo[i] = i_registry.getUpkeep(activeIds[i]);
        }
        return upkeepsInfo;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getMinBalanceForUpkeep(uint256 upkeepId) external view returns (uint96) {
        return i_registry.getMinBalanceForUpkeep(upkeepId);
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getMinBalancesForUpkeeps(uint256 offset, uint256 limit) public view returns (uint96[] memory) {
        uint256[] memory activeIds = getActiveUpkeepIDs(offset, limit);
        uint256 count = activeIds.length;
        if (offset >= count) return new uint96[](0);
        uint256 to = offset + limit;
        if (count < to) to = count;
        uint96[] memory upkeepsMinAmounts = new uint96[](to - offset);
        for (uint256 i = 0; i < upkeepsMinAmounts.length; i++) {
            upkeepsMinAmounts[i] = i_registry.getMinBalanceForUpkeep(activeIds[i]);
        }
        return upkeepsMinAmounts;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getDetailedUpkeeps(uint256 offset, uint256 limit) external view returns (DetailedUpkeep[] memory) {
        uint256[] memory activeIds = getActiveUpkeepIDs(offset, limit);
        uint256 count = activeIds.length;
        if (offset >= count) return new DetailedUpkeep[](0);
        uint256 to = offset + limit;
        if (count < to) to = count;
        DetailedUpkeep[] memory detailedUpkeeps = new DetailedUpkeep[](to - offset);
        UpkeepInfo[] memory info = getUpkeeps(offset, limit);
        uint96[] memory minAmounts = getMinBalancesForUpkeeps(offset, limit);
        for (uint256 i = 0; i < detailedUpkeeps.length; i++) {
            detailedUpkeeps[i] = DetailedUpkeep(activeIds[i], minAmounts[i], info[i]);
        }
        return detailedUpkeeps;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getUpkeepsCount() external view returns (uint256) {
        return activeUpkeeps.length();
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function getState()
        external
        view
        returns (
            State memory state,
            OnchainConfig memory config,
            address[] memory signers,
            address[] memory transmitters,
            uint8 f
        )
    {
        return i_registry.getState();
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function isNewUpkeepNeeded() external view returns (bool isNeeded, uint256 newOffset, uint256 newLimit) {
        uint256 lastActive = activeUpkeeps.length() - 1;
        uint256 lastUpkeepId = activeUpkeeps.at(lastActive);
        UpkeepInfo memory info = i_registry.getUpkeep(lastUpkeepId);
        (uint128 performOffset, uint128 performLimit) = abi.decode(info.checkData, (uint128, uint128));
        (, bytes memory checkResult) = AutomationCompatibleWithViewInterface(info.target).checkUpkeep(info.checkData);
        uint256[] memory performArray = abi.decode(checkResult, (uint256[]));
        isNeeded = performArray.length >= performLimit ? true : false;
        newOffset = performOffset + performLimit;
        newLimit = performLimit;
    }

    /**
     * @dev See {UpkeepControllerInterface}
     */
    function checkUpkeep(
        uint256 upkeepId
    )
        public
        returns (
            bool upkeepNeeded,
            bytes memory performData,
            UpkeepFailureReason upkeepFailureReason,
            uint256 gasUsed,
            uint256 fastGasWei,
            uint256 linkNative
        )
    {
        return i_registry.checkUpkeep(upkeepId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.12;

import {KeeperRegistrarInterface} from "./KeeperRegistrarInterface.sol";

interface AutomationCompatibleWithViewInterface {
    /**
     * @notice Checks the upkeep status and provides the necessary data for performing the upkeep.
     * @param checkData Additional data needed to determine the upkeep status.
     * @return upkeepNeeded Indicates whether the upkeep is needed or not.
     * @return performData The data required to perform the upkeep.
     * @dev This function allows users to check the status of an upkeep and obtain the data necessary to perform the upkeep.
     * The checkData parameter contains any additional data required to determine the upkeep status.
     * The function returns a boolean value (upkeepNeeded) indicating whether the upkeep is needed or not.
     * If upkeepNeeded is true, it means the upkeep should be performed.
     * In addition, the function returns performData, which is the data needed to execute the upkeep.
     * Users can use this data to perform the upkeep.
     */
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.12;

import {AutomationRegistryExecutableInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";

interface AutomationRegistryWithMinANeededAmountInterface is AutomationRegistryExecutableInterface {
    /**
     * @notice Retrieves the minimum balance required for a specific upkeep.
     * @param upkeepId The unique identifier (ID) of the upkeep.
     * @return The minimum balance required for the specified upkeep.
     * @dev This function allows users to retrieve the minimum balance required to perform a specific upkeep.
     * The minimum balance represents the amount of funds that need to be available in the contract in order to execute the upkeep successfully.
     * The upkeep ID is used to identify the specific upkeep for which the minimum balance is being retrieved.
     */
    function getMinBalanceForUpkeep(uint256 upkeepId) external view returns (uint96);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.12;

interface KeeperRegistrarInterface {
    /**
     * @notice Represents the registration parameters required for creating an upkeep.
     * @param name The name associated with the upkeep.
     * @param encryptedEmail The encrypted email associated with the upkeep.
     * @param upkeepContract The address of the upkeep contract.
     * @param gasLimit The gas limit for the upkeep.
     * @param adminAddress The address of the admin associated with the upkeep.
     * @param checkData Additional data used for checking the upkeep.
     * @param offchainConfig Off-chain configuration data associated with the upkeep.
     * @param amount The amount associated with the upkeep.
     * @dev This struct encapsulates the upkeep parameters required for creating an upkeep.
     */
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

    /**
     * @notice Registers an upkeep using the provided registration parameters.
     * @param requestParams The registration parameters for creating the upkeep.
     * @return The unique identifier (ID) assigned to the newly registered upkeep.
     * @dev This function allows users to register an upkeep by providing the necessary registration parameters.
     * The registration parameters include information such as the name, encrypted email, upkeep contract address,
     * gas limit, admin address, additional check data, off-chain configuration, and amount.
     * Upon successful registration, a unique identifier (ID) is assigned to the upkeep, which can be used for future reference.
     * @dev Emits an {UpkeepCreated} event.
     */
    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.12;

import {UpkeepInfo, State, OnchainConfig, UpkeepFailureReason} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";
import {AutomationRegistryExecutableInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";
import {KeeperRegistrarInterface} from "./KeeperRegistrarInterface.sol";

interface UpkeepControllerInterface {
    /**
     * @notice Represents a detailed upkeep containing information about an upkeep,
     * including its ID, minimum amount, and additional upkeep information.
     * @param id The ID of the upkeep.
     * @param minAmount The minimum amount required for the upkeep.
     * @param info The UpkeepInfo struct containing detailed information about the upkeep.
     * @dev This struct is used to encapsulate detailed information about an upkeep,
     * including its  relevant details.
     */
    struct DetailedUpkeep {
        uint256 id;
        uint96 minAmount;
        UpkeepInfo info;
    }

    /**
     * @notice Emitted when a new upkeep is created.
     * @param id The ID of the created upkeep.
     * @dev This event is emitted when a new upkeep.
     */
    event UpkeepCreated(uint256 indexed id);

    /**
     * @notice Emitted when an upkeep is canceled.
     * @param id The ID of the canceled upkeep.
     * @dev This event is emitted when an upkeep is canceled.
     */
    event UpkeepCanceled(uint256 indexed id);

    /**
     * @notice Emitted when an upkeep is paused.
     * @param id The ID of the paused upkeep.
     * @dev This event is emitted when an upkeep is paused.
     */
    event UpkeepPaused(uint256 indexed id);

    /**
     * @notice Emitted when an upkeep is unpaused.
     * @param id The ID of the unpaused upkeep.
     * @dev This event is emitted when an upkeep is unpaused.
     */
    event UpkeepUnpaused(uint256 indexed id);

    /**
     * @notice Emitted when an upkeep is updated.
     * @param id The ID of the updated upkeep.
     * @param newCheckData The new check data for the upkeep.
     * @dev This event is emitted when an upkeep is updated, with the new check data included.
     */

    event UpkeepUpdated(uint256 indexed id, bytes newCheckData);
    /**
     * @notice Emitted when funds are added to an upkeep.
     * @param id The ID of the upkeep to which funds are added.
     * @param amount The amount of funds added to the upkeep.
     * @dev This event is emitted when funds are added to an upkeep.
     */

    event FundsAdded(uint256 indexed id, uint96 amount);
    /**
     * @notice Emitted when the gas limit is set for an upkeep.
     * @param id The ID of the upkeep for which the gas limit is set.
     * @param amount The gas limit value set for the upkeep.
     * @dev This event is emitted when the gas limit is set for an upkeep.
     */

    event UpkeepGasLimitSet(uint256 indexed id, uint32 amount);

    /**
     * @notice Emitted when the off-chain configuration is set for an upkeep.
     * @param id The ID of the upkeep for which the off-chain configuration is set.
     * @param config The off-chain configuration data set for the upkeep.
     * @dev This event is emitted when the off-chain configuration is set for an upkeep.
     */
    event UpkeepOffchainConfigSet(uint256 indexed id, bytes config);

    /**
     * @notice Registers a new upkeep and predicts its ID.
     * @param params The registration parameters for the upkeep.
     * @dev The caller must approve the transfer of LINK tokens to this contract before calling this function.
     * @dev This function transfers the specified amount of LINK tokens from the caller to this contract.
     * @dev It then approves the transfer of LINK tokens to the KeeperRegistrar contract.
     * @dev Next, it calls the registerUpkeep function of the KeeperRegistrar contract to register the upkeep.
     * @dev If the upkeep is successfully registered, the upkeep ID is added to the activeUpkeeps set and an UpkeepCreated event is emitted.
     * @dev If the upkeep registration fails, the function reverts with an error message.
     * @dev Emits a {UpkeepCreated} event.
     */
    function registerAndPredictID(KeeperRegistrarInterface.RegistrationParams memory params) external;

    /**
     * @notice Cancel an active upkeep.
     * @param upkeepId The ID of the upkeep to cancel.
     * @dev The upkeep must be active.
     * @dev This function calls the cancelUpkeep function of the AutomationRegistry contract to cancel the upkeep.
     * @dev It removes the upkeep ID from the activeUpkeeps set.
     * @dev Emits a {UpkeepCanceled} event.
     */
    function cancelUpkeep(uint256 upkeepId) external;

    /**
     * @notice Pauses an active upkeep.
     * @param upkeepId The ID of the upkeep to pause.
     * @dev The upkeep must be active.
     * @dev This function calls the pauseUpkeep function of the AutomationRegistry contract to pause the upkeep.
     * @dev It removes the upkeep ID from the activeUpkeeps set, adds it to the pausedUpkeeps set.
     * @dev Emits a {UpkeepPaused} event.
     */
    function pauseUpkeep(uint256 upkeepId) external;

    /**
     * @notice Unpauses a paused upkeep.
     * @param upkeepId The ID of the upkeep to unpause.
     * @dev The upkeep must be paused.
     * @dev This function calls the unpauseUpkeep function of the AutomationRegistry contract to unpause the upkeep.
     * @dev It removes the upkeep ID from the pausedUpkeeps set, adds it to the activeUpkeeps set.
     * @dev Emits a {UpkeepUnpaused} event.
     */
    function unpauseUpkeep(uint256 upkeepId) external;

    /**
     * @notice Updates the check data of an upkeep.
     * @param upkeepId The ID of the upkeep to update.
     * @param newCheckData The new check data to set for the upkeep.
     * @dev The upkeep must be an active upkeep.
     * @dev This function calls the updateCheckData function of the AutomationRegistryWithMinANeededAmount contract to update the check data of the upkeep.
     * @dev Emits a {UpkeepUpdated} event.
     */
    function updateCheckData(uint256 upkeepId, bytes memory newCheckData) external;

    /**
     * @notice Update the gas limit for an specific upkeep.
     * @param upkeepId The ID of the upkeep to set the gas limit for.
     * @param gasLimit The gas limit to set for the upkeep.
     * @dev The upkeep must be active.
     * @dev This function calls the setUpkeepGasLimit function of the AutomationRegistry
     * contract to set the gas limit for the upkeep.
     * @dev Emits a {UpkeepGasLimitSet} event.
     */
    function setUpkeepGasLimit(uint256 upkeepId, uint32 gasLimit) external;

    /**
     * @notice Update the off-chain configuration for an upkeep.
     * @param upkeepId The ID of the upkeep to set the off-chain configuration for.
     * @param config The off-chain configuration data to set for the upkeep.
     * @dev The upkeep must be active.
     * @dev This function calls the setUpkeepOffchainConfig function of the AutomationRegistry contract
     * to set the off-chain configuration for the upkeep.
     * @dev Emits a {UpkeepOffchainConfigSet} event.
     */
    function setUpkeepOffchainConfig(uint256 upkeepId, bytes calldata config) external;

    /**
     * @notice Adds funds to an upkeep.
     * @param upkeepId The ID of the upkeep to add funds to.
     * @param amount The amount of funds to add to the upkeep.
     * @dev The upkeep must be active.
     * @dev This function transfers the specified amount of LINK tokens from the caller to the contract.
     * @dev It approves the transferred LINK tokens for the AutomationRegistry contract
     * and calls the addFunds function of the AutomationRegistry contract to add funds to the upkeep.
     * @dev Emits a {FundsAdded} event.
     */
    function addFunds(uint256 upkeepId, uint96 amount) external;

    /**
     * @notice Retrieves the information of an upkeep.
     * @param upkeepId The ID of the upkeep to retrieve information for.
     * @return upkeepInfo The UpkeepInfo struct containing the information of the upkeep.
     * @dev This function calls the getUpkeep function of the AutomationRegistry contract to retrieve the information of the upkeep.
     */
    function getUpkeep(uint256 upkeepId) external view returns (UpkeepInfo memory upkeepInfo);

    /**
     * @notice Retrieves the IDs of active upkeeps within a specified range.
     * @param offset The starting index of the range.
     * @param limit The maximum number of IDs to retrieve.
     * @return upkeeps An array of active upkeep IDs within the specified range.
     * @dev This function returns an array of active upkeep IDs, starting from the offset and up to the specified limit.
     * @dev If the offset exceeds the total number of active upkeeps, an empty array is returned.
     * @dev This function uses the activeUpkeeps set to retrieve the IDs.
     */
    function getActiveUpkeepIDs(uint256 offset, uint256 limit) external view returns (uint256[] memory upkeeps);

    /**
     * @notice Retrieves a batch of upkeeps with their information.
     * @param offset The starting index of the range.
     * @param limit The maximum number of upkeeps to retrieve.
     * @return upkeeps An array of UpkeepInfo structs containing the information of the retrieved upkeeps.
     * @dev This function retrieves a batch of upkeeps by calling the getActiveUpkeepIDs function
     * to get the IDs of active upkeeps within the specified range.
     * @dev It then iterates over the retrieved IDs and calls the getUpkeep function of the AutomationRegistry contract
     * to retrieve the information of each upkeep.
     */
    function getUpkeeps(uint256 offset, uint256 limit) external view returns (UpkeepInfo[] memory);

    /**
     * @notice Retrieves the minimum balance required for an upkeep.
     * @param upkeepId The ID of the upkeep to retrieve the minimum balance for.
     * @return minBalance The minimum balance required for the upkeep.
     * @dev This function calls the getMinBalanceForUpkeep function of the AutomationRegistry contract
     * to retrieve the minimum balance required for the upkeep.
     */
    function getMinBalanceForUpkeep(uint256 upkeepId) external view returns (uint96);

    /**
     * @notice Retrieves the minimum balances required for a batch of upkeeps.
     * @param offset The starting index of the range.
     * @param limit The maximum number of upkeeps to retrieve minimum balances for.
     * @return minBalances An array of minimum balances required for the retrieved upkeeps.
     * @dev This function retrieves a batch of upkeeps by calling the getActiveUpkeepIDs function
     * to get the IDs of active upkeeps within the specified range.
     * @dev It then iterates over the retrieved IDs and calls the getMinBalanceForUpkeep function of the AutomationRegistry contract
     * to retrieve the minimum balance for each upkeep.
     */

    function getMinBalancesForUpkeeps(uint256 offset, uint256 limit) external view returns (uint96[] memory);

    /**
     * @notice Retrieves a batch of detailed upkeeps.
     * @param offset The starting index of the range.
     * @param limit The maximum number of detailed upkeeps to retrieve.
     * @return detailedUpkeeps An array of DetailedUpkeep structs containing the information of the retrieved detailed upkeeps.
     * @dev This function retrieves a batch of upkeeps by calling the getActiveUpkeepIDs function
     * to get the IDs of active upkeeps within the specified range.
     * @dev It then calls the getUpkeeps and getMinBalancesForUpkeeps functions to retrieve the information and minimum balances for the upkeeps.
     * @dev Finally, it combines the information into DetailedUpkeep structs and returns an array of detailed upkeeps.
     */
    function getDetailedUpkeeps(uint256 offset, uint256 limit) external view returns (DetailedUpkeep[] memory);

    /**
     * @notice Retrieves the total number of active upkeeps.
     * @return count The total number of active upkeeps.
     * @dev This function returns the length of the activeUpkeeps set, representing the total number of active upkeeps.
     */
    function getUpkeepsCount() external view returns (uint256);

    /**
     * @notice Retrieves the current state, configuration, signers, transmitters, and flag from the registry.
     * @return state The State struct containing the current state of the registry.
     * @return config The OnchainConfig struct containing the current on-chain configuration of the registry.
     * @return signers An array of addresses representing the signers associated with the registry.
     * @return transmitters An array of addresses representing the transmitters associated with the registry.
     * @return f The flag value associated with the registry.
     * @dev This function calls the getState function of the AutomationRegistry contract
     * to retrieve the current state, configuration, signers, transmitters, and flag.
     */
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

    /**
     * @notice Checks if a new upkeep is needed and returns the offset and limit for the next of upkeep.
     * @return isNeeded A boolean indicating whether a new upkeep is needed.
     * @return newOffset The offset value for the next upkeep.
     * @return newLimit The limit value for the next upkeep.
     * @dev This function calculates the offset and limit for the next upkeep based on the last active upkeep.
     * @dev It retrieves the last active upkeep ID and the associated performOffset and performLimit from the registry.
     * @dev It then calls the checkUpkeep function of the AutomationCompatible contract to perform the upkeep check.
     * @dev The result is used to determine whether a new upkeep is needed,
     * and the new offset and limit values for the next upkeep are calculated.
     */
    function isNewUpkeepNeeded() external view returns (bool isNeeded, uint256 newOffset, uint256 newLimit);

    /**
     * @notice Performs the upkeep check for a specific upkeep.
     * @param upkeepId The ID of the upkeep to check.
     * @return upkeepNeeded A boolean indicating whether the upkeep is needed.
     * @return performData The perform data associated with the upkeep.
     * @return upkeepFailureReason The reason for the upkeep failure, if applicable.
     * @return gasUsed The amount of gas used during the upkeep check.
     * @return fastGasWei The wei value for fast gas during the upkeep check.
     * @return linkNative The amount of LINK or native currency used during the upkeep check.
     * @dev This function calls the checkUpkeep function of the AutomationRegistry contract
     * to perform the upkeep check for the specified upkeep.
     */
    function checkUpkeep(
        uint256 upkeepId
    )
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