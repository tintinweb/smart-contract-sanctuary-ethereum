// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract R3TRANCH is Ownable, ReentrancyGuard, Pausable {

    struct StakeParams {  
        bool active;
        uint256 stakingOrder;
        uint256 start;
        uint256 amount;
        uint256 lastRewardTS;
        // uint256 percentIndex; //todo remove
    }
    struct RewardParams {
        uint256 amount;
        uint256 rewardTS;
    }
    struct BoostParams {
        bool    active;
        uint8 boostYear;
        uint256 boostOrder;
        uint256 startTS;
        uint256 endTS;
        uint256 extraPercent;
    }

    address[] private stakers;

    IERC20 private r3tContract;
    IERC20 private rtContract;
    
    uint256 public constant DECIMAL_FACTOR = 100; // todo COMENT
    uint256 public constant DAY = 20;
    uint256 public constant YEAR = 365 * DAY;
    uint256 public constant FIVE_YEARS = 5 * YEAR;

    uint256[] public yearPercents = [150, 100, 50, 50, 50];


    uint256 private totalStakingBalanceRT;
    uint256 private totalRewards;
//     uint256[] private rewardYearPercent;
//     // bool fromGetReward;


    mapping(address => StakeParams[]) private stakingBalances;
    mapping(address => uint256[]) private rewards;
    mapping(address => uint256) private activeStake;
//     mapping(uint256 => uint256) private percentIndexTS; 
    mapping(address => mapping(uint256 => RewardParams[])) private ordersRewards;
    mapping(uint256 => BoostParams[]) private boosts;


    constructor(
        address r3tContractAddress, 
        address rtContractAddress 
//         uint256 _rewardYearPercent
        ) {
        r3tContract = IERC20(r3tContractAddress);
        rtContract = IERC20(rtContractAddress);
        // rewardYearPercent.push(_rewardYearPercent);
    }

    function totalSupplyR3T() external view returns (uint256) {
        return r3tContract.balanceOf(address(this));
    }

    function getTotalStakingBalanceRT() external view returns (uint256) {
        return totalStakingBalanceRT;
    }

    function getTotalStakedTokens(address _account)
        public
        view
        returns (uint256)
    {
        uint256 total;
        for(uint256 i = 0; i < stakingBalances[_account].length; i++) {

            if(stakingBalances[_account][i].active) {
                total += stakingBalances[_account][i].amount;
            }
        }
        return total;
    }

    function getStakes(address _account)
        public
        view
        returns (StakeParams[] memory)
    {
        return stakingBalances[_account];
    }
    function getBoosts(uint256 _year)
        public
        view
        returns (BoostParams[] memory)
    {
        return boosts[_year];
    }

    function getRewards(address _account)
        public
        view
        returns (uint256[] memory)
    {
        return rewards[_account];
    }    

    function getTotalRewards() external view returns (uint256) {
        return totalRewards;
    }

    function getTotalEarnedTokens(address _account) public view returns (uint256) {
        uint256 total;
        for(uint256 i = 0; i < rewards[_account].length; i++) {
            total += rewards[_account][i];
        }
        return total;
    }

   /*  function getStakingYearPercent() public view returns (uint256) {
        return rewardYearPercent[rewardYearPercent.length - 1];
    } */

    function viewStakers() public view returns (address[] memory) {
        return stakers;
    }
    function availableRewardOfStake(address account, uint256 stakingOrder, uint256 tS) public view returns (uint256) {
        StakeParams memory oneStake = stakingBalances[account][stakingOrder];
        RewardParams[] memory ordersReward = ordersRewards[account][stakingOrder];

        uint256 reward;

        if(tS > oneStake.start) {
            uint256 lastReward = oneStake.start;
            for(uint256 i = 0; i < ordersReward.length && ordersReward[i].rewardTS <= tS; i++) {
                lastReward = ordersReward[i].rewardTS;
            }
            if(lastReward > oneStake.start + FIVE_YEARS) {
                lastReward = oneStake.start + FIVE_YEARS;
            }
            reward = calculateReward(account, stakingOrder, lastReward, tS);
            /* if(oneStake.start + FIVE_YEARS <= tS) {
                uint256 allReward = calculatePaidRewardForOne(account, stakingOrder, tS);
                if(allReward + reward < oneStake.amount * 4) {
                    reward = oneStake.amount * 4 - allReward;
                    // reward +=  _stakeParams.amount * 4 - allReward;
                }
            } */
        }
        // uint256 paidReward = calculatePaidRewardForOne( account, stakingOrder, tS);
        return reward;
    }
    function availableRewardOfAcount(address account, uint256 tS) public view returns (uint256) {
        uint256 totalReward;

        for (uint256 stakingOrder = 0; stakingBalances[account][stakingOrder].start < tS; stakingOrder++) {
            totalReward += availableRewardOfStake(account, stakingOrder, tS);
        }
        return totalReward;
    }
    function availableRewardByDates(address account, uint256 stakingOrder, uint256[] memory tS) public view returns (uint256[] memory) {
        uint256[] memory _rewards = new uint256[](tS.length);

        for (uint256 i = 0; i < tS.length; i++) {
            _rewards[i] = availableRewardOfStake(account, stakingOrder, tS[i]);
            // rewards.push(availableRewardOfStake(account, stakingOrder, tS[i]));
        }
        return _rewards;
    }

    function stake(uint256 _amount) public nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be more than 0");

        rtContract.transferFrom(msg.sender, address(this), _amount);
        totalStakingBalanceRT += _amount;
        createNewStakingSession(_amount);
        
        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function remainLatestRewardTimes(StakeParams memory oneStake, uint256 endTS)
        internal
        pure
        returns (uint256)
    {
        uint256 oneStakeEnd = oneStake.start + FIVE_YEARS;
        uint256 timeForCount = oneStakeEnd < endTS ? oneStakeEnd : endTS;
        return (timeForCount - oneStake.lastRewardTS) / DAY;
    }

