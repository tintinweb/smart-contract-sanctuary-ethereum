/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

/**
 *Submitted for verification at Etherscan.io on 2020-01-08
*/

// File: contracts/Roles.sol

pragma solidity 0.5.12;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  /**
     * @dev Give an account access to this role.
     */
  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  /**
     * @dev Remove an account's access to this role.
     */
  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  /**
     * @dev Check if an account has this role.
     * @return bool
     */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

// File: contracts/Initializable.sol

pragma solidity 0.5.12;

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
    assembly {
      cs := extcodesize(address)
    } // solhint-disable-line
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private initializableGap;
}

// File: contracts/Context.sol

pragma solidity 0.5.12;


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
contract Context is Initializable {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor() internal {} // solhint-disable-line

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File: contracts/SafeMath.sol

pragma solidity 0.5.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
  function sub(uint256 a, uint256 b, string memory errorMessage)
    internal
    pure
    returns (uint256)
  {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
  function div(uint256 a, uint256 b, string memory errorMessage)
    internal
    pure
    returns (uint256)
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
  function mod(uint256 a, uint256 b, string memory errorMessage)
    internal
    pure
    returns (uint256)
  {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: contracts/IERC20.sol

pragma solidity 0.5.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
  function transferFrom(address sender, address recipient, uint256 amount)
    external
    returns (bool);

  /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ERC20.sol

pragma solidity 0.5.12;




/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool)
    {
        _transfer(from, to, value);
        _approve(
            from,
            _msgSender(),
            _allowances[from][_msgSender()].sub(value)
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount)
        internal
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    uint256[50] private erc20Gap;
}

// File: contracts/ERC20Detailed.sol

pragma solidity 0.5.12;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    uint256[50] private erc20DetailedGap;
}

// File: contracts/Ownable.sol

pragma solidity 0.5.12;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is ERC20Detailed {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
  function initialize(address sender) public initializer {
    _owner = sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
     * @dev Returns the address of the current owner.
     */
  function owner() external view returns (address) {
    return _owner;
  }

  /**
     * @dev Throws if called by any account other than the owner.
     */
  modifier onlyOwner() {
    require(isOwner(), 'Ownable: caller is not the owner');
    _;
  }

  /**
     * @dev Returns true if the caller is the current owner.
     */
  function isOwner() public view returns (bool) {
    return _msgSender() == _owner;
  }

  /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
  function transferOwnership(address newOwner) external onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  uint256[50] private ownableGap;
}

// File: contracts/Pausable.sol

pragma solidity 0.5.12;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Ownable {
  /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
  event Paused(address account);

  /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
  event Unpaused(address account);

  bool private _paused;

  /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
  function initialize() public initializer {
    _paused = false;
  }

  /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
  function paused() external view returns (bool) {
    return _paused;
  }

  /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
  modifier whenNotPaused() {
    require(!_paused, 'Pausable: paused');
    _;
  }

  /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
  modifier whenPaused() {
    require(_paused, 'Pausable: not paused');
    _;
  }

  /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
  function pause() external onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(_msgSender());
  }

  /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
  function unpause() external onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(_msgSender());
  }

  uint256[50] private pausableGap;
}

// File: contracts/AdminRole.sol

pragma solidity 0.5.12;



