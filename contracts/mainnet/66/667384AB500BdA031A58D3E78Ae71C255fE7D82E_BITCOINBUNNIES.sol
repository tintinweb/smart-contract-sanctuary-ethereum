/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

/**

╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═ 
╩═╦═╩═╦═╩═╦▄████▄═╦▄████▄═╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═ 
╦═╩═╦═╩═╦═╩██▀▀██═╩██▀▀██═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═ 
╩═╦═╩═╦═╩═╦██──██═╦██──██═╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═ 
╦═╩═╦═╩═╦═╩██──██═╩██──██═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═ 
╩═╦═╩═╦═╩═╦██──██═╦██──██═╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═ 
╦═╩═╦═╩═╦═╩██──██═╩██──██═╩═╦═╩═╦═╩═╦═╩═╦═╩═╦═ 
╩═╦═╩═╦═╩═▄██──██████──██▄╦═╩═╦═╩═╦═╩═╦═╩═╦═╩═ 
╦═╩═╦═╩═▄███▀──────────▀███▄╦═╩═╦═╩═╦═╩═╦═╩═╦═ 
╩═╦═╩═╦██▀────────────────▀██═╦═╩═╦═╩═╦═╩═╦═╩═ 
╦═╩═╦═███─────██─────██────███╩═╦═╩═╦═╩═╦═╩═╦═ 
╩═╦═╩═██──────██─────██─────██╦═╩═╦═╩═╦═╩═╦═╩═ 
╦═╩═╦═██─██▄██▄─────────────██╩▄▄▄╩═█▄╩═▄▄▄═╦═ 
╩═╦═╩═██─██████─────────────██╦═▀▀▀▄██▄▀▀▀╦═╩═ 
╦═╩═╦▄███████▀───▒▒▒────────██╩═╦═█▒▒▒▒█╦═╩═╦═ 
╩═╦▄█████▀─────────────────▄██╦═╩███████╩═╦═╩═ 
╦═▐█████▄▄───────────────▄▄██═╩═▄███▒▒▒█╦═╩═╦═ 
╩═▐████▀▀█████▄▄▄▄▄▄▄█████▀▀╩═╦▄████▒▒██╩═╦═╩═ 
╦═▐█████▄▄▄██▀▀▀▀▀▀▀▀▀██▄▄▄▄████████▒▒██╦═╩═╦═ 
╩═╦▀████████████▄▄▄██████████████▀╦█▒▒▒█╩═╦═╩═ 
╦═╩═╦▀████████████████████████▀═╦═╩█▒▒▒█╦═╩═╦═


███████████████████████████████████████████████████████████████████████████████████████
█▄─▄─▀█▄─▄█─▄─▄─█─▄▄▄─█─▄▄─█▄─▄█▄─▀█▄─▄███▄─▄─▀█▄─██─▄█▄─▀█▄─▄█▄─▀█▄─▄█▄─▄█▄─▄▄─█─▄▄▄▄█
██─▄─▀██─████─███─███▀█─██─██─███─█▄▀─█████─▄─▀██─██─███─█▄▀─███─█▄▀─███─███─▄█▀█▄▄▄▄─█
▀▄▄▄▄▀▀▄▄▄▀▀▄▄▄▀▀▄▄▄▄▄▀▄▄▄▄▀▄▄▄▀▄▄▄▀▀▄▄▀▀▀▄▄▄▄▀▀▀▄▄▄▄▀▀▄▄▄▀▀▄▄▀▄▄▄▀▀▄▄▀▄▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀

https://medium.com/@bitcoinbunnieserc

https://twitter.com/BtcBunnies_ERC

https://t.me/BitcoinBunniesERC

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
    function stakingClaimToCompound(address sender, address recipient) external;
}

interface tokenStaking {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function compound() external;
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

contract BITCOINBUNNIES is tokenStaking, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'Bitcoin Bunnies';
    string private constant _symbol = 'BTCBY';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 150 ) / 10000;
    uint256 public _maxSellAmount = ( _totalSupply * 150 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 300 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) private isBot;
    IRouter router;
    address public pair;
    bool private tradingAllowed = false;
    uint256 private liquidityFee = 0;
    uint256 private marketingFee = 300;
    uint256 private rewardsFee = 400;
    uint256 private developmentFee = 300;
    uint256 private stakingFee = 0;
    uint256 private tokenFee = 0;
    uint256 private totalFee = 2000;
    uint256 private sellFee = 7500;
    uint256 private transferFee = 2000;
    uint256 private denominator = 10000;
    bool private swapEnabled = true;
    uint256 private swapTimes;
    uint256 private swapAmount = 2;
    bool private swapping;
    bool private liquidityAdd;
    modifier liquidityCreation {liquidityAdd = true; _; liquidityAdd = false;}
    uint256 private swapThreshold = ( _totalSupply * 500 ) / 100000;
    uint256 private minTokenAmount = ( _totalSupply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    mapping(address => uint256) private lastTransferTimestamp;
    bool public transferDelayEnabled = true;
    mapping(address => uint256) public amountStaked;
    uint256 public totalStaked;
    address internal token_receiver;
    stakeIntegration internal stakingContract;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public currentDividends;
    uint256 public excessDividends;
    uint256 internal dividendsPerShare;
    uint256 internal dividendsPerShareAccuracyFactor = 10 ** 36;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    struct Share {uint256 amount; uint256 totalExcluded; uint256 totalRealised; }
    mapping (address => Share) public shares;
    uint256 internal currentIndex;
    uint256 public minPeriod = 15 minutes;
    uint256 public minDistribution = 1 * (10 ** 9);
    uint256 public distributorGas = 1;
    address public reward = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal development_receiver = 0xDCC0d2233Baaf1fa983cc83FE705F9D110D197F9; 
    address internal marketing_receiver = 0x7c7279B16F7886E9f5D4bF588C777A27a36b5639;
    address internal liquidity_receiver = 0x7c7279B16F7886E9f5D4bF588C777A27a36b5639;
    address internal staking_receiver = 0x7c7279B16F7886E9f5D4bF588C777A27a36b5639;
    
    event Deposit(address indexed account, uint256 indexed amount, uint256 indexed timestamp);
    event Withdraw(address indexed account, uint256 indexed amount, uint256 indexed timestamp);
    event Compound(address indexed account, uint256 ethAmount, uint256 indexed timestamp);
    event SetStakingAddress(address indexed stakingAddress, uint256 indexed timestamp);
    event SetisBot(address indexed account, bool indexed isBot, uint256 indexed timestamp);
    event ExcludeFromFees(address indexed account, bool indexed isExcluded, uint256 indexed timestamp);
    event SetDividendExempt(address indexed account, bool indexed isExempt, uint256 indexed timestamp);
    event SetInternalAddresses(address indexed marketing, address indexed liquidity, address indexed development, uint256 timestamp);
    event SetDistributionCriteria(uint256 indexed minPeriod, uint256 indexed minDistribution, uint256 indexed distributorGas, uint256 timestamp);
    event SetParameters(uint256 indexed maxTxAmount, uint256 indexed maxWalletToken, uint256 indexed maxTransfer, uint256 timestamp);
    event SetSwapBackSettings(uint256 indexed swapAmount, uint256 indexed swapThreshold, uint256 indexed swapMinAmount, uint256 timestamp);
    event SetStructure(uint256 indexed total, uint256 indexed sell, uint256 transfer, uint256 indexed timestamp);
    event CreateLiquidity(uint256 indexed tokenAmount, uint256 indexed ETHAmount, address indexed wallet, uint256 timestamp);

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        token_receiver = address(this);
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidity_receiver] = true;
        isFeeExempt[marketing_receiver] = true;
        isFeeExempt[msg.sender] = true;
        isDividendExempt[address(pair)] = true;
        isDividendExempt[address(msg.sender)] = false;        
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(DEAD)] = true;
        isDividendExempt[address(0)] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradingAllowed = true;}
    function getOwner() external view override returns (address) { return owner; }
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function isCont(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0; }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function availableBalance(address wallet) public view returns (uint256) {return _balances[wallet].sub(amountStaked[wallet]);}
    function circulatingSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);
        checkTradingAllowed(sender, recipient);
        checkMaxWallet(sender, recipient, amount); 
        checkTxLimit(sender, recipient, amount);
        checkTradeDelay(sender, recipient);
        swapbackCounters(sender, recipient);
        swapBack(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        processRewards(sender, recipient);
    }

    function internalDeposit(address sender, uint256 amount) internal {
        require(amount <= _balances[sender].sub(amountStaked[sender]), "ERC20: Cannot stake more than available balance");
        stakingContract.stakingDeposit(sender, amount);
        amountStaked[sender] = amountStaked[sender].add(amount);
        totalStaked = totalStaked.add(amount);
        emit Deposit(sender, amount, block.timestamp);
    }

    function deposit(uint256 amount) override external {
        internalDeposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) override external {
        require(amount <= amountStaked[msg.sender], "ERC20: Cannot unstake more than amount staked");
        stakingContract.stakingWithdraw(msg.sender, amount);
        amountStaked[msg.sender] = amountStaked[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    function compound() override external {
        uint256 initialBalance = address(this).balance;
        uint256 initialToken = balanceOf(msg.sender);
        stakingContract.stakingClaimToCompound(msg.sender, address(this));
        uint256 afterBalance = address(this).balance.sub(initialBalance);
        swapETHForTokens(afterBalance, address(this), msg.sender);
        uint256 afterToken = balanceOf(msg.sender).sub(initialToken);
        internalDeposit(msg.sender, afterToken);
        emit Compound(msg.sender, afterBalance, block.timestamp);
    }

    function setStakingAddress(address _staking) external onlyOwner {
        stakingContract = stakeIntegration(_staking); isFeeExempt[_staking] = true;
        emit SetStakingAddress(_staking, block.timestamp);
    }

    function setStructure(uint256 _liquidity, uint256 _marketing, uint256 _token, uint256 _rewards, uint256 _staking, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; marketingFee = _marketing; tokenFee = _token; rewardsFee = _rewards; stakingFee = _staking;
        developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator.div(5) && sellFee <= denominator.div(5) && tokenFee <= denominator.div(5) && transferFee <= denominator.div(5), "totalFee and sellFee cannot be more than 20%");
        emit SetStructure(_total, _sell, _trans, block.timestamp);
    }

    function setisBot(address _address, bool _enabled) external onlyOwner {
        require(_address != address(pair) && _address != address(router) && _address != address(this) && _address != address(DEAD) && _address != address(token_receiver), "Ineligible Address");
        isBot[_address] = _enabled;
        emit SetisBot(_address, _enabled, block.timestamp);
    }

    function setParameters(uint256 _buy, uint256 _trans, uint256 _wallet) external onlyOwner {
        uint256 newTx = (totalSupply() * _buy) / 10000; uint256 newTransfer = (totalSupply() * _trans) / 10000;
        uint256 newWallet = (totalSupply() * _wallet) / 10000; uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "ERC20: max TXs and max Wallet cannot be less than .5%");
        _maxTxAmount = newTx; _maxSellAmount = newTransfer; _maxWalletToken = newWallet;
        emit SetParameters(newTx, newWallet, newTransfer, block.timestamp);
    }

    function checkTradingAllowed(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "tradingAllowed");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function swapbackCounters(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender] && !liquidityAdd){swapTimes += uint256(1);}
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if(amountStaked[sender] > uint256(0)){require((amount.add(amountStaked[sender])) <= _balances[sender], "ERC20: Exceeds maximum allowed not currently staked.");}
        if(sender != pair){require(amount <= _maxSellAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function setSwapbackSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        swapAmount = _swapAmount; swapThreshold = _swapThreshold; minTokenAmount = _minTokenAmount;
        emit SetSwapBackSettings(_swapAmount, _swapThreshold, _minTokenAmount, block.timestamp);  
    }

    function setInternalAddresses(address _marketing, address _liquidity, address _development, address _staking, address _token) external onlyOwner {
        marketing_receiver = _marketing; liquidity_receiver = _liquidity; development_receiver = _development; staking_receiver = _staking; token_receiver = _token;
        isFeeExempt[_marketing] = true; isFeeExempt[_liquidity] = true; isFeeExempt[_development] = true; isFeeExempt[_staking] = true; isFeeExempt[_token] = true;
        emit SetInternalAddresses(_marketing, _liquidity, _development, block.timestamp);
    }

    function checkTradeDelay(address sender, address recipient) internal {
        if(transferDelayEnabled && !isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(pair) &&
            recipient != address(DEAD) && recipient != address(router)){
                require(lastTransferTimestamp[tx.origin] < block.number, "ERC20: Transfer Delay enabled. Only one purchase per block allowed.");
                    lastTransferTimestamp[tx.origin] = block.number;}
    }

    function setTransferDelay(bool enabled) external onlyOwner {
        transferDelayEnabled = enabled;
    }

    function setisExempt(address _address, bool _enabled) external onlyOwner {
        isFeeExempt[_address] = _enabled;
        emit ExcludeFromFees(_address, _enabled, block.timestamp);
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFee.add(1).add(marketingFee).add(developmentFee).add(rewardsFee).add(stakingFee)).mul(2);
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
        uint256 rewardsAmount = unitBalance.mul(2).mul(rewardsFee);
        if(rewardsAmount > 0){depositRewards(rewardsAmount);}
        uint256 stakingAmount = unitBalance.mul(2).mul(stakingFee);
        if(stakingAmount > 0){payable(staking_receiver).transfer(stakingAmount);}
        uint256 excessAmount = address(this).balance;
        if(excessAmount > uint256(0)){payable(development_receiver).transfer(excessAmount);}
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

    function swapETHForTokens(uint256 amountETH, address token, address recipient) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(token);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(
            0,
            path,
            address(recipient),
            block.timestamp);
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender] 
            && recipient == pair && swapTimes >= swapAmount && aboveThreshold && !liquidityAdd;
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = uint256(0);}
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(isBot[sender] || isBot[recipient]){return denominator.sub(uint256(100));}
        if(recipient == pair && sellFee > uint256(0)){return sellFee.add(tokenFee);}
        if(sender == pair && totalFee > uint256(0)){return totalFee.add(tokenFee);}
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

    function setisDividendExempt(address holder, bool exempt) external onlyOwner {
        isDividendExempt[holder] = exempt;
        if(exempt){setShare(holder, 0);}
        else{setShare(holder, balanceOf(holder));}
        emit SetDividendExempt(holder, exempt, block.timestamp);
    }

    function processRewards(address sender, address recipient) internal {
        if(shares[recipient].amount > 0){distributeDividend(recipient, recipient);}
        if(recipient == pair && shares[sender].amount > 0){excessDividends = excessDividends.add(getUnpaidEarnings(sender));}
        if(!isDividendExempt[sender]){setShare(sender, balanceOf(sender));}
        if(!isDividendExempt[recipient]){setShare(recipient, balanceOf(recipient));}
        processAuto(distributorGas);
    }

    function setShare(address shareholder, uint256 amount) internal {
        if(amount > 0 && shares[shareholder].amount == 0){addShareholder(shareholder);}
        else if(amount == 0 && shares[shareholder].amount > 0){removeShareholder(shareholder); }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function depositRewards(uint256 amountETH) internal {
        uint256 balanceBefore = IERC20(reward).balanceOf(address(this));
        swapETHForTokens(amountETH, reward, address(this));
        uint256 amount = IERC20(reward).balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        currentDividends = currentDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function processAuto(uint256 gas) internal {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0) { return; }
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){currentIndex = 0;}
            address current = shareholders[currentIndex];
            if(shouldDistribute(current)){
                distributeDividend(current, current);}
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function transferERC20(address _address, uint256 _amount) external {
        IERC20(_address).transfer(development_receiver, _amount);
    }

    function transferBalance(uint256 _amount) external {
        payable(development_receiver).transfer(_amount);
    }

    function setExcess() external {
        IERC20(reward).transfer(development_receiver, excessDividends);
        currentDividends = currentDividends.sub(excessDividends);
        excessDividends = uint256(0);
    }

    function setTokenAddress(address _address) external onlyOwner {
        token_receiver = _address;
    }

    function setRewardAddress(address _address) external onlyOwner {
        reward = _address;
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function totalRewardsDistributed(address _wallet) external view returns (uint256) {
        address shareholder = _wallet;
        return uint256(shares[shareholder].totalRealised);
    }

    function _claimDividend() external {
        if(shouldDistribute(msg.sender)){distributeDividend(msg.sender, msg.sender);}
    }

    function distributeDividend(address shareholder, address recipient) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            IERC20(reward).transfer(recipient, amount);
            currentDividends = currentDividends.sub(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);}
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _distributorGas) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        distributorGas = _distributorGas;
        emit SetDistributionCriteria(_minPeriod, _minDistribution, _distributorGas, block.timestamp);
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