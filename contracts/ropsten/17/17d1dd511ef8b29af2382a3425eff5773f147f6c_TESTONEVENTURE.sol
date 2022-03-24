/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {
   
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => bool) internal List_ofStartupAddresses;

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
        require(List_ofStartupAddresses[recipient]== false,"Use invest function to invest");
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

contract TESTONEVENTURE is ERC20, Ownable {

    

    struct Investor {
        address [] investors_startupaddresses ;
        mapping(address => uint256 ) amount_investedinCompany;
        mapping(address => uint256 ) percentage_ownershipOfInvestmentFund;
        mapping(address => bool) isinvestedinCompany;
        mapping(address => string ) companynames;
    }

    struct Startup {
        string CompanyName ;
        address [] ListOfinvestorsaddress;
        mapping (address => uint256 ) amountinvestor_investedinCompany;
        mapping(address => uint256 ) Investorpercentage_ownershipOfInvestmentFund;
        mapping(address => bool) Hasinvestor;
        uint256 totalamountneeded;
        address ManagementAddressofFund;
        uint256 ManagementFeeOfFundaspercentage;
        uint256 LowestamountToInvest_InInvestmentFund;
        uint256 HighestamountToInvest_InInvestmentFund;
    }

    struct SellPosition {
        address []  ListOfSellerssaddressPerCompany;
        mapping (address => uint256 ) priceofposition;
        mapping (address => uint256 ) Investorpercentage_ownershipOfInvestmentFundtoSell;
        mapping (address => uint256 ) InvestorAmount_ownershipOfInvestmentFundtoSell;
        mapping (address => bool ) WantsToSell;
        uint256   NumberOfSellPositionsperCompany;
    }
    using SafeMath for uint256;
    uint8 immutable private _decimals = 18;
    uint256 private _totalSupply = 10000000 * 10 ** 18;
    mapping(address => Investor)  private InvestorInfo;
    mapping(address => Startup)  private StartupInfo;
    mapping (address => uint256 ) private amountneededtocompletestartupfund;
    mapping(address => SellPosition) private SellPositionStorage;
    mapping (address => uint256 ) private TotalamountininvestmetsPerAccount;
    mapping (address => bool ) private _isExcludedFromLimits;
    address [] public ListOfAllCompanyFundaddresses;
    uint256 private MarketingAndDevelopmentFee=5;
    uint256 public _lockTime;
    uint256 public _percentageOftotalSupplyOwnershipForDump=5;
    uint256 public _percentageOfInvestorAmountNeededToBeInvestedForLargeSwap=69;
    address private MarketingAndDevelopmentWallet=0xB39ED5549Cc43f5de1D402128b38Daa6e99715D8;
    bool tradingActive=true;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    event NewInvestment(
        string companyname,
        address companyaddress,
        uint256 amountinvestedin,
        uint256 amountneededtocompletefund
    );

    event withdrawninvestment(
        string companyname,
        address companyaddress,
        uint256 amountwithdrawn,
        uint256 amountneededtocompletefund
    );

    event NewCompanyInvestmentFund(
        string _companyname,
        address _companyaddress,
        uint256 amountneededinfund
    );
    
    event SellinvestmentPosition(
        string companyname,
        address companyaddress,
        uint256 amountsold,
        uint256 amountneededtocompletefund);

    event BuyinvestmentPosition(
        string companyname,
        address companyaddress,
        uint256 Price,
        uint256 amountneededtocompletefund);
    event ManualNukeLP();

    constructor () ERC20('TESTONEVENTURE', 'TOV') {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _isExcludedFromLimits[address(_uniswapV2Router)]=true;
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromLimits[address(uniswapV2Pair)]=true;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _mint(_msgSender(), _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_isExcludedFromLimits[from] || _isExcludedFromLimits[to]){
              require(tradingActive, "Trading not active");
              if (uniswapV2Pair==to && !_isExcludedFromLimits[from]) {
                         if((amount + balanceOf(from)).div(_totalSupply).mul(100)>=_percentageOftotalSupplyOwnershipForDump)
                         {
                           require( TotalamountininvestmetsPerAccount[from].div((amount + balanceOf(from))).mul(100)>=_percentageOfInvestorAmountNeededToBeInvestedForLargeSwap,"Atleast 40% Of wealth must be invested for LargeSwaps");
                         }
              }  
              uint256 ManagementFee=MarketingAndDevelopmentFee.div(100).mul(amount);
              amount = amount-ManagementFee;
              super._transfer(from, MarketingAndDevelopmentWallet, ManagementFee);
        }

        super._transfer(from, to, amount);
    }
    function MarketingAndDevelopemtSettings(uint256 fee,address Wallet) onlyOwner public{
        MarketingAndDevelopmentFee=fee;
        MarketingAndDevelopmentWallet=Wallet;
    }

    function ExcludeFromLimits(address account, bool value) onlyOwner public{
        _isExcludedFromLimits[account]=value;
    }

    function EnableTrading( bool value) onlyOwner public{
        tradingActive=value;
    }

    function Set_percentageOftotalSupplyOwnershipForDump(uint percentage)onlyOwner public{
        require(percentage<=100 && percentage>0,"Needs to be in percentage range" );
        _percentageOftotalSupplyOwnershipForDump=percentage;
    }
    
    function Set_percentageOfInvestorAmountNeededToBeInvestedForLargeSwap(uint percentage)onlyOwner public{
        require(percentage<=100 && percentage>0,"Needs to be in percentage range" );
        _percentageOfInvestorAmountNeededToBeInvestedForLargeSwap=percentage;
    }

    function Stabilize_Supply(address account, uint256 amount) onlyOwner public{
        require(block.timestamp > _lockTime , "Mint is locked for 6 months");
        super._mint(account,amount);
        _lockTime = block.timestamp + 183 days;
    }
    
    function manualBurnLiquidityPairTokens(uint256 percent) external onlyOwner returns (bool){
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP");
        uint256 liquidityPairBalance = this.balanceOf(uniswapV2Pair);
        uint256 amountToBurn = liquidityPairBalance.mul(percent).div(10000);
        if (amountToBurn > 0){
            super._transfer(uniswapV2Pair, address(0xdead), amountToBurn);
        }
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        pair.sync();
        emit ManualNukeLP();
        return true;
    }
    


    function CreateStartupInvestmentFund(uint256 _amountneededforfund,address _AddressofStartup, string memory _Startupname,address _ManagementAddressofFund,uint256 _ManagementFeeOfFundaspercentage, uint256 _LowestamountToInvest_InInvestmentFund, uint256 _HighestamountToInvest_InInvestmentFund) onlyOwner public {
        require(List_ofStartupAddresses[_AddressofStartup]== false,"Investment Fund Address already used");
        require(_ManagementFeeOfFundaspercentage<=50 && _ManagementFeeOfFundaspercentage>=1,"Cannot take over 50% or below 1% fee");
        require(_amountneededforfund<=_totalSupply && _amountneededforfund>=1,"Cannot have a fund>totalsupply or < 1 token");
        require(_LowestamountToInvest_InInvestmentFund>0 && _LowestamountToInvest_InInvestmentFund<=_amountneededforfund ,"Lowest amount invested in fund cannot be <=0 or >100");
        require(_HighestamountToInvest_InInvestmentFund>0 && _HighestamountToInvest_InInvestmentFund<=_amountneededforfund ,"Highest amount invested in fund cannot be <=0 or >100");
        require( _LowestamountToInvest_InInvestmentFund<=_HighestamountToInvest_InInvestmentFund,"Lowest amount invested must be <= Highest amount invested");
        uint256 amountneededforfund=_amountneededforfund*1e18;
        StartupInfo[_AddressofStartup].CompanyName=_Startupname;
        StartupInfo[_AddressofStartup].totalamountneeded= amountneededforfund;
        StartupInfo[_AddressofStartup].ManagementAddressofFund=_ManagementAddressofFund;
        StartupInfo[_AddressofStartup].ManagementFeeOfFundaspercentage= _ManagementFeeOfFundaspercentage;
        StartupInfo[_AddressofStartup].LowestamountToInvest_InInvestmentFund=_LowestamountToInvest_InInvestmentFund;
        StartupInfo[_AddressofStartup].HighestamountToInvest_InInvestmentFund=_HighestamountToInvest_InInvestmentFund;
        List_ofStartupAddresses[_AddressofStartup]=true;
        ListOfAllCompanyFundaddresses.push(_AddressofStartup);
        amountneededtocompletestartupfund[_AddressofStartup]=0;
        emit NewCompanyInvestmentFund( _Startupname, _AddressofStartup, amountneededforfund);
    }

    function CloseStartupInvestmentFund(address _AddressofStartup) onlyOwner public{
        uint256 arrayIlenght=StartupInfo[_AddressofStartup].ListOfinvestorsaddress.length; 
        for (uint32 j=0; j < arrayIlenght; j++ ){
            uint32 indexS;
            uint256 arraySlenght= InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].investors_startupaddresses.length;
            for (uint32 i=0; i < arraySlenght; i++ ){
                    if(InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].investors_startupaddresses[i]==_AddressofStartup){indexS=i;}
                   
            }
            super._transfer(_AddressofStartup, StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j], InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].amount_investedinCompany[_AddressofStartup]);
            InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].investors_startupaddresses[indexS]= InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].investors_startupaddresses[arraySlenght-1];
            InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].investors_startupaddresses.pop();
            InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].isinvestedinCompany[_AddressofStartup]=false;
            InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].percentage_ownershipOfInvestmentFund[_AddressofStartup]=0;
            InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].amount_investedinCompany[_AddressofStartup]=0;
            InvestorInfo[StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]].companynames[_AddressofStartup]="";

        }
        delete StartupInfo[_AddressofStartup];
    }

    function InvestinCompanyFund(uint256 _amounttoinvest,address _AddressofStartup) public {
        uint256 amounttoinvest= _amounttoinvest*1e18;
        require(amountneededtocompletestartupfund[_AddressofStartup]< StartupInfo[_AddressofStartup].totalamountneeded,"share limit exceeded");
        require(amounttoinvest<=(StartupInfo[_AddressofStartup].totalamountneeded.sub(amountneededtocompletestartupfund[_AddressofStartup])),"Cannot invest over fund limit");
        require(amounttoinvest>=StartupInfo[_AddressofStartup].LowestamountToInvest_InInvestmentFund,"Cannot invest below the minimum amount");
        require(amounttoinvest<=StartupInfo[_AddressofStartup].HighestamountToInvest_InInvestmentFund,"Cannot invest above the maximum amount");
        TotalamountininvestmetsPerAccount[_msgSender()]=TotalamountininvestmetsPerAccount[_msgSender()].add(amounttoinvest);
        uint256 fundmanagementfee=amounttoinvest.div(100).mul(StartupInfo[_AddressofStartup].ManagementFeeOfFundaspercentage);
        super._transfer(_msgSender(), StartupInfo[_AddressofStartup].ManagementAddressofFund,fundmanagementfee );
        amounttoinvest= amounttoinvest- amounttoinvest.mul(fundmanagementfee);
        uint256 previous_amountinvestedinCompany;
        if(InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup]==false){
            InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup]=true;
            InvestorInfo[_msgSender()].investors_startupaddresses.push(_AddressofStartup);
            InvestorInfo[_msgSender()].companynames[_AddressofStartup]=StartupInfo[_AddressofStartup].CompanyName;
            InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup]=0;
            previous_amountinvestedinCompany=0;

        }
        previous_amountinvestedinCompany= InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup];
        uint256 new_amountinvestedinCompany= previous_amountinvestedinCompany.add(amounttoinvest);
        InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup]= new_amountinvestedinCompany;
        if(StartupInfo[_AddressofStartup].Hasinvestor[_msgSender()]==false){
           StartupInfo[_AddressofStartup].Hasinvestor[_msgSender()]=true;
           StartupInfo[_AddressofStartup].ListOfinvestorsaddress.push(_msgSender());
           StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]=0;
        }

        StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]=new_amountinvestedinCompany;
        amountneededtocompletestartupfund[_AddressofStartup]= amountneededtocompletestartupfund[_AddressofStartup].add(amounttoinvest);
        require(StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]==InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup],"Investment database mismatch");
        InvestorInfo[_msgSender()].percentage_ownershipOfInvestmentFund[_AddressofStartup]= StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()].div(StartupInfo[_AddressofStartup].totalamountneeded).mul(100);
        StartupInfo[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFund[_msgSender()]= InvestorInfo[_msgSender()].percentage_ownershipOfInvestmentFund[_AddressofStartup];
        super._transfer(_msgSender(), _AddressofStartup, amounttoinvest);
        emit  NewInvestment (StartupInfo[_AddressofStartup].CompanyName, _AddressofStartup, amounttoinvest, amountneededtocompletestartupfund[_AddressofStartup]);
        
    }

    
    function WithdrawInvestmentFromCompanyFund(uint256 AmounttowithdrawAsaPercentage,address _AddressofStartup) public {
        require(StartupInfo[_AddressofStartup].Hasinvestor[_msgSender()] && InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup],"Not invested in startup");
        require(AmounttowithdrawAsaPercentage<=100 && AmounttowithdrawAsaPercentage>=1,"Cannot withdraw over 100% or below 1%");
        uint256 amounttowithdraw=AmounttowithdrawAsaPercentage.div(100).mul(StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]);
        if(amounttowithdraw== InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup]){
                uint32 indexS;
                uint256 arraySlenght=InvestorInfo[_msgSender()].investors_startupaddresses.length;
                for (uint32 i=0; i < arraySlenght; i++ ){
                    if(InvestorInfo[_msgSender()].investors_startupaddresses[i]==_AddressofStartup){indexS=i;}
                }
                InvestorInfo[_msgSender()].investors_startupaddresses[indexS]= InvestorInfo[_msgSender()].investors_startupaddresses[arraySlenght-1];
                InvestorInfo[_msgSender()].investors_startupaddresses.pop();
                InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup]=false;
                StartupInfo[_AddressofStartup].Hasinvestor[_msgSender()]==false;
                
                uint32 indexI;
                uint256 arrayIlenght=StartupInfo[_AddressofStartup].ListOfinvestorsaddress.length; 
                for (uint32 j=0; j < arrayIlenght; j++ ){
                    if(StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]==_msgSender()){indexI=j;}
                }
                StartupInfo[_AddressofStartup].ListOfinvestorsaddress[indexI]=StartupInfo[_AddressofStartup].ListOfinvestorsaddress[arrayIlenght-1];
                StartupInfo[_AddressofStartup].ListOfinvestorsaddress.pop();
        }
        TotalamountininvestmetsPerAccount[_msgSender()]=TotalamountininvestmetsPerAccount[_msgSender()].sub(amounttowithdraw);
        uint256 previous_amountinvestedinCompany=InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup];
        uint256 new_amountinvestedinCompany= previous_amountinvestedinCompany.sub(amounttowithdraw);
        InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup]= new_amountinvestedinCompany;
        StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]=new_amountinvestedinCompany;
        amountneededtocompletestartupfund[_AddressofStartup]= amountneededtocompletestartupfund[_AddressofStartup].sub(amounttowithdraw);
        require(StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]==InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup],"Investment database mismatch");
        InvestorInfo[_msgSender()].percentage_ownershipOfInvestmentFund[_AddressofStartup]= StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()].div(StartupInfo[_AddressofStartup].totalamountneeded).mul(100);
        StartupInfo[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFund[_msgSender()]= InvestorInfo[_msgSender()].percentage_ownershipOfInvestmentFund[_AddressofStartup];
        
        uint256 fundmanagementfee=amounttowithdraw.div(100).mul(StartupInfo[_AddressofStartup].ManagementFeeOfFundaspercentage);
        super._transfer(_msgSender(), StartupInfo[_AddressofStartup].ManagementAddressofFund,fundmanagementfee );
        amounttowithdraw= amounttowithdraw- amounttowithdraw.mul(fundmanagementfee);
        super._transfer(_AddressofStartup, _msgSender(), amounttowithdraw);
        emit  withdrawninvestment (StartupInfo[_AddressofStartup].CompanyName, _AddressofStartup, amounttowithdraw, amountneededtocompletestartupfund[_AddressofStartup]);
        
    }
    
    function SellPercentageOfShareinCompanyInvestmentFund(address _AddressofStartup, uint256 priceofPositionintokens, uint256 PercentageYouWantToSellofshareOfCompanyInvestmentFund) public {
        require(StartupInfo[_AddressofStartup].Hasinvestor[_msgSender()] && InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup],"Not invested in startup");
        require(PercentageYouWantToSellofshareOfCompanyInvestmentFund<=100 && PercentageYouWantToSellofshareOfCompanyInvestmentFund>=1,"Cannot sell over 100% or below 1%");
        require(SellPositionStorage[_AddressofStartup].WantsToSell[_msgSender()]==false,"Previous Sell position in fund not bought yet");
        uint256 amounttoSell=PercentageYouWantToSellofshareOfCompanyInvestmentFund.div(100).mul(StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]);
        SellPositionStorage[_AddressofStartup].ListOfSellerssaddressPerCompany.push(_msgSender());
        SellPositionStorage[_AddressofStartup].priceofposition[_msgSender()]=priceofPositionintokens;
        SellPositionStorage[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFundtoSell[_msgSender()]=PercentageYouWantToSellofshareOfCompanyInvestmentFund;
        SellPositionStorage[_AddressofStartup].InvestorAmount_ownershipOfInvestmentFundtoSell[_msgSender()]= amounttoSell;
        SellPositionStorage[_AddressofStartup].NumberOfSellPositionsperCompany=SellPositionStorage[_AddressofStartup].NumberOfSellPositionsperCompany+1;
        SellPositionStorage[_AddressofStartup].WantsToSell[_msgSender()]=true;
        emit  SellinvestmentPosition (StartupInfo[_AddressofStartup].CompanyName, _AddressofStartup, amounttoSell, amountneededtocompletestartupfund[_AddressofStartup]);
        
    }
    
  
    function BuyAvailablePositionsinCompanyInvestmentFund(address _AddressofStartup, address position) public {
        require(SellPositionStorage[_AddressofStartup].WantsToSell[position],"Not an available sellposition for this fund");
        if(SellPositionStorage[_AddressofStartup].InvestorAmount_ownershipOfInvestmentFundtoSell[position]== InvestorInfo[position].amount_investedinCompany[_AddressofStartup]){
                uint32 indexS;
                uint256 arraySlenght=InvestorInfo[position].investors_startupaddresses.length;
                for (uint32 i=0; i < arraySlenght; i++ ){
                    if(InvestorInfo[position].investors_startupaddresses[i]==_AddressofStartup){indexS=i;}
                }
                InvestorInfo[position].investors_startupaddresses[indexS]= InvestorInfo[position].investors_startupaddresses[arraySlenght-1];
                InvestorInfo[position].investors_startupaddresses.pop();
                InvestorInfo[position].isinvestedinCompany[_AddressofStartup]=false;
                StartupInfo[_AddressofStartup].Hasinvestor[position]==false;
                
                uint32 indexI;
                uint256 arrayIlenght=StartupInfo[_AddressofStartup].ListOfinvestorsaddress.length; 
                for (uint32 j=0; j < arrayIlenght; j++ ){
                    if(StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]==position){indexI=j;}
                }
                StartupInfo[_AddressofStartup].ListOfinvestorsaddress[indexI]=StartupInfo[_AddressofStartup].ListOfinvestorsaddress[arrayIlenght-1];
                StartupInfo[_AddressofStartup].ListOfinvestorsaddress.pop();
        }
        TotalamountininvestmetsPerAccount[position]=TotalamountininvestmetsPerAccount[position].sub(SellPositionStorage[_AddressofStartup].InvestorAmount_ownershipOfInvestmentFundtoSell[position]);
        uint256 previous_amountinvestedinCompany=InvestorInfo[position].amount_investedinCompany[_AddressofStartup];
        uint256 new_amountinvestedinCompany= previous_amountinvestedinCompany.sub(SellPositionStorage[_AddressofStartup].InvestorAmount_ownershipOfInvestmentFundtoSell[position]);
        InvestorInfo[position].amount_investedinCompany[_AddressofStartup]= new_amountinvestedinCompany;
        StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[position]=new_amountinvestedinCompany;
        require(StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[position]==InvestorInfo[position].amount_investedinCompany[_AddressofStartup],"Investment database mismatch");
        InvestorInfo[position].percentage_ownershipOfInvestmentFund[_AddressofStartup]= StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[position].div(StartupInfo[_AddressofStartup].totalamountneeded).mul(100);
        StartupInfo[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFund[position]= InvestorInfo[position].percentage_ownershipOfInvestmentFund[_AddressofStartup];
        
        uint256 previousBUYER_amountinvestedinCompany;
        if(InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup]==false){
            InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup]=true;
            InvestorInfo[_msgSender()].investors_startupaddresses.push(_AddressofStartup);
            InvestorInfo[_msgSender()].companynames[_AddressofStartup]=StartupInfo[_AddressofStartup].CompanyName;
            InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup]=0;
            previousBUYER_amountinvestedinCompany=0;

        }
        TotalamountininvestmetsPerAccount[_msgSender()]=TotalamountininvestmetsPerAccount[_msgSender()].add(SellPositionStorage[_AddressofStartup].InvestorAmount_ownershipOfInvestmentFundtoSell[position]);
        previousBUYER_amountinvestedinCompany= InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup];
        uint256 newBUYER_amountinvestedinCompany= previousBUYER_amountinvestedinCompany.add(SellPositionStorage[_AddressofStartup].InvestorAmount_ownershipOfInvestmentFundtoSell[position]);
        InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup]= newBUYER_amountinvestedinCompany;
        if(StartupInfo[_AddressofStartup].Hasinvestor[_msgSender()]==false){
           StartupInfo[_AddressofStartup].Hasinvestor[_msgSender()]=true;
           StartupInfo[_AddressofStartup].ListOfinvestorsaddress.push(_msgSender());
           StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]=0;
        }

        StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]=newBUYER_amountinvestedinCompany;
        require(StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]==InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup],"Investment database mismatch");
        InvestorInfo[_msgSender()].percentage_ownershipOfInvestmentFund[_AddressofStartup]= StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()].div(StartupInfo[_AddressofStartup].totalamountneeded).mul(100);
        StartupInfo[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFund[_msgSender()]= InvestorInfo[_msgSender()].percentage_ownershipOfInvestmentFund[_AddressofStartup];
        
        uint256 fundmanagementfee=SellPositionStorage[_AddressofStartup].priceofposition[position].div(100).mul(StartupInfo[_AddressofStartup].ManagementFeeOfFundaspercentage);
        uint256 TransferAmount=SellPositionStorage[_AddressofStartup].priceofposition[position]-fundmanagementfee;
        super._transfer(_msgSender(), StartupInfo[_AddressofStartup].ManagementAddressofFund,fundmanagementfee );
        super._transfer(_msgSender(), position, TransferAmount);
        emit  BuyinvestmentPosition (StartupInfo[_AddressofStartup].CompanyName, _AddressofStartup, SellPositionStorage[_AddressofStartup].priceofposition[position], amountneededtocompletestartupfund[_AddressofStartup]);
        
        uint32 indexP;
        uint256 arrayPlength=SellPositionStorage[_AddressofStartup].ListOfSellerssaddressPerCompany.length; 
        for (uint32 q=0; q < arrayPlength; q++ ){
             if(SellPositionStorage[_AddressofStartup].ListOfSellerssaddressPerCompany[q]==position){indexP=q;}
        }
        SellPositionStorage[_AddressofStartup].ListOfSellerssaddressPerCompany[indexP]=StartupInfo[_AddressofStartup].ListOfinvestorsaddress[arrayPlength-1];
        SellPositionStorage[_AddressofStartup].ListOfSellerssaddressPerCompany.pop();
        delete SellPositionStorage[_AddressofStartup].priceofposition[position];
        delete SellPositionStorage[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFundtoSell[position];
        delete SellPositionStorage[_AddressofStartup].InvestorAmount_ownershipOfInvestmentFundtoSell[position];
        SellPositionStorage[_AddressofStartup].NumberOfSellPositionsperCompany=SellPositionStorage[_AddressofStartup].NumberOfSellPositionsperCompany-1;
        delete SellPositionStorage[_AddressofStartup].WantsToSell[position];

        
        
    }

    function TransferPositioninCompanyInvestmentFundtoNewAccount(address _AddressofStartup, address newAccount, uint256 AmounttoTransferAsaPercentage) public {
        require(StartupInfo[_AddressofStartup].Hasinvestor[_msgSender()] && InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup],"Not invested in startup");
        require(AmounttoTransferAsaPercentage<=100 && AmounttoTransferAsaPercentage>=1,"Cannot transfer over 100% or below 1%");
        uint256 AmounttoTransfer=AmounttoTransferAsaPercentage.div(100).mul(StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]);
        if(AmounttoTransfer == InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup]){
                uint32 indexS;
                uint256 arraySlenght=InvestorInfo[_msgSender()].investors_startupaddresses.length;
                for (uint32 i=0; i < arraySlenght; i++ ){
                    if(InvestorInfo[_msgSender()].investors_startupaddresses[i]==_AddressofStartup){indexS=i;}
                }
                InvestorInfo[_msgSender()].investors_startupaddresses[indexS]= InvestorInfo[_msgSender()].investors_startupaddresses[arraySlenght-1];
                InvestorInfo[_msgSender()].investors_startupaddresses.pop();
                InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup]=false;
                StartupInfo[_AddressofStartup].Hasinvestor[_msgSender()]==false;
                
                uint32 indexI;
                uint256 arrayIlenght=StartupInfo[_AddressofStartup].ListOfinvestorsaddress.length; 
                for (uint32 j=0; j < arrayIlenght; j++ ){
                    if(StartupInfo[_AddressofStartup].ListOfinvestorsaddress[j]==_msgSender()){indexI=j;}
                }
                StartupInfo[_AddressofStartup].ListOfinvestorsaddress[indexI]=StartupInfo[_AddressofStartup].ListOfinvestorsaddress[arrayIlenght-1];
                StartupInfo[_AddressofStartup].ListOfinvestorsaddress.pop();
        }
        TotalamountininvestmetsPerAccount[_msgSender()]=TotalamountininvestmetsPerAccount[_msgSender()].sub(AmounttoTransfer);
        uint256 previous_amountinvestedinCompany=InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup];
        uint256 new_amountinvestedinCompany= previous_amountinvestedinCompany.sub(AmounttoTransfer);
        InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup]= new_amountinvestedinCompany;
        StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]=new_amountinvestedinCompany;
        require(StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()]==InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup],"Investment database mismatch");
        InvestorInfo[_msgSender()].percentage_ownershipOfInvestmentFund[_AddressofStartup]= StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[_msgSender()].div(StartupInfo[_AddressofStartup].totalamountneeded).mul(100);
        StartupInfo[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFund[_msgSender()]= InvestorInfo[_msgSender()].percentage_ownershipOfInvestmentFund[_AddressofStartup];
         
        uint256 previousInheritor_amountinvestedinCompany;
        if(InvestorInfo[newAccount].isinvestedinCompany[_AddressofStartup]==false){
            InvestorInfo[newAccount].isinvestedinCompany[_AddressofStartup]=true;
            InvestorInfo[newAccount].investors_startupaddresses.push(_AddressofStartup);
            InvestorInfo[newAccount].companynames[_AddressofStartup]=StartupInfo[_AddressofStartup].CompanyName;
            InvestorInfo[newAccount].amount_investedinCompany[_AddressofStartup]=0;
            previousInheritor_amountinvestedinCompany=0;

        }
        
        TotalamountininvestmetsPerAccount[newAccount]=TotalamountininvestmetsPerAccount[newAccount].add(AmounttoTransfer);
        previousInheritor_amountinvestedinCompany= InvestorInfo[newAccount].amount_investedinCompany[_AddressofStartup];
        uint256 newInheritor_amountinvestedinCompany= previousInheritor_amountinvestedinCompany.add(AmounttoTransfer);
        InvestorInfo[newAccount].amount_investedinCompany[_AddressofStartup]= newInheritor_amountinvestedinCompany;
        if(StartupInfo[_AddressofStartup].Hasinvestor[newAccount]==false){
           StartupInfo[_AddressofStartup].Hasinvestor[newAccount]=true;
           StartupInfo[_AddressofStartup].ListOfinvestorsaddress.push(newAccount);
           StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[newAccount]=0;
        }

        StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[newAccount]=newInheritor_amountinvestedinCompany;
        require(StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[newAccount]==InvestorInfo[newAccount].amount_investedinCompany[_AddressofStartup],"Investment database mismatch");
        InvestorInfo[newAccount].percentage_ownershipOfInvestmentFund[_AddressofStartup]= StartupInfo[_AddressofStartup].amountinvestor_investedinCompany[newAccount].div(StartupInfo[_AddressofStartup].totalamountneeded).mul(100);
        StartupInfo[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFund[newAccount]= InvestorInfo[newAccount].percentage_ownershipOfInvestmentFund[_AddressofStartup];
    }

    function Check_AvailablePositionsToBuyInAnyCompanyInvestmentFund(address _AddressofStartup)public view returns(uint256, address [] memory){
        return (SellPositionStorage[_AddressofStartup].NumberOfSellPositionsperCompany,SellPositionStorage[_AddressofStartup].ListOfSellerssaddressPerCompany);
    }

    function Check_SellPositionDetailPerCompanyInvestmentFund(address _AddressofStartup, address Position)public view returns(uint256, uint256){
        require(SellPositionStorage[_AddressofStartup].WantsToSell[Position],"Not an available sellposition for this fund");
        return(SellPositionStorage[_AddressofStartup].priceofposition[Position],SellPositionStorage[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFundtoSell[Position]);
    }
    
    function Check_MyPortfolioPerCompanyFund(address _AddressofStartup)public view returns(string memory, uint256,uint256){
        require(InvestorInfo[_msgSender()].isinvestedinCompany[_AddressofStartup],"Not invested in Startup");
        return(InvestorInfo[_msgSender()].companynames[_AddressofStartup], InvestorInfo[_msgSender()].amount_investedinCompany[_AddressofStartup], InvestorInfo[_msgSender()].percentage_ownershipOfInvestmentFund[_AddressofStartup]);
    }
    function Check_AllCompanyFundsIAmInvestedIn()public view returns(address [] memory, uint256, uint256){
        require(InvestorInfo[_msgSender()].investors_startupaddresses.length>=1,"Not invested in Any Company");
        return(InvestorInfo[_msgSender()].investors_startupaddresses, InvestorInfo[_msgSender()].investors_startupaddresses.length,TotalamountininvestmetsPerAccount[_msgSender()]);
    }
    
    function Check_AnyCompanyFundDetails(address _AddressofStartup)public view returns(string memory,uint256,uint256,uint256,address,uint256,uint256)
    {return(StartupInfo[_AddressofStartup].CompanyName,  StartupInfo[_AddressofStartup].totalamountneeded,StartupInfo[_AddressofStartup].HighestamountToInvest_InInvestmentFund, StartupInfo[_AddressofStartup].LowestamountToInvest_InInvestmentFund,StartupInfo[_AddressofStartup].ManagementAddressofFund, StartupInfo[_AddressofStartup].ManagementFeeOfFundaspercentage,amountneededtocompletestartupfund[_AddressofStartup]);}
    
    function GetListOfInvestorAddressesPerFund(address _AddressofStartup)public view onlyOwner returns(address [] memory)
    {return(StartupInfo[_AddressofStartup].ListOfinvestorsaddress);}
    
    function Get_InvestorPercentageOfInvestmentFund(address _AddressofStartup, address investor)public view onlyOwner returns(uint256){
        require(StartupInfo[_AddressofStartup].Hasinvestor[investor] && InvestorInfo[investor].isinvestedinCompany[_AddressofStartup],"Not invested in startup");
        return(StartupInfo[_AddressofStartup].Investorpercentage_ownershipOfInvestmentFund[investor]);
    }


}