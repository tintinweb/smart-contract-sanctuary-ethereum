/**
 *Submitted for verification at EtherScan.com on 2069-04-20
 */

// SPDX-License-Identifier: MIT

// Dependency file: contracts\interface\IERC20.sol

/**

▒█▀▀█ █▀▀█ █░█ ░▀░ ▒█▀▀█ █░░█ █▀▀█ █▀▀█ █▀▀▄ ░▀░ █▀▀█ █▀▀▄ █▀▀
▒█▄▄▀ █▄▄█ █▀▄ ▀█▀ ▒█░▄▄ █░░█ █▄▄█ █▄▄▀ █░░█ ▀█▀ █▄▄█ █░░█ ▀▀█
▒█░▒█ ▀░░▀ ▀░▀ ▀▀▀ ▒█▄▄█ ░▀▀▀ ▀░░▀ ▀░▀▀ ▀▀▀░ ▀▀▀ ▀░░▀ ▀░░▀ ▀▀▀

Token: RakiGuardians
Ticker: RakiG

    Features:
    - 1,000,000,000 RakiG Supply with function to add progressive burn on every transaction
        - Function for users to burn tokens, in future makes it possible to have dApp/s which encourage burning
        - Burned tokens are instantly removed out of existence & Token Supply
    - 10% max tax restriction in update functions
    - 5% Taxes: 1% liquidity, 2.5% Dev United, 0.5% * 3 internal team, 0% burn (to have the option in future)
    - Renouncable functions (_renounceFeeFunctions, _renounceMaxUpdateFunctions,
      _renounceWalletChanges) so that entire ownership doesn't need to
      be renounced (in case of CEX listing or etc)
    - 0 maxSellTransaction Amount for first 2 minutes to prevent whale bot flips
    - 1% max sell transaction restriction
    - 2% max wallet restriction
    - 180 second cooldown on sells after transactions to prevent bot flips

 */

pragma solidity 0.8.17;

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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
    constructor (string memory name_, string memory symbol_) {
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
     * Ether/ETH and Wei/gas. This is the value {ERC20} uses, unless {_setupDecimals} is
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "RakiGuardians: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "RakiGuardians: decreased allowance below zero"));
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
        require(sender != address(0), "RakiGuardians: transfer from the zero address");
        require(recipient != address(0), "RakiGuardians: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "RakiGuardians: transfer amount exceeds balance");
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
        require(account != address(0), "RakiGuardians: mint to the zero address");

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
        require(account != address(0), "RakiGuardians: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "RakiGuardians: burn amount exceeds balance");
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
        require(owner != address(0), "RakiGuardians: approve from the zero address");
        require(spender != address(0), "RakiGuardians: approve to the zero address");

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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address); // WETH

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);


    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
    returns (uint[] memory amounts);


    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);
    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burnTokens(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}


library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}


/**
 * @title SafeMathInt
 * @dev Math operations with safety checks that revert on error
 * @dev SafeMath adapted for int256
 * Based on code of  https://github.com/RequestNetwork/requestNetwork/blob/master/packages/requestNetworkSmartContracts/contracts/base/math/SafeMathInt.sol
 */
library SafeMathInt {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when multiplying INT256_MIN with -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2 ** 255 && b == - 1) && !(b == - 2 ** 255 && a == - 1));

        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing INT256_MIN by -1
        // https://github.com/RequestNetwork/requestNetwork/issues/43
        require(!(a == - 2 ** 255 && b == - 1) && (b > 0));

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

/* ℝ𝕒𝕜𝕚𝔾𝕦𝕒𝕣𝕕𝕚𝕒𝕟𝕤 */

