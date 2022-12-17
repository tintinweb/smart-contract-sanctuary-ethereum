/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

//[email protected]_DEV creates new and innovative contracts. 
 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

contract SantaMarvin is ERC20, Ownable {
    using SafeMath for uint256;
    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Santa Marvin";
    string constant _symbol = "STM";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100_000_000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = _totalSupply / 99;//1%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 buyLiquidityFee = 100;//1%
    uint256 buyMarketingFee = 200;//1%

    uint256 sellLiquidityFee = 100;//1%
    uint256 sellMarketingFee = 1400;//14%

    uint256 buyTotalFee = buyLiquidityFee + buyMarketingFee;    
    uint256 sellTotalFee = sellLiquidityFee + sellMarketingFee;

    uint256 feeDenominator = 100;

    address public marketingFeeReceiver = 0x0E96423B0Ad3941467beC97F75F87a2BC800B755;
    address liquidityFeeReceiver = 0x0E96423B0Ad3941467beC97F75F87a2BC800B755;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 4; // 0.4%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[0x0E96423B0Ad3941467beC97F75F87a2BC800B755] = true;
        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[0x0E96423B0Ad3941467beC97F75F87a2BC800B755] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[address(this)] = true;

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

    function setSwapThreshold(uint256 amount) external onlyOwner{
        require(amount >= (_totalSupply / 10000) * 3);//0.03% min
        swapThreshold = amount;
    }

    function setSwapEnabled(bool value) external onlyOwner{
        swapEnabled = value;
    }

    function setFeeReceivers(address marketingAddress, address liquidityAddress) external onlyOwner{
        marketingFeeReceiver = marketingAddress;
        liquidityFeeReceiver = liquidityAddress;
    }

    function setFeeExempt(address target, bool value) external onlyOwner{
        isFeeExempt[target] = value;
    }

    function setTXExempt(address target, bool value) external onlyOwner{
        isTxLimitExempt[target] = value;
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
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack()){ swapBack(sender == pair ? buyLiquidityFee : sellLiquidityFee, sender == pair ? buyTotalFee : sellTotalFee); } 

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount, sender == pair ? buyTotalFee : sellTotalFee) : amount;
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

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount, uint256 trFee) internal returns (uint256) {
        uint256 feeAmount = amount * trFee > feeDenominator * 100 ? amount.mul(trFee).div(feeDenominator * 100) : 0;
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

    function swapBack(uint256 liquidityFee, uint256 totalFee) internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance * liquidityFee > totalFee ? contractTokenBalance.mul(liquidityFee).div(totalFee) : 0;
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);
        uint256 half = amountToLiquify > 2 ? amountToLiquify / 2 : 0;
        amountToLiquify = amountToLiquify.sub(half);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        if(half > 0){
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                half,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        
        uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

        if(amountToLiquify > 0 && amountETHLiquidity > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }

        balanceBefore = address(this).balance;
        
        if(amountToSwap > 0){
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
        
        uint256 amountETHMarketing = address(this).balance.sub(balanceBefore);

        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function clearStuckBalance(address receiver) external onlyOwner {
        payable(receiver).transfer(address(this).balance);
    }

    function rescueTokens(address tokenAddress, uint256 tokenAmountPercentage, address receiver) external onlyOwner {
        require(tokenAmountPercentage > 0 && tokenAmountPercentage <= 100, "Invalid percentage number.");
        require(tokenAddress != address(this));//This function can't be used to rescue this address tokens (Ex.:Fee tokens)
        ERC20(tokenAddress).transfer(receiver, (ERC20(tokenAddress).balanceOf(address(this)) * tokenAmountPercentage)/100);
    }

    function setWalletLimit(uint256 mwAmount) external onlyOwner {
        require(mwAmount >= _totalSupply / 1000);//0.1% Max wallet min value
        _maxWalletAmount = mwAmount;
    }

    function setFee(uint256 _buyLiquidityFee, uint256 _buyMarketingFee, uint256 _sellLiquidityFee, uint256 _sellMarketingFee) external onlyOwner {
        buyLiquidityFee = _buyLiquidityFee; 
        buyMarketingFee = _buyMarketingFee;

        sellLiquidityFee = _sellLiquidityFee;
        sellMarketingFee = _sellMarketingFee;

        buyTotalFee = _buyLiquidityFee + _buyMarketingFee;
        sellTotalFee = _sellLiquidityFee + _sellMarketingFee;

        require(buyTotalFee <= 30 * feeDenominator);//30% Fee max.
        require(sellTotalFee <= 30 * feeDenominator);//30% Fee max.
    }    
    
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}