contract AdminRole is Pausable {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  modifier onlyAdmin() {
    require(
      isAdmin(_msgSender()),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins.has(account);
  }

  // adding an admin should be possible any time
  function addAdmin(address account) external onlyOwner {
    _addAdmin(account);
  }

  // removing an admin should be possible any time
  function removeAdmin(address account) external onlyOwner {
    _removeAdmin(account);
  }

  // renouncing admin role should be possible any time
  function renounceAdmin() external {
    _removeAdmin(_msgSender());
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    emit AdminRemoved(account);
  }

  uint256[50] private adminRoleGap;
}

// File: contracts/StateManager.sol

pragma solidity 0.5.12;


contract StateManager is AdminRole {
  event WhitelistedAdded(address indexed account);
  event WhitelistedRemoved(address indexed account);

  event BlockedAdded(address indexed account);
  event BlockedRemoved(address indexed account);

  event BlacklistedAdded(address indexed account);

  enum States { None, Whitelisted, Blacklisted, Blocked }
  mapping(address => uint256) internal addressState;

  modifier notBlocked() {
    require(!isBlocked(_msgSender()), "Blocked: caller is not blocked ");
    _;
  }
  modifier notBlacklisted() {
    require(
      !isBlacklisted(_msgSender()),
      "Blacklisted: caller is not blacklisted"
    );
    _;
  }

  function isWhitelisted(address account) public view returns (bool) {
    return addressState[account] == uint256(States.Whitelisted);
  }

  function isBlocked(address account) public view returns (bool) {
    return addressState[account] == uint256(States.Blocked);
  }

  function isBlacklisted(address account) public view returns (bool) {
    return addressState[account] == uint256(States.Blacklisted);
  }

  function addWhitelisted(address account) external onlyAdmin whenNotPaused {
    require(!isWhitelisted(account), "Whitelisted: already whitelisted");
    require(!isBlocked(account), "Whitelisted: cannot add Blocked accounts");
    require(
      !isBlacklisted(account),
      "Whitelisted: cannot add Blacklisted accounts"
    );
    _addWhitelisted(account);
  }

  function addBlocked(address account) external onlyAdmin {
    require(!isBlocked(account), "Blocked: already blocked");
    require(
      !isBlacklisted(account),
      "Blocked: cannot add Blacklisted accounts"
    );
    _addBlocked(account);
  }

  function addBlacklisted(address account) external onlyAdmin {
    require(!isBlacklisted(account), "Blacklisted: already Blacklisted");
    _addBlacklisted(account);
  }

  function removeWhitelisted(address account) external onlyAdmin whenNotPaused {
    _removeWhitelisted(account);
  }

  function removeBlocked(address account) external onlyAdmin whenNotPaused {
    _removeBlocked(account);
  }

  function renounceWhitelisted() external whenNotPaused {
    _removeWhitelisted(_msgSender());
  }

  function _addWhitelisted(address account) internal {
    addressState[account] = uint256(States.Whitelisted);
    emit WhitelistedAdded(account);
  }
  function _addBlocked(address account) internal {
    addressState[account] = uint256(States.Blocked);
    emit BlockedAdded(account);
  }

  function _addBlacklisted(address account) internal {
    addressState[account] = uint256(States.Blacklisted);
    emit BlacklistedAdded(account);
  }

  function _removeWhitelisted(address account) internal {
    delete addressState[account];
    emit WhitelistedRemoved(account);
  }

  function _removeBlocked(address account) internal {
    delete addressState[account];
    emit BlockedRemoved(account);
  }

  uint256[50] private stateManagerGap;
}

// File: contracts/ERC20Pausable.sol

pragma solidity 0.5.12;


/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 */
contract ERC20Pausable is StateManager {
    function transfer(address to, uint256 value)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(to), "Cannot send to Blacklisted Address");
        require(!isBlocked(to), "Cannot send to blocked Address");
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(to), "Cannot send to Blacklisted Address");
        require(!isBlocked(to), "Cannot send to blocked Address");
        require(!isBlacklisted(from), "Cannot send from Blacklisted Address");
        require(!isBlocked(from), "Cannot send from blocked Address");
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(spender), "Cannot send to Blacklisted Address");
        require(!isBlocked(spender), "Cannot send to blocked Address");
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(spender), "Cannot send to Blacklisted Address");
        require(!isBlocked(spender), "Cannot send to blocked Address");
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotPaused
        notBlacklisted
        notBlocked
        returns (bool)
    {
        require(!isBlacklisted(spender), "Cannot send to Blacklisted Address");
        require(!isBlocked(spender), "Cannot send to blocked Address");
        return super.decreaseAllowance(spender, subtractedValue);
    }

    uint256[50] private erc20PausableGap;
}

// File: contracts/QCAD.sol

pragma solidity 0.5.12;


contract QCAD is ERC20Pausable {
  function initialize(
    string calldata name,
    string calldata symbol,
    uint8 decimals,
    address[] calldata admins
  ) external initializer {
    ERC20Detailed.initialize(name, symbol, decimals);
    Ownable.initialize(_msgSender());
    Pausable.initialize();

    for (uint256 i = 0; i < admins.length; ++i) {
      _addAdmin(admins[i]);
    }
  }

  function mint(address account, uint256 amount)
    external
    onlyAdmin
    whenNotPaused
    returns (bool)
  {
    require(isWhitelisted(account), "minting to non-whitelisted address");
    _mint(account, amount);
    return true;
  }

  function burn(uint256 amount)
    external
    onlyAdmin
    whenNotPaused
    returns (bool)
  {
    _burn(address(this), amount);
    return true;
  }
}