// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.13;

import "AggregatorV3Interface.sol";
import "Ownable.sol";
import "Counters.sol";

error PriceFeedProxyAlreadyExists(address _proxy);

contract PriceConsumerV3 is Ownable {
    using Counters for Counters.Counter;

    struct PriceFeed {
        string pair;
        address proxy;
    }

    Counters.Counter private _s_priceFeedIdCounter;

    mapping(uint256 => PriceFeed) public s_priceFeeds;
    mapping(address => bool) public s_existing;

    constructor(string memory _pair, address _proxy) {
        setPriceFeedProxy(_pair, _proxy);
    }

    modifier notExisting(address _proxy) {
        if (s_existing[_proxy]) revert PriceFeedProxyAlreadyExists(_proxy);
        _;
    }

    /**
     * Set price feed proxy.
     * @dev https://docs.chain.link/docs/reference-contracts/
     * @param _pair Currency pair. Recommended style: ETH/USD
     * @param _proxy Price feed proxy address.
     */
    function setPriceFeedProxy(string memory _pair, address _proxy)
        public
        onlyOwner
        notExisting(_proxy)
    {
        uint256 newId = _s_priceFeedIdCounter.current();

        s_priceFeeds[newId] = PriceFeed(_pair, _proxy);
        s_existing[_proxy] = true;

        _s_priceFeedIdCounter.increment();
    }

    function getTotalPriceFeeds() public view returns (uint256) {
        return _s_priceFeedIdCounter.current();
    }

    function getPair(uint256 _id)
        public
        view
        returns (string memory)
    {
        return s_priceFeeds[_id].pair;
    }

    /**
     * Get price feed proxy address.
     * @param _id ID of the price feed proxy (e.g. 1). See setPriceFeedProxy
     * @return Proxy address of a provided currency pair.
     */
    function getProxy(uint256 _id) public view returns (address) {
        return s_priceFeeds[_id].proxy;
    }

    /**
     * Get latest price of a particular aggregator.
     * @param _id ID of the price feed proxy (e.g. 1). See setPriceFeedProxy
     * @return Latest price.
     */
    function getPrice(uint256 _id) public view returns (uint256) {
        address proxy = s_priceFeeds[_id].proxy;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(proxy);

        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        return uint256(price);
    }

    /**
     * Get amount of decimals of a particular aggregator.
     * @param _id ID of the price feed proxy (e.g. 1). See setPriceFeedProxy
     * @return Decimals (usually 8 if x/USD or 18 if x/ETH; see docs).
     */
    function getDecimals(uint256 _id) public view returns (uint8) {
        address proxy = s_priceFeeds[_id].proxy;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(proxy);

        return priceFeed.decimals();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}