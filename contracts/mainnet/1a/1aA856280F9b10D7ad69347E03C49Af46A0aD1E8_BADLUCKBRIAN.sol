/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

//https://twitter.com/ethbadluckbrian
//https://t.me/erc20badluckbrian

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.4;

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
        if (a == 0) { return 0; }
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

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract BADLUCKBRIAN is IBEP20, Auth {
    
    using SafeMath for uint256;

    string constant _name = "Bad Luck Brian";
    string constant _symbol = "$Brian";
    uint8 constant _decimals = 18;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; //UniSwap V2 router

    uint256 _totalSupply = 100000000 * (10 ** _decimals);

    bool public tradingIsEnabled = false; 

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;

    uint256 public developmentFee    = 100; 
    uint256 public liquidityFee  = 0;
    uint256 public totalFees     =  developmentFee + liquidityFee;
    uint256 public feeDenominator = 1000;

    address public devWallet = msg.sender;

    IDEXRouter public router;
    address public pair;
	
	uint256 public launchedAt;

    // max wallet tools
    mapping(address => bool) private _isExcludedFromMaxWallet;
    bool private enableMaxWallet = true;
    uint256 private maxWalletRate = 25;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    uint256 public swapThreshold = _totalSupply / 1000;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () Auth(msg.sender) {
        
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        // exclude from max wallet limit
        _isExcludedFromMaxWallet[msg.sender] = true;
        _isExcludedFromMaxWallet[address(0)] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[DEAD] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function name() external pure override returns (string memory) { return _name; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function getOwner() external view override returns (address) { return owner; }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function enableTrading() external onlyOwner {
        require(!tradingIsEnabled, "Trading is already enabled");
        tradingIsEnabled = true;
    }
    
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setFeeRates(uint256 _liquidityFee, uint256 _developmentFee, uint256 _feeDenominator) public onlyOwner {
            liquidityFee = _liquidityFee;
            developmentFee = _developmentFee;
            totalFees = _liquidityFee + _developmentFee;
            feeDenominator = _feeDenominator;
            require(totalFees <= _feeDenominator / 4, "max 25%");
    }

    function setDevWallet(address payable wallet) external onlyOwner{
        devWallet = wallet;
    }

    function isExcludedFromMaxWallet(address account) public view returns(bool) {
        return _isExcludedFromMaxWallet[account];
    }

    function maxWalletAmount() public view returns (uint256) {
        return getCirculatingSupply().mul(maxWalletRate).div(1000);
    }

    function setmaxWalletAmountRateDenominator1000(uint256 _val) public onlyOwner {
        require(_val > 9, "Max wallet percentage cannot be lower than 1%");
        maxWalletRate = _val;
    }

    function setExcludeFromMaxWallet(address account, bool exclude) public onlyOwner {
          _isExcludedFromMaxWallet[account] = exclude;
    }

    function setenableMaxWallet(bool _val) public onlyOwner {
        enableMaxWallet = _val;
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit) external onlyOwner {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(tradingIsEnabled || (isFeeExempt[sender] || isFeeExempt[recipient]), "Trading is disabled");
        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }

        if (enableMaxWallet && maxWalletAmount() > 0) {
            if (
                _isExcludedFromMaxWallet[sender] == false
                && _isExcludedFromMaxWallet[recipient] == false &&
                recipient != pair
            ) {
                uint balance  = balanceOf(recipient);
                require(balance + amount <= maxWalletAmount(), "MaxWallet: Transfer amount exceeds the maxWalletAmount");
            }
        }

        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ 
			swapBack();
		}

        bool takeFee = !inSwapAndLiquify;

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        if(isFeeExempt[sender] || isFeeExempt[recipient]) {
            takeFee = false;
        }
        // no fee for wallet to wallet transfers
        if(sender != pair && recipient != pair) {
            takeFee = false;
        }
        
        uint256 finalAmount = amount;

        if(takeFee) {
            finalAmount = takeFees(sender, recipient, amount);
        }

        _balances[recipient] = _balances[recipient].add(finalAmount);

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (recipient == pair) {
            totalFees;
        }

    	uint256 feeAmount = amount.mul(totalFees).div(feeDenominator);

        if (recipient == pair) {
            totalFees;
        }

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack() internal lockTheSwap {
        
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(totalFees).div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;

        uint256 totalETHFee = totalFees.sub(liquidityFee.div(2));
        
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHTeam = amountETH.sub(amountETHLiquidity);
                
        if(developmentFee > 0){
            payable(devWallet).transfer(amountETHTeam);
        }

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);

}