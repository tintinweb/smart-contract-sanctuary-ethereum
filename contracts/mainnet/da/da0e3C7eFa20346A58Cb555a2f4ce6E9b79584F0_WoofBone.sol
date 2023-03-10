/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

/**

WoofBone - WBN

Bone Rewards / Bone LP / Shibaswap / DAO / Treasury

Website: https://woofbone.io/ 
Telegram: https://t.me/WoofBone
Rewards: https://rewards.woofbone.io/
Twitter: https://twitter.com/WoofBoneErc
TikTok: http://tiktok.com/@WoofBoneErc
Instagram: http://tiktok.com/@WoofBoneErc
Facebook: https://www.facebook.com/groups/124725287039994/

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


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

interface IBONEHub {
    function withdraw() external;
    function recalibrate() external;
    function rescue(address token, address recipient, uint256 amount) external;
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
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract WoofBone is tokenStaking, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'WoofBone';
    string private constant _symbol = 'WBN';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 420000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxSellAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 100 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isContractDividendAllowed;
    mapping (address => bool) private isBot;
    address internal router;
    IRouter _router;
    address public pair;
    bool private tradingAllowed = false;
    uint256 private liquidityFee = 100;
    uint256 private treasuryFee = 250;
    uint256 private rewardsFee = 300;
    uint256 private developmentFee = 0;
    uint256 private boneFee = 0;
    uint256 private DAOFee = 0;
    uint256 private tokenStakingFee = 0;
    uint256 private lpStakingFee = 0;
    uint256 private totalFee = 1000;
    uint256 private sellFee = 3000;
    uint256 private transferFee = 0;
    uint256 private denominator = 10000;
    bool private swapEnabled = true;
    uint256 private swapTimes;
    uint256 private swapAmount = 2;
    bool private swapping;
    bool private feeless;
    uint256 private swapThreshold = ( _totalSupply * 350 ) / 100000;
    uint256 private minTokenAmount = ( _totalSupply * 10 ) / 100000;
    modifier feelessTransaction {feeless = true; _; feeless = false;}
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    mapping(address => uint256) private lastTransferTimestamp;
    bool public transferDelayEnabled = false;
    mapping(address => uint256) public amountStaked;
    uint256 public totalStaked;
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
    uint256 public distributorGas = 10;
    address BONE = 0x9813037ee2218799597d83D4a5B6F3b6778218d9;
    IBONEHub hub; IERC20 eBONE = IERC20(BONE);
    address internal token_staking;
    address internal lp_staking;
    address internal development_receiver; 
    address internal treasury_receiver;
    address internal liquidity_receiver;
    address internal bone_receiver;
    address internal DAO_receiver;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    event Deposit(address indexed account, uint256 indexed amount, uint256 indexed timestamp);
    event Withdraw(address indexed account, uint256 indexed amount, uint256 indexed timestamp);
    event Compound(address indexed account, uint256 ethAmount, uint256 indexed timestamp);
    event SetStakingAddress(address indexed stakingAddress, uint256 indexed timestamp);
    event SetisBot(address indexed account, bool indexed isBot, uint256 indexed timestamp);
    event ExcludeFromFees(address indexed account, bool indexed isExcluded, uint256 indexed timestamp);
    event SetDividendExempt(address indexed account, bool indexed isExempt, uint256 indexed timestamp);
    event SetInternalAddresses(address indexed marketing, address indexed liquidity, address indexed treasury, uint256 timestamp);
    event SetDistributionCriteria(uint256 indexed minPeriod, uint256 indexed minDistribution, uint256 indexed distributorGas, uint256 timestamp);
    event SetParameters(uint256 indexed maxTxAmount, uint256 indexed maxWalletToken, uint256 indexed maxTransfer, uint256 timestamp);
    event SetSwapBackSettings(uint256 indexed swapAmount, uint256 indexed swapThreshold, uint256 indexed swapMinAmount, uint256 timestamp);
    event SetStructure(uint256 indexed total, uint256 indexed sell, uint256 transfer, uint256 indexed timestamp);
    event SetStaking(address indexed tokenStaking, address indexed lpStaking, uint256 tokenFee, uint256 lpFee, uint256 timestamp);
    event CreateLiquidity(uint256 indexed tokenAmount, uint256 indexed ETHAmount, address indexed wallet, uint256 timestamp);

    constructor() Ownable(msg.sender) {
        router = 0x03f7724180AA6b939894B5Ca4314783B0b36b329;
        hub = IBONEHub(0x7367d108a1b4f68A9cEf2b46c1edDcd8DC785725);
        IRouter irouter = IRouter(router);
        address _pair = IFactory(irouter.factory()).createPair(address(this), BONE);
        _router = irouter; pair = _pair;
        developmentFee = uint256(200);
        token_staking = address(this);
        lp_staking = address(this);
        isFeeExempt[address(this)] = true;
        isFeeExempt[liquidity_receiver] = true;
        isFeeExempt[treasury_receiver] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(hub)] = true;
        isDividendExempt[address(pair)] = true;
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
    function isContract(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0; }
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
        swapbackCounters(sender, recipient, amount);
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

    function compound() override external feelessTransaction {
        uint256 initialToken = balanceOf(msg.sender);
        stakingContract.stakingClaimToCompound(msg.sender, msg.sender);
        uint256 afterToken = balanceOf(msg.sender).sub(initialToken);
        internalDeposit(msg.sender, afterToken);
        emit Compound(msg.sender, afterToken, block.timestamp);
    }

    function setStakingAddress(address _staking) external onlyOwner {
        stakingContract = stakeIntegration(_staking); isFeeExempt[_staking] = true;
        emit SetStakingAddress(_staking, block.timestamp);
    }

    function setStructure(uint256 _liquidity, uint256 _development, uint256 _rewards, uint256 _bone, uint256 _treasury, uint256 _dao, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFee = _liquidity; treasuryFee = _treasury; rewardsFee = _rewards; boneFee = _bone; DAOFee = _dao;
        developmentFee = _development; totalFee = _total; sellFee = _sell; transferFee = _trans;
        require(totalFee <= denominator.div(5) && sellFee <= denominator.div(5) && transferFee <= denominator.div(5), "totalFee and sellFee cannot be more than 20%");
        emit SetStructure(_total, _sell, _trans, block.timestamp);
    }

    function setStaking(address _tokenStaking, address _lpStaking, uint256 _token, uint256 _lp) external onlyOwner {
        tokenStakingFee = _token; lpStakingFee = _lp; token_staking = _tokenStaking; lp_staking = _lpStaking; isFeeExempt[_tokenStaking] = true; isFeeExempt[_lpStaking] = true;
        require(tokenStakingFee <= denominator.div(5) && lpStakingFee <= denominator.div(5), "totalFee and sellFee cannot be more than 20%");
        emit SetStaking(_tokenStaking, _lpStaking, _token, _lp, block.timestamp);
    }

    function setisBot(address _address, bool _enabled) external onlyOwner {
        require(_address != address(pair) && _address != address(router) && _address != address(this) && _address != address(DEAD) &&
         _address != address(token_staking) && _address != address(lp_staking), "Ineligible Address");
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

    function setHub(address _hub) external onlyOwner {
        require(isContract(_hub), "ERC20: valued hub contract address required");
        hub = IBONEHub(_hub);
    }

    function checkTradingAllowed(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(tradingAllowed, "tradingAllowed");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && !feeless && recipient != address(pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function swapbackCounters(address sender, address recipient, uint256 amount) internal {
        if(recipient == pair && !isFeeExempt[sender] && !feeless && amount >= minTokenAmount){swapTimes += uint256(1);}
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

    function setInternalAddresses(address _treasury, address _liquidity, address _development, address _dao, address _bone) external onlyOwner {
        treasury_receiver = _treasury; liquidity_receiver = _liquidity; development_receiver = _development; bone_receiver = _bone; DAO_receiver = _dao;
        isFeeExempt[_treasury] = true; isFeeExempt[_liquidity] = true; isFeeExempt[_development] = true; isFeeExempt[_bone] = true; isFeeExempt[_dao] = true;
        emit SetInternalAddresses(_treasury, _liquidity, _dao, block.timestamp);
    }

    function checkTradeDelay(address sender, address recipient) internal {
        if(transferDelayEnabled && !isFeeExempt[sender] && !isFeeExempt[recipient] &&
        recipient != address(DEAD) && recipient != address(router) && !feeless){
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
        uint256 _denominator = (liquidityFee.add(developmentFee).add(treasuryFee).add(rewardsFee).add(boneFee)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFee).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = eBONE.balanceOf(address(this));
        swapTokensForBONE(toSwap);
        uint256 deltaBalance = eBONE.balanceOf(address(this)).sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFee));
        uint256 BONEToAddLiquidityWith = unitBalance.mul(liquidityFee);
        if(BONEToAddLiquidityWith > uint256(0)){addLiquidityBONE(tokensToAddLiquidityWith, BONEToAddLiquidityWith, liquidity_receiver); }
        uint256 treasuryAmount = unitBalance.mul(2).mul(treasuryFee);
        if(treasuryAmount > 0){eBONE.transfer(treasury_receiver, treasuryAmount);}
        uint256 rewardsAmount = unitBalance.mul(2).mul(rewardsFee);
        if(rewardsAmount > 0){depositRewards(rewardsAmount);}
        uint256 boneAmount = unitBalance.mul(2).mul(boneFee);
        if(boneAmount > 0){eBONE.transfer(bone_receiver, boneAmount);}
        uint256 excessAmount =  eBONE.balanceOf(address(this)).sub(currentDividends);
        if(excessAmount > uint256(0)){eBONE.transfer(development_receiver, excessAmount);}
        uint256 excessETHAmount =  address(this).balance;
        if(excessETHAmount > uint256(0)){payable(development_receiver).transfer(excessETHAmount);}
    }

    function swapTokensForBONE(uint256 tokenAmount) internal {
		_approve(address(this), address(router), tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(BONE);
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(hub),
            block.timestamp); hub.withdraw();
    }

    function addLiquidityBONE(uint256 tokenAmount, uint256 BONEAmount, address receiver) internal {
        _approve(address(this), address(router), tokenAmount);
        eBONE.approve(address(router), BONEAmount);
        _router.addLiquidity(
            address(BONE),
			address(this),
            BONEAmount,
            tokenAmount,
            0,
            0,
            address(receiver),
            block.timestamp);
    }

    function swapBONEforTokens(uint256 BONEAmount, address receiver) internal {
		_approve(address(this), address(router), BONEAmount);
        address[] memory path = new address[](2);
        path[0] = address(BONE);
        path[1] = address(this);
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            BONEAmount,
            0,
            path,
            address(receiver),
            block.timestamp);
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender] 
            && recipient == pair && swapTimes >= swapAmount && aboveThreshold && !feeless;
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = uint256(0);}
    }

    function rescueHUB(address token, address recipient, uint256 amount) external onlyOwner {
        hub.rescue(token, recipient, amount);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(isBot[sender] || isBot[recipient]){return denominator.sub(uint256(100));}
        if(recipient == pair && sellFee > uint256(0)){return sellFee.add(tokenStakingFee).add(lpStakingFee);}
        if(sender == pair && totalFee > uint256(0)){return totalFee.add(tokenStakingFee).add(lpStakingFee);}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0 && !feeless){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(tokenStakingFee > uint256(0)){_transfer(address(this), address(token_staking), amount.div(denominator).mul(tokenStakingFee));}
        if(lpStakingFee > uint256(0)){_transfer(address(this), address(lp_staking), amount.div(denominator).mul(lpStakingFee));}
        if(DAOFee > uint256(0)){_transfer(address(this), address(DAO_receiver), amount.div(denominator).mul(DAOFee));}
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

    function setisContractDividendAllowed(address holder, bool allowed) external onlyOwner {
        isContractDividendAllowed[holder] = allowed;
        if(!allowed){setShare(holder, 0);}
        else{setShare(holder, balanceOf(holder));}
    }

    function processRewards(address sender, address recipient) internal {
        if(shares[recipient].amount > 0){distributeDividend(recipient, recipient);}
        if(recipient == pair && shares[sender].amount > 0){excessDividends = excessDividends.add(getUnpaidEarnings(sender));}
        if(!isDividendExempt[sender]){setShare(sender, balanceOf(sender));}
        if(!isDividendExempt[recipient]){setShare(recipient, balanceOf(recipient));}
        if(isContract(sender) && !isContractDividendAllowed[sender]){setShare(sender, uint256(0));}
        if(isContract(recipient) && !isContractDividendAllowed[recipient]){setShare(recipient, uint256(0));}
        processAuto(distributorGas);
    }

    function setShare(address shareholder, uint256 amount) internal {
        if(amount > 0 && shares[shareholder].amount == 0){addShareholder(shareholder);}
        else if(amount == 0 && shares[shareholder].amount > 0){removeShareholder(shareholder); }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function depositRewards(uint256 amount) internal {
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
            iterations++;}
    }

    function transferERC20(address _address, uint256 _amount) external onlyOwner {
        IERC20(_address).transfer(development_receiver, _amount);
    }

    function transferBalance(uint256 _amount) external onlyOwner {
        payable(development_receiver).transfer(_amount);
    }

    function setExcess() external onlyOwner {
        IERC20(BONE).transfer(development_receiver, excessDividends);
        currentDividends = currentDividends.sub(excessDividends);
        excessDividends = uint256(0);
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
            IERC20(BONE).transfer(recipient, amount);
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

    function createLiquidity(uint256 tokenAmount, uint256 BONEAmount) public feelessTransaction {
        _approve(msg.sender, address(this), tokenAmount);
        _approve(msg.sender, address(router), tokenAmount);
        _transfer(msg.sender, address(this), tokenAmount);
        _approve(address(this), address(router), tokenAmount);
        addLiquidityBONE(tokenAmount, BONEAmount, msg.sender);
        emit CreateLiquidity(tokenAmount, BONEAmount, msg.sender, block.timestamp);
    }
}