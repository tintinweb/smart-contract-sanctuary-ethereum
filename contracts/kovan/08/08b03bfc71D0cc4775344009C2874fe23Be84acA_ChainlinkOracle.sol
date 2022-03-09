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

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/AggregatorV3Interface.sol";

/**
 * @title Mojito's price oracle, rely on various chainlink price feed
 * @author Mojito developers
 */
contract ChainlinkOracle is Ownable {
    enum PriceSource {
        FixedValue,
        Chainlink
    }

    struct TokenConfig {
        PriceSource source;
        uint256 fixedPrice;
        address chainlinkFeed;
        uint256 baseUnit; // 10 ^ underlying token decimals
        uint256 priceUnit; // 10 ^ price decimals
    }

    mapping(address => TokenConfig) public getTokenConfigByMToken;

    event TokenConfigChanged(address indexed token, PriceSource source, uint256 fixedPrice, address chainlinkFeed);

    function getUnderlyingPrice(address _mToken) external view returns (uint256) {
        TokenConfig storage config = getTokenConfigByMToken[address(_mToken)];
        // Comptroller needs prices in the format: ${raw price} * 1e(36 - baseUnit)
        // Since the prices in this view have it own decimals, we must scale them by 1e(36 - priceUnit - baseUnit)
        return ((1e36 / config.priceUnit) * getPrice(config)) / config.baseUnit;
    }

    function configToken(
        address _mToken,
        PriceSource _source,
        uint256 _fixedPrice,
        uint256 _underlyingDecimals,
        address _chainlinkPriceFeed,
        uint256 _priceFeedDecimals
    ) external onlyOwner {
        if (_source == PriceSource.FixedValue) {
            require(_fixedPrice != 0, "priceValueRequired");
            require(_chainlinkPriceFeed == address(0), "priceFeedNotAllowed");
        }

        if (_source == PriceSource.Chainlink) {
            require(_fixedPrice == 0, "priceValueNotAllowed");
            require(_chainlinkPriceFeed != address(0), "priceFeedRequired");
        }

        TokenConfig memory config = TokenConfig({
            source: _source,
            chainlinkFeed: _chainlinkPriceFeed,
            fixedPrice: _fixedPrice,
            baseUnit: 10**_underlyingDecimals,
            priceUnit: 10**_priceFeedDecimals
        });

        getTokenConfigByMToken[_mToken] = config;
        emit TokenConfigChanged(_mToken, _source, _fixedPrice, _chainlinkPriceFeed);
    }

    function getPrice(TokenConfig memory _config) private view returns (uint256) {
        if (_config.source == PriceSource.Chainlink) {
            AggregatorV3Interface feed = AggregatorV3Interface(_config.chainlinkFeed);
            (, int256 value, , , ) = feed.latestRoundData();

            return uint256(value);
        }
        if (_config.source == PriceSource.FixedValue) {
            return _config.fixedPrice;
        }

        revert("Invalid token config");
    }
}