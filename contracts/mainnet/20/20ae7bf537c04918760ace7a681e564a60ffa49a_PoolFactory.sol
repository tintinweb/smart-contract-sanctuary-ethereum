// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./libraries/StrConcat.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IDeployer01.sol";
import "./SystemSettings.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract PoolFactory is IPoolFactory, SystemSettings {
    mapping(address => mapping(address => mapping(bool => address))) public override pools;

    address private _uniFactoryV3;
    address private _uniFactoryV2;
    address private _sushiFactory;
    address private _deployer01;

    constructor(address uniFactoryV3,
        address uniFactoryV2,
        address sushiFactory,
        address deployer01,
        address deployer02) SystemSettings(deployer02) {
        _uniFactoryV3 = uniFactoryV3;
        _uniFactoryV2 = uniFactoryV2;
        _sushiFactory = sushiFactory;
        _deployer01 = deployer01;
    }

    function createPoolFromUni(address tradeToken, address poolToken, uint24 fee, bool reverse) external override {
        address uniPool;
        uint8 oracle;

        if (fee == 0) {
            IUniswapV2Factory uniswap = IUniswapV2Factory(_uniFactoryV2);
            uniPool = uniswap.getPair(tradeToken, poolToken);
            oracle = 1;
        } else {
            IUniswapV3Factory uniswap = IUniswapV3Factory(_uniFactoryV3);
            uniPool = uniswap.getPool(tradeToken, poolToken, fee);
            oracle = 0;
        }

        require(uniPool != address(0), "trade pair not found in uni swap");
        require(pools[poolToken][uniPool][reverse] == address(0), "pool already exists");

        string memory tradePair = StrConcat.strConcat(ERC20(tradeToken).symbol(), ERC20(poolToken).symbol());
        (address pool, address debt) = IDeployer01(_deployer01).deploy(poolToken, uniPool, address(this), tradePair, reverse, oracle);
        pools[poolToken][uniPool][reverse] = pool;

        emit CreatePoolFromUni(tradeToken, poolToken, uniPool, pool, debt, tradePair, fee, reverse);
    }

    function createPoolFromSushi(address tradeToken, address poolToken, bool reverse) external override {
        IUniswapV2Factory sushi = IUniswapV2Factory(_sushiFactory);
        address sushiPool = sushi.getPair(tradeToken, poolToken);

        require(sushiPool != address(0), "trade pair not found in sushi swap");
        require(pools[poolToken][sushiPool][reverse] == address(0), "pool already exists");

        string memory tradePair = StrConcat.strConcat(ERC20(tradeToken).symbol(), ERC20(poolToken).symbol());
        (address pool, address debt) = IDeployer01(_deployer01).deploy(poolToken, sushiPool, address(this), tradePair, reverse, 2);
        pools[poolToken][sushiPool][reverse] = pool;

        emit CreatePoolFromSushi(tradeToken, poolToken, sushiPool, pool, debt, tradePair, reverse);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
    function _setupDecimals(uint8 decimals_) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

library StrConcat {

    function strConcat(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        string memory ret = new string(ba.length + bb.length + 1);
        bytes memory bret = bytes(ret);

        uint k = 0;
        for (uint i = 0; i < ba.length; i++) {
            bret[k++] = ba[i];
        }
        bret[k++] = byte('-');
        for (uint i = 0; i < bb.length; i++) {
            bret[k++] = bb[i];
        }

        return string(bret);
    }

    function strConcat2(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        string memory ret = new string(ba.length + bb.length);
        bytes memory bret = bytes(ret);

        uint k = 0;
        for (uint i = 0; i < ba.length; i++) {
            bret[k++] = ba[i];
        }
        for (uint i = 0; i < bb.length; i++) {
            bret[k++] = bb[i];
        }

        return string(bret);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library BasicMaths {
    /**
     * @dev Returns the abs of substraction of two unsigned integers
     *
     * _Available since v3.4._
     */
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            return b - a;
        }
    }

    /**
     * @dev Returns a - b if a > b, else return 0
     *
     * _Available since v3.4._
     */
    function sub2Zero(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        } else {
            return 0;
        }
    }

    /**
     * @dev if isSub then Returns a - b, else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            return SafeMath.sub(a, b);
        }
    }

    /**
     * @dev if isSub then Returns sub2Zero(a, b), else return a + b
     *
     * _Available since v3.4._
     */
    function addOrSub2Zero(bool isAdd, uint256 a, uint256 b) internal pure returns (uint256) {
        if (isAdd) {
            return SafeMath.add(a, b);
        } else {
            if (a > b) {
                return a - b;
            } else {
                return 0;
            }
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1 ) / 2;
        uint256 y = x;
        while(z < y){
            y = z;
            z = ( x / z + z ) / 2;
        }
        return y;
    }

    function pow(uint256 x) internal pure returns (uint256) {
        return SafeMath.mul(x, x);
    }

    function diff2(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a >= b) {
            return (true, a - b);
        } else {
            return (false, b - a);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface ISystemSettings {
    struct PoolSetting {
        address owner;
        uint256 marginRatio;
        uint256 closingFee;
        uint256 liqFeeBase;
        uint256 liqFeeMax;
        uint256 liqFeeCoefficient;
        uint256 liqLsRequire;
        uint256 rebaseCoefficient;
        uint256 imbalanceThreshold;
        uint256 priceDeviationCoefficient;
        uint256 minHoldingPeriod;
        uint256 debtStart;
        uint256 debtAll;
        uint256 minDebtRepay;
        uint256 maxDebtRepay;
        uint256 interestRate;
        uint256 liquidityCoefficient;
        bool deviation;
    }

    function official() external view returns (address);

    function deployer02() external view returns (address);

    function leverages(uint32) external view returns (bool);

    function protocolFee() external view returns (uint256);

    function liqProtocolFee() external view returns (uint256);

    function marginRatio() external view returns (uint256);

    function closingFee() external view returns (uint256);

    function liqFeeBase() external view returns (uint256);

    function liqFeeMax() external view returns (uint256);

    function liqFeeCoefficient() external view returns (uint256);

    function liqLsRequire() external view returns (uint256);

    function rebaseCoefficient() external view returns (uint256);

    function imbalanceThreshold() external view returns (uint256);

    function priceDeviationCoefficient() external view returns (uint256);

    function minHoldingPeriod() external view returns (uint256);

    function debtStart() external view returns (uint256);

    function debtAll() external view returns (uint256);

    function minDebtRepay() external view returns (uint256);

    function maxDebtRepay() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function liquidityCoefficient() external view returns (uint256);

    function deviation() external view returns (bool);

    function checkOpenPosition(uint16 level) external view;

    function requireSystemActive() external view;

    function requireSystemSuspend() external view;

    function resumeSystem() external;

    function suspendSystem() external;

    function mulClosingFee(uint256 value) external view returns (uint256);

    function mulLiquidationFee(uint256 margin, uint256 deltaBlock) external view returns (uint256);

    function mulMarginRatio(uint256 margin) external view returns (uint256);

    function mulProtocolFee(uint256 amount) external view returns (uint256);

    function mulLiqProtocolFee(uint256 amount) external view returns (uint256);

    function meetImbalanceThreshold(
        uint256 nakedPosition,
        uint256 liquidityPool
    ) external view returns (bool);

    function mulImbalanceThreshold(uint256 liquidityPool)
        external
        view
        returns (uint256);

    function calDeviation(uint256 nakedPosition, uint256 liquidityPool)
        external
        view
        returns (uint256);

    function calRebaseDelta(
        uint256 rebaseSizeXBlockDelta,
        uint256 imbalanceSize
    ) external view returns (uint256);

    function calDebtRepay(
        uint256 lsPnl,
        uint256 totalDebt,
        uint256 totalLiquidity
    ) external view returns (uint256);

    function calDebtIssue(
        uint256 tdPnl,
        uint256 lsAvgPrice,
        uint256 lsPrice
    ) external view returns (uint256);

    function mulInterestFromDebt(
        uint256 amount
    ) external view returns (uint256);

    function divInterestFromDebt(
        uint256 amount
    ) external view returns (uint256);

    function mulLiquidityCoefficient(
        uint256 nakedPositions
    ) external view returns (uint256);

    enum systemParam {
        MarginRatio,
        ProtocolFee,
        LiqProtocolFee,
        ClosingFee,
        LiqFeeBase,
        LiqFeeMax,
        LiqFeeCoefficient,
        LiqLsRequire,
        RebaseCoefficient,
        ImbalanceThreshold,
        PriceDeviationCoefficient,
        MinHoldingPeriod,
        DebtStart,
        DebtAll,
        MinDebtRepay,
        MaxDebtRepay,
        InterestRate,
        LiquidityCoefficient,
        Other
    }

    event AddLeverage(uint32 leverage);
    event DeleteLeverage(uint32 leverage);

    event SetSystemParam(systemParam param, uint256 value);
    event SetDeviation(bool deviation);

    event SetPoolOwner(address pool, address owner);
    event SetPoolParam(address pool, systemParam param, uint256 value);
    event SetPoolDeviation(address pool, bool deviation);

    event Suspend(address indexed sender);
    event Resume(address indexed sender);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IPoolFactory {
    function createPoolFromUni(address tradeToken, address poolToken, uint24 fee, bool reverse) external;

    function createPoolFromSushi(address tradeToken, address poolToken, bool reverse) external;

    function pools(address poolToken, address oraclePool, bool reverse) external view returns (address pool);

    event CreatePoolFromUni(
        address tradeToken,
        address poolToken,
        address uniPool,
        address pool,
        address debt,
        string tradePair,
        uint24 fee,
        bool reverse);

    event CreatePoolFromSushi(
        address tradeToken,
        address poolToken,
        address sushiPool,
        address pool,
        address debt,
        string tradePair,
        bool reverse);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IPool {
    struct Position {
        uint256 openPrice;
        uint256 openBlock;
        uint256 margin;
        uint256 size;
        uint256 openRebase;
        address account;
        uint8 direction;
    }

    function _positions(uint32 positionId)
        external
        view
        returns (
            uint256 openPrice,
            uint256 openBlock,
            uint256 margin,
            uint256 size,
            uint256 openRebase,
            address account,
            uint8 direction
        );

    function debtToken() external view returns (address);

    function lsTokenPrice() external view returns (uint256);

    function addLiquidity(address user, uint256 amount) external;

    function removeLiquidity(address user, uint256 lsAmount, uint256 bondsAmount, address receipt) external;

    function openPosition(
        address user,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external returns (uint32);

    function addMargin(
        address user,
        uint32 positionId,
        uint256 margin
    ) external;

    function closePosition(
        address receipt,
        uint32 positionId
    ) external;

    function liquidate(
        address user,
        uint32 positionId,
        address receipt
    ) external;

    function exit(
        address receipt,
        uint32 positionId
    ) external;

    event MintLiquidity(uint256 amount);

    event AddLiquidity(
        address indexed sender,
        uint256 amount,
        uint256 lsAmount,
        uint256 bonds
    );

    event RemoveLiquidity(
        address indexed sender,
        uint256 amount,
        uint256 lsAmount,
        uint256 bondsRequired
    );

    event OpenPosition(
        address indexed sender,
        uint256 openPrice,
        uint256 openRebase,
        uint8 direction,
        uint16 level,
        uint256 margin,
        uint256 size,
        uint32 positionId
    );

    event AddMargin(
        address indexed sender,
        uint256 margin,
        uint32 positionId
    );

    event ClosePosition(
        address indexed receipt,
        uint256 closePrice,
        uint256 serviceFee,
        uint256 fundingFee,
        uint256 pnl,
        uint32  positionId,
        bool isProfit,
        int256 debtChange
    );

    event Liquidate(
        address indexed sender,
        uint32 positionID,
        uint256 liqPrice,
        uint256 serviceFee,
        uint256 fundingFee,
        uint256 liqReward,
        uint256 pnl,
        bool isProfit,
        uint256 debtRepay
    );

    event Rebase(uint256 rebaseAccumulatedLong, uint256 rebaseAccumulatedShort);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IDeployer01 {
    function deploy(
        address poolToken,
        address uniPool,
        address setting,
        string memory tradePair,
        bool reverse,
        uint8 oracle) external returns (address, address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./libraries/BasicMaths.sol";
import "./interfaces/ISystemSettings.sol";
import "./interfaces/IPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract SystemSettings is ISystemSettings, Ownable {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using BasicMaths for bool;

    mapping(address => PoolSetting) private _poolSettings;
    mapping(address => uint256) private _debtSettings;
    mapping(uint32 => bool) public override leverages;
    uint256 public override marginRatio;
    uint256 public override protocolFee;
    uint256 public override liqProtocolFee;
    uint256 public override closingFee;
    uint256 public override liqFeeBase;
    uint256 public override liqFeeMax;
    uint256 public override liqFeeCoefficient;
    uint256 public override rebaseCoefficient;
    uint256 public override imbalanceThreshold;
    uint256 public override priceDeviationCoefficient;
    uint256 public override debtStart;
    uint256 public override debtAll;
    uint256 public override minDebtRepay;
    uint256 public override maxDebtRepay;
    uint256 public override interestRate;
    uint256 public override liquidityCoefficient;

    uint256 private _liqLsRequire;
    uint256 private _minHoldingPeriod;
    bool    private _deviation;

    uint256 private constant E4 = 1e4;
    uint256 private constant E18 = 1e18;
    uint256 private constant E38 = 1e38;

    bool private _active;
    address private _official;
    address private _suspender;
    address private _deployer02;

    constructor(address deployer02) {
        _official = msg.sender;
        _suspender = msg.sender;
        _deployer02 = deployer02;
    }

    function official() external view override returns (address) {
        return _official;
    }

    function deployer02() external view override returns (address) {
        return _deployer02;
    }

    function requireSystemActive() external view override {
        require(_active, "system is suspended");
    }

    function requireSystemSuspend() external view override {
        require(!_active, "system is active");
    }

    function resumeSystem() external override onlySuspender {
        _active = true;
        emit Resume(msg.sender);
    }

    function suspendSystem() external override onlySuspender {
        _active = false;
        emit Suspend(msg.sender);
    }

    function liqLsRequire() external view override returns (uint256) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return _liqLsRequire;
        } else {
            return poolSetting.liqLsRequire;
        }
    }

    function minHoldingPeriod() external view override returns (uint256) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return _minHoldingPeriod;
        } else {
            return poolSetting.minHoldingPeriod;
        }
    }

    function deviation() external view override returns (bool) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return _deviation;
        } else {
            return poolSetting.deviation;
        }
    }

    function checkOpenPosition(uint16 level) external view override {
        require(_active, "system is suspended");
        require(leverages[level], "Non-Exist Leverage");
    }

    function mulClosingFee(uint256 value)
        external
        view
        override
        returns (uint256)
    {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return closingFee.mul(value) / E4;
        } else {
            return poolSetting.closingFee.mul(value) / E4;
        }
    }

    function mulLiquidationFee(uint256 margin, uint256 deltaBlock)
        external
        view
        override
        returns (uint256)
    {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];

        uint256 liqRatio;
        if (poolSetting.owner == address(0)) {
            if (liqFeeBase == liqFeeMax) {
                return liqFeeBase.mul(margin) / E4;
            }

            liqRatio = deltaBlock.mul(liqFeeMax.sub(liqFeeBase)) / liqFeeCoefficient + liqFeeBase;
            if (liqRatio < liqFeeMax) {
                return liqRatio.mul(margin) / E4;
            } else {
                return liqFeeMax.mul(margin) / E4;
            }
        } else {
            if (poolSetting.liqFeeBase == poolSetting.liqFeeMax) {
                return poolSetting.liqFeeBase.mul(margin) / E4;
            }

            liqRatio = deltaBlock.mul(poolSetting.liqFeeMax.sub(poolSetting.liqFeeBase)) / poolSetting.liqFeeCoefficient + poolSetting.liqFeeBase;
            if (liqRatio < poolSetting.liqFeeMax) {
                return liqRatio.mul(margin) / E4;
            } else {
                return poolSetting.liqFeeMax.mul(margin) / E4;
            }
        }
    }

    function mulMarginRatio(uint256 margin)
        external
        view
        override
        returns (uint256)
    {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return marginRatio.mul(margin) / E4;
        } else {
            return poolSetting.marginRatio.mul(margin) / E4;
        }
    }

    function mulProtocolFee(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        return protocolFee.mul(amount) / E4;
    }

    function mulLiqProtocolFee(uint256 amount)
        external
        view
        override
        returns (uint256)
    {
        return liqProtocolFee.mul(amount) / E4;
    }

    function meetImbalanceThreshold(
        uint256 nakedPosition,
        uint256 liquidityPool
    ) external view override returns (bool) {
        uint256 D = (nakedPosition).mul(E4) / liquidityPool;

        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return D > imbalanceThreshold;
        } else {
            return D > poolSetting.imbalanceThreshold;
        }
    }

    function mulImbalanceThreshold(uint256 liquidityPool)
        external
        view
        override
        returns (uint256)
    {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return liquidityPool.mul(imbalanceThreshold) / E4;
        } else {
            return liquidityPool.mul(poolSetting.imbalanceThreshold) / E4;
        }
    }

    function calRebaseDelta(
        uint256 rebaseSizeXBlockDelta,
        uint256 imbalanceSize
    ) external view override returns (uint256) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return rebaseSizeXBlockDelta.mul(E18).div(rebaseCoefficient).div(imbalanceSize);
        } else {
            return rebaseSizeXBlockDelta.mul(E18).div(poolSetting.rebaseCoefficient).div(imbalanceSize);
        }
    }

    function calDeviation(uint256 nakedPosition, uint256 liquidityPool)
        external
        view
        override
        returns (uint256)
    {
        uint256 D = nakedPosition.mul(E18) / liquidityPool;
        require(D < E38, "Maximum deviation is 100%");

        uint256 deviationResult;
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            deviationResult = (D.pow() / E18).mul(
                priceDeviationCoefficient
            ) / E4;
        } else {
            deviationResult = (D.pow() / E18).mul(
                poolSetting.priceDeviationCoefficient
            ) / E4;
        }

        // Maximum deviation is 1e18
        require(deviationResult < E18, "Maximum deviation is 100%");
        return deviationResult;
    }

    function calDebtRepay(
        uint256 lsPnl,
        uint256 totalDebtWithInterest,
        uint256 totalLiquidity
    ) external view override returns (uint256 repay) {

        uint256 minRepay;
        uint256 maxRepay;
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            minRepay = lsPnl.mul(minDebtRepay) / E4;
            maxRepay = lsPnl.mul(maxDebtRepay) / E4;
        } else {
            minRepay = lsPnl.mul(poolSetting.minDebtRepay) / E4;
            maxRepay = lsPnl.mul(poolSetting.maxDebtRepay) / E4;
        }

        repay = totalDebtWithInterest.pow().mul(lsPnl) / totalLiquidity.pow();

        if (repay < minRepay) {
            repay = minRepay;
        }

        if (repay > maxRepay) {
            repay = maxRepay;
        }

        if (repay > totalDebtWithInterest) {
            repay = totalDebtWithInterest;
        }

        return repay;
    }

    function calDebtIssue(
        uint256 tdPnl,
        uint256 lsAvgPrice,
        uint256 lsPrice
    ) external view override returns (uint256) {

        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            if (lsPrice.mul(E4) >= lsAvgPrice.mul(debtStart)) {
                return 0;
            }

            if (lsPrice.mul(E4) <= lsAvgPrice.mul(debtAll)) {
                return tdPnl;
            }
        } else {
            if (lsPrice.mul(E4) >= lsAvgPrice.mul(poolSetting.debtStart)) {
                return 0;
            }

            if (lsPrice.mul(E4) <= lsAvgPrice.mul(poolSetting.debtAll)) {
                return tdPnl;
            }
        }

        return lsAvgPrice.sub(lsPrice).pow().mul(tdPnl) / lsAvgPrice.pow();
    }

    function mulInterestFromDebt(
        uint256 amount
    ) external view override returns (uint256) {
        uint256 interestRateFromDebt = _debtSettings[msg.sender];
        if (interestRateFromDebt == 0) {
            return amount.mul(interestRate) / E4;
        } else {
            return amount.mul(interestRateFromDebt) / E4;
        }
    }

    function divInterestFromDebt(
        uint256 amount
    ) external view override returns (uint256) {
        uint256 interestRateFromDebt = _debtSettings[msg.sender];
        if (interestRateFromDebt == 0) {
            return amount.mul(E4) / interestRate;
        } else {
            return amount.mul(E4) / interestRateFromDebt;
        }
    }

    function mulLiquidityCoefficient(
        uint256 nakedPositions
    ) external view override returns (uint256) {
        PoolSetting memory poolSetting = _poolSettings[msg.sender];
        if (poolSetting.owner == address(0)) {
            return nakedPositions.mul(E4).div(liquidityCoefficient);
        } else {
            return nakedPositions.mul(E4).div(poolSetting.liquidityCoefficient);
        }
    }

    /*--------------------------------------------------------------------------------------------------*/

    function setProtocolFee(uint256 protocolFee_) external onlyOwner {
        require(protocolFee_ <= E4, "over range");
        protocolFee = protocolFee_;
        emit SetSystemParam(systemParam.ProtocolFee, protocolFee_);
    }

    function setLiqProtocolFee(uint256 liqProtocolFee_) external onlyOwner {
        require(liqProtocolFee_ <= E4, "over range");
        liqProtocolFee = liqProtocolFee_;
        emit SetSystemParam(systemParam.LiqProtocolFee, liqProtocolFee_);
    }

    function setMarginRatio(uint256 marginRatio_) external onlyOwner {
        require(marginRatio_ <= E4, "over range");
        marginRatio = marginRatio_;
        emit SetSystemParam(systemParam.MarginRatio, marginRatio_);
    }

    function setClosingFee(uint256 closingFee_) external onlyOwner {
        require(closingFee_ <= 1e2, "over range");
        closingFee = closingFee_;
        emit SetSystemParam(systemParam.ClosingFee, closingFee_);
    }

    function setLiqFeeBase(uint256 liqFeeBase_) external onlyOwner {
        require(liqFeeBase_ <= E4, "over range");
        require(liqFeeMax > liqFeeBase_, "liqFeeMax must > liqFeeBase");
        liqFeeBase = liqFeeBase_;
        emit SetSystemParam(systemParam.LiqFeeBase, liqFeeBase_);
    }

    function setLiqFeeMax(uint256 liqFeeMax_) external onlyOwner {
        require(liqFeeMax_ <= E4, "over range");
        require(liqFeeMax_ > liqFeeBase, "liqFeeMax must > liqFeeBase");
        liqFeeMax = liqFeeMax_;
        emit SetSystemParam(systemParam.LiqFeeMax, liqFeeMax_);
    }

    function setLiqFeeCoefficient(uint256 liqFeeCoefficient_) external onlyOwner {
        require(liqFeeCoefficient_ > 0 && liqFeeCoefficient_ <= 576000, "over range");
        liqFeeCoefficient = liqFeeCoefficient_;
        emit SetSystemParam(systemParam.LiqFeeCoefficient, liqFeeCoefficient_);
    }

    function setLiqLsRequire(uint256 liqLsRequire_) external onlyOwner {
        _liqLsRequire = liqLsRequire_;
        emit SetSystemParam(systemParam.LiqLsRequire, liqLsRequire_);
    }

    function addLeverage(uint32 leverage_) external onlyOwner {
        leverages[leverage_] = true;
        emit AddLeverage(leverage_);
    }

    function deleteLeverage(uint32 leverage_) external onlyOwner {
        leverages[leverage_] = false;
        emit DeleteLeverage(leverage_);
    }

    function setRebaseCoefficient(uint256 rebaseCoefficient_)
        external
        onlyOwner
    {
        require(rebaseCoefficient_ > 0 && rebaseCoefficient_ <= 5760000, "over range");
        rebaseCoefficient = rebaseCoefficient_;
        emit SetSystemParam(systemParam.RebaseCoefficient, rebaseCoefficient_);
    }

    function setImbalanceThreshold(uint256 imbalanceThreshold_)
        external
        onlyOwner
    {
        require(imbalanceThreshold_ <= 1e6, "over range");
        imbalanceThreshold = imbalanceThreshold_;
        emit SetSystemParam(
            systemParam.ImbalanceThreshold,
            imbalanceThreshold_
        );
    }

    function setPriceDeviationCoefficient(uint256 priceDeviationCoefficient_)
        external
        onlyOwner
    {
        require(priceDeviationCoefficient_ <= 1e6, "over range");
        priceDeviationCoefficient = priceDeviationCoefficient_;
        emit SetSystemParam(
            systemParam.PriceDeviationCoefficient,
            priceDeviationCoefficient_
        );
    }

    function setMinHoldingPeriod(uint256 minHoldingPeriod_)
        external
        onlyOwner
    {
        require(minHoldingPeriod_ <= 5760, "over range");
        _minHoldingPeriod = minHoldingPeriod_;
        emit SetSystemParam(
            systemParam.MinHoldingPeriod,
            minHoldingPeriod_
        );
    }

    function setDebtStart(uint256 debtStart_)
        external
        onlyOwner
    {
        require(debtStart_ <= E4, "over range");
        debtStart = debtStart_;
        emit SetSystemParam(
            systemParam.DebtStart,
            debtStart_
        );
    }

    function setDebtAll(uint256 debtAll_)
        external
        onlyOwner
    {
        require(debtAll_ <= E4, "over range");
        debtAll = debtAll_;
        emit SetSystemParam(
            systemParam.DebtAll,
            debtAll_
        );
    }

    function setMinDebtRepay(uint256 minDebtRepay_)
        external
        onlyOwner
    {
        require(minDebtRepay_ <= E4, "over range");
        minDebtRepay = minDebtRepay_;
        emit SetSystemParam(
            systemParam.MinDebtRepay,
            minDebtRepay_
        );
    }

    function setMaxDebtRepay(uint256 maxDebtRepay_)
        external
        onlyOwner
    {
        require(maxDebtRepay_ <= E4, "over range");
        maxDebtRepay = maxDebtRepay_;
        emit SetSystemParam(
            systemParam.MaxDebtRepay,
            maxDebtRepay_
        );
    }

    function setInterestRate(uint256 interestRate_)
        external
        onlyOwner
    {
        require(interestRate_ >= E4 && interestRate_ <= 2*E4, "over range");
        interestRate = interestRate_;
        emit SetSystemParam(
            systemParam.InterestRate,
            interestRate_
        );
    }

    function setLiquidityCoefficient(uint256 liquidityCoefficient_)
        external
        onlyOwner
    {
        require(liquidityCoefficient_ > 0 && liquidityCoefficient_ <= 1e6, "over range");
        liquidityCoefficient = liquidityCoefficient_;
        emit SetSystemParam(
            systemParam.LiquidityCoefficient,
            liquidityCoefficient_
        );
    }

    function setDeviation(bool deviation_) external onlyOwner {
        _deviation = deviation_;
        emit SetDeviation(_deviation);
    }

    /*--------------------------------------------------------------------------------------------------*/

    function setMarginRatioByPool(address pool, uint256 marginRatio_) external onlyPoolOwner(pool) {
        require(marginRatio_ <= E4, "over range");
        _poolSettings[pool].marginRatio = marginRatio_;
        emit SetPoolParam(pool, systemParam.MarginRatio, marginRatio_);
    }

    function setClosingFeeByPool(address pool, uint256 closingFee_) external onlyPoolOwner(pool) {
        require(closingFee_ <= E4, "over range");
        _poolSettings[pool].closingFee = closingFee_;
        emit SetPoolParam(pool, systemParam.ClosingFee, closingFee_);
    }

    function setLiqFeeBaseByPool(address pool, uint256 liqFeeBase_) external onlyPoolOwner(pool) {
        require(liqFeeBase_ <= E4, "over range");
        require(_poolSettings[pool].liqFeeMax > liqFeeBase_, "liqFeeMax must > liqFeeBase");
        _poolSettings[pool].liqFeeBase = liqFeeBase_;
        emit SetPoolParam(pool, systemParam.LiqFeeBase, liqFeeBase_);
    }

    function setLiqFeeMaxByPool(address pool, uint256 liqFeeMax_) external onlyPoolOwner(pool) {
        require(liqFeeMax_ <= E4, "over range");
        require(liqFeeMax_ > _poolSettings[pool].liqFeeBase, "liqFeeMax must > liqFeeBase");
        _poolSettings[pool].liqFeeMax = liqFeeMax_;
        emit SetPoolParam(pool, systemParam.LiqFeeMax, liqFeeMax_);
    }

    function setLiqFeeCoefficientByPool(address pool, uint256 liqFeeCoefficient_) external onlyPoolOwner(pool) {
        require(liqFeeCoefficient_ > 0 && liqFeeCoefficient_ <= 576000, "over range");
        _poolSettings[pool].liqFeeCoefficient = liqFeeCoefficient_;
        emit SetPoolParam(pool, systemParam.LiqFeeCoefficient, liqFeeCoefficient_);
    }

    function setLiqLsRequireByPool(address pool, uint256 liqLsRequire_) external onlyPoolOwner(pool) {
        _poolSettings[pool].liqLsRequire = liqLsRequire_;
        emit SetPoolParam(pool, systemParam.LiqLsRequire, liqLsRequire_);
    }

    function setRebaseCoefficientByPool(address pool, uint256 rebaseCoefficient_) external onlyPoolOwner(pool) {
        require(rebaseCoefficient_ > 0 && rebaseCoefficient_ <= 5760000, "over range");
        _poolSettings[pool].rebaseCoefficient = rebaseCoefficient_;
        emit SetPoolParam(pool, systemParam.RebaseCoefficient, rebaseCoefficient_);
    }

    function setImbalanceThresholdByPool(address pool, uint256 imbalanceThreshold_) external onlyPoolOwner(pool) {
        require(imbalanceThreshold_ <= 1e6, "over range");
        _poolSettings[pool].imbalanceThreshold = imbalanceThreshold_;
        emit SetPoolParam(pool, systemParam.ImbalanceThreshold, imbalanceThreshold_);
    }

    function setPriceDeviationCoefficientByPool(address pool, uint256 priceDeviationCoefficient_) external onlyPoolOwner(pool) {
        require(priceDeviationCoefficient_ <= 1e6, "over range");
        _poolSettings[pool].priceDeviationCoefficient = priceDeviationCoefficient_;
        emit SetPoolParam(pool, systemParam.PriceDeviationCoefficient, priceDeviationCoefficient_);
    }

    function setMinHoldingPeriodByPool(address pool, uint256 minHoldingPeriod_) external onlyPoolOwner(pool) {
        require(minHoldingPeriod_ <= 5760, "over range");
        _poolSettings[pool].minHoldingPeriod = minHoldingPeriod_;
        emit SetPoolParam(pool, systemParam.MinHoldingPeriod, minHoldingPeriod_);
    }

    function setDebtStartByPool(address pool, uint256 debtStart_) external onlyPoolOwner(pool) {
        require(debtStart_ <= E4, "over range");
        _poolSettings[pool].debtStart = debtStart_;
        emit SetPoolParam(pool, systemParam.DebtStart, debtStart_);
    }

    function setDebtAllByPool(address pool, uint256 debtAll_) external onlyPoolOwner(pool) {
        require(debtAll_ <= E4, "over range");
        _poolSettings[pool].debtAll = debtAll_;
        emit SetPoolParam(pool, systemParam.DebtAll, debtAll_);
    }

    function setMinDebtRepayByPool(address pool, uint256 minDebtRepay_) external onlyPoolOwner(pool) {
        require(minDebtRepay_ <= E4, "over range");
        _poolSettings[pool].minDebtRepay = minDebtRepay_;
        emit SetPoolParam(pool, systemParam.MinDebtRepay, minDebtRepay_);
    }

    function setMaxDebtRepayByPool(address pool, uint256 maxDebtRepay_) external onlyPoolOwner(pool) {
        require(maxDebtRepay_ <= E4, "over range");
        _poolSettings[pool].maxDebtRepay = maxDebtRepay_;
        emit SetPoolParam(pool, systemParam.MaxDebtRepay, maxDebtRepay_);
    }

    function setInterestRateByPool(address pool, uint256 interestRate_) external onlyPoolOwner(pool) {
        require(interestRate_ >= E4 && interestRate_ <= 2*E4, "over range");
        _poolSettings[pool].interestRate = interestRate_;
        _debtSettings[IPool(pool).debtToken()] = interestRate_;
        emit SetPoolParam(pool, systemParam.InterestRate, interestRate_);
    }

    function setLiquidityCoefficientByPool(address pool, uint256 liquidityCoefficient_) external onlyPoolOwner(pool) {
        require(liquidityCoefficient_ > 0 && liquidityCoefficient_ <= 1e6, "over range");
        _poolSettings[pool].liquidityCoefficient = liquidityCoefficient_;
        emit SetPoolParam(pool, systemParam.LiquidityCoefficient, liquidityCoefficient_);
    }

    function setDeviationByPool(address pool, bool deviation_) external onlyPoolOwner(pool) {
        _poolSettings[pool].deviation = deviation_;
        emit SetPoolDeviation(pool, deviation_);
    }

    function setPoolOwner(address pool, address newOwner) external onlyOwner {
        if (_poolSettings[pool].owner != address(0)) {
            _poolSettings[pool].owner = newOwner;
        } else {
            _poolSettings[pool] = PoolSetting(
                newOwner,
                marginRatio,
                closingFee,
                liqFeeBase,
                liqFeeMax,
                liqFeeCoefficient,
                _liqLsRequire,
                rebaseCoefficient,
                imbalanceThreshold,
                priceDeviationCoefficient,
                _minHoldingPeriod,
                debtStart,
                debtAll,
                minDebtRepay,
                maxDebtRepay,
                interestRate,
                liquidityCoefficient,
                _deviation
            );
            _debtSettings[IPool(pool).debtToken()] = interestRate;
        }

        emit SetPoolOwner(pool, newOwner);
    }

    function setOfficial(address official) external onlyOwner {
        _official = official;
    }

    function setSuspender(address suspender) external onlySuspender {
        _suspender = suspender;
    }

    modifier onlySuspender() {
        require(
            _suspender == msg.sender,
            "caller is not the suspender"
        );
        _;
    }

    modifier onlyPoolOwner(address pool) {
        require(
            _poolSettings[pool].owner == msg.sender,
            "caller is not the pool owner"
        );
        _;
    }
}