// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./RichInterface.sol";

contract RichTokenStaking is Ownable, ReentrancyGuard {

    uint256 constant public stakingPeriodLength = 300 seconds;

    mapping(address => uint256) public userBalance;
    uint256 public totalStaked = 0;
    uint256 public totalBurned = 0;
    uint256 public canClaimTs = 0;
    uint256 public startStakingTs = 0;
    uint256 public rewardAmount = 0;

    ERC20 private token;

    constructor(address _tokenAddress, uint256 _rewardAmount) payable {
        token = ERC20(_tokenAddress);
        startStakingTs = block.timestamp;
        canClaimTs = block.timestamp + stakingPeriodLength;
        rewardAmount = _rewardAmount;
    }

    function poolInfo() public view returns (uint256, uint256, uint256, uint256, uint256) {
        return (
            startStakingTs,
            canClaimTs,
            rewardAmount, 
            totalStaked, 
            totalBurned
        );
    }

    function userReward(address account) public view returns (uint256) {
        uint256 userStakedQty = userBalance[account];
        return totalStaked == 0 ? 0 : (userStakedQty / totalStaked) * rewardAmount;
    }

    function userStaked(address account) public view returns (uint256) {
        return userBalance[account];
    }

    function rewardPoolBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function claimable() public view returns (bool) {
        return block.timestamp >= canClaimTs;
    }

    function updateCanClaimTs() public onlyOwner {
        startStakingTs = block.timestamp;
        canClaimTs = block.timestamp + stakingPeriodLength;
    }

    function adjustReward(uint256 amount) onlyOwner external {
        rewardAmount = amount;
        emit rewardAdjusted(amount);
    } 

    function withdraw(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "zero amount not allowed");
        require(block.timestamp < canClaimTs , "Staking Period Ended");
        require(token.balanceOf(msg.sender) >= amount, "Insufficent token balance to stake");
        userBalance[msg.sender] += amount;
        totalStaked += amount;
        token.transferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    function unstake(uint256 amount) nonReentrant external {
        require(amount > 0, "zero amount not allowed");
        require(userBalance[msg.sender] >= amount, "Insufficiend staked token amount");
        userBalance[msg.sender] -= amount;
        totalStaked -= amount;
        token.approve(address(this), amount);
        token.transferFrom(address(this), msg.sender, amount);
        token.approve(address(this), 0);
        emit Unstaked(msg.sender, amount);
    }

    function claimReward() nonReentrant external {
        require(userBalance[msg.sender] > 0, "No token staked to share reward!");
        require(block.timestamp >= canClaimTs , "Cannot claim reward yet!");
        uint256 userStakedQty = userBalance[msg.sender];
        uint256 canClaimQty = (userStakedQty / totalStaked) * rewardAmount;
        require(canClaimQty >= address(this).balance, "Insufficent reward to claim");
        totalBurned += canClaimQty;
        userBalance[msg.sender] = 0;
        token.approve(address(this), userStakedQty);
        token.burnFrom(address(this), userStakedQty);
        token.approve(address(this), 0);
        payable(msg.sender).transfer(canClaimQty);
        emit RewardClaimed(msg.sender, canClaimQty);
    } 

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    event rewardAdjusted(uint256 amount);
    event Deposit(address account, uint256 amount);
    event Unstaked(address account, uint256 amonut);
    event RewardClaimed(address account, uint256 amount);

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

pragma solidity ^0.8.0;

interface ERC20 {
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 allowance) external;
    function increaseAllowance(address spender, uint256 addedValue) external;
    function decreaseAllowance(address spender, uint256 subtractedValue) external;
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
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