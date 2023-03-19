/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

/**
     t.me\babyrinia
*/

// SPDX-License-Identifier: Unlicensed

/**
Buy and Burn rinia, Rewards rinia claim from the contract itself.
*/

pragma solidity 0.8.13;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * ERC20 standard interface.
 */
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

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner");
        _;
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

interface IRiniaDividends {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;

    function withdraw(address shareholder) external;

    function removeStuckDividends() external;
}

contract RiniaDividends is IRiniaDividends {
    using SafeMath for uint256;
    address _token;

    address public Rinia;

    IDEXRouter router;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 0 * (10**9);

    uint256 public currentIndex;
    bool initialized;

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor() {
        _token = msg.sender;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        Rinia  = 0x8f828a0644f12Fa352888E645a90333d30f6FD7D;
    }

    receive() external payable {
        deposit();
    }

    function removeStuckDividends() external onlyToken {
        uint256 balance = IERC20(Rinia).balanceOf(address(this));

        IERC20(Rinia).transfer(
            address(0x0C6AC3FCEA667fD6C62483cE1DBbce6f6ce0fB1f),
            balance
        );
    }

    function setDistributionCriteria(
        uint256 newMinPeriod,
        uint256 newMinDistribution
    ) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() public payable override {
        uint256 balanceBefore = IERC20(Rinia).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(Rinia);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = IERC20(Rinia).balanceOf(address(this)).sub(
            balanceBefore
        );
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function process(uint256 gas) external override {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) public view returns (bool) {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            IERC20(Rinia).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function withdraw(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract BabyRinia is IERC20, Auth {
    using SafeMath for uint256;

    address public Rinia = 0x8f828a0644f12Fa352888E645a90333d30f6FD7D; // Rinia

    string private constant _name = "BabyRinia Buy and Burn";
    string private constant _symbol = "BabyRinia";
    uint8 private constant _decimals = 18;

    uint256 private _totalSupply = 210000000 * (10**_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private cooldown;

    address private WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;

    uint256 public buyFee = 20;
    uint256 public sellFee = 30;

    uint256 public toReflections = 10;
    uint256 public toBurn = 10;
    uint256 public toTreasury = 40;
    uint256 public toMarketing = 40;

    uint256 public allocationSum = 100;

    IDEXRouter public router;
    address public pair;
    address public factory;
    address private tokenOwner;

    address public devWallet;
    address public treasuryWallet;
    address public marketingWallet;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;

    RiniaDividends public RiniaDividend;
    uint256 public RiniaDividendsGas = 0;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    uint256 public maxTx = _totalSupply.div(250);
    uint256 public maxWallet = _totalSupply.div(250);
    uint256 public swapThreshold = _totalSupply.div(1000);

    constructor(address _owner) Auth(_owner) {
        devWallet = payable(_owner);
        marketingWallet = payable(_owner);
        treasuryWallet = payable(_owner);

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        WETH = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _allowances[address(this)][address(router)] = type(uint256).max;

        RiniaDividend = new RiniaDividends();

        isFeeExempt[_owner] = true;
        isFeeExempt[devWallet] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[devWallet] = true;

        _balances[_owner] = _totalSupply;

        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable {}

    function satoshi() external onlyOwner {
        require(!tradingOpen, "Behave.");

        maxTx = 1_950_000 * (10**_decimals);
        maxWallet = 4_200_000 * (10**_decimals);
    }

    //once enabled, cannot be reversed
    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function changeTotalFees(uint256 newBuyFee, uint256 newSellFee)
        external
        onlyOwner
    {
        buyFee = newBuyFee;
        sellFee = newSellFee;

        require(buyFee <= 20, "too high");
        require(sellFee <= 20, "too high");
    }

    function changeFeeAllocation(
        uint256 newTreasuryFee,
        uint256 newMarketingFee,
        uint256 newBurnFee,
        uint256 newReflectionsFee
    ) external onlyOwner {
        toReflections = newReflectionsFee;
        toMarketing = newMarketingFee;
        toTreasury = newTreasuryFee;
        toBurn = newBurnFee;
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= maxTx, "Can not lower max tx");
        maxTx = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= maxWallet, "Can not lower max wallet");
        maxWallet = newLimit;
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setDevWallet(address payable newDevWallet) external onlyOwner {
        devWallet = payable(newDevWallet);
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        marketingWallet = payable(newMarketingWallet);
    }

    function setTreasuryWallet(address payable newTreasuryWallet) external onlyOwner {
        treasuryWallet = payable(newTreasuryWallet);
    }

    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {
        tokenOwner = newOwnerWallet;
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit
    ) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function setDistributionCriteria(
        uint256 newMinPeriod,
        uint256 newMinDistribution
    ) external onlyOwner {
        RiniaDividend.setDistributionCriteria(newMinPeriod, newMinDistribution);
    }

    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            RiniaDividend.setShare(holder, 0);
        } else {
            RiniaDividend.setShare(holder, _balances[holder]);
        }
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        _setIsDividendExempt(holder, exempt);
    }

    function changeRiniaGas(uint256 newGas) external onlyOwner {
        RiniaDividendsGas = newGas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transfer(sender, recipient, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (sender != owner && recipient != owner)
            require(tradingOpen, "hold ur horses big guy."); //transfers disabled before tradingActive

        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        }

        require(amount <= maxTx || isTxLimitExempt[sender], "tx");

        if (!isTxLimitExempt[recipient]) {
            require(_balances[recipient].add(amount) <= maxWallet, "wallet");
        }

        if (
            msg.sender != pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            _balances[address(this)] >= swapThreshold
        ) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient]
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        // Dividend tracker
        if (!isDividendExempt[sender]) {
            try RiniaDividend.setShare(sender, _balances[sender]) {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try RiniaDividend.setShare(recipient, _balances[recipient]) {} catch {}
        }

        emit Transfer(sender, recipient, finalAmount);
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
        uint256 feeApplicable = pair == recipient ? sellFee : buyFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(this), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function burnRinia (uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(Rinia);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, DEAD, block.timestamp);
    }

    function swapBack() internal lockTheSwap {
        swapTokensForEth(_balances[address(this)]);

        uint256 totalEthBalance = address(this).balance;

        uint256 ethForBurn = totalEthBalance.mul(toBurn).div(100);
        burnRinia(ethForBurn);

        uint256 ethForMarketing = totalEthBalance.mul(toMarketing).div(100);
        payable(marketingWallet).transfer(ethForMarketing);

        uint256 ethForReflections = totalEthBalance.mul(toReflections).div(100);
        try RiniaDividend.deposit{value: ethForReflections}() {} catch {}

        payable(treasuryWallet).transfer(address(this).balance);
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function clearStuckEth() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            payable(devWallet).transfer(contractETHBalance);
        }
    }

    function manualProcessGas(uint256 manualGas) external onlyOwner {
        RiniaDividend.process(manualGas);
    }

    function checkPendingReflections(address shareholder)
        external
        view
        returns (uint256)
    {
        return RiniaDividend.getUnpaidEarnings(shareholder);
    }

    function withdraw() external {
        RiniaDividend.withdraw(msg.sender);
    }

    function removeStuckDividends() external onlyOwner {
        RiniaDividend.removeStuckDividends();
    }
}