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

interface IChainlinkPairOracle {
    function getPriceSpot(uint256 _pricePrecision) external view returns (uint256);

    function getPriceTWAP(uint256 _pricePrecision) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ChainlinkOracle {
    function getPriceToUsd(address oracleAddress, uint256 pricePrecition) internal view returns (uint256) {
        AggregatorV3Interface oracle = AggregatorV3Interface(oracleAddress);
        (, int256 price, , , ) = oracle.latestRoundData();
        uint8 _decimals = oracle.decimals();
        return (uint256(price) * pricePrecition) / _decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IChainlinkPairOracle.sol";
import "../libs/ChainlinkOracle.sol";

contract MasterOracle is Ownable {
    uint256 private constant PRICE_PRECISION = 1e18;
    IChainlinkPairOracle public oracleDollarUsd;
    IChainlinkPairOracle public oracleShareUsd;
    address public oracleUsdc;

    constructor(
        address _oracleDollarUsd,
        address _oracleShareUsd,
        address _oracleUsdc
    ) {
        require(_oracleDollarUsd != address(0), "Dollar oracle invalid address");
        require(_oracleShareUsd != address(0), "Share oracle invalid address");
        require(_oracleUsdc != address(0), "Usdc oracle invalid address");
        oracleDollarUsd = IChainlinkPairOracle(_oracleDollarUsd);
        oracleShareUsd = IChainlinkPairOracle(_oracleShareUsd);
        oracleUsdc = _oracleUsdc;
    }

    function getUsdcPrice() public view returns (uint256) {
        return ChainlinkOracle.getPriceToUsd(oracleUsdc, PRICE_PRECISION);
    }

    function getDollarPrice() public view returns (uint256) {
        return oracleDollarUsd.getPriceSpot(PRICE_PRECISION);
    }

    function getDollarTWAP() public view returns (uint256) {
        return oracleDollarUsd.getPriceTWAP(PRICE_PRECISION);
    }

    function getSharePrice() public view returns (uint256) {
        return oracleShareUsd.getPriceSpot(PRICE_PRECISION);
    }

    function getShareTWAP() public view returns (uint256) {
        return oracleShareUsd.getPriceTWAP(PRICE_PRECISION);
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