/*     function findPercentIndex(uint256 date, uint256 index) internal view returns (uint256) {
        uint256 percentIndex;
        while(index < rewardYearPercent.length && percentIndexTS[index] < date) {
            percentIndex = index;
            index++;
        }
        return percentIndex; 
    } */

    function calculateReward(address account) public view returns (uint256) {
        return calculateReward(account, block.timestamp);
    }

    /* function calculatePaidRewardForOne(address account, uint256 stakingOrder, uint256 tS) public view returns (uint256) {
        uint256 allReward;
        RewardParams[] storage ordersReward = ordersRewards[account][stakingOrder];
        
        for(uint256 i = 0; i < ordersReward.length && ordersReward[i].rewardTS <= tS; i++) {
            allReward += ordersReward[i].amount;
        }
        return allReward;
    } */

    function calculateReward(address account, uint256 endTS) public view returns (uint256) {
        uint256 reward;
        // uint256 allReward;        
        uint256 curRewardForOne;
        StakeParams memory _stakeParams;

        for(uint256 i = activeStake[account]; i < stakingBalances[account].length; i++) {
            _stakeParams = stakingBalances[account][i];
            if(endTS > _stakeParams.lastRewardTS && remainLatestRewardTimes(_stakeParams, endTS) > 0) {
                curRewardForOne = calculateReward(account, i, _stakeParams.lastRewardTS, endTS);
                reward += curRewardForOne;
              /*   if(_stakeParams.start + FIVE_YEARS <= endTS) {
                    allReward = calculatePaidRewardForOne(account, i, endTS);
                    allReward += curRewardForOne;

                    if(allReward < _stakeParams.amount * 4) {
                        reward +=  _stakeParams.amount * 4 - allReward;
                    }
                } */
            } 
        }
        return reward;
    }

    
    function calculate(address account, uint256 endTS) internal returns (uint256) {
        uint256 reward;
        // uint256 allReward;
        uint256 curRewardForOne;
        uint256 countDays;
        StakeParams memory _stakeParams;

        for(uint256 i = activeStake[account]; i < stakingBalances[account].length; i++) {
            _stakeParams = stakingBalances[account][i];            
            countDays = remainLatestRewardTimes(_stakeParams, endTS);
            if(endTS > _stakeParams.lastRewardTS && countDays > 0) {
                curRewardForOne = calculateReward(account, i, _stakeParams.lastRewardTS, endTS);
             /*    if(_stakeParams.start + FIVE_YEARS <= endTS) {
                    allReward = calculatePaidRewardForOne(account, i, endTS);
                    allReward += curRewardForOne;
                    if(allReward < _stakeParams.amount * 4) {
                        curRewardForOne += _stakeParams.amount * 4 - allReward;
                        // reward +=  _stakeParams.amount * 4 - allReward;
                    }
                } */
                reward += curRewardForOne;
                RewardParams memory params = RewardParams(
                    curRewardForOne,
                    _stakeParams.lastRewardTS + countDays * DAY
                    // endTS
                );
                ordersRewards[account][i].push(params);
            }
        }
        return reward;
    }
    function calculateLastRewardTS(address account) internal {
        StakeParams storage _stakeParams;

        for(uint256 i = activeStake[account]; i < stakingBalances[account].length; i++) {
            _stakeParams = stakingBalances[account][i];
            _stakeParams.lastRewardTS += remainLatestRewardTimes(_stakeParams, block.timestamp) * DAY;
            if(_stakeParams.lastRewardTS == _stakeParams.start + FIVE_YEARS) {
                _stakeParams.active = false;
                activeStake[account]++;
                totalStakingBalanceRT -= _stakeParams.amount;
            }
        }
    }

    function calculateBoosts(address account, uint256 stakingOrder, uint256 countDateStart, uint256 endTS, uint256 year) internal view returns (uint256) {
        // require(stakingBalances[account].length > stakingOrder, "Wrong stakingOrder!");
        // require(countDateStart >= stakingBalances[account][stakingOrder].start 
        //         && countDateStart < stakingBalances[account][stakingOrder].start + FIVE_YEARS, "Wrong countDateStart!");
        // require(endTS > countDateStart, "Wrong endTS!");

        uint256 countStartTS;
        uint256 countEndTS;
        uint256 reward;
        uint256 stakeAmount = stakingBalances[account][stakingOrder].amount;

        for(uint256 i = 0; i < boosts[year].length; i++) {
            BoostParams memory oneBoost = boosts[year][i];
            if(! oneBoost.active || oneBoost.startTS >= endTS || oneBoost.endTS <= countDateStart) {
                continue;
            }
            countStartTS = oneBoost.startTS > countDateStart ? oneBoost.startTS : countDateStart;
            countEndTS = oneBoost.endTS < endTS ? oneBoost.endTS : endTS;
            reward += (countEndTS - countStartTS) / DAY * (stakeAmount * oneBoost.extraPercent / (100 * DECIMAL_FACTOR));
        }
        return reward;
    }


    function calculateReward(address account, uint256 stakingOrder, uint256 countDateStart, uint256 endTS) internal view returns (uint256) {
        require(stakingBalances[account].length > stakingOrder, "Wrong stakingOrder!");
        StakeParams memory oneStake = stakingBalances[account][stakingOrder];
        require(countDateStart >= oneStake.start 
                && countDateStart < oneStake.start + FIVE_YEARS, "Wrong countDateStart!");
        require(endTS > countDateStart, "Wrong endTS!");
        

        uint256 stakeEndTS = oneStake.start + FIVE_YEARS;
        uint256 countDateEnd = countDateStart + ((endTS - countDateStart) / DAY * DAY);
        if (countDateEnd == countDateStart) {
            return 0;
        }
        countDateEnd = stakeEndTS < countDateEnd ? stakeEndTS : countDateEnd;
        uint256 reward;
        uint256 year;
        uint256 periodEnd;
        for(year = (countDateStart - oneStake.start) / YEAR + 1; year <= (countDateEnd - oneStake.start - 1) / YEAR; year++) {
            periodEnd = year * YEAR + oneStake.start;
            reward += (periodEnd - countDateStart) / DAY * oneStake.amount / 100 * yearPercents[year - 1] / 365;
            reward += calculateBoosts(account, stakingOrder, countDateStart, periodEnd, year);
            countDateStart = periodEnd;
        }
        reward += (countDateEnd - countDateStart) / DAY * oneStake.amount / 100 * yearPercents[year - 1] / 365;
        reward += calculateBoosts(account, stakingOrder, countDateStart, countDateEnd, year);
        return reward;
    }

    function getReward()
        public
        nonReentrant
        whenNotPaused
    {
        address acount = msg.sender;
        // fromGetReward = true;
        uint256 reward = calculate(acount, block.timestamp);
        // fromGetReward = false;
        require(reward > 0, "Insufficient reward");
        require(reward <= r3tContract.balanceOf(address(this)), "Insufficient contract balance");
        r3tContract.transfer(acount, reward);
        calculateLastRewardTS(acount);
        rewards[acount].push(reward);
        totalRewards += reward;

        emit RewardPaid(
            acount,
            reward,
            rewards[acount].length - 1,
            block.timestamp
        );
    }

