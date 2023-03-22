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
pragma solidity ^0.8.17;

/**
 * @title IOracleGetter interface
 * @notice Interface for the nft price oracle.
 **/

interface IOracleGetter {
    /**
     * @dev returns the asset price in ETH
     * @param asset the address of the asset
     * @return the ETH price of the asset
     **/
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @dev returns the volatility of the asset
     * @param asset the address of the asset
     * @return the volatility of the asset
     **/
    function getAssetVol(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOracleGetter.sol";

/**
 * @title NFTOracle
 * @author NFTCall
 * @notice Smart contract to get the price of an asset from a price source, with BenDAO
 *          smart contracts as primary option
 *  - If the returned price by BenDAO is <= 0, the call is forwarded to a fallbackOracle
 *  - Owner allowed to add sources for assets, replace them and change the fallbackOracle
 */
contract NFTOracle is IOracleGetter, Ownable {
    struct Source {
        address addr;
        bytes4 selector;
    }
    mapping(address => Source) private assetsSources;
    IOracleGetter private _fallbackOracle;

    event AssetSourceUpdated(
        address indexed asset,
        address indexed source,
        bytes4 selector
    );
    event FallbackOracleUpdated(address indexed fallbackOracle);

    /**
     * @dev Constructor
     * @param assets The addresses of the assets
     * @param sources The Source of the source of each asset
     * @param fallbackOracle The address of the fallback oracle to use
     */
    constructor(
        address[] memory assets,
        Source[] memory sources,
        address fallbackOracle
    ) {
        _setFallbackOracle(fallbackOracle);
        _setAssetsSources(assets, sources);
    }

    /**
     * @dev External function called by the owner to set or replace sources of assets
     * @param assets The addresses of the assets
     * @param sources The Source of the source of each asset
     */
    function setAssetSources(
        address[] memory assets,
        Source[] memory sources
    ) external onlyOwner {
        _setAssetsSources(assets, sources);
    }

    /**
     * @dev Sets the fallbackOracle
     * - Callable only by the owner
     * @param fallbackOracle The address of the fallbackOracle
     */
    function setFallbackOracle(address fallbackOracle) external onlyOwner {
        _setFallbackOracle(fallbackOracle);
    }

    /**
     * @dev Internal function to set the sources for each asset
     * @param assets The addresses of the assets
     * @param sources The Source of the source of each asset
     */
    function _setAssetsSources(
        address[] memory assets,
        Source[] memory sources
    ) internal {
        require(assets.length == sources.length, "INCONSISTENT_PARAMS_LENGTH");
        for (uint256 i = 0; i < assets.length; i++) {
            Source memory source = sources[i];
            assetsSources[assets[i]] = source;
            emit AssetSourceUpdated(assets[i], source.addr, source.selector);
        }
    }

    /**
     * @dev Internal function to set the fallbackOracle
     * @param fallbackOracle The address of the fallbackOracle
     */
    function _setFallbackOracle(address fallbackOracle) internal {
        _fallbackOracle = IOracleGetter(fallbackOracle);
        emit FallbackOracleUpdated(fallbackOracle);
    }

    /**
     * @dev Get an asset price by address
     * @param asset The asset address
     */
    function getAssetPrice(
        address asset
    ) public view override returns (uint256) {
        Source memory source = assetsSources[asset];

        uint256 price;
        if (address(source.addr) != address(0)) {
            (bool success, bytes memory returnedData) = source.addr.staticcall(
                abi.encodeWithSelector(source.selector, asset)
            );
            require(success);
            price = abi.decode(returnedData, (uint256));
        }
        if (price > 0) {
            return price;
        } else {
            return _fallbackOracle.getAssetPrice(asset);
        }
    }

    /**
     * @dev Get volatility by address
     * @param asset The asset address
     */
    function getAssetVol(address asset) public view override returns (uint256) {
        return _fallbackOracle.getAssetVol(asset);
    }

    function getAssets(
        address[] memory assets
    ) external view returns (uint256[2][] memory prices) {
        prices = new uint256[2][](assets.length);
        uint256 price;
        uint256 vol;
        for (uint256 i = 0; i < assets.length; i++) {
            price = getAssetPrice(assets[i]);
            vol = getAssetVol(assets[i]);
            prices[i] = [price, vol];
        }
        return prices;
    }

    /**
     * @dev Gets the address of the source for an asset address
     * @param asset The address of the asset
     * @return address The Source of the source
     */
    function getSourceOfAsset(
        address asset
    ) external view returns (Source memory) {
        return assetsSources[asset];
    }

    /**
     * @dev Gets the address of the fallback oracle
     * @return address The addres of the fallback oracle
     */
    function getFallbackOracle() external view returns (address) {
        return address(_fallbackOracle);
    }
}