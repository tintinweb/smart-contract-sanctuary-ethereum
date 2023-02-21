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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

/**                                                                                                                                    
    https://matr1x-miner.xyz/
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Matr1xMiner is Ownable, ReentrancyGuard {
    // 12.5 days for miners to double
    // after this period, rewards do NOT accumulate anymore though!
    uint256 private constant RUNE_REQ_PER_MINER = 1_080_000;
    uint256 private constant INITIAL_MARKET_RUNES = 108_000_000_000;
    uint256 public constant START_TIME = 1676815200; // 2023-02-19 14:00:00 UTC

    uint256 private constant PSN = 10000;
    uint256 private constant PSNH = 5000;

    uint256 private constant getDevFeeVal = 325;
    uint256 private constant getMarketingFeeVal = 175;

    uint256 private marketRunes = INITIAL_MARKET_RUNES;

    uint256 public uniqueUsers;

    address payable private devFeeReceiver;
    address payable private immutable marketingFeeReceiver;

    mapping(address => uint256) private academyMiners;
    mapping(address => uint256) private claimedRunes;
    mapping(address => uint256) private lastInfusion;
    mapping(address => bool) private hasParticipated;

    mapping(address => address) private referrals;

    error OnlyOwner(address);
    error NonZeroMarketRunes(uint);
    error FeeTooLow();
    error NotStarted(uint);

    modifier hasStarted() {
        if (block.timestamp < START_TIME) revert NotStarted(block.timestamp);
        _;
    }

    ///@dev infuse some intitial native coin deposit here
    constructor(
        address _devFeeReceiver,
        address _marketingFeeReceiver
    ) payable {
        devFeeReceiver = payable(_devFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
    }

    function changeDevFeeReceiver(address newReceiver) external onlyOwner {
        devFeeReceiver = payable(newReceiver);
    }

    ///@dev should market runes be 0 we can resest to initial state and also (re-)fund the contract again if needed
    function init() external payable onlyOwner {
        if (marketRunes > 0) revert NonZeroMarketRunes(marketRunes);
    }

    function fund() external payable onlyOwner {}

    // buy token from the contract
    function absolve(address ref) public payable hasStarted {
        uint256 runesBought = calculateRuneBuy(
            msg.value,
            address(this).balance - msg.value
        );

        uint256 devFee = getDevFee(runesBought);
        uint256 marketingFee = getMarketingFee(runesBought);

        if (marketingFee == 0) revert FeeTooLow();

        runesBought = runesBought - devFee - marketingFee;

        devFeeReceiver.transfer(getDevFee(msg.value));
        marketingFeeReceiver.transfer(getMarketingFee(msg.value));

        claimedRunes[msg.sender] += runesBought;

        if (!hasParticipated[msg.sender]) {
            hasParticipated[msg.sender] = true;
            uniqueUsers++;
        }

        infuse(ref);
    }

    ///@dev handles referrals
    function infuse(address ref) public hasStarted {
        if (ref == msg.sender) ref = address(0);

        if (ref == msg.sender || ref == address(0) || academyMiners[ref] == 0) {
            ref = owner();
        }

        if (
            referrals[msg.sender] == address(0) &&
            referrals[msg.sender] != msg.sender
        ) {
            referrals[msg.sender] = ref;
            if (!hasParticipated[ref]) {
                hasParticipated[ref] = true;
                uniqueUsers++;
            }
        }

        uint256 runesUsed = getMyRunes(msg.sender);
        uint256 myRuneRewards = getRunesSinceLastInfusion(msg.sender);
        claimedRunes[msg.sender] += myRuneRewards;

        uint256 newMiners = claimedRunes[msg.sender] / RUNE_REQ_PER_MINER;
        claimedRunes[msg.sender] -= (RUNE_REQ_PER_MINER * newMiners);
        academyMiners[msg.sender] += newMiners;
        lastInfusion[msg.sender] = block.timestamp;

        // send referral runes
        claimedRunes[referrals[msg.sender]] += (runesUsed / 8);

        // boost market to nerf miners hoarding
        marketRunes += (runesUsed / 5);
    }

    // sells token to the contract
    function enlighten() external hasStarted {
        uint256 ownedRunes = getMyRunes(msg.sender);
        uint256 runeValue = calculateRuneSell(ownedRunes);

        uint256 devFee = getDevFee(runeValue);
        uint256 marketingFee = getMarketingFee(runeValue);

        if (academyMiners[msg.sender] == 0) uniqueUsers--;
        claimedRunes[msg.sender] = 0;
        lastInfusion[msg.sender] = block.timestamp;
        marketRunes += ownedRunes;

        devFeeReceiver.transfer(devFee);
        marketingFeeReceiver.transfer(marketingFee);

        payable(msg.sender).transfer(runeValue - devFee - marketingFee);
    }

    // ################################## view functions ########################################

    function runeRewards(address adr) external view returns (uint256) {
        return calculateRuneSell(getMyRunes(adr));
    }

    function calculateRuneSell(uint256 runes) public view returns (uint256) {
        return calculateTrade(runes, marketRunes, address(this).balance);
    }

    function calculateRuneBuy(
        uint256 eth,
        uint256 contractBalance
    ) public view returns (uint256) {
        return calculateTrade(eth, contractBalance, marketRunes);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners() external view returns (uint256) {
        return academyMiners[msg.sender];
    }

    function getMyRunes(address adr) public view returns (uint256) {
        return claimedRunes[adr] + getRunesSinceLastInfusion(adr);
    }

    function getRunesSinceLastInfusion(
        address adr
    ) public view returns (uint256) {
        // 1 rune per second per miner
        return
            min(RUNE_REQ_PER_MINER, block.timestamp - lastInfusion[adr]) *
            academyMiners[adr];
    }

    function getRunes() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool os, ) = payable(owner()).call{value: balance}("");
        require(os);
    }

    // private ones

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private pure returns (uint256) {
        return (PSN * bs) / (PSNH + (((rs * PSN) + (rt * PSNH)) / rt));
    }

    function getDevFee(uint256 amount) private pure returns (uint256) {
        return (amount * getDevFeeVal) / 10000;
    }

    function getMarketingFee(uint256 amount) private pure returns (uint256) {
        return (amount * getMarketingFeeVal) / 10000;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}