/*     function setRewardYearPercent(uint256 _rewardYearPercent) public onlyOwner {
        require(percentIndexTS[rewardYearPercent.length - 1] + DAY < block.timestamp, "You can change the extraPercent only once a day");
        percentIndexTS[rewardYearPercent.length] = block.timestamp;
        rewardYearPercent.push(_rewardYearPercent);
    } */
    
    // todo coment about decimal extra extraPercent

    function notOvelrlaps(uint256 _startTS, uint256 _endTS, uint8 _boostYear) internal view returns (bool) {
        for(uint256 i = 0; i < boosts[_boostYear].length; i++) {
            BoostParams memory oneBoost = boosts[_boostYear][i];
            if(! (oneBoost.startTS >= _endTS || oneBoost.endTS <= _startTS)) {
                if(oneBoost.active) {
                    return false;
                }
            }
        }
        return true;
    }

    function boost(uint8 _boostYear, uint256 _startTS, uint256 _days, uint256 _extraPercent) public onlyOwner {
        require(_days > 0, "Incorrect days count");
        require(_boostYear >= 1 && _boostYear <= 5, "Boost can be set only for 1-5 years");
        require(block.timestamp < _startTS, "Wrong timestamps!");
        uint256 _endTS = _startTS + _days * DAY;       
        require(notOvelrlaps(_startTS, _endTS, _boostYear), "Wrong timestamps!");
        BoostParams memory params = BoostParams(
            true,
            _boostYear,
            boosts[_boostYear].length,
            _startTS,
            _endTS,
            _extraPercent
        );
        boosts[_boostYear].push(params);
    }

    function removeBoost(uint8 _boostYear, uint256 _boostOrder) public onlyOwner {
        require(_boostOrder < boosts[_boostYear].length , "Ther is no such boost!");       
        require(boosts[_boostYear][_boostOrder].active == true, "Boost is already deactivated!");       
        require(boosts[_boostYear][_boostOrder].startTS > block.timestamp, "Boost can't be deactivated!");       
        boosts[_boostYear][_boostOrder].active = false;
    }

    function fundContractBalanceR3T(uint256 _amount) external onlyOwner {  
        require(_amount > 0, "Invalid fund");

        r3tContract.transferFrom(msg.sender, address(this), _amount);
    }

    function createNewStakingSession(uint256 _amount) internal {
        StakeParams memory params = StakeParams(
            true,
            stakingBalances[msg.sender].length,
            block.timestamp,
            _amount,
            block.timestamp
        );
        stakingBalances[msg.sender].push(params);
        
        bool existingStaker = checkExistingStaker(msg.sender);

        if (!existingStaker) stakers.push(msg.sender);
    }

    function checkExistingStaker(address _account)
        internal
        view
        returns (bool)
    {
        for (uint256 index = 0; index < stakers.length; index++) {
            if (stakers[index] == _account) return true;
        }

        return false;
    }

    function withdrawRT(address account, uint256 amount) public onlyOwner {
        require(rtContract.balanceOf(address(this)) >= amount, "RANCH: over contract supply");

        rtContract.transfer(account, amount);
    }
    
    function withdrawBNB() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Insufficient balance");
        payable(msg.sender).transfer(amount);
    }

    function withdrawToken(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20 _token = IERC20(tokenAddress);
        require(
            _token.balanceOf(address(this)) >= amount,
            "Insufficient balance"
        );
        _token.transfer(msg.sender, amount);
    }

    receive() external payable {}

//     /* ========== EVENTS ========== */
    event Staked(address indexed user, uint256 amount, uint256 blockTime);
    event RewardPaid(
        address indexed user,
        uint256 rewardAmount,
        uint256 rewardorder,
        uint256 blockTime
    ); 
}