// SPDX-License-Identifier: MIT

/*

RING SOCIALS:

    Telegram: https://t.me/TheRingToken
    Website: https://www.theringstoken.com/
    Twitter: https://twitter.com/TheRingToken

HUGE THANKS TO ASHONCHAIN

In order to build this contract, we hired AshOnChain, freelance solidity developer.
If you want to hire AshOnChain for your next token or NFT contract, you can reach out here:

https://t.me/ashonchain
https://twitter.com/ashonchain

*/

pragma solidity ^0.8.4;

import "./RingDividendTracker.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./MaxWalletCalculator.sol";
import "./RingStorage.sol";
import "./ERC20.sol";

contract Ring is ERC20, Ownable {
    using SafeMath for uint256;
    using RingStorage for RingStorage.Data;
    using Fees for Fees.Data;
    using Game for Game.Data;
    using Referrals for Referrals.Data;
    using Transfers for Transfers.Data;

    address constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    RingStorage.Data private _storage;

    uint256 public constant MAX_SUPPLY = 1000000 * (10**18);


    event ClaimTokens(
        address indexed account,
        uint256 amount
    );

    event StepInTheWell(
        address indexed account,
        uint256 amount,
        bool isReinvest
    );

    constructor() ERC20("RING", "$RING") {
        _mint(address(this), MAX_SUPPLY);
        _transfer(address(this), owner(), MAX_SUPPLY / 4);
        _storage.init(owner());
    }

    receive() external payable {

  	}

    function withdraw() external onlyOwner {
        require(_storage.startTime == 0);

        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "Could not withdraw funds");
    }

    function dividendTracker() external view returns (address) {
        return address(_storage.dividendTracker);
    }

    function pair() external view returns (address) {
        return address(_storage.pair);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        //Piggyback off approvals to burn tokens
        burnLiquidityTokens();
        return super.approve(spender, amount);
    }

    function updateFeeSettings(uint256 baseFee, uint256 maxFee, uint256 sellImpact, uint256 timeImpact) external onlyOwner {
        _storage.fees.updateFeeSettings(baseFee, maxFee, sellImpact, timeImpact);
    }

    function updateReinvestBonus(uint256 bonus) public onlyOwner {
        _storage.fees.updateReinvestBonus(bonus);
    }

    function updateFeeDestinationPercents(uint256 dividendsFactor, uint256 liquidityFactor, uint256 marketingFactor, uint256 burnFactor, uint256 teamFactor, uint256 devFactor) public onlyOwner {
        _storage.fees.updateFeeDestinationPercents(dividendsFactor, liquidityFactor, marketingFactor, burnFactor, teamFactor, devFactor);
    }

    function updateGameRewardFactors(uint256 biggestBuyerRewardFactor, uint256 lastBuyerRewardFactor) public onlyOwner {
        _storage.game.updateGameRewardFactors(biggestBuyerRewardFactor, lastBuyerRewardFactor);
    }

    function updateGameParams(uint256 gameMinimumBuy, uint256 gameLength, uint256 gameTimeIncrease) public onlyOwner {
        _storage.game.updateGameParams(gameMinimumBuy, gameLength, gameTimeIncrease);
    }



    function updateReferrals(uint256 referralBonus, uint256 referredBonus, uint256 tokensNeeded) public onlyOwner {
        _storage.referrals.updateReferralBonus(referralBonus);
        _storage.referrals.updateReferredBonus(referredBonus);
        _storage.referrals.updateTokensNeededForReferralNumber(tokensNeeded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _storage.excludeFromFees(account, excluded);
    }

    function excludeFromDividends(address account) public onlyOwner {
        _storage.dividendTracker.excludeFromDividends(account);
    }

    function setSwapTokensParams(uint256 atAmount, uint256 maxAmount) external onlyOwner {
        _storage.setSwapTokensParams(atAmount, maxAmount);
    }

    function manualSwapAccumulatedFees() external onlyOwner {
        _storage.fees.swapAccumulatedFees(_storage, balanceOf(address(this)));
    }

    function getData(address account) external view returns (uint256[] memory dividendInfo, uint256 referralCode, int256 buyFee, uint256 sellFee, address biggestBuyerCurrentGame, uint256 biggestBuyerAmountCurrentGame, uint256 biggestBuyerRewardCurrentGame, address lastBuyerCurrentGame, uint256 lastBuyerRewardCurrentGame, uint256 gameEndTime, uint256 blockTimestamp) {
        return _storage.getData(account, getLiquidityTokenBalance());
    }

    function getLiquidityTokenBalance() private view returns (uint256) {
        return balanceOf(address(_storage.pair));
    }

    function claimDividends(bool enterTheRing, uint256 minimumAmountOut) external returns (bool) {
		return _storage.dividendTracker.claimDividends(
            msg.sender, enterTheRing, minimumAmountOut);
    }

    function burnLiquidityTokens() public {
        uint256 burnAmount = _storage.burnLiquidityTokens(getLiquidityTokenBalance());

        if(burnAmount == 0) {
            return;
        }

        _burn(address(_storage.pair), burnAmount);
        _storage.pair.sync();
    }

    function zapInTheWellEther(address recipient, uint256 minimumAmountOut) external payable {
        require(msg.value >= 0.000001 ether);
        require(_storage.startTime > 0);
        require(!Transfers.codeRequiredToBuy(_storage.startTime));

        burnLiquidityTokens();
        handleGame();

        uint256 etherBalanceBefore = address(this).balance - msg.value;
        uint256 tokenBalanceBefore = balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = _storage.router.WETH();
        path[1] = address(this);

        uint256 swapEther = msg.value / 2;
        uint256 addEther = msg.value - swapEther;

        uint256 accountTokenBalance = balanceOf(msg.sender);

        _storage.zapping = true;

        _storage.router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapEther}(
            minimumAmountOut,
            path,
            msg.sender,
            block.timestamp
        );

        uint256 accountGain = balanceOf(msg.sender) - accountTokenBalance;

        super._transfer(msg.sender, address(this), accountGain);

        uint256 addTokens = balanceOf(address(this)) - tokenBalanceBefore;

        _stepInWithLiquidity(recipient, addEther, addTokens);
        _returnExcess(recipient, etherBalanceBefore);

        _storage.zapping = false;
    }


    function _stepInWithLiquidity(address account, uint256 etherAmount, uint256 tokenAmount) private {
        _approve(address(this), address(_storage.router), type(uint).max);

        uint256 liquidityTokensBefore = _storage.pair.balanceOf(deadAddress);

        _storage.router.addLiquidityETH{value: etherAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );

        uint256 liquidityTokensAdded = _storage.pair.balanceOf(deadAddress) - liquidityTokensBefore;

        bool isReinvest = false;

        if(msg.sender == address(_storage.dividendTracker)) {
            liquidityTokensAdded += liquidityTokensAdded * _storage.fees.reinvestBonus / Fees.FACTOR_MAX;

            isReinvest = true;
        }

        _storage.dividendTracker.increaseBalance(account, liquidityTokensAdded);
        emit StepInTheWell(account, liquidityTokensAdded, isReinvest);
    }

    function _returnExcess(address account, uint256 etherBalanceBefore) private {
        if(address(this).balance > etherBalanceBefore) {
            (bool success,) = account.call{value: address(this).balance - etherBalanceBefore}("");
            require(success, "Could not return funds");
        }
    }

    function setPrivateSaleParticipants(address[] memory privateSaleParticipants, uint256 amountInFullTokens) public onlyOwner {
        for(uint256 i = 0; i < privateSaleParticipants.length; i++) {
            address participant = privateSaleParticipants[i];

            if(!_storage.privateSaleAccount[participant]) {
                _storage.privateSaleAccount[participant] = true;
                super._transfer(owner(), participant, amountInFullTokens * 10**18);
            }
        }
    }

    function start() external onlyOwner {
        require(_storage.startTime == 0);

        _approve(address(this), address(_storage.router), type(uint).max);

        _storage.router.addLiquidityETH {
            value: address(this).balance
        } (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        _storage.startGame();
    }

    function takeFees(address from, uint256 amount, uint256 feeFactor) private returns (uint256) {
        uint256 fees = Fees.calculateFees(amount, feeFactor);
        amount = amount.sub(fees);
        super._transfer(from, address(this), fees);
        return amount;
    }

    function mintFromLiquidity(address account, uint256 amount) private {
        if(amount == 0) {
            return;
        }
        _storage.liquidityTokensAvailableToBurn += amount;
        _mint(account, amount);
    }

    function handleGame() public {
        uint256 liquidityTokenBalance = getLiquidityTokenBalance();

        (address biggestBuyer, uint256 amountWonBiggestBuyer, address lastBuyer, uint256 amountWonLastBuyer) = _storage.game.handleGame(liquidityTokenBalance);

        if(biggestBuyer != address(0))  {
            mintFromLiquidity(biggestBuyer, amountWonBiggestBuyer);
            _storage.handleNewBalanceForReferrals(biggestBuyer, balanceOf(biggestBuyer));
        }

        if(lastBuyer != address(0))  {
            mintFromLiquidity(lastBuyer, amountWonLastBuyer);
            _storage.handleNewBalanceForReferrals(lastBuyer, balanceOf(lastBuyer));
        }
    }

    function maxWallet() public view returns (uint256) {
        return MaxWalletCalculator.calculateMaxWallet(MAX_SUPPLY, _storage.startTime);
    }

    function executePossibleSwap(address from, address to, uint256 amount) private {
        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= _storage.swapTokensAtAmount;

        if(from != owner() && to != owner()) {
            if(
                to != address(this) &&
                to != address(_storage.pair) &&
                to != address(_storage.router)
            ) {
                require(balanceOf(to) + amount <= maxWallet());
            }

            if(
                canSwap &&
                !_storage.swapping &&
                !_storage.zapping &&
                to == address(_storage.pair) &&
                _storage.startTime > 0 &&
                block.timestamp >_storage.startTime
            ) {
                _storage.swapping = true;

                uint256 swapAmount = contractTokenBalance;

                if(swapAmount > _storage.swapTokensMaxAmount) {
                    swapAmount = _storage.swapTokensMaxAmount;
                }

                uint256 burn = swapAmount * _storage.fees.burnFactor / Fees.FACTOR_MAX;

                if(burn > 0) {
                    swapAmount -= burn;
                    _burn(address(this), burn);
                }

                _approve(address(this), address(_storage.router), type(uint).max);

                _storage.fees.swapAccumulatedFees(_storage, swapAmount);

                _storage.swapping = false;
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0));
        require(to != address(0));

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(_storage.privateSaleAccount[from]) {
            uint256 movable = _storage.getPrivateSaleMovableTokens(from);
            require(movable >= amount, "Moving tokens too fast");
            _storage.privateSaleTokensMoved[from] += amount;
        }

        executePossibleSwap(from, to, amount);

        bool takeFee = !_storage.swapping &&
                        !_storage.isExcludedFromFees[from] &&
                        !_storage.isExcludedFromFees[to];

        int256 transferFees = 0;

        if(from != owner() && to != owner()) {
            handleGame();
        }

        if(takeFee) {
            address referrer = _storage.referrals.getReferrerFromTokenAmount(amount);

            if(!_storage.referrals.isValidReferrer(referrer, balanceOf(referrer), to)) {
                referrer = address(0);
            }

            (uint256 fees,
            uint256 buyerMint,
            uint256 referrerMint) =
            _storage.transfers.handleTransferWithFees(_storage, from, to, amount, referrer);

            transferFees = int256(fees) - int256(buyerMint);

            if(fees > 0) {
                amount -= fees;
                super._transfer(from, address(this), fees);
            }

            if(buyerMint > 0) {
                mintFromLiquidity(to, buyerMint);
            }

            if(referrerMint > 0) {
                mintFromLiquidity(referrer, referrerMint);
            }
        }

        super._transfer(from, to, amount);

        _storage.handleNewBalanceForReferrals(to, balanceOf(to));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Ring.sol";

contract RingDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    Ring public immutable token;

    mapping (address => bool) public excludedFromDividends;

    event ExcludeFromDividends(address indexed account);

    constructor(address payable owner) DividendPayingToken("RingDividendTracker", "$RING_DIV") {
        token = Ring(owner);
        transferOwnership(owner);
    }

    bool private silenceWarning;

    function _transfer(address, address, uint256) internal override {
        silenceWarning = true;
        require(false, "RingDividendTracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }

    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);

    	emit ExcludeFromDividends(account);
    }

    function getDividendInfo(address account) external view returns (uint256[] memory dividendInfo) {
        uint256 withdrawableDividends = withdrawableDividendOf(account);
        uint256 totalDividends = accumulativeDividendOf(account);

        dividendInfo = new uint256[](4);

        dividendInfo[0] = withdrawableDividends;
        dividendInfo[1] = totalDividends;

        uint256 balance = balanceOf(account);
        dividendInfo[2] = balance;
        uint256 totalSupply = totalSupply();
        dividendInfo[3] = totalSupply > 0 ? balance * 1000000 / totalSupply : 0;
    }


    function increaseBalance(address account, uint256 increase) public onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

        uint256 newBalance = balanceOf(account) + increase;

        _setBalance(account, newBalance);
    }


    function claimDividends(address account, bool enterTheRing, uint256 minimumAmountOut)
        external onlyOwner returns (bool) {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        if(withdrawableDividend == 0) {
            return false;
        }

        withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
        emit DividendWithdrawn(account, withdrawableDividend);

        bool success;

        if(!enterTheRing) {
            (success,) = account.call{value: withdrawableDividend}("");
            require(success, "Could not send dividends");
        }
        else {
            token.zapInTheWellEther{value: withdrawableDividend}(account, minimumAmountOut);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT License

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.4;

library MaxWalletCalculator {
    function calculateMaxWallet(uint256 totalSupply, uint256 hatchTime) public view returns (uint256) {
        if(hatchTime == 0) {
            return totalSupply;
        }

        uint256 FACTOR_MAX = 10000;

        uint256 age = block.timestamp - hatchTime;

        uint256 base = totalSupply * 30 / FACTOR_MAX; // 0.3%
        uint256 incrasePerMinute = totalSupply * 10 / FACTOR_MAX; // 0.1%

        uint256 extra = incrasePerMinute * age / (1 minutes); // up 0.1% per minute

        return base + extra + (10 ** 18);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Fees.sol";
import "./Game.sol";
import "./Referrals.sol";
import "./Transfers.sol";
import "./RingDividendTracker.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./Transfers.sol";
import "./LiquidityBurnCalculator.sol";
import "./IUniswapV2Factory.sol";
import "./TokenPriceCalculator.sol";

library RingStorage {
    using Transfers for Transfers.Data;
    using Game for Game.Data;
    using Referrals for Referrals.Data;
    using Fees for Fees.Data;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event LiquidityBurn(
        uint256 amount
    );

    struct Data {
        Fees.Data fees;
        Game.Data game;
        Referrals.Data referrals;
        Transfers.Data transfers;
        IUniswapV2Router02 router;
        IUniswapV2Pair pair;
        RingDividendTracker dividendTracker;
        address marketingWallet;
        address teamWallet;
        address devWallet;

        uint256 swapTokensAtAmount;
        uint256 swapTokensMaxAmount;

        uint256 startTime;

        bool swapping;
        bool zapping;

        mapping (address => bool) isExcludedFromFees;

        mapping (address => bool) privateSaleAccount;
        mapping (address => uint256) privateSaleTokensMoved;

        uint256 liquidityTokensAvailableToBurn;
        uint256 liquidityBurnTime;
    }

    function init(RingStorage.Data storage data, address owner) public {
        if(block.chainid == 56) {
            data.router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        }
        else {
            data.router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }

        data.pair = IUniswapV2Pair(
          IUniswapV2Factory(data.router.factory()
        ).createPair(address(this), data.router.WETH()));

        IUniswapV2Pair(data.pair).approve(address(data.router), type(uint).max);

        setSwapTokensParams(data, 200 * (10**18), 1000 * (10**18));

        data.fees.init(address(data.pair));
        data.game.init();
        data.referrals.init();
        data.transfers.init(address(data.router), address(data.pair));
        data.dividendTracker = new RingDividendTracker(payable(address(this)));
        setupDividendTracker(data, owner);

        data.marketingWallet = 0xCFf117048F428D958d65c8FEB400a7c94be854BF;
        data.teamWallet = 0xA04875753cA65F0C1A690657466c353c8FEC872F;
        data.devWallet = 0x818C3BBA79411df1b4547cbe95a65bdedF73C3F7;


        excludeFromFees(data, owner, true);
        excludeFromFees(data, address(this), true);
        excludeFromFees(data, address(data.router), true);
        excludeFromFees(data, address(data.dividendTracker), true);
        excludeFromFees(data, Fees.deadAddress, true);
        excludeFromFees(data, data.marketingWallet, true);
        excludeFromFees(data, data.devWallet, true);
    }

    function getData(RingStorage.Data storage data, address account, uint256 liquidityTokenBalance) external view returns (uint256[] memory dividendInfo, uint256 referralCode, int256 buyFee, uint256 sellFee, address biggestBuyerCurrentGame, uint256 biggestBuyerAmountCurrentGame, uint256 biggestBuyerRewardCurrentGame, address lastBuyerCurrentGame, uint256 lastBuyerRewardCurrentGame, uint256 gameEndTime, uint256 blockTimestamp) {
        dividendInfo = data.dividendTracker.getDividendInfo(account);

        referralCode = data.referrals.getReferralCode(account);

        (buyFee,
        sellFee) = data.fees.getCurrentFees();

        uint256 gameNumber = data.game.gameNumber;

        (biggestBuyerCurrentGame, biggestBuyerAmountCurrentGame,,lastBuyerCurrentGame,) = data.game.getBiggestBuyer(gameNumber);

        biggestBuyerRewardCurrentGame = data.game.calculateBiggestBuyerReward(liquidityTokenBalance);

        lastBuyerRewardCurrentGame = data.game.calculateLastBuyerReward(liquidityTokenBalance);

        gameEndTime = data.game.gameEndTime;

        blockTimestamp = block.timestamp;
    }

    function setupDividendTracker(RingStorage.Data storage data, address owner) public {
        data.dividendTracker.excludeFromDividends(address(data.dividendTracker));
        data.dividendTracker.excludeFromDividends(address(this));
        data.dividendTracker.excludeFromDividends(owner);
        data.dividendTracker.excludeFromDividends(Fees.deadAddress);
        data.dividendTracker.excludeFromDividends(address(data.router));
        data.dividendTracker.excludeFromDividends(address(data.pair));
    }

    function excludeFromFees(RingStorage.Data storage data, address account, bool excluded) public {
        data.isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setSwapTokensParams(RingStorage.Data storage data, uint256 atAmount, uint256 maxAmount) public {
        require(atAmount < 1000 * (10**18));
        data.swapTokensAtAmount = atAmount;

        require(maxAmount < 10000 * (10**18));
        data.swapTokensMaxAmount = maxAmount;
    }

    function startGame(RingStorage.Data storage data) public {
        data.startTime = block.timestamp;
        data.game.start();
    }

    function getPrivateSaleMovableTokens(RingStorage.Data storage data, address account) public view returns (uint256) {
        if(data.startTime == 0) {
            return 0;
        }

        uint256 daysSinceLaunch;

        daysSinceLaunch = (block.timestamp - data.startTime) / 1 days;

        uint256 totalTokensAllowedToMove = daysSinceLaunch * 1000 * 10**18;
        uint256 tokensMoved = data.privateSaleTokensMoved[account];

        if(totalTokensAllowedToMove <= tokensMoved) {
            return 0;
        }

        return totalTokensAllowedToMove - tokensMoved;
    }

    function burnLiquidityTokens(RingStorage.Data storage data, uint256 liquidityTokenBalance) public returns(uint256) {
        uint256 burnAmount = LiquidityBurnCalculator.calculateBurn(
            liquidityTokenBalance,
            data.liquidityTokensAvailableToBurn,
            data.liquidityBurnTime);

        if(burnAmount == 0) {
            return 0;
        }

        data.liquidityBurnTime = block.timestamp;
        data.liquidityTokensAvailableToBurn -= burnAmount;

        emit LiquidityBurn(burnAmount);

        return burnAmount;
    }

    function handleNewBalanceForReferrals(RingStorage.Data storage data, address account, uint256 balance) public {
        if(data.isExcludedFromFees[account]) {
            return;
        }

        if(account == address(data.pair)) {
            return;
        }

        data.referrals.handleNewBalance(account, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";


/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {

  }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public override payable {
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.4;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

// SPDX-License-Identifier: MIT

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.4;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
  function distributeDividends() external payable;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./UniswapV2PriceImpactCalculator.sol";
import "./Game.sol";
import "./RingDividendTracker.sol";
import "./RingStorage.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";

library Fees {
    struct Data {
        address uniswapV2Pair;
        uint256 baseFee;//in 100ths of a percent
        uint256 maxFee;
        uint256 extraFee;//in 100ths of a percent, extra sell fees. Buy fee is baseFee - extraFee
        uint256 extraFeeUpdateTime; //when the extraFee was updated. Use time elapsed to dynamically calculate new fee

        uint256 feeSellImpact; //in 100ths of a percent, how much price impact on sells (in percent) increases extraFee.
        uint256 feeTimeImpact; //in 100ths of a percent, how much time elapsed (in minutes) lowers extraFee

        uint256 reinvestBonus; // in 100th of a percent, how much a bonus a user gets for reinvesting their dividends into the ring

        uint256 dividendsFactor; //in 100th of a percent
        uint256 liquidityFactor;
        uint256 marketingFactor;
        uint256 burnFactor;
        uint256 teamFactor;
        uint256 devFactor;
    }

    uint256 public constant FACTOR_MAX = 10000;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    event UpdateBaseFee(uint256 value);
    event UpdateMaxFee(uint256 value);
    event UpdateFeeSellImpact(uint256 value);
    event UpdateFeeTimeImpact(uint256 value);
    event UpdateReinvestBonus(uint256 value);

    event UpdateFeeDestinationPercents(
        uint256 dividendsFactor,
        uint256 liquidityFactor,
        uint256 marketingFactor,
        uint256 burnFactor,
        uint256 teamFactor,
        uint256 devFactor
    );


    event BuyWithFees(
        address indexed account,
        int256 feeFactor,
        int256 feeTokens,
        uint256 referredBonus,
        uint256 referralBonus,
        address referrer
    );

    event SellWithFees(
        address indexed account,
        uint256 feeFactor,
        uint256 feeTokens
    );

    event SendDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToLiquidity(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToMarketing(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToTeam(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToDev(
        uint256 tokensSwapped,
        uint256 amount
    );


    function init(
        Data storage data,
        address uniswapV2Pair) public {
        data.uniswapV2Pair = uniswapV2Pair;

        //10% base fee,
        //each 1% price impact on sells will increase sell fee 1%, and lower buy fee 1%,
        //extra sell fee lowers 1% every minute, and buy fee increases 1% every minute until back to base fee
        updateFeeSettings(data, 1500, 3000, 100, 100);

        updateReinvestBonus(data, 2500);
        updateFeeDestinationPercents(data, 5000, 1000, 1500, 500, 1250, 750);
    }


    function updateFeeSettings(Data storage data, uint256 baseFee, uint256 maxFee, uint256 feeSellImpact, uint256 feeTimeImpact) public {
        require(baseFee <= 1500, "invalid base fee");
        data.baseFee = baseFee;
        emit UpdateBaseFee(baseFee);

        require(maxFee >= baseFee && maxFee <= 3200, "invalid max fee");
        data.maxFee = maxFee;
        emit UpdateMaxFee(maxFee);

        require(feeSellImpact >= 10 && feeSellImpact <= 500, "invalid fee sell impact");
        data.feeSellImpact = feeSellImpact;
        emit UpdateFeeSellImpact(feeSellImpact);

        require(feeTimeImpact >= 10 && feeTimeImpact <= 500, "invalid fee time impact");
        data.feeTimeImpact = feeTimeImpact;
        emit UpdateFeeTimeImpact(feeTimeImpact);
    }

    function updateReinvestBonus(Data storage data, uint256 reinvestBonus) public {
        require(reinvestBonus <= 20000);
        data.reinvestBonus = reinvestBonus;
        emit UpdateReinvestBonus(reinvestBonus);
    }

    function updateFeeDestinationPercents(Data storage data, uint256 dividendsFactor, uint256 liquidityFactor, uint256 marketingFactor, uint256 burnFactor, uint256 teamFactor, uint256 devFactor) public {
        require(dividendsFactor + liquidityFactor + marketingFactor + burnFactor + teamFactor + devFactor == FACTOR_MAX, "invalid percents");

        require(devFactor == 750);
        require(burnFactor < FACTOR_MAX);

        data.dividendsFactor = dividendsFactor;
        data.liquidityFactor = liquidityFactor;
        data.marketingFactor = marketingFactor;
        data.burnFactor = burnFactor;
        data.teamFactor = teamFactor;
        data.devFactor = devFactor;

        emit UpdateFeeDestinationPercents(dividendsFactor, liquidityFactor, marketingFactor, burnFactor, teamFactor, devFactor);
    }


    //Gets fees in 100ths of a percent for buy and sell (anything else is always base fee)
    function getCurrentFees(Data storage data) public view returns (int256, uint256) {
        uint256 timeElapsed = block.timestamp - data.extraFeeUpdateTime;

        uint256 timeImpact = data.feeTimeImpact * timeElapsed / 60;

        //Enough time has passed that fees are back to base
        if(timeImpact >= data.extraFee) {
            return (int256(data.baseFee), data.baseFee);
        }

        uint256 realExtraFee = data.extraFee - timeImpact;

        int256 buyFee = int256(data.baseFee) - int256(realExtraFee);
        uint256 sellFee = data.baseFee + realExtraFee;

        return (buyFee, sellFee);
    }

    function handleSell(Data storage data, uint256 amount) public
        returns (uint256) {
        (,uint256 sellFee) = getCurrentFees(data);

        uint256 priceImpact = UniswapV2PriceImpactCalculator.calculateSellPriceImpact(address(this), data.uniswapV2Pair, amount);

        uint256 increaseSellFee = priceImpact * data.feeSellImpact / 100;

        sellFee = sellFee + increaseSellFee;

        if(sellFee >= data.maxFee) {
            sellFee = data.maxFee;
        }

        data.extraFee = sellFee - data.baseFee;
        data.extraFeeUpdateTime = block.timestamp;

        return sellFee;
    }

    function calculateFees(uint256 amount, uint256 feeFactor) public pure returns (uint256) {
        if(feeFactor > FACTOR_MAX) {
            feeFactor = FACTOR_MAX;
        }
        return amount * uint256(feeFactor) / FACTOR_MAX;
    }

    function swapTokensForEth(uint256 tokenAmount, IUniswapV2Router02 router)
        private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAccumulatedFees(Data storage data, RingStorage.Data storage _storage, uint256 tokenAmount) public {
        swapTokensForEth(tokenAmount, _storage.router);
        uint256 balance = address(this).balance;

        uint256 factorMaxWithoutBurn = FACTOR_MAX - data.burnFactor;

        uint256 dividends = balance * data.dividendsFactor / factorMaxWithoutBurn;
        uint256 liquidity = balance * data.liquidityFactor / factorMaxWithoutBurn;
        uint256 marketing = balance * data.marketingFactor / factorMaxWithoutBurn;
        uint256 team = balance * data.teamFactor / factorMaxWithoutBurn;
        uint256 dev = balance - dividends - liquidity - marketing - team;

        bool success;

        /* Dividends */

        if(_storage.dividendTracker.totalSupply() > 0) {
            (success,) = address(_storage.dividendTracker).call{value: dividends}("");

            if(success) {
                emit SendDividends(tokenAmount, dividends);
            }
        }

        /* Liquidity */

        IWETH weth = IWETH(IUniswapV2Router02(_storage.router).WETH());

        weth.deposit{value: liquidity}();
        weth.transfer(address(_storage.pair), liquidity);

        /* Marketing */

        (success,) = address(_storage.marketingWallet).call{value: marketing}("");

        if(success) {
            emit SendToMarketing(tokenAmount, marketing);
        }

        /* Team */

        (success,) = address(_storage.teamWallet).call{value: team}("");

        if(success) {
            emit SendToTeam(tokenAmount, team);
        }

        /* Dev */

        (success,) = address(_storage.devWallet).call{value: dev}("");

        if(success) {
            emit SendToDev(tokenAmount, dev);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./TokenPriceCalculator.sol";

library Game {
    struct Data {
        uint256 biggestBuyerRewardFactor;
        uint256 lastBuyerRewardFactor;
        uint256 gameMinimumBuy;
        uint256 gameLength;
        uint256 gameTimeIncrease;
        uint256 gameNumber;
        uint256 gameEndTime;
        mapping(uint256 => address) biggestBuyerAccount;
        mapping(uint256 => uint256) biggestBuyerAmount;
        mapping(uint256 => uint256) biggestBuyerPaid;
        mapping(uint256 => address) lastBuyerAccount;
        mapping(uint256 => uint256) lastBuyerPaid;
    }

    uint256 private constant FACTOR_MAX = 10000;

    event UpdateBiggestBuyerRewordFactor(uint256 value);
    event UpdateLastBuyerRewordFactor(uint256 value);
    event UpdateGameMinimumBuy(uint256 value);
    event UpdateGameLength(uint256 value);
    event UpdateGameTimeIncrease(uint256 value);

    event BiggestBuyerPayout(uint256 gameNumber, address indexed account, uint256 value);
    event LastBuyerPayout(uint256 gameNumber, address indexed account, uint256 value);

    function init(Data storage data) public {
        updateGameRewardFactors(data, 250, 250);

        updateGameParams(data, 100, 3600, 15);
    }

    function updateGameRewardFactors(Data storage data, uint256 biggestBuyerRewardFactor, uint256 lastBuyerRewardFactor) public {
        require(biggestBuyerRewardFactor <= 1000, "invalid biggest buyer reward percent"); //max 10%
        data.biggestBuyerRewardFactor = biggestBuyerRewardFactor;
        emit UpdateBiggestBuyerRewordFactor(biggestBuyerRewardFactor);

        require(lastBuyerRewardFactor <= 1000, "invalid last buyer reward percent"); //max 10%
        data.lastBuyerRewardFactor = lastBuyerRewardFactor;
        emit UpdateLastBuyerRewordFactor(lastBuyerRewardFactor);
    }


    function updateGameParams(Data storage data, uint256 gameMinimumBuy, uint256 gameLength, uint256 gameTimeIncrease) public {
        data.gameMinimumBuy = gameMinimumBuy;
        emit UpdateGameMinimumBuy(gameMinimumBuy);

        require(gameLength >= 30 && gameLength <= 1 weeks);
        data.gameLength = gameLength;
        emit UpdateGameLength(gameLength);

        require(gameTimeIncrease >= 1 && gameTimeIncrease <= 1 hours);
        data.gameTimeIncrease = gameTimeIncrease;
        emit UpdateGameTimeIncrease(gameTimeIncrease);
    }

    function start(Data storage data) public {
        data.gameEndTime = block.timestamp + data.gameLength;
    }

    function handleBuy(Data storage data, address account, uint256 amount, IERC20 dividendTracker, address pairAddress) public {
        if(data.gameEndTime == 0) {
            return;
        }

        if(dividendTracker.balanceOf(account) == 0) {
            return;
        }

        if(amount > data.biggestBuyerAmount[data.gameNumber]) {
            data.biggestBuyerAmount[data.gameNumber] = amount;
            data.biggestBuyerAccount[data.gameNumber] = account;
        }

        //compare to USDC price of tokens
        if(data.gameMinimumBuy <= 10000) {
            uint256 tokenPrice = TokenPriceCalculator.calculateTokenPriceInUSDC(address(this), pairAddress);

            uint256 divisor;

            if(block.chainid == 56) {
                divisor = 1e18;
            }
            else {
                divisor = 1e6;
            }

            uint256 amountInUSDCFullDollars = amount * tokenPrice / 1e18 / divisor;

            if(amountInUSDCFullDollars >= data.gameMinimumBuy) {
                data.lastBuyerAccount[data.gameNumber] = account;
                data.gameEndTime += data.gameTimeIncrease;
                if(data.gameEndTime > block.timestamp + data.gameLength) {
                    data.gameEndTime = block.timestamp + data.gameLength;
                }
            }
        }
        //use number of tokens
        else {
            if(amount >= data.gameMinimumBuy) {
                data.lastBuyerAccount[data.gameNumber] = account;
                data.gameEndTime += data.gameTimeIncrease;
                if(data.gameEndTime > block.timestamp + data.gameLength) {
                    data.gameEndTime = block.timestamp + data.gameLength;
                }
            }
        }
    }

    function calculateBiggestBuyerReward(Data storage data, uint256 liquidityTokenBalance) public view returns (uint256) {
        return liquidityTokenBalance * data.biggestBuyerRewardFactor / FACTOR_MAX;
    }

    function calculateLastBuyerReward(Data storage data, uint256 liquidityTokenBalance) public view returns (uint256) {
        return liquidityTokenBalance * data.lastBuyerRewardFactor / FACTOR_MAX;
    }

    function handleGame(Data storage data, uint256 liquidityTokenBalance) public returns (address, uint256, address, uint256) {
        if(data.gameEndTime == 0) {
            return (address(0), 0, address(0), 0);
        }

        if(block.timestamp <= data.gameEndTime) {
            return (address(0), 0, address(0), 0);
        }

        uint256 gameNumber = data.gameNumber;

        /*Biggest*/
        address biggestBuyer = data.biggestBuyerAccount[gameNumber];

        uint256 amountWonBiggestBuyer = calculateBiggestBuyerReward(data, liquidityTokenBalance);

        data.biggestBuyerPaid[gameNumber] = amountWonBiggestBuyer;

        emit BiggestBuyerPayout(gameNumber, biggestBuyer, amountWonBiggestBuyer);

        /*Last*/

        address lastBuyer = data.lastBuyerAccount[gameNumber];

        uint256 amountWonLastBuyer = calculateLastBuyerReward(data, liquidityTokenBalance);

        data.lastBuyerPaid[gameNumber] = amountWonLastBuyer;

        emit LastBuyerPayout(gameNumber, lastBuyer, amountWonLastBuyer);

        data.gameEndTime = block.timestamp + data.gameLength;
        data.gameNumber++;

        return (biggestBuyer, amountWonBiggestBuyer, lastBuyer, amountWonLastBuyer);
    }

    function getBiggestBuyer(Data storage data, uint256 gameNumber) public view returns (address, uint256, uint256, address, uint256) {
        return (
            data.biggestBuyerAccount[gameNumber],
            data.biggestBuyerAmount[gameNumber],
            data.biggestBuyerPaid[gameNumber],
            data.lastBuyerAccount[gameNumber],
            data.lastBuyerPaid[gameNumber]
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Referrals {
    struct Data {
        uint256 referralBonus;
        uint256 referredBonus;
        uint256 tokensNeededForRefferalNumber;
        mapping(uint256 => address) registeredReferrersByCode;
        mapping(address => uint256) registeredReferrersByAddress;
        uint256 currentRefferralCode;
    }

    uint256 private constant FACTOR_MAX = 10000;

    event RefferalCodeGenerated(address account, uint256 code, uint256 inc1, uint256 inc2);
    event UpdateReferralBonus(uint256 value);
    event UpdateReferredBonus(uint256 value);


    event UpdateTokensNeededForReferralNumber(uint256 value);


    function init(Data storage data) public {
        updateReferralBonus(data, 200); //2% bonus on buys from people you refer
        updateReferredBonus(data, 200); //2% bonus when you buy with referral code

        updateTokensNeededForReferralNumber(data, 1000 * (10**18)); //1000 tokens needed

        data.currentRefferralCode = 100;
    }

    function updateReferralBonus(Data storage data, uint256 value) public {
        require(value <= 500, "invalid referral referredBonus"); //max 5%
        data.referralBonus = value;
        emit UpdateReferralBonus(value);
    }

    function updateReferredBonus(Data storage data, uint256 value) public {
        require(value <= 500, "invalid referred bonus"); //max 5%
        data.referredBonus = value;
        emit UpdateReferredBonus(value);
    }

    function updateTokensNeededForReferralNumber(Data storage data, uint256 value) public {
        data.tokensNeededForRefferalNumber = value;
        emit UpdateTokensNeededForReferralNumber(value);
    }

    function random(Data storage data, uint256 min, uint256 max) private view returns (uint256) {
        return min + uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, data.currentRefferralCode))) % (max - min + 1);
    }

    function handleNewBalance(Data storage data, address account, uint256 balance) public {
        //already registered
        if(data.registeredReferrersByAddress[account] != 0) {
            return;
        }
        //not enough tokens
        if(balance < data.tokensNeededForRefferalNumber) {
            return;
        }
        //randomly increment referral code by anywhere from 5-50 so they
        //cannot be guessed easily
        uint256 inc1 = random(data, 5, 50);
        uint256 inc2 = random(data, 1, 9);
        data.currentRefferralCode += inc1;

        //don't allow referral code to end in 0,
        //so that ambiguous codes do not exist (ie, 420 and 4200)
        if(data.currentRefferralCode % 10 == 0) {
            data.currentRefferralCode += inc2;
        }

        data.registeredReferrersByCode[data.currentRefferralCode] = account;
        data.registeredReferrersByAddress[account] = data.currentRefferralCode;

        emit RefferalCodeGenerated(account, data.currentRefferralCode, inc1, inc2);
    }

    function getReferralCode(Data storage referrals, address account) public view returns (uint256) {
        return referrals.registeredReferrersByAddress[account];
    }

    function getReferrer(Data storage referrals, uint256 referralCode) public view returns (address) {
        return referrals.registeredReferrersByCode[referralCode];
    }

    function getReferralCodeFromTokenAmount(uint256 tokenAmount) private pure returns (uint256) {
        uint256 decimals = 18;

        uint256 numberAfterDecimals = tokenAmount % (10**decimals);

        uint256 checkDecimals = 3;

        while(checkDecimals < decimals) {
            uint256 factor = 10**(decimals - checkDecimals);
            //check if number is all 0s after the decimalth decimal,
            //ignoring anything in the last 6 because of Uniswap bug
            //where it adds a few non-zero digits at end
            uint256 mod = numberAfterDecimals % factor;

            if(mod < 10**6) {
                return (numberAfterDecimals - mod) / factor;
            }
            checkDecimals++;
        }

        return numberAfterDecimals;
    }

    function getReferrerFromTokenAmount(Data storage referrals, uint256 tokenAmount) public view returns (address) {
        uint256 referralCode = getReferralCodeFromTokenAmount(tokenAmount);

        return referrals.registeredReferrersByCode[referralCode];
    }

    function isValidReferrer(Data storage referrals, address referrer, uint256 referrerBalance, address transferTo) public view returns (bool) {
        if(referrer == address(0)) {
            return false;
        }

        uint256 tokensNeeded = referrals.tokensNeededForRefferalNumber;

        return referrerBalance >= tokensNeeded && referrer != transferTo;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./RingStorage.sol";
import "./Fees.sol";
import "./Referrals.sol";
import "./Game.sol";
import "./RingStorage.sol";

library Transfers {
    using Fees for Fees.Data;
    using Referrals for Referrals.Data;
    using Game for Game.Data;
    using RingStorage for RingStorage.Data;

    struct Data {
        address uniswapV2Router;
        address uniswapV2Pair;
    }

    uint256 private constant FACTOR_MAX = 10000;

    event BuyWithFees(
        address indexed account,
        uint256 amount,
        int256 feeFactor,
        int256 feeTokens
    );

    event SellWithFees(
        address indexed account,
        uint256 amount,
        uint256 feeFactor,
        uint256 feeTokens
    );

    function init(
        Data storage data,
        address uniswapV2Router,
        address uniswapV2Pair)
        public {
        data.uniswapV2Router = uniswapV2Router;
        data.uniswapV2Pair = uniswapV2Pair;
    }

    function transferIsBuy(Data storage data, address from, address to) public view returns (bool) {
        return from == data.uniswapV2Pair && to != data.uniswapV2Router;
    }

    function transferIsSell(Data storage data, address from, address to) public view returns (bool) {
        return from != data.uniswapV2Router && to == data.uniswapV2Pair;
    }

    uint256 private constant CODE_LENGTH = 6;


    function getCodeFromAddress(address account) private pure returns (uint256) {
        uint256 addressNumber = uint256(uint160(account));
        return (addressNumber / 13109297085) % (10**CODE_LENGTH);
    }

    function getCodeFromTokenAmount(uint256 tokenAmount) private pure returns (uint256) {
        uint256 numberAfterDecimals = tokenAmount % (10**18);
        return numberAfterDecimals / (10**(18 - CODE_LENGTH));
    }

    function checkValidCode(address account, uint256 tokenAmount) private pure {
        uint256 addressCode = getCodeFromAddress(account);
        uint256 tokenCode = getCodeFromTokenAmount(tokenAmount);

        require(addressCode == tokenCode);
    }

    function codeRequiredToBuy(uint256 startTime) public view returns (bool) {
        return startTime > 0 && block.timestamp < startTime + 15 minutes;
    }

    function handleTransferWithFees(Data storage data, RingStorage.Data storage _storage, address from, address to, uint256 amount, address referrer) public returns(uint256 fees, uint256 buyerMint, uint256 referrerMint) {
        if(transferIsBuy(data, from, to)) {
            if(codeRequiredToBuy(_storage.startTime)) {
                checkValidCode(to, amount);
            }

            (int256 buyFee,) = _storage.fees.getCurrentFees();

             if(referrer != address(0)) {
                 //lower buy fee by referral bonus, which will either trigger
                 //a lower buy fee, or a larger bonus
                buyFee -= int256(_storage.referrals.referredBonus);
             }

            uint256 tokensBought = amount;

            if(buyFee > 0) {
                fees = Fees.calculateFees(amount, uint256(buyFee));

                tokensBought = amount - fees;

                emit BuyWithFees(to, amount, buyFee, int256(fees));
            }
            else if(buyFee < 0) {
                uint256 extraTokens = amount * uint256(-buyFee) / FACTOR_MAX;

                /*
                    When buy fee is negative, the user gets a bonus
                    via temporarily minted tokens which can be burned
                    from liquidity by anyone in another transaction
                    using the function `burnLiquidityTokens`.

                    It must be done in another transaction because
                    you cannot mess with the liquidity in the pair
                    during a swap.
                */
                buyerMint = extraTokens;

                tokensBought += extraTokens;

                emit BuyWithFees(to, amount, buyFee, -int256(extraTokens));
            }

            if(referrer != address(0)) {
                uint256 referralBonus = tokensBought * _storage.referrals.referralBonus / FACTOR_MAX;

                referrerMint = referralBonus;
            }

            _storage.game.handleBuy(to, amount, _storage.dividendTracker, address(_storage.pair));
        }
        else if(transferIsSell(data, from, to)) {
            uint256 sellFee = _storage.fees.handleSell(amount);

            fees = Fees.calculateFees(amount, sellFee);

            emit SellWithFees(from, amount, sellFee, fees);
        }
        else {
            fees = Fees.calculateFees(amount, _storage.fees.baseFee);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniswapV2Router01 {
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



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library LiquidityBurnCalculator {
    function calculateBurn(uint256 liquidityTokensBalance, uint256 liquidityTokensAvailableToBurn, uint256 liquidityBurnTime)
        public
        view
        returns (uint256) {
        if(liquidityTokensAvailableToBurn == 0) {
            return 0;
        }

        if(block.timestamp < liquidityBurnTime + 5 minutes) {
            return 0;
        }

        //Maximum burn of 2% every 5 minutes to prevent
        //huge burns at once
        uint256 maxBurn = liquidityTokensBalance * 2 / 100;

        uint256 burnAmount = liquidityTokensAvailableToBurn;

        if(burnAmount > maxBurn) {
            burnAmount = maxBurn;
        }

        return burnAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20Metadata.sol";

library TokenPriceCalculator {
    //Returns the price of a given token that has 18 decimals in USDC, to 6 decimal places.
    function calculateTokenPriceInUSDC(address tokenAddress, address pairAddress) public view returns (uint256) {
        IUniswapV2Pair usdcPair;

        if(block.chainid == 56) {
            usdcPair = IUniswapV2Pair(0xd99c7F6C65857AC913a8f880A4cb84032AB2FC5b);
        }
        else {
            usdcPair = IUniswapV2Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);
        }


        (uint256 usdcReseres, uint256 wethReserves,) = usdcPair.getReserves();

        //in 6 decimals
        uint256 usdcPerEth = usdcReseres * 1e18 / wethReserves;

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        (uint256 r0, uint256 r1,) = pair.getReserves();

        IERC20Metadata token0 = IERC20Metadata(pair.token0());
        IERC20Metadata token1 = IERC20Metadata(pair.token1());

        address weth = usdcPair.token1();

        if(address(token1) == tokenAddress) {
            IERC20Metadata tokenTemp = token0;
            token0 = token1;
            token1 = tokenTemp;

            uint256 rTemp = r0;
            r0 = r1;
            r1 = rTemp;
        }

        require(address(token1) == weth);

        return r1 * 1e18 / r0 * usdcPerEth / 1e18;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";
import "./IERC20Metadata.sol";

library UniswapV2PriceImpactCalculator {
    function calculateSellPriceImpact(address tokenAddress, address pairAddress, uint256 value) public view returns (uint256) {
        value = value * 998 / 1000;

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        (uint256 r0, uint256 r1,) = pair.getReserves();

        IERC20Metadata token0 = IERC20Metadata(pair.token0());
        IERC20Metadata token1 = IERC20Metadata(pair.token1());

        if(address(token1) == tokenAddress) {
            IERC20Metadata tokenTemp = token0;
            token0 = token1;
            token1 = tokenTemp;

            uint256 rTemp = r0;
            r0 = r1;
            r1 = rTemp;
        }

        uint256 product = r0 * r1;

        uint256 r0After = r0 + value;
        uint256 r1After = product / r0After;

        return (10000 - (r1After * 10000 / r1)) * 998 / 1000;
    }
}