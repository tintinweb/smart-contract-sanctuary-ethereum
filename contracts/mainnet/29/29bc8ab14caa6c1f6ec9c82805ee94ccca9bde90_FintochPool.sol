// SPDX-License-Identifier: MIT
// Chainlink Contracts v0.8
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC20} from '../../openzeppelin/contracts/IERC20.sol';

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
  /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
  /// also when the token returns `false`.
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    bytes4 selector_ = token.transfer.selector;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(freeMemoryPointer, selector_)
      mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 36), value)

      if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    require(getLastTransferResult(token), 'GPv2: failed transfer');
  }

  /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
  /// reverts also when the token returns `false`.
  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    bytes4 selector_ = token.transferFrom.selector;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(freeMemoryPointer, selector_)
      mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 68), value)

      if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    require(getLastTransferResult(token), 'GPv2: failed transferFrom');
  }

  /// @dev Verifies that the last return was a successful `transfer*` call.
  /// This is done by checking that the return data is either empty, or
  /// is a valid ABI encoded boolean.
  function getLastTransferResult(IERC20 token) private view returns (bool success) {
    // NOTE: Inspecting previous return data requires assembly. Note that
    // we write the return data to memory 0 in the case where the return
    // data size is 32, this is OK since the first 64 bytes of memory are
    // reserved by Solidy as a scratch space that can be used within
    // assembly blocks.
    // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
    // solhint-disable-next-line no-inline-assembly
    assembly {
      /// @dev Revert with an ABI encoded Solidity error with a message
      /// that fits into 32-bytes.
      ///
      /// An ABI encoded Solidity error has the following memory layout:
      ///
      /// ------------+----------------------------------
      ///  byte range | value
      /// ------------+----------------------------------
      ///  0x00..0x04 |        selector("Error(string)")
      ///  0x04..0x24 |      string offset (always 0x20)
      ///  0x24..0x44 |                    string length
      ///  0x44..0x64 | string value, padded to 32-bytes
      function revertWithMessage(length, message) {
        mstore(0x00, '\x08\xc3\x79\xa0')
        mstore(0x04, 0x20)
        mstore(0x24, length)
        mstore(0x44, message)
        revert(0x00, 0x64)
      }

      switch returndatasize()
      // Non-standard ERC20 transfer without return.
      case 0 {
        // NOTE: When the return data size is 0, verify that there
        // is code at the address. This is done in order to maintain
        // compatibility with Solidity calling conventions.
        // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
        if iszero(extcodesize(token)) {
          revertWithMessage(20, 'GPv2: not a contract')
        }

        success := 1
      }
      // Standard ERC20 transfer returning boolean success value.
      case 32 {
        returndatacopy(0, 0, returndatasize())

        // NOTE: For ABI encoding v1, any non-zero value is accepted
        // as `true` for a boolean. In order to stay compatible with
        // OpenZeppelin's `SafeERC20` library which is known to work
        // with the existing ERC20 implementation we care about,
        // make sure we return success for any non-zero return value
        // from the `transfer*` call.
        success := iszero(iszero(mload(0)))
      }
      default {
        revertWithMessage(31, 'GPv2: malformed transfer result')
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './IAccessControl.sol';
import './Context.sol';
import './Strings.sol';
import './ERC165.sol';

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
            'AccessControl: account ',
            Strings.toHexString(uint160(account), 20),
            ' is missing role ',
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
  function grantRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
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
  function revokeRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
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
    require(account == _msgSender(), 'AccessControl: can only renounce roles for self');

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
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './IERC165.sol';

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

pragma solidity ^0.8.10;

import './Context.sol';
import './IERC20.sol';
import './SafeMath.sol';
import './Address.sol';

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name, string memory symbol) {
    _name = name;
    _symbol = symbol;
    _decimals = 18;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
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
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

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

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
pragma solidity ^0.8.10;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
  /**
   * @dev Returns the downcasted uint224 from uint256, reverting on
   * overflow (when the input is greater than largest uint224).
   *
   * Counterpart to Solidity's `uint224` operator.
   *
   * Requirements:
   *
   * - input must fit into 224 bits
   */
  function toUint224(uint256 value) internal pure returns (uint224) {
    require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
    return uint224(value);
  }

  /**
   * @dev Returns the downcasted uint128 from uint256, reverting on
   * overflow (when the input is greater than largest uint128).
   *
   * Counterpart to Solidity's `uint128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   */
  function toUint128(uint256 value) internal pure returns (uint128) {
    require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
    return uint128(value);
  }

  /**
   * @dev Returns the downcasted uint96 from uint256, reverting on
   * overflow (when the input is greater than largest uint96).
   *
   * Counterpart to Solidity's `uint96` operator.
   *
   * Requirements:
   *
   * - input must fit into 96 bits
   */
  function toUint96(uint256 value) internal pure returns (uint96) {
    require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
    return uint96(value);
  }

  /**
   * @dev Returns the downcasted uint64 from uint256, reverting on
   * overflow (when the input is greater than largest uint64).
   *
   * Counterpart to Solidity's `uint64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
    return uint64(value);
  }

  /**
   * @dev Returns the downcasted uint32 from uint256, reverting on
   * overflow (when the input is greater than largest uint32).
   *
   * Counterpart to Solidity's `uint32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   */
  function toUint32(uint256 value) internal pure returns (uint32) {
    require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
    return uint32(value);
  }

  /**
   * @dev Returns the downcasted uint16 from uint256, reverting on
   * overflow (when the input is greater than largest uint16).
   *
   * Counterpart to Solidity's `uint16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   */
  function toUint16(uint256 value) internal pure returns (uint16) {
    require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
    return uint16(value);
  }

  /**
   * @dev Returns the downcasted uint8 from uint256, reverting on
   * overflow (when the input is greater than largest uint8).
   *
   * Counterpart to Solidity's `uint8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   */
  function toUint8(uint256 value) internal pure returns (uint8) {
    require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
    return uint8(value);
  }

  /**
   * @dev Converts a signed int256 into an unsigned uint256.
   *
   * Requirements:
   *
   * - input must be greater than or equal to 0.
   */
  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, 'SafeCast: value must be positive');
    return uint256(value);
  }

  /**
   * @dev Returns the downcasted int128 from int256, reverting on
   * overflow (when the input is less than smallest int128 or
   * greater than largest int128).
   *
   * Counterpart to Solidity's `int128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   *
   * _Available since v3.1._
   */
  function toInt128(int256 value) internal pure returns (int128) {
    require(
      value >= type(int128).min && value <= type(int128).max,
      "SafeCast: value doesn't fit in 128 bits"
    );
    return int128(value);
  }

  /**
   * @dev Returns the downcasted int64 from int256, reverting on
   * overflow (when the input is less than smallest int64 or
   * greater than largest int64).
   *
   * Counterpart to Solidity's `int64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   *
   * _Available since v3.1._
   */
  function toInt64(int256 value) internal pure returns (int64) {
    require(
      value >= type(int64).min && value <= type(int64).max,
      "SafeCast: value doesn't fit in 64 bits"
    );
    return int64(value);
  }

  /**
   * @dev Returns the downcasted int32 from int256, reverting on
   * overflow (when the input is less than smallest int32 or
   * greater than largest int32).
   *
   * Counterpart to Solidity's `int32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   *
   * _Available since v3.1._
   */
  function toInt32(int256 value) internal pure returns (int32) {
    require(
      value >= type(int32).min && value <= type(int32).max,
      "SafeCast: value doesn't fit in 32 bits"
    );
    return int32(value);
  }

  /**
   * @dev Returns the downcasted int16 from int256, reverting on
   * overflow (when the input is less than smallest int16 or
   * greater than largest int16).
   *
   * Counterpart to Solidity's `int16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   *
   * _Available since v3.1._
   */
  function toInt16(int256 value) internal pure returns (int16) {
    require(
      value >= type(int16).min && value <= type(int16).max,
      "SafeCast: value doesn't fit in 16 bits"
    );
    return int16(value);
  }

  /**
   * @dev Returns the downcasted int8 from int256, reverting on
   * overflow (when the input is less than smallest int8 or
   * greater than largest int8).
   *
   * Counterpart to Solidity's `int8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   *
   * _Available since v3.1._
   */
  function toInt8(int256 value) internal pure returns (int8) {
    require(
      value >= type(int8).min && value <= type(int8).max,
      "SafeCast: value doesn't fit in 8 bits"
    );
    return int8(value);
  }

  /**
   * @dev Converts an unsigned uint256 into a signed int256.
   *
   * Requirements:
   *
   * - input must be less than or equal to maxInt256.
   */
  function toInt256(uint256 value) internal pure returns (int256) {
    // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
    require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
    return int256(value);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library SafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x + y) >= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @param message The error msg
  /// @return z The difference of x and y
  function sub(
    uint256 x,
    uint256 y,
    string memory message
  ) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x, message);
    }
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require(x == 0 || (z = x * y) / x == y);
    }
  }

  /// @notice Returns x / y, reverts if overflows - no specific check, solidity reverts on division by 0
  /// @param x The numerator
  /// @param y The denominator
  /// @return z The product of x and y
  function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x / y;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
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
      return '0x00';
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
    buffer[0] = '0';
    buffer[1] = 'x';
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, 'Strings: hex length insufficient');
    return string(buffer);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import './BaseAdminUpgradeabilityProxy.sol';

/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for
 * initializing the implementation, admin, and init data.
 */
contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(
    address _logic,
    address _admin,
    bytes memory _data
  ) payable UpgradeabilityProxy(_logic, _data) {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal override(BaseAdminUpgradeabilityProxy, Proxy) {
    BaseAdminUpgradeabilityProxy._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import './UpgradeabilityProxy.sol';

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), 'Cannot change the admin of a proxy to the zero address');
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    payable
    ifAdmin
  {
    _upgradeTo(newImplementation);
    (bool success, ) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    //solium-disable-next-line
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;
    //solium-disable-next-line
    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal virtual override {
    require(msg.sender != _admin(), 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import './Proxy.sol';
import '../contracts/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    //solium-disable-next-line
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(
      Address.isContract(newImplementation),
      'Cannot set a proxy implementation to a non-contract address'
    );

    bytes32 slot = IMPLEMENTATION_SLOT;

    //solium-disable-next-line
    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(
      initializing || isConstructor() || !initialized,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import './BaseAdminUpgradeabilityProxy.sol';
import './InitializableUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is
  BaseAdminUpgradeabilityProxy,
  InitializableUpgradeabilityProxy
{
  /**
   * Contract initializer.
   * @param logic address of the initial implementation.
   * @param admin Address of the proxy administrator.
   * @param data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(
    address logic,
    address admin,
    bytes memory data
  ) public payable {
    require(_implementation() == address(0));
    InitializableUpgradeabilityProxy.initialize(logic, data);
    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(admin);
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal override(BaseAdminUpgradeabilityProxy, Proxy) {
    BaseAdminUpgradeabilityProxy._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Will run if no other function in the contract matches the call data.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    //solium-disable-next-line
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.10;

contract WETH9 {
  string public name = 'Wrapped Ether';
  string public symbol = 'WETH';
  uint8 public decimals = 18;

  event Approval(address indexed src, address indexed guy, uint256 wad);
  event Transfer(address indexed src, address indexed dst, uint256 wad);
  event Deposit(address indexed dst, uint256 wad);
  event Withdrawal(address indexed src, uint256 wad);

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  receive() external payable {
    deposit();
  }

  function deposit() public payable {
    balanceOf[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint256 wad) public {
    require(balanceOf[msg.sender] >= wad);
    balanceOf[msg.sender] -= wad;
    payable(msg.sender).transfer(wad);
    emit Withdrawal(msg.sender, wad);
  }

  function totalSupply() public view returns (uint256) {
    return address(this).balance;
  }

  function approve(address guy, uint256 wad) public returns (bool) {
    allowance[msg.sender][guy] = wad;
    emit Approval(msg.sender, guy, wad);
    return true;
  }

  function transfer(address dst, uint256 wad) public returns (bool) {
    return transferFrom(msg.sender, dst, wad);
  }

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) public returns (bool) {
    require(balanceOf[src] >= wad);

    if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
      require(allowance[src][msg.sender] >= wad);
      allowance[src][msg.sender] -= wad;
    }

    balanceOf[src] -= wad;
    balanceOf[dst] += wad;

    emit Transfer(src, dst, wad);

    return true;
  }
}

/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IFlashLoanReceiver} from '../interfaces/IFlashLoanReceiver.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';

/**
 * @title FlashLoanReceiverBase
 *
 * @notice Base contract to develop a flashloan-receiver contract.
 */
abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  IL1Pool public immutable override POOL;

  constructor(IPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
    POOL = IL1Pool(provider.getPool());
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IFlashLoanSimpleReceiver} from '../interfaces/IFlashLoanSimpleReceiver.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';

/**
 * @title FlashLoanSimpleReceiverBase
 *
 * @notice Base contract to develop a flashloan-receiver contract.
 */
abstract contract FlashLoanSimpleReceiverBase is IFlashLoanSimpleReceiver {
  IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  IL1Pool public immutable override POOL;

  constructor(IPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
    POOL = IL1Pool(provider.getPool());
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';

/**
 * @title IFlashLoanReceiver
 *
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
  /**
   * @notice Executes an operation after receiving the flash-borrowed assets
   * @dev Ensure that the contract can return the debt + premium, e.g., has
   *      enough funds to repay and has approved the Pool to pull the total amount
   * @param assets The addresses of the flash-borrowed assets
   * @param amounts The amounts of the flash-borrowed assets
   * @param premiums The fee of each flash-borrowed asset
   * @param initiator The address of the flashloan initiator
   * @param params The byte-encoded params passed when initiating the flashloan
   * @return True if the execution of the operation succeeds, false otherwise
   */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);

  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  function POOL() external view returns (IL1Pool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';

/**
 * @title IFlashLoanSimpleReceiver
 *
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanSimpleReceiver {
  /**
   * @notice Executes an operation after receiving the flash-borrowed asset
   * @dev Ensure that the contract can return the debt + premium, e.g., has
   *      enough funds to repay and has approved the Pool to pull the total amount
   * @param asset The address of the flash-borrowed asset
   * @param amount The amount of the flash-borrowed asset
   * @param premium The fee of the flash-borrowed asset
   * @param initiator The address of the flashloan initiator
   * @param params The byte-encoded params passed when initiating the flashloan
   * @return True if the execution of the operation succeeds, false otherwise
   */
  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address initiator,
    bytes calldata params
  ) external returns (bool);

  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  function POOL() external view returns (IL1Pool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IACLManager
 *
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
  /**
   * @notice Returns the contract address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the identifier of the PoolAdmin role
   * @return The id of the PoolAdmin role
   */
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the RiskAdmin role
   * @return The id of the RiskAdmin role
   */
  function RISK_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the FlashBorrower role
   * @return The id of the FlashBorrower role
   */
  function FLASH_BORROWER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the Bridge role
   * @return The id of the Bridge role
   */
  function BRIDGE_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the AssetListingAdmin role
   * @return The id of the AssetListingAdmin role
   */
  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new address as FlashBorrower
   * @param borrower The address of the new FlashBorrower
   */
  function addFlashBorrower(address borrower) external;

  /**
   * @notice Removes an admin as FlashBorrower
   * @param borrower The address of the FlashBorrower to remove
   */
  function removeFlashBorrower(address borrower) external;

  /**
   * @notice Returns true if the address is FlashBorrower, false otherwise
   * @param borrower The address to check
   * @return True if the given address is FlashBorrower, false otherwise
   */
  function isFlashBorrower(address borrower) external view returns (bool);

  /**
   * @notice Adds a new address as Bridge
   * @param bridge The address of the new Bridge
   */
  function addBridge(address bridge) external;

  /**
   * @notice Removes an address as Bridge
   * @param bridge The address of the bridge to remove
   */
  function removeBridge(address bridge) external;

  /**
   * @notice Returns true if the address is Bridge, false otherwise
   * @param bridge The address to check
   * @return True if the given address is Bridge, false otherwise
   */
  function isBridge(address bridge) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableAToken} from './IInitializableAToken.sol';

/**
 * @title IAToken
 *
 * @notice Defines the basic interface for an AToken.
 **/
interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The next liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @notice Mints `amount` aTokens to `user`
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted aTokens
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address caller,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @notice Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @dev In some instances, the mint event could be emitted from a burn transaction
   * if the amount to burn is less than the interest that the user accrued
   * @param from The address from which the aTokens will be burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The next liquidity index of the reserve
   **/
  function burn(
    address from,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @notice Mints aTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
   * @param from The address getting liquidated, current owner of the aTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @notice Transfers the underlying asset to `target`.
   * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external;

  /**
   * @notice Handles the underlying received by the aToken after the transfer has been completed.
   * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
   * transfer is concluded. However in the future there may be aTokens that allow for example to stake the underlying
   * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external;

  /**
   * @notice Allow passing a signed message to approve spending
   * @dev implements the permit function as for
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner The owner of the funds
   * @param spender The spender
   * @param value The amount
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v Signature param
   * @param s Signature param
   * @param r Signature param
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
   * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @return The address of the underlying asset
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @notice Returns the address of the Fintoch treasury, receiving the fees on this aToken.
   * @return Address of the Fintoch treasury
   **/
  function RESERVE_TREASURY_ADDRESS() external view returns (address);

  /**
   * @notice Get the domain separator for the token
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the nonce for owner.
   * @param owner The address of the owner
   * @return The nonce of the owner
   **/
  function nonces(address owner) external view returns (uint256);

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title ICreditDelegationToken
 *
 * @notice Defines the basic interface for a token supporting credit delegation.
 **/
interface ICreditDelegationToken {
  /**
   * @dev Emitted on `approveDelegation` and `borrowAllowance
   * @param fromUser The address of the delegator
   * @param toUser The address of the delegatee
   * @param asset The address of the delegated asset
   * @param amount The amount being delegated
   */
  event BorrowAllowanceDelegated(
    address indexed fromUser,
    address indexed toUser,
    address indexed asset,
    uint256 amount
  );

  /**
   * @notice Delegates borrowing power to a user on the specific debt token.
   * Delegation will still respect the liquidation constraints (even if delegated, a
   * delegatee cannot force a delegator HF to go below 1)
   * @param delegatee The address receiving the delegated borrowing power
   * @param amount The maximum amount being delegated.
   **/
  function approveDelegation(address delegatee, uint256 amount) external;

  /**
   * @notice Returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return The current allowance of `toUser`
   **/
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

  /**
   * @notice Delegates borrowing power to a user on the specific debt token via ERC712 signature
   * @param delegator The delegator of the credit
   * @param delegatee The delegatee that can use the credit
   * @param value The amount to be delegated
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v The V signature param
   * @param s The S signature param
   * @param r The R signature param
   */
  function delegationWithSig(
    address delegator,
    address delegatee,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IDelegationToken
 *
 * @notice Implements an interface for tokens with delegation COMP/UNI compatible
 **/
interface IDelegationToken {
  /**
   * @notice Delegate voting power to a delegatee
   * @param delegatee The address of the delegatee
   */
  function delegate(address delegatee) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';

/**
 * @title IERC20WithPermit
 *
 * @notice Interface for the permit function (EIP-2612)
 **/
interface IERC20WithPermit is IERC20 {
  /**
   * @notice Allow passing a signed message to approve spending
   * @dev implements the permit function as for
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner The owner of the funds
   * @param spender The spender
   * @param value The amount
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v Signature param
   * @param s Signature param
   * @param r Signature param
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
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IFintochIncentivesController
 *
 * @notice Defines the basic interface for an Fintoch Incentives Controller.
 **/
interface IFintochIncentivesController {
  /**
   * @dev Emitted during `handleAction`, `claimRewards` and `claimRewardsOnBehalf`
   * @param user The user that accrued rewards
   * @param amount The amount of accrued rewards
   */
  event RewardsAccrued(address indexed user, uint256 amount);

  event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted during `claimRewards` and `claimRewardsOnBehalf`
   * @param user The address that accrued rewards
   * @param to The address that will be receiving the rewards
   * @param claimer The address that performed the claim
   * @param amount The amount of rewards
   */
  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  /**
   * @dev Emitted during `setClaimer`
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  event ClaimerSet(address indexed user, address indexed claimer);

  /**
   * @notice Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index
   * @return The emission per second
   * @return The last updated timestamp
   **/
  function getAssetData(address asset)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /**
   * LEGACY **************************
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
  function assets(address asset)
    external
    view
    returns (
      uint128,
      uint128,
      uint256
    );

  /**
   * @notice Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @notice Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @notice Configure assets for a certain rewards emission
   * @param assets The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
    external;

  /**
   * @notice Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param userBalance The balance of the user of the asset in the pool
   * @param totalSupply The total supply of the asset in the pool
   **/
  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @notice Returns the total of rewards of a user, already accrued + not yet accrued
   * @param assets The assets to accumulate rewards for
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @notice Claims reward for a user, on the assets of the pool, accumulating the pending rewards
   * @param assets The assets to accumulate rewards for
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Claims reward for a user on its behalf, on the assets of the pool, accumulating the pending rewards.
   * @dev The caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The assets to accumulate rewards for
   * @param amount The amount of rewards to claim
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @return The amount of rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  /**
   * @notice Returns the unclaimed rewards of the user
   * @param user The address of the user
   * @return The unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);

  /**
   * @notice Returns the user index for a specific asset
   * @param user The address of the user
   * @param asset The asset to incentivize
   * @return The user index for the asset
   */
  function getUserAssetData(address user, address asset) external view returns (uint256);

  /**
   * @notice for backward compatibility with previous implementation of the Incentives controller
   * @return The address of the reward token
   */
  function REWARD_TOKEN() external view returns (address);

  /**
   * @notice for backward compatibility with previous implementation of the Incentives controller
   * @return The precision used in the incentives controller
   */
  function PRECISION() external view returns (uint8);

  /**
   * @dev Gets the distribution end timestamp of the emissions
   */
  function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IPriceOracleGetter} from './IPriceOracleGetter.sol';
import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IFintochOracle
 *
 * @notice Defines the basic interface for the Fintoch Oracle
 */
interface IFintochOracle is IPriceOracleGetter {
  /**
   * @dev Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

  /**
   * @dev Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
  event AssetSourceUpdated(address indexed asset, address indexed source);

  /**
   * @dev Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Sets or replaces price sources of assets
   * @param assets The addresses of the assets
   * @param sources The addresses of the price sources
   */
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;

  /**
   * @notice Sets the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function setFallbackOracle(address fallbackOracle) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (address);

  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IFintochIncentivesController} from './IFintochIncentivesController.sol';
import {IL1Pool} from './IL1Pool.sol';

/**
 * @title IInitializableAToken
 *
 * @notice Interface for the initialize function on AToken
 **/
interface IInitializableAToken {
  /**
   * @dev Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param aTokenDecimals The decimals of the underlying
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 aTokenDecimals,
    string aTokenName,
    string aTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the aToken
   * @param pool The pool contract that is initializing this contract
   * @param treasury The address of the Fintoch treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IL1Pool pool,
    address treasury,
    address underlyingAsset,
    IFintochIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IFintochIncentivesController} from './IFintochIncentivesController.sol';
import {IL1Pool} from './IL1Pool.sol';

/**
 * @title IInitializableDebtToken
 *
 * @notice Interface for the initialize function common between debt tokens
 **/
interface IInitializableDebtToken {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param incentivesController The address of the incentives controller for this aToken
   * @param debtTokenDecimals The decimals of the debt token
   * @param debtTokenName The name of the debt token
   * @param debtTokenSymbol The symbol of the debt token
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the debt token.
   * @param pool The pool contract that is initializing this contract
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IL1Pool pool,
    address underlyingAsset,
    IFintochIncentivesController incentivesController,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

interface IInvestmentEarnings {

    event NotedCancelReinvest(string orderId);
    event NotedWithdraw(uint64[] recordIds);
    event Liquidated(string orderId);
    event Processed(string orderId);

    function noteCancelReinvest(string calldata orderId) external;

    function noteWithdrawal(uint64[] calldata recordIds) external;

    function liquidatedAssets(string calldata orderId) external;

    function processBorrowing(string calldata orderId) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IL1Pool
 *
 * @notice Defines the basic interface for an L1 Fintoch Pool.
 **/
interface IL1Pool {
    /**
     * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   **/
    event MintUnbacked(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   **/
    event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

    /**
     * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   **/
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool useATokens
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        DataTypes.InterestRateMode interestRateMode
    );

    /**
     * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

    /**
     * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   **/
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   **/
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @dev Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function mintUnbacked(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   **/
    function backUnbacked(
        address asset,
        uint256 amount,
        uint256 fee
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   **/
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   **/
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   **/
    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.Fintoch.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.Fintoch.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
    function getUserAccountData(address user)
    external
    view
    returns (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );

    /**
     * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   **/
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
    external;

    /**
     * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
    function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
    function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   **/
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   **/
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
    function updateFlashloanPremiums(
        uint128 flashLoanPremiumTotal,
        uint128 flashLoanPremiumToProtocol
    ) external;

    /**
     * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
    function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

    /**
     * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
    function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

    /**
     * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
    function getUserEMode(address user) external view returns (uint256);

    /**
     * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
    function resetIsolationModeTotalDebt(address asset) external;

    /**
     * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

    /**
     * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   **/
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IL2Pool
 *
 * @notice Defines the basic extension interface for an L2 Fintoch Pool.
 **/
interface IL2Pool {
  /**
   * @notice Calldata efficient wrapper of the supply function on behalf of the caller
   * @param args Arguments for the supply function packed in one bytes32
   *    96 bits       16 bits         128 bits      16 bits
   * | 0-padding | referralCode | shortenedAmount | assetId |
   * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
   * type(uint256).max
   * @dev assetId is the index of the asset in the reservesList.
   */
  function supply(bytes32 args) external;

  /**
   * @notice Calldata efficient wrapper of the supplyWithPermit function on behalf of the caller
   * @param args Arguments for the supply function packed in one bytes32
   *    56 bits    8 bits         32 bits           16 bits         128 bits      16 bits
   * | 0-padding | permitV | shortenedDeadline | referralCode | shortenedAmount | assetId |
   * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
   * type(uint256).max
   * @dev assetId is the index of the asset in the reservesList.
   * @param r The R parameter of ERC712 permit sig
   * @param s The S parameter of ERC712 permit sig
   */
  function supplyWithPermit(
    bytes32 args,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Calldata efficient wrapper of the withdraw function, withdrawing to the caller
   * @param args Arguments for the withdraw function packed in one bytes32
   *    112 bits       128 bits      16 bits
   * | 0-padding | shortenedAmount | assetId |
   * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
   * type(uint256).max
   * @dev assetId is the index of the asset in the reservesList.
   */
  function withdraw(bytes32 args) external;

  /**
   * @notice Calldata efficient wrapper of the borrow function, borrowing on behalf of the caller
   * @param args Arguments for the borrow function packed in one bytes32
   *    88 bits       16 bits             8 bits                 128 bits       16 bits
   * | 0-padding | referralCode | shortenedInterestRateMode | shortenedAmount | assetId |
   * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
   * type(uint256).max
   * @dev assetId is the index of the asset in the reservesList.
   */
  function borrow(bytes32 args) external;

  /**
   * @notice Calldata efficient wrapper of the repay function, repaying on behalf of the caller
   * @param args Arguments for the repay function packed in one bytes32
   *    104 bits             8 bits               128 bits       16 bits
   * | 0-padding | shortenedInterestRateMode | shortenedAmount | assetId |
   * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
   * type(uint256).max
   * @dev assetId is the index of the asset in the reservesList.
   * @return The final amount repaid
   */
  function repay(bytes32 args) external returns (uint256);

  /**
   * @notice Calldata efficient wrapper of the repayWithPermit function, repaying on behalf of the caller
   * @param args Arguments for the repayWithPermit function packed in one bytes32
   *    64 bits    8 bits        32 bits                   8 bits               128 bits       16 bits
   * | 0-padding | permitV | shortenedDeadline | shortenedInterestRateMode | shortenedAmount | assetId |
   * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
   * type(uint256).max
   * @dev assetId is the index of the asset in the reservesList.
   * @param r The R parameter of ERC712 permit sig
   * @param s The S parameter of ERC712 permit sig
   * @return The final amount repaid
   */
  function repayWithPermit(
    bytes32 args,
    bytes32 r,
    bytes32 s
  ) external returns (uint256);

  /**
   * @notice Calldata efficient wrapper of the repayWithATokens function
   * @param args Arguments for the repayWithATokens function packed in one bytes32
   *    104 bits             8 bits               128 bits       16 bits
   * | 0-padding | shortenedInterestRateMode | shortenedAmount | assetId |
   * @dev the shortenedAmount is cast to 256 bits at decode time, if type(uint128).max the value will be expanded to
   * type(uint256).max
   * @dev assetId is the index of the asset in the reservesList.
   * @return The final amount repaid
   */
  function repayWithATokens(bytes32 args) external returns (uint256);

  /**
   * @notice Calldata efficient wrapper of the swapBorrowRateMode function
   * @param args Arguments for the swapBorrowRateMode function packed in one bytes32
   *    232 bits            8 bits             16 bits
   * | 0-padding | shortenedInterestRateMode | assetId |
   * @dev assetId is the index of the asset in the reservesList.
   */
  function swapBorrowRateMode(bytes32 args) external;

  /**
   * @notice Calldata efficient wrapper of the rebalanceStableBorrowRate function
   * @param args Arguments for the rebalanceStableBorrowRate function packed in one bytes32
   *    80 bits      160 bits     16 bits
   * | 0-padding | user address | assetId |
   * @dev assetId is the index of the asset in the reservesList.
   */
  function rebalanceStableBorrowRate(bytes32 args) external;

  /**
   * @notice Calldata efficient wrapper of the setUserUseReserveAsCollateral function
   * @param args Arguments for the setUserUseReserveAsCollateral function packed in one bytes32
   *    239 bits         1 bit       16 bits
   * | 0-padding | useAsCollateral | assetId |
   * @dev assetId is the index of the asset in the reservesList.
   */
  function setUserUseReserveAsCollateral(bytes32 args) external;

  /**
   * @notice Calldata efficient wrapper of the liquidationCall function
   * @param args1 part of the arguments for the liquidationCall function packed in one bytes32
   *    64 bits      160 bits       16 bits         16 bits
   * | 0-padding | user address | debtAssetId | collateralAssetId |
   * @param args2 part of the arguments for the liquidationCall function packed in one bytes32
   *    127 bits       1 bit             128 bits
   * | 0-padding | receiveAToken | shortenedDebtToCover |
   * @dev the shortenedDebtToCover is cast to 256 bits at decode time,
   * if type(uint128).max the value will be expanded to type(uint256).max
   */
  function liquidationCall(bytes32 args1, bytes32 args2) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an Fintoch Pool.
 **/
interface IPool {

    // An event sent when a redemption is triggered to the given address.
    event Redeemed(
        address from,
        address to,
        address erc20contract,
        uint256 transfer
    );

    // An event sent when a mint is triggered to the given address.
    event Mint(
        address from,
        address to,
        uint256 value
    );

    /**
    * @notice Use matching pool tokens to exchange for the source token
   * @param destination: the token receiver address.
   * @param value: the token value, in token minimum unit.
   */
    function redemption(
        address destination,
        uint256 value
    ) external;

    /**
     * @notice Mint matching pool tokens to destination, at the same time need to deduct the caller's source token
   * @param destination The address for receive the token
   * @param value The amount of token to mint
   */
    function mint(
        address destination,
        uint256 value
    ) external payable;

    function cancelReinvest(
        string calldata orderId
    ) external;

    function withdrawalIncome(
        uint64[] calldata recordIds
    ) external;

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IPoolAddressesProvider
 *
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Fintoch market to which this contract points to.
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Fintoch markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   **/
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   **/
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IPoolAddressesProviderRegistry
 *
 * @notice Defines the basic interface for an Fintoch Pool Addresses Provider Registry.
 **/
interface IPoolAddressesProviderRegistry {
  /**
   * @dev Emitted when a new AddressesProvider is registered.
   * @param addressesProvider The address of the registered PoolAddressesProvider
   * @param id The id of the registered PoolAddressesProvider
   */
  event AddressesProviderRegistered(address indexed addressesProvider, uint256 indexed id);

  /**
   * @dev Emitted when an AddressesProvider is unregistered.
   * @param addressesProvider The address of the unregistered PoolAddressesProvider
   * @param id The id of the unregistered PoolAddressesProvider
   */
  event AddressesProviderUnregistered(address indexed addressesProvider, uint256 indexed id);

  /**
   * @notice Returns the list of registered addresses providers
   * @return The list of addresses providers
   **/
  function getAddressesProvidersList() external view returns (address[] memory);

  /**
   * @notice Returns the id of a registered PoolAddressesProvider
   * @param addressesProvider The address of the PoolAddressesProvider
   * @return The id of the PoolAddressesProvider or 0 if is not registered
   */
  function getAddressesProviderIdByAddress(address addressesProvider)
    external
    view
    returns (uint256);

  /**
   * @notice Returns the address of a registered PoolAddressesProvider
   * @param id The id of the market
   * @return The address of the PoolAddressesProvider with the given id or zero address if it is not registered
   */
  function getAddressesProviderAddressById(uint256 id) external view returns (address);

  /**
   * @notice Registers an addresses provider
   * @dev The PoolAddressesProvider must not already be registered in the registry
   * @dev The id must not be used by an already registered PoolAddressesProvider
   * @param provider The address of the new PoolAddressesProvider
   * @param id The id for the new PoolAddressesProvider, referring to the market it belongs to
   **/
  function registerAddressesProvider(address provider, uint256 id) external;

  /**
   * @notice Removes an addresses provider from the list of registered addresses providers
   * @param provider The PoolAddressesProvider address
   **/
  function unregisterAddressesProvider(address provider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {ConfiguratorInputTypes} from '../protocol/libraries/types/ConfiguratorInputTypes.sol';

/**
 * @title IPoolConfigurator
 *
 * @notice Defines the basic interface for a Pool configurator.
 **/
interface IPoolConfigurator {
  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param aToken The address of the associated aToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when borrowing is enabled or disabled on a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing is enabled, false otherwise
   **/
  event ReserveBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when stable rate borrowing is enabled or disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing is enabled, false otherwise
   **/
  event ReserveStableRateBorrowing(address indexed asset, bool enabled);

  /**
   * @dev Emitted when a reserve is activated or deactivated
   * @param asset The address of the underlying asset of the reserve
   * @param active True if reserve is active, false otherwise
   **/
  event ReserveActive(address indexed asset, bool active);

  /**
   * @dev Emitted when a reserve is frozen or unfrozen
   * @param asset The address of the underlying asset of the reserve
   * @param frozen True if reserve is frozen, false otherwise
   **/
  event ReserveFrozen(address indexed asset, bool frozen);

  /**
   * @dev Emitted when a reserve is paused or unpaused
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if reserve is paused, false otherwise
   **/
  event ReservePaused(address indexed asset, bool paused);

  /**
   * @dev Emitted when a reserve is dropped.
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDropped(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldReserveFactor The old reserve factor, expressed in bps
   * @param newReserveFactor The new reserve factor, expressed in bps
   **/
  event ReserveFactorChanged(
    address indexed asset,
    uint256 oldReserveFactor,
    uint256 newReserveFactor
  );

  /**
   * @dev Emitted when the borrow cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldBorrowCap The old borrow cap
   * @param newBorrowCap The new borrow cap
   **/
  event BorrowCapChanged(address indexed asset, uint256 oldBorrowCap, uint256 newBorrowCap);

  /**
   * @dev Emitted when the supply cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldSupplyCap The old supply cap
   * @param newSupplyCap The new supply cap
   **/
  event SupplyCapChanged(address indexed asset, uint256 oldSupplyCap, uint256 newSupplyCap);

  /**
   * @dev Emitted when the liquidation protocol fee of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldFee The old liquidation protocol fee, expressed in bps
   * @param newFee The new liquidation protocol fee, expressed in bps
   **/
  event LiquidationProtocolFeeChanged(address indexed asset, uint256 oldFee, uint256 newFee);

  /**
   * @dev Emitted when the unbacked mint cap of a reserve is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldUnbackedMintCap The old unbacked mint cap
   * @param newUnbackedMintCap The new unbacked mint cap
   */
  event UnbackedMintCapChanged(
    address indexed asset,
    uint256 oldUnbackedMintCap,
    uint256 newUnbackedMintCap
  );

  /**
   * @dev Emitted when the category of an asset in eMode is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldCategoryId The old eMode asset category
   * @param newCategoryId The new eMode asset category
   **/
  event EModeAssetCategoryChanged(address indexed asset, uint8 oldCategoryId, uint8 newCategoryId);

  /**
   * @dev Emitted when a new eMode category is added.
   * @param categoryId The new eMode category id
   * @param ltv The ltv for the asset category in eMode
   * @param liquidationThreshold The liquidationThreshold for the asset category in eMode
   * @param liquidationBonus The liquidationBonus for the asset category in eMode
   * @param oracle The optional address of the price oracle specific for this category
   * @param label A human readable identifier for the category
   **/
  event EModeCategoryAdded(
    uint8 indexed categoryId,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    address oracle,
    string label
  );

  /**
   * @dev Emitted when a reserve interest strategy contract is updated.
   * @param asset The address of the underlying asset of the reserve
   * @param oldStrategy The address of the old interest strategy contract
   * @param newStrategy The address of the new interest strategy contract
   **/
  event ReserveInterestRateStrategyChanged(
    address indexed asset,
    address oldStrategy,
    address newStrategy
  );

  /**
   * @dev Emitted when an aToken implementation is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The aToken proxy address
   * @param implementation The new aToken implementation
   **/
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a stable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The stable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a variable debt token is upgraded.
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The variable debt token proxy address
   * @param implementation The new aToken implementation
   **/
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the debt ceiling of an asset is set.
   * @param asset The address of the underlying asset of the reserve
   * @param oldDebtCeiling The old debt ceiling
   * @param newDebtCeiling The new debt ceiling
   **/
  event DebtCeilingChanged(address indexed asset, uint256 oldDebtCeiling, uint256 newDebtCeiling);

  /**
   * @dev Emitted when the the siloed borrowing state for an asset is changed.
   * @param asset The address of the underlying asset of the reserve
   * @param oldState The old siloed borrowing state
   * @param newState The new siloed borrowing state
   **/
  event SiloedBorrowingChanged(address indexed asset, bool oldState, bool newState);

  /**
   * @dev Emitted when the bridge protocol fee is updated.
   * @param oldBridgeProtocolFee The old protocol fee, expressed in bps
   * @param newBridgeProtocolFee The new protocol fee, expressed in bps
   */
  event BridgeProtocolFeeUpdated(uint256 oldBridgeProtocolFee, uint256 newBridgeProtocolFee);

  /**
   * @dev Emitted when the total premium on flashloans is updated.
   * @param oldFlashloanPremiumTotal The old premium, expressed in bps
   * @param newFlashloanPremiumTotal The new premium, expressed in bps
   **/
  event FlashloanPremiumTotalUpdated(
    uint128 oldFlashloanPremiumTotal,
    uint128 newFlashloanPremiumTotal
  );

  /**
   * @dev Emitted when the part of the premium that goes to protocol is updated.
   * @param oldFlashloanPremiumToProtocol The old premium, expressed in bps
   * @param newFlashloanPremiumToProtocol The new premium, expressed in bps
   **/
  event FlashloanPremiumToProtocolUpdated(
    uint128 oldFlashloanPremiumToProtocol,
    uint128 newFlashloanPremiumToProtocol
  );

  /**
   * @dev Emitted when the reserve is set as borrowable/non borrowable in isolation mode.
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the reserve is borrowable in isolation, false otherwise
   **/
  event BorrowableInIsolationChanged(address asset, bool borrowable);

  /**
   * @notice Initializes multiple reserves.
   * @param input The array of initialization parameters
   **/
  function initReserves(ConfiguratorInputTypes.InitReserveInput[] calldata input) external;

  /**
   * @dev Updates the aToken implementation for the reserve.
   * @param input The aToken update parameters
   **/
  function updateAToken(ConfiguratorInputTypes.UpdateATokenInput calldata input) external;

  /**
   * @notice Updates the stable debt token implementation for the reserve.
   * @param input The stableDebtToken update parameters
   **/
  function updateStableDebtToken(ConfiguratorInputTypes.UpdateDebtTokenInput calldata input)
    external;

  /**
   * @notice Updates the variable debt token implementation for the asset.
   * @param input The variableDebtToken update parameters
   **/
  function updateVariableDebtToken(ConfiguratorInputTypes.UpdateDebtTokenInput calldata input)
    external;

  /**
   * @notice Configures borrowing on a reserve.
   * @dev Can only be disabled (set to false) if stable borrowing is disabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if borrowing needs to be enabled, false otherwise
   **/
  function setReserveBorrowing(address asset, bool enabled) external;

  /**
   * @notice Configures the reserve collateralization parameters.
   * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
   * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external;

  /**
   * @notice Enable or disable stable rate borrowing on a reserve.
   * @dev Can only be enabled (set to true) if borrowing is enabled
   * @param asset The address of the underlying asset of the reserve
   * @param enabled True if stable rate borrowing needs to be enabled, false otherwise
   **/
  function setReserveStableRateBorrowing(address asset, bool enabled) external;

  /**
   * @notice Activate or deactivate a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param active True if the reserve needs to be active, false otherwise
   **/
  function setReserveActive(address asset, bool active) external;

  /**
   * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
   * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
   * @param asset The address of the underlying asset of the reserve
   * @param freeze True if the reserve needs to be frozen, false otherwise
   **/
  function setReserveFreeze(address asset, bool freeze) external;

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the
   * borrowed amount will be accumulated in the isolated collateral's total debt exposure
   * @dev Only assets of the same family (e.g. USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations
   * @param asset The address of the underlying asset of the reserve
   * @param borrowable True if the asset should be borrowable in isolation, false otherwise
   **/
  function setBorrowableInIsolation(address asset, bool borrowable) external;

  /**
   * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
   * swap interest rate, liquidate, atoken transfers).
   * @param asset The address of the underlying asset of the reserve
   * @param paused True if pausing the reserve, false if unpausing
   **/
  function setReservePause(address asset, bool paused) external;

  /**
   * @notice Updates the reserve factor of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newReserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 newReserveFactor) external;

  /**
   * @notice Sets the interest rate strategy of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newRateStrategyAddress The address of the new interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address asset, address newRateStrategyAddress)
    external;

  /**
   * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
   * are suspended.
   * @param paused True if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool paused) external;

  /**
   * @notice Updates the borrow cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newBorrowCap The new borrow cap of the reserve
   **/
  function setBorrowCap(address asset, uint256 newBorrowCap) external;

  /**
   * @notice Updates the supply cap of a reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newSupplyCap The new supply cap of the reserve
   **/
  function setSupplyCap(address asset, uint256 newSupplyCap) external;

  /**
   * @notice Updates the liquidation protocol fee of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
   **/
  function setLiquidationProtocolFee(address asset, uint256 newFee) external;

  /**
   * @notice Updates the unbacked mint cap of reserve.
   * @param asset The address of the underlying asset of the reserve
   * @param newUnbackedMintCap The new unbacked mint cap of the reserve
   **/
  function setUnbackedMintCap(address asset, uint256 newUnbackedMintCap) external;

  /**
   * @notice Assign an efficiency mode (eMode) category to asset.
   * @param asset The address of the underlying asset of the reserve
   * @param newCategoryId The new category id of the asset
   **/
  function setAssetEModeCategory(address asset, uint8 newCategoryId) external;

  /**
   * @notice Adds a new efficiency mode (eMode) category.
   * @dev If zero is provided as oracle address, the default asset oracles will be used to compute the overall debt and
   * overcollateralization of the users using this category.
   * @dev The new ltv and liquidation threshold must be greater than the base
   * ltvs and liquidation thresholds of all assets within the eMode category
   * @param categoryId The id of the category to be configured
   * @param ltv The ltv associated with the category
   * @param liquidationThreshold The liquidation threshold associated with the category
   * @param liquidationBonus The liquidation bonus associated with the category
   * @param oracle The oracle associated with the category
   * @param label A label identifying the category
   **/
  function setEModeCategory(
    uint8 categoryId,
    uint16 ltv,
    uint16 liquidationThreshold,
    uint16 liquidationBonus,
    address oracle,
    string calldata label
  ) external;

  /**
   * @notice Drops a reserve entirely.
   * @param asset The address of the reserve to drop
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the bridge fee collected by the protocol reserves.
   * @param newBridgeProtocolFee The part of the fee sent to the protocol treasury, expressed in bps
   */
  function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external;

  /**
   * @notice Updates the total flash loan premium.
   * Total flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra balance
   * - A part is collected by the protocol reserves
   * @dev Expressed in bps
   * @dev The premium is calculated on the total amount borrowed
   * @param newFlashloanPremiumTotal The total flashloan premium
   */
  function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal) external;

  /**
   * @notice Updates the flash loan premium collected by protocol reserves
   * @dev Expressed in bps
   * @dev The premium to protocol is calculated on the total flashloan premium
   * @param newFlashloanPremiumToProtocol The part of the flashloan premium sent to the protocol treasury
   */
  function updateFlashloanPremiumToProtocol(uint128 newFlashloanPremiumToProtocol) external;

  /**
   * @notice Sets the debt ceiling for an asset.
   * @param newDebtCeiling The new debt ceiling
   */
  function setDebtCeiling(address asset, uint256 newDebtCeiling) external;

  /**
   * @notice Sets siloed borrowing for an asset
   * @param siloed The new siloed borrowing state
   */
  function setSiloedBorrowing(address asset, bool siloed) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface IPoolDataProvider {
  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return unbacked The amount of unbacked tokens
   * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
   * @return totalAToken The total supply of the aToken
   * @return totalStableDebt The total stable debt of the reserve
   * @return totalVariableDebt The total variable debt of the reserve
   * @return liquidityRate The liquidity rate of the reserve
   * @return variableBorrowRate The variable borrow rate of the reserve
   * @return stableBorrowRate The stable borrow rate of the reserve
   * @return averageStableBorrowRate The average stable borrow rate of the reserve
   * @return liquidityIndex The liquidity index of the reserve
   * @return variableBorrowIndex The variable borrow index of the reserve
   * @return lastUpdateTimestamp The timestamp of the last update of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  /**
   * @notice Returns the total supply of aTokens for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of the aToken
   **/
  function getATokenTotalSupply(address asset) external view returns (uint256);

  /**
   * @notice Returns the total debt for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total debt for asset
   **/
  function getTotalDebt(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IPriceOracle
 *
 * @notice Defines the basic interface for a Price oracle.
 **/
interface IPriceOracle {
  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);

  /**
   * @notice Set the price of the asset
   * @param asset The address of the asset
   * @param price The price of the asset
   **/
  function setAssetPrice(address asset, uint256 price) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IPriceOracleGetter
 *
 * @notice Interface for the Fintoch price oracle.
 **/
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   **/
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   **/
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IPriceOracleSentinel
 *
 * @notice Defines the basic interface for the PriceOracleSentinel
 */
interface IPriceOracleSentinel {
  /**
   * @dev Emitted after the sequencer oracle is updated
   * @param newSequencerOracle The new sequencer oracle
   */
  event SequencerOracleUpdated(address newSequencerOracle);

  /**
   * @dev Emitted after the grace period is updated
   * @param newGracePeriod The new grace period value
   */
  event GracePeriodUpdated(uint256 newGracePeriod);

  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns true if the `borrow` operation is allowed.
   * @dev Operation not allowed when PriceOracle is down or grace period not passed.
   * @return True if the `borrow` operation is allowed, false otherwise.
   */
  function isBorrowAllowed() external view returns (bool);

  /**
   * @notice Returns true if the `liquidation` operation is allowed.
   * @dev Operation not allowed when PriceOracle is down or grace period not passed.
   * @return True if the `liquidation` operation is allowed, false otherwise.
   */
  function isLiquidationAllowed() external view returns (bool);

  /**
   * @notice Updates the address of the sequencer oracle
   * @param newSequencerOracle The address of the new Sequencer Oracle to use
   */
  function setSequencerOracle(address newSequencerOracle) external;

  /**
   * @notice Updates the duration of the grace period
   * @param newGracePeriod The value of the new grace period duration
   */
  function setGracePeriod(uint256 newGracePeriod) external;

  /**
   * @notice Returns the SequencerOracle
   * @return The address of the sequencer oracle contract
   */
  function getSequencerOracle() external view returns (address);

  /**
   * @notice Returns the grace period
   * @return The duration of the grace period
   */
  function getGracePeriod() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IReserveInterestRateStrategy
 *
 * @notice Interface for the calculation of the interest rates
 */
interface IReserveInterestRateStrategy {
  /**
   * @notice Returns the base variable borrow rate
   * @return The base variable borrow rate, expressed in ray
   **/
  function getBaseVariableBorrowRate() external view returns (uint256);

  /**
   * @notice Returns the maximum variable borrow rate
   * @return The maximum variable borrow rate, expressed in ray
   **/
  function getMaxVariableBorrowRate() external view returns (uint256);

  /**
   * @notice Calculates the interest rates depending on the reserve's state and configurations
   * @param params The parameters needed to calculate interest rates
   * @return liquidityRate The liquidity rate expressed in rays
   * @return stableBorrowRate The stable borrow rate expressed in rays
   * @return variableBorrowRate The variable borrow rate expressed in rays
   **/
  function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IScaledBalanceToken
 *
 * @notice Defines the basic interface for a scaledbalance token.
 **/
interface IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted scaled balance tokens
   * @param value The amount being minted (user entered amount + balance increase from interest)
   * @param balanceIncrease The increase in balance since the last action of the user
   * @param index The next liquidity index of the reserve
   **/
  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @dev Emitted after scaled balance tokens are burned
   * @param from The address from which the scaled tokens will be burned
   * @param target The address that will receive the underlying, if any
   * @param value The amount being burned (user entered amount - balance increase from interest)
   * @param balanceIncrease The increase in balance since the last action of the user
   * @param index The next liquidity index of the reserve
   **/
  event Burn(
    address indexed from,
    address indexed target,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @notice Returns the scaled balance of the user.
   * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
   * at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @notice Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);

  /**
   * @notice Returns last index interest was accrued to the user's balance
   * @param user The address of the user
   * @return The last index interest was accrued to the user's balance, expressed in ray
   **/
  function getPreviousIndex(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title ISequencerOracle
 *
 * @notice Defines the basic interface for a Sequencer oracle.
 */
interface ISequencerOracle {
  /**
   * @notice Returns the health status of the sequencer.
   * @return roundId The round ID from the aggregator for which the data was retrieved combined with a phase to ensure
   * that round IDs get larger as time moves forward.
   * @return answer The answer for the latest round: 0 if the sequencer is up, 1 if it is down.
   * @return startedAt The timestamp when the round was started.
   * @return updatedAt The timestamp of the block in which the answer was updated on L1.
   * @return answeredInRound The round ID of the round in which the answer was computed.
   */
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IInitializableDebtToken} from './IInitializableDebtToken.sol';

/**
 * @title IStableDebtToken
 *
 * @notice Defines the interface for the stable debt token
 * @dev It does not inherit from IERC20 to save in code size
 **/
interface IStableDebtToken is IInitializableDebtToken {
  /**
   * @dev Emitted when new stable debt is minted
   * @param user The address of the user who triggered the minting
   * @param onBehalfOf The recipient of stable debt tokens
   * @param amount The amount minted (user entered amount + balance increase from interest)
   * @param currentBalance The current balance of the user
   * @param balanceIncrease The increase in balance since the last action of the user
   * @param newRate The rate of the debt after the minting
   * @param avgStableRate The next average stable rate after the minting
   * @param newTotalSupply The next total supply of the stable debt token after the action
   **/
  event Mint(
    address indexed user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 newRate,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @dev Emitted when new stable debt is burned
   * @param from The address from which the debt will be burned
   * @param amount The amount being burned (user entered amount - balance increase from interest)
   * @param currentBalance The current balance of the user
   * @param balanceIncrease The the increase in balance since the last action of the user
   * @param avgStableRate The next average stable rate after the burning
   * @param newTotalSupply The next total supply of the stable debt token after the action
   **/
  event Burn(
    address indexed from,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @notice Mints debt token to the `onBehalfOf` address.
   * @dev The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt tokens to mint
   * @param rate The rate of the debt being minted
   * @return True if it is the first borrow, false otherwise
   * @return The total stable debt
   * @return The average stable borrow rate
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 rate
  )
    external
    returns (
      bool,
      uint256,
      uint256
    );

  /**
   * @notice Burns debt of `user`
   * @dev The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @dev In some instances, a burn transaction will emit a mint event
   * if the amount to burn is less than the interest the user earned
   * @param from The address from which the debt will be burned
   * @param amount The amount of debt tokens getting burned
   * @return The total stable debt
   * @return The average stable borrow rate
   **/
  function burn(address from, uint256 amount) external returns (uint256, uint256);

  /**
   * @notice Returns the average rate of all the stable rate loans.
   * @return The average stable rate
   **/
  function getAverageStableRate() external view returns (uint256);

  /**
   * @notice Returns the stable rate of the user debt
   * @param user The address of the user
   * @return The stable rate of the user
   **/
  function getUserStableRate(address user) external view returns (uint256);

  /**
   * @notice Returns the timestamp of the last update of the user
   * @param user The address of the user
   * @return The timestamp
   **/
  function getUserLastUpdated(address user) external view returns (uint40);

  /**
   * @notice Returns the principal, the total supply, the average stable rate and the timestamp for the last update
   * @return The principal
   * @return The total supply
   * @return The average stable rate
   * @return The timestamp of the last update
   **/
  function getSupplyData()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint40
    );

  /**
   * @notice Returns the timestamp of the last update of the total supply
   * @return The timestamp
   **/
  function getTotalSupplyLastUpdated() external view returns (uint40);

  /**
   * @notice Returns the total supply and the average stable rate
   * @return The total supply
   * @return The average rate
   **/
  function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);

  /**
   * @notice Returns the principal debt balance of the user
   * @return The debt balance of the user since the last burn/mint action
   **/
  function principalBalanceOf(address user) external view returns (uint256);

  /**
   * @notice Returns the address of the underlying asset of this stableDebtToken (E.g. WETH for stableDebtWETH)
   * @return The address of the underlying asset
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableDebtToken} from './IInitializableDebtToken.sol';

/**
 * @title IVariableDebtToken
 *
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
  /**
   * @notice Mints debt token to the `onBehalfOf` address
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return True if the previous balance of the user is 0, false otherwise
   * @return The scaled total debt of the reserve
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool, uint256);

  /**
   * @notice Burns user variable debt
   * @dev In some instances, a burn transaction will emit a mint event
   * if the amount to burn is less than the interest that the user accrued
   * @param from The address from which the debt will be burned
   * @param amount The amount getting burned
   * @param index The variable debt index of the reserve
   * @return The scaled total debt of the reserve
   **/
  function burn(
    address from,
    uint256 amount,
    uint256 index
  ) external returns (uint256);

  /**
   * @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
   * @return The address of the underlying asset
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {AggregatorInterface} from '../dependencies/chainlink/AggregatorInterface.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';
import {IACLManager} from '../interfaces/IACLManager.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {IFintochOracle} from '../interfaces/IFintochOracle.sol';

/**
 * @title FintochOracle
 *
 * @notice Contract to get asset prices, manage price sources and update the fallback oracle
 * - Use of Chainlink Aggregators as first source of price
 * - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallback oracle
 * - Owned by the Fintoch governance
 */
contract FintochOracle is IFintochOracle {
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  // Map of asset price sources (asset => priceSource)
  mapping(address => AggregatorInterface) private assetsSources;

  IPriceOracleGetter private _fallbackOracle;
  address public immutable override BASE_CURRENCY;
  uint256 public immutable override BASE_CURRENCY_UNIT;

  /**
   * @dev Only asset listing or pool admin can call functions marked by this modifier.
   **/
  modifier onlyAssetListingOrPoolAdmins() {
    _onlyAssetListingOrPoolAdmins();
    _;
  }

  /**
   * @notice Constructor
   * @param provider The address of the new PoolAddressesProvider
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   * @param fallbackOracle The address of the fallback oracle to use if the data of an
   *        aggregator is not consistent
   * @param baseCurrency The base currency used for the price quotes. If USD is used, base currency is 0x0
   * @param baseCurrencyUnit The unit of the base currency
   */
  constructor(
    IPoolAddressesProvider provider,
    address[] memory assets,
    address[] memory sources,
    address fallbackOracle,
    address baseCurrency,
    uint256 baseCurrencyUnit
  ) {
    ADDRESSES_PROVIDER = provider;
    _setFallbackOracle(fallbackOracle);
    _setAssetsSources(assets, sources);
    BASE_CURRENCY = baseCurrency;
    BASE_CURRENCY_UNIT = baseCurrencyUnit;
    emit BaseCurrencySet(baseCurrency, baseCurrencyUnit);
  }

  /// @inheritdoc IFintochOracle
  function setAssetSources(address[] calldata assets, address[] calldata sources)
    external
    override
    onlyAssetListingOrPoolAdmins
  {
    _setAssetsSources(assets, sources);
  }

  /// @inheritdoc IFintochOracle
  function setFallbackOracle(address fallbackOracle)
    external
    override
    onlyAssetListingOrPoolAdmins
  {
    _setFallbackOracle(fallbackOracle);
  }

  /**
   * @notice Internal function to set the sources for each asset
   * @param assets The addresses of the assets
   * @param sources The address of the source of each asset
   */
  function _setAssetsSources(address[] memory assets, address[] memory sources) internal {
    require(assets.length == sources.length, Errors.INCONSISTENT_PARAMS_LENGTH);
    for (uint256 i = 0; i < assets.length; i++) {
      assetsSources[assets[i]] = AggregatorInterface(sources[i]);
      emit AssetSourceUpdated(assets[i], sources[i]);
    }
  }

  /**
   * @notice Internal function to set the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function _setFallbackOracle(address fallbackOracle) internal {
    _fallbackOracle = IPriceOracleGetter(fallbackOracle);
    emit FallbackOracleUpdated(fallbackOracle);
  }

  /// @inheritdoc IPriceOracleGetter
  function getAssetPrice(address asset) public view override returns (uint256) {
    AggregatorInterface source = assetsSources[asset];

    if (asset == BASE_CURRENCY) {
      return BASE_CURRENCY_UNIT;
    } else if (address(source) == address(0)) {
      return _fallbackOracle.getAssetPrice(asset);
    } else {
      int256 price = source.latestAnswer();
      if (price > 0) {
        return uint256(price);
      } else {
        return _fallbackOracle.getAssetPrice(asset);
      }
    }
  }

  /// @inheritdoc IFintochOracle
  function getAssetsPrices(address[] calldata assets)
    external
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory prices = new uint256[](assets.length);
    for (uint256 i = 0; i < assets.length; i++) {
      prices[i] = getAssetPrice(assets[i]);
    }
    return prices;
  }

  /// @inheritdoc IFintochOracle
  function getSourceOfAsset(address asset) external view override returns (address) {
    return address(assetsSources[asset]);
  }

  /// @inheritdoc IFintochOracle
  function getFallbackOracle() external view returns (address) {
    return address(_fallbackOracle);
  }

  function _onlyAssetListingOrPoolAdmins() internal view {
    IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
    require(
      aclManager.isAssetListingAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../protocol/libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {WadRayMath} from '../protocol/libraries/math/WadRayMath.sol';
import {IPoolAddressesProvider} from '../interfaces/IPoolAddressesProvider.sol';
import {IStableDebtToken} from '../interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../interfaces/IVariableDebtToken.sol';
import {IL1Pool} from '../interfaces/IL1Pool.sol';
import {IPoolDataProvider} from '../interfaces/IPoolDataProvider.sol';

/**
 * @title FintochProtocolDataProvider
 *
 * @notice Peripheral contract to collect and pre-process information from the Pool.
 */
contract FintochProtocolDataProvider is IPoolDataProvider {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using WadRayMath for uint256;

  address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
  address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  constructor(IPoolAddressesProvider addressesProvider) {
    ADDRESSES_PROVIDER = addressesProvider;
  }

  /**
   * @notice Returns the list of the existing reserves in the pool.
   * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
   * @return The list of reserves, pairs of symbols and addresses
   */
  function getAllReservesTokens() external view returns (TokenData[] memory) {
    IL1Pool pool = IL1Pool(ADDRESSES_PROVIDER.getPool());
    address[] memory reserves = pool.getReservesList();
    TokenData[] memory reservesTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      if (reserves[i] == MKR) {
        reservesTokens[i] = TokenData({symbol: 'MKR', tokenAddress: reserves[i]});
        continue;
      }
      if (reserves[i] == ETH) {
        reservesTokens[i] = TokenData({symbol: 'ETH', tokenAddress: reserves[i]});
        continue;
      }
      reservesTokens[i] = TokenData({
        symbol: IERC20Detailed(reserves[i]).symbol(),
        tokenAddress: reserves[i]
      });
    }
    return reservesTokens;
  }

  /**
   * @notice Returns the list of the existing ATokens in the pool.
   * @return The list of ATokens, pairs of symbols and addresses
   */
  function getAllATokens() external view returns (TokenData[] memory) {
    IL1Pool pool = IL1Pool(ADDRESSES_PROVIDER.getPool());
    address[] memory reserves = pool.getReservesList();
    TokenData[] memory aTokens = new TokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory reserveData = pool.getReserveData(reserves[i]);
      aTokens[i] = TokenData({
        symbol: IERC20Detailed(reserveData.aTokenAddress).symbol(),
        tokenAddress: reserveData.aTokenAddress
      });
    }
    return aTokens;
  }

  /**
   * @notice Returns the configuration data of the reserve
   * @dev Not returning borrow and supply caps for compatibility, nor pause flag
   * @param asset The address of the underlying asset of the reserve
   * @return decimals The number of decimals of the reserve
   * @return ltv The ltv of the reserve
   * @return liquidationThreshold The liquidationThreshold of the reserve
   * @return liquidationBonus The liquidationBonus of the reserve
   * @return reserveFactor The reserveFactor of the reserve
   * @return usageAsCollateralEnabled True if the usage as collateral is enabled, false otherwise
   * @return borrowingEnabled True if borrowing is enabled, false otherwise
   * @return stableBorrowRateEnabled True if stable rate borrowing is enabled, false otherwise
   * @return isActive True if it is active, false otherwise
   * @return isFrozen True if it is frozen, false otherwise
   **/
  function getReserveConfigurationData(address asset)
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    )
  {
    DataTypes.ReserveConfigurationMap memory configuration = IL1Pool(ADDRESSES_PROVIDER.getPool())
      .getConfiguration(asset);

    (ltv, liquidationThreshold, liquidationBonus, decimals, reserveFactor, ) = configuration
      .getParams();

    (isActive, isFrozen, borrowingEnabled, stableBorrowRateEnabled, ) = configuration.getFlags();

    usageAsCollateralEnabled = liquidationThreshold != 0;
  }

  /**
   * Returns the efficiency mode category of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The eMode id of the reserve
   */
  function getReserveEModeCategory(address asset) external view returns (uint256) {
    DataTypes.ReserveConfigurationMap memory configuration = IL1Pool(ADDRESSES_PROVIDER.getPool())
      .getConfiguration(asset);
    return configuration.getEModeCategory();
  }

  /**
   * @notice Returns the caps parameters of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return borrowCap The borrow cap of the reserve
   * @return supplyCap The supply cap of the reserve
   **/
  function getReserveCaps(address asset)
    external
    view
    returns (uint256 borrowCap, uint256 supplyCap)
  {
    (borrowCap, supplyCap) = IL1Pool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getCaps();
  }

  /**
   * @notice Returns if the pool is paused
   * @param asset The address of the underlying asset of the reserve
   * @return isPaused True if the pool is paused, false otherwise
   **/
  function getPaused(address asset) external view returns (bool isPaused) {
    (, , , , isPaused) = IL1Pool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getFlags();
  }

  /**
   * @notice Returns the siloed borrowing flag
   * @param asset The address of the underlying asset of the reserve
   * @return True if the asset is siloed for borrowing
   **/
  function getSiloedBorrowing(address asset) external view returns (bool) {
    return IL1Pool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getSiloedBorrowing();
  }

  /**
   * @notice Returns the protocol fee on the liquidation bonus
   * @param asset The address of the underlying asset of the reserve
   * @return The protocol fee on liquidation
   **/
  function getLiquidationProtocolFee(address asset) external view returns (uint256) {
    return IL1Pool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getLiquidationProtocolFee();
  }

  /**
   * @notice Returns the unbacked mint cap of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The unbacked mint cap of the reserve
   **/
  function getUnbackedMintCap(address asset) external view returns (uint256) {
    return IL1Pool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getUnbackedMintCap();
  }

  /**
   * @notice Returns the debt ceiling of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The debt ceiling of the reserve
   **/
  function getDebtCeiling(address asset) external view returns (uint256) {
    return IL1Pool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getDebtCeiling();
  }

  /**
   * @notice Returns the debt ceiling decimals
   * @return The debt ceiling decimals
   **/
  function getDebtCeilingDecimals() external pure returns (uint256) {
    return ReserveConfiguration.DEBT_CEILING_DECIMALS;
  }

  /**
   * @notice Returns the reserve data
   * @param asset The address of the underlying asset of the reserve
   * @return unbacked The amount of unbacked tokens
   * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
   * @return totalAToken The total supply of the aToken
   * @return totalStableDebt The total stable debt of the reserve
   * @return totalVariableDebt The total variable debt of the reserve
   * @return liquidityRate The liquidity rate of the reserve
   * @return variableBorrowRate The variable borrow rate of the reserve
   * @return stableBorrowRate The stable borrow rate of the reserve
   * @return averageStableBorrowRate The average stable borrow rate of the reserve
   * @return liquidityIndex The liquidity index of the reserve
   * @return variableBorrowIndex The variable borrow index of the reserve
   * @return lastUpdateTimestamp The timestamp of the last update of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    override
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    )
  {
    DataTypes.ReserveData memory reserve = IL1Pool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );

    return (
      reserve.unbacked,
      reserve.accruedToTreasury,
      IERC20Detailed(reserve.aTokenAddress).totalSupply(),
      IERC20Detailed(reserve.stableDebtTokenAddress).totalSupply(),
      IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply(),
      reserve.currentLiquidityRate,
      reserve.currentVariableBorrowRate,
      reserve.currentStableBorrowRate,
      IStableDebtToken(reserve.stableDebtTokenAddress).getAverageStableRate(),
      reserve.liquidityIndex,
      reserve.variableBorrowIndex,
      reserve.lastUpdateTimestamp
    );
  }

  /**
   * @notice Returns the total supply of aTokens for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total supply of the aToken
   **/
  function getATokenTotalSupply(address asset) external view override returns (uint256) {
    DataTypes.ReserveData memory reserve = IL1Pool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );
    return IERC20Detailed(reserve.aTokenAddress).totalSupply();
  }

  /**
   * @notice Returns the total debt for a given asset
   * @param asset The address of the underlying asset of the reserve
   * @return The total debt for asset
   **/
  function getTotalDebt(address asset) external view override returns (uint256) {
    DataTypes.ReserveData memory reserve = IL1Pool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );
    return
      IERC20Detailed(reserve.stableDebtTokenAddress).totalSupply() +
      IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply();
  }

  /**
   * @notice Returns the user data in a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param user The address of the user
   * @return currentATokenBalance The current AToken balance of the user
   * @return currentStableDebt The current stable debt of the user
   * @return currentVariableDebt The current variable debt of the user
   * @return principalStableDebt The principal stable debt of the user
   * @return scaledVariableDebt The scaled variable debt of the user
   * @return stableBorrowRate The stable borrow rate of the user
   * @return liquidityRate The liquidity rate of the reserve
   * @return stableRateLastUpdated The timestamp of the last update of the user stable rate
   * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
   *         otherwise
   **/
  function getUserReserveData(address asset, address user)
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    )
  {
    DataTypes.ReserveData memory reserve = IL1Pool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );

    DataTypes.UserConfigurationMap memory userConfig = IL1Pool(ADDRESSES_PROVIDER.getPool())
      .getUserConfiguration(user);

    currentATokenBalance = IERC20Detailed(reserve.aTokenAddress).balanceOf(user);
    currentVariableDebt = IERC20Detailed(reserve.variableDebtTokenAddress).balanceOf(user);
    currentStableDebt = IERC20Detailed(reserve.stableDebtTokenAddress).balanceOf(user);
    principalStableDebt = IStableDebtToken(reserve.stableDebtTokenAddress).principalBalanceOf(user);
    scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
    liquidityRate = reserve.currentLiquidityRate;
    stableBorrowRate = IStableDebtToken(reserve.stableDebtTokenAddress).getUserStableRate(user);
    stableRateLastUpdated = IStableDebtToken(reserve.stableDebtTokenAddress).getUserLastUpdated(
      user
    );
    usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);
  }

  /**
   * @notice Returns the token addresses of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return aTokenAddress The AToken address of the reserve
   * @return stableDebtTokenAddress The StableDebtToken address of the reserve
   * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
   */
  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    )
  {
    DataTypes.ReserveData memory reserve = IL1Pool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );

    return (
      reserve.aTokenAddress,
      reserve.stableDebtTokenAddress,
      reserve.variableDebtTokenAddress
    );
  }

  /**
   * @notice Returns the address of the Interest Rate strategy
   * @param asset The address of the underlying asset of the reserve
   * @return irStrategyAddress The address of the Interest Rate strategy
   */
  function getInterestRateStrategyAddress(address asset)
    external
    view
    returns (address irStrategyAddress)
  {
    DataTypes.ReserveData memory reserve = IL1Pool(ADDRESSES_PROVIDER.getPool()).getReserveData(
      asset
    );

    return (reserve.interestRateStrategyAddress);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {SafeCast} from '../dependencies/openzeppelin/contracts/SafeCast.sol';
import {IL1Pool} from '../interfaces/IL1Pool.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title L2Encoder
 *
 * @notice Helper contract to encode calldata, used to optimize calldata size in L2Pool for transaction cost reduction
 * only indented to help generate calldata for uses/frontends.
 */
contract L2Encoder {
  using SafeCast for uint256;
  IL1Pool public immutable POOL;

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   */
  constructor(IL1Pool pool) {
    POOL = pool;
  }

  /**
   * @notice Encodes supply parameters from standard input to compact representation of 1 bytes32
   * @dev Without an onBehalfOf parameter as the compact calls to L2Pool will use msg.sender as onBehalfOf
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param referralCode referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @return compact representation of supply parameters
   */
  function encodeSupplyParams(
    address asset,
    uint256 amount,
    uint16 referralCode
  ) external view returns (bytes32) {
    DataTypes.ReserveData memory data = POOL.getReserveData(asset);

    uint16 assetId = data.id;
    uint128 shortenedAmount = amount.toUint128();
    bytes32 res;

    assembly {
      res := add(assetId, add(shl(16, shortenedAmount), shl(144, referralCode)))
    }
    return res;
  }

  /**
   * @notice Encodes supplyWithPermit parameters from standard input to compact representation of 3 bytes32
   * @dev Without an onBehalfOf parameter as the compact calls to L2Pool will use msg.sender as onBehalfOf
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param referralCode referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return compact representation of supplyWithPermit parameters
   * @return The R parameter of ERC712 permit sig
   * @return The S parameter of ERC712 permit sig
   */
  function encodeSupplyWithPermitParams(
    address asset,
    uint256 amount,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  )
    external
    view
    returns (
      bytes32,
      bytes32,
      bytes32
    )
  {
    DataTypes.ReserveData memory data = POOL.getReserveData(asset);

    uint16 assetId = data.id;
    uint128 shortenedAmount = amount.toUint128();
    uint32 shortenedDeadline = deadline.toUint32();

    bytes32 res;
    assembly {
      res := add(
        assetId,
        add(
          shl(16, shortenedAmount),
          add(shl(144, referralCode), add(shl(160, shortenedDeadline), shl(192, permitV)))
        )
      )
    }

    return (res, permitR, permitS);
  }

  /**
   * @notice Encodes withdraw parameters from standard input to compact representation of 1 bytes32
   * @dev Without a to parameter as the compact calls to L2Pool will use msg.sender as to
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   * @return compact representation of withdraw parameters
   */
  function encodeWithdrawParams(address asset, uint256 amount) external view returns (bytes32) {
    DataTypes.ReserveData memory data = POOL.getReserveData(asset);

    uint16 assetId = data.id;
    uint128 shortenedAmount = amount == type(uint256).max ? type(uint128).max : amount.toUint128();

    bytes32 res;
    assembly {
      res := add(assetId, shl(16, shortenedAmount))
    }
    return res;
  }

  /**
   * @notice Encodes borrow parameters from standard input to compact representation of 1 bytes32
   * @dev Without an onBehalfOf parameter as the compact calls to L2Pool will use msg.sender as onBehalfOf
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @return compact representation of withdraw parameters
   */
  function encodeBorrowParams(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode
  ) external view returns (bytes32) {
    DataTypes.ReserveData memory data = POOL.getReserveData(asset);

    uint16 assetId = data.id;
    uint128 shortenedAmount = amount.toUint128();
    uint8 shortenedInterestRateMode = interestRateMode.toUint8();
    bytes32 res;
    assembly {
      res := add(
        assetId,
        add(
          shl(16, shortenedAmount),
          add(shl(144, shortenedInterestRateMode), shl(152, referralCode))
        )
      )
    }
    return res;
  }

  /**
   * @notice Encodes repay parameters from standard input to compact representation of 1 bytes32
   * @dev Without an onBehalfOf parameter as the compact calls to L2Pool will use msg.sender as onBehalfOf
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `interestRateMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return compact representation of repay parameters
   */
  function encodeRepayParams(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) public view returns (bytes32) {
    DataTypes.ReserveData memory data = POOL.getReserveData(asset);

    uint16 assetId = data.id;
    uint128 shortenedAmount = amount == type(uint256).max ? type(uint128).max : amount.toUint128();
    uint8 shortenedInterestRateMode = interestRateMode.toUint8();

    bytes32 res;
    assembly {
      res := add(assetId, add(shl(16, shortenedAmount), shl(144, shortenedInterestRateMode)))
    }
    return res;
  }

  /**
   * @notice Encodes repayWithPermit parameters from standard input to compact representation of 3 bytes32
   * @dev Without an onBehalfOf parameter as the compact calls to L2Pool will use msg.sender as onBehalfOf
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return compact representation of repayWithPermit parameters
   * @return The R parameter of ERC712 permit sig
   * @return The S parameter of ERC712 permit sig
   */
  function encodeRepayWithPermitParams(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  )
    external
    view
    returns (
      bytes32,
      bytes32,
      bytes32
    )
  {
    DataTypes.ReserveData memory data = POOL.getReserveData(asset);

    uint16 assetId = data.id;
    uint128 shortenedAmount = amount == type(uint256).max ? type(uint128).max : amount.toUint128();
    uint8 shortenedInterestRateMode = interestRateMode.toUint8();
    uint32 shortenedDeadline = deadline.toUint32();

    bytes32 res;
    assembly {
      res := add(
        assetId,
        add(
          shl(16, shortenedAmount),
          add(
            shl(144, shortenedInterestRateMode),
            add(shl(152, shortenedDeadline), shl(184, permitV))
          )
        )
      )
    }
    return (res, permitR, permitS);
  }

  /**
   * @notice Encodes repay with aToken parameters from standard input to compact representation of 1 bytes32
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return compact representation of repay with aToken parameters
   */
  function encodeRepayWithATokensParams(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external view returns (bytes32) {
    return encodeRepayParams(asset, amount, interestRateMode);
  }

  /**
   * @notice Encodes swap borrow rate mode parameters from standard input to compact representation of 1 bytes32
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   * @return compact representation of swap borrow rate mode parameters
   */
  function encodeSwapBorrowRateMode(address asset, uint256 interestRateMode)
    external
    view
    returns (bytes32)
  {
    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
    uint16 assetId = data.id;
    uint8 shortenedInterestRateMode = interestRateMode.toUint8();
    bytes32 res;
    assembly {
      res := add(assetId, shl(16, shortenedInterestRateMode))
    }
    return res;
  }

  /**
   * @notice Encodes rebalance stable borrow rate parameters from standard input to compact representation of 1 bytes32
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   * @return compact representation of rebalance stable borrow rate parameters
   */
  function encodeRebalanceStableBorrowRate(address asset, address user)
    external
    view
    returns (bytes32)
  {
    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
    uint16 assetId = data.id;

    bytes32 res;
    assembly {
      res := add(assetId, shl(16, user))
    }
    return res;
  }

  /**
   * @notice Encodes set user use reserve as collateral parameters from standard input to compact representation of 1 bytes32
   * @param asset The address of the underlying asset borrowed
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   * @return compact representation of set user use reserve as collateral parameters
   */
  function encodeSetUserUseReserveAsCollateral(address asset, bool useAsCollateral)
    external
    view
    returns (bytes32)
  {
    DataTypes.ReserveData memory data = POOL.getReserveData(asset);
    uint16 assetId = data.id;
    bytes32 res;
    assembly {
      res := add(assetId, shl(16, useAsCollateral))
    }
    return res;
  }

  /**
   * @notice Encodes liquidation call parameters from standard input to compact representation of 2 bytes32
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   * @return First half ot compact representation of liquidation call parameters
   * @return Second half ot compact representation of liquidation call parameters
   */
  function encodeLiquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external view returns (bytes32, bytes32) {
    DataTypes.ReserveData memory collateralData = POOL.getReserveData(collateralAsset);
    uint16 collateralAssetId = collateralData.id;

    DataTypes.ReserveData memory debtData = POOL.getReserveData(debtAsset);
    uint16 debtAssetId = debtData.id;

    uint128 shortenedDebtToCover = debtToCover == type(uint256).max
      ? type(uint128).max
      : debtToCover.toUint128();

    bytes32 res1;
    bytes32 res2;

    assembly {
      res1 := add(add(collateralAssetId, shl(16, debtAssetId)), shl(32, user))
      res2 := add(shortenedDebtToCover, shl(128, receiveAToken))
    }
    return (res1, res2);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {FlashLoanReceiverBase} from '../../flashloan/base/FlashLoanReceiverBase.sol';
import {MintableERC20} from '../tokens/MintableERC20.sol';

contract MockFlashLoanReceiver is FlashLoanReceiverBase {
  using GPv2SafeERC20 for IERC20;

  event ExecutedWithFail(address[] _assets, uint256[] _amounts, uint256[] _premiums);
  event ExecutedWithSuccess(address[] _assets, uint256[] _amounts, uint256[] _premiums);

  bool internal _failExecution;
  uint256 internal _amountToApprove;
  bool internal _simulateEOA;

  constructor(IPoolAddressesProvider provider) FlashLoanReceiverBase(provider) {}

  function setFailExecutionTransfer(bool fail) public {
    _failExecution = fail;
  }

  function setAmountToApprove(uint256 amountToApprove) public {
    _amountToApprove = amountToApprove;
  }

  function setSimulateEOA(bool flag) public {
    _simulateEOA = flag;
  }

  function getAmountToApprove() public view returns (uint256) {
    return _amountToApprove;
  }

  function simulateEOA() public view returns (bool) {
    return _simulateEOA;
  }

  function executeOperation(
    address[] memory assets,
    uint256[] memory amounts,
    uint256[] memory premiums,
    address, // initiator
    bytes memory // params
  ) public override returns (bool) {
    if (_failExecution) {
      emit ExecutedWithFail(assets, amounts, premiums);
      return !_simulateEOA;
    }

    for (uint256 i = 0; i < assets.length; i++) {
      //mint to this contract the specific amount
      MintableERC20 token = MintableERC20(assets[i]);

      //check the contract has the specified balance
      require(
        amounts[i] <= IERC20(assets[i]).balanceOf(address(this)),
        'Invalid balance for the contract'
      );

      uint256 amountToReturn = (_amountToApprove != 0)
        ? _amountToApprove
        : amounts[i] + premiums[i];
      //execution does not fail - mint tokens and return them to the _destination

      token.mint(premiums[i]);

      IERC20(assets[i]).approve(address(POOL), amountToReturn);
    }

    emit ExecutedWithSuccess(assets, amounts, premiums);

    return true;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {FlashLoanSimpleReceiverBase} from '../../flashloan/base/FlashLoanSimpleReceiverBase.sol';
import {MintableERC20} from '../tokens/MintableERC20.sol';

contract MockFlashLoanSimpleReceiver is FlashLoanSimpleReceiverBase {
  using GPv2SafeERC20 for IERC20;
  using SafeMath for uint256;

  event ExecutedWithFail(address asset, uint256 amount, uint256 premium);
  event ExecutedWithSuccess(address asset, uint256 amount, uint256 premium);

  bool internal _failExecution;
  uint256 internal _amountToApprove;
  bool internal _simulateEOA;

  constructor(IPoolAddressesProvider provider) FlashLoanSimpleReceiverBase(provider) {}

  function setFailExecutionTransfer(bool fail) public {
    _failExecution = fail;
  }

  function setAmountToApprove(uint256 amountToApprove) public {
    _amountToApprove = amountToApprove;
  }

  function setSimulateEOA(bool flag) public {
    _simulateEOA = flag;
  }

  function getAmountToApprove() public view returns (uint256) {
    return _amountToApprove;
  }

  function simulateEOA() public view returns (bool) {
    return _simulateEOA;
  }

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address, // initiator
    bytes memory // params
  ) public override returns (bool) {
    if (_failExecution) {
      emit ExecutedWithFail(asset, amount, premium);
      return !_simulateEOA;
    }

    //mint to this contract the specific amount
    MintableERC20 token = MintableERC20(asset);

    //check the contract has the specified balance
    require(amount <= IERC20(asset).balanceOf(address(this)), 'Invalid balance for the contract');

    uint256 amountToReturn = (_amountToApprove != 0) ? _amountToApprove : amount.add(premium);
    //execution does not fail - mint tokens and return them to the _destination

    token.mint(premium);

    IERC20(asset).approve(address(POOL), amountToReturn);

    emit ExecutedWithSuccess(asset, amount, premium);

    return true;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IFintochIncentivesController} from '../../interfaces/IFintochIncentivesController.sol';

contract MockIncentivesController is IFintochIncentivesController {
  function getAssetData(address)
    external
    pure
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (0, 0, 0);
  }

  function assets(address)
    external
    pure
    override
    returns (
      uint128,
      uint128,
      uint256
    )
  {
    return (0, 0, 0);
  }

  function setClaimer(address, address) external override {}

  function getClaimer(address) external pure override returns (address) {
    return address(1);
  }

  function configureAssets(address[] calldata, uint256[] calldata) external override {}

  function handleAction(
    address,
    uint256,
    uint256
  ) external override {}

  function getRewardsBalance(address[] calldata, address) external pure override returns (uint256) {
    return 0;
  }

  function claimRewards(
    address[] calldata,
    uint256,
    address
  ) external pure override returns (uint256) {
    return 0;
  }

  function claimRewardsOnBehalf(
    address[] calldata,
    uint256,
    address,
    address
  ) external pure override returns (uint256) {
    return 0;
  }

  function getUserUnclaimedRewards(address) external pure override returns (uint256) {
    return 0;
  }

  function getUserAssetData(address, address) external pure override returns (uint256) {
    return 0;
  }

  function REWARD_TOKEN() external pure override returns (address) {
    return address(0);
  }

  function PRECISION() external pure override returns (uint8) {
    return 0;
  }

  function DISTRIBUTION_END() external pure override returns (uint256) {
    return 0;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IInvestmentEarnings} from '../../interfaces/IInvestmentEarnings.sol';
import {L2Pool} from '../../protocol/pool/L2Pool.sol';

abstract contract MockL2Pool is L2Pool {

  constructor(
    IInvestmentEarnings investmentEarnings,
    address srcToken,
    address[] memory _owners,
    uint _required
  ) L2Pool(investmentEarnings, srcToken, _owners, _required) {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

contract MockPeripheryContractV1 {
  address private _manager;
  uint256 private _value;

  function initialize(address manager, uint256 value) external {
    _manager = manager;
    _value = value;
  }

  function getManager() external view returns (address) {
    return _manager;
  }

  function setManager(address newManager) external {
    _manager = newManager;
  }
}

contract MockPeripheryContractV2 {
  address private _manager;
  uint256 private _value;
  address private _addressesProvider;

  function initialize(address addressesProvider) external {
    _addressesProvider = addressesProvider;
  }

  function getManager() external view returns (address) {
    return _manager;
  }

  function setManager(address newManager) external {
    _manager = newManager;
  }

  function getAddressesProvider() external view returns (address) {
    return _addressesProvider;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IInvestmentEarnings} from '../../interfaces/IInvestmentEarnings.sol';

contract MockPool {
  // Reserved storage space to avoid layout collisions.
  uint256[100] private ______gap;

  address internal _addressesProvider;
  address[] internal _reserveList;

  function initialize(address provider) external {
    _addressesProvider = provider;
  }

  function addReserveToReservesList(address reserve) external {
    _reserveList.push(reserve);
  }

  function getReservesList() external view returns (address[] memory) {
    address[] memory reservesList = new address[](_reserveList.length);
    for (uint256 i; i < _reserveList.length; i++) {
      reservesList[i] = _reserveList[i];
    }
    return reservesList;
  }
}

import {FintochPool} from '../../protocol/pool/FintochPool.sol';

contract MockPoolInherited is FintochPool {
  uint16 internal _maxNumberOfReserves = 128;

  constructor(
    IInvestmentEarnings investmentEarnings,
    address srcToken,
    address[] memory _owners,
    uint _required
  ) FintochPool(investmentEarnings, srcToken, _owners, _required) {}

  function setMaxNumberOfReserves(uint16 newMaxNumberOfReserves) public {
    _maxNumberOfReserves = newMaxNumberOfReserves;
  }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {ReserveConfiguration} from '../../protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from '../../protocol/libraries/types/DataTypes.sol';

contract MockReserveConfiguration {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  DataTypes.ReserveConfigurationMap public configuration;

  function setLtv(uint256 ltv) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setLtv(ltv);
    configuration = config;
  }

  function getLtv() external view returns (uint256) {
    return configuration.getLtv();
  }

  function setLiquidationBonus(uint256 bonus) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setLiquidationBonus(bonus);
    configuration = config;
  }

  function getLiquidationBonus() external view returns (uint256) {
    return configuration.getLiquidationBonus();
  }

  function setLiquidationThreshold(uint256 threshold) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setLiquidationThreshold(threshold);
    configuration = config;
  }

  function getLiquidationThreshold() external view returns (uint256) {
    return configuration.getLiquidationThreshold();
  }

  function setDecimals(uint256 decimals) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setDecimals(decimals);
    configuration = config;
  }

  function getDecimals() external view returns (uint256) {
    return configuration.getDecimals();
  }

  function setFrozen(bool frozen) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setFrozen(frozen);
    configuration = config;
  }

  function getFrozen() external view returns (bool) {
    return configuration.getFrozen();
  }

  function setBorrowingEnabled(bool enabled) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setBorrowingEnabled(enabled);
    configuration = config;
  }

  function getBorrowingEnabled() external view returns (bool) {
    return configuration.getBorrowingEnabled();
  }

  function setStableRateBorrowingEnabled(bool enabled) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setStableRateBorrowingEnabled(enabled);
    configuration = config;
  }

  function getStableRateBorrowingEnabled() external view returns (bool) {
    return configuration.getStableRateBorrowingEnabled();
  }

  function setReserveFactor(uint256 reserveFactor) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setReserveFactor(reserveFactor);
    configuration = config;
  }

  function getReserveFactor() external view returns (uint256) {
    return configuration.getReserveFactor();
  }

  function setBorrowCap(uint256 borrowCap) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setBorrowCap(borrowCap);
    configuration = config;
  }

  function getBorrowCap() external view returns (uint256) {
    return configuration.getBorrowCap();
  }

  function getEModeCategory() external view returns (uint256) {
    return configuration.getEModeCategory();
  }

  function setEModeCategory(uint256 categoryId) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setEModeCategory(categoryId);
    configuration = config;
  }

  function setSupplyCap(uint256 supplyCap) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setSupplyCap(supplyCap);
    configuration = config;
  }

  function getSupplyCap() external view returns (uint256) {
    return configuration.getSupplyCap();
  }

  function setLiquidationProtocolFee(uint256 liquidationProtocolFee) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setLiquidationProtocolFee(liquidationProtocolFee);
    configuration = config;
  }

  function getLiquidationProtocolFee() external view returns (uint256) {
    return configuration.getLiquidationProtocolFee();
  }

  function setUnbackedMintCap(uint256 unbackedMintCap) external {
    DataTypes.ReserveConfigurationMap memory config = configuration;
    config.setUnbackedMintCap(unbackedMintCap);
    configuration = config;
  }

  function getUnbackedMintCap() external view returns (uint256) {
    return configuration.getUnbackedMintCap();
  }

  function getFlags()
    external
    view
    returns (
      bool,
      bool,
      bool,
      bool,
      bool
    )
  {
    return configuration.getFlags();
  }

  function getParams()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return configuration.getParams();
  }

  function getCaps() external view returns (uint256, uint256) {
    return configuration.getCaps();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

contract SelfdestructTransfer {
  function destroyAndTransfer(address payable to) external payable {
    selfdestruct(to);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

contract MockAggregator {
  int256 private _latestAnswer;

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  constructor(int256 initialAnswer) {
    _latestAnswer = initialAnswer;
    emit AnswerUpdated(initialAnswer, 0, block.timestamp);
  }

  function latestAnswer() external view returns (int256) {
    return _latestAnswer;
  }

  function getTokenType() external pure returns (uint256) {
    return 1;
  }

  function decimals() external pure returns (uint8) {
    return 8;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IPriceOracle} from '../../interfaces/IPriceOracle.sol';

contract PriceOracle is IPriceOracle {
  // Map of asset prices (asset => price)
  mapping(address => uint256) internal prices;

  uint256 internal ethPriceUsd;

  event AssetPriceUpdated(address asset, uint256 price, uint256 timestamp);
  event EthPriceUpdated(uint256 price, uint256 timestamp);

  function getAssetPrice(address asset) external view override returns (uint256) {
    return prices[asset];
  }

  function setAssetPrice(address asset, uint256 price) external override {
    prices[asset] = price;
    emit AssetPriceUpdated(asset, price, block.timestamp);
  }

  function getEthUsdPrice() external view returns (uint256) {
    return ethPriceUsd;
  }

  function setEthUsdPrice(uint256 price) external {
    ethPriceUsd = price;
    emit EthPriceUpdated(price, block.timestamp);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
import {ISequencerOracle} from '../../interfaces/ISequencerOracle.sol';

contract SequencerOracle is ISequencerOracle, Ownable {
  bool internal _isDown;
  uint256 internal _timestampGotUp;

  /**
   * @dev Constructor.
   * @param owner The owner address of this contract
   */
  constructor(address owner) {
    transferOwnership(owner);
  }

  /**
   * @notice Updates the health status of the sequencer.
   * @param isDown True if the sequencer is down, false otherwise
   * @param timestamp The timestamp of last time the sequencer got up
   */
  function setAnswer(bool isDown, uint256 timestamp) external onlyOwner {
    _isDown = isDown;
    _timestampGotUp = timestamp;
  }

  /// @inheritdoc ISequencerOracle
  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    int256 isDown;
    if (_isDown) {
      isDown = 1;
    }
    return (0, isDown, 0, _timestampGotUp, 0);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {FlashLoanSimpleReceiverBase} from '../../flashloan/base/FlashLoanSimpleReceiverBase.sol';
import {MintableERC20} from '../tokens/MintableERC20.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';
import {DataTypes} from '../../protocol/libraries/types/DataTypes.sol';

contract FlashloanAttacker is FlashLoanSimpleReceiverBase {
  using GPv2SafeERC20 for IERC20;
  using SafeMath for uint256;

  IPoolAddressesProvider internal _provider;
  IL1Pool internal _pool;

  constructor(IPoolAddressesProvider provider) FlashLoanSimpleReceiverBase(provider) {
    _pool = IL1Pool(provider.getPool());
  }

  function supplyAsset(address asset, uint256 amount) public {
    MintableERC20 token = MintableERC20(asset);
    token.mint(amount);
    token.approve(address(_pool), type(uint256).max);
    _pool.supply(asset, amount, address(this), 0);
  }

  function _innerBorrow(address asset) internal {
    DataTypes.ReserveData memory config = _pool.getReserveData(asset);
    IERC20 token = IERC20(asset);
    uint256 avail = token.balanceOf(config.aTokenAddress);
    _pool.borrow(asset, avail, 2, 0, address(this));
  }

  function executeOperation(
    address asset,
    uint256 amount,
    uint256 premium,
    address, // initiator
    bytes memory // params
  ) public override returns (bool) {
    MintableERC20 token = MintableERC20(asset);
    uint256 amountToReturn = amount.add(premium);

    // Also do a normal borrow here in the middle
    _innerBorrow(asset);

    token.mint(premium);
    IERC20(asset).approve(address(POOL), amountToReturn);

    return true;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IReserveInterestRateStrategy} from '../../interfaces/IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {WadRayMath} from '../../protocol/libraries/math/WadRayMath.sol';
import {DataTypes} from '../../protocol/libraries/types/DataTypes.sol';

contract MockReserveInterestRateStrategy is IReserveInterestRateStrategy {
  uint256 public immutable OPTIMAL_USAGE_RATIO;
  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
  uint256 internal immutable _baseVariableBorrowRate;
  uint256 internal immutable _variableRateSlope1;
  uint256 internal immutable _variableRateSlope2;
  uint256 internal immutable _stableRateSlope1;
  uint256 internal immutable _stableRateSlope2;

  uint256 internal _liquidityRate;
  uint256 internal _stableBorrowRate;
  uint256 internal _variableBorrowRate;

  constructor(
    IPoolAddressesProvider provider,
    uint256 optimalUsageRatio,
    uint256 baseVariableBorrowRate,
    uint256 variableRateSlope1,
    uint256 variableRateSlope2,
    uint256 stableRateSlope1,
    uint256 stableRateSlope2
  ) {
    OPTIMAL_USAGE_RATIO = optimalUsageRatio;
    ADDRESSES_PROVIDER = provider;
    _baseVariableBorrowRate = baseVariableBorrowRate;
    _variableRateSlope1 = variableRateSlope1;
    _variableRateSlope2 = variableRateSlope2;
    _stableRateSlope1 = stableRateSlope1;
    _stableRateSlope2 = stableRateSlope2;
  }

  function setLiquidityRate(uint256 liquidityRate) public {
    _liquidityRate = liquidityRate;
  }

  function setStableBorrowRate(uint256 stableBorrowRate) public {
    _stableBorrowRate = stableBorrowRate;
  }

  function setVariableBorrowRate(uint256 variableBorrowRate) public {
    _variableBorrowRate = variableBorrowRate;
  }

  function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory)
    external
    view
    override
    returns (
      uint256 liquidityRate,
      uint256 stableBorrowRate,
      uint256 variableBorrowRate
    )
  {
    return (_liquidityRate, _stableBorrowRate, _variableBorrowRate);
  }

  function getVariableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  function getVariableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }

  function getStableRateSlope1() external view returns (uint256) {
    return _stableRateSlope1;
  }

  function getStableRateSlope2() external view returns (uint256) {
    return _stableRateSlope2;
  }

  function getBaseVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  function getMaxVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {WadRayMath} from '../../protocol/libraries/math/WadRayMath.sol';

contract WadRayMathWrapper {
  function wad() public pure returns (uint256) {
    return WadRayMath.WAD;
  }

  function ray() public pure returns (uint256) {
    return WadRayMath.RAY;
  }

  function halfRay() public pure returns (uint256) {
    return WadRayMath.HALF_RAY;
  }

  function halfWad() public pure returns (uint256) {
    return WadRayMath.HALF_WAD;
  }

  function wadMul(uint256 a, uint256 b) public pure returns (uint256) {
    return WadRayMath.wadMul(a, b);
  }

  function wadDiv(uint256 a, uint256 b) public pure returns (uint256) {
    return WadRayMath.wadDiv(a, b);
  }

  function rayMul(uint256 a, uint256 b) public pure returns (uint256) {
    return WadRayMath.rayMul(a, b);
  }

  function rayDiv(uint256 a, uint256 b) public pure returns (uint256) {
    return WadRayMath.rayDiv(a, b);
  }

  function rayToWad(uint256 a) public pure returns (uint256) {
    return WadRayMath.rayToWad(a);
  }

  function wadToRay(uint256 a) public pure returns (uint256) {
    return WadRayMath.wadToRay(a);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {ERC20} from '../../dependencies/openzeppelin/contracts/ERC20.sol';
import {IDelegationToken} from '../../interfaces/IDelegationToken.sol';

/**
 * @title MintableDelegationERC20
 * @dev ERC20 minting logic with delegation
 */
contract MintableDelegationERC20 is IDelegationToken, ERC20 {
  address public delegatee;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20(name, symbol) {
    _setupDecimals(decimals);
  }

  /**
   * @dev Function to mint tokens
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 value) public returns (bool) {
    _mint(msg.sender, value);
    return true;
  }

  function delegate(address delegateeAddress) external override {
    delegatee = delegateeAddress;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {ERC20} from '../../dependencies/openzeppelin/contracts/ERC20.sol';
import {IERC20WithPermit} from '../../interfaces/IERC20WithPermit.sol';

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract MintableERC20 is IERC20WithPermit, ERC20 {
  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  // Map of address nonces (address => nonce)
  mapping(address => uint256) internal _nonces;

  bytes32 public DOMAIN_SEPARATOR;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) ERC20(name, symbol) {
    uint256 chainId = block.chainid;

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712_DOMAIN,
        keccak256(bytes(name)),
        keccak256(EIP712_REVISION),
        chainId,
        address(this)
      )
    );
    _setupDecimals(decimals);
  }

  /// @inheritdoc IERC20WithPermit
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(owner != address(0), 'INVALID_OWNER');
    //solium-disable-next-line
    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );
    require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
    _nonces[owner] = currentValidNonce + 1;
    _approve(owner, spender, value);
  }

  /**
   * @dev Function to mint tokens
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 value) public returns (bool) {
    _mint(_msgSender(), value);
    return true;
  }

  /**
   * @dev Function to mint tokens to address
   * @param account The account to mint tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address account, uint256 value) public returns (bool) {
    _mint(account, value);
    return true;
  }

  function nonces(address owner) public view virtual returns (uint256) {
    return _nonces[owner];
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {WETH9} from '../../dependencies/weth/WETH9.sol';

contract WETH9Mocked is WETH9 {
  // Mint not backed by Ether: only for testing purposes
  function mint(uint256 value) public returns (bool) {
    balanceOf[msg.sender] += value;
    emit Transfer(address(0), msg.sender, value);
    return true;
  }

  function mint(address account, uint256 value) public returns (bool) {
    balanceOf[account] += value;
    emit Transfer(address(0), account, value);
    return true;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {AToken} from '../../protocol/tokenization/AToken.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';
import {IFintochIncentivesController} from '../../interfaces/IFintochIncentivesController.sol';

contract MockAToken is AToken {
  constructor(IL1Pool pool) AToken(pool) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x2;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {VersionedInitializable} from '../../protocol/libraries/fintoch-upgradeability/VersionedInitializable.sol';

contract MockInitializableImple is VersionedInitializable {
  uint256 public value;
  string public text;
  uint256[] public values;

  uint256 public constant REVISION = 1;

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function initialize(
    uint256 val,
    string memory txt,
    uint256[] memory vals
  ) external initializer {
    value = val;
    text = txt;
    values = vals;
  }

  function setValue(uint256 newValue) public {
    value = newValue;
  }

  function setValueViaProxy(uint256 newValue) public {
    value = newValue;
  }
}

contract MockInitializableImpleV2 is VersionedInitializable {
  uint256 public value;
  string public text;
  uint256[] public values;

  uint256 public constant REVISION = 2;

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function initialize(
    uint256 val,
    string memory txt,
    uint256[] memory vals
  ) public initializer {
    value = val;
    text = txt;
    values = vals;
  }

  function setValue(uint256 newValue) public {
    value = newValue;
  }

  function setValueViaProxy(uint256 newValue) public {
    value = newValue;
  }
}

contract MockInitializableFromConstructorImple is VersionedInitializable {
  uint256 public value;

  uint256 public constant REVISION = 2;

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  constructor(uint256 val) {
    initialize(val);
  }

  function initialize(uint256 val) public initializer {
    value = val;
  }
}

contract MockReentrantInitializableImple is VersionedInitializable {
  uint256 public value;

  uint256 public constant REVISION = 2;

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function initialize(uint256 val) public initializer {
    value = val;
    if (value < 2) {
      initialize(value + 1);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {StableDebtToken} from '../../protocol/tokenization/StableDebtToken.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';

contract MockStableDebtToken is StableDebtToken {
  constructor(IL1Pool pool) StableDebtToken(pool) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x3;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {VariableDebtToken} from '../../protocol/tokenization/VariableDebtToken.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';

contract MockVariableDebtToken is VariableDebtToken {
  constructor(IL1Pool pool) VariableDebtToken(pool) {}

  function getRevision() internal pure override returns (uint256) {
    return 0x3;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {AccessControl} from '../../dependencies/openzeppelin/contracts/AccessControl.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';
import {Errors} from '../libraries/helpers/Errors.sol';

/**
 * @title ACLManager
 *
 * @notice Access Control List Manager. Main registry of system roles and permissions.
 */
contract ACLManager is AccessControl, IACLManager {
  bytes32 public constant override POOL_ADMIN_ROLE = keccak256('POOL_ADMIN');
  bytes32 public constant override EMERGENCY_ADMIN_ROLE = keccak256('EMERGENCY_ADMIN');
  bytes32 public constant override RISK_ADMIN_ROLE = keccak256('RISK_ADMIN');
  bytes32 public constant override FLASH_BORROWER_ROLE = keccak256('FLASH_BORROWER');
  bytes32 public constant override BRIDGE_ROLE = keccak256('BRIDGE');
  bytes32 public constant override ASSET_LISTING_ADMIN_ROLE = keccak256('ASSET_LISTING_ADMIN');

  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  /**
   * @dev Constructor
   * @dev The ACL admin should be initialized at the addressesProvider beforehand
   * @param provider The address of the PoolAddressesProvider
   */
  constructor(IPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
    address aclAdmin = provider.getACLAdmin();
    require(aclAdmin != address(0), Errors.ACL_ADMIN_CANNOT_BE_ZERO);
    _setupRole(DEFAULT_ADMIN_ROLE, aclAdmin);
  }

  /// @inheritdoc IACLManager
  function setRoleAdmin(bytes32 role, bytes32 adminRole)
    external
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setRoleAdmin(role, adminRole);
  }

  /// @inheritdoc IACLManager
  function addPoolAdmin(address admin) external override {
    grantRole(POOL_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function removePoolAdmin(address admin) external override {
    revokeRole(POOL_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function isPoolAdmin(address admin) external view override returns (bool) {
    return hasRole(POOL_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function addEmergencyAdmin(address admin) external override {
    grantRole(EMERGENCY_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function removeEmergencyAdmin(address admin) external override {
    revokeRole(EMERGENCY_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function isEmergencyAdmin(address admin) external view override returns (bool) {
    return hasRole(EMERGENCY_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function addRiskAdmin(address admin) external override {
    grantRole(RISK_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function removeRiskAdmin(address admin) external override {
    revokeRole(RISK_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function isRiskAdmin(address admin) external view override returns (bool) {
    return hasRole(RISK_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function addFlashBorrower(address borrower) external override {
    grantRole(FLASH_BORROWER_ROLE, borrower);
  }

  /// @inheritdoc IACLManager
  function removeFlashBorrower(address borrower) external override {
    revokeRole(FLASH_BORROWER_ROLE, borrower);
  }

  /// @inheritdoc IACLManager
  function isFlashBorrower(address borrower) external view override returns (bool) {
    return hasRole(FLASH_BORROWER_ROLE, borrower);
  }

  /// @inheritdoc IACLManager
  function addBridge(address bridge) external override {
    grantRole(BRIDGE_ROLE, bridge);
  }

  /// @inheritdoc IACLManager
  function removeBridge(address bridge) external override {
    revokeRole(BRIDGE_ROLE, bridge);
  }

  /// @inheritdoc IACLManager
  function isBridge(address bridge) external view override returns (bool) {
    return hasRole(BRIDGE_ROLE, bridge);
  }

  /// @inheritdoc IACLManager
  function addAssetListingAdmin(address admin) external override {
    grantRole(ASSET_LISTING_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function removeAssetListingAdmin(address admin) external override {
    revokeRole(ASSET_LISTING_ADMIN_ROLE, admin);
  }

  /// @inheritdoc IACLManager
  function isAssetListingAdmin(address admin) external view override returns (bool) {
    return hasRole(ASSET_LISTING_ADMIN_ROLE, admin);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {InitializableImmutableAdminUpgradeabilityProxy} from '../libraries/fintoch-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';

/**
 * @title PoolAddressesProvider
 *
 * @notice Main registry of addresses part of or connected to the protocol, including permissioned roles
 * @dev Acts as factory of proxies and admin of those, so with right to change its implementations
 * @dev Owned by the Fintoch Governance
 **/
contract PoolAddressesProvider is Ownable, IPoolAddressesProvider {
  // Identifier of the Fintoch Market
  string private _marketId;

  // Map of registered addresses (identifier => registeredAddress)
  mapping(bytes32 => address) private _addresses;

  // Main identifiers
  bytes32 private constant POOL = 'POOL';
  bytes32 private constant POOL_CONFIGURATOR = 'POOL_CONFIGURATOR';
  bytes32 private constant PRICE_ORACLE = 'PRICE_ORACLE';
  bytes32 private constant ACL_MANAGER = 'ACL_MANAGER';
  bytes32 private constant ACL_ADMIN = 'ACL_ADMIN';
  bytes32 private constant PRICE_ORACLE_SENTINEL = 'PRICE_ORACLE_SENTINEL';
  bytes32 private constant DATA_PROVIDER = 'DATA_PROVIDER';

  /**
   * @dev Constructor.
   * @param marketId The identifier of the market.
   * @param owner The owner address of this contract.
   */
  constructor(string memory marketId, address owner) {
    _setMarketId(marketId);
    transferOwnership(owner);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getMarketId() external view override returns (string memory) {
    return _marketId;
  }

  /// @inheritdoc IPoolAddressesProvider
  function setMarketId(string memory newMarketId) external override onlyOwner {
    _setMarketId(newMarketId);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /// @inheritdoc IPoolAddressesProvider
  function setAddress(bytes32 id, address newAddress) external override onlyOwner {
    address oldAddress = _addresses[id];
    _addresses[id] = newAddress;
    emit AddressSet(id, oldAddress, newAddress);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setAddressAsProxy(bytes32 id, address newImplementationAddress)
    external
    override
    onlyOwner
  {
    address proxyAddress = _addresses[id];
    address oldImplementationAddress = _getProxyImplementation(id);
    _updateImpl(id, newImplementationAddress);
    emit AddressSetAsProxy(id, proxyAddress, oldImplementationAddress, newImplementationAddress);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getPool() external view override returns (address) {
    return getAddress(POOL);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setPoolImpl(address newPoolImpl) external override onlyOwner {
    address oldPoolImpl = _getProxyImplementation(POOL);
    _updateImpl(POOL, newPoolImpl);
    emit PoolUpdated(oldPoolImpl, newPoolImpl);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getPoolConfigurator() external view override returns (address) {
    return getAddress(POOL_CONFIGURATOR);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external override onlyOwner {
    address oldPoolConfiguratorImpl = _getProxyImplementation(POOL_CONFIGURATOR);
    _updateImpl(POOL_CONFIGURATOR, newPoolConfiguratorImpl);
    emit PoolConfiguratorUpdated(oldPoolConfiguratorImpl, newPoolConfiguratorImpl);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getPriceOracle() external view override returns (address) {
    return getAddress(PRICE_ORACLE);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setPriceOracle(address newPriceOracle) external override onlyOwner {
    address oldPriceOracle = _addresses[PRICE_ORACLE];
    _addresses[PRICE_ORACLE] = newPriceOracle;
    emit PriceOracleUpdated(oldPriceOracle, newPriceOracle);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getACLManager() external view override returns (address) {
    return getAddress(ACL_MANAGER);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setACLManager(address newAclManager) external override onlyOwner {
    address oldAclManager = _addresses[ACL_MANAGER];
    _addresses[ACL_MANAGER] = newAclManager;
    emit ACLManagerUpdated(oldAclManager, newAclManager);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getACLAdmin() external view override returns (address) {
    return getAddress(ACL_ADMIN);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setACLAdmin(address newAclAdmin) external override onlyOwner {
    address oldAclAdmin = _addresses[ACL_ADMIN];
    _addresses[ACL_ADMIN] = newAclAdmin;
    emit ACLAdminUpdated(oldAclAdmin, newAclAdmin);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getPriceOracleSentinel() external view override returns (address) {
    return getAddress(PRICE_ORACLE_SENTINEL);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setPriceOracleSentinel(address newPriceOracleSentinel) external override onlyOwner {
    address oldPriceOracleSentinel = _addresses[PRICE_ORACLE_SENTINEL];
    _addresses[PRICE_ORACLE_SENTINEL] = newPriceOracleSentinel;
    emit PriceOracleSentinelUpdated(oldPriceOracleSentinel, newPriceOracleSentinel);
  }

  /// @inheritdoc IPoolAddressesProvider
  function getPoolDataProvider() external view override returns (address) {
    return getAddress(DATA_PROVIDER);
  }

  /// @inheritdoc IPoolAddressesProvider
  function setPoolDataProvider(address newDataProvider) external override onlyOwner {
    address oldDataProvider = _addresses[DATA_PROVIDER];
    _addresses[DATA_PROVIDER] = newDataProvider;
    emit PoolDataProviderUpdated(oldDataProvider, newDataProvider);
  }

  /**
   * @notice Internal function to update the implementation of a specific proxied component of the protocol.
   * @dev If there is no proxy registered with the given identifier, it creates the proxy setting `newAddress`
   *   as implementation and calls the initialize() function on the proxy
   * @dev If there is already a proxy registered, it just updates the implementation to `newAddress` and
   *   calls the initialize() function via upgradeToAndCall() in the proxy
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   **/
  function _updateImpl(bytes32 id, address newAddress) internal {
    address proxyAddress = _addresses[id];
    InitializableImmutableAdminUpgradeabilityProxy proxy;
    bytes memory params = abi.encodeWithSignature('initialize(address)', address(this));

    if (proxyAddress == address(0)) {
      proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
      _addresses[id] = proxyAddress = address(proxy);
      proxy.initialize(newAddress, params);
      emit ProxyCreated(id, proxyAddress, newAddress);
    } else {
      proxy = InitializableImmutableAdminUpgradeabilityProxy(payable(proxyAddress));
      proxy.upgradeToAndCall(newAddress, params);
    }
  }

  /**
   * @notice Updates the identifier of the Fintoch market.
   * @param newMarketId The new id of the market
   **/
  function _setMarketId(string memory newMarketId) internal {
    string memory oldMarketId = _marketId;
    _marketId = newMarketId;
    emit MarketIdSet(oldMarketId, newMarketId);
  }

  /**
   * @notice Returns the the implementation contract of the proxy contract by its identifier.
   * @dev It returns ZERO if there is no registered address with the given id
   * @dev It reverts if the registered address with the given id is not `InitializableImmutableAdminUpgradeabilityProxy`
   * @param id The id
   * @return The address of the implementation contract
   */
  function _getProxyImplementation(bytes32 id) internal returns (address) {
    address proxyAddress = _addresses[id];
    if (proxyAddress == address(0)) {
      return address(0);
    } else {
      address payable payableProxyAddress = payable(proxyAddress);
      return InitializableImmutableAdminUpgradeabilityProxy(payableProxyAddress).implementation();
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IPoolAddressesProviderRegistry} from '../../interfaces/IPoolAddressesProviderRegistry.sol';

/**
 * @title PoolAddressesProviderRegistry
 *
 * @notice Main registry of PoolAddressesProvider of Fintoch markets.
 * @dev Used for indexing purposes of Fintoch protocol's markets. The id assigned to a PoolAddressesProvider refers to the
 * market it is connected with, for example with `1` for the Fintoch main market and `2` for the next created.
 **/
contract PoolAddressesProviderRegistry is Ownable, IPoolAddressesProviderRegistry {
  // Map of address provider ids (addressesProvider => id)
  mapping(address => uint256) private _addressesProviderToId;
  // Map of id to address provider (id => addressesProvider)
  mapping(uint256 => address) private _idToAddressesProvider;
  // List of addresses providers
  address[] private _addressesProvidersList;
  // Map of address provider list indexes (addressesProvider => indexInList)
  mapping(address => uint256) private _addressesProvidersIndexes;

  /**
   * @dev Constructor.
   * @param owner The owner address of this contract.
   */
  constructor(address owner) {
    transferOwnership(owner);
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function getAddressesProvidersList() external view override returns (address[] memory) {
    return _addressesProvidersList;
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function registerAddressesProvider(address provider, uint256 id) external override onlyOwner {
    require(id != 0, Errors.INVALID_ADDRESSES_PROVIDER_ID);
    require(_idToAddressesProvider[id] == address(0), Errors.INVALID_ADDRESSES_PROVIDER_ID);
    require(_addressesProviderToId[provider] == 0, Errors.ADDRESSES_PROVIDER_ALREADY_ADDED);

    _addressesProviderToId[provider] = id;
    _idToAddressesProvider[id] = provider;

    _addToAddressesProvidersList(provider);
    emit AddressesProviderRegistered(provider, id);
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function unregisterAddressesProvider(address provider) external override onlyOwner {
    require(_addressesProviderToId[provider] != 0, Errors.ADDRESSES_PROVIDER_NOT_REGISTERED);
    uint256 oldId = _addressesProviderToId[provider];
    _idToAddressesProvider[oldId] = address(0);
    _addressesProviderToId[provider] = 0;

    _removeFromAddressesProvidersList(provider);

    emit AddressesProviderUnregistered(provider, oldId);
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function getAddressesProviderIdByAddress(address addressesProvider)
    external
    view
    override
    returns (uint256)
  {
    return _addressesProviderToId[addressesProvider];
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function getAddressesProviderAddressById(uint256 id) external view override returns (address) {
    return _idToAddressesProvider[id];
  }

  /**
   * @notice Adds the addresses provider address to the list.
   * @param provider The address of the PoolAddressesProvider
   */
  function _addToAddressesProvidersList(address provider) internal {
    _addressesProvidersIndexes[provider] = _addressesProvidersList.length;
    _addressesProvidersList.push(provider);
  }

  /**
   * @notice Removes the addresses provider address from the list.
   * @param provider The address of the PoolAddressesProvider
   */
  function _removeFromAddressesProvidersList(address provider) internal {
    uint256 index = _addressesProvidersIndexes[provider];

    _addressesProvidersIndexes[provider] = 0;

    // Swap the index of the last addresses provider in the list with the index of the provider to remove
    uint256 lastIndex = _addressesProvidersList.length - 1;
    if (index < lastIndex) {
      address lastProvider = _addressesProvidersList[lastIndex];
      _addressesProvidersList[index] = lastProvider;
      _addressesProvidersIndexes[lastProvider] = index;
    }
    _addressesProvidersList.pop();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Errors} from '../libraries/helpers/Errors.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IPriceOracleSentinel} from '../../interfaces/IPriceOracleSentinel.sol';
import {ISequencerOracle} from '../../interfaces/ISequencerOracle.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';

/**
 * @title PriceOracleSentinel
 *
 * @notice It validates if operations are allowed depending on the PriceOracle health.
 * @dev Once the PriceOracle gets up after an outage/downtime, users can make their positions healthy during a grace
 *  period. So the PriceOracle is considered completely up once its up and the grace period passed.
 */
contract PriceOracleSentinel is IPriceOracleSentinel {
  /**
   * @dev Only pool admin can call functions marked by this modifier.
   **/
  modifier onlyPoolAdmin() {
    IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
    require(aclManager.isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  /**
   * @dev Only risk or pool admin can call functions marked by this modifier.
   **/
  modifier onlyRiskOrPoolAdmins() {
    IACLManager aclManager = IACLManager(ADDRESSES_PROVIDER.getACLManager());
    require(
      aclManager.isRiskAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_RISK_OR_POOL_ADMIN
    );
    _;
  }

  IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;

  ISequencerOracle internal _sequencerOracle;

  uint256 internal _gracePeriod;

  /**
   * @dev Constructor
   * @param provider The address of the PoolAddressesProvider
   * @param oracle The address of the SequencerOracle
   * @param gracePeriod The duration of the grace period in seconds
   */
  constructor(
    IPoolAddressesProvider provider,
    ISequencerOracle oracle,
    uint256 gracePeriod
  ) {
    ADDRESSES_PROVIDER = provider;
    _sequencerOracle = oracle;
    _gracePeriod = gracePeriod;
  }

  /// @inheritdoc IPriceOracleSentinel
  function isBorrowAllowed() public view override returns (bool) {
    return _isUpAndGracePeriodPassed();
  }

  /// @inheritdoc IPriceOracleSentinel
  function isLiquidationAllowed() public view override returns (bool) {
    return _isUpAndGracePeriodPassed();
  }

  /**
   * @notice Checks the sequencer oracle is healthy: is up and grace period passed.
   * @return True if the SequencerOracle is up and the grace period passed, false otherwise
   */
  function _isUpAndGracePeriodPassed() internal view returns (bool) {
    (, int256 answer, , uint256 lastUpdateTimestamp, ) = _sequencerOracle.latestRoundData();
    return answer == 0 && block.timestamp - lastUpdateTimestamp > _gracePeriod;
  }

  /// @inheritdoc IPriceOracleSentinel
  function setSequencerOracle(address newSequencerOracle) public onlyPoolAdmin {
    _sequencerOracle = ISequencerOracle(newSequencerOracle);
    emit SequencerOracleUpdated(newSequencerOracle);
  }

  /// @inheritdoc IPriceOracleSentinel
  function setGracePeriod(uint256 newGracePeriod) public onlyRiskOrPoolAdmins {
    _gracePeriod = newGracePeriod;
    emit GracePeriodUpdated(newGracePeriod);
  }

  /// @inheritdoc IPriceOracleSentinel
  function getSequencerOracle() public view returns (address) {
    return address(_sequencerOracle);
  }

  /// @inheritdoc IPriceOracleSentinel
  function getGracePeriod() public view returns (uint256) {
    return _gracePeriod;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveConfiguration library
 *
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
  uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
  uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
  /// @dev bit 63 reserved

  uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
  uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
  uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
  uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
  uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

  uint256 internal constant MAX_VALID_LTV = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 internal constant MAX_VALID_DECIMALS = 255;
  uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
  uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
  uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
  uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
  uint256 internal constant MAX_VALID_EMODE_CATEGORY = 255;
  uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
  uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

  uint256 public constant DEBT_CEILING_DECIMALS = 2;
  uint16 public constant MAX_RESERVES_COUNT = 128;

  /**
   * @notice Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv The new ltv
   **/
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @notice Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @notice Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold)
    internal
    pure
  {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);

    self.data =
      (self.data & LIQUIDATION_THRESHOLD_MASK) |
      (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus)
    internal
    pure
  {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

    self.data =
      (self.data & LIQUIDATION_BONUS_MASK) |
      (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   **/
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals)
    internal
    pure
  {
    require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   **/
  function getDecimals(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   **/
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    self.data =
      (self.data & ACTIVE_MASK) |
      (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @notice Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   **/
  function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @notice Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    self.data =
      (self.data & FROZEN_MASK) |
      (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @notice Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @notice Sets the paused state of the reserve
   * @param self The reserve configuration
   * @param paused The paused state
   **/
  function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
    self.data =
      (self.data & PAUSED_MASK) |
      (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the paused state of the reserve
   * @param self The reserve configuration
   * @return The paused state
   **/
  function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~PAUSED_MASK) != 0;
  }

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed
   * amount will be accumulated in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @param borrowable True if the asset is borrowable
   **/
  function setBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self, bool borrowable)
    internal
    pure
  {
    self.data =
      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
      (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowable in isolation flag for the reserve.
   * @dev If the returned flag is true, the asset is borrowable against isolated collateral. Assets borrowed with
   * isolated collateral is accounted for in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @return The borrowable in isolation flag
   **/
  function getBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
  }

  /**
   * @notice Sets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @param siloed True if the asset is siloed
   **/
  function setSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self, bool siloed)
    internal
    pure
  {
    self.data =
      (self.data & SILOED_BORROWING_MASK) |
      (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @return The siloed borrowing flag
   **/
  function getSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~SILOED_BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   **/
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled)
    internal
    pure
  {
    self.data =
      (self.data & BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   **/
  function setStableRateBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   **/
  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @notice Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   **/
  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor)
    internal
    pure
  {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

    self.data =
      (self.data & RESERVE_FACTOR_MASK) |
      (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @notice Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @notice Sets the borrow cap of the reserve
   * @param self The reserve configuration
   * @param borrowCap The borrow cap
   **/
  function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap)
    internal
    pure
  {
    require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrow cap of the reserve
   * @param self The reserve configuration
   * @return The borrow cap
   **/
  function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the supply cap of the reserve
   * @param self The reserve configuration
   * @param supplyCap The supply cap
   **/
  function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap)
    internal
    pure
  {
    require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the supply cap of the reserve
   * @param self The reserve configuration
   * @return The supply cap
   **/
  function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the debt ceiling in isolation mode for the asset
   * @param self The reserve configuration
   * @param ceiling The maximum debt ceiling for the asset
   **/
  function setDebtCeiling(DataTypes.ReserveConfigurationMap memory self, uint256 ceiling)
    internal
    pure
  {
    require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);

    self.data = (self.data & DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the debt ceiling for the asset if the asset is in isolation mode
   * @param self The reserve configuration
   * @return The debt ceiling (0 = isolation mode disabled)
   **/
  function getDebtCeiling(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation protocol fee of the reserve
   * @param self The reserve configuration
   * @param liquidationProtocolFee The liquidation protocol fee
   **/
  function setLiquidationProtocolFee(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 liquidationProtocolFee
  ) internal pure {
    require(
      liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
      Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
    );

    self.data =
      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
      (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation protocol fee
   * @param self The reserve configuration
   * @return The liquidation protocol fee
   **/
  function getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return
      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
  }

  /**
   * @notice Sets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @param unbackedMintCap The unbacked mint cap
   **/
  function setUnbackedMintCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 unbackedMintCap
  ) internal pure {
    require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.INVALID_UNBACKED_MINT_CAP);

    self.data =
      (self.data & UNBACKED_MINT_CAP_MASK) |
      (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @return The unbacked mint cap
   **/
  function getUnbackedMintCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the eMode asset category
   * @param self The reserve configuration
   * @param category The asset category when the user selects the eMode
   **/
  function setEModeCategory(DataTypes.ReserveConfigurationMap memory self, uint256 category)
    internal
    pure
  {
    require(category <= MAX_VALID_EMODE_CATEGORY, Errors.INVALID_EMODE_CATEGORY);

    self.data = (self.data & EMODE_CATEGORY_MASK) | (category << EMODE_CATEGORY_START_BIT_POSITION);
  }

  /**
   * @dev Gets the eMode asset category
   * @param self The reserve configuration
   * @return The eMode category for the asset
   **/
  function getEModeCategory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION;
  }

  /**
   * @notice Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flag representing active
   * @return The state flag representing frozen
   * @return The state flag representing borrowing enabled
   * @return The state flag representing stableRateBorrowing enabled
   * @return The state flag representing paused
   **/
  function getFlags(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool,
      bool,
      bool,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0,
      (dataLocal & ~BORROWING_MASK) != 0,
      (dataLocal & ~STABLE_BORROWING_MASK) != 0,
      (dataLocal & ~PAUSED_MASK) != 0
    );
  }

  /**
   * @notice Gets the configuration parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing ltv
   * @return The state param representing liquidation threshold
   * @return The state param representing liquidation bonus
   * @return The state param representing reserve decimals
   * @return The state param representing reserve factor
   * @return The state param representing eMode category
   **/
  function getParams(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION,
      (dataLocal & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION
    );
  }

  /**
   * @notice Gets the caps parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing borrow cap
   * @return The state param representing supply cap.
   **/
  function getCaps(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256, uint256)
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveConfiguration} from './ReserveConfiguration.sol';

/**
 * @title UserConfiguration library
 *
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  uint256 internal constant BORROWING_MASK =
    0x5555555555555555555555555555555555555555555555555555555555555555;
  uint256 internal constant COLLATERAL_MASK =
    0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

  /**
   * @notice Sets if the user is borrowing the reserve identified by reserveIndex
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @param borrowing True if the user is borrowing the reserve, false otherwise
   **/
  function setBorrowing(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool borrowing
  ) internal {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      uint256 bit = 1 << (reserveIndex << 1);
      if (borrowing) {
        self.data |= bit;
      } else {
        self.data &= ~bit;
      }
    }
  }

  /**
   * @notice Sets if the user is using as collateral the reserve identified by reserveIndex
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @param usingAsCollateral True if the user is using the reserve as collateral, false otherwise
   **/
  function setUsingAsCollateral(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool usingAsCollateral
  ) internal {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      uint256 bit = 1 << ((reserveIndex << 1) + 1);
      if (usingAsCollateral) {
        self.data |= bit;
      } else {
        self.data &= ~bit;
      }
    }
  }

  /**
   * @notice Returns if a user has been using the reserve for borrowing or as collateral
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
   **/
  function isUsingAsCollateralOrBorrowing(
    DataTypes.UserConfigurationMap memory self,
    uint256 reserveIndex
  ) internal pure returns (bool) {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (self.data >> (reserveIndex << 1)) & 3 != 0;
    }
  }

  /**
   * @notice Validate a user has been using the reserve for borrowing
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing, false otherwise
   **/
  function isBorrowing(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
    internal
    pure
    returns (bool)
  {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (self.data >> (reserveIndex << 1)) & 1 != 0;
    }
  }

  /**
   * @notice Validate a user has been using the reserve as collateral
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve as collateral, false otherwise
   **/
  function isUsingAsCollateral(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
    internal
    pure
    returns (bool)
  {
    unchecked {
      require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
      return (self.data >> ((reserveIndex << 1) + 1)) & 1 != 0;
    }
  }

  /**
   * @notice Checks if a user has been supplying only one reserve as collateral
   * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
   * @param self The configuration object
   * @return True if the user has been supplying as collateral one reserve, false otherwise
   **/
  function isUsingAsCollateralOne(DataTypes.UserConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    uint256 collateralData = self.data & COLLATERAL_MASK;
    return collateralData != 0 && (collateralData & (collateralData - 1) == 0);
  }

  /**
   * @notice Checks if a user has been supplying any reserve as collateral
   * @param self The configuration object
   * @return True if the user has been supplying as collateral any reserve, false otherwise
   **/
  function isUsingAsCollateralAny(DataTypes.UserConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return self.data & COLLATERAL_MASK != 0;
  }

  /**
   * @notice Checks if a user has been borrowing only one asset
   * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
   * @param self The configuration object
   * @return True if the user has been supplying as collateral one reserve, false otherwise
   **/
  function isBorrowingOne(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    uint256 borrowingData = self.data & BORROWING_MASK;
    return borrowingData != 0 && (borrowingData & (borrowingData - 1) == 0);
  }

  /**
   * @notice Checks if a user has been borrowing from any reserve
   * @param self The configuration object
   * @return True if the user has been borrowing any reserve, false otherwise
   **/
  function isBorrowingAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data & BORROWING_MASK != 0;
  }

  /**
   * @notice Checks if a user has not been using any reserve for borrowing or supply
   * @param self The configuration object
   * @return True if the user has not been borrowing or supplying any reserve, false otherwise
   **/
  function isEmpty(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data == 0;
  }

  /**
   * @notice Returns the Isolation Mode state of the user
   * @param self The configuration object
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @return True if the user is in isolation mode, false otherwise
   * @return The address of the only asset used as collateral
   * @return The debt ceiling of the reserve
   */
  function getIsolationModeState(
    DataTypes.UserConfigurationMap memory self,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList
  )
    internal
    view
    returns (
      bool,
      address,
      uint256
    )
  {
    if (isUsingAsCollateralOne(self)) {
      uint256 assetId = _getFirstAssetIdByMask(self, COLLATERAL_MASK);

      address assetAddress = reservesList[assetId];
      uint256 ceiling = reservesData[assetAddress].configuration.getDebtCeiling();
      if (ceiling != 0) {
        return (true, assetAddress, ceiling);
      }
    }
    return (false, address(0), 0);
  }

  /**
   * @notice Returns the siloed borrowing state for the user
   * @param self The configuration object
   * @param reservesData The data of all the reserves
   * @param reservesList The reserve list
   * @return True if the user has borrowed a siloed asset, false otherwise
   * @return The address of the only borrowed asset
   */
  function getSiloedBorrowingState(
    DataTypes.UserConfigurationMap memory self,
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList
  ) internal view returns (bool, address) {
    if (isBorrowingOne(self)) {
      uint256 assetId = _getFirstAssetIdByMask(self, BORROWING_MASK);
      address assetAddress = reservesList[assetId];
      if (reservesData[assetAddress].configuration.getSiloedBorrowing()) {
        return (true, assetAddress);
      }
    }

    return (false, address(0));
  }

  /**
   * @notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
   * @param self The configuration object
   * @return The index of the first asset flagged in the bitmap once the corresponding mask is applied
   */
  function _getFirstAssetIdByMask(DataTypes.UserConfigurationMap memory self, uint256 mask)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      uint256 bitmapData = self.data & mask;
      uint256 firstAssetPosition = bitmapData & ~(bitmapData - 1);
      uint256 id;

      while ((firstAssetPosition >>= 2) != 0) {
        id += 1;
      }
      return id;
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {BaseUpgradeabilityProxy} from '../../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol';

/**
 * @title BaseImmutableAdminUpgradeabilityProxy
 *, inspired by the OpenZeppelin upgradeability proxy pattern
 * @notice This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * @dev The admin role is stored in an immutable, which helps saving transactions costs
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  address internal immutable _admin;

  /**
   * @dev Constructor.
   * @param admin The address of the admin
   */
  constructor(address admin) {
    _admin = admin;
  }

  modifier ifAdmin() {
    if (msg.sender == _admin) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @notice Return the admin address
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin;
  }

  /**
   * @notice Return the implementation address
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @notice Upgrade the backing implementation of the proxy.
   * @dev Only the admin can call this function.
   * @param newImplementation The address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @notice Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * @dev This is useful to initialize the proxied contract.
   * @param newImplementation The address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    payable
    ifAdmin
  {
    _upgradeTo(newImplementation);
    (bool success, ) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @notice Only fall back when the sender is not the admin.
   */
  function _willFallback() internal virtual override {
    require(msg.sender != _admin, 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {InitializableUpgradeabilityProxy} from '../../../dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol';
import {Proxy} from '../../../dependencies/openzeppelin/upgradeability/Proxy.sol';
import {BaseImmutableAdminUpgradeabilityProxy} from './BaseImmutableAdminUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 *
 * @dev Extends BaseAdminUpgradeabilityProxy with an initializer function
 */
contract InitializableImmutableAdminUpgradeabilityProxy is
  BaseImmutableAdminUpgradeabilityProxy,
  InitializableUpgradeabilityProxy
{
  /**
   * @dev Constructor.
   * @param admin The address of the admin
   */
  constructor(address admin) BaseImmutableAdminUpgradeabilityProxy(admin) {
    // Intentionally left blank
  }

  /// @inheritdoc BaseImmutableAdminUpgradeabilityProxy
  function _willFallback() internal override(BaseImmutableAdminUpgradeabilityProxy, Proxy) {
    BaseImmutableAdminUpgradeabilityProxy._willFallback();
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title VersionedInitializable
 *, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @notice Returns the revision number of the contract
   * @dev Needs to be defined in the inherited class as a constant.
   * @return The revision number
   **/
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @notice Returns true if and only if the function is running in the constructor
   * @return True if the function is running in the constructor
   **/
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

/**
 * @title Errors library
 *
 * @notice Defines the error messages emitted by the different contracts of the Fintoch protocol
 */
library Errors {
  string public constant CALLER_NOT_POOL_ADMIN = '1'; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
  string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
  string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = '4'; // 'The caller of the function is not a risk or pool admin'
  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '5'; // 'The caller of the function is not an asset listing or pool admin'
  string public constant CALLER_NOT_BRIDGE = '6'; // 'The caller of the function is not a bridge'
  string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = '7'; // 'Pool addresses provider is not registered'
  string public constant INVALID_ADDRESSES_PROVIDER_ID = '8'; // 'Invalid id for the pool addresses provider'
  string public constant NOT_CONTRACT = '9'; // 'Address is not a contract'
  string public constant CALLER_NOT_POOL_CONFIGURATOR = '10'; // 'The caller of the function is not the pool configurator'
  string public constant CALLER_NOT_ATOKEN = '11'; // 'The caller of the function is not an AToken'
  string public constant INVALID_ADDRESSES_PROVIDER = '12'; // 'The address of the pool addresses provider is invalid'
  string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = '13'; // 'Invalid return value of the flashloan executor function'
  string public constant RESERVE_ALREADY_ADDED = '14'; // 'Reserve has already been added to reserve list'
  string public constant NO_MORE_RESERVES_ALLOWED = '15'; // 'Maximum amount of reserves in the pool reached'
  string public constant EMODE_CATEGORY_RESERVED = '16'; // 'Zero eMode category is reserved for volatile heterogeneous assets'
  string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT = '17'; // 'Invalid eMode category assignment to asset'
  string public constant RESERVE_LIQUIDITY_NOT_ZERO = '18'; // 'The liquidity of the reserve needs to be 0'
  string public constant FLASHLOAN_PREMIUM_INVALID = '19'; // 'Invalid flashloan premium'
  string public constant INVALID_RESERVE_PARAMS = '20'; // 'Invalid risk parameters for the reserve'
  string public constant INVALID_EMODE_CATEGORY_PARAMS = '21'; // 'Invalid risk parameters for the eMode category'
  string public constant BRIDGE_PROTOCOL_FEE_INVALID = '22'; // 'Invalid bridge protocol fee'
  string public constant CALLER_MUST_BE_POOL = '23'; // 'The caller of this function must be a pool'
  string public constant INVALID_MINT_AMOUNT = '24'; // 'Invalid amount to mint'
  string public constant INVALID_BURN_AMOUNT = '25'; // 'Invalid amount to burn'
  string public constant INVALID_AMOUNT = '26'; // 'Amount must be greater than 0'
  string public constant RESERVE_INACTIVE = '27'; // 'Action requires an active reserve'
  string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
  string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
  string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
  string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
  string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
  string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
  string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
  string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
  string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
  string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
  string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
  string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
  string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
  string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
  string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '45'; // 'Health factor is not below the threshold'
  string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = '46'; // 'The collateral chosen cannot be liquidated'
  string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '47'; // 'User did not borrow the specified currency'
  string public constant SAME_BLOCK_BORROW_REPAY = '48'; // 'Borrow and repay in same block is not allowed'
  string public constant INCONSISTENT_FLASHLOAN_PARAMS = '49'; // 'Inconsistent flashloan parameters'
  string public constant BORROW_CAP_EXCEEDED = '50'; // 'Borrow cap is exceeded'
  string public constant SUPPLY_CAP_EXCEEDED = '51'; // 'Supply cap is exceeded'
  string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
  string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
  string public constant ATOKEN_SUPPLY_NOT_ZERO = '54'; // 'AToken supply is not zero'
  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
  string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
  string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
  string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
  string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
  string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
  string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
  string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
  string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
  string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
  string public constant INVALID_DECIMALS = '66'; // 'Invalid decimals parameter of the underlying asset of the reserve'
  string public constant INVALID_RESERVE_FACTOR = '67'; // 'Invalid reserve factor parameter for the reserve'
  string public constant INVALID_BORROW_CAP = '68'; // 'Invalid borrow cap for the reserve'
  string public constant INVALID_SUPPLY_CAP = '69'; // 'Invalid supply cap for the reserve'
  string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = '70'; // 'Invalid liquidation protocol fee for the reserve'
  string public constant INVALID_EMODE_CATEGORY = '71'; // 'Invalid eMode category for the reserve'
  string public constant INVALID_UNBACKED_MINT_CAP = '72'; // 'Invalid unbacked mint cap for the reserve'
  string public constant INVALID_DEBT_CEILING = '73'; // 'Invalid debt ceiling for the reserve
  string public constant INVALID_RESERVE_INDEX = '74'; // 'Invalid reserve index'
  string public constant ACL_ADMIN_CANNOT_BE_ZERO = '75'; // 'ACL admin cannot be set to the zero address'
  string public constant INCONSISTENT_PARAMS_LENGTH = '76'; // 'Array parameters that should be equal length are not'
  string public constant ZERO_ADDRESS_NOT_VALID = '77'; // 'Zero address not valid'
  string public constant INVALID_EXPIRATION = '78'; // 'Invalid expiration'
  string public constant INVALID_SIGNATURE = '79'; // 'Invalid signature'
  string public constant OPERATION_NOT_SUPPORTED = '80'; // 'Operation not supported'
  string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
  string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
  string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
  string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
  string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
  string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
  string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
  string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title Helpers library
 *
 */
library Helpers {
  /**
   * @notice Fetches the user current stable and variable debt balances
   * @param user The user address
   * @param reserveCache The reserve cache data object
   * @return The stable debt balance
   * @return The variable debt balance
   **/
  function getUserCurrentDebt(address user, DataTypes.ReserveCache memory reserveCache)
    internal
    view
    returns (uint256, uint256)
  {
    return (
      IERC20(reserveCache.stableDebtTokenAddress).balanceOf(user),
      IERC20(reserveCache.variableDebtTokenAddress).balanceOf(user)
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IStableDebtToken} from '../../../interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {Helpers} from '../helpers/Helpers.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {IsolationModeLogic} from './IsolationModeLogic.sol';

/**
 * @title BorrowLogic library
 *
 * @notice Implements the base logic for all the actions related to borrowing
 */
library BorrowLogic {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using GPv2SafeERC20 for IERC20;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using SafeCast for uint256;

  // See `IPool` for descriptions
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 borrowRate,
    uint16 indexed referralCode
  );
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
   * Fintoch protocol proportionally to their collateralization power. For isolated positions, it also increases the
   * isolated debt.
   * @dev  Emits the `Borrow()` event
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the borrow function
   */
  function executeBorrow(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteBorrowParams memory params
  ) public {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);

    (
      bool isolationModeActive,
      address isolationModeCollateralAddress,
      uint256 isolationModeDebtCeiling
    ) = userConfig.getIsolationModeState(reservesData, reservesList);

    ValidationLogic.validateBorrow(
      reservesData,
      reservesList,
      eModeCategories,
      DataTypes.ValidateBorrowParams({
        reserveCache: reserveCache,
        userConfig: userConfig,
        asset: params.asset,
        userAddress: params.onBehalfOf,
        amount: params.amount,
        interestRateMode: params.interestRateMode,
        maxStableLoanPercent: params.maxStableRateBorrowSizePercent,
        reservesCount: params.reservesCount,
        oracle: params.oracle,
        userEModeCategory: params.userEModeCategory,
        priceOracleSentinel: params.priceOracleSentinel,
        isolationModeActive: isolationModeActive,
        isolationModeCollateralAddress: isolationModeCollateralAddress,
        isolationModeDebtCeiling: isolationModeDebtCeiling
      })
    );

    uint256 currentStableRate = 0;
    bool isFirstBorrowing = false;

    if (params.interestRateMode == DataTypes.InterestRateMode.STABLE) {
      currentStableRate = reserve.currentStableBorrowRate;

      (
        isFirstBorrowing,
        reserveCache.nextTotalStableDebt,
        reserveCache.nextAvgStableBorrowRate
      ) = IStableDebtToken(reserveCache.stableDebtTokenAddress).mint(
        params.user,
        params.onBehalfOf,
        params.amount,
        currentStableRate
      );
    } else {
      (isFirstBorrowing, reserveCache.nextScaledVariableDebt) = IVariableDebtToken(
        reserveCache.variableDebtTokenAddress
      ).mint(params.user, params.onBehalfOf, params.amount, reserveCache.nextVariableBorrowIndex);
    }

    if (isFirstBorrowing) {
      userConfig.setBorrowing(reserve.id, true);
    }

    if (isolationModeActive) {
      uint256 nextIsolationModeTotalDebt = reservesData[isolationModeCollateralAddress]
        .isolationModeTotalDebt += (params.amount /
        10 **
          (reserveCache.reserveConfiguration.getDecimals() -
            ReserveConfiguration.DEBT_CEILING_DECIMALS)).toUint128();
      emit IsolationModeTotalDebtUpdated(
        isolationModeCollateralAddress,
        nextIsolationModeTotalDebt
      );
    }

    reserve.updateInterestRates(
      reserveCache,
      params.asset,
      0,
      params.releaseUnderlying ? params.amount : 0
    );

    if (params.releaseUnderlying) {
      IAToken(reserveCache.aTokenAddress).transferUnderlyingTo(params.user, params.amount);
    }

    emit Borrow(
      params.asset,
      params.user,
      params.onBehalfOf,
      params.amount,
      params.interestRateMode,
      params.interestRateMode == DataTypes.InterestRateMode.STABLE
        ? currentStableRate
        : reserve.currentVariableBorrowRate,
      params.referralCode
    );
  }

  /**
   * @notice Implements the repay feature. Repaying transfers the underlying back to the aToken and clears the
   * equivalent amount of debt for the user by burning the corresponding debt token. For isolated positions, it also
   * reduces the isolated debt.
   * @dev  Emits the `Repay()` event
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the repay function
   * @return The actual amount being repaid
   */
  function executeRepay(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteRepayParams memory params
  ) external returns (uint256) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();
    reserve.updateState(reserveCache);

    (uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(
      params.onBehalfOf,
      reserveCache
    );

    ValidationLogic.validateRepay(
      reserveCache,
      params.amount,
      params.interestRateMode,
      params.onBehalfOf,
      stableDebt,
      variableDebt
    );

    uint256 paybackAmount = params.interestRateMode == DataTypes.InterestRateMode.STABLE
      ? stableDebt
      : variableDebt;

    // Allows a user to repay with aTokens without leaving dust from interest.
    if (params.useATokens && params.amount == type(uint256).max) {
      params.amount = IAToken(reserveCache.aTokenAddress).balanceOf(msg.sender);
    }

    if (params.amount < paybackAmount) {
      paybackAmount = params.amount;
    }

    if (params.interestRateMode == DataTypes.InterestRateMode.STABLE) {
      (reserveCache.nextTotalStableDebt, reserveCache.nextAvgStableBorrowRate) = IStableDebtToken(
        reserveCache.stableDebtTokenAddress
      ).burn(params.onBehalfOf, paybackAmount);
    } else {
      reserveCache.nextScaledVariableDebt = IVariableDebtToken(
        reserveCache.variableDebtTokenAddress
      ).burn(params.onBehalfOf, paybackAmount, reserveCache.nextVariableBorrowIndex);
    }

    reserve.updateInterestRates(
      reserveCache,
      params.asset,
      params.useATokens ? 0 : paybackAmount,
      0
    );

    if (stableDebt + variableDebt - paybackAmount == 0) {
      userConfig.setBorrowing(reserve.id, false);
    }

    IsolationModeLogic.updateIsolatedDebtIfIsolated(
      reservesData,
      reservesList,
      userConfig,
      reserveCache,
      paybackAmount
    );

    if (params.useATokens) {
      IAToken(reserveCache.aTokenAddress).burn(
        msg.sender,
        reserveCache.aTokenAddress,
        paybackAmount,
        reserveCache.nextLiquidityIndex
      );
    } else {
      IERC20(params.asset).safeTransferFrom(msg.sender, reserveCache.aTokenAddress, paybackAmount);
      IAToken(reserveCache.aTokenAddress).handleRepayment(msg.sender, paybackAmount);
    }

    emit Repay(params.asset, params.onBehalfOf, msg.sender, paybackAmount, params.useATokens);

    return paybackAmount;
  }

  /**
   * @notice Implements the rebalance stable borrow rate feature. In case of liquidity crunches on the protocol, stable
   * rate borrows might need to be rebalanced to bring back equilibrium between the borrow and supply APYs.
   * @dev The rules that define if a position can be rebalanced are implemented in `ValidationLogic.validateRebalanceStableBorrowRate()`
   * @dev Emits the `RebalanceStableBorrowRate()` event
   * @param reserve The state of the reserve of the asset being repaid
   * @param asset The asset of the position being rebalanced
   * @param user The user being rebalanced
   */
  function executeRebalanceStableBorrowRate(
    DataTypes.ReserveData storage reserve,
    address asset,
    address user
  ) external {
    DataTypes.ReserveCache memory reserveCache = reserve.cache();
    reserve.updateState(reserveCache);

    ValidationLogic.validateRebalanceStableBorrowRate(reserve, reserveCache, asset);

    IStableDebtToken stableDebtToken = IStableDebtToken(reserveCache.stableDebtTokenAddress);
    uint256 stableDebt = IERC20(address(stableDebtToken)).balanceOf(user);

    stableDebtToken.burn(user, stableDebt);

    (, reserveCache.nextTotalStableDebt, reserveCache.nextAvgStableBorrowRate) = stableDebtToken
      .mint(user, user, stableDebt, reserve.currentStableBorrowRate);

    reserve.updateInterestRates(reserveCache, asset, 0, 0);

    emit RebalanceStableBorrowRate(asset, user);
  }

  /**
   * @notice Implements the swap borrow rate feature. Borrowers can swap from variable to stable positions at any time.
   * @dev Emits the `Swap()` event
   * @param reserve The of the reserve of the asset being repaid
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param asset The asset of the position being swapped
   * @param interestRateMode The current interest rate mode of the position being swapped
   */
  function executeSwapBorrowRateMode(
    DataTypes.ReserveData storage reserve,
    DataTypes.UserConfigurationMap storage userConfig,
    address asset,
    DataTypes.InterestRateMode interestRateMode
  ) external {
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);

    (uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(
      msg.sender,
      reserveCache
    );

    ValidationLogic.validateSwapRateMode(
      reserve,
      reserveCache,
      userConfig,
      stableDebt,
      variableDebt,
      interestRateMode
    );

    if (interestRateMode == DataTypes.InterestRateMode.STABLE) {
      (reserveCache.nextTotalStableDebt, reserveCache.nextAvgStableBorrowRate) = IStableDebtToken(
        reserveCache.stableDebtTokenAddress
      ).burn(msg.sender, stableDebt);

      (, reserveCache.nextScaledVariableDebt) = IVariableDebtToken(
        reserveCache.variableDebtTokenAddress
      ).mint(msg.sender, msg.sender, stableDebt, reserveCache.nextVariableBorrowIndex);
    } else {
      reserveCache.nextScaledVariableDebt = IVariableDebtToken(
        reserveCache.variableDebtTokenAddress
      ).burn(msg.sender, variableDebt, reserveCache.nextVariableBorrowIndex);

      (, reserveCache.nextTotalStableDebt, reserveCache.nextAvgStableBorrowRate) = IStableDebtToken(
        reserveCache.stableDebtTokenAddress
      ).mint(msg.sender, msg.sender, variableDebt, reserve.currentStableBorrowRate);
    }

    reserve.updateInterestRates(reserveCache, asset, 0, 0);

    emit SwapBorrowRateMode(asset, msg.sender, interestRateMode);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {Errors} from '../helpers/Errors.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {ReserveLogic} from './ReserveLogic.sol';

library BridgeLogic {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using GPv2SafeERC20 for IERC20;

  // See `IPool` for descriptions
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  /**
   * @notice Mint unbacked aTokens to a user and updates the unbacked for the reserve.
   * @dev Essentially a supply without transferring the underlying.
   * @dev Emits the `MintUnbacked` event
   * @dev Emits the `ReserveUsedAsCollateralEnabled` if asset is set as collateral
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param asset The address of the underlying asset to mint aTokens of
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function executeMintUnbacked(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);

    ValidationLogic.validateSupply(reserveCache, amount);

    uint256 unbackedMintCap = reserveCache.reserveConfiguration.getUnbackedMintCap();
    uint256 reserveDecimals = reserveCache.reserveConfiguration.getDecimals();

    uint256 unbacked = reserve.unbacked += amount.toUint128();

    require(unbacked <= unbackedMintCap * (10**reserveDecimals), Errors.UNBACKED_MINT_CAP_EXCEEDED);

    reserve.updateInterestRates(reserveCache, asset, 0, 0);

    bool isFirstSupply = IAToken(reserveCache.aTokenAddress).mint(
      msg.sender,
      onBehalfOf,
      amount,
      reserveCache.nextLiquidityIndex
    );

    if (isFirstSupply) {
      if (
        ValidationLogic.validateUseAsCollateral(
          reservesData,
          reservesList,
          userConfig,
          reserveCache.reserveConfiguration
        )
      ) {
        userConfig.setUsingAsCollateral(reserve.id, true);
        emit ReserveUsedAsCollateralEnabled(asset, onBehalfOf);
      }
    }

    emit MintUnbacked(asset, msg.sender, onBehalfOf, amount, referralCode);
  }

  /**
   * @notice Back the current unbacked with `amount` and pay `fee`.
   * @dev Emits the `BackUnbacked` event
   * @param reserve The reserve to back unbacked for
   * @param asset The address of the underlying asset to repay
   * @param amount The amount to back
   * @param fee The amount paid in fees
   * @param protocolFeeBps The fraction of fees in basis points paid to the protocol
   **/
  function executeBackUnbacked(
    DataTypes.ReserveData storage reserve,
    address asset,
    uint256 amount,
    uint256 fee,
    uint256 protocolFeeBps
  ) external {
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);

    uint256 backingAmount = (amount < reserve.unbacked) ? amount : reserve.unbacked;

    uint256 feeToProtocol = fee.percentMul(protocolFeeBps);
    uint256 feeToLP = fee - feeToProtocol;
    uint256 added = backingAmount + fee;

    reserveCache.nextLiquidityIndex = reserve.cumulateToLiquidityIndex(
      IERC20(reserveCache.aTokenAddress).totalSupply(),
      feeToLP
    );

    reserve.accruedToTreasury += feeToProtocol.rayDiv(reserveCache.nextLiquidityIndex).toUint128();

    reserve.unbacked -= backingAmount.toUint128();
    reserve.updateInterestRates(reserveCache, asset, added, 0);

    IERC20(asset).safeTransferFrom(msg.sender, reserveCache.aTokenAddress, added);

    emit BackUnbacked(asset, msg.sender, backingAmount, fee);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

/**
 * @title CalldataLogic library
 *
 * @notice Library to decode calldata, used to optimize calldata size in L2Pool for transaction cost reduction
 */
library CalldataLogic {
  /**
   * @notice Decodes compressed supply params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed supply params
   * @return The address of the underlying reserve
   * @return The amount to supply
   * @return The referralCode
   */
  function decodeSupplyParams(mapping(uint256 => address) storage reservesList, bytes32 args)
    internal
    view
    returns (
      address,
      uint256,
      uint16
    )
  {
    uint16 assetId;
    uint256 amount;
    uint16 referralCode;

    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      referralCode := and(shr(144, args), 0xFFFF)
    }
    return (reservesList[assetId], amount, referralCode);
  }

  /**
   * @notice Decodes compressed supply params to standard params along with permit params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed supply with permit params
   * @return The address of the underlying reserve
   * @return The amount to supply
   * @return The referralCode
   * @return The deadline of the permit
   * @return The V value of the permit signature
   */
  function decodeSupplyWithPermitParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  )
    internal
    view
    returns (
      address,
      uint256,
      uint16,
      uint256,
      uint8
    )
  {
    uint256 deadline;
    uint8 permitV;

    assembly {
      deadline := and(shr(160, args), 0xFFFFFFFF)
      permitV := and(shr(192, args), 0xFF)
    }
    (address asset, uint256 amount, uint16 referralCode) = decodeSupplyParams(reservesList, args);

    return (asset, amount, referralCode, deadline, permitV);
  }

  /**
   * @notice Decodes compressed withdraw params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed withdraw params
   * @return The address of the underlying reserve
   * @return The amount to withdraw
   */
  function decodeWithdrawParams(mapping(uint256 => address) storage reservesList, bytes32 args)
    internal
    view
    returns (address, uint256)
  {
    uint16 assetId;
    uint256 amount;
    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
    if (amount == type(uint128).max) {
      amount = type(uint256).max;
    }
    return (reservesList[assetId], amount);
  }

  /**
   * @notice Decodes compressed borrow params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed borrow params
   * @return The address of the underlying reserve
   * @return The amount to borrow
   * @return The interestRateMode, 1 for stable or 2 for variable debt
   * @return The referralCode
   */
  function decodeBorrowParams(mapping(uint256 => address) storage reservesList, bytes32 args)
    internal
    view
    returns (
      address,
      uint256,
      uint256,
      uint16
    )
  {
    uint16 assetId;
    uint256 amount;
    uint256 interestRateMode;
    uint16 referralCode;

    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      interestRateMode := and(shr(144, args), 0xFF)
      referralCode := and(shr(152, args), 0xFFFF)
    }

    return (reservesList[assetId], amount, interestRateMode, referralCode);
  }

  /**
   * @notice Decodes compressed repay params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed repay params
   * @return The address of the underlying reserve
   * @return The amount to repay
   * @return The interestRateMode, 1 for stable or 2 for variable debt
   */
  function decodeRepayParams(mapping(uint256 => address) storage reservesList, bytes32 args)
    internal
    view
    returns (
      address,
      uint256,
      uint256
    )
  {
    uint16 assetId;
    uint256 amount;
    uint256 interestRateMode;

    assembly {
      assetId := and(args, 0xFFFF)
      amount := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      interestRateMode := and(shr(144, args), 0xFF)
    }

    if (amount == type(uint128).max) {
      amount = type(uint256).max;
    }

    return (reservesList[assetId], amount, interestRateMode);
  }

  /**
   * @notice Decodes compressed repay params to standard params along with permit params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed repay with permit params
   * @return The address of the underlying reserve
   * @return The amount to repay
   * @return The interestRateMode, 1 for stable or 2 for variable debt
   * @return The deadline of the permit
   * @return The V value of the permit signature
   */
  function decodeRepayWithPermitParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  )
    internal
    view
    returns (
      address,
      uint256,
      uint256,
      uint256,
      uint8
    )
  {
    uint256 deadline;
    uint8 permitV;

    (address asset, uint256 amount, uint256 interestRateMode) = decodeRepayParams(
      reservesList,
      args
    );

    assembly {
      deadline := and(shr(152, args), 0xFFFFFFFF)
      permitV := and(shr(184, args), 0xFF)
    }

    return (asset, amount, interestRateMode, deadline, permitV);
  }

  /**
   * @notice Decodes compressed swap borrow rate mode params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed swap borrow rate mode params
   * @return The address of the underlying reserve
   * @return The interest rate mode, 1 for stable 2 for variable debt
   */
  function decodeSwapBorrowRateModeParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, uint256) {
    uint16 assetId;
    uint256 interestRateMode;

    assembly {
      assetId := and(args, 0xFFFF)
      interestRateMode := and(shr(16, args), 0xFF)
    }

    return (reservesList[assetId], interestRateMode);
  }

  /**
   * @notice Decodes compressed rebalance stable borrow rate params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed rabalance stable borrow rate params
   * @return The address of the underlying reserve
   * @return The address of the user to rebalance
   */
  function decodeRebalanceStableBorrowRateParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, address) {
    uint16 assetId;
    address user;
    assembly {
      assetId := and(args, 0xFFFF)
      user := and(shr(16, args), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
    return (reservesList[assetId], user);
  }

  /**
   * @notice Decodes compressed set user use reserve as collateral params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args The packed set user use reserve as collateral params
   * @return The address of the underlying reserve
   * @return True if to set using as collateral, false otherwise
   */
  function decodeSetUserUseReserveAsCollateralParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args
  ) internal view returns (address, bool) {
    uint16 assetId;
    bool useAsCollateral;
    assembly {
      assetId := and(args, 0xFFFF)
      useAsCollateral := and(shr(16, args), 0x1)
    }
    return (reservesList[assetId], useAsCollateral);
  }

  /**
   * @notice Decodes compressed liquidation call params to standard params
   * @param reservesList The addresses of all the active reserves
   * @param args1 The first half of packed liquidation call params
   * @param args2 The second half of the packed liquidation call params
   * @return The address of the underlying collateral asset
   * @return The address of the underlying debt asset
   * @return The address of the user to liquidate
   * @return The amount of debt to cover
   * @return True if receiving aTokens, false otherwise
   */
  function decodeLiquidationCallParams(
    mapping(uint256 => address) storage reservesList,
    bytes32 args1,
    bytes32 args2
  )
    internal
    view
    returns (
      address,
      address,
      address,
      uint256,
      bool
    )
  {
    uint16 collateralAssetId;
    uint16 debtAssetId;
    address user;
    uint256 debtToCover;
    bool receiveAToken;

    assembly {
      collateralAssetId := and(args1, 0xFFFF)
      debtAssetId := and(shr(16, args1), 0xFFFF)
      user := and(shr(32, args1), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

      debtToCover := and(args2, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      receiveAToken := and(shr(128, args2), 0x1)
    }

    if (debtToCover == type(uint128).max) {
      debtToCover = type(uint256).max;
    }

    return (
      reservesList[collateralAssetId],
      reservesList[debtAssetId],
      user,
      debtToCover,
      receiveAToken
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IL1Pool} from '../../../interfaces/IL1Pool.sol';
import {IInitializableAToken} from '../../../interfaces/IInitializableAToken.sol';
import {IInitializableDebtToken} from '../../../interfaces/IInitializableDebtToken.sol';
import {IFintochIncentivesController} from '../../../interfaces/IFintochIncentivesController.sol';
import {InitializableImmutableAdminUpgradeabilityProxy} from '../fintoch-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ConfiguratorInputTypes} from '../types/ConfiguratorInputTypes.sol';

/**
 * @title ConfiguratorLogic library
 *
 * @notice Implements the functions to initialize reserves and update aTokens and debtTokens
 */
library ConfiguratorLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  // See `IPoolConfigurator` for descriptions
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @notice Initialize a reserve by creating and initializing aToken, stable debt token and variable debt token
   * @dev Emits the `ReserveInitialized` event
   * @param pool The Pool in which the reserve will be initialized
   * @param input The needed parameters for the initialization
   */
  function executeInitReserve(IL1Pool pool, ConfiguratorInputTypes.InitReserveInput calldata input)
    public
  {
    address aTokenProxyAddress = _initTokenWithProxy(
      input.aTokenImpl,
      abi.encodeWithSelector(
        IInitializableAToken.initialize.selector,
        pool,
        input.treasury,
        input.underlyingAsset,
        input.incentivesController,
        input.underlyingAssetDecimals,
        input.aTokenName,
        input.aTokenSymbol,
        input.params
      )
    );

    address stableDebtTokenProxyAddress = _initTokenWithProxy(
      input.stableDebtTokenImpl,
      abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        pool,
        input.underlyingAsset,
        input.incentivesController,
        input.underlyingAssetDecimals,
        input.stableDebtTokenName,
        input.stableDebtTokenSymbol,
        input.params
      )
    );

    address variableDebtTokenProxyAddress = _initTokenWithProxy(
      input.variableDebtTokenImpl,
      abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        pool,
        input.underlyingAsset,
        input.incentivesController,
        input.underlyingAssetDecimals,
        input.variableDebtTokenName,
        input.variableDebtTokenSymbol,
        input.params
      )
    );

    pool.initReserve(
      input.underlyingAsset,
      aTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );

    DataTypes.ReserveConfigurationMap memory currentConfig = DataTypes.ReserveConfigurationMap(0);

    currentConfig.setDecimals(input.underlyingAssetDecimals);

    currentConfig.setActive(true);
    currentConfig.setPaused(false);
    currentConfig.setFrozen(false);

    pool.setConfiguration(input.underlyingAsset, currentConfig);

    emit ReserveInitialized(
      input.underlyingAsset,
      aTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );
  }

  /**
   * @notice Updates the aToken implementation and initializes it
   * @dev Emits the `ATokenUpgraded` event
   * @param cachedPool The Pool containing the reserve with the aToken
   * @param input The parameters needed for the initialize call
   */
  function executeUpdateAToken(
    IL1Pool cachedPool,
    ConfiguratorInputTypes.UpdateATokenInput calldata input
  ) public {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, , ) = cachedPool.getConfiguration(input.asset).getParams();

    bytes memory encodedCall = abi.encodeWithSelector(
      IInitializableAToken.initialize.selector,
      cachedPool,
      input.treasury,
      input.asset,
      input.incentivesController,
      decimals,
      input.name,
      input.symbol,
      input.params
    );

    _upgradeTokenImplementation(reserveData.aTokenAddress, input.implementation, encodedCall);

    emit ATokenUpgraded(input.asset, reserveData.aTokenAddress, input.implementation);
  }

  /**
   * @notice Updates the stable debt token implementation and initializes it
   * @dev Emits the `StableDebtTokenUpgraded` event
   * @param cachedPool The Pool containing the reserve with the stable debt token
   * @param input The parameters needed for the initialize call
   */
  function executeUpdateStableDebtToken(
    IL1Pool cachedPool,
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) public {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, , ) = cachedPool.getConfiguration(input.asset).getParams();

    bytes memory encodedCall = abi.encodeWithSelector(
      IInitializableDebtToken.initialize.selector,
      cachedPool,
      input.asset,
      input.incentivesController,
      decimals,
      input.name,
      input.symbol,
      input.params
    );

    _upgradeTokenImplementation(
      reserveData.stableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit StableDebtTokenUpgraded(
      input.asset,
      reserveData.stableDebtTokenAddress,
      input.implementation
    );
  }

  /**
   * @notice Updates the variable debt token implementation and initializes it
   * @dev Emits the `VariableDebtTokenUpgraded` event
   * @param cachedPool The Pool containing the reserve with the variable debt token
   * @param input The parameters needed for the initialize call
   */
  function executeUpdateVariableDebtToken(
    IL1Pool cachedPool,
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) public {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, , ) = cachedPool.getConfiguration(input.asset).getParams();

    bytes memory encodedCall = abi.encodeWithSelector(
      IInitializableDebtToken.initialize.selector,
      cachedPool,
      input.asset,
      input.incentivesController,
      decimals,
      input.name,
      input.symbol,
      input.params
    );

    _upgradeTokenImplementation(
      reserveData.variableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit VariableDebtTokenUpgraded(
      input.asset,
      reserveData.variableDebtTokenAddress,
      input.implementation
    );
  }

  /**
   * @notice Creates a new proxy and initializes the implementation
   * @param implementation The address of the implementation
   * @param initParams The parameters that is passed to the implementation to initialize
   * @return The address of initialized proxy
   */
  function _initTokenWithProxy(address implementation, bytes memory initParams)
    internal
    returns (address)
  {
    InitializableImmutableAdminUpgradeabilityProxy proxy = new InitializableImmutableAdminUpgradeabilityProxy(
        address(this)
      );

    proxy.initialize(implementation, initParams);

    return address(proxy);
  }

  /**
   * @notice Upgrades the implementation and makes call to the proxy
   * @dev The call is used to initialize the new implementation.
   * @param proxyAddress The address of the proxy
   * @param implementation The address of the new implementation
   * @param  initParams The parameters to the call after the upgrade
   */
  function _upgradeTokenImplementation(
    address proxyAddress,
    address implementation,
    bytes memory initParams
  ) internal {
    InitializableImmutableAdminUpgradeabilityProxy proxy = InitializableImmutableAdminUpgradeabilityProxy(
        payable(proxyAddress)
      );

    proxy.upgradeToAndCall(implementation, initParams);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {ReserveLogic} from './ReserveLogic.sol';

/**
 * @title EModeLogic library
 *
 * @notice Implements the base logic for all the actions related to the eMode
 */
library EModeLogic {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using GPv2SafeERC20 for IERC20;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  // See `IPool` for descriptions
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @notice Updates the user efficiency mode category
   * @dev Will revert if user is borrowing non-compatible asset or change will drop HF < HEALTH_FACTOR_LIQUIDATION_THRESHOLD
   * @dev Emits the `UserEModeSet` event
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param usersEModeCategory The state of all users efficiency mode category
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the setUserEMode function
   */
  function executeSetUserEMode(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    mapping(address => uint8) storage usersEModeCategory,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteSetUserEModeParams memory params
  ) external {
    ValidationLogic.validateSetUserEMode(
      reservesData,
      reservesList,
      eModeCategories,
      userConfig,
      params.reservesCount,
      params.categoryId
    );

    uint8 prevCategoryId = usersEModeCategory[msg.sender];
    usersEModeCategory[msg.sender] = params.categoryId;

    if (prevCategoryId != 0) {
      ValidationLogic.validateHealthFactor(
        reservesData,
        reservesList,
        eModeCategories,
        userConfig,
        msg.sender,
        params.categoryId,
        params.reservesCount,
        params.oracle
      );
    }
    emit UserEModeSet(msg.sender, params.categoryId);
  }

  /**
   * @notice Gets the eMode configuration and calculates the eMode asset price if a custom oracle is configured
   * @dev The eMode asset price returned is 0 if no oracle is specified
   * @param category The user eMode category
   * @param oracle The price oracle
   * @return The eMode ltv
   * @return The eMode liquidation threshold
   * @return The eMode asset price
   **/
  function getEModeConfiguration(
    DataTypes.EModeCategory storage category,
    IPriceOracleGetter oracle
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 eModeAssetPrice = 0;
    address eModePriceSource = category.priceSource;

    if (eModePriceSource != address(0)) {
      eModeAssetPrice = oracle.getAssetPrice(eModePriceSource);
    }

    return (category.ltv, category.liquidationThreshold, eModeAssetPrice);
  }

  /**
   * @notice Checks if eMode is active for a user and if yes, if the asset belongs to the eMode category chosen
   * @param eModeUserCategory The user eMode category
   * @param eModeAssetCategory The asset eMode category
   * @return True if eMode is active and the asset belongs to the eMode category chosen by the user, false otherwise
   **/
  function isInEModeCategory(uint256 eModeUserCategory, uint256 eModeAssetCategory)
    internal
    pure
    returns (bool)
  {
    return (eModeUserCategory != 0 && eModeAssetCategory == eModeUserCategory);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {IFlashLoanReceiver} from '../../../flashloan/interfaces/IFlashLoanReceiver.sol';
import {IFlashLoanSimpleReceiver} from '../../../flashloan/interfaces/IFlashLoanSimpleReceiver.sol';
import {IPoolAddressesProvider} from '../../../interfaces/IPoolAddressesProvider.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {BorrowLogic} from './BorrowLogic.sol';
import {ReserveLogic} from './ReserveLogic.sol';

/**
 * @title FlashLoanLogic library
 *
 * @notice Implements the logic for the flash loans
 */
library FlashLoanLogic {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using GPv2SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;

  // See `IPool` for descriptions
  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint256 amount,
    DataTypes.InterestRateMode interestRateMode,
    uint256 premium,
    uint16 indexed referralCode
  );

  // Helper struct for internal variables used in the `executeFlashLoan` function
  struct FlashLoanLocalVars {
    IFlashLoanReceiver receiver;
    uint256 i;
    address currentAsset;
    uint256 currentAmount;
    uint256[] totalPremiums;
    uint256 flashloanPremiumTotal;
    uint256 flashloanPremiumToProtocol;
  }

  /**
   * @notice Implements the flashloan feature that allow users to access liquidity of the pool for one transaction
   * as long as the amount taken plus fee is returned or debt is opened.
   * @dev For authorized flashborrowers the fee is waived
   * @dev At the end of the transaction the pool will pull amount borrowed + fee from the receiver,
   * if the receiver have not approved the pool the transaction will revert.
   * @dev Emits the `FlashLoan()` event
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the flashloan function
   */
  function executeFlashLoan(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.FlashloanParams memory params
  ) external {
    // The usual action flow (cache -> updateState -> validation -> changeState -> updateRates)
    // is altered to (validation -> user payload -> cache -> updateState -> changeState -> updateRates) for flashloans.
    // This is done to protect against reentrance and rate manipulation within the user specified payload.

    ValidationLogic.validateFlashloan(reservesData, params.assets, params.amounts);

    FlashLoanLocalVars memory vars;

    vars.totalPremiums = new uint256[](params.assets.length);

    vars.receiver = IFlashLoanReceiver(params.receiverAddress);
    (vars.flashloanPremiumTotal, vars.flashloanPremiumToProtocol) = params.isAuthorizedFlashBorrower
      ? (0, 0)
      : (params.flashLoanPremiumTotal, params.flashLoanPremiumToProtocol);

    for (vars.i = 0; vars.i < params.assets.length; vars.i++) {
      vars.currentAmount = params.amounts[vars.i];
      vars.totalPremiums[vars.i] = vars.currentAmount.percentMul(vars.flashloanPremiumTotal);
      IAToken(reservesData[params.assets[vars.i]].aTokenAddress).transferUnderlyingTo(
        params.receiverAddress,
        vars.currentAmount
      );
    }

    require(
      vars.receiver.executeOperation(
        params.assets,
        params.amounts,
        vars.totalPremiums,
        msg.sender,
        params.params
      ),
      Errors.INVALID_FLASHLOAN_EXECUTOR_RETURN
    );

    for (vars.i = 0; vars.i < params.assets.length; vars.i++) {
      vars.currentAsset = params.assets[vars.i];
      vars.currentAmount = params.amounts[vars.i];

      if (
        DataTypes.InterestRateMode(params.interestRateModes[vars.i]) ==
        DataTypes.InterestRateMode.NONE
      ) {
        _handleFlashLoanRepayment(
          reservesData[vars.currentAsset],
          DataTypes.FlashLoanRepaymentParams({
            asset: vars.currentAsset,
            receiverAddress: params.receiverAddress,
            amount: vars.currentAmount,
            totalPremium: vars.totalPremiums[vars.i],
            flashLoanPremiumToProtocol: vars.flashloanPremiumToProtocol,
            referralCode: params.referralCode
          })
        );
      } else {
        // If the user chose to not return the funds, the system checks if there is enough collateral and
        // eventually opens a debt position
        BorrowLogic.executeBorrow(
          reservesData,
          reservesList,
          eModeCategories,
          userConfig,
          DataTypes.ExecuteBorrowParams({
            asset: vars.currentAsset,
            user: msg.sender,
            onBehalfOf: params.onBehalfOf,
            amount: vars.currentAmount,
            interestRateMode: DataTypes.InterestRateMode(params.interestRateModes[vars.i]),
            referralCode: params.referralCode,
            releaseUnderlying: false,
            maxStableRateBorrowSizePercent: params.maxStableRateBorrowSizePercent,
            reservesCount: params.reservesCount,
            oracle: IPoolAddressesProvider(params.addressesProvider).getPriceOracle(),
            userEModeCategory: params.userEModeCategory,
            priceOracleSentinel: IPoolAddressesProvider(params.addressesProvider)
              .getPriceOracleSentinel()
          })
        );
        // no premium is paid when taking on the flashloan as debt
        emit FlashLoan(
          params.receiverAddress,
          msg.sender,
          vars.currentAsset,
          vars.currentAmount,
          DataTypes.InterestRateMode(params.interestRateModes[vars.i]),
          0,
          params.referralCode
        );
      }
    }
  }

  /**
   * @notice Implements the simple flashloan feature that allow users to access liquidity of ONE reserve for one
   * transaction as long as the amount taken plus fee is returned.
   * @dev Does not waive fee for approved flashborrowers nor allow taking on debt instead of repaying to save gas
   * @dev At the end of the transaction the pool will pull amount borrowed + fee from the receiver,
   * if the receiver have not approved the pool the transaction will revert.
   * @dev Emits the `FlashLoan()` event
   * @param reserve The state of the flashloaned reserve
   * @param params The additional parameters needed to execute the simple flashloan function
   */
  function executeFlashLoanSimple(
    DataTypes.ReserveData storage reserve,
    DataTypes.FlashloanSimpleParams memory params
  ) external {
    // The usual action flow (cache -> updateState -> validation -> changeState -> updateRates)
    // is altered to (validation -> user payload -> cache -> updateState -> changeState -> updateRates) for flashloans.
    // This is done to protect against reentrance and rate manipulation within the user specified payload.

    ValidationLogic.validateFlashloanSimple(reserve);

    IFlashLoanSimpleReceiver receiver = IFlashLoanSimpleReceiver(params.receiverAddress);
    uint256 totalPremium = params.amount.percentMul(params.flashLoanPremiumTotal);
    IAToken(reserve.aTokenAddress).transferUnderlyingTo(params.receiverAddress, params.amount);

    require(
      receiver.executeOperation(
        params.asset,
        params.amount,
        totalPremium,
        msg.sender,
        params.params
      ),
      Errors.INVALID_FLASHLOAN_EXECUTOR_RETURN
    );

    _handleFlashLoanRepayment(
      reserve,
      DataTypes.FlashLoanRepaymentParams({
        asset: params.asset,
        receiverAddress: params.receiverAddress,
        amount: params.amount,
        totalPremium: totalPremium,
        flashLoanPremiumToProtocol: params.flashLoanPremiumToProtocol,
        referralCode: params.referralCode
      })
    );
  }

  /**
   * @notice Handles repayment of flashloaned assets + premium
   * @dev Will pull the amount + premium from the receiver, so must have approved pool
   * @param reserve The state of the flashloaned reserve
   * @param params The additional parameters needed to execute the repayment function
   */
  function _handleFlashLoanRepayment(
    DataTypes.ReserveData storage reserve,
    DataTypes.FlashLoanRepaymentParams memory params
  ) internal {
    uint256 premiumToProtocol = params.totalPremium.percentMul(params.flashLoanPremiumToProtocol);
    uint256 premiumToLP = params.totalPremium - premiumToProtocol;
    uint256 amountPlusPremium = params.amount + params.totalPremium;

    DataTypes.ReserveCache memory reserveCache = reserve.cache();
    reserve.updateState(reserveCache);
    reserveCache.nextLiquidityIndex = reserve.cumulateToLiquidityIndex(
      IERC20(reserveCache.aTokenAddress).totalSupply(),
      premiumToLP
    );

    reserve.accruedToTreasury += premiumToProtocol
      .rayDiv(reserveCache.nextLiquidityIndex)
      .toUint128();

    reserve.updateInterestRates(reserveCache, params.asset, amountPlusPremium, 0);

    IERC20(params.asset).safeTransferFrom(
      params.receiverAddress,
      reserveCache.aTokenAddress,
      amountPlusPremium
    );

    IAToken(reserveCache.aTokenAddress).handleRepayment(params.receiverAddress, amountPlusPremium);

    emit FlashLoan(
      params.receiverAddress,
      msg.sender,
      params.asset,
      params.amount,
      DataTypes.InterestRateMode(0),
      params.totalPremium,
      params.referralCode
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IScaledBalanceToken} from '../../../interfaces/IScaledBalanceToken.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {EModeLogic} from './EModeLogic.sol';

/**
 * @title GenericLogic library
 *
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  struct CalculateUserAccountDataVars {
    uint256 assetPrice;
    uint256 assetUnit;
    uint256 userBalanceInBaseCurrency;
    uint256 decimals;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 i;
    uint256 healthFactor;
    uint256 totalCollateralInBaseCurrency;
    uint256 totalDebtInBaseCurrency;
    uint256 avgLtv;
    uint256 avgLiquidationThreshold;
    uint256 eModeAssetPrice;
    uint256 eModeLtv;
    uint256 eModeLiqThreshold;
    uint256 eModeAssetCategory;
    address currentReserveAddress;
    bool hasZeroLtvCollateral;
    bool isInEModeCategory;
  }

  /**
   * @notice Calculates the user data across the reserves.
   * @dev It includes the total liquidity/collateral/borrow balances in the base currency used by the price feed,
   * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param params Additional parameters needed for the calculation
   * @return The total collateral of the user in the base currency used by the price feed
   * @return The total debt of the user in the base currency used by the price feed
   * @return The average ltv of the user
   * @return The average liquidation threshold of the user
   * @return The health factor of the user
   * @return True if the ltv is zero, false otherwise
   **/
  function calculateUserAccountData(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.CalculateUserAccountDataParams memory params
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      bool
    )
  {
    if (params.userConfig.isEmpty()) {
      return (0, 0, 0, 0, type(uint256).max, false);
    }

    CalculateUserAccountDataVars memory vars;

    if (params.userEModeCategory != 0) {
      (vars.eModeLtv, vars.eModeLiqThreshold, vars.eModeAssetPrice) = EModeLogic
        .getEModeConfiguration(
          eModeCategories[params.userEModeCategory],
          IPriceOracleGetter(params.oracle)
        );
    }

    while (vars.i < params.reservesCount) {
      if (!params.userConfig.isUsingAsCollateralOrBorrowing(vars.i)) {
        unchecked {
          ++vars.i;
        }
        continue;
      }

      vars.currentReserveAddress = reservesList[vars.i];

      if (vars.currentReserveAddress == address(0)) {
        unchecked {
          ++vars.i;
        }
        continue;
      }

      DataTypes.ReserveData storage currentReserve = reservesData[vars.currentReserveAddress];

      (
        vars.ltv,
        vars.liquidationThreshold,
        ,
        vars.decimals,
        ,
        vars.eModeAssetCategory
      ) = currentReserve.configuration.getParams();

      unchecked {
        vars.assetUnit = 10**vars.decimals;
      }

      vars.assetPrice = vars.eModeAssetPrice != 0 &&
        params.userEModeCategory == vars.eModeAssetCategory
        ? vars.eModeAssetPrice
        : IPriceOracleGetter(params.oracle).getAssetPrice(vars.currentReserveAddress);

      if (vars.liquidationThreshold != 0 && params.userConfig.isUsingAsCollateral(vars.i)) {
        vars.userBalanceInBaseCurrency = _getUserBalanceInBaseCurrency(
          params.user,
          currentReserve,
          vars.assetPrice,
          vars.assetUnit
        );

        vars.totalCollateralInBaseCurrency += vars.userBalanceInBaseCurrency;

        vars.isInEModeCategory = EModeLogic.isInEModeCategory(
          params.userEModeCategory,
          vars.eModeAssetCategory
        );

        if (vars.ltv != 0) {
          vars.avgLtv +=
            vars.userBalanceInBaseCurrency *
            (vars.isInEModeCategory ? vars.eModeLtv : vars.ltv);
        } else {
          vars.hasZeroLtvCollateral = true;
        }

        vars.avgLiquidationThreshold +=
          vars.userBalanceInBaseCurrency *
          (vars.isInEModeCategory ? vars.eModeLiqThreshold : vars.liquidationThreshold);
      }

      if (params.userConfig.isBorrowing(vars.i)) {
        vars.totalDebtInBaseCurrency += _getUserDebtInBaseCurrency(
          params.user,
          currentReserve,
          vars.assetPrice,
          vars.assetUnit
        );
      }

      unchecked {
        ++vars.i;
      }
    }

    unchecked {
      vars.avgLtv = vars.totalCollateralInBaseCurrency != 0
        ? vars.avgLtv / vars.totalCollateralInBaseCurrency
        : 0;
      vars.avgLiquidationThreshold = vars.totalCollateralInBaseCurrency != 0
        ? vars.avgLiquidationThreshold / vars.totalCollateralInBaseCurrency
        : 0;
    }

    vars.healthFactor = (vars.totalDebtInBaseCurrency == 0)
      ? type(uint256).max
      : (vars.totalCollateralInBaseCurrency.percentMul(vars.avgLiquidationThreshold)).wadDiv(
        vars.totalDebtInBaseCurrency
      );
    return (
      vars.totalCollateralInBaseCurrency,
      vars.totalDebtInBaseCurrency,
      vars.avgLtv,
      vars.avgLiquidationThreshold,
      vars.healthFactor,
      vars.hasZeroLtvCollateral
    );
  }

  /**
   * @notice Calculates the maximum amount that can be borrowed depending on the available collateral, the total debt
   * and the average Loan To Value
   * @param totalCollateralInBaseCurrency The total collateral in the base currency used by the price feed
   * @param totalDebtInBaseCurrency The total borrow balance in the base currency used by the price feed
   * @param ltv The average loan to value
   * @return The amount available to borrow in the base currency of the used by the price feed
   **/
  function calculateAvailableBorrows(
    uint256 totalCollateralInBaseCurrency,
    uint256 totalDebtInBaseCurrency,
    uint256 ltv
  ) internal pure returns (uint256) {
    uint256 availableBorrowsInBaseCurrency = totalCollateralInBaseCurrency.percentMul(ltv);

    if (availableBorrowsInBaseCurrency < totalDebtInBaseCurrency) {
      return 0;
    }

    availableBorrowsInBaseCurrency = availableBorrowsInBaseCurrency - totalDebtInBaseCurrency;
    return availableBorrowsInBaseCurrency;
  }

  /**
   * @notice Calculates total debt of the user in the based currency used to normalize the values of the assets
   * @dev This fetches the `balanceOf` of the stable and variable debt tokens for the user. For gas reasons, the
   * variable debt balance is calculated by fetching `scaledBalancesOf` normalized debt, which is cheaper than
   * fetching `balanceOf`
   * @param user The address of the user
   * @param reserve The data of the reserve for which the total debt of the user is being calculated
   * @param assetPrice The price of the asset for which the total debt of the user is being calculated
   * @param assetUnit The value representing one full unit of the asset (10^decimals)
   * @return The total debt of the user normalized to the base currency
   **/
  function _getUserDebtInBaseCurrency(
    address user,
    DataTypes.ReserveData storage reserve,
    uint256 assetPrice,
    uint256 assetUnit
  ) private view returns (uint256) {
    // fetching variable debt
    uint256 userTotalDebt = IScaledBalanceToken(reserve.variableDebtTokenAddress).scaledBalanceOf(
      user
    );
    if (userTotalDebt != 0) {
      userTotalDebt = userTotalDebt.rayMul(reserve.getNormalizedDebt());
    }

    userTotalDebt = userTotalDebt + IERC20(reserve.stableDebtTokenAddress).balanceOf(user);

    userTotalDebt = assetPrice * userTotalDebt;

    unchecked {
      return userTotalDebt / assetUnit;
    }
  }

  /**
   * @notice Calculates total aToken balance of the user in the based currency used by the price oracle
   * @dev For gas reasons, the aToken balance is calculated by fetching `scaledBalancesOf` normalized debt, which
   * is cheaper than fetching `balanceOf`
   * @param user The address of the user
   * @param reserve The data of the reserve for which the total aToken balance of the user is being calculated
   * @param assetPrice The price of the asset for which the total aToken balance of the user is being calculated
   * @param assetUnit The value representing one full unit of the asset (10^decimals)
   * @return The total aToken balance of the user normalized to the base currency of the price oracle
   **/
  function _getUserBalanceInBaseCurrency(
    address user,
    DataTypes.ReserveData storage reserve,
    uint256 assetPrice,
    uint256 assetUnit
  ) private view returns (uint256) {
    uint256 normalizedIncome = reserve.getNormalizedIncome();
    uint256 balance = (
      IScaledBalanceToken(reserve.aTokenAddress).scaledBalanceOf(user).rayMul(normalizedIncome)
    ) * assetPrice;

    unchecked {
      return balance / assetUnit;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {DataTypes} from '../types/DataTypes.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';

/**
 * @title IsolationModeLogic library
 *
 * @notice Implements the base logic for handling repayments for assets borrowed in isolation mode
 */
library IsolationModeLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using SafeCast for uint256;

  // See `IPool` for descriptions
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @notice updated the isolated debt whenever a position collateralized by an isolated asset is repaid or liquidated
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping
   * @param reserveCache The cached data of the reserve
   * @param repayAmount The amount being repaid
   */
  function updateIsolatedDebtIfIsolated(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveCache memory reserveCache,
    uint256 repayAmount
  ) internal {
    (bool isolationModeActive, address isolationModeCollateralAddress, ) = userConfig
      .getIsolationModeState(reservesData, reservesList);

    if (isolationModeActive) {
      uint128 isolationModeTotalDebt = reservesData[isolationModeCollateralAddress]
        .isolationModeTotalDebt;

      uint128 isolatedDebtRepaid = (repayAmount /
        10 **
          (reserveCache.reserveConfiguration.getDecimals() -
            ReserveConfiguration.DEBT_CEILING_DECIMALS)).toUint128();

      // since the debt ceiling does not take into account the interest accrued, it might happen that amount
      // repaid > debt in isolation mode
      if (isolationModeTotalDebt <= isolatedDebtRepaid) {
        reservesData[isolationModeCollateralAddress].isolationModeTotalDebt = 0;
        emit IsolationModeTotalDebtUpdated(isolationModeCollateralAddress, 0);
      } else {
        uint256 nextIsolationModeTotalDebt = reservesData[isolationModeCollateralAddress]
          .isolationModeTotalDebt = isolationModeTotalDebt - isolatedDebtRepaid;
        emit IsolationModeTotalDebtUpdated(
          isolationModeCollateralAddress,
          nextIsolationModeTotalDebt
        );
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts//IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {PercentageMath} from '../../libraries/math/PercentageMath.sol';
import {WadRayMath} from '../../libraries/math/WadRayMath.sol';
import {Helpers} from '../../libraries/helpers/Helpers.sol';
import {DataTypes} from '../../libraries/types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {GenericLogic} from './GenericLogic.sol';
import {IsolationModeLogic} from './IsolationModeLogic.sol';
import {EModeLogic} from './EModeLogic.sol';
import {UserConfiguration} from '../../libraries/configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../../libraries/configuration/ReserveConfiguration.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {IStableDebtToken} from '../../../interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';

/**
 * @title LiquidationLogic library
 *
 * @notice Implements actions involving management of collateral in the protocol, the main one being the liquidations
 **/
library LiquidationLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using GPv2SafeERC20 for IERC20;

  // See `IPool` for descriptions
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Default percentage of borrower's debt to be repaid in a liquidation.
   * @dev Percentage applied when the users health factor is above `CLOSE_FACTOR_HF_THRESHOLD`
   * Expressed in bps, a value of 0.5e4 results in 50.00%
   */
  uint256 internal constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 0.5e4;

  /**
   * @dev Maximum percentage of borrower's debt to be repaid in a liquidation
   * @dev Percentage applied when the users health factor is below `CLOSE_FACTOR_HF_THRESHOLD`
   * Expressed in bps, a value of 1e4 results in 100.00%
   */
  uint256 public constant MAX_LIQUIDATION_CLOSE_FACTOR = 1e4;

  /**
   * @dev This constant represents below which health factor value it is possible to liquidate
   * an amount of debt corresponding to `MAX_LIQUIDATION_CLOSE_FACTOR`.
   * A value of 0.95e18 results in 0.95
   */
  uint256 public constant CLOSE_FACTOR_HF_THRESHOLD = 0.95e18;

  struct LiquidationCallLocalVars {
    uint256 userCollateralBalance;
    uint256 userVariableDebt;
    uint256 userTotalDebt;
    uint256 actualDebtToLiquidate;
    uint256 actualCollateralToLiquidate;
    uint256 liquidationBonus;
    uint256 healthFactor;
    uint256 liquidationProtocolFeeAmount;
    address collateralPriceSource;
    address debtPriceSource;
    IAToken collateralAToken;
    DataTypes.ReserveCache debtReserveCache;
  }

  /**
   * @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
   * covers `debtToCover` amount of debt of the user getting liquidated, and receives
   * a proportional amount of the `collateralAsset` plus a bonus to cover market risk
   * @dev Emits the `LiquidationCall()` event
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param params The additional parameters needed to execute the liquidation function
   **/
  function executeLiquidationCall(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.ExecuteLiquidationCallParams memory params
  ) external {
    LiquidationCallLocalVars memory vars;

    DataTypes.ReserveData storage collateralReserve = reservesData[params.collateralAsset];
    DataTypes.ReserveData storage debtReserve = reservesData[params.debtAsset];
    DataTypes.UserConfigurationMap storage userConfig = usersConfig[params.user];
    vars.debtReserveCache = debtReserve.cache();
    debtReserve.updateState(vars.debtReserveCache);

    (, , , , vars.healthFactor, ) = GenericLogic.calculateUserAccountData(
      reservesData,
      reservesList,
      eModeCategories,
      DataTypes.CalculateUserAccountDataParams({
        userConfig: userConfig,
        reservesCount: params.reservesCount,
        user: params.user,
        oracle: params.priceOracle,
        userEModeCategory: params.userEModeCategory
      })
    );

    (vars.userVariableDebt, vars.userTotalDebt, vars.actualDebtToLiquidate) = _calculateDebt(
      vars.debtReserveCache,
      params,
      vars.healthFactor
    );

    ValidationLogic.validateLiquidationCall(
      userConfig,
      collateralReserve,
      DataTypes.ValidateLiquidationCallParams({
        debtReserveCache: vars.debtReserveCache,
        totalDebt: vars.userTotalDebt,
        healthFactor: vars.healthFactor,
        priceOracleSentinel: params.priceOracleSentinel
      })
    );

    (
      vars.collateralAToken,
      vars.collateralPriceSource,
      vars.debtPriceSource,
      vars.liquidationBonus
    ) = _getConfigurationData(eModeCategories, collateralReserve, params);

    vars.userCollateralBalance = vars.collateralAToken.balanceOf(params.user);

    (
      vars.actualCollateralToLiquidate,
      vars.actualDebtToLiquidate,
      vars.liquidationProtocolFeeAmount
    ) = _calculateAvailableCollateralToLiquidate(
      collateralReserve,
      vars.debtReserveCache,
      vars.collateralPriceSource,
      vars.debtPriceSource,
      vars.actualDebtToLiquidate,
      vars.userCollateralBalance,
      vars.liquidationBonus,
      IPriceOracleGetter(params.priceOracle)
    );

    if (vars.userTotalDebt == vars.actualDebtToLiquidate) {
      userConfig.setBorrowing(debtReserve.id, false);
    }

    _burnDebtTokens(params, vars);

    debtReserve.updateInterestRates(
      vars.debtReserveCache,
      params.debtAsset,
      vars.actualDebtToLiquidate,
      0
    );

    IsolationModeLogic.updateIsolatedDebtIfIsolated(
      reservesData,
      reservesList,
      userConfig,
      vars.debtReserveCache,
      vars.actualDebtToLiquidate
    );

    if (params.receiveAToken) {
      _liquidateATokens(reservesData, reservesList, usersConfig, collateralReserve, params, vars);
    } else {
      _burnCollateralATokens(collateralReserve, params, vars);
    }

    // Transfer fee to treasury if it is non-zero
    if (vars.liquidationProtocolFeeAmount != 0) {
      vars.collateralAToken.transferOnLiquidation(
        params.user,
        vars.collateralAToken.RESERVE_TREASURY_ADDRESS(),
        vars.liquidationProtocolFeeAmount
      );
    }

    // If the collateral being liquidated is equal to the user balance,
    // we set the currency as not being used as collateral anymore
    if (vars.actualCollateralToLiquidate == vars.userCollateralBalance) {
      userConfig.setUsingAsCollateral(collateralReserve.id, false);
      emit ReserveUsedAsCollateralDisabled(params.collateralAsset, params.user);
    }

    // Transfers the debt asset being repaid to the aToken, where the liquidity is kept
    IERC20(params.debtAsset).safeTransferFrom(
      msg.sender,
      vars.debtReserveCache.aTokenAddress,
      vars.actualDebtToLiquidate
    );

    IAToken(vars.debtReserveCache.aTokenAddress).handleRepayment(
      msg.sender,
      vars.actualDebtToLiquidate
    );

    emit LiquidationCall(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      vars.actualDebtToLiquidate,
      vars.actualCollateralToLiquidate,
      msg.sender,
      params.receiveAToken
    );
  }

  /**
   * @notice Burns the collateral aTokens and transfers the underlying to the liquidator.
   * @dev   The function also updates the state and the interest rate of the collateral reserve.
   * @param collateralReserve The data of the collateral reserve
   * @param params The additional parameters needed to execute the liquidation function
   * @param vars The executeLiquidationCall() function local vars
   */
  function _burnCollateralATokens(
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ExecuteLiquidationCallParams memory params,
    LiquidationCallLocalVars memory vars
  ) internal {
    DataTypes.ReserveCache memory collateralReserveCache = collateralReserve.cache();
    collateralReserve.updateState(collateralReserveCache);
    collateralReserve.updateInterestRates(
      collateralReserveCache,
      params.collateralAsset,
      0,
      vars.actualCollateralToLiquidate
    );

    // Burn the equivalent amount of aToken, sending the underlying to the liquidator
    vars.collateralAToken.burn(
      params.user,
      msg.sender,
      vars.actualCollateralToLiquidate,
      collateralReserveCache.nextLiquidityIndex
    );
  }

  /**
   * @notice Liquidates the user aTokens by transferring them to the liquidator.
   * @dev   The function also checks the state of the liquidator and activates the aToken as collateral
   *        as in standard transfers if the isolation mode constraints are respected.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
   * @param collateralReserve The data of the collateral reserve
   * @param params The additional parameters needed to execute the liquidation function
   * @param vars The executeLiquidationCall() function local vars
   */
  function _liquidateATokens(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ExecuteLiquidationCallParams memory params,
    LiquidationCallLocalVars memory vars
  ) internal {
    uint256 liquidatorPreviousATokenBalance = IERC20(vars.collateralAToken).balanceOf(msg.sender);
    vars.collateralAToken.transferOnLiquidation(
      params.user,
      msg.sender,
      vars.actualCollateralToLiquidate
    );

    if (liquidatorPreviousATokenBalance == 0) {
      DataTypes.UserConfigurationMap storage liquidatorConfig = usersConfig[msg.sender];
      if (
        ValidationLogic.validateUseAsCollateral(
          reservesData,
          reservesList,
          liquidatorConfig,
          collateralReserve.configuration
        )
      ) {
        liquidatorConfig.setUsingAsCollateral(collateralReserve.id, true);
        emit ReserveUsedAsCollateralEnabled(params.collateralAsset, msg.sender);
      }
    }
  }

  /**
   * @notice Burns the debt tokens of the user up to the amount being repaid by the liquidator.
   * @dev The function alters the `debtReserveCache` state in `vars` to update the debt related data.
   * @param params The additional parameters needed to execute the liquidation function
   * @param vars the executeLiquidationCall() function local vars
   */
  function _burnDebtTokens(
    DataTypes.ExecuteLiquidationCallParams memory params,
    LiquidationCallLocalVars memory vars
  ) internal {
    if (vars.userVariableDebt >= vars.actualDebtToLiquidate) {
      vars.debtReserveCache.nextScaledVariableDebt = IVariableDebtToken(
        vars.debtReserveCache.variableDebtTokenAddress
      ).burn(
          params.user,
          vars.actualDebtToLiquidate,
          vars.debtReserveCache.nextVariableBorrowIndex
        );
    } else {
      // If the user doesn't have variable debt, no need to try to burn variable debt tokens
      if (vars.userVariableDebt != 0) {
        vars.debtReserveCache.nextScaledVariableDebt = IVariableDebtToken(
          vars.debtReserveCache.variableDebtTokenAddress
        ).burn(params.user, vars.userVariableDebt, vars.debtReserveCache.nextVariableBorrowIndex);
      }
      (
        vars.debtReserveCache.nextTotalStableDebt,
        vars.debtReserveCache.nextAvgStableBorrowRate
      ) = IStableDebtToken(vars.debtReserveCache.stableDebtTokenAddress).burn(
        params.user,
        vars.actualDebtToLiquidate - vars.userVariableDebt
      );
    }
  }

  /**
   * @notice Calculates the total debt of the user and the actual amount to liquidate depending on the health factor
   * and corresponding close factor.
   * @dev If the Health Factor is below CLOSE_FACTOR_HF_THRESHOLD, the close factor is increased to MAX_LIQUIDATION_CLOSE_FACTOR
   * @param debtReserveCache The reserve cache data object of the debt reserve
   * @param params The additional parameters needed to execute the liquidation function
   * @param healthFactor The health factor of the position
   * @return The variable debt of the user
   * @return The total debt of the user
   * @return The actual debt to liquidate as a function of the closeFactor
   */
  function _calculateDebt(
    DataTypes.ReserveCache memory debtReserveCache,
    DataTypes.ExecuteLiquidationCallParams memory params,
    uint256 healthFactor
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 userStableDebt, uint256 userVariableDebt) = Helpers.getUserCurrentDebt(
      params.user,
      debtReserveCache
    );

    uint256 userTotalDebt = userStableDebt + userVariableDebt;

    uint256 closeFactor = healthFactor > CLOSE_FACTOR_HF_THRESHOLD
      ? DEFAULT_LIQUIDATION_CLOSE_FACTOR
      : MAX_LIQUIDATION_CLOSE_FACTOR;

    uint256 maxLiquidatableDebt = userTotalDebt.percentMul(closeFactor);

    uint256 actualDebtToLiquidate = params.debtToCover > maxLiquidatableDebt
      ? maxLiquidatableDebt
      : params.debtToCover;

    return (userVariableDebt, userTotalDebt, actualDebtToLiquidate);
  }

  /**
   * @notice Returns the configuration data for the debt and the collateral reserves.
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param collateralReserve The data of the collateral reserve
   * @param params The additional parameters needed to execute the liquidation function
   * @return The collateral aToken
   * @return The address to use as price source for the collateral
   * @return The address to use as price source for the debt
   * @return The liquidation bonus to apply to the collateral
   */
  function _getConfigurationData(
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ExecuteLiquidationCallParams memory params
  )
    internal
    view
    returns (
      IAToken,
      address,
      address,
      uint256
    )
  {
    IAToken collateralAToken = IAToken(collateralReserve.aTokenAddress);
    uint256 liquidationBonus = collateralReserve.configuration.getLiquidationBonus();

    address collateralPriceSource = params.collateralAsset;
    address debtPriceSource = params.debtAsset;

    if (params.userEModeCategory != 0) {
      address eModePriceSource = eModeCategories[params.userEModeCategory].priceSource;

      if (
        EModeLogic.isInEModeCategory(
          params.userEModeCategory,
          collateralReserve.configuration.getEModeCategory()
        )
      ) {
        liquidationBonus = eModeCategories[params.userEModeCategory].liquidationBonus;

        if (eModePriceSource != address(0)) {
          collateralPriceSource = eModePriceSource;
        }
      }

      // when in eMode, debt will always be in the same eMode category, can skip matching category check
      if (eModePriceSource != address(0)) {
        debtPriceSource = eModePriceSource;
      }
    }

    return (collateralAToken, collateralPriceSource, debtPriceSource, liquidationBonus);
  }

  struct AvailableCollateralToLiquidateLocalVars {
    uint256 collateralPrice;
    uint256 debtAssetPrice;
    uint256 maxCollateralToLiquidate;
    uint256 baseCollateral;
    uint256 bonusCollateral;
    uint256 debtAssetDecimals;
    uint256 collateralDecimals;
    uint256 collateralAssetUnit;
    uint256 debtAssetUnit;
    uint256 collateralAmount;
    uint256 debtAmountNeeded;
    uint256 liquidationProtocolFeePercentage;
    uint256 liquidationProtocolFee;
  }

  /**
   * @notice Calculates how much of a specific collateral can be liquidated, given
   * a certain amount of debt asset.
   * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
   *   otherwise it might fail.
   * @param collateralReserve The data of the collateral reserve
   * @param debtReserveCache The cached data of the debt reserve
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param userCollateralBalance The collateral balance for the specific `collateralAsset` of the user being liquidated
   * @param liquidationBonus The collateral bonus percentage to receive as result of the liquidation
   * @return The maximum amount that is possible to liquidate given all the liquidation constraints (user balance, close factor)
   * @return The amount to repay with the liquidation
   * @return The fee taken from the liquidation bonus amount to be paid to the protocol
   **/
  function _calculateAvailableCollateralToLiquidate(
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ReserveCache memory debtReserveCache,
    address collateralAsset,
    address debtAsset,
    uint256 debtToCover,
    uint256 userCollateralBalance,
    uint256 liquidationBonus,
    IPriceOracleGetter oracle
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    AvailableCollateralToLiquidateLocalVars memory vars;

    vars.collateralPrice = oracle.getAssetPrice(collateralAsset);
    vars.debtAssetPrice = oracle.getAssetPrice(debtAsset);

    vars.collateralDecimals = collateralReserve.configuration.getDecimals();
    vars.debtAssetDecimals = debtReserveCache.reserveConfiguration.getDecimals();

    unchecked {
      vars.collateralAssetUnit = 10**vars.collateralDecimals;
      vars.debtAssetUnit = 10**vars.debtAssetDecimals;
    }

    vars.liquidationProtocolFeePercentage = collateralReserve
      .configuration
      .getLiquidationProtocolFee();

    // This is the base collateral to liquidate based on the given debt to cover
    vars.baseCollateral =
      ((vars.debtAssetPrice * debtToCover * vars.collateralAssetUnit)) /
      (vars.collateralPrice * vars.debtAssetUnit);

    vars.maxCollateralToLiquidate = vars.baseCollateral.percentMul(liquidationBonus);

    if (vars.maxCollateralToLiquidate > userCollateralBalance) {
      vars.collateralAmount = userCollateralBalance;
      vars.debtAmountNeeded = ((vars.collateralPrice * vars.collateralAmount * vars.debtAssetUnit) /
        (vars.debtAssetPrice * vars.collateralAssetUnit)).percentDiv(liquidationBonus);
    } else {
      vars.collateralAmount = vars.maxCollateralToLiquidate;
      vars.debtAmountNeeded = debtToCover;
    }

    if (vars.liquidationProtocolFeePercentage != 0) {
      vars.bonusCollateral =
        vars.collateralAmount -
        vars.collateralAmount.percentDiv(liquidationBonus);

      vars.liquidationProtocolFee = vars.bonusCollateral.percentMul(
        vars.liquidationProtocolFeePercentage
      );

      return (
        vars.collateralAmount - vars.liquidationProtocolFee,
        vars.debtAmountNeeded,
        vars.liquidationProtocolFee
      );
    } else {
      return (vars.collateralAmount, vars.debtAmountNeeded, 0);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {Address} from '../../../dependencies/openzeppelin/contracts/Address.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {GenericLogic} from './GenericLogic.sol';

/**
 * @title PoolLogic library
 *
 * @notice Implements the logic for Pool specific functions
 */
library PoolLogic {
  using GPv2SafeERC20 for IERC20;
  using WadRayMath for uint256;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  // See `IPool` for descriptions
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @notice Initialize an asset reserve and add the reserve to the list of reserves
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param params Additional parameters needed for initiation
   * @return true if appended, false if inserted at existing empty spot
   **/
  function executeInitReserve(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.InitReserveParams memory params
  ) external returns (bool) {
    require(Address.isContract(params.asset), Errors.NOT_CONTRACT);
    reservesData[params.asset].init(
      params.aTokenAddress,
      params.stableDebtAddress,
      params.variableDebtAddress,
      params.interestRateStrategyAddress
    );

    bool reserveAlreadyAdded = reservesData[params.asset].id != 0 ||
      reservesList[0] == params.asset;
    require(!reserveAlreadyAdded, Errors.RESERVE_ALREADY_ADDED);

    for (uint16 i = 0; i < params.reservesCount; i++) {
      if (reservesList[i] == address(0)) {
        reservesData[params.asset].id = i;
        reservesList[i] = params.asset;
        return false;
      }
    }

    require(params.reservesCount < params.maxNumberReserves, Errors.NO_MORE_RESERVES_ALLOWED);
    reservesData[params.asset].id = params.reservesCount;
    reservesList[params.reservesCount] = params.asset;
    return true;
  }

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function executeRescueTokens(
    address token,
    address to,
    uint256 amount
  ) external {
    IERC20(token).safeTransfer(to, amount);
  }

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param reservesData The state of all the reserves
   * @param assets The list of reserves for which the minting needs to be executed
   **/
  function executeMintToTreasury(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address[] calldata assets
  ) external {
    for (uint256 i = 0; i < assets.length; i++) {
      address assetAddress = assets[i];

      DataTypes.ReserveData storage reserve = reservesData[assetAddress];

      // this cover both inactive reserves and invalid reserves since the flag will be 0 for both
      if (!reserve.configuration.getActive()) {
        continue;
      }

      uint256 accruedToTreasury = reserve.accruedToTreasury;

      if (accruedToTreasury != 0) {
        reserve.accruedToTreasury = 0;
        uint256 normalizedIncome = reserve.getNormalizedIncome();
        uint256 amountToMint = accruedToTreasury.rayMul(normalizedIncome);
        IAToken(reserve.aTokenAddress).mintToTreasury(amountToMint, normalizedIncome);

        emit MintedToTreasury(assetAddress, amountToMint);
      }
    }
  }

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param reservesData The state of all the reserves
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function executeResetIsolationModeTotalDebt(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address asset
  ) external {
    require(reservesData[asset].configuration.getDebtCeiling() == 0, Errors.DEBT_CEILING_NOT_ZERO);
    reservesData[asset].isolationModeTotalDebt = 0;
    emit IsolationModeTotalDebtUpdated(asset, 0);
  }

  /**
   * @notice Drop a reserve
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param asset The address of the underlying asset of the reserve
   **/
  function executeDropReserve(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    address asset
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[asset];
    ValidationLogic.validateDropReserve(reservesList, reserve, asset);
    reservesList[reservesData[asset].id] = address(0);
    delete reservesData[asset];
  }

  /**
   * @notice Returns the user account data across all the reserves
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param params Additional params needed for the calculation
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
  function executeGetUserAccountData(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.CalculateUserAccountDataParams memory params
  )
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    (
      totalCollateralBase,
      totalDebtBase,
      ltv,
      currentLiquidationThreshold,
      healthFactor,

    ) = GenericLogic.calculateUserAccountData(reservesData, reservesList, eModeCategories, params);

    availableBorrowsBase = GenericLogic.calculateAvailableBorrows(
      totalCollateralBase,
      totalDebtBase,
      ltv
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IStableDebtToken} from '../../../interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IReserveInterestRateStrategy} from '../../../interfaces/IReserveInterestRateStrategy.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {MathUtils} from '../math/MathUtils.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';

/**
 * @title ReserveLogic library
 *
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using GPv2SafeERC20 for IERC20;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  // See `IPool` for descriptions
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @notice Returns the ongoing normalized income for the reserve.
   * @dev A value of 1e27 means there is no income. As time passes, the income is accrued
   * @dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return The normalized income, expressed in ray
   **/
  function getNormalizedIncome(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256)
  {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == block.timestamp) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndex;
    } else {
      return
        MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
          reserve.liquidityIndex
        );
    }
  }

  /**
   * @notice Returns the ongoing normalized variable debt for the reserve.
   * @dev A value of 1e27 means there is no debt. As time passes, the debt is accrued
   * @dev A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
   * @param reserve The reserve object
   * @return The normalized variable debt, expressed in ray
   **/
  function getNormalizedDebt(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256)
  {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == block.timestamp) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.variableBorrowIndex;
    } else {
      return
        MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp).rayMul(
          reserve.variableBorrowIndex
        );
    }
  }

  /**
   * @notice Updates the liquidity cumulative index and the variable borrow index.
   * @param reserve The reserve object
   * @param reserveCache The caching layer for the reserve data
   **/
  function updateState(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {
    _updateIndexes(reserve, reserveCache);
    _accrueToTreasury(reserve, reserveCache);
  }

  /**
   * @notice Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example
   * to accumulate the flashloan fee to the reserve, and spread it between all the suppliers.
   * @param reserve The reserve object
   * @param totalLiquidity The total liquidity available in the reserve
   * @param amount The amount to accumulate
   * @return The next liquidity index of the reserve
   **/
  function cumulateToLiquidityIndex(
    DataTypes.ReserveData storage reserve,
    uint256 totalLiquidity,
    uint256 amount
  ) internal returns (uint256) {
    //next liquidity index is calculated this way: `((amount / totalLiquidity) + 1) * liquidityIndex`
    //division `amount / totalLiquidity` done in ray for precision
    uint256 result = (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) + WadRayMath.RAY).rayMul(
      reserve.liquidityIndex
    );
    reserve.liquidityIndex = result.toUint128();
    return result;
  }

  /**
   * @notice Initializes a reserve.
   * @param reserve The reserve object
   * @param aTokenAddress The address of the overlying atoken contract
   * @param stableDebtTokenAddress The address of the overlying stable debt token contract
   * @param variableDebtTokenAddress The address of the overlying variable debt token contract
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function init(
    DataTypes.ReserveData storage reserve,
    address aTokenAddress,
    address stableDebtTokenAddress,
    address variableDebtTokenAddress,
    address interestRateStrategyAddress
  ) internal {
    require(reserve.aTokenAddress == address(0), Errors.RESERVE_ALREADY_INITIALIZED);

    reserve.liquidityIndex = uint128(WadRayMath.RAY);
    reserve.variableBorrowIndex = uint128(WadRayMath.RAY);
    reserve.aTokenAddress = aTokenAddress;
    reserve.stableDebtTokenAddress = stableDebtTokenAddress;
    reserve.variableDebtTokenAddress = variableDebtTokenAddress;
    reserve.interestRateStrategyAddress = interestRateStrategyAddress;
  }

  struct UpdateInterestRatesLocalVars {
    uint256 nextLiquidityRate;
    uint256 nextStableRate;
    uint256 nextVariableRate;
    uint256 totalVariableDebt;
  }

  /**
   * @notice Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate.
   * @param reserve The reserve reserve to be updated
   * @param reserveCache The caching layer for the reserve data
   * @param reserveAddress The address of the reserve to be updated
   * @param liquidityAdded The amount of liquidity added to the protocol (supply or repay) in the previous action
   * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
   **/
  function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    address reserveAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
  ) internal {
    UpdateInterestRatesLocalVars memory vars;

    vars.totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );

    (
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate
    ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress).calculateInterestRates(
      DataTypes.CalculateInterestRatesParams({
        unbacked: reserveCache.reserveConfiguration.getUnbackedMintCap() != 0
          ? reserve.unbacked
          : 0,
        liquidityAdded: liquidityAdded,
        liquidityTaken: liquidityTaken,
        totalStableDebt: reserveCache.nextTotalStableDebt,
        totalVariableDebt: vars.totalVariableDebt,
        averageStableBorrowRate: reserveCache.nextAvgStableBorrowRate,
        reserveFactor: reserveCache.reserveFactor,
        reserve: reserveAddress,
        aToken: reserveCache.aTokenAddress
      })
    );

    reserve.currentLiquidityRate = vars.nextLiquidityRate.toUint128();
    reserve.currentStableBorrowRate = vars.nextStableRate.toUint128();
    reserve.currentVariableBorrowRate = vars.nextVariableRate.toUint128();

    emit ReserveDataUpdated(
      reserveAddress,
      vars.nextLiquidityRate,
      vars.nextStableRate,
      vars.nextVariableRate,
      reserveCache.nextLiquidityIndex,
      reserveCache.nextVariableBorrowIndex
    );
  }

  struct AccrueToTreasuryLocalVars {
    uint256 prevTotalStableDebt;
    uint256 prevTotalVariableDebt;
    uint256 currTotalVariableDebt;
    uint256 cumulatedStableInterest;
    uint256 totalDebtAccrued;
    uint256 amountToMint;
  }

  /**
   * @notice Mints part of the repaid interest to the reserve treasury as a function of the reserve factor for the
   * specific asset.
   * @param reserve The reserve to be updated
   * @param reserveCache The caching layer for the reserve data
   **/
  function _accrueToTreasury(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {
    AccrueToTreasuryLocalVars memory vars;

    if (reserveCache.reserveFactor == 0) {
      return;
    }

    //calculate the total variable debt at moment of the last interaction
    vars.prevTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
      reserveCache.currVariableBorrowIndex
    );

    //calculate the new total variable debt after accumulation of the interest on the index
    vars.currTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
      reserveCache.nextVariableBorrowIndex
    );

    //calculate the stable debt until the last timestamp update
    vars.cumulatedStableInterest = MathUtils.calculateCompoundedInterest(
      reserveCache.currAvgStableBorrowRate,
      reserveCache.stableDebtLastUpdateTimestamp,
      reserveCache.reserveLastUpdateTimestamp
    );

    vars.prevTotalStableDebt = reserveCache.currPrincipalStableDebt.rayMul(
      vars.cumulatedStableInterest
    );

    //debt accrued is the sum of the current debt minus the sum of the debt at the last update
    vars.totalDebtAccrued =
      vars.currTotalVariableDebt +
      reserveCache.currTotalStableDebt -
      vars.prevTotalVariableDebt -
      vars.prevTotalStableDebt;

    vars.amountToMint = vars.totalDebtAccrued.percentMul(reserveCache.reserveFactor);

    if (vars.amountToMint != 0) {
      reserve.accruedToTreasury += vars
        .amountToMint
        .rayDiv(reserveCache.nextLiquidityIndex)
        .toUint128();
    }
  }

  /**
   * @notice Updates the reserve indexes and the timestamp of the update.
   * @param reserve The reserve reserve to be updated
   * @param reserveCache The cache layer holding the cached protocol data
   **/
  function _updateIndexes(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache
  ) internal {
    reserveCache.nextLiquidityIndex = reserveCache.currLiquidityIndex;
    reserveCache.nextVariableBorrowIndex = reserveCache.currVariableBorrowIndex;

    //only cumulating if there is any income being produced
    if (reserveCache.currLiquidityRate != 0) {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
        reserveCache.currLiquidityRate,
        reserveCache.reserveLastUpdateTimestamp
      );
      reserveCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
        reserveCache.currLiquidityIndex
      );
      reserve.liquidityIndex = reserveCache.nextLiquidityIndex.toUint128();

      //as the liquidity rate might come only from stable rate loans, we need to ensure
      //that there is actual variable debt before accumulating
      if (reserveCache.currScaledVariableDebt != 0) {
        uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
          reserveCache.currVariableBorrowRate,
          reserveCache.reserveLastUpdateTimestamp
        );
        reserveCache.nextVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(
          reserveCache.currVariableBorrowIndex
        );
        reserve.variableBorrowIndex = reserveCache.nextVariableBorrowIndex.toUint128();
      }
    }

    //solium-disable-next-line
    reserve.lastUpdateTimestamp = uint40(block.timestamp);
  }

  /**
   * @notice Creates a cache object to avoid repeated storage reads and external contract calls when updating state and
   * interest rates.
   * @param reserve The reserve object for which the cache will be filled
   * @return The cache object
   */
  function cache(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (DataTypes.ReserveCache memory)
  {
    DataTypes.ReserveCache memory reserveCache;

    reserveCache.reserveConfiguration = reserve.configuration;
    reserveCache.reserveFactor = reserveCache.reserveConfiguration.getReserveFactor();
    reserveCache.currLiquidityIndex = reserve.liquidityIndex;
    reserveCache.currVariableBorrowIndex = reserve.variableBorrowIndex;
    reserveCache.currLiquidityRate = reserve.currentLiquidityRate;
    reserveCache.currVariableBorrowRate = reserve.currentVariableBorrowRate;

    reserveCache.aTokenAddress = reserve.aTokenAddress;
    reserveCache.stableDebtTokenAddress = reserve.stableDebtTokenAddress;
    reserveCache.variableDebtTokenAddress = reserve.variableDebtTokenAddress;

    reserveCache.reserveLastUpdateTimestamp = reserve.lastUpdateTimestamp;

    reserveCache.currScaledVariableDebt = reserveCache.nextScaledVariableDebt = IVariableDebtToken(
      reserveCache.variableDebtTokenAddress
    ).scaledTotalSupply();

    (
      reserveCache.currPrincipalStableDebt,
      reserveCache.currTotalStableDebt,
      reserveCache.currAvgStableBorrowRate,
      reserveCache.stableDebtLastUpdateTimestamp
    ) = IStableDebtToken(reserveCache.stableDebtTokenAddress).getSupplyData();

    // by default the actions are considered as not affecting the debt balances.
    // if the action involves mint/burn of debt, the cache needs to be updated
    reserveCache.nextTotalStableDebt = reserveCache.currTotalStableDebt;
    reserveCache.nextAvgStableBorrowRate = reserveCache.currAvgStableBorrowRate;

    return reserveCache;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {Errors} from '../helpers/Errors.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {ValidationLogic} from './ValidationLogic.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';

/**
 * @title SupplyLogic library
 *
 * @notice Implements the base logic for supply/withdraw
 */
library SupplyLogic {
  using ReserveLogic for DataTypes.ReserveCache;
  using ReserveLogic for DataTypes.ReserveData;
  using GPv2SafeERC20 for IERC20;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  // See `IPool` for descriptions
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @notice Implements the supply feature. Through `supply()`, users supply assets to the Fintoch protocol.
   * @dev Emits the `Supply()` event.
   * @dev In the first supply action, `ReserveUsedAsCollateralEnabled()` is emitted, if the asset can be enabled as
   * collateral.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the supply function
   */
  function executeSupply(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteSupplyParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);

    ValidationLogic.validateSupply(reserveCache, params.amount);

    reserve.updateInterestRates(reserveCache, params.asset, params.amount, 0);

    IERC20(params.asset).safeTransferFrom(msg.sender, reserveCache.aTokenAddress, params.amount);

    bool isFirstSupply = IAToken(reserveCache.aTokenAddress).mint(
      msg.sender,
      params.onBehalfOf,
      params.amount,
      reserveCache.nextLiquidityIndex
    );

    if (isFirstSupply) {
      if (
        ValidationLogic.validateUseAsCollateral(
          reservesData,
          reservesList,
          userConfig,
          reserveCache.reserveConfiguration
        )
      ) {
        userConfig.setUsingAsCollateral(reserve.id, true);
        emit ReserveUsedAsCollateralEnabled(params.asset, params.onBehalfOf);
      }
    }

    emit Supply(params.asset, msg.sender, params.onBehalfOf, params.amount, params.referralCode);
  }

  /**
   * @notice Implements the withdraw feature. Through `withdraw()`, users redeem their aTokens for the underlying asset
   * previously supplied in the Fintoch protocol.
   * @dev Emits the `Withdraw()` event.
   * @dev If the user withdraws everything, `ReserveUsedAsCollateralDisabled()` is emitted.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
   * @param params The additional parameters needed to execute the withdraw function
   * @return The actual amount withdrawn
   */
  function executeWithdraw(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ExecuteWithdrawParams memory params
  ) external returns (uint256) {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    reserve.updateState(reserveCache);

    uint256 userBalance = IAToken(reserveCache.aTokenAddress).scaledBalanceOf(msg.sender).rayMul(
      reserveCache.nextLiquidityIndex
    );

    uint256 amountToWithdraw = params.amount;

    if (params.amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    ValidationLogic.validateWithdraw(reserveCache, amountToWithdraw, userBalance);

    reserve.updateInterestRates(reserveCache, params.asset, 0, amountToWithdraw);

    IAToken(reserveCache.aTokenAddress).burn(
      msg.sender,
      params.to,
      amountToWithdraw,
      reserveCache.nextLiquidityIndex
    );

    if (userConfig.isUsingAsCollateral(reserve.id)) {
      if (userConfig.isBorrowingAny()) {
        ValidationLogic.validateHFAndLtv(
          reservesData,
          reservesList,
          eModeCategories,
          userConfig,
          params.asset,
          msg.sender,
          params.reservesCount,
          params.oracle,
          params.userEModeCategory
        );
      }

      if (amountToWithdraw == userBalance) {
        userConfig.setUsingAsCollateral(reserve.id, false);
        emit ReserveUsedAsCollateralDisabled(params.asset, msg.sender);
      }
    }

    emit Withdraw(params.asset, msg.sender, params.to, amountToWithdraw);

    return amountToWithdraw;
  }

  /**
   * @notice Validates a transfer of aTokens. The sender is subjected to health factor validation to avoid
   * collateralization constraints violation.
   * @dev Emits the `ReserveUsedAsCollateralEnabled()` event for the `to` account, if the asset is being activated as
   * collateral.
   * @dev In case the `from` user transfers everything, `ReserveUsedAsCollateralDisabled()` is emitted for `from`.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
   * @param params The additional parameters needed to execute the finalizeTransfer function
   */
  function executeFinalizeTransfer(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
    DataTypes.FinalizeTransferParams memory params
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[params.asset];

    ValidationLogic.validateTransfer(reserve);

    uint256 reserveId = reserve.id;

    if (params.from != params.to && params.amount != 0) {
      DataTypes.UserConfigurationMap storage fromConfig = usersConfig[params.from];

      if (fromConfig.isUsingAsCollateral(reserveId)) {
        if (fromConfig.isBorrowingAny()) {
          ValidationLogic.validateHFAndLtv(
            reservesData,
            reservesList,
            eModeCategories,
            usersConfig[params.from],
            params.asset,
            params.from,
            params.reservesCount,
            params.oracle,
            params.fromEModeCategory
          );
        }
        if (params.balanceFromBefore == params.amount) {
          fromConfig.setUsingAsCollateral(reserveId, false);
          emit ReserveUsedAsCollateralDisabled(params.asset, params.from);
        }
      }

      if (params.balanceToBefore == 0) {
        DataTypes.UserConfigurationMap storage toConfig = usersConfig[params.to];
        if (
          ValidationLogic.validateUseAsCollateral(
            reservesData,
            reservesList,
            toConfig,
            reserve.configuration
          )
        ) {
          toConfig.setUsingAsCollateral(reserveId, true);
          emit ReserveUsedAsCollateralEnabled(params.asset, params.to);
        }
      }
    }
  }

  /**
   * @notice Executes the 'set as collateral' feature. A user can choose to activate or deactivate an asset as
   * collateral at any point in time. Deactivating an asset as collateral is subjected to the usual health factor
   * checks to ensure collateralization.
   * @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
   * @dev In case the asset is being deactivated as collateral, `ReserveUsedAsCollateralDisabled()` is emitted.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The users configuration mapping that track the supplied/borrowed assets
   * @param asset The address of the asset being configured as collateral
   * @param useAsCollateral True if the user wants to set the asset as collateral, false otherwise
   * @param reservesCount The number of initialized reserves
   * @param priceOracle The address of the price oracle
   * @param userEModeCategory The eMode category chosen by the user
   */
  function executeUseReserveAsCollateral(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap storage userConfig,
    address asset,
    bool useAsCollateral,
    uint256 reservesCount,
    address priceOracle,
    uint8 userEModeCategory
  ) external {
    DataTypes.ReserveData storage reserve = reservesData[asset];
    DataTypes.ReserveCache memory reserveCache = reserve.cache();

    uint256 userBalance = IERC20(reserveCache.aTokenAddress).balanceOf(msg.sender);

    ValidationLogic.validateSetUseReserveAsCollateral(reserveCache, userBalance);

    if (useAsCollateral == userConfig.isUsingAsCollateral(reserve.id)) return;

    if (useAsCollateral) {
      require(
        ValidationLogic.validateUseAsCollateral(reservesData, reservesList, userConfig, reserveCache.reserveConfiguration),
        Errors.USER_IN_ISOLATION_MODE
      );

      userConfig.setUsingAsCollateral(reserve.id, true);
      emit ReserveUsedAsCollateralEnabled(asset, msg.sender);
    } else {
      userConfig.setUsingAsCollateral(reserve.id, false);
      ValidationLogic.validateHFAndLtv(
        reservesData,
        reservesList,
        eModeCategories,
        userConfig,
        asset,
        msg.sender,
        reservesCount,
        priceOracle,
        userEModeCategory
      );

      emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {Address} from '../../../dependencies/openzeppelin/contracts/Address.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IReserveInterestRateStrategy} from '../../../interfaces/IReserveInterestRateStrategy.sol';
import {IStableDebtToken} from '../../../interfaces/IStableDebtToken.sol';
import {IScaledBalanceToken} from '../../../interfaces/IScaledBalanceToken.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {IAToken} from '../../../interfaces/IAToken.sol';
import {IPriceOracleSentinel} from '../../../interfaces/IPriceOracleSentinel.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {GenericLogic} from './GenericLogic.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';

/**
 * @title ReserveLogic library
 *
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeCast for uint256;
  using GPv2SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;
  using Address for address;

  // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
  // A value of 0.9e4 results in 90%
  uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 0.9e4;

  // Minimum health factor allowed under any circumstance
  // A value of 0.95e18 results in 0.95
  uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 0.95e18;

  /**
   * @dev Minimum health factor to consider a user position healthy
   * A value of 1e18 results in 1
   */
  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

  /**
   * @notice Validates a supply action.
   * @param reserveCache The cached data of the reserve
   * @param amount The amount to be supplied
   */
  function validateSupply(DataTypes.ReserveCache memory reserveCache, uint256 amount)
    internal
    view
  {
    require(amount != 0, Errors.INVALID_AMOUNT);

    (bool isActive, bool isFrozen, , , bool isPaused) = reserveCache
      .reserveConfiguration
      .getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);

    uint256 supplyCap = reserveCache.reserveConfiguration.getSupplyCap();
    require(
      supplyCap == 0 ||
        (IAToken(reserveCache.aTokenAddress).scaledTotalSupply().rayMul(
          reserveCache.nextLiquidityIndex
        ) + amount) <=
        supplyCap * (10**reserveCache.reserveConfiguration.getDecimals()),
      Errors.SUPPLY_CAP_EXCEEDED
    );
  }

  /**
   * @notice Validates a withdraw action.
   * @param reserveCache The cached data of the reserve
   * @param amount The amount to be withdrawn
   * @param userBalance The balance of the user
   */
  function validateWithdraw(
    DataTypes.ReserveCache memory reserveCache,
    uint256 amount,
    uint256 userBalance
  ) internal pure {
    require(amount != 0, Errors.INVALID_AMOUNT);
    require(amount <= userBalance, Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE);

    (bool isActive, , , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
  }

  struct ValidateBorrowLocalVars {
    uint256 currentLtv;
    uint256 collateralNeededInBaseCurrency;
    uint256 userCollateralInBaseCurrency;
    uint256 userDebtInBaseCurrency;
    uint256 availableLiquidity;
    uint256 healthFactor;
    uint256 totalDebt;
    uint256 totalSupplyVariableDebt;
    uint256 reserveDecimals;
    uint256 borrowCap;
    uint256 amountInBaseCurrency;
    uint256 assetUnit;
    address eModePriceSource;
    address siloedBorrowingAddress;
    bool isActive;
    bool isFrozen;
    bool isPaused;
    bool borrowingEnabled;
    bool stableRateBorrowingEnabled;
    bool siloedBorrowingEnabled;
  }

  /**
   * @notice Validates a borrow action.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param params Additional params needed for the validation
   */
  function validateBorrow(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.ValidateBorrowParams memory params
  ) internal view {
    require(params.amount != 0, Errors.INVALID_AMOUNT);

    ValidateBorrowLocalVars memory vars;

    (
      vars.isActive,
      vars.isFrozen,
      vars.borrowingEnabled,
      vars.stableRateBorrowingEnabled,
      vars.isPaused
    ) = params.reserveCache.reserveConfiguration.getFlags();

    require(vars.isActive, Errors.RESERVE_INACTIVE);
    require(!vars.isPaused, Errors.RESERVE_PAUSED);
    require(!vars.isFrozen, Errors.RESERVE_FROZEN);
    require(vars.borrowingEnabled, Errors.BORROWING_NOT_ENABLED);

    require(
      params.priceOracleSentinel == address(0) ||
        IPriceOracleSentinel(params.priceOracleSentinel).isBorrowAllowed(),
      Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
    );

    //validate interest rate mode
    require(
      params.interestRateMode == DataTypes.InterestRateMode.VARIABLE ||
        params.interestRateMode == DataTypes.InterestRateMode.STABLE,
      Errors.INVALID_INTEREST_RATE_MODE_SELECTED
    );

    vars.reserveDecimals = params.reserveCache.reserveConfiguration.getDecimals();
    vars.borrowCap = params.reserveCache.reserveConfiguration.getBorrowCap();
    unchecked {
      vars.assetUnit = 10**vars.reserveDecimals;
    }

    if (vars.borrowCap != 0) {
      vars.totalSupplyVariableDebt = params.reserveCache.currScaledVariableDebt.rayMul(
        params.reserveCache.nextVariableBorrowIndex
      );

      vars.totalDebt =
        params.reserveCache.currTotalStableDebt +
        vars.totalSupplyVariableDebt +
        params.amount;

      unchecked {
        require(vars.totalDebt <= vars.borrowCap * vars.assetUnit, Errors.BORROW_CAP_EXCEEDED);
      }
    }

    if (params.isolationModeActive) {
      // check that the asset being borrowed is borrowable in isolation mode AND
      // the total exposure is no bigger than the collateral debt ceiling
      require(
        params.reserveCache.reserveConfiguration.getBorrowableInIsolation(),
        Errors.ASSET_NOT_BORROWABLE_IN_ISOLATION
      );

      require(
        reservesData[params.isolationModeCollateralAddress].isolationModeTotalDebt +
          (params.amount / 10**(vars.reserveDecimals - ReserveConfiguration.DEBT_CEILING_DECIMALS))
            .toUint128() <=
          params.isolationModeDebtCeiling,
        Errors.DEBT_CEILING_EXCEEDED
      );
    }

    if (params.userEModeCategory != 0) {
      require(
        params.reserveCache.reserveConfiguration.getEModeCategory() == params.userEModeCategory,
        Errors.INCONSISTENT_EMODE_CATEGORY
      );
      vars.eModePriceSource = eModeCategories[params.userEModeCategory].priceSource;
    }

    (
      vars.userCollateralInBaseCurrency,
      vars.userDebtInBaseCurrency,
      vars.currentLtv,
      ,
      vars.healthFactor,

    ) = GenericLogic.calculateUserAccountData(
      reservesData,
      reservesList,
      eModeCategories,
      DataTypes.CalculateUserAccountDataParams({
        userConfig: params.userConfig,
        reservesCount: params.reservesCount,
        user: params.userAddress,
        oracle: params.oracle,
        userEModeCategory: params.userEModeCategory
      })
    );

    require(vars.userCollateralInBaseCurrency != 0, Errors.COLLATERAL_BALANCE_IS_ZERO);
    require(vars.currentLtv != 0, Errors.LTV_VALIDATION_FAILED);

    require(
      vars.healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    vars.amountInBaseCurrency =
      IPriceOracleGetter(params.oracle).getAssetPrice(
        vars.eModePriceSource != address(0) ? vars.eModePriceSource : params.asset
      ) *
      params.amount;
    unchecked {
      vars.amountInBaseCurrency /= vars.assetUnit;
    }

    //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    vars.collateralNeededInBaseCurrency = (vars.userDebtInBaseCurrency + vars.amountInBaseCurrency)
      .percentDiv(vars.currentLtv); //LTV is calculated in percentage

    require(
      vars.collateralNeededInBaseCurrency <= vars.userCollateralInBaseCurrency,
      Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW
    );

    /**
     * Following conditions need to be met if the user is borrowing at a stable rate:
     * 1. Reserve must be enabled for stable rate borrowing
     * 2. Users cannot borrow from the reserve if their collateral is (mostly) the same currency
     *    they are borrowing, to prevent abuses.
     * 3. Users will be able to borrow only a portion of the total available liquidity
     **/

    if (params.interestRateMode == DataTypes.InterestRateMode.STABLE) {
      //check if the borrow mode is stable and if stable rate borrowing is enabled on this reserve

      require(vars.stableRateBorrowingEnabled, Errors.STABLE_BORROWING_NOT_ENABLED);

      require(
        !params.userConfig.isUsingAsCollateral(reservesData[params.asset].id) ||
          params.reserveCache.reserveConfiguration.getLtv() == 0 ||
          params.amount > IERC20(params.reserveCache.aTokenAddress).balanceOf(params.userAddress),
        Errors.COLLATERAL_SAME_AS_BORROWING_CURRENCY
      );

      vars.availableLiquidity = IERC20(params.asset).balanceOf(params.reserveCache.aTokenAddress);

      //calculate the max available loan size in stable rate mode as a percentage of the
      //available liquidity
      uint256 maxLoanSizeStable = vars.availableLiquidity.percentMul(params.maxStableLoanPercent);

      require(params.amount <= maxLoanSizeStable, Errors.AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE);
    }

    if (params.userConfig.isBorrowingAny()) {
      (vars.siloedBorrowingEnabled, vars.siloedBorrowingAddress) = params
        .userConfig
        .getSiloedBorrowingState(reservesData, reservesList);

      if (vars.siloedBorrowingEnabled) {
        require(vars.siloedBorrowingAddress == params.asset, Errors.SILOED_BORROWING_VIOLATION);
      } else {
        require(
          !params.reserveCache.reserveConfiguration.getSiloedBorrowing(),
          Errors.SILOED_BORROWING_VIOLATION
        );
      }
    }
  }

  /**
   * @notice Validates a repay action.
   * @param reserveCache The cached data of the reserve
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param interestRateMode The interest rate mode of the debt being repaid
   * @param onBehalfOf The address of the user msg.sender is repaying for
   * @param stableDebt The borrow balance of the user
   * @param variableDebt The borrow balance of the user
   */
  function validateRepay(
    DataTypes.ReserveCache memory reserveCache,
    uint256 amountSent,
    DataTypes.InterestRateMode interestRateMode,
    address onBehalfOf,
    uint256 stableDebt,
    uint256 variableDebt
  ) internal view {
    require(amountSent != 0, Errors.INVALID_AMOUNT);
    require(
      amountSent != type(uint256).max || msg.sender == onBehalfOf,
      Errors.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
    );

    (bool isActive, , , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);

    uint256 variableDebtPreviousIndex = IScaledBalanceToken(reserveCache.variableDebtTokenAddress)
      .getPreviousIndex(onBehalfOf);

    uint40 stableRatePreviousTimestamp = IStableDebtToken(reserveCache.stableDebtTokenAddress)
      .getUserLastUpdated(onBehalfOf);

    require(
      (stableRatePreviousTimestamp < uint40(block.timestamp) &&
        interestRateMode == DataTypes.InterestRateMode.STABLE) ||
        (variableDebtPreviousIndex < reserveCache.nextVariableBorrowIndex &&
          interestRateMode == DataTypes.InterestRateMode.VARIABLE),
      Errors.SAME_BLOCK_BORROW_REPAY
    );

    require(
      (stableDebt != 0 && interestRateMode == DataTypes.InterestRateMode.STABLE) ||
        (variableDebt != 0 && interestRateMode == DataTypes.InterestRateMode.VARIABLE),
      Errors.NO_DEBT_OF_SELECTED_TYPE
    );
  }

  /**
   * @notice Validates a swap of borrow rate mode.
   * @param reserve The reserve state on which the user is swapping the rate
   * @param reserveCache The cached data of the reserve
   * @param userConfig The user reserves configuration
   * @param stableDebt The stable debt of the user
   * @param variableDebt The variable debt of the user
   * @param currentRateMode The rate mode of the debt being swapped
   */
  function validateSwapRateMode(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    DataTypes.UserConfigurationMap storage userConfig,
    uint256 stableDebt,
    uint256 variableDebt,
    DataTypes.InterestRateMode currentRateMode
  ) internal view {
    (bool isActive, bool isFrozen, , bool stableRateEnabled, bool isPaused) = reserveCache
      .reserveConfiguration
      .getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
    require(!isFrozen, Errors.RESERVE_FROZEN);

    if (currentRateMode == DataTypes.InterestRateMode.STABLE) {
      require(stableDebt != 0, Errors.NO_OUTSTANDING_STABLE_DEBT);
    } else if (currentRateMode == DataTypes.InterestRateMode.VARIABLE) {
      require(variableDebt != 0, Errors.NO_OUTSTANDING_VARIABLE_DEBT);
      /**
       * user wants to swap to stable, before swapping we need to ensure that
       * 1. stable borrow rate is enabled on the reserve
       * 2. user is not trying to abuse the reserve by supplying
       * more collateral than he is borrowing, artificially lowering
       * the interest rate, borrowing at variable, and switching to stable
       **/
      require(stableRateEnabled, Errors.STABLE_BORROWING_NOT_ENABLED);

      require(
        !userConfig.isUsingAsCollateral(reserve.id) ||
          reserveCache.reserveConfiguration.getLtv() == 0 ||
          stableDebt + variableDebt > IERC20(reserveCache.aTokenAddress).balanceOf(msg.sender),
        Errors.COLLATERAL_SAME_AS_BORROWING_CURRENCY
      );
    } else {
      revert(Errors.INVALID_INTEREST_RATE_MODE_SELECTED);
    }
  }

  /**
   * @notice Validates a stable borrow rate rebalance action.
   * @dev Rebalancing is accepted when depositors are earning <= 90% of their earnings in pure supply/demand market (variable rate only)
   * For this to be the case, there has to be quite large stable debt with an interest rate below the current variable rate.
   * @param reserve The reserve state on which the user is getting rebalanced
   * @param reserveCache The cached state of the reserve
   * @param reserveAddress The address of the reserve
   */
  function validateRebalanceStableBorrowRate(
    DataTypes.ReserveData storage reserve,
    DataTypes.ReserveCache memory reserveCache,
    address reserveAddress
  ) internal view {
    (bool isActive, , , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);

    uint256 totalDebt = IERC20(reserveCache.stableDebtTokenAddress).totalSupply() +
      IERC20(reserveCache.variableDebtTokenAddress).totalSupply();

    (uint256 liquidityRateVariableDebtOnly, , ) = IReserveInterestRateStrategy(
      reserve.interestRateStrategyAddress
    ).calculateInterestRates(
        DataTypes.CalculateInterestRatesParams({
          unbacked: reserve.unbacked,
          liquidityAdded: 0,
          liquidityTaken: 0,
          totalStableDebt: 0,
          totalVariableDebt: totalDebt,
          averageStableBorrowRate: 0,
          reserveFactor: reserveCache.reserveFactor,
          reserve: reserveAddress,
          aToken: reserveCache.aTokenAddress
        })
      );

    require(
      reserveCache.currLiquidityRate <=
        liquidityRateVariableDebtOnly.percentMul(REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD),
      Errors.INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET
    );
  }

  /**
   * @notice Validates the action of setting an asset as collateral.
   * @param reserveCache The cached data of the reserve
   * @param userBalance The balance of the user
   */
  function validateSetUseReserveAsCollateral(
    DataTypes.ReserveCache memory reserveCache,
    uint256 userBalance
  ) internal pure {
    require(userBalance != 0, Errors.UNDERLYING_BALANCE_ZERO);

    (bool isActive, , , , bool isPaused) = reserveCache.reserveConfiguration.getFlags();
    require(isActive, Errors.RESERVE_INACTIVE);
    require(!isPaused, Errors.RESERVE_PAUSED);
  }

  /**
   * @notice Validates a flashloan action.
   * @param reservesData The state of all the reserves
   * @param assets The assets being flash-borrowed
   * @param amounts The amounts for each asset being borrowed
   */
  function validateFlashloan(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    address[] memory assets,
    uint256[] memory amounts
  ) internal view {
    require(assets.length == amounts.length, Errors.INCONSISTENT_FLASHLOAN_PARAMS);
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory configuration = reservesData[assets[i]]
        .configuration;
      require(!configuration.getPaused(), Errors.RESERVE_PAUSED);
      require(configuration.getActive(), Errors.RESERVE_INACTIVE);
    }
  }

  /**
   * @notice Validates a flashloan action.
   * @param reserve The state of the reserve
   */
  function validateFlashloanSimple(DataTypes.ReserveData storage reserve) internal view {
    DataTypes.ReserveConfigurationMap memory configuration = reserve.configuration;
    require(!configuration.getPaused(), Errors.RESERVE_PAUSED);
    require(configuration.getActive(), Errors.RESERVE_INACTIVE);
  }

  struct ValidateLiquidationCallLocalVars {
    bool collateralReserveActive;
    bool collateralReservePaused;
    bool principalReserveActive;
    bool principalReservePaused;
    bool isCollateralEnabled;
  }

  /**
   * @notice Validates the liquidation action.
   * @param userConfig The user configuration mapping
   * @param collateralReserve The reserve data of the collateral
   * @param params Additional parameters needed for the validation
   */
  function validateLiquidationCall(
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ValidateLiquidationCallParams memory params
  ) internal view {
    ValidateLiquidationCallLocalVars memory vars;

    (vars.collateralReserveActive, , , , vars.collateralReservePaused) = collateralReserve
      .configuration
      .getFlags();

    (vars.principalReserveActive, , , , vars.principalReservePaused) = params
      .debtReserveCache
      .reserveConfiguration
      .getFlags();

    require(vars.collateralReserveActive && vars.principalReserveActive, Errors.RESERVE_INACTIVE);
    require(!vars.collateralReservePaused && !vars.principalReservePaused, Errors.RESERVE_PAUSED);

    require(
      params.priceOracleSentinel == address(0) ||
        params.healthFactor < MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
        IPriceOracleSentinel(params.priceOracleSentinel).isLiquidationAllowed(),
      Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
    );

    require(
      params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD
    );

    vars.isCollateralEnabled =
      collateralReserve.configuration.getLiquidationThreshold() != 0 &&
      userConfig.isUsingAsCollateral(collateralReserve.id);

    //if collateral isn't enabled as collateral by user, it cannot be liquidated
    require(vars.isCollateralEnabled, Errors.COLLATERAL_CANNOT_BE_LIQUIDATED);
    require(params.totalDebt != 0, Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER);
  }

  /**
   * @notice Validates the health factor of a user.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The state of the user for the specific reserve
   * @param user The user to validate health factor of
   * @param userEModeCategory The users active efficiency mode category
   * @param reservesCount The number of available reserves
   * @param oracle The price oracle
   */
  function validateHealthFactor(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    address user,
    uint8 userEModeCategory,
    uint256 reservesCount,
    address oracle
  ) internal view returns (uint256, bool) {
    (, , , , uint256 healthFactor, bool hasZeroLtvCollateral) = GenericLogic
      .calculateUserAccountData(
        reservesData,
        reservesList,
        eModeCategories,
        DataTypes.CalculateUserAccountDataParams({
          userConfig: userConfig,
          reservesCount: reservesCount,
          user: user,
          oracle: oracle,
          userEModeCategory: userEModeCategory
        })
      );

    require(
      healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    return (healthFactor, hasZeroLtvCollateral);
  }

  /**
   * @notice Validates the health factor of a user and the ltv of the asset being withdrawn.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories The configuration of all the efficiency mode categories
   * @param userConfig The state of the user for the specific reserve
   * @param asset The asset for which the ltv will be validated
   * @param from The user from which the aTokens are being transferred
   * @param reservesCount The number of available reserves
   * @param oracle The price oracle
   * @param userEModeCategory The users active efficiency mode category
   */
  function validateHFAndLtv(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    address asset,
    address from,
    uint256 reservesCount,
    address oracle,
    uint8 userEModeCategory
  ) internal view {
    DataTypes.ReserveData memory reserve = reservesData[asset];

    (, bool hasZeroLtvCollateral) = validateHealthFactor(
      reservesData,
      reservesList,
      eModeCategories,
      userConfig,
      from,
      userEModeCategory,
      reservesCount,
      oracle
    );

    require(
      !hasZeroLtvCollateral || reserve.configuration.getLtv() == 0,
      Errors.LTV_VALIDATION_FAILED
    );
  }

  /**
   * @notice Validates a transfer action.
   * @param reserve The reserve object
   */
  function validateTransfer(DataTypes.ReserveData storage reserve) internal view {
    require(!reserve.configuration.getPaused(), Errors.RESERVE_PAUSED);
  }

  /**
   * @notice Validates a drop reserve action.
   * @param reservesList The addresses of all the active reserves
   * @param reserve The reserve object
   * @param asset The address of the reserve's underlying asset
   **/
  function validateDropReserve(
    mapping(uint256 => address) storage reservesList,
    DataTypes.ReserveData storage reserve,
    address asset
  ) internal view {
    require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
    require(reserve.id != 0 || reservesList[0] == asset, Errors.ASSET_NOT_LISTED);
    require(IERC20(reserve.stableDebtTokenAddress).totalSupply() == 0, Errors.STABLE_DEBT_NOT_ZERO);
    require(
      IERC20(reserve.variableDebtTokenAddress).totalSupply() == 0,
      Errors.VARIABLE_DEBT_SUPPLY_NOT_ZERO
    );
    require(IERC20(reserve.aTokenAddress).totalSupply() == 0, Errors.ATOKEN_SUPPLY_NOT_ZERO);
  }

  /**
   * @notice Validates the action of setting efficiency mode.
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param eModeCategories a mapping storing configurations for all efficiency mode categories
   * @param userConfig the user configuration
   * @param reservesCount The total number of valid reserves
   * @param categoryId The id of the category
   **/
  function validateSetUserEMode(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    mapping(uint8 => DataTypes.EModeCategory) storage eModeCategories,
    DataTypes.UserConfigurationMap memory userConfig,
    uint256 reservesCount,
    uint8 categoryId
  ) internal view {
    // category is invalid if the liq threshold is not set
    require(
      categoryId == 0 || eModeCategories[categoryId].liquidationThreshold != 0,
      Errors.INCONSISTENT_EMODE_CATEGORY
    );

    //eMode can always be enabled if the user hasn't supplied anything
    if (userConfig.isEmpty()) {
      return;
    }

    // if user is trying to set another category than default we require that
    // either the user is not borrowing, or it's borrowing assets of categoryId
    if (categoryId != 0) {
      unchecked {
        for (uint256 i = 0; i < reservesCount; i++) {
          if (userConfig.isBorrowing(i)) {
            DataTypes.ReserveConfigurationMap memory configuration = reservesData[reservesList[i]]
              .configuration;
            require(
              configuration.getEModeCategory() == categoryId,
              Errors.INCONSISTENT_EMODE_CATEGORY
            );
          }
        }
      }
    }
  }

  /**
   * @notice Validates if an asset can be activated as collateral in the following actions: supply, transfer,
   * set as collateral, mint unbacked, and liquidate
   * @dev This is used to ensure that the constraints for isolated assets are respected by all the actions that
   * generate transfers of aTokens
   * @param reservesData The state of all the reserves
   * @param reservesList The addresses of all the active reserves
   * @param userConfig the user configuration
   * @param reserveConfig The reserve configuration
   * @return True if the asset can be activated as collateral, false otherwise
   **/
  function validateUseAsCollateral(
    mapping(address => DataTypes.ReserveData) storage reservesData,
    mapping(uint256 => address) storage reservesList,
    DataTypes.UserConfigurationMap storage userConfig,
    DataTypes.ReserveConfigurationMap memory reserveConfig
  ) internal view returns (bool) {
    if (!userConfig.isUsingAsCollateralAny()) {
      return true;
    }
    (bool isolationModeActive, , ) = userConfig.getIsolationModeState(reservesData, reservesList);

    return (!isolationModeActive && reserveConfig.getDebtCeiling() == 0);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {WadRayMath} from './WadRayMath.sol';

/**
 * @title MathUtils library
 *
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library MathUtils {
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   **/
  function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    //solium-disable-next-line
    uint256 result = rate * (block.timestamp - uint256(lastUpdateTimestamp));
    unchecked {
      result = result / SECONDS_PER_YEAR;
    }

    return WadRayMath.RAY + result;
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
   * gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
   * error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

    if (exp == 0) {
      return WadRayMath.RAY;
    }

    uint256 expMinusOne;
    uint256 expMinusTwo;
    uint256 basePowerTwo;
    uint256 basePowerThree;
    unchecked {
      expMinusOne = exp - 1;

      expMinusTwo = exp > 2 ? exp - 2 : 0;

      basePowerTwo = rate.rayMul(rate) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
      basePowerThree = basePowerTwo.rayMul(rate) / SECONDS_PER_YEAR;
    }

    uint256 secondTerm = exp * expMinusOne * basePowerTwo;
    unchecked {
      secondTerm /= 2;
    }
    uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
    unchecked {
      thirdTerm /= 6;
    }

    return WadRayMath.RAY + (rate * exp) / SECONDS_PER_YEAR + secondTerm + thirdTerm;
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   * @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

/**
 * @title PercentageMath library
 *
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library PercentageMath {
  // Maximum percentage factor (100.00%)
  uint256 internal constant PERCENTAGE_FACTOR = 1e4;

  // Half percentage factor (50.00%)
  uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

  /**
   * @notice Executes a percentage multiplication
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return result value percentmul percentage
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
    // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
    assembly {
      if iszero(
        or(
          iszero(percentage),
          iszero(gt(value, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage)))
        )
      ) {
        revert(0, 0)
      }

      result := div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
    }
  }

  /**
   * @notice Executes a percentage division
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return result value percentdiv percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
    // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
    assembly {
      if or(
        iszero(percentage),
        iszero(iszero(gt(value, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))
      ) {
        revert(0, 0)
      }

      result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

/**
 * @title WadRayMath library
 *
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

library ConfiguratorInputTypes {
  struct InitReserveInput {
    address aTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct UpdateATokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveAToken;
        address priceOracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useATokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteSetUserEModeParams {
        uint256 reservesCount;
        address oracle;
        uint8 categoryId;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address addressesProvider;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
        bool isolationModeActive;
        address isolationModeCollateralAddress;
        uint256 isolationModeDebtCeiling;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address aToken;
    }

    struct InitReserveParams {
        address asset;
        address aTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }

    struct FTHTokenParams {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {IReserveInterestRateStrategy} from '../../interfaces/IReserveInterestRateStrategy.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {Errors} from '../libraries/helpers/Errors.sol';

/**
 * @title DefaultReserveInterestRateStrategy contract
 *
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_USAGE_RATIO`
 * point of usage and another from that one to 100%.
 * - An instance of this same contract, can't be used across different Fintoch markets, due to the caching
 *   of the PoolAddressesProvider
 **/
contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  /**
   * @dev This constant represents the usage ratio at which the pool aims to obtain most competitive borrow rates.
   * Expressed in ray
   **/
  uint256 public immutable OPTIMAL_USAGE_RATIO;

  /**
   * @dev This constant represents the optimal stable debt to total debt ratio of the reserve.
   * Expressed in ray
   */
  uint256 public immutable OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO;

  /**
   * @dev This constant represents the excess usage ratio above the optimal. It's always equal to
   * 1-optimal usage ratio. Added as a constant here for gas optimizations.
   * Expressed in ray
   **/
  uint256 public immutable MAX_EXCESS_USAGE_RATIO;

  /**
   * @dev This constant represents the excess stable debt ratio above the optimal. It's always equal to
   * 1-optimal stable to total debt ratio. Added as a constant here for gas optimizations.
   * Expressed in ray
   **/
  uint256 public immutable MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO;

  IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  // Base variable borrow rate when usage rate = 0. Expressed in ray
  uint256 internal immutable _baseVariableBorrowRate;

  // Slope of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal immutable _variableRateSlope1;

  // Slope of the variable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal immutable _variableRateSlope2;

  // Slope of the stable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal immutable _stableRateSlope1;

  // Slope of the stable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
  uint256 internal immutable _stableRateSlope2;

  // Premium on top of `_variableRateSlope1` for base stable borrowing rate
  uint256 internal immutable _baseStableRateOffset;

  // Additional premium applied to stable rate when stable debt surpass `OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO`
  uint256 internal immutable _stableRateExcessOffset;

  /**
   * @dev Constructor.
   * @param provider The address of the PoolAddressesProvider contract
   * @param optimalUsageRatio The optimal usage ratio
   * @param baseVariableBorrowRate The base variable borrow rate
   * @param variableRateSlope1 The variable rate slope below optimal usage ratio
   * @param variableRateSlope2 The variable rate slope above optimal usage ratio
   * @param stableRateSlope1 The stable rate slope below optimal usage ratio
   * @param stableRateSlope2 The stable rate slope above optimal usage ratio
   * @param baseStableRateOffset The premium on top of variable rate for base stable borrowing rate
   * @param stableRateExcessOffset The premium on top of stable rate when there stable debt surpass the threshold
   * @param optimalStableToTotalDebtRatio The optimal stable debt to total debt ratio of the reserve
   */
  constructor(
    IPoolAddressesProvider provider,
    uint256 optimalUsageRatio,
    uint256 baseVariableBorrowRate,
    uint256 variableRateSlope1,
    uint256 variableRateSlope2,
    uint256 stableRateSlope1,
    uint256 stableRateSlope2,
    uint256 baseStableRateOffset,
    uint256 stableRateExcessOffset,
    uint256 optimalStableToTotalDebtRatio
  ) {
    require(WadRayMath.RAY >= optimalUsageRatio, Errors.INVALID_OPTIMAL_USAGE_RATIO);
    require(
      WadRayMath.RAY >= optimalStableToTotalDebtRatio,
      Errors.INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
    );
    OPTIMAL_USAGE_RATIO = optimalUsageRatio;
    MAX_EXCESS_USAGE_RATIO = WadRayMath.RAY - optimalUsageRatio;
    OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = optimalStableToTotalDebtRatio;
    MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO = WadRayMath.RAY - optimalStableToTotalDebtRatio;
    ADDRESSES_PROVIDER = provider;
    _baseVariableBorrowRate = baseVariableBorrowRate;
    _variableRateSlope1 = variableRateSlope1;
    _variableRateSlope2 = variableRateSlope2;
    _stableRateSlope1 = stableRateSlope1;
    _stableRateSlope2 = stableRateSlope2;
    _baseStableRateOffset = baseStableRateOffset;
    _stableRateExcessOffset = stableRateExcessOffset;
  }

  /**
   * @notice Returns the variable rate slope below optimal usage ratio
   * @dev Its the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The variable rate slope
   **/
  function getVariableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  /**
   * @notice Returns the variable rate slope above optimal usage ratio
   * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The variable rate slope
   **/
  function getVariableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }

  /**
   * @notice Returns the stable rate slope below optimal usage ratio
   * @dev Its the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
   * @return The stable rate slope
   **/
  function getStableRateSlope1() external view returns (uint256) {
    return _stableRateSlope1;
  }

  /**
   * @notice Returns the stable rate slope above optimal usage ratio
   * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
   * @return The stable rate slope
   **/
  function getStableRateSlope2() external view returns (uint256) {
    return _stableRateSlope2;
  }

  /**
   * @notice Returns the stable rate excess offset
   * @dev An additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
   * @return The stable rate excess offset
   */
  function getStableRateExcessOffset() external view returns (uint256) {
    return _stableRateExcessOffset;
  }

  /**
   * @notice Returns the base stable borrow rate
   * @return The base stable borrow rate
   **/
  function getBaseStableBorrowRate() public view returns (uint256) {
    return _variableRateSlope1 + _baseStableRateOffset;
  }

  /// @inheritdoc IReserveInterestRateStrategy
  function getBaseVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  /// @inheritdoc IReserveInterestRateStrategy
  function getMaxVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
  }

  struct CalcInterestRatesLocalVars {
    uint256 availableLiquidity;
    uint256 totalDebt;
    uint256 currentVariableBorrowRate;
    uint256 currentStableBorrowRate;
    uint256 currentLiquidityRate;
    uint256 borrowUsageRatio;
    uint256 supplyUsageRatio;
    uint256 stableToTotalDebtRatio;
    uint256 availableLiquidityPlusDebt;
  }

  /// @inheritdoc IReserveInterestRateStrategy
  function calculateInterestRates(DataTypes.CalculateInterestRatesParams calldata params)
    external
    view
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    CalcInterestRatesLocalVars memory vars;

    vars.totalDebt = params.totalStableDebt + params.totalVariableDebt;

    vars.currentLiquidityRate = 0;
    vars.currentVariableBorrowRate = _baseVariableBorrowRate;
    vars.currentStableBorrowRate = getBaseStableBorrowRate();

    if (vars.totalDebt != 0) {
      vars.stableToTotalDebtRatio = params.totalStableDebt.rayDiv(vars.totalDebt);
      vars.availableLiquidity =
        IERC20(params.reserve).balanceOf(params.aToken) +
        params.liquidityAdded -
        params.liquidityTaken;

      vars.availableLiquidityPlusDebt = vars.availableLiquidity + vars.totalDebt;
      vars.borrowUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
      vars.supplyUsageRatio = vars.totalDebt.rayDiv(
        vars.availableLiquidityPlusDebt + params.unbacked
      );
    }

    if (vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO) {
      uint256 excessBorrowUsageRatio = (vars.borrowUsageRatio - OPTIMAL_USAGE_RATIO).rayDiv(
        MAX_EXCESS_USAGE_RATIO
      );

      vars.currentStableBorrowRate +=
        _stableRateSlope1 +
        _stableRateSlope2.rayMul(excessBorrowUsageRatio);

      vars.currentVariableBorrowRate +=
        _variableRateSlope1 +
        _variableRateSlope2.rayMul(excessBorrowUsageRatio);
    } else {
      vars.currentStableBorrowRate += _stableRateSlope1.rayMul(vars.borrowUsageRatio).rayDiv(
        OPTIMAL_USAGE_RATIO
      );

      vars.currentVariableBorrowRate += _variableRateSlope1.rayMul(vars.borrowUsageRatio).rayDiv(
        OPTIMAL_USAGE_RATIO
      );
    }

    if (vars.stableToTotalDebtRatio > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO) {
      uint256 excessStableDebtRatio = (vars.stableToTotalDebtRatio -
        OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO).rayDiv(MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO);
      vars.currentStableBorrowRate += _stableRateExcessOffset.rayMul(excessStableDebtRatio);
    }

    vars.currentLiquidityRate = _getOverallBorrowRate(
      params.totalStableDebt,
      params.totalVariableDebt,
      vars.currentVariableBorrowRate,
      params.averageStableBorrowRate
    ).rayMul(vars.supplyUsageRatio).percentMul(
        PercentageMath.PERCENTAGE_FACTOR - params.reserveFactor
      );

    return (
      vars.currentLiquidityRate,
      vars.currentStableBorrowRate,
      vars.currentVariableBorrowRate
    );
  }

  /**
   * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable
   * debt
   * @param totalStableDebt The total borrowed from the reserve at a stable rate
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param currentVariableBorrowRate The current variable borrow rate of the reserve
   * @param currentAverageStableBorrowRate The current weighted average of all the stable rate loans
   * @return The weighted averaged borrow rate
   **/
  function _getOverallBorrowRate(
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 currentVariableBorrowRate,
    uint256 currentAverageStableBorrowRate
  ) internal pure returns (uint256) {
    uint256 totalDebt = totalStableDebt + totalVariableDebt;

    if (totalDebt == 0) return 0;

    uint256 weightedVariableRate = totalVariableDebt.wadToRay().rayMul(currentVariableBorrowRate);

    uint256 weightedStableRate = totalStableDebt.wadToRay().rayMul(currentAverageStableBorrowRate);

    uint256 overallBorrowRate = (weightedVariableRate + weightedStableRate).rayDiv(
      totalDebt.wadToRay()
    );

    return overallBorrowRate;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';

contract FTHToken is IERC20 {
    using SafeMath for uint256;

    string public constant name = 'Fintoch DC';
    string public constant symbol = 'FTH-DC';
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// This is the ETH/ERC20 borrow contract for Fintoch.
//
// For 2-of-3 multisig, to authorize a spend, two signtures must be provided by 2 of the 3 owners.
// To generate the message to be signed, provide the destination address and
// spend amount (in wei) to the generateMessageToSign method.
// The signatures must be provided as the (v, r, s) hex-encoded coordinates.
// The S coordinate must be 0x00 or 0x01 corresponding to 0x1b and 0x1c, respectively.
//
// WARNING: The generated message is only valid until the next spend is executed.
//          after that, a new message will need to be calculated.
//
//
// INFO: This contract is ERC20 compatible.
// This contract can both receive ETH and ERC20 tokens.
// Notice that NFT (ERC721/ERC1155) is not supported. But can be transferred out throught spendAny.

import {IPool} from '../../interfaces/IPool.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';

contract Fintoch {

    struct BorrowInfo {
        string orderId;
        uint256 borrowAmount;
        address tokenAddress; // this address will be 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE when borrow ETH
    }

    BorrowInfo public borrowInfo;

    uint constant public MAX_OWNER_COUNT = 9;

    // The N addresses which control the funds in this contract. The
    // owners of M of these addresses will need to both sign a message
    // allowing the funds in this contract to be spent.
    mapping(address => bool) private isOwner;
    address[] private owners;
    uint private immutable required;

    // The contract nonce is not accessible to the contract so we
    // implement a nonce-like variable for replay protection.
    uint256 private spendNonce = 0;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address private constant ETH_CONTRACT = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // An event sent when funds are received.
    event Funded(address from, uint value);

    // An event sent when a spend is triggered to the given address.
    event Spent(address to, uint transfer);

    // An event sent when a spendERC20 is triggered to the given address.
    event SpentERC20(address erc20contract, address to, uint transfer);

    // An event sent when a liquidatedAssets is triggered to the given address.
    event Liquidated(string orderId, address erc20contract, address fintochPool, uint recoveryAmount, uint reserveAmount);

    // An event sent when an toSwap is executed.
    event Swapped(address routerAddress, uint transfer);

    // An event sent when a crossChain is triggered to the given address.
    event Crossed(address erc20contract, address to, uint transfer);

    // An event sent when an spendAny is executed.
    event SpentAny(address to, uint transfer);

    // An event sent when an setBorrowInfo is executed.
    event BorrowInfoUpdated(BorrowInfo newInfo);

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
        && _required <= ownerCount
            && _required >= 1);
        _;
    }

    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required, BorrowInfo memory _borrowInfo) validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            //onwer should be distinct, and non-zero
            if (isOwner[_owners[i]] || _owners[i] == address(0x0)) {
                revert();
            }
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        borrowInfo = _borrowInfo;
    }

    // The receive function for this contract.
    receive() external payable {
        if (msg.value > 0) {
            emit Funded(msg.sender, msg.value);
        }
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getSpendNonce() external view returns (uint256) {
        return spendNonce;
    }

    function getRequired() external view returns (uint) {
        return required;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Fintoch: TRANSFER_FAILED');
    }

    // Generates the message to sign given the output destination address and amount.
    // includes this contract's address and a nonce for replay protection.
    // One option to independently verify: https://leventozturk.com/engineering/sha3/ and select keccak
    function generateMessageToSign(bytes4 selector, address erc20Contract, address destination, uint256 value) private view returns (bytes32) {
        require(destination != address(this));
        //the sequence should match generateMultiSigV2 in JS
        bytes32 message = keccak256(abi.encodePacked(address(this), selector, erc20Contract, destination, value, spendNonce));
        return message;
    }

    function _messageToRecover(bytes4 selector, address erc20Contract, address destination, uint256 value) private view returns (bytes32) {
        bytes32 hashedUnsignedMessage = generateMessageToSign(selector, erc20Contract, destination, value);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, hashedUnsignedMessage));
    }

    // Generates the message to sign given the output destination address and amount.
    // includes this contract's address and a nonce for replay protection.
    // One option to independently verify: https://leventozturk.com/engineering/sha3/ and select keccak
    function generateMessageToSignAny(bytes4 selector, address destination, uint256 value, bytes calldata data) private view returns (bytes32) {
        require(destination != address(this));
        //the sequence should match generateMultiSigV2 in JS
        bytes32 message = keccak256(abi.encodePacked(address(this), selector, destination, data, value, spendNonce));
        return message;
    }

    function _messageToRecoverAny(bytes4 selector, address destination, uint256 value, bytes calldata data) private view returns (bytes32) {
        bytes32 hashedUnsignedMessage = generateMessageToSignAny(selector, destination, value, data);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, hashedUnsignedMessage));
    }

    //0x20 is used for setBorrowInfo
    function setBorrowInfo(bytes calldata borrowInfoBytes, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        (string memory orderId, uint256 borrowAmount, address tokenAddress) = abi.decode(borrowInfoBytes, (string, uint256, address));
        require(_validSignature(this.setBorrowInfo.selector, address(0x20), tokenAddress, borrowAmount, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        borrowInfo = BorrowInfo({
            orderId: orderId,
            borrowAmount: borrowAmount,
            tokenAddress: tokenAddress
        });
        emit BorrowInfoUpdated(borrowInfo);
    }

    /**
     * @param destination: the ether receiver address.
   * @param value: the ether value, in wei.
   * @param vs, rs, ss: the signatures
   */
    function spend(address destination, uint256 value, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        require(destination != address(this), "Not allow sending to yourself");
        require(address(this).balance >= value && value > 0, "balance or spend value invalid");
        require(_validSignature(this.spend.selector, address(0x0), destination, value, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        //transfer will throw if fails
        (bool success,) = destination.call{value : value}("");
        require(success, "transfer fail");
        emit Spent(destination, value);
    }

    /**
     * @param erc20contract: the erc20 contract address.
   * @param destination: the token receiver address.
   * @param value: the token value, in token minimum unit.
   * @param vs, rs, ss: the signatures
   */
    function spendERC20(address destination, address erc20contract, uint256 value, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        require(destination != address(this), "Not allow sending to yourself");
        //transfer erc20 token
        require(value > 0, "Erc20 spend value invalid");
        require(_validSignature(this.spendERC20.selector, erc20contract, destination, value, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        // transfer tokens from this contract to the destination address
        _safeTransfer(erc20contract, destination, value);
        emit SpentERC20(erc20contract, destination, value);
    }

    // @fintochPool: the fintoch pool address.
    // @assetAmount: the number of tokens that need to be converted into lp, remaining tokens will be sent directly to the fintoch pool
    // @vs, rs, ss: the signatures
    function liquidatedAssets(address fintochPool, uint256 assetAmount, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        require(fintochPool != address(0), "Cannot be zero address");
        require(_validSignature(this.liquidatedAssets.selector, borrowInfo.tokenAddress, fintochPool, assetAmount, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        // transfer tokens from this contract to the fintochPool address
        uint256 actualBalance;
        uint256 mintValue;
        if (borrowInfo.tokenAddress == ETH_CONTRACT) {
            actualBalance = address(this).balance;
            mintValue = assetAmount;
        } else {
            actualBalance = IERC20(borrowInfo.tokenAddress).balanceOf(address(this));
        }
        require(actualBalance >= assetAmount, "actualBalance < assetAmount");
        uint256 reserveAmount = actualBalance - assetAmount;
        IPool(fintochPool).mint{value: mintValue}(address(this), assetAmount);
        if (reserveAmount > 0) {
            // If there are remaining tokens after switching to lp, transfer directly
            if (borrowInfo.tokenAddress == ETH_CONTRACT) {
                (bool success,) = fintochPool.call{value : reserveAmount}("");
                require(success, "transfer reserve ETH fail");
            } else {
                _safeTransfer(borrowInfo.tokenAddress, fintochPool, reserveAmount);
            }
        }
        emit Liquidated(borrowInfo.orderId, borrowInfo.tokenAddress, fintochPool, assetAmount, reserveAmount);
    }

    // @routerAddress: the routing contract address of the decentralized exchange.
    // @value: the ether value, in wei.
    // @vs, rs, ss: the signatures
    // @data: contract invocation input data
    function toSwap(address routerAddress, uint256 value, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss, bytes calldata data) external {
        require(_validSignatureAny(this.toSwap.selector, routerAddress, value, data, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        //transfer tokens from this contract to the routerAddress
        (bool success,) = routerAddress.call{value : value}(data);
        require(success, "swap fail");
        emit Swapped(routerAddress, value);
    }

    // @erc20contract: the erc20 contract address.
    // @destination: the token receiver address, usually the payment address of the third-party cross-chain platform
    // @value: the token value, in token minimum unit.
    // @vs, rs, ss: the signatures
    function crossChain(address destination, address erc20contract, uint256 value, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        require(destination != address(this), "Not allow sending to yourself");
        require(value > 0, "Erc20 spend value invalid");
        require(_validSignature(this.crossChain.selector, erc20contract, destination, value, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        // transfer tokens from this contract to the destination address
        _safeTransfer(erc20contract, destination, value);
        emit Crossed(erc20contract, destination, value);
    }

    //This is usually for some emergent recovery, for example, recovery of NTFs, etc.
    function spendAny(address destination, uint256 value, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss, bytes calldata data) external {
        require(destination != address(this), "Not allow sending to yourself");
        require(_validSignatureAny(this.spendAny.selector, destination, value, data, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        //transfer tokens from this contract to the destination address
        (bool success,) = destination.call{value : value}(data);
        require(success, "call fail");
        emit SpentAny(destination, value);
    }

    // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
    // authorize a spend of this contract's funds to the given destination address.
    function _validSignature(bytes4 selector, address erc20Contract, address destination, uint256 value, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) private view returns (bool) {
        require(vs.length == rs.length);
        require(rs.length == ss.length);
        require(vs.length <= owners.length);
        require(vs.length >= required);
        bytes32 message = _messageToRecover(selector, erc20Contract, destination, value);
        address[] memory addrs = new address[](vs.length);
        for (uint i = 0; i < vs.length; i++) {
            //recover the address associated with the public key from elliptic curve signature or return zero on error
            addrs[i] = ecrecover(message, vs[i] + 27, rs[i], ss[i]);
        }
        require(_distinctOwners(addrs));
        return true;
    }

    // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
    // authorize a spend of this contract's funds to the given destination address.
    function _validSignatureAny(bytes4 selector, address destination, uint256 value, bytes calldata data, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) private view returns (bool) {
        require(vs.length == rs.length);
        require(rs.length == ss.length);
        require(vs.length <= owners.length);
        require(vs.length >= required);
        bytes32 message = _messageToRecoverAny(selector, destination, value, data);
        address[] memory addrs = new address[](vs.length);
        for (uint i = 0; i < vs.length; i++) {
            //recover the address associated with the public key from elliptic curve signature or return zero on error
            addrs[i] = ecrecover(message, vs[i] + 27, rs[i], ss[i]);
        }
        require(_distinctOwners(addrs));
        return true;
    }

    // Confirm the addresses as distinct owners of this contract.
    function _distinctOwners(address[] memory addrs) private view returns (bool) {
        if (addrs.length > owners.length) {
            return false;
        }
        for (uint i = 0; i < addrs.length; i++) {
            if (!isOwner[addrs[i]]) {
                return false;
            }
            //address should be distinct
            for (uint j = 0; j < i; j++) {
                if (addrs[i] == addrs[j]) {
                    return false;
                }
            }
        }
        return true;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IInvestmentEarnings} from '../../interfaces/IInvestmentEarnings.sol';
import {IPool} from '../../interfaces/IPool.sol';
import {FTHToken} from './FTHToken.sol';

/**
 * @title FintochPool contract
 *
 * @notice Main point of interaction with an Fintoch protocol's market
 * - Users can:
 *   # Supply
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Swap their loans between variable and stable rate
 *   # Enable/disable their supplied assets as collateral rebalance stable rate borrow positions
 *   # Liquidate positions
 *   # Execute Flash Loans
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 **/
contract FintochPool is FTHToken, IPool {

    uint256 public constant POOL_REVISION = 0x2;
    IInvestmentEarnings public immutable INVESTMENT_EARNINGS_CONTRACT;
    address public immutable SRC_TOKEN; // 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE stands for ETH

    uint constant public MAX_OWNER_COUNT = 9;

    // The N addresses which control the funds in this contract. The
    // owners of M of these addresses will need to both sign a message
    // allowing the funds in this contract to be spent.
    mapping(address => bool) private isOwner;
    address[] private owners;
    uint private immutable required;

    // The contract nonce is not accessible to the contract so we
    // implement a nonce-like variable for replay protection.
    uint256 private spendNonce = 0;
    uint public allowInternalCall = 1;

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant TRANSFER_FROM_SELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    address private constant ETH_CONTRACT = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // An event sent when funds are received.
    event Funded(address from, uint value);

    // An event sent when a setAllowInternalCall is triggered.
    event AllowInternalCallUpdated(uint value);

    // An event sent when a spend is triggered to the given address.
    event Spent(address to, uint transfer);

    // An event sent when a spendERC20 is triggered to the given address.
    event SpentERC20(address erc20contract, address to, uint transfer);

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
        && _required <= ownerCount
            && _required >= 1);
        _;
    }

    /**
     * @dev Constructor.
   * @param _owners List of initial owners.
   * @param _required Number of required confirmations.
   */
    constructor(
        IInvestmentEarnings investmentEarnings,
        address srcToken,
        address[] memory _owners,
        uint _required
    ) validRequirement(_owners.length, _required) {
        INVESTMENT_EARNINGS_CONTRACT = investmentEarnings;
        SRC_TOKEN = srcToken;
        for (uint i = 0; i < _owners.length; i++) {
            //onwer should be distinct, and non-zero
            if (isOwner[_owners[i]] || _owners[i] == address(0x0)) {
                revert();
            }
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /**
     * @dev Leaves the contract without owners. It will not be possible to call
   * with signature check anymore. Can only be called by the current owners.
   *
   * NOTE: Renouncing ownership will leave the contract without owners,
   * thereby removing any functionality that is only available to the owner.
   */
    function renounceOwnership(uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        bytes32 renounceOwnershipTypeHash = keccak256("RenounceOwnership(uint256 spendNonce)");
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(renounceOwnershipTypeHash, spendNonce))
            )
        );
        require(_validMsgSignature(digest, vs, rs, ss), "invalid signatures");
        for (uint i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = false;
        }
        delete owners;
    }

    // The receive function for this contract.
    receive() external payable {
        if (msg.value > 0) {
            emit Funded(msg.sender, msg.value);
        }
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getSpendNonce() external view returns (uint256) {
        return spendNonce;
    }

    function getRequired() external view returns (uint) {
        return required;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FintochPool: TRANSFER_FAILED');
    }

    function _safeTransferFrom(address token, address from, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_FROM_SELECTOR, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'FintochPool: TRANSFER_FROM_FAILED');
    }

    // Generates the message to sign given the output destination address and amount.
    // includes this contract's address and a nonce for replay protection.
    // One option to independently verify: https://leventozturk.com/engineering/sha3/ and select keccak
    function generateMessageToSign(address erc20Contract, address destination, uint256 value) private view returns (bytes32) {
        require(destination != address(this));
        //the sequence should match generateMultiSigV2 in JS
        bytes32 message = keccak256(abi.encodePacked(address(this), erc20Contract, destination, value, spendNonce));
        return message;
    }

    function _messageToRecover(address erc20Contract, address destination, uint256 value) private view returns (bytes32) {
        bytes32 hashedUnsignedMessage = generateMessageToSign(erc20Contract, destination, value);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, hashedUnsignedMessage));
    }

    /**
   * @param _allowInternalCall: the new allowInternalCall value.
   * @param vs, rs, ss: the signatures
   */
    function setAllowInternalCall(uint _allowInternalCall, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        require(_validSignature(address(this), msg.sender, _allowInternalCall, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        allowInternalCall = _allowInternalCall;
        emit AllowInternalCallUpdated(allowInternalCall);
    }

    /**
     * @param destination: the ether receiver address.
   * @param value: the ether value, in wei.
   * @param vs, rs, ss: the signatures
   */
    function spend(address destination, uint256 value, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        require(destination != address(this), "Not allow sending to yourself");
        require(address(this).balance >= value && value > 0, "balance or spend value invalid");
        require(_validSignature(address(0x0), destination, value, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        (bool success,) = destination.call{value : value}("");
        require(success, "transfer fail");
        emit Spent(destination, value);
    }

    /**
     * @param erc20contract: the erc20 contract address.
   * @param destination: the token receiver address.
   * @param value: the token value, in token minimum unit.
   * @param vs, rs, ss: the signatures
   */
    function spendERC20(address destination, address erc20contract, uint256 value, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        require(destination != address(this), "Not allow sending to yourself");
        //transfer erc20 token
        require(value > 0, "Erc20 spend value invalid");
        require(_validSignature(erc20contract, destination, value, vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;
        // transfer tokens from this contract to the destination address
        _safeTransfer(erc20contract, destination, value);
        emit SpentERC20(erc20contract, destination, value);
    }

    /**
   * @param destination: the token receiver address.
   * @param value: the token value, in token minimum unit.
   */
    function redemption(address destination, uint256 value) external {
        require(destination != address(this), "Not allow sending to yourself");
        //transfer erc20 token
        require(value > 0, "withdraw value invalid");
        _burn(msg.sender, value);
        if (SRC_TOKEN == ETH_CONTRACT) {
            // transfer ETH
            (bool success,) = destination.call{value : value}("");
            require(success, "transfer fail");
        } else {
            // transfer erc20 token
            _safeTransfer(SRC_TOKEN, destination, value);
        }
        emit Redeemed(msg.sender, destination, SRC_TOKEN, value);
    }

    function mint(address destination, uint256 value) external payable {
        require(destination != address(0), 'ERC20: mint to the zero address');
        uint256 mintAmount = msg.value;
        if (SRC_TOKEN != ETH_CONTRACT) {
            // transfer erc20 token
            mintAmount = value;
            _safeTransferFrom(SRC_TOKEN, msg.sender, address(this), mintAmount);
        }
        _mint(destination, mintAmount);
        emit Mint(msg.sender, destination, mintAmount);
    }

    function cancelReinvest(string calldata orderId) external {
        uint256 size;
        address callerAddress = msg.sender;
        assembly {
            size := extcodesize(callerAddress)
        }
        require(size == 0 || allowInternalCall == 1, "forbidden");
        INVESTMENT_EARNINGS_CONTRACT.noteCancelReinvest(orderId);
    }

    function withdrawalIncome(uint64[] calldata recordIds) external {
        uint256 size;
        address callerAddress = msg.sender;
        assembly {
            size := extcodesize(callerAddress)
        }
        require(size == 0 || allowInternalCall == 1, "forbidden");
        for (uint i = 0; i < recordIds.length; i++) {
            require(recordIds[i] > 0, "invalid record id");
            for (uint j = 0; j < i; j++) {
                if (recordIds[i] == recordIds[j]) {
                    revert("duplicate record id");
                }
            }
        }
        INVESTMENT_EARNINGS_CONTRACT.noteWithdrawal(recordIds);
    }

    // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
    // authorize a spend of this contract's funds to the given destination address.
    function _validMsgSignature(
        bytes32 message,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) private view returns (bool) {
        require(vs.length == rs.length);
        require(rs.length == ss.length);
        require(vs.length <= owners.length);
        require(vs.length >= required);
        address[] memory addrs = new address[](vs.length);
        for (uint i = 0; i < vs.length; i++) {
            //recover the address associated with the public key from elliptic curve signature or return zero on error
            addrs[i] = ecrecover(message, vs[i] + 27, rs[i], ss[i]);
        }
        require(_distinctOwners(addrs));
        return true;
    }

    // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
    // authorize a spend of this contract's funds to the given destination address.
    function _validSignature(
        address erc20Contract,
        address destination,
        uint256 value,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) private view returns (bool) {
        bytes32 message = _messageToRecover(erc20Contract, destination, value);
        return _validMsgSignature(message, vs, rs, ss);
    }

    // Confirm the addresses as distinct owners of this contract.
    function _distinctOwners(address[] memory addrs) private view returns (bool) {
        if (addrs.length > owners.length) {
            return false;
        }
        for (uint i = 0; i < addrs.length; i++) {
            if (!isOwner[addrs[i]]) {
                return false;
            }
            //address should be distinct
            for (uint j = 0; j < i; j++) {
                if (addrs[i] == addrs[j]) {
                    return false;
                }
            }
        }
        return true;
    }

}

pragma solidity ^0.8.10;

import {FintochPool} from './FintochPool.sol';
import {IInvestmentEarnings} from '../../interfaces/IInvestmentEarnings.sol';
import {IL2Pool} from '../../interfaces/IL2Pool.sol';
import {CalldataLogic} from '../libraries/logic/CalldataLogic.sol';

/**
 * @title L2Pool
 *
 * @notice Calldata optimized extension of the Pool contract allowing users to pass compact calldata representation
 * to reduce transaction costs on rollups.
 */
abstract contract L2Pool is FintochPool, IL2Pool {
  /**
   * @dev Constructor.
   */
  constructor(
    IInvestmentEarnings investmentEarnings,
    address srcToken,
    address[] memory _owners,
    uint _required
  ) FintochPool(investmentEarnings, srcToken, _owners, _required) {
    // Intentionally left blank
  }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {VersionedInitializable} from '../libraries/fintoch-upgradeability/VersionedInitializable.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {ConfiguratorLogic} from '../libraries/logic/ConfiguratorLogic.sol';
import {ConfiguratorInputTypes} from '../libraries/types/ConfiguratorInputTypes.sol';
import {IPoolConfigurator} from '../../interfaces/IPoolConfigurator.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';
import {IACLManager} from '../../interfaces/IACLManager.sol';
import {IPoolDataProvider} from '../../interfaces/IPoolDataProvider.sol';

/**
 * @title PoolConfigurator
 *
 * @dev Implements the configuration methods for the Fintoch protocol
 **/
contract PoolConfigurator is VersionedInitializable, IPoolConfigurator {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  IPoolAddressesProvider internal _addressesProvider;
  IL1Pool internal _pool;

  /**
   * @dev Only pool admin can call functions marked by this modifier.
   **/
  modifier onlyPoolAdmin() {
    _onlyPoolAdmin();
    _;
  }

  /**
   * @dev Only emergency admin can call functions marked by this modifier.
   **/
  modifier onlyEmergencyAdmin() {
    _onlyEmergencyAdmin();
    _;
  }

  /**
   * @dev Only emergency or pool admin can call functions marked by this modifier.
   **/
  modifier onlyEmergencyOrPoolAdmin() {
    _onlyPoolOrEmergencyAdmin();
    _;
  }

  /**
   * @dev Only asset listing or pool admin can call functions marked by this modifier.
   **/
  modifier onlyAssetListingOrPoolAdmins() {
    _onlyAssetListingOrPoolAdmins();
    _;
  }

  /**
   * @dev Only risk or pool admin can call functions marked by this modifier.
   **/
  modifier onlyRiskOrPoolAdmins() {
    _onlyRiskOrPoolAdmins();
    _;
  }

  uint256 public constant CONFIGURATOR_REVISION = 0x1;

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure virtual override returns (uint256) {
    return CONFIGURATOR_REVISION;
  }

  function initialize(IPoolAddressesProvider provider) public initializer {
    _addressesProvider = provider;
    _pool = IL1Pool(_addressesProvider.getPool());
  }

  /// @inheritdoc IPoolConfigurator
  function initReserves(ConfiguratorInputTypes.InitReserveInput[] calldata input)
    external
    override
    onlyAssetListingOrPoolAdmins
  {
    IL1Pool cachedPool = _pool;
    for (uint256 i = 0; i < input.length; i++) {
      ConfiguratorLogic.executeInitReserve(cachedPool, input[i]);
    }
  }

  /// @inheritdoc IPoolConfigurator
  function dropReserve(address asset) external override onlyPoolAdmin {
    _pool.dropReserve(asset);
    emit ReserveDropped(asset);
  }

  /// @inheritdoc IPoolConfigurator
  function updateAToken(ConfiguratorInputTypes.UpdateATokenInput calldata input)
    external
    override
    onlyPoolAdmin
  {
    ConfiguratorLogic.executeUpdateAToken(_pool, input);
  }

  /// @inheritdoc IPoolConfigurator
  function updateStableDebtToken(ConfiguratorInputTypes.UpdateDebtTokenInput calldata input)
    external
    override
    onlyPoolAdmin
  {
    ConfiguratorLogic.executeUpdateStableDebtToken(_pool, input);
  }

  /// @inheritdoc IPoolConfigurator
  function updateVariableDebtToken(ConfiguratorInputTypes.UpdateDebtTokenInput calldata input)
    external
    override
    onlyPoolAdmin
  {
    ConfiguratorLogic.executeUpdateVariableDebtToken(_pool, input);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveBorrowing(address asset, bool enabled) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    if (!enabled) {
      require(!currentConfig.getStableRateBorrowingEnabled(), Errors.STABLE_BORROWING_ENABLED);
    }
    currentConfig.setBorrowingEnabled(enabled);
    _pool.setConfiguration(asset, currentConfig);
    emit ReserveBorrowing(asset, enabled);
  }

  /// @inheritdoc IPoolConfigurator
  function configureReserveAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external override onlyRiskOrPoolAdmins {
    //validation of the parameters: the LTV can
    //only be lower or equal than the liquidation threshold
    //(otherwise a loan against the asset would cause instantaneous liquidation)
    require(ltv <= liquidationThreshold, Errors.INVALID_RESERVE_PARAMS);

    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);

    if (liquidationThreshold != 0) {
      //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
      //collateral than needed to cover the debt
      require(liquidationBonus > PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_RESERVE_PARAMS);

      //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
      //a loan is taken there is enough collateral available to cover the liquidation bonus
      require(
        liquidationThreshold.percentMul(liquidationBonus) <= PercentageMath.PERCENTAGE_FACTOR,
        Errors.INVALID_RESERVE_PARAMS
      );
    } else {
      require(liquidationBonus == 0, Errors.INVALID_RESERVE_PARAMS);
      //if the liquidation threshold is being set to 0,
      // the reserve is being disabled as collateral. To do so,
      //we need to ensure no liquidity is supplied
      _checkNoSuppliers(asset);
    }

    currentConfig.setLtv(ltv);
    currentConfig.setLiquidationThreshold(liquidationThreshold);
    currentConfig.setLiquidationBonus(liquidationBonus);

    _pool.setConfiguration(asset, currentConfig);

    emit CollateralConfigurationChanged(asset, ltv, liquidationThreshold, liquidationBonus);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveStableRateBorrowing(address asset, bool enabled)
    external
    override
    onlyRiskOrPoolAdmins
  {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    if (enabled) {
      require(currentConfig.getBorrowingEnabled(), Errors.BORROWING_NOT_ENABLED);
    }
    currentConfig.setStableRateBorrowingEnabled(enabled);
    _pool.setConfiguration(asset, currentConfig);
    emit ReserveStableRateBorrowing(asset, enabled);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveActive(address asset, bool active) external override onlyPoolAdmin {
    if (!active) _checkNoSuppliers(asset);
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    currentConfig.setActive(active);
    _pool.setConfiguration(asset, currentConfig);
    emit ReserveActive(asset, active);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveFreeze(address asset, bool freeze) external override onlyRiskOrPoolAdmins {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    currentConfig.setFrozen(freeze);
    _pool.setConfiguration(asset, currentConfig);
    emit ReserveFrozen(asset, freeze);
  }

  /// @inheritdoc IPoolConfigurator
  function setBorrowableInIsolation(address asset, bool borrowable)
    external
    override
    onlyRiskOrPoolAdmins
  {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    currentConfig.setBorrowableInIsolation(borrowable);
    _pool.setConfiguration(asset, currentConfig);
    emit BorrowableInIsolationChanged(asset, borrowable);
  }

  /// @inheritdoc IPoolConfigurator
  function setReservePause(address asset, bool paused) public override onlyEmergencyOrPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    currentConfig.setPaused(paused);
    _pool.setConfiguration(asset, currentConfig);
    emit ReservePaused(asset, paused);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveFactor(address asset, uint256 newReserveFactor)
    external
    override
    onlyRiskOrPoolAdmins
  {
    require(newReserveFactor <= PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_RESERVE_FACTOR);
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldReserveFactor = currentConfig.getReserveFactor();
    currentConfig.setReserveFactor(newReserveFactor);
    _pool.setConfiguration(asset, currentConfig);
    emit ReserveFactorChanged(asset, oldReserveFactor, newReserveFactor);
  }

  /// @inheritdoc IPoolConfigurator
  function setDebtCeiling(address asset, uint256 newDebtCeiling)
    external
    override
    onlyRiskOrPoolAdmins
  {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);

    uint256 oldDebtCeiling = currentConfig.getDebtCeiling();
    if (oldDebtCeiling == 0) {
      _checkNoSuppliers(asset);
    }
    currentConfig.setDebtCeiling(newDebtCeiling);
    _pool.setConfiguration(asset, currentConfig);

    if (newDebtCeiling == 0) {
      _pool.resetIsolationModeTotalDebt(asset);
    }

    emit DebtCeilingChanged(asset, oldDebtCeiling, newDebtCeiling);
  }

  /// @inheritdoc IPoolConfigurator
  function setSiloedBorrowing(address asset, bool newSiloed)
    external
    override
    onlyRiskOrPoolAdmins
  {
    if (newSiloed) {
      _checkNoBorrowers(asset);
    }
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);

    bool oldSiloed = currentConfig.getSiloedBorrowing();

    currentConfig.setSiloedBorrowing(newSiloed);

    _pool.setConfiguration(asset, currentConfig);

    emit SiloedBorrowingChanged(asset, oldSiloed, newSiloed);
  }

  /// @inheritdoc IPoolConfigurator
  function setBorrowCap(address asset, uint256 newBorrowCap)
    external
    override
    onlyRiskOrPoolAdmins
  {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldBorrowCap = currentConfig.getBorrowCap();
    currentConfig.setBorrowCap(newBorrowCap);
    _pool.setConfiguration(asset, currentConfig);
    emit BorrowCapChanged(asset, oldBorrowCap, newBorrowCap);
  }

  /// @inheritdoc IPoolConfigurator
  function setSupplyCap(address asset, uint256 newSupplyCap)
    external
    override
    onlyRiskOrPoolAdmins
  {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldSupplyCap = currentConfig.getSupplyCap();
    currentConfig.setSupplyCap(newSupplyCap);
    _pool.setConfiguration(asset, currentConfig);
    emit SupplyCapChanged(asset, oldSupplyCap, newSupplyCap);
  }

  /// @inheritdoc IPoolConfigurator
  function setLiquidationProtocolFee(address asset, uint256 newFee)
    external
    override
    onlyRiskOrPoolAdmins
  {
    require(newFee <= PercentageMath.PERCENTAGE_FACTOR, Errors.INVALID_LIQUIDATION_PROTOCOL_FEE);
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldFee = currentConfig.getLiquidationProtocolFee();
    currentConfig.setLiquidationProtocolFee(newFee);
    _pool.setConfiguration(asset, currentConfig);
    emit LiquidationProtocolFeeChanged(asset, oldFee, newFee);
  }

  /// @inheritdoc IPoolConfigurator
  function setEModeCategory(
    uint8 categoryId,
    uint16 ltv,
    uint16 liquidationThreshold,
    uint16 liquidationBonus,
    address oracle,
    string calldata label
  ) external override onlyRiskOrPoolAdmins {
    require(ltv != 0, Errors.INVALID_EMODE_CATEGORY_PARAMS);
    require(liquidationThreshold != 0, Errors.INVALID_EMODE_CATEGORY_PARAMS);

    // validation of the parameters: the LTV can
    // only be lower or equal than the liquidation threshold
    // (otherwise a loan against the asset would cause instantaneous liquidation)
    require(ltv <= liquidationThreshold, Errors.INVALID_EMODE_CATEGORY_PARAMS);
    require(
      liquidationBonus > PercentageMath.PERCENTAGE_FACTOR,
      Errors.INVALID_EMODE_CATEGORY_PARAMS
    );

    // if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
    // a loan is taken there is enough collateral available to cover the liquidation bonus
    require(
      uint256(liquidationThreshold).percentMul(liquidationBonus) <=
        PercentageMath.PERCENTAGE_FACTOR,
      Errors.INVALID_EMODE_CATEGORY_PARAMS
    );

    address[] memory reserves = _pool.getReservesList();
    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(reserves[i]);
      if (categoryId == currentConfig.getEModeCategory()) {
        require(ltv > currentConfig.getLtv(), Errors.INVALID_EMODE_CATEGORY_PARAMS);
        require(
          liquidationThreshold > currentConfig.getLiquidationThreshold(),
          Errors.INVALID_EMODE_CATEGORY_PARAMS
        );
      }
    }

    _pool.configureEModeCategory(
      categoryId,
      DataTypes.EModeCategory({
        ltv: ltv,
        liquidationThreshold: liquidationThreshold,
        liquidationBonus: liquidationBonus,
        priceSource: oracle,
        label: label
      })
    );
    emit EModeCategoryAdded(categoryId, ltv, liquidationThreshold, liquidationBonus, oracle, label);
  }

  /// @inheritdoc IPoolConfigurator
  function setAssetEModeCategory(address asset, uint8 newCategoryId)
    external
    override
    onlyRiskOrPoolAdmins
  {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);

    if (newCategoryId != 0) {
      DataTypes.EModeCategory memory categoryData = _pool.getEModeCategoryData(newCategoryId);
      require(
        categoryData.liquidationThreshold > currentConfig.getLiquidationThreshold(),
        Errors.INVALID_EMODE_CATEGORY_ASSIGNMENT
      );
    }
    uint256 oldCategoryId = currentConfig.getEModeCategory();
    currentConfig.setEModeCategory(newCategoryId);
    _pool.setConfiguration(asset, currentConfig);
    emit EModeAssetCategoryChanged(asset, uint8(oldCategoryId), newCategoryId);
  }

  /// @inheritdoc IPoolConfigurator
  function setUnbackedMintCap(address asset, uint256 newUnbackedMintCap)
    external
    override
    onlyRiskOrPoolAdmins
  {
    DataTypes.ReserveConfigurationMap memory currentConfig = _pool.getConfiguration(asset);
    uint256 oldUnbackedMintCap = currentConfig.getUnbackedMintCap();
    currentConfig.setUnbackedMintCap(newUnbackedMintCap);
    _pool.setConfiguration(asset, currentConfig);
    emit UnbackedMintCapChanged(asset, oldUnbackedMintCap, newUnbackedMintCap);
  }

  /// @inheritdoc IPoolConfigurator
  function setReserveInterestRateStrategyAddress(address asset, address newRateStrategyAddress)
    external
    override
    onlyRiskOrPoolAdmins
  {
    DataTypes.ReserveData memory reserve = _pool.getReserveData(asset);
    address oldRateStrategyAddress = reserve.interestRateStrategyAddress;
    _pool.setReserveInterestRateStrategyAddress(asset, newRateStrategyAddress);
    emit ReserveInterestRateStrategyChanged(asset, oldRateStrategyAddress, newRateStrategyAddress);
  }

  /// @inheritdoc IPoolConfigurator
  function setPoolPause(bool paused) external override onlyEmergencyAdmin {
    address[] memory reserves = _pool.getReservesList();

    for (uint256 i = 0; i < reserves.length; i++) {
      if (reserves[i] != address(0)) {
        setReservePause(reserves[i], paused);
      }
    }
  }

  /// @inheritdoc IPoolConfigurator
  function updateBridgeProtocolFee(uint256 newBridgeProtocolFee) external override onlyPoolAdmin {
    require(
      newBridgeProtocolFee <= PercentageMath.PERCENTAGE_FACTOR,
      Errors.BRIDGE_PROTOCOL_FEE_INVALID
    );
    uint256 oldBridgeProtocolFee = _pool.BRIDGE_PROTOCOL_FEE();
    _pool.updateBridgeProtocolFee(newBridgeProtocolFee);
    emit BridgeProtocolFeeUpdated(oldBridgeProtocolFee, newBridgeProtocolFee);
  }

  /// @inheritdoc IPoolConfigurator
  function updateFlashloanPremiumTotal(uint128 newFlashloanPremiumTotal)
    external
    override
    onlyPoolAdmin
  {
    require(
      newFlashloanPremiumTotal <= PercentageMath.PERCENTAGE_FACTOR,
      Errors.FLASHLOAN_PREMIUM_INVALID
    );
    uint128 oldFlashloanPremiumTotal = _pool.FLASHLOAN_PREMIUM_TOTAL();
    _pool.updateFlashloanPremiums(newFlashloanPremiumTotal, _pool.FLASHLOAN_PREMIUM_TO_PROTOCOL());
    emit FlashloanPremiumTotalUpdated(oldFlashloanPremiumTotal, newFlashloanPremiumTotal);
  }

  /// @inheritdoc IPoolConfigurator
  function updateFlashloanPremiumToProtocol(uint128 newFlashloanPremiumToProtocol)
    external
    override
    onlyPoolAdmin
  {
    require(
      newFlashloanPremiumToProtocol <= PercentageMath.PERCENTAGE_FACTOR,
      Errors.FLASHLOAN_PREMIUM_INVALID
    );
    uint128 oldFlashloanPremiumToProtocol = _pool.FLASHLOAN_PREMIUM_TO_PROTOCOL();
    _pool.updateFlashloanPremiums(_pool.FLASHLOAN_PREMIUM_TOTAL(), newFlashloanPremiumToProtocol);
    emit FlashloanPremiumToProtocolUpdated(
      oldFlashloanPremiumToProtocol,
      newFlashloanPremiumToProtocol
    );
  }

  function _checkNoSuppliers(address asset) internal view {
    uint256 totalATokens = IPoolDataProvider(_addressesProvider.getPoolDataProvider())
      .getATokenTotalSupply(asset);
    require(totalATokens == 0, Errors.RESERVE_LIQUIDITY_NOT_ZERO);
  }

  function _checkNoBorrowers(address asset) internal view {
    uint256 totalDebt = IPoolDataProvider(_addressesProvider.getPoolDataProvider()).getTotalDebt(
      asset
    );
    require(totalDebt == 0, Errors.RESERVE_DEBT_NOT_ZERO);
  }

  function _onlyPoolAdmin() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(aclManager.isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
  }

  function _onlyEmergencyAdmin() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(aclManager.isEmergencyAdmin(msg.sender), Errors.CALLER_NOT_EMERGENCY_ADMIN);
  }

  function _onlyPoolOrEmergencyAdmin() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(
      aclManager.isPoolAdmin(msg.sender) || aclManager.isEmergencyAdmin(msg.sender),
      Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN
    );
  }

  function _onlyAssetListingOrPoolAdmins() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(
      aclManager.isAssetListingAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
    );
  }

  function _onlyRiskOrPoolAdmins() internal view {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(
      aclManager.isRiskAdmin(msg.sender) || aclManager.isPoolAdmin(msg.sender),
      Errors.CALLER_NOT_RISK_OR_POOL_ADMIN
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {UserConfiguration} from '../libraries/configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';

/**
 * @title PoolStorage
 *
 * @notice Contract used as storage of the Pool contract.
 * @dev It defines the storage layout of the Pool contract.
 */
contract PoolStorage {
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  // Map of reserves and their data (underlyingAssetOfReserve => reserveData)
  mapping(address => DataTypes.ReserveData) internal _reserves;

  // Map of users address and their configuration data (userAddress => userConfiguration)
  mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

  // List of reserves as a map (reserveId => reserve).
  // It is structured as a mapping for gas savings reasons, using the reserve id as index
  mapping(uint256 => address) internal _reservesList;

  // List of eMode categories as a map (eModeCategoryId => eModeCategory).
  // It is structured as a mapping for gas savings reasons, using the eModeCategoryId as index
  mapping(uint8 => DataTypes.EModeCategory) internal _eModeCategories;

  // Map of users address and their eMode category (userAddress => eModeCategoryId)
  mapping(address => uint8) internal _usersEModeCategory;

  // Fee of the protocol bridge, expressed in bps
  uint256 internal _bridgeProtocolFee;

  // Total FlashLoan Premium, expressed in bps
  uint128 internal _flashLoanPremiumTotal;

  // FlashLoan premium paid to protocol treasury, expressed in bps
  uint128 internal _flashLoanPremiumToProtocol;

  // Available liquidity that can be borrowed at once at stable rate, expressed in bps
  uint64 internal _maxStableRateBorrowSizePercent;

  // Maximum number of active reserves there have been in the protocol. It is the upper bound of the reserves list
  uint16 internal _reservesCount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {SafeCast} from '../../dependencies/openzeppelin/contracts/SafeCast.sol';
import {VersionedInitializable} from '../libraries/fintoch-upgradeability/VersionedInitializable.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';
import {IAToken} from '../../interfaces/IAToken.sol';
import {IFintochIncentivesController} from '../../interfaces/IFintochIncentivesController.sol';
import {IInitializableAToken} from '../../interfaces/IInitializableAToken.sol';
import {ScaledBalanceTokenBase} from './base/ScaledBalanceTokenBase.sol';
import {IncentivizedERC20} from './base/IncentivizedERC20.sol';
import {EIP712Base} from './base/EIP712Base.sol';

/**
 * @title Fintoch ERC20 AToken
 *
 * @notice Implementation of the interest bearing token for the Fintoch protocol
 */
contract AToken is VersionedInitializable, ScaledBalanceTokenBase, EIP712Base, IAToken {
  using WadRayMath for uint256;
  using SafeCast for uint256;
  using GPv2SafeERC20 for IERC20;

  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  uint256 public constant ATOKEN_REVISION = 0x1;

  address internal _treasury;
  address internal _underlyingAsset;

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure virtual override returns (uint256) {
    return ATOKEN_REVISION;
  }

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   */
  constructor(IL1Pool pool)
    ScaledBalanceTokenBase(pool, 'ATOKEN_IMPL', 'ATOKEN_IMPL', 0)
    EIP712Base()
  {
    // Intentionally left blank
  }

  /// @inheritdoc IInitializableAToken
  function initialize(
    IL1Pool initializingPool,
    address treasury,
    address underlyingAsset,
    IFintochIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external override initializer {
    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
    _setName(aTokenName);
    _setSymbol(aTokenSymbol);
    _setDecimals(aTokenDecimals);

    _treasury = treasury;
    _underlyingAsset = underlyingAsset;
    _incentivesController = incentivesController;

    _domainSeparator = _calculateDomainSeparator();

    emit Initialized(
      underlyingAsset,
      address(POOL),
      treasury,
      address(incentivesController),
      aTokenDecimals,
      aTokenName,
      aTokenSymbol,
      params
    );
  }

  /// @inheritdoc IAToken
  function mint(
    address caller,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external virtual override onlyPool returns (bool) {
    return _mintScaled(caller, onBehalfOf, amount, index);
  }

  /// @inheritdoc IAToken
  function burn(
    address from,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external virtual override onlyPool {
    _burnScaled(from, receiverOfUnderlying, amount, index);
    if (receiverOfUnderlying != address(this)) {
      IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);
    }
  }

  /// @inheritdoc IAToken
  function mintToTreasury(uint256 amount, uint256 index) external override onlyPool {
    if (amount == 0) {
      return;
    }
    _mintScaled(address(POOL), _treasury, amount, index);
  }

  /// @inheritdoc IAToken
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external override onlyPool {
    // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
    // so no need to emit a specific event here
    _transfer(from, to, value, false);

    emit Transfer(from, to, value);
  }

  /// @inheritdoc IERC20
  function balanceOf(address user)
    public
    view
    virtual
    override(IncentivizedERC20, IERC20)
    returns (uint256)
  {
    return super.balanceOf(user).rayMul(POOL.getReserveNormalizedIncome(_underlyingAsset));
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override(IncentivizedERC20, IERC20) returns (uint256) {
    uint256 currentSupplyScaled = super.totalSupply();

    if (currentSupplyScaled == 0) {
      return 0;
    }

    return currentSupplyScaled.rayMul(POOL.getReserveNormalizedIncome(_underlyingAsset));
  }

  /// @inheritdoc IAToken
  function RESERVE_TREASURY_ADDRESS() external view override returns (address) {
    return _treasury;
  }

  /// @inheritdoc IAToken
  function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
    return _underlyingAsset;
  }

  /// @inheritdoc IAToken
  function transferUnderlyingTo(address target, uint256 amount) external virtual override onlyPool {
    IERC20(_underlyingAsset).safeTransfer(target, amount);
  }

  /// @inheritdoc IAToken
  function handleRepayment(address user, uint256 amount) external virtual override onlyPool {
    // Intentionally left blank
  }

  /// @inheritdoc IAToken
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override {
    require(owner != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
    //solium-disable-next-line
    require(block.timestamp <= deadline, Errors.INVALID_EXPIRATION);
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR(),
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );
    require(owner == ecrecover(digest, v, r, s), Errors.INVALID_SIGNATURE);
    _nonces[owner] = currentValidNonce + 1;
    _approve(owner, spender, value);
  }

  /**
   * @notice Transfers the aTokens between two users. Validates the transfer
   * (ie checks for valid HF after the transfer) if required
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   * @param validate True if the transfer needs to be validated, false otherwise
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount,
    bool validate
  ) internal {
    address underlyingAsset = _underlyingAsset;

    uint256 index = POOL.getReserveNormalizedIncome(underlyingAsset);

    uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
    uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

    super._transfer(from, to, amount.rayDiv(index).toUint128());

    if (validate) {
      POOL.finalizeTransfer(underlyingAsset, from, to, amount, fromBalanceBefore, toBalanceBefore);
    }

    emit BalanceTransfer(from, to, amount, index);
  }

  /**
   * @notice Overrides the parent _transfer to force validated transfer() and transferFrom()
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   **/
  function _transfer(
    address from,
    address to,
    uint128 amount
  ) internal override {
    _transfer(from, to, amount, true);
  }

  /**
   * @dev Overrides the base function to fully implement IAToken
   * @dev see `IncentivizedERC20.DOMAIN_SEPARATOR()` for more detailed documentation
   */
  function DOMAIN_SEPARATOR() public view override(IAToken, EIP712Base) returns (bytes32) {
    return super.DOMAIN_SEPARATOR();
  }

  /**
   * @dev Overrides the base function to fully implement IAToken
   * @dev see `IncentivizedERC20.nonces()` for more detailed documentation
   */
  function nonces(address owner) public view override(IAToken, EIP712Base) returns (uint256) {
    return super.nonces(owner);
  }

  /// @inheritdoc EIP712Base
  function _EIP712BaseId() internal view override returns (string memory) {
    return name();
  }

  /// @inheritdoc IAToken
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external override onlyPoolAdmin {
    require(token != _underlyingAsset, Errors.UNDERLYING_CANNOT_BE_RESCUED);
    IERC20(token).safeTransfer(to, amount);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IL1Pool} from '../../interfaces/IL1Pool.sol';
import {IDelegationToken} from '../../interfaces/IDelegationToken.sol';
import {AToken} from './AToken.sol';

/**
 * @title DelegationAwareAToken
 *
 * @notice AToken enabled to delegate voting power of the underlying asset to a different address
 * @dev The underlying asset needs to be compatible with the COMP delegation interface
 */
contract DelegationAwareAToken is AToken {
  /**
   * @dev Emitted when underlying voting power is delegated
   * @param delegatee The address of the delegatee
   */
  event DelegateUnderlyingTo(address indexed delegatee);

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   */
  constructor(IL1Pool pool) AToken(pool) {
    // Intentionally left blank
  }

  /**
   * @notice Delegates voting power of the underlying asset to a `delegatee` address
   * @param delegatee The address that will receive the delegation
   **/
  function delegateUnderlyingTo(address delegatee) external onlyPoolAdmin {
    IDelegationToken(_underlyingAsset).delegate(delegatee);
    emit DelegateUnderlyingTo(delegatee);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {VersionedInitializable} from '../libraries/fintoch-upgradeability/VersionedInitializable.sol';
import {MathUtils} from '../libraries/math/MathUtils.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IFintochIncentivesController} from '../../interfaces/IFintochIncentivesController.sol';
import {IInitializableDebtToken} from '../../interfaces/IInitializableDebtToken.sol';
import {IStableDebtToken} from '../../interfaces/IStableDebtToken.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';
import {EIP712Base} from './base/EIP712Base.sol';
import {DebtTokenBase} from './base/DebtTokenBase.sol';
import {IncentivizedERC20} from './base/IncentivizedERC20.sol';
import {SafeCast} from '../../dependencies/openzeppelin/contracts/SafeCast.sol';

/**
 * @title StableDebtToken
 *
 * @notice Implements a stable debt token to track the borrowing positions of users
 * at stable rate mode
 * @dev Transfer and approve functionalities are disabled since its a non-transferable token
 **/
contract StableDebtToken is DebtTokenBase, IncentivizedERC20, IStableDebtToken {
  using WadRayMath for uint256;
  using SafeCast for uint256;

  uint256 public constant DEBT_TOKEN_REVISION = 0x1;

  // Map of users address and the timestamp of their last update (userAddress => lastUpdateTimestamp)
  mapping(address => uint40) internal _timestamps;

  uint128 internal _avgStableRate;

  // Timestamp of the last update of the total supply
  uint40 internal _totalSupplyTimestamp;

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   */
  constructor(IL1Pool pool)
    DebtTokenBase()
    IncentivizedERC20(pool, 'STABLE_DEBT_TOKEN_IMPL', 'STABLE_DEBT_TOKEN_IMPL', 0)
  {
    // Intentionally left blank
  }

  /// @inheritdoc IInitializableDebtToken
  function initialize(
    IL1Pool initializingPool,
    address underlyingAsset,
    IFintochIncentivesController incentivesController,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external override initializer {
    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
    _setName(debtTokenName);
    _setSymbol(debtTokenSymbol);
    _setDecimals(debtTokenDecimals);

    _underlyingAsset = underlyingAsset;
    _incentivesController = incentivesController;

    _domainSeparator = _calculateDomainSeparator();

    emit Initialized(
      underlyingAsset,
      address(POOL),
      address(incentivesController),
      debtTokenDecimals,
      debtTokenName,
      debtTokenSymbol,
      params
    );
  }

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure virtual override returns (uint256) {
    return DEBT_TOKEN_REVISION;
  }

  /// @inheritdoc IStableDebtToken
  function getAverageStableRate() external view virtual override returns (uint256) {
    return _avgStableRate;
  }

  /// @inheritdoc IStableDebtToken
  function getUserLastUpdated(address user) external view virtual override returns (uint40) {
    return _timestamps[user];
  }

  /// @inheritdoc IStableDebtToken
  function getUserStableRate(address user) external view virtual override returns (uint256) {
    return _userState[user].additionalData;
  }

  /// @inheritdoc IERC20
  function balanceOf(address account) public view virtual override returns (uint256) {
    uint256 accountBalance = super.balanceOf(account);
    uint256 stableRate = _userState[account].additionalData;
    if (accountBalance == 0) {
      return 0;
    }
    uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
      stableRate,
      _timestamps[account]
    );
    return accountBalance.rayMul(cumulatedInterest);
  }

  struct MintLocalVars {
    uint256 previousSupply;
    uint256 nextSupply;
    uint256 amountInRay;
    uint256 currentStableRate;
    uint256 nextStableRate;
    uint256 currentAvgStableRate;
  }

  /// @inheritdoc IStableDebtToken
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 rate
  )
    external
    virtual
    override
    onlyPool
    returns (
      bool,
      uint256,
      uint256
    )
  {
    MintLocalVars memory vars;

    if (user != onBehalfOf) {
      _decreaseBorrowAllowance(onBehalfOf, user, amount);
    }

    (, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(onBehalfOf);

    vars.previousSupply = totalSupply();
    vars.currentAvgStableRate = _avgStableRate;
    vars.nextSupply = _totalSupply = vars.previousSupply + amount;

    vars.amountInRay = amount.wadToRay();

    vars.currentStableRate = _userState[onBehalfOf].additionalData;
    vars.nextStableRate = (vars.currentStableRate.rayMul(currentBalance.wadToRay()) +
      vars.amountInRay.rayMul(rate)).rayDiv((currentBalance + amount).wadToRay());

    _userState[onBehalfOf].additionalData = vars.nextStableRate.toUint128();

    //solium-disable-next-line
    _totalSupplyTimestamp = _timestamps[onBehalfOf] = uint40(block.timestamp);

    // Calculates the updated average stable rate
    vars.currentAvgStableRate = _avgStableRate = (
      (vars.currentAvgStableRate.rayMul(vars.previousSupply.wadToRay()) +
        rate.rayMul(vars.amountInRay)).rayDiv(vars.nextSupply.wadToRay())
    ).toUint128();

    uint256 amountToMint = amount + balanceIncrease;
    _mint(onBehalfOf, amountToMint, vars.previousSupply);

    emit Transfer(address(0), onBehalfOf, amountToMint);
    emit Mint(
      user,
      onBehalfOf,
      amountToMint,
      currentBalance,
      balanceIncrease,
      vars.nextStableRate,
      vars.currentAvgStableRate,
      vars.nextSupply
    );

    return (currentBalance == 0, vars.nextSupply, vars.currentAvgStableRate);
  }

  /// @inheritdoc IStableDebtToken
  function burn(address from, uint256 amount)
    external
    virtual
    override
    onlyPool
    returns (uint256, uint256)
  {
    (, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(from);

    uint256 previousSupply = totalSupply();
    uint256 nextAvgStableRate = 0;
    uint256 nextSupply = 0;
    uint256 userStableRate = _userState[from].additionalData;

    // Since the total supply and each single user debt accrue separately,
    // there might be accumulation errors so that the last borrower repaying
    // might actually try to repay more than the available debt supply.
    // In this case we simply set the total supply and the avg stable rate to 0
    if (previousSupply <= amount) {
      _avgStableRate = 0;
      _totalSupply = 0;
    } else {
      nextSupply = _totalSupply = previousSupply - amount;
      uint256 firstTerm = uint256(_avgStableRate).rayMul(previousSupply.wadToRay());
      uint256 secondTerm = userStableRate.rayMul(amount.wadToRay());

      // For the same reason described above, when the last user is repaying it might
      // happen that user rate * user balance > avg rate * total supply. In that case,
      // we simply set the avg rate to 0
      if (secondTerm >= firstTerm) {
        nextAvgStableRate = _totalSupply = _avgStableRate = 0;
      } else {
        nextAvgStableRate = _avgStableRate = (
          (firstTerm - secondTerm).rayDiv(nextSupply.wadToRay())
        ).toUint128();
      }
    }

    if (amount == currentBalance) {
      _userState[from].additionalData = 0;
      _timestamps[from] = 0;
    } else {
      //solium-disable-next-line
      _timestamps[from] = uint40(block.timestamp);
    }
    //solium-disable-next-line
    _totalSupplyTimestamp = uint40(block.timestamp);

    if (balanceIncrease > amount) {
      uint256 amountToMint = balanceIncrease - amount;
      _mint(from, amountToMint, previousSupply);
      emit Transfer(address(0), from, amountToMint);
      emit Mint(
        from,
        from,
        amountToMint,
        currentBalance,
        balanceIncrease,
        userStableRate,
        nextAvgStableRate,
        nextSupply
      );
    } else {
      uint256 amountToBurn = amount - balanceIncrease;
      _burn(from, amountToBurn, previousSupply);
      emit Transfer(from, address(0), amountToBurn);
      emit Burn(from, amountToBurn, currentBalance, balanceIncrease, nextAvgStableRate, nextSupply);
    }

    return (nextSupply, nextAvgStableRate);
  }

  /**
   * @notice Calculates the increase in balance since the last user interaction
   * @param user The address of the user for which the interest is being accumulated
   * @return The previous principal balance
   * @return The new principal balance
   * @return The balance increase
   **/
  function _calculateBalanceIncrease(address user)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 previousPrincipalBalance = super.balanceOf(user);

    if (previousPrincipalBalance == 0) {
      return (0, 0, 0);
    }

    uint256 newPrincipalBalance = balanceOf(user);

    return (
      previousPrincipalBalance,
      newPrincipalBalance,
      newPrincipalBalance - previousPrincipalBalance
    );
  }

  /// @inheritdoc IStableDebtToken
  function getSupplyData()
    external
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint40
    )
  {
    uint256 avgRate = _avgStableRate;
    return (super.totalSupply(), _calcTotalSupply(avgRate), avgRate, _totalSupplyTimestamp);
  }

  /// @inheritdoc IStableDebtToken
  function getTotalSupplyAndAvgRate() external view override returns (uint256, uint256) {
    uint256 avgRate = _avgStableRate;
    return (_calcTotalSupply(avgRate), avgRate);
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override returns (uint256) {
    return _calcTotalSupply(_avgStableRate);
  }

  /// @inheritdoc IStableDebtToken
  function getTotalSupplyLastUpdated() external view override returns (uint40) {
    return _totalSupplyTimestamp;
  }

  /// @inheritdoc IStableDebtToken
  function principalBalanceOf(address user) external view virtual override returns (uint256) {
    return super.balanceOf(user);
  }

  /// @inheritdoc IStableDebtToken
  function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
    return _underlyingAsset;
  }

  /**
   * @notice Calculates the total supply
   * @param avgRate The average rate at which the total supply increases
   * @return The debt balance of the user since the last burn/mint action
   **/
  function _calcTotalSupply(uint256 avgRate) internal view returns (uint256) {
    uint256 principalSupply = super.totalSupply();

    if (principalSupply == 0) {
      return 0;
    }

    uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
      avgRate,
      _totalSupplyTimestamp
    );

    return principalSupply.rayMul(cumulatedInterest);
  }

  /**
   * @notice Mints stable debt tokens to a user
   * @param account The account receiving the debt tokens
   * @param amount The amount being minted
   * @param oldTotalSupply The total supply before the minting event
   **/
  function _mint(
    address account,
    uint256 amount,
    uint256 oldTotalSupply
  ) internal {
    uint128 castAmount = amount.toUint128();
    uint128 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance + castAmount;

    if (address(_incentivesController) != address(0)) {
      _incentivesController.handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  /**
   * @notice Burns stable debt tokens of a user
   * @param account The user getting his debt burned
   * @param amount The amount being burned
   * @param oldTotalSupply The total supply before the burning event
   **/
  function _burn(
    address account,
    uint256 amount,
    uint256 oldTotalSupply
  ) internal {
    uint128 castAmount = amount.toUint128();
    uint128 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance - castAmount;

    if (address(_incentivesController) != address(0)) {
      _incentivesController.handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  /// @inheritdoc EIP712Base
  function _EIP712BaseId() internal view override returns (string memory) {
    return name();
  }

  /**
   * @dev Being non transferrable, the debt token does not implement any of the
   * standard ERC20 functions for transfer and allowance.
   **/
  function transfer(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function allowance(address, address) external view virtual override returns (uint256) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function approve(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function transferFrom(
    address,
    address,
    uint256
  ) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function increaseAllowance(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function decreaseAllowance(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {SafeCast} from '../../dependencies/openzeppelin/contracts/SafeCast.sol';
import {VersionedInitializable} from '../libraries/fintoch-upgradeability/VersionedInitializable.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';
import {IFintochIncentivesController} from '../../interfaces/IFintochIncentivesController.sol';
import {IInitializableDebtToken} from '../../interfaces/IInitializableDebtToken.sol';
import {IVariableDebtToken} from '../../interfaces/IVariableDebtToken.sol';
import {EIP712Base} from './base/EIP712Base.sol';
import {DebtTokenBase} from './base/DebtTokenBase.sol';
import {ScaledBalanceTokenBase} from './base/ScaledBalanceTokenBase.sol';

/**
 * @title VariableDebtToken
 *
 * @notice Implements a variable debt token to track the borrowing positions of users
 * at variable rate mode
 * @dev Transfer and approve functionalities are disabled since its a non-transferable token
 **/
contract VariableDebtToken is DebtTokenBase, ScaledBalanceTokenBase, IVariableDebtToken {
  using WadRayMath for uint256;
  using SafeCast for uint256;

  uint256 public constant DEBT_TOKEN_REVISION = 0x1;

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   */
  constructor(IL1Pool pool)
    DebtTokenBase()
    ScaledBalanceTokenBase(pool, 'VARIABLE_DEBT_TOKEN_IMPL', 'VARIABLE_DEBT_TOKEN_IMPL', 0)
  {
    // Intentionally left blank
  }

  /// @inheritdoc IInitializableDebtToken
  function initialize(
    IL1Pool initializingPool,
    address underlyingAsset,
    IFintochIncentivesController incentivesController,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external override initializer {
    require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
    _setName(debtTokenName);
    _setSymbol(debtTokenSymbol);
    _setDecimals(debtTokenDecimals);

    _underlyingAsset = underlyingAsset;
    _incentivesController = incentivesController;

    _domainSeparator = _calculateDomainSeparator();

    emit Initialized(
      underlyingAsset,
      address(POOL),
      address(incentivesController),
      debtTokenDecimals,
      debtTokenName,
      debtTokenSymbol,
      params
    );
  }

  /// @inheritdoc VersionedInitializable
  function getRevision() internal pure virtual override returns (uint256) {
    return DEBT_TOKEN_REVISION;
  }

  /// @inheritdoc IERC20
  function balanceOf(address user) public view virtual override returns (uint256) {
    uint256 scaledBalance = super.balanceOf(user);

    if (scaledBalance == 0) {
      return 0;
    }

    return scaledBalance.rayMul(POOL.getReserveNormalizedVariableDebt(_underlyingAsset));
  }

  /// @inheritdoc IVariableDebtToken
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external virtual override onlyPool returns (bool, uint256) {
    if (user != onBehalfOf) {
      _decreaseBorrowAllowance(onBehalfOf, user, amount);
    }
    return (_mintScaled(user, onBehalfOf, amount, index), scaledTotalSupply());
  }

  /// @inheritdoc IVariableDebtToken
  function burn(
    address from,
    uint256 amount,
    uint256 index
  ) external virtual override onlyPool returns (uint256) {
    _burnScaled(from, address(0), amount, index);
    return scaledTotalSupply();
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override returns (uint256) {
    return super.totalSupply().rayMul(POOL.getReserveNormalizedVariableDebt(_underlyingAsset));
  }

  /// @inheritdoc EIP712Base
  function _EIP712BaseId() internal view override returns (string memory) {
    return name();
  }

  /**
   * @dev Being non transferrable, the debt token does not implement any of the
   * standard ERC20 functions for transfer and allowance.
   **/
  function transfer(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function allowance(address, address) external view virtual override returns (uint256) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function approve(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function transferFrom(
    address,
    address,
    uint256
  ) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function increaseAllowance(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  function decreaseAllowance(address, uint256) external virtual override returns (bool) {
    revert(Errors.OPERATION_NOT_SUPPORTED);
  }

  /// @inheritdoc IVariableDebtToken
  function UNDERLYING_ASSET_ADDRESS() external view override returns (address) {
    return _underlyingAsset;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Context} from '../../../dependencies/openzeppelin/contracts/Context.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';
import {VersionedInitializable} from '../../libraries/fintoch-upgradeability/VersionedInitializable.sol';
import {ICreditDelegationToken} from '../../../interfaces/ICreditDelegationToken.sol';
import {EIP712Base} from './EIP712Base.sol';

/**
 * @title DebtTokenBase
 *
 * @notice Base contract for different types of debt tokens, like StableDebtToken or VariableDebtToken
 */
abstract contract DebtTokenBase is
  VersionedInitializable,
  EIP712Base,
  Context,
  ICreditDelegationToken
{
  // Map of borrow allowances (delegator => delegatee => borrowAllowanceAmount)
  mapping(address => mapping(address => uint256)) internal _borrowAllowances;

  // Credit Delegation Typehash
  bytes32 public constant DELEGATION_WITH_SIG_TYPEHASH =
    keccak256('DelegationWithSig(address delegatee,uint256 value,uint256 nonce,uint256 deadline)');

  address internal _underlyingAsset;

  /**
   * @dev Constructor.
   */
  constructor() EIP712Base() {
    // Intentionally left blank
  }

  /// @inheritdoc ICreditDelegationToken
  function approveDelegation(address delegatee, uint256 amount) external override {
    _approveDelegation(_msgSender(), delegatee, amount);
  }

  /// @inheritdoc ICreditDelegationToken
  function delegationWithSig(
    address delegator,
    address delegatee,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(delegator != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
    //solium-disable-next-line
    require(block.timestamp <= deadline, Errors.INVALID_EXPIRATION);
    uint256 currentValidNonce = _nonces[delegator];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR(),
        keccak256(
          abi.encode(DELEGATION_WITH_SIG_TYPEHASH, delegatee, value, currentValidNonce, deadline)
        )
      )
    );
    require(delegator == ecrecover(digest, v, r, s), Errors.INVALID_SIGNATURE);
    _nonces[delegator] = currentValidNonce + 1;
    _approveDelegation(delegator, delegatee, value);
  }

  /// @inheritdoc ICreditDelegationToken
  function borrowAllowance(address fromUser, address toUser)
    external
    view
    override
    returns (uint256)
  {
    return _borrowAllowances[fromUser][toUser];
  }

  /**
   * @notice Updates the borrow allowance of a user on the specific debt token.
   * @param delegator The address delegating the borrowing power
   * @param delegatee The address receiving the delegated borrowing power
   * @param amount The allowance amount being delegated.
   **/
  function _approveDelegation(
    address delegator,
    address delegatee,
    uint256 amount
  ) internal {
    _borrowAllowances[delegator][delegatee] = amount;
    emit BorrowAllowanceDelegated(delegator, delegatee, _underlyingAsset, amount);
  }

  /**
   * @notice Decreases the borrow allowance of a user on the specific debt token.
   * @param delegator The address delegating the borrowing power
   * @param delegatee The address receiving the delegated borrowing power
   * @param amount The amount to subtract from the current allowance
   **/
  function _decreaseBorrowAllowance(
    address delegator,
    address delegatee,
    uint256 amount
  ) internal {
    uint256 newAllowance = _borrowAllowances[delegator][delegatee] - amount;

    _borrowAllowances[delegator][delegatee] = newAllowance;

    emit BorrowAllowanceDelegated(delegator, delegatee, _underlyingAsset, newAllowance);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/**
 * @title EIP712Base
 *
 * @notice Base contract implementation of EIP712.
 */
abstract contract EIP712Base {
  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

  // Map of address nonces (address => nonce)
  mapping(address => uint256) internal _nonces;

  bytes32 internal _domainSeparator;
  uint256 internal immutable _chainId;

  /**
   * @dev Constructor.
   */
  constructor() {
    _chainId = block.chainid;
  }

  /**
   * @notice Get the domain separator for the token
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    if (block.chainid == _chainId) {
      return _domainSeparator;
    }
    return _calculateDomainSeparator();
  }

  /**
   * @notice Returns the nonce value for address specified as parameter
   * @param owner The address for which the nonce is being returned
   * @return The nonce value for the input address`
   */
  function nonces(address owner) public view virtual returns (uint256) {
    return _nonces[owner];
  }

  /**
   * @notice Compute the current domain separator
   * @return The domain separator for the token
   */
  function _calculateDomainSeparator() internal view returns (bytes32) {
    return
      keccak256(
        abi.encode(
          EIP712_DOMAIN,
          keccak256(bytes(_EIP712BaseId())),
          keccak256(EIP712_REVISION),
          block.chainid,
          address(this)
        )
      );
  }

  /**
   * @notice Returns the user readable name of signing domain (e.g. token name)
   * @return The name of the signing domain
   */
  function _EIP712BaseId() internal view virtual returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Context} from '../../../dependencies/openzeppelin/contracts/Context.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';
import {WadRayMath} from '../../libraries/math/WadRayMath.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';
import {IFintochIncentivesController} from '../../../interfaces/IFintochIncentivesController.sol';
import {IPoolAddressesProvider} from '../../../interfaces/IPoolAddressesProvider.sol';
import {IL1Pool} from '../../../interfaces/IL1Pool.sol';
import {IACLManager} from '../../../interfaces/IACLManager.sol';

/**
 * @title IncentivizedERC20
 *, inspired by the Openzeppelin ERC20 implementation
 * @notice Basic ERC20 implementation
 **/
abstract contract IncentivizedERC20 is Context, IERC20Detailed {
  using WadRayMath for uint256;
  using SafeCast for uint256;

  /**
   * @dev Only pool admin can call functions marked by this modifier.
   **/
  modifier onlyPoolAdmin() {
    IACLManager aclManager = IACLManager(_addressesProvider.getACLManager());
    require(aclManager.isPoolAdmin(msg.sender), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  /**
   * @dev Only pool can call functions marked by this modifier.
   **/
  modifier onlyPool() {
    require(_msgSender() == address(POOL), Errors.CALLER_MUST_BE_POOL);
    _;
  }

  /**
   * @dev UserState - additionalData is a flexible field.
   * ATokens and VariableDebtTokens use this field store the index of the
   * user's last supply/withdrawal/borrow/repayment. StableDebtTokens use
   * this field to store the user's stable rate.
   */
  struct UserState {
    uint128 balance;
    uint128 additionalData;
  }
  // Map of users address and their state data (userAddress => userStateData)
  mapping(address => UserState) internal _userState;

  // Map of allowances (delegator => delegatee => allowanceAmount)
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 internal _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  IFintochIncentivesController internal _incentivesController;
  IPoolAddressesProvider internal immutable _addressesProvider;
  IL1Pool public immutable POOL;

  /**
   * @dev Constructor.
   * @param pool The reference to the main Pool contract
   * @param name The name of the token
   * @param symbol The symbol of the token
   * @param decimals The number of decimals of the token
   */
  constructor(
    IL1Pool pool,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) {
    _addressesProvider = pool.ADDRESSES_PROVIDER();
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    POOL = pool;
  }

  /// @inheritdoc IERC20Detailed
  function name() public view override returns (string memory) {
    return _name;
  }

  /// @inheritdoc IERC20Detailed
  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  /// @inheritdoc IERC20Detailed
  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  /// @inheritdoc IERC20
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /// @inheritdoc IERC20
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _userState[account].balance;
  }

  /**
   * @notice Returns the address of the Incentives Controller contract
   * @return The address of the Incentives Controller
   **/
  function getIncentivesController() external view virtual returns (IFintochIncentivesController) {
    return _incentivesController;
  }

  /**
   * @notice Sets a new Incentives Controller
   * @param controller the new Incentives controller
   **/
  function setIncentivesController(IFintochIncentivesController controller) external onlyPoolAdmin {
    _incentivesController = controller;
  }

  /// @inheritdoc IERC20
  function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
    uint128 castAmount = amount.toUint128();
    _transfer(_msgSender(), recipient, castAmount);
    return true;
  }

  /// @inheritdoc IERC20
  function allowance(address owner, address spender)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /// @inheritdoc IERC20
  function approve(address spender, uint256 amount) external virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /// @inheritdoc IERC20
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external virtual override returns (bool) {
    uint128 castAmount = amount.toUint128();
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - castAmount);
    _transfer(sender, recipient, castAmount);
    return true;
  }

  /**
   * @notice Increases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param addedValue The amount being added to the allowance
   * @return `true`
   **/
  function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  /**
   * @notice Decreases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param subtractedValue The amount being subtracted to the allowance
   * @return `true`
   **/
  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    virtual
    returns (bool)
  {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
    return true;
  }

  /**
   * @notice Transfers tokens between two users and apply incentives if defined.
   * @param sender The source address
   * @param recipient The destination address
   * @param amount The amount getting transferred
   */
  function _transfer(
    address sender,
    address recipient,
    uint128 amount
  ) internal virtual {
    uint128 oldSenderBalance = _userState[sender].balance;
    _userState[sender].balance = oldSenderBalance - amount;
    uint128 oldRecipientBalance = _userState[recipient].balance;
    _userState[recipient].balance = oldRecipientBalance + amount;

    IFintochIncentivesController incentivesControllerLocal = _incentivesController;
    if (address(incentivesControllerLocal) != address(0)) {
      uint256 currentTotalSupply = _totalSupply;
      incentivesControllerLocal.handleAction(sender, currentTotalSupply, oldSenderBalance);
      if (sender != recipient) {
        incentivesControllerLocal.handleAction(recipient, currentTotalSupply, oldRecipientBalance);
      }
    }
    emit Transfer(sender, recipient, amount);
  }

  /**
   * @notice Approve `spender` to use `amount` of `owner`s balance
   * @param owner The address owning the tokens
   * @param spender The address approved for spending
   * @param amount The amount of tokens to approve spending of
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @notice Update the name of the token
   * @param newName The new name for the token
   */
  function _setName(string memory newName) internal {
    _name = newName;
  }

  /**
   * @notice Update the symbol for the token
   * @param newSymbol The new symbol for the token
   */
  function _setSymbol(string memory newSymbol) internal {
    _symbol = newSymbol;
  }

  /**
   * @notice Update the number of decimals for the token
   * @param newDecimals The new number of decimals for the token
   */
  function _setDecimals(uint8 newDecimals) internal {
    _decimals = newDecimals;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {IFintochIncentivesController} from '../../../interfaces/IFintochIncentivesController.sol';
import {IL1Pool} from '../../../interfaces/IL1Pool.sol';
import {IncentivizedERC20} from './IncentivizedERC20.sol';

/**
 * @title MintableIncentivizedERC20
 *
 * @notice Implements mint and burn functions for IncentivizedERC20
 **/
abstract contract MintableIncentivizedERC20 is IncentivizedERC20 {
  /**
   * @dev Constructor.
   * @param pool The reference to the main Pool contract
   * @param name The name of the token
   * @param symbol The symbol of the token
   * @param decimals The number of decimals of the token
   */
  constructor(
    IL1Pool pool,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) IncentivizedERC20(pool, name, symbol, decimals) {
    // Intentionally left blank
  }

  /**
   * @notice Mints tokens to an account and apply incentives if defined
   * @param account The address receiving tokens
   * @param amount The amount of tokens to mint
   */
  function _mint(address account, uint128 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply + amount;

    uint128 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance + amount;

    IFintochIncentivesController incentivesControllerLocal = _incentivesController;
    if (address(incentivesControllerLocal) != address(0)) {
      incentivesControllerLocal.handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  /**
   * @notice Burns tokens from an account and apply incentives if defined
   * @param account The account whose tokens are burnt
   * @param amount The amount of tokens to burn
   */
  function _burn(address account, uint128 amount) internal virtual {
    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply - amount;

    uint128 oldAccountBalance = _userState[account].balance;
    _userState[account].balance = oldAccountBalance - amount;

    IFintochIncentivesController incentivesControllerLocal = _incentivesController;

    if (address(incentivesControllerLocal) != address(0)) {
      incentivesControllerLocal.handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

import {SafeCast} from '../../../dependencies/openzeppelin/contracts/SafeCast.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';
import {WadRayMath} from '../../libraries/math/WadRayMath.sol';
import {IL1Pool} from '../../../interfaces/IL1Pool.sol';
import {IScaledBalanceToken} from '../../../interfaces/IScaledBalanceToken.sol';
import {MintableIncentivizedERC20} from './MintableIncentivizedERC20.sol';

/**
 * @title ScaledBalanceTokenBase
 *
 * @notice Basic ERC20 implementation of scaled balance token
 **/
abstract contract ScaledBalanceTokenBase is MintableIncentivizedERC20, IScaledBalanceToken {
  using WadRayMath for uint256;
  using SafeCast for uint256;

  /**
   * @dev Constructor.
   * @param pool The reference to the main Pool contract
   * @param name The name of the token
   * @param symbol The symbol of the token
   * @param decimals The number of decimals of the token
   */
  constructor(
    IL1Pool pool,
    string memory name,
    string memory symbol,
    uint8 decimals
  ) MintableIncentivizedERC20(pool, name, symbol, decimals) {
    // Intentionally left blank
  }

  /// @inheritdoc IScaledBalanceToken
  function scaledBalanceOf(address user) external view override returns (uint256) {
    return super.balanceOf(user);
  }

  /// @inheritdoc IScaledBalanceToken
  function getScaledUserBalanceAndSupply(address user)
    external
    view
    override
    returns (uint256, uint256)
  {
    return (super.balanceOf(user), super.totalSupply());
  }

  /// @inheritdoc IScaledBalanceToken
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /// @inheritdoc IScaledBalanceToken
  function getPreviousIndex(address user) external view virtual override returns (uint256) {
    return _userState[user].additionalData;
  }

  /**
   * @notice Implements the basic logic to mint a scaled balance token.
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the scaled tokens
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   **/
  function _mintScaled(
    address caller,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) internal returns (bool) {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.INVALID_MINT_AMOUNT);

    uint256 scaledBalance = super.balanceOf(onBehalfOf);
    uint256 balanceIncrease = scaledBalance.rayMul(index) -
      scaledBalance.rayMul(_userState[onBehalfOf].additionalData);

    _userState[onBehalfOf].additionalData = index.toUint128();

    _mint(onBehalfOf, amountScaled.toUint128());

    uint256 amountToMint = amount + balanceIncrease;
    emit Transfer(address(0), onBehalfOf, amountToMint);
    emit Mint(caller, onBehalfOf, amountToMint, balanceIncrease, index);

    return (scaledBalance == 0);
  }

  /**
   * @notice Implements the basic logic to burn a scaled balance token.
   * @dev In some instances, a burn transaction will emit a mint event
   * if the amount to burn is less than the interest that the user accrued
   * @param user The user which debt is burnt
   * @param target The address that will receive the underlying, if any
   * @param amount The amount getting burned
   * @param index The variable debt index of the reserve
   **/
  function _burnScaled(
    address user,
    address target,
    uint256 amount,
    uint256 index
  ) internal {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.INVALID_BURN_AMOUNT);

    uint256 scaledBalance = super.balanceOf(user);
    uint256 balanceIncrease = scaledBalance.rayMul(index) -
      scaledBalance.rayMul(_userState[user].additionalData);

    _userState[user].additionalData = index.toUint128();

    _burn(user, amountScaled.toUint128());

    if (balanceIncrease > amount) {
      uint256 amountToMint = balanceIncrease - amount;
      emit Transfer(address(0), user, amountToMint);
      emit Mint(user, user, amountToMint, balanceIncrease, index);
    } else {
      uint256 amountToBurn = amount - balanceIncrease;
      emit Transfer(user, address(0), amountToBurn);
      emit Burn(user, target, amountToBurn, balanceIncrease, index);
    }
  }
}