// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/ICurveLPTokensDetailsFetchersRepository.sol";
import "../../_common/PriceProvidersRepositoryManager.sol";
import "../../../lib/Ping.sol";
import "../../../interfaces/IPriceProvidersRepository.sol";

/// @title Curve LP Tokens details fetchers repository
/// @dev For more info about Curve LP Tokens details fetchers see ICurveLPTokensDetailsFetcher
contract CurveLPTokensDetailsFetchersRepository is
    ICurveLPTokensDetailsFetchersRepository,
    PriceProvidersRepositoryManager
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Curve LP Tokens details fetchers set
    EnumerableSet.AddressSet internal _fetchers;

    /// @dev Revert if Curve LP Tokens details fetcher is already added to the set
    error FetcherAlreadyAdded();
    /// @dev Revert if Curve LP Tokens details fetcher is not registered in the repository
    error FetcherIsNotRegistered();
    /// @dev Revert on a false sanity check with `Ping` library for a fetcher
    error InvalidFetcher();

    /// @dev Constructor is required for indirect PriceProvidersRepositoryManager initialization.
    /// Arguments for PriceProvidersRepositoryManager initialization are given in the modifier-style
    /// in the derived constructor.
    /// CurveLPTokensDetailsFetchersRepository constructor body should be empty as we need to do nothing.
    /// @param _repository Price providers repository address
    constructor(IPriceProvidersRepository _repository) PriceProvidersRepositoryManager(_repository) {
        // The code will not compile without it. So, we need to keep an empty constructor.
    }

    /// @inheritdoc ICurveLPTokensDetailsFetchersRepository
    function addFetcher(ICurveLPTokensDetailsFetcher _fetcher) external virtual onlyManager() {
        if (!Ping.pong(_fetcher.curveLPTokensDetailsFetcherPing)) revert InvalidFetcher();
        if (!_fetchers.add(address(_fetcher))) revert FetcherAlreadyAdded();

        emit FetcherAdded(_fetcher);
    }

    /// @inheritdoc ICurveLPTokensDetailsFetchersRepository
    function removeFetcher(ICurveLPTokensDetailsFetcher _fetcher) external virtual onlyManager() {
        if (!_fetchers.remove(address(_fetcher))) revert FetcherIsNotRegistered();

        emit FetcherRemoved(_fetcher);
    }

    /// @inheritdoc ICurveLPTokensDetailsFetchersRepository
    function getLPTokenDetails(
        address _lpToken,
        bytes memory _data
    )
        external
        virtual
        view
        returns (
            LPTokenDetails memory details,
            bytes memory data
        )
    {
        uint256 i = 0;
        uint256 numberOfFetchers = _fetchers.length();

        while(i < numberOfFetchers) {
            ICurveLPTokensDetailsFetcher fetcher = ICurveLPTokensDetailsFetcher(_fetchers.at(i));

            (details, data) = fetcher.getLPTokenDetails(_lpToken, _data);

            // Assume that if a pool address is not address(0), we are done
            if (details.pool.addr != address(0)) {
                return (details, data);
            }

            // variables 'i' and 'numberOfFetchers' have the same data type,
            // so due to condition (i < numberOfFetchers) overflow is impossible.
            unchecked { i++; }
        }
    }

    /// @return pool of the `_lpToken`
    function getLPTokenPool(address _lpToken) external view returns (address pool) {
        uint256 i = 0;
        bytes memory data;
        LPTokenDetails memory details;
        uint256 numberOfFetchers = _fetchers.length();

        while(i < numberOfFetchers) {
            ICurveLPTokensDetailsFetcher fetcher = ICurveLPTokensDetailsFetcher(_fetchers.at(i));

            (details, data) = fetcher.getLPTokenDetails(_lpToken, data);

            // Assume that if a pool address is not address(0), we are done
            if (details.pool.addr != address(0)) {
                return details.pool.addr;
            }

            // variables 'i' and 'numberOfFetchers' have the same data type,
            // so due to condition (i < numberOfFetchers) overflow is impossible.
            unchecked { i++; }
        }
    }

    /// @inheritdoc ICurveLPTokensDetailsFetchersRepository
    function getFetchers() external virtual view returns (address[] memory) {
        return _fetchers.values();
    }

    /// @inheritdoc ICurveLPTokensDetailsFetchersRepository
    function curveLPTokensFetchersRepositoryPing() external virtual pure returns (bytes4) {
        return this.curveLPTokensFetchersRepositoryPing.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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