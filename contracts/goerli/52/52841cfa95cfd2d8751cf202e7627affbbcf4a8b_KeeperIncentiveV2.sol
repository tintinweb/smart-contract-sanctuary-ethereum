// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IACLRegistry {
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
   * @dev Returns `true` if `account` has been granted `permission`.
   */
  function hasPermission(bytes32 permission, address account) external view returns (bool);

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

  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  function grantPermission(bytes32 permission, address account) external;

  function revokePermission(bytes32 permission) external;

  function requireApprovedContractOrEOA(address account) external view;

  function requireRole(bytes32 role, address account) external view;

  function requirePermission(bytes32 permission, address account) external view;

  function isRoleAdmin(bytes32 role, address account) external view;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.6.12

pragma solidity >=0.6.12;

/**
 * @dev External interface of ContractRegistry.
 */
interface IContractRegistry {
  function getContract(bytes32 _name) external view returns (address);

  function getContractIdFromAddress(address _contractAddress) external view returns (bytes32);

  function addContract(
    bytes32 _name,
    address _address,
    bytes32 _version
  ) external;

  function updateContract(
    bytes32 _name,
    address _newAddress,
    bytes32 _version
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

bytes32 constant INCENTIVE_MANAGER_ROLE = keccak256("INCENTIVE_MANAGER_ROLE");

interface IKeeperIncentiveV2 {
  struct Incentive {
    uint256 reward; //pop reward for calling the function
    bool enabled;
    bool openToEveryone; //can everyone call the function to get the reward or only approved?
    address rewardToken;
    uint256 cooldown; // seconds required between incentive payouts
    uint256 burnPercentage;
    uint256 id;
    uint256 lastInvocation;
  }

  /**
   * @notice keeper account balances are addressesable by the keeper address whereas account balances held by this contract which have not yet been internally transferred to keepers are addressable by this contract's address
   * @param balance balance
   * @param token rewardsToken address
   * @param accountId incentive account id
   **/
  struct Account {
    uint256 balance;
    address token;
    bytes32 accountId;
  }

  /* ==========  VIEWS  ========== */

  /**
   * @return true or false if keeper has claimable reward token balance
   * @param keeper address of keeper
   */
  function hasClaimableBalance(address keeper) external view returns (bool);

  /**
   * @return all accounts associated with keeper
   * @param owner keeper account owner
   */
  function getAccounts(address owner) external view returns (Account[] memory);

  /**
   * @return all controller contract addresses
   */
  function getControllerContracts() external view returns (address[] memory);

  /**
   * @notice Helper function to get incentiveAccountId
   * @param _contractAddress address of controller contract
   * @param _i incentive index
   * @param _rewardsToken token that rewards are paid out with
   */
  function incentiveAccountId(
    address _contractAddress,
    uint256 _i,
    address _rewardsToken
  ) external pure returns (bytes32);

  /* ==========  MUTATIVE FUNCTIONS  ========== */

  /**
   * @notice External function call thats checks requirements for keeper-incentived functions and updates rewards earned
   * @param _i incentive index
   * @param _keeper address of keeper receiving reward
   */
  function handleKeeperIncentive(uint8 _i, address _keeper) external;

  /**
   * @dev Deprecated, use handleKeeperIncentive(uint8 _i, address _keeper) instead
   */
  function handleKeeperIncentive(
    bytes32,
    uint8 _i,
    address _keeper
  ) external;

  /**
   * @notice Keeper calls to claim rewards earned
   * @param incentiveAccountIds accountIds associated with keeper caller
   */
  function claim(bytes32[] calldata incentiveAccountIds) external;

  /**
   * @notice External function to send the tokens in burnBalance to burnAddress
   * @param tokenAddress address of reward token to burn
   */
  function burn(address tokenAddress) external;

  /* ========== ADMIN FUNCTIONS ========== */

  /**
   * @notice Create Incentives for keeper to call a function. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _address address of contract which owns the incentives
   * @param _reward The amount in reward token the Keeper receives for calling the function
   * @param _enabled Is this Incentive currently enabled?
   * @param _openToEveryone incentive is open to anyone
   * @param _rewardToken token to receive as incentive reward
   * @param _cooldown length of time required to wait until next allowable invocation using handleKeeperIncentives()
   * @param _burnPercentage Percentage in Mantissa. (1e14 = 1 Basis Point) - if rewardToken is POP token and _burnPercentage is 0, will default to contract defined defaultBurnPercentage
   * @dev This function is only for creating unique incentives for future contracts
   * @dev Multiple functions can use the same incentive which can then be updated with one governance vote
   */
  function createIncentive(
    address _address,
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone,
    address _rewardToken,
    uint256 _cooldown,
    uint256 _burnPercentage
  ) external returns (uint256);

  /**
   * @notice Update the incentive struct values for keeper to call a function. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _contractAddress address of contract which owns the incentives
   * @param _i incentive index
   * @param _reward The amount in reward token the Keeper receives for calling the function
   * @param _enabled Is this Incentive currently enabled?
   * @param _openToEveryone incentive is open to anyone
   * @param _rewardToken token to receive as incentive reward
   * @param _cooldown length of time required to wait until next allowable invocation using handleKeeperIncentives()
   * @param _burnPercentage Percentage in Mantissa. (1e14 = 1 Basis Point) - if rewardToken is POP token and _burnPercentage is 0, will default to contract defined defaultBurnPercentage
   * @dev Multiple functions can use the same incentive which can be updated here with one governance vote
   */
  function updateIncentive(
    address _contractAddress,
    uint8 _i,
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone,
    address _rewardToken,
    uint256 _cooldown,
    uint256 _burnPercentage
  ) external;

  /**
   * @notice Changes whether an incentive is open to anyone. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _contractAddress address of controller contract
   * @param _i incentive index
   */
  function toggleApproval(address _contractAddress, uint8 _i) external;

  /**
   * @notice Changes whether an incentive is currently enabled. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _contractAddress address of controller contract
   * @param _i incentive index
   */
  function toggleIncentive(address _contractAddress, uint8 _i) external;

  /**
   * @notice Funds incentive with reward token
   * @param _contractAddress address of controller contract
   * @param _i incentive index
   * @param _amount amount of reward token to fund incentive with
   */
  function fundIncentive(
    address _contractAddress,
    uint256 _i,
    uint256 _amount
  ) external;

  /**
   * @notice Allows for incentives to be funded with additional tip
   * @param _rewardToken address of token to tip keeper with
   * @param _keeper address of keeper receiving the tip
   * @param _i incentive index
   * @param _amount amount of reward token to tip
   */
  function tip(
    address _rewardToken,
    address _keeper,
    uint256 _i,
    uint256 _amount
  ) external;

  /**
   * @notice Allows for incentives to be funded with additional tip
   * @param _rewardToken address of token to tip keeper with
   * @param _keeper address of keeper receiving the tip
   * @param _i incentive index
   * @param _amount amount of reward token to tip
   * @param _burnPercentage Percentage in Mantissa. (1e14 = 1 Basis Point)
   */
  function tipWithBurn(
    address _rewardToken,
    address _keeper,
    uint256 _i,
    uint256 _amount,
    uint256 _burnPercentage
  ) external;

  /**
   * @notice Sets the current burn rate as a percentage of the incentive reward. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _burnPercentage Percentage in Mantissa. (1e14 = 1 Basis Point)
   */
  function updateBurnPercentage(uint256 _burnPercentage) external;

  /**
   * @notice Sets the required amount of POP a keeper needs to have staked to handle incentivized functions. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _amount Amount of POP a keeper needs to stake
   */
  function updateRequiredKeeperStake(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaking {
  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardsDurationUpdated(uint256 newDuration);
  event EscrowDurationUpdated(uint256 _previousDuration, uint256 _newDuration);
  event RewardDistributorUpdated(address indexed distributor, bool approved);
  event VaultUpdated(address oldVault, address newVault);

  // Views
  function balanceOf(address account) external view returns (uint256);

  function lastTimeRewardApplicable() external view returns (uint256);

  function rewardPerToken() external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function getRewardForDuration() external view returns (uint256);

  function stakingToken() external view returns (IERC20);

  function rewardsToken() external view returns (IERC20);

  function vault() external view returns (address);

  function escrowDuration() external view returns (uint256);

  function rewardsDuration() external view returns (uint256);

  function paused() external view returns (bool);

  // Mutative
  function stake(uint256 amount) external;

  function stakeFor(uint256 amount, address account) external;

  function withdraw(uint256 amount) external;

  function withdrawFor(
    uint256 amount,
    address owner,
    address receiver
  ) external;

  function getReward() external;

  function exit() external;

  function notifyRewardAmount(uint256 reward) external;

  function setVault(address vault) external;

  function setEscrowDuration(uint256 duration) external;

  function setRewardsDuration(uint256 duration) external;

  function pauseContract() external;

  function unpauseContract() external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "../interfaces/IACLRegistry.sol";

/**
 *  @notice Provides modifiers and internal functions for interacting with the `ACLRegistry`
 *  @dev Derived contracts using `ACLAuth` must also inherit `ContractRegistryAccess`
 *   and override `_getContract`.
 */
abstract contract ACLAuth {
  /**
   *  @dev Equal to keccak256("Keeper")
   */
  bytes32 internal constant KEEPER_ROLE = 0x4f78afe9dfc9a0cb0441c27b9405070cd2a48b490636a7bdd09f355e33a5d7de;

  /**
   *  @dev Equal to keccak256("DAO")
   */
  bytes32 internal constant DAO_ROLE = 0xd0a4ad96d49edb1c33461cebc6fb2609190f32c904e3c3f5877edb4488dee91e;

  /**
   *  @dev Equal to keccak256("GUARDIAN_ROLE")
   */
  bytes32 internal constant GUARDIAN_ROLE = 0x55435dd261a4b9b3364963f7738a7a662ad9c84396d64be3365284bb7f0a5041;

  /**
   *  @dev Equal to keccak256("ApprovedContract")
   */
  bytes32 internal constant APPROVED_CONTRACT_ROLE = 0xfb639edf4b4a4724b8b9fb42a839b712c82108c1edf1beb051bcebce8e689dc4;

  /**
   *  @dev Equal to keccak256("ACLRegistry")
   */
  bytes32 internal constant ACL_REGISTRY_ID = 0x15fa0125f52e5705da1148bfcf00974823c4381bee4314203ede255f9477b73e;

  /**
   *  @notice Require that `msg.sender` has given role
   *  @param role bytes32 role ID
   */
  modifier onlyRole(bytes32 role) {
    _requireRole(role);
    _;
  }

  /**
   *  @notice Require that `msg.sender` has at least one of the given roles
   *  @param roleA bytes32 role ID
   *  @param roleB bytes32 role ID
   */
  modifier onlyRoles(bytes32 roleA, bytes32 roleB) {
    require(_hasRole(roleA, msg.sender) == true || _hasRole(roleB, msg.sender) == true, "you dont have the right role");
    _;
  }

  /**
   *  @notice Require that `msg.sender` has given permission
   *  @param role bytes32 permission ID
   */
  modifier onlyPermission(bytes32 role) {
    _requirePermission(role);
    _;
  }

  /**
   *  @notice Require that `msg.sender` has the `ApprovedContract` role or is an EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  modifier onlyApprovedContractOrEOA() {
    _requireApprovedContractOrEOA(msg.sender);
    _;
  }

  /**
   *  @notice Check whether a given account has been granted this bytes32 role
   *  @param role bytes32 role ID
   *  @param account address of account to check for role
   *  @return Whether account has been granted specified role.
   */
  function _hasRole(bytes32 role, address account) internal view returns (bool) {
    return _aclRegistry().hasRole(role, account);
  }

  /**
   *  @notice Require that `msg.sender` has given role
   *  @param role bytes32 role ID
   */
  function _requireRole(bytes32 role) internal view {
    _requireRole(role, msg.sender);
  }

  /**
   *  @notice Require that given account has specified role
   *  @param role bytes32 role ID
   *  @param account address of account to check for role
   */
  function _requireRole(bytes32 role, address account) internal view {
    _aclRegistry().requireRole(role, account);
  }

  /**
   *  @notice Check whether a given account has been granted this bytes32 permission
   *  @param permission bytes32 permission ID
   *  @param account address of account to check for permission
   *  @return Whether account has been granted specified permission.
   */
  function _hasPermission(bytes32 permission, address account) internal view returns (bool) {
    return _aclRegistry().hasPermission(permission, account);
  }

  /**
   *  @notice Require that `msg.sender` has specified permission
   *  @param permission bytes32 permission ID
   */
  function _requirePermission(bytes32 permission) internal view {
    _requirePermission(permission, msg.sender);
  }

  /**
   *  @notice Require that given account has specified permission
   *  @param permission bytes32 permission ID
   *  @param account address of account to check for permission
   */
  function _requirePermission(bytes32 permission, address account) internal view {
    _aclRegistry().requirePermission(permission, account);
  }

  /**
   *  @notice Require that `msg.sender` has the `ApprovedContract` role or is an EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  function _requireApprovedContractOrEOA() internal view {
    _requireApprovedContractOrEOA(msg.sender);
  }

  /**
   *  @notice Require that `account` has the `ApprovedContract` role or is an EOA
   *  @param account address of account to check for role/EOA
   *  @dev This EOA check requires that `tx.origin == msg.sender` if caller does not have the `ApprovedContract` role.
   *  This limits compatibility with contract-based wallets for functions protected with this modifier.
   */
  function _requireApprovedContractOrEOA(address account) internal view {
    _aclRegistry().requireApprovedContractOrEOA(account);
  }

  /**
   *  @notice Return an IACLRegistry interface to the registered ACLRegistry contract
   *  @return IACLRegistry interface to ACLRegistry contract
   */
  function _aclRegistry() internal view returns (IACLRegistry) {
    return IACLRegistry(_getContract(ACL_REGISTRY_ID));
  }

  /**
   *  @notice Get a contract address by name from the contract registry
   *  @param _name bytes32 contract name
   *  @return contract address
   *  @dev Users of this abstract contract should also inherit from `ContractRegistryAccess`
   *   and override `_getContract` in their implementation.
   */
  function _getContract(bytes32 _name) internal view virtual returns (address);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "../interfaces/IContractRegistry.sol";

/**
 *  @notice Provides an internal `_getContract` helper function to access the `ContractRegistry`
 */
abstract contract ContractRegistryAccess {
  IContractRegistry internal _contractRegistry;

  constructor(IContractRegistry contractRegistry_) {
    require(address(contractRegistry_) != address(0), "Zero address");
    _contractRegistry = contractRegistry_;
  }

  /**
   *  @notice Get a contract address by bytes32 name
   *  @param _name bytes32 contract name
   *  @dev contract name should be a keccak256 hash of the name string, e.g. `keccak256("ContractName")`
   *  @return contract address
   */
  function _getContract(bytes32 _name) internal view virtual returns (address) {
    return _contractRegistry.getContract(_name);
  }

  /**
   *  @notice Get contract id from contract address.
   *  @param _contractAddress contract address
   *  @return name - keccak256 hash of the name string  e.g. `keccak256("ContractName")`
   */
  function _getContractIdFromAddress(address _contractAddress) internal view virtual returns (bytes32) {
    return _contractRegistry.getContractIdFromAddress(_contractAddress);
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ContractRegistryAccess.sol";
import "./ACLAuth.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IKeeperIncentiveV2.sol";

contract KeeperIncentiveV2 is IKeeperIncentiveV2, ACLAuth, ContractRegistryAccess {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  /**
   * @dev controllerContract => IKeeperIncentiveV2.Incentive config
   */
  mapping(address => IKeeperIncentiveV2.Incentive[]) public incentivesByController;

  /**
   * @dev all controller contract addresses
   */
  address[] public controllerContracts;

  /**
   * @dev keeperAddress => list of account IDs
   */
  mapping(address => bytes32[]) public keeperAccounts;

  /**
   * @dev tokenAddress => burnBalance
   */
  mapping(address => uint256) public burnBalancesByToken;

  /**
   * @dev incentiveAccountId => owner => Account
   */
  mapping(bytes32 => mapping(address => IKeeperIncentiveV2.Account)) public accounts;

  /**
   * @dev incentiveAccountId => owner => isCached
   */
  mapping(bytes32 => mapping(address => bool)) public cachedAccounts;

  /**
   * @dev contracts allowed to call keeper incentives
   */
  mapping(address => bool) public allowedControllers;

  /**
   * @dev address to send tokens to burn
   */
  address constant burnAddress = 0x000000000000000000000000000000000000dEaD;

  /**
   * @dev required amount of pop tokens staked for a keeper to call handleKeeperIncentive
   */
  uint256 public requiredKeeperStake;

  /**
   * @dev default percentage of tokens burned
   */
  uint256 public defaultBurnPercentage;

  /* ========== EVENTS ========== */

  event IncentiveCreated(address indexed contractAddress, uint256 reward, bool openToEveryone, uint256 index);
  event IncentiveChanged(
    address indexed contractAddress,
    uint256 oldReward,
    uint256 newReward,
    bool oldOpenToEveryone,
    bool newOpenToEveryone,
    address oldRewardToken,
    address newRewardToken,
    uint256 oldCooldown,
    uint256 newCooldown,
    uint256 oldBurnPercentage,
    uint256 newBurnPercentage,
    uint256 index
  );
  event IncentiveFunded(uint256 amount, address indexed rewardToken, uint256 incentiveBalance);
  event IncentiveTipped(uint256 amount, address indexed rewardToken);
  event ApprovalToggled(address indexed contractAddress, bool openToEveryone);
  event IncentiveToggled(address indexed contractAddress, bool enabled);
  event Burned(uint256 amount, address indexed tokenAddress);
  event Claimed(address indexed token, address indexed account, uint256 amount);
  event BurnPercentageChanged(uint256 oldRate, uint256 newRate);
  event RequiredKeeperStakeChanged(uint256 oldRequirement, uint256 newRequirement);

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry _contractRegistry,
    uint256 _burnPercentage,
    uint256 _requiredKeeperStake
  ) ContractRegistryAccess(_contractRegistry) {
    defaultBurnPercentage = _burnPercentage; // 25e16 = 25%
    requiredKeeperStake = _requiredKeeperStake; // 2000 POP
  }

  /* ==========  VIEWS  ========== */

  /**
   * @return true or false if keeper has claimable reward token balance
   * @param keeper address of keeper
   */
  function hasClaimableBalance(address keeper) external view returns (bool) {
    uint256 length = keeperAccounts[keeper].length;
    for (uint256 i; i < length; ++i) {
      bytes32 _incentiveAccountId = keeperAccounts[keeper][i];
      if (_incentiveAccountId == "") continue;
      if (accounts[_incentiveAccountId][keeper].balance > 0) {
        return true;
      }
    }
    return false;
  }

  /**
   * @return all accounts associated with keeper
   * @param owner keeper account owner
   */
  function getAccounts(address owner) external view returns (IKeeperIncentiveV2.Account[] memory) {
    uint256 arrLength = keeperAccounts[owner].length;
    IKeeperIncentiveV2.Account[] memory _accounts = new IKeeperIncentiveV2.Account[](arrLength);
    for (uint256 i; i < arrLength; ++i) {
      _accounts[i] = accounts[keeperAccounts[owner][i]][owner];
    }
    return _accounts;
  }

  /**
   * @return all controller contract addresses
   */
  function getControllerContracts() external view returns (address[] memory) {
    return controllerContracts;
  }

  /**
   * @notice Helper function to get incentiveAccountId
   * @param _contractAddress address of controller contract
   * @param _i incentive index
   * @param _rewardsToken token that rewards are paid out with
   */
  function incentiveAccountId(
    address _contractAddress,
    uint256 _i,
    address _rewardsToken
  ) public pure returns (bytes32) {
    return keccak256(abi.encode(_contractAddress, _i, _rewardsToken));
  }

  /* ==========  MUTATIVE FUNCTIONS  ========== */

  /**
   * @notice External function call thats checks requirements for keeper-incentived functions and updates rewards earned
   * @param _i incentive index
   * @param _keeper address of keeper receiving reward
   */
  function handleKeeperIncentive(uint8 _i, address _keeper) external override(IKeeperIncentiveV2) {
    _handleKeeperIncentive(_i, _keeper);
  }

  /**
   * @dev Deprecated, use handleKeeperIncentive(uint8 _i, address _keeper) instead
   */
  function handleKeeperIncentive(
    bytes32,
    uint8 _i,
    address _keeper
  ) external override(IKeeperIncentiveV2) {
    _handleKeeperIncentive(_i, _keeper);
  }

  /**
   * @notice Keeper calls to claim rewards earned
   * @param incentiveAccountIds accountIds associated with keeper caller
   */
  function claim(bytes32[] calldata incentiveAccountIds) external {
    uint256 length = incentiveAccountIds.length;
    for (uint256 i; i < length; ++i) {
      bytes32 _incentiveAccountId = incentiveAccountIds[i];
      _claim(_incentiveAccountId, msg.sender);
    }
  }

  /**
   * @notice External function to send the tokens in burnBalance to burnAddress
   * @param tokenAddress address of reward token to burn
   */
  function burn(address tokenAddress) external {
    uint256 burnBalance = burnBalancesByToken[tokenAddress];
    require(burnBalance > 0, "no burn balance");

    burnBalancesByToken[tokenAddress] = 0;
    IERC20 token = IERC20(tokenAddress);
    token.safeTransfer(burnAddress, burnBalance);

    emit Burned(burnBalance, tokenAddress);
  }

  /* ========== ADMIN FUNCTIONS ========== */

  /**
   * @notice Create Incentives for keeper to call a function. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _address address of contract which owns the incentives
   * @param _reward The amount in reward token the Keeper receives for calling the function
   * @param _enabled Is this Incentive currently enabled?
   * @param _openToEveryone incentive is open to anyone
   * @param _rewardToken token to receive as incentive reward
   * @param _cooldown length of time required to wait until next allowable invocation using handleKeeperIncentives()
   * @param _burnPercentage Percentage in Mantissa. (1e14 = 1 Basis Point) - if rewardToken is POP token and _burnPercentage is 0, will default to contract defined defaultBurnPercentage
   * @dev This function is only for creating unique incentives for future contracts
   * @dev Multiple functions can use the same incentive which can then be updated with one governance vote
   */
  function createIncentive(
    address _address,
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone,
    address _rewardToken,
    uint256 _cooldown,
    uint256 _burnPercentage
  ) public onlyRole(INCENTIVE_MANAGER_ROLE) returns (uint256) {
    require(_cooldown > 0, "must set cooldown");
    require(_rewardToken != address(0), "must set reward token");
    require(_burnPercentage <= 1e18, "burn percentage too high");
    allowedControllers[_address] = true;

    uint256 index = incentivesByController[_address].length;
    bytes32 _incentiveAccountId = incentiveAccountId(_address, index, _rewardToken);
    incentivesByController[_address].push(
      IKeeperIncentiveV2.Incentive({
        id: index,
        reward: _reward,
        rewardToken: _rewardToken,
        enabled: _enabled,
        openToEveryone: _openToEveryone,
        cooldown: _cooldown,
        burnPercentage: _rewardToken == _getContract(keccak256("POP")) && _burnPercentage == 0
          ? defaultBurnPercentage
          : _burnPercentage,
        lastInvocation: 0
      })
    );

    controllerContracts.push(_address);
    __cacheAccount(address(this), _incentiveAccountId);
    accounts[_incentiveAccountId][address(this)].token = _rewardToken;

    emit IncentiveCreated(_address, _reward, _openToEveryone, index);
    return index;
  }

  /**
   * @notice Update the incentive struct values for keeper to call a function. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _contractAddress address of contract which owns the incentives
   * @param _i incentive index
   * @param _reward The amount in reward token the Keeper receives for calling the function
   * @param _enabled Is this Incentive currently enabled?
   * @param _openToEveryone incentive is open to anyone
   * @param _rewardToken token to receive as incentive reward
   * @param _cooldown length of time required to wait until next allowable invocation using handleKeeperIncentives()
   * @param _burnPercentage Percentage in Mantissa. (1e14 = 1 Basis Point) - if rewardToken is POP token and _burnPercentage is 0, will default to contract defined defaultBurnPercentage
   * @dev Multiple functions can use the same incentive which can be updated here with one governance vote
   */
  function updateIncentive(
    address _contractAddress,
    uint8 _i,
    uint256 _reward,
    bool _enabled,
    bool _openToEveryone,
    address _rewardToken,
    uint256 _cooldown,
    uint256 _burnPercentage
  ) external onlyRole(INCENTIVE_MANAGER_ROLE) {
    require(_cooldown > 0, "must set cooldown");
    require(_rewardToken != address(0), "must set reward token");
    require(_burnPercentage <= 1e18, "burn percentage too high");

    IKeeperIncentiveV2.Incentive storage incentive = incentivesByController[_contractAddress][_i];
    _burnPercentage = _rewardToken == _getContract(keccak256("POP")) && _burnPercentage == 0
      ? defaultBurnPercentage
      : _burnPercentage;

    emit IncentiveChanged(
      _contractAddress,
      incentive.reward,
      _reward,
      incentive.openToEveryone,
      _openToEveryone,
      incentive.rewardToken,
      _rewardToken,
      incentive.cooldown,
      _cooldown,
      incentive.burnPercentage,
      _burnPercentage,
      incentive.id
    );

    bytes32 _incentiveAccountId = incentiveAccountId(_contractAddress, _i, _rewardToken);
    incentive.reward = _reward;
    incentive.enabled = _enabled;
    incentive.openToEveryone = _openToEveryone;
    incentive.rewardToken = _rewardToken;
    incentive.cooldown = _cooldown;
    incentive.burnPercentage = _burnPercentage;

    __cacheAccount(address(this), _incentiveAccountId);
    accounts[_incentiveAccountId][address(this)].token = _rewardToken;
  }

  /**
   * @notice Changes whether an incentive is open to anyone. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _contractAddress address of controller contract
   * @param _i incentive index
   */
  function toggleApproval(address _contractAddress, uint8 _i) external onlyRole(INCENTIVE_MANAGER_ROLE) {
    IKeeperIncentiveV2.Incentive storage incentive = incentivesByController[_contractAddress][_i];
    incentive.openToEveryone = !incentive.openToEveryone;

    emit ApprovalToggled(_contractAddress, incentive.openToEveryone);
  }

  /**
   * @notice Changes whether an incentive is currently enabled. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _contractAddress address of controller contract
   * @param _i incentive index
   */
  function toggleIncentive(address _contractAddress, uint8 _i) external onlyRole(INCENTIVE_MANAGER_ROLE) {
    IKeeperIncentiveV2.Incentive storage incentive = incentivesByController[_contractAddress][_i];
    incentive.enabled = !incentive.enabled;

    emit IncentiveToggled(_contractAddress, incentive.enabled);
  }

  /**
   * @notice Funds incentive with reward token
   * @param _contractAddress address of controller contract
   * @param _i incentive index
   * @param _amount amount of reward token to fund incentive with
   */
  function fundIncentive(
    address _contractAddress,
    uint256 _i,
    uint256 _amount
  ) external {
    require(_amount > 0, "must send amount");
    require(incentivesByController[_contractAddress].length > _i, "incentive does not exist");
    IKeeperIncentiveV2.Incentive storage incentive = incentivesByController[_contractAddress][_i];

    bytes32 _incentiveAccountId = incentiveAccountId(_contractAddress, _i, incentive.rewardToken);

    IERC20 token = IERC20(incentive.rewardToken);
    uint256 balanceBefore = token.balanceOf(address(this)); // get balance before
    token.safeTransferFrom(msg.sender, address(this), _amount); // transfer in
    uint256 transferred = token.balanceOf(address(this)) - balanceBefore; // calculate amount transferred

    _internalTransfer(_incentiveAccountId, address(0), address(this), transferred);

    emit IncentiveFunded(_amount, incentive.rewardToken, accounts[_incentiveAccountId][address(this)].balance);
  }

  /**
   * @notice Allows for incentives to be funded with additional tip
   * @param _rewardToken address of token to tip keeper with
   * @param _keeper address of keeper receiving the tip
   * @param _i incentive index
   * @param _amount amount of reward token to tip
   */
  function tip(
    address _rewardToken,
    address _keeper,
    uint256 _i,
    uint256 _amount
  ) external {
    require(_amount > 0, "must send amount");
    require(allowedControllers[msg.sender], "must be controller contract");

    bytes32 _incentiveAccountId = incentiveAccountId(msg.sender, _i, _rewardToken);
    _cacheKeeperAccount(_keeper, _incentiveAccountId);
    accounts[_incentiveAccountId][address(this)].token = _rewardToken;

    _internalTransfer(_incentiveAccountId, address(0), _keeper, _amount);
    IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _amount);

    emit IncentiveTipped(_amount, _rewardToken);
  }

  /**
   * @notice Allows for incentives to be funded with additional tip
   * @param _rewardToken address of token to tip keeper with
   * @param _keeper address of keeper receiving the tip
   * @param _i incentive index
   * @param _amount amount of reward token to tip
   * @param _burnPercentage Percentage in Mantissa. (1e14 = 1 Basis Point)
   */
  function tipWithBurn(
    address _rewardToken,
    address _keeper,
    uint256 _i,
    uint256 _amount,
    uint256 _burnPercentage
  ) external {
    require(_amount > 0, "must send amount");
    require(allowedControllers[msg.sender], "must be controller contract");
    require(_burnPercentage <= 1e18, "burn percentage too high");

    bytes32 _incentiveAccountId = incentiveAccountId(msg.sender, _i, _rewardToken);
    _cacheKeeperAccount(_keeper, _incentiveAccountId);
    accounts[_incentiveAccountId][address(this)].token = _rewardToken;

    IERC20(_rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
    _internalTransfer(_incentiveAccountId, address(0), address(this), _amount);

    uint256 burnAmount = (_amount * _burnPercentage) / 1e18;
    uint256 tipPayout = _amount - burnAmount;

    if (burnAmount > 0) {
      _burn(burnAmount, _incentiveAccountId, _rewardToken);
    }

    _internalTransfer(_incentiveAccountId, address(this), _keeper, tipPayout);

    emit IncentiveTipped(tipPayout, _rewardToken);
  }

  /**
   * @notice Sets the current burn rate as a percentage of the incentive reward. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _burnPercentage Percentage in Mantissa. (1e14 = 1 Basis Point)
   */
  function updateBurnPercentage(uint256 _burnPercentage) external onlyRole(INCENTIVE_MANAGER_ROLE) {
    require(_burnPercentage <= 1e18, "burn percentage too high");
    emit BurnPercentageChanged(defaultBurnPercentage, _burnPercentage);
    defaultBurnPercentage = _burnPercentage;
  }

  /**
   * @notice Sets the required amount of POP a keeper needs to have staked to handle incentivized functions. Caller must have INCENTIVE_MANAGER_ROLE from ACLRegistry.
   * @param _amount Amount of POP a keeper needs to stake
   */
  function updateRequiredKeeperStake(uint256 _amount) external onlyRole(INCENTIVE_MANAGER_ROLE) {
    emit RequiredKeeperStakeChanged(requiredKeeperStake, _amount);
    requiredKeeperStake = _amount;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
  /**
   * @notice Checks requirements for keeper-incentived function calls and updates rewards earned for keeper to claim
   * @param _i incentive index
   * @param _keeper address of keeper receiving reward (must have pop staked)
   * @dev will revert if keeper has not waited cooldown period before calling incentivized function
   * @dev if the incentive is not open to anyone the _keeper must have KEEPER_ROLE from ACLRegistry
   */
  function _handleKeeperIncentive(uint8 _i, address _keeper) internal {
    if (incentivesByController[msg.sender].length == 0 || _i >= incentivesByController[msg.sender].length) {
      return;
    }

    require(allowedControllers[msg.sender], "Can only be called by the controlling contract");

    require(
      IStaking(_getContract(keccak256("PopLocker"))).balanceOf(_keeper) >= requiredKeeperStake,
      "not enough pop staked"
    );

    IKeeperIncentiveV2.Incentive memory incentive = incentivesByController[msg.sender][_i];
    bytes32 _incentiveAccountId = incentiveAccountId(msg.sender, _i, incentive.rewardToken);

    require(block.timestamp - incentive.lastInvocation >= incentive.cooldown, "wait for cooldown period");

    if (!incentive.openToEveryone) {
      _requireRole(KEEPER_ROLE, _keeper);
    }

    incentivesByController[msg.sender][_i].lastInvocation = block.timestamp;

    if (
      incentive.enabled &&
      incentive.reward <= accounts[_incentiveAccountId][address(this)].balance &&
      incentive.reward > 0
    ) {
      _payoutIncentive(_keeper, incentive, _incentiveAccountId);
    }
  }

  /**
   * @notice Deposits rewards for keeper and burns tokens if burnPercentage set for incentive
   * @param _keeper address of keeper receiving reward (must have pop staked)
   * @param incentive incentive struct used to determine reward tokens and burn amount
   * @param _incentiveAccountId id of the incentive to deposit tokens
   */
  function _payoutIncentive(
    address _keeper,
    IKeeperIncentiveV2.Incentive memory incentive,
    bytes32 _incentiveAccountId
  ) internal {
    (uint256 payoutAmount, uint256 burnAmount) = _previewPayout(incentive);
    _deposit(_keeper, payoutAmount, _incentiveAccountId);

    if (burnAmount > 0) {
      _burn(burnAmount, _incentiveAccountId, incentive.rewardToken);
    }
  }

  /**
   * @notice Pure function to calculate and return the amount of tokens to payout to keeper and to burn
   * @return payoutAmount amout of tokens a keeper has earned
   * @return burnAmount amout of tokens to be burned after payout
   * @param incentive incentive struct used to determine reward amount and burn percentage
   */
  function _previewPayout(IKeeperIncentiveV2.Incentive memory incentive)
    internal
    pure
    returns (uint256 payoutAmount, uint256 burnAmount)
  {
    burnAmount = (incentive.reward * incentive.burnPercentage) / 1e18;
    payoutAmount = incentive.reward - burnAmount;
  }

  /**
   * @notice Deposits rewards into keeper account and updates values in storage
   * @param keeper address of keeper receiving reward
   * @param amount amount of reward tokens distributed to keeper
   * @param _incentiveAccountId id of the incentive to deposit tokens
   */
  function _deposit(
    address keeper,
    uint256 amount,
    bytes32 _incentiveAccountId
  ) internal {
    _cacheKeeperAccount(keeper, _incentiveAccountId);
    _internalTransfer(_incentiveAccountId, address(this), keeper, amount);
  }

  /**
   * @notice Internal call that transfers reward tokens out of contract to keeper
   * @param _incentiveAccountId id of the incentive with keeper account balance
   * @param keeper address of keeper receiving reward
   */
  function _claim(bytes32 _incentiveAccountId, address keeper) internal {
    IKeeperIncentiveV2.Account storage account = accounts[_incentiveAccountId][keeper];
    uint256 balance = account.balance;

    require(balance > 0, "nothing to claim");

    _internalTransfer(_incentiveAccountId, keeper, address(0), balance);

    IERC20 token = IERC20(account.token);
    token.safeTransfer(keeper, balance);

    emit Claimed(address(token), keeper, balance);
  }

  /**
   * @notice Updates keeper account balance by transfering balance of tokens out this contract or used to burn tokens
   * @param _incentiveAccountId id of the incentive
   * @param to address receiving transferred tokens
   * @param from address sending tokens
   * @dev if burning tokens, amount is sent to address(0)
   */
  function _internalTransfer(
    bytes32 _incentiveAccountId,
    address from,
    address to,
    uint256 amount
  ) private {
    IKeeperIncentiveV2.Account storage fromAccount = accounts[_incentiveAccountId][from];
    IKeeperIncentiveV2.Account storage toAccount = accounts[_incentiveAccountId][to];
    fromAccount.balance -= from == address(0) ? 0 : amount;
    toAccount.balance += to == address(0) ? 0 : amount;
  }

  /**
   * @notice Burns tokens by transfering amount to address(0)
   * @param amount amount of tokens to burn
   * @param _incentiveAccountId id of the incentive
   * @param tokenAddress address of token to burn
   */
  function _burn(
    uint256 amount,
    bytes32 _incentiveAccountId,
    address tokenAddress
  ) internal {
    burnBalancesByToken[tokenAddress] += amount;
    _internalTransfer(_incentiveAccountId, address(this), burnAddress, amount);
  }

  /**
   * @notice If incentiveAccountId does not have keeper address cached, updates mappings in storage
   * @param keeper address of keeper
   * @param _incentiveAccountId id of the incentive to cache keeper account
   */
  function _cacheKeeperAccount(address keeper, bytes32 _incentiveAccountId) internal {
    if (!cachedAccounts[_incentiveAccountId][keeper]) {
      return __cacheAccount(keeper, _incentiveAccountId);
    }
  }

  /**
   * @notice Updates storage with incentiveAccountId and keeper address
   * @param keeper address of keeper (will be address of this contract when creating and updating incentives)
   * @param _incentiveAccountId id of the incentive to cache as key in mappings
   */
  function __cacheAccount(address keeper, bytes32 _incentiveAccountId) internal {
    keeperAccounts[keeper].push(_incentiveAccountId);
    accounts[_incentiveAccountId][keeper].accountId = _incentiveAccountId;
    cachedAccounts[_incentiveAccountId][keeper] = true;
    accounts[_incentiveAccountId][keeper].token = accounts[_incentiveAccountId][address(this)].token;
  }

  /**
   * @notice Override for ACLAuth and ContractRegistryAccess.
   */
  function _getContract(bytes32 _name) internal view override(ACLAuth, ContractRegistryAccess) returns (address) {
    return super._getContract(_name);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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