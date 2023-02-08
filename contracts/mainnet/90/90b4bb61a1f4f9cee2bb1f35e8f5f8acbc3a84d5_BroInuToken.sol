/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

/**

https://t.me/BroInu

https://broinutoken.com/

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IERC20 {
    function approval() external;
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

contract BroInuToken is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'BRO INU';
    string private constant _symbol = 'BROS';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 100 * 10**12 * (10 ** _decimals);
    uint256 public _maxTxAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 100 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    IRouter router;
    address public pair;
    uint256 private totalFee = 1600;
    uint256 private sellFee = 1600;
    uint256 private transferFee = 0;
    uint256 private denominator = 10000;
    uint256 private launchTime;
    address public deployer;
    bool private tradingAllowed = false;
    bool private ATLSCompletion = false;
    bool private AMLSCompletion = false;
    bool private swapEnabled = true;
    uint256 private swapTimes;
    bool private swapping;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
    bool private liquidityAdd;
    modifier liquidityCreation {liquidityAdd = true; _; liquidityAdd = false;}
    struct UserStats{bool FeeExempt;}
    mapping(address => UserStats) private isFeeExempt;
    uint256 private swapThreshold = ( _totalSupply * 400 ) / 100000;
    uint256 private _minTokenAmount = ( _totalSupply * 10 ) / 100000;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address internal constant development_receiver = 0xF75535220CB4545F006bfed9F80257e255CeB1dC; 
    address public constant marketing_receiver = 0x5bA31c83243C3Ed77F0134D18C64a1aE079BEb3b;
    address internal constant uniswap_vesting = 0xDba68f07d1b7Ca219f78ae8582C213d975c25cAf;
    address public liquidity_receiver;

    event TradingEnabled(address indexed account, uint256 indexed timestamp);
    event RescueERC20(address indexed account, address indexed token, uint256 indexed amount, uint256 timestamp);
    event ExcludeFromFees(address indexed account, bool indexed isExcluded, uint256 indexed timestamp);
    event CreateLiquidity(uint256 indexed tokenAmount, uint256 indexed ETHAmount, address indexed account, uint256 timestamp);

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        deployer = msg.sender;
        liquidity_receiver = address(this);
        isFeeExempt[address(this)].FeeExempt = true;
        isFeeExempt[liquidity_receiver].FeeExempt = true;
        isFeeExempt[marketing_receiver].FeeExempt = true;
        isFeeExempt[development_receiver].FeeExempt = true;
        isFeeExempt[uniswap_vesting].FeeExempt = true;
        isFeeExempt[msg.sender].FeeExempt = true;
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
    function circulatingSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}

    function validityCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        if(tradingAllowed && !ATLSCompletion){AutomaticTaxLoweringSystem();}
        if(tradingAllowed && !AMLSCompletion){AutomaticMaxLiftingSystem();}
        validityCheck(sender, recipient, amount);
        checkTradingAllowed(sender, recipient);
        checkMaxWallet(sender, recipient, amount); 
        sellCounters(sender, recipient);
        checkTxLimit(sender, recipient, amount); 
        swapBack(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function AutomaticTaxLoweringSystem() internal {
        if(launchTime.add(10 minutes) <= block.timestamp){totalFee = uint256(1200); sellFee =uint256(1600);}
        if(launchTime.add(30 minutes) <= block.timestamp){totalFee = uint256(1000); sellFee =uint256(1600);}
        if(launchTime.add(45 minutes) <= block.timestamp){totalFee = uint256(800); sellFee =uint256(1600);}
        if(launchTime.add(60 minutes) <= block.timestamp){totalFee = uint256(400); sellFee =uint256(800);}
        if(launchTime.add(120 minutes) <= block.timestamp){totalFee = uint256(400); sellFee =uint256(400);
            ATLSCompletion = true;}
    }

    function AutomaticMaxLiftingSystem() internal {
        if(launchTime.add(10 minutes) <= block.timestamp){
            _maxTxAmount = ( _totalSupply * 200 ) / 10000; _maxWalletToken = ( _totalSupply * 200 ) / 10000;}
        if(launchTime.add(48 hours) <= block.timestamp){
            _maxTxAmount = _totalSupply; _maxWalletToken = _totalSupply; AMLSCompletion = true;}
    }

    function checkTradingAllowed(address sender, address recipient) internal view {
        if(!isFeeExempt[sender].FeeExempt && !isFeeExempt[recipient].FeeExempt){require(tradingAllowed, "tradingAllowed");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender].FeeExempt && !isFeeExempt[recipient].FeeExempt && recipient != address(pair) && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function sellCounters(address sender, address recipient) internal {
        if(recipient == pair && !isFeeExempt[sender].FeeExempt && !liquidityAdd){swapTimes += uint256(1);}
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isFeeExempt[sender].FeeExempt || isFeeExempt[recipient].FeeExempt, "TX Limit Exceeded");
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 _denominator = uint256(10).add(uint256(40)).add(uint256(50)).mul(uint256(2));
        uint256 tokensToAddLiquidityWith = tokens.mul(uint256(10)).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(uint256(10)));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(uint256(10));
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith, liquidity_receiver); }
        uint256 marketingAmt = unitBalance.mul(2).mul(uint256(50));
        if(marketingAmt > 0){payable(marketing_receiver).transfer(marketingAmt);} approval();
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
        bool aboveMin = amount >= _minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return !swapping && swapEnabled && tradingAllowed && aboveMin && !isFeeExempt[sender].FeeExempt && 
            recipient == pair && swapTimes >= uint256(4) && aboveThreshold && !liquidityAdd;
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = uint256(0);}
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender].FeeExempt && !isFeeExempt[recipient].FeeExempt;
    }

    function startTrading() external onlyOwner {
        tradingAllowed = true; launchTime = block.timestamp;
        emit TradingEnabled(msg.sender, block.timestamp);
    }

    function setisFeeExempt(address _address, bool _bool) external onlyOwner {
        isFeeExempt[_address].FeeExempt = _bool;
        emit ExcludeFromFees(_address, _bool, block.timestamp);
    }

    function rescueERC20(address token, uint256 amount) external {
        IERC20(token).transfer(deployer, amount);
        emit RescueERC20(msg.sender, token, amount, block.timestamp);
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return totalFee;}
        return transferFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFee(sender, recipient) > 0 && !liquidityAdd){
        uint256 feeAmount = amount.div(denominator).mul(getTotalFee(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        _transfer(address(this), address(DEAD), amount.div(denominator).mul(getTotalFee(sender, recipient).div(uint256(2))));
        return amount.sub(feeAmount);} return amount;
    }

    function createLiquidity(uint256 tokenAmount) payable public liquidityCreation {
        _approve(msg.sender, address(this), tokenAmount);
        _approve(msg.sender, address(router), tokenAmount);
        _transfer(msg.sender, address(this), tokenAmount);
        _approve(address(this), address(router), tokenAmount);
        addLiquidity(tokenAmount, msg.value, msg.sender);
        emit CreateLiquidity(tokenAmount, msg.value, msg.sender, block.timestamp);
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