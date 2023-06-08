// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CurveLPTokensNPAPBaseCache.sol";
import "../interfaces/ICurvePoolNonPeggedAssetsLike.sol";
import "../interfaces/ICurveLPTokensDetailsFetchersRepository.sol";
import "../interfaces/ICurveLPTokensPriceProvider.sol";
import "../../_common/PriceProviderPing.sol";
import "../../_common/PriceProvidersRepositoryQuoteToken.sol";
import "../../../interfaces/IPriceProvidersRepository.sol";
import "./CurveNPAPTokensPriceProvider.sol";

/// @title Curve non-pegged pools tokens price provider for ethereum network
/// @notice We have a particular case with the tricrypto2 pool in the Ethereum network,
/// as it is without the lp_rice() function, and it is implemented in the separate smart contract.
/// @dev NPAP - non-pegged assets pools
contract CurveNPAPTokensPriceProviderETH is CurveNPAPTokensPriceProvider {
    /// @dev tricrypto2 (USDT/wBTC/ETH) LP Token (Ethereum network)
    address constant public TRICRYPTO2_LP_TOKEN = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff;
    /// @dev tricrypto2 smart contract to provide LP token price (Ethereum network)
    address constant public TRICRYPTO2_LP_PRICE = 0xE8b2989276E2Ca8FDEA2268E3551b2b4B2418950;

    /// @dev Constructor is required for indirect CurveLPTokensPriceProvider initialization.
    /// Arguments for CurveLPTokensPriceProvider initialization are given in the
    /// modifier-style in the derived constructor. There are no requirements during
    /// CurveNPAPTokensPriceProviderETH deployment, so the constructor body should be empty.
    constructor(
        IPriceProvidersRepository _providersRepository,
        ICurveLPTokensDetailsFetchersRepository _fetchersRepository,
        address _nullAddr,
        address _nativeWrappedAddr
    )
        CurveNPAPTokensPriceProvider(
            _providersRepository,
            _fetchersRepository,
            _nullAddr,
            _nativeWrappedAddr
        )
    {
        // The code will not compile without it. So, we need to keep an empty constructor.
    }

    /// @param _lpToken Curve LP Token address for which a price to be calculated
    /// @return Price of the `_lpToken` denominated in the price providers repository quote token
    function getPrice(address _lpToken) external override view returns (uint256) {
        address pool = lpTokenPool[_lpToken].addr;

        if (pool == address(0)) revert NotSupported();

        // We have a particular case for the tricrypto2 pool, as originally, it didn't support
        // the `lp_price` function. Because of it, function was implemented in a separate smart contract.
        address provider = _lpToken == TRICRYPTO2_LP_TOKEN ? TRICRYPTO2_LP_PRICE : pool;
        uint256 lpPrice = ICurvePoolNonPeggedAssetsLike(provider).lp_price();

        return _getPrice(_lpToken, lpPrice);
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
pragma solidity 0.8.13;

import "../../interfaces/IPriceProvider.sol";

/// @title Price Provider ping feature
abstract contract PriceProviderPing is IPriceProvider {
    /// @inheritdoc IPriceProvider
    function priceProviderPing() external pure returns (bytes4) {
        return this.priceProviderPing.selector;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "../../lib/Ping.sol";
import "../../interfaces/IPriceProvidersRepository.sol";

/// @title Price Providers Repository manager
abstract contract PriceProvidersRepositoryManager  {
    /// @dev Price Providers Repository
    IPriceProvidersRepository internal immutable _priceProvidersRepository;

    /// @dev Revert if `msg.sender` is not Price Providers Repository manager
    error OnlyManager();
    /// @dev Revert on a false sanity check with `Ping` library
    error InvalidPriceProviderRepository();

    /// @dev Permissions verification modifier.
    /// Functions execution with this modifier will be allowed only for the Price Providers Repository manager
    modifier onlyManager() {
        if (_priceProvidersRepository.manager() != msg.sender) revert OnlyManager();
        _;
    }

    /// @param _repository address of the Price Providers Repository
    constructor(IPriceProvidersRepository _repository) {
        if (!Ping.pong(_repository.priceProvidersRepositoryPing)) {
            revert InvalidPriceProviderRepository();
        }

        _priceProvidersRepository = _repository;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./PriceProvidersRepositoryManager.sol";
import "../../interfaces/IPriceProvider.sol";

/// @title Price providers repository quote token
abstract contract PriceProvidersRepositoryQuoteToken is PriceProvidersRepositoryManager, IPriceProvider {
    /// @inheritdoc IPriceProvider
    function quoteToken() external view returns (address) {
        return _priceProvidersRepository.quoteToken();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "../../../lib/Ping.sol";
import "../../_common/PriceProvidersRepositoryManager.sol";
import "../../../interfaces/IPriceProvider.sol";
import "../interfaces/ICurveRegistryLike.sol";
import "../interfaces/ICurveLPTokensDetailsFetchersRepository.sol";
import "./CurveLPTokensDataTypes.sol";

abstract contract CurveLPTokenDetailsBaseCache {
    /// @notice Curve LP Tokens details fetchers repository
    // solhint-disable-next-line var-name-mixedcase
    ICurveLPTokensDetailsFetchersRepository internal immutable _FETCHERS_REPO;
    /// @notice A null address that the Curve pool use to describe ether coin
    // solhint-disable-next-line var-name-mixedcase
    address internal immutable _NULL_ADDRESS;
    /// @notice wETH address
    // solhint-disable-next-line var-name-mixedcase
    address internal immutable _NATIVE_WRAPPED_ADDRESS;
    /// @notice Minimal number of coins in the valid pool
    uint8 internal constant _MIN_COINS = 2;

    /// @dev LP Token address => pool coins
    mapping(address => PoolCoin[]) public coins;
    /// @dev LP Token address => pool details
    mapping(address => Pool) public lpTokenPool;

    /// Revert if this price provider does not support an asset
    error NotSupported();
    /// Revert on a false sanity check with `Ping` library
    error InvalidFetchersRepository();
    /// Revert if a pool is not found for provided Curve LP Token
    error PoolForLPTokenNotFound();
    /// Revert if a number of coins in the initialized pool < `_MIN_COINS`
    error InvalidNumberOfCoinsInPool();
    /// Revert if Curve LP Token is already initialized in the price provider
    error TokenAlreadyInitialized();
    /// Revert if wETH address is empty
    error EmptyWETHAddress();
    /// @dev Revert if a `getPrice` function ended-up with a zero price
    error ZeroPrice();

    /// @param _repository Curve LP Tokens details fetchers repository
    /// @param _nullAddr Null address that Curve use for a native token
    /// @param _nativeWrappedAddr Address of the wrapped native token
    constructor(
        ICurveLPTokensDetailsFetchersRepository _repository,
        address _nullAddr,
        address _nativeWrappedAddr
    ) {
        if (address(_nativeWrappedAddr) == address(0)) revert EmptyWETHAddress();

        if (!Ping.pong(_repository.curveLPTokensFetchersRepositoryPing)) {
            revert InvalidFetchersRepository();
        }

        _FETCHERS_REPO = _repository;
        _NULL_ADDRESS = _nullAddr;
        _NATIVE_WRAPPED_ADDRESS = _nativeWrappedAddr;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev Identifiers of the Curve protocol components in the Curve address provider
enum RegistryId {
    MAIN_REGISTRY_0,
    POOL_INFO_GETTER_1,
    EXCHANGES_2,
    META_POOL_FACTORY_3,
    FEE_DISTRIBUTOR_4,
    CRYPTO_SWAP_REGISTRY_5,
    CRYPTO_POOL_FACTORY_6
}

/// @dev Storage struct that holds Curve pool coin details
struct PoolCoin {
    /// @dev Coin address
    address addr;
    /// @dev `true` if a coin is Curve LP Token (used in the meta pools)
    bool isLPToken;
}

/// @dev Storage struct that holds Curve pool details
struct Pool {
    /// @dev Pool address
    address addr;
    /// @dev `true` if a pool is the meta pool (the pool that contains other Curve LP Tokens)
    bool isMeta;
}

/// @dev Describes an LP Token with all the details required for the price calculation
struct LPTokenDetails {
    /// @dev A pool of the LP Token. See a Pool struct
    Pool pool;
    /// @dev A list of the LP token pool coins
    address[] coins;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "../_common/CurveLPTokensDataTypes.sol";

/// @title Curve LP Tokens details fetcher
/// @dev Designed to unify an interface of the Curve pool tokens details getter,
/// such registries as Main Registry, CryptoSwap Registry,  Metapool Factory, and Cryptopool Factory
/// have different interfaces.
interface ICurveLPTokensDetailsFetcher {
    /// @notice Emitted when Curve LP registry address has been updated
    /// @param registry The configured registry address
    event RegistryUpdated(address indexed registry);

    /// @notice Pulls a registry address from the Curve address provider
    function updateRegistry() external;

    /// @notice Curve LP Token details getter
    /// @param _lpToken Curve LP token address
    /// @param _data Any additional data that can be required
    /// @dev This method should not revert. If the data is not found or provided an invalid LP token address,
    /// it should return an empty data structure.
    /// @return details LP token details. See CurveLPTokensDataTypes.LPTokenDetails
    /// @return data Any additional data to return
    function getLPTokenDetails(
        address _lpToken,
        bytes memory _data
    )
      external
      view
      returns (
        LPTokenDetails memory details,
        bytes memory data
      );

    /// @notice Helper method that allows easily detects, if contract is Curve Registry Fatcher
    /// @return always curveLPTokensDetailsFetcherPing.selector
    function curveLPTokensDetailsFetcherPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./ICurveLPTokensDetailsFetcher.sol";
import "../_common/CurveLPTokensDataTypes.sol";

/// @title Curve LP Tokens details fetchers repository
/// @dev Designed to unify an interface of the Curve pool tokens details getter,
/// such registries as Main Registry, CryptoSwap Registry,  Metapool Factory, and Cryptopool Factory
/// have different interfaces.
interface ICurveLPTokensDetailsFetchersRepository {
    /// @notice Emitted when Curve LP token fetcher added to the repository
    /// @param fetcher Added fetcher address
    event FetcherAdded(ICurveLPTokensDetailsFetcher indexed fetcher);

    /// @notice Emitted when Curve LP token fetcher removed from the repository
    /// @param fetcher Removed fetcher address
    event FetcherRemoved(ICurveLPTokensDetailsFetcher indexed fetcher);

    /// @notice Add Curve LP token details fetcher to the repository
    /// @param _fetcher A Curve LP token details fetcher to be added to the repository
    function addFetcher(ICurveLPTokensDetailsFetcher _fetcher) external;

    /// @notice Remove Curve LP token details fetcher from the repository
    /// @param _fetcher A Curve LP token details fetcher to be removed from the repository
    function removeFetcher(ICurveLPTokensDetailsFetcher _fetcher) external;

    /// @notice Curve LP Token details getter
    /// @param _lpToken Curve LP token address
    /// @param _data Any additional data that can be required
    /// @return details LP token details. See CurveLPTokensDataTypes.LPTokenDetails
    /// @return data Any additional data to return
    function getLPTokenDetails(
        address _lpToken,
        bytes memory _data
    )
        external
        view
        returns (
            LPTokenDetails memory details,
            bytes memory data
        );

    /// @return pool of the `_lpToken`
    function getLPTokenPool(address _lpToken) external view returns (address pool);

    /// @dev Returns a list of the registered fetchers
    function getFetchers() external view returns (address[] memory);

    /// @notice Helper method that allows easily detects, if contract is Curve Repository fetcher
    /// @return always curveLPTokensFetchersRepositoryPing.selector
    function curveLPTokensFetchersRepositoryPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "../_common/CurveLPTokensDataTypes.sol";
import "../../../interfaces/IPriceProvider.sol";

/// @notice A price provider for Curve LP Tokens
interface ICurveLPTokensPriceProvider is IPriceProvider {
    /// @notice Enable Curve LP token in the price provider
    /// @param _lpToken Curve LP Token address that will be enabled in the price provider
    function setupAsset(address _lpToken) external;

    /// @notice Enable a list of Curve LP tokens in the price provider
    /// @param _lpTokens List of Curve LP Tokens addresses that will be enabled in the price provider
    function setupAssets(address[] memory _lpTokens) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @notice A simplified interface of the Curve pool.
/// @dev Includes only methods for CurveLPTokensPriceProviders.
interface ICurvePoolNonPeggedAssetsLike {
    /// Description from Curve docs:
    /// @notice Approximate LP token price
    /// @dev n * self.virtual_price * self.sqrt_int(self.internal_price_oracle()) / 10**18
    /// where n is a number of coins in the pool
    //  solhint-disable-next-line func-name-mixedcase
    function lp_price() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @notice A simplified interface of the Curve registry.
/// @dev Includes only methods for CurveLPTokensPriceProvider.
interface ICurveRegistryLike {
    /// @param _lpToken LP Token address to fetch a pool address for
    /// @return Pool address associated with `_lpToken`
    //  solhint-disable-next-line func-name-mixedcase
    function get_pool_from_lp_token(address _lpToken) external view returns (address);

    /// @notice Verifies whether a pool is meta pool
    /// @param _pool Pool address to be verified
    /// @return Boolean value that shows if a pool is a meta pool or not
    //  solhint-disable-next-line func-name-mixedcase
    function is_meta(address _pool) external view returns (bool);

    /// @param _pool Pool address to fetch coins for
    /// @return A list of coins in the pool
    //  solhint-disable-next-line func-name-mixedcase
    function get_coins(address _pool) external view returns (address[8] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "../_common/CurveLPTokenDetailsBaseCache.sol";

/// @dev NPAP - non-pegged assets pools
abstract contract CurveLPTokensNPAPBaseCache is CurveLPTokenDetailsBaseCache {
    /// @notice Emitted when Curve LP token was enabled in the price provider
    /// @param pool Pool address of the Curve LP token
    /// @param token Curve LP token address that has been enabled in the price provider
    event LPTokenEnabled(address indexed pool, address indexed token);

    /// @dev Revert if the Curve LP tokens detail fetchers repository returned details
    /// with an `isMeta` flag equal to `true` for the pool with non-pegged assets.
    error CryptoPoolCantBeMetaPool();

    /// @notice Enable Curve LP token in the price provider
    /// @dev Reverts if the token is already initialized
    /// @param _lpToken Curve LP Token address that will be enabled in the price provider
    function _setupAsset(address _lpToken) internal virtual {
        if (coins[_lpToken].length != 0) revert TokenAlreadyInitialized();

        bytes memory data; // We'll use it as an `input` and `return` data
        LPTokenDetails memory details;

        (details, data) = _FETCHERS_REPO.getLPTokenDetails(_lpToken, data);

        if (details.pool.addr == address(0) || details.coins[0] == address(0)) {
            revert PoolForLPTokenNotFound();
        }

        if (details.coins.length < _MIN_COINS) revert InvalidNumberOfCoinsInPool();

        // Sanity check to ensure a data validity.
        // Crypto pools are not meta pools.
        if (details.pool.isMeta) revert CryptoPoolCantBeMetaPool();

        // For the pools with non-pegged asset we don't need to store all coins
        // as a price that pool will return will be denominated in the coins[0]
        PoolCoin memory coin = PoolCoin({ addr: details.coins[0], isLPToken: false });

        // Some of the Curve pools for ether use 'Null Address' which we are not
        // able to use for the price calculation. To be able to calculate an LP Token
        // price for this kind of pools we will use wETH address instead.
        if (coin.addr == _NULL_ADDRESS) {
            coin.addr = _NATIVE_WRAPPED_ADDRESS;
        }

        coins[_lpToken].push(coin);

        lpTokenPool[_lpToken] = details.pool;

        emit LPTokenEnabled(lpTokenPool[_lpToken].addr, _lpToken);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CurveLPTokensNPAPBaseCache.sol";
import "../interfaces/ICurvePoolNonPeggedAssetsLike.sol";
import "../interfaces/ICurveLPTokensDetailsFetchersRepository.sol";
import "../interfaces/ICurveLPTokensPriceProvider.sol";
import "../../_common/PriceProviderPing.sol";
import "../../_common/PriceProvidersRepositoryQuoteToken.sol";
import "../../../interfaces/IPriceProvidersRepository.sol";

/// @title Curve non-pegged pools tokens price provider
/// @dev NPAP - non-pegged assets pools
contract CurveNPAPTokensPriceProvider is
    CurveLPTokensNPAPBaseCache,
    PriceProvidersRepositoryQuoteToken,
    PriceProviderPing,
    ICurveLPTokensPriceProvider
{
    /// @dev Constructor is required for indirect CurveLPTokensPriceProvider initialization.
    /// Arguments for CurveLPTokensPriceProvider initialization are given in the
    /// modifier-style in the derived constructor. There are no requirements during
    /// CurveNPAPTokensPriceProvider deployment, so the constructor body should be empty.
    constructor(
        IPriceProvidersRepository _providersRepository,
        ICurveLPTokensDetailsFetchersRepository _fetchersRepository,
        address _nullAddr,
        address _nativeWrappedAddr
    )
        PriceProvidersRepositoryManager(_providersRepository)
        CurveLPTokenDetailsBaseCache(_fetchersRepository, _nullAddr, _nativeWrappedAddr)
    {
        // The code will not compile without it. So, we need to keep an empty constructor.
    }

    /// @inheritdoc ICurveLPTokensPriceProvider
    function setupAsset(address _lpToken) external virtual onlyManager {
        _setUpAssetAndEnsureItIsSupported(_lpToken);
    }

    /// @inheritdoc ICurveLPTokensPriceProvider
    function setupAssets(address[] calldata _lpTokens) external virtual onlyManager {
        uint256 i = 0;

        while(i < _lpTokens.length) {
            _setUpAssetAndEnsureItIsSupported(_lpTokens[i]);

            // Ignoring overflow check as it is impossible
            // to have more than 2 ** 256 - 1 LP Tokens for initialization.
            unchecked { i++; }
        }
    }

    /// @inheritdoc IPriceProvider
    function assetSupported(address _lpToken) external virtual view returns (bool) {
        return lpTokenPool[_lpToken].addr != address(0);
    }

    /// @param _lpToken Curve LP Token address for which a price to be calculated
    /// @return Price of the `_lpToken` denominated in the price providers repository quote token
    function getPrice(address _lpToken) external virtual view returns (uint256) {
        address pool = lpTokenPool[_lpToken].addr;

        if (pool == address(0)) revert NotSupported();
        
        uint256 lpPrice = ICurvePoolNonPeggedAssetsLike(pool).lp_price();

        return _getPrice(_lpToken, lpPrice);
    }

    /// @notice Enable Curve LP token in the price provider
    /// @param _lpToken Curve LP Token address that will be enabled in the price provider
    function _setUpAssetAndEnsureItIsSupported(address _lpToken) internal virtual {
        _setupAsset(_lpToken);
        
        // Ensure that the get price function does not revert for initialized coins
        // The price providers repository should revert if the provided coin is not supported
        _priceProvidersRepository.getPrice(coins[_lpToken][0].addr);
    }

    /// @param _lpToken Curve LP Token address for which a price to be calculated
    /// @param _lpPrice Curve LP Token price received from the pool's `lp_price` function
    /// @return price of the `_lpToken` denominated in the price providers repository quote token
    function _getPrice(address _lpToken, uint256 _lpPrice) internal virtual view returns (uint256 price) {
        uint256 coinPrice = _priceProvidersRepository.getPrice(coins[_lpToken][0].addr);

        // `_lpToken` price calculation
        price = coinPrice * _lpPrice;

        // It doesn't make sense to do any math check here because if a `price` < 1e18,
        // in any case, it will return 0. Otherwise, we are fine.
        unchecked { price = price / 1e18; }

        // Zero price is unacceptable
        if (price == 0) revert ZeroPrice();
    }
}