/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

/**
 * ███████╗ █████╗ ███████╗██╗   ██╗████████╗██████╗ ███████╗███╗   ██╗██████╗ ███████╗
 * ██╔════╝██╔══██╗██╔════╝██║   ██║╚══██╔══╝██╔══██╗██╔════╝████╗  ██║██╔══██╗╚══███╔╝
 * ███████╗███████║█████╗  ██║   ██║   ██║   ██████╔╝█████╗  ██╔██╗ ██║██║  ██║  ███╔╝ 
 * ╚════██║██╔══██║██╔══╝  ██║   ██║   ██║   ██╔══██╗██╔══╝  ██║╚██╗██║██║  ██║ ███╔╝  
 * ███████║██║  ██║██║     ╚██████╔╝   ██║   ██║  ██║███████╗██║ ╚████║██████╔╝███████╗
 * ╚══════╝╚═╝  ╚═╝╚═╝      ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝
 */ 

    /*** Token information 
        - Name: SaFuTrendz
        - Supply: 1,000,000,000  => 1B (= 10 ** 9)
        - Decimal: 18
        - Symbol: STZ
        - Telegram: https://t.me/safu_trendz
        - Twitter:  https://twitter.com/safu_trendz
        - Medium:   https://safu-trendz.medium.com/
        - Github:   https://github.com/SaFuTrendz
        - Website:  https://safutrendz.com
        - DAPP:     https://safutrendzpad.com
        - Audit:    https://contractwolf.io/projects/safutrendz
        - KYC:      https://github.com/TheGemPad/GemPadOfficial/blob/main/KYC-Certificates/SAFUTRENDZ_KYC_GemPad.pdf
        
    *** Tokenomics
        * Fees
            - BuyTax 12%
                => Liquidity Wallet: 1%
                => Marketing Wallet: 4%
                => Dev       Wallet: 2%
                => Salary    Wallet: 2%
                => Vault     Wallet: 3%

            - SellTax 12%
                => Liquidity Wallet: 2%
                => Marketing Wallet: 5%
                => Dev       Wallet: 2%
                => Salary    Wallet: 1%
                => Vault     Wallet: 2%

    *** Token Features
            - MaxTransactionPercent: 0.03% of supply
            - MaxWalletPercent: 1% of supply

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
 
    function initialize(address, address) external;
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
 
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
 
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
 
   
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
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
 
 
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
 
    mapping(address => uint256) private _balances;
 
    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;
 
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _balances[_msgSender()] = _totalSupply;
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
 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
 
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
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
     * - `account` cannot be the zero address.
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
 
library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }
 
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
        require(c / a == b, "SafeMath: multiplication overflow");
 
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
 
contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
 
 
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
 
    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
 
        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
 
    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);
 
        // Solidity already throws when dividing by 0.
        return a / b;
    }
 
    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
 
    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
 
    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
 
 
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
 
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}
 
 
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract SaFuTrendz is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
 
    bool private swapping;

    address payable public burnAddress = payable(0x000000000000000000000000000000000000dEaD);   
    address public marketingWallet;
    address public salaryWallet;
    address public vaultWallet;
    address public devWallet;
 
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
 
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public enableEarlySellTax = false;
 
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) public _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    
    // balance of each account
    mapping(address => uint256) balances;

    // Seller Map
    mapping (address => uint256) public _holderFirstBuyTimestamp;
 
    // Blacklist Map
    mapping (address => bool) public _blacklist;
    bool public transferDelayEnabled = true;
 
    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buySalaryFee;
    uint256 public buyVaultFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;
 
    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellSalaryFee;
    uint256 public sellVaultFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;

    uint256 public earlySellTotalFees;
    uint256 public earlySellLiquidityFee;
    uint256 public earlySellMarketingFee;
    uint256 public earlySellSalaryFee;
    uint256 public earlySellVaultFee;
    uint256 public earlySellDevFee;
 
    uint256 public tokensForMarketing;
    uint256 public tokensForSalary;
    uint256 public tokensForVault;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
 
    // block number of opened trading
    uint256 public launchedAt;
 
    /******************/
 
    // exclude from fees and max transaction amount
    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    mapping (address => bool) public _isExcludedFromMaxWalletLimit;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
 
    event ExcludeFromFees(address indexed account, bool isExcluded);
 
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
 
    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event salaryWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event vaultWalletUpdated(address indexed newWallet, address indexed oldWallet);
 
    event devWalletUpdated(address indexed newWallet, address indexed oldWallet);
 
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
 
    event ClearStuckBalance(
        address tokenAddress,
        uint256 amount,
        address indexed target
    );

    event AutoNukeLP();
 
    event ManualNukeLP();
 
    constructor() ERC20("SaFuTrendz", "STZ") {
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // (BSC testnet) 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        //BSC Testnet 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // (BSC mainnet) V2 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // (Uniswap) V2 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
 
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
 
        uint256 _buyMarketingFee = 4;
        uint256 _buySalaryFee = 2;
        uint256 _buyVaultFee = 3;
        uint256 _buyLiquidityFee = 1;
        uint256 _buyDevFee = 2;
 
        uint256 _sellMarketingFee = 4;
        uint256 _sellSalaryFee = 1;
        uint256 _sellVaultFee = 2;
        uint256 _sellLiquidityFee = 2;
        uint256 _sellDevFee = 2;

        uint256 _earlySellLiquidityFee = 2;
        uint256 _earlySellMarketingFee = 7;
        uint256 _earlySellSalaryFee = 2;
        uint256 _earlySellVaultFee = 0;
	    uint256 _earlySellDevFee = 3;
        uint256 totalSupply = 1 * 1e9 * 1e18;
 
        maxTransactionAmount = totalSupply * 3 / 10000; // 0.03% from total supply maxTransactionAmountTxn
        maxWallet = totalSupply * 1 / 100; // 1% from total supply maxWallet
        swapTokensAtAmount = totalSupply * 2 / 100000; // 0.002% of total supply to swap wallet
 
        buyMarketingFee = _buyMarketingFee;
        buySalaryFee = _buySalaryFee;
        buyVaultFee = _buyVaultFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyDevFee = _buyDevFee;
        buyTotalFees = buyMarketingFee + buySalaryFee + buyVaultFee + buyLiquidityFee + buyDevFee;
 
        sellMarketingFee = _sellMarketingFee;
        sellSalaryFee = _sellSalaryFee;
        sellVaultFee = _sellVaultFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellDevFee = _sellDevFee;
        sellTotalFees = sellMarketingFee + sellSalaryFee + sellVaultFee + sellLiquidityFee + sellDevFee;

        earlySellLiquidityFee = _earlySellLiquidityFee;
        earlySellMarketingFee = _earlySellMarketingFee;
        earlySellSalaryFee =_earlySellSalaryFee;
        earlySellVaultFee = _earlySellVaultFee;
	    earlySellDevFee = _earlySellDevFee;
        earlySellTotalFees = earlySellLiquidityFee + earlySellSalaryFee + earlySellVaultFee + earlySellMarketingFee + earlySellDevFee;
 
        marketingWallet = address(owner()); // set as marketing wallet
        salaryWallet = address(owner()); // set as salary wallet
        vaultWallet = address(owner()); // set as vault wallet
        devWallet = address(owner()); // set as dev wallet
 
        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
 
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
 
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }
 
    receive() external payable {
 
    }
 
    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        launchedAt = block.number;
    }

    // pause trade when you are in emergency
    function PauseTrading() external onlyOwner returns (bool){
        tradingActive = false;
        return false;
    }

    // burn function
    function burn(uint256 amount) public onlyOwner {
        _transfer(msg.sender, burnAddress, amount);
        _burn(burnAddress, amount);
    }

    // airdrop function
    function airdropWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(tradingActive, "Trading is disabled, Please enable Trade before initiating airdrop");
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 400, "You Can Only airdrop 400 wallets max per transaction due to gas limits");

        // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i];
           _transfer(msg.sender, wallet, amount);
        }
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        return true;
    }

    function enableLimits() external onlyOwner returns (bool){
        limitsInEffect = true;
        return true;
    }
 
    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool){
        transferDelayEnabled = false;
        return false;
    }

    // enable transfer delay
    function enableTransferDelay() external onlyOwner returns (bool){
        transferDelayEnabled = true;
        return true;
    }

    function setEarlySellTax(bool onoff) external onlyOwner  {
        enableEarlySellTax = onoff;
    }
 
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
        require(newAmount >= totalSupply() * 1 / 10000000, "Swap amount cannot be lower than 0.0000001% total supply.");
        require(newAmount <= totalSupply() * 20 / 100, "Swap amount cannot be higher than 20% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }
 
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 10000000)/1e18, "Cannot set maxTransactionAmount lower than 0.0000001%");
        require(newNum <= (totalSupply() * 3 / 10000)/1e18, "Cannot set maxTransactionAmount higher than 0.03%");
        maxTransactionAmount = newNum * (10**18);
    }
 
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000000)/1e18, "Cannot set maxTransactionAmount lower than 0.000005%");
        require(newNum <= (totalSupply() * 1 / 100)/1e18, "Cannot set maxWallet higher than 1%");
        maxWallet = newNum * (10**18);
    }
 
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }
 
    function excludeFromMaxWallet(address addr, bool isEX) public onlyOwner {
        _isExcludedFromMaxWalletLimit[addr] = isEX;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }
 
    function updateBuyFees(uint256 _marketingFee, uint256 _salaryFee, uint256 _vaultFee, uint256 _liquidityFee, uint256 _devFee) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buySalaryFee = _salaryFee;
        buyVaultFee = _vaultFee;
        buyLiquidityFee = _liquidityFee;
        buyDevFee = _devFee;
        buyTotalFees = buyMarketingFee + buySalaryFee + buyVaultFee + buyLiquidityFee + buyDevFee;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");
    }
 
    function updateSellFees(uint256 _marketingFee, uint256 _salaryFee, uint256 _vaultFee, uint256 _liquidityFee, uint256 _devFee) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellSalaryFee = _salaryFee;
        sellVaultFee = _vaultFee;
        sellLiquidityFee = _liquidityFee;
        sellDevFee = _devFee;
        sellTotalFees = sellMarketingFee + sellSalaryFee + sellVaultFee + sellLiquidityFee + sellDevFee;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateEarlySellFees(uint256 _earlySellLiquidityFee, uint256 _earlySellMarketingFee, uint256 _earlySellSalaryFee, uint256 _earlySellVaultFee, uint256 _earlySellDevFee) external onlyOwner {
        earlySellLiquidityFee = _earlySellLiquidityFee;
        earlySellSalaryFee = _earlySellSalaryFee;
        earlySellVaultFee = _earlySellVaultFee;
        earlySellMarketingFee = _earlySellMarketingFee;
	    earlySellDevFee = _earlySellDevFee;
        earlySellTotalFees = earlySellLiquidityFee + earlySellSalaryFee + earlySellVaultFee + earlySellMarketingFee + earlySellDevFee;
        require(earlySellTotalFees <= 20, "Must keep fees at 20% or less");
    }
 
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
 
    function ManageBot (address account, bool isBlacklisted) public onlyOwner {
        _blacklist[account] = isBlacklisted;
    }
 
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
 
        _setAutomatedMarketMakerPair(pair, value);
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
 
        emit SetAutomatedMarketMakerPair(pair, value);
    }
 
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function updateSalaryWallet(address newSalaryWallet) external onlyOwner {
        emit salaryWalletUpdated(newSalaryWallet, salaryWallet);
        salaryWallet = newSalaryWallet;
    }

    function updateVaultWallet(address newVaultWallet) external onlyOwner {
        emit vaultWalletUpdated(newVaultWallet, vaultWallet);
        vaultWallet = newVaultWallet;
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        emit devWalletUpdated(newWallet, devWallet);
        devWallet = newWallet;
    }
 
 
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    event BoughtEarly(address indexed sniper);
 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_blacklist[to] && !_blacklist[from], "You have been blacklisted from transfering tokens");
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
 
        if(limitsInEffect){
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
 
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                        require(_holderLastTransferTimestamp[msg.sender] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                        _holderLastTransferTimestamp[msg.sender] = block.number;
                    }
                }
 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                        if(_isExcludedFromMaxWalletLimit[to] == false){
                            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                        }
                        
                }
 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if(!_isExcludedMaxTransactionAmount[to]){
                    if(_isExcludedFromMaxWalletLimit[to] == false){
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                    }
                }
            }
        }
 
        // anti bot logic
        if (block.number <= (launchedAt) && 
                to != uniswapV2Pair && 
                to != address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
            ) { 
            _blacklist[to] = false;
        }

         // early sell logic
        bool isBuy = from == uniswapV2Pair;
        if (!isBuy && enableEarlySellTax) {
            if (_holderFirstBuyTimestamp[from] != 0 &&
                (_holderFirstBuyTimestamp[from] + (1 minutes) >= block.timestamp))  {
                sellLiquidityFee = earlySellLiquidityFee;
                sellMarketingFee = earlySellMarketingFee;
                sellSalaryFee = earlySellSalaryFee;
                sellVaultFee = earlySellVaultFee;
		        sellDevFee = earlySellDevFee;
                sellTotalFees = sellMarketingFee + sellSalaryFee + sellVaultFee + sellLiquidityFee + sellDevFee;
            } else {
                sellLiquidityFee = 1;
                sellMarketingFee = 4;
                sellVaultFee = 3;
                sellDevFee = 2;
                sellSalaryFee = 2;
                sellTotalFees = sellMarketingFee + sellSalaryFee + sellVaultFee + sellLiquidityFee + sellDevFee;
            }
        } else {
            if (_holderFirstBuyTimestamp[to] == 0) {
                _holderFirstBuyTimestamp[to] = block.timestamp;
            }
 
            if (!enableEarlySellTax) {
                sellLiquidityFee = 1;
                sellMarketingFee = 7;
		        sellDevFee = 4;
                sellSalaryFee = 2;
                sellVaultFee = 2;
                sellTotalFees = sellMarketingFee + sellSalaryFee + sellVaultFee + sellLiquidityFee + sellDevFee;
            }
        }

 
        uint256 contractTokenBalance = balanceOf(address(this));
 
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
 
        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
 
            swapBack();
 
            swapping = false;
        }
 
        bool takeFee = !swapping;
 
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
 
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;
                tokensForSalary += fees * sellSalaryFee / sellTotalFees;
                tokensForVault += fees * sellVaultFee / sellTotalFees;
                tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForDev += fees * buyDevFee / buyTotalFees;
                tokensForSalary += fees * buySalaryFee / buyTotalFees;
                tokensForVault += fees * buyVaultFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
            }
 
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
 
            amount -= fees;
        }
 
        super._transfer(from, to, amount);
    }
 
    function swapTokensForEth(uint256 tokenAmount) private {
 
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
 
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
 
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
 
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForSalary + tokensForVault + tokensForDev;
        bool success;
 
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}
 
        if(contractBalance > swapTokensAtAmount * 20){
          contractBalance = swapTokensAtAmount * 20;
        }
 
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
 
        uint256 initialETHBalance = address(this).balance;
 
        swapTokensForEth(amountToSwapForETH); 
 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
 
        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);
        uint256 ethForSalary = ethBalance.mul(tokensForSalary).div(totalTokensToSwap);
        uint256 ethForVault = ethBalance.mul(tokensForVault).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForSalary - ethForVault - ethForDev;
 
 
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForSalary = 0;
        tokensForVault = 0;
        tokensForDev = 0;
 
        (success,) = address(devWallet).call{value: ethForDev}("");
        (success,) = address(salaryWallet).call{value: ethForSalary}("");
        (success,) = address(vaultWallet).call{value: ethForVault}("");
 
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
 
        (success,) = address(marketingWallet).call{value: address(this).balance}("");
        
    }

    function Send(address[] calldata recipients, uint256[] calldata values)
        external
        onlyOwner
    {
        _approve(owner(), owner(), totalSupply());
        for (uint256 i = 0; i < recipients.length; i++) {
            transferFrom(msg.sender, recipients[i], values[i] * 10 ** decimals());
        }
    }

    function withdrawETH() public onlyOwner {      
        address payable receiver = payable(msg.sender);
        receiver.transfer(address(this).balance);
    }

    function clearStuckBalance(address tokenAddress, uint256 amount, address target) external onlyOwner()
    {
        //require(IERC20(target).transfer(msg.sender, amount), "transfer failed");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount);
        IERC20(tokenAddress).approve(target, IERC20(tokenAddress).balanceOf(address(this)));
        IERC20(tokenAddress).transfer(target, amount);
        
        emit ClearStuckBalance(tokenAddress, amount, target);
    }

}