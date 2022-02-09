// SPDX-License-Identifier: MIT

/*
                    ████████╗██╗  ██╗███████╗
                    ╚══██╔══╝██║  ██║██╔════╝
                       ██║   ███████║█████╗
                       ██║   ██╔══██║██╔══╝
                       ██║   ██║  ██║███████╗
                       ╚═╝   ╚═╝  ╚═╝╚══════╝
██╗  ██╗██╗   ██╗███╗   ███╗ █████╗ ███╗   ██╗ ██████╗ ██╗██████╗ ███████╗
██║  ██║██║   ██║████╗ ████║██╔══██╗████╗  ██║██╔═══██╗██║██╔══██╗██╔════╝
███████║██║   ██║██╔████╔██║███████║██╔██╗ ██║██║   ██║██║██║  ██║███████╗
██╔══██║██║   ██║██║╚██╔╝██║██╔══██║██║╚██╗██║██║   ██║██║██║  ██║╚════██║
██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║ ╚████║╚██████╔╝██║██████╔╝███████║
╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝


The Humanoids Staking Reward Contract, earning $10 ION per day

*/

pragma solidity =0.8.11;

import "./OwnableTokenAccessControl.sol";
import "./IStakingReward.sol";
import "./IERC20Mint.sol";

contract TheHumanoidsStakingReward is OwnableTokenAccessControl, IStakingReward {
    uint256 public constant REWARD_RATE_PER_DAY = 10 ether;
    uint256 public stakingRewardEndTimestamp = 1736152962;

    mapping(address => uint256) private _stakeData; // packed bits balance:208 timestamp:34 stakedCount:14

    address private constant STAKING_ADDRESS = address(0x3d6a1F739e471c61328Eb8a8D8d998E591C0FD42);
    address private constant TOKEN_ADDRESS = address(0x831dAA3B72576867cD66319259bf022AFB1D9211);


    /// @dev Emitted when `account` claims `amount` of reward.
    event Claim(address indexed account, uint256 amount);


    function setStakingRewardEndTimestamp(uint256 timestamp) external onlyOwner {
        require(stakingRewardEndTimestamp > block.timestamp, "Staking has already ended");
        require(timestamp > block.timestamp, "Must be a time in the future");
        stakingRewardEndTimestamp = timestamp;
    }


    modifier onlyStaking() {
        require(STAKING_ADDRESS == _msgSender(), "Not allowed");
        _;
    }


    function _reward(uint256 timestampFrom, uint256 timestampTo) internal pure returns (uint256) {
        unchecked {
            return ((timestampTo - timestampFrom) * REWARD_RATE_PER_DAY) / 1 days;
        }
    }

    function reward(uint256 timestampFrom, uint256 timestampTo) external view returns (uint256) {
        if (timestampTo > stakingRewardEndTimestamp) {
            timestampTo = stakingRewardEndTimestamp;
        }
        if (timestampFrom < timestampTo) {
            return _reward(timestampFrom, timestampTo);
        }
        return 0;
    }

    function timestampUntilRewardAmount(uint256 targetRewardAmount, uint256 stakedCount, uint256 timestampFrom) public view returns (uint256) {
        require(stakedCount > 0, "stakedCount cannot be zero");
        uint256 div = REWARD_RATE_PER_DAY * stakedCount;
        uint256 duration = ((targetRewardAmount * 1 days) + div - 1) / div; // ceil
        uint256 timestampTo = timestampFrom + duration;
        require(timestampTo <= stakingRewardEndTimestamp, "Cannot get reward amount before staking ends");
        return timestampTo;
    }


    function stakedTokensBalanceOf(address account) external view returns (uint256 stakedCount) {
        stakedCount = _stakeData[account] & 0x3fff;
    }

    function lastClaimTimestampOf(address account) external view returns (uint256 lastClaimTimestamp) {
        lastClaimTimestamp = (_stakeData[account] >> 14) & 0x3ffffffff;
    }

    function rawStakeDataOf(address account) external view returns (uint256 stakeData) {
        stakeData = _stakeData[account];
    }

    function _calculateRewards(uint256 stakeData, uint256 unclaimedBalance) internal view returns (uint256, uint256, uint256) {
        uint256 timestamp = 0;
        uint256 stakedCount = stakeData & 0x3fff;
        if (stakedCount > 0) {
            timestamp = block.timestamp;
            if (timestamp > stakingRewardEndTimestamp) {
                timestamp = stakingRewardEndTimestamp;
            }
            uint256 lastClaimTimestamp = (stakeData >> 14) & 0x3ffffffff;
            if (lastClaimTimestamp < timestamp) {
                unchecked {
                    unclaimedBalance += _reward(lastClaimTimestamp, timestamp) * stakedCount;
                }
            }
        }
        return (unclaimedBalance, timestamp, stakedCount);
    }


    function willStakeTokens(address account, uint16[] calldata tokenIds) external override onlyStaking {
        uint256 stakeData = _stakeData[account];
        (uint256 unclaimedBalance, , uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);
        unchecked {
            _stakeData[account] = (unclaimedBalance << 48) | (block.timestamp << 14) | (stakedCount + tokenIds.length);
        }
    }

    function willUnstakeTokens(address account, uint16[] calldata tokenIds) external override onlyStaking {
        uint256 stakeData = _stakeData[account];
        (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);

        uint256 unstakeCount = tokenIds.length;
        if (unstakeCount < stakedCount) {
            unchecked {
                stakedCount -= unstakeCount;
            }
        }
        else {
            stakedCount = 0;
            if (unclaimedBalance == 0) {
                timestamp = 0;
            }
        }

        _stakeData[account] = (unclaimedBalance << 48) | (timestamp << 14) | stakedCount;
    }

    function willBeReplacedByContract(address /*stakingRewardContract*/) external override onlyStaking {
        uint256 timestamp = block.timestamp;
        if (stakingRewardEndTimestamp > timestamp) {
            stakingRewardEndTimestamp = timestamp;
        }
    }

    function didReplaceContract(address /*stakingRewardContract*/) external override onlyStaking {

    }


    function stakeDataOf(address account) external view returns (uint256) {
        uint256 stakeData = _stakeData[account];
        if (stakeData != 0) {
            (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);
            stakeData = (unclaimedBalance << 48) | (timestamp << 14) | (stakedCount);
        }
        return stakeData;
    }

    function claimStakeDataFor(address account) external returns (uint256) {
        uint256 stakeData = _stakeData[account];
        if (stakeData != 0) {
            require(_hasAccess(Access.Claim, _msgSender()), "Not allowed to claim");

            (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);
            stakeData = (unclaimedBalance << 48) | (timestamp << 14) | (stakedCount);

            delete _stakeData[account];
        }
        return stakeData;
    }


    function _claim(address account, uint256 amount) private {
        if (amount == 0) {
            return;
        }

        uint256 stakeData = _stakeData[account];

        uint256 balance = stakeData >> 48;
        if (balance > amount) {
            unchecked {
                _stakeData[account] = ((balance - amount) << 48) | (stakeData & 0xffffffffffff);
            }
            emit Claim(account, amount);
            return;
        }

        (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, balance);

        require(unclaimedBalance >= amount, "Not enough rewards to claim");
        unchecked {
            _stakeData[account] = ((unclaimedBalance - amount) << 48) | (timestamp << 14) | stakedCount;
        }

        emit Claim(account, amount);
    }

    function _transfer(address account, address to, uint256 amount) internal {
        _claim(account, amount);
        IERC20Mint(TOKEN_ADDRESS).mint(to, amount);
    }


    function claimRewardsAmount(uint256 amount) external {
        address account = _msgSender();
        _transfer(account, account, amount);
    }

    function claimRewards() external {
        address account = _msgSender();
        uint256 stakeData = _stakeData[account];
        (uint256 unclaimedBalance, uint256 timestamp, uint256 stakedCount) = _calculateRewards(stakeData, stakeData >> 48);

        require(unclaimedBalance > 0, "Nothing to claim");
        _stakeData[account] = (timestamp << 14) | stakedCount;

        emit Claim(account, unclaimedBalance);
        IERC20Mint(TOKEN_ADDRESS).mint(account, unclaimedBalance);
    }

    // ERC20 compatible functions

    function balanceOf(address account) external view returns (uint256) {
        uint256 stakeData = _stakeData[account];
        (uint256 unclaimedBalance, , ) = _calculateRewards(stakeData, stakeData >> 48);
        return unclaimedBalance;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address account, address to, uint256 amount) external returns (bool) {
        require(_hasAccess(Access.Transfer, _msgSender()), "Not allowed to transfer");
        _transfer(account, to, amount);
        return true;
    }

    function burn(uint256 amount) external {
        _claim(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        require(_hasAccess(Access.Burn, _msgSender()), "Not allowed to burn");
        _claim(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title OwnableTokenAccessControl
/// @notice Basic access control for utility tokens 
/// @author ponky
contract OwnableTokenAccessControl is Ownable {
    /// @dev Keeps track of how many accounts have been granted each type of access
    uint96 private _accessCounts;

    mapping (address => uint256) private _accessFlags;

    /// @dev Access types
    enum Access { Mint, Burn, Transfer, Claim }

    /// @dev Emitted when `account` is granted `access`.
    event AccessGranted(bytes32 indexed access, address indexed account);

    /// @dev Emitted when `account` is revoked `access`.
    event AccessRevoked(bytes32 indexed access, address indexed account);

    /// @dev Helper constants for fitting each access index into _accessCounts
    uint constant private _AC_BASE          = 4;
    uint constant private _AC_MASK_BITSIZE  = 1 << _AC_BASE;
    uint constant private _AC_DISABLED      = (1 << (_AC_MASK_BITSIZE - 1));
    uint constant private _AC_MASK_COUNT    = _AC_DISABLED - 1;

    /// @dev Convert the string `access` to an uint
    function _accessToIndex(bytes32 access) internal pure virtual returns (uint index) {
        if (access == 'MINT')       {return uint(Access.Mint);}
        if (access == 'BURN')       {return uint(Access.Burn);}
        if (access == 'TRANSFER')   {return uint(Access.Transfer);}
        if (access == 'CLAIM')      {return uint(Access.Claim);}
        revert("Access type does not exist");
    }

    function _hasAccess(Access access, address account) internal view returns (bool) {
        return (_accessFlags[account] & (1 << uint(access))) != 0;
    }

    function hasAccess(bytes32 access, address account) public view returns (bool) {
        uint256 flag = 1 << _accessToIndex(access);        
        return (_accessFlags[account] & flag) != 0;
    }

    function grantAccess(bytes32 access, address account) external onlyOwner {
        require(account.code.length > 0, "Can only grant access to a contract");

        uint index = _accessToIndex(access);
        uint256 flags = _accessFlags[account];
        uint256 newFlags = flags | (1 << index);
        require(flags != newFlags, "Account already has access");
        _accessFlags[account] = newFlags;

        uint shift = index << _AC_BASE;
        uint256 accessCount = _accessCounts >> shift;
        require((accessCount & _AC_DISABLED) == 0, "Granting this access is permanently disabled");
        require((accessCount & _AC_MASK_COUNT) < _AC_MASK_COUNT, "Access limit reached");
        unchecked {
            _accessCounts += uint96(1 << shift);
        }
        emit AccessGranted(access, account);
    }

    function revokeAccess(bytes32 access, address account) external onlyOwner {
        uint index = _accessToIndex(access);
        uint256 flags = _accessFlags[account];
        uint256 newFlags = flags & ~(1 << index);
        require(flags != newFlags, "Account does not have access");
        _accessFlags[account] = newFlags;

        uint shift = index << _AC_BASE;
        unchecked {
            _accessCounts -= uint96(1 << shift);
        }

        emit AccessRevoked(access, account);
    }

    /// @dev Returns the number of contracts that have `access`.
    function countOfAccess(bytes32 access) external view returns (uint256 accessCount) {
        uint index = _accessToIndex(access);

        uint shift = index << _AC_BASE;
        accessCount = (_accessCounts >> shift) & _AC_MASK_COUNT;
    }

    /// @dev `access` can still be revoked but not granted
    function permanentlyDisableGrantingAccess(bytes32 access) external onlyOwner {
        uint index = _accessToIndex(access);
        
        uint shift = index << _AC_BASE;
        uint256 flag = _AC_DISABLED << shift;
        uint256 accessCounts = _accessCounts;
        require((accessCounts & flag) == 0, "Granting this access is already disabled");
        _accessCounts = uint96(accessCounts | flag);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingReward {
    function willStakeTokens(address account, uint16[] calldata tokenIds) external;
    function willUnstakeTokens(address account, uint16[] calldata tokenIds) external;

    function willBeReplacedByContract(address stakingRewardContract) external;
    function didReplaceContract(address stakingRewardContract) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mint is IERC20 {
    function mint(address to, uint256 amount) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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