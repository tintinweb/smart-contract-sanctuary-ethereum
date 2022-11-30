// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IStablecoinEngine.sol";
import "./interfaces/IMintableBurnableERC20.sol";
import "./interfaces/ITreasury.sol";

import "./external/IUniswapV2Factory.sol";
import "./external/IUniswapV2Pair.sol";
import "./external/UniswapV2Library.sol";

/// @title StablecoinEngine
/// @author Bluejay Core Team
/// @notice StablecoinEngine controls the supply of stablecoins and manages
/// liquidity pools for the stablecoins and their reserve assets.
contract StablecoinEngine is AccessControl, IStablecoinEngine {
  using SafeERC20 for IERC20;
  using SafeERC20 for IMintableBurnableERC20;

  uint256 private constant WAD = 10**18;

  /// @notice Role for initializing new pools and managing liquidity
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @notice Role for performing swap on Uniswap v2 Pairs
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /// @notice Role for minting stablecoins
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /// @notice Contract address of the treasury
  ITreasury public immutable treasury;

  /// @notice Contract address of the Uniswap V2 Factory
  IUniswapV2Factory public immutable poolFactory;

  /// @notice Mapping of reserve assets to stablecoins to the Uniswap V2 pools
  /// @dev pools[reserve][stablecoin] = liquidityPoolAddress
  mapping(address => mapping(address => address)) public override pools;

  /// @notice Mapping of Uniswap V2 Pair addresses to their information
  /// @dev poolsInfo[liquidityPoolAddress] = StablecoinPoolInfo
  mapping(address => StablecoinPoolInfo) public override poolsInfo;

  /// @notice Checks if pool has been initialized
  modifier ifPoolExists(address pool) {
    require(poolsInfo[pool].reserve != address(0), "Pool has not been added");
    _;
  }

  /// @notice Checks if pool has not been initialized
  modifier onlyUninitializedPool(address reserve, address stablecoin) {
    require(
      pools[reserve][stablecoin] == address(0),
      "Pool already initialized"
    );
    _;
  }

  /// @notice Constructor to initialize the contract
  /// @param _treasury Address of the treasury contract
  /// @param factory Address of the Uniswap V2 Factory contract
  constructor(address _treasury, address factory) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    treasury = ITreasury(_treasury);
    poolFactory = IUniswapV2Factory(factory);
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function to store intormation about a pool
  /// @param reserve Address of the reserve asset
  /// @param stablecoin Address of the stablecoin
  /// @param pool Address of the Uniswap V2 pool
  function _storePoolInfo(
    address reserve,
    address stablecoin,
    address pool
  ) internal {
    (address token0, ) = UniswapV2Library.sortTokens(stablecoin, reserve);
    pools[reserve][stablecoin] = pool;
    poolsInfo[pool] = StablecoinPoolInfo({
      reserve: reserve,
      stablecoin: stablecoin,
      pool: pool,
      stablecoinIsToken0: token0 == stablecoin
    });
    emit PoolAdded(reserve, stablecoin, pool);
  }

  /// @notice Internal function to add liquidity to a pool using reserve assets from treasury
  /// and minting matching amount of stablecoins.
  /// @dev Function assumes that safety checks have been performed, use `calculateAmounts` to
  /// get exact amount of reserve and stablecoin to add to the pool.
  /// @param pool Address of the Uniswap V2 pool
  /// @param reserveAmount Amount of reserve assets to add to the pool
  /// @param stablecoinAmount Amount of stablecoins to add to the pool
  /// @return liquidity Amount of LP tokens sent to treasury
  function _addLiquidity(
    address pool,
    uint256 reserveAmount,
    uint256 stablecoinAmount
  ) internal ifPoolExists(pool) returns (uint256 liquidity) {
    StablecoinPoolInfo memory info = poolsInfo[pool];
    IMintableBurnableERC20(info.stablecoin).mint(pool, stablecoinAmount);
    treasury.withdraw(info.reserve, pool, reserveAmount);
    liquidity = IUniswapV2Pair(pool).mint(address(treasury));
    emit LiquidityAdded(pool, liquidity, reserveAmount, stablecoinAmount);
  }

  /// @notice Internal function to remove liquidity from a pool, sending reserves to treasury
  /// and burning stablecoins.
  /// @param pool Address of the Uniswap V2 pool
  /// @param liquidity Amount of LP tokens to burn
  /// @return reserveAmount Amount of reserve assets sent to treasury
  /// @return stablecoinAmount Amount of stablecoins burned
  function _removeLiquidity(address pool, uint256 liquidity)
    internal
    ifPoolExists(pool)
    returns (uint256 reserveAmount, uint256 stablecoinAmount)
  {
    StablecoinPoolInfo memory info = poolsInfo[pool];
    treasury.withdraw(pool, pool, liquidity);
    IUniswapV2Pair(pool).burn(address(this));
    stablecoinAmount = IMintableBurnableERC20(info.stablecoin).balanceOf(
      address(this)
    );
    IMintableBurnableERC20(info.stablecoin).burn(stablecoinAmount);
    reserveAmount = IERC20(info.reserve).balanceOf(address(this));
    IERC20(info.reserve).safeTransfer(address(treasury), reserveAmount);
    emit LiquidityRemoved(pool, liquidity, reserveAmount, stablecoinAmount);
  }

  // =============================== MANAGER FUNCTIONS =================================

  /// @notice Create a new stablecoin pool and add it to the engine
  /// @dev Stablecoin minting and reserve asset withdrawal permission should be set before
  /// calling this function. This function will run even if the pool has already been
  /// created from the factory, but liquidity will not be added to the pool.
  /// @param reserve Address of the reserve asset
  /// @param stablecoin Address of the stablecoin
  /// @param initialReserveAmount Initial amount of reserve to add to pool
  /// @param initialStablecoinAmount Initial amount of stablecoins to add to pool
  /// @return poolAddress Address of the created pool
  function initializeStablecoin(
    address reserve,
    address stablecoin,
    uint256 initialReserveAmount,
    uint256 initialStablecoinAmount
  )
    public
    override
    onlyRole(MANAGER_ROLE)
    onlyUninitializedPool(reserve, stablecoin)
    returns (address poolAddress)
  {
    poolAddress = poolFactory.getPair(reserve, stablecoin);
    if (poolAddress == address(0)) {
      poolAddress = poolFactory.createPair(reserve, stablecoin);
      _storePoolInfo(reserve, stablecoin, poolAddress);
      _addLiquidity(poolAddress, initialReserveAmount, initialStablecoinAmount);
    } else {
      _storePoolInfo(reserve, stablecoin, poolAddress);
    }
  }

  /// @notice Add liquidity to an initialized pool
  /// @dev The exact amount of reserve and stablecoin to add to the pool is calculated
  /// when the function is executed. To prevent liquidity sniping, call this function
  /// with tight slippage and relay the call via private pools.
  /// @param pool Address of the Uniswap V2 pool
  /// @param reserveAmountDesired Desired amount of reserve assets to add to the pool
  /// @param stablecoinAmountDesired Desired amount of stablecoins to add to the pool
  /// @param reserveAmountMin Minimum amount of reserve assets to add after slippage
  /// @param stablecoinAmountMin Maximum amount of stablecoins to add after slippage
  /// @return liquidity Amount of LP tokens sent to treasury
  function addLiquidity(
    address pool,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  )
    public
    override
    onlyRole(MANAGER_ROLE)
    ifPoolExists(pool)
    returns (uint256)
  {
    (uint256 reserveAmount, uint256 stablecoinAmount) = calculateAmounts(
      pool,
      reserveAmountDesired,
      stablecoinAmountDesired,
      reserveAmountMin,
      stablecoinAmountMin
    );
    return _addLiquidity(pool, reserveAmount, stablecoinAmount);
  }

  /// @notice Remove liquidity from an initialized pool
  /// @dev To prevent liquidity sniping, call this function with tight slippage
  /// and relay the call via private pools.
  /// @param pool Address of the Uniswap V2 pool
  /// @param liquidity Amount of LP tokens to remove from the pool
  /// @param minimumReserveAmount Minimum amount of reserve assets sent to treasury
  /// @param minimumStablecoinAmount Minimum amount of stablecoins burned
  /// @return reserveAmount Amount of reserve assets sent to treasury
  /// @return stablecoinAmount Amount of stablecoins burned
  function removeLiquidity(
    address pool,
    uint256 liquidity,
    uint256 minimumReserveAmount,
    uint256 minimumStablecoinAmount
  )
    public
    override
    onlyRole(MANAGER_ROLE)
    ifPoolExists(pool)
    returns (uint256 reserveAmount, uint256 stablecoinAmount)
  {
    (reserveAmount, stablecoinAmount) = _removeLiquidity(pool, liquidity);
    require(reserveAmount >= minimumReserveAmount, "Insufficient reserve");
    require(
      stablecoinAmount >= minimumStablecoinAmount,
      "Insufficient stablecoin"
    );
  }

  // =============================== OPERATOR FUNCTIONS =================================

  /// @notice Perform a swap with an initialized pool using reserve assets from treasury
  /// @dev Ensure that the operator role is only given to trusted parties that perform
  /// checks when swapping to prevent misuse.
  /// @param poolAddr Address of the Uniswap V2 pool
  /// @param amountIn Amount of stablecoins or reserve assets to swap, specified by `stablecoinForReserve`
  /// @param minAmountOut Minimum output of reserve assets or stablecoins to limit slippage
  /// @param stablecoinForReserve True if swapping from stablecoin to reserve, false otherwise
  /// @return amountOut Amount of reserve assets received or stablecoins burned
  function swap(
    address poolAddr,
    uint256 amountIn,
    uint256 minAmountOut,
    bool stablecoinForReserve
  )
    public
    override
    onlyRole(OPERATOR_ROLE)
    ifPoolExists(poolAddr)
    returns (uint256 amountOut)
  {
    StablecoinPoolInfo memory info = poolsInfo[poolAddr];
    IUniswapV2Pair pool = IUniswapV2Pair(poolAddr);
    (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();
    bool zeroForOne = stablecoinForReserve == info.stablecoinIsToken0;
    amountOut = UniswapV2Library.getAmountOut(
      amountIn,
      zeroForOne ? reserve0 : reserve1,
      zeroForOne ? reserve1 : reserve0
    );
    require(amountOut >= minAmountOut, "Insufficient output");

    if (stablecoinForReserve) {
      IMintableBurnableERC20(info.stablecoin).mint(poolAddr, amountIn);
    } else {
      treasury.withdraw(info.reserve, poolAddr, amountIn);
    }
    pool.swap(
      zeroForOne ? 0 : amountOut,
      zeroForOne ? amountOut : 0,
      stablecoinForReserve ? address(treasury) : address(this),
      new bytes(0)
    );

    if (!stablecoinForReserve) {
      IMintableBurnableERC20(info.stablecoin).burn(amountOut);
    }
    emit Swap(poolAddr, amountIn, amountOut, stablecoinForReserve);
  }

  // =============================== MINTER FUNCTIONS =================================

  /// @notice Mint stablecoins directly using the engine, for modules like PSMs in the future
  /// @dev Ensure that the minter role is only given to trusted parties that perform
  /// necessary checks.
  /// @param stablecoin Address of stablecoin to mint
  /// @param to Address of recipient
  /// @param amount Amount of stablecoins to mint
  function mint(
    address stablecoin,
    address to,
    uint256 amount
  ) public override onlyRole(MINTER_ROLE) {
    IMintableBurnableERC20(stablecoin).mint(to, amount);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Calculate the exact amount of liquidity to add to a pool
  /// https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/UniswapV2Router02.sol#L33
  /// @param reserveAmountDesired Desired amount of reserve assets to add to the pool
  /// @param stablecoinAmountDesired Desired amount of stablecoins to add to the pool
  /// @param reserveAmountMin Minimum amount of reserve assets to add after slippage
  /// @param stablecoinAmountMin Minimum amount of stablecoins to add after slippage
  /// @return reserveAmount Exact amount of reserve assets to add
  /// @return stablecoinAmount Exact amount of stablecoins to add
  function calculateAmounts(
    address poolAddr,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  )
    public
    view
    override
    returns (uint256 reserveAmount, uint256 stablecoinAmount)
  {
    IUniswapV2Pair pool = IUniswapV2Pair(poolAddr);
    (uint256 reserve0, uint256 reserve1, ) = pool.getReserves();

    if (reserve0 == 0 && reserve1 == 0) {
      (reserveAmount, stablecoinAmount) = (
        reserveAmountDesired,
        stablecoinAmountDesired
      );
    } else {
      StablecoinPoolInfo memory info = poolsInfo[poolAddr];
      uint256 stablecoinAmountOptimal = info.stablecoinIsToken0
        ? (reserveAmountDesired * reserve0) / reserve1
        : (reserveAmountDesired * reserve1) / reserve0;

      if (stablecoinAmountOptimal <= stablecoinAmountDesired) {
        require(
          stablecoinAmountOptimal >= stablecoinAmountMin,
          "Insufficient stablecoin"
        );
        (reserveAmount, stablecoinAmount) = (
          reserveAmountDesired,
          stablecoinAmountOptimal
        );
      } else {
        uint256 reserveAmountOptimal = info.stablecoinIsToken0
          ? (stablecoinAmountDesired * reserve1) / reserve0
          : (stablecoinAmountDesired * reserve0) / reserve1;
        require(
          reserveAmountOptimal <= reserveAmountDesired,
          "Excessive reserve"
        );
        require(
          reserveAmountOptimal >= reserveAmountMin,
          "Insufficient reserve"
        );
        (reserveAmount, stablecoinAmount) = (
          reserveAmountOptimal,
          stablecoinAmountDesired
        );
      }
    }
  }

  /// @notice Utility function to fetch and sort reserves from a pool
  /// @param poolAddr Address of the Uniswap V2 pool
  /// @return stablecoinReserve Amount of stablecoins on the pool
  /// @return reserveReserve Amount of reserve assets on the pool
  function getReserves(address poolAddr)
    public
    view
    override
    returns (uint256 stablecoinReserve, uint256 reserveReserve)
  {
    IUniswapV2Pair pool = IUniswapV2Pair(poolAddr);
    StablecoinPoolInfo memory info = poolsInfo[poolAddr];
    (reserveReserve, stablecoinReserve, ) = pool.getReserves();
    if (info.stablecoinIsToken0) {
      (reserveReserve, stablecoinReserve) = (stablecoinReserve, reserveReserve);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
pragma solidity ^0.8.4;

interface IStablecoinEngine {
  struct StablecoinPoolInfo {
    address reserve;
    address stablecoin;
    address pool;
    bool stablecoinIsToken0;
  }

  function pools(address reserve, address stablecoin)
    external
    view
    returns (address pool);

  function poolsInfo(address _pool)
    external
    view
    returns (
      address reserve,
      address stablecoin,
      address pool,
      bool stablecoinIsToken0
    );

  function initializeStablecoin(
    address reserve,
    address stablecoin,
    uint256 initialReserveAmount,
    uint256 initialStablecoinAmount
  ) external returns (address poolAddress);

  function addLiquidity(
    address pool,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  ) external returns (uint256 liquidity);

  function removeLiquidity(
    address pool,
    uint256 liquidity,
    uint256 minimumReserveAmount,
    uint256 minimumStablecoinAmount
  ) external returns (uint256 reserveAmount, uint256 stablecoinAmount);

  function swap(
    address poolAddr,
    uint256 amountIn,
    uint256 minAmountOut,
    bool stablecoinForReserve
  ) external returns (uint256 amountOut);

  function mint(
    address stablecoin,
    address to,
    uint256 amount
  ) external;

  function calculateAmounts(
    address poolAddr,
    uint256 reserveAmountDesired,
    uint256 stablecoinAmountDesired,
    uint256 reserveAmountMin,
    uint256 stablecoinAmountMin
  ) external view returns (uint256 reserveAmount, uint256 stablecoinAmount);

  function getReserves(address poolAddr)
    external
    view
    returns (uint256 stablecoinReserve, uint256 reserveReserve);

  event PoolAdded(
    address indexed reserve,
    address indexed stablecoin,
    address indexed pool
  );
  event LiquidityAdded(
    address indexed pool,
    uint256 liquidity,
    uint256 reserve,
    uint256 stablecoin
  );
  event LiquidityRemoved(
    address indexed pool,
    uint256 liquidity,
    uint256 reserve,
    uint256 stablecoin
  );
  event Swap(
    address indexed pool,
    uint256 amountIn,
    uint256 amountOut,
    bool stablecoinForReserve
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IMintableBurnableERC20 is IERC20 {
  function mint(address _to, uint256 _amount) external;

  function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
  function mint(address to, uint256 amount) external;

  function withdraw(
    address token,
    address to,
    uint256 amount
  ) external;

  function increaseMintLimit(address minter, uint256 amount) external;

  function decreaseMintLimit(address minter, uint256 amount) external;

  function increaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  function decreaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  event Mint(address indexed to, uint256 amount);
  event Withdraw(address indexed token, address indexed to, uint256 amount);
  event MintLimitUpdate(address indexed minter, uint256 amount);
  event WithdrawLimitUpdate(
    address indexed token,
    address indexed minter,
    uint256 amount
  );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Factory.sol
pragma solidity ^0.8.4;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IUniswapV2Pair is IERC20 {
  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";

library UniswapV2Library {
  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
            )
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
      pairFor(factory, tokenA, tokenB)
    ).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = (amountA * reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn * 997;
    uint256 numerator = amountInWithFee * reserveOut;
    uint256 denominator = (reserveIn * 1000) + amountInWithFee;
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn * amountOut * 1000;
    uint256 denominator = (reserveOut - amountOut) * 997;
    amountIn = (numerator / denominator) + 1;
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i],
        path[i + 1]
      );
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i - 1],
        path[i]
      );
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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