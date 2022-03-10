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

pragma solidity ^0.8.4;

interface IUSDPairOracle {
    function getSpot(uint256 _pricePrecision) external view returns (uint256);

    function getTWAP(uint256 _pricePrecision) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ChainlinkOracleLib {
    function getPriceToUsd(address _chainlinkToUsd, uint256 _pricePrecition) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_chainlinkToUsd);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 _decimals = priceFeed.decimals();
        return (uint256(price) * _pricePrecition) / (10**_decimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IUSDPairOracle.sol";
import "../libs/ChainlinkOracleLib.sol";

contract MasterOracle is Ownable {
    uint256 private constant PRICE_PRECISION = 1e18;

    IUSDPairOracle public dollarUsdOracle;
    IUSDPairOracle public shareUsdOracle;
    address public usdcChainlinkDataFeed;

    /* ========== CONSTRUCTOR ================ */
    constructor(
        IUSDPairOracle _dollarUsdOracle,
        IUSDPairOracle _shareUsdOracle,
        address _usdcChainlinkDataFeed
    ) {
        require(address(_dollarUsdOracle) != address(0), "MasterOracle::dollarUsdOracle address is invalid ");
        require(address(_shareUsdOracle) != address(0), "MasterOracle::shareUsdOracle address is invalid ");
        require(_usdcChainlinkDataFeed != address(0), "MasterOracle::Usdc chainlink data feed address is invalid ");
        dollarUsdOracle = IUSDPairOracle(_dollarUsdOracle);
        shareUsdOracle = IUSDPairOracle(_shareUsdOracle);
        usdcChainlinkDataFeed = _usdcChainlinkDataFeed;
    }

    /* ========== VIEWS ========== */

    function getUsdcPrice() public view returns (uint256) {
        return ChainlinkOracleLib.getPriceToUsd(usdcChainlinkDataFeed, PRICE_PRECISION);
    }

    function getDollarPrice() public view returns (uint256) {
        return dollarUsdOracle.getSpot(PRICE_PRECISION);
    }

    function getDollarTWAP() public view returns (uint256) {
        return dollarUsdOracle.getTWAP(PRICE_PRECISION);
    }

    function getSharePrice() public view returns (uint256) {
        return shareUsdOracle.getSpot(PRICE_PRECISION);
    }

    function getShareTWAP() public view returns (uint256) {
        return shareUsdOracle.getTWAP(PRICE_PRECISION);
    }

    function getSpotPrices()
        external
        view
        returns (
            uint256 _sharePrice,
            uint256 _dollarPrice,
            uint256 _usdcPrice
        )
    {
        _sharePrice = getSharePrice();
        _dollarPrice = getDollarPrice();
        _usdcPrice = getUsdcPrice();
    }
}