// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TCGStaking is Ownable {

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many Staking Tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * accTokensPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws Staking Tokens to a  Here's what happens:
        //   1. The pool's `accTokensPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    address public immutable rewardToken;   // Reward ERC-20 Token.
    address public immutable stakingToken;  // Staking ERC20 token
    address public treasuryAddress;
    bool public stakingEnabled = true;
    uint256 public totalReward;
    uint256 public rewardPerBlock; // Tokens distributed per block. Use getTokenPerBlock() to get the updated reward.
    uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
    uint256 public totalStaked;
    uint256 accTokensPerShare;
    uint256 public maxPerWallet;

    mapping(address => UserInfo) public UserInfos; // Info of each user that stakes Staking Tokens.
    uint256 public startBlock; // The block number when token mining starts.
    uint256 public blockRewardUpdateCycle = 1 days; // The cycle in which the rewardPerBlock gets updated.
    uint256 public blockRewardLastUpdateTime = block.timestamp; // The timestamp when the block rewardPerBlock was last updated.
    uint256 public blocksPerDay = 28750; // The estimated number of mined blocks per day.
    uint256 public blockRewardPercentage = 3; // The percentage used for rewardPerBlock calculation.   
    
    constructor(address _rewardToken,  address _stakingToken, uint256 _startBlock, address _treasuryAddress,
        uint256 _totalReward, uint256 _maxPerWallet) 
    {
        require(address(_rewardToken) != address(0), "_rewardToken address is invalid");
        rewardToken = _rewardToken;
        stakingToken = _stakingToken;
        startBlock = _startBlock == 0 ? block.number : _startBlock;        
        treasuryAddress = _treasuryAddress;
        totalReward = _totalReward;
        rewardPerBlock = totalReward * blockRewardPercentage / 100 / blocksPerDay;  
        maxPerWallet = _maxPerWallet;       
    }

    // Update reward variables to be up-to-date when lpSupply changes
    // For every deposit/withdraw recalculates accumulated token value
    function updateRewardVariables() public updateRewardPerBlock {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number - (lastRewardBlock);
        uint256 tokenReward = multiplier * (rewardPerBlock);

        // no minting is required, the contract should have token balance pre-allocated
        // accumulated per share is stored multiplied by 10^12 to allow small 'fractional' values
        accTokensPerShare = accTokensPerShare + (tokenReward * (1e12) / (totalStaked));
        lastRewardBlock = block.number;
    }

    /**** USER FUNCTIONS ****/

    function deposit( uint256 _amount) public {
        require(stakingEnabled, "STAKING_DISABLED");
        UserInfo storage user = UserInfos[msg.sender];
        require(user.amount + _amount <= maxPerWallet, "EXCEEDS_MAX_PER_WALLET");
        if (user.amount > 0) {
            uint256 pending = user.amount * (accTokensPerShare) / (1e12) - (user.rewardDebt);
            if (pending > 0) {
                tokenTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            IERC20(stakingToken).transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + (_amount);
            totalStaked += _amount;
        }
        user.rewardDebt = user.amount * (accTokensPerShare) / (1e12);
        emit Deposit(msg.sender, _amount);
    }

    function withdraw( uint256 _amount) public {
        UserInfo storage user = UserInfos[msg.sender];
        require(user.amount >= _amount, "Withdraw amount is greater than user amount");

        uint256 pending = user.amount * accTokensPerShare / 1e12 - user.rewardDebt;
        if (pending > 0) {
            tokenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {            
            IERC20(stakingToken).transfer(address(msg.sender), _amount);
            
            user.amount = user.amount - (_amount);
            totalStaked -= _amount;
        }
        
        user.rewardDebt = user.amount * (accTokensPerShare) / (1e12);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = UserInfos[msg.sender];
        totalStaked -= user.amount;
        IERC20(stakingToken).transfer(address(msg.sender), user.amount);
        
        user.amount = 0;
        user.rewardDebt = 0;

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /**** VIEWS ****/

    function getRewardPerBlock() public view returns (uint256, bool) {
        if (block.number < startBlock) {
            return (0, false);
        }
        if (totalReward == 0) {
            return (0, rewardPerBlock != 0);
        }

        if (block.timestamp >= getRewardPerBlockUpdateTime() || rewardPerBlock == 0) {
            return (totalReward * (blockRewardPercentage) / (100) / (blocksPerDay), true);
        }

        return (rewardPerBlock, false);
    }

    function getRewardPerBlockUpdateTime() public view returns (uint256) {
        // if blockRewardUpdateCycle = 1 day then roundedUpdateTime = today's UTC midnight
        uint256 roundedUpdateTime = blockRewardLastUpdateTime - (blockRewardLastUpdateTime % blockRewardUpdateCycle);
        // if blockRewardUpdateCycle = 1 day then calculateRewardTime = tomorrow's UTC midnight
        uint256 calculateRewardTime = roundedUpdateTime + blockRewardUpdateCycle;
        return calculateRewardTime;
    }

    // View function to see pending tokens on frontend.
    function pendingRewards(address _user) external view returns (uint256) {
        UserInfo storage user = UserInfos[_user];
        uint256 _accTokensPerShare = accTokensPerShare;
        if (block.number > lastRewardBlock && totalStaked != 0) {
            uint256 multiplier = block.number - (lastRewardBlock);
            (uint256 blockReward, ) = getRewardPerBlock();
            uint256 tokenReward = multiplier * blockReward;
            _accTokensPerShare = _accTokensPerShare + (tokenReward * (1e12) / (totalStaked));
        }
        return user.amount * (_accTokensPerShare) / (1e12) - (user.rewardDebt);
    }

    function getRewardToken1APY() external view returns (uint256) {
        if(totalReward == 0) return 0;
        (uint256 blockReward, ) = getRewardPerBlock();
        uint256 rewardForYear = blockReward * blocksPerDay * 365;
        return rewardForYear / totalStaked;
    }

    function getRewardToken1WPY() external view returns (uint256) {
        if(totalReward == 0) return 0;
        (uint256 blockReward, ) = getRewardPerBlock();
        uint256 rewardForYear = blockReward * blocksPerDay * 7;
        return rewardForYear / totalStaked;
    }

    /**** UTILITY ****/

    // Safe token transfer function, just in case if
    // rounding error causes pool to not have enough tokens
    function tokenTransfer(address _to, uint256 _amount) internal {
        uint256 amount = _amount > totalReward ? totalReward : _amount;
        IERC20(rewardToken).transfer(_to, amount);
        totalReward -= amount;
    }

    /**** ADMIN ****/

    function setTotalReward(uint256 amount) external onlyOwner {
        totalReward = amount;
        rewardPerBlock = totalReward * blockRewardPercentage / 100 / blocksPerDay;  
    }

    function addTotalReward(uint256 amount) external onlyOwner {
        totalReward += amount;
        rewardPerBlock = totalReward * blockRewardPercentage / 100 / blocksPerDay;  
    }

    function toggleStakingEnabled() external onlyOwner {
        stakingEnabled = !stakingEnabled;
    }

    function setBlockRewardUpdateCycle(uint256 _blockRewardUpdateCycle) external onlyOwner {
        require(_blockRewardUpdateCycle > 0, "Value is zero");
        blockRewardUpdateCycle = _blockRewardUpdateCycle;
    }

    // Just in case an adjustment is needed since mined blocks per day
    // changes constantly depending on the network
    function setBlocksPerDay(uint256 _blocksPerDay) external onlyOwner {
        require(_blocksPerDay >= 1000 && _blocksPerDay <= 40000, "Value is outside of range 1000-40000");
        blocksPerDay = _blocksPerDay;
    }

    function setBlockRewardPercentage(uint256 _blockRewardPercentage) external onlyOwner {
        require(_blockRewardPercentage >= 1 && _blockRewardPercentage <= 5, "Value is outside of range 1-5");
        blockRewardPercentage = _blockRewardPercentage;
    }
    
    function transferTokens(address _tokenAddr) external {
        IERC20(_tokenAddr).transfer(treasuryAddress, IERC20(_tokenAddr).balanceOf(address(this)));
    }    

    function withdrawETH() external {
        require(treasuryAddress != address(0), "TREASURY_NOT_SET");
        uint256 bal = address(this).balance;
        (bool sent, ) = treasuryAddress.call{value: bal}("");
        require(sent, "FAILED_SENDING_FUNDS");
        emit WithdrawETH(_msgSender(), bal);
    }     

    modifier updateRewardPerBlock() {
        (uint256 blockReward, bool update) = getRewardPerBlock();
        if (update) {
            rewardPerBlock = blockReward;
            blockRewardLastUpdateTime = block.timestamp;
        }
        _;
    }    

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event WithdrawETH(address indexed sender, uint256 indexed balance);
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