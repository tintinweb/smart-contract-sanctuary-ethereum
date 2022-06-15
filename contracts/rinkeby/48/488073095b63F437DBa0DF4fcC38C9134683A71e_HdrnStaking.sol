// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IHedron {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

interface ISwap {
    function convertEthToHedronDistribute() external returns (uint256);
}

contract HdrnStaking is Ownable,ReentrancyGuard{
    struct StakeDepositData {
        uint256 stakeId;
        address wallet;
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
        uint256 claimedRewards;
        uint256 lastClaimDay;
        bool activeStaked;
    }

    struct RewardData {
        uint256 rewardForTheDay;
        uint256 totalActiveStakes;
        uint256 day;
    }
    ISwap internal swap;

    uint256 internal LAUNCH_TIME = block.timestamp;
    address internal hdrnToken;
    uint256 public totalHedronStaked;
    uint256 internal rewardToDistribute;
    uint256 public totalRewardCollected;
    mapping(uint256 => StakeDepositData) public stakers;
    mapping(address => StakeDepositData[]) public stakes;

    StakeDepositData[] internal stakersData;
    RewardData[] public dailyRewardData;
  

//5=>{}
    //initialize the contract and set the Hedron token address
    constructor(address _hdrnToken, address _swapContractAddress) {
        hdrnToken = _hdrnToken;
        swap = ISwap(_swapContractAddress);
    }

    receive() external payable {}

    //modifier to check if msg.sender has an active stake
    modifier hasStaked(uint256 stakeId) {
        require(stakers[stakeId].activeStaked, "Stake is not active");
        _;
    }

    event stakeAdded(uint256 stakeId,address wallet,uint256 amount,uint256 startDate, uint256 endDate);
    event stakeRemoved(uint256 stakeId,address wallet,uint256 totalAmountClaimed);
    event claimedReward(uint256 stakeId,address wallet,uint256 amountClaimed);
    // staking function -Used to  stake hedron with the given amount
    function stake(uint256 amount) public nonReentrant  returns (uint256) {
        require(amount > 0, "Amount should be greater than 0");
        require(
            IHedron(hdrnToken).allowance(msg.sender, address(this)) >= amount,
            "No allowance. Please grant hedron allowance"
        );
        require(
            IHedron(hdrnToken).balanceOf(msg.sender) >= amount,
            "Cannot stake more than the balance"
        );
        IHedron(hdrnToken).transferFrom(msg.sender, address(this), amount);
        uint256 newStakeId = stakersData.length;
        stakers[newStakeId] = StakeDepositData({
            stakeId: newStakeId,
            wallet: msg.sender,
            amount: amount,
            startDate: block.timestamp,
            endDate: block.timestamp + 2 days,
            claimedRewards: 0,
            lastClaimDay: currentDay(),
            activeStaked: true
        });
        stakes[msg.sender].push(stakers[newStakeId]);
        stakersData.push(stakers[newStakeId]);
        assert(stakersData[newStakeId].wallet == msg.sender);
        totalHedronStaked += amount;
        emit stakeAdded(newStakeId,msg.sender,amount,block.timestamp,block.timestamp+2 days);
        return newStakeId;
    }

    function updateRewardRate() public {
     
        dailyRewardData.push(
            RewardData({rewardForTheDay: rewardToDistribute,totalActiveStakes:totalActiveStakes() ,day: currentDay()})
        );
        rewardToDistribute = 0;
    }

    //unstake function-used to  remove the stake after 369  days
    function unstake(uint256 stakeId) public nonReentrant  hasStaked(stakeId) {
          require(msg.sender == stakers[stakeId].wallet,"Wrong wallet address");
        require(
            hasCompletedStakingPeriod(stakeId),
            "Staking period is not over"
        );

     uint256 reward = calculateRewards(stakeId);
        uint256 total_amount = stakers[stakeId].amount+reward;
        stakers[stakeId].activeStaked = false;
        IHedron(hdrnToken).transfer(stakers[stakeId].wallet, total_amount);
    emit stakeRemoved(stakeId, stakers[stakeId].wallet,total_amount);

    }

    //user can ESS and lose 50% of hedron
    function emergencyEndStake(uint256 stakeId) public nonReentrant  hasStaked(stakeId) {
        require(msg.sender == stakers[stakeId].wallet,"Wrong wallet address");
        uint256 reward = calculateRewards(stakeId);
        uint256 total_amount = (stakers[stakeId].amount / 2) + reward;
        stakers[stakeId].activeStaked = false;
        IHedron(hdrnToken).transfer(stakers[stakeId].wallet, total_amount);
        rewardToDistribute = rewardToDistribute+stakers[stakeId].amount / 2;
    }
    // to fetch and add reward to distribute
    function fetchRewards() public {
        uint256 hedronReceived = swap.convertEthToHedronDistribute();
        rewardToDistribute += hedronReceived;
        totalRewardCollected += hedronReceived;
    }

    function claimReward(uint256 stakeId) public nonReentrant  hasStaked(stakeId) {
        uint256 reward = calculateRewards(stakeId);
        require(reward > 0, "No reward available to claim");
        stakers[stakeId].claimedRewards= stakers[stakeId].claimedRewards+reward;
        stakers[stakeId].lastClaimDay=currentDay();

        IHedron(hdrnToken).transfer(stakers[stakeId].wallet, reward);
        emit claimedReward(stakeId,stakers[stakeId].wallet,reward);
    }

    function CompoundReward(uint256 stakeId) public hasStaked(stakeId){
        uint256 reward = calculateRewards(stakeId);
        require(reward > 0, "No reward available to compound");
        stakers[stakeId].claimedRewards= stakers[stakeId].claimedRewards+reward;
        stakers[stakeId].lastClaimDay=currentDay();
        stakers[stakeId].amount=stakers[stakeId].amount+reward;
     
    }

    function totalActiveStakes() public view returns (uint256) {
        uint256 totalStakes;
        for (uint256 i = 0; i < stakersData.length; i++) {
            require(!hasCompletedStakingPeriod(stakersData[i].stakeId));
            totalStakes += stakersData[i].amount;
        }
        return totalStakes;
    }

    function currentDay() public view returns (uint256) {
        return _currentDay();
    }

    function getStakes(address wallet)
        public
        view
        returns (StakeDepositData[] memory)
    {
        return stakes[wallet];
    }


    function calculateRewards(uint256 stakeId) public view returns (uint256) {
     
        StakeDepositData memory s = stakers[stakeId];
        uint256 day=s.endDate/1 days;
        uint256 reward;
        uint256 totalDays=day<dailyRewardData.length?day:dailyRewardData.length;
       
        for (uint256 i = s.lastClaimDay; i < totalDays ; i++) {
            reward += (s.amount * dailyRewardData[i].rewardForTheDay)/dailyRewardData[i].totalActiveStakes;
        }
        return reward;
    }

    function _currentDay() internal view returns (uint256) {
        return (block.timestamp - LAUNCH_TIME) / 1 days;
    }

    function hasCompletedStakingPeriod(uint256 stakeId)
        internal
        view
        returns (bool)
    {
        if (block.timestamp >= stakers[stakeId].endDate) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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