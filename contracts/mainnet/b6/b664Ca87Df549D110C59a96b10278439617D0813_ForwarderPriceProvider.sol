// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "../PriceProvider.sol";
import "../../interfaces/IPriceProvidersRepository.sol";

/// @title ForwarderPriceProvider
/// @notice ForwarderPriceProvider is used to register the price of one token as the price source for another token.
///     For example, wrapped token price is equal to underlying token price, because it can be wrapped or
///     unwrapped with 1:1 ratio any time.
/// @custom:security-contact [email protected]
contract ForwarderPriceProvider is PriceProvider {
    /// @dev Token to get price, does not have pool => token that has price provider, used as the price source.
    mapping(address => address) public priceSourceAssets;

    event AssetRegistered(address indexed asset, address indexed priceSourceAsset);
    event AssetRemoved(address indexed asset);

    /// @dev Revert when price source for an asset does not exist.
    error AssetNotSupported();

    /// @dev Asset can't be it's own price source asset.
    error AssetEqualToSource();

    /// @dev Revert when price source is registered in `ForwarderPriceProvider` to prevent circular dependency.
    error DoubleForwardingIsNotAllowed();

    /// @dev Revert when price source asset does not have price in `PriceProvidersRepository`.
    error PriceSourceIsNotReady();

    /// @dev Revert `removeAsset` when `ForwarderPriceProvider` is registered as the price provider for an asset.
    error RemovingAssetWhenRegisteredInRepository();

    constructor(IPriceProvidersRepository _priceProvidersRepository) PriceProvider(_priceProvidersRepository) {}

    /// @inheritdoc IPriceProvider
    function getPrice(address _asset) public view virtual override returns (uint256) {
        address priceSourceAsset = priceSourceAssets[_asset];

        if (priceSourceAsset == address(0)) revert AssetNotSupported();

        return priceProvidersRepository.getPrice(priceSourceAsset);
    }

    /// @notice Register `_asset` price as the price of `_priceSourceAsset`
    /// @dev We don't allow price source asset to be registered in `ForwarderPriceProvider` to
    ///     prevent circular dependency. If the price source asset has price forwarded too, use the
    ///     original source instead. Does not revert for duplicate calls with the same arguments.
    /// @param _asset address, can be already registered in `ForwarderPriceProvider`
    /// @param _priceSourceAsset address, it's price must be available in `PriceProvidersRepository`
    function setupAsset(address _asset, address _priceSourceAsset) external virtual onlyManager {
        if (_asset == _priceSourceAsset) revert AssetEqualToSource();
        if (priceSourceAssets[_priceSourceAsset] != address(0)) revert DoubleForwardingIsNotAllowed();
        if (!priceProvidersRepository.providersReadyForAsset(_priceSourceAsset)) revert PriceSourceIsNotReady();

        priceSourceAssets[_asset] = _priceSourceAsset;

        emit AssetRegistered(_asset, _priceSourceAsset);
    }

    /// @notice Removes asset from this price provider. `ForwarderPriceProvider` must not be registered
    ///     as the price provider for an `_asset` in `PriceProvidersRepository`.
    /// @param _asset address
    function removeAsset(address _asset) external virtual onlyManager {
        if (address(priceProvidersRepository.priceProviders(_asset)) == address(this)) {
            revert RemovingAssetWhenRegisteredInRepository();
        }

        priceSourceAssets[_asset] = address(0);
        emit AssetRemoved(_asset);
    }

    /// @notice Returns true, if asset has other token price as the price source
    /// @param _asset address
    function assetSupported(address _asset) public view virtual override returns (bool) {
        return priceSourceAssets[_asset] != address(0);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

/// @title Common interface for Silo Price Providers
interface IPriceProvider {
    /// @notice Returns "Time-Weighted Average Price" for an asset. Calculates TWAP price for quote/asset.
    /// It unifies all tokens decimal to 18, examples:
    /// - if asses == quote it returns 1e18
    /// - if asset is USDC and quote is ETH and ETH costs ~$3300 then it returns ~0.0003e18 WETH per 1 USDC
    /// @param _asset address of an asset for which to read price
    /// @return price of asses with 18 decimals, throws when pool is not ready yet to provide price
    function getPrice(address _asset) external view returns (uint256 price);

    /// @dev Informs if PriceProvider is setup for asset. It does not means PriceProvider can provide price right away.
    /// Some providers implementations need time to "build" buffer for TWAP price,
    /// so price may not be available yet but this method will return true.
    /// @param _asset asset in question
    /// @return TRUE if asset has been setup, otherwise false
    function assetSupported(address _asset) external view returns (bool);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Helper method that allows easily detects, if contract is PriceProvider
    /// @dev this can save us from simple human errors, in case we use invalid address
    /// but this should NOT be treated as security check
    /// @return always true
    function priceProviderPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "./IPriceProvider.sol";

interface IPriceProvidersRepository {
    /// @notice Emitted when price provider is added
    /// @param newPriceProvider new price provider address
    event NewPriceProvider(IPriceProvider indexed newPriceProvider);

    /// @notice Emitted when price provider is removed
    /// @param priceProvider removed price provider address
    event PriceProviderRemoved(IPriceProvider indexed priceProvider);

    /// @notice Emitted when asset is assigned to price provider
    /// @param asset assigned asset   address
    /// @param priceProvider price provider address
    event PriceProviderForAsset(address indexed asset, IPriceProvider indexed priceProvider);

    /// @notice Register new price provider
    /// @param _priceProvider address of price provider
    function addPriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Unregister price provider
    /// @param _priceProvider address of price provider to be removed
    function removePriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Sets price provider for asset
    /// @dev Request for asset price is forwarded to the price provider assigned to that asset
    /// @param _asset address of an asset for which price provider will be used
    /// @param _priceProvider address of price provider
    function setPriceProviderForAsset(address _asset, IPriceProvider _priceProvider) external;

    /// @notice Returns "Time-Weighted Average Price" for an asset
    /// @param _asset address of an asset for which to read price
    /// @return price TWAP price of a token with 18 decimals
    function getPrice(address _asset) external view returns (uint256 price);

    /// @notice Gets price provider assigned to an asset
    /// @param _asset address of an asset for which to get price provider
    /// @return priceProvider address of price provider
    function priceProviders(address _asset) external view returns (IPriceProvider priceProvider);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Gets manager role address
    /// @return manager role address
    function manager() external view returns (address);

    /// @notice Checks if providers are available for an asset
    /// @param _asset asset address to check
    /// @return returns TRUE if price feed is ready, otherwise false
    function providersReadyForAsset(address _asset) external view returns (bool);

    /// @notice Returns true if address is a registered price provider
    /// @param _provider address of price provider to be removed
    /// @return true if address is a registered price provider, otherwise false
    function isPriceProvider(IPriceProvider _provider) external view returns (bool);

    /// @notice Gets number of price providers registered
    /// @return number of price providers registered
    function providersCount() external view returns (uint256);

    /// @notice Gets an array of price providers
    /// @return array of price providers
    function providerList() external view returns (address[] memory);

    /// @notice Sanity check function
    /// @return returns always TRUE
    function priceProvidersRepositoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;


library Ping {
    function pong(function() external pure returns(bytes4) pingFunction) internal pure returns (bool) {
        return pingFunction.address != address(0) && pingFunction.selector == pingFunction();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "../lib/Ping.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/IPriceProvidersRepository.sol";

/// @title PriceProvider
/// @notice Abstract PriceProvider contract, parent of all PriceProviders
/// @dev Price provider is a contract that directly integrates with a price source, ie. a DEX or alternative system
/// like Chainlink to calculate TWAP prices for assets. Each price provider should support a single price source
/// and multiple assets.
abstract contract PriceProvider is IPriceProvider {
    /// @notice PriceProvidersRepository address
    IPriceProvidersRepository public immutable priceProvidersRepository;

    /// @notice Token address which prices are quoted in. Must be the same as PriceProvidersRepository.quoteToken
    address public immutable override quoteToken;

    modifier onlyManager() {
        if (priceProvidersRepository.manager() != msg.sender) revert("OnlyManager");
        _;
    }

    /// @param _priceProvidersRepository address of PriceProvidersRepository
    constructor(IPriceProvidersRepository _priceProvidersRepository) {
        if (
            !Ping.pong(_priceProvidersRepository.priceProvidersRepositoryPing)            
        ) {
            revert("InvalidPriceProviderRepository");
        }

        priceProvidersRepository = _priceProvidersRepository;
        quoteToken = _priceProvidersRepository.quoteToken();
    }

    /// @inheritdoc IPriceProvider
    function priceProviderPing() external pure override returns (bytes4) {
        return this.priceProviderPing.selector;
    }

    function _revertBytes(bytes memory _errMsg, string memory _customErr) internal pure {
        if (_errMsg.length > 0) {
            assembly { // solhint-disable-line no-inline-assembly
                revert(add(32, _errMsg), mload(_errMsg))
            }
        }

        revert(_customErr);
    }
}