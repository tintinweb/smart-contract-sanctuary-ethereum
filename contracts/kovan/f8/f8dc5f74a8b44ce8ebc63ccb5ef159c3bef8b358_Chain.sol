/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/IERC20.sol


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

    function decimals() external view returns (uint256);

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
// File: contracts/rafferalcontract.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;




contract Chain is Ownable, ReentrancyGuard {
    event Invested(address indexed investor, uint256 timestamp);
    event Withdrawn(address indexed withdrawer, uint256 amount, uint256 timestamp);
    event Reward(address indexed user, uint256 amount);

    struct User {
        uint256 deposited;
        uint256 timestamp;
        uint256 referralReward;
        uint256 reward;
        uint256 claimed;
        address addr;
        bytes32 link;
        uint referredCount;
        bytes32 referred;
    }

    mapping(bytes32 => User) public users;
    mapping(address => bytes32) public referralLink;

    uint24 private constant DAY = 86400;
    bytes32 private constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint256[] private collections;
    uint256 private decimal;
    uint256 private startTime;
    address public treasurer;
    IERC20 public token;

    constructor(IERC20 _token, address _treasurer) {
        treasurer = _treasurer;
        token = _token;
        startTime = (block.timestamp/DAY) * DAY;
        decimal = token.decimals();
    }

    function setTreasurer(address _treasurer) public onlyOwner {
        treasurer = _treasurer;
    }

    function addReferral(address addr, uint256 amount, bytes32 referral) external nonReentrant {
        require(referralLink[addr] == ZERO_BYTES32, "already a member");
        require(users[referral].addr != address(0) || referral == ZERO_BYTES32, "Invalid referrral");

        uint256 requiredAmountInWei = _invest(amount);

        bytes32 link = keccak256(abi.encode(addr, referral));
        referralLink[addr] = link;

        users[link] = User({
            deposited: requiredAmountInWei,
            timestamp: block.timestamp,
            referralReward: 0,
            reward: 0,
            claimed: 0,
            addr: addr,
            link: link,
            referredCount: 0,
            referred: referral
        });

        _distributeBonus(referral, requiredAmountInWei);
    }

    function _distributeBonus(bytes32 link, uint256 amountInWei) internal {
        bytes32 userLink = link;
        User storage user;
        uint8 bonusPercentage;
        uint bonus;
        for(uint i = 0; i < 40; i++) {
            if (link == ZERO_BYTES32) break;
            user = users[userLink];
            if(i==0) {
                bonusPercentage = 20;
            } else if (i==1) {
                bonusPercentage = 10;
            } else if (i==2) {
                bonusPercentage = 5;
            } else if (i==3) {
                bonusPercentage = 4;
            } else {
                bonusPercentage = 2;
            }

            bonus = (amountInWei * bonusPercentage)/100;
            user.referralReward += bonus;
            userLink = user.referred;
        }
    }

    function topup(address addr, uint256 amount) external nonReentrant {
        require(users[referralLink[addr]].addr != address(0), "Invalid address");
        uint256 requiredAmountInWei = _invest(amount);

        User storage user = users[referralLink[addr]];

        user.deposited += requiredAmountInWei;
        user.timestamp = block.timestamp;

        _distributeBonus(referralLink[addr], requiredAmountInWei);
    }

    function _invest(uint256 amount) internal returns(uint256) {
        require(amount >= 100, "Too Low");
        uint256 amountInWei = amount * (10**decimal);
        uint256 requiredAmountInWei = ((amount / 100) * 100) * (10**decimal);

        uint16 index = uint16((block.timestamp - startTime)/DAY);

        uint256 previousBalance = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), amountInWei);
        uint256 newBalance = token.balanceOf(address(this));

        require(
            (previousBalance + requiredAmountInWei) <= newBalance,
            "Insuff"
        );

        collections[index] += requiredAmountInWei;
        uint256 leftover = newBalance - (previousBalance + requiredAmountInWei);
        if (leftover > 0) token.transfer(msg.sender, leftover);

        emit Invested(msg.sender, block.timestamp);
        return requiredAmountInWei;
    }

    function _totalReward(bytes32 link) internal view returns(uint256) {
        User storage user = users[link];
        uint256 dailyReward = (user.deposited * 5)/1000;
        uint16 time = uint16((block.timestamp - user.timestamp)/DAY);

        return ((dailyReward * time) + user.referralReward + user.reward);
    }

    function myRewards() public view returns(uint256) {
        User memory user = users[referralLink[msg.sender]];
        uint256 reward = _totalReward(user.link);
        return reward - user.claimed;
    }

    function claim() public {
        User storage user = users[referralLink[msg.sender]];
        require(user.deposited != 0, "No Deposits");
        require(((block.timestamp - user.timestamp)/DAY) > 0, "Too Early");
        
        user.reward = _totalReward(user.link);
        uint256 amountToClaim = user.reward - user.claimed;
        user.claimed += amountToClaim;
    
        token.transfer(msg.sender, amountToClaim);

        emit Reward(user.addr, amountToClaim);
    }

    // NOTICE: Here user can withdraw any sum of amount, not compulsory 
    // to be the multiple of 100
    function withdraw(uint256 amount) public nonReentrant {

        uint256 amountInWei = amount * (10 ** decimal);
        User memory user = users[referralLink[msg.sender]];
        if (msg.sender == treasurer) {
            _withdraw(treasurer, amountInWei);
        } else {
            require(user.deposited >= amount, "Low Balance");

            uint256 adminAmountInWei = ((amountInWei * 10) / 100);
            uint256 userAmountInWei = amountInWei - adminAmountInWei;

            uint256 rewardsAccumulated = _totalReward(user.link);

            user.deposited -= amountInWei;
            user.timestamp = block.timestamp;
            user.reward = rewardsAccumulated;

            _withdraw(treasurer, adminAmountInWei);
            _withdraw(msg.sender, userAmountInWei);
        }
    }

    function withdrawAll() external nonReentrant {
        if (msg.sender == treasurer) {
            uint256 totalAmount = token.balanceOf(address(this));
            _withdraw(treasurer, totalAmount);
        } else {
            withdraw(users[referralLink[msg.sender]].deposited);
        }
    }

    function _withdraw(address withdrawer, uint256 amount) internal {
        require(amount <= token.balanceOf(address(this)), "Insuff");

        token.transfer(withdrawer, amount);
        emit Withdrawn(withdrawer, amount, block.timestamp);
    }
}