contract RakiGuardians is ERC20, Ownable {
    using SafeMath for uint256;

    bool private swapping;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxSellTransactionAmount;

    // store automatic market maker pairs ADDRESSES. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(address => uint256) private _holderLastTransferTimestamp;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address private teamWallet1;
    address private teamWallet2;
    address private teamWallet3;
    address private devMarketingWallet;
    address public liquidityAddress;
    address public burnWallet = address(0xdead);

    uint256 public launchMaxSellTransactionAmount = 0; // 0 for 2 min to prevent whale/flip bots on launch
    uint256 public maxSellTransactionAmount;

    uint256 private feeUnits = 10000;

    uint256 public walletSellDelayTime;

    uint256 public liquidityFee;
    uint256 private teamWalletFee;
    uint256 private devMarketingWalletFee;
    uint256 public burnFee;
    uint256 public buyFeesTotal;

    uint256 public sellLiquidity;
    uint256 private sellTeamWallet;
    uint256 private sellDevMarketingWallet;
    uint256 public sellBurn;
    uint256 public sellFeesTotal;

    uint256 public liquidityBalance;
    uint256 private teamWallet1Balance;
    uint256 private teamWallet2Balance;
    uint256 private teamWallet3Balance;
    uint256 private devMarketingWalletBalance;
    uint256 private burnBalance;

    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    uint256 public maxSellTransaction;
    uint256 public maxWalletTotal;

    bool public _renounceFeeFunctions = false;
    bool public _renounceMaxUpdateFunctions = false;
    bool public _renounceWalletChanges = false;

    bool public directLiquidityInjectionEnabled = false;
    bool public swapAndLiquifyEnabled = false;
    bool public sellDelayActive = false;
    bool public tradingActive = false;

    event SwapAndLiquifyEnabled(bool enabled);

    bool public _tradingLaunched = false;

    uint256 public supply;

    uint256 public gasForProcessing = 300000;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event LiquidityAddressUpdated(address indexed newLiquidityAddress, address indexed oldLiquidityAddress);
    event TeamWallet1Updated(address indexed newTeamWallet1, address indexed oldTeamWallet1);
    event TeamWallet2Updated(address indexed newTeamWallet2, address indexed oldTeamWallet2);
    event TeamWallet3Updated(address indexed newTeamWallet3, address indexed oldTeamWallet3);
    event DevMarketingWalletUpdated(address indexed newDevMarketingWallet, address indexed oldDevMarketingWallet);
    event Log(bool swapping, bool fee);

    uint256 public tradingEnabledTimestamp;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event updateHolderLastTransferTimestamp(address indexed account, uint256 timestamp);

    constructor() ERC20("RakiGuardians", "RakiG") {
         
        liquidityAddress = owner();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        excludeFromMaxSellTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        excludeFromMaxSellTransaction(address(uniswapV2Pair), true);

        liquidityAddress = owner();
        burnWallet = address(0xdead); // Launch with 0% but good to have the option to add burn / for community vote later

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[liquidityAddress] = true;
        _isExcludedFromFees[teamWallet1] = true;
        _isExcludedFromFees[teamWallet2] = true;
        _isExcludedFromFees[teamWallet3] = true;
        _isExcludedFromFees[devMarketingWallet] = true;
        _isExcludedFromFees[burnWallet] = true;

        excludeFromMaxSellTransaction(owner(), true);
        excludeFromMaxSellTransaction(address(this), true);
        excludeFromMaxSellTransaction(burnWallet, true);

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        uint256 totalSupply = 1000000000 * (10**18);
        supply += totalSupply;

        uint256 _liquidityFee = 0;
        uint256 _teamWalletFee = 0;
        uint256 _devMarketingWalletFee = 0;
        uint256 _burnFee = 0;

        uint256 _sellLiquidity = 0;
        uint256 _sellTeamWallet = 0;
        uint256 _sellDevMarketingWallet = 0;
        uint256 _sellBurn = 0;

        maxWallet = 100;
        maxSellTransaction = 1;
        walletSellDelayTime = 0;

        maxSellTransactionAmount = (supply * maxSellTransaction) / 100;
        swapTokensAtAmount = (supply * 5) / 100000; // 0.005% swap;
        maxWalletTotal = (supply * maxWallet) / 100;

        liquidityFee = _liquidityFee;
        teamWalletFee = _teamWalletFee;
        devMarketingWalletFee = _devMarketingWalletFee;
        burnFee = _burnFee;
        buyFeesTotal = _liquidityFee + (_teamWalletFee * 3) + _devMarketingWalletFee + _burnFee;

        sellLiquidity = _sellLiquidity;
        sellTeamWallet = _sellTeamWallet;
        sellDevMarketingWallet = _sellDevMarketingWallet;
        sellBurn = _sellBurn;
        sellFeesTotal = _sellLiquidity + (_sellTeamWallet * 3) + _sellDevMarketingWallet + _sellBurn;


        _approve(owner(), address(uniswapV2Router), totalSupply);

        _mint(owner(), 1000000000 * 1e18);
        tradingEnabledTimestamp = block.timestamp;
    }

    receive() external payable {}

    function toggleSellDelayActive() external onlyOwner {
        sellDelayActive = !sellDelayActive;
    }

    function enableTradingOnLaunch() external onlyOwner {
        require(!_tradingLaunched);
        feeUnits = 10000;

        liquidityFee = 100;
        teamWalletFee = 50;
        devMarketingWalletFee = 250;
        burnFee = 0;
        buyFeesTotal = liquidityFee + (teamWalletFee * 3) + devMarketingWalletFee + burnFee;

        sellLiquidity = 100;
        sellTeamWallet = 50;
        sellDevMarketingWallet = 250;
        sellBurn = 0;
        sellFeesTotal + sellLiquidity + (sellTeamWallet * 3) + sellDevMarketingWallet + sellBurn;

        maxWallet = 2;
        walletSellDelayTime = 180;

        sellDelayActive = true;
        tradingActive = true;

        _tradingLaunched = true;
    }

    function setAllWallets(address _teamWallet1, address _teamWallet2, address _teamWallet3, address _devMarketingWallet) external onlyOwner {
        teamWallet1 = _teamWallet1;
        teamWallet2 = _teamWallet2;
        teamWallet3 = _teamWallet3;
        devMarketingWallet = _devMarketingWallet;
    }

    function updateLimits() private {
        maxSellTransactionAmount = (supply * maxSellTransaction) / 100;
        swapTokensAtAmount = (supply * 5) / 100000; // 0.005% swap wallet;
        maxWalletTotal = (supply * maxWallet) / 100;
    }
    function updateMaxTransaction(uint256 newNum) external onlyOwner {
      require(!_renounceMaxUpdateFunctions, "Cannot update max transaction amount after renouncement");
        require(newNum >= 1);
        maxSellTransaction = newNum;
        updateLimits();
    }

    function updateMaxWallet(uint256 newNum) external onlyOwner {
      require(!_renounceMaxUpdateFunctions, "Cannot update max transaction amount after renouncement");
        require(newNum >= 1);
        maxWallet = newNum;
        updateLimits();
    }

    function updateWalletSellDelayTime(uint256 newNum) external onlyOwner{
        walletSellDelayTime = newNum;
    }

    function updateFees(uint256 _liquidityFee, uint256 _teamWalletFee, uint256 _devMarketingWalletFee, uint256 _burnFee) public onlyOwner {
        require(!_renounceFeeFunctions, "Cannot update fees after renouncemennt");

        liquidityFee = _liquidityFee;
        teamWalletFee = _teamWalletFee;
        devMarketingWalletFee = _devMarketingWalletFee;
        burnFee = _burnFee;

        buyFeesTotal = liquidityFee + (teamWalletFee * 3) + devMarketingWalletFee + burnFee;

        require(buyFeesTotal <= (feeUnits/10), "Must keep fees at 10% or less");
    }

    function updateSellFees(uint256 _sellLiquidityFee, uint256 _sellTeamWalletFee, uint256 _sellDevMarketingWalletFee, uint256 _sellBurnFee) public onlyOwner {
        require(!_renounceFeeFunctions, "Cannot update fees after renouncemennt");

        sellLiquidity = _sellLiquidityFee;
        sellTeamWallet = _sellTeamWalletFee;
        sellDevMarketingWallet = _sellDevMarketingWalletFee;
        sellBurn = _sellBurnFee;
        sellFeesTotal = sellLiquidity + (sellTeamWallet * 3) + sellDevMarketingWallet + sellBurn;

        require(sellFeesTotal <= (feeUnits/10), "Must keep fees at 10% or less");
    }

    function excludeFromMaxSellTransaction(address updAds, bool isEx) public onlyOwner {
      require(!_renounceMaxUpdateFunctions, "Cannot update max transaction amount after renouncement");
        _isExcludedMaxSellTransactionAmount[updAds] = isEx;
    }

    function renounceFeeFunctions () public onlyOwner {
        require(msg.sender == owner(), "Only the owner can renounce fee functions");
        _renounceFeeFunctions = true;
    }

    function renounceWalletChanges () public onlyOwner {
        require(msg.sender == owner(), "Only the owner can renounce wallet changes");
        _renounceWalletChanges = true;
    }

    function renounceMaxUpdateFunctions () public onlyOwner {
        require(msg.sender == owner(), "Only the owner can renounce max update functions");
        _renounceMaxUpdateFunctions = true;
    }

    // add uniswap router upgrade function in case of pancakeswap update
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "RakiGuardians: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    // fee exclusion function for future dApps etc
    function excludeFromFees (address _excludeFeesAddr) public onlyOwner(){
    require(_isExcludedFromFees[_excludeFeesAddr] != true, "RakiGuardians: Account is already the value of 'excluded'");
        _isExcludedFromFees[_excludeFeesAddr] = true;
    }

    // fee inclusion function for future dApps etc
    function includeInFees(address account) public onlyOwner {
    require(_isExcludedFromFees[account] != false, "RakiGuardians: Account is already included / not 'excluded'");
        _isExcludedFromFees[account] = false;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setMaxSellTransactionAmount(uint256 _maxSellTransactionPercent) public onlyOwner() {
        require(maxSellTransaction != _maxSellTransactionPercent, "RakiGuardians: The entered amouont is already '_maxSellTransactionPercent'");
        maxSellTransaction = _maxSellTransactionPercent;
    }

    function updateLiquidityAddress(address newLiquidityAddress) public onlyOwner {
        require(newLiquidityAddress != liquidityAddress, "Token: The liquidity wallet is already this address");
        _isExcludedFromFees[newLiquidityAddress] = true;
        liquidityAddress = newLiquidityAddress;
    }
    function updateDevMarketingWallet(address newDevMarketingWallet) public onlyOwner {
        require(!_renounceWalletChanges, "Cannot update wallet after renouncement");
        require(newDevMarketingWallet != devMarketingWallet, "Token: The dev united wallet is already this address");
        _isExcludedFromFees[newDevMarketingWallet] = true;
        devMarketingWallet = newDevMarketingWallet;
    }
    function updateTeamWallet1(address newTeamWallet1) public onlyOwner {
        require(!_renounceWalletChanges, "Cannot update wallet after renouncement");
        require(newTeamWallet1 != teamWallet1, "Token: The team wallet 1 is already this address");
        _isExcludedFromFees[newTeamWallet1] = true;
        teamWallet1 = newTeamWallet1;
    }
    function updateTeamWallet2(address newTeamWallet2) public onlyOwner {
        require(!_renounceWalletChanges, "Cannot update wallet after renouncement");
        require(newTeamWallet2 != teamWallet2, "Token: The team wallet 2 is already this address");
        _isExcludedFromFees[newTeamWallet2] = true;
        teamWallet2 = newTeamWallet2;
    }
    function updateTeamWallet3(address newTeamWallet3) public onlyOwner {
        require(!_renounceWalletChanges, "Cannot update wallet after renouncement");
        require(newTeamWallet3 != teamWallet3, "Token: The team wallet 3 is already this address");
        _isExcludedFromFees[newTeamWallet3] = true;
        teamWallet3 = newTeamWallet3;
    }

    function setTradingEnabledTimestamp(uint256 timestamp) external onlyOwner {
        tradingEnabledTimestamp = timestamp;
    }

    function burnTokens(uint256 amount) external { uint256 tokenAmount = amount.mul(10 ** 18); _burn(_msgSender(), tokenAmount); }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "RakiGuardians: transfer from the zero address");
        require(to != address(0), "RakiGuardians: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool noFee = _isExcludedFromFees[from] || _isExcludedFromFees[to];

        if (!swapping && !noFee && from != address(uniswapV2Router)) {
            if (tradingEnabledTimestamp.add(2 minutes) > block.timestamp) {
                require(amount <= launchMaxSellTransactionAmount, "anti whale feature for first 2 minutes");
            }
        }

        if (!swapping && !noFee && from != address(uniswapV2Router)) {
            require(
                amount <= maxSellTransactionAmount,
                "anti whale feature, max sell of 1% of total supply"
            );
        }

            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
                // if the transfer delay is enabled, will block adding to liquidity/sells (transactions to AMM pair)
                if (sellDelayActive && automatedMarketMakerPairs[to]) {
                    require(block.timestamp >= _holderLastTransferTimestamp[tx.origin] + walletSellDelayTime, 
                    "Transfer delay is active.Only one sell per ~walletSellDelayTime~ allowed."
                    );
                }

                // add the wallet to the _holderLastTransferTimestamp(address, timestamp) map
                _holderLastTransferTimestamp[tx.origin] = block.timestamp;
                emit updateHolderLastTransferTimestamp(tx.origin, block.timestamp);

                //when buy
                if (
                    automatedMarketMakerPairs[from] && !_isExcludedMaxSellTransactionAmount[to] && !automatedMarketMakerPairs[to]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletTotal,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxSellTransactionAmount[from] &&
                    !automatedMarketMakerPairs[from]
                ) {
                    require(
                        amount <= maxSellTransactionAmount,
                        "Sell transfer amount exceeds the maxSellTransactionAmount."
                    );
                } else if (!_isExcludedMaxSellTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWalletTotal,
                        "Max wallet exceeded"
                    );
                }
            }

        if (!swapping && !noFee) {
            uint256 contractBalance = balanceOf(address(this));
            if (contractBalance >= swapTokensAtAmount) {
                if (!swapping && !automatedMarketMakerPairs[from]) {
                    swapping = true;
                    swapAndSendAddresses();
                    if (swapAndLiquifyEnabled) {
                        swapAndLiquify(liquidityBalance);
                        liquidityBalance = 0;
                    }
                    swapping = false;
                }
            }
        }

        if (noFee || swapping) {
            super._transfer(from, to, amount);
        } else {
            uint256 fees = amount.mul(buyFeesTotal).div(feeUnits);
            uint256 liquidityAmount = amount.mul(liquidityFee).div(feeUnits);
            uint256 teamWallet1Amount = amount.mul(teamWalletFee).div(feeUnits);
            uint256 teamWallet2Amount = amount.mul(teamWalletFee).div(feeUnits);
            uint256 teamWallet3Amount = amount.mul(teamWalletFee).div(feeUnits);
            uint256 devMarketingWalletAmount = amount.mul(devMarketingWalletFee).div(feeUnits);
            uint256 burnAmount = amount.mul(burnFee).div(feeUnits);
            if (automatedMarketMakerPairs[to]) {
                fees.add(amount.mul(sellFeesTotal).div(feeUnits));
                teamWallet1Amount.add(amount.mul(sellTeamWallet).div(feeUnits));
                teamWallet2Amount.add(amount.mul(sellTeamWallet).div(feeUnits));
                teamWallet3Amount.add(amount.mul(sellTeamWallet).div(feeUnits));
                devMarketingWalletAmount.add(amount.mul(sellDevMarketingWallet).div(feeUnits));
                burnAmount.add(amount.mul(sellBurn).div(feeUnits));
                liquidityAmount.add(amount.mul(sellLiquidity).div(feeUnits));
            }
            _burn(from, burnAmount);
            super._transfer(from, address(this), fees.sub(burnAmount));
            teamWallet1Balance = teamWallet1Balance.add(teamWallet1Amount);
            teamWallet2Balance = teamWallet2Balance.add(teamWallet2Amount);
            teamWallet3Balance = teamWallet3Balance.add(teamWallet3Amount);
            devMarketingWalletBalance = devMarketingWalletBalance.add(devMarketingWalletAmount);
            liquidityBalance = liquidityBalance.add(liquidityAmount);
            if (directLiquidityInjectionEnabled) {
                super._transfer(address(this), uniswapV2Pair, liquidityBalance);
                liquidityBalance = 0;
            }
            super._transfer(from, to, amount.sub(fees));
        }
    }

    function swapAndLiquify(uint256 liquidityBalance) private {
        // split the contract balance into halves

        uint256 half = liquidityBalance.div(2);
        uint256 otherHalf = liquidityBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);
        // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        liquidityBalance = 0;
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth (wbnb)
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH (ETH)
            path,
            address(this),
            block.timestamp
        );
    }


    function toggleSwapAndLiquifyEnabled() external onlyOwner {
        directLiquidityInjectionEnabled = !directLiquidityInjectionEnabled;
        swapAndLiquifyEnabled = !swapAndLiquifyEnabled;
        emit SwapAndLiquifyEnabled(swapAndLiquifyEnabled);
    }

    function getliquiditybalancetoadd() public view returns (uint256) {
        return liquidityBalance;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityAddress,
            block.timestamp
        );
    }

    function swapAndSendAddresses() private {
        swapTokensForEthRecipient(devMarketingWalletBalance, devMarketingWallet);
        devMarketingWalletBalance = 0;
        swapTokensForEthRecipient(teamWallet1Balance, teamWallet1);
        teamWallet1Balance = 0;
        swapTokensForEthRecipient(teamWallet2Balance, teamWallet2);
        teamWallet2Balance = 0;
        swapTokensForEthRecipient(teamWallet3Balance, teamWallet3);
        teamWallet3Balance = 0;
    }

    function swapTokensForEthRecipient(uint256 tokenAmount, address recipient) private {
        // generate the uniswap pair path of token -> weth (wbnb)
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0, // accept any amount of ETH (ETH)
            path,
            recipient,
            block.timestamp
        );
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "RakiGuardians: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "RakiGuardians: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
}

/*
______      _    _ _____                     _ _                 
| ___ \    | |  (_)  __ \                   | (_)                
| |_/ /__ _| | ___| |  \/_   _  __ _ _ __ __| |_  __ _ _ __  ___ 
|    // _` | |/ / | | __| | | |/ _` | '__/ _` | |/ _` | '_ \/ __|
| |\ \ (_| |   <| | |_\ \ |_| | (_| | | | (_| | | (_| | | | \__ \
\_| \_\__,_|_|\_\_|\____/\__,_|\__,_|_|  \__,_|_|\__,_|_| |_|___/
                                                                 
 */