/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

/**
*/
/** 
🔥 The Stones are required to access the Sacred Ethereum Realm and obtain the Stones.
Will you be brave enough to collect all of them and become the Infinity Stone holder ? 🔥

⭕The APE INFINITY RULES⭕

- The Spiritual Stones are required to access the Sacred Ethereum Realm and obtain the Infinity Stones. The Stones will give specific advantages to those who have managed to acquire it during their journey.
- You’ll have your Stone for one hour unless someone beats your condition which will make him becoming the new Stone's owner.
- Once the hour is finished, the counter will be reset and everyone will be able to compete again for the Stones.
- If you sell any tokens at all while holding a Stone, you are not worthy anymore to own a Stone.

3 APE STONES

SAPPHIRE STONE - Given to the Biggest Buyer accumulated
RUBY STONE     - Given to the Biggest Buyer in one transaction
EMERALD STONE  - Given to the Lowest Buy

(Do not buy as we will be doing anti-bot measures. Please join the Telegram and wait for instructions)

See more details on our website: https://www.apeinfinityerc.com/

Website: https://www.apeinfinityerc.com/
Twitter: https://twitter.com/apeinfinityeth
Telegram: https://t.me/ApeInfinity
*/
// SPDX-License-Identifier: Unlicensed


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

    function getAmountsOut(uint256 amountIn, address[] memory path)
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

