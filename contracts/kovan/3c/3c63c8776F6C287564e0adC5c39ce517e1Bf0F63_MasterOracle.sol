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

pragma solidity 0.8.4;

interface IPairOracle {
    function twap(address token, uint256 pricePrecision) external view returns (uint256 amountOut);

    function spot(address token, uint256 pricePrecision) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPairOracle.sol";

contract MasterOracle is Ownable {
    /*================= VARIABLES ==================*/

    address public dollar;
    address public share;

    IPairOracle public immutable dollarUsdcPairOracle;
    IPairOracle public immutable shareEthPairOracle;

    AggregatorV3Interface public immutable usdcToUsdChainlink;
    AggregatorV3Interface public immutable ethToUsdChainlink;

    /*================= CONSTANTS ==================*/
    uint256 private constant PRICE_PRECISION = 1e18;

    /*================= CONSTRUCTOR ==================*/
    constructor(
        address _dollar,
        address _share,
        address _dollarUsdcPairOracle,
        address _shareEthPairOracle,
        address _usdcToUsdChainlink,
        address _ethToUsdChainlink
    ) {
        require(_dollar != address(0), "MasterOracle::constructor: Invalid address");
        require(_share != address(0), "MasterOracle::constructor:Invalid address");
        require(_shareEthPairOracle != address(0), "MasterOracle::constructor: Invalid address");
        require(_dollarUsdcPairOracle != address(0), "MasterOracle::constructor:Invalid address");
        require(_usdcToUsdChainlink != address(0), "MasterOracle::constructor: Invalid address");
        require(_ethToUsdChainlink != address(0), "MasterOracle::constructor: Invalid address");
        dollarUsdcPairOracle = IPairOracle(_dollarUsdcPairOracle);
        shareEthPairOracle = IPairOracle(_shareEthPairOracle);
        dollar = _dollar;
        share = _share;
        usdcToUsdChainlink = AggregatorV3Interface(_usdcToUsdChainlink);
        ethToUsdChainlink = AggregatorV3Interface(_ethToUsdChainlink);
    }

    /*================= VIEWS ==================*/

    /**
     * @notice Get TWAP of dollar
     * @return TWAP of Dollar
     */
    function getDollarTWAP() public view returns (uint256) {
        return twap(dollar, dollarUsdcPairOracle, usdcToUsdChainlink);
    }

    /**
     * @notice Get TWAP of share
     * @return TWAP of Share
     */
    function getShareTWAP() public view returns (uint256) {
        return twap(share, shareEthPairOracle, ethToUsdChainlink);
    }

    /**
     * @notice Get spot prices of Share, Dollar and USDC to $ value
     * @return _sharePrice Price of Share
     * @return _dollarPrice Price of Dollar
     * @return _usdcPrice Price of USDC
     */
    function getSpotPrices()
        external
        view
        returns (
            uint256 _sharePrice,
            uint256 _dollarPrice,
            uint256 _usdcPrice
        )
    {
        _sharePrice = spot(share, shareEthPairOracle, ethToUsdChainlink);
        _dollarPrice = spot(dollar, dollarUsdcPairOracle, usdcToUsdChainlink);
        _usdcPrice = getChainlinkPrice(usdcToUsdChainlink);
    }

    /*================= INTERNAL FUNCTIONS ==================*/
    /**
     * @notice get usd spot price of token
     * @param _token: Token address
     * @param _pairOracle: precision for price
     * @param _chainlinkTokenToUsdPriceFeed: precision for price
     * @return SpotPrice
     */
    function spot(
        address _token,
        IPairOracle _pairOracle,
        AggregatorV3Interface _chainlinkTokenToUsdPriceFeed
    ) internal view returns (uint256) {
        (, int256 tokenToUsdPrice, , , ) = _chainlinkTokenToUsdPriceFeed.latestRoundData();
        uint8 decimals = _chainlinkTokenToUsdPriceFeed.decimals();
        return (_pairOracle.spot(_token, PRICE_PRECISION) * uint256(tokenToUsdPrice)) / (10**decimals);
    }

    /**
     * @notice get usd spot price of token
     * @param _token: Token address
     * @param _pairOracle: precision for price
     * @param _chainlinkTokenToUsdPriceFeed: precision for price
     * @return Timeweighted  Average Price
     */
    function twap(
        address _token,
        IPairOracle _pairOracle,
        AggregatorV3Interface _chainlinkTokenToUsdPriceFeed
    ) internal view returns (uint256) {
        (, int256 tokenToUsdPrice, , , ) = _chainlinkTokenToUsdPriceFeed.latestRoundData();
        uint8 decimals = _chainlinkTokenToUsdPriceFeed.decimals();
        return (_pairOracle.twap(_token, PRICE_PRECISION) * uint256(tokenToUsdPrice)) / (10**decimals);
    }

    /**
     * @notice get usd  price of token via Chainlink
     * @param _chainlinkTokenToUsdPriceFeed: precision for price
     * @return Price
     */
    function getChainlinkPrice(AggregatorV3Interface _chainlinkTokenToUsdPriceFeed) internal view returns (uint256) {
        (, int256 tokenToUsdPrice, , , ) = _chainlinkTokenToUsdPriceFeed.latestRoundData();
        uint8 decimals = _chainlinkTokenToUsdPriceFeed.decimals();
        return (PRICE_PRECISION * uint256(tokenToUsdPrice)) / (10**decimals);
    }
}