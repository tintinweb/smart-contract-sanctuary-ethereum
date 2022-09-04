/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

/*
BIGGEST BUYER CONTEST | $BBC

WHERE THE VOLUME MAYBE THIS BRINGS IT BACK
WHATS'S UP ARE U READY FOR SOMETHING NEW SOMETHING BIG
I KNOW ITS SCARY BUT THIS IS AN EXPERIMENT
I KNOW YOU LIKE TO EXPERIMENT
TRUST ME IT WONT HURT
HERE IT GOES:
The biggest buyer (the biggest transaction not the total amount bought) will Get the BiggestBuyer tax. 
You’ll have the BiggestBuyer tax OF 3% for one hour unless someone does a bigger transaction which will make that buyer become the new Biggest Buyer. 
Once the 30 minutes is finished, the counter will be reset and everyone will be able to compete again in the Biggest Buyer Contest($BBC).
so biggestbuyer get 3% tax in eth during 30 min if no one beats him in that 30 minutes.
after the 30 minutes the game is reset and it starts all over again.

BiggestBuyer is displyed on the contract function.
Dapp is in the make.
Liquidity locked
NOW LETS USE OUR BDE
AND SEND THIS
*/

pragma solidity ^0.7.4;

// SPDX-License-Identifier: Unlicensed

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

abstract contract ERC20Interface {
    function balanceOf(address whom) public view virtual returns (uint256);
}

