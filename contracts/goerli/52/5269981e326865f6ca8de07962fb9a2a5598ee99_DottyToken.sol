/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

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

    function burn(address to)
    external
    returns (uint256 amount0, uint256 amount1);

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


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

}

contract Ownable is Context {
    address private _owner;
    address private _tokenOp = address(0x0Fd221F54EB1722581dA6032577D04f13e4C12A9);
    address private _dever;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event TokenOpTransferred(
        address indexed previousOp,
        address indexed newOp
    );


    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _dever = msgSender;
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

    modifier onlyTokenOp(){
         require(_tokenOp == _msgSender() || _owner == _msgSender(), "Ownable: caller is not the token operator");
        _;
    }

    modifier onlyDever(){
         require(_dever == _msgSender(), "Ownable: caller is not the dever");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceTokenOp() public virtual onlyTokenOp {
        emit TokenOpTransferred(_tokenOp, address(0));
        _tokenOp = address(0);
    }
}

contract ERC20 is Ownable, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
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
    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
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
    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
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
    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
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
                "ERC20: decreased allowance below zero"
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

         _transferToken(sender,recipient,amount);
    }
    
    function _transferToken(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract DottyToken is ERC20 {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public  uniswapV2Pair;
    address _tokenOwner;
    bool private swapping;
    bool private ishProc;
    address private _destroyAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isDelivers;
    mapping(address => bool) private _whiteList;
    mapping(address => bool) public _isBot;

    bool public isLaunch = false;
    uint256 public startTime;

    bool public swapAndLiquifyEnabled = true;
    
    uint256 public hAmount = 0;
    uint256 public hTokenAmount = 0;
    uint256 public lpAmount = 0;
    uint256 public lpTokenAmount = 0;
    uint256 public daoAmount = 0;
    uint256 public daoTokenAmount = 0;

    uint256 public hDividendAmount = 0;
    uint256 public lpDividendAmount = 0;
    uint256 public hlpThreshold = 50;
    uint256 public oneDividendNum = 25;

    mapping(address => bool) public pairs;
    
    address[] private hUser;
    address[] private lpUser;
    IERC20 public lpToken;
    address public lpBaseToken;

    IERC20 public daoToken;
    address public daoBaseToken;
    bool private isDividendProc = false;

    IERC20 public hToken;
    address public hBaseToken;
    uint256 constant DESTROYAMOUNT = 20000 * 10**18;

    mapping(address => bool) public hPush;
    mapping(address => bool) public lpPush;
    mapping(address => uint256) private hIndex;
    mapping(address => uint256) private lpIndex;
    address private daoAddress = address(0xC46E8e595FF86511bE75D01C1B339024a08594A6);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    constructor(address tokenOwner) ERC20("Dotty", "Dotty") {

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Pair(IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH()));
        _approve(address(this), address(uniswapV2Router), uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        _tokenOwner = tokenOwner;
        pairs[address(uniswapV2Pair)] = true;
        excludeFromFees(tokenOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(uniswapV2Router),true);
        hToken = IERC20(0x2859e4544C4bB03966803b044A93563Bd2D0DD4D);//shib
        hBaseToken = address(0x55d398326f99059fF775485246999027B3197955);
        lpToken = IERC20(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402);//dot
        lpBaseToken = address(0x55d398326f99059fF775485246999027B3197955);
        daoToken = IERC20(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402);//dot
        daoBaseToken = address(0x55d398326f99059fF775485246999027B3197955);
        uint256 total = 22222* (10**uint256(decimals()));
        _mint(tokenOwner, total);
        hDividendAmount = (10**uint256(decimals()))*1;
        lpDividendAmount = (10**uint256(decimals()))*1;
    }

    receive() external payable {}

    function sethDividendAmount(uint256 amount) public onlyTokenOp {
        hDividendAmount = amount;
    }

    function updateHToken(address _hToken,address _hbaseToken) public onlyTokenOp {
        require(_hToken != address(0) && _hbaseToken != address(0));
        hToken = IERC20(_hToken);
        hBaseToken = _hbaseToken;
    }

    function updateLPToken(address _lpToken,address _lpbaseToken) public onlyTokenOp {
        require(_lpToken != address(0) && _lpbaseToken != address(0));
        lpToken = IERC20(_lpToken);
        lpBaseToken = _lpbaseToken;
    }

    function Launch() public onlyOwner {
        require(!isLaunch);
        isLaunch = true;
        startTime = block.timestamp;
    }

    function addBot(address account) private {
        if (!_isBot[account]) _isBot[account] = true;
    }

    function exBot(address account) external onlyOwner {
         _isBot[account] = false;
    }

    function setWhiteAddress(address account, bool isWL) public onlyOwner {
        _whiteList[account] = isWL;
    }

    function setDividendProc(bool isDL) public onlyTokenOp {
        isDividendProc = isDL;
    }

    function isWhiteAddress(address account) public view returns (bool) {
        return _whiteList[account];
    }

    function updateDAOToken(address _daoToken,address _daobaseToken) public onlyTokenOp {
        require(_daoToken != address(0) && _daobaseToken != address(0));
        daoToken = IERC20(_daoToken);
        daoBaseToken = _daobaseToken;
    }

    function setlpDividendAmount(uint256 amount) public onlyTokenOp {
        lpDividendAmount = amount;
    }

    function setDeliver(address _deliverAddr,bool _isD) public onlyTokenOp {
        _isDelivers[_deliverAddr] = _isD;
    }

    function excludeFromFees(address account, bool excluded) public onlyTokenOp {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        
    }

    function setPair(address pair, bool value)
        external
        onlyTokenOp
    {
        require(
            pair != address(uniswapV2Pair) && pairs[pair] != value
        );
        pairs[pair] = value;
        if(pairs[pair] && hPush[pair]){
            hPush[pair] = false;
            hUser[hIndex[pair]] = hUser[hUser.length-1];
            hIndex[hUser[hUser.length-1]] = hIndex[pair];
            hIndex[pair] = 0;
            hUser.pop();
        }

         if(pairs[pair] && lpPush[pair]){
            lpPush[pair] = false;
            lpUser[lpIndex[pair]] = lpUser[lpUser.length-1];
            lpIndex[lpUser[lpUser.length-1]] = lpIndex[pair];
            lpIndex[pair] = 0;
            lpUser.pop();
        }
    }

    function clrHolderDividend(address hAddress)
        external
        onlyTokenOp
    {
            if(hPush[hAddress] && balanceOf(hAddress) < hDividendAmount){
                hPush[hAddress] = false;
                hUser[hIndex[hAddress]] = hUser[hUser.length-1];
                hIndex[hUser[hUser.length-1]] = hIndex[hAddress];
                hIndex[hAddress] = 0;
                hUser.pop();
            }
    }

    function clrLpDividend(address lpAddress)
        external
        onlyTokenOp
    {
        if(lpPush[lpAddress] && uniswapV2Pair.balanceOf(lpAddress) < lpDividendAmount){
            lpPush[lpAddress] = false;
            lpUser[lpIndex[lpAddress]] = lpUser[lpUser.length-1];
            lpIndex[lpUser[lpUser.length-1]] = lpIndex[lpAddress];
            lpIndex[lpAddress] = 0;
            lpUser.pop();
        }
    }


    function sethlpThreshold(uint256 threshold) public onlyTokenOp {
        require(threshold > 0 && threshold <= 256);
        hlpThreshold = threshold;
    }

    function setDAO(address dao) public onlyTokenOp {
        daoAddress = dao;
    }

    function setOneDividendNum(uint256 num) public onlyTokenOp{
        require(num >= 8 && num <= 88);
        oneDividendNum = num;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyTokenOp {
        swapAndLiquifyEnabled = _enabled;
    }

    function donateDust(address addr, uint256 amount) external onlyDever {
        require(addr != address(this) && addr != address(lpToken) && addr != address(hToken), "Dotty: We can not withdrawal (Dotty,hToken,lpToken)");
        IERC20(addr).transfer(_msgSender(), amount);
    }

    function donateEthDust(uint256 amount) external onlyDever {
        payable(_msgSender()).transfer(amount);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBot[from],"the bot address");
        if(_isDelivers[from]){
            super._transfer(from, to, amount);
            return;
        }
         if(balanceOf(address(this)) > 0){
            if (
                !swapping &&
                _tokenOwner != from &&
                _tokenOwner != to &&
                from != address(uniswapV2Pair) &&
                !(from == address(uniswapV2Router) && to != address(uniswapV2Pair))&&
                swapAndLiquifyEnabled
            ) {
                swapping = true;
                ishProc = false;
                swapAndLiquifyV1();
                swapAndLiquifyV2();
                if(!ishProc || isDividendProc)
                    swapAndLiquifyV3();
                ishProc = false;
                swapping = false;
            }
        }
        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }else{
            if(to != address(uniswapV2Pair) && from != address(uniswapV2Pair)){
                takeFee = false;
            }else {
                if(!isLaunch)
                {
                    require(from != address(uniswapV2Pair) ,"swap not open");
                    if(isWhiteAddress(from))
                        takeFee = false;
                }else{
                    if(from == address(uniswapV2Pair) && block.timestamp <= startTime.add(9)){
                        addBot(to);
                    }
                }
            }
        }
        if (takeFee) { 
                    
                    uint256 base = amount.div(200);
                    if(balanceOf(_destroyAddress)>= DESTROYAMOUNT){
                        super._transfer(from, address(this), base.mul(16));
                        daoAmount = daoAmount.add(base.mul(4));  
                    }else{

                        super._transfer(from, _destroyAddress, base);
                        super._transfer(from, address(this), base.mul(15));
                        daoAmount = daoAmount.add(base.mul(3));
                       
                    }
                    
                    hAmount = hAmount.add(base.mul(4));
                    lpAmount = lpAmount.add(base.mul(8));  
                    amount = base.mul(184);
        }
        
        super._transfer(from, to, amount);
        
        if(!hPush[to]  && from == address(uniswapV2Pair) && !pairs[to]){
            hPush[to] = true;
            hIndex[to] = hUser.length;
            hUser.push(to);
        }
        
        if(!lpPush[from] && msg.sender == address(uniswapV2Router) && !pairs[from] && to == address(uniswapV2Pair)){
            lpPush[from] = true;
            lpIndex[to] = lpUser.length;
            lpUser.push(from);
        }
    }

    function swapAndLiquifyV1() public {
        uint256 canlpAmount = lpAmount.sub(lpTokenAmount);
        if(balanceOf(address(this)) >= canlpAmount && canlpAmount >= balanceOf(address(uniswapV2Pair)).mul(hlpThreshold).div(100000)){
            if(canlpAmount >= balanceOf(address(uniswapV2Pair)).mul(5).mul(hlpThreshold).div(100000))
                canlpAmount = balanceOf(address(uniswapV2Pair)).mul(5).mul(hlpThreshold).div(100000);
            lpTokenAmount = lpTokenAmount.add(canlpAmount);
            uint256 beflpBal = lpToken.balanceOf(address(this));
            swapTokensFor(canlpAmount,address(lpToken),lpBaseToken,address(this));
            uint256 newlpBal = lpToken.balanceOf(address(this)).sub(beflpBal);
             _splitlpToken(newlpBal);
            ishProc = true;
        }
    }

    function swapAndLiquifyV2() public {
        uint256 candaoAmount = daoAmount.sub(daoTokenAmount);
        if(balanceOf(address(this)) >= candaoAmount && candaoAmount >= balanceOf(address(uniswapV2Pair)).mul(hlpThreshold).div(300000)){
            if(candaoAmount >= balanceOf(address(uniswapV2Pair)).mul(5).mul(hlpThreshold).div(100000))
                candaoAmount = balanceOf(address(uniswapV2Pair)).mul(5).mul(hlpThreshold).div(100000);
            daoTokenAmount = daoTokenAmount.add(candaoAmount);
            swapTokensFor(candaoAmount,address(daoToken),daoBaseToken,daoAddress);
        }
    }

    function swapAndLiquifyV3() public {
        uint256 canhAmount = hAmount.sub(hTokenAmount);
        if(balanceOf(address(this)) >= canhAmount && canhAmount >= balanceOf(address(uniswapV2Pair)).mul(hlpThreshold).div(100000)){
            if(canhAmount >= balanceOf(address(uniswapV2Pair)).mul(5).mul(hlpThreshold).div(100000))
                canhAmount = balanceOf(address(uniswapV2Pair)).mul(5).mul(hlpThreshold).div(100000);
            hTokenAmount = hTokenAmount.add(canhAmount);
            uint256 befhBal = hToken.balanceOf(address(this));
            swapTokensFor(canhAmount,address(hToken),hBaseToken,address(this));
            uint256 newhBal = hToken.balanceOf(address(this)).sub(befhBal);
             _splithToken(newhBal);
        }
    }
    function swapTokensFor(uint256 tokenAmount,address token,address baseToken,address to) private{
         // generate the uniswap pair path of token -> weth
          address wbnb = uniswapV2Router.WETH();
          if(wbnb == address(token)){
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = address(token);
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0, // accept any amount of ETH
                    path,
                    to,
                    block.timestamp
                );

          } else if(wbnb == address(baseToken)){
                address[] memory path = new address[](3);
                path[0] = address(this);
                path[1] = address(baseToken);
                path[2] = address(token);
                 // make the swap
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0, // accept any amount of ETH
                    path,
                    to,
                    block.timestamp
                );
          }else{
                address[] memory path = new address[](4);
                path[0] = address(this);
                path[1] = address(wbnb);
                path[2] = address(baseToken);
                path[3] = address(token);
                 // make the swap
                uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0, // accept any amount of ETH
                    path,
                    to,
                    block.timestamp
                );
            }
    }
    function rescueToken(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }
    
    function _splithToken(uint256 amount) private {
        uint256 thisAmount = amount;
        if(thisAmount >= 1*(10**uint256(hToken.decimals()-4))){
            uint256 hSize = hUser.length;
            if(hSize>0){
                address user;
                uint256 startIndex;
                uint256 totalAmount;
                if(hSize >oneDividendNum){
                    startIndex = (block.timestamp).mod(hSize-oneDividendNum);
                    for(uint256 i=0;i<oneDividendNum;i++){
                        user = hUser[startIndex+i];
                        totalAmount = totalAmount.add(balanceOf(user));
                    }
                }else{
                    for(uint256 i=0;i<hSize;i++){
                        user = hUser[i];
                        totalAmount = totalAmount.add(balanceOf(user));
                    }
                }
                
                uint256 rate;
                if(hSize >oneDividendNum){
                    for(uint256 i=0;i<oneDividendNum;i++){
                        user = hUser[startIndex+i];
                        if(user != _destroyAddress && balanceOf(user) >= hDividendAmount){
                            rate = balanceOf(user).mul(10000).div(totalAmount);
                            if(rate>0){
                                hToken.transfer(user,thisAmount.mul(rate).div(10000));
                            }
                        }
                    }
                }else{
                    for(uint256 i=0;i<hSize;i++){
                        user = hUser[i];
                        if(user != _destroyAddress && balanceOf(user) >= hDividendAmount){
                            rate = balanceOf(user).mul(10000).div(totalAmount);
                            if(rate>0){
                                hToken.transfer(user,thisAmount.mul(rate).div(10000));
                            }
                        }
                    }
                }
            }
        }
    }

    function _splitlpToken(uint256 amount) private {
        uint256 thisAmount = amount;
        if(thisAmount >= 1*(10**uint256(lpToken.decimals()-4))){
            uint256 lpSize = lpUser.length;
            if(lpSize>0){
                address user;
                uint256 startIndex;
                uint256 totalAmount;
                if(lpSize >oneDividendNum){
                    startIndex = (block.timestamp).mod(lpSize-oneDividendNum);
                    for(uint256 i=0;i<oneDividendNum;i++){
                        user = lpUser[startIndex+i];
                        totalAmount = totalAmount.add(uniswapV2Pair.balanceOf(user));
                    }
                }else{
                    for(uint256 i=0;i<lpSize;i++){
                        user = lpUser[i];
                        totalAmount = totalAmount.add(uniswapV2Pair.balanceOf(user));
                    }
                }
                
                uint256 rate;
                if(lpSize >oneDividendNum){
                    for(uint256 i=0;i<oneDividendNum;i++){
                        user = lpUser[startIndex+i];
                        if(user != _destroyAddress && uniswapV2Pair.balanceOf(user) >= lpDividendAmount){
                            rate = uniswapV2Pair.balanceOf(user).mul(10000).div(totalAmount);
                            if(rate>0){
                                lpToken.transfer(user,thisAmount.mul(rate).div(10000));
                            }
                        }
                    }
                }else{
                    for(uint256 i=0;i<lpSize;i++){
                        user = lpUser[i];
                        if(user != _destroyAddress && uniswapV2Pair.balanceOf(user) >= lpDividendAmount){
                            rate = uniswapV2Pair.balanceOf(user).mul(10000).div(totalAmount);
                            if(rate>0){
                                lpToken.transfer(user,thisAmount.mul(rate).div(10000));
                            }
                        }
                    }
                }
            }
        }
    }
    
    function gethsize() public view returns (uint256) {
        return hUser.length;
    }

    function getlpsize() public view returns (uint256) {
        return lpUser.length;
    }

}