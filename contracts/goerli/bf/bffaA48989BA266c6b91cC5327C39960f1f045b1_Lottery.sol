// SPDX-License-Identifier: MIT
pragma solidity >=0.0.6 <0.9.0;

import "AggregatorV3Interface.sol";  // get current exchange rate ETH/USD
import "Ownable.sol";  // adds access control by ownership

contract Lottery is Ownable {    // "is Ownable" adds OpenZeppelin functionality to contract
    address payable[] players;   // define array of addresses for players
    uint256 public usdEntryFee;  // Minimum fee in USD
    AggregatorV3Interface internal ethUsdPriceFeed;    // Interface to get ETH price in USD 
    
    // New "data type"define the different states the lottery can be in: 0=OPEN, 1=CLOSED, 2=CALCULATING_WINNER
    enum LOTTERY_STATE {  
        OPEN,
        CLOSED,
        CALCULATING_WINNER}
    LOTTERY_STATE public lottery_state;   // variable lottery_state is created based on LOTTERY_STATE



    constructor(address _price_feed_address) public {         // _priceFeedAddress: Parameter der im deploy.py Ã¼bergeben werden muss
        usdEntryFee = 50 * (10**18);     // as one (1) Wei is equal to 10 **-18 1ETH 
        ethUsdPriceFeed = AggregatorV3Interface(_price_feed_address);   // gets the PriceFeed contract address from deploy.py
        lottery_state = LOTTERY_STATE.CLOSED;  // lottery is initially closed 
    }
    
    
    function enterLottery() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntrenceFee(), "You need to pay more EHT to match at least 50 USD");
        players.push(payable(msg.sender));   // to send a message, ETH has to be paied --> then added to the player array 
    }


    function getEntrenceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // Chainlink docu: Number has 8 decimals --> so add 10 more
        // $50, $2,000 / ETH
        // 50/2,000
        // 50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;  
        return costToEnter;
    }


    function startLottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "You can't start new lottery yet:");
        lottery_state = LOTTERY_STATE.OPEN;
    }
 


    function endLottery() public {
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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