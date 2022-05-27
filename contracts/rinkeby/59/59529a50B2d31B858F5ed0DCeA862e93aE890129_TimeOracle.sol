// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";
import "Ownable.sol";

contract TimeOracle is Ownable {

    // Pricefeed arrays
    AggregatorV3Interface[] public timeFeed;

    // index of addresses in array mapping
    mapping(address => uint256) public feedToArrayLocation;


    /**
     * @dev Function to add price feed to array.
     * 
     * Requirements:
     *  
     *  -'_newFeed' cannot be in array already.
    */
    function addPriceFeed(address _newFeed) public onlyOwner{
        require(feedToArrayLocation[_newFeed] == 0, 'Pricefeed already in contract');
        AggregatorV3Interface newFeed = AggregatorV3Interface(_newFeed);
        timeFeed.push(newFeed);
        feedToArrayLocation[_newFeed] = timeFeed.length;
    }

    /**
     * @dev Function to delete price feed from array.
     * 
     * Requirements:
     *  
     *  -'_feedToDelete' must be in array already.
    */
    function deletePriceFeed(address _feedToDelete) public onlyOwner{
        require(feedToArrayLocation[_feedToDelete] != 0, 'Pricefeed not in contract');
        uint256 index = feedToArrayLocation[_feedToDelete] - 1;
        feedToArrayLocation[_feedToDelete] = 0;
        timeFeed[index] = timeFeed[timeFeed.length-1];
        timeFeed.pop();
    }

    /**
     * @dev Function retrive the ceiling function of the average time in feeds.
     * 
     * Returns:
     *  
     *  - ceil of average of picefeed times. 
    */
    function getLatestTime() public view returns (uint) {
        uint sumOfTimes;
        uint256 i;
        uint timeStamp;
        for(i = 0; i < timeFeed.length; i++){
            timeStamp = 0;
            ( , , , timeStamp,) = timeFeed[i].latestRoundData();
            sumOfTimes = sumOfTimes + timeStamp;
        }
        return (sumOfTimes + (sumOfTimes % timeFeed.length))/timeFeed.length;
    }

    /**
     * @dev array length getter.
     * 
     * Returns:
     *  
     *  - length of pricefeed array
    */
    function getLength() public view returns (uint){
        return timeFeed.length; 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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