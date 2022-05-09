/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();
  event PauserChanged(address indexed newAddress);


  address public pauser;
  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev throws if called by any account other than the pauser
   */
  modifier onlyPauser() {
    require(msg.sender == pauser);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyPauser public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyPauser public {
    paused = false;
    emit Unpause();
  }

  /**
   * @dev update the pauser role
   */
  function updatePauser(address _newPauser) onlyOwner public {
    require(_newPauser != address(0));
    pauser = _newPauser;
    emit PauserChanged(pauser);
  }

}

contract Blacklistable is Ownable {

    address public blacklister;
    mapping(address => bool) internal blacklisted;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    /**
     * @dev Throws if called by any account other than the blacklister
    */
    modifier onlyBlacklister() {
        require(msg.sender == blacklister);
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param _account The address to check
    */
    modifier notBlacklisted(address _account) {
        require(blacklisted[_account] == false);
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check    
    */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
    */
    function blacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
    */
    function unBlacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister) public onlyOwner {
        require(_newBlacklister != address(0));
        blacklister = _newBlacklister;
        emit BlacklisterChanged(blacklister);
    }
}

interface IUniswapV2Router02 {
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
    returns (uint[] memory amounts);
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
        ) external returns (uint amountA, uint amountB);
     
    function WETH() external pure returns(address);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
   

     
    
}

interface IUniswapV2Factory {

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

contract UUSD is Ownable, Pausable, Blacklistable, ERC20 {
    using SafeMath for uint256;
    IERC20 usdcToken;
    IERC20 usdtToken;
    IERC20 daiToken;
    IERC20 waterToken;

  
    //address private constant USDC_address = address(0x060aD346b830ee4c5CA128d957d17C4D8807Dc11); //ropsten USDC ADDRESS
    //address private constant DAI_address = address(0x014b42dC75B130b8346759Fe05444aDE61F2FbD1); //ropsten DAI ADDRESS
    //address private constant USDT_address = address (0xdAC17F958D2ee523a2206206994597C13D831ec7); //ropsten USDT address
    address private constant FACTORY_CONTRACT = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); //ropsten
    address private constant UNISWAP_V2_ROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //ropsten address

    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Factory public uniswapFactory;
    address vault;
    uint256 usdc_balance;
    uint256 usdt_balance;
    uint256 dai_balance;
    
