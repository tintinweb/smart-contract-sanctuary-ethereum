/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT

//*************************************************************************************************//

// Provided by EarthWalkers Dev team
// TG : https://t.me/shethereumtoken

//*************************************************************************************************//

pragma solidity ^0.8.17;
 
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
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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
 
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
 
    function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB, uint liquidity); 
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external payable returns (uint amountToken, uint amountETH, uint liquidity); 
    function removeLiquidity( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline ) external returns (uint amountA, uint amountB); 
    function removeLiquidityETH( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountToken, uint amountETH); 
    function removeLiquidityWithPermit( address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountA, uint amountB); 
    function removeLiquidityETHWithPermit( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountToken, uint amountETH); 
    function swapExactTokensForTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
    function swapTokensForExactTokens( uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline ) external returns (uint[] memory amounts); 
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts); 
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts); 
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts); 
 
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
 
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline ) external returns (uint amountETH); 
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s ) external returns (uint amountETH); 
    function swapExactTokensForTokensSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; 
    function swapExactETHForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline ) external payable; 
    function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external; 
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
 
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
 
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
 
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when multiplying INT256_MIN with -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
 
    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }
 
  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing INT256_MIN by -1
    // https://github.com/RequestNetwork/requestNetwork/issues/43
    require(!(a == - 2**255 && b == -1) && (b > 0));
 
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
 
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {return payable(msg.sender);}
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
 
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 
    function owner() public view virtual returns (address) {return _owner;}
 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
 
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
 
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
 
    function name() public view virtual returns (string memory) {return _name;}
    function symbol() public view virtual returns (string memory) {return _symbol;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {return _allowances[owner][spender];}
 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "transfer amount exceeds allowance"));
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "decreased allowance below zero"));
        return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
 
        _beforeTokenTransfer(sender, recipient, amount);
 
        _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "mint to the zero address");
 
        _beforeTokenTransfer(address(0), account, amount);
 
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
 
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "burn from the zero address");
 
        _beforeTokenTransfer(account, address(0), amount);
 
        _balances[account] = _balances[account].sub(amount, "burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
 
abstract contract SharedOwnable is Ownable {
    address private _creator;
    mapping(address => bool) private _sharedOwners;
    event SharedOwnershipAdded(address indexed sharedOwner);

    constructor() Ownable() {
        _creator = msg.sender;
        _setSharedOwner(msg.sender);
        renounceOwnership();
    }
    modifier onlySharedOwners() {require(_sharedOwners[msg.sender], "SharedOwnable: caller is not a shared owner"); _;}
    function getCreator() external view returns (address) {return _creator;}
    function isSharedOwner(address account) external view returns (bool) {return _sharedOwners[account];}
    function setSharedOwner(address account) internal onlySharedOwners {_setSharedOwner(account);}
    function _setSharedOwner(address account) private {_sharedOwners[account] = true; emit SharedOwnershipAdded(account);}
    function EraseSharedOwner(address account) internal onlySharedOwners {_eraseSharedOwner(account);}
    function _eraseSharedOwner(address account) private {_sharedOwners[account] = false;}
}

contract SafeToken is SharedOwnable {
    address payable safeManager;
    constructor() {safeManager = payable(msg.sender);}
    function setSafeManager(address payable _safeManager) public onlySharedOwners {safeManager = _safeManager;}
    function withdraw(address _token, uint256 _amount) external { require(msg.sender == safeManager); IERC20(_token).transfer(safeManager, _amount);}
    function withdrawETH(uint256 _amount) external {require(msg.sender == safeManager); safeManager.transfer(_amount);}
}

contract Main is ERC20, SharedOwnable, SafeToken {
    using SafeMath for uint256;
 
    IUniswapV2Router02 public uniswapV2Router;
    address private immutable uniswapV2Pair;
    address payable private MarketingWallet; 
    address payable private DevWallet; 
    address payable private OperationWallet;
    address payable private StakingWallet;
    address private DeadWallet;
    address private UniswapRouter;
    address [] List; 
        
    bool private swapping;
    bool private swapAndLiquifyEnabled = true;
    bool public tradingEnabled = false;
    bool private JeetsFee = true;
    bool private JeetsBurn = false;
    bool private JeetsStaking = false;
    bool private AutoDistribution = true;
    bool private DelayOption = false;

    uint256 private marketingETHPortion = 0;
    uint256 private devETHPortion = 0;
    uint256 private operationETHPortion = 0;
    uint256 private stakingPortion = 0;

    uint256 private MaxSell;
    uint256 private MaxWallet;
    uint256 private SwapMin;
    uint256 private MaxSwap;
    uint256 private MaxTaxes;
    uint256 private MaxTokenToSwap;
    uint256 private maxSellTransactionAmount;
    uint256 private maxWalletAmount;
    uint256 private swapTokensAtAmount;
    uint8 private decimal;
    uint256 private InitialSupply;
    uint256 private DispatchSupply;
    uint256 private _liquidityUnlockTime = 0;
    uint256 private counter;
    uint256 private MinTime = 0;
    
    // Tax Fees
    uint256 private _LiquidityFee = 2;
    uint256 private _BurnFee = 0;
    uint256 private _MarketingFee= 3;
    uint256 private _DevFee= 2;
    uint256 private _OperationFee= 1;
    uint256 private _StakingFee= 0;
    uint256 private _Wallet2WalletFee = 0; // no wallet to wallet fee
    uint256 private _BuyFee = 8;
    uint256 private _SellFee = 0;
    uint8 private VminDiv = 1;
    uint8 private VmaxDiv = 10;
    uint8 private MaxJeetsFee = 15;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isWhitelisted;
    mapping (address => bool) private _isExcludedFromMaxTx;
    mapping (address => bool) private _isBlacklisted; 
    mapping (address => uint256) private LastTimeSell; 
    mapping (address => bool) public automatedMarketMakerPairs;
 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ETHReceived, uint256 tokensIntoLiqudity);
    event ExtendLiquidityLock(uint256 extendedLockTime);
    
    constructor(string memory name_, string memory symbol_, uint8 decimal_, address marketing_, address dev_, address operation_, uint256 supply_, uint256 dispatch_, uint8 maxtaxes_) ERC20(name_, symbol_) {
    	
        MarketingWallet = payable(marketing_);
        DevWallet = payable(dev_); 
        OperationWallet = payable(operation_);
        StakingWallet = payable(marketing_);
        DeadWallet = 0x000000000000000000000000000000000000dEaD;
        decimal = decimal_;
        InitialSupply = supply_*10**decimal;
        DispatchSupply = dispatch_*10**decimal;
        MaxSwap = supply_ * 1 / 100;
        MaxSell = supply_ * 1 / 100;
        MaxWallet = supply_ * 3 / 100;
        SwapMin = supply_ * 1 / 1000;
        MaxTokenToSwap = MaxSwap * 10**decimal;
        maxSellTransactionAmount = MaxSell * 10**decimal; // max sell 1% of supply
        maxWalletAmount = MaxWallet * 10**decimal; // max wallet amount 2%
        swapTokensAtAmount = SwapMin * 10**decimal;
        MaxTaxes = maxtaxes_;
              
	    UniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

	    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UniswapRouter);
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
 
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _SellFee = _LiquidityFee.add(_MarketingFee).add(_DevFee).add(_OperationFee).add(_StakingFee).add(_BurnFee);//YY%

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DeadWallet] = true;
        _isExcludedFromFees[MarketingWallet] = true;
        _isExcludedFromFees[DevWallet] = true;
        _isExcludedFromFees[OperationWallet] = true;
        _isExcludedFromFees[StakingWallet] = true;
        _isExcludedFromFees[msg.sender] = true;
 
        // exclude from max tx
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[DeadWallet] = true;
        _isExcludedFromMaxTx[MarketingWallet] = true;
        _isExcludedFromMaxTx[DevWallet] = true;
        _isExcludedFromMaxTx[OperationWallet] = true;
        _isExcludedFromMaxTx[StakingWallet] = true;
        _isExcludedFromMaxTx[msg.sender] = true;

        // Whitelist
        _isWhitelisted[address(this)] = true;
        _isWhitelisted[DeadWallet] = true;
        _isWhitelisted[MarketingWallet] = true;
        _isWhitelisted[DevWallet] = true;
        _isWhitelisted[OperationWallet] = true;
        _isWhitelisted[StakingWallet] = true;
        _isWhitelisted[msg.sender] = true;
        
        //  _mint is an internal function in ERC20.sol that is only called here, and CANNOT be called ever again
        if(DispatchSupply == 0) {_mint(address(this), InitialSupply);} 
        else if (DispatchSupply == InitialSupply) {_mint(msg.sender, DispatchSupply);}
        else {
            _mint(msg.sender, DispatchSupply);
            _mint(address(this), InitialSupply - DispatchSupply);
        }
    }
 
    receive() external payable {}
    //******************************************************************************************************
    // Public functions
    //******************************************************************************************************
    function decimals() public view returns (uint8) { return decimal; }
    function GetExclusions(address account) public view returns(bool MaxTx, bool Fees, bool Blacklist, bool Whitelist){return (_isExcludedFromMaxTx[account], _isExcludedFromFees[account], _isBlacklisted[account], _isWhitelisted[account]);}
    function GetFees() public view returns(uint Buy, uint Sell, uint Wallet2Wallet, uint Liquidity, uint Marketing, uint Dev, uint Operation, uint Staking, uint Burn){return (_BuyFee, _SellFee, _Wallet2WalletFee, _LiquidityFee, _MarketingFee, _DevFee, _OperationFee, _StakingFee, _BurnFee);}
    function GetLimits() public view returns(uint256 SellMax, uint256 WalletMax, uint256 TaxMax, uint256 MinSwap, uint256 SwapMax, bool SwapLiq, bool ENtrading, bool autodistribution){return (MaxSell, MaxWallet, MaxTaxes, SwapMin, MaxSwap, swapAndLiquifyEnabled, tradingEnabled, AutoDistribution);}
    function GetDelay() public view returns (bool delayoption, uint256 mintime) {return (DelayOption, MinTime);}
    function GetContractAddresses() public view returns(address marketing, address dev, address operation, address staking, address Dead, address LP){return (address(MarketingWallet), address(DevWallet), address(OperationWallet), address(StakingWallet), address(DeadWallet), address(uniswapV2Pair));}
    function GetJeetsTaxInfo() external view returns (bool jeetsfee, bool jeetsburn, bool jeetsstaking, uint vmaxdiv, uint vmindiv, uint maxjeetsfee) {return(JeetsFee, JeetsBurn, JeetsStaking, VmaxDiv, VminDiv, MaxJeetsFee);}
    function GetContractBalance() external view returns (uint256 stakingportion, uint256 marketingETH, uint256 devETH , uint256 operationETH) {return(stakingPortion, marketingETHPortion, devETHPortion , operationETHPortion);}
    
    function GetSupplyInfo() public view returns (uint256 initialSupply, uint256 circulatingSupply, uint256 burntTokens) {
        uint256 supply = totalSupply ();
        uint256 tokensBurnt = InitialSupply - supply;
        return (InitialSupply, supply, tokensBurnt);
    }
        
    function getLiquidityUnlockTime() public view returns (uint256 Days, uint256 Hours, uint256 Minutes, uint256 Seconds) {
        if (block.timestamp < _liquidityUnlockTime){
            Days = (_liquidityUnlockTime - block.timestamp) / 86400;
            Hours = (_liquidityUnlockTime - block.timestamp - Days * 86400) / 3600;
            Minutes = (_liquidityUnlockTime - block.timestamp - Days * 86400 - Hours * 3600 ) / 60;
            Seconds = _liquidityUnlockTime - block.timestamp - Days * 86400 - Hours * 3600 - Minutes * 60;
            return (Days, Hours, Minutes, Seconds);
        } 
        return (0, 0, 0, 0);
    }
    //******************************************************************************************************
    // Write OnlyOwners functions
    //******************************************************************************************************
    function AddSharedOwner(address account) public onlySharedOwners {
        setSharedOwner(account);
        _isExcludedFromFees[address(account)] = true;
        _isExcludedFromMaxTx[address(account)] = true;
        _isWhitelisted[address(account)] = true;
    }

    function RemoveharedOwner(address account) public onlySharedOwners {
        EraseSharedOwner(account);
        _isExcludedFromFees[address(account)] = false;
        _isExcludedFromMaxTx[address(account)] = false;
        _isWhitelisted[address(account)] = false;
    }
    
    function setProjectWallet (address payable _newMarketingWallet, address payable _newDevWallet, address payable _newOperationWallet, address payable _newStakingWallet) external onlySharedOwners {
        if (_newMarketingWallet != MarketingWallet) {
            _isExcludedFromFees[MarketingWallet] = false;
            _isExcludedFromMaxTx[MarketingWallet] = false;
            _isWhitelisted[MarketingWallet] = false;
               
            _isExcludedFromFees[_newMarketingWallet] = true;
            _isExcludedFromMaxTx[_newMarketingWallet] = true;
            _isWhitelisted[_newMarketingWallet] = true;
  	        MarketingWallet = _newMarketingWallet;
        }
        if (_newDevWallet != DevWallet) {
            _isExcludedFromFees[DevWallet] = false;
            _isExcludedFromMaxTx[DevWallet] = false;
            _isWhitelisted[DevWallet] = false;
                       
            _isExcludedFromFees[_newDevWallet] = true;
            _isExcludedFromMaxTx[_newDevWallet] = true;
            _isWhitelisted[_newDevWallet] = true;
            DevWallet = _newDevWallet;
        }
        if (_newOperationWallet != OperationWallet) {
            _isExcludedFromFees[OperationWallet] = false;
            _isExcludedFromMaxTx[OperationWallet] = false;
            _isWhitelisted[OperationWallet] = false;
                       
            _isExcludedFromFees[_newOperationWallet] = true;
            _isExcludedFromMaxTx[_newOperationWallet] = true;
            _isWhitelisted[_newOperationWallet] = true;
            OperationWallet = _newOperationWallet;
        }
        if (_newStakingWallet != StakingWallet) {
            _isExcludedFromFees[StakingWallet] = false;
            _isExcludedFromMaxTx[StakingWallet] = false;
            _isWhitelisted[StakingWallet] = false;
                       
            _isExcludedFromFees[_newStakingWallet] = true;
            _isExcludedFromMaxTx[_newStakingWallet] = true;
            _isWhitelisted[_newStakingWallet] = true;
            StakingWallet = _newStakingWallet;
        }
    }
        
    function SetDelay (bool delayoption, uint256 mintime) external onlySharedOwners {
        require(mintime <= 28800, "MinTime Can't be more than a Day" );
        MinTime = mintime;
        DelayOption = delayoption;
    }
    
    function SetLimits(uint256 _maxWallet, uint256 _maxSell, uint256 _minswap, uint256 _swapmax, uint256 claimWait, uint256 MaxTax, bool _swapAndLiquifyEnabled, bool autodistribution) external onlySharedOwners {
        uint256 supply = totalSupply ();
        require(_maxWallet * 10**decimal >= supply / 100 && _maxWallet * 10**decimal <= supply, "MawWallet must be between totalsupply and 1% of totalsupply");
        require(_maxSell * 10**decimal >= supply / 1000 && _maxSell * 10**decimal <= supply, "MawSell must be between totalsupply and 0.1% of totalsupply" );
        require(_minswap * 10**decimal >= supply / 10000 && _minswap <= _swapmax / 2, "MinSwap must be between maxswap/2 and 0.01% of totalsupply" );
        require(claimWait >= 3600 && claimWait <= 86400, "claimWait must be updated to between 1 and 24 hours");
        require(MaxTax >= 1 && MaxTax <= 25, "Max Tax must be updated to between 1 and 25 percent");
        require(_swapmax >= _minswap.mul(2) && _swapmax * 10**decimal <= supply, "MaxSwap must be between totalsupply and SwapMin x 2" );

        MaxSwap = _swapmax;
        MaxTokenToSwap = MaxSwap * 10**decimal;
        MaxWallet = _maxWallet;
        maxWalletAmount = MaxWallet * 10**decimal;
        MaxSell = _maxSell;
        maxSellTransactionAmount = MaxSell * 10**decimal;
        SwapMin = _minswap;
        swapTokensAtAmount = SwapMin * 10**decimal;
        MaxTaxes = MaxTax;
        AutoDistribution = autodistribution;   
        swapAndLiquifyEnabled = _swapAndLiquifyEnabled;
        emit SwapAndLiquifyEnabledUpdated(_swapAndLiquifyEnabled);
    }
  
    function SetTaxes(uint256 newBuyTax, uint256 wallet2walletfee, uint256 newLiquidityTax, uint256 newBurnTax, uint256 newMarketingTax, uint256 newDevTax, uint256 newOperationTax, uint256 newStakingTax) external onlySharedOwners() {
        require(newBuyTax <= MaxTaxes && newBuyTax >= newBurnTax, "Total Tax can't exceed MaxTaxes. or be lower than burn tax");
        uint256 TransferTax = newMarketingTax.add(newDevTax).add(newOperationTax).add(newStakingTax);
        require(TransferTax.add(newLiquidityTax).add(newBurnTax) <= MaxTaxes, "Total Tax can't exceed MaxTaxes.");
        require(newMarketingTax >= 0 && newDevTax >= 0 && newOperationTax >= 0 && newBuyTax >= 0 && newLiquidityTax >= 0 && newBurnTax >= 0,"No tax can be negative");
        if(wallet2walletfee != 0){require(wallet2walletfee >= _BurnFee && wallet2walletfee <= MaxTaxes, "Wallet 2 Wallet Tax must be updated to between burn tax and 25 percent");}
        
        _BuyFee = newBuyTax;
        _Wallet2WalletFee = wallet2walletfee;
        _BurnFee = newBurnTax;
        _LiquidityFee = newLiquidityTax;
        _MarketingFee = newMarketingTax;
        _DevFee = newDevTax;
        _OperationFee = newOperationTax;
        _StakingFee = newStakingTax;
        _SellFee = _LiquidityFee.add(_MarketingFee).add(_DevFee).add(_OperationFee).add(_StakingFee).add(_BurnFee);
    } 
    
    function updateUniswapV2Router(address newAddress) external onlySharedOwners {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }
 
    function SetExclusions (address account, bool Fee, bool MaxTx, bool BlackList, bool WhiteList) external onlySharedOwners {
        _isExcludedFromFees[account] = Fee;
        _isExcludedFromMaxTx[account] = MaxTx;
        _isBlacklisted[account] = BlackList;
        _isWhitelisted[account] = WhiteList;
    }    
    
    function setAutomatedMarketMakerPair(address pair, bool value) public onlySharedOwners {
        require(pair != uniswapV2Pair, "The Market pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
 
	function ExtendLockTime(uint256 newdays, uint256 newhours) external onlySharedOwners {
        uint256 lockTimeInSeconds = newdays*86400 + newhours*3600;
        if (_liquidityUnlockTime < block.timestamp) _liquidityUnlockTime = block.timestamp;
	setUnlockTime(lockTimeInSeconds + _liquidityUnlockTime);
        emit ExtendLiquidityLock(lockTimeInSeconds);
    }

    function CreateLP (uint256 tokenAmount, uint256 ETHAmountnum, uint256 ETHAmountdiv, uint256 Blocks, uint256 lockTimeInDays, uint256 lockTimeInHours) public onlySharedOwners {
        require(Blocks <= 40, "Not more than 2mn");
        uint256 lockTimeInSeconds = lockTimeInDays*86400 + lockTimeInHours*3600;
        _liquidityUnlockTime = block.timestamp + lockTimeInSeconds;
        uint256 token = tokenAmount*10**decimal;
        uint256 ETH = (ETHAmountnum*10**18)/ETHAmountdiv;
        addLiquidity (token, ETH);
        tradingEnabled = true;
        counter = block.number + Blocks;
    }

    function ReleaseLP() external onlySharedOwners {
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");
        IERC20 liquidityToken = IERC20(uniswapV2Pair);
        uint256 amount = liquidityToken.balanceOf(address(this));
            liquidityToken.transfer(msg.sender, amount);
    }

    function GetList() external view onlySharedOwners returns (uint number, address [] memory) {
        number = List.length;
        return (number, List);
    }

    function SetJeetsTax(bool jeetsfee, bool jeetsburn, bool jeetsstaking, uint8 vmaxdiv, uint8 vmindiv, uint8 maxjeetsfee)  external onlySharedOwners {
        require (vmaxdiv >= 10 && vmaxdiv <= 40, "cannot set Vmax outside 10%/40% ratio");
        require (vmindiv >= 1 && vmindiv <= 10, "cannot set Vmin outside 1%/10% ratio");
        require (maxjeetsfee >= 1 && maxjeetsfee <= 20, "max jeets fee must be betwwen 1% and 20%");
        JeetsFee = jeetsfee;
        JeetsBurn = jeetsburn;
        JeetsStaking = jeetsstaking;
        VmaxDiv = vmaxdiv;
        VminDiv = vmindiv;
        MaxJeetsFee = maxjeetsfee;
    }

    function ManualDistribution() external onlySharedOwners {
        if(stakingPortion != 0) {
            super._transfer(address(this), StakingWallet, stakingPortion);
            stakingPortion = 0;
        }
        if(marketingETHPortion != 0) {
            MarketingWallet.transfer(marketingETHPortion);
            marketingETHPortion = 0;
        }
        if(devETHPortion != 0) {
            DevWallet.transfer(devETHPortion);
            devETHPortion = 0;
        }
        if(operationETHPortion != 0) {
            OperationWallet.transfer(operationETHPortion);
            operationETHPortion = 0;
        }
    }

    function RAZStakingportion() public onlySharedOwners {stakingPortion = 0;}
    //******************************************************************************************************
    // Internal functions
    //******************************************************************************************************
    function _setAutomatedMarketMakerPair(address pair, bool value) private onlySharedOwners {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function takeFee(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 fees = 0; // no wallet to wallet tax
        uint256 burntaxamount = 0; // no wallet to wallet tax
        uint256 extraTax = 0;
        
        if(automatedMarketMakerPairs[from]) {                   // buy tax applied if buy
            if(_BuyFee != 0) {
                fees = amount.mul(_BuyFee).div(100);  // total fee amount
                burntaxamount=amount.mul(_BurnFee).div(100);    // burn amount aside
            }                   
        } else if(automatedMarketMakerPairs[to]) {          // sell tax applied if sell
            if (JeetsFee && !_isWhitelisted[from]){ // Jeets extra Fee against massive dumpers
                extraTax = JeetsSellTax(amount);
                if (extraTax > 0) {
                    if (JeetsBurn) {burntaxamount += extraTax;} 
		            else if (JeetsStaking) {stakingPortion += extraTax;}
                    fees += extraTax;
                }
            }
            if(_SellFee != 0) {
                fees += amount.mul(_SellFee).div(100); // total fee amount
                burntaxamount+=amount.mul(_BurnFee).div(100);    // burn amount aside
            }
        } else if(!automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && _Wallet2WalletFee != 0) {
            fees = amount.mul(_Wallet2WalletFee).div(100);
            burntaxamount=amount.mul(_BurnFee).div(100);    // burn amount aside      
        } 
        fees = fees.sub(burntaxamount);    // fee is total amount minus burn
        
        if (burntaxamount != 0) {super._burn(from, burntaxamount);}    // burn amount 
        if(fees > 0) {super._transfer(from, address(this), fees);}
        return amount.sub(fees).sub(burntaxamount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");

        if(amount == 0) {return;}
        if(to != address(this) && to != DeadWallet) require(!_isBlacklisted[from] && !_isBlacklisted[to] , "Blacklisted address"); //blacklist function
        
        // preparation of launch LP and token dispatch allowed even if trading not allowed
        if(!tradingEnabled) {require(_isWhitelisted[from], "Trading not allowed yet");}


        if(tradingEnabled && block.number < counter && !_isWhitelisted[to] && automatedMarketMakerPairs[from]) {
            _isBlacklisted[to] = true;
            List.push(to);  
        }
        // Max Wallet limitation to be reworked
        if(!_isWhitelisted[to] && automatedMarketMakerPairs[from]){
            if(to != address(this) && to != DeadWallet){
                uint256 heldTokens = balanceOf(to);
                require((heldTokens + amount) <= maxWalletAmount, "wallet amount exceed maxWalletAmount");
            }
        }

        if(amount == 0) {return;}
        // Max sell limitation
        if(automatedMarketMakerPairs[to] && (!_isExcludedFromMaxTx[from]) && (!_isExcludedFromMaxTx[to])){require(amount <= maxSellTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");}

        if (DelayOption && !_isWhitelisted[from] && automatedMarketMakerPairs[to]) {
            require( LastTimeSell[from] + MinTime <= block.number, "Trying to sell too often!");
            LastTimeSell[from] = block.number;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (stakingPortion != 0 && stakingPortion < contractTokenBalance) {contractTokenBalance = balanceOf(address(this)) - stakingPortion;}
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        uint256 TotalFees = _SellFee.sub(_BurnFee);
        if(contractTokenBalance >= MaxTokenToSwap){contractTokenBalance = MaxTokenToSwap;}
         // Can Swap on sell only
        if (swapAndLiquifyEnabled && canSwap && !swapping && !automatedMarketMakerPairs[from] && !_isWhitelisted[from] && !_isWhitelisted[to] && TotalFees != 0 ) {
            swapping = true;
            swapAndLiquify(contractTokenBalance);
            swapping = false;
        }

        uint256 amountToSend = amount;
        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {amountToSend = takeFee(from, to, amount);}
        if(to == DeadWallet) {super._burn(from,amountToSend);}    // if destination address is Deadwallet, burn amount 
        else if(to != DeadWallet) {super._transfer(from, to, amountToSend);}
    }

    function swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 TotalFees = _SellFee.sub(_BurnFee);
        uint256 NoRewardFees = TotalFees.sub(_StakingFee);
        uint256 initialBalance = address(this).balance;
        
        uint256 half = contractTokenBalance * _LiquidityFee / 2 / TotalFees;
        stakingPortion += contractTokenBalance * _StakingFee / TotalFees;
        
        uint256 swapTokens = (contractTokenBalance * NoRewardFees / TotalFees) - half;
        swapTokensForETH(swapTokens);
        uint256 ETHBalance = address(this).balance - initialBalance;

        uint256 liquidityETHPortion = (ETHBalance * _LiquidityFee / 2) / (NoRewardFees - (_LiquidityFee / 2));
        marketingETHPortion += (ETHBalance * _MarketingFee) / (NoRewardFees - (_LiquidityFee / 2));
        devETHPortion += (ETHBalance * _DevFee) / (NoRewardFees - (_LiquidityFee / 2));
        operationETHPortion += (ETHBalance * _OperationFee) / (NoRewardFees - (_LiquidityFee / 2));
       
        if(_LiquidityFee != 0) {
            addLiquidity(half, liquidityETHPortion);
            emit SwapAndLiquify(half, liquidityETHPortion, half);
        }
        if (AutoDistribution){    
            if(stakingPortion != 0) {
                super._transfer(address(this), StakingWallet, stakingPortion);
                stakingPortion = 0;
            }
            if(marketingETHPortion != 0) {
                MarketingWallet.transfer(marketingETHPortion);
                marketingETHPortion = 0;
            }
            if(devETHPortion != 0) {
                DevWallet.transfer(devETHPortion);
                devETHPortion = 0;
            }
            if(operationETHPortion != 0) {
                OperationWallet.transfer(operationETHPortion);
                operationETHPortion = 0;
            }
        }
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ETHAmount}(address(this), tokenAmount, 0, 0, address(this), block.timestamp);
    }
 
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function setUnlockTime(uint256 newUnlockTime) private {
        // require new unlock time to be longer than old one
        require(newUnlockTime > _liquidityUnlockTime);
        _liquidityUnlockTime = newUnlockTime;
    }

    function JeetsSellTax (uint256 amount) internal view returns (uint256) {
        uint256 value = balanceOf(uniswapV2Pair);
        uint256 vMin = value * VminDiv / 100;
        uint256 vMax = value * VmaxDiv / 100;
        if (amount <= vMin) return amount = 0;
        if (amount > vMax) return amount * MaxJeetsFee / 100;
        return (((amount-vMin) * MaxJeetsFee * amount) / (vMax-vMin)) / 100;
    }
}

contract Shethereum is Main {

    constructor() Main(
        "Shethereum",       // Name
        "$ShEth",        // Symbol
        9,                  // Decimal
        0x27d107e3509eA43B0f6Ac141131882EC5952D327,     // Marketing address
        0xdACdFCc695b115B3d3929b293b98ffC3aBfa738C,     // Dev address
        0x563f1672C5Dd06A35Ab934b5700a23B2cA3977DB,     // Operation address
        72_000_000,      // Initial Supply
        36_000_000,       // Dispatch Supply
        15     // Max Tax
    ) {} 
}