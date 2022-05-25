//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "AggregatorV3Interface.sol";
import "Ownable.sol";

contract AdFair is Ownable {
    uint256 public immutable i_adOrderAmount;

    //Array which holds wallet info of all users waiting for rewards.
    address payable[] public s_adpublishers;
    address payable[] public s_webusers;
    address[] public s_advertisers;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    AggregatorV3Interface public priceFeed;

    mapping(address => uint256) public advertiserAmount;

    error AdFair_InsufficientOrderAmount();

    event AdPurchased(address indexed advertiser);

    constructor(address _priceFeed) {
        i_adOrderAmount = 1 * (10**18);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function buyAd() external payable {
        //If order value is not greater than $10 then transaction will fail.
        if (msg.value <= getMinimumRequiredOrderAmount()) {
            revert AdFair_InsufficientOrderAmount();
        } else {
            s_advertisers.push(payable(msg.sender));
        }
        //emiting event to caputre it outside of smart contract
        emit AdPurchased(msg.sender);
    }

    function getMinimumRequiredOrderAmount() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 formattedPrice = uint256(price) * 10**10;
        uint256 minimumOrderAmount = (i_adOrderAmount * 10**18) /
            formattedPrice;
        return minimumOrderAmount;
    }

    function getPriceFeedVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // //Get price of eth from chainlink datafeed
    // function getETHPrice() public view returns (uint256) {
    //     (, int256 answer, , , ) = priceFeed.latestRoundData();
    //     return uint256(answer * 100000000);
    // }

    // //Convert usd to eth based on eth/usd price feed data
    // function getConversionRate(uint256 ethAmount)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     uint256 ethPrice = getETHPrice();
    //     uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    //     return ethAmountInUsd;
    // }

    // function getEntranceFee() public view returns (uint256) {
    //     uint256 adPrice = 50 * 10**18;
    //     uint256 price = getETHPrice();
    //     uint256 precision = 1 * 10**18;
    //     return (adPrice * precision) / price;
    // }

    // function setPayableAdPublishers(payable[] _adpublishers)
    //     public
    //     payable
    //     onlyOwner
    // {
    //     s_adpublishers = _adpublishers;
    // }

    // function setPayableWebUser(payable[] _webusers) public payable onlyOwner {
    //     s_webusers = _webusers;
    // }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}