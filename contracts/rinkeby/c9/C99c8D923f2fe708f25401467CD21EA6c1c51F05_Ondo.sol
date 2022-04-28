// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

/*
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
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return interfaceId == type(IERC165).interfaceId;
  }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;
}

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
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {_setupRole}.
   */
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      interfaceId == type(IAccessControl).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account)
    public
    view
    override
    returns (bool)
  {
    return _roles[role].members[account];
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
   */
  function grantRole(bytes32 role, address account) public virtual override {
    require(
      hasRole(getRoleAdmin(role), _msgSender()),
      "AccessControl: sender must be an admin to grant"
    );

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
   */
  function revokeRole(bytes32 role, address account) public virtual override {
    require(
      hasRole(getRoleAdmin(role), _msgSender()),
      "AccessControl: sender must be an admin to revoke"
    );

    _revokeRole(role, account);
  }

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
  function renounceRole(bytes32 role, address account) public virtual override {
    require(
      account == _msgSender(),
      "AccessControl: can only renounce roles for self"
    );

    _revokeRole(role, account);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
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
    emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
    _roles[role].adminRole = adminRole;
  }

  function _grantRole(bytes32 role, address account) private {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  function _revokeRole(bytes32 role, address account) private {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

interface IOndo {
  enum InvestorType {CoinlistTranche1, CoinlistTranche2, SeedTranche}

  // ----------- State changing api -----------

  /// @notice Called by timelock contract to initialize locked balance of coinlist/seed investor
  function updateTrancheBalance(
    address beneficiary,
    uint256 rawAmount,
    InvestorType tranche
  ) external;

  // ----------- Getters -----------

  /// @notice Gets the TOTAL amount of Ondo available for an address
  function getFreedBalance(address account) external view returns (uint96);

  /// @notice Gets the initial locked balance and unlocked Ondo for an address
  function getVestedBalance(address account)
    external
    view
    returns (uint96, uint96);
}

abstract contract LinearTimelock {
  struct InvestorParam {
    IOndo.InvestorType investorType;
    uint96 initialBalance;
  }

  /// @notice the timestamp at which releasing is allowed
  uint256 public cliffTimestamp;
  /// @notice the linear vesting period for the first tranche
  uint256 public immutable tranche1VestingPeriod;
  /// @notice the linear vesting period for the second tranche
  uint256 public immutable tranche2VestingPeriod;
  /// @notice the linear vesting period for the Seed/Series A Tranche
  uint256 public immutable seedVestingPeriod;
  /// @dev mapping of balances for each investor
  mapping(address => InvestorParam) internal investorBalances;
  /// @notice role that allows updating of tranche balances - granted to Merkle airdrop contract
  bytes32 public constant TIMELOCK_UPDATE_ROLE =
    keccak256("TIMELOCK_UPDATE_ROLE");

  constructor(
    uint256 _cliffTimestamp,
    uint256 _tranche1VestingPeriod,
    uint256 _tranche2VestingPeriod,
    uint256 _seedVestingPeriod
  ) {
    cliffTimestamp = _cliffTimestamp;
    tranche1VestingPeriod = _tranche1VestingPeriod;
    tranche2VestingPeriod = _tranche2VestingPeriod;
    seedVestingPeriod = _seedVestingPeriod;
  }

  function passedCliff() public view returns (bool) {
    return block.timestamp > cliffTimestamp;
  }

  /// @dev the seedVestingPeriod is the longest vesting period
  function passedAllVestingPeriods() public view returns (bool) {
    return block.timestamp > cliffTimestamp + seedVestingPeriod;
  }

  /**
    @notice View function to get the user's initial balance and current amount of freed balance
   */
  function getVestedBalance(address account)
    external
    view
    returns (uint256, uint256)
  {
    if (investorBalances[account].initialBalance == 0) {
      return (0, 0);
    }
    InvestorParam memory investorParam = investorBalances[account];
    uint96 amountAvailable;
    if (passedAllVestingPeriods()) {
      amountAvailable = investorParam.initialBalance;
    } else if (passedCliff()) {
      (uint256 vestingPeriod, uint256 elapsed) =
        _getTrancheInfo(investorParam.investorType);
      amountAvailable = _proportionAvailable(
        elapsed,
        vestingPeriod,
        investorParam
      );
    } else {
      amountAvailable = 0;
    }
    return (investorParam.initialBalance, amountAvailable);
  }

  function _getTrancheInfo(IOndo.InvestorType investorType)
    internal
    view
    returns (uint256 vestingPeriod, uint256 elapsed)
  {
    elapsed = block.timestamp - cliffTimestamp;
    if (investorType == IOndo.InvestorType.CoinlistTranche1) {
      elapsed = elapsed > tranche1VestingPeriod
        ? tranche1VestingPeriod
        : elapsed;
      vestingPeriod = tranche1VestingPeriod;
    } else if (investorType == IOndo.InvestorType.CoinlistTranche2) {
      elapsed = elapsed > tranche2VestingPeriod
        ? tranche2VestingPeriod
        : elapsed;
      vestingPeriod = tranche2VestingPeriod;
    } else if (investorType == IOndo.InvestorType.SeedTranche) {
      elapsed = elapsed > seedVestingPeriod ? seedVestingPeriod : elapsed;
      vestingPeriod = seedVestingPeriod;
    }
  }

  function _proportionAvailable(
    uint256 elapsed,
    uint256 vestingPeriod,
    InvestorParam memory investorParam
  ) internal pure returns (uint96) {
    if (investorParam.investorType == IOndo.InvestorType.SeedTranche) {
      // Seed/Series A Tranche Balance = proportionAvail*2/3 + x/3, where x = Balance. This allows 1/3 of the series A balance to be unlocked at cliff
      uint96 vestedAmount =
        safe96(
          (((investorParam.initialBalance * elapsed) / vestingPeriod) * 2) / 3,
          "Ondo::_proportionAvailable: amount exceeds 96 bits"
        );
      return
        add96(
          vestedAmount,
          investorParam.initialBalance / 3,
          "Ondo::_proportionAvailable: overflow"
        );
    } else {
      return
        safe96(
          (investorParam.initialBalance * elapsed) / vestingPeriod,
          "Ondo::_proportionAvailable: amount exceeds 96 bits"
        );
    }
  }

  function safe32(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint32)
  {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function safe96(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint96)
  {
    require(n < 2**96, errorMessage);
    return uint96(n);
  }

  function add96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    return a - b;
  }
}

contract Ondo is AccessControl, LinearTimelock {
  /// @notice EIP-20 token name for this token
  string public constant name = "Ondo";

  /// @notice EIP-20 token symbol for this token
  string public constant symbol = "ONDO";

  /// @notice EIP-20 token decimals for this token
  uint8 public constant decimals = 18;

  // whether token transfers are allowed
  bool public transferAllowed; // false by default

  /// @notice Total number of tokens in circulation
  uint256 public totalSupply = 10_000_000_000e18; // 10 billion Ondo

  // Allowance amounts on behalf of others
  mapping(address => mapping(address => uint96)) internal allowances;

  // Official record of token balances for each account
  mapping(address => uint96) internal balances;

  /// @notice A record of each accounts delegate
  mapping(address => address) public delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint96 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256(
      "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
    );

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH =
    keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice The identifier of the role which allows special transfer privileges.
  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(
    address indexed delegator,
    address indexed fromDelegate,
    address indexed toDelegate
  );

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(
    address indexed delegate,
    uint256 previousBalance,
    uint256 newBalance
  );

  /// @notice The standard EIP-20 transfer event
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /// @notice The standard EIP-20 approval event
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  event CliffTimestampUpdate(uint256 newTimestamp);

  /**
   * @dev Emitted when the transfer is enabled triggered by `account`.
   */
  event TransferEnabled(address account);

  /// @notice a modifier which checks if transfers are allowed
  modifier whenTransferAllowed() {
    require(
      transferAllowed || hasRole(TRANSFER_ROLE, msg.sender),
      "OndoToken: Transfers not allowed or not right privillege"
    );
    _;
  }

  /**
   * @notice Construct a new Ondo token
   * @param _governance The initial account to grant owner permission and all the tokens
   */
  constructor(
    address _governance,
    uint256 _cliffTimestamp,
    uint256 _tranche1VestingPeriod,
    uint256 _tranche2VestingPeriod,
    uint256 _seedVestingPeriod
  )
    LinearTimelock(
      _cliffTimestamp,
      _tranche1VestingPeriod,
      _tranche2VestingPeriod,
      _seedVestingPeriod
    )
  {
    balances[_governance] = uint96(totalSupply);
    _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    _setupRole(TRANSFER_ROLE, _governance);
    _setupRole(MINTER_ROLE, _governance);
    emit Transfer(address(0), _governance, totalSupply);
  }

  /**
   * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
   * @param account The address of the account holding the funds
   * @param spender The address of the account spending the funds
   * @return The number of tokens approved
   */
  function allowance(address account, address spender)
    external
    view
    returns (uint256)
  {
    return allowances[account][spender];
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 rawAmount) external returns (bool) {
    uint96 amount;
    if (rawAmount == type(uint256).max) {
      amount = type(uint96).max;
    } else {
      amount = safe96(rawAmount, "Ondo::approve: amount exceeds 96 bits");
    }

    allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Get the number of tokens held by the `account`
   * @param account The address of the account to get the balance of
   * @return The number of tokens held
   */
  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  /**
   * @notice Get the total number of UNLOCKED tokens held by the `account`
   * @param account The address of the account to get the unlocked balance of
   * @return The number of unlocked tokens held.
   */
  function getFreedBalance(address account) external view returns (uint256) {
    if (investorBalances[account].initialBalance > 0) {
      return _getFreedBalance(account);
    } else {
      return balances[account];
    }
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 rawAmount) external returns (bool) {
    uint96 amount = safe96(rawAmount, "Ondo::transfer: amount exceeds 96 bits");
    _transferTokens(msg.sender, dst, amount);
    return true;
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 rawAmount
  ) external returns (bool) {
    address spender = msg.sender;
    uint96 spenderAllowance = allowances[src][spender];
    uint96 amount = safe96(rawAmount, "Ondo::approve: amount exceeds 96 bits");

    if (spender != src && spenderAllowance != type(uint96).max) {
      uint96 newAllowance =
        sub96(
          spenderAllowance,
          amount,
          "Ondo::transferFrom: transfer amount exceeds spender allowance"
        );
      allowances[src][spender] = newAllowance;

      emit Approval(src, spender, newAllowance);
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegatee The address to delegate votes to
   */
  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  /**
   * @notice Delegates votes from signatory to `delegatee`
   * @param delegatee The address to delegate votes to
   * @param nonce The contract state required to match the signature
   * @param expiry The time at which to expire the signature
   * @param v The recovery byte of the signature
   * @param r Half of the ECDSA signature pair
   * @param s Half of the ECDSA signature pair
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 domainSeparator =
      keccak256(
        abi.encode(
          DOMAIN_TYPEHASH,
          keccak256(bytes(name)),
          getChainId(),
          address(this)
        )
      );
    bytes32 structHash =
      keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest =
      keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "Ondo::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "Ondo::delegateBySig: invalid nonce");
    require(
      block.timestamp <= expiry,
      "Ondo::delegateBySig: signature expired"
    );
    return _delegate(signatory, delegatee);
  }

  /**
   * @notice Gets the current votes balance for `account`
   * @param account The address to get votes balance
   * @return The number of current votes for `account`
   */
  function getCurrentVotes(address account) external view returns (uint96) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
   * @notice Determine the prior number of votes for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param account The address of the account to check
   * @param blockNumber The block number to get the vote balance at
   * @return The number of votes the account had as of the given block
   */
  function getPriorVotes(address account, uint256 blockNumber)
    public
    view
    returns (uint96)
  {
    require(
      blockNumber < block.number,
      "Ondo::getPriorVotes: not yet determined"
    );

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  /**
   * @notice Create `rawAmount` new tokens and assign them to `account`.
   * @param account The address to give newly minted tokens to
   * @param rawAmount Number of new tokens to mint.
   * @dev Even though total token supply is uint96, we use uint256 for the amount for consistency with other external interfaces.
   */
  function mint(address account, uint256 rawAmount) external {
    require(hasRole(MINTER_ROLE, msg.sender), "Ondo::mint: not authorized");
    require(account != address(0), "cannot mint to the zero address");

    uint96 amount = safe96(rawAmount, "Ondo::mint: amount exceeds 96 bits");
    uint96 supply =
      safe96(totalSupply, "Ondo::mint: totalSupply exceeds 96 bits");
    totalSupply = add96(supply, amount, "Ondo::mint: token supply overflow");
    balances[account] = add96(
      balances[account],
      amount,
      "Ondo::mint: balance overflow"
    );

    emit Transfer(address(0), account, amount);
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint96 delegatorBalance = balances[delegator];
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _transferTokens(
    address src,
    address dst,
    uint96 amount
  ) internal whenTransferAllowed {
    require(
      src != address(0),
      "Ondo::_transferTokens: cannot transfer from the zero address"
    );
    require(
      dst != address(0),
      "Ondo::_transferTokens: cannot transfer to the zero address"
    );
    if (investorBalances[src].initialBalance > 0) {
      require(
        amount <= _getFreedBalance(src),
        "Ondo::_transferTokens: not enough unlocked balance"
      );
    }

    balances[src] = sub96(
      balances[src],
      amount,
      "Ondo::_transferTokens: transfer amount exceeds balance"
    );
    balances[dst] = add96(
      balances[dst],
      amount,
      "Ondo::_transferTokens: transfer amount overflows"
    );
    emit Transfer(src, dst, amount);

    _moveDelegates(delegates[src], delegates[dst], amount);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint96 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld =
          srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint96 srcRepNew =
          sub96(srcRepOld, amount, "Ondo::_moveVotes: vote amount underflows");
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld =
          dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew =
          add96(dstRepOld, amount, "Ondo::_moveVotes: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint96 oldVotes,
    uint96 newVotes
  ) internal {
    uint32 blockNumber =
      safe32(
        block.number,
        "Ondo::_writeCheckpoint: block number exceeds 32 bits"
      );

    if (
      nCheckpoints > 0 &&
      checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
    ) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }

  /**
   * @notice Turn on _transferAllowed variable. Transfers are enabled
   */
  function enableTransfer() external {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "Ondo::enableTransfer: not authorized"
    );
    transferAllowed = true;
    emit TransferEnabled(msg.sender);
  }

  /**
   * @notice Called by merkle airdrop contract to initialize locked balances
   */
  function updateTrancheBalance(
    address beneficiary,
    uint256 rawAmount,
    IOndo.InvestorType investorType
  ) external {
    require(hasRole(TIMELOCK_UPDATE_ROLE, msg.sender));
    require(rawAmount > 0, "Ondo::updateTrancheBalance: amount must be > 0");
    require(
      investorBalances[beneficiary].initialBalance == 0,
      "Ondo::updateTrancheBalance: already has timelocked Ondo"
    ); //Prevents users from being in more than 1 tranche

    uint96 amount =
      safe96(rawAmount, "Ondo::updateTrancheBalance: amount exceeds 96 bits");
    investorBalances[beneficiary] = InvestorParam(investorType, amount);
  }

  /**
   * @notice Internal function the amount of unlocked Ondo for an account that participated in Coinlist/Seed Investments
   */
  function _getFreedBalance(address account) internal view returns (uint96) {
    if (passedAllVestingPeriods()) {
      //all vesting periods are over, just return the total balance
      return balances[account];
    } else {
      InvestorParam memory investorParam = investorBalances[account];
      if (passedCliff()) {
        //we are in between the cliff timestamp and last vesting period
        (uint256 vestingPeriod, uint256 elapsed) =
          _getTrancheInfo(investorParam.investorType);
        uint96 lockedBalance =
          sub96(
            investorParam.initialBalance,
            _proportionAvailable(elapsed, vestingPeriod, investorParam),
            "Ondo::getFreedBalance: locked balance underflow"
          );
        return
          sub96(
            balances[account],
            lockedBalance,
            "Ondo::getFreedBalance: total freed balance underflow"
          );
      } else {
        //we have not hit the cliff yet, all investor balance is locked
        return
          sub96(
            balances[account],
            investorParam.initialBalance,
            "Ondo::getFreedBalance: balance underflow"
          );
      }
    }
  }

  function updateCliffTimestamp(uint256 newTimestamp) external {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "Ondo::updateCliffTimestamp: not authorized"
    );
    cliffTimestamp = newTimestamp;
    emit CliffTimestampUpdate(newTimestamp);
  }
}