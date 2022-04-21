// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/ISquidoshiReflector.sol';
import './interfaces/ISmartLottery.sol';
import './utils/LockableFunction.sol';
import './utils/AntiLPSniper.sol';
import './SmartBuyback.sol';
import './interfaces/ISupportingTokenInjection.sol';

interface IERC20Detailed is IERC20 {
    function name() external view virtual returns (string memory);

    function decimals() external view virtual returns (uint8);
}

contract Squidoshi is IERC20Detailed, ISupportingTokenInjection, AntiLPSniper, LockableFunction, SmartBuyback {
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;

    event Burn(address indexed from, uint256 tokensBurned);

    struct Fees {
        uint256 liquidity;
        uint256 marketing;
        uint256 vault;
        uint256 tokenReflection;
        uint256 buyback;
        uint256 lottery;
        uint256 divisor;
    }

    struct TokenTracker {
        uint256 liquidity;
        uint256 marketingTokens;
        uint256 vaultTokens;
        uint256 reward;
        uint256 buyback;
        uint256 lottery;
    }

    bool private initialized;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) private automatedMarketMakerPairs;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;

    bool tradingIsEnabled;

    // Trackers for various pending token swaps and fees
    Fees public buySellFees;
    Fees public transferFees;
    TokenTracker public tokenTracker;

    uint256 public _maxBuyTxAmount;
    uint256 public _maxSellTxAmount;
    uint256 public tokenSwapThreshold;

    uint256 public gasForProcessing = 400000;

    address payable public marketingWallet;
    address payable public vaultAddress;
    ISmartLottery public lotteryContract;
    ISquidoshiReflector public reflectorContract;

    constructor(
        uint256 _supply,
        address routerAddress,
        address _marketingWallet,
        address _vaultAddress
    ) public AuthorizedList() {
        _name = 'Squidoshi';
        _symbol = 'SQDI';
        _decimals = 9;
        _totalSupply = _supply * 10**_decimals;

        swapsEnabled = false;

        _maxBuyTxAmount = _totalSupply.mul(3).div(100);
        _maxSellTxAmount = _totalSupply.mul(1).div(100);
        tokenSwapThreshold = _maxSellTxAmount.div(500);

        liquidityReceiver = deadAddress;

        marketingWallet = payable(_marketingWallet);
        vaultAddress = payable(_vaultAddress);
        pancakeRouter = IPancakeRouter02(routerAddress);

        buySellFees = Fees({
            liquidity: 3,
            marketing: 3,
            vault: 2,
            tokenReflection: 2,
            buyback: 2,
            lottery: 0,
            divisor: 100
        });

        transferFees = Fees({
            liquidity: 0,
            marketing: 25,
            vault: 0,
            tokenReflection: 0,
            buyback: 0,
            lottery: 0,
            divisor: 1000
        });

        tokenTracker = TokenTracker({
            liquidity: 0,
            marketingTokens: 0,
            vaultTokens: 0,
            reward: 0,
            buyback: 0,
            lottery: 0
        });

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[deadAddress] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[vaultAddress] = true;

        balances[owner()] = _totalSupply;
        emit Transfer(address(this), owner(), _totalSupply);
    }

    function init(address payable _reflectorContract, address payable _lotteryContract) external authorized {
        require(!initialized, 'already initialized');

        automatedMarketMakerPairs[pancakePair] = true;

        reflectorContract = ISquidoshiReflector(_reflectorContract);
        lotteryContract = ISmartLottery(_lotteryContract);

        _isExcludedFromFee[address(_reflectorContract)] = true;
        _isExcludedFromFee[address(_lotteryContract)] = true;

        reflectorContract.excludeFromReward(pancakePair, true);
        reflectorContract.excludeFromReward(_lotteryContract, true);

        lotteryContract.excludeFromJackpot(pancakePair, true);
        lotteryContract.excludeFromJackpot(_reflectorContract, true);
        lotteryContract.excludeFromJackpot(marketingWallet, true);
        lotteryContract.excludeFromJackpot(vaultAddress, true);

        initialized = true;
    }

    fallback() external payable {}

    //to recieve BNB from pancakeswapV2Router when swaping

    receive() external payable {}

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return uint8(_decimals);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = payable(_marketingWallet);
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        vaultAddress = payable(_vaultAddress);
    }

    function setMaxBuyTxAmount(uint256 amountBIPS) external onlyOwner {
        _maxBuyTxAmount = _totalSupply.mul(amountBIPS).div(10000);
    }

    function setMaxSellTxAmount(uint256 amountBIPS) external onlyOwner {
        _maxSellTxAmount = _totalSupply.mul(amountBIPS).div(10000);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function updateGasForProcessing(uint256 newValue) public authorized {
        require(newValue >= 200000 && newValue <= 1000000);
        require(newValue != gasForProcessing);
        gasForProcessing = newValue;
    }

    function excludeFromFee(address account, bool shouldExclude) public authorized {
        _isExcludedFromFee[account] = shouldExclude;
    }

    function _calculateFees(uint256 amount, bool isTransfer)
        private
        view
        returns (
            uint256 liquidityFee,
            uint256 marketingFee,
            uint256 vaultFee,
            uint256 buybackFee,
            uint256 reflectionFee,
            uint256 lotteryFee
        )
    {
        Fees memory _fees;
        if (isTransfer) _fees = transferFees;
        else _fees = buySellFees;
        liquidityFee = amount.mul(_fees.liquidity).div(_fees.divisor);
        marketingFee = amount.mul(_fees.marketing).div(_fees.divisor);
        vaultFee = amount.mul(_fees.vault).div(_fees.divisor);
        buybackFee = amount.mul(_fees.buyback).div(_fees.divisor);
        reflectionFee = amount.mul(_fees.tokenReflection).div(_fees.divisor);
        lotteryFee = amount.mul(_fees.lottery).div(_fees.divisor);
    }

    function _takeFees(
        address from,
        uint256 amount,
        bool isTransfer
    ) private returns (uint256 transferAmount) {
        (
            uint256 liquidityFee,
            uint256 marketingFee,
            uint256 vaultFee,
            uint256 buybackFee,
            uint256 reflectionFee,
            uint256 lotteryFee
        ) = _calculateFees(amount, isTransfer);

        tokenTracker.liquidity = tokenTracker.liquidity.add(liquidityFee);
        tokenTracker.marketingTokens = tokenTracker.marketingTokens.add(marketingFee);
        tokenTracker.vaultTokens = tokenTracker.vaultTokens.add(vaultFee);
        tokenTracker.buyback = tokenTracker.buyback.add(buybackFee);
        tokenTracker.reward = tokenTracker.reward.add(reflectionFee);
        tokenTracker.lottery = tokenTracker.lottery.add(lotteryFee);

        uint256 totalFees = liquidityFee.add(marketingFee).add(vaultFee);
        totalFees = totalFees.add(buybackFee).add(reflectionFee).add(lotteryFee);

        balances[address(this)] = balances[address(this)].add(totalFees);
        emit Transfer(from, address(this), totalFees);
        transferAmount = amount.sub(totalFees);
    }

    function updateTransferFees(
        uint256 _liquidity,
        uint256 _marketing,
        uint256 _vault,
        uint256 _tokenReflection,
        uint256 _buyback,
        uint256 _lottery,
        uint256 _divisor
    ) external onlyOwner {
        transferFees = Fees({
            liquidity: _liquidity,
            marketing: _marketing,
            vault: _vault,
            tokenReflection: _tokenReflection,
            buyback: _buyback,
            lottery: _lottery,
            divisor: _divisor
        });
    }

    function updateBuySellFees(
        uint256 _liquidity,
        uint256 _marketing,
        uint256 _vault,
        uint256 _tokenReflection,
        uint256 _buyback,
        uint256 _lottery,
        uint256 _divisor
    ) external onlyOwner {
        buySellFees = Fees({
            liquidity: _liquidity,
            marketing: _marketing,
            vault: _vault,
            tokenReflection: _tokenReflection,
            buyback: _buyback,
            lottery: _lottery,
            divisor: _divisor
        });
    }

    function setTokenSwapThreshold(uint256 minTokensBeforeTransfer) public authorized {
        tokenSwapThreshold = minTokensBeforeTransfer * 10**_decimals;
    }

    function burn(uint256 burnAmount) public override {
        require(_msgSender() != address(0));
        require(balanceOf(_msgSender()) > burnAmount);
        _burn(_msgSender(), burnAmount);
    }

    function _burn(address from, uint256 burnAmount) private {
        _transferStandard(from, deadAddress, burnAmount, burnAmount);
        emit Burn(from, burnAmount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        require(owner != address(0) && spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0) && to != address(0));
        require(!isBlackListed[to] && !isBlackListed[from]);
        require(initialized);
        if (amount == 0) {
            _transferStandard(from, to, 0, 0);
        }
        uint256 transferAmount = amount;
        bool tryBuyback;

        if (from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if (automatedMarketMakerPairs[from]) {
                // Buy
                require(amount <= _maxBuyTxAmount);
                if (!tradingIsEnabled && antiSniperEnabled) {
                    banHammer(to);
                    to = address(this);
                } else {
                    transferAmount = _takeFees(from, amount, false);
                }
            } else if (automatedMarketMakerPairs[to]) {
                // Sell
                require(tradingIsEnabled);
                if (from != address(this) && from != address(pancakeRouter)) {
                    require(amount <= _maxSellTxAmount);
                    tryBuyback = shouldBuyback(balanceOf(pancakePair), amount);
                    transferAmount = _takeFees(from, amount, false);
                }
            } else {
                // Transfer
                transferAmount = _takeFees(from, amount, true);
            }
        } else if (from != address(this) && to != address(this) && tradingIsEnabled) {
            reflectorContract.process(gasForProcessing);
        }

        try reflectorContract.setShare(payable(from), balanceOf(from)) {} catch {}
        try reflectorContract.setShare(payable(to), balanceOf(to)) {} catch {}
        try lotteryContract.logTransfer(payable(from), balanceOf(from), payable(to), balanceOf(to)) {} catch {}
        if (tryBuyback) {
            doBuyback(balanceOf(pancakePair), amount);
        } else if (!inSwap && from != pancakePair && from != address(pancakeRouter) && tradingIsEnabled) {
            selectSwapEvent();
            try reflectorContract.claimDividendFor(from) {} catch {}
        }

        _transferStandard(from, to, amount, transferAmount);
    }

    function pushSwap() external {
        if (!inSwap && tradingIsEnabled) selectSwapEvent();
    }

    function selectSwapEvent() private lockTheSwap {
        if (!swapsEnabled) {
            return;
        }
        uint256 contractBalance = address(this).balance;

        if (tokenTracker.reward >= tokenSwapThreshold) {
            uint256 toSwap = tokenTracker.reward > _maxSellTxAmount ? _maxSellTxAmount : tokenTracker.reward;
            swapTokensForCurrency(toSwap);
            uint256 swappedCurrency = address(this).balance.sub(contractBalance);
            reflectorContract.deposit{value: swappedCurrency}();
            tokenTracker.reward = tokenTracker.reward.sub(toSwap);
        } else if (tokenTracker.buyback >= tokenSwapThreshold) {
            uint256 toSwap = tokenTracker.buyback > _maxSellTxAmount ? _maxSellTxAmount : tokenTracker.buyback;
            swapTokensForCurrency(toSwap);
            tokenTracker.buyback = tokenTracker.buyback.sub(toSwap);
        } else if (tokenTracker.lottery >= tokenSwapThreshold) {
            uint256 toSwap = tokenTracker.lottery > _maxSellTxAmount ? _maxSellTxAmount : tokenTracker.lottery;
            swapTokensForCurrency(toSwap);
            uint256 swappedCurrency = address(this).balance.sub(contractBalance);
            lotteryContract.deposit{value: swappedCurrency}();
            tokenTracker.lottery = tokenTracker.lottery.sub(toSwap);
        } else if (tokenTracker.liquidity >= tokenSwapThreshold) {
            uint256 toSwap = tokenTracker.liquidity > _maxSellTxAmount ? _maxSellTxAmount : tokenTracker.liquidity;
            swapAndLiquify(tokenTracker.liquidity);
            tokenTracker.liquidity = tokenTracker.liquidity.sub(toSwap);
        } else if (tokenTracker.marketingTokens >= tokenSwapThreshold) {
            uint256 toSwap = tokenTracker.marketingTokens > _maxSellTxAmount
                ? _maxSellTxAmount
                : tokenTracker.marketingTokens;
            swapTokensForCurrency(toSwap);
            uint256 swappedCurrency = address(this).balance.sub(contractBalance);
            address(marketingWallet).call{value: swappedCurrency}('');
            tokenTracker.marketingTokens = tokenTracker.marketingTokens.sub(toSwap);
        } else if (tokenTracker.vaultTokens >= tokenSwapThreshold) {
            uint256 toSwap = tokenTracker.vaultTokens > _maxSellTxAmount ? _maxSellTxAmount : tokenTracker.vaultTokens;
            swapTokensForCurrency(toSwap);
            uint256 swappedCurrency = address(this).balance.sub(contractBalance);
            address(vaultAddress).call{value: swappedCurrency}('');
            tokenTracker.vaultTokens = tokenTracker.vaultTokens.sub(toSwap);
        }
        try lotteryContract.checkAndPayJackpot() {} catch {}
        try reflectorContract.process(gasForProcessing) {} catch {}
    }

    function authorizeCaller(address authAddress, bool shouldAuthorize) external override onlyOwner {
        authorizedCaller[authAddress] = shouldAuthorize;

        lotteryContract.authorizeCaller(authAddress, shouldAuthorize);
        reflectorContract.authorizeCaller(authAddress, shouldAuthorize);

        emit AuthorizationUpdated(authAddress, shouldAuthorize);
    }

    function updateLPPair(address newAddress) public override authorized {
        super.updateLPPair(newAddress);
        registerPairAddress(newAddress, true);
        reflectorContract.excludeFromReward(pancakePair, true);
        lotteryContract.excludeFromJackpot(pancakePair, true);
    }

    function addBUSDPair(address _BUSD) public authorized {
        require(_BUSD != address(0),"zero address");
        address _pancakeswapV2Pair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this),_BUSD);
        if(_pancakeswapV2Pair != pancakePair){
            updateLPPair(_pancakeswapV2Pair);
        }
    }

    function registerPairAddress(address ammPair, bool isLPPair) public authorized {
        automatedMarketMakerPairs[ammPair] = isLPPair;
        reflectorContract.excludeFromReward(pancakePair, true);
        lotteryContract.excludeFromJackpot(pancakePair, true);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount,
        uint256 transferAmount
    ) private {
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(transferAmount);
        emit Transfer(sender, recipient, transferAmount);
    }

    function addBUSDLiquidity(
        address _BUSD,
        uint256 _BUSDAmount,
        uint256 _tokenAmount
    ) public authorized {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), _tokenAmount);

        pancakeRouter.addLiquidity(
            address(this),
            _BUSD,
            _tokenAmount,
            _BUSDAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function openTrading() external authorized {
        require(!tradingIsEnabled);
        tradingIsEnabled = true;
        swapsEnabled = true;
        autoBuybackEnabled = true;
        autoBuybackAtCap = true;
    }

    function updateReflectionContract(address newReflectorAddress) external authorized {
        reflectorContract = ISquidoshiReflector(newReflectorAddress);
    }

    function updateLotteryContract(address newLotteryAddress) external authorized {
        lotteryContract = ISmartLottery(newLotteryAddress);
    }

    function excludeFromJackpot(address userAddress, bool shouldExclude) external authorized {
        lotteryContract.excludeFromJackpot(userAddress, shouldExclude);
    }

    function excludeFromRewards(address userAddress, bool shouldExclude) external authorized {
        reflectorContract.excludeFromReward(userAddress, shouldExclude);
    }

    function reflections() external view returns (string memory) {
        return reflectorContract.rewardCurrency();
    }

    function jackpot() external view returns (string memory) {
        return lotteryContract.rewardCurrency();
    }

    function depositTokens(
        uint256 liquidityDeposit,
        uint256 rewardsDeposit,
        uint256 jackpotDeposit,
        uint256 buybackDeposit
    ) external override {
        require(
            balanceOf(_msgSender()) >= (liquidityDeposit.add(rewardsDeposit).add(jackpotDeposit).add(buybackDeposit))
        );
        uint256 totalDeposit = liquidityDeposit.add(rewardsDeposit).add(jackpotDeposit).add(buybackDeposit);
        _transferStandard(_msgSender(), address(this), totalDeposit, totalDeposit);
        tokenTracker.liquidity = tokenTracker.liquidity.add(liquidityDeposit);
        tokenTracker.reward = tokenTracker.reward.add(rewardsDeposit);
        tokenTracker.lottery = tokenTracker.lottery.add(jackpotDeposit);
        tokenTracker.buyback = tokenTracker.buyback.add(buybackDeposit);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IBaseDistributor.sol";
import "../utils/AuthorizedList.sol";

interface ISquidoshiReflector is IBaseDistributor, IAuthorizedListExt, IAuthorizedList {

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function process(uint256 gas) external;

    function setRewardToCurrency(bool andSwap) external;
    function setRewardToToken(address _tokenAddress, bool andSwap) external;
    function excludeFromReward(address shareholder, bool shouldExclude) external;
    function claimDividendFor(address shareholder) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./IBaseDistributor.sol";
import "./IUserInfoManager.sol";
import "./IAuthorizedList.sol";

interface ISmartLottery is IBaseDistributor, IAuthorizedListExt, IAuthorizedList {
    struct WinnerLog{
        string rewardName;
        address winnerAddress;
        uint256 drawNumber;
        uint256 prizeWon;
    }

    struct JackpotRequirements{
        uint256 minSquidoshiBalance;
        uint256 minDrawsSinceLastWin;
        uint256 timeSinceLastTransfer;
    }

    event JackpotSet(string indexed tokenName, uint256 JackpotAmount);
    event JackpotWon(address indexed winner, string indexed reward, uint256 amount, uint256 drawNo);
    event JackpotCriteriaUpdated(uint256 minSquidoshiBalance, uint256 minDrawsSinceLastWin, uint256 timeSinceLastTransfer);

    function draw() external pure returns(uint256);
    function jackpotAmount() external view returns(uint256);
    function isJackpotReady() external view returns(bool);
    function setJackpot(uint256 newJackpot) external;
    function checkAndPayJackpot() external returns(bool);
    function excludeFromJackpot(address shareholder, bool shouldExclude) external;
    function setMaxAttempts(uint256 attemptsToFindWinner) external;

    function setJackpotToCurrency(bool andSwap) external;
    function setJackpotToToken(address _tokenAddress, bool andSwap) external;
    function setJackpotEligibilityCriteria(uint256 minSquidoshiBalance, uint256 minDrawsSinceWin, uint256 timeSinceLastTransferHours) external;
    function logTransfer(address payable from, uint256 fromBalance, address payable to, uint256 toBalance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract LockableFunction {
    bool internal locked;

    modifier lockFunction {
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./AuthorizedList.sol";

contract AntiLPSniper is AuthorizedList {
    bool public antiSniperEnabled = true;
    mapping(address => bool) public isBlackListed;

    function banHammer(address user) internal {
        isBlackListed[user] = true;
    }

    function updateBlacklist(address user, bool shouldBlacklist) external onlyOwner {
        isBlackListed[user] = shouldBlacklist;
    }

    function enableAntiSniper(bool enabled) external authorized {
        antiSniperEnabled = enabled;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './utils/AuthorizedList.sol';
import './utils/LPSwapSupport.sol';

abstract contract SmartBuyback is AuthorizedList, LPSwapSupport {
    event BuybackTriggered(uint256 amountSpent);
    event BuybackReceiverUpdated(address indexed oldReceiver, address indexed newReceiver);

    uint256 public minAutoBuyback = 0.05 ether;
    uint256 public maxAutoBuyback = 10 ether;
    uint256 private significantLPBuyPct = 1;
    uint256 private significantLPBuyPctDivisor = 100;
    bool public autoBuybackEnabled;
    bool public autoBuybackAtCap = true;
    bool public doSimpleBuyback;
    address public buybackReceiver = deadAddress;
    uint256 private lastBuybackAmount;
    uint256 private lastBuybackTime;
    uint256 private lastBuyPoolSize;

    function shouldBuyback(uint256 poolTokens, uint256 sellAmount) public view returns (bool) {
        return
            (poolTokens.mul(significantLPBuyPct).div(significantLPBuyPctDivisor) >= sellAmount &&
                autoBuybackEnabled &&
                address(this).balance >= minAutoBuyback) ||
            (autoBuybackAtCap && address(this).balance >= maxAutoBuyback);
    }

    function doBuyback(uint256 poolTokens, uint256 sellAmount) internal {
        if (autoBuybackEnabled && !inSwap && address(this).balance >= minAutoBuyback)
            _doBuyback(poolTokens, sellAmount);
    }

    function _doBuyback(uint256 poolTokens, uint256 sellAmount) private lockTheSwap {
        uint256 lpMin = minSpendAmount;
        uint256 lpMax = maxSpendAmount;
        minSpendAmount = minAutoBuyback;
        maxSpendAmount = maxAutoBuyback;
        if (autoBuybackAtCap && address(this).balance >= maxAutoBuyback) {
            simpleBuyback(poolTokens, 0);
        } else if (doSimpleBuyback) {
            simpleBuyback(poolTokens, sellAmount);
        } else {
            dynamicBuyback(poolTokens, sellAmount);
        }
        minSpendAmount = lpMin;
        maxSpendAmount = lpMax;
    }

    function _doBuybackNoLimits(uint256 amount) private lockTheSwap {
        uint256 lpMin = minSpendAmount;
        uint256 lpMax = maxSpendAmount;
        minSpendAmount = 0;
        maxSpendAmount = amount;
        swapCurrencyForTokensAdv(address(this), amount, buybackReceiver);
        emit BuybackTriggered(amount);
        minSpendAmount = lpMin;
        maxSpendAmount = lpMax;
    }

    function simpleBuyback(uint256 poolTokens, uint256 sellAmount) private {
        uint256 amount = address(this).balance > maxAutoBuyback ? maxAutoBuyback : address(this).balance;
        if (amount >= minAutoBuyback) {
            if (sellAmount == 0) {
                amount = minAutoBuyback;
            }
            swapCurrencyForTokensAdv(address(this), amount, buybackReceiver);
            emit BuybackTriggered(amount);
            lastBuybackAmount = amount;
            lastBuybackTime = block.timestamp;
            lastBuyPoolSize = poolTokens;
        }
    }

    function dynamicBuyback(uint256 poolTokens, uint256 sellAmount) private {
        if (lastBuybackTime == 0) {
            simpleBuyback(poolTokens, sellAmount);
        }
        uint256 amount = sellAmount.mul(address(pancakePair).balance).div(poolTokens);
        if (lastBuyPoolSize < poolTokens) {
            amount = amount.add(amount.mul(poolTokens).div(poolTokens.add(lastBuyPoolSize)));
        }

        swapCurrencyForTokensAdv(address(this), amount, buybackReceiver);
        emit BuybackTriggered(amount);
        lastBuybackAmount = amount;
        lastBuybackTime = block.timestamp;
        lastBuyPoolSize = poolTokens;
    }

    function enableAutoBuybacks(bool enable, bool autoBuybackAtCapEnabled) external authorized {
        autoBuybackEnabled = enable;
        autoBuybackAtCap = autoBuybackAtCapEnabled;
    }

    function updateBuybackSettings(
        uint256 lpSizePct,
        uint256 pctDivisor,
        bool simpleBuybacksOnly
    ) external authorized {
        significantLPBuyPct = lpSizePct;
        significantLPBuyPctDivisor = pctDivisor;
        doSimpleBuyback = simpleBuybacksOnly;
    }

    function updateBuybackLimits(uint256 minBuyAmount, uint256 maxBuyAmount) external authorized {
        minAutoBuyback = minBuyAmount;
        maxAutoBuyback = maxBuyAmount;
    }

    function forceBuyback(uint256 amount) external authorized {
        require(address(this).balance >= amount);
        if (!inSwap) {
            _doBuybackNoLimits(amount);
        }
    }

    function updateBuybackReceiver(address newReceiver) external onlyOwner {
        emit BuybackReceiverUpdated(buybackReceiver, newReceiver);
        buybackReceiver = newReceiver;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface ISupportingTokenInjection {
    function depositTokens(uint256 liquidityDeposit, uint256 rewardsDeposit, uint256 jackpotDeposit, uint256 buybackDeposit) external;
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IBaseDistributor {
    enum RewardType{
        TOKEN,
        CURRENCY
    }

    struct RewardInfo{
        string name;
        address rewardAddress;
        uint256 decimals;
    }

    function deposit() external payable;
    function rewardCurrency() external view returns(string memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IAuthorizedList.sol';

contract AuthorizedList is IAuthorizedList, Context, Ownable {
    using Address for address;

    event AuthorizationUpdated(address indexed user, bool authorized);
    event AuthorizationRenounced(address indexed user);

    mapping(address => bool) internal authorizedCaller;

    modifier authorized() {
        require(authorizedCaller[_msgSender()] || _msgSender() == owner(), 'not authorized');
        require(_msgSender() != address(0), 'Invalid caller');
        _;
    }

    constructor() public Ownable() {
        authorizedCaller[_msgSender()] = true;
    }

    function authorizeCaller(address authAddress, bool shouldAuthorize) external virtual override onlyOwner {
        authorizedCaller[authAddress] = shouldAuthorize;
        emit AuthorizationUpdated(authAddress, shouldAuthorize);
    }

    function renounceAuthorization() external authorized {
        authorizedCaller[_msgSender()] = false;
        emit AuthorizationRenounced(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IAuthorizedList {
    function authorizeCaller(address authAddress, bool shouldAuthorize) external;
}

interface IAuthorizedListExt {
    function authorizeByAuthorized(address authAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IUserInfoManager {
//    function logTransfer(address payable from, uint256 fromBalance, address payable to, uint256 toBalance) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
There are far too many uses for the LP swapping pool.
Rather than rewrite them, this contract performs them for us and uses both generic and specific calls.
-The Dev
*/
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
//import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol';
//import '@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol';
import './pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol';
import './AuthorizedList.sol';

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

abstract contract LPSwapSupport is AuthorizedList {
    using SafeMath for uint256;
    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event UpdatePair(address indexed newAddress, address indexed oldAddress);
    event UpdateLPReceiver(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 currencyReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool internal inSwap;
    bool public swapsEnabled = true;

    uint256 public minSpendAmount = 0.001 ether;
    uint256 public maxSpendAmount = 1 ether;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    address public liquidityReceiver = deadAddress;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;

    function _approve(
        address owner,
        address spender,
        uint256 tokenAmount
    ) internal virtual;

    function updateRouter(address newAddress) public authorized {
        require(newAddress != address(pancakeRouter), 'already set');
        emit UpdateRouter(newAddress, address(pancakeRouter));
        pancakeRouter = IPancakeRouter02(newAddress);
    }

    function updateLiquidityReceiver(address receiverAddress) external onlyOwner {
        require(receiverAddress != liquidityReceiver);
        emit UpdateLPReceiver(receiverAddress, liquidityReceiver);
        liquidityReceiver = receiverAddress;
    }

    function updateRouterAndPair(address newAddress) public virtual authorized {
        if (newAddress != address(pancakeRouter)) {
            updateRouter(newAddress);
        }
        address _pancakeswapV2Pair = IPancakeFactory(pancakeRouter.factory()).createPair(
            address(this),
            pancakeRouter.WETH()
        );
        if (_pancakeswapV2Pair != pancakePair) {
            updateLPPair(_pancakeswapV2Pair);
        }
    }

    function updateLPPair(address newAddress) public virtual authorized {
        require(newAddress != pancakePair, 'already set');
        emit UpdatePair(newAddress, pancakePair);
        pancakePair = newAddress;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public authorized {
        swapsEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function swapAndLiquify(uint256 tokens) internal {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for
        swapTokensForCurrency(half);

        // how much did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForCurrency(uint256 tokenAmount) internal {
        swapTokensForCurrencyAdv(address(this), tokenAmount, address(this));
    }

    function swapTokensForCurrencyAdv(
        address tokenAddress,
        uint256 tokenAmount,
        address destination
    ) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = pancakeRouter.WETH();

        if (tokenAddress != address(this)) {
            IERC20(tokenAddress).approve(address(pancakeRouter), tokenAmount);
        } else {
            _approve(address(this), address(pancakeRouter), tokenAmount);
        }

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            destination,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 cAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeRouter), tokenAmount);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: cAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReceiver,
            block.timestamp
        );
    }

    function swapCurrencyForTokens(uint256 amount) internal {
        swapCurrencyForTokensAdv(address(this), amount, address(this));
    }

    function swapCurrencyForTokensAdv(
        address tokenAddress,
        uint256 amount,
        address destination
    ) internal {
        // generate the pair path of token
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = tokenAddress;
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }
        if (amount > maxSpendAmount) {
            amount = maxSpendAmount;
        }
        if (amount < minSpendAmount) {
            return;
        }

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            destination,
            block.timestamp.add(400)
        );
    }

    function updateSwapRange(uint256 minAmount, uint256 maxAmount) external authorized {
        require(minAmount <= maxAmount);
        minSpendAmount = minAmount;
        maxSpendAmount = maxAmount;
    }
}

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}