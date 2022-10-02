// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../ProviderAwareOracle.sol";

contract ChainlinkPriceOracle is ProviderAwareOracle {

    uint private constant MIN_TIME = 60 minutes;
    
    // If comparing to WETH, will be left as address(0)
    address public BASE_PRICE_FEED;

    uint8 public decimals = 18;

    mapping(address => address) public priceFeed; // token => chainlink price feed

    event UpdateValues(address indexed feed);
    event OutputDecimalsUpdated(uint8 _old, uint8 _new);
    event SetPriceFeed(address indexed token, address indexed feed);

    constructor(address _provider, address _base_price_feed) ProviderAwareOracle(_provider) {
        BASE_PRICE_FEED = _base_price_feed;
    }

    function setPriceFeed(address _token, address _feed) external onlyOwner {
        priceFeed[_token] = _feed;

        emit SetPriceFeed(_token, _feed);
    }

    function getSafePrice(address _token) public view returns (uint256 _amountOut) {
        return getCurrentPrice(_token);
    }

    function getCurrentPrice(address _token) public view returns (uint256 _amountOut) {
        require(priceFeed[_token] != address(0), "UNSUPPORTED");

        _amountOut = _divide(
            _feedPrice(priceFeed[_token]),
            _feedPrice(BASE_PRICE_FEED),
            decimals
        );
    }

    function setOutputDecimals(uint8 _decimals) public onlyOwner {
        uint8 _old = _decimals;
        decimals = _decimals;
        emit OutputDecimalsUpdated(_old, _decimals);
    }

    function updateSafePrice(address _feed) public returns (uint256 _amountOut) {
        emit UpdateValues(_feed); // keeps this mutable so it matches the interface

        return getCurrentPrice(_feed);
    }

    /****** INTERNAL METHODS ******/

    /**
     * @dev internal method that does quick division using the set precision
     */
    function _divide(
        uint256 a,
        uint256 b,
        uint8 precision
    ) internal pure returns (uint256) {
        return (a * (10**precision)) / b;
    }

    function _feedPrice(address _feed) internal view returns (uint256 latestUSD) {

        /// To allow for TOKEN-ETH feeds on one oracle, TOKEN-USD feeds on another
        if(_feed == address(0)) {
            return PRECISION;
        }

        (uint80 roundID, int256 answer, uint256 startedAt, uint256 timestamp, uint80 answeredInRound) = AggregatorV3Interface(_feed).latestRoundData();

        require(answer > 0, 'ER045');
        require(timestamp != 0, 'ER046');
        require(answeredInRound >= roundID, "ER047");

        // difference between when started and returned needs to be less than 60-minutes
        require(timestamp - startedAt < MIN_TIME, "E113");

        return uint256(answer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IPriceOracle.sol";
import "../../interfaces/IPriceProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProviderAwareOracle is IPriceOracle, Ownable {

    uint internal constant PRECISION = 1 ether;

    IPriceProvider public provider;

    event ProviderTransfer(address _newProvider, address _oldProvider);

    constructor(address _provider) {
        provider = IPriceProvider(_provider);
    }

    function setPriceProvider(address _newProvider) external onlyOwner {
        address oldProvider = address(provider);
        provider = IPriceProvider(_newProvider);
        emit ProviderTransfer(_newProvider, oldProvider);
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
pragma solidity ^0.8.0;

interface IPriceProvider {

    event SetTokenOracle(address token, address oracle);

    function getSafePrice(address token) external view returns (uint256);

    function getCurrentPrice(address token) external view returns (uint256);

    function updateSafePrice(address token) external returns (uint256);

    /// Get value of an asset in units of quote
    function getValueOfAsset(address asset, address quote) external view returns (uint safePrice);

    function tokenHasOracle(address token) external view returns (bool hasOracle);

    function pairHasOracle(address token, address quote) external view returns (bool hasOracle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @dev Oracles should always return un the price in FTM with 18 decimals
interface IPriceOracle {
    /// @dev This method returns a flashloan resistant price.
    function getSafePrice(address token) external view returns (uint256 _amountOut);

    /// @dev This method has no guarantee on the safety of the price returned. It should only be
    //used if the price returned does not expose the caller contract to flashloan attacks.
    function getCurrentPrice(address token) external view returns (uint256 _amountOut);

    /// @dev This method returns a flashloan resistant price, but doesn't
    //have the view modifier which makes it convenient to update
    //a uniswap oracle which needs to maintain the TWAP regularly.
    //You can use this function while doing other state changing tx and
    //make the callers maintain the oracle.
    function updateSafePrice(address token) external returns (uint256 _amountOut);
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