    mapping(address => bool) whitelist;


    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);
    event Log(string _message, uint _amount);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    constructor(address _vault, IERC20 _usdt, IERC20 _usdc, IERC20 _dai, IERC20 _water) ERC20("Wrapped USD", "UUSD")  {
        uniswapRouter = IUniswapV2Router02(UNISWAP_V2_ROUTER);
        uniswapFactory = IUniswapV2Factory(FACTORY_CONTRACT);
        vault = _vault;
        usdtToken = _usdt;
        usdcToken = _usdc;
        daiToken = _dai;
        waterToken = _water;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    //Burn UUSD Token 
    // OnlyOwner function
    function burnUUSD(uint256 _amount) external onlyOwner {
        _burn(msg.sender,_amount);
    }

    //Buy UUSD using WATER Token
    function buyUUSD(address _token, uint256 _amount) external onlyOwner {
        require(IERC20(_token) == waterToken,"TOKEN IS INVALID");
        ERC20(_token).transferFrom(msg.sender, vault, _amount); // address(this) --> vault
        _mint(msg.sender, _amount);
    }

    function buy(address _token,uint256 _amount) external payable {
        
        //For stable coins we are minting same amount of tokens
        //For whitelisting users only.
        if(isWhitelisted(_token)){ 
            ERC20(_token).transferFrom(msg.sender, vault, _amount); // address(this) --> vault
            _mint(msg.sender, _amount);
        }
        else{
            if(msg.value > 0){
                uint256 values  = msg.value;
                uint deadline = block.timestamp + 150;
                address[] memory path = new address[](2);
                path[0] = uniswapRouter.WETH();
                path[1] = address(usdcToken);
               uint[] memory swappedTokenAmount = uniswapRouter.swapETHForExactTokens{value:values}(_amount, path, vault, deadline); // address(this) --> vault
                _mint(msg.sender, swappedTokenAmount[1]);
        
                (bool success,) = msg.sender.call{ value: address(this).balance }("");
                require(success, "refund failed");
            }
            else{
                uint swappedTokenAmount = swap(_token,_amount);
                _mint(msg.sender, swappedTokenAmount);
            }
               
        }
    }
    
    function swap(address _swapToken,uint256 _amountIn) internal returns(uint){

        address pair1 = uniswapFactory.getPair(_swapToken, address(usdcToken)); //check pair with US
        if(pair1!= address(0)){
            uint deadline = block.timestamp + 250;
            address[] memory path = new address[](2);
            path[0] = _swapToken;
            path[1] = address(usdcToken);
            IERC20(_swapToken).transferFrom(msg.sender,address(this),_amountIn);
            IERC20(_swapToken).approve(UNISWAP_V2_ROUTER,_amountIn);
            uint[] memory result = uniswapRouter.swapTokensForExactTokens(_amountIn, 0, path, vault, deadline); // address(this) --> vault
            return result[1]; 
           
            
        }else{
            uint deadline = block.timestamp + 150;
            address[] memory path = new address[](2);
            path[0] = _swapToken;
            path[1] = address(daiToken);
            IERC20(_swapToken).transferFrom(msg.sender,address(this),_amountIn);
            IERC20(_swapToken).approve(UNISWAP_V2_ROUTER,_amountIn);
            uint[] memory result = uniswapRouter.swapTokensForExactTokens(_amountIn, 0, path, vault, deadline); // address(this) --> vault
            return result[1]; 
        }
    }   

 
        // USDC-USDT
        // USDC-DAI
        // USDT-DAI
    function settleAmount() external onlyOwner {
        usdc_balance = usdcToken.balanceOf(vault);
        usdt_balance = usdtToken.balanceOf(vault);
        dai_balance = daiToken.balanceOf(vault);

        usdcToken.approve(UNISWAP_V2_ROUTER, usdc_balance);
        usdtToken.approve(UNISWAP_V2_ROUTER, usdt_balance);
        daiToken.approve(UNISWAP_V2_ROUTER, dai_balance);

        //require(checkAllPairs(address(usdcToken), address(usdtToken), address(daiToken)),"Pair of Token is not possible");
        (uint256 _amountA, uint256 _amountB, uint256 _LPAmountA) = uniswapRouter.addLiquidity(
            address(usdcToken),
            address(usdtToken),
            usdc_balance,
            usdt_balance, 
            1, 
            1, 
            vault, // address(this) --> vault
            block.timestamp + 150
        );

        emit Log("amount", _amountA);
        emit Log("amount", _amountB);
        emit Log("liquidity", _LPAmountA);

        (uint256 _amountC, uint256 _amountD, uint256 _LPAmountC) = uniswapRouter.addLiquidity(
            address(usdcToken),
            address(daiToken),
            usdc_balance,
            dai_balance, 
            1, 
            1, 
            vault, // address(this) --> vault
            block.timestamp + 150
        );

        emit Log("amount", _amountC);
        emit Log("amount", _amountD);
        emit Log("liquidity", _LPAmountC);

        (uint256 _amountE, uint256 _amountF, uint256 _LPAmountE) = uniswapRouter.addLiquidity(
            address(usdtToken),
            address(daiToken),
            usdt_balance,
            dai_balance, 
            1, 
            1, 
            vault,  // address(this) --> vault
            block.timestamp + 150
        );

        emit Log("amount", _amountE);
        emit Log("amount", _amountF);
        emit Log("liquidity", _LPAmountE);
    }  

    function removeLiquidity(address _tokenA, address _tokenB) external onlyOwner {
        address pair = uniswapFactory.getPair(_tokenA, _tokenB);

        uint liquidity = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(UNISWAP_V2_ROUTER, liquidity);

        (uint amountA, uint amountB) =
        uniswapRouter.removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            1,
            1,
            vault,
            block.timestamp
        );

        emit Log("amountA", amountA);
        emit Log("amountB", amountB);
    }

    //_USDC_address = USDC
    //_DAI_address = USDT
    //_token3 = DAI
    // function checkAllPairs(address _USDC_address, address _DAI_address, address _token3) internal returns(bool){
    //     address _tokenPair1 = uniswapFactory.getPair(_USDC_address,_DAI_address);
    //     address _tokenPair2 = uniswapFactory.getPair(_USDC_address,_token3); 
    //     address _tokenPair3 = uniswapFactory.getPair(_DAI_address,_token3); 
    //     if(_tokenPair1 == address(0)){
    //         _tokenPair1 = uniswapFactory.createPair(_USDC_address, _DAI_address); //USDC - USDT
    //     }if(_tokenPair2 == address(0)){
    //         _tokenPair2 = uniswapFactory.createPair(_USDC_address, _token3); //USDC - DAI
    //     }if(_tokenPair3 == address(0)){
    //         _tokenPair3 = uniswapFactory.createPair(_DAI_address, _token3); //USDT - DAI
    //     }
    //     return true;
    // }
   
    function setVaultAddress(address _vault) external onlyOwner returns(bool){
        vault = _vault;
        return true;
    }    
    
    function burn(uint _amount) external payable{
        checkBalance(_amount);
        //payable(msg.sender).transfer(_amount); 
        _burn(msg.sender, _amount);
    }

    function checkBalance(uint256 _amount) internal {
        uint256 equalReturnAmount = _amount.mul(33).div(100);
        uint256 fiftyFiftyReturnAmount = _amount.mul(50).div(100);
        if((usdcToken.balanceOf(vault) > equalReturnAmount && (usdtToken.balanceOf(vault) > equalReturnAmount) && (daiToken.balanceOf(vault) > equalReturnAmount))){
            usdcToken.transferFrom(vault, msg.sender, equalReturnAmount);
            usdtToken.transferFrom(vault, msg.sender, equalReturnAmount);
            daiToken.transferFrom(vault, msg.sender, equalReturnAmount);

        }else if((usdcToken.balanceOf(vault) < equalReturnAmount) && (usdtToken.balanceOf(vault) > equalReturnAmount) && (daiToken.balanceOf(vault) > equalReturnAmount)){

            usdtToken.transferFrom(vault, msg.sender, fiftyFiftyReturnAmount);
            daiToken.transferFrom(vault, msg.sender, fiftyFiftyReturnAmount);
            

        }else if((usdcToken.balanceOf(vault) > equalReturnAmount) && (usdtToken.balanceOf(vault) < equalReturnAmount) && (daiToken.balanceOf(vault) > equalReturnAmount)){
            usdcToken.transferFrom(vault, msg.sender, fiftyFiftyReturnAmount);
            daiToken.transferFrom(vault, msg.sender, fiftyFiftyReturnAmount);
            

        }else if((usdcToken.balanceOf(vault) > equalReturnAmount) && (usdtToken.balanceOf(vault) > equalReturnAmount) && (daiToken.balanceOf(vault) < equalReturnAmount)){
            usdtToken.transferFrom(vault, msg.sender, fiftyFiftyReturnAmount);
            usdcToken.transferFrom(vault, msg.sender, fiftyFiftyReturnAmount);
            

        }else if((usdcToken.balanceOf(vault) < equalReturnAmount) && (usdtToken.balanceOf(vault) < equalReturnAmount) && (daiToken.balanceOf(vault) > equalReturnAmount)){
            daiToken.transferFrom(vault, msg.sender, _amount);
           

        }else if((usdcToken.balanceOf(vault) < equalReturnAmount) && (usdtToken.balanceOf(vault) > equalReturnAmount) && (daiToken.balanceOf(vault) < equalReturnAmount)){
            usdtToken.transferFrom(vault, msg.sender, _amount);
            

        }else if((usdcToken.balanceOf(vault) > equalReturnAmount) && (usdtToken.balanceOf(vault) < equalReturnAmount) && (daiToken.balanceOf(vault) < equalReturnAmount)){
            usdcToken.transferFrom(vault, msg.sender, _amount);
            
            
        }

    }

    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }


    function withdraw(address _recipient) public payable onlyOwner {    
    payable(_recipient).transfer(address(this).balance);
    }

    receive() payable  external {}




}