// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '../interfaces/IDCAFeeManager.sol';

contract DCAFeeManager is RunSwap, AccessControl, Multicall, IDCAFeeManager {
  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  using SafeERC20 for IERC20;
  using Address for address payable;

  /// @inheritdoc IDCAFeeManager
  uint16 public constant MAX_TOKEN_TOTAL_SHARE = 10000;
  /// @inheritdoc IDCAFeeManager
  uint32 public constant SWAP_INTERVAL = 1 days;
  /// @inheritdoc IDCAFeeManager
  mapping(bytes32 => uint256) public positions; // key(from, to) => position id

  mapping(address => uint256[]) internal _positionsWithToken; // token address => all positions with address as to

  constructor(
    address _swapperRegistry,
    address _superAdmin,
    address[] memory _initialAdmins
  ) SwapAdapter(_swapperRegistry) {
    if (_superAdmin == address(0)) revert ZeroAddress();
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);
    for (uint256 i; i < _initialAdmins.length; i++) {
      _setupRole(ADMIN_ROLE, _initialAdmins[i]);
    }
  }

  /// @inheritdoc IDCAFeeManager
  function runSwap(RunSwapParams calldata _parameters) public payable override(IDCAFeeManager, RunSwap) onlyRole(ADMIN_ROLE) {
    super.runSwap(_parameters);
  }

  /// @inheritdoc IDCAFeeManager
  function withdrawFromPlatformBalance(
    IDCAHub _hub,
    IDCAHub.AmountOfToken[] calldata _amountToWithdraw,
    address _recipient
  ) external onlyRole(ADMIN_ROLE) {
    _hub.withdrawFromPlatformBalance(_amountToWithdraw, _recipient);
  }

  /// @inheritdoc IDCAFeeManager
  function withdrawFromBalance(IDCAHub.AmountOfToken[] calldata _amountToWithdraw, address _recipient) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _amountToWithdraw.length; ) {
      IDCAHub.AmountOfToken memory _amountOfToken = _amountToWithdraw[i];
      _sendToRecipient(_amountOfToken.token, _amountOfToken.amount, _recipient);
      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IDCAFeeManager
  function withdrawFromPositions(
    IDCAHub _hub,
    IDCAHub.PositionSet[] calldata _positionSets,
    address _recipient
  ) external onlyRole(ADMIN_ROLE) {
    _hub.withdrawSwappedMany(_positionSets, _recipient);
  }

  /// @inheritdoc IDCAFeeManager
  function fillPositions(
    IDCAHub _hub,
    AmountToFill[] calldata _amounts,
    TargetTokenShare[] calldata _distribution
  ) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _amounts.length; ) {
      AmountToFill memory _amount = _amounts[i];

      _maxApproveSpenderIfNeeded(
        IERC20(_amount.token),
        address(_hub),
        true, // No need to check if the hub is a valid allowance target
        _amount.amount
      );

      // Distribute to different tokens
      uint256 _amountSpent;
      for (uint256 j = 0; j < _distribution.length; ) {
        uint256 _amountToDeposit = j < _distribution.length - 1
          ? (_amount.amount * _distribution[j].shares) / MAX_TOKEN_TOTAL_SHARE
          : _amount.amount - _amountSpent; // If this is the last token, then assign everything that hasn't been spent. We do this to prevent unspent tokens due to rounding errors

        bool _failed = _depositToHub(_hub, _amount.token, _distribution[j].token, _amountToDeposit, _amount.amountOfSwaps);
        if (!_failed) {
          _amountSpent += _amountToDeposit;
        }
        unchecked {
          j++;
        }
      }
      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IDCAFeeManager
  function terminatePositions(
    IDCAHub _hub,
    uint256[] calldata _positionIds,
    address _recipient
  ) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _positionIds.length; ) {
      uint256 _positionId = _positionIds[i];
      IDCAHubPositionHandler.UserPosition memory _position = _hub.userPosition(_positionId);
      _hub.terminate(_positionId, _recipient, _recipient);
      delete positions[getPositionKey(address(_position.from), address(_position.to))];
      unchecked {
        i++;
      }
    }
  }

  /// @inheritdoc IDCAFeeManager
  function revokeAllowances(RevokeAction[] calldata _revokeActions) external onlyRole(ADMIN_ROLE) {
    _revokeAllowances(_revokeActions);
  }

  /// @inheritdoc IDCAFeeManager
  function availableBalances(IDCAHub _hub, address[] calldata _tokens) external view returns (AvailableBalance[] memory _balances) {
    _balances = new AvailableBalance[](_tokens.length);
    for (uint256 i = 0; i < _tokens.length; i++) {
      address _token = _tokens[i];
      uint256[] memory _positionIds = _positionsWithToken[_token];
      PositionBalance[] memory _positions = new PositionBalance[](_positionIds.length);
      for (uint256 j = 0; j < _positionIds.length; j++) {
        IDCAHubPositionHandler.UserPosition memory _userPosition = _hub.userPosition(_positionIds[j]);
        _positions[j] = PositionBalance({
          positionId: _positionIds[j],
          from: _userPosition.from,
          to: _userPosition.to,
          swapped: _userPosition.swapped,
          remaining: _userPosition.remaining
        });
      }
      _balances[i] = AvailableBalance({
        token: _token,
        platformBalance: _hub.platformBalance(_token),
        feeManagerBalance: IERC20(_token).balanceOf(address(this)),
        positions: _positions
      });
    }
  }

  function getPositionKey(address _from, address _to) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_from, _to));
  }

  function _depositToHub(
    IDCAHub _hub,
    address _from,
    address _to,
    uint256 _amount,
    uint32 _amountOfSwaps
  ) internal returns (bool _failed) {
    // We will try to create or increase an existing position, but both could fail. Maybe one of the tokens is no longer
    // allowed, or a pair not supported, so we need to check if it fails or not and act accordingly

    // Find the position for this token
    bytes32 _key = getPositionKey(_from, _to);
    uint256 _positionId = positions[_key];

    if (_positionId == 0) {
      // If position doesn't exist, then try to create it
      try _hub.deposit(_from, _to, _amount, _amountOfSwaps, SWAP_INTERVAL, address(this), new IDCAPermissionManager.PermissionSet[](0)) returns (
        uint256 _newPositionId
      ) {
        positions[_key] = _newPositionId;
        _positionsWithToken[_to].push(_newPositionId);
      } catch {
        _failed = true;
      }
    } else {
      // If position exists, then try to increase it
      try _hub.increasePosition(_positionId, _amount, _amountOfSwaps) {} catch {
        _failed = true;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@mean-finance/dca-v2-core/contracts/interfaces/IDCAHub.sol';
import '@mean-finance/swappers/solidity/contracts/extensions/RunSwap.sol';

/**
 * @title DCA Fee Manager
 * @notice This contract will manage all platform fees. Since fees come in different tokens, this manager
 *         will be in charge of taking them and converting them to different tokens, for example ETH/MATIC
 *         or stablecoins. Allowed users will to withdraw fees as generated, or DCA them into tokens
 *         of their choosing
 */
interface IDCAFeeManager {
  /// @notice Represents a share of a target token
  struct TargetTokenShare {
    address token;
    uint16 shares;
  }

  /// @notice Represents how much to deposit to a position, for a specific token
  struct AmountToFill {
    address token;
    uint32 amountOfSwaps;
    uint256 amount;
  }

  /// @notice Represents how much is available for withdraw, for a specific token
  struct AvailableBalance {
    address token;
    uint256 platformBalance;
    uint256 feeManagerBalance;
    PositionBalance[] positions;
  }

  /// @notice Represents information about a specific position
  struct PositionBalance {
    uint256 positionId;
    IERC20Metadata from;
    IERC20Metadata to;
    uint256 swapped;
    uint256 remaining;
  }

  /**
   * @notice The contract's owner and other allowed users can specify the target tokens that the fees
   *         should be converted to. They can also specify the percentage assigned to each token
   * @dev This value is constant and cannot be modified
   * @return The numeric value that represents a 100% asignment for the fee conversion distribution
   */
  // solhint-disable-next-line func-name-mixedcase
  function MAX_TOKEN_TOTAL_SHARE() external view returns (uint16);

  /**
   * @notice Returns the swap interval used for DCA swaps
   * @dev This value is constant and cannot be modified
   * @return The swap interval used for DCA swaps
   */
  // solhint-disable-next-line func-name-mixedcase
  function SWAP_INTERVAL() external view returns (uint32);

  /**
   * @notice Returns the position id for a given (from, to) pair
   * @dev Key for (tokenA, tokenB) is different from the key for(tokenB, tokenA)
   * @param pairKey The key of the pair (from, to)
   * @return The position id for the given pair
   */
  function positions(bytes32 pairKey) external view returns (uint256); // key(from, to) => position id

  /**
   * @notice Executes a swap with the given swapper. The input tokens are expected to be on the contract before
   *         this function is executed. If the swap doesn't include a transfer, then the swapped tokens will be left
   *         on the contract
   * @dev This function can only be executed with swappers that are allowlisted. Can only be executed by admins
   * @param parameters The parameters for the swap
   */
  function runSwap(RunSwap.RunSwapParams calldata parameters) external payable;

  /**
   * @notice Withdraws tokens from the platform balance, and sends them to the given recipient
   * @dev Can only be executed by admins
   * @param hub The address of the DCA Hub
   * @param amountToWithdraw The tokens to withdraw, and their amounts
   * @param recipient The address of the recipient
   */
  function withdrawFromPlatformBalance(
    IDCAHub hub,
    IDCAHub.AmountOfToken[] calldata amountToWithdraw,
    address recipient
  ) external;

  /**
   * @notice Withdraws tokens from the contract's balance, and sends them to the given recipient
   * @dev Can only be executed by admins
   * @param amountToWithdraw The tokens to withdraw, and their amounts
   * @param recipient The address of the recipient
   */
  function withdrawFromBalance(IDCAHub.AmountOfToken[] calldata amountToWithdraw, address recipient) external;

  /**
   * @notice Withdraws tokens from the given positions, and sends them to the given recipient
   * @dev Can only be executed by admins
   * @param hub The address of the DCA Hub
   * @param positionSets The positions to withdraw from
   * @param recipient The address of the recipient
   */
  function withdrawFromPositions(
    IDCAHub hub,
    IDCAHub.PositionSet[] calldata positionSets,
    address recipient
  ) external;

  /**
   * @notice Takes a certain amount of the given tokens, and sets up DCA swaps for each of them.
   *         The given amounts can be distributed across different target tokens
   * @dev Can only be executed by admins
   * @param hub The address of the DCA Hub
   * @param amounts Specific tokens and amounts to take from this contract and send to the hub
   * @param distribution How to distribute the source tokens across different target tokens
   */
  function fillPositions(
    IDCAHub hub,
    AmountToFill[] calldata amounts,
    TargetTokenShare[] calldata distribution
  ) external;

  /**
   * @notice Takes list of position ids and terminates them. All swapped and unswapped balance is
   *         sent to the given recipient. This is meant to be used only if for some reason swaps are
   *         no longer executed
   * @dev Can only be executed by admins
   * @param hub The address of the DCA Hub
   * @param positionIds The positions to terminate
   * @param recipient The address that will receive all swapped and unswapped tokens
   */
  function terminatePositions(
    IDCAHub hub,
    uint256[] calldata positionIds,
    address recipient
  ) external;

  /**
   * @notice Revokes ERC20 allowances for the given spenders
   * @dev Can only be executed by admins
   * @param revokeActions The spenders and tokens to revoke
   */
  function revokeAllowances(ISwapAdapter.RevokeAction[] calldata revokeActions) external;

  /**
   * @notice Returns how much is available for withdraw, for the given tokens
   * @dev This is meant for off-chan purposes
   * @param hub The address of the DCA Hub
   * @param tokens The tokens to check the balance for
   * @return How much is available for withdraw, for the given tokens
   */
  function availableBalances(IDCAHub hub, address[] calldata tokens) external view returns (AvailableBalance[] memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@mean-finance/oracles/solidity/interfaces/ITokenPriceOracle.sol';
import './IDCAPermissionManager.sol';

/**
 * @title The interface for all state related queries
 * @notice These methods allow users to read the hubs's current values
 */
interface IDCAHubParameters {
  /**
   * @notice Returns how much will the amount to swap differ from the previous swap. f.e. if the returned value is -100, then the amount to swap will be 100 less than the swap just before it
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @param swapNumber The swap number to check
   * @return swapDeltaAToB How much less of token A will the following swap require
   * @return swapDeltaBToA How much less of token B will the following swap require
   */
  function swapAmountDelta(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask,
    uint32 swapNumber
  ) external view returns (uint128 swapDeltaAToB, uint128 swapDeltaBToA);

  /**
   * @notice Returns the sum of the ratios reported in all swaps executed until the given swap number
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @param swapNumber The swap number to check
   * @return accumRatioAToB The sum of all ratios from A to B
   * @return accumRatioBToA The sum of all ratios from B to A
   */
  function accumRatio(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask,
    uint32 swapNumber
  ) external view returns (uint256 accumRatioAToB, uint256 accumRatioBToA);

  /**
   * @notice Returns swapping information about a specific pair
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA One of the pair's token
   * @param tokenB The other of the pair's token
   * @param swapIntervalMask The byte representation of the swap interval to check
   * @return performedSwaps How many swaps have been executed
   * @return nextAmountToSwapAToB How much of token A will be swapped on the next swap
   * @return lastSwappedAt Timestamp of the last swap
   * @return nextAmountToSwapBToA How much of token B will be swapped on the next swap
   */
  function swapData(
    address tokenA,
    address tokenB,
    bytes1 swapIntervalMask
  )
    external
    view
    returns (
      uint32 performedSwaps,
      uint224 nextAmountToSwapAToB,
      uint32 lastSwappedAt,
      uint224 nextAmountToSwapBToA
    );

  /**
   * @notice Returns the byte representation of the set of actice swap intervals for the given pair
   * @dev `tokenA` must be smaller than `tokenB` (tokenA < tokenB)
   * @param tokenA The smaller of the pair's token
   * @param tokenB The other of the pair's token
   * @return The byte representation of the set of actice swap intervals
   */
  function activeSwapIntervals(address tokenA, address tokenB) external view returns (bytes1);

  /**
   * @notice Returns how much of the hub's token balance belongs to the platform
   * @param token The token to check
   * @return The amount that belongs to the platform
   */
  function platformBalance(address token) external view returns (uint256);
}

/**
 * @title The interface for all position related matters
 * @notice These methods allow users to create, modify and terminate their positions
 */
interface IDCAHubPositionHandler {
  /// @notice The position of a certain user
  struct UserPosition {
    // The token that the user deposited and will be swapped in exchange for "to"
    IERC20Metadata from;
    // The token that the user will get in exchange for their "from" tokens in each swap
    IERC20Metadata to;
    // How frequently the position's swaps should be executed
    uint32 swapInterval;
    // How many swaps were executed since deposit, last modification, or last withdraw
    uint32 swapsExecuted;
    // How many "to" tokens can currently be withdrawn
    uint256 swapped;
    // How many swaps left the position has to execute
    uint32 swapsLeft;
    // How many "from" tokens there are left to swap
    uint256 remaining;
    // How many "from" tokens need to be traded in each swap
    uint120 rate;
  }

  /// @notice A list of positions that all have the same `to` token
  struct PositionSet {
    // The `to` token
    address token;
    // The position ids
    uint256[] positionIds;
  }

  /**
   * @notice Emitted when a position is terminated
   * @param user The address of the user that terminated the position
   * @param recipientUnswapped The address of the user that will receive the unswapped tokens
   * @param recipientSwapped The address of the user that will receive the swapped tokens
   * @param positionId The id of the position that was terminated
   * @param returnedUnswapped How many "from" tokens were returned to the caller
   * @param returnedSwapped How many "to" tokens were returned to the caller
   */
  event Terminated(
    address indexed user,
    address indexed recipientUnswapped,
    address indexed recipientSwapped,
    uint256 positionId,
    uint256 returnedUnswapped,
    uint256 returnedSwapped
  );

  /**
   * @notice Emitted when a position is created
   * @param depositor The address of the user that creates the position
   * @param owner The address of the user that will own the position
   * @param positionId The id of the position that was created
   * @param fromToken The address of the "from" token
   * @param toToken The address of the "to" token
   * @param swapInterval How frequently the position's swaps should be executed
   * @param rate How many "from" tokens need to be traded in each swap
   * @param startingSwap The number of the swap when the position will be executed for the first time
   * @param lastSwap The number of the swap when the position will be executed for the last time
   * @param permissions The permissions defined for the position
   */
  event Deposited(
    address indexed depositor,
    address indexed owner,
    uint256 positionId,
    address fromToken,
    address toToken,
    uint32 swapInterval,
    uint120 rate,
    uint32 startingSwap,
    uint32 lastSwap,
    IDCAPermissionManager.PermissionSet[] permissions
  );

  /**
   * @notice Emitted when a position is created and extra data is provided
   * @param positionId The id of the position that was created
   * @param data The extra data that was provided
   */
  event Miscellaneous(uint256 positionId, bytes data);

  /**
   * @notice Emitted when a user withdraws all swapped tokens from a position
   * @param withdrawer The address of the user that executed the withdraw
   * @param recipient The address of the user that will receive the withdrawn tokens
   * @param positionId The id of the position that was affected
   * @param token The address of the withdrawn tokens. It's the same as the position's "to" token
   * @param amount The amount that was withdrawn
   */
  event Withdrew(address indexed withdrawer, address indexed recipient, uint256 positionId, address token, uint256 amount);

  /**
   * @notice Emitted when a user withdraws all swapped tokens from many positions
   * @param withdrawer The address of the user that executed the withdraws
   * @param recipient The address of the user that will receive the withdrawn tokens
   * @param positions The positions to withdraw from
   * @param withdrew The total amount that was withdrawn from each token
   */
  event WithdrewMany(address indexed withdrawer, address indexed recipient, PositionSet[] positions, uint256[] withdrew);

  /**
   * @notice Emitted when a position is modified
   * @param user The address of the user that modified the position
   * @param positionId The id of the position that was modified
   * @param rate How many "from" tokens need to be traded in each swap
   * @param startingSwap The number of the swap when the position will be executed for the first time
   * @param lastSwap The number of the swap when the position will be executed for the last time
   */
  event Modified(address indexed user, uint256 positionId, uint120 rate, uint32 startingSwap, uint32 lastSwap);

  /// @notice Thrown when a user tries to create a position with the same `from` & `to`
  error InvalidToken();

  /// @notice Thrown when a user tries to create a position with a swap interval that is not allowed
  error IntervalNotAllowed();

  /// @notice Thrown when a user tries operate on a position that doesn't exist (it might have been already terminated)
  error InvalidPosition();

  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();

  /// @notice Thrown when a user tries to create a position with zero swaps
  error ZeroSwaps();

  /// @notice Thrown when a user tries to create a position with zero funds
  error ZeroAmount();

  /// @notice Thrown when a user tries to withdraw a position whose `to` token doesn't match the specified one
  error PositionDoesNotMatchToken();

  /// @notice Thrown when a user tries create or modify a position with an amount too big
  error AmountTooBig();

  /**
   * @notice Returns the permission manager contract
   * @return The contract itself
   */
  function permissionManager() external view returns (IDCAPermissionManager);

  /**
   * @notice Returns total created positions
   * @return The total created positions
   */
  function totalCreatedPositions() external view returns (uint256);

  /**
   * @notice Returns a user position
   * @param positionId The id of the position
   * @return position The position itself
   */
  function userPosition(uint256 positionId) external view returns (UserPosition memory position);

  /**
   * @notice Creates a new position
   * @dev Will revert:
   *      - With ZeroAddress if from, to or owner are zero
   *      - With InvalidToken if from == to
   *      - With ZeroAmount if amount is zero
   *      - With AmountTooBig if amount is too big
   *      - With ZeroSwaps if amountOfSwaps is zero
   *      - With IntervalNotAllowed if swapInterval is not allowed
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param permissions Extra permissions to add to the position. Can be empty
   * @return positionId The id of the created position
   */
  function deposit(
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions
  ) external returns (uint256 positionId);

  /**
   * @notice Creates a new position
   * @dev Will revert:
   *      - With ZeroAddress if from, to or owner are zero
   *      - With InvalidToken if from == to
   *      - With ZeroAmount if amount is zero
   *      - With AmountTooBig if amount is too big
   *      - With ZeroSwaps if amountOfSwaps is zero
   *      - With IntervalNotAllowed if swapInterval is not allowed
   * @param from The address of the "from" token
   * @param to The address of the "to" token
   * @param amount How many "from" tokens will be swapped in total
   * @param amountOfSwaps How many swaps to execute for this position
   * @param swapInterval How frequently the position's swaps should be executed
   * @param owner The address of the owner of the position being created
   * @param permissions Extra permissions to add to the position. Can be empty
   * @param miscellaneous Bytes that will be emitted, and associated with the position
   * @return positionId The id of the created position
   */
  function deposit(
    address from,
    address to,
    uint256 amount,
    uint32 amountOfSwaps,
    uint32 swapInterval,
    address owner,
    IDCAPermissionManager.PermissionSet[] calldata permissions,
    bytes calldata miscellaneous
  ) external returns (uint256 positionId);

  /**
   * @notice Withdraws all swapped tokens from a position to a recipient
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroAddress if recipient is zero
   * @param positionId The position's id
   * @param recipient The address to withdraw swapped tokens to
   * @return swapped How much was withdrawn
   */
  function withdrawSwapped(uint256 positionId, address recipient) external returns (uint256 swapped);

  /**
   * @notice Withdraws all swapped tokens from multiple positions
   * @dev Will revert:
   *      - With InvalidPosition if any of the position ids are invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position to any of the given positions
   *      - With ZeroAddress if recipient is zero
   *      - With PositionDoesNotMatchToken if any of the positions do not match the token in their position set
   * @param positions A list positions, grouped by `to` token
   * @param recipient The address to withdraw swapped tokens to
   * @return withdrawn How much was withdrawn for each token
   */
  function withdrawSwappedMany(PositionSet[] calldata positions, address recipient) external returns (uint256[] memory withdrawn);

  /**
   * @notice Takes the unswapped balance, adds the new deposited funds and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With AmountTooBig if amount is too big
   * @param positionId The position's id
   * @param amount Amount of funds to add to the position
   * @param newSwaps The new amount of swaps
   */
  function increasePosition(
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps
  ) external;

  /**
   * @notice Withdraws the specified amount from the unswapped balance and modifies the position so that
   * it is executed in newSwaps swaps
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroSwaps if newSwaps is zero and amount is not the total unswapped balance
   * @param positionId The position's id
   * @param amount Amount of funds to withdraw from the position
   * @param newSwaps The new amount of swaps
   * @param recipient The address to send tokens to
   */
  function reducePosition(
    uint256 positionId,
    uint256 amount,
    uint32 newSwaps,
    address recipient
  ) external;

  /**
   * @notice Terminates the position and sends all unswapped and swapped balance to the specified recipients
   * @dev Will revert:
   *      - With InvalidPosition if positionId is invalid
   *      - With UnauthorizedCaller if the caller doesn't have access to the position
   *      - With ZeroAddress if recipientUnswapped or recipientSwapped is zero
   * @param positionId The position's id
   * @param recipientUnswapped The address to withdraw unswapped tokens to
   * @param recipientSwapped The address to withdraw swapped tokens to
   * @return unswapped The unswapped balance sent to `recipientUnswapped`
   * @return swapped The swapped balance sent to `recipientSwapped`
   */
  function terminate(
    uint256 positionId,
    address recipientUnswapped,
    address recipientSwapped
  ) external returns (uint256 unswapped, uint256 swapped);
}

/**
 * @title The interface for all swap related matters
 * @notice These methods allow users to get information about the next swap, and how to execute it
 */
interface IDCAHubSwapHandler {
  /// @notice Information about a swap
  struct SwapInfo {
    // The tokens involved in the swap
    TokenInSwap[] tokens;
    // The pairs involved in the swap
    PairInSwap[] pairs;
  }

  /// @notice Information about a token's role in a swap
  struct TokenInSwap {
    // The token's address
    address token;
    // How much will be given of this token as a reward
    uint256 reward;
    // How much of this token needs to be provided by swapper
    uint256 toProvide;
    // How much of this token will be paid to the platform
    uint256 platformFee;
  }

  /// @notice Information about a pair in a swap
  struct PairInSwap {
    // The address of one of the tokens
    address tokenA;
    // The address of the other token
    address tokenB;
    // The total amount of token A swapped in this pair
    uint256 totalAmountToSwapTokenA;
    // The total amount of token B swapped in this pair
    uint256 totalAmountToSwapTokenB;
    // How much is 1 unit of token A when converted to B
    uint256 ratioAToB;
    // How much is 1 unit of token B when converted to A
    uint256 ratioBToA;
    // The swap intervals involved in the swap, represented as a byte
    bytes1 intervalsInSwap;
  }

  /// @notice A pair of tokens, represented by their indexes in an array
  struct PairIndexes {
    // The index of the token A
    uint8 indexTokenA;
    // The index of the token B
    uint8 indexTokenB;
  }

  /**
   * @notice Emitted when a swap is executed
   * @param sender The address of the user that initiated the swap
   * @param rewardRecipient The address that received the reward
   * @param callbackHandler The address that executed the callback
   * @param swapInformation All information related to the swap
   * @param borrowed How much was borrowed
   * @param fee The swap fee at the moment of the swap
   */
  event Swapped(
    address indexed sender,
    address indexed rewardRecipient,
    address indexed callbackHandler,
    SwapInfo swapInformation,
    uint256[] borrowed,
    uint32 fee
  );

  /// @notice Thrown when pairs indexes are not sorted correctly
  error InvalidPairs();

  /// @notice Thrown when trying to execute a swap, but there is nothing to swap
  error NoSwapsToExecute();

  /**
   * @notice Returns all information related to the next swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   * @param tokens The tokens involved in the next swap
   * @param pairs The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param calculatePrivilegedAvailability Some accounts get privileged availability and can execute swaps before others. This flag provides
   *        the possibility to calculate the next swap information for privileged and non-privileged accounts
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return swapInformation The information about the next swap
   */
  function getNextSwapInfo(
    address[] calldata tokens,
    PairIndexes[] calldata pairs,
    bool calculatePrivilegedAvailability,
    bytes calldata oracleData
  ) external view returns (SwapInfo memory swapInformation);

  /**
   * @notice Executes a flash swap
   * @dev Will revert with:
   *      - With InvalidTokens if tokens are not sorted, or if there are duplicates
   *      - With InvalidPairs if pairs are not sorted (first by indexTokenA and then indexTokenB), or if indexTokenA >= indexTokenB for any pair
   *      - With Paused if swaps are paused by protocol
   *      - With NoSwapsToExecute if there are no swaps to execute for the given pairs
   *      - With LiquidityNotReturned if the required tokens were not back during the callback
   * @param tokens The tokens involved in the next swap
   * @param pairsToSwap The pairs that you want to swap. Each element of the list points to the index of the token in the tokens array
   * @param rewardRecipient The address to send the reward to
   * @param callbackHandler Address to call for callback (and send the borrowed tokens to)
   * @param borrow How much to borrow of each of the tokens in tokens. The amount must match the position of the token in the tokens array
   * @param callbackData Bytes to send to the caller during the callback
   * @param oracleData Bytes to send to the oracle when executing a quote
   * @return Information about the executed swap
   */
  function swap(
    address[] calldata tokens,
    PairIndexes[] calldata pairsToSwap,
    address rewardRecipient,
    address callbackHandler,
    uint256[] calldata borrow,
    bytes calldata callbackData,
    bytes calldata oracleData
  ) external returns (SwapInfo memory);
}

/**
 * @title The interface for handling all configuration
 * @notice This contract will manage configuration that affects all pairs, swappers, etc
 */
interface IDCAHubConfigHandler {
  /**
   * @notice Emitted when a new oracle is set
   * @param oracle The new oracle contract
   */
  event OracleSet(ITokenPriceOracle oracle);

  /**
   * @notice Emitted when a new swap fee is set
   * @param feeSet The new swap fee
   */
  event SwapFeeSet(uint32 feeSet);

  /**
   * @notice Emitted when new swap intervals are allowed
   * @param swapIntervals The new swap intervals
   */
  event SwapIntervalsAllowed(uint32[] swapIntervals);

  /**
   * @notice Emitted when some swap intervals are no longer allowed
   * @param swapIntervals The swap intervals that are no longer allowed
   */
  event SwapIntervalsForbidden(uint32[] swapIntervals);

  /**
   * @notice Emitted when a new platform fee ratio is set
   * @param platformFeeRatio The new platform fee ratio
   */
  event PlatformFeeRatioSet(uint16 platformFeeRatio);

  /**
   * @notice Emitted when allowed states of tokens are updated
   * @param tokens Array of updated tokens
   * @param allowed Array of new allow state per token were allowed[i] is the updated state of tokens[i]
   */
  event TokensAllowedUpdated(address[] tokens, bool[] allowed);

  /// @notice Thrown when trying to interact with an unallowed token
  error UnallowedToken();

  /// @notice Thrown when set allowed tokens input is not valid
  error InvalidAllowedTokensInput();

  /// @notice Thrown when trying to set a fee higher than the maximum allowed
  error HighFee();

  /// @notice Thrown when trying to set a fee that is not multiple of 100
  error InvalidFee();

  /// @notice Thrown when trying to set a fee ratio that is higher that the maximum allowed
  error HighPlatformFeeRatio();

  /**
   * @notice Returns the max fee ratio that can be set
   * @dev Cannot be modified
   * @return The maximum possible value
   */
  // solhint-disable-next-line func-name-mixedcase
  function MAX_PLATFORM_FEE_RATIO() external view returns (uint16);

  /**
   * @notice Returns the fee charged on swaps
   * @return swapFee The fee itself
   */
  function swapFee() external view returns (uint32 swapFee);

  /**
   * @notice Returns the price oracle contract
   * @return oracle The contract itself
   */
  function oracle() external view returns (ITokenPriceOracle oracle);

  /**
   * @notice Returns how much will the platform take from the fees collected in swaps
   * @return The current ratio
   */
  function platformFeeRatio() external view returns (uint16);

  /**
   * @notice Returns the max fee that can be set for swaps
   * @dev Cannot be modified
   * @return maxFee The maximum possible fee
   */
  // solhint-disable-next-line func-name-mixedcase
  function MAX_FEE() external view returns (uint32 maxFee);

  /**
   * @notice Returns a byte that represents allowed swap intervals
   * @return allowedSwapIntervals The allowed swap intervals
   */
  function allowedSwapIntervals() external view returns (bytes1 allowedSwapIntervals);

  /**
   * @notice Returns if a token is currently allowed or not
   * @return Allowed state of token
   */
  function allowedTokens(address token) external view returns (bool);

  /**
   * @notice Returns token's magnitude (10**decimals)
   * @return Stored magnitude for token
   */
  function tokenMagnitude(address token) external view returns (uint120);

  /**
   * @notice Returns whether swaps and deposits are currently paused
   * @return isPaused Whether swaps and deposits are currently paused
   */
  function paused() external view returns (bool isPaused);

  /**
   * @notice Sets a new swap fee
   * @dev Will revert with HighFee if the fee is higher than the maximum
   * @dev Will revert with InvalidFee if the fee is not multiple of 100
   * @param fee The new swap fee
   */
  function setSwapFee(uint32 fee) external;

  /**
   * @notice Sets a new price oracle
   * @dev Will revert with ZeroAddress if the zero address is passed
   * @param oracle The new oracle contract
   */
  function setOracle(ITokenPriceOracle oracle) external;

  /**
   * @notice Sets a new platform fee ratio
   * @dev Will revert with HighPlatformFeeRatio if given ratio is too high
   * @param platformFeeRatio The new ratio
   */
  function setPlatformFeeRatio(uint16 platformFeeRatio) external;

  /**
   * @notice Adds new swap intervals to the allowed list
   * @param swapIntervals The new swap intervals
   */
  function addSwapIntervalsToAllowedList(uint32[] calldata swapIntervals) external;

  /**
   * @notice Removes some swap intervals from the allowed list
   * @param swapIntervals The swap intervals to remove
   */
  function removeSwapIntervalsFromAllowedList(uint32[] calldata swapIntervals) external;

  /// @notice Pauses all swaps and deposits
  function pause() external;

  /// @notice Unpauses all swaps and deposits
  function unpause() external;
}

/**
 * @title The interface for handling platform related actions
 * @notice This contract will handle all actions that affect the platform in some way
 */
interface IDCAHubPlatformHandler {
  /**
   * @notice Emitted when someone withdraws from the paltform balance
   * @param sender The address of the user that initiated the withdraw
   * @param recipient The address that received the withdraw
   * @param amounts The tokens (and the amount) that were withdrawn
   */
  event WithdrewFromPlatform(address indexed sender, address indexed recipient, IDCAHub.AmountOfToken[] amounts);

  /**
   * @notice Withdraws tokens from the platform balance
   * @param amounts The amounts to withdraw
   * @param recipient The address that will receive the tokens
   */
  function withdrawFromPlatformBalance(IDCAHub.AmountOfToken[] calldata amounts, address recipient) external;
}

interface IDCAHub is IDCAHubParameters, IDCAHubConfigHandler, IDCAHubSwapHandler, IDCAHubPositionHandler, IDCAHubPlatformHandler {
  /// @notice Specifies an amount of a token. For example to determine how much to borrow from certain tokens
  struct AmountOfToken {
    // The tokens' address
    address token;
    // How much to borrow or withdraw of the specified token
    uint256 amount;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when the expected liquidity is not returned in flash swaps
  error LiquidityNotReturned();

  /// @notice Thrown when a list of token pairs is not sorted, or if there are duplicates
  error InvalidTokens();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '../SwapAdapter.sol';

abstract contract RunSwap is SwapAdapter {
  /// @notice The parameters to execute the call
  struct RunSwapParams {
    // The swapper that will execute the call
    address swapper;
    // The account that needs to be approved for token transfers
    address allowanceTarget;
    // The actual swap execution
    bytes swapData;
    // The token that will be swapped
    address tokenIn;
    // The amount of "token in" that will be spent
    uint256 amountIn;
  }

  /**
   * @notice Executes a swap with the given swapper. The input tokens are expected to be on the contract before
   *         this function is executed. If the swap doesn't include a transfer, then the swapped tokens will be left
   *         on the contract
   * @dev This function can only be executed with swappers that are allowlisted
   * @param _parameters The parameters for the swap
   */
  function runSwap(RunSwapParams calldata _parameters) public payable virtual onlyAllowlisted(_parameters.swapper) {
    if (_parameters.tokenIn == PROTOCOL_TOKEN) {
      _executeSwap(_parameters.swapper, _parameters.swapData, _parameters.amountIn);
    } else {
      _maxApproveSpenderIfNeeded(
        IERC20(_parameters.tokenIn),
        _parameters.allowanceTarget,
        _parameters.swapper == _parameters.allowanceTarget, // If target is a swapper, then it's ok as allowance target
        _parameters.amountIn
      );
      _executeSwap(_parameters.swapper, _parameters.swapData, 0);
    }
  }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title The interface for an oracle that provides price quotes
 * @notice These methods allow users to add support for pairs, and then ask for quotes
 */
interface ITokenPriceOracle {
  /// @notice Thrown when trying to add support for a pair that cannot be supported
  error PairCannotBeSupported(address tokenA, address tokenB);

  /// @notice Thrown when trying to execute a quote with a pair that isn't supported yet
  error PairNotSupportedYet(address tokenA, address tokenB);

  /**
   * @notice Returns whether this oracle can support the given pair of tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return Whether the given pair of tokens can be supported by the oracle
   */
  function canSupportPair(address tokenA, address tokenB) external view returns (bool);

  /**
   * @notice Returns whether this oracle is already supporting the given pair of tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return Whether the given pair of tokens is already being supported by the oracle
   */
  function isPairAlreadySupported(address tokenA, address tokenB) external view returns (bool);

  /**
   * @notice Returns a quote, based on the given tokens and amount
   * @dev Will revert if pair isn't supported
   * @param tokenIn The token that will be provided
   * @param amountIn The amount that will be provided
   * @param tokenOut The token we would like to quote
   * @param data Custom data that the oracle might need to operate
   * @return amountOut How much `tokenOut` will be returned in exchange for `amountIn` amount of `tokenIn`
   */
  function quote(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    bytes calldata data
  ) external view returns (uint256 amountOut);

  /**
   * @notice Add or reconfigures the support for a given pair. This function will let the oracle take some actions
   *         to configure the pair, in preparation for future quotes. Can be called many times in order to let the oracle
   *         re-configure for a new context
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function addOrModifySupportForPair(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) external;

  /**
   * @notice Adds support for a given pair if the oracle didn't support it already. If called for a pair that is already supported,
   *         then nothing will happen. This function will let the oracle take some actions to configure the pair, in preparation
   *         for future quotes
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function addSupportForPairIfNeeded(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@mean-finance/nft-descriptors/solidity/interfaces/IDCAHubPositionDescriptor.sol';

interface IERC721BasicEnumerable {
  /**
   * @notice Count NFTs tracked by this contract
   * @return A count of valid NFTs tracked by this contract, where each one of
   *         them has an assigned and queryable owner not equal to the zero address
   */
  function totalSupply() external view returns (uint256);
}

/**
 * @title The interface for all permission related matters
 * @notice These methods allow users to set and remove permissions to their positions
 */
interface IDCAPermissionManager is IERC721, IERC721BasicEnumerable {
  /// @notice Set of possible permissions
  enum Permission {
    INCREASE,
    REDUCE,
    WITHDRAW,
    TERMINATE
  }

  /// @notice A set of permissions for a specific operator
  struct PermissionSet {
    // The address of the operator
    address operator;
    // The permissions given to the overator
    Permission[] permissions;
  }

  /// @notice A collection of permissions sets for a specific position
  struct PositionPermissions {
    // The id of the token
    uint256 tokenId;
    // The permissions to assign to the position
    PermissionSet[] permissionSets;
  }

  /**
   * @notice Emitted when permissions for a token are modified
   * @param tokenId The id of the token
   * @param permissions The set of permissions that were updated
   */
  event Modified(uint256 tokenId, PermissionSet[] permissions);

  /**
   * @notice Emitted when the address for a new descritor is set
   * @param descriptor The new descriptor contract
   */
  event NFTDescriptorSet(IDCAHubPositionDescriptor descriptor);

  /// @notice Thrown when a user tries to set the hub, once it was already set
  error HubAlreadySet();

  /// @notice Thrown when a user provides a zero address when they shouldn't
  error ZeroAddress();

  /// @notice Thrown when a user calls a method that can only be executed by the hub
  error OnlyHubCanExecute();

  /// @notice Thrown when a user tries to modify permissions for a token they do not own
  error NotOwner();

  /// @notice Thrown when a user tries to execute a permit with an expired deadline
  error ExpiredDeadline();

  /// @notice Thrown when a user tries to execute a permit with an invalid signature
  error InvalidSignature();

  /**
   * @notice The permit typehash used in the permit signature
   * @return The typehash for the permit
   */
  // solhint-disable-next-line func-name-mixedcase
  function PERMIT_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the permission permit signature
   * @return The typehash for the permission permit
   */
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_PERMIT_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the multi permission permit signature
   * @return The typehash for the multi permission permit
   */
  // solhint-disable-next-line func-name-mixedcase
  function MULTI_PERMISSION_PERMIT_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the permission permit signature
   * @return The typehash for the permission set
   */
  // solhint-disable-next-line func-name-mixedcase
  function PERMISSION_SET_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The permit typehash used in the multi permission permit signature
   * @return The typehash for the position permissions
   */
  // solhint-disable-next-line func-name-mixedcase
  function POSITION_PERMISSIONS_TYPEHASH() external pure returns (bytes32);

  /**
   * @notice The domain separator used in the permit signature
   * @return The domain seperator used in encoding of permit signature
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the NFT descriptor contract
   * @return The contract for the NFT descriptor
   */
  function nftDescriptor() external returns (IDCAHubPositionDescriptor);

  /**
   * @notice Returns the address of the DCA Hub
   * @return The address of the DCA Hub
   */
  function hub() external returns (address);

  /**
   * @notice Returns the next nonce to use for a given user
   * @param user The address of the user
   * @return nonce The next nonce to use
   */
  function nonces(address user) external returns (uint256 nonce);

  /**
   * @notice Returns whether the given address has the permission for the given token
   * @param id The id of the token to check
   * @param account The address of the user to check
   * @param permission The permission to check
   * @return Whether the user has the permission or not
   */
  function hasPermission(
    uint256 id,
    address account,
    Permission permission
  ) external view returns (bool);

  /**
   * @notice Returns whether the given address has the permissions for the given token
   * @param id The id of the token to check
   * @param account The address of the user to check
   * @param permissions The permissions to check
   * @return hasPermissions Whether the user has each permission or not
   */
  function hasPermissions(
    uint256 id,
    address account,
    Permission[] calldata permissions
  ) external view returns (bool[] memory hasPermissions);

  /**
   * @notice Sets the address for the hub
   * @dev Can only be successfully executed once. Once it's set, it can be modified again
   *      Will revert:
   *      - With ZeroAddress if address is zero
   *      - With HubAlreadySet if the hub has already been set
   * @param hub The address to set for the hub
   */
  function setHub(address hub) external;

  /**
   * @notice Mints a new NFT with the given id, and sets the permissions for it
   * @dev Will revert with OnlyHubCanExecute if the caller is not the hub
   * @param id The id of the new NFT
   * @param owner The owner of the new NFT
   * @param permissions Permissions to set for the new NFT
   */
  function mint(
    uint256 id,
    address owner,
    PermissionSet[] calldata permissions
  ) external;

  /**
   * @notice Burns the NFT with the given id, and clears all permissions
   * @dev Will revert with OnlyHubCanExecute if the caller is not the hub
   * @param id The token's id
   */
  function burn(uint256 id) external;

  /**
   * @notice Sets new permissions for the given position
   * @dev Will revert with NotOwner if the caller is not the token's owner.
   *      Operators that are not part of the given permission sets do not see their permissions modified.
   *      In order to remove permissions to an operator, provide an empty list of permissions for them
   * @param id The token's id
   * @param permissions A list of permission sets
   */
  function modify(uint256 id, PermissionSet[] calldata permissions) external;

  /**
   * @notice Sets new permissions for the given positions
   * @dev This is basically the same as executing multiple `modify`
   * @param permissions A list of position permissions to set
   */
  function modifyMany(PositionPermissions[] calldata permissions) external;

  /**
   * @notice Approves spending of a specific token ID by spender via signature
   * @param spender The account that is being approved
   * @param tokenId The ID of the token that is being approved for spending
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Sets permissions via signature
   * @dev This method works similarly to `modifyMany`, but instead of being executed by the owner, it can be set by signature
   * @param permissions The permissions to set for the different positions
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function multiPermissionPermit(
    PositionPermissions[] calldata permissions,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Sets permissions via signature
   * @dev This method works similarly to `modify`, but instead of being executed by the owner, it can be set my signature
   * @param permissions The permissions to set
   * @param tokenId The token's id
   * @param deadline The deadline timestamp by which the call must be mined for the approve to work
   * @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
   * @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
   * @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
   */
  function permissionPermit(
    PermissionSet[] calldata permissions,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Sets a new NFT descriptor
   * @dev Will revert with ZeroAddress if address is zero
   * @param descriptor The new NFT descriptor contract
   */
  function setNFTDescriptor(IDCAHubPositionDescriptor descriptor) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/**
 * @title The interface for generating a description for a position in a DCA Hub
 * @notice Contracts that implement this interface must return a base64 JSON with the entire description
 */
interface IDCAHubPositionDescriptor {
  /**
   * @notice Generates a positions's description, both the JSON and the image inside
   * @param hub The address of the DCA Hub
   * @param positionId The token/position id
   * @return description The position's description
   */
  function tokenURI(address hub, uint256 positionId) external view returns (string memory description);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/ISwapAdapter.sol';

abstract contract SwapAdapter is ISwapAdapter {
  using SafeERC20 for IERC20;
  using Address for address;
  using Address for address payable;

  /// @inheritdoc ISwapAdapter
  address public constant PROTOCOL_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  /// @inheritdoc ISwapAdapter
  ISwapperRegistry public immutable SWAPPER_REGISTRY;

  constructor(address _swapperRegistry) {
    if (_swapperRegistry == address(0)) revert ZeroAddress();
    SWAPPER_REGISTRY = ISwapperRegistry(_swapperRegistry);
  }

  receive() external payable {}

  /**
   * @notice Takes the given amount of tokens from the caller
   * @param _token The token to check
   * @param _amount The amount to take
   */
  function _takeFromMsgSender(IERC20 _token, uint256 _amount) internal virtual {
    _token.safeTransferFrom(msg.sender, address(this), _amount);
  }

  /**
   * @notice Checks if the given spender has enough allowance, and approves the max amount
   *         if it doesn't
   * @param _token The token to check
   * @param _spender The spender to check
   * @param _minAllowance The min allowance. If the spender has over this amount, then no extra approve is needed
   */
  function _maxApproveSpenderIfNeeded(
    IERC20 _token,
    address _spender,
    bool _alreadyValidatedSpender,
    uint256 _minAllowance
  ) internal virtual {
    if (_spender != address(0)) {
      uint256 _allowance = _token.allowance(address(this), _spender);
      if (_allowance < _minAllowance) {
        if (!_alreadyValidatedSpender && !SWAPPER_REGISTRY.isValidAllowanceTarget(_spender)) {
          revert InvalidAllowanceTarget(_spender);
        }
        if (_allowance > 0) {
          _token.approve(_spender, 0); // We do this because some tokens (like USDT) fail if we don't
        }
        _token.approve(_spender, type(uint256).max);
      }
    }
  }

  /**
   * @notice Executes a swap for the given swapper
   * @param _swapper The actual swapper
   * @param _swapData The swap execution data
   */
  function _executeSwap(
    address _swapper,
    bytes calldata _swapData,
    uint256 _value
  ) internal virtual {
    _swapper.functionCallWithValue(_swapData, _value);
  }

  /**
   * @notice Checks if the contract has any balance of the given token, and if it does,
   *         it sends it to the given recipient
   * @param _token The token to check
   * @param _recipient The recipient of the token balance
   */
  function _sendBalanceOnContractToRecipient(address _token, address _recipient) internal virtual {
    uint256 _balance = _token == PROTOCOL_TOKEN ? address(this).balance : IERC20(_token).balanceOf(address(this));
    if (_balance > 0) {
      _sendToRecipient(_token, _balance, _recipient);
    }
  }

  /**
   * @notice Transfers the given amount of tokens from the contract to the recipient
   * @param _token The token to check
   * @param _amount The amount to send
   * @param _recipient The recipient
   */
  function _sendToRecipient(
    address _token,
    uint256 _amount,
    address _recipient
  ) internal virtual {
    if (_recipient == address(0)) _recipient = msg.sender;
    if (_token == PROTOCOL_TOKEN) {
      payable(_recipient).sendValue(_amount);
    } else {
      IERC20(_token).safeTransfer(_recipient, _amount);
    }
  }

  /**
   * @notice Checks if given swapper is allowlisted, and fails if it isn't
   * @param _swapper The swapper to check
   */
  function _assertSwapperIsAllowlisted(address _swapper) internal view {
    if (!SWAPPER_REGISTRY.isSwapperAllowlisted(_swapper)) revert SwapperNotAllowlisted(_swapper);
  }

  /**
   * @notice Revokes ERC20 allowances for the given spenders
   * @dev If exposed, then it should be permissioned
   * @param _revokeActions The spenders and tokens to revoke
   */
  function _revokeAllowances(RevokeAction[] calldata _revokeActions) internal virtual {
    for (uint256 i = 0; i < _revokeActions.length; ) {
      RevokeAction memory _action = _revokeActions[i];
      for (uint256 j = 0; j < _action.tokens.length; ) {
        _action.tokens[j].approve(_action.spender, 0);
        unchecked {
          j++;
        }
      }
      unchecked {
        i++;
      }
    }
  }

  modifier onlyAllowlisted(address _swapper) {
    _assertSwapperIsAllowlisted(_swapper);
    _;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/interfaces/IERC20.sol';
import './ISwapperRegistry.sol';

/**
 * @notice This abstract contract will give contracts that implement it swapping capabilities. It will
 *         take a swapper and a swap's data, and if the swapper is valid, it will execute the swap
 */
interface ISwapAdapter {
  /// @notice Describes how the allowance should be revoked for the given spender
  struct RevokeAction {
    address spender;
    IERC20[] tokens;
  }

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /**
   * @notice Thrown when trying to execute a swap with a swapper that is not allowlisted
   * @param swapper The swapper that was not allowlisted
   */
  error SwapperNotAllowlisted(address swapper);

  /// @notice Thrown when the allowance target is not allowed by the swapper registry
  error InvalidAllowanceTarget(address spender);

  /**
   * @notice Returns the address of the swapper registry
   * @dev Cannot be modified
   * @return The address of the swapper registry
   */
  function SWAPPER_REGISTRY() external view returns (ISwapperRegistry);

  /**
   * @notice Returns the address of the protocol token
   * @dev Cannot be modified
   * @return The address of the protocol token;
   */
  function PROTOCOL_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

/**
 * @notice This contract will act as a registry to allowlist swappers. Different contracts from the Mean
 *         ecosystem will ask this contract if an address is a valid swapper or not
 *         In some cases, swappers have supplementary allowance targets that need ERC20 approvals. We
 *         will also track those here
 */
interface ISwapperRegistry {
  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when trying to remove an account from the swappers list, when it wasn't there before
  error AccountIsNotSwapper(address account);

  /**
   * @notice Thrown when trying to remove an account from the supplementary allowance target list,
   *         when it wasn't there before
   */
  error AccountIsNotSupplementaryAllowanceTarget(address account);

  /// @notice Thrown when trying to mark an account as swapper or allowance target, but it already has a role assigned
  error AccountAlreadyHasRole(address account);

  /**
   * @notice Emitted when swappers are removed from the allowlist
   * @param swappers The swappers that were removed
   */
  event RemoveSwappersFromAllowlist(address[] swappers);

  /**
   * @notice Emitted when new swappers are added to the allowlist
   * @param swappers The swappers that were added
   */
  event AllowedSwappers(address[] swappers);

  /**
   * @notice Emitted when new supplementary allowance targets are are added to the allowlist
   * @param allowanceTargets The allowance targets that were added
   */
  event AllowedSupplementaryAllowanceTargets(address[] allowanceTargets);

  /**
   * @notice Emitted when supplementary allowance targets are removed from the allowlist
   * @param allowanceTargets The allowance targets that were removed
   */
  event RemovedAllowanceTargetsFromAllowlist(address[] allowanceTargets);

  /**
   * @notice Returns whether a given account is allowlisted for swaps
   * @param account The address to check
   * @return Whether it is allowlisted for swaps
   */
  function isSwapperAllowlisted(address account) external view returns (bool);

  /**
   * @notice Returns whether a given account is a valid allowance target. This would be true
   *         if the account is either a swapper, or a supplementary allowance target
   * @param account The address to check
   * @return Whether it is a valid allowance target
   */
  function isValidAllowanceTarget(address account) external view returns (bool);

  /**
   * @notice Adds a list of swappers to the allowlist
   * @dev Can only be called by users with the admin role
   * @param swappers The list of swappers to add
   */
  function allowSwappers(address[] calldata swappers) external;

  /**
   * @notice Removes the given swappers from the allowlist
   * @dev Can only be called by users with the admin role
   * @param swappers The list of swappers to remove
   */
  function removeSwappersFromAllowlist(address[] calldata swappers) external;

  /**
   * @notice Adds a list of supplementary allowance targets to the allowlist
   * @dev Can only be called by users with the admin role
   * @param allowanceTargets The list of allowance targets to add
   */
  function allowSupplementaryAllowanceTargets(address[] calldata allowanceTargets) external;

  /**
   * @notice Removes the given allowance targets from the allowlist
   * @dev Can only be called by users with the admin role
   * @param allowanceTargets The list of allowance targets to remove
   */
  function removeSupplementaryAllowanceTargetsFromAllowlist(address[] calldata allowanceTargets) external;
}