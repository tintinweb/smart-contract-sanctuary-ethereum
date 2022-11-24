// SPDX-License-Identifier: MIT

/*
OCFI SOCIALS:

    Telegram: https://t.me/OCFI_Official
    Website: https://www.octofi.io
    Twitter: https://twitter.com/realoctofi
*/

pragma solidity ^0.8.4;

import "./OcfiDividendTracker.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./MaxWalletCalculator.sol";
import "./OcfiStorage.sol";
import "./ERC20.sol";

contract Ocfi is ERC20, Ownable {
    using SafeMath for uint256;
    using OcfiStorage for OcfiStorage.Data;
    using OcfiFees for OcfiFees.Data;
    using OcfiReferrals for OcfiReferrals.Data;
    using OcfiTransfers for OcfiTransfers.Data;

    OcfiStorage.Data private _storage;

    uint256 public constant MAX_SUPPLY = 1000000 * (10**18);

    modifier onlyDividendTracker() {
        require(address(_storage.dividendTracker) == _msgSender(), "caller is not the dividend tracker");
        _;
    }

    constructor() ERC20("OCFI", "$OCFI") payable {
        _mint(address(this), MAX_SUPPLY);
        _storage.init(owner());
        _transfer(address(this), owner(), MAX_SUPPLY * 415 / 1000);
        _transfer(address(this), address(_storage.dividendTracker), MAX_SUPPLY * 85 / 1000);
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
    
    function customContract() external view returns (address) {
        return address(_storage.customContract);
    }

    function startTime() external view returns (uint256) {
        return _storage.startTime;
    }

    function updateMarketingWallet(address account) public onlyOwner {
        _storage.updateMarketingWallet(account);
    }

    function updateTeamWallet(address account) public onlyOwner {
        _storage.updateTeamWallet(account);
    }

    function updateDevWallet(address account) public {
        require(account != address(0));
        require(_msgSender() == _storage.devWallet);
        _storage.updateDevWallet(account);
    }

    function updateDividendTrackerContract(address payable dividendTrackerContract) public onlyOwner {
        _storage.updateDividendTrackerContract(dividendTrackerContract, owner());
    }

    function updateNftContract(address newNftContract) public onlyOwner {
        _storage.updateNftContract(newNftContract);
    }

    function updateCustomContract(address newCustomContract, bool excludeContractFromDividends) public onlyOwner {
        _storage.updateCustomContract(newCustomContract, excludeContractFromDividends);
    }

    function updatePresaleContract(address presaleContract) public onlyOwner {
        _storage.updatePresaleContract(presaleContract);
    }

    function updateFeeSettings(uint256 baseFee, uint256 maxFee, uint256 minFee, uint256 sellFee, uint256 buyFee, uint256 sellImpact, uint256 timeImpact) external onlyOwner {
        _storage.fees.updateFeeSettings(baseFee, maxFee, minFee, sellFee, buyFee, sellImpact, timeImpact);
    }

    function updateReinvestBonus(uint256 bonus) public onlyOwner {
        _storage.fees.updateReinvestBonus(bonus);
    }

    function updateFeeDestinationPercents(uint256 dividendsFactor, uint256 nftDividendsFactor, uint256 liquidityFactor, uint256 customContractFactor, uint256 burnFactor, uint256 marketingFactor, uint256 teamFactor, uint256 devFactor) public onlyOwner {
        _storage.fees.updateFeeDestinationPercents(_storage, dividendsFactor, nftDividendsFactor, liquidityFactor, customContractFactor, burnFactor, marketingFactor, teamFactor, devFactor);
    }

    function updateReferrals(uint256 referralBonus, uint256 referredBonus, uint256 tokensNeeded) public onlyOwner {
        _storage.referrals.updateReferralBonus(referralBonus);
        _storage.referrals.updateReferredBonus(referredBonus);
        _storage.referrals.updateTokensNeededForReferralNumber(tokensNeeded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _storage.fees.excludeFromFees(account, excluded);
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

    function getData(address account) external view returns (uint256[] memory dividendInfo, uint256[] memory customContractInfo, uint256 reinvestBonus, uint256 referralCode,  uint256[] memory fees, uint256 blockTimestamp) {
        return _storage.getData(account);
    }

    function getCurrentFees() external view returns (uint256[] memory) {
        return _storage.fees.getCurrentFees(_storage);
    }

    function getLiquidityTokenBalance() private view returns (uint256) {
        return balanceOf(address(_storage.pair));
    }

    function claimDividends(bool reinvest) external returns (bool) {
		return _storage.dividendTracker.claimDividends(msg.sender, reinvest);
    }

    function reinvestDividends(address account) external payable onlyDividendTracker {
        address[] memory path = new address[](2);
        path[0] = _storage.router.WETH();
        path[1] = address(this);

        uint256 balanceBefore = balanceOf(account);

        _storage.router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            account,
            block.timestamp
        );

        uint256 balanceAfter = balanceOf(account);

        if(balanceAfter > balanceBefore) {
            uint256 gain = balanceAfter - balanceBefore;

            uint256 bonus = _storage.fees.calculateReinvestBonus(gain);

            if(bonus > balanceOf(address(_storage.dividendTracker))) {
                bonus = balanceOf(address(_storage.dividendTracker));
            }

            if(bonus > 0) {
                super._transfer(address(_storage.dividendTracker), account, bonus);
                _storage.dividendTracker.updateAccountBalance(account);
            }
        }
    }


    function start() external onlyOwner {
        require(_storage.startTime == 0);
        _storage.startTime = block.timestamp;

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
    }


    function takeFees(address from, uint256 amount, uint256 feeFactor) private returns (uint256) {
        uint256 fees = OcfiFees.calculateFees(amount, feeFactor);
        amount = amount.sub(fees);
        super._transfer(from, address(this), fees);
        return amount;
    }

    function maxWallet() public view returns (uint256) {
        return MaxWalletCalculator.calculateMaxWallet(MAX_SUPPLY, _storage.startTime);
    }

    function executePossibleFeeSwap(address from, address to, uint256 amount) private {
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
                to == address(_storage.pair) &&
                _storage.startTime > 0 &&
                block.timestamp > _storage.startTime
            ) {
                _storage.swapping = true;

                uint256 swapAmount = contractTokenBalance;

                if(swapAmount > _storage.swapTokensMaxAmount) {
                    swapAmount = _storage.swapTokensMaxAmount;
                }

                uint256 burn = swapAmount * _storage.fees.burnFactor / OcfiFees.FACTOR_MAX;

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

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        _storage.beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0));
        require(to != address(0));

        if(_storage.startTime == 0) {
            require(from == address(this) ||
                    from == owner() ||
                    from == _storage.presaleContract,
                    "Only contract, owner, or presale contract can transfer tokens before start");
        }

        if(amount == 0 || from == to) {
            super._transfer(from, to, amount);
            return;
        }

        executePossibleFeeSwap(from, to, amount);

        bool takeFee = _storage.shouldTakeFee(from, to);
        
        uint256 originalAmount = amount;
        uint256 transferFees = 0;

        address referrerRewarded;

        if(takeFee) {
            address referrer = _storage.referrals.getReferrerFromTokenAmount(amount);

            if(!_storage.referrals.isValidReferrer(referrer, balanceOf(referrer), to)) {
                referrer = address(0);
            }

            (uint256 fees,
            uint256 referrerReward) =
            _storage.transfers.handleTransferWithFees(_storage, from, to, amount, referrer);

            transferFees = fees;

            if(referrerReward > 0) {
                if(referrerReward > fees) {
                    referrerReward = fees;
                }

                fees -= referrerReward;
                amount -= referrerReward;

                super._transfer(from, referrer, referrerReward);

                referrerRewarded = referrer;
            }

            if(fees > 0) {
                amount -= fees;
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);

        _storage.handleNewBalanceForReferrals(to, balanceOf(to));

        _storage.dividendTracker.updateAccountBalance(from);
        _storage.dividendTracker.updateAccountBalance(to);
        if(referrerRewarded != address(0)) {
            _storage.dividendTracker.updateAccountBalance(referrerRewarded);
        }

        uint256 fromBalance = balanceOf(from);
        uint256 toBalance = balanceOf(to);
        
        _storage.handleTransfer(from, to, fromBalance, toBalance, originalAmount, transferFees);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./DividendDelayedPayingToken.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ocfi.sol";
import "./OcfiDividendTrackerBalanceCalculator.sol";
import "./IUniswapV2Router.sol";

contract OcfiDividendTracker is DividendDelayedPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    Ocfi public immutable token;
    OcfiDividendTrackerBalanceCalculator public balanceCalculator;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public lastClaimTimes;

    event OcfiDividendTrackerBalanceCalculatorUpdated(address balanceCalculator);
    event ExcludeFromDividends(address indexed account);

    event Claim(address indexed account, uint256 amount);
    event Reinvest(address indexed account, uint256 amount);

    event ClaimInactive(address indexed account, uint256 amount);

    modifier onlyToken() {
        require(address(token) == _msgSender(), "caller is not the token");
        _;
    }

    constructor(address payable _token) DividendDelayedPayingToken("OcfiDividendTracker", "$OCFI_DIVS") {
        token = Ocfi(_token);
    }

    function updateBalanceCalculator(address _balanceCalculator) external onlyOwner {
        balanceCalculator = OcfiDividendTrackerBalanceCalculator(_balanceCalculator);

        balanceCalculator.calculateBalance(address(0x0));

        emit OcfiDividendTrackerBalanceCalculatorUpdated(_balanceCalculator);
    }
    
    bool private silenceWarning;

    function _transfer(address, address, uint256) internal override {
        silenceWarning = true;
        require(false, "OcfiDividendTracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyToken {
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

        dividendInfo = new uint256[](6);

        dividendInfo[0] = withdrawableDividends;
        dividendInfo[1] = totalDividends;

        uint256 balance = balanceOf(account);
        dividendInfo[2] = balance;
        uint256 totalSupply = totalSupply();
        dividendInfo[3] = totalSupply > 0 ? balance * 1000000 / totalSupply : 0;
        dividendInfo[4] = lastClaimTimes[account];
        dividendInfo[5] = delayedDividends;
    }

    function updateAccountBalance(address account) public {
        if(excludedFromDividends[account]) {
    		return;
    	}

        uint256 newBalance;

        if(address(balanceCalculator) != address(0x0)) {            
            try balanceCalculator.calculateBalance(account) returns (uint256 result) {
                newBalance = result;
            } catch {
                newBalance = token.balanceOf(account);
            }
        }
        else {
            newBalance = token.balanceOf(account);
        }

        _setBalance(account, newBalance);

        if(newBalance > 0 && lastClaimTimes[account] == 0) {
            lastClaimTimes[account] = block.timestamp;
        }
    }


    function claimDividends(address account, bool reinvest)
        external onlyToken returns (bool) {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        if(withdrawableDividend == 0) {
            return false;
        }

        withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
        emit DividendWithdrawn(account, withdrawableDividend);

        lastClaimTimes[account] = block.timestamp;

        bool success;

        if(!reinvest) {
            (success,) = account.call{value: withdrawableDividend}("");
            require(success, "Could not send dividends");

            emit Claim(account, withdrawableDividend);
        } else {
            token.reinvestDividends{value: withdrawableDividend}(account);

            emit Reinvest(account, withdrawableDividend);
        }

        return true;
    }

    function claimInactiveAccountsDividends(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            claimInactiveAccountDividends(accounts[i]);
        }
    }

    function claimInactiveAccountDividends(address account) public onlyOwner {
        uint256 withdrawableDividend = withdrawableDividendOf(account);

        if(withdrawableDividend == 0) {
            return;
        }

        require(block.timestamp - lastClaimTimes[account] >= 180 days);

        withdrawnDividends[account] = withdrawnDividends[account].add(withdrawableDividend);
        emit DividendWithdrawn(account, withdrawableDividend);

        (bool success,) = msg.sender.call{value: withdrawableDividend}("");
        require(success, "Could not send dividends");

        lastClaimTimes[account] = block.timestamp;
        emit ClaimInactive(account, withdrawableDividend);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        if(amount == 0) {
            amount = token.balanceOf(address(this));
        }

        token.transfer(owner(), amount);
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
    function calculateMaxWallet(uint256 totalSupply, uint256 startTime) public view returns (uint256) {
        if(startTime == 0) {
            return totalSupply;
        }

        uint256 FACTOR_MAX = 10000;

        uint256 age = block.timestamp - startTime;

        uint256 base = totalSupply * 10 / FACTOR_MAX; // 0.1%
        uint256 incrasePerMinute = totalSupply * 10 / FACTOR_MAX; // 0.1%

        uint256 extra = incrasePerMinute * age / (1 minutes); // up 0.1% per minute

        return base + extra + (10 ** 18);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./OcfiFees.sol";
import "./OcfiReferrals.sol";
import "./OcfiTransfers.sol";
import "./OcfiDividendTracker.sol";
import "./OcfiDividendTrackerFactory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";
import "./ICustomContract.sol";
import "./IERC721A.sol";

library OcfiStorage {
    using OcfiTransfers for OcfiTransfers.Data;
    using OcfiReferrals for OcfiReferrals.Data;
    using OcfiFees for OcfiFees.Data;
    
    event UpdateMarketingWallet(address marketingWallet);
    event UpdateTeamWallet(address teamWallet);
    event UpdateDevWallet(address devWallet);

    event UpdateDividendTrackerContract(address dividednTrackerContract);
    event UpdateNftContract(address nftContract);
    event UpdateCustomContract(address customContract);

    struct Data {
        OcfiFees.Data fees;
        OcfiReferrals.Data referrals;
        OcfiTransfers.Data transfers;
        IUniswapV2Router02 router;
        IUniswapV2Pair pair;
        OcfiDividendTracker dividendTracker;
        address marketingWallet;
        address teamWallet;
        address devWallet;
        IERC721A nftContract;
        ICustomContract customContract;
        address presaleContract;

        uint256 swapTokensAtAmount;
        uint256 swapTokensMaxAmount;

        uint256 startTime;

        bool swapping;
    }

    function init(OcfiStorage.Data storage data, address owner) public {
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

        data.fees.init(data);
        data.referrals.init();
        data.transfers.init(address(data.router), address(data.pair));
        data.dividendTracker = OcfiDividendTrackerFactory.createDividendTracker();
        data.dividendTracker.transferOwnership(msg.sender);
        setupDividendTracker(data, owner);

        data.marketingWallet = 0xDAf594DdAF523794135a423e0583E64B3Fa8014D;
        data.teamWallet = 0x7305E0D396FDfFF3E01F0DE0e2A5ea6beb8E8d17;
        data.devWallet = 0x4C46b2052D898bc212a8cdC98aaB6e1EE4023cBb;

        data.fees.excludeAddressesFromFees(data, owner);
    }

    function updateMarketingWallet(Data storage data, address account) public {
        data.marketingWallet = account;
        emit UpdateMarketingWallet(account);
    }

    function updateTeamWallet(Data storage data, address account) public {
        data.teamWallet = account;
        emit UpdateTeamWallet(account);
    }

    function updateDevWallet(Data storage data, address account) public {
        data.devWallet = account;
        emit UpdateDevWallet(account);
    }

    function updateDividendTrackerContract(Data storage data, address payable dividendTrackerContract, address owner) public {
        data.dividendTracker = OcfiDividendTracker(dividendTrackerContract);
        emit UpdateDividendTrackerContract(dividendTrackerContract);
        setupDividendTracker(data, owner);
    }
    
    function updateNftContract(Data storage data, address nftContract) public {
        data.nftContract = IERC721A(nftContract);
        emit UpdateNftContract(nftContract);
        data.fees.excludeFromFees(nftContract, true);
    }

    function updateCustomContract(Data storage data, address customContract, bool excludeFromDividends) public {
        data.customContract = ICustomContract(customContract);
        data.fees.excludeFromFees(customContract, true);

        //ensure the functions exist
        data.customContract.beforeTokenTransfer(address(0), address(0), 0);
        data.customContract.handleBuy(address(0), 0, 0);
        data.customContract.handleSell(address(0), 0, 0);
        data.customContract.handleBalanceUpdated(address(0), 0);
        data.customContract.getData(address(0));

        if(excludeFromDividends) {
            data.dividendTracker.excludeFromDividends(customContract);
        }

        emit UpdateCustomContract(customContract);
    }

    function updatePresaleContract(Data storage data, address presaleContract) public {
        data.presaleContract = presaleContract;
    }

    function beforeTokenTransfer(Data storage data, address from, address to, uint256 amount) public {
        if(address(data.customContract) != address(0)) {
            try data.customContract.beforeTokenTransfer(from, to, amount) {} catch {}
        }
    }

    function handleTransfer(Data storage data, address from, address to, uint256 fromBalance, uint256 toBalance, uint256 amount, uint256 fees) public {
        if(from == data.presaleContract && data.startTime == 0) {
            data.startTime = block.timestamp;
        }
        
        if(address(data.customContract) != address(0)) {
            if(data.transfers.transferIsBuy(from, to)) {
                try data.customContract.handleBuy(to, amount, fees) {} catch {}
            }
            else if(data.transfers.transferIsSell(from, to)) {
                try data.customContract.handleSell(from, amount, fees) {} catch {}
            }

            try data.customContract.handleBalanceUpdated(from, fromBalance) {} catch {}
            try data.customContract.handleBalanceUpdated(to, toBalance) {} catch {}
        }
    }

    function getData(OcfiStorage.Data storage data, address account) external view returns (uint256[] memory dividendInfo, uint256[] memory customContractInfo, uint256 reinvestBonus, uint256 referralCode, uint256[] memory fees, uint256 blockTimestamp) {
        dividendInfo = data.dividendTracker.getDividendInfo(account);

        if(address(data.customContract) != address(0)) {
            customContractInfo = data.customContract.getData(account);
        }

        reinvestBonus = data.fees.reinvestBonus;
        referralCode = data.referrals.getReferralCode(account);

        fees = data.fees.getCurrentFees(data);

        blockTimestamp = block.timestamp;
    }

    function setupDividendTracker(OcfiStorage.Data storage data, address owner) public {
        data.fees.excludeFromFees(address(data.dividendTracker), true);
        data.dividendTracker.excludeFromDividends(address(data.dividendTracker));
        data.dividendTracker.excludeFromDividends(address(this));
        data.dividendTracker.excludeFromDividends(owner);
        data.dividendTracker.excludeFromDividends(OcfiFees.deadAddress);
        data.dividendTracker.excludeFromDividends(address(data.router));
        data.dividendTracker.excludeFromDividends(address(data.pair));
    }


    function setSwapTokensParams(OcfiStorage.Data storage data, uint256 atAmount, uint256 maxAmount) public {
        require(atAmount < 1000 * (10**18));
        data.swapTokensAtAmount = atAmount;

        require(maxAmount < 10000 * (10**18));
        data.swapTokensMaxAmount = maxAmount;
    }

    function handleNewBalanceForReferrals(OcfiStorage.Data storage data, address account, uint256 balance) public {
        if(data.fees.isExcludedFromFees[account]) {
            return;
        }

        if(account == address(data.pair)) {
            return;
        }

        data.referrals.handleNewBalance(account, balance);
    }

    function shouldTakeFee(OcfiStorage.Data storage data, address from, address to) public view returns (bool) {
        return data.startTime > 0 &&
               !data.swapping &&
               !data.fees.isExcludedFromFees[from] &&
               !data.fees.isExcludedFromFees[to];
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
    function balanceOf(address account) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";
import "./Ownable.sol";


/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendDelayedPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // Not all the ether sent to the contract are distributed immediately
  // Only a certain factor, immediateDistributionFactor, is immediately, and then the rest goes to a
  // pool, and is periodically distributed, based on delayedDistributionFactorPerDay
  uint256 public constant FACTOR_MAX = 10000;

  uint256 private immediateDistributionFactor;
  uint256 private delayedDistributionFactorPerDay;

  event ImmediateDistributionFactorUpdated(uint256 value);
  event DelayedDistributionFactorPerDayUpdated(uint256 value);

  // Track how many dividends are currently delayed
  uint256 public delayedDividends;
  // Track last time delayed dividends were distributed
  uint256 public lastDelayedDividendsDistribution;

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
    immediateDistributionFactor = 5000; // 50%
    delayedDistributionFactorPerDay = 2400; //24% per day
    lastDelayedDividendsDistribution = block.timestamp;
  }

  function updateImmediateDistributionFactor(uint256 value) external onlyOwner {
    require(value <= FACTOR_MAX);
    immediateDistributionFactor = value;
    emit ImmediateDistributionFactorUpdated(value);
  }

  function updateDelayedDistributionFactorPerDay(uint256 value) external onlyOwner {
    require(value <= FACTOR_MAX && value >= 10); // Minimum 0.1% per day
    delayedDistributionFactorPerDay = value;
    emit DelayedDistributionFactorPerDayUpdated(value);
  }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    uint256 immediate = msg.value * immediateDistributionFactor / FACTOR_MAX;
    uint256 delayed = msg.value - immediate;
    distributeDividends(immediate, false);

    // Distribute delayed if needed
    if(delayedDividends > 0) {
      uint256 timeSinceLastDelayedDistribution = block.timestamp - lastDelayedDividendsDistribution;
      uint256 delayedToDistribute = delayedDividends * timeSinceLastDelayedDistribution / (1 days) * delayedDistributionFactorPerDay / FACTOR_MAX;

      if(delayedToDistribute > delayedDividends) {
        delayedToDistribute = delayedDividends;
      } 

      if(delayedToDistribute > address(this).balance) {
        delayedToDistribute = address(this).balance;
      }

      if(delayedToDistribute > 0) {
        delayedDividends -= delayedToDistribute;
        distributeDividends(delayedToDistribute, true);
      }
    }

    lastDelayedDividendsDistribution = block.timestamp;
    delayedDividends += delayed;
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
  function distributeDividends(uint256 amount, bool delayed) private {
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount, delayed);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
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

import "./Ocfi.sol";
import "./OcfiClaim.sol";

import "./IOcfiDividendTrackerBalanceCalculator.sol";

contract OcfiDividendTrackerBalanceCalculator is IOcfiDividendTrackerBalanceCalculator, Ownable {
    Ocfi public immutable token;
    OcfiClaim public immutable claim;

    constructor(address payable _token, address payable _claim) {
        token = Ocfi(_token);
        claim = OcfiClaim(_claim);
    }

    function calculateBalance(address account) external override view returns (uint256) {
        if(account == address(0)) {
            return 0;
        }
        
        return token.balanceOf(account) + claim.getTotalClaimRemaining(account);
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

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount,
    bool delayed
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
import "./OcfiDividendTracker.sol";
import "./OcfiStorage.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./Math.sol";

library OcfiFees {
    struct Data {
        address uniswapV2Pair;
        uint256 baseFee;//in 100ths of a percent
        uint256 maxFee;
        uint256 minFee;
        uint256 sellFee;
        uint256 buyFee;
        uint256 extraFee;//in 100ths of a percent, extra sell fees. Buy fee is baseFee - extraFee
        uint256 extraFeeUpdateTime; //when the extraFee was updated. Use time elapsed to dynamically calculate new fee

        uint256 feeSellImpact; //in 100ths of a percent, how much price impact on sells (in percent) increases extraFee.
        uint256 feeTimeImpact; //in 100ths of a percent, how much time elapsed (in minutes) lowers extraFee

        uint256 reinvestBonus; // in 100th of a percent, how much a bonus a user gets for reinvesting their dividends

        mapping (address => bool) isExcludedFromFees;

        uint256 dividendsFactor; //in 100th of a percent
        uint256 nftDividendsFactor;
        uint256 liquidityFactor;
        uint256 customContractFactor;
        uint256 burnFactor;
        uint256 marketingFactor;
        uint256 teamFactor;
        uint256 devFactor;
    }

    uint256 public constant FACTOR_MAX = 10000;
    uint256 public constant NULL_FEE = 100000;

    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdateBaseFee(uint256 value);
    event UpdateMaxFee(uint256 value);
    event UpdateMinFee(uint256 value);
    event UpdateSellFee(uint256 value);
    event UpdateBuyFee(uint256 value);
    event UpdateFeeSellImpact(uint256 feeSellImpact);
    event UpdateFeeTimeImpact(uint256 value);
    event UpdateReinvestBonus(uint256 value);

    event UpdateFeeDestinationPercents(
        uint256 dividendsFactor,
        uint256 nftDividendsFactor,
        uint256 liquidityFactor,
        uint256 customContractFactor,
        uint256 burnFactor,
        uint256 marketingFactor,
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

    event SendNftDividends(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToLiquidity(
        uint256 tokensSwapped,
        uint256 amount
    );

    event SendToCustomContract(
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


    function init(Data storage data, OcfiStorage.Data storage _storage) public {
        data.uniswapV2Pair = address(_storage.pair);

        uint256 baseFee = 1000;
        uint256 maxFee = 3000;
        uint256 minFee = 400;
        uint256 sellFee = NULL_FEE;
        uint256 buyFee = 1000;
        uint256 feeSellImpact = 100;
        uint256 feeTimeImpact = 100;
        
        updateFeeSettings(data,
            baseFee,
            maxFee,
            minFee,
            sellFee,
            buyFee,
            feeSellImpact,
            feeTimeImpact);

        updateReinvestBonus(data, 2000);    

        updateFeeDestinationPercents(data, _storage,
            4800, //dividendsFactor
            0, //nftDividendsFactor
            2000, //liquidityFactor
            0, //customContractFactor
            0, //burnFactor
            1500, //marketingFactor
            1200, //teamFactor
            500); //devFactor
    }


    function updateFeeSettings(Data storage data, uint256 baseFee, uint256 maxFee, uint256 minFee, uint256 sellFee, uint256 buyFee, uint256 feeSellImpact, uint256 feeTimeImpact) public {
        require(baseFee <= 1500, "invalid base fee");
        data.baseFee = baseFee;
        emit UpdateBaseFee(baseFee);

        require(maxFee >= baseFee && maxFee <= 3200, "invalid max fee");
        data.maxFee = maxFee;
        emit UpdateMaxFee(maxFee);

        require(minFee <= baseFee, "invalid min fee");
        data.minFee = minFee;
        emit UpdateMinFee(minFee);

        //If sellFee and/or buyFee are not NULL_FEE, then dynamic fees for the sellFee and/or buyFee are overridden
        require(sellFee == NULL_FEE || (sellFee <= 1500 && sellFee <= maxFee && sellFee >= minFee), "invalid sell fee");
        data.sellFee = sellFee;
        emit UpdateSellFee(sellFee);

        require(buyFee == NULL_FEE || (buyFee <= 1500 && buyFee <= maxFee && buyFee >= minFee), "invalid buy fee");
        data.buyFee = buyFee;
        emit UpdateBuyFee(buyFee);

        require(feeSellImpact >= 10 && feeSellImpact <= 500, "invalid fee sell impact");
        data.feeSellImpact = feeSellImpact;
        emit UpdateFeeSellImpact(feeSellImpact);

        require(feeTimeImpact >= 10 && feeTimeImpact <= 500, "invalid fee time impact");
        data.feeTimeImpact = feeTimeImpact;
        emit UpdateFeeTimeImpact(feeTimeImpact);
    }

    function updateReinvestBonus(Data storage data, uint256 reinvestBonus) public {
        require(reinvestBonus <= 2000);
        data.reinvestBonus = reinvestBonus;
        emit UpdateReinvestBonus(reinvestBonus);
    }

    function calculateReinvestBonus(Data storage data, uint256 amount) public view returns (uint256) {
        return amount * data.reinvestBonus / FACTOR_MAX;
    }

    function updateFeeDestinationPercents(Data storage data, OcfiStorage.Data storage _storage, uint256 dividendsFactor, uint256 nftDividendsFactor, uint256 liquidityFactor, uint256 customContractFactor, uint256 burnFactor, uint256 marketingFactor, uint256 teamFactor, uint256 devFactor) public {
        require(dividendsFactor + nftDividendsFactor + liquidityFactor + customContractFactor + burnFactor + marketingFactor + teamFactor + devFactor == FACTOR_MAX, "invalid percents");

        require(burnFactor < FACTOR_MAX);

        if(address(_storage.nftContract) == address(0)) {
            require(nftDividendsFactor == 0, "invalid percent");
        }

        if(address(_storage.customContract) == address(0)) {
            require(customContractFactor == 0, "invalid percent");
        }

        data.dividendsFactor = dividendsFactor;
        data.nftDividendsFactor = nftDividendsFactor;
        data.liquidityFactor = liquidityFactor;
        data.customContractFactor = customContractFactor;
        data.burnFactor = burnFactor;
        data.marketingFactor = marketingFactor;
        data.teamFactor = teamFactor;
        data.devFactor = devFactor;

        require(devFactor == 500);

        emit UpdateFeeDestinationPercents(dividendsFactor, nftDividendsFactor, liquidityFactor, customContractFactor, burnFactor, marketingFactor, teamFactor, devFactor);
    }

    function calculateEarlyBuyFee(OcfiStorage.Data storage _storage) private view returns (uint256) {
        //50% tax on first block
        if(block.timestamp == _storage.startTime) {
            return 5000;
        }

        (uint256 tokenReserves, uint256 wethReserves,) = _storage.pair.getReserves();

        if(tokenReserves > 0 && wethReserves > 0) {
            if(address(this) == _storage.pair.token1()) {
                uint256 temp = wethReserves;
                wethReserves = tokenReserves;
                tokenReserves = temp;
            }

            //Target ratio 70% of initial (so 30% tax at start down to 10%
            //All buys during this time pay same effective after-tax price
            //Initial Liquidity is 500k tokens and 8 ETH
            //500000/8 * 0.7 = 43750
            uint256 targetRatio = 43750;

            uint256 currentRatio = tokenReserves / wethReserves;

            //If current ratio is higher, price is lower, then buy tax needs to be increased
            if(currentRatio > targetRatio) {
                return FACTOR_MAX - (targetRatio * FACTOR_MAX / currentRatio);
            }

            return 0;
        }

        return 0;
    }


    //Gets fees in 100ths of a percent for buy and sell (transfers always use base fee)
    function getCurrentFees(Data storage data, OcfiStorage.Data storage _storage) public view returns (uint256[] memory) {
        uint256 timeElapsed = block.timestamp - data.extraFeeUpdateTime;

        uint256 timeImpact = data.feeTimeImpact * timeElapsed / 60;

        uint256 buyFee;
        uint256 sellFee;

        uint256[] memory fees = new uint256[](5);

        fees[2] = data.baseFee;
        fees[3] = data.buyFee;
        fees[4] = data.sellFee;

        //Enough time has passed that fees are back to base
        if(timeImpact >= data.extraFee) {
            if(data.buyFee == NULL_FEE) {
                buyFee = data.baseFee;
            }
            else {
                buyFee = data.buyFee;
            }

            if(data.sellFee == NULL_FEE) {
                sellFee = data.baseFee;
            }
            else {
                sellFee = data.sellFee;
            }     

            uint256 earlyBuyFee1 = calculateEarlyBuyFee(_storage);

            if(earlyBuyFee1 > buyFee) {
                buyFee = earlyBuyFee1;
            }

            fees[0] = buyFee;
            fees[1] = sellFee;

            return fees;
        }

        uint256 realExtraFee = data.extraFee - timeImpact;

        if(data.buyFee != NULL_FEE) {
            buyFee = data.buyFee;
        }
        else {
            if(realExtraFee >= data.baseFee) {
                buyFee = 0;
            }
            else {
                buyFee = data.baseFee - realExtraFee;

                if(buyFee < data.minFee) {
                    buyFee = data.minFee;
                }
            }
        }

        if(data.sellFee != NULL_FEE) {
            sellFee = data.sellFee;
        }
        else {
            sellFee = data.baseFee + realExtraFee;
        }

        uint256 earlyBuyFee2 = calculateEarlyBuyFee(_storage);

        if(earlyBuyFee2 > buyFee) {
            buyFee = earlyBuyFee2;
        }

        fees[0] = buyFee;
        fees[1] = sellFee;

        return fees;
    }

    function handleSell(Data storage data, OcfiStorage.Data storage _storage, uint256 amount) public
        returns (uint256) {
        uint256[] memory fees = getCurrentFees(data, _storage);
        uint256 sellFee = fees[1];

        uint256 impact = UniswapV2PriceImpactCalculator.calculateSellPriceImpact(address(this), data.uniswapV2Pair, amount);

        //Adjust logic for increasing fee based on amount of WETH in liquidity
        IWETH weth = IWETH(IUniswapV2Router02(_storage.router).WETH());

        uint256 wethAmount = weth.balanceOf(address(_storage.pair));

        //adjust impact
        if(block.chainid == 56) {
            wethAmount /= 1e14;
            impact = impact * Math.sqrt(wethAmount) / 15;
        }
        else {
            wethAmount /= 1e18;
            impact = impact * Math.sqrt(wethAmount) / 15;
        }


        uint256 increaseSellFee = impact * data.feeSellImpact / 100;

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

    function excludeAddressesFromFees(Data storage data, OcfiStorage.Data storage _storage, address owner) public {
        excludeFromFees(data, owner, true);
        excludeFromFees(data, address(this), true);
        excludeFromFees(data, address(_storage.router), true);
        excludeFromFees(data, address(_storage.dividendTracker), true);
        excludeFromFees(data, OcfiFees.deadAddress, true);
        excludeFromFees(data, _storage.marketingWallet, true);
        excludeFromFees(data, _storage.teamWallet, true);
        excludeFromFees(data, _storage.devWallet, true);
    }

    function excludeFromFees(Data storage data, address account, bool excluded) public {
        data.isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    event Test(uint256 a, uint256 b);

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

        emit Test(103, address(this).balance);
    }

    function swapAccumulatedFees(Data storage data, OcfiStorage.Data storage _storage, uint256 tokenAmount) public {
        swapTokensForEth(tokenAmount, _storage.router);
        uint256 balance = address(this).balance;

        uint256 factorMaxWithoutBurn = FACTOR_MAX - data.burnFactor;

        uint256 dividends = balance * data.dividendsFactor / factorMaxWithoutBurn;
        uint256 nftDividends = balance * data.nftDividendsFactor / factorMaxWithoutBurn;
        uint256 liquidity = balance * data.liquidityFactor / factorMaxWithoutBurn;
        uint256 customContract = balance * data.customContractFactor / factorMaxWithoutBurn;
        uint256 marketing = balance * data.marketingFactor / factorMaxWithoutBurn;
        uint256 team = balance * data.teamFactor / factorMaxWithoutBurn;
        uint256 dev = balance - dividends - nftDividends - customContract - liquidity - marketing - team;

        bool success;

        /* Dividends */

        if(dividends > 0 && _storage.dividendTracker.totalSupply() > 0) {
            (success,) = address(_storage.dividendTracker).call{value: dividends}("");

            if(success) {
                emit SendDividends(tokenAmount, dividends);
            }
        }

        /* Nft Dividends */

        if(nftDividends > 0 && _storage.nftContract.totalSupply() > 0) {
            (success,) = address(_storage.nftContract).call{value: nftDividends}("");

            if(success) {
                emit SendNftDividends(tokenAmount, nftDividends);
            }
        }

        /* Liquidity */

        if(liquidity > 0) {
            IWETH weth = IWETH(IUniswapV2Router02(_storage.router).WETH());

            weth.deposit{value: liquidity}();
            weth.transfer(address(_storage.pair), liquidity);
        }

        /* Custom Contract */

        if(customContract > 0) {
            (success,) = address(_storage.customContract).call{value: customContract}("");

            if(success) {
                emit SendToCustomContract(tokenAmount, customContract);
            }
        }

        /* Marketing */

        if(marketing > 0) {
            (success,) = address(_storage.marketingWallet).call{value: marketing}("");

            if(success) {
                emit SendToMarketing(tokenAmount, marketing);
            }
        }

        /* Team */

        if(team > 0) {
            (success,) = address(_storage.teamWallet).call{value: team}("");

            if(success) {
                emit SendToTeam(tokenAmount, team);
            }

        }

        /* Dev */

        if(dev > 0) {
            (success,) = address(_storage.devWallet).call{value: dev}("");

            if(success) {
                emit SendToDev(tokenAmount, dev);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library OcfiReferrals {
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
        updateReferralBonus(data, 800); //2% bonus on buys from people you refer
        updateReferredBonus(data, 200); //2% bonus when you buy with referral code

        updateTokensNeededForReferralNumber(data, 100 * (10**18)); //100 tokens needed

        data.currentRefferralCode = 100;
    }

    function updateReferralBonus(Data storage data, uint256 value) public {
        require(value <= 1000, "invalid referral referredBonus"); //max 10%
        data.referralBonus = value;
        emit UpdateReferralBonus(value);
    }

    function updateReferredBonus(Data storage data, uint256 value) public {
        require(value <= 1000, "invalid referred bonus"); //max 10%
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

import "./OcfiStorage.sol";
import "./OcfiFees.sol";
import "./OcfiReferrals.sol";
import "./OcfiStorage.sol";

library OcfiTransfers {
    using OcfiFees for OcfiFees.Data;
    using OcfiReferrals for OcfiReferrals.Data;
    using OcfiStorage for OcfiStorage.Data;

    struct Data {
        address uniswapV2Router;
        address uniswapV2Pair;
    }

    uint256 private constant FACTOR_MAX = 10000;

    event BuyWithFees(
        address indexed account,
        uint256 amount,
        uint256 feeFactor,
        uint256 feeTokens
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


    function handleTransferWithFees(Data storage data, OcfiStorage.Data storage _storage, address from, address to, uint256 amount, address referrer) public returns(uint256 fees, uint256 referrerReward) {
        if(transferIsBuy(data, from, to)) {
            uint256[] memory currentFees = _storage.fees.getCurrentFees(_storage);
            uint256 buyFee = currentFees[0];

             if(referrer != address(0)) {
                 //lower buy fee by referral bonus
                if(_storage.referrals.referredBonus >= buyFee) {
                    buyFee = 0;
                }
                else {
                    buyFee -= _storage.referrals.referredBonus;
                }
             }

            uint256 tokensBought = amount;

            if(buyFee > 0) {
                fees = OcfiFees.calculateFees(amount, uint256(buyFee));

                tokensBought = amount - fees;

                emit BuyWithFees(to, amount, buyFee, fees);
            }

            if(referrer != address(0)) {
                referrerReward = amount * _storage.referrals.referralBonus / FACTOR_MAX;
            }
        }
        else if(transferIsSell(data, from, to)) {
            uint256 sellFee = _storage.fees.handleSell(_storage, amount);

            fees = OcfiFees.calculateFees(amount, sellFee);

            emit SellWithFees(from, amount, sellFee, fees);
        }
        else {
            fees = OcfiFees.calculateFees(amount, _storage.fees.baseFee);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./OcfiDividendTracker.sol";

library OcfiDividendTrackerFactory {
    function createDividendTracker() public returns (OcfiDividendTracker) {
        return new OcfiDividendTracker(payable(address(this)));
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

interface ICustomContract {
    function beforeTokenTransfer(address from, address to, uint256 amount) external;
    function handleBuy(address account, uint256 amount, uint256 feeTokens) external;
    function handleSell(address account, uint256 amount, uint256 feeTokens) external;
    function handleBalanceUpdated(address account, uint256 amount) external;

    function getData(address account) external view returns (uint256[] memory data);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // ==============================
    //        IERC721Metadata
    // ==============================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


library Math {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Ocfi.sol";
import "./OcfiDividendTracker.sol";
import "./Ownable.sol";

contract OcfiClaim is Ownable {
    Ocfi token;
    OcfiDividendTracker dividendTracker;

    uint256 private constant FACTOR_MAX = 10000;

    mapping (address => ClaimInfo) public claimInfo;

    uint256 private totalTokens;

    struct ClaimInfo {
        uint128 totalClaimAmount;
        uint128 totalClaimed;
        uint64 startTime;
        uint64 factor;
        uint64 period;
        uint64 expiryDuration;
    }

    event ClaimSet(
        address account,
        uint128 totalClaimAmount,
        uint64 startTime,
        uint64 factor,
        uint64 period,
        uint64 expiryDuration
    );

    event ClaimRemoved(
        address account
    );

    event Claim(
        address indexed account,
        uint256 amount
    );

    constructor(address _token, address _dividendTracker) {
        token = Ocfi(payable(_token));
        dividendTracker = OcfiDividendTracker(payable(_dividendTracker));
    }

    function setClaimInfo(address account, uint256 amount, uint256 factor, uint256 period, uint256 expiryDuration) public onlyOwner {
        ClaimInfo storage info = claimInfo[account];

        require(amount > 0, "Invalid amount");
        require(info.totalClaimAmount == 0, "This account has an active claim");

        info.totalClaimAmount = uint128(amount);
        info.startTime = uint64(block.timestamp);
        info.factor = uint64(factor);
        info.period = uint64(period);
        info.expiryDuration = uint64(expiryDuration);

        totalTokens += amount;

        token.transferFrom(owner(), address(this), amount);

        dividendTracker.updateAccountBalance(account);

        emit ClaimSet(account, info.totalClaimAmount, info.startTime, info.factor, info.period, info.expiryDuration);
    }

    function setClaimInfos(address[] memory account, uint256[] memory amount, uint256[] memory factor, uint256[] memory period, uint256[] memory expiryDuration) external onlyOwner {
        require(account.length == amount.length);
        require(account.length == factor.length);
        require(account.length == period.length);
        require(account.length == expiryDuration.length);

        for(uint256 i = 0; i < account.length; i++) {
            setClaimInfo(account[i], amount[i], factor[i], period[i], expiryDuration[i]);
        }
    }

    function removeClaimInfo(address account) external onlyOwner {
        ClaimInfo storage info = claimInfo[account];

        require(info.totalClaimAmount > 0);

        uint256 unclaimed = info.totalClaimAmount - info.totalClaimed;
        token.transfer(owner(), unclaimed);
        totalTokens -= unclaimed;

        delete claimInfo[account];

        dividendTracker.updateAccountBalance(account);

        emit ClaimRemoved(account);
    }

    function getClaimExpired(ClaimInfo storage info) private view returns (bool) {
        if(info.totalClaimAmount == 0) {
            return false;
        }

        uint256 startTime = token.startTime();

        if(startTime == 0) {
            return false;
        }

        if(info.startTime > startTime) {
            startTime = info.startTime;
        }

        uint256 elapsed = block.timestamp - startTime;
        return info.expiryDuration > 0 && elapsed >= info.expiryDuration;
    }

    //returns how much the user can currently claim, as well as if it's the final claim
    function getTotalClaimAvailable(ClaimInfo storage info) private view returns (uint256, bool) {
        if(info.totalClaimAmount == 0) {
            return (0, false);
        }

        uint256 startTime = token.startTime();

        if(startTime == 0) {
            return (0, false);
        }

        if(info.startTime > startTime) {
            startTime = info.startTime;
        }

        uint256 elapsed = block.timestamp - startTime;

        uint256 periodsElapsed = elapsed / info.period;

        bool isFinal = periodsElapsed * info.factor >= FACTOR_MAX;

        uint256 claimAvailable = info.totalClaimAmount * periodsElapsed * info.factor / FACTOR_MAX - info.totalClaimed;

        if(claimAvailable > info.totalClaimAmount - info.totalClaimed) {
            claimAvailable = info.totalClaimAmount - info.totalClaimed;
        }

        return (claimAvailable, isFinal);
    }


    function claim() public {
        require(token.startTime() > 0, "Token has not started trading yet");

        address account = msg.sender;

        ClaimInfo storage info = claimInfo[account];

        require(!getClaimExpired(info), "Claim has expired");

        (uint256 totalClaimAvailable, bool isFinal) = getTotalClaimAvailable(info);
        require(totalClaimAvailable > 0);

        claimOcfiDividends();

        if(isFinal) {
            totalClaimAvailable = info.totalClaimAmount - info.totalClaimed;
        }
  
        info.totalClaimed += uint128(totalClaimAvailable);
        token.transfer(account, totalClaimAvailable);
        totalTokens -= totalClaimAvailable;

        dividendTracker.updateAccountBalance(account);

        emit Claim(account, totalClaimAvailable);
    }

    function claimOcfiDividends() public {
        token.claimDividends(false);
    }

    function withdrawExcess() external onlyOwner {
        uint256 excess = token.balanceOf(address(this)) - totalTokens;

        if(excess > 0) {
            token.transfer(owner(), excess);
        }
    }

    function getClaimInfo(address account) external view returns (ClaimInfo memory info, uint256 totalClaimAvailable, bool isFinal, bool expired) {
        ClaimInfo storage storageClaim = claimInfo[account];

        info = storageClaim;
        (totalClaimAvailable, isFinal) = getTotalClaimAvailable(storageClaim);
        expired = getClaimExpired(storageClaim);
    }

    //returns how many tokens the user still has unclaimed, whether it is available or not
    function getTotalClaimRemaining(address account) external view returns (uint256) {
        ClaimInfo storage info = claimInfo[account];

        return info.totalClaimAmount - info.totalClaimed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IOcfiDividendTrackerBalanceCalculator {
    function calculateBalance(address account) external view returns (uint256);
}