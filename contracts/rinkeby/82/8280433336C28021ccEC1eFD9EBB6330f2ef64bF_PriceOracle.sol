// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAggregatorV3.sol";

interface IERC20Metadata {
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract PriceOracle is Ownable {
    /**
     * @dev please take care token decimal
     * e.x ethPrice[uno_address] = 123456 means 1 UNO = 123456 / (10 ** 18 eth)
     */
    mapping(address => uint256) ethPrices;
    // address private ethUSDAggregator = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e; // rinkeby
    address private ethUSDAggregator = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    event AssetPriceUpdated(address _asset, uint256 _price, uint256 timestamp);
    event SetETHUSDAggregator(address _oldAggregator, address _newAggregator);

    function getEthUsdPrice() external view returns (uint256) {
        return _fetchEthUsdPrice();
    }

    function _fetchEthUsdPrice() private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(ethUSDAggregator);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) / 1e8;
    }

    function getAssetEthPrice(address _asset) external view returns (uint256) {
        return ethPrices[_asset];
    }

    function setAssetEthPrice(address _asset, uint256 _price) external onlyOwner {
        ethPrices[_asset] = _price;
        emit AssetPriceUpdated(_asset, _price, block.timestamp);
    }

    function setETHUSDAggregator(address _aggregator) external onlyOwner {
        address oldAggregator = ethUSDAggregator;
        ethUSDAggregator = _aggregator;
        emit SetETHUSDAggregator(oldAggregator, _aggregator);
    }

    /**
     * returns the tokenB amount for tokenA
     */
    function consult(
        address tokenA,
        address tokenB,
        uint256 amountA
    ) external view returns (uint256) {
        require(ethPrices[tokenA] != 0 && ethPrices[tokenB] != 0, "PO: Prices of boht tokens should be set");

        // amountA * ethPrices[tokenA] / IERC20Metadata(tokenA).decimals() / ethPrices[tokenB] * IERC20Metadata(tokenB).decimals()
        return
            (amountA * ethPrices[tokenA] * (10**IERC20Metadata(tokenB).decimals())) /
            (10**IERC20Metadata(tokenA).decimals() * ethPrices[tokenB]);
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