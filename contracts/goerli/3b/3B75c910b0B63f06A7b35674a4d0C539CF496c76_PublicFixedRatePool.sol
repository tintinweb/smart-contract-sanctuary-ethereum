// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStakePool.sol";

contract PublicFixedRatePool is Ownable, ReentrancyGuard, IStakePool {
    event Refunded(address indexed user, uint256 indexed amount);

    mapping(address => uint256) public occupiedBalances; 
    mapping(address => uint256) private _unlockedBalances;
    mapping(address => StakingInfo[]) private _lockedBalances;
    
    mapping(address => uint256) private _remainBalances;
    mapping(address => uint256) private _earned;
    mapping(address => uint256) private rewards;
    

    struct StakingInfo {
        uint256 amount;
        uint256 lastUpdateTime;
        uint256 endTime;
    }

    
    uint256 private _totalSupply;
    uint256 public constant decimals = 1e18;
    uint256 public endTime; // end time of the pool
    uint256 public rewardRate; // The reward rate means the rate of XBT that will be rewarded to the user every second when the user stakes.
    uint256 public stakePeriod;
    uint256 public minStakeRequire;
    uint256 public maxStakeRequire;
    uint256 private _userAmount;

    IERC20 public immutable XBTToken;
    IERC20 public immutable rewardToken;

    constructor(
        address _xbtToken,
        address _rewardToken,
        uint256 _stakePeriod,
        uint256 _poolPeriod,
        uint256 _rewardRate,
        uint256 _minStakeRequire,
        uint256 _maxStakeRequire
    ) Ownable() {
        XBTToken = IERC20(_xbtToken);
        rewardToken = IERC20(_rewardToken);
        endTime = block.timestamp + _poolPeriod;
        stakePeriod = _stakePeriod;
        minStakeRequire = _minStakeRequire;
        maxStakeRequire = _maxStakeRequire;
        rewardRate = _rewardRate;
    }

    /***********************************|
    |                View               |
    |__________________________________*/

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function unlockedBalanceOf(address _user)
        external
        view
        returns (uint256)
    {
        uint256 res = _unlockedBalances[_user];
        for (uint256 i = 0; i < _lockedBalances[_user].length; i++) {
            if (_lockedBalances[_user][i].endTime <= block.timestamp) {
                res += _lockedBalances[_user][i].amount;
            }
        }
        return res + (block.timestamp > endTime ? _remainBalances[_user] : 0);
    }

    function lockedBalanceOf(address _user)
        external
        view
        returns (uint256)
    {
        uint256 res = 0;
        for (uint256 i = 0; i < _lockedBalances[_user].length; i++) {
            if (_lockedBalances[_user][i].endTime > block.timestamp) {
                res += _lockedBalances[_user][i].amount;
            }
        }
        return res;
    }

    function calcReward(address _user) external view returns (uint256) {
        uint256 res = rewards[_user];
        for (uint256 i = 0; i < _lockedBalances[_user].length; i++) {
            uint effectiveEndTime = _lockedBalances[_user][i].endTime > block.timestamp ? block.timestamp : _lockedBalances[_user][i].endTime;
            res += (_lockedBalances[_user][i].amount * rewardRate * (effectiveEndTime - _lockedBalances[_msgSender()][i].lastUpdateTime)) / decimals;
        }
        return res;
    }

    function getUserAmount() external view returns (uint256) {
        return _userAmount;
    }

    function getEarned(address _account) external view returns (uint256) {
        return _earned[_account];
    }


    /***********************************|
    |                Core               |
    |__________________________________*/

    function stake(uint256 _amount) external nonReentrant {
        require(
            block.timestamp < endTime,
            "Pool is not active"
        );
        require(
            _amount >= minStakeRequire,
            "stake amount must be greater than min stake require amount"
        );
        require(
            _amount + occupiedBalances[_msgSender()] <= maxStakeRequire,
            "staking amount must be less than max staking require amount"
        );
        if (block.timestamp + stakePeriod <= endTime) {
            _lockedBalances[_msgSender()].push(
                StakingInfo(_amount, block.timestamp, block.timestamp + stakePeriod)
            );
        } else {
            _remainBalances[_msgSender()] += _amount;
        }

        XBTToken.transferFrom(_msgSender(), address(this), _amount);
        _totalSupply += _amount;
        occupiedBalances[_msgSender()] += _amount;
        if (_lockedBalances[_msgSender()].length <= 1) {
            _userAmount++;
        }
        emit Staked(_msgSender(), _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        for (uint256 i = 0; i < _lockedBalances[_msgSender()].length; i++) {
            if (_lockedBalances[_msgSender()][i].endTime <= block.timestamp) {
                // These balances should be unlocked
                _unlockedBalances[_msgSender()] += _lockedBalances[_msgSender()][i].amount;
                rewards[_msgSender()] +=
                    (_lockedBalances[_msgSender()][i].amount *
                        rewardRate *
                        (_lockedBalances[_msgSender()][i].endTime -
                            _lockedBalances[_msgSender()][i].lastUpdateTime)) /
                    decimals;
                delete _lockedBalances[_msgSender()][i];
            }
        }

        if (block.timestamp >= endTime) {
            _unlockedBalances[_msgSender()] += _remainBalances[_msgSender()];
        }

        require(
            _amount <= _unlockedBalances[_msgSender()],
            "Amount must be less or equal than your unlocked balance"
        );

        XBTToken.transfer(_msgSender(), _amount);

        _unlockedBalances[_msgSender()] -= _amount;
        _totalSupply -= _amount;

        if (_unlockedBalances[_msgSender()] == 0) {
            _userAmount--;
        }
        emit Withdrawn(_msgSender(), _amount);
    }

    function getReward() external nonReentrant {
        address sender = _msgSender();
        for (uint256 i = 0; i < _lockedBalances[sender].length; i++) {
            if (_lockedBalances[sender][i].endTime >= block.timestamp) {
                rewards[sender] += (_lockedBalances[sender][i].amount * rewardRate * (block.timestamp - _lockedBalances[sender][i].lastUpdateTime)) / decimals;
                _lockedBalances[sender][i].lastUpdateTime = block.timestamp; // Update time
            } else {
                _unlockedBalances[sender] += _lockedBalances[sender][i].amount;
                rewards[sender] += (_lockedBalances[sender][i].amount * rewardRate * (_lockedBalances[sender][i].endTime - _lockedBalances[sender][i].lastUpdateTime)) / decimals;
                delete _lockedBalances[sender][i];
            }
        }
        uint256 reward = rewards[sender];
        rewardToken.transfer(sender, reward);
        rewards[msg.sender] = 0;
        _earned[msg.sender] += reward;
        emit RewardPaid(sender, reward);
    }


    /***********************************|
    |              Setting              |
    |__________________________________*/

    function refund(uint _amount) external onlyOwner {
        require(XBTToken != rewardToken || _amount + _totalSupply <= rewardToken.balanceOf(address(this)), "You shouldn't refund users' token"); // || 

        rewardToken.transfer(_msgSender(), _amount);

        emit Refunded(_msgSender(), _amount);
    }

    function setEndTime(uint _endTime) external onlyOwner {
        endTime = _endTime;
    }

    function setStakePeriod(uint _stakePeriod) external onlyOwner {
        stakePeriod = _stakePeriod;
    }

    function setMinStakeRequire(uint _minStakeRequire) external onlyOwner {
        minStakeRequire = _minStakeRequire;
    }

    function setMaxStakeRequire(uint _maxStakeRequire) external onlyOwner {
        maxStakeRequire = _maxStakeRequire;
    }

    function setRewardRate(uint _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakePool {
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed amount);

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function getReward() external;


    /***********************************|
    |                View               |
    |__________________________________*/

    function endTime() external view returns (uint256);

    function getUserAmount() external view returns (uint256);

    function getEarned(address _user) external view returns (uint256);

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