// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IACLRegistry.sol";
import "../interfaces/IContractRegistry.sol";

contract ParticipationReward is ReentrancyGuard {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */
  enum VaultStatus {
    Init,
    Open
  }

  struct Vault {
    VaultStatus status;
    uint256 endTime;
    uint256 shares;
    uint256 tokenBalance;
    mapping(address => uint256) shareBalances;
    mapping(address => bool) claimed;
  }

  IContractRegistry public contractRegistry;

  uint256 public rewardBalance;
  uint256 public totalVaultsBudget;
  mapping(bytes32 => uint256) public rewardBudgets;
  mapping(bytes32 => Vault) public vaults;
  mapping(address => bytes32[]) public userVaults;
  mapping(bytes32 => address) public controllerContracts;
  mapping(bytes32 => bool) public rewardsEnabled;

  /* ========== EVENTS ========== */
  event RewardBudgetChanged(bytes32 _contractName, uint256 amount);
  event VaultInitialized(bytes32 vaultId);
  event VaultOpened(bytes32 vaultId);
  event VaultClosed(bytes32 vaultId);
  event RewardClaimed(bytes32 vaultId, address _account, uint256 amount);
  event RewardsClaimed(address _account, uint256 amount);
  event SharesAdded(bytes32 _vaultId, address _account, uint256 _shares);
  event RewardBalanceIncreased(address account, uint256 amount);
  event ControllerContractAdded(bytes32 _contractName, address _contract);
  event RewardsToggled(bytes32 _contractName, bool prevState, bool newState);

  /* ========== CONSTRUCTOR ========== */

  constructor(IContractRegistry _contractRegistry) {
    contractRegistry = _contractRegistry;
  }

  /* ========== VIEWS ========== */

  function isClaimable(bytes32 _vaultId, address _beneficiary) public view vaultExists(_vaultId) returns (bool) {
    return
      vaults[_vaultId].status == VaultStatus.Open &&
      vaults[_vaultId].shareBalances[_beneficiary] > 0 &&
      vaults[_vaultId].claimed[_beneficiary] == false;
  }

  /**
   * @notice Checks if a beneficiary has a claim in the specified vault
   * @param _vaultId Bytes32
   * @param _beneficiary address of the beneficiary
   */
  function hasClaim(bytes32 _vaultId, address _beneficiary) public view vaultExists(_vaultId) returns (bool) {
    return vaults[_vaultId].shareBalances[_beneficiary] > 0 && vaults[_vaultId].claimed[_beneficiary] == false;
  }

  /**
   * @notice Returns the vault status
   * @param _vaultId Bytes32
   */
  function getVaultStatus(bytes32 _vaultId) external view returns (VaultStatus) {
    return vaults[_vaultId].status;
  }

  /**
   * @notice Returns all vaultIds which an account has/had claims in
   * @param _account address
   */
  function getUserVaults(address _account) external view returns (bytes32[] memory) {
    return userVaults[_account];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Initializes a vault for voting claims
   * @param _contractName Name of contract that uses ParticipationRewards in bytes32
   * @param _vaultId Bytes32
   * @param _endTime Unix timestamp in seconds after which a vault can be closed
   * @dev There must be enough funds in this contract to support opening another vault
   */
  function initializeVault(
    bytes32 _contractName,
    bytes32 _vaultId,
    uint256 _endTime
  ) external onlyControllerContract(_contractName) returns (bool, bytes32) {
    require(rewardsEnabled[_contractName], "participationRewards are not enabled for this contract");
    require(vaults[_vaultId].endTime == 0, "Vault must not exist");
    require(_endTime > block.timestamp, "end must be in the future");

    uint256 expectedVaultBudget = totalVaultsBudget + rewardBudgets[_contractName];
    if (expectedVaultBudget > rewardBalance || rewardBalance == 0) {
      return (false, "");
    }

    totalVaultsBudget = expectedVaultBudget;

    Vault storage vault = vaults[_vaultId];
    vault.endTime = _endTime;
    vault.tokenBalance = rewardBudgets[_contractName];

    emit VaultInitialized(_vaultId);
    return (true, _vaultId);
  }

  /**
   * @notice Open a vault it can receive rewards and accept claims
   * @dev Vault must be in an initialized state
   * @param _contractName the controller contract
   * @param _vaultId Vault ID in bytes32
   */
  function openVault(bytes32 _contractName, bytes32 _vaultId)
    external
    onlyControllerContract(_contractName)
    vaultExists(_vaultId)
  {
    require(vaults[_vaultId].status == VaultStatus.Init, "Vault must be initialized");
    require(vaults[_vaultId].endTime <= block.timestamp, "wait till endTime is over");
    //TODO should vaults also be mapped to contracts? Currently contract A could technically open vaults for contract B the only protection against that is governance who decides which contracts get added
    vaults[_vaultId].status = VaultStatus.Open;

    emit VaultOpened(_vaultId);
  }

  /**
   * @notice Adds Shares of an account to the current vault
   * @param _contractName the controller contract
   * @param _vaultId Bytes32
   * @param _account address
   * @param _shares uint256
   * @dev This will be called by contracts after an account has voted in order to add them to the vault of the specified election.
   */
  function addShares(
    bytes32 _contractName,
    bytes32 _vaultId,
    address _account,
    uint256 _shares
  ) external onlyControllerContract(_contractName) vaultExists(_vaultId) {
    require(vaults[_vaultId].status == VaultStatus.Init, "Vault must be initialized");
    vaults[_vaultId].shares = vaults[_vaultId].shares + _shares;
    vaults[_vaultId].shareBalances[_account] = _shares;

    userVaults[_account].push(_vaultId);

    emit SharesAdded(_vaultId, _account, _shares);
  }

  /**
   * @notice Claim rewards of a vault
   * @param _index uint256
   * @dev Uses the vaultId at the specified index of userVaults.
   * @dev This function is used when a user only wants to claim a specific vault or if they decide the gas cost of claimRewards are to high for now.
   * @dev (lower cost but also lower reward)
   */
  function claimReward(uint256 _index) external nonReentrant {
    bytes32 vaultId = userVaults[msg.sender][_index];
    require(vaults[vaultId].status == VaultStatus.Open, "vault is not open");
    require(!vaults[vaultId].claimed[msg.sender], "already claimed");
    uint256 reward = _claimVaultReward(vaultId, _index, msg.sender);
    require(reward > 0, "no rewards");
    require(reward <= rewardBalance, "not enough funds for payout");

    totalVaultsBudget = totalVaultsBudget - reward;
    rewardBalance = rewardBalance - reward;

    IERC20(contractRegistry.getContract(keccak256("POP"))).safeTransfer(msg.sender, reward);

    emit RewardsClaimed(msg.sender, reward);
  }

  /**
   * @notice Claim rewards of a a number of vaults
   * @param _indices uint256[]
   * @dev Uses the vaultIds at the specified indices of userVaults.
   * @dev This function is used when a user only wants to claim multiple vaults at once (probably most of the time)
   * @dev The array of indices is limited to 19 as we want to prevent gas overflow of looping through too many vaults
   */
  function claimRewards(uint256[] calldata _indices) external nonReentrant {
    require(_indices.length < 20, "claiming too many vaults");
    uint256 total;

    for (uint256 i = 0; i < _indices.length; i++) {
      bytes32 vaultId = userVaults[msg.sender][_indices[i]];
      if (vaults[vaultId].status == VaultStatus.Open && !vaults[vaultId].claimed[msg.sender]) {
        total = total + _claimVaultReward(vaultId, _indices[i], msg.sender);
      }
    }

    require(total > 0, "no rewards");
    require(total <= rewardBalance, "not enough funds for payout");

    totalVaultsBudget = totalVaultsBudget - total;
    rewardBalance = rewardBalance - total;

    IERC20(contractRegistry.getContract(keccak256("POP"))).safeTransfer(msg.sender, total);

    emit RewardsClaimed(msg.sender, total);
  }

  /**
   * @notice Underlying function to calculate the rewards that a user gets and set the vault to claimed
   * @param _vaultId Bytes32
   * @param _index uint256
   * @param _account address
   * @dev We dont want it to error when a vault is empty for the user as this would terminate the entire loop when used in claimRewards()
   */
  function _claimVaultReward(
    bytes32 _vaultId,
    uint256 _index,
    address _account
  ) internal returns (uint256) {
    uint256 userShares = vaults[_vaultId].shareBalances[_account];
    if (userShares > 0) {
      uint256 reward = (vaults[_vaultId].tokenBalance * userShares) / vaults[_vaultId].shares;
      vaults[_vaultId].tokenBalance = vaults[_vaultId].tokenBalance - reward;
      vaults[_vaultId].claimed[_account] = true;

      delete userVaults[_account][_index];
      return reward;
    }
    return 0;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
   * @notice Sets the budget of rewards in POP per vault
   * @param _contractName the name of the controller contract in bytes32
   * @param _amount uint256 reward amount in POP per vault
   * @dev When opening a vault this contract must have enough POP to fund the rewardBudgets of the new vault
   * @dev Every controller contract has their own rewardsBudget to set indivual rewards per controller contract
   */
  function setRewardsBudget(bytes32 _contractName, uint256 _amount) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    require(_amount > 0, "must be larger 0");
    rewardBudgets[_contractName] = _amount;
    emit RewardBudgetChanged(_contractName, _amount);
  }

  /**
   * @notice In order to allow a contract to use ParticipationReward they need to be added as a controller contract
   * @param _contractName the name of the controller contract in bytes32
   * @param _contract the address of the controller contract
   * @dev all critical functions to init/open vaults and add shares to them can only be called by controller contracts
   */
  function addControllerContract(bytes32 _contractName, address _contract) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    controllerContracts[_contractName] = _contract;
    rewardsEnabled[_contractName] = true;
    emit ControllerContractAdded(_contractName, _contract);
  }

  /**
   * @notice Governance can disable rewards for a controller contract in order to stop an unused contract to leech rewards
   * @param _contractName the address of the controller contract
   * @dev all critical functions to init/open vaults and add shares to them can only be called by controller contracts
   */
  function toggleRewards(bytes32 _contractName) external {
    IACLRegistry(contractRegistry.getContract(keccak256("ACLRegistry"))).requireRole(keccak256("DAO"), msg.sender);
    bool prevState = rewardsEnabled[_contractName];
    rewardsEnabled[_contractName] = !prevState;
    emit RewardsToggled(_contractName, prevState, rewardsEnabled[_contractName]);
  }

  /**
   * @notice Transfer POP to the contract for vault rewards
   * @param _amount uint256 amount in POP to be used for vault rewards
   * @dev Sufficient RewardsBalance will be checked when opening a new vault to see if enough POP exist to support the new Vault
   */
  function contributeReward(uint256 _amount) external {
    require(_amount > 0, "must be larger 0");
    IERC20(contractRegistry.getContract(keccak256("POP"))).safeTransferFrom(msg.sender, address(this), _amount);
    rewardBalance = rewardBalance + _amount;
    emit RewardBalanceIncreased(msg.sender, _amount);
  }

  /* ========== MODIFIERS ========== */

  /**
   * @notice Modifier to check if a vault exists
   * @param _vaultId Bytes32
   */
  modifier vaultExists(bytes32 _vaultId) {
    require(vaults[_vaultId].endTime > 0, "Uninitialized vault slot");
    _;
  }

  /**
   * @notice Checks if the msg.sender is the controllerContract
   * @param _contractName Bytes32
   */
  modifier onlyControllerContract(bytes32 _contractName) {
    require(msg.sender == controllerContracts[_contractName], "Can only be called by the controlling contract");
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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