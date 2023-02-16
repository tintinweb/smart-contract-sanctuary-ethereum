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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface PulseBitcoinLockNFTInterface {
    function ownerOf(uint256 tokenId) external view returns (address);

    function lockTime(uint256 tokenId) external view returns (uint256);

    function tokenIdsToAmounts(uint256 tokenId) external view returns (uint256);
}

contract PulseBitcoinLockNFTRewards is Ownable {
    address public CARN;
    address public immutable waatcaAddress;
    PulseBitcoinLockNFTInterface pulseBitcoinLockNftContract;
    address public pulseBitcoinLockNftContractAddress;
    mapping(uint256 => bool) public tokenIdsToRegistered; // True if they registered their NFT for rewards...will be able to withdraw rewards 1 day after registering
    mapping(uint256 => uint256) public tokenIdsToLastWithdrawalDay; // records the last day they withdrew rewards
    mapping(uint256 => uint256) public tokenIdsToDailyRewardAmount; // records their daily rewards amount
    mapping(uint256 => uint256) public tokenIdsToEndRewardsDay; // records their last day they can get rewards (max 1000 after registering)...(the smaller of 1000 or their actual end day measured from registration day)
    uint256 internal constant LAUNCH_TIME = 1676073600;//1678406400; march 10th launch date 00:00 utc (gmt)

    constructor(address _waatcaAddress, address _pulseBitcoinLockNftContractAddress) {
        waatcaAddress = _waatcaAddress;
        pulseBitcoinLockNftContractAddress = _pulseBitcoinLockNftContractAddress;
        pulseBitcoinLockNftContract = PulseBitcoinLockNFTInterface(pulseBitcoinLockNftContractAddress);
    }

    function setCarnAddress(address _rewardTokenCARN) public onlyOwner {
        CARN = _rewardTokenCARN;
    }

    function withdrawRewards(uint256 tokenId) public {
        require(
            msg.sender == pulseBitcoinLockNftContract.ownerOf(tokenId),
            "You are not the owner of this NFT"
        );
        require(
            tokenIdsToRegistered[tokenId],
            "You must register your NFT for rewards first"
        );
        require(
            tokenIdsToLastWithdrawalDay[tokenId] <
                tokenIdsToEndRewardsDay[tokenId],
            "You have already recieved all possible rewards for this NFT"
        );
        require(
            _currentDay() > tokenIdsToLastWithdrawalDay[tokenId],
            "Cannot withdraw twice on the same day, try again tomorrow"
        );

        uint256 totalDaysOfRewardsLeft = tokenIdsToEndRewardsDay[tokenId] -
            tokenIdsToLastWithdrawalDay[tokenId];
        uint256 numOfDaysSinceLastWithdrawal = _currentDay() -
            tokenIdsToLastWithdrawalDay[tokenId];

        // if numOfDaysSinceLastWithdrawal is greater than (their EndRewardsDay-LastWithdrawalDay) then set numOfDaysSinceLastWithdrawal to (their EndRewardsDay-LastWithdrawalDay)
        if (numOfDaysSinceLastWithdrawal > totalDaysOfRewardsLeft) {
            // in this scenario they are past the end of their lock up period.
            // meaning they locked up for 500 days, and its now day 540 for example (or 501)
            // in that case we only want to give them rewards from their last withdrawal day, up until the last day they are eligible for rewards (day 500)
            // so if their last withdrawal day was day 400, we would only give them 100 days worth of rewards and not 140
            numOfDaysSinceLastWithdrawal = totalDaysOfRewardsLeft;
        }

        IERC20(CARN).transfer(
            msg.sender,
            tokenIdsToDailyRewardAmount[tokenId] * numOfDaysSinceLastWithdrawal
        );
        IERC20(CARN).transfer(
            waatcaAddress,
            tokenIdsToDailyRewardAmount[tokenId] * numOfDaysSinceLastWithdrawal
        );

        tokenIdsToLastWithdrawalDay[tokenId] = _currentDay();
    }

    function registerNftForRewards(uint256 tokenId) public {
        require(
            msg.sender == pulseBitcoinLockNftContract.ownerOf(tokenId),
            "You are not the owner of this NFT, shame on you!"
        );
        require(
            !tokenIdsToRegistered[tokenId],
            "It seems you have already registered this NFT, go enjoy the rest of the carnival!"
        );

        // get the '(the end day of their lock period)' for this tokenId
        uint256 endOfLockPeriod = pulseBitcoinLockNftContract.lockTime(tokenId);

        // calculate numDaysLockedUpFromRegistration (the end day of their lock period) - (the day they are registering...today) // set this to 1000 if its greater than 1000
        uint256 numDaysLockedUpFromRegistration = ((endOfLockPeriod - LAUNCH_TIME) / 1 days) - _currentDay();

        if (numDaysLockedUpFromRegistration > 1000) {
            // this makes locking more than 1000 plsb for more than 1000 days, not beneficial in terms of getting rewards
            numDaysLockedUpFromRegistration = 1000;
        }

        uint256 amountPLSBLockedUp = pulseBitcoinLockNftContract
            .tokenIdsToAmounts(tokenId);

        if (amountPLSBLockedUp > 1000) {
            // this makes locking more than 1000 plsb for more than 1000 days, not beneficial in terms of getting rewards
            amountPLSBLockedUp = 1000;
        }

        // calculate this nft's tokenIdsToDailyRewardAmount (amount of PLSB locked * (numDaysLockedUpSinceRegistration / 1000) * 0.0015)
        tokenIdsToDailyRewardAmount[tokenId] =
            (amountPLSBLockedUp * numDaysLockedUpFromRegistration * 15) /
            10_000_000;

        // set his registered value as TRUE (for that first require statement at the top of the function)
        tokenIdsToRegistered[tokenId] = true;

        // set his tokenIdsToLastWithdrawalDay to the _curentDay
        // even though this nft never had a real withdrawal, set the lastWithdrwalDay to today as a starting point to measure future withdrawals from
        tokenIdsToLastWithdrawalDay[tokenId] = _currentDay();

        // send the user his daily allotement of reward token for 1 days worth
        // as 1) a reward for registering, also it informs the user how much theyll be recieving per day
        IERC20(CARN).transfer(
            msg.sender,
            tokenIdsToDailyRewardAmount[tokenId] * 100
        );

        // set tokenIdsToEndRewardsDay to currentday + numDaysLockedUpFromRegistration (max 1000 days from registration)
        tokenIdsToEndRewardsDay[tokenId] =
            _currentDay() +
            numDaysLockedUpFromRegistration;
    }

    function currentDay() external view returns (uint256) {
        return _currentDay();
    }

    function _currentDay() internal view returns (uint256) {
        return (block.timestamp - LAUNCH_TIME) / 1 days;
    }
}