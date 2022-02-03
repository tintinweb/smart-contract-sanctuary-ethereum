// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ILoomi {
  function spendLoomi(address user, uint256 amount) external;
}

contract MysteryBox is Context, Ownable, ReentrancyGuard  {
   
    int8[][10] public points;

    uint256 private constant WEEK_LENGTH = 1 weeks;
    uint256 public constant SHARDS_INDEX = 4;
    uint256 public constant ITEMS_PER_WEEK = 10;

    uint256 public startTimestamp;
    uint256 public pointLoomiPrice;
    uint256 public spinPrice;
    

    bool public boxOpened;
    bool public isPaused;

    ILoomi public loomi;

    mapping(uint256 => mapping(address => uint256)) _tokenToUserBalance;
    mapping(address => int8) public _userPoints;

    event SpinMysteryBox(address indexed user, int8 pointsAdded);
    event SacrificeLoomi(address indexed user, int8 pointsAdded);
    event AddPoints(address indexed user, int8 pointsAdded);
    event RemovePoints(address indexed user, int8 pointsAdded);

    constructor (address _loomi) {
        points[0] = [int8(-1),int8(-1),int8(-1),int8(0),int8(0),int8(1),int8(2),int8(3),int8(4),int8(5)];
        points[1] = [int8(-1),int8(-1),int8(-1),int8(0),int8(0),int8(1),int8(2),int8(3),int8(4),int8(5)];
        points[2] = [int8(-1),int8(-1),int8(-1),int8(0),int8(0),int8(1),int8(2),int8(3),int8(4),int8(5)];
        points[3] = [int8(-1),int8(-1),int8(-1),int8(0),int8(0),int8(1),int8(2),int8(3),int8(4),int8(5)];
        
        loomi = ILoomi(_loomi);

        pointLoomiPrice = 10 ether;
        spinPrice = 10 ether;
    }

    modifier whenNotPaused {
      require(!isPaused, "Tax collection paused!");
      _;
    }

    function random(uint256 num) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, num, _msgSender())));
    }  

    function spinMysteryBox(uint256 numberOfSpins) public whenNotPaused {
      require(boxOpened, "Mystery box is closed");

      uint256 loomiAmount = spinPrice * numberOfSpins;
      loomi.spendLoomi(_msgSender(), loomiAmount);
      
      uint256 currentWeek = getCurrentWeek();
      int8 finalPoints;

      for (uint256 i; i < numberOfSpins;i++) {
          uint256 rand = random(i) % ITEMS_PER_WEEK + currentWeek * ITEMS_PER_WEEK;
          _tokenToUserBalance[rand][_msgSender()] += 1;
          _userPoints[_msgSender()] += points[currentWeek][rand];
          finalPoints += points[currentWeek][rand];
      }

      emit SpinMysteryBox(_msgSender(), finalPoints);
    }

    function sacrifice(uint8 numberOfPoints) public whenNotPaused {
      require(boxOpened, "Mystery box is closed");

      uint256 loomiAmount = pointLoomiPrice * numberOfPoints;
      loomi.spendLoomi(_msgSender(), loomiAmount);

      _userPoints[_msgSender()] += int8(numberOfPoints);

      emit SacrificeLoomi(_msgSender(), int8(numberOfPoints));
    }

    function getCurrentWeek() public view returns(uint256) {
      if (startTimestamp == 0) return 0;
      return (block.timestamp - startTimestamp) / WEEK_LENGTH;
    }

    function getUserBalance(address user) public view returns (uint256[] memory) {
        uint256 itemsInGame = points.length * ITEMS_PER_WEEK;
        uint256[] memory output = new uint256[](itemsInGame);
        for (uint256 i; i < itemsInGame; i++) {
            output[i] = _tokenToUserBalance[i][user]; 
        }
        return output;
    }

    function getUserShards(address user) public view returns (uint256[] memory) {
      uint256[] memory shards = new uint256[](points.length);
      
      for (uint256 i; i < points.length; i++) {
        uint256 shardIndex = i + SHARDS_INDEX;
        shards[i] = _tokenToUserBalance[shardIndex][user];
      }

      return shards;
    }

    function openMysteryBox() public onlyOwner {
      require(startTimestamp == 0, "Already opened");
      startTimestamp = block.timestamp;
      boxOpened = true;
    }

    function pause(bool _pause) public onlyOwner {
      isPaused = _pause;
    }

    function addPoints(address user, int8 pointsToAdd) public onlyOwner {
      _userPoints[user] += pointsToAdd;
      emit AddPoints(user, pointsToAdd);
    }

    function removePoints(address user, int8 pointsToRemove) public onlyOwner {
      _userPoints[user] -= pointsToRemove;
      emit RemovePoints(user, pointsToRemove);
    }
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