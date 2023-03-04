/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/access/Ownable2Step.sol


// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// File: contracts/interfaces/IPriceFeed.sol


pragma solidity ^0.8.17;

interface IPriceFeed {
    function getLatestPriceUSD(address) external returns (uint256, uint8);

    function amountInUSD(address token, uint256 amount)
        external
        returns (uint256);

    function exchangeRate(
        address base,
        address quote,
        uint256 amount
    ) external returns (uint256);
}

// File: contracts/libraries/Errors.sol


pragma solidity ^0.8.0;

library Errors {
    string public constant PRICE_FEED_TOKEN_NOT_SUPPORTED = "100"; // Token is not supported
    string public constant PRICE_FEED_TOKEN_BELOW_ZERO = "101"; // Token below zero price
}
// File: contracts/PriceFeed.sol


pragma solidity ^0.8.17;





contract PriceFeed is Ownable2Step, IPriceFeed {
    mapping(address => address) feedAddresses;
    address USD = 0x9BB8A6dcD83E36726Cc230a97F1AF8a84ae5F128;

    event PriceFeedAdded(
        uint256 timestamp,
        address indexed token,
        address indexed priceFeed
    );

    constructor() Ownable2Step() {
        feedAddresses[USD] = USD;
    }

    /// @dev function for owner to add more price feeds
    function addPriceFeed(address _tokenAddress, address _chainlinkPriceFeed)
        external
        onlyOwner
    {
        feedAddresses[_tokenAddress] = _chainlinkPriceFeed;
        emit PriceFeedAdded(
            block.timestamp,
            _tokenAddress,
            _chainlinkPriceFeed
        );
    }

    /* Returns the latest price */
    function getLatestPriceUSD(address _tokenAddress)
        public
        view
        override
        returns (uint256, uint8)
    {
        require(
            feedAddresses[_tokenAddress] != address(0),
            "ERR_TOKEN_ADDRESS"
        );

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            feedAddresses[_tokenAddress]
        );

        (, int256 answer, , , uint80 decimal) = priceFeed.latestRoundData();
        require(answer > 0, "ERR_ZERO_ANSWER");

        return (uint256(answer), uint8(decimal));
    }

    function amountInUSD(address _tokenAddress, uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        return exchangeRate(_tokenAddress, USD, _amount);
    }

    function exchangeRate(
        address _base,
        address _quote,
        uint256 _amount
    ) public view override returns (uint256) {
        (uint256 basePrice, ) = getLatestPriceUSD(_base);
        (uint256 quotePrice, ) = getLatestPriceUSD(_quote);

        return (basePrice * _amount) / quotePrice;
    }
}