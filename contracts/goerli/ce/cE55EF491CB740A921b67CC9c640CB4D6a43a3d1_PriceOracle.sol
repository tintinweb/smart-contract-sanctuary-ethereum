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
pragma solidity >=0.8.7;

interface IPriceOracle {

   /// Set the price for names of a given length.
   function setPriceForLen(uint256 len, uint256 usdPrice) external;
   /// Set prices for names of all lengths.
   function setPriceForAll(uint256[] calldata usdPrices) external;
   /// Query the ether price of a name.
   function price(string calldata name) external view returns (uint256 ethPrice);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./IPriceOracle.sol";
import "../registrar/StringUtils.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceOracle is IPriceOracle, Ownable {
    using StringUtils for *;

    AggregatorV3Interface internal priceFeed;

    mapping(uint256 => uint256) public prices;

    event PriceChanged(uint256 len, uint256 usdPrice);
  
    constructor(address _aggregatorAddress) {
        priceFeed = AggregatorV3Interface(_aggregatorAddress);
    }

    function setPriceForLen(uint256 len, uint256 usdPrice) external override {
        _setPrice(len, usdPrice);
    }

    function setPriceForAll(uint256[] calldata usdPrices) external override {
        _setPrices(usdPrices);
    }

    /// Returns the latest price
    function getLatestPrice() internal view returns (int) {
        ///   /*uint80 roundID*/,
        ///    int price,
        ///    /*uint startedAt*/,
        ///    /*uint timeStamp*/,
        ///    /*uint80 answeredInRound*/
        (,int usdPrice,,,) = priceFeed.latestRoundData();
        return usdPrice;
    }

    /**
     * Get a name's ether price from usd price.
     * @param name The name to query.
     * @return ethPrice The name's ether price.
     */
    function price(string calldata name) 
        external 
        view 
        override
        returns (uint256 ethPrice) 
    {   
        uint256 len = name.strlen();
        uint256 namePrice;
        if(len >= 5) {
            namePrice = prices[5];
        } else {
            namePrice = prices[len];
        }
        ethPrice = _attoUSDToWei(namePrice);
        return ethPrice;
    }


    function _attoUSDToWei(uint256 amount) internal view returns (uint256) {
        uint256 ethPrice = uint256(getLatestPrice());
        return (amount * 1 ether) / ethPrice;
    }

    function _setPrice(uint256 len, uint256 usdPrice) internal onlyOwner {
        prices[len] = usdPrice;
        emit PriceChanged(len, usdPrice);
    }

    /**
     * @dev Use an array to set the price for each length of the name: 
     * For example, an array of prices: usdPrices -> [1000,800,600,400,200]
     * It will be stored as:
     * { prices[1] = 1000; prices[2] = 800; prices[3] = 600; prices[4] = 400; prices[5] = 200 }
     * @param usdPrices An array of prices.
     */
    function _setPrices(uint256[] memory usdPrices) internal onlyOwner {
        for (uint i = 0; i < usdPrices.length; i++) {
            prices[i+1] = usdPrices[i];
            emit PriceChanged(i+1, usdPrices[i]);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}