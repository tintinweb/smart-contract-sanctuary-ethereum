/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

/**

https://t.me/BobcatAI

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


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
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
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

interface stakeIntegration {
    function stakingWithdraw(address depositor, uint256 _amount) external;
    function stakingDeposit(address depositor, uint256 _amount) external;
}

interface tokenStaking {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract BobcatAI is IERC20, tokenStaking, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'Bobcat AI';
    string private constant _symbol = 'BOBCAT';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxSellAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 100 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    struct UserStats{bool whitelist; bool isBot; bool feeExempt;}
    mapping(address => UserStats) private isFeeExempt;
    IRouter router;
    address public pair;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 200;
    uint256 private developmentFee = 100;
    uint256 private stakingFee = 0;
    uint256 private tokenFee = 0;
    uint256 private totalFee = 2000;
    uint256 private sellFee = 2000;
    uint256 private transferFee = 2000;
    uint256 private denominator = 10000;
    bool private swapEnabled = true;
    bool private whitelistAllowed = false;
    bool private tradingAllowed = false;
    mapping(address => uint256) private lastTransferTimestamp;
    bool public transferDelayEnabled = true;
    uint256 private swapTimes;
    bool private swapping;
    bool private liquidityAdd;
    modifier liquidityCreation {liquidityAdd = true; _; liquidityAdd = false;}
    uint256 private swapAmount = 2;
    uint256 private swapThreshold = ( _totalSupply * 200 ) / 100000;
    uint256 private minTokenAmount = ( _totalSupply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    mapping(address => uint256) public amountStaked;
    uint256 public totalStaked;
    stakeIntegration internal stakingContract;
    
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal development_receiver = 0x6b3E4261576d6Dd0c6EDa6714ab9E390F76978D8; 
    address internal marketing_receiver = 0xe810E5C054D2D52E8148759BaA5fF3494Df466Db;
    address internal liquidity_receiver = 0x6b3E4261576d6Dd0c6EDa6714ab9E390F76978D8;
    address internal staking_receiver = 0x6b3E4261576d6Dd0c6EDa6714ab9E390F76978D8;
    address internal token_receiver = 0x000000000000000000000000000000000000dEaD;
    
    event Deposit(address indexed account, uint256 indexed amount, uint256 indexed timestamp);
    event Withdraw(address indexed account, uint256 indexed amount, uint256 indexed timestamp);
    event SetStakingAddress(address indexed stakingAddress, uint256 indexed timestamp);
    event SetisBot(address indexed account, bool indexed isBot, uint256 indexed timestamp);
    event TradingEnabled(address indexed account, uint256 indexed timestamp);
    event isWhitelisted(address indexed account, bool indexed isWhitelisted, uint256 indexed timestamp);
    event ExcludeFromFees(address indexed account, bool indexed isExcluded, uint256 indexed timestamp);
    event SetDividendExempt(address indexed account, bool indexed isExempt, uint256 indexed timestamp);
    event Launch(uint256 indexed whitelistTime, bool indexed whitelistAllowed, uint256 indexed timestamp);
    event SetInternalAddresses(address indexed marketing, address indexed liquidity, address indexed development, uint256 timestamp);
    event SetSwapBackSettings(uint256 indexed swapAmount, uint256 indexed swapThreshold, uint256 indexed swapMinAmount, uint256 timestamp);
    event SetDistributionCriteria(uint256 indexed minPeriod, uint256 indexed minDistribution, uint256 indexed distributorGas, uint256 timestamp);
    event SetParameters(uint256 indexed maxTxAmount, uint256 indexed maxWalletToken, uint256 indexed maxTransfer, uint256 timestamp);
    event SetStructure(uint256 indexed total, uint256 indexed sell, uint256 transfer, uint256 indexed timestamp);
    event CreateLiquidity(uint256 indexed tokenAmount, uint256 indexed ETHAmount, address indexed wallet, uint256 timestamp);

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isFeeExempt[address(this)].whitelist = true;
        isFeeExempt[msg.sender].whitelist = true;
        isFeeExempt[address(this)].feeExempt = true;
        isFeeExempt[liquidity_receiver].feeExempt = true;
        isFeeExempt[marketing_receiver].feeExempt = true;
        isFeeExempt[development_receiver].feeExempt = true;
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
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function availableBalance(address wallet) public view returns (uint256) {return _balances[wallet].sub(amountStaked[wallet]);}
    function circulatingSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"ERC20: below available balance threshold");
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);
        checkTradingAllowed(sender, recipient);
        checkTxLimit(sender, recipient, amount);
        checkMaxWallet(sender, recipient, amount);
        checkTradeDelay(sender, recipient);
        swapbackCounters(sender, recipient);
        swapBack(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function deposit(uint256 amount) override external {
        require(amount <= _balances[msg.sender].sub(amountStaked[msg.sender]), "ERC20: Cannot stake more than available balance");
        stakingContract.stakingDeposit(msg.sender, amount);
        amountStaked[msg.sender] = amountStaked[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);
        emit Deposit(msg.sender, amount, block.timestamp);
    }

    function withdraw(uint256 amount) override external {
        require(amount <= amountStaked[msg.sender], "ERC20: Cannot unstake more than amount staked");
        stakingContract.stakingWithdraw(msg.sender, amount);
        amountStaked[msg.sender] = amountStaked[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    uint256 internal launchTime; uint256 internal whitelistTime;
    function startWhitelistTrading(uint256 _whitelistTime, bool _whitelistAllowed) external onlyOwner {
        require(!whitelistAllowed, "ERC20: whitelist period already enabled");
        tradingAllowed = true; launchTime = block.timestamp; 
        whitelistTime = _whitelistTime; whitelistAllowed = _whitelistAllowed;
        emit Launch(_whitelistTime, _whitelistAllowed, block.timestamp);
    }

    function setisWhitelist(address[] calldata addresses, bool _bool) external onlyOwner {
        for(uint i=0; i < addresses.length; i++){isFeeExempt[addresses[i]].whitelist = _bool;
        emit isWhitelisted(addresses[i], _bool, block.timestamp);}
    }

    function setStakingAddress(address _staking) external onlyOwner {
        stakingContract = stakeIntegration(_staking); isFeeExempt[_staking].feeExempt = true;
        emit SetStakingAddress(_staking, block.timestamp);
    }

    function setStructure(uint256 _liquidity, uint256 _marketing, uint256 _token, uint256 _development, uint256 _staking, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; tokenFee = _token; stakingFee = _staking;
        developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator.div(5) && sellFee <= denominator.div(5) && transferFee <= denominator.div(5), "ERC20: fees cannot be more than 20%");
        emit SetStructure(_total, _sell, _trans, block.timestamp);
    }

    function setisBot(address _address, bool _enabled) external onlyOwner {
        require(_address != address(pair) && _address != address(router) && _address != address(this) && _address != address(DEAD), "ERC20: ineligible address");
        isFeeExempt[_address].isBot = _enabled;
        emit SetisBot(_address, _enabled, block.timestamp);
    }

    function setParameters(uint256 _buy, uint256 _trans, uint256 _wallet) external onlyOwner {
        uint256 newTx = (totalSupply() * _buy) / 10000; uint256 newTransfer = (totalSupply() * _trans) / 10000;
        uint256 newWallet = (totalSupply() * _wallet) / 10000; uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "ERC20: max TXs and max Wallet cannot be less than .5%");
        _maxTxAmount = newTx; _maxSellAmount = newTransfer; _maxWalletToken = newWallet;
        emit SetParameters(newTx, newWallet, newTransfer, block.timestamp);
    }

    function setTransferDelay(bool enabled) external onlyOwner {
        transferDelayEnabled = enabled;
    }

    function checkTradingAllowed(address sender, address recipient) internal {
        if(launchTime.add(whitelistTime) < block.timestamp){whitelistAllowed = false;}
        if(!isFeeExempt[sender].feeExempt && !isFeeExempt[recipient].feeExempt && !whitelistAllowed){require(tradingAllowed, "ERC20: Trading is not allowed");}
        if(whitelistAllowed && tradingAllowed){require(!whitelistIneligible(sender, recipient), "ERC20: Whitelist Period");}
    }
    
    function whitelistIneligible(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender].whitelist && !isFeeExempt[recipient].whitelist && !isFeeExempt[sender].feeExempt && !isFeeExempt[recipient].feeExempt;
    }

    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender].feeExempt && !isFeeExempt[recipient].feeExempt && recipient != address(pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "ERC20: exceeds maximum wallet amount.");}
    }

    function checkTradeDelay(address sender, address recipient) internal {
        if(transferDelayEnabled && !isFeeExempt[sender].feeExempt && !isFeeExempt[recipient].feeExempt && recipient != address(pair) &&
            recipient != address(DEAD) && recipient != address(router)){
                require(lastTransferTimestamp[tx.origin] < block.number, "ERC20: Transfer Delay enabled. Only one purchase per block allowed.");
                    lastTransferTimestamp[tx.origin] = block.number;}
    }

    function swapbackCounters(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender].feeExempt && !liquidityAdd){swapTimes += uint256(1);}
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if(amountStaked[sender] > uint256(0)){require((amount.add(amountStaked[sender])) <= _balances[sender], "ERC20: exceeds maximum allowed not currently staked.");}
        if(sender != pair){require(amount <= _maxSellAmount || isFeeExempt[sender].feeExempt || isFeeExempt[recipient].feeExempt, "ERC20: tx limit exceeded");}
        require(amount <= _maxTxAmount || isFeeExempt[sender].feeExempt || isFeeExempt[recipient].feeExempt, "ERC20: tx limit exceeded");
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee).add(stakingFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith, liquidity_receiver); }
        uint256 marketingAmount = unitBalance.mul(2).mul(marketingFee);
        if(marketingAmount > 0){payable(marketing_receiver).transfer(marketingAmount);}
        uint256 stakingAmount = unitBalance.mul(2).mul(stakingFee);
        if(stakingAmount > 0){payable(staking_receiver).transfer(stakingAmount);}
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
        bool aboveMin = amount >= minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender].feeExempt 
            && recipient == pair && swapTimes >= swapAmount && aboveThreshold && !liquidityAdd;
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = uint256(0);}
    }
    
    function startTrading() external onlyOwner {
        tradingAllowed = true;
        emit TradingEnabled(msg.sender, block.timestamp);
    }

    function setInternalAddresses(address _marketing, address _liquidity, address _development, address _staking, address _token) external onlyOwner {
        marketing_receiver = _marketing; liquidity_receiver = _liquidity; development_receiver = _development; staking_receiver = _staking; token_receiver = _token;
        isFeeExempt[_marketing].feeExempt = true; isFeeExempt[_liquidity].feeExempt = true; isFeeExempt[_staking].feeExempt = true; isFeeExempt[_token].feeExempt = true;
        emit SetInternalAddresses(_marketing, _liquidity, _development, block.timestamp);
    }

    function setisExempt(address _address, bool _enabled) external onlyOwner {
        isFeeExempt[_address].feeExempt = _enabled;
        emit ExcludeFromFees(_address, _enabled, block.timestamp);
    }

    function rescueERC20(address _address, uint256 _amount) external {
        IERC20(_address).transfer(development_receiver, _amount);
    }

    function setSwapbackSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        swapAmount = _swapAmount; swapThreshold = _swapThreshold; minTokenAmount = _minTokenAmount;
        emit SetSwapBackSettings(_swapAmount, _swapThreshold, _minTokenAmount, block.timestamp);  
    }

    function createLiquidity(uint256 tokenAmount) payable public liquidityCreation {
        _approve(msg.sender, address(this), tokenAmount);
        _approve(msg.sender, address(router), tokenAmount);
        _transfer(msg.sender, address(this), tokenAmount);
        _approve(address(this), address(router), tokenAmount);
        addLiquidity(tokenAmount, msg.value, msg.sender);
        emit CreateLiquidity(tokenAmount, msg.value, msg.sender, block.timestamp);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender].feeExempt && !isFeeExempt[recipient].feeExempt;
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(isFeeExempt[sender].isBot || isFeeExempt[recipient].isBot){return denominator.sub(uint256(100));}
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0 && !liquidityAdd){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(tokenFee > uint256(0)){_transfer(address(this), address(token_receiver), amount.div(denominator).mul(tokenFee));}
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
}