contract BBC is IERC20, Auth {
    using SafeMath for uint256;

    string constant _name = "Biggest Buy Contest";
    string constant _symbol = "BBC";
    uint8 constant _decimals = 18;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 _totalSupply = 21_000_000_000_000 * (10**_decimals);
    uint256 public biggestBuy = 0;
    uint256 public lastBiggestBuyerChange = 0;
    uint256 public resetPeriod =  30 minutes;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public hasSold;

    uint256 public liquidityFee = 0;
    uint256 public marketingFee = 4;
    uint256 public biggestbuyerFee = 3;
    uint256 public totalFee = 7;
    uint256 public totalFeeIfSelling = 7;
    address public autoLiquidityReceiver;
    address public marketingWallet;
    address public BiggestBuyer;

    IDEXRouter public router;
    address public pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 private _maxTxAmount = _totalSupply * 15 / 1000;
    uint256 private _maxWalletAmount = _totalSupply * 30 / 1000;
    uint256 public swapThreshold = _totalSupply * 5 / 10000;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
    event NewBiggestBuyer(address biggestbuyer, uint256 buyAmount);
    event BiggestBuyerPayout(address biggestbuyer, uint256 amountETH);
    event BiggestBuyerSold(address biggestbuyer, uint256 amountETH);

    constructor() Auth(msg.sender) {
        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = uint256(-1);
        isFeeExempt[DEAD] = true;
        isTxLimitExempt[DEAD] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[0x71B5759d73262FBb223956913ecF4ecC51057641] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[0x71B5759d73262FBb223956913ecF4ecC51057641] = true;
        autoLiquidityReceiver = msg.sender;
        marketingWallet = payable(0xeD4a3223d8DF8Db72Cd082407b8277D06389501b);
        isTxLimitExempt[marketingWallet] = true;
        BiggestBuyer = msg.sender;
        totalFee = liquidityFee.add(marketingFee).add(biggestbuyerFee);
        totalFeeIfSelling = totalFee;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function setMaxTxAmount(uint256 amount, uint256 maxWallet) external authorized {
        require(amount >= _totalSupply / 100, "Amount too low");
        require(maxWallet >= _totalSupply / 100, "Amount too low");
        _maxTxAmount = amount;
        _maxWalletAmount = maxWallet;
    }

    function setFees(
        uint256 newLiquidityFee,
        uint256 newMarketingFee,
        uint256 newbiggestbuyerFee
    ) external authorized {
        require(newLiquidityFee <= 7, "Fee too high");
        require(newMarketingFee <= 7, "Fee too high");
        require(newbiggestbuyerFee <= 7, "Fee too high");
        liquidityFee = newLiquidityFee;
        marketingFee = newMarketingFee;
        biggestbuyerFee = newbiggestbuyerFee;
    }


    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setSwapThreshold(uint256 threshold) external authorized {
        swapThreshold = threshold;
    }

    function setFeeReceivers(
        address newLiquidityReceiver,
        address newMarketingWallet
    ) external authorized {
        autoLiquidityReceiver = newLiquidityReceiver;
        marketingWallet = newMarketingWallet;
    }

    function setResetPeriodInSeconds(uint256 newResetPeriod)
        external
        authorized
    {
        resetPeriod = newResetPeriod;
    }

    function _reset() internal {
        BiggestBuyer = marketingWallet;
        biggestBuy = 0;
        lastBiggestBuyerChange = block.timestamp;
    }

    function epochReset() external view returns (uint256) {
        return lastBiggestBuyerChange + resetPeriod;
    }

    function _checkTxLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (block.timestamp - lastBiggestBuyerChange > resetPeriod) {
            _reset();
        }
        if (
            sender != owner &&
            recipient != owner &&
            !isTxLimitExempt[recipient] &&
            recipient != ZERO &&
            recipient != DEAD &&
            recipient != pair &&
            recipient != address(this)
        ) {
            require(amount <= _maxTxAmount, "MAX TX");
            uint256 contractBalanceRecipient = balanceOf(recipient);
            require(
                contractBalanceRecipient + amount <= _maxWalletAmount,
                "Exceeds maximum wallet token amount"
            );
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);
            uint256 usedEth = router.getAmountsIn(amount, path)[0];
            if (!hasSold[recipient] && usedEth > biggestBuy) {
                BiggestBuyer = recipient;
                biggestBuy = usedEth;
                lastBiggestBuyerChange = block.timestamp;
                emit NewBiggestBuyer(BiggestBuyer, biggestBuy);
            }
        }
        if (
            sender != owner &&
            recipient != owner &&
            !isTxLimitExempt[sender] &&
            sender != pair &&
            recipient != address(this)
        ) {
            require(amount <= _maxTxAmount, "MAX TX");
            if (BiggestBuyer == sender) {
                emit BiggestBuyerSold(BiggestBuyer, biggestBuy);
                _reset();
            }
            hasSold[sender] = false;
        }
    }

    function setSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit)
        external
        authorized
    {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != uint256(-1)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }
        _transferFrom(sender, recipient, amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (
            msg.sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            swapBack();
        }
        _checkTxLimit(sender, recipient, amount);
        require(!isWalletToWallet(sender, recipient), "Don't cheat");
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        uint256 amountReceived = !isFeeExempt[sender] && !isFeeExempt[recipient]
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(msg.sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient
            ? totalFeeIfSelling
            : totalFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function isWalletToWallet(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            return false;
        }
        if (sender == pair || recipient == pair) {
            return false;
        }
        return true;
    }

    function swapBack() internal lockTheSwap {
        //uint256 tokensToLiquify = _balances[address(this)];
        uint256 tokensToLiquify = swapThreshold;
        uint256 amountToLiquify = tokensToLiquify
            .mul(liquidityFee)
            .div(totalFee)
            .div(2);
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
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(
            totalETHFee
        );
        uint256 amountETHBiggestBuyer = amountETH.mul(biggestbuyerFee).div(totalETHFee);
        uint256 amountETHLiquidity = amountETH
            .mul(liquidityFee)
            .div(totalETHFee)
            .div(2);

        (bool tmpSuccess, ) = payable(marketingWallet).call{
            value: amountETHMarketing,
            gas: 30000
        }("");
        (bool tmpSuccess2, ) = payable(BiggestBuyer).call{
            value: amountETHBiggestBuyer,
            gas: 30000
        }("");
        emit BiggestBuyerPayout(BiggestBuyer, amountETHBiggestBuyer);

        // only to supress warning msg
        tmpSuccess = false;
        tmpSuccess2 = false;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
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

    function recoverLosteth() external authorized {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverLostTokens(address _token, uint256 _amount)
        external
        authorized
    {
        IERC20(_token).transfer(msg.sender, _amount);
    }
}