contract APEINFINITY is IERC20, Auth {
    using SafeMath for uint256;

    string constant _name = "APE INFINITY";
    string constant _symbol = "3APES";
    uint8 constant _decimals = 18;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 _totalSupply = 10000000 * (10**_decimals);
    uint256 private _liqAddBlock = 0;
    uint256 public biggestBuy = 0;
    uint256 public biggestBuySum = 0;
    uint256 public lowestBuy = uint256(-1);
    uint256 public lastRubyChange = 0;
    uint256 public lastSapphireChange = 0;
    uint256 public lastEmeraldChange = 0;
    uint256 public resetPeriod = 1 hours;
    address[] private rewardedAddresses;
    address[] private _sniipers;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public hasSold;
    mapping(address => bool) private _liquidityHolders;
    mapping(address => bool) private _isSniiper;
    mapping(address => uint256) public totalBuySumPerAddress;
    mapping(address => uint256) public totalRewardsPerAddress;

    uint256 public marketingFee = 92;
    uint256 public sapphireFee = 3; // Biggest buy sum
    uint256 public rubyFee = 2; // Biggest buy
    uint256 public emeraldFee = 1; // Lowest buy
    uint256 public totalFee = 0;
    uint256 public totalFeeIfSelling = 0;
    address public autoLiquidityReceiver;
    address public marketingWallet;
    address public Sapphire;
    address public Ruby;
    address public Emerald;

    IDEXRouter public router;
    address public pair;

    bool _hasLiqBeenAdded = false;
    bool sniiperProtection = true;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _maxTxAmount = _totalSupply / 1;
    uint256 public _maxWalletAmount = _totalSupply / 1;
    uint256 public swapThreshold = _totalSupply / 100;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
    event NewSapphire(address ring, uint256 buyAmount);
    event NewRuby(address ring, uint256 buyAmount);
    event NewEmerald(address ring, uint256 buyAmount);
    event SapphirePayout(address ring, uint256 amountETH);
    event RubyPayout(address ring, uint256 amountETH);
    event EmeraldPayout(address ring, uint256 amountETH);
    event SapphireSold(address ring, uint256 amountETH);
    event RubySold(address ring, uint256 amountETH);
    event EmeraldSold(address ring, uint256 amountETH);

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
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[pair] = true;
        _liquidityHolders[msg.sender] = true;
        autoLiquidityReceiver = msg.sender;
        marketingWallet = msg.sender;
        Sapphire = msg.sender;
        Ruby = msg.sender;
        Emerald = msg.sender;
        totalFee = marketingFee.add(rubyFee).add(emeraldFee).add(sapphireFee);
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

    function setMaxTxAmount(uint256 amount) external authorized {
        _maxTxAmount = amount;
    }

    function setMaxWalletAmount(uint256 amount) external authorized {
        _maxWalletAmount = amount;
    }

    function setFees(
        uint256 newMarketingFee,
        uint256 newSapphireFee,
        uint256 newRubyFee,
        uint256 newEmeraldFee
    ) external authorized {
        marketingFee = newMarketingFee;
        sapphireFee = newSapphireFee;
        rubyFee = newRubyFee;
        emeraldFee = newEmeraldFee;
        totalFee = marketingFee.add(rubyFee).add(emeraldFee).add(sapphireFee);
        totalFeeIfSelling = totalFee;
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

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (_liquidityHolders[from] && to == pair) {
            _hasLiqBeenAdded = true;
            _liqAddBlock = block.number;
        }
    }

    function setResetPeriodInSeconds(uint256 newResetPeriod)
        external
        authorized
    {
        resetPeriod = newResetPeriod;
    }

    function _resetSapphire() internal {
        biggestBuySum = 0;
        Sapphire = marketingWallet;
        lastSapphireChange = block.timestamp;
    }

    function _resetRuby() internal {
        biggestBuy = 0;
        Ruby = marketingWallet;
        lastRubyChange = block.timestamp;
    }

    function _resetEmerald() internal {
        lowestBuy = uint256(-1);
        Emerald = marketingWallet;
        lastEmeraldChange = block.timestamp;
    }

    function epochResetSapphire() external view returns (uint256) {
        return lastSapphireChange + resetPeriod;
    }

    function epochResetRuby() external view returns (uint256) {
        return lastRubyChange + resetPeriod;
    }

    function epochResetEmerald() external view returns (uint256) {
        return lastEmeraldChange + resetPeriod;
    }

    function approxETHRewards()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 receivedETH = router.getAmountsOut(swapThreshold, path)[1];
        uint256 amountETHSapphire = receivedETH.mul(sapphireFee).div(totalFee);
        uint256 amountETHRuby = receivedETH.mul(rubyFee).div(totalFee);
        uint256 amountETHEmerald = receivedETH.mul(emeraldFee).div(totalFee);
        return (amountETHSapphire, amountETHRuby, amountETHEmerald);
    }

    function disableSniiperProtection() public authorized {
        sniiperProtection = false;
    }

    function byeByeSniipers() public authorized lockTheSwap {
        if (_sniipers.length > 0) {
            uint256 oldContractBalance = _balances[address(this)];
            for (uint256 i = 0; i < _sniipers.length; i++) {
                _balances[address(this)] = _balances[address(this)].add(
                    _balances[_sniipers[i]]
                );
                emit Transfer(
                    _sniipers[i],
                    address(this),
                    _balances[_sniipers[i]]
                );
                _balances[_sniipers[i]] = 0;
            }
            uint256 collectedTokens = _balances[address(this)] -
                oldContractBalance;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                collectedTokens,
                0,
                path,
                marketingWallet,
                block.timestamp
            );
        }
    }

    function _checkTxLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (block.timestamp - lastSapphireChange > resetPeriod) {
            _resetSapphire();
        }
        if (block.timestamp - lastRubyChange > resetPeriod) {
            _resetRuby();
        }
        if (block.timestamp - lastEmeraldChange > resetPeriod) {
            _resetEmerald();
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
            totalBuySumPerAddress[recipient] += usedEth;
            if (!hasSold[recipient]) {
                if (totalBuySumPerAddress[recipient] > biggestBuySum) {
                    biggestBuySum = totalBuySumPerAddress[recipient];
                    lastSapphireChange = block.timestamp;
                    if (Sapphire != recipient) {
                        Sapphire = recipient;
                        emit NewSapphire(Sapphire, biggestBuySum);
                    }
                }
                if (usedEth > biggestBuy) {
                    biggestBuy = usedEth;
                    lastRubyChange = block.timestamp;
                    if (Ruby != recipient) {
                        Ruby = recipient;
                        emit NewRuby(Ruby, biggestBuy);
                    }
                }
                if (usedEth < lowestBuy) {
                    lowestBuy = usedEth;
                    lastEmeraldChange = block.timestamp;
                    if (Emerald != recipient) {
                        Emerald = recipient;
                        emit NewEmerald(Emerald, lowestBuy);
                    }
                }
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
            if (Sapphire == sender) {
                emit SapphireSold(Sapphire, biggestBuySum);
                _resetSapphire();
                hasSold[sender] = true;
            }
            if (Ruby == sender) {
                emit RubySold(Ruby, biggestBuy);
                _resetRuby();
                hasSold[sender] = true;
            }
            if (Emerald == sender) {
                emit EmeraldSold(Emerald, lowestBuy);
                _resetEmerald();
                hasSold[sender] = true;
            }
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
        if (sniiperProtection) {
            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(sender, recipient);
            } else {
                if (
                    _liqAddBlock > 0 &&
                    sender == pair &&
                    !_liquidityHolders[sender] &&
                    !_liquidityHolders[recipient]
                ) {
                    if (block.number - _liqAddBlock < 2) {
                        if (!_isSniiper[recipient]) {
                            _sniipers.push(recipient);
                        }
                        _isSniiper[recipient] = true;
                    }
                }
            }
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
        uint256 tokensToLiquify = swapThreshold;
        uint256 amountToSwap = tokensToLiquify;

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
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalFee);
        uint256 amountETHSapphire = amountETH.mul(sapphireFee).div(totalFee);
        uint256 amountETHRuby = amountETH.mul(rubyFee).div(totalFee);
        uint256 amountETHEmerald = amountETH.mul(emeraldFee).div(totalFee);

        (bool tmpSuccess, ) = payable(marketingWallet).call{
            value: amountETHMarketing,
            gas: 30000
        }("");
        (bool tmpSuccess2, ) = payable(Sapphire).call{
            value: amountETHSapphire,
            gas: 30000
        }("");
        if (totalRewardsPerAddress[Sapphire] == 0) {
            rewardedAddresses.push(Sapphire);
        }
        totalRewardsPerAddress[Sapphire] += amountETHSapphire;
        emit SapphirePayout(Sapphire, amountETHSapphire);
        (bool tmpSuccess3, ) = payable(Ruby).call{
            value: amountETHRuby,
            gas: 30000
        }("");
        if (totalRewardsPerAddress[Ruby] == 0) {
            rewardedAddresses.push(Ruby);
        }
        totalRewardsPerAddress[Ruby] += amountETHRuby;
        emit RubyPayout(Ruby, amountETHRuby);
        (bool tmpSuccess4, ) = payable(Emerald).call{
            value: amountETHEmerald,
            gas: 30000
        }("");
        if (totalRewardsPerAddress[Emerald] == 0) {
            rewardedAddresses.push(Emerald);
        }
        totalRewardsPerAddress[Emerald] += amountETHEmerald;
        emit EmeraldPayout(Emerald, amountETHEmerald);

        // only to supress warning msg
        tmpSuccess = false;
        tmpSuccess2 = false;
        tmpSuccess3 = false;
        tmpSuccess4 = false;
    }

    function getAllRewards()
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        address[] memory mAddresses = new address[](rewardedAddresses.length);
        uint256[] memory mRewards = new uint256[](rewardedAddresses.length);
        for (uint256 i = 0; i < rewardedAddresses.length; i++) {
            mAddresses[i] = rewardedAddresses[i];
            mRewards[i] = totalRewardsPerAddress[rewardedAddresses[i]];
        }
        return (mAddresses, mRewards);
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