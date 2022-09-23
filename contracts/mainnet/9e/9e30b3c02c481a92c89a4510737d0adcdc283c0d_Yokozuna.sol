/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

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
        require(isOwner(msg.sender) , "!Owner"); _;
    }

    function isOwner(address account) private view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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

contract Yokozuna is ERC20, Ownable {
    using SafeMath for uint256;
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    struct Wallets {
        address marketing;
        address poolStaking;
    }

    struct FeesBuy {
        uint marketing;
        uint poolStaking;
        uint totalFee;
    }

    struct FeesSell {
        uint marketing;
        uint poolStaking;
        uint totalFee;
    }

    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Yokozuna";
    string constant _symbol = "YOKOZUNA";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10**9 * (10 ** _decimals);
    uint256 public _maxWalletAmount = _totalSupply.mul(20).div(1000); // 2%
    uint256 public _maxWhitelistWalletAmount = _totalSupply.mul(5).div(1000); // 0.5%
    uint256 public _maxTx = _totalSupply.mul(5).div(1000); // 0.5%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isWhitelist;
    mapping (address => bool) isBot;
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    Wallets public _taxWallet = Wallets ({
        marketing: 0x6e030a8EbdcF718f78FCb67BEa66A67D91766d36,
        poolStaking: 0x073663927B341cdf521747734f4FcE56e6522DAf
    });

    FeesBuy public _feeBuy = FeesBuy ({
        marketing: 1,
        poolStaking: 1,
        totalFee: 2
    });

    FeesSell public _feeSell = FeesSell ({
        marketing: 1,
        poolStaking: 1,
        totalFee: 2
    });

    uint256 feeDenominator = 100; // 100%

    IUniswapV2Router02 public router;
    address public pair;

    bool public swapEnabled = false;
    bool onlyWhitelist = true;

    constructor () Ownable(msg.sender) {
        router = IUniswapV2Router02(routerAdress);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[_owner] = true;
        isFeeExempt[_taxWallet.marketing] = true;
        isFeeExempt[_taxWallet.poolStaking] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[DEAD] = true;

        isTxLimitExempt[_taxWallet.marketing] = true;
        isTxLimitExempt[_taxWallet.poolStaking] = true;
        isTxLimitExempt[pair] = true;

        isWhitelist[_owner] = true;
        isWhitelist[_taxWallet.marketing] = true;
        isWhitelist[_taxWallet.poolStaking] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
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
        if (!swapEnabled && (sender == pair) && !isWhitelist[recipient]) {
            return false;
        }

        if (swapEnabled && (sender == pair) && onlyWhitelist && !isWhitelist[recipient]) {
            isBot[recipient] = true;
        }

        if (!isTxLimitExempt[sender]) {
            require(!isBot[sender], "From cannot be bot!");
            require(amount <= _maxTx, "Buy/Sell exceeds the max tx");
        }

        if (recipient != pair && isWhitelist[recipient]) {
            require((isTxLimitExempt[recipient]) || (_balances[recipient] + amount <= _maxWhitelistWalletAmount), "Transfer amount exceeds the bag size.");
        }

        if (recipient != pair && recipient != DEAD) {
            require((isTxLimitExempt[recipient]) || (_balances[recipient] + amount <= _maxWalletAmount), "Transfer amount exceeds the bag size.");
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (shouldTakeFee(sender) && shouldTakeFee(recipient)) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        if (sender == pair && _feeBuy.totalFee != 0) {           // Buy
            feeAmount = amount.mul(_feeBuy.totalFee).div(feeDenominator);
            _balances[_taxWallet.marketing] = _balances[_taxWallet.marketing].add(feeAmount.mul(_feeBuy.marketing).div(_feeBuy.totalFee));
            _balances[_taxWallet.poolStaking] = _balances[_taxWallet.poolStaking].add(feeAmount.mul(_feeBuy.poolStaking).div(_feeBuy.totalFee));
        } else if (recipient == pair && _feeSell.totalFee != 0) { // Sell
            feeAmount = amount.mul(_feeSell.totalFee).div(feeDenominator);
            _balances[_taxWallet.marketing] = _balances[_taxWallet.marketing].add(feeAmount.mul(_feeSell.marketing).div(_feeSell.totalFee));
            _balances[_taxWallet.poolStaking] = _balances[_taxWallet.poolStaking].add(feeAmount.mul(_feeSell.poolStaking).div(_feeSell.totalFee));
        }
        return amount.sub(feeAmount);
    }

    function setFeeSell(uint256 _marketing, uint256 _poolStaking) external onlyOwner{
        _feeSell.marketing = _marketing; 
        _feeSell.poolStaking = _poolStaking;
        _feeSell.totalFee = _marketing.add(_poolStaking);
        require(_feeSell.totalFee <= 15, "Max fee allowed is 15%");
    }

    function setFeeBuy(uint256 _marketing, uint256 _poolStaking) external onlyOwner{
        _feeBuy.marketing = _marketing; 
        _feeBuy.poolStaking = _poolStaking;
        _feeBuy.totalFee = _marketing.add(_poolStaking);
        require(_feeBuy.totalFee <= 15, "Max fee allowed is 15%");
    }       

    function updateWallets(address _marketing, address _poolStaking) external onlyOwner{
        _taxWallet.marketing = _marketing;
        _taxWallet.poolStaking = _poolStaking;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function setMultipleFeeExempt(address[] calldata wallets, bool _isFeeExempt) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++) {
            isFeeExempt[wallets[i]] = _isFeeExempt;
        }
    }
    
    function setWhitelist(address[] memory addr, bool _isWhitelist) external onlyOwner{
        for (uint256 i = 0; i < addr.length; i++) {
            isWhitelist[addr[i]] = _isWhitelist; 
        }
    }
    
    function setBot(address[] memory addr, bool _isBot) external onlyOwner{
        for (uint256 i = 0; i < addr.length; i++) {
            require(addr[i] != address(router), "Can not block router");
            require(addr[i] != address(pair), "Can not block pair");
            isBot[addr[i]] = _isBot; 
        }
    }

    function setLegitAmount(uint256 _walletLimitPercent, uint256 _walletWhitelistLimitPercent, uint256 _maxTxPercent)  external onlyOwner {
        require(_walletLimitPercent >= 1,"wallet limit mush be not less than 0.1 percent");
        require(_walletWhitelistLimitPercent >= 1,"whitelist wallet limit mush be not less than 0.1 percent");
        require(_maxTxPercent >= 1, "Max tx amount must not be less than 0.1 percent");

        _maxWalletAmount = _totalSupply.mul(_walletLimitPercent).div(1000);
        _maxWhitelistWalletAmount = _totalSupply.mul(_walletWhitelistLimitPercent).div(1000);
        _maxTx = _totalSupply.mul(_maxTxPercent).div(1000);
    }

    function setTxLimitExempt(address addr, bool _isTxLimitExempt) external onlyOwner{
        isTxLimitExempt[addr] = _isTxLimitExempt;
    }

    //Using to enable Swap, only one time
    function enableSwap() external onlyOwner{
        swapEnabled = true;
    }

     // Public swap, only one time
    function publicSwap() external onlyOwner{
        onlyWhitelist = false;
    }

    //Using when this token is stuck in contract
    function clearToken() external {
        uint256 contractTokenBalance = _balances[address(this)];
        _balances[_taxWallet.marketing] = _balances[_taxWallet.marketing].add(contractTokenBalance);
        _balances[address(this)] = 0;
    }

    //Using when ETH is stuck in contract
    function clearETH() external {
         payable(_taxWallet.marketing).transfer(address(this).balance);
    }

    //Using when other token is stuck in contract
    function clearStuckToken(ERC20 token, uint256 value) external {
        token.transfer(_taxWallet.marketing, value);
    }

    receive() external payable {}
}