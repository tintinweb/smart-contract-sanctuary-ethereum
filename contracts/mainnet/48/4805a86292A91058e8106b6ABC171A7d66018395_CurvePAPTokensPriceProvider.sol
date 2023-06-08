// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CurveReentrancyCheck.sol";
import "./CurveLPTokensPAPBaseCache.sol";
import "../interfaces/ICurvePoolLike.sol";
import "../interfaces/ICurveLPTokensDetailsFetchersRepository.sol";
import "../interfaces/ICurveLPTokensPriceProvider.sol";
import "../../_common/PriceProviderPing.sol";
import "../../_common/PriceProvidersRepositoryQuoteToken.sol";
import "../../../interfaces/IPriceProvidersRepository.sol";
import "../../../lib/MathHelpers.sol";

/// @title Curve pegged pools tokens price provider
/// @dev PAP - pegged assets pools
contract CurvePAPTokensPriceProvider is
    CurveReentrancyCheck,
    CurveLPTokensPAPBaseCache,
    PriceProvidersRepositoryQuoteToken,
    PriceProviderPing,
    ICurveLPTokensPriceProvider
{
    using MathHelpers for uint256[];

    /// @dev Maximal number of coins in the Curve pools
    uint256 constant internal _MAX_NUMBER_OF_COINS = 8;

    /// @dev Revert in the case when the `@nonreentrant('lock')` is activated in the Curve pool
    error NonreentrantLockIsActive();

    /// @dev Constructor is required for indirect CurveLPTokensPriceProvider initialization.
    /// Arguments for CurveLPTokensPriceProvider initialization are given in the
    /// modifier-style in the derived constructor. There are no requirements during
    /// CurvePAPTokensPriceProvider deployment, so the constructor body should be empty.
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

    /// @inheritdoc ICurveReentrancyCheck
    function setReentrancyVerificationConfig(
        address _pool,
        uint128 _gasLimit,
        N_COINS _nCoins
    )
        external
        virtual
        onlyManager
    {
        _setReentrancyVerificationConfig(_pool, _gasLimit, _nCoins);
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
    /// @return price of the `_lpToken` denominated in the price providers repository quote token
    function getPrice(address _lpToken) external virtual view returns (uint256 price) {
        address pool = lpTokenPool[_lpToken].addr;

        if (pool == address(0)) revert NotSupported();

        if (isLocked(pool)) revert NonreentrantLockIsActive();

        uint256 minPrice = _lpTokenPoolCoinsPrices(_lpToken).minValue();
        uint256 virtualPrice = ICurvePoolLike(pool).get_virtual_price();

        // `_lpToken` price calculation
        // Expect a `virtualPrice` to be a value close to 10 ** 18.
        // So, to have an overflow here a `minPrice` value must be approximately > 10 ** 59.
        // About the price calculation algorithm:
        // https://news.curve.fi/chainlink-oracles-and-curve-pools/
        price = minPrice * virtualPrice;

        // It doesn't make sense to do any math check here because if a `price` < 1e18,
        // in any case, it will return 0. Otherwise, we are fine.
        unchecked { price = price / 1e18; }

        // Zero price is unacceptable
        if (price == 0) revert ZeroPrice();
    }

    /// @notice Getter that resolves a list of the underlying coins for an LP token pool,
    /// including coins of LP tokens if it is a metapool.
    /// @param _lpToken Curve LP Token address for which pool we need to prepare a coins list
    /// @dev As we don't know the total number of coins in the case with metapool,
    /// we use a fixed-size array for a return type with a maximum number of coins in the Curve protocol (8).
    /// In the case of the metapool, we'll ignore LP Tokens and add underlying pool coins instead.
    /// @return length Total number of coins in the pool
    /// @return coinsList List of the coins of the LP Tokens pool
    function getPoolUnderlyingCoins(address _lpToken)
        public
        virtual
        view
        returns (
            uint256 length,
            address[_MAX_NUMBER_OF_COINS] memory coinsList
        )
    {
        PoolCoin[] memory currentPoolCoins = coins[_lpToken];
        uint256 i = 0;

        while(i < currentPoolCoins.length) {
            if (currentPoolCoins[i].isLPToken) {
                (uint256 nestedCoinsLen, address[_MAX_NUMBER_OF_COINS] memory nestedPoolCoins)
                    = getPoolUnderlyingCoins(currentPoolCoins[i].addr);

                uint256 j = 0;

                while(j < nestedCoinsLen) {
                    coinsList[length] = nestedPoolCoins[j];

                    // Ignoring overflow check as it is impossible
                    // to have more than 2 ** 256 - 1 coins in the storage.
                    unchecked { j++; length++; }
                }

                // Ignoring overflow check as it is impossible
                // to have more than 2 ** 256 - 1 coins in the storage.
                 unchecked { i++; }

                continue;
            }

            coinsList[length] = currentPoolCoins[i].addr;

            // Ignoring overflow check as it is impossible
            // to have more than 2 ** 256 - 1 coins in the storage.
            unchecked { i++; length++; }
        }
    }

    /// @notice Enable Curve LP token in the price provider
    /// @param _lpToken Curve LP Token address that will be enabled in the price provider
    function _setUpAssetAndEnsureItIsSupported(address _lpToken) internal {
        _setupAsset(_lpToken);
        
        // Ensure that the get price function does not revert for initialized coins
        uint256 length = coins[_lpToken].length;
        uint256 i = 0;

        while(i < length) {
            // The price providers repository should revert if the provided coin is not supported
            _priceProvidersRepository.getPrice(coins[_lpToken][i].addr);

            // Ignoring overflow check as it is impossible
            // to have more than 2 ** 256 - 1 coins in the storage.
            unchecked { i++; }
        }
    }

    /// @notice Price is denominated in the quote token
    /// @param _lpToken Curve LP Token address for which pool coins we must select prices
    /// @return prices A list of the `_lpToken` pool coins prices
    function _lpTokenPoolCoinsPrices(address _lpToken) internal view returns (uint256[] memory prices) {
        uint256 length;
        address[_MAX_NUMBER_OF_COINS] memory poolCoins;

        (length, poolCoins) = getPoolUnderlyingCoins(_lpToken);

        prices = new uint256[](length);
        uint256 i = 0;

        while(i < length) {
            prices[i] = _priceProvidersRepository.getPrice(poolCoins[i]);

            // Ignoring overflow check as it is impossible
            // to have more than 2 ** 256 - 1 coins in the storage.
            unchecked { i++; }
        }
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
pragma solidity >=0.7.6 <=0.9.0;

/// @title Math helper functions
library MathHelpers {
    /// @notice It will not support an array with `0` or `1` element.
    /// @dev Returns a minimal value from the provided array.
    /// @param _values A list of values from which will be selected a lower value
    /// @return min A lower value from the `_values` array
    function minValue(uint256[] memory _values) internal pure returns (uint256 min) {
        min = _values[0] > _values[1] ? _values[1] : _values[0];
        uint256 i = 2;

        while(i < _values.length) {
            if (min > _values[i]) {
                min = _values[i];
            }

            // Variable 'i' and '_values.length' have the same data type,
            // so due to condition (i < _values.length) overflow is impossible.
            unchecked { i++; }
        }
    }
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

interface ICurveHackyPool {
    // We do not expect to write in the store on this call.
    // Our expectation is 1 sload operation for the `lock` status check + revert.
    // Because of it this function can be view which opens a possibility to do
    // a verification in the price provider on the `getPrice` fn execution.
    //  solhint-disable func-name-mixedcase
    function remove_liquidity(uint256 _tokenAmount, uint256[2] calldata _amounts) external view;
    function remove_liquidity(uint256 _tokenAmount, uint256[3] calldata _amounts) external view;
    function remove_liquidity(uint256 _tokenAmount, uint256[4] calldata _amounts) external view;
    function remove_liquidity(uint256 _tokenAmount, uint256[5] calldata _amounts) external view;
    function remove_liquidity(uint256 _tokenAmount, uint256[6] calldata _amounts) external view;
    function remove_liquidity(uint256 _tokenAmount, uint256[7] calldata _amounts) external view;
    function remove_liquidity(uint256 _tokenAmount, uint256[8] calldata _amounts) external view;
    //  solhint-enable func-name-mixedcase
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
interface ICurvePoolLike {
    /// Description from Curve docs:
    /// @notice Returns portfolio virtual price (for calculating profit) scaled up by 1e18
    //  solhint-disable-next-line func-name-mixedcase
    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface ICurveReentrancyCheck {
    enum N_COINS { // solhint-disable-line contract-name-camelcase
        NOT_CONFIGURED,
        INVALID,
        TWO_COINS,
        THREE_COINS,
        FOUR_COINS,
        FIVE_COINS,
        SIX_COINS,
        SEVEN_COINS,
        EIGHT_COINS
    }

    /// @notice Set/Update a pool configuration for the reentrancy check
    /// @param _pool address
    /// @param _gasLimit the gas limit to be set on the check execution
    /// @param _nCoins the number of the coins in the Curve pool (N_COINS)
    function setReentrancyVerificationConfig(address _pool, uint128 _gasLimit, N_COINS _nCoins) external;
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

/// @dev PAP - pegged assets pools
abstract contract CurveLPTokensPAPBaseCache is CurveLPTokenDetailsBaseCache {
    /// @dev Revert in the case when we will try to initialize a pool with two LP Tokens
    /// as Metapools can have only one LP underlying
    error UnsupportedPoolWithTwoLPs();

    /// @notice Emitted when Curve LP token was enabled in the price provider
    /// @param pool Pool address of the Curve LP token
    /// @param token Curve LP token address that has been enabled in the price provider
    event LPTokenEnabled(address indexed pool, address indexed token);

    /// @notice Enable Curve LP token in the price provider
    /// @dev Reverts if the token is already initialized
    /// @param _lpToken Curve LP Token address that will be enabled in the price provider
    function _setupAsset(address _lpToken) internal {
        if (coins[_lpToken].length != 0) revert TokenAlreadyInitialized();

        bool result = _setUp(_lpToken);

        if (!result) revert PoolForLPTokenNotFound();
    }

    /// @notice Enable Curve LP token in the price provider
    /// @param _lpToken Curve LP Token address that will be enabled in the price provider
    /// @return `true` if `_lpToken` has been enabled in the price provider, or already
    /// has been initialized before, `false` if a pool not found for `_lpToken`.
    function _setUp(address _lpToken) internal returns (bool) {
        if (coins[_lpToken].length != 0) {
            // In the case, if `_lpToken` has already been initialized
            return true;
        }

        bytes memory data; // We'll use it as an `input` and `return` data
        LPTokenDetails memory details;

        (details, data) = _FETCHERS_REPO.getLPTokenDetails(_lpToken, data);

        if (details.pool.addr == address(0)) {
            return false;
        }

        uint256 i = 0;
        bool alreadyWithLPToken;

        while (i < details.coins.length) {
            bool isLPToken = _addCoin(_lpToken, details.coins[i], details.pool.isMeta);

            if (isLPToken && alreadyWithLPToken) revert UnsupportedPoolWithTwoLPs();

            if (!alreadyWithLPToken) {
                alreadyWithLPToken = isLPToken;
            }

            // Because of the condition `i < details.coins.length` we can ignore overflow check
            unchecked { i++; }
        }

        lpTokenPool[_lpToken] = details.pool;

        if (coins[_lpToken].length < _MIN_COINS) revert InvalidNumberOfCoinsInPool();

        emit LPTokenEnabled(lpTokenPool[_lpToken].addr, _lpToken);

        return true;
    }

    /// @notice Cache a coin in the price provider storage to avoid
    /// multiple external requests (save gas) during a price calculation.
    /// @param _lpToken Curve LP Token address
    /// @param _coin Coin from the `_lpToken` pool
    /// @param _isMetaPool `true` if the `_lpToken` pool is meta pool
    function _addCoin(address _lpToken, address _coin, bool _isMetaPool) internal returns (bool isLPToken) {
        PoolCoin memory coin = PoolCoin({
            addr: _coin,
            // If a pool is a meta pool, it can contain other Curve LP tokens.
            // We need to try to set up a coin, so we will know if the coin is an LP token or not.
            isLPToken: _isMetaPool ? _setUp(_coin) : false
        });

        // Some of the Curve pools for ether use 'Null Address' which we are not
        // able to use for the price calculation. To be able to calculate an LP Token
        // price for this kind of pools we will use wETH address instead.
        if (coin.addr == _NULL_ADDRESS) {
            coin.addr = _NATIVE_WRAPPED_ADDRESS;
        }

        coins[_lpToken].push(coin);

        isLPToken = coin.isLPToken;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "../interfaces/ICurveHackyPool.sol";
import "../interfaces/ICurveReentrancyCheck.sol";

/// @title Curve read-only reentrancy check
abstract contract CurveReentrancyCheck is ICurveReentrancyCheck {
    struct ReentrancyConfig {
        uint128 gasLimit;
        N_COINS nCoins;
    }

    /// @dev Minimal acceptable gas limit for the check
    // ~2700 - 5600 when we do a call to an invalid interface (depends on an input data size)
    // ~1800 if the pool is locked
    uint256 constant public MIN_GAS_LIMIT = 6500;

    mapping(address => ReentrancyConfig) public poolReentrancyConfig;

    /// @dev Revert if the pool reentrancy config is not configured
    error MissingPoolReentrancyConfig();
    /// @dev Revert on the invalid pool configuration
    error InvalidPoolConfiguration();
    /// @dev Pool interface validation
    error InvalidInterface();

    /// @dev Write info the log about the Curve pool reentrancy check config update
    event ReentrancyCheckConfigUpdated(address _pool, uint256 _gasLimit, N_COINS _nCoins);

    /// @notice Set/Update a pool configuration for the reentrancy check
    /// @param _pool address
    /// @param _gasLimit the gas limit to be set on the check execution
    /// @param _nCoins the number of the coins in the Curve pool (N_COINS)
    function _setReentrancyVerificationConfig(address _pool, uint128 _gasLimit, N_COINS _nCoins) internal virtual {
        if (_pool == address(0)) revert InvalidPoolConfiguration();
        if (_gasLimit < MIN_GAS_LIMIT) revert InvalidPoolConfiguration();
        if (_nCoins < N_COINS.TWO_COINS) revert InvalidPoolConfiguration();

        poolReentrancyConfig[_pool] = ReentrancyConfig({
            gasLimit: _gasLimit,
            nCoins: _nCoins
        });

        // The call to the pool with an invalid input also reverts with the gas consumption lower
        // than defined threshold. Approximately 2700 gas for an input with 3 coins and 5600 for 8.
        // We do a sanity check of the interface by checking if a pool is locked on a setup.
        // The call to the valid interface will consume more than `MIN_GAS_LIMIT`.
        if (isLocked(_pool)) revert InvalidInterface();

        emit ReentrancyCheckConfigUpdated(_pool, _gasLimit, _nCoins);
    }

    /// @notice Verifies if the `lock` is activate on the Curve pool
    // The idea is to measure the gas consumption of the `remove_liquidity` fn.
    // solhint-disable-next-line code-complexity
    function isLocked(address _pool) public virtual view returns (bool) {
        ReentrancyConfig memory config = poolReentrancyConfig[_pool];

        if (config.gasLimit == 0) revert MissingPoolReentrancyConfig();

        uint256 gasStart = gasleft();

        ICurveHackyPool pool = ICurveHackyPool(_pool);

        if (config.nCoins == N_COINS.TWO_COINS) {
            uint256[2] memory amounts;
            try pool.remove_liquidity{gas: config.gasLimit}(0, amounts) {} catch (bytes memory) {}
        } else if (config.nCoins == N_COINS.THREE_COINS) {
            uint256[3] memory amounts;
            try pool.remove_liquidity{gas: config.gasLimit}(0, amounts) {} catch (bytes memory) {}
        } if (config.nCoins == N_COINS.FOUR_COINS) {
            uint256[4] memory amounts;
            try pool.remove_liquidity{gas: config.gasLimit}(0, amounts) {} catch (bytes memory) {}
        } else if (config.nCoins == N_COINS.FIVE_COINS) {
            uint256[5] memory amounts;
            try pool.remove_liquidity{gas: config.gasLimit}(0, amounts) {} catch (bytes memory) {}
        } else if (config.nCoins == N_COINS.SIX_COINS) {
            uint256[6] memory amounts;
            try pool.remove_liquidity{gas: config.gasLimit}(0, amounts) {} catch (bytes memory) {}
        } else if (config.nCoins == N_COINS.SEVEN_COINS) {
            uint256[7] memory amounts;
            try pool.remove_liquidity{gas: config.gasLimit}(0, amounts) {} catch (bytes memory) {}
        } else if (config.nCoins == N_COINS.EIGHT_COINS) {
            uint256[8] memory amounts;
            try pool.remove_liquidity{gas: config.gasLimit}(0, amounts) {} catch (bytes memory) {}
        }

        uint256 gasSpent;
        // `gasStart` will be always > `gasleft()`
        unchecked { gasSpent = gasStart - gasleft(); }

        return gasSpent > config.gasLimit ? false /* is not locked */ : true /* locked */;
    }
}