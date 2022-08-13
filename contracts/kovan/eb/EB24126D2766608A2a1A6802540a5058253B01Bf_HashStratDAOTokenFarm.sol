// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
pragma abicoder v2;

import "./StakingPool.sol";
import "./IHashStratDAO.sol";

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/**
 * A Farm contract to distribute HashStrat DAO tokens among LP token stakers proportionally to the amount and duration of the their stakes.
 * Users are free to add and remove tokens to their stake at any time.
 * Users can also claim their pending HashStrat DAO tokens at any time.
 *
 * The contract implements an efficient O(1) algo to distribute the rewards based on this paper:
 * https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf
 */

contract HashStratDAOTokenFarm is StakingPool  {

    event RewardPaid(address indexed user, uint256 reward);

    struct RewardPeriod {
        uint id;
        uint reward;
        uint from;
        uint to;
        uint lastUpdated; // when the totalStakedWeight was last updated (after last stake was ended)
        uint totalStaked; // T: sum of all active stake deposits
        uint rewardPerTokenStaked; // S: SUM(reward/T) - sum of all rewards distributed divided all active stakes
        uint totalRewardsPaid; 
    }

    struct UserInfo {
        uint userRewardPerTokenStaked;
        uint pendingRewards;
        uint rewardsPaid;
    }

    struct RewardsStats {
        // user stats
        uint claimableRewards;
        uint rewardsPaid;
        // general stats
        uint rewardRate;
        uint totalRewardsPaid;
    }

    // The DAO token give out to LP stakers
    IERC20Metadata immutable public hstdaoToken;

    // Predetermined amout of reward periods
    uint public immutable rewardPeriodsCount = 10;
    RewardPeriod[] public rewardPeriods;

    mapping(address => UserInfo) userInfos;

    uint constant rewardPrecision = 1e9;



    constructor(address hstTokenAddress) StakingPool() {
        hstdaoToken = IERC20Metadata(hstTokenAddress);
    }


    //// Public View Functions ////

    function getrewardPeriods() public view returns(RewardPeriod[] memory) {
        return rewardPeriods;
    }


    function hstTokenBalance() public view returns (uint) {
        return hstdaoToken.balanceOf(address(this));
    }


    function getCurrentRewardPeriodId() public view returns (uint) {
        if (rewardPeriodsCount == 0) return 0;
        for (uint i=rewardPeriods.length; i>0; i--) {
            RewardPeriod memory period = rewardPeriods[i-1];
            if (period.from <= block.timestamp && period.to >= block.timestamp) {
                return period.id;
            }
        }
        return 0;
    }


    function getRewardsStats(address account) public view returns (RewardsStats memory) {
        UserInfo memory userInfo = userInfos[msg.sender];

        RewardsStats memory stats = RewardsStats(0, 0, 0, 0);
        // user stats
        stats.claimableRewards = claimableReward(account);
        stats.rewardsPaid = userInfo.rewardsPaid;

        // reward period stats
        uint periodId = getCurrentRewardPeriodId();
        if (periodId > 0) {
            RewardPeriod memory period = rewardPeriods[periodId-1];
            stats.rewardRate = rewardRate(period);
            stats.totalRewardsPaid = period.totalRewardsPaid;
        }

        return stats;
    }

    
    function getStakedLP(address account) public view returns (uint) {
        uint staked = 0;
        for (uint i=0; i<lpTokensArray.length; i++){
            address lpTokenAddress = lpTokensArray[i];
            if (lpTokens[lpTokenAddress]) {
                staked += stakes[account][lpTokenAddress];
            }
        }
        return staked;
    }



    //// Public Functions ////

    function startStake(address lpToken, uint amount) public override {
        uint periodId = getCurrentRewardPeriodId();
        require(periodId > 0, "No active reward period found");
        update();

        super.startStake(lpToken, amount);

        // update total tokens staked
        RewardPeriod storage period = rewardPeriods[periodId-1];
        period.totalStaked += amount;
    }


    function endStake(address lpToken, uint amount) public override {
        update();
        super.endStake(lpToken, amount);

        // update total tokens staked
        uint periodId = getCurrentRewardPeriodId();
        RewardPeriod storage period = rewardPeriods[periodId-1];
        period.totalStaked -= amount;
        
        claim();
    }


    function claimableReward(address account) public view returns (uint) {
        uint periodId = getCurrentRewardPeriodId();
        if (periodId == 0) return 0;

        RewardPeriod memory period = rewardPeriods[periodId-1];
        uint newRewardDistribution = calculateRewardDistribution(period);
        uint reward = calculateReward(account, newRewardDistribution);

        UserInfo memory userInfo = userInfos[account];
        uint pending = userInfo.pendingRewards;

        return pending + reward;
    }

 
    function claimReward() public {
        update();
        claim();
    }


    function addRewardPeriods() public  {

        require(rewardPeriods.length == 0, "Reward periods already set");
        require(hstdaoToken.balanceOf(address(this))  > 0, "Missing DAO tokens");
        require(hstdaoToken.balanceOf(address(this))  == hstdaoToken.totalSupply(), "Should own the whole supply");

        // firt year reward is 500k tokens halving every following year
        uint initialRewardAmount = hstdaoToken.balanceOf(address(this)) / 2;
        
        uint secondsInYear = 365 * 24 * 60 * 60;

        uint rewardAmount = initialRewardAmount;
        uint from = block.timestamp;
        uint to = from + secondsInYear - 1;

        // create all reward periods
        for (uint i=0; i<rewardPeriodsCount; i++) {
            addRewardPeriod(rewardAmount, from, to);
            from = (to + 1);
            to = (from + secondsInYear - 1);
            rewardAmount /= 2;
        }
    }



    //// INTERNAL FUNCTIONS ////

    function claim() internal {
        UserInfo storage userInfo = userInfos[msg.sender];
        uint rewards = userInfo.pendingRewards;
        if (rewards != 0) {
            userInfo.pendingRewards = 0;

            uint periodId = getCurrentRewardPeriodId();
            RewardPeriod storage period = rewardPeriods[periodId-1];
            period.totalRewardsPaid += rewards;

            payReward(msg.sender, rewards);
        }
    }


    function payReward(address account, uint reward) internal {
        UserInfo storage userInfo = userInfos[msg.sender];
        userInfo.rewardsPaid += reward;
        hstdaoToken.transfer(account, reward);

        emit RewardPaid(account, reward);
    }


    function addRewardPeriod(uint reward, uint from, uint to) internal {
        require(reward > 0, "Invalid reward period amount");
        require(to > from && to > block.timestamp, "Invalid reward period interval");
        require(rewardPeriods.length == 0 || from > rewardPeriods[rewardPeriods.length-1].to, "Invalid period start time");

        rewardPeriods.push(RewardPeriod(rewardPeriods.length+1, reward, from, to, block.timestamp, 0, 0, 0));
    }



    /// Reward calcualtion logic

    function rewardRate(RewardPeriod memory period) internal pure returns (uint) {
        uint duration = period.to - period.from;
        return period.reward / duration;
    }


    function update() internal {
        uint periodId = getCurrentRewardPeriodId();
        require(periodId > 0, "No active reward period found");

        RewardPeriod storage period = rewardPeriods[periodId-1];
        uint rewardDistribuedPerToken = calculateRewardDistribution(period);

        // update pending rewards reward since rewardPerTokenStaked was updated
        uint reward = calculateReward(msg.sender, rewardDistribuedPerToken);
        UserInfo storage userInfo = userInfos[msg.sender];
        userInfo.pendingRewards += reward;
        userInfo.userRewardPerTokenStaked = rewardDistribuedPerToken;

        require(rewardDistribuedPerToken >= period.rewardPerTokenStaked, "Reward distribution should be monotonic increasing");

        period.rewardPerTokenStaked = rewardDistribuedPerToken;
        period.lastUpdated = block.timestamp;
    }


    function calculateRewardDistribution(RewardPeriod memory period) internal view returns (uint) {

        // calculate total reward to be distributed since period.lastUpdated
        uint rate = rewardRate(period);
        uint deltaTime = block.timestamp - period.lastUpdated;
        uint reward = deltaTime * rate;

        // S = S + r / T
        uint newRewardPerTokenStaked = (period.totalStaked == 0)?  
                                        period.rewardPerTokenStaked :
                                        period.rewardPerTokenStaked + ( rewardPrecision * reward / period.totalStaked ); 

        return newRewardPerTokenStaked;
    }


    function calculateReward(address account, uint rewardDistribution) internal view returns (uint) {
        if (rewardDistribution == 0) return 0;

        uint staked = getStakedLP(account);
        UserInfo memory userInfo = userInfos[account];
        
        uint reward =  (staked * (rewardDistribution - userInfo.userRewardPerTokenStaked)) / rewardPrecision;

        return reward;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
pragma abicoder v2;

import "./Wallet.sol";


contract StakingPool is Wallet  {

    // using SafeMath for uint256;

    event Staked(address indexed user, address indexed lpTokenAddresses, uint amount);
    event UnStaked(address indexed user, address indexed lpTokenAddresses, uint256 amount);

    // addresses that have active stakes
    address[] public stakers; 

    // account_address => (lp_token_address => stake_balance)
    mapping (address => mapping(address =>  uint)) public stakes;
    uint public totalStakes;
 
    constructor() Wallet() {}


    //// Public View Functions ////

    function getStakers() external view returns (address[] memory) {
        return stakers;
    }

    function getStakedBalance(address account, address lpToken) public view returns (uint) {
        require(lpTokens[lpToken] == true, "LP Token not supported");
        return stakes[account][lpToken];
    }


    //// Public Functions ////

    function depositAndStartStake(address lpToken, uint256 amount) public {
        deposit(lpToken, amount);
        startStake(lpToken, amount);
    }


    function endStakeAndWithdraw(address lpToken, uint amount) public {
        endStake(lpToken, amount);
        withdraw(lpToken, amount);
    }


    function startStake(address lpToken, uint amount) virtual public {
        require(lpTokens[lpToken] == true, "LP Token not supported");
        require(amount > 0, "Stake must be a positive amount greater than 0");
        require(balances[msg.sender][lpToken] >= amount, "Not enough tokens to stake");

        // move tokens from lp token balance to the staked balance
        balances[msg.sender][lpToken] -= amount;
        stakes[msg.sender][lpToken] += amount;
       
        totalStakes += amount;

        emit Staked(msg.sender, lpToken, amount);
    }


    function endStake(address lpToken, uint amount) virtual public {
        require(lpTokens[lpToken] == true, "LP Token not supported");
        require(stakes[msg.sender][lpToken] >= amount, "Not enough tokens staked");

        // return lp tokens to lp token balance
        balances[msg.sender][lpToken] += amount;
        stakes[msg.sender][lpToken] -= amount; 

        totalStakes -= amount;

        emit UnStaked(msg.sender, lpToken, amount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


interface IHashStratDAO {

    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Wallet is Ownable {

    event Deposited(address indexed user, address indexed lpTokenAddress, uint256 amount);
    event Withdrawn(address indexed user, address indexed lpTokenAddress, uint256 amount);

    // account_address -> (lp_token_address -> lp_token_balance)
    mapping(address => mapping(address => uint256) ) public balances;

    // the addresses of LP tokens of the HashStrat Pools and Indexes supported
    address[] internal lpTokensArray;
    mapping(address => bool) internal lpTokens;

    // users that deposited CakeLP tokens into their balances
    address[] internal usersArray;
    mapping(address => bool) internal users;


    //// Public View Functions ////
    function getBalance(address _userAddress, address _lpAddr) external view returns (uint256) {
        return balances[_userAddress][_lpAddr];
    }

    function getUsers() external view returns (address[] memory) {
        return usersArray;
    }

    function getLPTokens() external view returns (address[] memory) {
        return lpTokensArray;
    }


    //// Public Functions ////
    function deposit(address lpAddress, uint256 amount) public {
        require(amount > 0, "Deposit amount should not be 0");
        require(lpTokens[lpAddress] == true, "LP Token not supported");

        require(
            IERC20(lpAddress).allowance(msg.sender, address(this)) >= amount, "Insufficient allowance"
        );

        balances[msg.sender][lpAddress] += amount;

        // remember addresses that deposited LP tokens
        if (!users[msg.sender]) {
            users[msg.sender] = true;
            usersArray.push(msg.sender);
        }

        IERC20(lpAddress).transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, lpAddress, amount);
    }


    function withdraw(address lpAddress, uint256 amount) public {
        require(lpTokens[lpAddress] == true, "LP Token not supported");
        require(balances[msg.sender][lpAddress] >= amount, "Insufficient token balance");

        balances[msg.sender][lpAddress] -= amount;
        IERC20(lpAddress).transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, lpAddress, amount);
    }


    //// ONLY OWNER FUNCTIONALITY ////

    function addLPToken(address lpToken) external onlyOwner {
        if (lpTokens[lpToken] == false) {
            lpTokens[lpToken] = true;
            lpTokensArray.push(msg.sender);
        }
    }

    function removeLPToken(address lpToken) external onlyOwner {
        if (lpTokens[lpToken] == false) {
            lpTokens[lpToken] = true;
        }
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