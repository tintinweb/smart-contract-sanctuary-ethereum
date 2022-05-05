/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*

                         ,@[email protected]@@ggg,
                        [email protected],
                      ,@[email protected],
                     [email protected],
                    @[email protected]
                  ,@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$g,
                 g$$$$N*"'              "**%[email protected],
               ,@@*'                          "N$$$$$$$$$$$$$$$$$$$g
              /"                                  *[email protected],
                                                    "%$$$$$$$$$$$$$$$$k
                                                      '%$$$$$$$$$$$$$$$g
                                                        *$$$$$$$$$$$$$$$g
                                                       _,]$$$$$$$$$$$$$$$k
                                               ,,[email protected]@@$$$$$$$$$$$$$$$$$$$$
                                      _,,[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$F
                              ,,[email protected]@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                     _,,[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                   `"**N%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                            `"*N%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
                                    `"**N%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$[
                                             `"*N%$$$$$$$$$$$$$$$$$$$$$$$$
                                                     `"**%$$$$$$$$$$$$$$$F
                                                        ,@[email protected]
                                                       g$$$$$$$$$$$$$$$$
                                                     [email protected][email protected]
              ,                                   ,[email protected]$$$$$$$$$$$$$$$$F
               ]@g                             ,[email protected]$$$$$$$$$$$$$$$$$$"
                '[email protected]@g,                   ,[email protected]$$$$$$$$$$$$$$$$$$$$F
                  %[email protected]@@[email protected]@@$$$$$$$$$$$$$$$$$$$$$$$$F
                   "[email protected]"
                     %[email protected]*
                      ]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$N"
                        [email protected]"
                         ]$$$$$$$$$$$$$$$$$$%M*"
                           `""""""""""'
    
 * ---------------------------
 * LP Staking for NFT Battles by Cells
 * https://nftbattles.xyz
 * https://cells.land
 * https://discord.gg/cells
 * ---------------------------
 */

contract StakingOwnable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract StakedToken {
    struct Reward {
        address token;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
        uint256 lastUpdateTime;
        uint256 periodFinish;
        uint256 balance;
        uint256 dailySupply;
        bool mintable;
        bool lockedOnly;
    }

    struct UserRewards {
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }

    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }

    struct Balances {
        uint256 total;
        uint256 unlocked;
        uint256 locked;
    }

    struct RewardData {
        address token;
        uint256 amount;
    }    

    IERC20 public stakedToken;

    address[] public rewardTokens;
    
    uint256 public constant rewardsDuration = 7 days;
    uint256 public constant lockDuration = rewardsDuration * 4;

    uint256 public totalSupply;
    uint256 public lockedSupply;    

    mapping(address => Balances) public balances;
    mapping(address => LockedBalance[]) public userLocks;
    mapping(address => Reward) public rewardData;
    mapping(address => mapping(address => UserRewards)) public userRewards;

    event Staked(address indexed user, uint256 amount, bool lock);
    event Withdrawn(address indexed user, uint256 amount);

    function stakeFor(address forWhom, uint256 amount, bool lock) public virtual {
        IERC20 st = stakedToken;
        Balances storage bal = balances[forWhom];
        
        require(amount > 0, 'Cannot stake 0');
        require(st.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        if (lock) {
            lockedSupply += amount;
            bal.locked += amount;
            uint256 unlockTime = block.timestamp / rewardsDuration * rewardsDuration + lockDuration;
            uint256 idx = userLocks[forWhom].length;
            if (idx == 0 || userLocks[forWhom][idx-1].unlockTime < unlockTime) {
                userLocks[forWhom].push(LockedBalance({amount: amount, unlockTime: unlockTime}));
            } else {
                userLocks[forWhom][idx-1].amount += amount;
            }
        } else {
            bal.unlocked += amount;
        }
        totalSupply += amount;
        bal.total += amount;
        
        emit Staked(forWhom, amount, lock);
    }

    function withdraw(uint256 amount) public virtual {
        require(amount > 0, "Cannot withdraw 0");
        Balances storage bal = balances[msg.sender];
        require(amount <= bal.unlocked, "Amount exceeds unlocked balance");
        bal.unlocked -= amount;
        bal.total -= amount;
        totalSupply -= amount;
        stakedToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);            
    }

    // Information on a user's locked balances
    function lockedBalances(
        address user
    ) view external returns (
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    ) {
        LockedBalance[] storage locks = userLocks[user];
        for (uint i = 0; i < locks.length; i++) {
            if (locks[i].unlockTime > block.timestamp) {
                locked += locks[i].amount;
            } else {
                unlockable += locks[i].amount;
            }
        }
        return (balances[user].total, unlockable, locked, locks);
    }

    function allRewardTokens() view external returns (address[] memory) {
        return rewardTokens;
    }
    
}

contract ERC20Staking is StakedToken, StakingOwnable {
    event RewardAdded(address indexed token, uint256 reward);
    event RewardPaid(address indexed user, address indexed token, uint256 reward);
    
    constructor(address _stakedToken, address _rewardToken, uint256 _reward) {
        stakedToken = IERC20(_stakedToken);
        rewardTokens.push(_rewardToken);
        rewardData[_rewardToken].token = _rewardToken;
        rewardData[_rewardToken].balance = _reward;
        rewardData[_rewardToken].rewardRate = _reward / rewardsDuration;
        rewardData[_rewardToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardToken].periodFinish = block.timestamp + rewardsDuration;
        rewardData[_rewardToken].mintable = true;
        rewardData[_rewardToken].lockedOnly = true;
    }

    modifier updateReward(address account) {
        uint256 supply = totalSupply;
        uint256 length = rewardTokens.length;
        for (uint i = 0; i < length; i++) {
            address token = rewardTokens[i];
            Reward storage r = rewardData[token];
            uint rpt = _rewardPerToken(token, r.lockedOnly ? lockedSupply : supply);
            r.rewardPerTokenStored = rpt;
            r.lastUpdateTime = lastTimeRewardApplicable(token);
            uint bal = r.lockedOnly ? balances[account].locked : balances[account].total;
            if (account != address(this)) {
                userRewards[account][token].rewards = _earned(account, token, bal, rpt);
                userRewards[account][token].userRewardPerTokenPaid = rpt;
            }
        }
        _;
    }

    function lastTimeRewardApplicable(address _token) public view returns (uint256) {
        uint256 blockTimestamp = block.timestamp;
        uint256 periodFinish = rewardData[_token].periodFinish;
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }

    function rewardPerToken(address token) public view returns (uint256) {
        if (rewardData[token].lockedOnly) return _rewardPerToken(token, lockedSupply);
        return _rewardPerToken(token, totalSupply);
    }

    function _rewardPerToken(address token, uint256 supply) internal view returns (uint256) {
        uint256 rewardRate = rewardData[token].rewardRate;
        uint256 rewardPerTokenStored = rewardData[token].rewardPerTokenStored;
        uint256 lastUpdateTime = rewardData[token].lastUpdateTime;
        if (supply == 0) {
            return rewardPerTokenStored;
        }
        unchecked {
            uint256 rewardDuration = lastTimeRewardApplicable(token) - lastUpdateTime;
            return
                uint256(
                    rewardPerTokenStored +
                        (rewardDuration * rewardRate * 1e18) /
                        supply
                );
        }
    }

    function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
        return rewardData[_rewardsToken].rewardRate * rewardsDuration;
    }
    
    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address account) external view returns (RewardData[] memory rewards) {
        rewards = new RewardData[](rewardTokens.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            bool lockedOnly = rewardData[rewardTokens[i]].lockedOnly;
            uint256 balance = lockedOnly ? balances[account].locked : balances[account].total;
            uint256 supply = lockedOnly ? lockedSupply : totalSupply;
            rewards[i].token = rewardTokens[i];
            rewards[i].amount = _earned(account, rewards[i].token, balance, _rewardPerToken(rewardTokens[i], supply));
        }
        return rewards;
    }

    function _earned(address account, address token, uint256 balance, uint256 currentRewardPerToken) internal view returns (uint256) {
        unchecked {
            return
                uint256(
                    (balance *
                        (currentRewardPerToken -
                            userRewards[account][token].userRewardPerTokenPaid)) /
                        1e18 +
                        userRewards[account][token].rewards
                );
        }
    }    

    function stake(uint256 amount, bool lock) external {
        stakeFor(msg.sender, amount, lock);
    }

    function stakeFor(address forWhom, uint256 amount, bool lock)
        public
        override
        updateReward(forWhom)
    {
        super.stakeFor(forWhom, amount, lock);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        super.withdraw(amount);
    }

    function getAllRewards() public {
        getReward(rewardTokens);
    }

    function getReward(address[] memory _tokens) public updateReward(msg.sender) {
        uint256 length = _tokens.length;
        for (uint i; i < length; i++) {
            address token = _tokens[i];
            uint256 reward = userRewards[msg.sender][token].rewards;
            Reward storage r = rewardData[token];
            uint256 periodFinish = r.periodFinish;
            require(periodFinish > 0, "Unknown reward token");
            if (periodFinish < block.timestamp + rewardsDuration - 86400) {
                uint256 notifyAmount = r.dailySupply;
                if (!r.mintable) {
                    uint currBalance = IERC20(token).balanceOf(address(this));
                    notifyAmount = currBalance - r.balance;
                }
                if (notifyAmount > 0) {
                    _notifyReward(token, notifyAmount);
                    r.balance += notifyAmount;
                } else {
                    r.lastUpdateTime = block.timestamp;
                    r.periodFinish = block.timestamp + rewardsDuration;
                }
            }
            if (reward == 0) continue;
            userRewards[msg.sender][token].rewards = 0;
            if (r.mintable) {
                IERC20(token).mint(msg.sender, reward);
            } else {
                r.balance -= reward;
                IERC20(token).transfer(msg.sender, reward);
            }
            emit RewardPaid(msg.sender, token, reward);
        }
    }

    // Withdraw all currently locked tokens where the unlock time has passed
    function withdrawExpiredLocks() external updateReward(msg.sender) {
        LockedBalance[] storage locks = userLocks[msg.sender];
        Balances storage bal = balances[msg.sender];
        uint256 amount;
        uint256 length = locks.length;
        if (locks[length-1].unlockTime <= block.timestamp) {
            amount = bal.locked;
            delete userLocks[msg.sender];
        } else {
            for (uint i = 0; i < length; i++) {
                if (locks[i].unlockTime > block.timestamp) break;
                amount += locks[i].amount;
                delete locks[i];
            }
        }
        require(amount > 0, "Can't withdraw zero");
        bal.locked -= amount;
        bal.total -= amount;
        totalSupply -= amount;
        lockedSupply -= amount;
        stakedToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function _notifyReward(address _rewardsToken, uint256 _reward) internal {
        Reward storage r = rewardData[_rewardsToken];
        if (block.timestamp >= r.periodFinish) {
            r.rewardRate = _reward / rewardsDuration;
        } else {
            uint256 remaining = r.periodFinish - block.timestamp;
            uint256 leftover = remaining * r.rewardRate;
            r.rewardRate = (_reward + leftover) / rewardsDuration;
        }
        r.lastUpdateTime = block.timestamp;
        r.periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(_rewardsToken, _reward);
    }

    // Add a new reward token to be distributed to stakers
    function addReward(address _rewardsToken, uint256 _reward, uint256 _dailySupply, bool _mintable, bool _lockedOnly) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime == 0, "Reward already exists");
        uint balance = _mintable ? _reward : IERC20(_rewardsToken).balanceOf(address(this));
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].token = _rewardsToken;
        rewardData[_rewardsToken].mintable = _mintable;
        rewardData[_rewardsToken].balance = balance;
        rewardData[_rewardsToken].rewardRate = balance / rewardsDuration;
        rewardData[_rewardsToken].dailySupply = _mintable ? _dailySupply : 0;
        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp + rewardsDuration;
        rewardData[_rewardsToken].lockedOnly = _lockedOnly;
    }

    function modifyDailySupply(address _rewardsToken, uint256 _dailySupply) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime != 0, "Invalid reward");
        rewardData[_rewardsToken].dailySupply = _dailySupply;
    }

    function modifyRewardRate(address _rewardsToken, uint256 _balance) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime != 0, "Invalid reward");
        rewardData[_rewardsToken].rewardRate = _balance / rewardsDuration;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakedToken), "Cannot withdraw staking token");
        require(tokenAddress != rewardData[tokenAddress].token || rewardData[tokenAddress].mintable, "Cannot withdraw not mintable token");
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }

}