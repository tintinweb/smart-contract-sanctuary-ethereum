// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FurionPricingOracle is Ownable {
    mapping(bytes32 => AggregatorV3Interface) priceFeed;

    mapping(address => uint256[]) public prices;

    // 0: Normal - 1: Mid - 2: Rare
    // NFT token address to token id to price
    mapping(address => mapping(uint256 => uint256)) public priceLevel;
    mapping(address => bytes32) public quoteToken;

    event PriceUpdated(address token, uint256 level, uint256 price);

    function setPriceFeed(string calldata _name, address _feed)
        external
        onlyOwner
    {
        bytes32 tokenId = keccak256(abi.encodePacked(_name));

        // Set price feed info
        priceFeed[tokenId] = AggregatorV3Interface(_feed);
    }

    function getNFTPrice(address _token, uint256 _id)
        external
        view
        returns (uint256 price)
    {
        uint256 level = getPriceLevel(_token, _id);

        return prices[_token][level];
    }

    function getPriceLevel(address _token, uint256 _id)
        public
        view
        returns (uint256)
    {
        return priceLevel[_token][_id];
    }

    // update price to all levels under certain token address
    function updatePrices(address _token, uint256[] memory _prices)
        public
        onlyOwner
    {
        uint256 length = prices[_token].length;

        require(length > 0, "Price not initialized");

        require(length == _prices.length, "Length mismatch");

        for (uint256 i; i < length; ) {
            prices[_token][i] = _prices[i];

            unchecked {
                ++i;
            }

            emit PriceUpdated(_token, i, _prices[i]);
        }
    }

    function initPrice(address _token, uint256 _levels) external onlyOwner {
        require(prices[_token].length == 0, "Already initialized");

        for (uint256 i; i < _levels; ) {
            prices[_token].push(0);
            unchecked {
                ++i;
            }
        }
    }

    function updatePrice(
        address _token,
        uint256 _level,
        uint256 _price
    ) public onlyOwner {
        require(prices[_token].length > 0, "Price not initialized");

        prices[_token][_level] = _price;
        emit PriceUpdated(_token, _level, _price);
    }

    function _getChainlinkPrice(bytes32 _id) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed[_id].latestRoundData();

        return uint256(price);
    }
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