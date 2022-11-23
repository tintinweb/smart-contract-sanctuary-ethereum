/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint8 private _setupDecimals = 18;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = _setupDecimals;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
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
    */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) virtual public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) virtual public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender) virtual public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) virtual public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom (address sender, address recipient, uint256 amount) virtual public override returns (bool) {
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
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero'));
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    // function mint(uint256 amount) public onlyOwner returns (bool) {
    //     _mint(_msgSender(), amount);
    //     return true;
    // }

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
    function _transfer (address sender, address recipient, uint256 amount) virtual internal {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

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
    function _mint(address account, uint256 amount) virtual internal {
        require(account != address(0), 'ERC20: mint to the zero address');

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
    function _burn(address account, uint256 amount) virtual internal {
        require(account != address(0), 'ERC20: burn from the zero address');

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
    function _approve (address owner, address spender, uint256 amount) virtual internal {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    // function _burnFrom(address account, uint256 amount) virtual internal {
    //     _burn(account, amount);
    //     _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'ERC20: burn amount exceeds allowance'));
    // }
}

contract CrypterToken is ERC20 {
    
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Addresses excluded from fees
    mapping (address => bool) public isExcludedFromFee;

    // Addresses that are black listed
    mapping (address => bool) public isBlackListed;

    // Addresses that are excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;

    mapping (address => bool) public automatedMarketMakerPairs;

    uint16 public maxHoldingRate = 300; 

    uint8 public stakingFee = 20; // 2%
    uint8 public teamFee = 20; // 2%
    uint8 public marketingFee = 20; // 2%
    uint8 public totalFee = 60; // 6%
    uint8 public constant MAXFEE = 100; // 10%

    uint256 public minSwapAmount = 10000000000000000000;   //10 CRYPT tokens

    address public stakingContract = 0x8E6d9456947730cafE572C494dD32dD4dd705Ab1;
    address public marketingWallet = 0xa6508c6e3B90871E23980B3E00BBe0305088244B;
    address public rewardWallet = 0x42567B693B651Bf1d94d92C2F9EB3F2d8102335B;

    uint256 initialSupply = 100000000000 ether;

    // Trading bool
    bool public tradingOpen; 

    // Enable MaxHolding mechanism
    bool public maxHoldingEnable = true; // INMUTABLE

    // In swap and liquify
    bool private _inSwap;

    // Automatic swap and liquify enabled
    bool public swapEnabled = true; // INMUTABLE

    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD; // INMUTABLE

    // STABLE Token address
    address public STABLE;
    
    // Events before Governance
    event MaxHoldingEnableUpdated(address indexed operator, bool enabled);
    event MaxHoldingRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapToStable(address stableAddress, uint256 amount, address receiver);
    event SwapToETH(address ETH, uint256 amount, address receiver);
    event SetTaxAddresses(address stakingAddress, address rewardAddress, address marktingAddress);
    event SetTaxFee(uint8 stakingAddress, uint8 rewardAddress, uint8 marktingAddress);
    event SetExcludedFromAntiWhale(address indexed account, bool indexed whaleExcluded);
    event SetExcludeFromFee(address indexed account, bool indexed feeExcluded);
    event SetBlackList(address indexed account, bool indexed listed);
    event UpdateSTABLE(address stable);
    
    // Lock the swap on SwapAndLiquify
    modifier lockTheSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        // Is maxHolding enabled?
        if(maxHoldingEnable) {
            if (maxHolding() > 0 && sender != owner() && recipient != owner()) {
                if ( _excludedFromAntiWhale[recipient] == false ) {
                    require(amount <= maxHolding() - balanceOf(recipient) && balanceOf(recipient) <= maxHolding(), "CRYPT::antiWhale: Transfer amount would result in a balance bigger than the maxHoldingRate");
                }
            }
        }
        
        _;
    }

    /**z
     * @notice Constructs the PAL token contract.
     */
    constructor(address _router, address _stable) ERC20("CrypterToken", "CRYPT") {

        _mint(msg.sender, initialSupply);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        STABLE = _stable;

        setExcludeFromFee(msg.sender, true);
        setExcludeFromFee(address(0), true);
        setExcludeFromFee(address(this), true);
        setExcludeFromFee(address(uniswapV2Router), true);
        setExcludeFromFee(address(BURN_ADDRESS), true);

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[address(uniswapV2Router)] = true;
        _excludedFromAntiWhale[address(BURN_ADDRESS)] = true;
    }

    /// @dev overrides transfer function to meet tokenomics of PAL
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        // Pre-flight checks
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap  = contractBalance >= minSwapAmount;
        if( 
            tradingOpen == true
            && swapEnabled == true 
            && _inSwap == false
            && canSwap
            && !automatedMarketMakerPairs[sender]
            && sender != owner() 
        ) {
            swapBack();
        }
        if (sender == owner() || recipient == owner() || totalFee == 0 || isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            require(tradingOpen == true, "CRYPT:: Trading is not yet open.");
            require(!isBlackListed[sender] && !isBlackListed[recipient], "CRYPT:: Black listed");

            uint256 sendAmount = amount;
            uint256 feeAmount;
            //Buy || Sell Token
            if(automatedMarketMakerPairs[sender] || automatedMarketMakerPairs[recipient]) {
                feeAmount = amount.mul(totalFee).div(1000);
                sendAmount = amount.sub(feeAmount);
            }
            if(feeAmount > 0) {
                super._transfer(sender, address(this), feeAmount);
            }
            super._transfer(sender, recipient, sendAmount);
        }
    }


    function swapBack() private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 stakingFeeAmount = contractTokenBalance.mul(stakingFee).div(totalFee);
        uint256 marketingFeeAmount = contractTokenBalance.mul(marketingFee).div(totalFee);
        uint256 teamRewardAmount = contractTokenBalance.sub(stakingFeeAmount).sub(marketingFeeAmount);

        swapToStable(stakingFeeAmount, stakingContract);
        swapToETH(marketingFeeAmount, marketingWallet);
        super._transfer(address(this), rewardWallet, teamRewardAmount);
    }

    function swapToStable(uint256 _amount, address _receiver) internal {
        address[] memory path;
        path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = STABLE;
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            _receiver,
            block.timestamp + 400
        );

        emit SwapToStable(STABLE, _amount, _receiver);
    }

    function swapToETH(uint256 _amount, address _receiver) internal {
        address[] memory path;
        path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            _receiver,
            block.timestamp + 400
        );

        emit SwapToETH(uniswapV2Router.WETH(), _amount, _receiver);
    }
   
    /**
     * @dev Returns the max holding amount.
     */
    function maxHolding() public view returns (uint256) {
        uint256 cap = totalSupply();
        return cap.mul(maxHoldingRate).div(1000000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

    /** 
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the current operator.
     */
    function setExcludedFromAntiWhale(address _account, bool _bool) public onlyOwner {
        _excludedFromAntiWhale[_account] = _bool;
        emit SetExcludedFromAntiWhale(_account, _bool);
    }

    /** NO NEED TO CHANGE MAX HOLDING ENABLED
     * @dev Enable / Disable Max Holding Mechanism.
     * Can only be called by the current operator.
     */
    function updateMaxHoldingEnable(bool _enabled) public onlyOwner {
        emit MaxHoldingEnableUpdated(msg.sender, _enabled);
        maxHoldingEnable = _enabled;
    }

    function updateMaxHoldingRate(uint16 _maxHoldingRate) public onlyOwner {
        require(_maxHoldingRate >= 100, "CRYPT::updateMaxHoldingRate: Max holding rate must not be below the minimum rate.");
        emit MaxHoldingRateUpdated(msg.sender, maxHoldingRate, _maxHoldingRate);
        maxHoldingRate = _maxHoldingRate;
    }

    function openTrading() public onlyOwner {
        // Can open trading only once!
        tradingOpen = true;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setExcludeFromFee(address _account, bool _bool) public onlyOwner {
        isExcludedFromFee[_account] = _bool;
        emit SetExcludeFromFee(_account, _bool);
    }

    function setBlackList(address _account, bool _bool) public onlyOwner {
        isBlackListed[_account] = _bool;
        emit SetBlackList(_account, _bool);
    }

    function updateMinSwapAmount(uint256 _minSwapAmount) public onlyOwner {
        minSwapAmount = _minSwapAmount;
    }

    function updateSTABLE(address _stable) public onlyOwner {
        require(_stable != address(0), "CRYPT:: updateSTABLE: STABLE address is zero address");
        STABLE = _stable;
        emit UpdateSTABLE(_stable);
    }

    function enableSwapToken(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function setTaxAddresses(address _staking, address _rewardWallet, address _marketingWallet) public onlyOwner {
        require(_staking != address(0), "CRYPT:: setTaxAddresses: Staking address is zero address");
        require(_rewardWallet != address(0), "CRYPT:: setTaxAddresses: Reward address is zero address");
        require(_marketingWallet != address(0), "CRYPT:: setTaxAddresses: Market address is zero address");

        stakingContract = _staking;
        rewardWallet = _rewardWallet;
        marketingWallet = _marketingWallet;

        emit SetTaxAddresses(_staking, _rewardWallet, _marketingWallet);
    }

    function setTaxFee(uint8 _stakingFee, uint8 _teamFee, uint8 _marketingFee) public onlyOwner {
        require(_stakingFee + _teamFee + _marketingFee < MAXFEE, "CRYPT:: setTaxFee: Max Fee is reached");
        stakingFee = _stakingFee;
        teamFee = _teamFee;
        marketingFee = _marketingFee;
        totalFee = stakingFee + teamFee + marketingFee;

        emit SetTaxFee(_stakingFee, _teamFee, _marketingFee);
    }
}