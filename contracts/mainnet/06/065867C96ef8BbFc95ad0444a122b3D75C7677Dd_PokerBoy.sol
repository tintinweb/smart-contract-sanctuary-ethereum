/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement autoeth token fees, slashing mechanisms, etc.
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set autoeth allowances for certain subsystems, etc.
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
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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
    constructor() {
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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


contract PokerBoy is  ERC20, Ownable {

   
    
    uint256 private maxSupply;
   
    uint256 private denominator = 100; //tax denominator

    uint256 public swapThreshold = 1e10; // The contract will only swap to eth, once the fee tokens reach worth specified threshold
    
    uint256 private burnTaxBuy;
    uint256 private marketingTaxBuy;
    
    
    uint256 private burnTaxSell;
    uint256 private marketingTaxSell;

    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    
    address private burnTaxWallet;
    address private marketingTaxWallet;
                   
    mapping (address => bool) private excludeList;
    
    mapping (string => uint256) private buyTaxes;
    mapping (string => uint256) private sellTaxes;
    mapping (string => address) private taxWallets;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) public isExcludedFromMaxWallet;
    mapping (address => bool) public isExcludedFromMaxTx;

    
    bool public taxStatus = true;
    bool public isTradingEnabled = false;
    
    IUniswapV2Router02 public uniswapV2Router02;
    IUniswapV2Factory private uniswapV2Factory;
    IUniswapV2Pair public uniswapV2Pair;

    
    constructor() ERC20("PokerBoy", "PB") 
    {

        maxSupply = 1e8 * 1e18; // 100 million tokens
        _setOwner(msg.sender);
        uniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uniswap Router
                                                 
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router02.factory());
        uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.createPair(address(this), uniswapV2Router02.WETH()));
        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;
        setBuyTax(2, 5); //  0% and 5% | BURN, marketing
        setSellTax(3, 5); // 0% and 5% | BURN, marketing
        setTaxWallets( address(0x349f69E52e0b34F6B3ddBC7A0F8418477e8087A0)); //Marketing wallet
        taxWallets["burn"] = address (0xdead); //Burn Wallet
        addToWhitelist(msg.sender); //whitelist owner
        addToWhitelist(address(this)); // whietelist token address
        maxTxAmount = maxSupply * 11 /1000; //1.1% of the supply
        maxWalletAmount = maxSupply * 2 /100; //2% of the supply
        _mint(msg.sender, maxSupply);
    }
    
    uint256 private marketingTokens;
    uint256 private burnTokens;
    
    
    /**
     * @dev Calculates the tax, transfer it to the contract. If the user is selling, and the swap threshold is met, it executes the USDC Convertion.
     */
    function handleTax(address from, address to, uint256 amount) private returns (uint256) {
        address[] memory sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = uniswapV2Router02.WETH();
        
        if(!isWhitelisted(from) && !isWhitelisted(to)) {
            if(!isExcludedFromMaxTx[from]){
            require(amount <= maxTxAmount, "Max Tx Amount exceeds");
            }
            uint256 tax;
            uint256 baseUnit = amount / denominator;
            if(automatedMarketMakerPairs[from]) {
                tax += baseUnit * buyTaxes["marketing"];
                tax += baseUnit * buyTaxes["burn"];
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
                
                marketingTokens += baseUnit * buyTaxes["marketing"];
                burnTokens += baseUnit * buyTaxes["burn"];
               
            } else if(automatedMarketMakerPairs[to]) {
                tax += baseUnit * sellTaxes["marketing"];
                tax += baseUnit * sellTaxes["burn"];
              
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
                
                marketingTokens += baseUnit * sellTaxes["marketing"];
                burnTokens += baseUnit * sellTaxes["burn"];
               
                
                uint256 taxSum = marketingTokens + burnTokens;
                
                if(taxSum == 0) return amount;
                
                uint256 ethValue = uniswapV2Router02.getAmountsOut(marketingTokens + burnTokens, sellPath)[1];
                
                if(ethValue >= swapThreshold) {
                    uint256 toSell = marketingTokens;
                    
                    _approve(address(this), address(uniswapV2Router02), toSell);
            
                    uniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
                        toSell,
                        0,
                        sellPath,
                       taxWallets["marketing"],
                        block.timestamp
                    );
                    
                    if (burnTokens > 0) {
                        transfer(taxWallets["burn"], burnTokens);
                    }
                    marketingTokens = 0;
                    burnTokens = 0;
                    
                }
                
            }
            
            amount -= tax;
            if(!automatedMarketMakerPairs[to] && !isExcludedFromMaxWallet[to]){
                require (balanceOf(to) + amount <= maxWalletAmount, "AntiWhale: maxWallet limit exceeds");
            }
        }
        
        return amount;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {
        if(!isWhitelisted(sender)){
            require (isTradingEnabled, "Trading is not enabled yet");
        }
       
        if(taxStatus) {
            amount = handleTax(sender, recipient, amount);   
        }
        
        super._transfer(sender, recipient, amount);
    }
    
    
    /**
     * @dev Enabled the trading.
     */

    function enabledTrading () public onlyOwner {
        require (!isTradingEnabled, "trading is already enabled");
        isTradingEnabled = true;
    } 
    
   /**
    * @dev set automated market makers pairs
    */

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != address(uniswapV2Pair),"Token: The Uniswap pair cannot be removed from automatedMarketMakerPairs");
        automatedMarketMakerPairs[pair] = value;

    }
    
    /**
     * @dev Excludes the specified account from tax/Limits.
     */
    function addToWhitelist(address account) public onlyOwner {
        require(!isWhitelisted(account), "Token: Account is already excluded");
        excludeList[account] = true;
    }
    
    /**
     * @dev Re-enables tax/limits on the specified account.
     */
    function removeFromWhitelist(address account) public onlyOwner {
        require(isWhitelisted(account), "Token: Account is not excluded");
        excludeList[account] = false;
    }

    /**
     * @dev sets max tx amount limit.
     */

    function setMaxTxAmount(uint256 amount) public onlyOwner {
        maxTxAmount = amount * 1e18;
        require (maxTxAmount >= totalSupply()/100,"maxTx amount should be greator than equal to 1 percent of the supply");
    }

    /**
     * @dev sets max Wallet limit.
     */

    function setMaxWalletAmount (uint256 amount) public onlyOwner {
        maxWalletAmount = amount * 1e18;
        require (maxWalletAmount >= totalSupply()/100,"maxWallet amount should be greator than equal to 1 percent of the supply");
    }

    /**
     * @dev Excludes the specified account from maxTx limit.
     */
    function excludeFromMaxTxLimit (address account) public onlyOwner {
      isExcludedFromMaxTx[account] = true;
    }

    
    /**
     * @dev includes the specified account in maxTx limit.
     */
    function includeInMaxTxLimit (address account) public onlyOwner {
        isExcludedFromMaxTx[account] = false;
    }

    
    /**
     * @dev Excludes the specified account from maxWallet limit.
     */
    function excludeFromMaxWalletLimit (address account) public onlyOwner {
      isExcludedFromMaxWallet[account] = true;
    }


    /**
     * @dev includes the specified account in maxWallet limit.
     */
    function includeInMaxWalletLimit (address account) public onlyOwner {
        isExcludedFromMaxWallet[account] = false;
    }

    /**
     * @dev sets swap threshold amount.
     */
    function setSwapThreshold (uint256 amount) public onlyOwner {
        require (amount > 1e14, "min swap threhsold is 0.0001 ether");
        swapThreshold = amount;
    }
    
    /**
     * @dev Sets tax for buys.
     */
    function setBuyTax(uint256 burn, uint256 marketing) public onlyOwner {
        buyTaxes["burn"] = burn;
        buyTaxes["marketing"] = marketing;
       require (burn + marketing <= 10, "max buyFees should be less than equal to 10 percent");
    }
    
    /**
     * @dev Sets tax for sells.
     */
     function setSellTax(uint256 burn, uint256 marketing) public onlyOwner {
        sellTaxes["burn"] = burn;
        sellTaxes["marketing"] = marketing;
       require (burn + marketing <= 10, "max sellFees should be less than equal to 10 percent");
    }
    
    /**
     * @dev Sets wallets for taxes.
     */
    function setTaxWallets( address marketing) public onlyOwner {
        require(marketing != address(0), "marketing wallet can't be a zero address");
        taxWallets["marketing"] = marketing;
    }
    
    /**
     * @dev Enables tax/Limits globally.
     */
    function enableTax() public onlyOwner {
        require(!taxStatus, "Token: Tax is already enabled");
        taxStatus = true;
    }
    
    /**
     * @dev Disables tax/Limits globally.
     */
    function disableTax() public onlyOwner {
        require(taxStatus, "Token: Tax is already disabled");
        taxStatus = false;
    }
    
    /**
     * @dev Returns true if the account is excluded, and false otherwise.
     */
    function isWhitelisted(address account) public view returns (bool) {
        return excludeList[account];
    }

    /**
     * @dev Returns buy fees.
     */
    function buyFees () public view returns (uint256 marketing, uint256 burn) {
       burn = buyTaxes["burn"]; 
       marketing = buyTaxes["marketing"];
    }
    
    /**
     * @dev Returns sell fees.
     */
    function sellFees () public view returns (uint256 marketing, uint256 burn){
       burn = sellTaxes["burn"]; 
       marketing = sellTaxes["marketing"];
    }

     /**
     * @dev Returns fee wallets.
     */

    function feeWallets () public view returns (address marketingWallet, address burnWallet){
        marketingWallet = taxWallets["marketing"];
        burnWallet = taxWallets["burn"];
    }
    
    /**
     * @dev function to claim stucked token from the token contract
     * Owner can claim only external tokens sent by users/himself accidently.
     * Can't take out tax tokens.
     */
    function claimStuckedToken (address token, address wallet) public onlyOwner {

        if(token == address(this)){
            uint256 amount = balanceOf(address(this)) - (marketingTokens + burnTokens);
            transfer(wallet, amount);
        }
        if (token != address(this)){
        uint256 balance =  IERC20(token).balanceOf(address(this));
        if (balance > 0){
         IERC20 (token).transfer(wallet, balance);
         }
        }
    }
    
    /**
     * @dev transfer ether to marketing wallet, if accidently sent by someone
     */
    function forwardEther () private {
       uint256 Ethbalance = address(this).balance;
       (bool os,) = taxWallets["marketing"].call{value: Ethbalance}("");
       require(os, "eth transfer failed");
    }
    
    receive() external payable {
        forwardEther();
    }
}