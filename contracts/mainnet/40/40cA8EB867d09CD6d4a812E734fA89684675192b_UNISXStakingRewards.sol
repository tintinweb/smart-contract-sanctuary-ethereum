// SPDX-License-Identifier: MIT

// Based on https://github.com/Synthetixio/synthetix/blob/master/contracts/StakingRewards.sol

pragma solidity ^0.8;

import "./OpenZeppelin/Ownable.sol";
import "./interfaces/IERC20Min.sol";
import "./interfaces/ITokenManagerMin.sol";
import "./interfaces/IVaultMin.sol";

contract UNISXStakingRewards is Ownable {
    IVaultMin public immutable treasury;
    IERC20Min public immutable UNISXToken;
    ITokenManagerMin public immutable xUNISXTokenManager;

    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(
        address _treasuryAddress,
        address _UNISXToken,
        address _tokenManager,
        uint256 _rewardRate
    ) {
        treasury = IVaultMin(_treasuryAddress);
        UNISXToken = IERC20Min(_UNISXToken);
        xUNISXTokenManager = ITokenManagerMin(_tokenManager);
        rewardRate = _rewardRate;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) /
                _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }

        _;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "cannot stake 0");
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        UNISXToken.transferFrom(msg.sender, address(this), _amount);
        xUNISXTokenManager.mint(msg.sender, _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require(_amount > 0, "cannot withdraw 0");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        xUNISXTokenManager.burn(msg.sender, _amount);
        UNISXToken.transfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function getReward() external updateReward(msg.sender) returns (uint256) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        treasury.transfer(address(UNISXToken), msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
        return reward;
    }

    function setRewardRate(uint256 _rewardRate)
        external
        updateReward(address(0))
        onlyOwner
    {
        rewardRate = _rewardRate;
        emit RewardRateSet(rewardRate);
    }

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRateSet(uint256 rewardRate);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

pragma solidity ^0.8.0;

interface IERC20Min {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenManagerMin {
    function mint(address _receiver, uint256 _amount) external;

    function burn(address _holder, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IVaultMin {
    function transfer(address _token, address _to, uint256 _value) external;
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