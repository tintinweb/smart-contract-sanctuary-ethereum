//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./priceCalculate.sol";

contract EverStaking is Ownable {
    using SafeMath for uint256;

    address public _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 duration;
    }

    IERC20 public REWARD;
    IERC20 public STAKING;
    IERC20 public TOKEN;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;
    mapping(address => Stake) public stakeDetails;

    PriceCalculator public priceCalculator;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;

    uint256 public totalStaking;
    uint256 public rewardPerShare;

    uint256 public penaltyPercentage = 2;

    uint256 public minTokenPerShare = 1 * 10**18;

    uint256 public maxStakePercentage = 20;

    //APR is in percent * 100 (e.g. 2500 = 25% = 0.25)
    uint256 public currentApr = 2300;
    uint256 public poolStakePeriod = 7;

    uint256 public maxStakeTokensInThePool = 100000 * 10**18;

    uint256 public maxStakeTokensPerUser = 1000 * 10**18;

    uint256 public currentStakeInThePool;

    uint256 public bonusShareFactor = 200;
    uint256 public reserveRatio = 25;

    bool public useApy = false;
    IUniswapV2Router02 public router;

    uint256 public minStakeAmount = 1 * (10**18);

    uint256 secondsForDay = 86400;
    uint256 currentIndex;

    event NewStake(address staker, uint256 amount, uint256 time);
    event WithdrawAndExit(address staker, uint256 amount);
    event EmergencyWithdraw(address staker, uint256 amount);
    event CalcReward(
        uint256 amount,
        uint256 time,
        uint256 totalTime,
        uint256 apr,
        uint256 reward
    );

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    constructor() {
        REWARD = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        STAKING = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        TOKEN = IERC20(0xA87Ed75C257f1ec38393bEA0A83d55Ac2279D79c);

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        priceCalculator = new PriceCalculator();

        updatePool();
    }

    receive() external payable {}

    function purge(address receiver) external onlyOwner {
        uint256 balance = REWARD.balanceOf(address(this));
        REWARD.transfer(receiver, balance);
    }

    function getErc20Tokens(
        address bepToken,
        uint256 _amount,
        address receiver
    ) external onlyOwner {
        require(
            IERC20(bepToken).balanceOf(address(this)) >= _amount,
            "No enough tokens in the pool"
        );

        IERC20(bepToken).transfer(receiver, _amount);
    }

    function changePenaltyPercentage(uint256 _percentage) external onlyOwner {
        penaltyPercentage = _percentage;
    }

    function changePoolStakePeriod(uint256 _time) external onlyOwner {
        poolStakePeriod = _time;
    }

    function changeMaxStakePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Percentage can not be greater than 100%");
        maxStakePercentage = _percentage;
    }

    function changeMinimumStakeAmount(uint256 _amount) external onlyOwner {
        minStakeAmount = _amount;
    }

    function changeMinimumTokenPerShare(uint256 _amount) external onlyOwner {
        minTokenPerShare = _amount;
    }

    function changeBonusShareFactor(uint256 _value) external onlyOwner {
        bonusShareFactor = _value;
    }

    function changeRecerveRatio(uint256 _value) external onlyOwner {
        reserveRatio = _value;
    }

    function changeApr(uint256 _apr, bool _useApy) external onlyOwner {
        currentApr = _apr;
        useApy = _useApy;
    }

    function changeMaxTokenPerWallet(uint256 _amount) external onlyOwner {
        maxStakeTokensPerUser = _amount;
    }

    function changeMaxTokenPerPool(uint256 _amount) external onlyOwner {
        maxStakeTokensInThePool = _amount;
    }

    function setShare(
        address shareholder,
        uint256 amount,
        uint256 time
    ) internal {
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            totalShares = totalShares.sub(shares[shareholder].amount);
            shares[shareholder].amount = 0;
            removeShareholder(shareholder);
        }

        if (time == 0) {
            time = 1;
        }
        uint256 totalShareAmount = amount.mul(time);
        if (bonusShareFactor > 0) {
            totalShareAmount = totalShareAmount
                .mul(time.add(bonusShareFactor))
                .div(bonusShareFactor);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(
            totalShareAmount
        );
        shares[shareholder].amount = totalShareAmount;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return shareholders.length;
    }

    function getShareHoldersList() external view returns (address[] memory) {
        return shareholders;
    }

    function totalDistributedRewards() external view returns (uint256) {
        return totalDistributed;
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

    // staking

    function newStake(uint256 amount) public {
        // check user has ever earn tokens
        require(
            TOKEN.balanceOf(msg.sender) > 0,
            "You don't have any ever earn tokens"
        );
        uint256 userTokenValue = priceCalculator.getLatestPrice(
            address(TOKEN),
            TOKEN.balanceOf(msg.sender)
        );

        uint256 maxBusdAmountToStake = userTokenValue
            .mul(maxStakePercentage)
            .div(100);

        require(
            amount <= maxBusdAmountToStake,
            "You can not stake more than your token value"
        );
        require(
            amount <= maxStakeTokensPerUser,
            "You exceeded max token amount that one wallet can stake"
        );
        require(
            currentStakeInThePool.add(amount) <= maxStakeTokensInThePool,
            "Maximum pool token exceeded"
        );
        require(
            stakeDetails[msg.sender].amount == 0,
            "You Already have another running staking"
        );
        require(
            amount >= minStakeAmount,
            "You should stake more than minimum balance"
        );
        require(
            STAKING.balanceOf(msg.sender) >= amount,
            "You token balance is lower than requested staking amount"
        );

        STAKING.transferFrom(address(msg.sender), address(this), amount);
        totalStaking = totalStaking + amount;
        setShare(msg.sender, amount, poolStakePeriod);
        // stake time in seconds
        uint256 stakeTimeInSeconds = poolStakePeriod.mul(secondsForDay);
        // set stake details
        stakeDetails[msg.sender].amount = amount;
        stakeDetails[msg.sender].startTime = block.timestamp;
        stakeDetails[msg.sender].endTime = block.timestamp.add(
            stakeTimeInSeconds
        );
        stakeDetails[msg.sender].duration = poolStakePeriod;

        currentStakeInThePool = currentStakeInThePool.add(amount);

        emit NewStake(msg.sender, amount, poolStakePeriod);
        // update pool
        updatePool();
    }

    // remove
    function withdrawAndExit() public {
        require(
            stakeDetails[msg.sender].amount > 0,
            "You don't have any staking in this pool"
        );
        require(
            stakeDetails[msg.sender].endTime <= block.timestamp,
            "Lock time did not end. You cannot use normal withdraw"
        );
        updatePool();
        // get staked amount
        uint256 amountToSend = stakeDetails[msg.sender].amount;
        // calculate reward token
        uint256 rewardByShare = rewardPerShare.mul(shares[msg.sender].amount);
        uint256 totalTime = secondsForDay.mul(
            stakeDetails[msg.sender].duration
        );
        if (stakeDetails[msg.sender].duration == 0) {
            totalTime = block.timestamp.sub(stakeDetails[msg.sender].startTime);
        }
        uint256 rewardByApr = calculateReward(
            amountToSend,
            stakeDetails[msg.sender].duration,
            totalTime
        );
        uint256 rewardTokens = 0;
        if (rewardByApr < rewardByShare) {
            rewardTokens = rewardByApr;
        } else {
            rewardTokens = rewardByShare;
        }
        totalDistributed = totalDistributed.add(rewardTokens);
        // total amount to send user
        amountToSend = amountToSend.add(rewardTokens);

        require(
            REWARD.balanceOf(address(this)) >= amountToSend,
            "No enough tokens in the pool"
        );

        setShare(msg.sender, 0, 0);

        totalStaking = totalStaking.sub(stakeDetails[msg.sender].amount);

        currentStakeInThePool = currentStakeInThePool.sub(
            stakeDetails[msg.sender].amount
        );

        // reset stake details
        stakeDetails[msg.sender].amount = 0;
        stakeDetails[msg.sender].startTime = 0;
        stakeDetails[msg.sender].endTime = 0;
        // send tokens
        REWARD.transfer(msg.sender, amountToSend);

        emit WithdrawAndExit(msg.sender, amountToSend);
        updatePool();
    }

    function emergencyWithdraw() public {
        require(
            stakeDetails[msg.sender].amount > 0,
            "You don't have any staking in this pool"
        );
        require(
            stakeDetails[msg.sender].endTime > block.timestamp,
            "Lock time already finished. You cannot use emergency withdraw, use normal withdraw instead."
        );
        // get staked amount
        uint256 amountToSend = stakeDetails[msg.sender].amount;
        // calculate reward token
        uint256 totalTime = block.timestamp.sub(
            stakeDetails[msg.sender].startTime
        );
        uint256 lockTime = stakeDetails[msg.sender].duration.mul(secondsForDay);
        uint256 rewardByShare = rewardPerShare
            .mul(shares[msg.sender].amount)
            .mul(totalTime)
            .div(lockTime);
        uint256 rewardByApr = calculateReward(
            amountToSend,
            stakeDetails[msg.sender].duration,
            totalTime
        );
        uint256 rewardTokens = 0;
        if (rewardByApr < rewardByShare) {
            rewardTokens = rewardByApr;
        } else {
            rewardTokens = rewardByShare;
        }
        uint256 penaltyAmount = rewardTokens.mul(penaltyPercentage).div(100);

        amountToSend = amountToSend.add(rewardTokens).sub(penaltyAmount);

        require(
            REWARD.balanceOf(address(this)) >= amountToSend,
            "No enough tokens in the pool"
        );

        setShare(msg.sender, 0, 0);

        totalStaking = totalStaking.sub(stakeDetails[msg.sender].amount);
        currentStakeInThePool = currentStakeInThePool.sub(
            stakeDetails[msg.sender].amount
        );

        // reset stake details
        stakeDetails[msg.sender].amount = 0;
        stakeDetails[msg.sender].startTime = 0;
        stakeDetails[msg.sender].endTime = 0;

        // send tokens
        REWARD.transfer(msg.sender, amountToSend);

        emit EmergencyWithdraw(msg.sender, amountToSend);
        updatePool();
    }

    // update stake pool
    function updatePool() public {
        uint256 currentTokenBalance = REWARD.balanceOf(address(this));
        totalDividends = currentTokenBalance.sub(totalStaking);

        uint256 const = 100;
        if (totalShares > 0) {
            rewardPerShare = (totalDividends.div(totalShares)).mul(
                (const.sub(reserveRatio)).div(100)
            );
        }
        if (rewardPerShare < minTokenPerShare) {
            rewardPerShare = minTokenPerShare;
        }
    }

    function getUserInfo(address _wallet)
        public
        view
        returns (
            uint256 _amount,
            uint256 _startTime,
            uint256 _endTime
        )
    {
        _amount = stakeDetails[_wallet].amount;
        _startTime = stakeDetails[_wallet].startTime;
        _endTime = stakeDetails[_wallet].endTime;
    }

    function calculatRewardByAPY(
        uint256 amount,
        uint256 apr,
        uint256 timeDays
    ) public pure returns (uint256) {
        uint256 reward = amount;
        bool improveAccuracy = amount < 10**20;
        if (improveAccuracy) {
            //increase accuracy
            reward = reward.mul(10**20);
        }
        uint256 const3650000 = 3650000;
        for (uint256 i = 0; i < timeDays; i++) {
            //apr/(365*10000) gives the daily return. (3650000+apr)/3650000 = (1+apr/(365*10000))
            reward = reward.mul(const3650000.add(apr)).div(3650000);
        }
        if (improveAccuracy) {
            //increase accuracy
            reward = reward.div(10**20);
        }
        reward = reward.sub(amount);
        return reward;
    }

    ///return APY with precision of two digits after the point
    function calcApyMul100() public view returns (uint256) {
        uint256 amount = 1 * (10**18);
        uint256 rewardAmount = calculatRewardByAPY(amount, currentApr, 365);
        uint256 apyMul100 = rewardAmount.mul(10000).div(amount);
        return apyMul100;
    }

    function calculateReward(
        uint256 amount,
        uint256 time,
        uint256 totalTime
    ) internal returns (uint256) {
        uint256 rewardAmount = 0;

        if (!useApy) {
            rewardAmount = amount
                .mul(currentApr)
                .mul(totalTime)
                .div(secondsForDay.mul(365))
                .div(10000);
        } else {
            uint256 totalTimeDays = totalTime.div(secondsForDay); //rounded down, so partial day wouldn't count
            rewardAmount = calculatRewardByAPY(
                amount,
                currentApr,
                totalTimeDays
            );
        }
        emit CalcReward(amount, time, totalTime, currentApr, rewardAmount);
        return rewardAmount;
    }

    function buyTokenFromUsdc(uint256 _amount) external onlyOwner {
        require(
            REWARD.balanceOf(address(this)) >= _amount,
            "No enough Tokens in the pool"
        );

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(REWARD);
        path[1] = router.WETH();
        path[2] = address(TOKEN);

        REWARD.approve(address(router), _amount);

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );
    }

    function convertUsdcForEth(uint256 _amount) external onlyOwner {
        require(
            REWARD.balanceOf(address(this)) >= _amount,
            "No enough Tokens in the pool"
        );

        address[] memory path = new address[](2);
        path[0] = address(REWARD);
        path[1] = router.WETH();

        REWARD.approve(address(router), _amount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function sendTokens(uint256 _amount, address _address) external onlyOwner {
        require(
            TOKEN.balanceOf(address(this)) >= _amount,
            "No enough Tokens in the pool"
        );
        TOKEN.transfer(_address, _amount);
    }

    function sendUsdc(uint256 _amount, address _address) external onlyOwner {
        require(
            REWARD.balanceOf(address(this)) >= _amount,
            "No enough Tokens in the pool"
        );
        REWARD.transfer(_address, _amount);
    }

    function sendEth(uint256 _amount, address _address) external onlyOwner {
        require(
            address(this).balance >= _amount,
            "No enough Tokens in the pool"
        );
        payable(_address).transfer(_amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity >=0.5.0;

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PriceCalculator {
    using SafeMath for uint256;

    IUniswapV2Router02 public router;

    address bnb;
    address usdt;

    constructor() {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        bnb = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        usdt = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    function getLatestPrice(address _tokenAddress, uint256 _tokenAmount)
        public
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = bnb;

        // get token price in bnb
        uint256[] memory amounts = router.getAmountsOut(_tokenAmount, path);

        uint256 bnbAmount = amounts[1];
        uint256 tokenPriceInUsdt = getBnbPrice(bnbAmount);

        return tokenPriceInUsdt;
    }

    function getBnbPrice(uint256 _amount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = bnb;
        path[1] = usdt;

        uint256[] memory amounts = router.getAmountsOut(_amount, path);

        return amounts[1];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

pragma solidity >=0.6.2;

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