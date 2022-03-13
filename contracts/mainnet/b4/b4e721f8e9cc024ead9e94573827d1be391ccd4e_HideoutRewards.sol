/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// File: contracts/interface/ISkvllpvnkz.sol


pragma solidity ^0.8.0;

interface ISkvllpvnkz {
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: contracts/HideoutRewards.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;





contract HideoutRewards is Ownable, ReentrancyGuard {

    event RewardCollected(address owner, uint256 skvllpvnkId, uint256 amount);
    event HideoutRewardsOpen();
    event HideoutRewardsClosed();

    IERC20 private AMMO = IERC20(0xBcB6112292a9EE9C9cA876E6EAB0FeE7622445F1);
    ISkvllpvnkz private SkvllpvnkzHideout = ISkvllpvnkz(0xB28a4FdE7B6c3Eb0C914d7b4d3ddb4544c3bcbd6);

    uint256 public constant START_TIMESTAMP = 1631142000; // 09-09-2021
    uint256 public constant REWARD_PER_DAY = 2*10**18;
    uint256 public constant REWARD_PER_SEC = REWARD_PER_DAY / 86400;

    bool public isHideoutRewardsOpen = false;

    mapping(uint256 => uint256) private skvllpvnkz;

    struct Report{
        uint256 id;
        address owner;
        uint256 lastClaimTimestamp;
        uint256 unclaimedRewards;
    }

    modifier hideoutRewardsOpen {
        require( isHideoutRewardsOpen, "Hideout Rewards is closed" );
        _;
    }

    function setTreasuryContract(address _address) external onlyOwner{
        AMMO = IERC20(_address);
    }

    function setSkvllpvnkzContract(address _address) external onlyOwner{
        SkvllpvnkzHideout = ISkvllpvnkz(_address);
    }

    function getBatchPendingRewards(uint64[] memory skvllpvnkIds) external view returns(Report[] memory) {
        Report[] memory allRewards = new Report[](skvllpvnkIds.length);
        for (uint64 i = 0; i < skvllpvnkIds.length; i++){
            allRewards[i] = 
                Report(
                    skvllpvnkIds[i],
                    SkvllpvnkzHideout.ownerOf(skvllpvnkIds[i]),
                    skvllpvnkz[skvllpvnkIds[i]] == 0 
                        ? START_TIMESTAMP 
                        : skvllpvnkz[skvllpvnkIds[i]], 
                    _calculateRewards(skvllpvnkIds[i], block.timestamp));
        }
        return allRewards;
    }

    function getWalletReport(address wallet) external view returns(Report[] memory) {
        uint256[] memory skvllpvnkIds = SkvllpvnkzHideout.walletOfOwner(wallet);
        Report[] memory report = new Report[](skvllpvnkIds.length);
        uint256 rewardTimestamp = block.timestamp;
        for (uint64 i = 0; i < skvllpvnkIds.length; i++){
            report[i] = 
                Report(
                    skvllpvnkIds[i],
                    wallet,
                    skvllpvnkz[skvllpvnkIds[i]] == 0 
                    ? START_TIMESTAMP 
                    : skvllpvnkz[skvllpvnkIds[i]], 
                    _calculateRewards(skvllpvnkIds[i], rewardTimestamp));
        }
        return report;
    }

    function collectRewards(uint256[] memory skvllpvnkIds) public hideoutRewardsOpen nonReentrant {
        uint256 rewardTimestamp = block.timestamp;
        uint256 rewardAmount = 0; 
        for (uint256 i; i < skvllpvnkIds.length; i++){     
            require(SkvllpvnkzHideout.ownerOf(skvllpvnkIds[i]) == msg.sender, "You do not own this Skvllpvnk");
            rewardAmount += _calculateRewards(skvllpvnkIds[i], rewardTimestamp);
            skvllpvnkz[skvllpvnkIds[i]] = rewardTimestamp;
            emit RewardCollected( msg.sender, skvllpvnkIds[i], rewardAmount);
        }
        _releasePayment(rewardAmount);
    }

    function _calculateRewards(uint256 skvllpvnkId, uint256 currentTime) internal view returns (uint256){
        uint256 startTime = skvllpvnkz[skvllpvnkId] == 0 ? START_TIMESTAMP : skvllpvnkz[skvllpvnkId];
        return (currentTime - startTime) * REWARD_PER_SEC;
    }

    function _releasePayment(uint256 rewardAmount) internal {
        require(rewardAmount > 0, "Nothing to collect");
        require(AMMO.balanceOf(address(this)) >= rewardAmount, "Not enough AMMO");
        AMMO.approve(address(this), rewardAmount); 
        AMMO.transfer(msg.sender, rewardAmount);
    }

    function openCloseHideout() external onlyOwner {
        isHideoutRewardsOpen = !isHideoutRewardsOpen;
    }

}