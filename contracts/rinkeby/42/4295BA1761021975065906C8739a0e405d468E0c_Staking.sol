// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

//import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC20Mintable.sol";
import "./IStaking.sol";
import "./IDAO.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is IStaking, Ownable {// is AccessControl {

//requer mint for rewardableToken

    struct StakeHolder {
        //uint64 id;
        uint64 reward;
        uint64 timeStartStake;
        uint128 amount;
    }

    uint16 public rewardPercentage;
    uint64 public lockTime;
    uint32 public rewardCircleTimer;
    
    address public lpToken;
    address public rewardableToken;
    address public dao;

    mapping (address => StakeHolder) _stakeHolders;

    constructor(address lpToken_, address rewardableToken_) {
        lpToken = lpToken_;
        rewardableToken = rewardableToken_;

        rewardCircleTimer = 1 weeks; // 1 week
        rewardPercentage = 300; //3.00 %
        lockTime = 2 weeks; //2 weeks
    }

    modifier onlyDAO() {
        require(dao == msg.sender, "Staking: need dao role");
        _;
    }

    function getLockedTokenAmount(address accountAddress) external view virtual override returns(uint128) {
        return _stakeHolders[accountAddress].amount;
    }

    function getCurrentSaveReward(address accountAddress) external view virtual override returns(uint64) {
        return _stakeHolders[accountAddress].reward;
    }

    function getTimeStartStake(address accountAddress) external view virtual override returns(uint64) {
        return _stakeHolders[accountAddress].timeStartStake;
    }

    function setDAO(address newDAOAddress) external virtual override onlyOwner {
        dao = newDAOAddress;
    }

    function stake(uint128 amount) external virtual override {
        address sender = msg.sender;
        IERC20(lpToken).transferFrom(sender, address(this), amount);

        StakeHolder storage stakeHolder = _stakeHolders[sender];
        uint64 timeStamp = uint64(block.timestamp);

        //calculate current reward
        uint128 amountInStake = stakeHolder.amount;
        uint64 countCycles = (timeStamp - stakeHolder.timeStartStake) / rewardCircleTimer;
        uint256 reward = amountInStake * countCycles * rewardPercentage / 10000; // / 100.00%

        //update stake data
        stakeHolder.timeStartStake = timeStamp;
        stakeHolder.reward += uint64(reward);
        stakeHolder.amount += amount;

        emit Staked(sender, amount, timeStamp);
    }

    function claim() public virtual override {
        address sender = msg.sender;
        StakeHolder storage stakeHolder = _stakeHolders[sender];

        require(stakeHolder.amount > 0, "Staking: User has not staked yet");
        
        uint64 timeStamp = uint64(block.timestamp);
      
        //calculate current reward
        uint256 amountInStake = stakeHolder.amount;
        uint256 countCycles = (timeStamp - stakeHolder.timeStartStake) / rewardCircleTimer;
        uint256 reward = amountInStake * countCycles * rewardPercentage / 10000; // / 100.00%
        reward += stakeHolder.reward;
        
        stakeHolder.timeStartStake = timeStamp;
        stakeHolder.reward = 0;

        IERC20Mintable(rewardableToken).mint(sender, reward);

        emit Claimed(sender, reward);
    }

    function unstake() external virtual override {
        address sender = msg.sender;
        StakeHolder storage stakeHolder = _stakeHolders[sender];

        uint64 timeStamp = uint64(block.timestamp);
        require(timeStamp > (stakeHolder.timeStartStake + lockTime), "Staking:lock time not passed");
        
        require(IDAO(dao).allVotesFinished(sender), "Staking: votes not finished");

        claim();
        
        uint256 amount = stakeHolder.amount;
        stakeHolder.amount = 0;

        IERC20(lpToken).transfer(sender, amount);

        emit Unstaked(sender, amount, uint64(block.timestamp));
    }

    function setLockTime(uint64 newLockTime) external virtual override onlyDAO {
        
        lockTime = newLockTime;

        emit LockTimeUpdated(lockTime);
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
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IStaking {
    event Staked(address stakeHoldersAddress, uint256 amount, uint64 timeStartStake);
    event Unstaked(address stakeHoldersAddress, uint256 amount, uint64 unstakeTime);
    event Claimed(address stakeHoldersAddress, uint256 amount);

    event RewardCircleTimerUpdated(uint256 amount);
    event LockTimeUpdated(uint64 amount);
    event RewardPercentageUpdated(uint8 amount);

    function getLockedTokenAmount(address accountAddress) external view returns(uint128);
    function getCurrentSaveReward(address accountAddress) external view returns(uint64);
    function getTimeStartStake(address accountAddress) external view returns(uint64);
    
    function setDAO(address newDAOAddress) external;

    function stake(uint128 amount) external;
    function claim() external;
    function unstake() external;
    function setLockTime(uint64 newLockTime) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IDAO {
    function allVotesFinished(address voterAddress) external returns(bool);
    function setStakingAddress(address newStaking) external;
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