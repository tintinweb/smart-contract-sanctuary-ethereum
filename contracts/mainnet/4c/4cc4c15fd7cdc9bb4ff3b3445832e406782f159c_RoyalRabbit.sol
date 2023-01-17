/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

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

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Div by zero");
        return a % b;
    }
}


interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    address internal potentialOwner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        require(adr != owner, "Cant unauthorize current owner");
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr, uint256 confirm) public onlyOwner {
        require(confirm == 911911911,"Accidental Press");
        require(adr != owner, "Already the owner");
        require(adr != address(0), "Can not be zero address.");
        potentialOwner = adr;
        emit OwnershipNominated(adr);
    }

    function acceptOwnership() public {
        require(msg.sender == potentialOwner, "You must be nominated as potential owner before you can accept the role.");
        authorizations[owner] = false;
        authorizations[potentialOwner] = true;
        owner = potentialOwner;
        potentialOwner = address(0);
        emit OwnershipTransferred(owner);
    }

    event OwnershipTransferred(address owner);
    event OwnershipNominated(address potentialOwner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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
        uint deadline
    ) external;
}


interface InterfaceLP {
    function sync() external;
}

contract RoyalRabbit  is IERC20, Auth {
    using SafeMath for uint256;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "RoyalRabbit";
    string constant _symbol = "ROYALR";
    uint8 constant _decimals = 9;

    // Rebase data
    bool public autoRebase = false;
    uint256 public rewardYield = 4208333;
    uint256 public rewardYieldDenominator = 10000000000;
    uint256 public rebaseFrequency = 1800;
    uint256 public nextRebase;

    // Rebase constants
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 10**8 * 10**_decimals;
    uint256 private constant MAX_SUPPLY = type(uint128).max;
    uint256 private TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 _totalSupply =  INITIAL_FRAGMENTS_SUPPLY;

    uint256 private _rate = TOTAL_GONS.div(_totalSupply);

    uint256 public _maxTxAmount = TOTAL_GONS / 100;
    uint256 public _maxWalletToken = TOTAL_GONS / 50;

    mapping (address => uint256) _rBalance;
    mapping (address => mapping (address => uint256)) _allowances;

    bool public blacklistMode = true;
    mapping (address => bool) public isBlacklisted;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isWalletLimitExempt;

    uint256 public LIQFee = 4;
    uint256 public RLRee = 1;
    uint256 public PRDFee = 1; 
    uint256 public infernoFee = 0;
    uint256 public totalFee = RLRee + LIQFee + PRDFee + infernoFee;
    uint256 public constant feeDenominator = 100;

    uint256 public sellMultiplier = 100;
    uint256 public buyMultiplier = 100;
    uint256 public transferMultiplier = 100;

    address public LIQReceiver;
    address public RLReeReceiver;
    address public PRDFeeReceiver;
    address public infernoFeeReceiver;

    IDEXRouter public router;
    address public pair;
    InterfaceLP pcspair_interface;
    address[] public _markerPairs;

    bool public tradingOpen = false;
    bool public burnDAO = true;

    bool public antibot = false;

    bool public launchMode = true;

    bool public swapEnabled = false;
    bool public swapAll = false;
    uint256 private gonSwapThreshold = TOTAL_GONS / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {

        if (block.chainid == 56) {
            router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 1 || block.chainid == 4) {
            router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else if (block.chainid == 25) {
            router = IDEXRouter(0x145677FC4d9b8F19B5D56d1820c48e0443049a30);
        } else {
            revert();
        }

        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(), 
            address(this)
            );

        pcspair_interface = InterfaceLP(pair);

        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][pair] = type(uint256).max;
        _allowances[address(this)][address(this)] = type(uint256).max;

        LIQReceiver = address(this);
        RLReeReceiver = 0x4a0165d8E9172a9Fe0154B743d7ed9302B60c06f;
        PRDFeeReceiver = 0x4a0165d8E9172a9Fe0154B743d7ed9302B60c06f;
        infernoFeeReceiver = DEAD; 

        isFeeExempt[msg.sender] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[DEAD] = true;
        isWalletLimitExempt[infernoFeeReceiver] = true;

        nextRebase = block.timestamp + 200000;

        _rBalance[msg.sender] = TOTAL_GONS;


        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _rBalance[account].div(_rate);
    }

    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }


    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        uint256 rAmount = amount.mul(_rate);

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
            if(antibot && sender == pair && recipient != pair){
                isBlacklisted[recipient] = true;
            }
        }

        if(blacklistMode){
            require(!isBlacklisted[sender],"Blacklisted");    
        }

        if (!authorizations[sender] && !isWalletLimitExempt[sender] && !isWalletLimitExempt[recipient] && recipient != pair) {
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= (_maxWalletToken.div(_rate)),"max wallet limit reached");
        }


        require(amount <= (_maxTxAmount.div(_rate)) || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");


        if(shouldRebase() && autoRebase && recipient == pair) {
            _rebase();
            pcspair_interface.sync();

            if(sender != pair && recipient != pair){
                manualSync();
            }
        }

        if(shouldSwapBack()) {
            swapBack();
        }

        //Exchange tokens
        _rBalance[sender] = _rBalance[sender].sub(rAmount, "Insufficient Balance");

        uint256 amountReceived = ( isFeeExempt[sender] || isFeeExempt[recipient] ) ? rAmount : takeFee(sender, rAmount, recipient);
        _rBalance[recipient] = _rBalance[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived.div(_rate));

        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 rAmount = amount.mul(_rate);
        _rBalance[sender] = _rBalance[sender].sub(rAmount, "Insufficient Balance");
        _rBalance[recipient] = _rBalance[recipient].add(rAmount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        if(totalFee == 0) { return amount; }

        uint256 multiplier = transferMultiplier;
        if(recipient == pair){
            multiplier = sellMultiplier;
        } else if(sender == pair){
            multiplier = buyMultiplier;
        }

        uint256 feeAmount = amount.div(feeDenominator * 100).mul(totalFee).mul(multiplier);
        uint256 infernoTokens = feeAmount.mul(infernoFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(infernoTokens);

        if(contractTokens > 0){
            _rBalance[address(this)] = _rBalance[address(this)].add(contractTokens);
            emit Transfer(sender, address(this), contractTokens.div(_rate));    
        }

        if(infernoTokens > 0){
            _rBalance[infernoFeeReceiver] = _rBalance[infernoFeeReceiver].add(infernoTokens);
            emit Transfer(sender, infernoFeeReceiver, infernoTokens.div(_rate));    
        }

        return amount.sub(feeAmount);
    }

    function trueburn(uint256 _percent) external {
        
        require(burnDAO || isAuthorized(msg.sender),"TrueBurn DAO Turned off");

        address wallet = 0x000000000000000000000000000000000000dEaD;
        uint256 rTokenstoburn = _rBalance[wallet].div(100).mul(_percent);

        _rBalance[wallet] = _rBalance[wallet] - rTokenstoburn;
        _totalSupply = _totalSupply - (rTokenstoburn.div(_rate));
        TOTAL_GONS = TOTAL_GONS - rTokenstoburn;

        emit Transfer(wallet,address(this),(rTokenstoburn.div(_rate)));
    }


    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _rBalance[address(this)] >= gonSwapThreshold;
    }

    function swapBack() internal swapping {
        
        if(totalFee == 0) { return ; }

        uint256 tokensToSwap = _rBalance[address(this)].div(_rate);
        if(!swapAll) {
            tokensToSwap = gonSwapThreshold.div(_rate);
        }

        uint256 amountToLiquify = tokensToSwap.mul(LIQFee).div(totalFee).div(2);
        uint256 amountToSwap = tokensToSwap.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(LIQFee.div(2));
        
        uint256 amountBNBLIQ = amountBNB.mul(LIQFee).div(totalBNBFee).div(2);
        uint256 amountBNBRLR = amountBNB.mul(RLRee).div(totalBNBFee);
        uint256 amountBNBPRD = amountBNB.mul(PRDFee).div(totalBNBFee);

        payable(RLReeReceiver).transfer(amountBNBRLR);
        payable(PRDFeeReceiver).transfer(amountBNBPRD);
        
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLIQ}(
                address(this),
                amountToLiquify,
                0,
                0,
                LIQReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLIQ, amountToLiquify);
        }
    }

    // Public function starts
    function setMaxWalletPercent_base10000(uint256 maxWallPercent_base10000) external onlyOwner {
        require(maxWallPercent_base10000 >= 10,"Cannot set max wallet less than 0.1%");
        _maxWalletToken = TOTAL_GONS.div(10000).mul(maxWallPercent_base10000);
    }
    function setMaxTxPercent_base10000(uint256 maxTXPercentage_base10000) external onlyOwner {
        require(maxTXPercentage_base10000 >= 10,"Cannot set max transaction less than 0.1%");
        _maxTxAmount = TOTAL_GONS.div(10000).mul(maxTXPercentage_base10000);
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        if(tokens == 0){
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external authorized {
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;

        require(totalFee.mul(buyMultiplier).div(100) <= 10, "Buy fees cannot be more than 10%");
        require(totalFee.mul(sellMultiplier).div(100) <= 10, "Sell fees cannot be more than 10%");
    }

    function tradingStatus(bool _status, bool _b) external onlyOwner {
        if(!_status){
            require(launchMode,"Cannot stop trading after launch is done");
        }
        tradingOpen = _status;
        antibot = _b;
    }

    function trueburn_DAO(bool _status) external onlyOwner{
        burnDAO = _status;
    }

    function tradingStatus_launchmode(uint256 _pass) external onlyOwner {
        require(_pass == 123111123, "Accidental press, please enter pass");
        require(tradingOpen,"Cant close launch mode when trading is disabled");
        require(!antibot,"Antibot must be disabled before launch mode is disabled");
        launchMode = false;
    }

    function manage_blacklist_status(bool _status) external onlyOwner {
        if(_status){
            require(launchMode,"Cannot turn on blacklistMode after launch is done");
        }
        blacklistMode = _status;
    }

    function manage_blacklist(address[] calldata addresses, bool status) external onlyOwner {
        if(status){
            require(launchMode,"Cannot manually blacklist after launch");
        }

        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isBlacklisted[addresses[i]] = status;
        }
    }

    function manage_FeeExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isFeeExempt[addresses[i]] = status;
        }
    }

    function manage_TxLimitExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isTxLimitExempt[addresses[i]] = status;
        }
    }

    function manage_WalletLimitExempt(address[] calldata addresses, bool status) external authorized {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isWalletLimitExempt[addresses[i]] = status;
        }
    }

    function setFees(uint256 _LIQFee,  uint256 _RLRee, uint256 _PRDFee, uint256 _infernoFee) external onlyOwner {
        LIQFee = _LIQFee;
        RLRee = _RLRee;
        PRDFee = _PRDFee;
        infernoFee = _infernoFee;
        totalFee = _LIQFee.add(_RLRee).add(_PRDFee).add(_infernoFee);

        require(totalFee.mul(buyMultiplier).div(100) <= 10, "Buy fees cannot be more than 10%");
        require(totalFee.mul(sellMultiplier).div(100) <= 10, "Sell fees cannot be more than 10%");
    }

    function setFeeReceivers(address _RLReeReceiver, address _PRDFeeReceiver) external onlyOwner {
        require(_RLReeReceiver != address(0), "Cannot set zero address as fee receiver");
        require(_PRDFeeReceiver != address(0), "Cannot set zero address as fee receiver");
        RLReeReceiver = _RLReeReceiver;
        PRDFeeReceiver = _PRDFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, bool _swapAll) external authorized {
        swapEnabled = _enabled;
        gonSwapThreshold = _amount.mul(_rate);
        swapAll = _swapAll;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return (TOTAL_GONS.sub(_rBalance[DEAD]).sub(_rBalance[ZERO])).div(_rate);
    }

    function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {
        require(launchMode,"Cannot execute this after launch is done");

        require(addresses.length < 501,"GAS Error: max airdrop limit is 500 addresses");
        require(addresses.length == tokens.length,"Mismatch between Address and token count");

        uint256 SCCC = 0;

        for(uint i=0; i < addresses.length; i++){
            SCCC = SCCC + tokens[i];
        }

        require(balanceOf(from) >= SCCC, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens[i]);
        }
    }


    // Rebase related function
    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_rate);
    }

    function shouldRebase() internal view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function manualSync() public {
        for(uint i = 0; i < _markerPairs.length; i++){
            InterfaceLP(_markerPairs[i]).sync();
        }
    }


    function MarkerPair_add(address adr) external onlyOwner{
        _markerPairs.push(adr);
    }

    function MarkerPair_clear(uint256 pairstoremove) external onlyOwner{
        for(uint i = 0; i < pairstoremove; i++){
            _markerPairs.pop();
        }
    }

    // Rebase core
    function _rebase() private {
        if(!inSwap) {

            uint256 times = (rebaseFrequency + block.timestamp - nextRebase)/rebaseFrequency;
            uint256 newSupply = getCirculatingSupply();
            uint256 supplyDelta = 0;

            for (uint256 i = 0; i < times; i++) {
                supplyDelta = newSupply.mul(rewardYield).div(rewardYieldDenominator);
                newSupply = newSupply + supplyDelta;
            }

            coreRebase(newSupply - getCirculatingSupply());
        }
    }

    function coreRebase(uint256 supplyDelta) private returns (bool) {
        uint256 epoch = block.timestamp;

        // Dont rebase if at max supply
        if (supplyDelta == 0 || (_totalSupply+supplyDelta) > MAX_SUPPLY) {
            emit LogRebase(epoch, _totalSupply);
            return false;
        }

        _totalSupply = _totalSupply.add(supplyDelta);
        _rate = TOTAL_GONS.div(_totalSupply);

        nextRebase = epoch + rebaseFrequency;

        emit LogRebase(epoch, _totalSupply);
        return true;
    }


    function manualRebase() external onlyOwner{
        require(!inSwap, "Try again");
        require(nextRebase <= block.timestamp, "Not in time");

        uint256 circulatingSupply = getCirculatingSupply();
        uint256 supplyDelta = circulatingSupply.mul(rewardYield).div(rewardYieldDenominator);

        coreRebase(supplyDelta);
        manualSync();
    }

    function manualRebase_customrate(uint256 _yield, uint256 _denominator) external onlyOwner{
        require(launchMode,"Cannot execute this after launch");
        uint256 circulatingSupply = getCirculatingSupply();
        uint256 supplyDelta = circulatingSupply.mul(_yield).div(_denominator);

        coreRebase(supplyDelta);
        manualSync();
    }

    function rebase_AutoRebase(bool _status, uint256 _nextRebaseInterval) external onlyOwner {
        require(autoRebase != _status, "Not changed");
        if(_nextRebaseInterval > 0){
            nextRebase = block.timestamp + _nextRebaseInterval;
        }
        autoRebase = _status;
    }

    function rebase_setFrequency(uint256 _rebaseFrequency) external onlyOwner {
        require(_rebaseFrequency <= 18000, "Max 5hr period for rebase");
        require(_rebaseFrequency >= 300, "Min 5min period for rebase");
        rebaseFrequency = _rebaseFrequency;
    }

    function rebase_setYield(uint256 _rewardYield, uint256 _rewardYieldDenominator) external onlyOwner {
        require(rewardYield > 0, "Cannot disable APY");
        require(rewardYieldDenominator > 10000, "Accuracy too low");
        rewardYield = _rewardYield;
        rewardYieldDenominator = _rewardYieldDenominator;
    }

    function rebase_setNextRebase(uint256 _nextRebase) external onlyOwner {
        nextRebase = _nextRebase;
    }

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);

}