/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

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


// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/access/[email protected]
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


// File contracts/EthericeBonus.sol

pragma solidity ^0.8.13;


interface TokenInterface {
    function calcTokenValue(address _address, uint256 _Day) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function currentDay() external returns(uint256);
}

contract EthericeBonus is ReentrancyGuard, Ownable {
    event BonusTokensClaimed(
        address indexed addr,
        uint256 timestamp,
        uint256 tokensClaimed,
        uint256 day
    );

    address public tokenAddress;

    mapping(uint256 => mapping(address => bool) ) internal _claimed;
    mapping(uint256 => uint256 ) internal _percents;
    mapping(uint256 => uint256) internal _claimableDay;
    bool public claimsOpen;

    TokenInterface public tokenContract;

    constructor(){
        // The Day 0 problem
        // As we can't use day 0 as a key here all these days are 
        // day + 1. The percents and claimable functions should be 
        // used to access the data instead of accessing the private
        // arrays directly as these functions account for the day + 1
        // issue
        _percents[1] = 10;
        _percents[2] = 10;
        _percents[3] = 5;
        _percents[4] = 3;
        _percents[5] = 2;
        _percents[6] = 1;

        _claimableDay[1] = 8;
        _claimableDay[2] = 9;
        _claimableDay[3] = 10;
        _claimableDay[4] = 11;
        _claimableDay[5] = 12;
        _claimableDay[6] = 13;
    }

    receive() external payable {}

    function percents(uint256 day) public view returns (uint256) {
        return _percents[day + 1];
    }

    function claimableDay(uint256 day) public view returns (uint256) {
        return _claimableDay[day + 1];
    }

    function hasClaimed(uint256 day, address _address) public view returns(bool){
        return _claimed[day + 1][_address];
    }
 
    function setTokenAddress(address _address) external onlyOwner {
        tokenContract = TokenInterface(_address);
    }

    function setClaimOpen(bool value) external onlyOwner {
        claimsOpen = value;
    }

    function claimAmount(address _address, uint256 day) public returns (uint256) {
        uint256 percent = percents(day);
        if(percent == 0) return 0;
        uint256 tokens = tokenContract.calcTokenValue(_address, day);
        if(tokens == 0) return 0;
        uint256 bonus = tokens / 100 * percent;
        return bonus;
    }

    function claimTokens(address _address, uint256 day) external nonReentrant {
        bool claimed = hasClaimed(day, _address);
        require(claimed == false, "address already claimed for day");
        require(claimsOpen, "Claims are not open");

        uint256 currentDay = tokenContract.currentDay();
        uint256 claimDay = claimableDay(day);
        require(claimDay > 0, "Day doesnt have claim window");
        require(currentDay >= claimDay, "Claim day has not been reached" );

        uint256 bonus = claimAmount(_address, day);
        _claimed[day + 1][_address] = true; // see constructor for day 0 (day + 1) problem 
        tokenContract.transfer(_address, bonus);
    }

    function withdrawTokens() external onlyOwner {
        tokenContract.transfer(owner(), tokenContract.balanceOf(address(this)));
    }
}