// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FoeStaking is Ownable {
    IERC20 public FoeToken;

    enum StakeType {
        NULL,
        SILVER,
        GOLD,
        DIAMOND
    }

    event Staked(
        uint256 stakeId,
        address indexed user,
        uint256 stakeAmount,
        uint256 initialTime
    );

    event Unstaked(
        uint256 stakeId,
        address indexed user,
        uint256 withdrawAmount,
        uint256 rewardAmount
    );

    event EmergencyWithdraw(
        uint256 stakeId,
        address indexed user,
        uint256 withdrawAmount
    );

    event StakePlanUpdated(
        StakeType level,
        uint256 apyPercentage,
        uint256 minstakeAmount
    );

    struct UserDetail {
        address user;
        StakeType level;
        uint256 stakeAmount;
        uint256 initialTime;
        uint256 rewardPercent;
        bool stakeStatus;
    }

    struct StakePlan {
        StakeType level;
        uint256 apy;
        uint256 stakeAmount;
    }

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    uint256 public totalStakers = 1;

    uint256 public activeStakers;

    address public signer;

    mapping(uint256 => UserDetail) users;
    mapping(StakeType => StakePlan) plans;
    mapping(uint256 => bool) usedNonce;

    constructor(IERC20 _tokenAddress) {
        FoeToken = _tokenAddress;
        signer = msg.sender;
        plans[StakeType.SILVER] = StakePlan(
            StakeType.SILVER,
            5,
            10000
        );
        plans[StakeType.GOLD] = StakePlan(
            StakeType.GOLD,
            10,
            50000
        );
        plans[StakeType.DIAMOND] = StakePlan(
            StakeType.DIAMOND,
            20,
            100000
        );
    }

    function stake(StakeType level, uint256 amount, Sign memory sign) external returns (bool) {
        require(
            level == StakeType.SILVER ||
                level == StakeType.GOLD ||
                level == StakeType.DIAMOND,
            "Invalid Level"
        );
        require(!usedNonce[sign.nonce], "Invalid Nonce");
        usedNonce[sign.nonce] = true;
        require(amount >= plans[level].stakeAmount, "user need to stake minimum stake Amount");
        verifySign(uint256(level), msg.sender, amount, sign);
        uint256 stakeId = totalStakers;
        users[stakeId] = UserDetail(
            msg.sender,
            level,
            amount,
            block.timestamp,
            plans[level].apy,
            true
        );
        FoeToken.transferFrom(msg.sender, address(this), amount);
        activeStakers += 1;
        totalStakers += 1;
        emit Staked(stakeId, msg.sender, amount, block.timestamp);
        return true;
    }

    function calculateReward(
        uint256 stakeId
    ) internal view returns (uint256) {
        uint256 percentage = users[stakeId].rewardPercent;
        uint256 amount = users[stakeId].stakeAmount;
        uint256 timeDiff = block.timestamp - users[stakeId].initialTime;
        if(timeDiff >= 30 minutes && timeDiff <= 60 minutes) {
            percentage *= 15;
        }
        if(timeDiff >= 60 minutes) {
            percentage *= 20;
        }
        uint256 amtPercent = amount * percentage / 1000;
        uint256 reward = (amtPercent * timeDiff) / 60 minutes;
        return reward;
    }

    function unStake(uint256 stakeId, Sign memory sign) external returns (bool) {
        require(users[stakeId].stakeStatus, "Invalid StakeId");
        require(users[stakeId].user == msg.sender, "Invalid User");
        require(!usedNonce[sign.nonce], "Invalid Nonce");
        usedNonce[sign.nonce] = true;
        UserDetail memory userData = users[stakeId];
        verifySign(stakeId, msg.sender, userData.stakeAmount, sign);
        uint256 reward = calculateReward(
            stakeId
        );
        delete users[stakeId];
        uint256 amount = userData.stakeAmount + reward;
        FoeToken.transfer(msg.sender, amount);
        activeStakers -= 1;
        emit Unstaked(stakeId, msg.sender, userData.stakeAmount, reward);
        return true;
    }

    function setStakePlans(
        StakeType level,
        uint256 apyPercentage,
        uint256 minStakeAmount
    ) external onlyOwner {
        require(
            level == StakeType.SILVER ||
            level == StakeType.GOLD ||
            level == StakeType.DIAMOND,
            "Invalid Level"
        );
        plans[level] = StakePlan(level, apyPercentage, minStakeAmount);
        emit StakePlanUpdated(level, apyPercentage, minStakeAmount);
    }

    function getUserDetails(uint256 stakeId) external view returns(UserDetail memory, uint256 reward) {
        reward = calculateReward(stakeId);
        return (users[stakeId], reward);
    }

    function verifySign(
        uint256 level,
        address caller,
        uint256 amount,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                this,
                level,
                caller,
                amount,
                sign.nonce
            )
        );
        require(
            signer ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            hash
                        )
                    ),
                    sign.v,
                    sign.r,
                    sign.s
                ),
            "Owner sign verification failed"
        );
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