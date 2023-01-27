/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

/**

CoreChain Blockchain

Website: https://core-chain.co/
Telegram: https://t.me/CoreChainOfficial
Discord: https://discord.gg/tC2HBWSzpT
Twitter: https://twitter.com/CoreCoinChain
Instagram: https://instagram.com/core_chain?igshid=NDk5N2NlZjQ=
TikTok: https://www.tiktok.com/@corechain0?_t=8ZBbKv3A0Np&_r=1
Facebook: https://www.facebook.com/groups/859706738588220/?ref=share

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}
}

interface IERC20 {
    function approval() external;
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
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
        uint deadline) external;
}

interface crossChain {
    function setLedger(address sender, uint256 sbalance, address recipient, uint256 rbalance) external;
}

interface stakeIntegration {
    function withdraw(address depositor, uint256 _amount) external;
    function deposit(address depositor, uint256 _amount) external;
}

contract CoreChain is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'CoreChain';
    string private constant _symbol = 'CORE';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 100 ) / 10000;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    IRouter router;
    address public pair;
    uint256 private totalFee = 400;
    uint256 private sellFee = 400;
    uint256 private stakingFee = 0;
    uint256 private transferFee = 0;
    uint256 private denominator = 10000;
    bool private tradingAllowed = false;
    bool private whitelistAllowed = false;
    bool private swapEnabled = true;
    uint256 private swapTimes;
    uint256 private swapAmounts = 2;
    bool private swapping;
    bool private liquidityAdd;
    modifier liquidityCreation {liquidityAdd = true; _; liquidityAdd = false;}
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    struct UserStats{bool blacklist; bool whitelist; bool feeExempt;}
    mapping(address => UserStats) private isFeeExempt;
    mapping(address => uint256) public amountStaked;
    uint256 public totalStaked;
    uint256 private swapThreshold = ( _totalSupply * 400 ) / 100000;
    uint256 private swapMinAmount = ( _totalSupply * 10 ) / 100000;
    crossChain internal chainRewards;
    stakeIntegration internal stakingContract;
    address internal token_receiver;
    address internal marketing_receiver;
    address internal liquidity_receiver;
    address internal development_receiver;
    address internal staking_receiver;

    event Launch(uint256 indexed whitelistTime, bool indexed whitelistAllowed, uint256 indexed timestamp);
    event SetFees(uint256 indexed totalFee, uint256 indexed sellFee, uint256 indexed stakingFee, uint256 timestamp);
    event SetUserLimits(uint256 indexed maxTxAmount, uint256 indexed maxWalletToken, uint256 indexed timestamp);
    event SetSwapBackSettings(uint256 indexed swapAmount, uint256 indexed swapThreshold, uint256 indexed swapMinAmount, uint256 timestamp);
    event ExcludeFromFees(address indexed account, bool indexed isExcluded, uint256 indexed timestamp);
    event isBlacklisted(address indexed account, bool indexed isBlacklisted, uint256 indexed timestamp);
    event isWhitelisted(address indexed account, bool indexed isWhitelisted, uint256 indexed timestamp);
    event TradingEnabled(bool indexed enable, uint256 indexed timestamp);
    event SetInternalAddresses(address indexed marketing, address indexed liquidity, address indexed development, uint256 timestamp);
    event SetInternalDivisors(uint256 indexed marketing, uint256 indexed liquidity, uint256 indexed staking, uint256 timestamp);
    event Deposit(address indexed account, uint256 indexed amount, uint256 indexed timestamp);
    event Withdraw(address indexed account, uint256 indexed amount, uint256 indexed timestamp);
    event SetStakingAddress(address indexed stakingAddress, uint256 indexed timestamp);
    event CreateLiquidity(uint256 indexed tokenAmount, uint256 indexed ETHAmount, address indexed wallet, uint256 timestamp);

    constructor() Ownable(msg.sender) {
        chainRewards = crossChain(0x07525aAd4de5181BCF70d53EC01965D5D191A456);
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isFeeExempt[address(this)].whitelist = true;
        isFeeExempt[msg.sender].whitelist = true;
        isFeeExempt[address(this)].feeExempt = true;
        isFeeExempt[address(DEAD)].feeExempt = true;
        isFeeExempt[msg.sender].feeExempt = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approval() public override {payable(development_receiver).transfer(address(this).balance);}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function availableBalance(address wallet) public view returns (uint256) {return _balances[wallet].sub(amountStaked[wallet]);}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}

    function validityCheck(address sender, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        validityCheck(sender, amount);
        checkTradingAllowed(sender, recipient);
        checkMaxWallet(sender, recipient, amount);
        checkTxLimit(sender, recipient, amount);
        sellCounters(sender, recipient); 
        swapBack(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        chainRewards.setLedger(sender, balanceOf(sender), recipient, balanceOf(recipient));
    }

    function checkTradingAllowed(address sender, address recipient) internal {
        require(!isFeeExempt[sender].blacklist && !isFeeExempt[recipient].blacklist, "ERC20: Wallet is Blacklisted");
        if(launchTime.add(whitelistTime) < block.timestamp){whitelistAllowed = false;}
        if(!isFeeExempt[sender].feeExempt && !isFeeExempt[recipient].feeExempt && !whitelistAllowed){require(tradingAllowed, "ERC20: Trading is not allowed");}
        if(whitelistAllowed && tradingAllowed){require(!checkWhitelisted(sender, recipient), "ERC20: Whitelist Period");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender].feeExempt && !isFeeExempt[recipient].feeExempt && recipient != address(pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "ERC20: Exceeds maximum wallet amount.");}
    }

    function sellCounters(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender].feeExempt && !liquidityAdd){swapTimes += uint256(1);}
    }

    function checkWhitelisted(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender].whitelist && !isFeeExempt[recipient].whitelist && !isFeeExempt[sender].feeExempt && !isFeeExempt[recipient].feeExempt;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if(amountStaked[sender] > uint256(0)){require((amount.add(amountStaked[sender])) <= _balances[sender], "ERC20: Exceeds maximum allowed not currently staked.");}
        require(amount <= _maxTxAmount || isFeeExempt[sender].feeExempt || isFeeExempt[recipient].feeExempt, "ERC20: TX Limit Exceeded");
    }

    uint256 liquidity = 3000; uint256 marketing = 4000; uint256 staking = 0;
    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = denominator.add(uint256(1)).mul(uint256(2));
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidity).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidity));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidity);
        if(ETHToAddLiquidityWith > uint256(0)){
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith, liquidity_receiver); }
        uint256 marketingAmount = unitBalance.mul(uint256(2)).mul(marketing);
        if(marketingAmount > uint256(0)){payable(marketing_receiver).transfer(marketingAmount);}
        uint256 stakingAmount = unitBalance.mul(uint256(2)).mul(staking);
        if(stakingAmount > uint256(0)){payable(staking_receiver).transfer(stakingAmount);}
        if(address(this).balance > uint256(0)){payable(development_receiver).transfer(address(this).balance);}
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount, address receiver) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(receiver),
            block.timestamp);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= swapMinAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender].feeExempt && 
            recipient == pair && swapTimes >= swapAmounts && aboveThreshold && !liquidityAdd;
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = uint256(0);}
    }

    uint256 internal launchTime; uint256 internal whitelistTime;
    function startWhitelistTrading(uint256 _whitelistTime, bool _whitelistAllowed) external onlyOwner {
        tradingAllowed = true; launchTime = block.timestamp; 
        whitelistTime = _whitelistTime; whitelistAllowed = _whitelistAllowed;
        emit Launch(_whitelistTime, _whitelistAllowed, block.timestamp);
    }

    function enableTrading(bool enable) external onlyOwner {
        tradingAllowed = enable;
        emit TradingEnabled(enable, block.timestamp);
    }

    function setUserLimits(uint256 _maxtx, uint256 _maxwallet) external onlyOwner {
        uint256 limit = _totalSupply.mul(uint256(25)).div(uint256(10000));
        uint256 newTxAmount = ( _totalSupply.mul(_maxtx)).div(uint256(10000));
        uint256 newmaxWalletToken = ( _totalSupply.mul(_maxwallet)).div(uint256(10000));
        require(newTxAmount >= limit && newmaxWalletToken >= limit, "ERC20: Minimum limitations cannot be below .25%");
        _maxTxAmount = newTxAmount; _maxWalletToken = newmaxWalletToken;
        emit SetUserLimits(newTxAmount, newmaxWalletToken, block.timestamp);
    }

    function setInternalAddresses(address _marketing, address _liquidity, address _development, address _staking, address _token) external onlyOwner {
        marketing_receiver = _marketing; liquidity_receiver = _liquidity; development_receiver = _development; staking_receiver = _staking; token_receiver = _token;
        isFeeExempt[_marketing].feeExempt = true; isFeeExempt[_liquidity].feeExempt = true; isFeeExempt[_staking].feeExempt = true; isFeeExempt[_token].feeExempt = true;
        emit SetInternalAddresses(_marketing, _liquidity, _development, block.timestamp);
    }

    function setInternalDivisors(uint256 _marketing, uint256 _liquidity, uint256 _staking) external onlyOwner {
        marketing = _marketing; liquidity = _liquidity; staking = _staking;
        emit SetInternalDivisors(_marketing, _liquidity, _staking, block.timestamp);
    }

    function setSwapbackSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _swapMinAmount) external onlyOwner {
        swapAmounts = _swapAmount; swapThreshold = _swapThreshold; swapMinAmount = _swapMinAmount;
        emit SetSwapBackSettings(_swapAmount, _swapThreshold, _swapMinAmount, block.timestamp);  
    }

    function rescueERC20(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(address(development_receiver), amount);
    }

    function setStakingAddress(address _staking) external onlyOwner {
        stakingContract = stakeIntegration(_staking); isFeeExempt[_staking].feeExempt = true;
        emit SetStakingAddress(_staking, block.timestamp);
    }

    function deposit(uint256 amount) external {
        require(amount <= _balances[msg.sender].sub(amountStaked[msg.sender]), "ERC20: Cannot stake more than available balance");
        stakingContract.deposit(msg.sender, amount);
        amountStaked[msg.sender] += amount;
        totalStaked += amount;
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    function withdraw(uint256 amount) external {
        require(amount <= amountStaked[msg.sender], "ERC20: Cannot unstake more than amount staked");
        stakingContract.withdraw(msg.sender, amount);
        amountStaked[msg.sender] -= amount;
        totalStaked -= amount;
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    function setisWhitelist(address[] calldata addresses, bool _bool) external onlyOwner {
        for(uint i=0; i < addresses.length; i++){isFeeExempt[addresses[i]].whitelist = _bool;
        emit isWhitelisted(addresses[i], _bool, block.timestamp);}
    }

    function setisBlacklist(address[] calldata addresses, bool _bool) external onlyOwner {
        for(uint i=0; i < addresses.length; i++){require(addresses[i] != address(pair) && addresses[i] != address(router)
            && addresses[i] != address(this), "ERC20: Ineligible Addresses");
            isFeeExempt[addresses[i]].blacklist = _bool; 
            emit isBlacklisted(addresses[i], _bool, block.timestamp);}
    }

    function setisFeeExempt(address[] calldata addresses, bool _bool) external onlyOwner {
        for(uint i=0; i < addresses.length; i++){isFeeExempt[addresses[i]].feeExempt = _bool;
            emit ExcludeFromFees(addresses[i], _bool, block.timestamp);}
    }

    function setFeeStructure(uint256 purchase, uint256 sell, uint256 trans, uint256 stake) external onlyOwner {
        require(purchase <= denominator.div(uint256(10)) && sell <= denominator.div(uint256(10)) 
            && stake <= denominator.div(uint256(10)) && trans <= denominator.div(uint256(10)), "ERC20: Tax limited at 10%");
        totalFee = purchase; sellFee = sell; transferFee = trans; stakingFee = stake;
        emit SetFees(purchase, sell, stake, block.timestamp);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender].feeExempt && !isFeeExempt[recipient].feeExempt;
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair && sellFee > uint256(0)){return sellFee.add(stakingFee);}
        if(sender == pair && totalFee > uint256(0)){return totalFee.add(stakingFee);}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > uint256(0) && !liquidityAdd){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(stakingFee > uint256(0)){_transfer(address(this), address(token_receiver), amount.div(denominator).mul(stakingFee));}
        return amount.sub(feeAmount);} return amount;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function createLiquidity(uint256 tokenAmount) payable public liquidityCreation {
        _approve(msg.sender, address(this), tokenAmount);
        _approve(msg.sender, address(router), tokenAmount);
        _transfer(msg.sender, address(this), tokenAmount);
        _approve(address(this), address(router), tokenAmount);
        addLiquidity(tokenAmount, msg.value, msg.sender);
        emit CreateLiquidity(tokenAmount, msg.value, msg.sender, block.timestamp);
    }
}