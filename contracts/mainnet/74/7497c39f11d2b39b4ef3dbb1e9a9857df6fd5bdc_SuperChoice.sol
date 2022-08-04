/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT

/* 

Super Choice
Twitter: https://twitter.com/SuperChoiceERC
Telegram: https://t.me/SuperChoicePortal
Website: https://www.superchoice.io/

*/

pragma solidity ^0.8.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
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
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
interface DividendPayingTokenOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns(uint256);
  function withdrawnDividendOf(address _owner) external view returns(uint256);
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface DividendPayingTokenInterface {
  function dividendOf(address _owner) external view returns(uint256);
  function distributeDividends() external payable;
  function withdrawDividend() external;
  event DividendsDistributed(address indexed from, uint256 weiAmount);
  event DividendWithdrawn(address indexed to, uint256 weiAmount);
}
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;
  uint256 constant internal magnitude = 2**128;
  uint256 internal magnifiedDividendPerShare;
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  mapping(address => uint256) internal rawETHWithdrawnDividends;
  mapping(address => address) public userCurrentRewardToken;
  mapping(address => bool) public userHasCustomRewardToken;
  mapping(address => address) public userCurrentRewardAMM;
  mapping(address => bool) public userHasCustomRewardAMM;
  mapping(address => uint256) public rewardTokenSelectionCount; // keep track of how many people have each reward token selected (for fun mostly)
  mapping(address => bool) public ammIsWhiteListed; // only allow whitelisted AMMs
  mapping(address => bool) public ignoreRewardTokens;
  IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  function updateDividendUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "CHOICE: The router already has that address");
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
  uint256 public totalDividendsDistributed; // dividends distributed per reward token
  constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {
    // add whitelisted AMMs here -- more will get added postlaunch
    ammIsWhiteListed[address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)] = true; // UNISWAP V2 router
  }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }
  // Customized function to send tokens to dividend recipients
  function swapETHForTokens(
        address recipient,
        uint256 ethAmount
    ) private returns (uint256) {
        bool swapSuccess;
        IERC20 token = IERC20(userCurrentRewardToken[recipient]);
        IUniswapV2Router02 swapRouter = uniswapV2Router;
        if(userHasCustomRewardAMM[recipient] && ammIsWhiteListed[userCurrentRewardAMM[recipient]]){
            swapRouter = IUniswapV2Router02(userCurrentRewardAMM[recipient]);
        }
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(token);
        try swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}( //try to swap for tokens, if it fails (bad contract, or whatever other reason, send ETH)
            1, // accept any amount of Tokens above 1 wei (so it will fail if nothing returns)
            path,
            address(recipient),
            block.timestamp + 360
        ){
            swapSuccess = true;
        }
        catch {
            swapSuccess = false;
        }
        // if the swap failed, send them their ETH instead
        if(!swapSuccess){
            rawETHWithdrawnDividends[recipient] = rawETHWithdrawnDividends[recipient].add(ethAmount);
            (bool success,) = recipient.call{value: ethAmount, gas: 3000}("");
    
            if(!success) {
                withdrawnDividends[recipient] = withdrawnDividends[recipient].sub(ethAmount);
                rawETHWithdrawnDividends[recipient] = rawETHWithdrawnDividends[recipient].sub(ethAmount);
                return 0;
            }
        }
        return ethAmount;
    }
  
  function setIgnoreToken(address tokenAddress, bool isIgnored) external onlyOwner {
      ignoreRewardTokens[tokenAddress] = isIgnored;
  }
  
  function isIgnoredToken(address tokenAddress) public view returns (bool){
      return ignoreRewardTokens[tokenAddress];
  }
  
  function getRawETHDividends(address holder) external view returns (uint256){
      return rawETHWithdrawnDividends[holder];
  }
    
  function setWhiteListAMM(address ammAddress, bool whitelisted) external onlyOwner {
      ammIsWhiteListed[ammAddress] = whitelisted;
  }
  
  // call this to set a custom reward token (call from token contract only)
  function setRewardToken(address holder, address rewardTokenAddress, address ammContractAddress) external onlyOwner {
    if(userHasCustomRewardToken[holder] == true){
        if(rewardTokenSelectionCount[userCurrentRewardToken[holder]] > 0){
            rewardTokenSelectionCount[userCurrentRewardToken[holder]] -= 1; // remove count from old token
        }
    }

    userHasCustomRewardToken[holder] = true;
    userCurrentRewardToken[holder] = rewardTokenAddress;
    // only set custom AMM if the AMM is whitelisted.
    if(ammContractAddress != address(uniswapV2Router) && ammIsWhiteListed[ammContractAddress]){
        userHasCustomRewardAMM[holder] = true;
        userCurrentRewardAMM[holder] = ammContractAddress;
    } else {
        userHasCustomRewardAMM[holder] = false;
        userCurrentRewardAMM[holder] = address(uniswapV2Router);
    }
    rewardTokenSelectionCount[rewardTokenAddress] += 1; // add count to new token
  }
  // call this to go back to receiving ETH after setting another token. (call from token contract only)
  function unsetRewardToken(address holder) external onlyOwner {
    userHasCustomRewardToken[holder] = false;
    if(rewardTokenSelectionCount[userCurrentRewardToken[holder]] > 0){
        rewardTokenSelectionCount[userCurrentRewardToken[holder]] -= 1; // remove count from old token
    }
    userCurrentRewardToken[holder] = address(0);
    userCurrentRewardAMM[holder] = address(uniswapV2Router);
    userHasCustomRewardAMM[holder] = false;
  }
  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
         // if no custom reward token or reward token is ignored, send ETH.
        if(!userHasCustomRewardToken[user] && !isIgnoredToken(userCurrentRewardToken[user])){
        
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          rawETHWithdrawnDividends[user] = rawETHWithdrawnDividends[user].add(_withdrawableDividend);
          emit DividendWithdrawn(user, _withdrawableDividend);
          (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");
    
          if(!success) {
            withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
            rawETHWithdrawnDividends[user] = rawETHWithdrawnDividends[user].sub(_withdrawableDividend);
            return 0;
          }
          return _withdrawableDividend;
          
        // the reward is a token, not ETH, use an IERC20 buyback instead!
        } else { 
          withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
          emit DividendWithdrawn(user, _withdrawableDividend);
          return swapETHForTokens(user, _withdrawableDividend);
        }
    }
    return 0;
  }
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);
    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }
  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);
    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
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


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}


