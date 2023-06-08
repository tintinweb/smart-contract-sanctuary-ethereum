// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CurveRegistriesBaseFetcher.sol";
import "../interfaces/ICurveMainRegistryLike.sol";
import "../../../interfaces/IPriceProvidersRepository.sol";

/// @title Curve LP Tokens details fetcher for Main Registry
/// @dev Registry id `0` in the Curve address provider
contract CurveMainRegistryFetcher is CurveRegistriesBaseFetcher {
    /// @dev Number of coins by the Curve Main Registry interface
    uint256 constant internal _MAX_NUMBER_OF_COINS = 8;

    /// @dev Constructor is required for indirect CurveRegistriesBaseFetcher and
    /// PriceProvidersRepositoryManager initialization. Arguments for CurveRegistriesBaseFetcher
    /// initialization are given in the modifier-style in the derived constructor.
    /// CurveMainRegistryFetcher constructor body should be empty as we need to do nothing.
    /// @param _repository Price providers repository address
    /// @param _addressProvider Curve address provider address
    constructor(
        IPriceProvidersRepository _repository,
        ICurveAddressProviderLike _addressProvider
    )
        PriceProvidersRepositoryManager(_repository)
        CurveRegistriesBaseFetcher(_addressProvider, RegistryId.MAIN_REGISTRY_0)
    {
        // The code will not compile without it. So, we need to keep an empty constructor.
    }

    /// @inheritdoc ICurveLPTokensDetailsFetcher
    function getLPTokenDetails(
        address _lpToken,
        bytes memory
    )
        external
        virtual
        view
        returns (
            LPTokenDetails memory details,
            bytes memory data
        )
    {
        ICurveMainRegistryLike mainRegistry = ICurveMainRegistryLike(registry);
        details.pool.addr = mainRegistry.get_pool_from_lp_token(_lpToken);

        if (details.pool.addr == address(0)) {
            return (details, data);
        }

        details.pool.isMeta = mainRegistry.is_meta(details.pool.addr);

        uint256 numberOfCoins = 0;
        address[_MAX_NUMBER_OF_COINS] memory poolCoins = mainRegistry.get_coins(details.pool.addr);

        while (numberOfCoins < _MAX_NUMBER_OF_COINS) {
            if (poolCoins[numberOfCoins] == address(0)) break;

            // Because of the condition `numberOfCoins < 8` we can ignore overflow check
            unchecked { numberOfCoins++; }
        }

        details.coins = new address[](numberOfCoins);
        uint256 i = 0;

        while (i < numberOfCoins) {
            details.coins[i] = poolCoins[i];
            // Because of the condition `i < numberOfCoins` we can ignore overflow check
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
pragma solidity >=0.7.6 <0.9.0;


library Ping {
    function pong(function() external pure returns(bytes4) pingFunction) internal pure returns (bool) {
        return pingFunction.address != address(0) && pingFunction.selector == pingFunction();
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

/// @notice A simplified interface of the Curve address provider for the registry contracts.
/// @dev As curve protocol is implemented with Vyper programming language and we don't use
/// all the methods present in the Curve address provider. We'll have a solidity version
/// of the interface that includes only methods required for Silo's Curve LP Tokens price providers.
interface ICurveAddressProviderLike {
    /// Description from Curve docs:
    /// @notice Fetch the address associated with `_id`
    /// @dev Returns ZERO_ADDRESS if `_id` has not been defined, or has been unset
    /// @param _id Identifier to fetch an address for
    /// @return Current address associated to `_id`
    //  solhint-disable-next-line func-name-mixedcase
    function get_address(uint256 _id) external view returns (address);
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

/// @notice A simplified interface of the Curve Main Registry.
/// @dev As curve protocol is implemented with Vyper programming language and we don't use
/// all the methods present in the Curve address provider. We'll have a solidity version of the interface
/// that includes only methods required to retrieve LP token details as are necessary for a price calculation.
interface ICurveMainRegistryLike {
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

import "../_common/CurveLPTokensDataTypes.sol";
import "../interfaces/ICurveAddressProviderLike.sol";
import "../interfaces/ICurveLPTokensDetailsFetcher.sol";
import "../../_common/PriceProvidersRepositoryManager.sol";

/// @title Curve registries base fetcher
abstract contract CurveRegistriesBaseFetcher is PriceProvidersRepositoryManager, ICurveLPTokensDetailsFetcher {
    /// @dev The registry identifier that this fetcher is designed for
    RegistryId public immutable REGISTRY_ID; // solhint-disable-line var-name-mixedcase
    /// @dev Curve address provider
    ICurveAddressProviderLike public immutable ADDRESS_PROVIDER; // solhint-disable-line var-name-mixedcase
    /// @dev Curve registry address pulled from the Curve address provider.
    /// As Main Registry, CryptoSwap Registry, Metapool Factory, and Cryptopool Factory have different
    /// interfaces we will store registry as an address as it is a base contract that will be used for
    /// each registry and it must have a common type.
    address public registry;

    /// @dev Revert if address provider address is empty
    error EmptyAddressProvider();
    /// @dev Revert if Curve registry is not changed
    error RegistryIsTheSame();
    /// @dev Revert if in the Curve address provider the registry is not found by the provided registry id
    error RegistryNotFoundById(RegistryId id);

    /// @dev Emitted on creation
    /// @param curveAddressProvider The Curve address provider for a data fetcher
    /// @param registryId The Curve registry identifier in the Curve address provider for a data fetcher
    event DataFetcherCreated(ICurveAddressProviderLike curveAddressProvider, RegistryId registryId);

    /// @dev Curve address provider contract address is immutable and it’s address will never change.
    /// We do it configurable to make a code compliant with different networks in the case if 
    /// address will differs for them.
    /// @param _curveAddressProvider Curve address provider
    /// @param _id Curve registry identifier. See CurveLPTokensDataTypes.RegistryId
    constructor(ICurveAddressProviderLike _curveAddressProvider, RegistryId _id) {
        if (address(_curveAddressProvider) == address(0)) revert EmptyAddressProvider();

        REGISTRY_ID = _id;
        ADDRESS_PROVIDER = _curveAddressProvider;

        _updateRegistry();

        emit DataFetcherCreated(ADDRESS_PROVIDER, REGISTRY_ID);
    }

    /// @inheritdoc ICurveLPTokensDetailsFetcher
    function updateRegistry() external virtual onlyManager() {
        _updateRegistry();
    }

    /// @inheritdoc ICurveLPTokensDetailsFetcher
    function curveLPTokensDetailsFetcherPing() external virtual pure returns (bytes4) {
        return this.curveLPTokensDetailsFetcherPing.selector;
    }

    /// @notice Updates a registry address from the Curve address provider
    /// @dev Reverts if an address is not found or is the same as current address
    function _updateRegistry() internal {
        address newRegistry = ADDRESS_PROVIDER.get_address(uint256(REGISTRY_ID));

        if (newRegistry == address(0)) revert RegistryNotFoundById(REGISTRY_ID);
        if (registry == newRegistry) revert RegistryIsTheSame();

        registry = newRegistry;

        emit RegistryUpdated(newRegistry);
    }
}