interface IUniswapV2Pair {
    function factory() external view returns (address);
}

contract SuperChoice is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool private swapping;

    CHOICEDividendTracker public dividendTracker;
    
    mapping(address => uint256) public holderETHUsedForBuyBacks;
    mapping(address => bool) public _isAllowedDuringDisabled;
    mapping(address => bool) public _isIgnoredAddress;

    address public liquidityWallet;
    address public operationsWallet;
    address private buyBackWallet;

    uint256 public maxSellTransactionAmount = 100000000  * (10**9);
    uint256 public swapTokensAtAmount = 100000 * (10**9);
    
    // Anti-bot and anti-whale mappings and variables for launch
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;
    
    
    // to track last sell to reduce sell penalty over time by 10% per week the holder sells *no* tokens.
    mapping (address => uint256) public _holderLastSellDate;
    
    // fees
    uint256 public RewardsFee = 5;
    uint256 public liquidityFee = 2; // This fee must be a TOTAL of LP, Operations Fee AND Buyback fee (Note, Buyback has been disabled)
    uint256 public totalFees = RewardsFee.add(liquidityFee);
    // this is a subset of the liquidity fee, not in addition to. operations fee + buyback fee cannot be higher than liquidity fee.  Will be reasonably reduced post launch.
    uint256 public operationsFee = 3;
    uint256 public buyBackFee = 0;
	uint256 public _maxSellPercent = 1; // Set the maximum percent allowed on sale per a single transaction
    
    // Disable trading initially
    bool isTradingEnabled = false;
    
    // Swap and liquify active status 
    bool isSwapAndLiquifyEnabled = false;

    // sells have fees of 4.8 and 12 (16.8 total) (4 * 1.2 and 10 * 1.2)
    uint256 public immutable sellFeeIncreaseFactor = 100;
    uint256 public immutable rewardFeeSellFactor = 100;

    // use by default 300,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 300000;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BuyBackWithNoFees(address indexed holder, uint256 indexed ethSpent);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event OperationsWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event BuyBackWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event FeesUpdated(uint256 indexed newRewardsFee, uint256 indexed newLiquidityFee, uint256 newOperationsFee, uint256 newBuyBackFee);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("Super Choice", "Choice", 9) {

        dividendTracker = new CHOICEDividendTracker();
        liquidityWallet = owner();
        operationsWallet = (0x7A5a85BA12Eab427ea66D7748a964161A5c0C559);
        buyBackWallet = owner();
        
       IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(liquidityWallet);
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD)); // don't want dead address to take ETH!!!
        dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);
        excludeFromFees(address(operationsWallet), true);
        excludeFromFees(address(buyBackWallet), true);
        
        _isAllowedDuringDisabled[address(this)] = true;
        _isAllowedDuringDisabled[owner()] = true;
        _isAllowedDuringDisabled[liquidityWallet] = true;
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100000000 * (10**9));
    }

    receive() external payable {

    }
    
    // @dev Owner functions start -------------------------------------
    
    // enable / disable custom AMMs
    function setWhiteListAMM(address ammAddress, bool isWhiteListed) external onlyOwner {
      require(isContract(ammAddress), "CHOICE: setWhiteListAMM:: AMM is a wallet, not a contract");
      dividendTracker.setWhiteListAMM(ammAddress, isWhiteListed);
    }
    
    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
        require(newAmount < totalSupply(), "Swap amount cannot be higher than total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }
    
    // remove transfer delay after launch
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }
    
    // migration feature (DO NOT CHANGE WITHOUT CONSULTATION)
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "CHOICE: The dividend tracker already has that address");
        CHOICEDividendTracker newDividendTracker = CHOICEDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "CHOICE: The new dividend tracker must be owned by the CHOICE token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }
    
    // updates the maximum amount of tokens that can be bought or sold by holders
    function updateMaxTxn(uint256 maxTxnAmount) external onlyOwner {
        maxSellTransactionAmount = maxTxnAmount;
    }
    
    // updates the minimum amount of tokens people must hold in order to get dividends
    function updateDividendTokensMinimum(uint256 minimumToEarnDivs) external onlyOwner {
        dividendTracker.updateDividendMinimum(minimumToEarnDivs);
    }

    // updates the default router for selling tokens
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "CHOICE: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
    
    // updates the default router for buying tokens from dividend tracker
    function updateDividendUniswapV2Router(address newAddress) external onlyOwner {
        dividendTracker.updateDividendUniswapV2Router(newAddress);
    }
    
    // updates the current trading status of the contract 
    function updateTradingStatus(bool tradingStatus) external onlyOwner {
        isTradingEnabled = tradingStatus;
    }

    // excludes wallets from max txn and fees.
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // allows multiple exclusions at once
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }
    
    function addToWhitelist(address wallet, bool status) external onlyOwner {
        _isAllowedDuringDisabled[wallet] = status;
    }
    
    function setIsBot(address wallet, bool status) external onlyOwner {
        _isIgnoredAddress[wallet] = status;
    }

    // excludes wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    // removes exclusion on wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
    }
    
    // allow adding additional AMM pairs to the list
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "CHOICE: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }
    
    // sets the wallet that receives LP tokens to lock
    function updateLiquidityWallet(address newLiquidityWallet) external onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "CHOICE: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }
    
    // updates the operations wallet (marketing, charity, etc.)
    function updateOperationsWallet(address newOperationsWallet) external onlyOwner {
        require(newOperationsWallet != operationsWallet, "CHOICE: The operations wallet is already this address");
        excludeFromFees(newOperationsWallet, true);
        emit OperationsWalletUpdated(newOperationsWallet, operationsWallet);
        operationsWallet = newOperationsWallet;
    }
    
    // updates the wallet used for manual buybacks.
    function updateBuyBackWallet(address newBuyBackWallet) external onlyOwner {
        require(newBuyBackWallet != buyBackWallet, "CHOICE: The buyback wallet is already this address");
        excludeFromFees(newBuyBackWallet, true);
        emit BuyBackWalletUpdated(newBuyBackWallet, buyBackWallet);
        buyBackWallet = newBuyBackWallet;
    }
    
    // rebalance fees as needed
    function updateFees(uint256 RewardPerc, uint256 liquidityPerc, uint256 operationsPerc, uint256 buyBackPerc) external onlyOwner {
        require (operationsPerc.add(buyBackPerc) <= liquidityPerc, "CHOICE: updateFees:: Liquidity Perc must be equal to or higher than operations and buyback combined.");
        emit FeesUpdated(RewardPerc, liquidityPerc, operationsPerc, buyBackPerc);
        RewardsFee = RewardPerc;
        liquidityFee = liquidityPerc;
        operationsFee = operationsPerc;
        buyBackFee= buyBackPerc;
        
        totalFees = RewardsFee.add(liquidityFee);
        
    }

    // changes the gas reserve for processing dividend distribution
    function updateGasForProcessing(uint256 newValue) external onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "CHOICE: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "CHOICE: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    // changes the amount of time to wait for claims (1-24 hours, expressed in seconds)
    function updateClaimWait(uint256 claimWait) external onlyOwner returns (bool){
        dividendTracker.updateClaimWait(claimWait);
        return true;
    }
    
    function setIgnoreToken(address tokenAddress, bool isIgnored) external onlyOwner returns (bool){
        dividendTracker.setIgnoreToken(tokenAddress, isIgnored);
        return true;
    }
    
    // determines if an AMM can be used for rewards
    function isAMMWhitelisted(address ammAddress) public view returns (bool){
        return dividendTracker.ammIsWhiteListed(ammAddress);
    }
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function getUserCurrentRewardToken(address holder) public view returns (address){
        return dividendTracker.userCurrentRewardToken(holder);
    }
    
    function getUserHasCustomRewardToken(address holder) public view returns (bool){
        return dividendTracker.userHasCustomRewardToken(holder);
    }
    
    function getRewardTokenSelectionCount(address token) public view returns (uint256){
        return dividendTracker.rewardTokenSelectionCount(token);
    }
    
    function getLastProcessedIndex() external view returns(uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    // returns a number between 50 and 120 that determines the penalty a user pays on sells.
    
    function getHolderSellFactor(address holder) public view returns (uint256){
        // get time since last sell measured in 2 week increments
        uint256 timeSinceLastSale = (block.timestamp.sub(_holderLastSellDate[holder])).div(2 weeks);
        // protection in case someone tries to use a contract to facilitate buys/sells
        if(_holderLastSellDate[holder] == 0){
            return sellFeeIncreaseFactor;
        }
        // cap the sell factor cooldown to 14 weeks and 50% of sell tax
        if(timeSinceLastSale >= 7){
            return 50; // 50% sell factor is minimum
        }
        // return the fee factor minus the number of weeks since sale * 10.  SellFeeIncreaseFactor is immutable at 120 so the most this can subtract is 6*10 = 120 - 60 = 60%
        return sellFeeIncreaseFactor-(timeSinceLastSale.mul(10));
    }
    
     function getDividendTokensMinimum() external view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
    }
    
    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }
    
    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccountAtIndex(index);
    }
    
    function getRawETHDividends(address holder) public view returns (uint256){
        return dividendTracker.getRawETHDividends(holder);
    }
    
    function getETHAvailableForHolderBuyBack(address holder) public view returns (uint256){
        return getRawETHDividends(holder).sub(holderETHUsedForBuyBacks[msg.sender]);
    }
    
    function isIgnoredToken(address tokenAddress) public view returns (bool){
        return dividendTracker.isIgnoredToken(tokenAddress);
    }
    
    // @dev User Callable Functions start here! ---------------------------------------------
    
    // set the reward token for the user.  Call from here.
    function setRewardToken(address rewardTokenAddress) public returns (bool) {
        require(isContract(rewardTokenAddress), "CHOICE: setRewardToken:: Address is a wallet, not a contract.");
        require(rewardTokenAddress != address(this), "CHOICE: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
        require(!isIgnoredToken(rewardTokenAddress), "CHOICE: setRewardToken:: Reward Token is ignored from being used as rewards.");
        dividendTracker.setRewardToken(msg.sender, rewardTokenAddress, address(uniswapV2Router));
        return true;
    }
    
    // set the reward token for the user with a custom AMM (AMM must be whitelisted).  Call from here.
    function setRewardTokenWithCustomAMM(address rewardTokenAddress, address ammContractAddress) public returns (bool) {
        require(isContract(rewardTokenAddress), "CHOICE: setRewardToken:: Address is a wallet, not a contract.");
        require(ammContractAddress != address(uniswapV2Router), "CHOICE: setRewardToken:: Use setRewardToken to use default Router");
        require(rewardTokenAddress != address(this), "CHOICE: setRewardToken:: Cannot set reward token as this token due to Router limitations.");
        require(!isIgnoredToken(rewardTokenAddress), "CHOICE: setRewardToken:: Reward Token is ignored from being used as rewards.");
        require(isAMMWhitelisted(ammContractAddress) == true, "CHOICE: setRewardToken:: AMM is not whitelisted!");
        dividendTracker.setRewardToken(msg.sender, rewardTokenAddress, ammContractAddress);
        return true;
    }
    
    // Unset the reward token back to ETH.  Call from here.
    function unsetRewardToken() public returns (bool){
        dividendTracker.unsetRewardToken(msg.sender);
        return true;
    }
    
    // Activate trading on the contract and enable swapAndLiquify for tax redemption against LP
    function activateContract() public onlyOwner {
        isTradingEnabled = true;
        isSwapAndLiquifyEnabled = true;
    }
    
    // Holders can buyback with no fees up to their claimed raw ETH amount.
    function buyBackTokensWithNoFees() external payable returns (bool) {
        uint256 userRawETHDividends = getRawETHDividends(msg.sender);
        require(userRawETHDividends >= holderETHUsedForBuyBacks[msg.sender].add(msg.value), "CHOICE: buyBackTokensWithNoFees:: Cannot Spend more than earned.");
        
        uint256 ethAmount = msg.value;
        
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        
        // update amount to prevent user from buying with more ETH than they've received as raw rewards (lso update before transfer to prevent reentrancy)
        holderETHUsedForBuyBacks[msg.sender] = holderETHUsedForBuyBacks[msg.sender].add(msg.value);
        
        bool prevExclusion = _isExcludedFromFees[msg.sender]; // ensure we don't remove exclusions if the current wallet is already excluded
        // make the swap to the contract first to bypass fees
        _isExcludedFromFees[msg.sender] = true;
        
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}( //try to swap for tokens, if it fails (bad contract, or whatever other reason, send ETH)
            0,
            path,
            address(msg.sender),
            block.timestamp + 360
        );
        
        _isExcludedFromFees[msg.sender] = prevExclusion; // set value to match original value
        emit BuyBackWithNoFees(msg.sender, ethAmount);
        return true;
    }
    
    // allows a user to manually claim their tokens.
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }
    
    // allow a user to manuall process dividends.
    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
    
    // @dev Token functions
    
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "CHOICE: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isIgnoredAddress[to] || !_isIgnoredAddress[from], "CHOICE: To/from address is ignored");
        
        if(!isTradingEnabled) {
            require(_isAllowedDuringDisabled[to] || _isAllowedDuringDisabled[from], "Trading is currently disabled");
        }
        
        if(automatedMarketMakerPairs[to] && !isTradingEnabled && _isAllowedDuringDisabled[from]) {
            require((from == owner() || to == owner()) || _isAllowedDuringDisabled[from], "Only dev can trade against UNISWAP during migration");
        }
        
        // early exit with no other logic if transfering 0 (to prevent 0 transfers from triggering other logic)
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        // Prevent buying more than 1 txn per block at launch. Bot killer. Will be removed shortly after launch.
        
        if (transferDelayEnabled){
            if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair) && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]){
                require(_holderLastTransferTimestamp[to] < block.timestamp, "_transfer:: Transfer Delay enabled.  Please try again later.");
                _holderLastTransferTimestamp[to] = block.timestamp;
            }
        }
        
        // set last sell date to first purchase date for new wallet
        
        if(!isContract(to) && !_isExcludedFromFees[to]){
            if(_holderLastSellDate[to] == 0){
                _holderLastSellDate[to] == block.timestamp;
            }
        }
        
        // update sell date on buys to prevent gaming the decaying sell tax feature.  
        // Every buy moves the sell date up 1/3rd of the difference between last sale date and current timestamp
        
        if(!isContract(to) && automatedMarketMakerPairs[from] && !_isExcludedFromFees[to]){
            if(_holderLastSellDate[to] >= block.timestamp){
                _holderLastSellDate[to] = _holderLastSellDate[to].add(block.timestamp.sub(_holderLastSellDate[to]).div(3));
            }
        }
        
	if(automatedMarketMakerPairs[to]){

		require(amount <= maxSellTransactionAmount, "ERC20: Exceeds max sell amount");

		amount = amount.mul(_maxSellPercent).div(100); // Maximum sell of 99% per one single transaction, to ensure some loose change is left in the holders wallet .
	}

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(
            canSwap &&
            !swapping &&
            isSwapAndLiquifyEnabled &&
            !automatedMarketMakerPairs[from] &&
            from != liquidityWallet &&
            to != liquidityWallet &&
            from != operationsWallet &&
            to != operationsWallet &&
            from != buyBackWallet &&
            to != buyBackWallet &&
            !_isExcludedFromFees[to] &&
            !_isExcludedFromFees[from] &&
            from != address(this) &&
            from != address(dividendTracker)
        ) {

            swapping = true;
            
            uint256 swapTokens = contractTokenBalance.mul(liquidityFee).div(totalFees);
            swapAndLiquify(swapTokens);

            uint256 sellTokens = balanceOf(address(this));
            swapAndSendDividends(sellTokens);

            swapping = false;
        }


        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || from == address(this)) {
            takeFee = false;
        }
        if(takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);
            // if sell, multiply by holderSellFactor (decaying sell penalty by 10% every 2 weeks without selling)
            if(automatedMarketMakerPairs[to]) {
                uint256 rewardSellFee = amount.mul(RewardsFee).div(100).mul(rewardFeeSellFactor).div(100);
                uint256 otherSellFee = amount.mul(liquidityFee).div(100).mul(getHolderSellFactor(from)).div(100);
                fees = rewardSellFee.add(otherSellFee);
                _holderLastSellDate[from] = block.timestamp; // update last sale date on sell!
                
            }
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount);
        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        if(!swapping) {
            uint256 gas = gasForProcessing;
            try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            } 
            catch {
            }
        }
    }

    function swapAndLiquify(uint256 tokens) private {
        
        if(liquidityFee > 0){ // dividing by 0 is not fun.
            // split the contract balance into proper pieces
            // figure out how many tokens should be sold for liquidity vs operations / buybacks.
            uint256 tokensForLiquidity;
            if(liquidityFee > 0){
                tokensForLiquidity = tokens.mul(liquidityFee.sub(buyBackFee.add(operationsFee))).div(liquidityFee);
            } else {
                tokensForLiquidity = 0;
            }
            uint256 tokensForBuyBackAndOperations = tokens.sub(tokensForLiquidity);
            uint256 half = tokensForLiquidity.div(2);
            uint256 otherHalf = tokensForLiquidity.sub(half);
            uint256 initialBalance = address(this).balance;
            // swap tokens for ETH
            swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
            // add liquidity to uniswap
            addLiquidity(otherHalf, newBalance);
            swapTokensForEth(tokensForBuyBackAndOperations);
            uint256 balanceForOperationsAndBuyBack = address(this).balance.sub(initialBalance);
            bool success;
            if(operationsFee > 0){
                // Send amounts to Operations Wallet
                uint256 operationsBalance = balanceForOperationsAndBuyBack.mul(operationsFee).div(buyBackFee.add(operationsFee));
                (success,) = payable(operationsWallet).call{value: operationsBalance}("");
                require(success, "CHOICE: SwapAndLiquify:: Unable to send ETH to Operations Wallet");
            }
            if(buyBackFee > 0){
                // Send amounts to BuyBack Wallet
                uint256 buyBackBalance = balanceForOperationsAndBuyBack.mul(buyBackFee).div(buyBackFee.add(operationsFee));
                (success,) = payable(buyBackWallet).call{value: buyBackBalance}("");
                require(success, "CHOICE: SwapAndLiquify:: Unable to send ETH to BuyBack Wallet");
            }
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
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
            liquidityWallet,
            block.timestamp
        );
    }

    function swapAndSendDividends(uint256 tokens) private {
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance;
        (bool success,) = address(dividendTracker).call{value: dividends}("");
        if(success) {
            emit SendDividends(tokens, dividends);
        }
    }

	function recoverContractETH(uint256 recoverRate) public onlyOwner{
        		uint256 ethAmount = address(this).balance;
        		if(ethAmount > 0){
            	sendToOperationsWallet(ethAmount.mul(recoverRate).div(100));
        		}
    	}
	function sendToOperationsWallet(uint256 amount) private {
        		payable(operationsWallet).transfer(amount);
    	}

    function setMaxSellPercent(uint256 maxSellPercent) public onlyOwner {
        require(maxSellPercent < 100, "Max sell percent must be under 100%");
        _maxSellPercent = maxSellPercent;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }
    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }
    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }
    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }
    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }
        delete map.inserted[key];
        delete map.values[key];
        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract CHOICEDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;
    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("CHOICE_Dividend_Tracker", "CHOICE_Dividend_Tracker", 9) {
        claimWait = 3600;
        minimumTokenBalanceForDividends = 500 * (10**9); //must hold 500+ tokens to get divs
    }

    function _transfer(address, address, uint256) pure internal override {
        require(false, "CHOICE_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() pure public override {
        require(false, "CHOICE_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main CHOICE contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }

    function includeInDividends(address account) external onlyOwner {
        require(excludedFromDividends[account]);
        excludedFromDividends[account] = false;
        emit IncludeInDividends(account);
    }
    
    function updateDividendMinimum(uint256 minimumToEarnDivs) external onlyOwner {
        minimumTokenBalanceForDividends = minimumToEarnDivs;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "CHOICE_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "CHOICE_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;
        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

        if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }
            gasLeft = newGasLeft;
        }
        lastProcessedIndex = _lastProcessedIndex;
        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}