// SPDX-License-Identifier: MIT
// Chainlink Contracts v0.8
pragma solidity ^0.8.10;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {AggregatorInterface} from "../dependencies/chainlink/AggregatorInterface.sol";
import {Errors} from "../protocol/libraries/helpers/Errors.sol";
import {IACLManager} from "../interfaces/IACLManager.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IParaSpaceOracle} from "../interfaces/IParaSpaceOracle.sol";

/**
 * @title ParaSpaceOracle
 *
 * @notice Contract to get asset prices, manage price sources and update the fallback oracle
 * - Use of Chainlink Aggregators as first source of price
 * - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallback oracle
 * - Owned by the ParaSpace governance
 */
contract ParaSpaceOracle is IParaSpaceOracle {
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    // Map of asset price sources (asset => priceSource)
    mapping(address => AggregatorInterface) private assetsSources;

    IPriceOracleGetter private _fallbackOracle;
    address public immutable override BASE_CURRENCY;
    uint256 public immutable override BASE_CURRENCY_UNIT;

    /**
     * @dev Only asset listing or pool admin can call functions marked by this modifier.
     **/
    modifier onlyAssetListingOrPoolAdmins() {
        _onlyAssetListingOrPoolAdmins();
        _;
    }

    /**
     * @notice Constructor
     * @param provider The address of the new PoolAddressesProvider
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     * @param fallbackOracle The address of the fallback oracle to use if the data of an
     *        aggregator is not consistent
     * @param baseCurrency The base currency used for the price quotes. If USD is used, base currency is 0x0
     * @param baseCurrencyUnit The unit of the base currency
     */
    constructor(
        IPoolAddressesProvider provider,
        address[] memory assets,
        address[] memory sources,
        address fallbackOracle,
        address baseCurrency,
        uint256 baseCurrencyUnit
    ) {
        ADDRESSES_PROVIDER = provider;
        _setFallbackOracle(fallbackOracle);
        _setAssetsSources(assets, sources);
        BASE_CURRENCY = baseCurrency;
        BASE_CURRENCY_UNIT = baseCurrencyUnit;
        emit BaseCurrencySet(baseCurrency, baseCurrencyUnit);
    }

    /// @inheritdoc IParaSpaceOracle
    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external override onlyAssetListingOrPoolAdmins {
        _setAssetsSources(assets, sources);
    }

    /// @inheritdoc IParaSpaceOracle
    function setFallbackOracle(address fallbackOracle)
        external
        override
        onlyAssetListingOrPoolAdmins
    {
        _setFallbackOracle(fallbackOracle);
    }

    /**
     * @notice Internal function to set the sources for each asset
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     */
    function _setAssetsSources(
        address[] memory assets,
        address[] memory sources
    ) internal {
        require(
            assets.length == sources.length,
            Errors.INCONSISTENT_PARAMS_LENGTH
        );
        for (uint256 i = 0; i < assets.length; i++) {
            assetsSources[assets[i]] = AggregatorInterface(sources[i]);
            emit AssetSourceUpdated(assets[i], sources[i]);
        }
    }

    /**
     * @notice Internal function to set the fallback oracle
     * @param fallbackOracle The address of the fallback oracle
     */
    function _setFallbackOracle(address fallbackOracle) internal {
        _fallbackOracle = IPriceOracleGetter(fallbackOracle);
        emit FallbackOracleUpdated(fallbackOracle);
    }

    /// @inheritdoc IPriceOracleGetter
    function getAssetPrice(address asset)
        public
        view
        override
        returns (uint256)
    {
        AggregatorInterface source = assetsSources[asset];

        if (asset == BASE_CURRENCY) {
            return BASE_CURRENCY_UNIT;
        } else if (address(source) == address(0)) {
            return _fallbackOracle.getAssetPrice(asset);
        } else {
            int256 price = source.latestAnswer();
            if (price > 0) {
                return uint256(price);
            } else {
                return _fallbackOracle.getAssetPrice(asset);
            }
        }
    }

    /// @inheritdoc IParaSpaceOracle
    function getAssetsPrices(address[] calldata assets)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }

    /// @inheritdoc IParaSpaceOracle
    function getSourceOfAsset(address asset)
        external
        view
        override
        returns (address)
    {
        return address(assetsSources[asset]);
    }

    /// @inheritdoc IParaSpaceOracle
    function getFallbackOracle() external view returns (address) {
        return address(_fallbackOracle);
    }

    function _onlyAssetListingOrPoolAdmins() internal view {
        IACLManager aclManager = IACLManager(
            ADDRESSES_PROVIDER.getACLManager()
        );
        require(
            aclManager.isAssetListingAdmin(msg.sender) ||
                aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title Errors library
 *
 * @notice Defines the error messages emitted by the different contracts of the ParaSpace protocol
 */
library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "1"; // 'The caller of the function is not a pool admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "2"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = "3"; // 'The caller of the function is not a pool or emergency admin'
    string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = "4"; // 'The caller of the function is not a risk or pool admin'
    string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = "5"; // 'The caller of the function is not an asset listing or pool admin'
    string public constant CALLER_NOT_BRIDGE = "6"; // 'The caller of the function is not a bridge'
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "7"; // 'Pool addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "8"; // 'Invalid id for the pool addresses provider'
    string public constant NOT_CONTRACT = "9"; // 'Address is not a contract'
    string public constant CALLER_NOT_POOL_CONFIGURATOR = "10"; // 'The caller of the function is not the pool configurator'
    string public constant CALLER_NOT_XTOKEN = "11"; // 'The caller of the function is not an PToken'
    string public constant INVALID_ADDRESSES_PROVIDER = "12"; // 'The address of the pool addresses provider is invalid'
    string public constant RESERVE_ALREADY_ADDED = "14"; // 'Reserve has already been added to reserve list'
    string public constant NO_MORE_RESERVES_ALLOWED = "15"; // 'Maximum amount of reserves in the pool reached'
    string public constant RESERVE_LIQUIDITY_NOT_ZERO = "18"; // 'The liquidity of the reserve needs to be 0'
    string public constant INVALID_RESERVE_PARAMS = "20"; // 'Invalid risk parameters for the reserve'
    string public constant CALLER_MUST_BE_POOL = "23"; // 'The caller of this function must be a pool'
    string public constant INVALID_MINT_AMOUNT = "24"; // 'Invalid amount to mint'
    string public constant INVALID_BURN_AMOUNT = "25"; // 'Invalid amount to burn'
    string public constant INVALID_AMOUNT = "26"; // 'Amount must be greater than 0'
    string public constant RESERVE_INACTIVE = "27"; // 'Action requires an active reserve'
    string public constant RESERVE_FROZEN = "28"; // 'Action cannot be performed because the reserve is frozen'
    string public constant RESERVE_PAUSED = "29"; // 'Action cannot be performed because the reserve is paused'
    string public constant BORROWING_NOT_ENABLED = "30"; // 'Borrowing is not enabled'
    string public constant STABLE_BORROWING_NOT_ENABLED = "31"; // 'Stable borrowing is not enabled'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "32"; // 'User cannot withdraw more than the available balance'
    string public constant INVALID_INTEREST_RATE_MODE_SELECTED = "33"; // 'Invalid interest rate mode selected'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "34"; // 'The collateral balance is 0'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "35"; // 'Health factor is lesser than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "36"; // 'There is not enough collateral to cover a new borrow'
    string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = "37"; // 'Collateral is (mostly) the same currency that is being borrowed'
    string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "38"; // 'The requested amount is greater than the max loan size in stable rate mode'
    string public constant NO_DEBT_OF_SELECTED_TYPE = "39"; // 'For repayment of a specific type of debt, the user needs to have debt that type'
    string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "40"; // 'To repay on behalf of a user an explicit amount to repay is needed'
    string public constant NO_OUTSTANDING_STABLE_DEBT = "41"; // 'User does not have outstanding stable rate debt on this reserve'
    string public constant NO_OUTSTANDING_VARIABLE_DEBT = "42"; // 'User does not have outstanding variable rate debt on this reserve'
    string public constant UNDERLYING_BALANCE_ZERO = "43"; // 'The underlying balance needs to be greater than 0'
    string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "44"; // 'Interest rate rebalance conditions were not met'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "45"; // 'Health factor is not below the threshold'
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "46"; // 'The collateral chosen cannot be liquidated'
    string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "47"; // 'User did not borrow the specified currency'
    string public constant SAME_BLOCK_BORROW_REPAY = "48"; // 'Borrow and repay in same block is not allowed'
    string public constant BORROW_CAP_EXCEEDED = "50"; // 'Borrow cap is exceeded'
    string public constant SUPPLY_CAP_EXCEEDED = "51"; // 'Supply cap is exceeded'
    string public constant XTOKEN_SUPPLY_NOT_ZERO = "54"; // 'PToken supply is not zero'
    string public constant STABLE_DEBT_NOT_ZERO = "55"; // 'Stable debt supply is not zero'
    string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = "56"; // 'Variable debt supply is not zero'
    string public constant LTV_VALIDATION_FAILED = "57"; // 'Ltv validation failed'
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "59"; // 'Price oracle sentinel validation failed'
    string public constant RESERVE_ALREADY_INITIALIZED = "61"; // 'Reserve has already been initialized'
    string public constant INVALID_LTV = "63"; // 'Invalid ltv parameter for the reserve'
    string public constant INVALID_LIQ_THRESHOLD = "64"; // 'Invalid liquidity threshold parameter for the reserve'
    string public constant INVALID_LIQ_BONUS = "65"; // 'Invalid liquidity bonus parameter for the reserve'
    string public constant INVALID_DECIMALS = "66"; // 'Invalid decimals parameter of the underlying asset of the reserve'
    string public constant INVALID_RESERVE_FACTOR = "67"; // 'Invalid reserve factor parameter for the reserve'
    string public constant INVALID_BORROW_CAP = "68"; // 'Invalid borrow cap for the reserve'
    string public constant INVALID_SUPPLY_CAP = "69"; // 'Invalid supply cap for the reserve'
    string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = "70"; // 'Invalid liquidation protocol fee for the reserve'
    string public constant INVALID_DEBT_CEILING = "73"; // 'Invalid debt ceiling for the reserve
    string public constant INVALID_RESERVE_INDEX = "74"; // 'Invalid reserve index'
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "75"; // 'ACL admin cannot be set to the zero address'
    string public constant INCONSISTENT_PARAMS_LENGTH = "76"; // 'Array parameters that should be equal length are not'
    string public constant ZERO_ADDRESS_NOT_VALID = "77"; // 'Zero address not valid'
    string public constant INVALID_EXPIRATION = "78"; // 'Invalid expiration'
    string public constant INVALID_SIGNATURE = "79"; // 'Invalid signature'
    string public constant OPERATION_NOT_SUPPORTED = "80"; // 'Operation not supported'
    string public constant ASSET_NOT_LISTED = "82"; // 'Asset is not listed'
    string public constant INVALID_OPTIMAL_USAGE_RATIO = "83"; // 'Invalid optimal usage ratio'
    string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = "84"; // 'Invalid optimal stable to total debt ratio'
    string public constant UNDERLYING_CANNOT_BE_RESCUED = "85"; // 'The underlying asset cannot be rescued'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "86"; // 'Reserve has already been added to reserve list'
    string public constant POOL_ADDRESSES_DO_NOT_MATCH = "87"; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
    string public constant STABLE_BORROWING_ENABLED = "88"; // 'Stable borrowing is enabled'
    string public constant SILOED_BORROWING_VIOLATION = "89"; // 'User is trying to borrow multiple assets including a siloed one'
    string public constant RESERVE_DEBT_NOT_ZERO = "90"; // the total debt of the reserve needs to be 0
    string public constant NOT_THE_OWNER = "91"; // user is not the owner of a given asset
    string public constant LIQUIDATION_AMOUNT_NOT_ENOUGH = "92";
    string public constant INVALID_ASSET_TYPE = "93"; // invalid asset type for action.
    string public constant INVALID_FLASH_CLAIM_RECEIVER = "94"; // invalid flash claim receiver.
    string public constant ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "95"; // 'ERC721 Health factor is not below the threshold. Can only liquidate ERC20'
    string public constant UNDERLYING_ASSET_CAN_NOT_BE_TRANSFERRED = "96"; //underlying asset can not be transferred.
    string public constant TOKEN_TRANSFERRED_CAN_NOT_BE_SELF_ADDRESS = "97"; //token transferred can not be self address.
    string public constant INVALID_AIRDROP_CONTRACT_ADDRESS = "98"; //invalid airdrop contract address.
    string public constant INVALID_AIRDROP_PARAMETERS = "99"; //invalid airdrop parameters.
    string public constant CALL_AIRDROP_METHOD_FAILED = "100"; //call airdrop method failed.
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IACLManager
 *
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
    /**
     * @notice Returns the contract address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Returns the identifier of the PoolAdmin role
     * @return The id of the PoolAdmin role
     */
    function POOL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the RiskAdmin role
     * @return The id of the RiskAdmin role
     */
    function RISK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the FlashBorrower role
     * @return The id of the FlashBorrower role
     */
    function FLASH_BORROWER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the Bridge role
     * @return The id of the Bridge role
     */
    function BRIDGE_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the AssetListingAdmin role
     * @return The id of the AssetListingAdmin role
     */
    function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as PoolAdmin
     * @param admin The address of the new admin
     */
    function addPoolAdmin(address admin) external;

    /**
     * @notice Removes an admin as PoolAdmin
     * @param admin The address of the admin to remove
     */
    function removePoolAdmin(address admin) external;

    /**
     * @notice Returns true if the address is PoolAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is PoolAdmin, false otherwise
     */
    function isPoolAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as RiskAdmin
     * @param admin The address of the new admin
     */
    function addRiskAdmin(address admin) external;

    /**
     * @notice Removes an admin as RiskAdmin
     * @param admin The address of the admin to remove
     */
    function removeRiskAdmin(address admin) external;

    /**
     * @notice Returns true if the address is RiskAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is RiskAdmin, false otherwise
     */
    function isRiskAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new address as FlashBorrower
     * @param borrower The address of the new FlashBorrower
     */
    function addFlashBorrower(address borrower) external;

    /**
     * @notice Removes an admin as FlashBorrower
     * @param borrower The address of the FlashBorrower to remove
     */
    function removeFlashBorrower(address borrower) external;

    /**
     * @notice Returns true if the address is FlashBorrower, false otherwise
     * @param borrower The address to check
     * @return True if the given address is FlashBorrower, false otherwise
     */
    function isFlashBorrower(address borrower) external view returns (bool);

    /**
     * @notice Adds a new address as Bridge
     * @param bridge The address of the new Bridge
     */
    function addBridge(address bridge) external;

    /**
     * @notice Removes an address as Bridge
     * @param bridge The address of the bridge to remove
     */
    function removeBridge(address bridge) external;

    /**
     * @notice Returns true if the address is Bridge, false otherwise
     * @param bridge The address to check
     * @return True if the given address is Bridge, false otherwise
     */
    function isBridge(address bridge) external view returns (bool);

    /**
     * @notice Adds a new admin as AssetListingAdmin
     * @param admin The address of the new admin
     */
    function addAssetListingAdmin(address admin) external;

    /**
     * @notice Removes an admin as AssetListingAdmin
     * @param admin The address of the admin to remove
     */
    function removeAssetListingAdmin(address admin) external;

    /**
     * @notice Returns true if the address is AssetListingAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is AssetListingAdmin, false otherwise
     */
    function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IPoolAddressesProvider
 *
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param oldAddress The old address of the Pool
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param oldAddress The old address of the PoolConfigurator
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed implementationAddress
    );

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param oldImplementationAddress The address of the old implementation contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice Returns the id of the ParaSpace market to which this contract points to.
     * @return The market id
     **/
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple ParaSpace markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress)
        external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     **/
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     **/
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     **/
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     **/
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     **/
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     **/
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     **/
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IPriceOracleGetter
 *
 * @notice Interface for the ParaSpace price oracle.
 **/
interface IPriceOracleGetter {
    /**
     * @notice Returns the base currency address
     * @dev Address 0x0 is reserved for USD as base currency.
     * @return Returns the base currency address.
     **/
    function BASE_CURRENCY() external view returns (address);

    /**
     * @notice Returns the base currency unit
     * @dev 1 ether for ETH, 1e8 for USD.
     * @return Returns the base currency unit.
     **/
    function BASE_CURRENCY_UNIT() external view returns (uint256);

    /**
     * @notice Returns the asset price in the base currency
     * @param asset The address of the asset
     * @return The price of the asset
     **/
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPriceOracleGetter} from "./IPriceOracleGetter.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IParaSpaceOracle
 *
 * @notice Defines the basic interface for the ParaSpace Oracle
 */
interface IParaSpaceOracle is IPriceOracleGetter {
    /**
     * @dev Emitted after the base currency is set
     * @param baseCurrency The base currency of used for price quotes
     * @param baseCurrencyUnit The unit of the base currency
     */
    event BaseCurrencySet(
        address indexed baseCurrency,
        uint256 baseCurrencyUnit
    );

    /**
     * @dev Emitted after the price source of an asset is updated
     * @param asset The address of the asset
     * @param source The price source of the asset
     */
    event AssetSourceUpdated(address indexed asset, address indexed source);

    /**
     * @dev Emitted after the address of fallback oracle is updated
     * @param fallbackOracle The address of the fallback oracle
     */
    event FallbackOracleUpdated(address indexed fallbackOracle);

    /**
     * @notice Returns the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Sets or replaces price sources of assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external;

    /**
     * @notice Sets the fallback oracle
     * @param fallbackOracle The address of the fallback oracle
     */
    function setFallbackOracle(address fallbackOracle) external;

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param assets The list of assets addresses
     * @return The prices of the given assets
     */
    function getAssetsPrices(address[] calldata assets)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Returns the address of the source for an asset address
     * @param asset The address of the asset
     * @return The address of the source
     */
    function getSourceOfAsset(address asset) external view returns (address);

    /**
     * @notice Returns the address of the fallback oracle
     * @return The address of the fallback oracle
     */
    function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IERC721Metadata} from "../dependencies/openzeppelin/contracts/IERC721Metadata.sol";
import {IERC721} from "../dependencies/openzeppelin/contracts/IERC721.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IUiPoolDataProvider} from "./interfaces/IUiPoolDataProvider.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IParaSpaceOracle} from "../interfaces/IParaSpaceOracle.sol";
import {IPToken} from "../interfaces/IPToken.sol";
import {ICollaterizableERC721} from "../interfaces/ICollaterizableERC721.sol";
import {INToken} from "../interfaces/INToken.sol";
import {IVariableDebtToken} from "../interfaces/IVariableDebtToken.sol";
import {IStableDebtToken} from "../interfaces/IStableDebtToken.sol";
import {WadRayMath} from "../protocol/libraries/math/WadRayMath.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {DefaultReserveInterestRateStrategy} from "../protocol/pool/DefaultReserveInterestRateStrategy.sol";
import {IEACAggregatorProxy} from "./interfaces/IEACAggregatorProxy.sol";
import {IERC20DetailedBytes} from "./interfaces/IERC20DetailedBytes.sol";
import {ProtocolDataProvider} from "../misc/ProtocolDataProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

contract UiPoolDataProvider is IUiPoolDataProvider {
    using WadRayMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IEACAggregatorProxy
        public immutable networkBaseTokenPriceInUsdProxyAggregator;
    IEACAggregatorProxy
        public immutable marketReferenceCurrencyPriceInUsdProxyAggregator;
    uint256 public constant ETH_CURRENCY_UNIT = 1 ether;
    address public constant MKR_ADDRESS =
        0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

    constructor(
        IEACAggregatorProxy _networkBaseTokenPriceInUsdProxyAggregator,
        IEACAggregatorProxy _marketReferenceCurrencyPriceInUsdProxyAggregator
    ) {
        networkBaseTokenPriceInUsdProxyAggregator = _networkBaseTokenPriceInUsdProxyAggregator;
        marketReferenceCurrencyPriceInUsdProxyAggregator = _marketReferenceCurrencyPriceInUsdProxyAggregator;
    }

    function getInterestRateStrategySlopes(
        DefaultReserveInterestRateStrategy interestRateStrategy
    ) internal view returns (InterestRates memory) {
        InterestRates memory interestRates;
        interestRates.variableRateSlope1 = interestRateStrategy
            .getVariableRateSlope1();
        interestRates.variableRateSlope2 = interestRateStrategy
            .getVariableRateSlope2();
        interestRates.stableRateSlope1 = interestRateStrategy
            .getStableRateSlope1();
        interestRates.stableRateSlope2 = interestRateStrategy
            .getStableRateSlope2();
        interestRates.baseStableBorrowRate = interestRateStrategy
            .getBaseStableBorrowRate();
        interestRates.baseVariableBorrowRate = interestRateStrategy
            .getBaseVariableBorrowRate();
        interestRates.optimalUsageRatio = interestRateStrategy
            .OPTIMAL_USAGE_RATIO();

        return interestRates;
    }

    function getReservesList(IPoolAddressesProvider provider)
        public
        view
        override
        returns (address[] memory)
    {
        IPool pool = IPool(provider.getPool());
        return pool.getReservesList();
    }

    function getReservesData(IPoolAddressesProvider provider)
        public
        view
        override
        returns (AggregatedReserveData[] memory, BaseCurrencyInfo memory)
    {
        IParaSpaceOracle oracle = IParaSpaceOracle(provider.getPriceOracle());
        IPool pool = IPool(provider.getPool());
        ProtocolDataProvider poolDataProvider = ProtocolDataProvider(
            provider.getPoolDataProvider()
        );

        address[] memory reserves = pool.getReservesList();
        AggregatedReserveData[]
            memory reservesData = new AggregatedReserveData[](reserves.length);

        for (uint256 i = 0; i < reserves.length; i++) {
            AggregatedReserveData memory reserveData = reservesData[i];
            reserveData.underlyingAsset = reserves[i];

            // reserve current state
            DataTypes.ReserveData memory baseData = pool.getReserveData(
                reserveData.underlyingAsset
            );
            //the liquidity index. Expressed in ray
            reserveData.liquidityIndex = baseData.liquidityIndex;
            //variable borrow index. Expressed in ray
            reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
            //the current supply rate. Expressed in ray
            reserveData.liquidityRate = baseData.currentLiquidityRate;
            //the current variable borrow rate. Expressed in ray
            reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
            //the current stable borrow rate. Expressed in ray
            reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
            reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
            reserveData.xTokenAddress = baseData.xTokenAddress;
            reserveData.stableDebtTokenAddress = baseData
                .stableDebtTokenAddress;
            reserveData.variableDebtTokenAddress = baseData
                .variableDebtTokenAddress;
            //address of the interest rate strategy
            reserveData.interestRateStrategyAddress = baseData
                .interestRateStrategyAddress;
            reserveData.priceInMarketReferenceCurrency = oracle.getAssetPrice(
                reserveData.underlyingAsset
            );
            // reserveData.priceOracle = oracle.getSourceOfAsset(
            //     reserveData.underlyingAsset
            // );

            (
                reserveData.totalPrincipalStableDebt,
                ,
                reserveData.averageStableRate,
                reserveData.stableDebtLastUpdateTimestamp
            ) = IStableDebtToken(reserveData.stableDebtTokenAddress)
                .getSupplyData();
            reserveData.totalScaledVariableDebt = IVariableDebtToken(
                reserveData.variableDebtTokenAddress
            ).scaledTotalSupply();
            reserveData.assetType = baseData.assetType;

            if (baseData.assetType == DataTypes.AssetType.ERC20) {
                // Due we take the symbol from underlying token we need a special case for $MKR as symbol() returns bytes32
                if (
                    address(reserveData.underlyingAsset) == address(MKR_ADDRESS)
                ) {
                    bytes32 symbol = IERC20DetailedBytes(
                        reserveData.underlyingAsset
                    ).symbol();
                    reserveData.symbol = bytes32ToString(symbol);
                } else {
                    reserveData.symbol = IERC20Detailed(
                        reserveData.underlyingAsset
                    ).symbol();
                }

                reserveData.availableLiquidity = IERC20Detailed(
                    reserveData.underlyingAsset
                ).balanceOf(reserveData.xTokenAddress);
            } else {
                reserveData.symbol = IERC721Metadata(
                    reserveData.underlyingAsset
                ).symbol();

                reserveData.availableLiquidity = IERC721(
                    reserveData.underlyingAsset
                ).balanceOf(reserveData.xTokenAddress);
            }

            DataTypes.ReserveConfigurationMap
                memory reserveConfigurationMap = baseData.configuration;
            //uint256 eModeCategoryId;
            (
                reserveData.baseLTVasCollateral,
                reserveData.reserveLiquidationThreshold,
                reserveData.reserveLiquidationBonus,
                reserveData.decimals,
                reserveData.reserveFactor
                // eModeCategoryId
            ) = reserveConfigurationMap.getParams();
            reserveData.usageAsCollateralEnabled =
                reserveData.baseLTVasCollateral != 0;

            bool isPaused;
            (
                reserveData.isActive,
                reserveData.isFrozen,
                reserveData.borrowingEnabled,
                reserveData.stableBorrowRateEnabled,
                isPaused
            ) = reserveConfigurationMap.getFlags();

            InterestRates memory interestRates = getInterestRateStrategySlopes(
                DefaultReserveInterestRateStrategy(
                    reserveData.interestRateStrategyAddress
                )
            );

            reserveData.variableRateSlope1 = interestRates.variableRateSlope1;
            reserveData.variableRateSlope2 = interestRates.variableRateSlope2;
            reserveData.stableRateSlope1 = interestRates.stableRateSlope1;
            reserveData.stableRateSlope2 = interestRates.stableRateSlope2;
            reserveData.baseStableBorrowRate = interestRates
                .baseStableBorrowRate;
            reserveData.baseVariableBorrowRate = interestRates
                .baseVariableBorrowRate;
            reserveData.optimalUsageRatio = interestRates.optimalUsageRatio;

            // v3 only
            reserveData.eModeCategoryId = 0;
            // reserveData.debtCeiling = reserveConfigurationMap.getDebtCeiling();
            // reserveData.debtCeilingDecimals = poolDataProvider
            //     .getDebtCeilingDecimals();
            (
                reserveData.borrowCap,
                reserveData.supplyCap
            ) = reserveConfigurationMap.getCaps();

            reserveData.isPaused = isPaused;
            reserveData.unbacked = 0;
            reserveData.isolationModeTotalDebt = 0;
            reserveData.accruedToTreasury = baseData.accruedToTreasury;

            //DataTypes.EModeCategory memory categoryData = pool.getEModeCategoryData(reserveData.eModeCategoryId);
            reserveData.eModeLtv = 0;
            reserveData.eModeLiquidationThreshold = 0;
            reserveData.eModeLiquidationBonus = 0;
            // each eMode category may or may not have a custom oracle to override the individual assets price oracles
            reserveData.eModePriceSource = address(0);
            reserveData.eModeLabel = "";

            reserveData.borrowableInIsolation = false; // reserveConfigurationMap.getBorrowableInIsolation();
        }

        BaseCurrencyInfo memory baseCurrencyInfo;
        baseCurrencyInfo
            .networkBaseTokenPriceInUsd = networkBaseTokenPriceInUsdProxyAggregator
            .latestAnswer();
        baseCurrencyInfo
            .networkBaseTokenPriceDecimals = networkBaseTokenPriceInUsdProxyAggregator
            .decimals();

        try oracle.BASE_CURRENCY_UNIT() returns (uint256 baseCurrencyUnit) {
            baseCurrencyInfo.marketReferenceCurrencyUnit = baseCurrencyUnit;
            baseCurrencyInfo.marketReferenceCurrencyPriceInUsd = int256(
                baseCurrencyUnit
            );
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            baseCurrencyInfo.marketReferenceCurrencyUnit = ETH_CURRENCY_UNIT;
            baseCurrencyInfo
                .marketReferenceCurrencyPriceInUsd = marketReferenceCurrencyPriceInUsdProxyAggregator
                .latestAnswer();
        }

        return (reservesData, baseCurrencyInfo);
    }

    function getNTokenData(
        address user,
        address[] memory nTokenAddresses,
        uint256[][] memory tokenIds
    ) external view override returns (DataTypes.ERC721SupplyParams[][] memory) {
        uint256[] memory userBalances = new uint256[](nTokenAddresses.length);

        uint256 tokenDataSize;

        DataTypes.ERC721SupplyParams[][]
            memory tokenData = new DataTypes.ERC721SupplyParams[][](
                nTokenAddresses.length
            );

        for (uint256 i = 0; i < nTokenAddresses.length; i++) {
            address asset = nTokenAddresses[i];
            uint256 userTotalBalance = INToken(asset).balanceOf(user);
            tokenData[i] = new DataTypes.ERC721SupplyParams[](userTotalBalance);

            for (uint256 j = 0; j < userTotalBalance; j++) {
                tokenData[i][j].tokenId = tokenIds[i][j];
                tokenData[i][j].useAsCollateral = ICollaterizableERC721(asset)
                    .isUsedAsCollateral(tokenIds[i][j]);
            }
        }

        return (tokenData);
    }

    function getUserReservesData(IPoolAddressesProvider provider, address user)
        external
        view
        override
        returns (UserReserveData[] memory, uint8)
    {
        IPool pool = IPool(provider.getPool());
        address[] memory reserves = pool.getReservesList();
        DataTypes.UserConfigurationMap memory userConfig = pool
            .getUserConfiguration(user);

        uint8 userEmodeCategoryId = 0;

        UserReserveData[] memory userReservesData = new UserReserveData[](
            user != address(0) ? reserves.length : 0
        );

        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory baseData = pool.getReserveData(
                reserves[i]
            );

            // user reserve data
            userReservesData[i].underlyingAsset = reserves[i];
            if (baseData.assetType == DataTypes.AssetType.ERC20) {
                userReservesData[i].scaledXTokenBalance = IPToken(
                    baseData.xTokenAddress
                ).scaledBalanceOf(user);
            } else {
                userReservesData[i].scaledXTokenBalance = INToken(
                    baseData.xTokenAddress
                ).balanceOf(user);
                userReservesData[i].collaterizedBalance = ICollaterizableERC721(
                    baseData.xTokenAddress
                ).collaterizedBalanceOf(user);
            }

            userReservesData[i].usageAsCollateralEnabledOnUser = userConfig
                .isUsingAsCollateral(i);

            if (userConfig.isBorrowing(i)) {
                userReservesData[i].scaledVariableDebt = IVariableDebtToken(
                    baseData.variableDebtTokenAddress
                ).scaledBalanceOf(user);
                userReservesData[i].principalStableDebt = IStableDebtToken(
                    baseData.stableDebtTokenAddress
                ).principalBalanceOf(user);
                if (userReservesData[i].principalStableDebt != 0) {
                    userReservesData[i].stableBorrowRate = IStableDebtToken(
                        baseData.stableDebtTokenAddress
                    ).getUserStableRate(user);
                    userReservesData[i]
                        .stableBorrowLastUpdateTimestamp = IStableDebtToken(
                        baseData.stableDebtTokenAddress
                    ).getUserLastUpdated(user);
                }
            }
        }

        return (userReservesData, userEmodeCategoryId);
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IERC20} from "./IERC20.sol";

interface IERC20Detailed is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.10;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.10;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

interface IUiPoolDataProvider {
    struct InterestRates {
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
        uint256 stableRateSlope1;
        uint256 stableRateSlope2;
        uint256 baseStableBorrowRate;
        uint256 baseVariableBorrowRate;
        uint256 optimalUsageRatio;
    }

    struct AggregatedReserveData {
        address underlyingAsset;
        string name;
        string symbol;
        uint256 decimals;
        uint256 baseLTVasCollateral;
        uint256 reserveLiquidationThreshold;
        uint256 reserveLiquidationBonus;
        uint256 reserveFactor;
        bool usageAsCollateralEnabled;
        bool borrowingEnabled;
        bool stableBorrowRateEnabled;
        bool isActive;
        bool isFrozen;
        // base data
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 liquidityRate;
        uint128 variableBorrowRate;
        uint128 stableBorrowRate;
        uint40 lastUpdateTimestamp;
        address xTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        //
        uint256 availableLiquidity;
        uint256 totalPrincipalStableDebt;
        uint256 averageStableRate;
        uint256 stableDebtLastUpdateTimestamp;
        uint256 totalScaledVariableDebt;
        uint256 priceInMarketReferenceCurrency;
        address priceOracle;
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
        uint256 stableRateSlope1;
        uint256 stableRateSlope2;
        uint256 baseStableBorrowRate;
        uint256 baseVariableBorrowRate;
        uint256 optimalUsageRatio;
        // v3 only
        bool isPaused;
        uint128 accruedToTreasury;
        uint128 unbacked;
        uint128 isolationModeTotalDebt;
        //
        uint256 debtCeiling;
        uint256 debtCeilingDecimals;
        uint8 eModeCategoryId;
        uint256 borrowCap;
        uint256 supplyCap;
        // eMode
        uint16 eModeLtv;
        uint16 eModeLiquidationThreshold;
        uint16 eModeLiquidationBonus;
        address eModePriceSource;
        string eModeLabel;
        bool borrowableInIsolation;
        //AssetType
        DataTypes.AssetType assetType;
    }

    struct UserReserveData {
        address underlyingAsset;
        uint256 scaledXTokenBalance;
        uint256 collaterizedBalance;
        bool usageAsCollateralEnabledOnUser;
        uint256 stableBorrowRate;
        uint256 scaledVariableDebt;
        uint256 principalStableDebt;
        uint256 stableBorrowLastUpdateTimestamp;
    }

    struct BaseCurrencyInfo {
        uint256 marketReferenceCurrencyUnit;
        int256 marketReferenceCurrencyPriceInUsd;
        int256 networkBaseTokenPriceInUsd;
        uint8 networkBaseTokenPriceDecimals;
    }

    function getReservesList(IPoolAddressesProvider provider)
        external
        view
        returns (address[] memory);

    function getReservesData(IPoolAddressesProvider provider)
        external
        view
        returns (AggregatedReserveData[] memory, BaseCurrencyInfo memory);

    function getUserReservesData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (UserReserveData[] memory, uint8);

    function getNTokenData(
        address user,
        address[] memory nTokenAddresses,
        uint256[][] memory tokenIds
    ) external view returns (DataTypes.ERC721SupplyParams[][] memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an ParaSpace Pool.
 **/
interface IPool {
    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the xTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     **/
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    event SupplyERC721(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        DataTypes.ERC721SupplyParams[] tokenData,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of xTokens
     * @param to The address that will receive the underlying asset
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on withdrawERC721()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of xTokens
     * @param to The address that will receive the underlying asset
     * @param tokenIds The tokenIds to be withdrawn
     **/
    event WithdrawERC721(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256[] tokenIds
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param usePTokens True if the repayment is done using xTokens, `false` if done with underlying asset directly
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool usePTokens
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        DataTypes.InterestRateMode interestRateMode
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receivePToken True if the liquidators wants to receive the collateral xTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receivePToken
    );

    /**
     * @dev Emitted when a borrower's ERC721 asset is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param liquidationAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param liquidationAmount The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralTokenId The token id of ERC721 asset received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveNToken True if the liquidators wants to receive the collateral NTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event ERC721LiquidationCall(
        address indexed collateralAsset,
        address indexed liquidationAsset,
        address indexed user,
        uint256 liquidationAmount,
        uint256 liquidatedCollateralTokenId,
        address liquidator,
        bool receiveNToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param stableBorrowRate The next stable borrow rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted xTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     **/
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @dev Emitted on flashClaim
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash claim
     * @param nftAsset address of the underlying asset of NFT
     * @param tokenId The token id of the asset being flash borrowed
     **/
    event FlashClaim(
        address indexed target,
        address indexed initiator,
        address indexed nftAsset,
        uint256 tokenId
    );

    /**
     * @dev Allows smart contracts to access the tokens within one transaction, as long as the tokens taken is returned.
     *
     * Requirements:
     *  - `nftTokenIds` must exist.
     *
     * @param receiverAddress The address of the contract receiving the tokens, implementing the IFlashClaimReceiver interface
     * @param nftAsset address of the underlying asset of NFT
     * @param nftTokenIds token ids of the underlying asset
     * @param params Variadic packed params to pass to the receiver as extra information
     */
    function flashClaim(
        address receiverAddress,
        address nftAsset,
        uint256[] calldata nftTokenIds,
        bytes calldata params
    ) external;

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying xTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 pUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the xTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of xTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Supplies multiple `tokenIds` of underlying ERC721 asset into the reserve, receiving in return overlying nTokens.
     * - E.g. User supplies 2 BAYC and gets in return 2 nBAYC
     * @param asset The address of the underlying asset to supply
     * @param tokenData The list of tokenIds and their collateral configs to be supplied
     * @param onBehalfOf The address that will receive the xTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of xTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supplyERC721(
        address asset,
        DataTypes.ERC721SupplyParams[] calldata tokenData,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the xTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of xTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     **/
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent xTokens owned
     * E.g. User has 100 pUSDC, calls withdraw() and receives 100 USDC, burning the 100 pUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Withdraws multiple `tokenIds` of underlying ERC721  asset from the reserve, burning the equivalent nTokens owned
     * E.g. User has 2 nBAYC, calls withdraw() and receives 2 BAYC, burning the 2 nBAYC
     * @param asset The address of the underlying asset to withdraw
     * @param tokenIds The underlying tokenIds to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole xToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdrawERC721(
        address asset,
        uint256[] calldata tokenIds,
        address to
    ) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     **/
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve xTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 pUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual xToken dust balance, if the user xToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     **/
    function repayWithPTokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
     * @param asset The address of the underlying asset borrowed
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     **/
    function swapBorrowRateMode(address asset, uint256 interestRateMode)
        external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
     *        much has been borrowed at a stable rate and suppliers are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied ERC721 asset with a tokenID as collateral
     * @param asset The address of the underlying asset supplied
     * @param tokenId the id of the supplied ERC721 token
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     **/
    function setUserUseERC721AsCollateral(
        address asset,
        uint256 tokenId,
        bool useAsCollateral
    ) external virtual;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receivePToken True if the liquidators wants to receive the collateral xTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receivePToken
    ) external;

    function liquidationERC721(
        address collateralAsset,
        address liquidationAsset,
        address user,
        uint256 collateralTokenId,
        uint256 liquidationAmount,
        bool receiveNToken
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 erc721HealthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an xToken and debt tokens and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param xTokenAddress The address of the xToken that will be assigned to the reserve
     * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     **/
    function initReserve(
        address asset,
        DataTypes.AssetType assetType,
        address xTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     **/
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     **/
    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    ) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an xToken transfer
     * @dev Only callable by the overlying xToken of the `asset`
     * @param asset The address of the underlying asset of the xToken
     * @param from The user from which the xTokens are transferred
     * @param to The user receiving the xTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The xToken balance of the `from` user before the transfer
     * @param balanceToBefore The xToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        bool usedAsCollateral,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     **/
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     **/
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     **/
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
     * @return The percentage of available liquidity to borrow, expressed in bps
     */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
        external
        view
        returns (uint256);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of xTokens
     * @param assets The list of reserves for which the minting needs to be executed
     **/
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializablePToken} from "./IInitializablePToken.sol";

/**
 * @title IPToken
 *
 * @notice Defines the basic interface for an PToken.
 **/
interface IPToken is IERC20, IScaledBalanceToken, IInitializablePToken {
    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The next liquidity index of the reserve
     **/
    event BalanceTransfer(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 index
    );

    /**
     * @notice Mints `amount` xTokens to `user`
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted xTokens
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address caller,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @notice Burns xTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @dev In some instances, the mint event could be emitted from a burn transaction
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the xTokens will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The next liquidity index of the reserve
     **/
    function burn(
        address from,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @notice Mints xTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @notice Transfers xTokens in the event of a borrow being liquidated, in case the liquidators reclaims the xToken
     * @param from The address getting liquidated, current owner of the xTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @notice Transfers the underlying asset to `target`.
     * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the underlying
     * @param amount The amount getting transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount) external;

    /**
     * @notice Handles the underlying received by the xToken after the transfer has been completed.
     * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
     * transfer is concluded. However in the future there may be xTokens that allow for example to stake the underlying
     * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
     * @param user The user executing the repayment
     * @param amount The amount getting repaid
     **/
    function handleRepayment(address user, uint256 amount) external;

    /**
     * @notice Allow passing a signed message to approve spending
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Returns the address of the underlying asset of this xToken (E.g. WETH for pWETH)
     * @return The address of the underlying asset
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Returns the address of the ParaSpace treasury, receiving the fees on this xToken.
     * @return Address of the ParaSpace treasury
     **/
    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    /**
     * @notice Get the domain separator for the token
     * @dev Return cached value if chainId matches cache, otherwise recomputes separator
     * @return The domain separator of the token at current chain
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Returns the nonce for owner.
     * @param owner The address of the owner
     * @return The nonce of the owner
     **/
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title ICollaterizableERC721
 * @author Parallel
 * @notice Defines the basic interface for an CollaterizableERC721.
 **/
interface ICollaterizableERC721 {
    /**
     * @dev get the collaterized balance of a specific user
     */
    function collaterizedBalanceOf(address user)
        external
        view
        virtual
        returns (uint256);

    /**
     * @dev get the the collateral configuration of a spefifc token
     */
    function isUsedAsCollateral(uint256 tokenId) external view returns (bool);

    /**
     * @dev changes the collateral state/config of a token
     * @return bool (if the state has changed), address (the owner address), uint256 (user's new collaterized balance)
     */
    function setIsUsedAsCollateral(uint256 tokenId, bool useAsCollateral)
        external
        virtual
        returns (
            bool,
            address,
            uint256
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC721} from "../dependencies/openzeppelin/contracts/IERC721.sol";
import {IERC721Receiver} from "../dependencies/openzeppelin/contracts/IERC721Receiver.sol";
import {IERC721Enumerable} from "../dependencies/openzeppelin/contracts/IERC721Enumerable.sol";
import {IERC1155Receiver} from "../dependencies/openzeppelin/contracts/IERC1155Receiver.sol";

import {IInitializableNToken} from "./IInitializableNToken.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title INToken
 * @author ParallelFi
 * @notice Defines the basic interface for an NToken.
 **/
interface INToken is
    IERC721Enumerable,
    IInitializableNToken,
    IERC721Receiver,
    IERC1155Receiver
{
    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param tokenId The id of the token being transferred
     **/
    event BalanceTransfer(
        address indexed from,
        address indexed to,
        uint256 tokenId
    );

    /**
     * @dev Emitted during claimERC20Airdrop()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being claimed from the airdrop
     **/
    event ClaimERC20Airdrop(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted during claimERC721Airdrop()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being claimed from the airdrop
     **/
    event ClaimERC721Airdrop(
        address indexed token,
        address indexed to,
        uint256[] ids
    );

    /**
     * @dev Emitted during claimERC1155Airdrop()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being claimed from the airdrop
     * @param amounts The amount of NFTs being claimed from the airdrop for a specific id.
     * @param data The data of the tokens that is being claimed from the airdrop. Usually this is 0.
     **/
    event ClaimERC1155Airdrop(
        address indexed token,
        address indexed to,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );

    /**
     * @dev Emitted during executeAirdrop()
     * @param airdropContract The address of the airdrop contract
     **/
    event ExecuteAirdrop(address indexed airdropContract);

    /**
     * @notice Mints `amount` nTokens to `user`
     * @param onBehalfOf The address of the user that will receive the minted nTokens
     * @param tokenData The list of the tokens getting minted and their collateral configs
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address onBehalfOf,
        DataTypes.ERC721SupplyParams[] calldata tokenData
    ) external returns (bool);

    /**
     * @notice Burns nTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @dev In some instances, the mint event could be emitted from a burn transaction
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the nTokens will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param tokenIds The ids of the tokens getting burned
     **/
    function burn(
        address from,
        address receiverOfUnderlying,
        uint256[] calldata tokenIds
    ) external returns (bool);

    // TODO are we using the Treasury at all? Can we remove?
    // /**
    //  * @notice Mints nTokens to the reserve treasury
    //  * @param tokenId The id of the token getting minted
    //  * @param index The next liquidity index of the reserve
    //  */
    // function mintToTreasury(uint256 tokenId, uint256 index) external;

    /**
     * @notice Transfers nTokens in the event of a borrow being liquidated, in case the liquidators reclaims the nToken
     * @param from The address getting liquidated, current owner of the nTokens
     * @param to The recipient
     * @param tokenId The id of the token getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice Transfers the underlying asset to `target`.
     * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the underlying
     * @param tokenId The id of the token getting transferred
     **/
    function transferUnderlyingTo(address user, uint256 tokenId) external;

    /**
     * @notice Handles the underlying received by the nToken after the transfer has been completed.
     * @dev The default implementation is empty as with standard ERC721 tokens, nothing needs to be done after the
     * transfer is concluded. However in the future there may be nTokens that allow for example to stake the underlying
     * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
     * @param user The user executing the repayment
     * @param tokenId The amount getting repaid
     **/
    function handleRepayment(address user, uint256 tokenId) external;

    /**
     * @notice Allow passing a signed message to approve spending
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The tokenId
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Returns the address of the underlying asset of this nToken (E.g. WETH for pWETH)
     * @return The address of the underlying asset
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Returns the address of the ParaSpace treasury, receiving the fees on this nToken.
     * @return Address of the ParaSpace treasury
     **/
    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    /**
     * @notice Get the domain separator for the token
     * @dev Return cached value if chainId matches cache, otherwise recomputes separator
     * @return The domain separator of the token at current chain
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Returns the nonce for owner.
     * @param owner The address of the owner
     * @return The nonce of the owner
     **/
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param value The tokenId or amount to transfer
     */
    function rescueTokens(
        address token,
        address to,
        uint256 value
    ) external;

    /**
     * @notice Claims ERC20 Airdrops.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being claimed from the airdrop
     **/
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Claims ERC721 Airdrops.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being claimed from the airdrop
     **/
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    /**
     * @notice Claims ERC1155 Airdrops.
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being claimed from the airdrop
     * @param amounts The amount of NFTs being claimed from the airdrop for a specific id.
     * @param data The data of the tokens that is being claimed from the airdrop. Usually this is 0.
     **/
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @notice Executes airdrop.
     * @param airdropContract The address of the airdrop contract
     * @param airdropParams Third party airdrop abi data. You need to get this from the third party airdrop.
     **/
    function executeAirdrop(
        address airdropContract,
        bytes calldata airdropParams
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";

/**
 * @title IVariableDebtToken
 *
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
    /**
     * @notice Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return True if the previous balance of the user is 0, false otherwise
     * @return The scaled total debt of the reserve
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool, uint256);

    /**
     * @notice Burns user variable debt
     * @dev In some instances, a burn transaction will emit a mint event
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the debt will be burned
     * @param amount The amount getting burned
     * @param index The variable debt index of the reserve
     * @return The scaled total debt of the reserve
     **/
    function burn(
        address from,
        uint256 amount,
        uint256 index
    ) external returns (uint256);

    /**
     * @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
     * @return The address of the underlying asset
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";

/**
 * @title IStableDebtToken
 *
 * @notice Defines the interface for the stable debt token
 * @dev It does not inherit from IERC20 to save in code size
 **/
interface IStableDebtToken is IInitializableDebtToken {
    /**
     * @dev Emitted when new stable debt is minted
     * @param user The address of the user who triggered the minting
     * @param onBehalfOf The recipient of stable debt tokens
     * @param amount The amount minted (user entered amount + balance increase from interest)
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param newRate The rate of the debt after the minting
     * @param avgStableRate The next average stable rate after the minting
     * @param newTotalSupply The next total supply of the stable debt token after the action
     **/
    event Mint(
        address indexed user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 newRate,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @dev Emitted when new stable debt is burned
     * @param from The address from which the debt will be burned
     * @param amount The amount being burned (user entered amount - balance increase from interest)
     * @param currentBalance The current balance of the user
     * @param balanceIncrease The the increase in balance since the last action of the user
     * @param avgStableRate The next average stable rate after the burning
     * @param newTotalSupply The next total supply of the stable debt token after the action
     **/
    event Burn(
        address indexed from,
        uint256 amount,
        uint256 currentBalance,
        uint256 balanceIncrease,
        uint256 avgStableRate,
        uint256 newTotalSupply
    );

    /**
     * @notice Mints debt token to the `onBehalfOf` address.
     * @dev The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt tokens to mint
     * @param rate The rate of the debt being minted
     * @return True if it is the first borrow, false otherwise
     * @return The total stable debt
     * @return The average stable borrow rate
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 rate
    )
        external
        returns (
            bool,
            uint256,
            uint256
        );

    /**
     * @notice Burns debt of `user`
     * @dev The resulting rate is the weighted average between the rate of the new debt
     * and the rate of the previous debt
     * @dev In some instances, a burn transaction will emit a mint event
     * if the amount to burn is less than the interest the user earned
     * @param from The address from which the debt will be burned
     * @param amount The amount of debt tokens getting burned
     * @return The total stable debt
     * @return The average stable borrow rate
     **/
    function burn(address from, uint256 amount)
        external
        returns (uint256, uint256);

    /**
     * @notice Returns the average rate of all the stable rate loans.
     * @return The average stable rate
     **/
    function getAverageStableRate() external view returns (uint256);

    /**
     * @notice Returns the stable rate of the user debt
     * @param user The address of the user
     * @return The stable rate of the user
     **/
    function getUserStableRate(address user) external view returns (uint256);

    /**
     * @notice Returns the timestamp of the last update of the user
     * @param user The address of the user
     * @return The timestamp
     **/
    function getUserLastUpdated(address user) external view returns (uint40);

    /**
     * @notice Returns the principal, the total supply, the average stable rate and the timestamp for the last update
     * @return The principal
     * @return The total supply
     * @return The average stable rate
     * @return The timestamp of the last update
     **/
    function getSupplyData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint40
        );

    /**
     * @notice Returns the timestamp of the last update of the total supply
     * @return The timestamp
     **/
    function getTotalSupplyLastUpdated() external view returns (uint40);

    /**
     * @notice Returns the total supply and the average stable rate
     * @return The total supply
     * @return The average rate
     **/
    function getTotalSupplyAndAvgRate()
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Returns the principal debt balance of the user
     * @return The debt balance of the user since the last burn/mint action
     **/
    function principalBalanceOf(address user) external view returns (uint256);

    /**
     * @notice Returns the address of the underlying asset of this stableDebtToken (E.g. WETH for stableDebtWETH)
     * @return The address of the underlying asset
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title WadRayMath library
 *
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(
                or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(
                iszero(b),
                iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))
            ) {
                revert(0, 0)
            }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 *
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
    uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
    uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
    uint256 internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
    /// @dev bit 63 reserved

    uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
    uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
    uint256 internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
    uint256 internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
    uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

    uint256 internal constant MAX_VALID_LTV = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
    uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
    uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
    uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
    uint256 internal constant MAX_VALID_EMODE_CATEGORY = 255;
    uint256 internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
    uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

    uint256 public constant DEBT_CEILING_DECIMALS = 2;
    uint16 public constant MAX_RESERVES_COUNT = 128;

    /**
     * @notice Sets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @param ltv The new ltv
     **/
    function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv)
        internal
        pure
    {
        require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @notice Gets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @return The loan to value
     **/
    function getLtv(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return self.data & ~LTV_MASK;
    }

    /**
     * @notice Sets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @param threshold The new liquidation threshold
     **/
    function setLiquidationThreshold(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 threshold
    ) internal pure {
        require(
            threshold <= MAX_VALID_LIQUIDATION_THRESHOLD,
            Errors.INVALID_LIQ_THRESHOLD
        );

        self.data =
            (self.data & LIQUIDATION_THRESHOLD_MASK) |
            (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @return The liquidation threshold
     **/
    function getLiquidationThreshold(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (uint256) {
        return
            (self.data & ~LIQUIDATION_THRESHOLD_MASK) >>
            LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @param bonus The new liquidation bonus
     **/
    function setLiquidationBonus(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 bonus
    ) internal pure {
        require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

        self.data =
            (self.data & LIQUIDATION_BONUS_MASK) |
            (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @return The liquidation bonus
     **/
    function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~LIQUIDATION_BONUS_MASK) >>
            LIQUIDATION_BONUS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @param decimals The decimals
     **/
    function setDecimals(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 decimals
    ) internal pure {
        require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

        self.data =
            (self.data & DECIMALS_MASK) |
            (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @return The decimals of the asset
     **/
    function getDecimals(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setActive(
        DataTypes.ReserveConfigurationMap memory self,
        bool active
    ) internal pure {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @notice Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     **/
    function getActive(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @notice Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     **/
    function setFrozen(
        DataTypes.ReserveConfigurationMap memory self,
        bool frozen
    ) internal pure {
        self.data =
            (self.data & FROZEN_MASK) |
            (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @notice Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     **/
    function getFrozen(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @notice Sets the paused state of the reserve
     * @param self The reserve configuration
     * @param paused The paused state
     **/
    function setPaused(
        DataTypes.ReserveConfigurationMap memory self,
        bool paused
    ) internal pure {
        self.data =
            (self.data & PAUSED_MASK) |
            (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the paused state of the reserve
     * @param self The reserve configuration
     * @return The paused state
     **/
    function getPaused(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~PAUSED_MASK) != 0;
    }

    /**
     * @notice Sets the siloed borrowing flag for the reserve.
     * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
     * @param self The reserve configuration
     * @param siloed True if the asset is siloed
     **/
    function setSiloedBorrowing(
        DataTypes.ReserveConfigurationMap memory self,
        bool siloed
    ) internal pure {
        self.data =
            (self.data & SILOED_BORROWING_MASK) |
            (uint256(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
    }

    /**
     * @notice Gets the siloed borrowing flag for the reserve.
     * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
     * @param self The reserve configuration
     * @return The siloed borrowing flag
     **/
    function getSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~SILOED_BORROWING_MASK) != 0;
    }

    /**
     * @notice Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     **/
    function setBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     **/
    function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @notice Enables or disables stable rate borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
     **/
    function setStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & STABLE_BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) <<
                STABLE_BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the stable rate borrowing state of the reserve
     * @param self The reserve configuration
     * @return The stable rate borrowing state
     **/
    function getStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (bool) {
        return (self.data & ~STABLE_BORROWING_MASK) != 0;
    }

    /**
     * @notice Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     **/
    function setReserveFactor(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 reserveFactor
    ) internal pure {
        require(
            reserveFactor <= MAX_VALID_RESERVE_FACTOR,
            Errors.INVALID_RESERVE_FACTOR
        );

        self.data =
            (self.data & RESERVE_FACTOR_MASK) |
            (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
    }

    /**
     * @notice Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     **/
    function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return
            (self.data & ~RESERVE_FACTOR_MASK) >>
            RESERVE_FACTOR_START_BIT_POSITION;
    }

    /**
     * @notice Sets the borrow cap of the reserve
     * @param self The reserve configuration
     * @param borrowCap The borrow cap
     **/
    function setBorrowCap(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 borrowCap
    ) internal pure {
        require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

        self.data =
            (self.data & BORROW_CAP_MASK) |
            (borrowCap << BORROW_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrow cap of the reserve
     * @param self The reserve configuration
     * @return The borrow cap
     **/
    function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the supply cap of the reserve
     * @param self The reserve configuration
     * @param supplyCap The supply cap
     **/
    function setSupplyCap(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 supplyCap
    ) internal pure {
        require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

        self.data =
            (self.data & SUPPLY_CAP_MASK) |
            (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the supply cap of the reserve
     * @param self The reserve configuration
     * @return The supply cap
     **/
    function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256)
    {
        return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation protocol fee of the reserve
     * @param self The reserve configuration
     * @param liquidationProtocolFee The liquidation protocol fee
     **/
    function setLiquidationProtocolFee(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 liquidationProtocolFee
    ) internal pure {
        require(
            liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
            Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
        );

        self.data =
            (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
            (liquidationProtocolFee <<
                LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation protocol fee
     * @param self The reserve configuration
     * @return The liquidation protocol fee
     **/
    function getLiquidationProtocolFee(
        DataTypes.ReserveConfigurationMap memory self
    ) internal pure returns (uint256) {
        return
            (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >>
            LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flag representing active
     * @return The state flag representing frozen
     * @return The state flag representing borrowing enabled
     * @return The state flag representing stableRateBorrowing enabled
     * @return The state flag representing paused
     **/
    function getFlags(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            bool,
            bool,
            bool,
            bool,
            bool
        )
    {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_MASK) != 0,
            (dataLocal & ~STABLE_BORROWING_MASK) != 0,
            (dataLocal & ~PAUSED_MASK) != 0
        );
    }

    /**
     * @notice Gets the configuration parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing ltv
     * @return The state param representing liquidation threshold
     * @return The state param representing liquidation bonus
     * @return The state param representing reserve decimals
     * @return The state param representing reserve factor
     **/
    function getParams(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 dataLocal = self.data;

        return (
            dataLocal & ~LTV_MASK,
            (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >>
                LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_BONUS_MASK) >>
                LIQUIDATION_BONUS_START_BIT_POSITION,
            (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
            (dataLocal & ~RESERVE_FACTOR_MASK) >>
                RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @notice Gets the caps parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing borrow cap
     * @return The state param representing supply cap.
     **/
    function getCaps(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
            (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveConfiguration} from "./ReserveConfiguration.sol";

/**
 * @title UserConfiguration library
 *
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    uint256 internal constant BORROWING_MASK =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 internal constant COLLATERAL_MASK =
        0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

    /**
     * @notice Sets if the user is borrowing the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param borrowing True if the user is borrowing the reserve, false otherwise
     **/
    function setBorrowing(
        DataTypes.UserConfigurationMap storage self,
        uint256 reserveIndex,
        bool borrowing
    ) internal {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            uint256 bit = 1 << (reserveIndex << 1);
            if (borrowing) {
                self.data |= bit;
            } else {
                self.data &= ~bit;
            }
        }
    }

    /**
     * @notice Sets if the user is using as collateral the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param usingAsCollateral True if the user is using the reserve as collateral, false otherwise
     **/
    function setUsingAsCollateral(
        DataTypes.UserConfigurationMap storage self,
        uint256 reserveIndex,
        bool usingAsCollateral
    ) internal {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            uint256 bit = 1 << ((reserveIndex << 1) + 1);
            if (usingAsCollateral) {
                self.data |= bit;
            } else {
                self.data &= ~bit;
            }
        }
    }

    /**
     * @notice Returns if a user has been using the reserve for borrowing or as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
     **/
    function isUsingAsCollateralOrBorrowing(
        DataTypes.UserConfigurationMap memory self,
        uint256 reserveIndex
    ) internal pure returns (bool) {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            return (self.data >> (reserveIndex << 1)) & 3 != 0;
        }
    }

    /**
     * @notice Validate a user has been using the reserve for borrowing
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing, false otherwise
     **/
    function isBorrowing(
        DataTypes.UserConfigurationMap memory self,
        uint256 reserveIndex
    ) internal pure returns (bool) {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            return (self.data >> (reserveIndex << 1)) & 1 != 0;
        }
    }

    /**
     * @notice Validate a user has been using the reserve as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve as collateral, false otherwise
     **/
    function isUsingAsCollateral(
        DataTypes.UserConfigurationMap memory self,
        uint256 reserveIndex
    ) internal pure returns (bool) {
        unchecked {
            require(
                reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT,
                Errors.INVALID_RESERVE_INDEX
            );
            return (self.data >> ((reserveIndex << 1) + 1)) & 1 != 0;
        }
    }

    /**
     * @notice Checks if a user has been supplying only one reserve as collateral
     * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
     * @param self The configuration object
     * @return True if the user has been supplying as collateral one reserve, false otherwise
     **/
    function isUsingAsCollateralOne(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        uint256 collateralData = self.data & COLLATERAL_MASK;
        return
            collateralData != 0 && (collateralData & (collateralData - 1) == 0);
    }

    /**
     * @notice Checks if a user has been supplying any reserve as collateral
     * @param self The configuration object
     * @return True if the user has been supplying as collateral any reserve, false otherwise
     **/
    function isUsingAsCollateralAny(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return self.data & COLLATERAL_MASK != 0;
    }

    /**
     * @notice Checks if a user has been borrowing only one asset
     * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
     * @param self The configuration object
     * @return True if the user has been supplying as collateral one reserve, false otherwise
     **/
    function isBorrowingOne(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        uint256 borrowingData = self.data & BORROWING_MASK;
        return borrowingData != 0 && (borrowingData & (borrowingData - 1) == 0);
    }

    /**
     * @notice Checks if a user has been borrowing from any reserve
     * @param self The configuration object
     * @return True if the user has been borrowing any reserve, false otherwise
     **/
    function isBorrowingAny(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return self.data & BORROWING_MASK != 0;
    }

    /**
     * @notice Checks if a user has not been using any reserve for borrowing or supply
     * @param self The configuration object
     * @return True if the user has not been borrowing or supplying any reserve, false otherwise
     **/
    function isEmpty(DataTypes.UserConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return self.data == 0;
    }

    /**
     * @notice Returns the siloed borrowing state for the user
     * @param self The configuration object
     * @param reservesData The data of all the reserves
     * @param reservesList The reserve list
     * @return True if the user has borrowed a siloed asset, false otherwise
     * @return The address of the only borrowed asset
     */
    function getSiloedBorrowingState(
        DataTypes.UserConfigurationMap memory self,
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList
    ) internal view returns (bool, address) {
        if (isBorrowingOne(self)) {
            uint256 assetId = _getFirstAssetIdByMask(self, BORROWING_MASK);
            address assetAddress = reservesList[assetId];
            if (reservesData[assetAddress].configuration.getSiloedBorrowing()) {
                return (true, assetAddress);
            }
        }

        return (false, address(0));
    }

    /**
     * @notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
     * @param self The configuration object
     * @return The index of the first asset flagged in the bitmap once the corresponding mask is applied
     */
    function _getFirstAssetIdByMask(
        DataTypes.UserConfigurationMap memory self,
        uint256 mask
    ) internal pure returns (uint256) {
        unchecked {
            uint256 bitmapData = self.data & mask;
            uint256 firstAssetPosition = bitmapData & ~(bitmapData - 1);
            uint256 id;

            while ((firstAssetPosition >>= 2) != 0) {
                id += 1;
            }
            return id;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

library DataTypes {
    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        // the asset type of the reserve (uint8)
        AssetType assetType;
        //xToken address
        address xTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct ERC721SupplyParams {
        uint256 tokenId;
        bool useAsCollateral;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        AssetType assetType;
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address xTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    // struct ExecuteLiquidationCallParams {
    //     uint256 reservesCount;
    //     uint256 debtToCover;
    //     address collateralAsset;
    //     address debtAsset;
    //     address user;
    //     bool receivePToken;
    //     address priceOracle;
    //     address priceOracleSentinel;
    // }

    // struct ExecuteERC721LiquidationCallParams {
    //     uint256 reservesCount;
    //     uint256 liquidationAmount;
    //     uint256 collateralTokenId;
    //     address collateralAsset;
    //     address liquidationAsset;
    //     address user;
    //     bool receiveNToken;
    //     address priceOracle;
    //     address priceOracleSentinel;
    // }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 liquidationAmount;
        uint256 collateralTokenId;
        address collateralAsset;
        address liquidationAsset;
        address user;
        bool receiveXToken;
        address priceOracle;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteSupplyERC721Params {
        address asset;
        DataTypes.ERC721SupplyParams[] tokenData;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool usePTokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct ExecuteWithdrawERC721Params {
        address asset;
        uint256[] tokenIds;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        bool usedAsCollateral;
        uint256 value;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
        AssetType assetType;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
        AssetType assetType;
    }

    struct ValidateERC721LiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        uint256 tokenId;
        uint256 collateralDiscountedPrice;
        uint256 liquidationAmount;
        address priceOracleSentinel;
        address xTokenAddress;
        AssetType assetType;
    }

    struct CalculateInterestRatesParams {
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address xToken;
    }

    struct InitReserveParams {
        address asset;
        AssetType assetType;
        address xTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }

    struct ExecuteFlashClaimParams {
        address receiverAddress;
        address nftAsset;
        uint256[] nftTokenIds;
        bytes params;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IReserveInterestRateStrategy} from "../../interfaces/IReserveInterestRateStrategy.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IToken} from "../../interfaces/IToken.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

/**
 * @title DefaultReserveInterestRateStrategy contract
 *
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_USAGE_RATIO`
 * point of usage and another from that one to 100%.
 * - An instance of this same contract, can't be used across different ParaSpace markets, due to the caching
 *   of the PoolAddressesProvider
 **/
contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    /**
     * @dev This constant represents the usage ratio at which the pool aims to obtain most competitive borrow rates.
     * Expressed in ray
     **/
    uint256 public immutable OPTIMAL_USAGE_RATIO;

    /**
     * @dev This constant represents the optimal stable debt to total debt ratio of the reserve.
     * Expressed in ray
     */
    uint256 public immutable OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO;

    /**
     * @dev This constant represents the excess usage ratio above the optimal. It's always equal to
     * 1-optimal usage ratio. Added as a constant here for gas optimizations.
     * Expressed in ray
     **/
    uint256 public immutable MAX_EXCESS_USAGE_RATIO;

    /**
     * @dev This constant represents the excess stable debt ratio above the optimal. It's always equal to
     * 1-optimal stable to total debt ratio. Added as a constant here for gas optimizations.
     * Expressed in ray
     **/
    uint256 public immutable MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    // Base variable borrow rate when usage rate = 0. Expressed in ray
    uint256 internal immutable _baseVariableBorrowRate;

    // Slope of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
    uint256 internal immutable _variableRateSlope1;

    // Slope of the variable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
    uint256 internal immutable _variableRateSlope2;

    // Slope of the stable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
    uint256 internal immutable _stableRateSlope1;

    // Slope of the stable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
    uint256 internal immutable _stableRateSlope2;

    // Premium on top of `_variableRateSlope1` for base stable borrowing rate
    uint256 internal immutable _baseStableRateOffset;

    // Additional premium applied to stable rate when stable debt surpass `OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO`
    uint256 internal immutable _stableRateExcessOffset;

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     * @param optimalUsageRatio The optimal usage ratio
     * @param baseVariableBorrowRate The base variable borrow rate
     * @param variableRateSlope1 The variable rate slope below optimal usage ratio
     * @param variableRateSlope2 The variable rate slope above optimal usage ratio
     * @param stableRateSlope1 The stable rate slope below optimal usage ratio
     * @param stableRateSlope2 The stable rate slope above optimal usage ratio
     * @param baseStableRateOffset The premium on top of variable rate for base stable borrowing rate
     * @param stableRateExcessOffset The premium on top of stable rate when there stable debt surpass the threshold
     * @param optimalStableToTotalDebtRatio The optimal stable debt to total debt ratio of the reserve
     */
    constructor(
        IPoolAddressesProvider provider,
        uint256 optimalUsageRatio,
        uint256 baseVariableBorrowRate,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2,
        uint256 stableRateSlope1,
        uint256 stableRateSlope2,
        uint256 baseStableRateOffset,
        uint256 stableRateExcessOffset,
        uint256 optimalStableToTotalDebtRatio
    ) {
        require(
            WadRayMath.RAY >= optimalUsageRatio,
            Errors.INVALID_OPTIMAL_USAGE_RATIO
        );
        require(
            WadRayMath.RAY >= optimalStableToTotalDebtRatio,
            Errors.INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
        );
        OPTIMAL_USAGE_RATIO = optimalUsageRatio;
        MAX_EXCESS_USAGE_RATIO = WadRayMath.RAY - optimalUsageRatio;
        OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = optimalStableToTotalDebtRatio;
        MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO =
            WadRayMath.RAY -
            optimalStableToTotalDebtRatio;
        ADDRESSES_PROVIDER = provider;
        _baseVariableBorrowRate = baseVariableBorrowRate;
        _variableRateSlope1 = variableRateSlope1;
        _variableRateSlope2 = variableRateSlope2;
        _stableRateSlope1 = stableRateSlope1;
        _stableRateSlope2 = stableRateSlope2;
        _baseStableRateOffset = baseStableRateOffset;
        _stableRateExcessOffset = stableRateExcessOffset;
    }

    /**
     * @notice Returns the variable rate slope below optimal usage ratio
     * @dev Its the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
     * @return The variable rate slope
     **/
    function getVariableRateSlope1() external view returns (uint256) {
        return _variableRateSlope1;
    }

    /**
     * @notice Returns the variable rate slope above optimal usage ratio
     * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
     * @return The variable rate slope
     **/
    function getVariableRateSlope2() external view returns (uint256) {
        return _variableRateSlope2;
    }

    /**
     * @notice Returns the stable rate slope below optimal usage ratio
     * @dev Its the stable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
     * @return The stable rate slope
     **/
    function getStableRateSlope1() external view returns (uint256) {
        return _stableRateSlope1;
    }

    /**
     * @notice Returns the stable rate slope above optimal usage ratio
     * @dev Its the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
     * @return The stable rate slope
     **/
    function getStableRateSlope2() external view returns (uint256) {
        return _stableRateSlope2;
    }

    /**
     * @notice Returns the stable rate excess offset
     * @dev An additional premium applied to the stable when stable debt > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
     * @return The stable rate excess offset
     */
    function getStableRateExcessOffset() external view returns (uint256) {
        return _stableRateExcessOffset;
    }

    /**
     * @notice Returns the base stable borrow rate
     * @return The base stable borrow rate
     **/
    function getBaseStableBorrowRate() public view returns (uint256) {
        return _variableRateSlope1 + _baseStableRateOffset;
    }

    /// @inheritdoc IReserveInterestRateStrategy
    function getBaseVariableBorrowRate()
        external
        view
        override
        returns (uint256)
    {
        return _baseVariableBorrowRate;
    }

    /// @inheritdoc IReserveInterestRateStrategy
    function getMaxVariableBorrowRate()
        external
        view
        override
        returns (uint256)
    {
        return
            _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
    }

    struct CalcInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 totalDebt;
        uint256 currentVariableBorrowRate;
        uint256 currentStableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 borrowUsageRatio;
        uint256 supplyUsageRatio;
        uint256 stableToTotalDebtRatio;
        uint256 availableLiquidityPlusDebt;
    }

    /// @inheritdoc IReserveInterestRateStrategy
    function calculateInterestRates(
        DataTypes.CalculateInterestRatesParams calldata params
    )
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = params.totalStableDebt + params.totalVariableDebt;

        vars.currentLiquidityRate = 0;
        vars.currentVariableBorrowRate = _baseVariableBorrowRate;
        vars.currentStableBorrowRate = getBaseStableBorrowRate();

        if (vars.totalDebt != 0) {
            vars.stableToTotalDebtRatio = params.totalStableDebt.rayDiv(
                vars.totalDebt
            );
            vars.availableLiquidity =
                IToken(params.reserve).balanceOf(params.xToken) +
                params.liquidityAdded -
                params.liquidityTaken;

            vars.availableLiquidityPlusDebt =
                vars.availableLiquidity +
                vars.totalDebt;
            vars.borrowUsageRatio = vars.totalDebt.rayDiv(
                vars.availableLiquidityPlusDebt
            );
            vars.supplyUsageRatio = vars.totalDebt.rayDiv(
                vars.availableLiquidityPlusDebt
            );
        }

        if (vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO) {
            uint256 excessBorrowUsageRatio = (vars.borrowUsageRatio -
                OPTIMAL_USAGE_RATIO).rayDiv(MAX_EXCESS_USAGE_RATIO);

            vars.currentStableBorrowRate +=
                _stableRateSlope1 +
                _stableRateSlope2.rayMul(excessBorrowUsageRatio);

            vars.currentVariableBorrowRate +=
                _variableRateSlope1 +
                _variableRateSlope2.rayMul(excessBorrowUsageRatio);
        } else {
            vars.currentStableBorrowRate += _stableRateSlope1
                .rayMul(vars.borrowUsageRatio)
                .rayDiv(OPTIMAL_USAGE_RATIO);

            vars.currentVariableBorrowRate += _variableRateSlope1
                .rayMul(vars.borrowUsageRatio)
                .rayDiv(OPTIMAL_USAGE_RATIO);
        }

        if (vars.stableToTotalDebtRatio > OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO) {
            uint256 excessStableDebtRatio = (vars.stableToTotalDebtRatio -
                OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO).rayDiv(
                    MAX_EXCESS_STABLE_TO_TOTAL_DEBT_RATIO
                );
            vars.currentStableBorrowRate += _stableRateExcessOffset.rayMul(
                excessStableDebtRatio
            );
        }

        vars.currentLiquidityRate = _getOverallBorrowRate(
            params.totalStableDebt,
            params.totalVariableDebt,
            vars.currentVariableBorrowRate,
            params.averageStableBorrowRate
        ).rayMul(vars.supplyUsageRatio).percentMul(
                PercentageMath.PERCENTAGE_FACTOR - params.reserveFactor
            );

        return (
            vars.currentLiquidityRate,
            vars.currentStableBorrowRate,
            vars.currentVariableBorrowRate
        );
    }

    /**
     * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable
     * debt
     * @param totalStableDebt The total borrowed from the reserve at a stable rate
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param currentVariableBorrowRate The current variable borrow rate of the reserve
     * @param currentAverageStableBorrowRate The current weighted average of all the stable rate loans
     * @return The weighted averaged borrow rate
     **/
    function _getOverallBorrowRate(
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 currentVariableBorrowRate,
        uint256 currentAverageStableBorrowRate
    ) internal pure returns (uint256) {
        uint256 totalDebt = totalStableDebt + totalVariableDebt;

        if (totalDebt == 0) return 0;

        uint256 weightedVariableRate = totalVariableDebt.wadToRay().rayMul(
            currentVariableBorrowRate
        );

        uint256 weightedStableRate = totalStableDebt.wadToRay().rayMul(
            currentAverageStableBorrowRate
        );

        uint256 overallBorrowRate = (weightedVariableRate + weightedStableRate)
            .rayDiv(totalDebt.wadToRay());

        return overallBorrowRate;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IEACAggregatorProxy {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 timestamp
    );
    event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";

interface IERC20DetailedBytes is IERC20 {
    function name() external view returns (bytes32);

    function symbol() external view returns (bytes32);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {WadRayMath} from "../protocol/libraries/math/WadRayMath.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IStableDebtToken} from "../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../interfaces/IVariableDebtToken.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IPoolDataProvider} from "../interfaces/IPoolDataProvider.sol";

/**
 * @title ProtocolDataProvider
 *
 * @notice Peripheral contract to collect and pre-process information from the Pool.
 */
contract ProtocolDataProvider is IPoolDataProvider {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using WadRayMath for uint256;

    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    constructor(IPoolAddressesProvider addressesProvider) {
        ADDRESSES_PROVIDER = addressesProvider;
    }

    /**
     * @notice Returns the list of the existing reserves in the pool.
     * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
     * @return The list of reserves, pairs of symbols and addresses
     */
    function getAllReservesTokens() external view returns (TokenData[] memory) {
        IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
        address[] memory reserves = pool.getReservesList();
        TokenData[] memory reservesTokens = new TokenData[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            if (reserves[i] == MKR) {
                reservesTokens[i] = TokenData({
                    symbol: "MKR",
                    tokenAddress: reserves[i]
                });
                continue;
            }
            if (reserves[i] == ETH) {
                reservesTokens[i] = TokenData({
                    symbol: "ETH",
                    tokenAddress: reserves[i]
                });
                continue;
            }
            reservesTokens[i] = TokenData({
                symbol: IERC20Detailed(reserves[i]).symbol(),
                tokenAddress: reserves[i]
            });
        }
        return reservesTokens;
    }

    /**
     * @notice Returns the list of the existing PTokens in the pool.
     * @return The list of PTokens, pairs of symbols and addresses
     */
    function getAllPTokens() external view returns (TokenData[] memory) {
        IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
        address[] memory reserves = pool.getReservesList();
        TokenData[] memory xTokens = new TokenData[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory reserveData = pool.getReserveData(
                reserves[i]
            );
            xTokens[i] = TokenData({
                symbol: IERC20Detailed(reserveData.xTokenAddress).symbol(),
                tokenAddress: reserveData.xTokenAddress
            });
        }
        return xTokens;
    }

    /**
     * @notice Returns the configuration data of the reserve
     * @dev Not returning borrow and supply caps for compatibility, nor pause flag
     * @param asset The address of the underlying asset of the reserve
     * @return decimals The number of decimals of the reserve
     * @return ltv The ltv of the reserve
     * @return liquidationThreshold The liquidationThreshold of the reserve
     * @return liquidationBonus The liquidationBonus of the reserve
     * @return reserveFactor The reserveFactor of the reserve
     * @return usageAsCollateralEnabled True if the usage as collateral is enabled, false otherwise
     * @return borrowingEnabled True if borrowing is enabled, false otherwise
     * @return stableBorrowRateEnabled True if stable rate borrowing is enabled, false otherwise
     * @return isActive True if it is active, false otherwise
     * @return isFrozen True if it is frozen, false otherwise
     **/
    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        )
    {
        DataTypes.ReserveConfigurationMap memory configuration = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getConfiguration(asset);

        (
            ltv,
            liquidationThreshold,
            liquidationBonus,
            decimals,
            reserveFactor
        ) = configuration.getParams();

        (
            isActive,
            isFrozen,
            borrowingEnabled,
            stableBorrowRateEnabled,

        ) = configuration.getFlags();

        usageAsCollateralEnabled = liquidationThreshold != 0;
    }

    /**
     * @notice Returns the caps parameters of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return borrowCap The borrow cap of the reserve
     * @return supplyCap The supply cap of the reserve
     **/
    function getReserveCaps(address asset)
        external
        view
        returns (uint256 borrowCap, uint256 supplyCap)
    {
        (borrowCap, supplyCap) = IPool(ADDRESSES_PROVIDER.getPool())
            .getConfiguration(asset)
            .getCaps();
    }

    /**
     * @notice Returns if the pool is paused
     * @param asset The address of the underlying asset of the reserve
     * @return isPaused True if the pool is paused, false otherwise
     **/
    function getPaused(address asset) external view returns (bool isPaused) {
        (, , , , isPaused) = IPool(ADDRESSES_PROVIDER.getPool())
            .getConfiguration(asset)
            .getFlags();
    }

    /**
     * @notice Returns the siloed borrowing flag
     * @param asset The address of the underlying asset of the reserve
     * @return True if the asset is siloed for borrowing
     **/
    function getSiloedBorrowing(address asset) external view returns (bool) {
        return
            IPool(ADDRESSES_PROVIDER.getPool())
                .getConfiguration(asset)
                .getSiloedBorrowing();
    }

    /**
     * @notice Returns the protocol fee on the liquidation bonus
     * @param asset The address of the underlying asset of the reserve
     * @return The protocol fee on liquidation
     **/
    function getLiquidationProtocolFee(address asset)
        external
        view
        returns (uint256)
    {
        return
            IPool(ADDRESSES_PROVIDER.getPool())
                .getConfiguration(asset)
                .getLiquidationProtocolFee();
    }

    /**
     * @notice Returns the reserve data
     * @param asset The address of the underlying asset of the reserve
     * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
     * @return totalPToken The total supply of the xToken
     * @return totalStableDebt The total stable debt of the reserve
     * @return totalVariableDebt The total variable debt of the reserve
     * @return liquidityRate The liquidity rate of the reserve
     * @return variableBorrowRate The variable borrow rate of the reserve
     * @return stableBorrowRate The stable borrow rate of the reserve
     * @return averageStableBorrowRate The average stable borrow rate of the reserve
     * @return liquidityIndex The liquidity index of the reserve
     * @return variableBorrowIndex The variable borrow index of the reserve
     * @return lastUpdateTimestamp The timestamp of the last update of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        override
        returns (
            uint256 accruedToTreasuryScaled,
            uint256 totalPToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        )
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);

        return (
            reserve.accruedToTreasury,
            IERC20Detailed(reserve.xTokenAddress).totalSupply(),
            IERC20Detailed(reserve.stableDebtTokenAddress).totalSupply(),
            IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply(),
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            reserve.currentStableBorrowRate,
            IStableDebtToken(reserve.stableDebtTokenAddress)
                .getAverageStableRate(),
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.lastUpdateTimestamp
        );
    }

    /**
     * @notice Returns the total supply of xTokens for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total supply of the xToken
     **/
    function getPTokenTotalSupply(address asset)
        external
        view
        override
        returns (uint256)
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);
        return IERC20Detailed(reserve.xTokenAddress).totalSupply();
    }

    /**
     * @notice Returns the total debt for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total debt for asset
     **/
    function getTotalDebt(address asset)
        external
        view
        override
        returns (uint256)
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);
        return
            IERC20Detailed(reserve.stableDebtTokenAddress).totalSupply() +
            IERC20Detailed(reserve.variableDebtTokenAddress).totalSupply();
    }

    /**
     * @notice Returns the user data in a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param user The address of the user
     * @return currentPTokenBalance The current PToken balance of the user
     * @return currentStableDebt The current stable debt of the user
     * @return currentVariableDebt The current variable debt of the user
     * @return principalStableDebt The principal stable debt of the user
     * @return scaledVariableDebt The scaled variable debt of the user
     * @return stableBorrowRate The stable borrow rate of the user
     * @return liquidityRate The liquidity rate of the reserve
     * @return stableRateLastUpdated The timestamp of the last update of the user stable rate
     * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
     *         otherwise
     **/
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentPTokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        )
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);

        DataTypes.UserConfigurationMap memory userConfig = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getUserConfiguration(user);

        currentPTokenBalance = IERC20Detailed(reserve.xTokenAddress).balanceOf(
            user
        );
        currentVariableDebt = IERC20Detailed(reserve.variableDebtTokenAddress)
            .balanceOf(user);
        currentStableDebt = IERC20Detailed(reserve.stableDebtTokenAddress)
            .balanceOf(user);
        principalStableDebt = IStableDebtToken(reserve.stableDebtTokenAddress)
            .principalBalanceOf(user);
        scaledVariableDebt = IVariableDebtToken(
            reserve.variableDebtTokenAddress
        ).scaledBalanceOf(user);
        liquidityRate = reserve.currentLiquidityRate;
        stableBorrowRate = IStableDebtToken(reserve.stableDebtTokenAddress)
            .getUserStableRate(user);
        stableRateLastUpdated = IStableDebtToken(reserve.stableDebtTokenAddress)
            .getUserLastUpdated(user);
        usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);
    }

    /**
     * @notice Returns the token addresses of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return xTokenAddress The PToken address of the reserve
     * @return stableDebtTokenAddress The StableDebtToken address of the reserve
     * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
     */
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address xTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        )
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);

        return (
            reserve.xTokenAddress,
            reserve.stableDebtTokenAddress,
            reserve.variableDebtTokenAddress
        );
    }

    /**
     * @notice Returns the address of the Interest Rate strategy
     * @param asset The address of the underlying asset of the reserve
     * @return irStrategyAddress The address of the Interest Rate strategy
     */
    function getInterestRateStrategyAddress(address asset)
        external
        view
        returns (address irStrategyAddress)
    {
        DataTypes.ReserveData memory reserve = IPool(
            ADDRESSES_PROVIDER.getPool()
        ).getReserveData(asset);

        return (reserve.interestRateStrategyAddress);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IScaledBalanceToken
 *
 * @notice Defines the basic interface for a scaledbalance token.
 **/
interface IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted scaled balance tokens
     * @param value The amount being minted (user entered amount + balance increase from interest)
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param index The next liquidity index of the reserve
     **/
    event Mint(
        address indexed caller,
        address indexed onBehalfOf,
        uint256 value,
        uint256 balanceIncrease,
        uint256 index
    );

    /**
     * @dev Emitted after scaled balance tokens are burned
     * @param from The address from which the scaled tokens will be burned
     * @param target The address that will receive the underlying, if any
     * @param value The amount being burned (user entered amount - balance increase from interest)
     * @param balanceIncrease The increase in balance since the last action of the user
     * @param index The next liquidity index of the reserve
     **/
    event Burn(
        address indexed from,
        address indexed target,
        uint256 value,
        uint256 balanceIncrease,
        uint256 index
    );

    /**
     * @notice Returns the scaled balance of the user.
     * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
     * at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @notice Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);

    /**
     * @notice Returns last index interest was accrued to the user's balance
     * @param user The address of the user
     * @return The last index interest was accrued to the user's balance, expressed in ray
     **/
    function getPreviousIndex(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IRewardController} from "./IRewardController.sol";
import {IPool} from "./IPool.sol";

/**
 * @title IInitializablePToken
 *
 * @notice Interface for the initialize function on PToken
 **/
interface IInitializablePToken {
    /**
     * @dev Emitted when an pToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param treasury The address of the treasury
     * @param incentivesController The address of the incentives controller for this pToken
     * @param pTokenDecimals The decimals of the underlying
     * @param pTokenName The name of the pToken
     * @param pTokenSymbol The symbol of the pToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        address incentivesController,
        uint8 pTokenDecimals,
        string pTokenName,
        string pTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the pToken
     * @param pool The pool contract that is initializing this contract
     * @param treasury The address of the ParaSpace treasury, receiving the fees on this pToken
     * @param underlyingAsset The address of the underlying asset of this pToken (E.g. WETH for pWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param pTokenDecimals The decimals of the pToken, same as the underlying asset's
     * @param pTokenName The name of the pToken
     * @param pTokenSymbol The symbol of the pToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address treasury,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 pTokenDecimals,
        string calldata pTokenName,
        string calldata pTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IRewardController
 *
 * @notice Defines the basic interface for an ParaSpace Incentives Controller.
 **/
interface IRewardController {
    /**
     * @dev Emitted during `handleAction`, `claimRewards` and `claimRewardsOnBehalf`
     * @param user The user that accrued rewards
     * @param amount The amount of accrued rewards
     */
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted during `claimRewards` and `claimRewardsOnBehalf`
     * @param user The address that accrued rewards
     * @param to The address that will be receiving the rewards
     * @param claimer The address that performed the claim
     * @param amount The amount of rewards
     */
    event RewardsClaimed(
        address indexed user,
        address indexed to,
        address indexed claimer,
        uint256 amount
    );

    /**
     * @dev Emitted during `setClaimer`
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @notice Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index
     * @return The emission per second
     * @return The last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * LEGACY **************************
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function assets(address asset)
        external
        view
        returns (
            uint128,
            uint128,
            uint256
        );

    /**
     * @notice Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @notice Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @notice Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(
        address[] calldata assets,
        uint256[] calldata emissionsPerSecond
    ) external;

    /**
     * @notice Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the pool
     * @param totalSupply The total supply of the asset in the pool
     **/
    function handleAction(
        address asset,
        uint256 totalSupply,
        uint256 userBalance
    ) external;

    /**
     * @notice Returns the total of rewards of a user, already accrued + not yet accrued
     * @param assets The assets to accumulate rewards for
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    /**
     * @notice Claims reward for a user, on the assets of the pool, accumulating the pending rewards
     * @param assets The assets to accumulate rewards for
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice Claims reward for a user on its behalf, on the assets of the pool, accumulating the pending rewards.
     * @dev The caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param assets The assets to accumulate rewards for
     * @param amount The amount of rewards to claim
     * @param user The address to check and claim rewards
     * @param to The address that will be receiving the rewards
     * @return The amount of rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @notice Returns the unclaimed rewards of the user
     * @param user The address of the user
     * @return The unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the user index for a specific asset
     * @param user The address of the user
     * @param asset The asset to incentivize
     * @return The user index for the asset
     */
    function getUserAssetData(address user, address asset)
        external
        view
        returns (uint256);

    /**
     * @notice for backward compatibility with previous implementation of the Incentives controller
     * @return The address of the reward token
     */
    function REWARD_TOKEN() external view returns (address);

    /**
     * @notice for backward compatibility with previous implementation of the Incentives controller
     * @return The precision used in the incentives controller
     */
    function PRECISION() external view returns (uint8);

    /**
     * @dev Gets the distribution end timestamp of the emissions
     */
    function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity 0.8.10;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.10;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.10;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IRewardController} from "./IRewardController.sol";
import {IPool} from "./IPool.sol";

/**
 * @title IInitializablenToken
 *
 * @notice Interface for the initialize function on NToken
 **/
interface IInitializableNToken {
    /**
     * @dev Emitted when an nToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param treasury The address of the treasury
     * @param incentivesController The address of the incentives controller for this nToken
     * @param nTokenName The name of the nToken
     * @param nTokenSymbol The symbol of the nToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        address incentivesController,
        string nTokenName,
        string nTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the nToken
     * @param pool The pool contract that is initializing this contract
     * @param treasury The address of the ParaSpace treasury, receiving the fees on this nToken
     * @param underlyingAsset The address of the underlying asset of this nToken (E.g. WETH for pWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param nTokenName The name of the nToken
     * @param nTokenSymbol The symbol of the nToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address treasury,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 nTokenDecimals,
        string calldata nTokenName,
        string calldata nTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IRewardController} from "./IRewardController.sol";
import {IPool} from "./IPool.sol";

/**
 * @title IInitializableDebtToken
 *
 * @notice Interface for the initialize function common between debt tokens
 **/
interface IInitializableDebtToken {
    /**
     * @dev Emitted when a debt token is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param incentivesController The address of the incentives controller for this xToken
     * @param debtTokenDecimals The decimals of the debt token
     * @param debtTokenName The name of the debt token
     * @param debtTokenSymbol The symbol of the debt token
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address incentivesController,
        uint8 debtTokenDecimals,
        string debtTokenName,
        string debtTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the debt token.
     * @param pool The pool contract that is initializing this contract
     * @param underlyingAsset The address of the underlying asset of this xToken (E.g. WETH for pWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title PercentageMath library
 *
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    // Half percentage factor (50.00%)
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

    /**
     * @notice Executes a percentage multiplication
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentmul percentage
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256 result)
    {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if iszero(
                or(
                    iszero(percentage),
                    iszero(
                        gt(
                            value,
                            div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage)
                        )
                    )
                )
            ) {
                revert(0, 0)
            }

            result := div(
                add(mul(value, percentage), HALF_PERCENTAGE_FACTOR),
                PERCENTAGE_FACTOR
            )
        }
    }

    /**
     * @notice Executes a percentage division
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentdiv percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256 result)
    {
        // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
        assembly {
            if or(
                iszero(percentage),
                iszero(
                    iszero(
                        gt(
                            value,
                            div(
                                sub(not(0), div(percentage, 2)),
                                PERCENTAGE_FACTOR
                            )
                        )
                    )
                )
            ) {
                revert(0, 0)
            }

            result := div(
                add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)),
                percentage
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IReserveInterestRateStrategy
 *
 * @notice Interface for the calculation of the interest rates
 */
interface IReserveInterestRateStrategy {
    /**
     * @notice Returns the base variable borrow rate
     * @return The base variable borrow rate, expressed in ray
     **/
    function getBaseVariableBorrowRate() external view returns (uint256);

    /**
     * @notice Returns the maximum variable borrow rate
     * @return The maximum variable borrow rate, expressed in ray
     **/
    function getMaxVariableBorrowRate() external view returns (uint256);

    /**
     * @notice Calculates the interest rates depending on the reserve's state and configurations
     * @param params The parameters needed to calculate interest rates
     * @return liquidityRate The liquidity rate expressed in rays
     * @return stableBorrowRate The stable borrow rate expressed in rays
     * @return variableBorrowRate The variable borrow rate expressed in rays
     **/
    function calculateInterestRates(
        DataTypes.CalculateInterestRatesParams memory params
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IToken {
    function balanceOf(address) external view virtual returns (uint256);

    function totalSupply() external view virtual returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IPoolDataProvider {
    /**
     * @notice Returns the reserve data
     * @param asset The address of the underlying asset of the reserve
     * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
     * @return totalPToken The total supply of the xToken
     * @return totalStableDebt The total stable debt of the reserve
     * @return totalVariableDebt The total variable debt of the reserve
     * @return liquidityRate The liquidity rate of the reserve
     * @return variableBorrowRate The variable borrow rate of the reserve
     * @return stableBorrowRate The stable borrow rate of the reserve
     * @return averageStableBorrowRate The average stable borrow rate of the reserve
     * @return liquidityIndex The liquidity index of the reserve
     * @return variableBorrowIndex The variable borrow index of the reserve
     * @return lastUpdateTimestamp The timestamp of the last update of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 accruedToTreasuryScaled,
            uint256 totalPToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    /**
     * @notice Returns the total supply of xTokens for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total supply of the xToken
     **/
    function getPTokenTotalSupply(address asset)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the total debt for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total debt for asset
     **/
    function getTotalDebt(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VersionedInitializable} from "../libraries/paraspace-upgradeability/VersionedInitializable.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {ConfiguratorLogic} from "../libraries/logic/ConfiguratorLogic.sol";
import {ConfiguratorInputTypes} from "../libraries/types/ConfiguratorInputTypes.sol";
import {IPoolConfigurator} from "../../interfaces/IPoolConfigurator.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {IPoolDataProvider} from "../../interfaces/IPoolDataProvider.sol";

/**
 * @title PoolConfigurator
 *
 * @dev Implements the configuration methods for the ParaSpace protocol
 **/
contract PoolConfigurator is VersionedInitializable, IPoolConfigurator {
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    IPoolAddressesProvider internal _addressesProvider;
    IPool internal _pool;

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        _onlyPoolAdmin();
        _;
    }

    /**
     * @dev Only emergency admin can call functions marked by this modifier.
     **/
    modifier onlyEmergencyAdmin() {
        _onlyEmergencyAdmin();
        _;
    }

    /**
     * @dev Only emergency or pool admin can call functions marked by this modifier.
     **/
    modifier onlyEmergencyOrPoolAdmin() {
        _onlyPoolOrEmergencyAdmin();
        _;
    }

    /**
     * @dev Only asset listing or pool admin can call functions marked by this modifier.
     **/
    modifier onlyAssetListingOrPoolAdmins() {
        _onlyAssetListingOrPoolAdmins();
        _;
    }

    /**
     * @dev Only risk or pool admin can call functions marked by this modifier.
     **/
    modifier onlyRiskOrPoolAdmins() {
        _onlyRiskOrPoolAdmins();
        _;
    }

    uint256 public constant CONFIGURATOR_REVISION = 0x1;

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return CONFIGURATOR_REVISION;
    }

    function initialize(IPoolAddressesProvider provider) external initializer {
        _addressesProvider = provider;
        _pool = IPool(_addressesProvider.getPool());
    }

    /// @inheritdoc IPoolConfigurator
    function initReserves(
        ConfiguratorInputTypes.InitReserveInput[] calldata input
    ) external override onlyAssetListingOrPoolAdmins {
        IPool cachedPool = _pool;
        for (uint256 i = 0; i < input.length; i++) {
            ConfiguratorLogic.executeInitReserve(cachedPool, input[i]);
        }
    }

    /// @inheritdoc IPoolConfigurator
    function dropReserve(address asset) external override onlyPoolAdmin {
        _pool.dropReserve(asset);
        emit ReserveDropped(asset);
    }

    /// @inheritdoc IPoolConfigurator
    function updatePToken(
        ConfiguratorInputTypes.UpdateXTokenInput calldata input
    ) external override onlyPoolAdmin {
        ConfiguratorLogic.executeUpdateXToken(_pool, input);
    }

    /// @inheritdoc IPoolConfigurator
    function updateStableDebtToken(
        ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
    ) external override onlyPoolAdmin {
        ConfiguratorLogic.executeUpdateStableDebtToken(_pool, input);
    }

    /// @inheritdoc IPoolConfigurator
    function updateVariableDebtToken(
        ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
    ) external override onlyPoolAdmin {
        ConfiguratorLogic.executeUpdateVariableDebtToken(_pool, input);
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveBorrowing(address asset, bool enabled)
        external
        override
        onlyRiskOrPoolAdmins
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        if (!enabled) {
            require(
                !currentConfig.getStableRateBorrowingEnabled(),
                Errors.STABLE_BORROWING_ENABLED
            );
        }
        currentConfig.setBorrowingEnabled(enabled);
        _pool.setConfiguration(asset, currentConfig);
        emit ReserveBorrowing(asset, enabled);
    }

    /// @inheritdoc IPoolConfigurator
    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external override onlyRiskOrPoolAdmins {
        //validation of the parameters: the LTV can
        //only be lower or equal than the liquidation threshold
        //(otherwise a loan against the asset would cause instantaneous liquidation)
        require(ltv <= liquidationThreshold, Errors.INVALID_RESERVE_PARAMS);

        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);

        if (liquidationThreshold != 0) {
            //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
            //collateral than needed to cover the debt
            require(
                liquidationBonus > PercentageMath.PERCENTAGE_FACTOR,
                Errors.INVALID_RESERVE_PARAMS
            );

            //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
            //a loan is taken there is enough collateral available to cover the liquidation bonus
            require(
                liquidationThreshold.percentMul(liquidationBonus) <=
                    PercentageMath.PERCENTAGE_FACTOR,
                Errors.INVALID_RESERVE_PARAMS
            );
        } else {
            require(liquidationBonus == 0, Errors.INVALID_RESERVE_PARAMS);
            //if the liquidation threshold is being set to 0,
            // the reserve is being disabled as collateral. To do so,
            //we need to ensure no liquidity is supplied
            _checkNoSuppliers(asset);
        }

        currentConfig.setLtv(ltv);
        currentConfig.setLiquidationThreshold(liquidationThreshold);
        currentConfig.setLiquidationBonus(liquidationBonus);

        _pool.setConfiguration(asset, currentConfig);

        emit CollateralConfigurationChanged(
            asset,
            ltv,
            liquidationThreshold,
            liquidationBonus
        );
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveStableRateBorrowing(address asset, bool enabled)
        external
        override
        onlyRiskOrPoolAdmins
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        if (enabled) {
            require(
                currentConfig.getBorrowingEnabled(),
                Errors.BORROWING_NOT_ENABLED
            );
        }
        currentConfig.setStableRateBorrowingEnabled(enabled);
        _pool.setConfiguration(asset, currentConfig);
        emit ReserveStableRateBorrowing(asset, enabled);
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveActive(address asset, bool active)
        external
        override
        onlyPoolAdmin
    {
        if (!active) _checkNoSuppliers(asset);
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        currentConfig.setActive(active);
        _pool.setConfiguration(asset, currentConfig);
        emit ReserveActive(asset, active);
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveFreeze(address asset, bool freeze)
        external
        override
        onlyRiskOrPoolAdmins
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        currentConfig.setFrozen(freeze);
        _pool.setConfiguration(asset, currentConfig);
        emit ReserveFrozen(asset, freeze);
    }

    /// @inheritdoc IPoolConfigurator
    function setReservePause(address asset, bool paused)
        public
        override
        onlyEmergencyOrPoolAdmin
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        currentConfig.setPaused(paused);
        _pool.setConfiguration(asset, currentConfig);
        emit ReservePaused(asset, paused);
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveFactor(address asset, uint256 newReserveFactor)
        external
        override
        onlyRiskOrPoolAdmins
    {
        require(
            newReserveFactor <= PercentageMath.PERCENTAGE_FACTOR,
            Errors.INVALID_RESERVE_FACTOR
        );
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        uint256 oldReserveFactor = currentConfig.getReserveFactor();
        currentConfig.setReserveFactor(newReserveFactor);
        _pool.setConfiguration(asset, currentConfig);
        emit ReserveFactorChanged(asset, oldReserveFactor, newReserveFactor);
    }

    /// @inheritdoc IPoolConfigurator
    function setSiloedBorrowing(address asset, bool newSiloed)
        external
        override
        onlyRiskOrPoolAdmins
    {
        if (newSiloed) {
            _checkNoBorrowers(asset);
        }
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);

        bool oldSiloed = currentConfig.getSiloedBorrowing();

        currentConfig.setSiloedBorrowing(newSiloed);

        _pool.setConfiguration(asset, currentConfig);

        emit SiloedBorrowingChanged(asset, oldSiloed, newSiloed);
    }

    /// @inheritdoc IPoolConfigurator
    function setBorrowCap(address asset, uint256 newBorrowCap)
        external
        override
        onlyRiskOrPoolAdmins
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        uint256 oldBorrowCap = currentConfig.getBorrowCap();
        currentConfig.setBorrowCap(newBorrowCap);
        _pool.setConfiguration(asset, currentConfig);
        emit BorrowCapChanged(asset, oldBorrowCap, newBorrowCap);
    }

    /// @inheritdoc IPoolConfigurator
    function setSupplyCap(address asset, uint256 newSupplyCap)
        external
        override
        onlyRiskOrPoolAdmins
    {
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        uint256 oldSupplyCap = currentConfig.getSupplyCap();
        currentConfig.setSupplyCap(newSupplyCap);
        _pool.setConfiguration(asset, currentConfig);
        emit SupplyCapChanged(asset, oldSupplyCap, newSupplyCap);
    }

    /// @inheritdoc IPoolConfigurator
    function setLiquidationProtocolFee(address asset, uint256 newFee)
        external
        override
        onlyRiskOrPoolAdmins
    {
        require(
            newFee <= PercentageMath.PERCENTAGE_FACTOR,
            Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
        );
        DataTypes.ReserveConfigurationMap memory currentConfig = _pool
            .getConfiguration(asset);
        uint256 oldFee = currentConfig.getLiquidationProtocolFee();
        currentConfig.setLiquidationProtocolFee(newFee);
        _pool.setConfiguration(asset, currentConfig);
        emit LiquidationProtocolFeeChanged(asset, oldFee, newFee);
    }

    /// @inheritdoc IPoolConfigurator
    function setReserveInterestRateStrategyAddress(
        address asset,
        address newRateStrategyAddress
    ) external override onlyRiskOrPoolAdmins {
        DataTypes.ReserveData memory reserve = _pool.getReserveData(asset);
        address oldRateStrategyAddress = reserve.interestRateStrategyAddress;
        _pool.setReserveInterestRateStrategyAddress(
            asset,
            newRateStrategyAddress
        );
        emit ReserveInterestRateStrategyChanged(
            asset,
            oldRateStrategyAddress,
            newRateStrategyAddress
        );
    }

    /// @inheritdoc IPoolConfigurator
    function setPoolPause(bool paused) external override onlyEmergencyAdmin {
        address[] memory reserves = _pool.getReservesList();

        for (uint256 i = 0; i < reserves.length; i++) {
            if (reserves[i] != address(0)) {
                setReservePause(reserves[i], paused);
            }
        }
    }

    function _checkNoSuppliers(address asset) internal view {
        uint256 totalPTokens = IPoolDataProvider(
            _addressesProvider.getPoolDataProvider()
        ).getPTokenTotalSupply(asset);
        require(totalPTokens == 0, Errors.RESERVE_LIQUIDITY_NOT_ZERO);
    }

    function _checkNoBorrowers(address asset) internal view {
        uint256 totalDebt = IPoolDataProvider(
            _addressesProvider.getPoolDataProvider()
        ).getTotalDebt(asset);
        require(totalDebt == 0, Errors.RESERVE_DEBT_NOT_ZERO);
    }

    function _onlyPoolAdmin() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
    }

    function _onlyEmergencyAdmin() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isEmergencyAdmin(msg.sender),
            Errors.CALLER_NOT_EMERGENCY_ADMIN
        );
    }

    function _onlyPoolOrEmergencyAdmin() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isPoolAdmin(msg.sender) ||
                aclManager.isEmergencyAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_OR_EMERGENCY_ADMIN
        );
    }

    function _onlyAssetListingOrPoolAdmins() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isAssetListingAdmin(msg.sender) ||
                aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
        );
    }

    function _onlyRiskOrPoolAdmins() internal view {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isRiskAdmin(msg.sender) ||
                aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_RISK_OR_POOL_ADMIN
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title VersionedInitializable
 * , inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing ||
                isConstructor() ||
                revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /**
     * @notice Returns the revision number of the contract
     * @dev Needs to be defined in the inherited class as a constant.
     * @return The revision number
     **/
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @notice Returns true if and only if the function is running in the constructor
     * @return True if the function is running in the constructor
     **/
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from "../../../interfaces/IPool.sol";
import {IInitializablePToken} from "../../../interfaces/IInitializablePToken.sol";
import {IInitializableDebtToken} from "../../../interfaces/IInitializableDebtToken.sol";
import {IRewardController} from "../../../interfaces/IRewardController.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "../paraspace-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ConfiguratorInputTypes} from "../types/ConfiguratorInputTypes.sol";

/**
 * @title ConfiguratorLogic library
 *
 * @notice Implements the functions to initialize reserves and update xTokens and debtTokens
 */
library ConfiguratorLogic {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    // See `IPoolConfigurator` for descriptions
    event ReserveInitialized(
        address indexed asset,
        address indexed xToken,
        address stableDebtToken,
        address variableDebtToken,
        address interestRateStrategyAddress
    );
    event XTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );
    // TODO can we get rid of StableDebtToken?
    event StableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );
    event VariableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @notice Initialize a reserve by creating and initializing xToken, stable debt token and variable debt token
     * @dev Emits the `ReserveInitialized` event
     * @param pool The Pool in which the reserve will be initialized
     * @param input The needed parameters for the initialization
     */
    function executeInitReserve(
        IPool pool,
        ConfiguratorInputTypes.InitReserveInput calldata input
    ) public {
        address xTokenProxyAddress = _initTokenWithProxy(
            input.xTokenImpl,
            abi.encodeWithSelector(
                IInitializablePToken.initialize.selector,
                pool,
                input.treasury,
                input.underlyingAsset,
                input.incentivesController,
                input.underlyingAssetDecimals,
                input.xTokenName,
                input.xTokenSymbol,
                input.params
            )
        );

        address stableDebtTokenProxyAddress = _initTokenWithProxy(
            input.stableDebtTokenImpl,
            abi.encodeWithSelector(
                IInitializableDebtToken.initialize.selector,
                pool,
                input.underlyingAsset,
                input.incentivesController,
                input.underlyingAssetDecimals,
                input.stableDebtTokenName,
                input.stableDebtTokenSymbol,
                input.params
            )
        );

        address variableDebtTokenProxyAddress = _initTokenWithProxy(
            input.variableDebtTokenImpl,
            abi.encodeWithSelector(
                IInitializableDebtToken.initialize.selector,
                pool,
                input.underlyingAsset,
                input.incentivesController,
                input.underlyingAssetDecimals,
                input.variableDebtTokenName,
                input.variableDebtTokenSymbol,
                input.params
            )
        );

        pool.initReserve(
            input.underlyingAsset,
            input.assetType,
            xTokenProxyAddress,
            stableDebtTokenProxyAddress,
            variableDebtTokenProxyAddress,
            input.interestRateStrategyAddress
        );

        DataTypes.ReserveConfigurationMap memory currentConfig = DataTypes
            .ReserveConfigurationMap(0);

        currentConfig.setDecimals(input.underlyingAssetDecimals);

        currentConfig.setActive(true);
        currentConfig.setPaused(false);
        currentConfig.setFrozen(false);

        pool.setConfiguration(input.underlyingAsset, currentConfig);

        emit ReserveInitialized(
            input.underlyingAsset,
            xTokenProxyAddress,
            stableDebtTokenProxyAddress,
            variableDebtTokenProxyAddress,
            input.interestRateStrategyAddress
        );
    }

    /**
     * @notice Updates the xToken implementation and initializes it
     * @dev Emits the `XTokenUpgraded` event
     * @param cachedPool The Pool containing the reserve with the xToken
     * @param input The parameters needed for the initialize call
     */
    function executeUpdateXToken(
        IPool cachedPool,
        ConfiguratorInputTypes.UpdateXTokenInput calldata input
    ) public {
        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(
            input.asset
        );

        (, , , uint256 decimals, ) = cachedPool
            .getConfiguration(input.asset)
            .getParams();

        bytes memory encodedCall = abi.encodeWithSelector(
            IInitializablePToken.initialize.selector,
            cachedPool,
            input.treasury,
            input.asset,
            input.incentivesController,
            decimals,
            input.name,
            input.symbol,
            input.params
        );

        _upgradeTokenImplementation(
            reserveData.xTokenAddress,
            input.implementation,
            encodedCall
        );

        emit XTokenUpgraded(
            input.asset,
            reserveData.xTokenAddress,
            input.implementation
        );
    }

    // TODO can we get rid of StableDebtToken?
    /**
     * @notice Updates the stable debt token implementation and initializes it
     * @dev Emits the `StableDebtTokenUpgraded` event
     * @param cachedPool The Pool containing the reserve with the stable debt token
     * @param input The parameters needed for the initialize call
     */
    function executeUpdateStableDebtToken(
        IPool cachedPool,
        ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
    ) public {
        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(
            input.asset
        );

        (, , , uint256 decimals, ) = cachedPool
            .getConfiguration(input.asset)
            .getParams();

        bytes memory encodedCall = abi.encodeWithSelector(
            IInitializableDebtToken.initialize.selector,
            cachedPool,
            input.asset,
            input.incentivesController,
            decimals,
            input.name,
            input.symbol,
            input.params
        );

        _upgradeTokenImplementation(
            reserveData.stableDebtTokenAddress,
            input.implementation,
            encodedCall
        );

        emit StableDebtTokenUpgraded(
            input.asset,
            reserveData.stableDebtTokenAddress,
            input.implementation
        );
    }

    /**
     * @notice Updates the variable debt token implementation and initializes it
     * @dev Emits the `VariableDebtTokenUpgraded` event
     * @param cachedPool The Pool containing the reserve with the variable debt token
     * @param input The parameters needed for the initialize call
     */
    function executeUpdateVariableDebtToken(
        IPool cachedPool,
        ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
    ) public {
        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(
            input.asset
        );

        (, , , uint256 decimals, ) = cachedPool
            .getConfiguration(input.asset)
            .getParams();

        bytes memory encodedCall = abi.encodeWithSelector(
            IInitializableDebtToken.initialize.selector,
            cachedPool,
            input.asset,
            input.incentivesController,
            decimals,
            input.name,
            input.symbol,
            input.params
        );

        _upgradeTokenImplementation(
            reserveData.variableDebtTokenAddress,
            input.implementation,
            encodedCall
        );

        emit VariableDebtTokenUpgraded(
            input.asset,
            reserveData.variableDebtTokenAddress,
            input.implementation
        );
    }

    /**
     * @notice Creates a new proxy and initializes the implementation
     * @param implementation The address of the implementation
     * @param initParams The parameters that is passed to the implementation to initialize
     * @return The address of initialized proxy
     */
    function _initTokenWithProxy(
        address implementation,
        bytes memory initParams
    ) internal returns (address) {
        InitializableImmutableAdminUpgradeabilityProxy proxy = new InitializableImmutableAdminUpgradeabilityProxy(
                address(this)
            );

        proxy.initialize(implementation, initParams);

        return address(proxy);
    }

    /**
     * @notice Upgrades the implementation and makes call to the proxy
     * @dev The call is used to initialize the new implementation.
     * @param proxyAddress The address of the proxy
     * @param implementation The address of the new implementation
     * @param  initParams The parameters to the call after the upgrade
     */
    function _upgradeTokenImplementation(
        address proxyAddress,
        address implementation,
        bytes memory initParams
    ) internal {
        InitializableImmutableAdminUpgradeabilityProxy proxy = InitializableImmutableAdminUpgradeabilityProxy(
                payable(proxyAddress)
            );

        proxy.upgradeToAndCall(implementation, initParams);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {DataTypes} from "./DataTypes.sol";

library ConfiguratorInputTypes {
    struct InitReserveInput {
        address xTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
        uint8 underlyingAssetDecimals;
        address interestRateStrategyAddress;
        address underlyingAsset;
        DataTypes.AssetType assetType;
        address treasury;
        address incentivesController;
        string xTokenName;
        string xTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        string stableDebtTokenName;
        string stableDebtTokenSymbol;
        bytes params;
    }

    struct UpdateXTokenInput {
        address asset;
        address treasury;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }

    struct UpdateDebtTokenInput {
        address asset;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {ConfiguratorInputTypes} from "../protocol/libraries/types/ConfiguratorInputTypes.sol";

/**
 * @title IPoolConfigurator
 *
 * @notice Defines the basic interface for a Pool configurator.
 **/
interface IPoolConfigurator {
    /**
     * @dev Emitted when a reserve is initialized.
     * @param asset The address of the underlying asset of the reserve
     * @param xToken The address of the associated xToken contract
     * @param stableDebtToken The address of the associated stable rate debt token
     * @param variableDebtToken The address of the associated variable rate debt token
     * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
     **/
    event ReserveInitialized(
        address indexed asset,
        address indexed xToken,
        address stableDebtToken,
        address variableDebtToken,
        address interestRateStrategyAddress
    );

    /**
     * @dev Emitted when borrowing is enabled or disabled on a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if borrowing is enabled, false otherwise
     **/
    event ReserveBorrowing(address indexed asset, bool enabled);

    /**
     * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
     * @param asset The address of the underlying asset of the reserve
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     **/
    event CollateralConfigurationChanged(
        address indexed asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    );

    /**
     * @dev Emitted when stable rate borrowing is enabled or disabled on a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if stable rate borrowing is enabled, false otherwise
     **/
    event ReserveStableRateBorrowing(address indexed asset, bool enabled);

    /**
     * @dev Emitted when a reserve is activated or deactivated
     * @param asset The address of the underlying asset of the reserve
     * @param active True if reserve is active, false otherwise
     **/
    event ReserveActive(address indexed asset, bool active);

    /**
     * @dev Emitted when a reserve is frozen or unfrozen
     * @param asset The address of the underlying asset of the reserve
     * @param frozen True if reserve is frozen, false otherwise
     **/
    event ReserveFrozen(address indexed asset, bool frozen);

    /**
     * @dev Emitted when a reserve is paused or unpaused
     * @param asset The address of the underlying asset of the reserve
     * @param paused True if reserve is paused, false otherwise
     **/
    event ReservePaused(address indexed asset, bool paused);

    /**
     * @dev Emitted when a reserve is dropped.
     * @param asset The address of the underlying asset of the reserve
     **/
    event ReserveDropped(address indexed asset);

    /**
     * @dev Emitted when a reserve factor is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldReserveFactor The old reserve factor, expressed in bps
     * @param newReserveFactor The new reserve factor, expressed in bps
     **/
    event ReserveFactorChanged(
        address indexed asset,
        uint256 oldReserveFactor,
        uint256 newReserveFactor
    );

    /**
     * @dev Emitted when the borrow cap of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldBorrowCap The old borrow cap
     * @param newBorrowCap The new borrow cap
     **/
    event BorrowCapChanged(
        address indexed asset,
        uint256 oldBorrowCap,
        uint256 newBorrowCap
    );

    /**
     * @dev Emitted when the supply cap of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldSupplyCap The old supply cap
     * @param newSupplyCap The new supply cap
     **/
    event SupplyCapChanged(
        address indexed asset,
        uint256 oldSupplyCap,
        uint256 newSupplyCap
    );

    /**
     * @dev Emitted when the liquidation protocol fee of a reserve is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldFee The old liquidation protocol fee, expressed in bps
     * @param newFee The new liquidation protocol fee, expressed in bps
     **/
    event LiquidationProtocolFeeChanged(
        address indexed asset,
        uint256 oldFee,
        uint256 newFee
    );

    /**
     * @dev Emitted when a reserve interest strategy contract is updated.
     * @param asset The address of the underlying asset of the reserve
     * @param oldStrategy The address of the old interest strategy contract
     * @param newStrategy The address of the new interest strategy contract
     **/
    event ReserveInterestRateStrategyChanged(
        address indexed asset,
        address oldStrategy,
        address newStrategy
    );

    /**
     * @dev Emitted when an xToken implementation is upgraded.
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The xToken proxy address
     * @param implementation The new xToken implementation
     **/
    event XTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the implementation of a stable debt token is upgraded.
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The stable debt token proxy address
     * @param implementation The new xToken implementation
     **/
    event StableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the implementation of a variable debt token is upgraded.
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The variable debt token proxy address
     * @param implementation The new xToken implementation
     **/
    event VariableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the the siloed borrowing state for an asset is changed.
     * @param asset The address of the underlying asset of the reserve
     * @param oldState The old siloed borrowing state
     * @param newState The new siloed borrowing state
     **/
    event SiloedBorrowingChanged(
        address indexed asset,
        bool oldState,
        bool newState
    );

    /**
     * @notice Initializes multiple reserves.
     * @param input The array of initialization parameters
     **/
    function initReserves(
        ConfiguratorInputTypes.InitReserveInput[] calldata input
    ) external;

    /**
     * @dev Updates the xToken implementation for the reserve.
     * @param input The xToken update parameters
     **/
    function updatePToken(
        ConfiguratorInputTypes.UpdateXTokenInput calldata input
    ) external;

    /**
     * @notice Updates the stable debt token implementation for the reserve.
     * @param input The stableDebtToken update parameters
     **/
    function updateStableDebtToken(
        ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
    ) external;

    /**
     * @notice Updates the variable debt token implementation for the asset.
     * @param input The variableDebtToken update parameters
     **/
    function updateVariableDebtToken(
        ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
    ) external;

    /**
     * @notice Configures borrowing on a reserve.
     * @dev Can only be disabled (set to false) if stable borrowing is disabled
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if borrowing needs to be enabled, false otherwise
     **/
    function setReserveBorrowing(address asset, bool enabled) external;

    /**
     * @notice Configures the reserve collateralization parameters.
     * @dev All the values are expressed in bps. A value of 10000, results in 100.00%
     * @dev The `liquidationBonus` is always above 100%. A value of 105% means the liquidator will receive a 5% bonus
     * @param asset The address of the underlying asset of the reserve
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     **/
    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;

    /**
     * @notice Enable or disable stable rate borrowing on a reserve.
     * @dev Can only be enabled (set to true) if borrowing is enabled
     * @param asset The address of the underlying asset of the reserve
     * @param enabled True if stable rate borrowing needs to be enabled, false otherwise
     **/
    function setReserveStableRateBorrowing(address asset, bool enabled)
        external;

    /**
     * @notice Activate or deactivate a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param active True if the reserve needs to be active, false otherwise
     **/
    function setReserveActive(address asset, bool active) external;

    /**
     * @notice Freeze or unfreeze a reserve. A frozen reserve doesn't allow any new supply, borrow
     * or rate swap but allows repayments, liquidations, rate rebalances and withdrawals.
     * @param asset The address of the underlying asset of the reserve
     * @param freeze True if the reserve needs to be frozen, false otherwise
     **/
    function setReserveFreeze(address asset, bool freeze) external;

    /**
     * @notice Pauses a reserve. A paused reserve does not allow any interaction (supply, borrow, repay,
     * swap interest rate, liquidate, xtoken transfers).
     * @param asset The address of the underlying asset of the reserve
     * @param paused True if pausing the reserve, false if unpausing
     **/
    function setReservePause(address asset, bool paused) external;

    /**
     * @notice Updates the reserve factor of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newReserveFactor The new reserve factor of the reserve
     **/
    function setReserveFactor(address asset, uint256 newReserveFactor) external;

    /**
     * @notice Sets the interest rate strategy of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newRateStrategyAddress The address of the new interest strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        address newRateStrategyAddress
    ) external;

    /**
     * @notice Pauses or unpauses all the protocol reserves. In the paused state all the protocol interactions
     * are suspended.
     * @param paused True if protocol needs to be paused, false otherwise
     **/
    function setPoolPause(bool paused) external;

    /**
     * @notice Updates the borrow cap of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newBorrowCap The new borrow cap of the reserve
     **/
    function setBorrowCap(address asset, uint256 newBorrowCap) external;

    /**
     * @notice Updates the supply cap of a reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newSupplyCap The new supply cap of the reserve
     **/
    function setSupplyCap(address asset, uint256 newSupplyCap) external;

    /**
     * @notice Updates the liquidation protocol fee of reserve.
     * @param asset The address of the underlying asset of the reserve
     * @param newFee The new liquidation protocol fee of the reserve, expressed in bps
     **/
    function setLiquidationProtocolFee(address asset, uint256 newFee) external;

    /**
     * @notice Drops a reserve entirely.
     * @param asset The address of the reserve to drop
     **/
    function dropReserve(address asset) external;

    /**
     * @notice Sets siloed borrowing for an asset
     * @param siloed The new siloed borrowing state
     */
    function setSiloedBorrowing(address asset, bool siloed) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {InitializableUpgradeabilityProxy} from "../../../dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol";
import {Proxy} from "../../../dependencies/openzeppelin/upgradeability/Proxy.sol";
import {BaseImmutableAdminUpgradeabilityProxy} from "./BaseImmutableAdminUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 *
 * @dev Extends BaseAdminUpgradeabilityProxy with an initializer function
 */
contract InitializableImmutableAdminUpgradeabilityProxy is
    BaseImmutableAdminUpgradeabilityProxy,
    InitializableUpgradeabilityProxy
{
    /**
     * @dev Constructor.
     * @param admin The address of the admin
     */
    constructor(address admin) BaseImmutableAdminUpgradeabilityProxy(admin) {
        // Intentionally left blank
    }

    /// @inheritdoc BaseImmutableAdminUpgradeabilityProxy
    function _willFallback()
        internal
        override(BaseImmutableAdminUpgradeabilityProxy, Proxy)
    {
        BaseImmutableAdminUpgradeabilityProxy._willFallback();
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
     * @dev Contract initializer.
     * @param _logic Address of the initial implementation.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    function initialize(address _logic, bytes memory _data) public payable {
        require(_implementation() == address(0));
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
    /**
     * @dev Fallback function.
     * Will run if no other function in the contract matches the call data.
     * Implemented entirely in `_fallback`.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @return The Address of the implementation.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param implementation Address to delegate.
     */
    function _delegate(address implementation) internal {
        //solium-disable-next-line
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Function that is run as the first thing in the fallback function.
     * Can be redefined in derived contracts to add functionality.
     * Redefinitions must call super._willFallback().
     */
    function _willFallback() internal virtual {}

    /**
     * @dev fallback implementation.
     * Extracted to enable manual triggering.
     */
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {BaseUpgradeabilityProxy} from "../../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol";

/**
 * @title BaseImmutableAdminUpgradeabilityProxy
 * , inspired by the OpenZeppelin upgradeability proxy pattern
 * @notice This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * @dev The admin role is stored in an immutable, which helps saving transactions costs
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
    address internal immutable _admin;

    /**
     * @dev Constructor.
     * @param admin The address of the admin
     */
    constructor(address admin) {
        _admin = admin;
    }

    modifier ifAdmin() {
        if (msg.sender == _admin) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @notice Return the admin address
     * @return The address of the proxy admin.
     */
    function admin() external ifAdmin returns (address) {
        return _admin;
    }

    /**
     * @notice Return the implementation address
     * @return The address of the implementation.
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @notice Upgrade the backing implementation of the proxy.
     * @dev Only the admin can call this function.
     * @param newImplementation The address of the new implementation.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @notice Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * @dev This is useful to initialize the proxied contract.
     * @param newImplementation The address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifAdmin
    {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @notice Only fall back when the sender is not the admin.
     */
    function _willFallback() internal virtual override {
        require(
            msg.sender != _admin,
            "Cannot call fallback function from the proxy admin"
        );
        super._willFallback();
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./Proxy.sol";
import "../contracts/Address.sol";

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view override returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        //solium-disable-next-line
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function _setImplementation(address newImplementation) internal {
        require(
            Address.isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        //solium-disable-next-line
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Context} from "../../../dependencies/openzeppelin/contracts/Context.sol";
import {Strings} from "../../../dependencies/openzeppelin/contracts/Strings.sol";
import {Address} from "../../../dependencies/openzeppelin/contracts/Address.sol";
// TODO does this need to be updated to IERC721?
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC165} from "../../../dependencies/openzeppelin/contracts/IERC165.sol";

import {IERC721Metadata} from "../../../dependencies/openzeppelin/contracts/IERC721Metadata.sol";
import {IERC721Receiver} from "../../../dependencies/openzeppelin/contracts/IERC721Receiver.sol";
import {IERC721Enumerable} from "../../../dependencies/openzeppelin/contracts/IERC721Enumerable.sol";
import {ICollaterizableERC721} from "../../../interfaces/ICollaterizableERC721.sol";

import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {IRewardController} from "../../../interfaces/IRewardController.sol";
import {IPoolAddressesProvider} from "../../../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {IACLManager} from "../../../interfaces/IACLManager.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";

/**
 * @title MintableIncentivizedERC721
 * , inspired by the Openzeppelin ERC721 implementation
 * @notice Basic ERC721 implementation
 **/
abstract contract MintableIncentivizedERC721 is
    ICollaterizableERC721,
    Context,
    IERC721Metadata,
    IERC721Enumerable,
    IERC165
{
    using Address for address;

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    /**
     * @dev Only pool can call functions marked by this modifier.
     **/
    modifier onlyPool() {
        require(_msgSender() == address(POOL), Errors.CALLER_MUST_BE_POOL);
        _;
    }

    /**
     * @dev UserState - additionalData is a flexible field.
     * PTokens and VariableDebtTokens use this field store the index of the
     * user's last supply/withdrawal/borrow/repayment. StableDebtTokens use
     * this field to store the user's stable rate.
     */
    struct UserState {
        uint64 balance;
        uint64 collaterizedBalance;
        uint128 additionalData;
    }

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Map of users address and their state data (userAddress => userStateData)
    mapping(address => UserState) internal _userState;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Map of allowances (delegator => delegatee => allowanceAmount)
    mapping(address => mapping(address => uint256)) private _allowances;

    IRewardController internal _rewardController;
    IPoolAddressesProvider internal immutable _addressesProvider;
    IPool public immutable POOL;

    mapping(uint256 => bool) _isUsedAsCollateral;

    /**
     * @dev Constructor.
     * @param pool The reference to the main Pool contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     */
    constructor(
        IPool pool,
        string memory name,
        string memory symbol
    ) {
        _addressesProvider = pool.ADDRESSES_PROVIDER();
        _name = name;
        _symbol = symbol;
        POOL = pool;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _userState[account].balance;
    }

    /**
     * @notice Returns the address of the Incentives Controller contract
     * @return The address of the Incentives Controller
     **/
    function getIncentivesController()
        external
        view
        virtual
        returns (IRewardController)
    {
        return _rewardController;
    }

    /**
     * @notice Sets a new Incentives Controller
     * @param controller the new Incentives controller
     **/
    function setIncentivesController(IRewardController controller)
        external
        onlyPoolAdmin
    {
        _rewardController = controller;
    }

    /**
     * @notice Update the name of the token
     * @param newName The new name for the token
     */
    function _setName(string memory newName) internal {
        _name = newName;
    }

    /**
     * @notice Update the symbol for the token
     * @param newSymbol The new symbol for the token
     */
    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _owners[tokenId];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to old owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        external
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _mintMultiple(
        address to,
        DataTypes.ERC721SupplyParams[] calldata tokenData
    ) internal virtual returns (bool) {
        require(to != address(0), "ERC721: mint to the zero address");
        uint64 oldBalance = _userState[to].balance;
        uint256 oldTotalSupply = totalSupply();
        uint64 collaterizedTokens = 0;

        uint256 length = _allTokens.length;

        for (uint256 index = 0; index < tokenData.length; index++) {
            uint256 tokenId = tokenData[index].tokenId;

            require(!_exists(tokenId), "ERC721: token already minted");

            _addTokenToAllTokensEnumeration(tokenId, length + index);
            _addTokenToOwnerEnumeration(to, tokenId, oldBalance + index);

            _owners[tokenId] = to;

            if (
                tokenData[index].useAsCollateral &&
                !_isUsedAsCollateral[tokenId]
            ) {
                _isUsedAsCollateral[tokenId] = true;
                collaterizedTokens++;
            }

            emit Transfer(address(0), to, tokenId);

            // TODO check if this is needed
            require(
                _checkOnERC721Received(address(0), to, tokenId, ""),
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }

        _userState[to].collaterizedBalance += collaterizedTokens;

        _userState[to].balance = oldBalance + uint64(tokenData.length);

        // calculate incentives
        IRewardController rewardControllerLocal = _rewardController;
        if (address(rewardControllerLocal) != address(0)) {
            rewardControllerLocal.handleAction(to, oldTotalSupply, oldBalance);
        }

        return (oldBalance == 0 && collaterizedTokens != 0);
    }

    function _burnMultiple(address user, uint256[] calldata tokenIds)
        internal
        virtual
        returns (bool allCollaterizedBurnt)
    {
        uint64 burntCollaterizedTokens = 0;
        uint64 balanceToBurn;
        uint256 oldTotalSupply = totalSupply();
        uint256 oldBalance = _userState[user].balance;

        uint64 oldCollaterizedBalance = _userState[user].collaterizedBalance;

        uint256 length = _allTokens.length;

        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            address owner = ownerOf(tokenId);
            require(owner == user, "not the owner of Ntoken");

            _removeTokenFromAllTokensEnumeration(tokenId, length - index);
            _removeTokenFromOwnerEnumeration(user, tokenId, oldBalance - index);

            // Clear approvals
            _approve(address(0), tokenId);

            balanceToBurn++;
            delete _owners[tokenId];

            if (_isUsedAsCollateral[tokenId]) {
                delete _isUsedAsCollateral[tokenId];
                burntCollaterizedTokens++;
            }
            emit Transfer(owner, address(0), tokenId);

            // _afterTokenTransfer(owner, address(0), tokenId);
        }

        _userState[user].balance -= balanceToBurn;
        _userState[user].collaterizedBalance =
            oldCollaterizedBalance -
            burntCollaterizedTokens;

        // calculate incentives
        IRewardController rewardControllerLocal = _rewardController;

        if (address(rewardControllerLocal) != address(0)) {
            rewardControllerLocal.handleAction(
                user,
                oldTotalSupply,
                oldBalance
            );
        }

        return (oldCollaterizedBalance == burntCollaterizedTokens);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint64 oldSenderBalance = _userState[from].balance;
        _userState[from].balance = oldSenderBalance - 1;
        uint64 oldRecipientBalance = _userState[to].balance;
        _userState[to].balance = oldRecipientBalance + 1;

        _owners[tokenId] = to;

        // TODO calculate incentives

        IRewardController rewardControllerLocal = _rewardController;
        if (address(rewardControllerLocal) != address(0)) {
            uint256 oldTotalSupply = totalSupply();
            rewardControllerLocal.handleAction(
                from,
                oldTotalSupply,
                oldSenderBalance
            );
            if (from != to) {
                rewardControllerLocal.handleAction(
                    to,
                    oldTotalSupply,
                    oldRecipientBalance
                );
            }
        }

        emit Transfer(from, to, tokenId);

        // _afterTokenTransfer(from, to, tokenId);
        // TODO do we need _checkOnERC721Received here?
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev update collateral information on transfer
     */
    function _transferCollaterizable(
        address from,
        address to,
        uint256 tokenId,
        bool isUsedAsCollateral
    ) internal virtual {
        MintableIncentivizedERC721._transfer(from, to, tokenId);

        if (isUsedAsCollateral) {
            _userState[from].collaterizedBalance -= 1;
            _userState[to].collaterizedBalance += 1;
        }
    }

    /// @inheritdoc ICollaterizableERC721
    function collaterizedBalanceOf(address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _userState[account].collaterizedBalance;
    }

    /// @inheritdoc ICollaterizableERC721
    function setIsUsedAsCollateral(uint256 tokenId, bool useAsCollateral)
        external
        virtual
        override
        onlyPool
        returns (
            bool,
            address,
            uint256
        )
    {
        if (_isUsedAsCollateral[tokenId] == useAsCollateral)
            return (false, address(0x0), 0);

        address owner = ownerOf(tokenId);

        uint64 collaterizedBalance = _userState[owner].collaterizedBalance;

        _isUsedAsCollateral[tokenId] = useAsCollateral;
        collaterizedBalance = useAsCollateral
            ? collaterizedBalance + 1
            : collaterizedBalance - 1;
        _userState[owner].collaterizedBalance = collaterizedBalance;

        return (true, owner, collaterizedBalance);
    }

    /// @inheritdoc ICollaterizableERC721
    function isUsedAsCollateral(uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isUsedAsCollateral[tokenId];
    }

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        external
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        // super._beforeTokenTransfer(from, to, tokenId);

        // TODO remove the if (from == 0) and (to == 0) since they are handled in mint and burn already
        if (from == address(0)) {
            uint256 length = _allTokens.length;
            _addTokenToAllTokensEnumeration(tokenId, length);
        } else if (from != to) {
            uint256 userBalance = balanceOf(from);
            _removeTokenFromOwnerEnumeration(from, tokenId, userBalance);
        }
        if (to == address(0)) {
            uint256 length = _allTokens.length;
            _removeTokenFromAllTokensEnumeration(tokenId, length);
        } else if (to != from) {
            uint256 length = balanceOf(to);
            _addTokenToOwnerEnumeration(to, tokenId, length);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(
        address to,
        uint256 tokenId,
        uint256 length
    ) private {
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId, uint256 length)
        private
    {
        _allTokensIndex[tokenId] = length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 tokenId,
        uint256 userBalance
    ) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = userBalance - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(
        uint256 tokenId,
        uint256 length
    ) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
pragma solidity 0.8.10;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {MintableIncentivizedERC721} from "./MintableIncentivizedERC721.sol";

/**
 * @title ScaledBalanceTokenBase
 *
 * @notice Basic ERC721 implementation of scaled balance token
 **/
abstract contract ScaledBalanceTokenBaseERC721 is
    MintableIncentivizedERC721,
    IScaledBalanceToken
{
    using WadRayMath for uint256;
    using SafeCast for uint256;

    /**
     * @dev Constructor.
     * @param pool The reference to the main Pool contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     */
    constructor(
        IPool pool,
        string memory name,
        string memory symbol
    ) MintableIncentivizedERC721(pool, name, symbol) {
        // Intentionally left blank
    }

    /// @inheritdoc IScaledBalanceToken
    function scaledBalanceOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return balanceOf(user);
    }

    /// @inheritdoc IScaledBalanceToken
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256)
    {
        return (balanceOf(user), totalSupply());
    }

    /// @inheritdoc IScaledBalanceToken
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return totalSupply();
    }

    /// @inheritdoc IScaledBalanceToken
    function getPreviousIndex(address user)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _userState[user].additionalData;
    }

    function decimals() external view returns (uint8) {
        return 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721} from "../../dependencies/openzeppelin/contracts/IERC721.sol";
import {IERC1155} from "../../dependencies/openzeppelin/contracts/IERC1155.sol";
import {IERC721Metadata} from "../../dependencies/openzeppelin/contracts/IERC721Metadata.sol";
import {Address} from "../../dependencies/openzeppelin/contracts/Address.sol";
import {GPv2SafeERC20} from "../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {SafeCast} from "../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {VersionedInitializable} from "../libraries/paraspace-upgradeability/VersionedInitializable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {INToken} from "../../interfaces/INToken.sol";
import {IRewardController} from "../../interfaces/IRewardController.sol";
import {IInitializablePToken} from "../../interfaces/IInitializablePToken.sol";
import {ScaledBalanceTokenBaseERC721} from "./base/ScaledBalanceTokenBaseERC721.sol";
import {IncentivizedERC20} from "./base/IncentivizedERC20.sol";
import {EIP712Base} from "./base/EIP712Base.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title ParaSpace ERC20 PToken
 *
 * @notice Implementation of the interest bearing token for the ParaSpace protocol
 */
contract NToken is
    VersionedInitializable,
    ScaledBalanceTokenBaseERC721,
    EIP712Base,
    INToken
{
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 public constant NTOKEN_REVISION = 0x1;

    address internal _treasury;
    address internal _underlyingAsset;

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return NTOKEN_REVISION;
    }

    /**
     * @dev Constructor.
     * @param pool The address of the Pool contract
     */
    constructor(IPool pool)
        ScaledBalanceTokenBaseERC721(pool, "NTOKEN_IMPL", "NTOKEN_IMPL")
    {
        // Intentionally left blank
    }

    function initialize(
        IPool initializingPool,
        address treasury,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 nTokenDecimals,
        string calldata nTokenName,
        string calldata nTokenSymbol,
        bytes calldata params
    ) external override initializer {
        require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
        _setName(nTokenName);
        _setSymbol(nTokenSymbol);

        _treasury = treasury;
        _underlyingAsset = underlyingAsset;
        _rewardController = incentivesController;

        _domainSeparator = _calculateDomainSeparator();

        emit Initialized(
            underlyingAsset,
            address(POOL),
            treasury,
            address(incentivesController),
            nTokenName,
            nTokenSymbol,
            params
        );
    }

    /// @inheritdoc INToken
    function mint(
        address onBehalfOf,
        DataTypes.ERC721SupplyParams[] calldata tokenData
    ) external virtual override onlyPool returns (bool) {
        // TODO think about using safe mint instead
        return _mintMultiple(onBehalfOf, tokenData);
    }

    /// @inheritdoc INToken
    function burn(
        address from,
        address receiverOfUnderlying,
        uint256[] calldata tokenIds
    ) external virtual override onlyPool returns (bool) {
        bool withdrawingAllTokens = _burnMultiple(from, tokenIds);

        if (receiverOfUnderlying != address(this)) {
            for (uint256 index = 0; index < tokenIds.length; index++) {
                IERC721(_underlyingAsset).safeTransferFrom(
                    address(this),
                    receiverOfUnderlying,
                    tokenIds[index]
                );
            }
        }

        return withdrawingAllTokens;
    }

    // TODO do we use Treasury?
    // /// @inheritdoc INToken
    // function mintToTreasury(uint256 tokenId, uint256 index)
    //     external
    //     override
    //     onlyPool
    // {
    //     _mint(_treasury, tokenId);
    // }

    /// @inheritdoc INToken
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external override onlyPool {
        // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
        // so no need to emit a specific event here
        _transfer(from, to, value, false);
    }

    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external override onlyPoolAdmin {
        require(
            token != _underlyingAsset,
            Errors.UNDERLYING_ASSET_CAN_NOT_BE_TRANSFERRED
        );
        require(
            token != address(this),
            Errors.TOKEN_TRANSFERRED_CAN_NOT_BE_SELF_ADDRESS
        );
        IERC20(token).transfer(to, amount);
        emit ClaimERC20Airdrop(token, to, amount);
    }

    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external override onlyPoolAdmin {
        require(
            token != _underlyingAsset,
            Errors.UNDERLYING_ASSET_CAN_NOT_BE_TRANSFERRED
        );
        require(
            token != address(this),
            Errors.TOKEN_TRANSFERRED_CAN_NOT_BE_SELF_ADDRESS
        );
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(token).safeTransferFrom(address(this), to, ids[i]);
        }
        emit ClaimERC721Airdrop(token, to, ids);
    }

    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override onlyPoolAdmin {
        require(
            token != _underlyingAsset,
            Errors.UNDERLYING_ASSET_CAN_NOT_BE_TRANSFERRED
        );
        require(
            token != address(this),
            Errors.TOKEN_TRANSFERRED_CAN_NOT_BE_SELF_ADDRESS
        );
        IERC1155(token).safeBatchTransferFrom(
            address(this),
            to,
            ids,
            amounts,
            data
        );
        emit ClaimERC1155Airdrop(token, to, ids, amounts, data);
    }

    function executeAirdrop(
        address airdropContract,
        bytes calldata airdropParams
    ) external override onlyPoolAdmin {
        require(
            airdropContract != address(0),
            Errors.INVALID_AIRDROP_CONTRACT_ADDRESS
        );
        require(airdropParams.length >= 4, Errors.INVALID_AIRDROP_PARAMETERS);

        // call project airdrop contract
        Address.functionCall(
            airdropContract,
            airdropParams,
            Errors.CALL_AIRDROP_METHOD_FAILED
        );

        emit ExecuteAirdrop(airdropContract);
    }

    /// @inheritdoc INToken
    function RESERVE_TREASURY_ADDRESS()
        external
        view
        override
        returns (address)
    {
        return _treasury;
    }

    /// @inheritdoc INToken
    function UNDERLYING_ASSET_ADDRESS()
        external
        view
        override
        returns (address)
    {
        return _underlyingAsset;
    }

    /// @inheritdoc INToken
    function transferUnderlyingTo(address target, uint256 tokenId)
        external
        virtual
        override
        onlyPool
    {
        IERC721(_underlyingAsset).safeTransferFrom(
            address(this),
            target,
            tokenId
        );
    }

    /// @inheritdoc INToken
    function handleRepayment(address user, uint256 amount)
        external
        virtual
        override
        onlyPool
    {
        // Intentionally left blank
    }

    /// @inheritdoc INToken
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        //solium-disable-next-line
        require(block.timestamp <= deadline, Errors.INVALID_EXPIRATION);
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        currentValidNonce,
                        deadline
                    )
                )
            )
        );
        require(owner == ecrecover(digest, v, r, s), Errors.INVALID_SIGNATURE);
        _nonces[owner] = currentValidNonce + 1;
        _approve(spender, value);
    }

    /**
     * @notice Transfers the nTokens between two users. Validates the transfer
     * (ie checks for valid HF after the transfer) if required
     * @param from The source address
     * @param to The destination address
     * @param tokenId The amount getting transferred
     * @param validate True if the transfer needs to be validated, false otherwise
     **/
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bool validate
    ) internal {
        address underlyingAsset = _underlyingAsset;

        uint256 fromBalanceBefore = balanceOf(from);
        uint256 toBalanceBefore = balanceOf(to);

        bool isUsedAsCollateral = _isUsedAsCollateral[tokenId];
        _transferCollaterizable(from, to, tokenId, isUsedAsCollateral);

        if (validate) {
            POOL.finalizeTransfer(
                underlyingAsset,
                from,
                to,
                isUsedAsCollateral,
                tokenId,
                fromBalanceBefore,
                toBalanceBefore
            );
        }

        // emit BalanceTransfer(from, to, tokenId, index); TODO emit a transfer event
    }

    /**
     * @notice Overrides the parent _transfer to force validated transfer() and transferFrom()
     * @param from The source address
     * @param to The destination address
     * @param tokenId The token id getting transferred
     **/
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        _transfer(from, to, tokenId, true);
    }

    /**
     * @dev Overrides the base function to fully implement INToken
     * @dev see `IncentivizedERC20.DOMAIN_SEPARATOR()` for more detailed documentation
     */
    function DOMAIN_SEPARATOR()
        public
        view
        override(INToken, EIP712Base)
        returns (bytes32)
    {
        return super.DOMAIN_SEPARATOR();
    }

    /**
     * @dev Overrides the base function to fully implement INToken
     * @dev see `IncentivizedERC20.nonces()` for more detailed documentation
     */
    function nonces(address owner)
        public
        view
        override(INToken, EIP712Base)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    /// @inheritdoc EIP712Base
    function _EIP712BaseId() internal view override returns (string memory) {
        return name();
    }

    /// @inheritdoc INToken
    function rescueTokens(
        address token,
        address to,
        uint256 tokenId
    ) external override onlyPoolAdmin {
        require(token != _underlyingAsset, Errors.UNDERLYING_CANNOT_BE_RESCUED);

        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        id;
        value;
        data;
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        ids;
        values;
        data;
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return IERC721Metadata(_underlyingAsset).tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.10;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20} from "../../openzeppelin/contracts/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "GPv2: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(IERC20 token)
        private
        view
        returns (bool success)
    {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(20, "GPv2: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(31, "GPv2: malformed transfer result")
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Context} from "../../../dependencies/openzeppelin/contracts/Context.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC20Detailed} from "../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {IRewardController} from "../../../interfaces/IRewardController.sol";
import {IPoolAddressesProvider} from "../../../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {IACLManager} from "../../../interfaces/IACLManager.sol";

/**
 * @title IncentivizedERC20
 * , inspired by the Openzeppelin ERC20 implementation
 * @notice Basic ERC20 implementation
 **/
abstract contract IncentivizedERC20 is Context, IERC20Detailed {
    using WadRayMath for uint256;
    using SafeCast for uint256;

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        IACLManager aclManager = IACLManager(
            _addressesProvider.getACLManager()
        );
        require(
            aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    /**
     * @dev Only pool can call functions marked by this modifier.
     **/
    modifier onlyPool() {
        require(_msgSender() == address(POOL), Errors.CALLER_MUST_BE_POOL);
        _;
    }

    /**
     * @dev UserState - additionalData is a flexible field.
     * PTokens and VariableDebtTokens use this field store the index of the
     * user's last supply/withdrawal/borrow/repayment. StableDebtTokens use
     * this field to store the user's stable rate.
     */
    struct UserState {
        uint128 balance;
        uint128 additionalData;
    }
    // Map of users address and their state data (userAddress => userStateData)
    mapping(address => UserState) internal _userState;

    // Map of allowances (delegator => delegatee => allowanceAmount)
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    IRewardController internal _rewardController;
    IPoolAddressesProvider internal immutable _addressesProvider;
    IPool public immutable POOL;

    /**
     * @dev Constructor.
     * @param pool The reference to the main Pool contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     */
    constructor(
        IPool pool,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) {
        _addressesProvider = pool.ADDRESSES_PROVIDER();
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        POOL = pool;
    }

    /// @inheritdoc IERC20Detailed
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC20Detailed
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC20Detailed
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _userState[account].balance;
    }

    /**
     * @notice Returns the address of the Incentives Controller contract
     * @return The address of the Incentives Controller
     **/
    function getIncentivesController()
        external
        view
        virtual
        returns (IRewardController)
    {
        return _rewardController;
    }

    /**
     * @notice Sets a new Incentives Controller
     * @param controller the new Incentives controller
     **/
    function setIncentivesController(IRewardController controller)
        external
        onlyPoolAdmin
    {
        _rewardController = controller;
    }

    /// @inheritdoc IERC20
    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        uint128 castAmount = amount.toUint128();
        _transfer(_msgSender(), recipient, castAmount);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        uint128 castAmount = amount.toUint128();
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - castAmount
        );
        _transfer(sender, recipient, castAmount);
        return true;
    }

    /**
     * @notice Increases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param addedValue The amount being added to the allowance
     * @return `true`
     **/
    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @notice Decreases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param subtractedValue The amount being subtracted to the allowance
     * @return `true`
     **/
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    /**
     * @notice Transfers tokens between two users and apply incentives if defined.
     * @param sender The source address
     * @param recipient The destination address
     * @param amount The amount getting transferred
     */
    function _transfer(
        address sender,
        address recipient,
        uint128 amount
    ) internal virtual {
        uint128 oldSenderBalance = _userState[sender].balance;
        _userState[sender].balance = oldSenderBalance - amount;
        uint128 oldRecipientBalance = _userState[recipient].balance;
        _userState[recipient].balance = oldRecipientBalance + amount;

        IRewardController rewardControllerLocal = _rewardController;
        if (address(rewardControllerLocal) != address(0)) {
            uint256 currentTotalSupply = _totalSupply;
            rewardControllerLocal.handleAction(
                sender,
                currentTotalSupply,
                oldSenderBalance
            );
            if (sender != recipient) {
                rewardControllerLocal.handleAction(
                    recipient,
                    currentTotalSupply,
                    oldRecipientBalance
                );
            }
        }
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice Approve `spender` to use `amount` of `owner`s balance
     * @param owner The address owning the tokens
     * @param spender The address approved for spending
     * @param amount The amount of tokens to approve spending of
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Update the name of the token
     * @param newName The new name for the token
     */
    function _setName(string memory newName) internal {
        _name = newName;
    }

    /**
     * @notice Update the symbol for the token
     * @param newSymbol The new symbol for the token
     */
    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    /**
     * @notice Update the number of decimals for the token
     * @param newDecimals The new number of decimals for the token
     */
    function _setDecimals(uint8 newDecimals) internal {
        _decimals = newDecimals;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @title EIP712Base
 *
 * @notice Base contract implementation of EIP712.
 */
abstract contract EIP712Base {
    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // Map of address nonces (address => nonce)
    mapping(address => uint256) internal _nonces;

    bytes32 internal _domainSeparator;
    uint256 internal immutable _chainId;

    /**
     * @dev Constructor.
     */
    constructor() {
        _chainId = block.chainid;
    }

    /**
     * @notice Get the domain separator for the token
     * @dev Return cached value if chainId matches cache, otherwise recomputes separator
     * @return The domain separator of the token at current chain
     */
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        if (block.chainid == _chainId) {
            return _domainSeparator;
        }
        return _calculateDomainSeparator();
    }

    /**
     * @notice Returns the nonce value for address specified as parameter
     * @param owner The address for which the nonce is being returned
     * @return The nonce value for the input address`
     */
    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @notice Compute the current domain separator
     * @return The domain separator for the token
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN,
                    keccak256(bytes(_EIP712BaseId())),
                    keccak256(EIP712_REVISION),
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @notice Returns the user readable name of signing domain (e.g. token name)
     * @return The name of the signing domain
     */
    function _EIP712BaseId() internal view virtual returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {OwnableUpgradeable} from "../dependencies/openzeppelin/contracts/proxy/OwnableUpgradeable.sol";
import {IPool} from "../interfaces/IPool.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {DataTypesHelper} from "./libraries/DataTypesHelper.sol";

// ERC721 imports
import {IERC721} from "../dependencies/openzeppelin/contracts/IERC721.sol";
import {IERC721Receiver} from "../dependencies/openzeppelin/contracts/IERC721Receiver.sol";
import {IPunks} from "../misc/interfaces/IPunks.sol";
import {IWrappedPunks} from "../misc/interfaces/IWrappedPunks.sol";
import {IWPunkGateway} from "./interfaces/IWPunkGateway.sol";
import {INToken} from "../interfaces/INToken.sol";

contract WPunkGateway is IWPunkGateway, IERC721Receiver, OwnableUpgradeable {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IPunks internal immutable Punk;
    IWrappedPunks internal immutable WPunk;
    IPool internal immutable Pool;
    address public proxy;

    address public immutable punk;
    address public immutable wpunk;
    address public immutable pool;

    /**
     * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
     * @param _punk Address of the Punk contract
     * @param _wpunk Address of the Wrapped Punk contract
     * @param _pool Address of the proxy pool of this contract
     **/
    constructor(
        address _punk,
        address _wpunk,
        address _pool
    ) {
        punk = _punk;
        wpunk = _wpunk;
        pool = _pool;

        Punk = IPunks(punk);
        WPunk = IWrappedPunks(wpunk);
        Pool = IPool(pool);
    }

    function initialize() external initializer {
        __Ownable_init();

        // create new WPunk Proxy for PunkGateway contract
        WPunk.registerProxy();

        // address(this) = WPunkGatewayProxy
        // proxy of PunkGateway contract is the new Proxy created above
        proxy = WPunk.proxyInfo(address(this));

        WPunk.setApprovalForAll(pool, true);
    }

    /**
     * @dev supplies (deposits) WPunk into the reserve, using native Punk. A corresponding amount of the overlying asset (xTokens)
     * is minted.
     * @param pool address of the targeted underlying pool
     * @param punkIndexes punkIndexes to supply to gateway
     * @param onBehalfOf address of the user who will receive the xTokens representing the supply
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function supplyPunk(
        address pool,
        DataTypes.ERC721SupplyParams[] calldata punkIndexes,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            Punk.buyPunk(punkIndexes[i].tokenId);
            Punk.transferPunk(proxy, punkIndexes[i].tokenId);
            // gatewayProxy is the sender of this function, not the original gateway
            WPunk.mint(punkIndexes[i].tokenId);
        }

        Pool.supplyERC721(
            address(WPunk),
            punkIndexes,
            onBehalfOf,
            referralCode
        );
    }

    /**
     * @dev withdraws the WPUNK _reserves of msg.sender.
     * @param pool address of the targeted underlying pool
     * @param punkIndexes indexes of nWPunks to withdraw and receive native WPunk
     * @param to address of the user who will receive native Punks
     */
    function withdrawPunk(
        address pool,
        uint256[] calldata punkIndexes,
        address to
    ) external {
        INToken nWPunk = INToken(
            Pool.getReserveData(address(WPunk)).xTokenAddress
        );
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            nWPunk.safeTransferFrom(msg.sender, address(this), punkIndexes[i]);
        }
        Pool.withdrawERC721(address(WPunk), punkIndexes, address(this));
        for (uint256 i = 0; i < punkIndexes.length; i++) {
            WPunk.burn(punkIndexes[i]);
            Punk.transferPunk(to, punkIndexes[i]);
        }
    }

    // // gives app permission to withdraw n token
    // // permitV, permitR, permitS. passes signature parameters
    // /**
    //  * @dev withdraws the WPUNK _reserves of msg.sender.
    //  * @param pool address of the targeted underlying pool
    //  * @param punkIndexes punkIndexes of nWPunks to withdraw and receive native WPunk
    //  * @param to address of the user who will receive native Punks
    //  * @param deadline validity deadline of permit and so depositWithPermit signature
    //  * @param permitV V parameter of ERC712 permit sig
    //  * @param permitR R parameter of ERC712 permit sig
    //  * @param permitS S parameter of ERC712 permit sig
    //  */
    // function withdrawPunkWithPermit(
    //     address pool,
    //     uint256[] calldata punkIndexes,
    //     address to,
    //     uint256 deadline,
    //     uint8 permitV,
    //     bytes32 permitR,
    //     bytes32 permitS
    // ) external override {
    //     INToken nWPunk = INToken(
    //         Pool.getReserveData(address(WPunk)).xTokenAddress
    //     );

    //     for (uint256 i = 0; i < punkIndexes.length; i++) {
    //         nWPunk.permit(
    //             msg.sender,
    //             address(this),
    //             punkIndexes[i],
    //             deadline,
    //             permitV,
    //             permitR,
    //             permitS
    //         );
    //         nWPunk.safeTransferFrom(msg.sender, address(this), punkIndexes[i]);
    //     }
    //     Pool.withdrawERC721(address(WPunk), punkIndexes, address(this));
    //     for (uint256 i = 0; i < punkIndexes.length; i++) {
    //         WPunk.burn(punkIndexes[i]);
    //         Punk.transferPunk(to, punkIndexes[i]);
    //     }
    // }

    /**
     * @dev transfer ERC721 from the utility contract, for ERC721 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param from punk owner of the transfer
     * @param to recipient of the transfer
     * @param tokenId tokenId to send
     */
    function emergencyTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external onlyOwner {
        IERC721(address(WPunk)).safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev transfer native Punk from the utility contract, for native Punk recovery in case of stuck Punk
     * due selfdestructs or transfer punk to pre-computated contract address before deployment.
     * @param to recipient of the transfer
     * @param punkIndex punk to send
     */
    function emergencyPunkTransfer(address to, uint256 punkIndex)
        external
        onlyOwner
    {
        Punk.transferPunk(to, punkIndex);
    }

    /**
     * @dev Get WPunk address used by WPunkGateway
     */
    function getWPunkAddress() external view returns (address) {
        return address(WPunk);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.10;

import "./ContextUpgradeable.sol";
import "../../upgradeability/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

/**
 * @title DataTypesHelper
 *
 * @dev Helper library to track user current debt balance, used by WETHGateway
 */
library DataTypesHelper {
    /**
     * @notice Fetches the user current stable and variable debt balances
     * @param user The user address
     * @param reserve The reserve data object
     * @return The stable debt balance
     * @return The variable debt balance
     **/
    function getUserCurrentDebt(
        address user,
        DataTypes.ReserveData memory reserve
    ) internal view returns (uint256, uint256) {
        return (
            IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
            IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IPunks {
    function balanceOf(address account) external view returns (uint256);

    function punkIndexToAddress(uint256 punkIndex)
        external
        view
        returns (address owner);

    function buyPunk(uint256 punkIndex) external;

    function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IERC721} from "../../../contracts/dependencies/openzeppelin/contracts/IERC721.sol";

//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IWrappedPunks is IERC721 {
    function punkContract() external view returns (address);

    function mint(uint256 punkIndex) external;

    function burn(uint256 punkIndex) external;

    function registerProxy() external;

    function proxyInfo(address user) external returns (address proxy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

interface IWPunkGateway {
    function supplyPunk(
        address pool,
        DataTypes.ERC721SupplyParams[] calldata punkIndexes,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdrawPunk(
        address pool,
        uint256[] calldata punkIndexes,
        address to
    ) external;
}

pragma solidity ^0.8.10;
import "../../upgradeability/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../contracts/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import {IFlashClaimReceiver} from "../../../interfaces/IFlashClaimReceiver.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";
import {ValidationLogic} from "./ValidationLogic.sol";

library FlashClaimLogic {
    // See `IPool` for descriptions
    event FlashClaim(
        address indexed target,
        address indexed initiator,
        address indexed nftAsset,
        uint256 tokenId
    );

    function executeFlashClaim(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.ExecuteFlashClaimParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.nftAsset];
        ValidationLogic.validateFlashClaim(reserve, params);

        uint256 i;
        // step 1: moving underlying asset forward to receiver contract
        for (i = 0; i < params.nftTokenIds.length; i++) {
            INToken(reserve.xTokenAddress).transferUnderlyingTo(
                params.receiverAddress,
                params.nftTokenIds[i]
            );
        }

        // step 2: execute receiver contract, doing something like airdrop
        require(
            IFlashClaimReceiver(params.receiverAddress).executeOperation(
                params.nftAsset,
                params.nftTokenIds,
                params.params
            ),
            Errors.INVALID_FLASH_CLAIM_RECEIVER
        );

        // step 3: moving underlying asset backward from receiver contract
        for (i = 0; i < params.nftTokenIds.length; i++) {
            IERC721(params.nftAsset).safeTransferFrom(
                params.receiverAddress,
                reserve.xTokenAddress,
                params.nftTokenIds[i]
            );

            emit FlashClaim(
                params.receiverAddress,
                msg.sender,
                params.nftAsset,
                params.nftTokenIds[i]
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title IFlashClaimReceiver interface
 * @notice Interface for the IFlashClaimReceiver.
 * @author ParaSpace
 * @dev implement this interface to develop a flashclaim-compatible flashclaimReceiver contract
 **/
interface IFlashClaimReceiver {
    function executeOperation(
        address asset,
        uint256[] calldata tokenIds,
        bytes calldata params
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {Address} from "../../../dependencies/openzeppelin/contracts/Address.sol";
import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {IStableDebtToken} from "../../../interfaces/IStableDebtToken.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {ICollaterizableERC721} from "../../../interfaces/ICollaterizableERC721.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {IPriceOracleSentinel} from "../../../interfaces/IPriceOracleSentinel.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {IToken} from "../../../interfaces/IToken.sol";

/**
 * @title ReserveLogic library
 *
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    // Factor to apply to "only-variable-debt" liquidity rate to get threshold for rebalancing, expressed in bps
    // A value of 0.9e4 results in 90%
    uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 0.9e4;

    // Minimum health factor allowed under any circumstance
    // A value of 0.95e18 results in 0.95
    uint256 public constant MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD =
        0.95e18;

    /**
     * @dev Minimum health factor to consider a user position healthy
     * A value of 1e18 results in 1
     */
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18;

    /**
     * @notice Validates a supply action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be supplied
     */
    function validateSupply(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amount,
        DataTypes.AssetType assetType
    ) internal view {
        require(amount != 0, Errors.INVALID_AMOUNT);
        require(reserveCache.assetType == assetType, Errors.INVALID_ASSET_TYPE);

        (bool isActive, bool isFrozen, , , bool isPaused) = reserveCache
            .reserveConfiguration
            .getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(!isFrozen, Errors.RESERVE_FROZEN);

        uint256 supplyCap = reserveCache.reserveConfiguration.getSupplyCap();

        if (assetType == DataTypes.AssetType.ERC20) {
            require(
                supplyCap == 0 ||
                    (IPToken(reserveCache.xTokenAddress)
                        .scaledTotalSupply()
                        .rayMul(reserveCache.nextLiquidityIndex) + amount) <=
                    supplyCap *
                        (10**reserveCache.reserveConfiguration.getDecimals()),
                Errors.SUPPLY_CAP_EXCEEDED
            );
        } else if (assetType == DataTypes.AssetType.ERC721) {
            require(
                supplyCap == 0 ||
                    (INToken(reserveCache.xTokenAddress).totalSupply() +
                        amount <=
                        supplyCap),
                Errors.SUPPLY_CAP_EXCEEDED
            );
        }
    }

    /**
     * @notice Validates a withdraw action.
     * @param reserveCache The cached data of the reserve
     * @param amount The amount to be withdrawn
     * @param userBalance The balance of the user
     */
    function validateWithdraw(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amount,
        uint256 userBalance
    ) internal pure {
        require(amount != 0, Errors.INVALID_AMOUNT);
        require(
            reserveCache.assetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );

        require(
            amount <= userBalance,
            Errors.NOT_ENOUGH_AVAILABLE_USER_BALANCE
        );

        (bool isActive, , , , bool isPaused) = reserveCache
            .reserveConfiguration
            .getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    function validateWithdrawERC721(DataTypes.ReserveCache memory reserveCache)
        internal
        pure
    {
        require(
            reserveCache.assetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );
        (bool isActive, , , , bool isPaused) = reserveCache
            .reserveConfiguration
            .getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 collateralNeededInBaseCurrency;
        uint256 userCollateralInBaseCurrency;
        uint256 userDebtInBaseCurrency;
        uint256 availableLiquidity;
        uint256 healthFactor;
        uint256 totalDebt;
        uint256 totalSupplyVariableDebt;
        uint256 reserveDecimals;
        uint256 borrowCap;
        uint256 amountInBaseCurrency;
        uint256 assetUnit;
        address siloedBorrowingAddress;
        bool isActive;
        bool isFrozen;
        bool isPaused;
        bool borrowingEnabled;
        bool stableRateBorrowingEnabled;
        bool siloedBorrowingEnabled;
    }

    /**
     * @notice Validates a borrow action.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional params needed for the validation
     */
    function validateBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.ValidateBorrowParams memory params
    ) internal view {
        require(params.amount != 0, Errors.INVALID_AMOUNT);
        require(
            params.assetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
        ValidateBorrowLocalVars memory vars;

        (
            vars.isActive,
            vars.isFrozen,
            vars.borrowingEnabled,
            vars.stableRateBorrowingEnabled,
            vars.isPaused
        ) = params.reserveCache.reserveConfiguration.getFlags();

        require(vars.isActive, Errors.RESERVE_INACTIVE);
        require(!vars.isPaused, Errors.RESERVE_PAUSED);
        require(!vars.isFrozen, Errors.RESERVE_FROZEN);
        require(vars.borrowingEnabled, Errors.BORROWING_NOT_ENABLED);

        require(
            params.priceOracleSentinel == address(0) ||
                IPriceOracleSentinel(params.priceOracleSentinel)
                    .isBorrowAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        //validate interest rate mode
        require(
            params.interestRateMode == DataTypes.InterestRateMode.VARIABLE ||
                params.interestRateMode == DataTypes.InterestRateMode.STABLE,
            Errors.INVALID_INTEREST_RATE_MODE_SELECTED
        );

        vars.reserveDecimals = params
            .reserveCache
            .reserveConfiguration
            .getDecimals();
        vars.borrowCap = params
            .reserveCache
            .reserveConfiguration
            .getBorrowCap();
        unchecked {
            vars.assetUnit = 10**vars.reserveDecimals;
        }

        if (vars.borrowCap != 0) {
            vars.totalSupplyVariableDebt = params
                .reserveCache
                .currScaledVariableDebt
                .rayMul(params.reserveCache.nextVariableBorrowIndex);

            vars.totalDebt =
                params.reserveCache.currTotalStableDebt +
                vars.totalSupplyVariableDebt +
                params.amount;

            unchecked {
                require(
                    vars.totalDebt <= vars.borrowCap * vars.assetUnit,
                    Errors.BORROW_CAP_EXCEEDED
                );
            }
        }

        (
            vars.userCollateralInBaseCurrency,
            ,
            vars.userDebtInBaseCurrency,
            vars.currentLtv,
            ,
            ,
            ,
            vars.healthFactor,
            ,

        ) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: params.userConfig,
                reservesCount: params.reservesCount,
                user: params.userAddress,
                oracle: params.oracle
            })
        );

        require(
            vars.userCollateralInBaseCurrency != 0,
            Errors.COLLATERAL_BALANCE_IS_ZERO
        );
        require(vars.currentLtv != 0, Errors.LTV_VALIDATION_FAILED);

        require(
            vars.healthFactor > HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        vars.amountInBaseCurrency =
            IPriceOracleGetter(params.oracle).getAssetPrice(params.asset) *
            params.amount;
        unchecked {
            vars.amountInBaseCurrency /= vars.assetUnit;
        }

        //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
        vars.collateralNeededInBaseCurrency = (vars.userDebtInBaseCurrency +
            vars.amountInBaseCurrency).percentDiv(vars.currentLtv); //LTV is calculated in percentage

        require(
            vars.collateralNeededInBaseCurrency <=
                vars.userCollateralInBaseCurrency,
            Errors.COLLATERAL_CANNOT_COVER_NEW_BORROW
        );

        /**
         * Following conditions need to be met if the user is borrowing at a stable rate:
         * 1. Reserve must be enabled for stable rate borrowing
         * 2. Users cannot borrow from the reserve if their collateral is (mostly) the same currency
         *    they are borrowing, to prevent abuses.
         * 3. Users will be able to borrow only a portion of the total available liquidity
         **/

        if (params.interestRateMode == DataTypes.InterestRateMode.STABLE) {
            //check if the borrow mode is stable and if stable rate borrowing is enabled on this reserve

            require(
                vars.stableRateBorrowingEnabled,
                Errors.STABLE_BORROWING_NOT_ENABLED
            );

            require(
                !params.userConfig.isUsingAsCollateral(
                    reservesData[params.asset].id
                ) ||
                    params.reserveCache.reserveConfiguration.getLtv() == 0 ||
                    params.amount >
                    IToken(params.reserveCache.xTokenAddress).balanceOf(
                        params.userAddress
                    ),
                Errors.COLLATERAL_SAME_AS_BORROWING_CURRENCY
            );

            vars.availableLiquidity = IToken(params.asset).balanceOf(
                params.reserveCache.xTokenAddress
            );

            //calculate the max available loan size in stable rate mode as a percentage of the
            //available liquidity
            uint256 maxLoanSizeStable = vars.availableLiquidity.percentMul(
                params.maxStableLoanPercent
            );

            require(
                params.amount <= maxLoanSizeStable,
                Errors.AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE
            );
        }
    }

    /**
     * @notice Validates a repay action.
     * @param reserveCache The cached data of the reserve
     * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
     * @param interestRateMode The interest rate mode of the debt being repaid
     * @param onBehalfOf The address of the user msg.sender is repaying for
     * @param stableDebt The borrow balance of the user
     * @param variableDebt The borrow balance of the user
     */
    function validateRepay(
        DataTypes.ReserveCache memory reserveCache,
        uint256 amountSent,
        DataTypes.InterestRateMode interestRateMode,
        address onBehalfOf,
        uint256 stableDebt,
        uint256 variableDebt
    ) internal view {
        require(amountSent != 0, Errors.INVALID_AMOUNT);
        require(
            amountSent != type(uint256).max || msg.sender == onBehalfOf,
            Errors.NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
        );

        (bool isActive, , , , bool isPaused) = reserveCache
            .reserveConfiguration
            .getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);

        uint256 variableDebtPreviousIndex = IScaledBalanceToken(
            reserveCache.variableDebtTokenAddress
        ).getPreviousIndex(onBehalfOf);

        uint40 stableRatePreviousTimestamp = IStableDebtToken(
            reserveCache.stableDebtTokenAddress
        ).getUserLastUpdated(onBehalfOf);

        require(
            (stableRatePreviousTimestamp < uint40(block.timestamp) &&
                interestRateMode == DataTypes.InterestRateMode.STABLE) ||
                (variableDebtPreviousIndex <
                    reserveCache.nextVariableBorrowIndex &&
                    interestRateMode == DataTypes.InterestRateMode.VARIABLE),
            Errors.SAME_BLOCK_BORROW_REPAY
        );

        require(
            (stableDebt != 0 &&
                interestRateMode == DataTypes.InterestRateMode.STABLE) ||
                (variableDebt != 0 &&
                    interestRateMode == DataTypes.InterestRateMode.VARIABLE),
            Errors.NO_DEBT_OF_SELECTED_TYPE
        );
    }

    /**
     * @notice Validates a swap of borrow rate mode.
     * @param reserve The reserve state on which the user is swapping the rate
     * @param reserveCache The cached data of the reserve
     * @param userConfig The user reserves configuration
     * @param stableDebt The stable debt of the user
     * @param variableDebt The variable debt of the user
     * @param currentRateMode The rate mode of the debt being swapped
     */
    function validateSwapRateMode(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache,
        DataTypes.UserConfigurationMap storage userConfig,
        uint256 stableDebt,
        uint256 variableDebt,
        DataTypes.InterestRateMode currentRateMode
    ) internal view {
        (
            bool isActive,
            bool isFrozen,
            ,
            bool stableRateEnabled,
            bool isPaused
        ) = reserveCache.reserveConfiguration.getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
        require(!isFrozen, Errors.RESERVE_FROZEN);

        if (currentRateMode == DataTypes.InterestRateMode.STABLE) {
            require(stableDebt != 0, Errors.NO_OUTSTANDING_STABLE_DEBT);
        } else if (currentRateMode == DataTypes.InterestRateMode.VARIABLE) {
            require(variableDebt != 0, Errors.NO_OUTSTANDING_VARIABLE_DEBT);
            /**
             * user wants to swap to stable, before swapping we need to ensure that
             * 1. stable borrow rate is enabled on the reserve
             * 2. user is not trying to abuse the reserve by supplying
             * more collateral than he is borrowing, artificially lowering
             * the interest rate, borrowing at variable, and switching to stable
             **/
            require(stableRateEnabled, Errors.STABLE_BORROWING_NOT_ENABLED);

            require(
                !userConfig.isUsingAsCollateral(reserve.id) ||
                    reserveCache.reserveConfiguration.getLtv() == 0 ||
                    stableDebt + variableDebt >
                    IToken(reserveCache.xTokenAddress).balanceOf(msg.sender),
                Errors.COLLATERAL_SAME_AS_BORROWING_CURRENCY
            );
        } else {
            revert(Errors.INVALID_INTEREST_RATE_MODE_SELECTED);
        }
    }

    /**
     * @notice Validates a stable borrow rate rebalance action.
     * @dev Rebalancing is accepted when depositors are earning <= 90% of their earnings in pure supply/demand market (variable rate only)
     * For this to be the case, there has to be quite large stable debt with an interest rate below the current variable rate.
     * @param reserve The reserve state on which the user is getting rebalanced
     * @param reserveCache The cached state of the reserve
     * @param reserveAddress The address of the reserve
     */
    function validateRebalanceStableBorrowRate(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache,
        address reserveAddress
    ) internal view {
        (bool isActive, , , , bool isPaused) = reserveCache
            .reserveConfiguration
            .getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);

        uint256 totalDebt = IToken(reserveCache.stableDebtTokenAddress)
            .totalSupply() +
            IToken(reserveCache.variableDebtTokenAddress).totalSupply();

        (
            uint256 liquidityRateVariableDebtOnly,
            ,

        ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress)
                .calculateInterestRates(
                    DataTypes.CalculateInterestRatesParams({
                        liquidityAdded: 0,
                        liquidityTaken: 0,
                        totalStableDebt: 0,
                        totalVariableDebt: totalDebt,
                        averageStableBorrowRate: 0,
                        reserveFactor: reserveCache.reserveFactor,
                        reserve: reserveAddress,
                        xToken: reserveCache.xTokenAddress
                    })
                );

        require(
            reserveCache.currLiquidityRate <=
                liquidityRateVariableDebtOnly.percentMul(
                    REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD
                ),
            Errors.INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET
        );
    }

    /**
     * @notice Validates the action of setting an asset as collateral.
     * @param reserveCache The cached data of the reserve
     * @param userBalance The balance of the user
     */
    function validateSetUseReserveAsCollateral(
        DataTypes.ReserveCache memory reserveCache,
        uint256 userBalance
    ) internal pure {
        require(userBalance != 0, Errors.UNDERLYING_BALANCE_ZERO);

        (bool isActive, , , , bool isPaused) = reserveCache
            .reserveConfiguration
            .getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    function validateSetUseERC721AsCollateral(
        DataTypes.ReserveCache memory reserveCache,
        address sender,
        address owner
    ) internal pure {
        require(sender == owner, Errors.NOT_THE_OWNER);
        (bool isActive, , , , bool isPaused) = reserveCache
            .reserveConfiguration
            .getFlags();
        require(isActive, Errors.RESERVE_INACTIVE);
        require(!isPaused, Errors.RESERVE_PAUSED);
    }

    struct ValidateLiquidationCallLocalVars {
        bool collateralReserveActive;
        bool collateralReservePaused;
        bool principalReserveActive;
        bool principalReservePaused;
        bool isCollateralEnabled;
    }

    /**
     * @notice Validates the liquidation action.
     * @param userConfig The user configuration mapping
     * @param collateralReserve The reserve data of the collateral
     * @param params Additional parameters needed for the validation
     */
    function validateLiquidationCall(
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateLiquidationCallParams memory params
    ) internal view {
        require(
            params.assetType == DataTypes.AssetType.ERC20,
            Errors.INVALID_ASSET_TYPE
        );
        ValidateLiquidationCallLocalVars memory vars;

        (
            vars.collateralReserveActive,
            ,
            ,
            ,
            vars.collateralReservePaused
        ) = collateralReserve.configuration.getFlags();

        (
            vars.principalReserveActive,
            ,
            ,
            ,
            vars.principalReservePaused
        ) = params.debtReserveCache.reserveConfiguration.getFlags();

        require(
            vars.collateralReserveActive && vars.principalReserveActive,
            Errors.RESERVE_INACTIVE
        );
        require(
            !vars.collateralReservePaused && !vars.principalReservePaused,
            Errors.RESERVE_PAUSED
        );

        require(
            params.priceOracleSentinel == address(0) ||
                params.healthFactor <
                MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
                IPriceOracleSentinel(params.priceOracleSentinel)
                    .isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        require(
            params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_NOT_BELOW_THRESHOLD
        );

        vars.isCollateralEnabled =
            collateralReserve.configuration.getLiquidationThreshold() != 0 &&
            userConfig.isUsingAsCollateral(collateralReserve.id);

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(
            vars.isCollateralEnabled,
            Errors.COLLATERAL_CANNOT_BE_LIQUIDATED
        );
        require(
            params.totalDebt != 0,
            Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
        );
    }

    /**
     * @notice Validates the liquidation action.
     * @param userConfig The user configuration mapping
     * @param collateralReserve The reserve data of the collateral
     * @param params Additional parameters needed for the validation
     */
    function validateERC721LiquidationCall(
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ValidateERC721LiquidationCallParams memory params
    ) internal view {
        require(
            params.assetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );

        ValidateLiquidationCallLocalVars memory vars;

        (
            vars.collateralReserveActive,
            ,
            ,
            ,
            vars.collateralReservePaused
        ) = collateralReserve.configuration.getFlags();

        (
            vars.principalReserveActive,
            ,
            ,
            ,
            vars.principalReservePaused
        ) = params.debtReserveCache.reserveConfiguration.getFlags();

        require(
            vars.collateralReserveActive && vars.principalReserveActive,
            Errors.RESERVE_INACTIVE
        );
        require(
            !vars.collateralReservePaused && !vars.principalReservePaused,
            Errors.RESERVE_PAUSED
        );

        require(
            params.priceOracleSentinel == address(0) ||
                params.healthFactor <
                MINIMUM_HEALTH_FACTOR_LIQUIDATION_THRESHOLD ||
                IPriceOracleSentinel(params.priceOracleSentinel)
                    .isLiquidationAllowed(),
            Errors.PRICE_ORACLE_SENTINEL_CHECK_FAILED
        );

        require(
            params.healthFactor < HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.ERC721_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
        );

        require(
            params.liquidationAmount >= params.collateralDiscountedPrice,
            Errors.LIQUIDATION_AMOUNT_NOT_ENOUGH
        );

        vars.isCollateralEnabled =
            collateralReserve.configuration.getLiquidationThreshold() != 0 &&
            userConfig.isUsingAsCollateral(collateralReserve.id) &&
            ICollaterizableERC721(params.xTokenAddress).isUsedAsCollateral(
                params.tokenId
            );

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(
            vars.isCollateralEnabled,
            Errors.COLLATERAL_CANNOT_BE_LIQUIDATED
        );
        require(
            params.totalDebt != 0,
            Errors.SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
        );
    }

    /**
     * @notice Validates the health factor of a user.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param user The user to validate health factor of
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHealthFactor(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap memory userConfig,
        address user,
        uint256 reservesCount,
        address oracle
    ) internal view returns (uint256, bool) {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 healthFactor,
            ,
            bool hasZeroLtvCollateral
        ) = GenericLogic.calculateUserAccountData(
                reservesData,
                reservesList,
                DataTypes.CalculateUserAccountDataParams({
                    userConfig: userConfig,
                    reservesCount: reservesCount,
                    user: user,
                    oracle: oracle
                })
            );

        require(
            healthFactor >= HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        return (healthFactor, hasZeroLtvCollateral);
    }

    /**
     * @notice Validates the health factor of a user and the ltv of the asset being withdrawn.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The state of the user for the specific reserve
     * @param asset The asset for which the ltv will be validated
     * @param from The user from which the xTokens are being transferred
     * @param reservesCount The number of available reserves
     * @param oracle The price oracle
     */
    function validateHFAndLtv(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap memory userConfig,
        address asset,
        address from,
        uint256 reservesCount,
        address oracle
    ) internal view {
        DataTypes.ReserveData memory reserve = reservesData[asset];

        (, bool hasZeroLtvCollateral) = validateHealthFactor(
            reservesData,
            reservesList,
            userConfig,
            from,
            reservesCount,
            oracle
        );

        require(
            !hasZeroLtvCollateral || reserve.configuration.getLtv() == 0,
            Errors.LTV_VALIDATION_FAILED
        );
    }

    /**
     * @notice Validates a transfer action.
     * @param reserve The reserve object
     */
    function validateTransfer(DataTypes.ReserveData storage reserve)
        internal
        view
    {
        require(!reserve.configuration.getPaused(), Errors.RESERVE_PAUSED);
    }

    /**
     * @notice Validates a drop reserve action.
     * @param reservesList The addresses of all the active reserves
     * @param reserve The reserve object
     * @param asset The address of the reserve's underlying asset
     **/
    function validateDropReserve(
        mapping(uint256 => address) storage reservesList,
        DataTypes.ReserveData storage reserve,
        address asset
    ) internal view {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            reserve.id != 0 || reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        require(
            IToken(reserve.stableDebtTokenAddress).totalSupply() == 0,
            Errors.STABLE_DEBT_NOT_ZERO
        );
        require(
            IToken(reserve.variableDebtTokenAddress).totalSupply() == 0,
            Errors.VARIABLE_DEBT_SUPPLY_NOT_ZERO
        );
        require(
            IToken(reserve.xTokenAddress).totalSupply() == 0,
            Errors.XTOKEN_SUPPLY_NOT_ZERO
        );
    }

    /**
     * @notice Validates a flash claim.
     * @param reserve The reserve object
     * @param params The flash claim params
     */
    function validateFlashClaim(
        DataTypes.ReserveData storage reserve,
        DataTypes.ExecuteFlashClaimParams memory params
    ) internal view {
        require(
            reserve.assetType == DataTypes.AssetType.ERC721,
            Errors.INVALID_ASSET_TYPE
        );
        require(
            params.receiverAddress != address(0),
            Errors.ZERO_ADDRESS_NOT_VALID
        );

        // only token owner can do flash claim
        for (uint256 i = 0; i < params.nftTokenIds.length; i++) {
            require(
                INToken(reserve.xTokenAddress).ownerOf(params.nftTokenIds[i]) ==
                    msg.sender,
                Errors.NOT_THE_OWNER
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IPriceOracleSentinel
 *
 * @notice Defines the basic interface for the PriceOracleSentinel
 */
interface IPriceOracleSentinel {
    /**
     * @dev Emitted after the sequencer oracle is updated
     * @param newSequencerOracle The new sequencer oracle
     */
    event SequencerOracleUpdated(address newSequencerOracle);

    /**
     * @dev Emitted after the grace period is updated
     * @param newGracePeriod The new grace period value
     */
    event GracePeriodUpdated(uint256 newGracePeriod);

    /**
     * @notice Returns the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Returns true if the `borrow` operation is allowed.
     * @dev Operation not allowed when PriceOracle is down or grace period not passed.
     * @return True if the `borrow` operation is allowed, false otherwise.
     */
    function isBorrowAllowed() external view returns (bool);

    /**
     * @notice Returns true if the `liquidation` operation is allowed.
     * @dev Operation not allowed when PriceOracle is down or grace period not passed.
     * @return True if the `liquidation` operation is allowed, false otherwise.
     */
    function isLiquidationAllowed() external view returns (bool);

    /**
     * @notice Updates the address of the sequencer oracle
     * @param newSequencerOracle The address of the new Sequencer Oracle to use
     */
    function setSequencerOracle(address newSequencerOracle) external;

    /**
     * @notice Updates the duration of the grace period
     * @param newGracePeriod The value of the new grace period duration
     */
    function setGracePeriod(uint256 newGracePeriod) external;

    /**
     * @notice Returns the SequencerOracle
     * @return The address of the sequencer oracle contract
     */
    function getSequencerOracle() external view returns (address);

    /**
     * @notice Returns the grace period
     * @return The duration of the grace period
     */
    function getGracePeriod() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {IStableDebtToken} from "../../../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IReserveInterestRateStrategy} from "../../../interfaces/IReserveInterestRateStrategy.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";

/**
 * @title ReserveLogic library
 *
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeCast for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    // See `IPool` for descriptions
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @notice Returns the ongoing normalized income for the reserve.
     * @dev A value of 1e27 means there is no income. As time passes, the income is accrued
     * @dev A value of 2*1e27 means for each unit of asset one unit of income has been accrued
     * @param reserve The reserve object
     * @return The normalized income, expressed in ray
     **/
    function getNormalizedIncome(DataTypes.ReserveData storage reserve)
        internal
        view
        returns (uint256)
    {
        uint40 timestamp = reserve.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == block.timestamp) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.liquidityIndex;
        } else {
            return
                MathUtils
                    .calculateLinearInterest(
                        reserve.currentLiquidityRate,
                        timestamp
                    )
                    .rayMul(reserve.liquidityIndex);
        }
    }

    /**
     * @notice Returns the ongoing normalized variable debt for the reserve.
     * @dev A value of 1e27 means there is no debt. As time passes, the debt is accrued
     * @dev A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
     * @param reserve The reserve object
     * @return The normalized variable debt, expressed in ray
     **/
    function getNormalizedDebt(DataTypes.ReserveData storage reserve)
        internal
        view
        returns (uint256)
    {
        uint40 timestamp = reserve.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == block.timestamp) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.variableBorrowIndex;
        } else {
            return
                MathUtils
                    .calculateCompoundedInterest(
                        reserve.currentVariableBorrowRate,
                        timestamp
                    )
                    .rayMul(reserve.variableBorrowIndex);
        }
    }

    /**
     * @notice Updates the liquidity cumulative index and the variable borrow index.
     * @param reserve The reserve object
     * @param reserveCache The caching layer for the reserve data
     **/
    function updateState(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache
    ) internal {
        _updateIndexes(reserve, reserveCache);
        _accrueToTreasury(reserve, reserveCache);
    }

    /**
     * @notice Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example
     * to accumulate the flashloan fee to the reserve, and spread it between all the suppliers.
     * @param reserve The reserve object
     * @param totalLiquidity The total liquidity available in the reserve
     * @param amount The amount to accumulate
     * @return The next liquidity index of the reserve
     **/
    function cumulateToLiquidityIndex(
        DataTypes.ReserveData storage reserve,
        uint256 totalLiquidity,
        uint256 amount
    ) internal returns (uint256) {
        //next liquidity index is calculated this way: `((amount / totalLiquidity) + 1) * liquidityIndex`
        //division `amount / totalLiquidity` done in ray for precision
        uint256 result = (amount.wadToRay().rayDiv(totalLiquidity.wadToRay()) +
            WadRayMath.RAY).rayMul(reserve.liquidityIndex);
        reserve.liquidityIndex = result.toUint128();
        return result;
    }

    /**
     * @notice Initializes a reserve.
     * @param reserve The reserve object
     * @param xTokenAddress The address of the overlying xtoken contract
     * @param stableDebtTokenAddress The address of the overlying stable debt token contract
     * @param variableDebtTokenAddress The address of the overlying variable debt token contract
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     **/
    function init(
        DataTypes.ReserveData storage reserve,
        address xTokenAddress,
        DataTypes.AssetType assetType,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress,
        address interestRateStrategyAddress
    ) internal {
        require(
            reserve.xTokenAddress == address(0),
            Errors.RESERVE_ALREADY_INITIALIZED
        );

        reserve.liquidityIndex = uint128(WadRayMath.RAY);
        reserve.variableBorrowIndex = uint128(WadRayMath.RAY);
        reserve.xTokenAddress = xTokenAddress;
        reserve.assetType = assetType;
        reserve.stableDebtTokenAddress = stableDebtTokenAddress;
        reserve.variableDebtTokenAddress = variableDebtTokenAddress;
        reserve.interestRateStrategyAddress = interestRateStrategyAddress;
    }

    struct UpdateInterestRatesLocalVars {
        uint256 nextLiquidityRate;
        uint256 nextStableRate;
        uint256 nextVariableRate;
        uint256 totalVariableDebt;
    }

    /**
     * @notice Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate.
     * @param reserve The reserve reserve to be updated
     * @param reserveCache The caching layer for the reserve data
     * @param reserveAddress The address of the reserve to be updated
     * @param liquidityAdded The amount of liquidity added to the protocol (supply or repay) in the previous action
     * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
     **/
    function updateInterestRates(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache,
        address reserveAddress,
        uint256 liquidityAdded,
        uint256 liquidityTaken
    ) internal {
        UpdateInterestRatesLocalVars memory vars;

        vars.totalVariableDebt = reserveCache.nextScaledVariableDebt.rayMul(
            reserveCache.nextVariableBorrowIndex
        );

        (
            vars.nextLiquidityRate,
            vars.nextStableRate,
            vars.nextVariableRate
        ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress)
            .calculateInterestRates(
                DataTypes.CalculateInterestRatesParams({
                    liquidityAdded: liquidityAdded,
                    liquidityTaken: liquidityTaken,
                    totalStableDebt: reserveCache.nextTotalStableDebt,
                    totalVariableDebt: vars.totalVariableDebt,
                    averageStableBorrowRate: reserveCache
                        .nextAvgStableBorrowRate,
                    reserveFactor: reserveCache.reserveFactor,
                    reserve: reserveAddress,
                    xToken: reserveCache.xTokenAddress
                })
            );

        reserve.currentLiquidityRate = vars.nextLiquidityRate.toUint128();
        reserve.currentStableBorrowRate = vars.nextStableRate.toUint128();
        reserve.currentVariableBorrowRate = vars.nextVariableRate.toUint128();

        emit ReserveDataUpdated(
            reserveAddress,
            vars.nextLiquidityRate,
            vars.nextStableRate,
            vars.nextVariableRate,
            reserveCache.nextLiquidityIndex,
            reserveCache.nextVariableBorrowIndex
        );
    }

    struct AccrueToTreasuryLocalVars {
        uint256 prevTotalStableDebt;
        uint256 prevTotalVariableDebt;
        uint256 currTotalVariableDebt;
        uint256 cumulatedStableInterest;
        uint256 totalDebtAccrued;
        uint256 amountToMint;
    }

    /**
     * @notice Mints part of the repaid interest to the reserve treasury as a function of the reserve factor for the
     * specific asset.
     * @param reserve The reserve to be updated
     * @param reserveCache The caching layer for the reserve data
     **/
    function _accrueToTreasury(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache
    ) internal {
        AccrueToTreasuryLocalVars memory vars;

        if (reserveCache.reserveFactor == 0) {
            return;
        }

        //calculate the total variable debt at moment of the last interaction
        vars.prevTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
            reserveCache.currVariableBorrowIndex
        );

        //calculate the new total variable debt after accumulation of the interest on the index
        vars.currTotalVariableDebt = reserveCache.currScaledVariableDebt.rayMul(
            reserveCache.nextVariableBorrowIndex
        );

        //calculate the stable debt until the last timestamp update
        vars.cumulatedStableInterest = MathUtils.calculateCompoundedInterest(
            reserveCache.currAvgStableBorrowRate,
            reserveCache.stableDebtLastUpdateTimestamp,
            reserveCache.reserveLastUpdateTimestamp
        );

        vars.prevTotalStableDebt = reserveCache.currPrincipalStableDebt.rayMul(
            vars.cumulatedStableInterest
        );

        //debt accrued is the sum of the current debt minus the sum of the debt at the last update
        vars.totalDebtAccrued =
            vars.currTotalVariableDebt +
            reserveCache.currTotalStableDebt -
            vars.prevTotalVariableDebt -
            vars.prevTotalStableDebt;

        vars.amountToMint = vars.totalDebtAccrued.percentMul(
            reserveCache.reserveFactor
        );

        if (vars.amountToMint != 0) {
            reserve.accruedToTreasury += vars
                .amountToMint
                .rayDiv(reserveCache.nextLiquidityIndex)
                .toUint128();
        }
    }

    /**
     * @notice Updates the reserve indexes and the timestamp of the update.
     * @param reserve The reserve reserve to be updated
     * @param reserveCache The cache layer holding the cached protocol data
     **/
    function _updateIndexes(
        DataTypes.ReserveData storage reserve,
        DataTypes.ReserveCache memory reserveCache
    ) internal {
        reserveCache.nextLiquidityIndex = reserveCache.currLiquidityIndex;
        reserveCache.nextVariableBorrowIndex = reserveCache
            .currVariableBorrowIndex;

        //only cumulating if there is any income being produced
        if (reserveCache.currLiquidityRate != 0) {
            uint256 cumulatedLiquidityInterest = MathUtils
                .calculateLinearInterest(
                    reserveCache.currLiquidityRate,
                    reserveCache.reserveLastUpdateTimestamp
                );
            reserveCache.nextLiquidityIndex = cumulatedLiquidityInterest.rayMul(
                reserveCache.currLiquidityIndex
            );
            reserve.liquidityIndex = reserveCache
                .nextLiquidityIndex
                .toUint128();

            //as the liquidity rate might come only from stable rate loans, we need to ensure
            //that there is actual variable debt before accumulating
            if (reserveCache.currScaledVariableDebt != 0) {
                uint256 cumulatedVariableBorrowInterest = MathUtils
                    .calculateCompoundedInterest(
                        reserveCache.currVariableBorrowRate,
                        reserveCache.reserveLastUpdateTimestamp
                    );
                reserveCache
                    .nextVariableBorrowIndex = cumulatedVariableBorrowInterest
                    .rayMul(reserveCache.currVariableBorrowIndex);
                reserve.variableBorrowIndex = reserveCache
                    .nextVariableBorrowIndex
                    .toUint128();
            }
        }

        //solium-disable-next-line
        reserve.lastUpdateTimestamp = uint40(block.timestamp);
    }

    /**
     * @notice Creates a cache object to avoid repeated storage reads and external contract calls when updating state and
     * interest rates.
     * @param reserve The reserve object for which the cache will be filled
     * @return The cache object
     */
    function cache(DataTypes.ReserveData storage reserve)
        internal
        view
        returns (DataTypes.ReserveCache memory)
    {
        DataTypes.ReserveCache memory reserveCache;

        reserveCache.reserveConfiguration = reserve.configuration;
        reserveCache.assetType = reserve.assetType;
        reserveCache.reserveFactor = reserveCache
            .reserveConfiguration
            .getReserveFactor();
        reserveCache.currLiquidityIndex = reserve.liquidityIndex;
        reserveCache.currVariableBorrowIndex = reserve.variableBorrowIndex;
        reserveCache.currLiquidityRate = reserve.currentLiquidityRate;
        reserveCache.currVariableBorrowRate = reserve.currentVariableBorrowRate;

        reserveCache.xTokenAddress = reserve.xTokenAddress;
        reserveCache.stableDebtTokenAddress = reserve.stableDebtTokenAddress;
        reserveCache.variableDebtTokenAddress = reserve
            .variableDebtTokenAddress;

        reserveCache.reserveLastUpdateTimestamp = reserve.lastUpdateTimestamp;

        reserveCache.currScaledVariableDebt = reserveCache
            .nextScaledVariableDebt = IVariableDebtToken(
            reserveCache.variableDebtTokenAddress
        ).scaledTotalSupply();

        (
            reserveCache.currPrincipalStableDebt,
            reserveCache.currTotalStableDebt,
            reserveCache.currAvgStableBorrowRate,
            reserveCache.stableDebtLastUpdateTimestamp
        ) = IStableDebtToken(reserveCache.stableDebtTokenAddress)
            .getSupplyData();

        // by default the actions are considered as not affecting the debt balances.
        // if the action involves mint/burn of debt, the cache needs to be updated
        reserveCache.nextTotalStableDebt = reserveCache.currTotalStableDebt;
        reserveCache.nextAvgStableBorrowRate = reserveCache
            .currAvgStableBorrowRate;

        return reserveCache;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {ICollaterizableERC721} from "../../../interfaces/ICollaterizableERC721.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

/**
 * @title GenericLogic library
 *
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    struct CalculateUserAccountDataVars {
        uint256 assetPrice;
        uint256 assetUnit;
        DataTypes.AssetType assetType;
        uint256 userBalanceInBaseCurrency;
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 i;
        uint256 healthFactor;
        uint256 erc721HealthFactor;
        uint256 totalERC721CollateralInBaseCurrency;
        uint256 payableDebtByERC20Assets;
        uint256 totalCollateralInBaseCurrency;
        uint256 totalDebtInBaseCurrency;
        uint256 avgLtv;
        uint256 avgLiquidationThreshold;
        uint256 avgERC721LiquidationThreshold;
        address currentReserveAddress;
        bool hasZeroLtvCollateral;
    }

    /**
     * @notice Calculates the user data across the reserves.
     * @dev It includes the total liquidity/collateral/borrow balances in the base currency used by the price feed,
     * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for the calculation
     * @return The total collateral of the user in the base currency used by the price feed
     * @return The total ERC721 collateral of the user in the base currency used by the price feed
     * @return The total debt of the user in the base currency used by the price feed
     * @return The average ltv of the user
     * @return The average liquidation threshold of the user
     * @return The health factor of the user
     * @return True if the ltv is zero, false otherwise
     **/
    function calculateUserAccountData(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.CalculateUserAccountDataParams memory params
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        if (params.userConfig.isEmpty()) {
            return (
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                type(uint256).max,
                type(uint256).max,
                false
            );
        }

        CalculateUserAccountDataVars memory vars;

        while (vars.i < params.reservesCount) {
            if (!params.userConfig.isUsingAsCollateralOrBorrowing(vars.i)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            vars.currentReserveAddress = reservesList[vars.i];

            if (vars.currentReserveAddress == address(0)) {
                unchecked {
                    ++vars.i;
                }
                continue;
            }

            DataTypes.ReserveData storage currentReserve = reservesData[
                vars.currentReserveAddress
            ];

            vars.assetType = currentReserve.assetType;

            (
                vars.ltv,
                vars.liquidationThreshold,
                vars.liquidationBonus,
                vars.decimals,

            ) = currentReserve.configuration.getParams();

            unchecked {
                vars.assetUnit = 10**vars.decimals;
            }

            vars.assetPrice = IPriceOracleGetter(params.oracle).getAssetPrice(
                vars.currentReserveAddress
            );

            if (
                vars.liquidationThreshold != 0 &&
                params.userConfig.isUsingAsCollateral(vars.i)
            ) {
                vars.userBalanceInBaseCurrency = _getUserBalanceInBaseCurrency(
                    params.user,
                    currentReserve,
                    vars.assetPrice,
                    vars.assetUnit
                );

                vars.totalCollateralInBaseCurrency += vars
                    .userBalanceInBaseCurrency;

                if (vars.ltv != 0) {
                    vars.avgLtv += vars.userBalanceInBaseCurrency * vars.ltv;
                } else {
                    vars.hasZeroLtvCollateral = true;
                }

                vars.liquidationThreshold =
                    vars.userBalanceInBaseCurrency *
                    (vars.liquidationThreshold);

                vars.avgLiquidationThreshold += vars.liquidationThreshold;

                if (vars.assetType == DataTypes.AssetType.ERC721) {
                    vars.totalERC721CollateralInBaseCurrency += vars
                        .userBalanceInBaseCurrency;
                    vars.avgERC721LiquidationThreshold += vars
                        .liquidationThreshold;
                } else {
                    vars.payableDebtByERC20Assets += vars
                        .userBalanceInBaseCurrency
                        .percentDiv(vars.liquidationBonus);
                }
            }

            if (params.userConfig.isBorrowing(vars.i)) {
                vars.totalDebtInBaseCurrency += _getUserDebtInBaseCurrency(
                    params.user,
                    currentReserve,
                    vars.assetPrice,
                    vars.assetUnit
                );
            }

            unchecked {
                ++vars.i;
            }
        }

        unchecked {
            vars.avgLtv = vars.totalCollateralInBaseCurrency != 0
                ? vars.avgLtv / vars.totalCollateralInBaseCurrency
                : 0;
            vars.avgLiquidationThreshold = vars.totalCollateralInBaseCurrency !=
                0
                ? vars.avgLiquidationThreshold /
                    vars.totalCollateralInBaseCurrency
                : 0;

            vars.avgERC721LiquidationThreshold = vars
                .totalERC721CollateralInBaseCurrency != 0
                ? vars.avgERC721LiquidationThreshold /
                    vars.totalERC721CollateralInBaseCurrency
                : 0;
        }

        vars.healthFactor = (vars.totalDebtInBaseCurrency == 0)
            ? type(uint256).max
            : (
                vars.totalCollateralInBaseCurrency.percentMul(
                    vars.avgLiquidationThreshold
                )
            ).wadDiv(vars.totalDebtInBaseCurrency);

        vars.erc721HealthFactor = (vars.totalDebtInBaseCurrency == 0 ||
            vars.payableDebtByERC20Assets >= vars.totalDebtInBaseCurrency)
            ? type(uint256).max
            : (
                vars.totalERC721CollateralInBaseCurrency.percentMul(
                    vars.avgERC721LiquidationThreshold
                )
            ).wadDiv(
                    vars.totalDebtInBaseCurrency - vars.payableDebtByERC20Assets
                );

        return (
            vars.totalCollateralInBaseCurrency,
            vars.totalERC721CollateralInBaseCurrency,
            vars.totalDebtInBaseCurrency,
            vars.avgLtv,
            vars.avgLiquidationThreshold,
            vars.avgERC721LiquidationThreshold,
            vars.payableDebtByERC20Assets,
            vars.healthFactor,
            vars.erc721HealthFactor,
            vars.hasZeroLtvCollateral
        );
    }

    /**
     * @notice Calculates the maximum amount that can be borrowed depending on the available collateral, the total debt
     * and the average Loan To Value
     * @param totalCollateralInBaseCurrency The total collateral in the base currency used by the price feed
     * @param totalDebtInBaseCurrency The total borrow balance in the base currency used by the price feed
     * @param ltv The average loan to value
     * @return The amount available to borrow in the base currency of the used by the price feed
     **/
    function calculateAvailableBorrows(
        uint256 totalCollateralInBaseCurrency,
        uint256 totalDebtInBaseCurrency,
        uint256 ltv
    ) internal pure returns (uint256) {
        uint256 availableBorrowsInBaseCurrency = totalCollateralInBaseCurrency
            .percentMul(ltv);

        if (availableBorrowsInBaseCurrency < totalDebtInBaseCurrency) {
            return 0;
        }

        availableBorrowsInBaseCurrency =
            availableBorrowsInBaseCurrency -
            totalDebtInBaseCurrency;
        return availableBorrowsInBaseCurrency;
    }

    /**
     * @notice Calculates total debt of the user in the based currency used to normalize the values of the assets
     * @dev This fetches the `balanceOf` of the stable and variable debt tokens for the user. For gas reasons, the
     * variable debt balance is calculated by fetching `scaledBalancesOf` normalized debt, which is cheaper than
     * fetching `balanceOf`
     * @param user The address of the user
     * @param reserve The data of the reserve for which the total debt of the user is being calculated
     * @param assetPrice The price of the asset for which the total debt of the user is being calculated
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total debt of the user normalized to the base currency
     **/
    function _getUserDebtInBaseCurrency(
        address user,
        DataTypes.ReserveData storage reserve,
        uint256 assetPrice,
        uint256 assetUnit
    ) private view returns (uint256) {
        // fetching variable debt
        uint256 userTotalDebt = IScaledBalanceToken(
            reserve.variableDebtTokenAddress
        ).scaledBalanceOf(user);
        if (userTotalDebt != 0) {
            userTotalDebt = userTotalDebt.rayMul(reserve.getNormalizedDebt());
        }

        userTotalDebt =
            userTotalDebt +
            IERC20(reserve.stableDebtTokenAddress).balanceOf(user);

        userTotalDebt = assetPrice * userTotalDebt;

        unchecked {
            return userTotalDebt / assetUnit;
        }
    }

    /**
     * @notice Calculates total xToken balance of the user in the based currency used by the price oracle
     * @dev For gas reasons, the xToken balance is calculated by fetching `scaledBalancesOf` normalized debt, which
     * is cheaper than fetching `balanceOf`
     * @param user The address of the user
     * @param reserve The data of the reserve for which the total xToken balance of the user is being calculated
     * @param assetPrice The price of the asset for which the total xToken balance of the user is being calculated
     * @param assetUnit The value representing one full unit of the asset (10^decimals)
     * @return The total xToken balance of the user normalized to the base currency of the price oracle
     **/
    function _getUserBalanceInBaseCurrency(
        address user,
        DataTypes.ReserveData storage reserve,
        uint256 assetPrice,
        uint256 assetUnit
    ) private view returns (uint256) {
        uint256 balance = 0;

        if (reserve.assetType == DataTypes.AssetType.ERC20) {
            uint256 normalizedIncome = reserve.getNormalizedIncome();
            balance =
                (
                    IScaledBalanceToken(reserve.xTokenAddress)
                        .scaledBalanceOf(user)
                        .rayMul(normalizedIncome)
                ) *
                assetPrice;
        } else if (reserve.assetType == DataTypes.AssetType.ERC721) {
            balance =
                ICollaterizableERC721(reserve.xTokenAddress)
                    .collaterizedBalanceOf(user) *
                assetPrice;
        }

        unchecked {
            return balance / assetUnit;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {WadRayMath} from "./WadRayMath.sol";

/**
 * @title MathUtils library
 *
 * @notice Provides functions to perform linear and compounded interest calculations
 */
library MathUtils {
    using WadRayMath for uint256;

    /// @dev Ignoring leap years
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Function to calculate the interest accumulated using a linear interest rate formula
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate linearly accumulated during the timeDelta, in ray
     **/
    function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
        internal
        view
        returns (uint256)
    {
        //solium-disable-next-line
        uint256 result = rate *
            (block.timestamp - uint256(lastUpdateTimestamp));
        unchecked {
            result = result / SECONDS_PER_YEAR;
        }

        return WadRayMath.RAY + result;
    }

    /**
     * @dev Function to calculate the interest using a compounded interest rate formula
     * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
     *
     *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
     *
     * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great
     * gas cost reductions. The whitepaper contains reference to the approximation and a table showing the margin of
     * error per different time periods
     *
     * @param rate The interest rate, in ray
     * @param lastUpdateTimestamp The timestamp of the last update of the interest
     * @return The interest rate compounded during the timeDelta, in ray
     **/
    function calculateCompoundedInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256) {
        //solium-disable-next-line
        uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

        if (exp == 0) {
            return WadRayMath.RAY;
        }

        uint256 expMinusOne;
        uint256 expMinusTwo;
        uint256 basePowerTwo;
        uint256 basePowerThree;
        unchecked {
            expMinusOne = exp - 1;

            expMinusTwo = exp > 2 ? exp - 2 : 0;

            basePowerTwo =
                rate.rayMul(rate) /
                (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
            basePowerThree = basePowerTwo.rayMul(rate) / SECONDS_PER_YEAR;
        }

        uint256 secondTerm = exp * expMinusOne * basePowerTwo;
        unchecked {
            secondTerm /= 2;
        }
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree;
        unchecked {
            thirdTerm /= 6;
        }

        return
            WadRayMath.RAY +
            (rate * exp) /
            SECONDS_PER_YEAR +
            secondTerm +
            thirdTerm;
    }

    /**
     * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
     * @param rate The interest rate (in ray)
     * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
     * @return The interest rate compounded between lastUpdateTimestamp and current block timestamp, in ray
     **/
    function calculateCompoundedInterest(
        uint256 rate,
        uint40 lastUpdateTimestamp
    ) internal view returns (uint256) {
        return
            calculateCompoundedInterest(
                rate,
                lastUpdateTimestamp,
                block.timestamp
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts//IERC20.sol";
import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {PercentageMath} from "../../libraries/math/PercentageMath.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {Helpers} from "../../libraries/helpers/Helpers.sol";
import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {SupplyLogic} from "./SupplyLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {UserConfiguration} from "../../libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../../libraries/configuration/ReserveConfiguration.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {ICollaterizableERC721} from "../../../interfaces/ICollaterizableERC721.sol";
import {INToken} from "../../../interfaces/INToken.sol";

import {IStableDebtToken} from "../../../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IPriceOracleGetter} from "../../../interfaces/IPriceOracleGetter.sol";

/**
 * @title LiquidationLogic library
 *
 * @notice Implements actions involving management of collateral in the protocol, the main one being the liquidations
 **/
library LiquidationLogic {
    using PercentageMath for uint256;
    using ReserveLogic for DataTypes.ReserveCache;
    using ReserveLogic for DataTypes.ReserveData;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using GPv2SafeERC20 for IERC20;

    // See `IPool` for descriptions
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed liquidationAsset,
        address indexed user,
        uint256 liquidationAmount,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receivePToken
    );

    event ERC721LiquidationCall(
        address indexed collateralAsset,
        address indexed liquidationAsset,
        address indexed user,
        uint256 liquidationAmount,
        uint256 liquidatedCollateralTokenId,
        address liquidator,
        bool receiveNToken
    );

    /**
     * @dev Default percentage of borrower's debt to be repaid in a liquidation.
     * @dev Percentage applied when the users health factor is above `CLOSE_FACTOR_HF_THRESHOLD`
     * Expressed in bps, a value of 0.5e4 results in 50.00%
     */
    uint256 internal constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 0.5e4;

    /**
     * @dev Maximum percentage of borrower's debt to be repaid in a liquidation
     * @dev Percentage applied when the users health factor is below `CLOSE_FACTOR_HF_THRESHOLD`
     * Expressed in bps, a value of 1e4 results in 100.00%
     */
    uint256 public constant MAX_LIQUIDATION_CLOSE_FACTOR = 1e4;

    /**
     * @dev This constant represents below which health factor value it is possible to liquidate
     * an amount of debt corresponding to `MAX_LIQUIDATION_CLOSE_FACTOR`.
     * A value of 0.95e18 results in 0.95
     */
    uint256 public constant CLOSE_FACTOR_HF_THRESHOLD = 0.95e18;

    uint256 private constant BASE_CURRENCY_DECIMALS = 18;

    struct LiquidationCallLocalVars {
        uint256 userCollateralBalance;
        uint256 userGlobalCollateralBalance;
        uint256 userVariableDebt;
        uint256 userGlobalTotalDebt;
        uint256 userTotalDebt;
        uint256 actualDebtToLiquidate;
        uint256 collateralDiscountedPrice;
        uint256 actualCollateralToLiquidate;
        uint256 liquidationBonus;
        uint256 healthFactor;
        uint256 liquidationProtocolFeeAmount;
        address collateralPriceSource;
        address debtPriceSource;
        address collateralXToken;
        bool isLiquidationAssetBorrowed;
        DataTypes.ReserveCache debtReserveCache;
        DataTypes.AssetType assetType;
    }

    /**
     * @notice Function to liquidate a position if its Health Factor drops below 1. The caller (liquidator)
     * covers `liquidationAmount` amount of debt of the user getting liquidated, and receives
     * a proportional amount of the `collateralAsset` plus a bonus to cover market risk
     * @dev Emits the `LiquidationCall()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the liquidation function
     **/
    function executeLiquidationCall(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ExecuteLiquidationCallParams memory params
    ) external {
        LiquidationCallLocalVars memory vars;

        DataTypes.ReserveData storage collateralReserve = reservesData[
            params.collateralAsset
        ];
        DataTypes.ReserveData storage debtReserve = reservesData[
            params.liquidationAsset
        ];
        DataTypes.UserConfigurationMap storage userConfig = usersConfig[
            params.user
        ];
        vars.debtReserveCache = debtReserve.cache();
        debtReserve.updateState(vars.debtReserveCache);

        (, , , , , , , vars.healthFactor, , ) = GenericLogic
            .calculateUserAccountData(
                reservesData,
                reservesList,
                DataTypes.CalculateUserAccountDataParams({
                    userConfig: userConfig,
                    reservesCount: params.reservesCount,
                    user: params.user,
                    oracle: params.priceOracle
                })
            );

        (
            vars.userVariableDebt,
            vars.userTotalDebt,
            vars.actualDebtToLiquidate
        ) = _calculateDebt(vars.debtReserveCache, params, vars.healthFactor);

        ValidationLogic.validateLiquidationCall(
            userConfig,
            collateralReserve,
            DataTypes.ValidateLiquidationCallParams({
                debtReserveCache: vars.debtReserveCache,
                totalDebt: vars.userTotalDebt,
                healthFactor: vars.healthFactor,
                priceOracleSentinel: params.priceOracleSentinel,
                assetType: collateralReserve.assetType
            })
        );

        (
            vars.collateralXToken,
            vars.collateralPriceSource,
            vars.debtPriceSource,
            vars.liquidationBonus
        ) = _getConfigurationData(collateralReserve, params);

        vars.userCollateralBalance = IPToken(vars.collateralXToken).balanceOf(
            params.user
        );

        (
            vars.actualCollateralToLiquidate,
            vars.actualDebtToLiquidate,
            vars.liquidationProtocolFeeAmount
        ) = _calculateAvailableCollateralToLiquidate(
            collateralReserve,
            vars.debtReserveCache,
            vars.collateralPriceSource,
            vars.debtPriceSource,
            vars.actualDebtToLiquidate,
            vars.userCollateralBalance,
            vars.liquidationBonus,
            IPriceOracleGetter(params.priceOracle)
        );

        if (vars.userTotalDebt == vars.actualDebtToLiquidate) {
            userConfig.setBorrowing(debtReserve.id, false);
        }

        _burnDebtTokens(params, vars);

        debtReserve.updateInterestRates(
            vars.debtReserveCache,
            params.liquidationAsset,
            vars.actualDebtToLiquidate,
            0
        );

        if (params.receiveXToken) {
            _liquidatePTokens(usersConfig, collateralReserve, params, vars);
        } else {
            _burnCollateralPTokens(collateralReserve, params, vars);
        }

        // Transfer fee to treasury if it is non-zero
        if (vars.liquidationProtocolFeeAmount != 0) {
            IPToken(vars.collateralXToken).transferOnLiquidation(
                params.user,
                IPToken(vars.collateralXToken).RESERVE_TREASURY_ADDRESS(),
                vars.liquidationProtocolFeeAmount
            );
        }

        // If the collateral being liquidated is equal to the user balance,
        // we set the currency as not being used as collateral anymore
        if (vars.actualCollateralToLiquidate == vars.userCollateralBalance) {
            userConfig.setUsingAsCollateral(collateralReserve.id, false);
            emit ReserveUsedAsCollateralDisabled(
                params.collateralAsset,
                params.user
            );
        }

        // Transfers the debt asset being repaid to the xToken, where the liquidity is kept
        IERC20(params.liquidationAsset).safeTransferFrom(
            msg.sender,
            vars.debtReserveCache.xTokenAddress,
            vars.actualDebtToLiquidate
        );

        IPToken(vars.debtReserveCache.xTokenAddress).handleRepayment(
            msg.sender,
            vars.actualDebtToLiquidate
        );

        emit LiquidationCall(
            params.collateralAsset,
            params.liquidationAsset,
            params.user,
            vars.actualDebtToLiquidate,
            vars.actualCollateralToLiquidate,
            msg.sender,
            params.receiveXToken
        );
    }

    /**
     * @notice Function to liquidate an ERC721 of a position if its Health Factor drops below 1. The caller (liquidator)
     * covers `liquidationAmount` amount of debt of the user getting liquidated, and receives
     * a proportional tokenId of the `collateralAsset` minus a bonus to cover market risk
     * @dev Emits the `ERC721LiquidationCall()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the liquidation function
     **/
    function executeERC721LiquidationCall(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ExecuteLiquidationCallParams memory params
    ) external {
        LiquidationCallLocalVars memory vars;
        DataTypes.ReserveData storage collateralReserve = reservesData[
            params.collateralAsset
        ];
        vars.assetType = collateralReserve.assetType;
        DataTypes.ReserveData storage liquidationAssetReserve = reservesData[
            params.liquidationAsset
        ];
        DataTypes.UserConfigurationMap storage userConfig = usersConfig[
            params.user
        ];
        uint16 liquidationAssetReserveId = liquidationAssetReserve.id;
        vars.debtReserveCache = liquidationAssetReserve.cache();

        liquidationAssetReserve.updateState(vars.debtReserveCache);
        (
            vars.userGlobalCollateralBalance,
            ,
            vars.userGlobalTotalDebt,
            ,
            ,
            ,
            ,
            ,
            vars.healthFactor,

        ) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            DataTypes.CalculateUserAccountDataParams({
                userConfig: userConfig,
                reservesCount: params.reservesCount,
                user: params.user,
                oracle: params.priceOracle
            })
        );

        vars.isLiquidationAssetBorrowed = userConfig.isBorrowing(
            liquidationAssetReserveId
        );

        if (vars.isLiquidationAssetBorrowed) {
            (
                vars.userVariableDebt,
                vars.userTotalDebt,
                vars.actualDebtToLiquidate
            ) = _calculateDebt(
                vars.debtReserveCache,
                params,
                vars.healthFactor
            );
        }

        (
            vars.collateralXToken,
            vars.collateralPriceSource,
            vars.debtPriceSource,
            vars.liquidationBonus
        ) = _getConfigurationData(collateralReserve, params);

        if (!vars.isLiquidationAssetBorrowed) {
            vars.liquidationBonus = PercentageMath.PERCENTAGE_FACTOR;
        }

        vars.userCollateralBalance = ICollaterizableERC721(
            vars.collateralXToken
        ).collaterizedBalanceOf(params.user);

        // vars.userGlobalTotalDebt is set twice to get updated in base currency if it is not already
        (
            vars.collateralDiscountedPrice,
            vars.liquidationProtocolFeeAmount,
            vars.userGlobalTotalDebt,

        ) = _calculateERC721LiquidationParameters(
            collateralReserve,
            vars.debtReserveCache,
            vars.collateralPriceSource,
            vars.debtPriceSource,
            vars.userGlobalTotalDebt,
            vars.actualDebtToLiquidate,
            vars.userCollateralBalance,
            vars.liquidationBonus,
            IPriceOracleGetter(params.priceOracle)
        );

        ValidationLogic.validateERC721LiquidationCall(
            userConfig,
            collateralReserve,
            DataTypes.ValidateERC721LiquidationCallParams({
                debtReserveCache: vars.debtReserveCache,
                totalDebt: vars.userGlobalTotalDebt,
                collateralDiscountedPrice: vars.collateralDiscountedPrice,
                liquidationAmount: params.liquidationAmount,
                healthFactor: vars.healthFactor,
                priceOracleSentinel: params.priceOracleSentinel,
                tokenId: params.collateralTokenId,
                assetType: vars.assetType,
                xTokenAddress: vars.collateralXToken
            })
        );

        uint256 debtCanBeCovered = vars.collateralDiscountedPrice -
            vars.liquidationProtocolFeeAmount;
        // Debt to be covered for the nft = discounted price for NFT, not including protocol fees
        // collateralDiscountedPrice includes the fees by default so you need to subtract them

        if (debtCanBeCovered > vars.actualDebtToLiquidate) {
            // the discounted price will never be greater than the amount the liquidator is passing in
            // require(params.liquidationAmount >= params.collateralDiscountedPrice) - line 669 of ValidationLogic.sol
            // there will always be excess if the discounted price is > amount needed to liquidate
            // vars.actualDebtToLiquidate = The actual debt that is getting liquidated. If liquidation amount passed in by the liquidator is greater then the total user debt, then use the user total debt as the actual debt getting liquidated. If the user total debt is greater than the liquidation amount getting passed in by the liquidator, then use the liquidation amount the user is passing in.
            if (vars.userGlobalTotalDebt > vars.actualDebtToLiquidate) {
                // userGlobalTotalDebt = debt across all positions (ie. if there are multiple positions)
                // if the global debt > the actual debt that is getting liquidated then the excess amount goes to pay protocol
                SupplyLogic.executeSupply(
                    reservesData,
                    userConfig,
                    DataTypes.ExecuteSupplyParams({
                        asset: params.liquidationAsset,
                        amount: debtCanBeCovered - vars.actualDebtToLiquidate,
                        onBehalfOf: params.user,
                        referralCode: 0
                    })
                );

                if (
                    !userConfig.isUsingAsCollateral(liquidationAssetReserveId)
                ) {
                    userConfig.setUsingAsCollateral(
                        liquidationAssetReserveId,
                        true
                    );
                    emit ReserveUsedAsCollateralEnabled(
                        params.liquidationAsset,
                        params.user
                    );
                }
            } else {
                // if the actual debt that is getting liquidated > user global debt then pay back excess to user
                IERC20(params.liquidationAsset).safeTransferFrom(
                    msg.sender,
                    params.user,
                    debtCanBeCovered - vars.actualDebtToLiquidate
                );
            }
        } else {
            // if the actual debt that is getting liquidated > discounted price then there is no excess amount
            // update the actual debt that is getting liquidated to the discounted price of the nft
            vars.actualDebtToLiquidate = debtCanBeCovered;
        }

        if (vars.actualDebtToLiquidate != 0) {
            _burnDebtTokens(params, vars);
            liquidationAssetReserve.updateInterestRates(
                vars.debtReserveCache,
                params.liquidationAsset,
                vars.actualDebtToLiquidate,
                0
            );

            IERC20(params.liquidationAsset).safeTransferFrom(
                msg.sender,
                vars.debtReserveCache.xTokenAddress,
                vars.actualDebtToLiquidate
            );
        }

        if (params.receiveXToken) {
            _liquidateNTokens(usersConfig, collateralReserve, params, vars);
        } else {
            _burnCollateralNTokens(params, vars);
        }

        if (vars.userTotalDebt == vars.actualDebtToLiquidate) {
            userConfig.setBorrowing(liquidationAssetReserve.id, false);
        }

        // Transfer fee to treasury if it is non-zero
        if (vars.liquidationProtocolFeeAmount != 0) {
            IERC20(params.liquidationAsset).safeTransferFrom(
                msg.sender,
                IPToken(vars.debtReserveCache.xTokenAddress)
                    .RESERVE_TREASURY_ADDRESS(),
                vars.liquidationProtocolFeeAmount
            );
        }

        // If the collateral being liquidated is equal to the user balance,
        // we set the currency as not being used as collateral anymore
        if (vars.userCollateralBalance == 1) {
            userConfig.setUsingAsCollateral(collateralReserve.id, false);
            emit ReserveUsedAsCollateralDisabled(
                params.collateralAsset,
                params.user
            );
        }

        emit ERC721LiquidationCall(
            params.collateralAsset,
            params.liquidationAsset,
            params.user,
            vars.actualDebtToLiquidate,
            params.collateralTokenId,
            msg.sender,
            params.receiveXToken
        );
    }

    /**
     * @notice Burns the collateral xTokens and transfers the underlying to the liquidator.
     * @dev   The function also updates the state and the interest rate of the collateral reserve.
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidationCall() function local vars
     */
    function _burnCollateralPTokens(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidationCallParams memory params,
        LiquidationCallLocalVars memory vars
    ) internal {
        DataTypes.ReserveCache memory collateralReserveCache = collateralReserve
            .cache();
        collateralReserve.updateState(collateralReserveCache);
        collateralReserve.updateInterestRates(
            collateralReserveCache,
            params.collateralAsset,
            0,
            vars.actualCollateralToLiquidate
        );

        // Burn the equivalent amount of xToken, sending the underlying to the liquidator
        IPToken(vars.collateralXToken).burn(
            params.user,
            msg.sender,
            vars.actualCollateralToLiquidate,
            collateralReserveCache.nextLiquidityIndex
        );
    }

    /**
     * @notice Burns the collateral xTokens and transfers the underlying to the liquidator.
     * @dev   The function also updates the state and the interest rate of the collateral reserve.
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidationCall() function local vars
     */
    function _burnCollateralNTokens(
        DataTypes.ExecuteLiquidationCallParams memory params,
        LiquidationCallLocalVars memory vars
    ) internal {
        // Burn the equivalent amount of xToken, sending the underlying to the liquidator
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = params.collateralTokenId;
        INToken(vars.collateralXToken).burn(params.user, msg.sender, tokenIds);
    }

    /**
     * @notice Liquidates the user xTokens by transferring them to the liquidator.
     * @dev   The function also checks the state of the liquidator and activates the xToken as collateral
     *        as in standard transfers if the isolation mode constraints are respected.
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidationCall() function local vars
     */
    function _liquidatePTokens(
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidationCallParams memory params,
        LiquidationCallLocalVars memory vars
    ) internal {
        uint256 liquidatorPreviousPTokenBalance = IERC20(vars.collateralXToken)
            .balanceOf(msg.sender);
        IPToken(vars.collateralXToken).transferOnLiquidation(
            params.user,
            msg.sender,
            vars.actualCollateralToLiquidate
        );

        if (liquidatorPreviousPTokenBalance == 0) {
            DataTypes.UserConfigurationMap
                storage liquidatorConfig = usersConfig[msg.sender];

            liquidatorConfig.setUsingAsCollateral(collateralReserve.id, true);
            emit ReserveUsedAsCollateralEnabled(
                params.collateralAsset,
                msg.sender
            );
        }
    }

    /**
     * @notice Liquidates the user xTokens by transferring them to the liquidator.
     * @dev   The function also checks the state of the liquidator and activates the xToken as collateral
     *        as in standard transfers if the isolation mode constraints are respected.
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars The executeLiquidationCall() function local vars
     */
    function _liquidateNTokens(
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidationCallParams memory params,
        LiquidationCallLocalVars memory vars
    ) internal {
        uint256 liquidatorPreviousNTokenBalance = ICollaterizableERC721(
            vars.collateralXToken
        ).collaterizedBalanceOf(msg.sender);

        bool isTokenUsedAsCollateral = ICollaterizableERC721(
            vars.collateralXToken
        ).isUsedAsCollateral(params.collateralTokenId);

        INToken(vars.collateralXToken).transferOnLiquidation(
            params.user,
            msg.sender,
            params.collateralTokenId
        );

        if (liquidatorPreviousNTokenBalance == 0 && isTokenUsedAsCollateral) {
            DataTypes.UserConfigurationMap
                storage liquidatorConfig = usersConfig[msg.sender];

            liquidatorConfig.setUsingAsCollateral(collateralReserve.id, true);
            emit ReserveUsedAsCollateralEnabled(
                params.collateralAsset,
                msg.sender
            );
        }
    }

    /**
     * @notice Burns the debt tokens of the user up to the amount being repaid by the liquidator.
     * @dev The function alters the `debtReserveCache` state in `vars` to update the debt related data.
     * @param params The additional parameters needed to execute the liquidation function
     * @param vars the executeLiquidationCall() function local vars
     */
    function _burnDebtTokens(
        DataTypes.ExecuteLiquidationCallParams memory params,
        LiquidationCallLocalVars memory vars
    ) internal {
        if (vars.userVariableDebt >= vars.actualDebtToLiquidate) {
            vars.debtReserveCache.nextScaledVariableDebt = IVariableDebtToken(
                vars.debtReserveCache.variableDebtTokenAddress
            ).burn(
                    params.user,
                    vars.actualDebtToLiquidate,
                    vars.debtReserveCache.nextVariableBorrowIndex
                );
        } else {
            // If the user doesn't have variable debt, no need to try to burn variable debt tokens
            if (vars.userVariableDebt != 0) {
                vars
                    .debtReserveCache
                    .nextScaledVariableDebt = IVariableDebtToken(
                    vars.debtReserveCache.variableDebtTokenAddress
                ).burn(
                        params.user,
                        vars.userVariableDebt,
                        vars.debtReserveCache.nextVariableBorrowIndex
                    );
            }
            (
                vars.debtReserveCache.nextTotalStableDebt,
                vars.debtReserveCache.nextAvgStableBorrowRate
            ) = IStableDebtToken(vars.debtReserveCache.stableDebtTokenAddress)
                .burn(
                    params.user,
                    vars.actualDebtToLiquidate - vars.userVariableDebt
                );
        }
    }

    /**
     * @notice Calculates the total debt of the user and the actual amount to liquidate depending on the health factor
     * and corresponding close factor. we are always using max closing factor in this version
     * @param debtReserveCache The reserve cache data object of the debt reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @param healthFactor The health factor of the position
     * @return The variable debt of the user
     * @return The total debt of the user
     * @return The actual debt that is getting liquidated. If liquidation amount passed in by the liquidator is greater then the total user debt, then use the user total debt as the actual debt getting liquidated. If the user total debt is greater than the liquidation amount getting passed in by the liquidator, then use the liquidation amount the user is passing in.
     */
    function _calculateDebt(
        DataTypes.ReserveCache memory debtReserveCache,
        DataTypes.ExecuteLiquidationCallParams memory params,
        uint256 healthFactor
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 userStableDebt, uint256 userVariableDebt) = Helpers
            .getUserCurrentDebt(params.user, debtReserveCache);

        uint256 userTotalDebt = userStableDebt + userVariableDebt;
        // userTotalDebt = debt of the borrowed position needed for liquidation

        uint256 actualDebtToLiquidate = params.liquidationAmount > userTotalDebt
            ? userTotalDebt
            : params.liquidationAmount;

        return (userVariableDebt, userTotalDebt, actualDebtToLiquidate);
    }

    /**
     * @notice Returns the configuration data for the debt and the collateral reserves.
     * @param collateralReserve The data of the collateral reserve
     * @param params The additional parameters needed to execute the liquidation function
     * @return The collateral xToken
     * @return The address to use as price source for the collateral
     * @return The address to use as price source for the debt
     * @return The liquidation bonus to apply to the collateral
     */
    function _getConfigurationData(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ExecuteLiquidationCallParams memory params
    )
        internal
        view
        returns (
            address,
            address,
            address,
            uint256
        )
    {
        address collateralXToken = collateralReserve.xTokenAddress;
        uint256 liquidationBonus = collateralReserve
            .configuration
            .getLiquidationBonus();

        address collateralPriceSource = params.collateralAsset;
        address debtPriceSource = params.liquidationAsset;

        return (
            collateralXToken,
            collateralPriceSource,
            debtPriceSource,
            liquidationBonus
        );
    }

    struct AvailableCollateralToLiquidateLocalVars {
        uint256 collateralPrice;
        uint256 debtAssetPrice;
        uint256 globalDebtPrice;
        uint256 debtToCoverInBaseCurrency;
        uint256 maxCollateralToLiquidate;
        uint256 baseCollateral;
        uint256 bonusCollateral;
        uint256 debtAssetDecimals;
        uint256 collateralDecimals;
        uint256 collateralAssetUnit;
        uint256 debtAssetUnit;
        uint256 collateralAmount;
        uint256 collateralPriceInDebtAsset;
        uint256 collateralDiscountedPrice;
        uint256 actualLiquidationBonus;
        uint256 liquidationProtocolFeePercentage;
        uint256 liquidationProtocolFee;
    }

    /**
     * @notice Calculates how much of a specific collateral can be liquidated, given
     * a certain amount of debt asset.
     * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
     *   otherwise it might fail.
     * @param collateralReserve The data of the collateral reserve
     * @param debtReserveCache The cached data of the debt reserve
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param liquidationAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param liquidationAmount The debt amount of borrowed `asset` the liquidator wants to cover
     * @param userCollateralBalance The collateral balance for the specific `collateralAsset` of the user being liquidated
     * @param liquidationBonus The collateral bonus percentage to receive as result of the liquidation
     * @return The maximum amount that is possible to liquidate given all the liquidation constraints (user balance, close factor)
     * @return The amount to repay with the liquidation
     * @return The fee taken from the liquidation bonus amount to be paid to the protocol
     **/
    function _calculateAvailableCollateralToLiquidate(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ReserveCache memory debtReserveCache,
        address collateralAsset,
        address liquidationAsset,
        uint256 liquidationAmount,
        uint256 userCollateralBalance,
        uint256 liquidationBonus,
        IPriceOracleGetter oracle
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        AvailableCollateralToLiquidateLocalVars memory vars;

        vars.collateralPrice = oracle.getAssetPrice(collateralAsset);
        vars.debtAssetPrice = oracle.getAssetPrice(liquidationAsset);

        vars.collateralDecimals = collateralReserve.configuration.getDecimals();
        vars.debtAssetDecimals = debtReserveCache
            .reserveConfiguration
            .getDecimals();

        unchecked {
            vars.collateralAssetUnit = 10**vars.collateralDecimals;
            vars.debtAssetUnit = 10**vars.debtAssetDecimals;
        }

        vars.liquidationProtocolFeePercentage = collateralReserve
            .configuration
            .getLiquidationProtocolFee();

        // This is the base collateral to liquidate based on the given debt to cover
        vars.baseCollateral =
            (
                (vars.debtAssetPrice *
                    liquidationAmount *
                    vars.collateralAssetUnit)
            ) /
            (vars.collateralPrice * vars.debtAssetUnit);

        vars.maxCollateralToLiquidate = vars.baseCollateral.percentMul(
            liquidationBonus
        );

        if (vars.maxCollateralToLiquidate > userCollateralBalance) {
            vars.collateralAmount = userCollateralBalance;
            vars.collateralDiscountedPrice = ((vars.collateralPrice *
                vars.collateralAmount *
                vars.debtAssetUnit) /
                (vars.debtAssetPrice * vars.collateralAssetUnit)).percentDiv(
                    liquidationBonus
                );
        } else {
            vars.collateralAmount = vars.maxCollateralToLiquidate;
            vars.collateralDiscountedPrice = liquidationAmount;
        }

        if (vars.liquidationProtocolFeePercentage != 0) {
            vars.bonusCollateral =
                vars.collateralAmount -
                vars.collateralAmount.percentDiv(liquidationBonus);

            vars.liquidationProtocolFee = vars.bonusCollateral.percentMul(
                vars.liquidationProtocolFeePercentage
            );

            return (
                vars.collateralAmount - vars.liquidationProtocolFee,
                vars.collateralDiscountedPrice,
                vars.liquidationProtocolFee
            );
        } else {
            return (vars.collateralAmount, vars.collateralDiscountedPrice, 0);
        }
    }

    /**
     * @notice Calculates how much of a specific collateral can be liquidated, given
     * a certain amount of debt asset.
     * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
     *   otherwise it might fail.
     * @param collateralReserve The data of the collateral reserve
     * @param debtReserveCache The cached data of the debt reserve
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param liquidationAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param userGlobalTotalDebt The total debt the user has
     * @param liquidationAmount The debt amount of borrowed `asset` the liquidator wants to cover
     * @param userCollateralBalance The collateral balance for the specific `collateralAsset` of the user being liquidated
     * @param liquidationBonus The collateral bonus percentage to receive as result of the liquidation
     * @return The discounted nft price + the liquidationProtocolFee
     * @return The liquidationProtocolFee
     * @return The debt price you are paying in (for example, USD or ETH)
     * @return The amount of debt the liquidator can cover using the base currency they are using for liquidation
     **/
    function _calculateERC721LiquidationParameters(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ReserveCache memory debtReserveCache,
        address collateralAsset,
        address liquidationAsset,
        uint256 userGlobalTotalDebt,
        uint256 liquidationAmount,
        uint256 userCollateralBalance,
        uint256 liquidationBonus,
        IPriceOracleGetter oracle
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AvailableCollateralToLiquidateLocalVars memory vars;

        // price of the asset that is used as collateral
        vars.collateralPrice = oracle.getAssetPrice(collateralAsset);
        // price of the asset the liquidator is liquidating with
        vars.debtAssetPrice = oracle.getAssetPrice(liquidationAsset);

        vars.collateralDecimals = collateralReserve.configuration.getDecimals();
        vars.debtAssetDecimals = debtReserveCache
            .reserveConfiguration
            .getDecimals();

        unchecked {
            vars.collateralAssetUnit = 10**vars.collateralDecimals;
            vars.debtAssetUnit = 10**vars.debtAssetDecimals;
        }

        vars.liquidationProtocolFeePercentage = collateralReserve
            .configuration
            .getLiquidationProtocolFee();

        vars.collateralPriceInDebtAsset = ((vars.collateralPrice *
            vars.debtAssetUnit) /
            (vars.debtAssetPrice * vars.collateralAssetUnit));

        // base currency to convert to liquidation asset unit.
        vars.globalDebtPrice =
            (userGlobalTotalDebt * vars.debtAssetUnit) /
            vars.debtAssetPrice;

        // (liquidation amount (passed in by liquidator, this has decimals) * debtAssetPrice) / number of decimals
        // ie. liquidation amount (10k DAI * 10^18) * price of DAI ($1) / 10^18 = 10k
        // vars.debtToCoverInBaseCurrency needs to be >= vars.collateralDiscountedPrice otherwise the liquidator cannot buy the NFT
        // in a scenario where there are multiple people trying to liquidate and the highest amount would pay back the more of the total global debt that user has to protocol
        vars.debtToCoverInBaseCurrency =
            (liquidationAmount * vars.debtAssetPrice) /
            vars.debtAssetUnit;

        vars.collateralDiscountedPrice = vars
            .collateralPriceInDebtAsset
            .percentDiv(liquidationBonus);

        if (vars.liquidationProtocolFeePercentage != 0) {
            vars.bonusCollateral =
                vars.collateralPriceInDebtAsset -
                vars.collateralDiscountedPrice;

            vars.liquidationProtocolFee = vars.bonusCollateral.percentMul(
                vars.liquidationProtocolFeePercentage
            );

            return (
                vars.collateralDiscountedPrice + vars.liquidationProtocolFee,
                vars.liquidationProtocolFee,
                vars.globalDebtPrice,
                vars.debtToCoverInBaseCurrency
            );
        } else {
            return (
                vars.collateralDiscountedPrice,
                0,
                vars.globalDebtPrice,
                vars.debtToCoverInBaseCurrency
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title Helpers library
 *
 */
library Helpers {
    /**
     * @notice Fetches the user current stable and variable debt balances
     * @param user The user address
     * @param reserveCache The reserve cache data object
     * @return The stable debt balance
     * @return The variable debt balance
     **/
    function getUserCurrentDebt(
        address user,
        DataTypes.ReserveCache memory reserveCache
    ) internal view returns (uint256, uint256) {
        return (
            IERC20(reserveCache.stableDebtTokenAddress).balanceOf(user),
            IERC20(reserveCache.variableDebtTokenAddress).balanceOf(user)
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC721} from "../../../dependencies/openzeppelin/contracts/IERC721.sol";

import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {INToken} from "../../../interfaces/INToken.sol";
import {ICollaterizableERC721} from "../../../interfaces/ICollaterizableERC721.sol";
import {Errors} from "../helpers/Errors.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";

/**
 * @title SupplyLogic library
 *
 * @notice Implements the base logic for supply/withdraw
 */
library SupplyLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using GPv2SafeERC20 for IERC20;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using WadRayMath for uint256;

    // See `IPool` for descriptions
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );
    event SupplyERC721(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        DataTypes.ERC721SupplyParams[] tokenData,
        uint16 indexed referralCode
    );

    event WithdrawERC721(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256[] tokenIds
    );

    /**
     * @notice Implements the supply feature. Through `supply()`, users supply assets to the ParaSpace protocol.
     * @dev Emits the `Supply()` event.
     * @dev In the first supply action, `ReserveUsedAsCollateralEnabled()` is emitted, if the asset can be enabled as
     * collateral.
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the supply function
     */
    function executeSupply(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        ValidationLogic.validateSupply(
            reserveCache,
            params.amount,
            DataTypes.AssetType.ERC20
        );

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            params.amount,
            0
        );

        IERC20(params.asset).safeTransferFrom(
            msg.sender,
            reserveCache.xTokenAddress,
            params.amount
        );

        bool isFirstSupply = IPToken(reserveCache.xTokenAddress).mint(
            msg.sender,
            params.onBehalfOf,
            params.amount,
            reserveCache.nextLiquidityIndex
        );

        if (isFirstSupply) {
            userConfig.setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(
                params.asset,
                params.onBehalfOf
            );
        }

        emit Supply(
            params.asset,
            msg.sender,
            params.onBehalfOf,
            params.amount,
            params.referralCode
        );
    }

    function executeSupplyERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteSupplyERC721Params memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        uint256 amount = params.tokenData.length;

        ValidationLogic.validateSupply(
            reserveCache,
            amount,
            DataTypes.AssetType.ERC721
        );

        // uint256 usedAsCollateral;

        for (uint256 index = 0; index < amount; index++) {
            // if (params.tokenData[index].useAsCollateral) {
            //     usedAsCollateral++;
            // }
            // msg.sender is wPunkGatewayProxy address who is the owner of the token = from
            // to is reserveCache.xTokenAddress
            // token id is params.tokenData[index].tokenId
            IERC721(params.asset).safeTransferFrom(
                msg.sender,
                reserveCache.xTokenAddress,
                params.tokenData[index].tokenId
            );
        }

        bool isFirstSupply = INToken(reserveCache.xTokenAddress).mint(
            params.onBehalfOf,
            params.tokenData
        );
        // TODO consider using (usedAsCollateral > 0) instead here to enable collateralization
        if (isFirstSupply) {
            userConfig.setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(
                params.asset,
                params.onBehalfOf
            );
        }

        emit SupplyERC721(
            params.asset,
            msg.sender,
            params.onBehalfOf,
            params.tokenData,
            params.referralCode
        );
    }

    /**
     * @notice Implements the withdraw feature. Through `withdraw()`, users redeem their xTokens for the underlying asset
     * previously supplied in the ParaSpace protocol.
     * @dev Emits the `Withdraw()` event.
     * @dev If the user withdraws everything, `ReserveUsedAsCollateralDisabled()` is emitted.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the withdraw function
     * @return The actual amount withdrawn
     */
    function executeWithdraw(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteWithdrawParams memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        uint256 userBalance = IPToken(reserveCache.xTokenAddress)
            .scaledBalanceOf(msg.sender)
            .rayMul(reserveCache.nextLiquidityIndex);

        uint256 amountToWithdraw = params.amount;

        if (params.amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }

        ValidationLogic.validateWithdraw(
            reserveCache,
            amountToWithdraw,
            userBalance
        );

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            0,
            amountToWithdraw
        );

        IPToken(reserveCache.xTokenAddress).burn(
            msg.sender,
            params.to,
            amountToWithdraw,
            reserveCache.nextLiquidityIndex
        );

        if (userConfig.isUsingAsCollateral(reserve.id)) {
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtv(
                    reservesData,
                    reservesList,
                    userConfig,
                    params.asset,
                    msg.sender,
                    params.reservesCount,
                    params.oracle
                );
            }

            if (amountToWithdraw == userBalance) {
                userConfig.setUsingAsCollateral(reserve.id, false);
                emit ReserveUsedAsCollateralDisabled(params.asset, msg.sender);
            }
        }

        emit Withdraw(params.asset, msg.sender, params.to, amountToWithdraw);

        return amountToWithdraw;
    }

    function executeWithdrawERC721(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteWithdrawERC721Params memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);
        uint256 amountToWithdraw = params.tokenIds.length;

        bool withdrwingAllCollateral = INToken(reserveCache.xTokenAddress).burn(
            msg.sender,
            params.to,
            params.tokenIds
        );

        ValidationLogic.validateWithdrawERC721(reserveCache);

        if (userConfig.isUsingAsCollateral(reserve.id)) {
            if (userConfig.isBorrowingAny()) {
                ValidationLogic.validateHFAndLtv(
                    reservesData,
                    reservesList,
                    userConfig,
                    params.asset,
                    msg.sender,
                    params.reservesCount,
                    params.oracle
                );
            }

            if (withdrwingAllCollateral) {
                userConfig.setUsingAsCollateral(reserve.id, false);
                emit ReserveUsedAsCollateralDisabled(params.asset, msg.sender);
            }
        }

        emit WithdrawERC721(
            params.asset,
            msg.sender,
            params.to,
            params.tokenIds
        );

        return amountToWithdraw;
    }

    /**
     * @notice Validates a transfer of xTokens. The sender is subjected to health factor validation to avoid
     * collateralization constraints violation.
     * @dev Emits the `ReserveUsedAsCollateralEnabled()` event for the `to` account, if the asset is being activated as
     * collateral.
     * @dev In case the `from` user transfers everything, `ReserveUsedAsCollateralDisabled()` is emitted for `from`.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param usersConfig The users configuration mapping that track the supplied/borrowed assets
     * @param params The additional parameters needed to execute the finalizeTransfer function
     */
    function executeFinalizeTransfer(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        mapping(address => DataTypes.UserConfigurationMap) storage usersConfig,
        DataTypes.FinalizeTransferParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];

        ValidationLogic.validateTransfer(reserve);

        uint256 reserveId = reserve.id;

        if (params.from != params.to && params.value != 0) {
            DataTypes.UserConfigurationMap storage fromConfig = usersConfig[
                params.from
            ];

            bool usingAsCollateral;
            uint256 amount;

            if (reserve.assetType == DataTypes.AssetType.ERC721) {
                usingAsCollateral = params.usedAsCollateral;
                amount = 1;
            } else {
                usingAsCollateral = fromConfig.isUsingAsCollateral(reserveId);
                amount = params.value;
            }

            if (usingAsCollateral) {
                if (fromConfig.isBorrowingAny()) {
                    ValidationLogic.validateHFAndLtv(
                        reservesData,
                        reservesList,
                        usersConfig[params.from],
                        params.asset,
                        params.from,
                        params.reservesCount,
                        params.oracle
                    );
                }
                if (params.balanceFromBefore == amount) {
                    fromConfig.setUsingAsCollateral(reserveId, false);
                    emit ReserveUsedAsCollateralDisabled(
                        params.asset,
                        params.from
                    );
                }
            }

            if (params.balanceToBefore == 0 && params.usedAsCollateral) {
                DataTypes.UserConfigurationMap storage toConfig = usersConfig[
                    params.to
                ];

                toConfig.setUsingAsCollateral(reserveId, true);
                emit ReserveUsedAsCollateralEnabled(params.asset, params.to);
            }
        }
    }

    /**
     * @notice Executes the 'set as collateral' feature. A user can choose to activate or deactivate an asset as
     * collateral at any point in time. Deactivating an asset as collateral is subjected to the usual health factor
     * checks to ensure collateralization.
     * @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
     * @dev In case the asset is being deactivated as collateral, `ReserveUsedAsCollateralDisabled()` is emitted.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The users configuration mapping that track the supplied/borrowed assets
     * @param asset The address of the asset being configured as collateral
     * @param useAsCollateral True if the user wants to set the asset as collateral, false otherwise
     * @param reservesCount The number of initialized reserves
     * @param priceOracle The address of the price oracle
     */
    function executeUseReserveAsCollateral(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        address asset,
        bool useAsCollateral,
        uint256 reservesCount,
        address priceOracle
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        uint256 userBalance;

        if (reserveCache.assetType == DataTypes.AssetType.ERC20) {
            userBalance = IERC20(reserveCache.xTokenAddress).balanceOf(
                msg.sender
            );
        } else {
            userBalance = ICollaterizableERC721(reserveCache.xTokenAddress)
                .collaterizedBalanceOf(msg.sender);
        }

        ValidationLogic.validateSetUseReserveAsCollateral(
            reserveCache,
            userBalance
        );

        if (useAsCollateral == userConfig.isUsingAsCollateral(reserve.id))
            return;

        if (useAsCollateral) {
            userConfig.setUsingAsCollateral(reserve.id, true);
            emit ReserveUsedAsCollateralEnabled(asset, msg.sender);
        } else {
            userConfig.setUsingAsCollateral(reserve.id, false);
            ValidationLogic.validateHFAndLtv(
                reservesData,
                reservesList,
                userConfig,
                asset,
                msg.sender,
                reservesCount,
                priceOracle
            );

            emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
        }
    }

    /**
     * @notice Executes the 'set as collateral' feature. A user can choose to activate or deactivate an asset as
     * collateral at any point in time. Deactivating an asset as collateral is subjected to the usual health factor
     * checks to ensure collateralization.
     * @dev Emits the `ReserveUsedAsCollateralEnabled()` event if the asset can be activated as collateral.
     * @dev In case the asset is being deactivated as collateral, `ReserveUsedAsCollateralDisabled()` is emitted.
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The users configuration mapping that track the supplied/borrowed assets
     * @param asset The address of the asset being configured as collateral
     * @param useAsCollateral True if the user wants to set the asset as collateral, false otherwise
     * @param reservesCount The number of initialized reserves
     * @param priceOracle The address of the price oracle
     */
    function executeUseERC721AsCollateral(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        address asset,
        uint256 tokenId,
        bool useAsCollateral,
        uint256 reservesCount,
        address priceOracle
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        (
            bool valid,
            address owner,
            uint256 collaterizedBalance
        ) = ICollaterizableERC721(reserveCache.xTokenAddress)
                .setIsUsedAsCollateral(tokenId, useAsCollateral);

        if (valid) {
            ValidationLogic.validateSetUseERC721AsCollateral(
                reserveCache,
                msg.sender,
                owner
            );

            if (useAsCollateral) {
                if (collaterizedBalance == 1) {
                    userConfig.setUsingAsCollateral(reserve.id, true);
                    emit ReserveUsedAsCollateralEnabled(asset, msg.sender);
                }
                // TODO emit event
            } else {
                if (collaterizedBalance == 0) {
                    userConfig.setUsingAsCollateral(reserve.id, false);
                    emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
                }
                ValidationLogic.validateHFAndLtv(
                    reservesData,
                    reservesList,
                    userConfig,
                    asset,
                    msg.sender,
                    reservesCount,
                    priceOracle
                );
            }
        } else {
            return;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title PoolStorage
 *
 * @notice Contract used as storage of the Pool contract.
 * @dev It defines the storage layout of the Pool contract.
 */
contract PoolStorage {
    // Map of reserves and their data (underlyingAssetOfReserve => reserveData)
    mapping(address => DataTypes.ReserveData) internal _reserves;

    // Map of users address and their configuration data (userAddress => userConfiguration)
    mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

    // List of reserves as a map (reserveId => reserve).
    // It is structured as a mapping for gas savings reasons, using the reserve id as index
    mapping(uint256 => address) internal _reservesList;

    // Available liquidity that can be borrowed at once at stable rate, expressed in bps
    uint64 internal _maxStableRateBorrowSizePercent;

    // Maximum number of active reserves there have been in the protocol. It is the upper bound of the reserves list
    uint16 internal _reservesCount;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {OwnableUpgradeable} from "../dependencies/openzeppelin/contracts/proxy/OwnableUpgradeable.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {IWETH} from "../misc/interfaces/IWETH.sol";
import {IWETHGateway} from "./interfaces/IWETHGateway.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IPToken} from "../interfaces/IPToken.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {DataTypesHelper} from "./libraries/DataTypesHelper.sol";

contract WETHGateway is IWETHGateway, OwnableUpgradeable {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IWETH internal immutable WETH;

    address public immutable weth;
    address public immutable pool;

    /**
     * @dev Sets the WETH address and the PoolAddressesProvider address. Infinite approves pool.
     * @param _weth Address of the Wrapped Ether contract
     * @param _pool Address of the proxy pool of this contract
     **/
    constructor(address _weth, address _pool) {
        weth = _weth;
        pool = _pool;

        WETH = IWETH(weth);
    }

    function initialize() external initializer {
        __Ownable_init();

        WETH.approve(pool, type(uint256).max);
    }

    /**
     * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (xTokens)
     * is minted.
     * @param pool address of the targeted underlying pool
     * @param onBehalfOf address of the user who will receive the xTokens representing the deposit
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable override {
        WETH.deposit{value: msg.value}();
        IPool(pool).supply(address(WETH), msg.value, onBehalfOf, referralCode);
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param pool address of the targeted underlying pool
     * @param amount amount of pWETH to withdraw and receive native ETH
     * @param to address of the user who will receive native ETH
     */
    function withdrawETH(
        address pool,
        uint256 amount,
        address to
    ) external override {
        IPToken pWETH = IPToken(
            IPool(pool).getReserveData(address(WETH)).xTokenAddress
        );
        uint256 userBalance = pWETH.balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;

        // if amount is equal to uint(-1), the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        pWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
        IPool(pool).withdraw(address(WETH), amountToWithdraw, address(this));
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(to, amountToWithdraw);
    }

    /**
     * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
     * @param pool address of the targeted underlying pool
     * @param amount the amount to repay, or uint256(-1) if the user wants to repay everything
     * @param rateMode the rate mode to repay
     * @param onBehalfOf the address for which msg.sender is repaying
     */
    function repayETH(
        address pool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable override {
        (uint256 stableDebt, uint256 variableDebt) = DataTypesHelper
            .getUserCurrentDebt(
                onBehalfOf,
                IPool(pool).getReserveData(address(WETH))
            );

        uint256 paybackAmount = DataTypes.InterestRateMode(rateMode) ==
            DataTypes.InterestRateMode.STABLE
            ? stableDebt
            : variableDebt;

        if (amount < paybackAmount) {
            paybackAmount = amount;
        }
        require(
            msg.value >= paybackAmount,
            "msg.value is less than repayment amount"
        );
        WETH.deposit{value: paybackAmount}();
        IPool(pool).repay(address(WETH), msg.value, rateMode, onBehalfOf);

        // refund remaining dust eth
        if (msg.value > paybackAmount)
            _safeTransferETH(msg.sender, msg.value - paybackAmount);
    }

    /**
     * @dev borrow WETH, unwraps to ETH and send both the ETH and DebtTokens to msg.sender, via `approveDelegation` and onBehalf argument in `Pool.borrow`.
     * @param pool address of the targeted underlying pool
     * @param amount the amount of ETH to borrow
     * @param interesRateMode the interest rate mode
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     */
    function borrowETH(
        address pool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external override {
        IPool(pool).borrow(
            address(WETH),
            amount,
            interesRateMode,
            referralCode,
            msg.sender
        );
        WETH.withdraw(amount);
        _safeTransferETH(msg.sender, amount);
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param pool address of the targeted underlying pool
     * @param amount amount of pWETH to withdraw and receive native ETH
     * @param to address of the user who will receive native ETH
     * @param deadline validity deadline of permit and so depositWithPermit signature
     * @param permitV V parameter of ERC712 permit sig
     * @param permitR R parameter of ERC712 permit sig
     * @param permitS S parameter of ERC712 permit sig
     */
    function withdrawETHWithPermit(
        address pool,
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external override {
        IPToken pWETH = IPToken(
            IPool(pool).getReserveData(address(WETH)).xTokenAddress
        );
        uint256 userBalance = pWETH.balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;

        // if amount is equal to uint(-1), the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        // choosing to permit `amount`and not `amountToWithdraw`, easier for frontends, intregrators.
        pWETH.permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            permitV,
            permitR,
            permitS
        );
        pWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
        IPool(pool).withdraw(address(WETH), amountToWithdraw, address(this));
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(to, amountToWithdraw);
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param token token to transfer
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /**
     * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computated contract address before deployment.
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransfer(address to, uint256 amount)
        external
        onlyOwner
    {
        _safeTransferETH(to, amount);
    }

    /**
     * @dev Get WETH address used by WETHGateway
     */
    function getWETHAddress() external view returns (address) {
        return address(WETH);
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert("Fallback not allowed");
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IWETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;

    function repayETH(
        address pool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address pool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;

    function withdrawETHWithPermit(
        address pool,
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {Address} from "../dependencies/openzeppelin/contracts/Address.sol";
import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../interfaces/IPool.sol";
import {GPv2SafeERC20} from "../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title WalletBalanceProvider contract
 * , influenced by https://github.com/wbobeirne/eth-balance-checker/blob/master/contracts/BalanceChecker.sol
 * @notice Implements a logic of getting multiple tokens balance for one user address
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE ParaSpace PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the ParaSpace backend.
 **/
contract WalletBalanceProvider {
    using Address for address payable;
    using Address for address;
    using GPv2SafeERC20 for IERC20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    address constant MOCK_ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
    @dev Fallback function, don't accept any ETH
    **/
    receive() external payable {
        //only contracts can send ETH to the core
        require(msg.sender.isContract(), "22");
    }

    /**
    @dev Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
    function balanceOf(address user, address token)
        public
        view
        returns (uint256)
    {
        if (token == MOCK_ETH_ADDRESS) {
            return user.balance; // ETH balance
            // check if token is actually a contract
        } else if (token.isContract()) {
            return IERC20(token).balanceOf(user);
        }
        revert("INVALID_TOKEN");
    }

    /**
     * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
     * @param users The list of users
     * @param tokens The list of tokens
     * @return And array with the concatenation of, for each user, his/her balances
     **/
    function batchBalanceOf(address[] calldata users, address[] calldata tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](users.length * tokens.length);

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                balances[i * tokens.length + j] = balanceOf(
                    users[i],
                    tokens[j]
                );
            }
        }

        return balances;
    }

    /**
    @dev provides balances of user wallet for all reserves available on the pool
    */
    function getUserWalletBalances(address provider, address user)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        IPool pool = IPool(IPoolAddressesProvider(provider).getPool());

        address[] memory reserves = pool.getReservesList();
        address[] memory reservesWithEth = new address[](reserves.length + 1);
        for (uint256 i = 0; i < reserves.length; i++) {
            reservesWithEth[i] = reserves[i];
        }
        reservesWithEth[reserves.length] = MOCK_ETH_ADDRESS;

        uint256[] memory balances = new uint256[](reservesWithEth.length);

        for (uint256 j = 0; j < reserves.length; j++) {
            DataTypes.ReserveConfigurationMap memory configuration = pool
                .getConfiguration(reservesWithEth[j]);

            (bool isActive, , , , ) = configuration.getFlags();

            if (!isActive) {
                balances[j] = 0;
                continue;
            }
            balances[j] = balanceOf(user, reservesWithEth[j]);
        }
        balances[reserves.length] = balanceOf(user, MOCK_ETH_ADDRESS);

        return (reservesWithEth, balances);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {GPv2SafeERC20} from "../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {SafeCast} from "../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {VersionedInitializable} from "../libraries/paraspace-upgradeability/VersionedInitializable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {IPToken} from "../../interfaces/IPToken.sol";
import {IRewardController} from "../../interfaces/IRewardController.sol";
import {IInitializablePToken} from "../../interfaces/IInitializablePToken.sol";
import {ScaledBalanceTokenBaseERC20} from "./base/ScaledBalanceTokenBaseERC20.sol";
import {IncentivizedERC20} from "./base/IncentivizedERC20.sol";
import {EIP712Base} from "./base/EIP712Base.sol";

/**
 * @title ParaSpace ERC20 PToken
 *
 * @notice Implementation of the interest bearing token for the ParaSpace protocol
 */
contract PToken is
    VersionedInitializable,
    ScaledBalanceTokenBaseERC20,
    EIP712Base,
    IPToken
{
    using WadRayMath for uint256;
    using SafeCast for uint256;
    using GPv2SafeERC20 for IERC20;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 public constant PTOKEN_REVISION = 0x1;

    address internal _treasury;
    address internal _underlyingAsset;

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return PTOKEN_REVISION;
    }

    /**
     * @dev Constructor.
     * @param pool The address of the Pool contract
     */
    constructor(IPool pool)
        ScaledBalanceTokenBaseERC20(pool, "PTOKEN_IMPL", "PTOKEN_IMPL", 0)
        EIP712Base()
    {
        // Intentionally left blank
    }

    /// @inheritdoc IInitializablePToken
    function initialize(
        IPool initializingPool,
        address treasury,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 pTokenDecimals,
        string calldata pTokenName,
        string calldata pTokenSymbol,
        bytes calldata params
    ) external override initializer {
        require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
        _setName(pTokenName);
        _setSymbol(pTokenSymbol);
        _setDecimals(pTokenDecimals);

        _treasury = treasury;
        _underlyingAsset = underlyingAsset;
        _rewardController = incentivesController;

        _domainSeparator = _calculateDomainSeparator();

        emit Initialized(
            underlyingAsset,
            address(POOL),
            treasury,
            address(incentivesController),
            pTokenDecimals,
            pTokenName,
            pTokenSymbol,
            params
        );
    }

    /// @inheritdoc IPToken
    function mint(
        address caller,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external virtual override onlyPool returns (bool) {
        return _mintScaled(caller, onBehalfOf, amount, index);
    }

    /// @inheritdoc IPToken
    function burn(
        address from,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external virtual override onlyPool {
        _burnScaled(from, receiverOfUnderlying, amount, index);
        if (receiverOfUnderlying != address(this)) {
            IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);
        }
    }

    /// @inheritdoc IPToken
    function mintToTreasury(uint256 amount, uint256 index)
        external
        override
        onlyPool
    {
        if (amount == 0) {
            return;
        }
        _mintScaled(address(POOL), _treasury, amount, index);
    }

    /// @inheritdoc IPToken
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external override onlyPool {
        // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
        // so no need to emit a specific event here
        _transfer(from, to, value, false);

        emit Transfer(from, to, value);
    }

    /// @inheritdoc IERC20
    function balanceOf(address user)
        public
        view
        virtual
        override(IncentivizedERC20, IERC20)
        returns (uint256)
    {
        return
            super.balanceOf(user).rayMul(
                POOL.getReserveNormalizedIncome(_underlyingAsset)
            );
    }

    /// @inheritdoc IERC20
    function totalSupply()
        public
        view
        virtual
        override(IncentivizedERC20, IERC20)
        returns (uint256)
    {
        uint256 currentSupplyScaled = super.totalSupply();

        if (currentSupplyScaled == 0) {
            return 0;
        }

        return
            currentSupplyScaled.rayMul(
                POOL.getReserveNormalizedIncome(_underlyingAsset)
            );
    }

    /// @inheritdoc IPToken
    function RESERVE_TREASURY_ADDRESS()
        external
        view
        override
        returns (address)
    {
        return _treasury;
    }

    /// @inheritdoc IPToken
    function UNDERLYING_ASSET_ADDRESS()
        external
        view
        override
        returns (address)
    {
        return _underlyingAsset;
    }

    /// @inheritdoc IPToken
    function transferUnderlyingTo(address target, uint256 amount)
        external
        virtual
        override
        onlyPool
    {
        IERC20(_underlyingAsset).safeTransfer(target, amount);
    }

    /// @inheritdoc IPToken
    function handleRepayment(address user, uint256 amount)
        external
        virtual
        override
        onlyPool
    {
        // Intentionally left blank
    }

    /// @inheritdoc IPToken
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        //solium-disable-next-line
        require(block.timestamp <= deadline, Errors.INVALID_EXPIRATION);
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        currentValidNonce,
                        deadline
                    )
                )
            )
        );
        require(owner == ecrecover(digest, v, r, s), Errors.INVALID_SIGNATURE);
        _nonces[owner] = currentValidNonce + 1;
        _approve(owner, spender, value);
    }

    /**
     * @notice Transfers the pTokens between two users. Validates the transfer
     * (ie checks for valid HF after the transfer) if required
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     * @param validate True if the transfer needs to be validated, false otherwise
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount,
        bool validate
    ) internal {
        address underlyingAsset = _underlyingAsset;

        uint256 index = POOL.getReserveNormalizedIncome(underlyingAsset);

        uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
        uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

        super._transfer(from, to, amount.rayDiv(index).toUint128());

        if (validate) {
            POOL.finalizeTransfer(
                underlyingAsset,
                from,
                to,
                false,
                amount,
                fromBalanceBefore,
                toBalanceBefore
            );
        }

        emit BalanceTransfer(from, to, amount, index);
    }

    /**
     * @notice Overrides the parent _transfer to force validated transfer() and transferFrom()
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     **/
    function _transfer(
        address from,
        address to,
        uint128 amount
    ) internal override {
        _transfer(from, to, amount, true);
    }

    /**
     * @dev Overrides the base function to fully implement IPToken
     * @dev see `IncentivizedERC20.DOMAIN_SEPARATOR()` for more detailed documentation
     */
    function DOMAIN_SEPARATOR()
        public
        view
        override(IPToken, EIP712Base)
        returns (bytes32)
    {
        return super.DOMAIN_SEPARATOR();
    }

    /**
     * @dev Overrides the base function to fully implement IPToken
     * @dev see `IncentivizedERC20.nonces()` for more detailed documentation
     */
    function nonces(address owner)
        public
        view
        override(IPToken, EIP712Base)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    /// @inheritdoc EIP712Base
    function _EIP712BaseId() internal view override returns (string memory) {
        return name();
    }

    /// @inheritdoc IPToken
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external override onlyPoolAdmin {
        require(token != _underlyingAsset, Errors.UNDERLYING_CANNOT_BE_RESCUED);
        IERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {IScaledBalanceToken} from "../../../interfaces/IScaledBalanceToken.sol";
import {MintableIncentivizedERC20} from "./MintableIncentivizedERC20.sol";

/**
 * @title ScaledBalanceTokenBase
 *
 * @notice Basic ERC20 implementation of scaled balance token
 **/
abstract contract ScaledBalanceTokenBaseERC20 is
    MintableIncentivizedERC20,
    IScaledBalanceToken
{
    using WadRayMath for uint256;
    using SafeCast for uint256;

    /**
     * @dev Constructor.
     * @param pool The reference to the main Pool contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     */
    constructor(
        IPool pool,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) MintableIncentivizedERC20(pool, name, symbol, decimals) {
        // Intentionally left blank
    }

    /// @inheritdoc IScaledBalanceToken
    function scaledBalanceOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return super.balanceOf(user);
    }

    /// @inheritdoc IScaledBalanceToken
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (super.balanceOf(user), super.totalSupply());
    }

    /// @inheritdoc IScaledBalanceToken
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.totalSupply();
    }

    /// @inheritdoc IScaledBalanceToken
    function getPreviousIndex(address user)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _userState[user].additionalData;
    }

    /**
     * @notice Implements the basic logic to mint a scaled balance token.
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the scaled tokens
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     **/
    function _mintScaled(
        address caller,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) internal returns (bool) {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.INVALID_MINT_AMOUNT);

        uint256 scaledBalance = super.balanceOf(onBehalfOf);
        uint256 balanceIncrease = scaledBalance.rayMul(index) -
            scaledBalance.rayMul(_userState[onBehalfOf].additionalData);

        _userState[onBehalfOf].additionalData = index.toUint128();

        _mint(onBehalfOf, amountScaled.toUint128());

        uint256 amountToMint = amount + balanceIncrease;
        emit Transfer(address(0), onBehalfOf, amountToMint);
        emit Mint(caller, onBehalfOf, amountToMint, balanceIncrease, index);

        return (scaledBalance == 0);
    }

    /**
     * @notice Implements the basic logic to burn a scaled balance token.
     * @dev In some instances, a burn transaction will emit a mint event
     * if the amount to burn is less than the interest that the user accrued
     * @param user The user which debt is burnt
     * @param target The address that will receive the underlying, if any
     * @param amount The amount getting burned
     * @param index The variable debt index of the reserve
     **/
    function _burnScaled(
        address user,
        address target,
        uint256 amount,
        uint256 index
    ) internal {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, Errors.INVALID_BURN_AMOUNT);

        uint256 scaledBalance = super.balanceOf(user);
        uint256 balanceIncrease = scaledBalance.rayMul(index) -
            scaledBalance.rayMul(_userState[user].additionalData);

        _userState[user].additionalData = index.toUint128();

        _burn(user, amountScaled.toUint128());

        if (balanceIncrease > amount) {
            uint256 amountToMint = balanceIncrease - amount;
            emit Transfer(address(0), user, amountToMint);
            emit Mint(user, user, amountToMint, balanceIncrease, index);
        } else {
            uint256 amountToBurn = amount - balanceIncrease;
            emit Transfer(user, address(0), amountToBurn);
            emit Burn(user, target, amountToBurn, balanceIncrease, index);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IRewardController} from "../../../interfaces/IRewardController.sol";
import {IPool} from "../../../interfaces/IPool.sol";
import {IncentivizedERC20} from "./IncentivizedERC20.sol";

/**
 * @title MintableIncentivizedERC20
 *
 * @notice Implements mint and burn functions for IncentivizedERC20
 **/
abstract contract MintableIncentivizedERC20 is IncentivizedERC20 {
    /**
     * @dev Constructor.
     * @param pool The reference to the main Pool contract
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param decimals The number of decimals of the token
     */
    constructor(
        IPool pool,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) IncentivizedERC20(pool, name, symbol, decimals) {
        // Intentionally left blank
    }

    /**
     * @notice Mints tokens to an account and apply incentives if defined
     * @param account The address receiving tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint128 amount) internal virtual {
        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply + amount;

        uint128 oldAccountBalance = _userState[account].balance;
        _userState[account].balance = oldAccountBalance + amount;

        IRewardController rewardControllerLocal = _rewardController;
        if (address(rewardControllerLocal) != address(0)) {
            rewardControllerLocal.handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    /**
     * @notice Burns tokens from an account and apply incentives if defined
     * @param account The account whose tokens are burnt
     * @param amount The amount of tokens to burn
     */
    function _burn(address account, uint128 amount) internal virtual {
        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply - amount;

        uint128 oldAccountBalance = _userState[account].balance;
        _userState[account].balance = oldAccountBalance - amount;

        IRewardController rewardControllerLocal = _rewardController;

        if (address(rewardControllerLocal) != address(0)) {
            rewardControllerLocal.handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPool} from "../../interfaces/IPool.sol";
import {IDelegationToken} from "../../interfaces/IDelegationToken.sol";
import {PToken} from "./PToken.sol";

/**
 * @title DelegationAwarePToken
 *
 * @notice PToken enabled to delegate voting power of the underlying asset to a different address
 * @dev The underlying asset needs to be compatible with the COMP delegation interface
 */
contract DelegationAwarePToken is PToken {
    /**
     * @dev Emitted when underlying voting power is delegated
     * @param delegatee The address of the delegatee
     */
    event DelegateUnderlyingTo(address indexed delegatee);

    /**
     * @dev Constructor.
     * @param pool The address of the Pool contract
     */
    constructor(IPool pool) PToken(pool) {
        // Intentionally left blank
    }

    /**
     * @notice Delegates voting power of the underlying asset to a `delegatee` address
     * @param delegatee The address that will receive the delegation
     **/
    function delegateUnderlyingTo(address delegatee) external onlyPoolAdmin {
        IDelegationToken(_underlyingAsset).delegate(delegatee);
        emit DelegateUnderlyingTo(delegatee);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IDelegationToken
 *
 * @notice Implements an interface for tokens with delegation COMP/UNI compatible
 **/
interface IDelegationToken {
    /**
     * @notice Delegate voting power to a delegatee
     * @param delegatee The address of the delegatee
     */
    function delegate(address delegatee) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {ERC20} from "../../dependencies/openzeppelin/contracts/ERC20.sol";
import {IDelegationToken} from "../../interfaces/IDelegationToken.sol";

/**
 * @title MintableDelegationERC20
 * @dev ERC20 minting logic with delegation
 */
contract MintableDelegationERC20 is IDelegationToken, ERC20 {
    address public delegatee;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    /**
     * @dev Function to mint tokens
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 value) public returns (bool) {
        _mint(msg.sender, value);
        return true;
    }

    function delegate(address delegateeAddress) external override {
        delegatee = delegateeAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library SafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x + y) >= x);
        }
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x);
        }
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @param message The error msg
    /// @return z The difference of x and y
    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x, message);
        }
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require(x == 0 || (z = x * y) / x == y);
        }
    }

    /// @notice Returns x / y, reverts if overflows - no specific check, solidity reverts on division by 0
    /// @param x The numerator
    /// @param y The denominator
    /// @return z The product of x and y
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {ERC20} from "../../dependencies/openzeppelin/contracts/ERC20.sol";
import {IERC20WithPermit} from "../../interfaces/IERC20WithPermit.sol";

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract MintableERC20 is IERC20WithPermit, ERC20 {
    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    // Map of address nonces (address => nonce)
    mapping(address => uint256) internal _nonces;

    bytes32 public DOMAIN_SEPARATOR;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol) {
        uint256 chainId = block.chainid;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN,
                keccak256(bytes(name)),
                keccak256(EIP712_REVISION),
                chainId,
                address(this)
            )
        );
        _setupDecimals(decimals);
    }

    /// @inheritdoc IERC20WithPermit
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner != address(0), "INVALID_OWNER");
        //solium-disable-next-line
        require(block.timestamp <= deadline, "INVALID_EXPIRATION");
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        currentValidNonce,
                        deadline
                    )
                )
            )
        );
        require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
        _nonces[owner] = currentValidNonce + 1;
        _approve(owner, spender, value);
    }

    /**
     * @dev Function to mint tokens
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 value) public returns (bool) {
        _mint(_msgSender(), value);
        return true;
    }

    /**
     * @dev Function to mint tokens to address
     * @param account The account to mint tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address account, uint256 value) public returns (bool) {
        _mint(account, value);
        return true;
    }

    function nonces(address owner) public view virtual returns (uint256) {
        return _nonces[owner];
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

/**
 * @title IERC20WithPermit
 *
 * @notice Interface for the permit function (EIP-2612)
 **/
interface IERC20WithPermit is IERC20 {
    /**
     * @notice Allow passing a signed message to approve spending
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VersionedInitializable} from "../libraries/paraspace-upgradeability/VersionedInitializable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {PoolLogic} from "../libraries/logic/PoolLogic.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {SupplyLogic} from "../libraries/logic/SupplyLogic.sol";
import {BorrowLogic} from "../libraries/logic/BorrowLogic.sol";
import {LiquidationLogic} from "../libraries/logic/LiquidationLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IERC20WithPermit} from "../../interfaces/IERC20WithPermit.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {PoolStorage} from "./PoolStorage.sol";
import {FlashClaimLogic} from "../libraries/logic/FlashClaimLogic.sol";
import {Address} from "../../dependencies/openzeppelin/contracts/Address.sol";

/**
 * @title Pool contract
 *
 * @notice Main point of interaction with an ParaSpace protocol's market
 * - Users can:
 *   # Supply
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Liquidate positions
 * @dev To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * @dev All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 **/
contract Pool is VersionedInitializable, PoolStorage, IPool {
    using ReserveLogic for DataTypes.ReserveData;

    uint256 public constant POOL_REVISION = 3;
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /**
     * @dev Only pool configurator can call functions marked by this modifier.
     **/
    modifier onlyPoolConfigurator() {
        _onlyPoolConfigurator();
        _;
    }

    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        _onlyPoolAdmin();
        _;
    }

    function _onlyPoolConfigurator() internal view virtual {
        require(
            ADDRESSES_PROVIDER.getPoolConfigurator() == msg.sender,
            Errors.CALLER_NOT_POOL_CONFIGURATOR
        );
    }

    function _onlyPoolAdmin() internal view virtual {
        require(
            IACLManager(ADDRESSES_PROVIDER.getACLManager()).isPoolAdmin(
                msg.sender
            ),
            Errors.CALLER_NOT_POOL_ADMIN
        );
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return POOL_REVISION;
    }

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     */
    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    /**
     * @notice Initializes the Pool.
     * @dev Function is invoked by the proxy contract when the Pool contract is added to the
     * PoolAddressesProvider of the market.
     * @dev Caching the address of the PoolAddressesProvider in order to reduce gas consumption on subsequent operations
     * @param provider The address of the PoolAddressesProvider
     **/
    function initialize(IPoolAddressesProvider provider)
        external
        virtual
        initializer
    {
        require(
            provider == ADDRESSES_PROVIDER,
            Errors.INVALID_ADDRESSES_PROVIDER
        );
        _maxStableRateBorrowSizePercent = 0.25e4;
    }

    /// @inheritdoc IPool
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external virtual override {
        SupplyLogic.executeSupply(
            _reserves,
            _usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyParams({
                asset: asset,
                amount: amount,
                onBehalfOf: onBehalfOf,
                referralCode: referralCode
            })
        );
    }

    /// @inheritdoc IPool
    function supplyERC721(
        address asset,
        DataTypes.ERC721SupplyParams[] calldata tokenData,
        address onBehalfOf,
        uint16 referralCode
    ) external virtual override {
        SupplyLogic.executeSupplyERC721(
            _reserves,
            _usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyERC721Params({
                asset: asset,
                tokenData: tokenData,
                onBehalfOf: onBehalfOf,
                referralCode: referralCode
            })
        );
    }

    /// @inheritdoc IPool
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external virtual override {
        // Need to accommodate ERC721 and ERC1155 here
        IERC20WithPermit(asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            permitV,
            permitR,
            permitS
        );
        SupplyLogic.executeSupply(
            _reserves,
            _usersConfig[onBehalfOf],
            DataTypes.ExecuteSupplyParams({
                asset: asset,
                amount: amount,
                onBehalfOf: onBehalfOf,
                referralCode: referralCode
            })
        );
    }

    /// @inheritdoc IPool
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external virtual override returns (uint256) {
        return
            SupplyLogic.executeWithdraw(
                _reserves,
                _reservesList,
                _usersConfig[msg.sender],
                DataTypes.ExecuteWithdrawParams({
                    asset: asset,
                    amount: amount,
                    to: to,
                    reservesCount: _reservesCount,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle()
                })
            );
    }

    /// @inheritdoc IPool
    function withdrawERC721(
        address asset,
        uint256[] calldata tokenIds,
        address to
    ) external virtual override returns (uint256) {
        return
            SupplyLogic.executeWithdrawERC721(
                _reserves,
                _reservesList,
                _usersConfig[msg.sender],
                DataTypes.ExecuteWithdrawERC721Params({
                    asset: asset,
                    tokenIds: tokenIds,
                    to: to,
                    reservesCount: _reservesCount,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle()
                })
            );
    }

    /// @inheritdoc IPool
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external virtual override {
        BorrowLogic.executeBorrow(
            _reserves,
            _reservesList,
            _usersConfig[onBehalfOf],
            DataTypes.ExecuteBorrowParams({
                asset: asset,
                user: msg.sender,
                onBehalfOf: onBehalfOf,
                amount: amount,
                interestRateMode: DataTypes.InterestRateMode(interestRateMode),
                referralCode: referralCode,
                releaseUnderlying: true,
                maxStableRateBorrowSizePercent: _maxStableRateBorrowSizePercent,
                reservesCount: _reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
            })
        );
    }

    /// @inheritdoc IPool
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external virtual override returns (uint256) {
        return
            BorrowLogic.executeRepay(
                _reserves,
                _usersConfig[onBehalfOf],
                DataTypes.ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    interestRateMode: DataTypes.InterestRateMode(
                        interestRateMode
                    ),
                    onBehalfOf: onBehalfOf,
                    usePTokens: false
                })
            );
    }

    /// @inheritdoc IPool
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external virtual override returns (uint256) {
        {
            IERC20WithPermit(asset).permit(
                msg.sender,
                address(this),
                amount,
                deadline,
                permitV,
                permitR,
                permitS
            );
        }
        {
            DataTypes.ExecuteRepayParams memory params = DataTypes
                .ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    interestRateMode: DataTypes.InterestRateMode(
                        interestRateMode
                    ),
                    onBehalfOf: onBehalfOf,
                    usePTokens: false
                });
            return
                BorrowLogic.executeRepay(
                    _reserves,
                    _usersConfig[onBehalfOf],
                    params
                );
        }
    }

    /// @inheritdoc IPool
    function repayWithPTokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external virtual override returns (uint256) {
        return
            BorrowLogic.executeRepay(
                _reserves,
                _usersConfig[msg.sender],
                DataTypes.ExecuteRepayParams({
                    asset: asset,
                    amount: amount,
                    interestRateMode: DataTypes.InterestRateMode(
                        interestRateMode
                    ),
                    onBehalfOf: msg.sender,
                    usePTokens: true
                })
            );
    }

    /// @inheritdoc IPool
    function swapBorrowRateMode(address asset, uint256 interestRateMode)
        external
        virtual
        override
    {
        BorrowLogic.executeSwapBorrowRateMode(
            _reserves[asset],
            _usersConfig[msg.sender],
            asset,
            DataTypes.InterestRateMode(interestRateMode)
        );
    }

    /// @inheritdoc IPool
    function rebalanceStableBorrowRate(address asset, address user)
        external
        virtual
        override
    {
        BorrowLogic.executeRebalanceStableBorrowRate(
            _reserves[asset],
            asset,
            user
        );
    }

    /// @inheritdoc IPool
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external
        virtual
        override
    {
        SupplyLogic.executeUseReserveAsCollateral(
            _reserves,
            _reservesList,
            _usersConfig[msg.sender],
            asset,
            useAsCollateral,
            _reservesCount,
            ADDRESSES_PROVIDER.getPriceOracle()
        );
    }

    function setUserUseERC721AsCollateral(
        address asset,
        uint256 tokenId,
        bool useAsCollateral
    ) external virtual override {
        SupplyLogic.executeUseERC721AsCollateral(
            _reserves,
            _reservesList,
            _usersConfig[msg.sender],
            asset,
            tokenId,
            useAsCollateral,
            _reservesCount,
            ADDRESSES_PROVIDER.getPriceOracle()
        );
    }

    /// @inheritdoc IPool
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receivePToken
    ) external virtual override {
        LiquidationLogic.executeLiquidationCall(
            _reserves,
            _reservesList,
            _usersConfig,
            DataTypes.ExecuteLiquidationCallParams({
                reservesCount: _reservesCount,
                liquidationAmount: debtToCover,
                collateralAsset: collateralAsset,
                liquidationAsset: debtAsset,
                user: user,
                receiveXToken: receivePToken,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel(),
                collateralTokenId: 0
            })
        );
    }

    /// @inheritdoc IPool
    function liquidationERC721(
        address collateralAsset,
        address liquidationAsset,
        address user,
        uint256 collateralTokenId,
        uint256 liquidationAmount,
        bool receiveNToken
    ) external virtual override {
        LiquidationLogic.executeERC721LiquidationCall(
            _reserves,
            _reservesList,
            _usersConfig,
            DataTypes.ExecuteLiquidationCallParams({
                reservesCount: _reservesCount,
                liquidationAmount: liquidationAmount,
                liquidationAsset: liquidationAsset,
                collateralAsset: collateralAsset,
                collateralTokenId: collateralTokenId,
                user: user,
                receiveXToken: receiveNToken,
                priceOracle: ADDRESSES_PROVIDER.getPriceOracle(),
                priceOracleSentinel: ADDRESSES_PROVIDER.getPriceOracleSentinel()
            })
        );
    }

    /// @inheritdoc IPool
    function flashClaim(
        address receiverAddress,
        address nftAsset,
        uint256[] calldata nftTokenIds,
        bytes calldata params
    ) external virtual override {
        FlashClaimLogic.executeFlashClaim(
            _reserves,
            DataTypes.ExecuteFlashClaimParams({
                receiverAddress: receiverAddress,
                nftAsset: nftAsset,
                nftTokenIds: nftTokenIds,
                params: params
            })
        );
    }

    /// @inheritdoc IPool
    function mintToTreasury(address[] calldata assets)
        external
        virtual
        override
    {
        PoolLogic.executeMintToTreasury(_reserves, assets);
    }

    /// @inheritdoc IPool
    function getReserveData(address asset)
        external
        view
        virtual
        override
        returns (DataTypes.ReserveData memory)
    {
        return _reserves[asset];
    }

    /// @inheritdoc IPool
    function getUserAccountData(address user)
        external
        view
        virtual
        override
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 erc721HealthFactor
        )
    {
        return
            PoolLogic.executeGetUserAccountData(
                _reserves,
                _reservesList,
                DataTypes.CalculateUserAccountDataParams({
                    userConfig: _usersConfig[user],
                    reservesCount: _reservesCount,
                    user: user,
                    oracle: ADDRESSES_PROVIDER.getPriceOracle()
                })
            );
    }

    /// @inheritdoc IPool
    function getConfiguration(address asset)
        external
        view
        virtual
        override
        returns (DataTypes.ReserveConfigurationMap memory)
    {
        return _reserves[asset].configuration;
    }

    /// @inheritdoc IPool
    function getUserConfiguration(address user)
        external
        view
        virtual
        override
        returns (DataTypes.UserConfigurationMap memory)
    {
        return _usersConfig[user];
    }

    /// @inheritdoc IPool
    function getReserveNormalizedIncome(address asset)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _reserves[asset].getNormalizedIncome();
    }

    /// @inheritdoc IPool
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _reserves[asset].getNormalizedDebt();
    }

    /// @inheritdoc IPool
    function getReservesList()
        external
        view
        virtual
        override
        returns (address[] memory)
    {
        uint256 reservesListCount = _reservesCount;
        uint256 droppedReservesCount = 0;
        address[] memory reservesList = new address[](reservesListCount);

        for (uint256 i = 0; i < reservesListCount; i++) {
            if (_reservesList[i] != address(0)) {
                reservesList[i - droppedReservesCount] = _reservesList[i];
            } else {
                droppedReservesCount++;
            }
        }

        // Reduces the length of the reserves array by `droppedReservesCount`
        assembly {
            mstore(reservesList, sub(reservesListCount, droppedReservesCount))
        }
        return reservesList;
    }

    /// @inheritdoc IPool
    function getReserveAddressById(uint16 id) external view returns (address) {
        return _reservesList[id];
    }

    /// @inheritdoc IPool
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _maxStableRateBorrowSizePercent;
    }

    /// @inheritdoc IPool
    function MAX_NUMBER_RESERVES()
        public
        view
        virtual
        override
        returns (uint16)
    {
        return ReserveConfiguration.MAX_RESERVES_COUNT;
    }

    /// @inheritdoc IPool
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        bool usedAsCollateral,
        uint256 value,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external virtual override {
        require(
            msg.sender == _reserves[asset].xTokenAddress,
            Errors.CALLER_NOT_XTOKEN
        );
        SupplyLogic.executeFinalizeTransfer(
            _reserves,
            _reservesList,
            _usersConfig,
            DataTypes.FinalizeTransferParams({
                asset: asset,
                from: from,
                to: to,
                usedAsCollateral: usedAsCollateral,
                value: value,
                balanceFromBefore: balanceFromBefore,
                balanceToBefore: balanceToBefore,
                reservesCount: _reservesCount,
                oracle: ADDRESSES_PROVIDER.getPriceOracle()
            })
        );
    }

    /// @inheritdoc IPool
    function initReserve(
        address asset,
        DataTypes.AssetType assetType,
        address xTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external virtual override onlyPoolConfigurator {
        if (
            PoolLogic.executeInitReserve(
                _reserves,
                _reservesList,
                DataTypes.InitReserveParams({
                    asset: asset,
                    assetType: assetType,
                    xTokenAddress: xTokenAddress,
                    stableDebtAddress: stableDebtAddress,
                    variableDebtAddress: variableDebtAddress,
                    interestRateStrategyAddress: interestRateStrategyAddress,
                    reservesCount: _reservesCount,
                    maxNumberReserves: MAX_NUMBER_RESERVES()
                })
            )
        ) {
            _reservesCount++;
        }
    }

    /// @inheritdoc IPool
    function dropReserve(address asset)
        external
        virtual
        override
        onlyPoolConfigurator
    {
        PoolLogic.executeDropReserve(_reserves, _reservesList, asset);
    }

    /// @inheritdoc IPool
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external virtual override onlyPoolConfigurator {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            _reserves[asset].id != 0 || _reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        _reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
    }

    /// @inheritdoc IPool
    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    ) external virtual override onlyPoolConfigurator {
        require(asset != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        require(
            _reserves[asset].id != 0 || _reservesList[0] == asset,
            Errors.ASSET_NOT_LISTED
        );
        _reserves[asset].configuration = configuration;
    }

    /// @inheritdoc IPool
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external virtual override onlyPoolAdmin {
        PoolLogic.executeRescueTokens(token, to, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {Address} from "../../../dependencies/openzeppelin/contracts/Address.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";

/**
 * @title PoolLogic library
 *
 * @notice Implements the logic for Pool specific functions
 */
library PoolLogic {
    using GPv2SafeERC20 for IERC20;
    using WadRayMath for uint256;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    // See `IPool` for descriptions
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @notice Initialize an asset reserve and add the reserve to the list of reserves
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for initiation
     * @return true if appended, false if inserted at existing empty spot
     **/
    function executeInitReserve(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.InitReserveParams memory params
    ) external returns (bool) {
        require(Address.isContract(params.asset), Errors.NOT_CONTRACT);
        reservesData[params.asset].init(
            params.xTokenAddress,
            params.assetType,
            params.stableDebtAddress,
            params.variableDebtAddress,
            params.interestRateStrategyAddress
        );

        bool reserveAlreadyAdded = reservesData[params.asset].id != 0 ||
            reservesList[0] == params.asset;
        require(!reserveAlreadyAdded, Errors.RESERVE_ALREADY_ADDED);

        for (uint16 i = 0; i < params.reservesCount; i++) {
            if (reservesList[i] == address(0)) {
                reservesData[params.asset].id = i;
                reservesList[i] = params.asset;
                return false;
            }
        }

        require(
            params.reservesCount < params.maxNumberReserves,
            Errors.NO_MORE_RESERVES_ALLOWED
        );
        reservesData[params.asset].id = params.reservesCount;
        reservesList[params.reservesCount] = params.asset;
        return true;
    }

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function executeRescueTokens(
        address token,
        address to,
        uint256 amount
    ) external {
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of xTokens
     * @param reservesData The state of all the reserves
     * @param assets The list of reserves for which the minting needs to be executed
     **/
    function executeMintToTreasury(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        address[] calldata assets
    ) external {
        for (uint256 i = 0; i < assets.length; i++) {
            address assetAddress = assets[i];

            DataTypes.ReserveData storage reserve = reservesData[assetAddress];

            // this cover both inactive reserves and invalid reserves since the flag will be 0 for both
            if (!reserve.configuration.getActive()) {
                continue;
            }

            uint256 accruedToTreasury = reserve.accruedToTreasury;

            if (accruedToTreasury != 0) {
                reserve.accruedToTreasury = 0;
                uint256 normalizedIncome = reserve.getNormalizedIncome();
                uint256 amountToMint = accruedToTreasury.rayMul(
                    normalizedIncome
                );
                IPToken(reserve.xTokenAddress).mintToTreasury(
                    amountToMint,
                    normalizedIncome
                );

                emit MintedToTreasury(assetAddress, amountToMint);
            }
        }
    }

    /**
     * @notice Drop a reserve
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param asset The address of the underlying asset of the reserve
     **/
    function executeDropReserve(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        address asset
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        ValidationLogic.validateDropReserve(reservesList, reserve, asset);
        reservesList[reservesData[asset].id] = address(0);
        delete reservesData[asset];
    }

    /**
     * @notice Returns the user account data across all the reserves
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional params needed for the calculation
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function executeGetUserAccountData(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.CalculateUserAccountDataParams memory params
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 erc721HealthFactor
        )
    {
        (
            totalCollateralBase,
            ,
            totalDebtBase,
            ltv,
            currentLiquidationThreshold,
            ,
            ,
            healthFactor,
            erc721HealthFactor,

        ) = GenericLogic.calculateUserAccountData(
            reservesData,
            reservesList,
            params
        );

        availableBorrowsBase = GenericLogic.calculateAvailableBorrows(
            totalCollateralBase,
            totalDebtBase,
            ltv
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {GPv2SafeERC20} from "../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IStableDebtToken} from "../../../interfaces/IStableDebtToken.sol";
import {IVariableDebtToken} from "../../../interfaces/IVariableDebtToken.sol";
import {IPToken} from "../../../interfaces/IPToken.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {Helpers} from "../helpers/Helpers.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

/**
 * @title BorrowLogic library
 *
 * @notice Implements the base logic for all the actions related to borrowing
 */
library BorrowLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using GPv2SafeERC20 for IERC20;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    // See `IPool` for descriptions
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool usePTokens
    );
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        DataTypes.InterestRateMode interestRateMode
    );

    /**
     * @notice Implements the borrow feature. Borrowing allows users that provided collateral to draw liquidity from the
     * ParaSpace protocol proportionally to their collateralization power. For isolated positions, it also increases the
     * isolated debt.
     * @dev  Emits the `Borrow()` event
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the borrow function
     */
    function executeBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteBorrowParams memory params
    ) public {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        ValidationLogic.validateBorrow(
            reservesData,
            reservesList,
            DataTypes.ValidateBorrowParams({
                reserveCache: reserveCache,
                userConfig: userConfig,
                asset: params.asset,
                userAddress: params.onBehalfOf,
                amount: params.amount,
                interestRateMode: params.interestRateMode,
                maxStableLoanPercent: params.maxStableRateBorrowSizePercent,
                reservesCount: params.reservesCount,
                oracle: params.oracle,
                priceOracleSentinel: params.priceOracleSentinel,
                assetType: reserveCache.assetType
            })
        );

        uint256 currentStableRate = 0;
        bool isFirstBorrowing = false;

        if (params.interestRateMode == DataTypes.InterestRateMode.STABLE) {
            currentStableRate = reserve.currentStableBorrowRate;

            (
                isFirstBorrowing,
                reserveCache.nextTotalStableDebt,
                reserveCache.nextAvgStableBorrowRate
            ) = IStableDebtToken(reserveCache.stableDebtTokenAddress).mint(
                params.user,
                params.onBehalfOf,
                params.amount,
                currentStableRate
            );
        } else {
            (
                isFirstBorrowing,
                reserveCache.nextScaledVariableDebt
            ) = IVariableDebtToken(reserveCache.variableDebtTokenAddress).mint(
                params.user,
                params.onBehalfOf,
                params.amount,
                reserveCache.nextVariableBorrowIndex
            );
        }

        if (isFirstBorrowing) {
            userConfig.setBorrowing(reserve.id, true);
        }

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            0,
            params.releaseUnderlying ? params.amount : 0
        );

        if (params.releaseUnderlying) {
            IPToken(reserveCache.xTokenAddress).transferUnderlyingTo(
                params.user,
                params.amount
            );
        }

        emit Borrow(
            params.asset,
            params.user,
            params.onBehalfOf,
            params.amount,
            params.interestRateMode,
            params.interestRateMode == DataTypes.InterestRateMode.STABLE
                ? currentStableRate
                : reserve.currentVariableBorrowRate,
            params.referralCode
        );
    }

    /**
     * @notice Implements the repay feature. Repaying transfers the underlying back to the xToken and clears the
     * equivalent amount of debt for the user by burning the corresponding debt token. For isolated positions, it also
     * reduces the isolated debt.
     * @dev  Emits the `Repay()` event
     * @param reservesData The state of all the reserves
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param params The additional parameters needed to execute the repay function
     * @return The actual amount being repaid
     */
    function executeRepay(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        DataTypes.ExecuteRepayParams memory params
    ) external returns (uint256) {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        DataTypes.ReserveCache memory reserveCache = reserve.cache();
        reserve.updateState(reserveCache);

        (uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(
            params.onBehalfOf,
            reserveCache
        );

        ValidationLogic.validateRepay(
            reserveCache,
            params.amount,
            params.interestRateMode,
            params.onBehalfOf,
            stableDebt,
            variableDebt
        );

        uint256 paybackAmount = params.interestRateMode ==
            DataTypes.InterestRateMode.STABLE
            ? stableDebt
            : variableDebt;

        // Allows a user to repay with xTokens without leaving dust from interest.
        if (params.usePTokens && params.amount == type(uint256).max) {
            params.amount = IPToken(reserveCache.xTokenAddress).balanceOf(
                msg.sender
            );
        }

        // if amount user is sending is less than payback amount (debt), update the payback amount to what the user is sending
        if (params.amount < paybackAmount) {
            paybackAmount = params.amount;
        }

        if (params.interestRateMode == DataTypes.InterestRateMode.STABLE) {
            (
                reserveCache.nextTotalStableDebt,
                reserveCache.nextAvgStableBorrowRate
            ) = IStableDebtToken(reserveCache.stableDebtTokenAddress).burn(
                params.onBehalfOf,
                paybackAmount
            );
        } else {
            reserveCache.nextScaledVariableDebt = IVariableDebtToken(
                reserveCache.variableDebtTokenAddress
            ).burn(
                    params.onBehalfOf,
                    paybackAmount,
                    reserveCache.nextVariableBorrowIndex
                );
        }

        reserve.updateInterestRates(
            reserveCache,
            params.asset,
            params.usePTokens ? 0 : paybackAmount,
            0
        );

        if (stableDebt + variableDebt - paybackAmount == 0) {
            userConfig.setBorrowing(reserve.id, false);
        }

        if (params.usePTokens) {
            IPToken(reserveCache.xTokenAddress).burn(
                msg.sender,
                reserveCache.xTokenAddress,
                paybackAmount,
                reserveCache.nextLiquidityIndex
            );
        } else {
            // send paybackAmount from user to reserve
            IERC20(params.asset).safeTransferFrom(
                msg.sender,
                reserveCache.xTokenAddress,
                paybackAmount
            );
            IPToken(reserveCache.xTokenAddress).handleRepayment(
                msg.sender,
                paybackAmount
            );
        }

        emit Repay(
            params.asset,
            params.onBehalfOf,
            msg.sender,
            paybackAmount,
            params.usePTokens
        );

        return paybackAmount;
    }

    /**
     * @notice Implements the rebalance stable borrow rate feature. In case of liquidity crunches on the protocol, stable
     * rate borrows might need to be rebalanced to bring back equilibrium between the borrow and supply APYs.
     * @dev The rules that define if a position can be rebalanced are implemented in `ValidationLogic.validateRebalanceStableBorrowRate()`
     * @dev Emits the `RebalanceStableBorrowRate()` event
     * @param reserve The state of the reserve of the asset being repaid
     * @param asset The asset of the position being rebalanced
     * @param user The user being rebalanced
     */
    function executeRebalanceStableBorrowRate(
        DataTypes.ReserveData storage reserve,
        address asset,
        address user
    ) external {
        DataTypes.ReserveCache memory reserveCache = reserve.cache();
        reserve.updateState(reserveCache);

        ValidationLogic.validateRebalanceStableBorrowRate(
            reserve,
            reserveCache,
            asset
        );

        IStableDebtToken stableDebtToken = IStableDebtToken(
            reserveCache.stableDebtTokenAddress
        );
        uint256 stableDebt = IERC20(address(stableDebtToken)).balanceOf(user);

        stableDebtToken.burn(user, stableDebt);

        (
            ,
            reserveCache.nextTotalStableDebt,
            reserveCache.nextAvgStableBorrowRate
        ) = stableDebtToken.mint(
            user,
            user,
            stableDebt,
            reserve.currentStableBorrowRate
        );

        reserve.updateInterestRates(reserveCache, asset, 0, 0);

        emit RebalanceStableBorrowRate(asset, user);
    }

    /**
     * @notice Implements the swap borrow rate feature. Borrowers can swap from variable to stable positions at any time.
     * @dev Emits the `Swap()` event
     * @param reserve The of the reserve of the asset being repaid
     * @param userConfig The user configuration mapping that tracks the supplied/borrowed assets
     * @param asset The asset of the position being swapped
     * @param interestRateMode The current interest rate mode of the position being swapped
     */
    function executeSwapBorrowRateMode(
        DataTypes.ReserveData storage reserve,
        DataTypes.UserConfigurationMap storage userConfig,
        address asset,
        DataTypes.InterestRateMode interestRateMode
    ) external {
        DataTypes.ReserveCache memory reserveCache = reserve.cache();

        reserve.updateState(reserveCache);

        (uint256 stableDebt, uint256 variableDebt) = Helpers.getUserCurrentDebt(
            msg.sender,
            reserveCache
        );

        ValidationLogic.validateSwapRateMode(
            reserve,
            reserveCache,
            userConfig,
            stableDebt,
            variableDebt,
            interestRateMode
        );

        if (interestRateMode == DataTypes.InterestRateMode.STABLE) {
            (
                reserveCache.nextTotalStableDebt,
                reserveCache.nextAvgStableBorrowRate
            ) = IStableDebtToken(reserveCache.stableDebtTokenAddress).burn(
                msg.sender,
                stableDebt
            );

            (, reserveCache.nextScaledVariableDebt) = IVariableDebtToken(
                reserveCache.variableDebtTokenAddress
            ).mint(
                    msg.sender,
                    msg.sender,
                    stableDebt,
                    reserveCache.nextVariableBorrowIndex
                );
        } else {
            reserveCache.nextScaledVariableDebt = IVariableDebtToken(
                reserveCache.variableDebtTokenAddress
            ).burn(
                    msg.sender,
                    variableDebt,
                    reserveCache.nextVariableBorrowIndex
                );

            (
                ,
                reserveCache.nextTotalStableDebt,
                reserveCache.nextAvgStableBorrowRate
            ) = IStableDebtToken(reserveCache.stableDebtTokenAddress).mint(
                msg.sender,
                msg.sender,
                variableDebt,
                reserve.currentStableBorrowRate
            );
        }

        reserve.updateInterestRates(reserveCache, asset, 0, 0);

        emit SwapBorrowRateMode(asset, msg.sender, interestRateMode);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Errors} from "../libraries/helpers/Errors.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IPriceOracleSentinel} from "../../interfaces/IPriceOracleSentinel.sol";
import {ISequencerOracle} from "../../interfaces/ISequencerOracle.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";

/**
 * @title PriceOracleSentinel
 *
 * @notice It validates if operations are allowed depending on the PriceOracle health.
 * @dev Once the PriceOracle gets up after an outage/downtime, users can make their positions healthy during a grace
 *  period. So the PriceOracle is considered completely up once its up and the grace period passed.
 */
contract PriceOracleSentinel is IPriceOracleSentinel {
    /**
     * @dev Only pool admin can call functions marked by this modifier.
     **/
    modifier onlyPoolAdmin() {
        IACLManager aclManager = IACLManager(
            ADDRESSES_PROVIDER.getACLManager()
        );
        require(
            aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    /**
     * @dev Only risk or pool admin can call functions marked by this modifier.
     **/
    modifier onlyRiskOrPoolAdmins() {
        IACLManager aclManager = IACLManager(
            ADDRESSES_PROVIDER.getACLManager()
        );
        require(
            aclManager.isRiskAdmin(msg.sender) ||
                aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_RISK_OR_POOL_ADMIN
        );
        _;
    }

    IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;

    ISequencerOracle internal _sequencerOracle;

    uint256 internal _gracePeriod;

    /**
     * @dev Constructor
     * @param provider The address of the PoolAddressesProvider
     * @param oracle The address of the SequencerOracle
     * @param gracePeriod The duration of the grace period in seconds
     */
    constructor(
        IPoolAddressesProvider provider,
        ISequencerOracle oracle,
        uint256 gracePeriod
    ) {
        ADDRESSES_PROVIDER = provider;
        _sequencerOracle = oracle;
        _gracePeriod = gracePeriod;
    }

    /// @inheritdoc IPriceOracleSentinel
    function isBorrowAllowed() external view override returns (bool) {
        return _isUpAndGracePeriodPassed();
    }

    /// @inheritdoc IPriceOracleSentinel
    function isLiquidationAllowed() external view override returns (bool) {
        return _isUpAndGracePeriodPassed();
    }

    /**
     * @notice Checks the sequencer oracle is healthy: is up and grace period passed.
     * @return True if the SequencerOracle is up and the grace period passed, false otherwise
     */
    function _isUpAndGracePeriodPassed() internal view returns (bool) {
        (, int256 answer, , uint256 lastUpdateTimestamp, ) = _sequencerOracle
            .latestRoundData();
        return
            answer == 0 && block.timestamp - lastUpdateTimestamp > _gracePeriod;
    }

    /// @inheritdoc IPriceOracleSentinel
    function setSequencerOracle(address newSequencerOracle)
        external
        onlyPoolAdmin
    {
        _sequencerOracle = ISequencerOracle(newSequencerOracle);
        emit SequencerOracleUpdated(newSequencerOracle);
    }

    /// @inheritdoc IPriceOracleSentinel
    function setGracePeriod(uint256 newGracePeriod)
        external
        onlyRiskOrPoolAdmins
    {
        _gracePeriod = newGracePeriod;
        emit GracePeriodUpdated(newGracePeriod);
    }

    /// @inheritdoc IPriceOracleSentinel
    function getSequencerOracle() external view returns (address) {
        return address(_sequencerOracle);
    }

    /// @inheritdoc IPriceOracleSentinel
    function getGracePeriod() external view returns (uint256) {
        return _gracePeriod;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title ISequencerOracle
 *
 * @notice Defines the basic interface for a Sequencer oracle.
 */
interface ISequencerOracle {
    /**
     * @notice Returns the health status of the sequencer.
     * @return roundId The round ID from the aggregator for which the data was retrieved combined with a phase to ensure
     * that round IDs get larger as time moves forward.
     * @return answer The answer for the latest round: 0 if the sequencer is up, 1 if it is down.
     * @return startedAt The timestamp when the round was started.
     * @return updatedAt The timestamp of the block in which the answer was updated on L1.
     * @return answeredInRound The round ID of the round in which the answer was computed.
     */
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";
import {ISequencerOracle} from "../../interfaces/ISequencerOracle.sol";

contract SequencerOracle is ISequencerOracle, Ownable {
    bool internal _isDown;
    uint256 internal _timestampGotUp;

    /**
     * @dev Constructor.
     * @param owner The owner address of this contract
     */
    constructor(address owner) {
        transferOwnership(owner);
    }

    /**
     * @notice Updates the health status of the sequencer.
     * @param isDown True if the sequencer is down, false otherwise
     * @param timestamp The timestamp of last time the sequencer got up
     */
    function setAnswer(bool isDown, uint256 timestamp) external onlyOwner {
        _isDown = isDown;
        _timestampGotUp = timestamp;
    }

    /// @inheritdoc ISequencerOracle
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        int256 isDown;
        if (_isDown) {
            isDown = 1;
        }
        return (0, isDown, 0, _timestampGotUp, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IPoolAddressesProviderRegistry} from "../../interfaces/IPoolAddressesProviderRegistry.sol";

/**
 * @title PoolAddressesProviderRegistry
 *
 * @notice Main registry of PoolAddressesProvider of ParaSpace markets.
 * @dev Used for indexing purposes of ParaSpace protocol's markets. The id assigned to a PoolAddressesProvider refers to the
 * market it is connected with, for example with `1` for the ParaSpace main market and `2` for the next created.
 **/
contract PoolAddressesProviderRegistry is
    Ownable,
    IPoolAddressesProviderRegistry
{
    // Map of address provider ids (addressesProvider => id)
    mapping(address => uint256) private _addressesProviderToId;
    // Map of id to address provider (id => addressesProvider)
    mapping(uint256 => address) private _idToAddressesProvider;
    // List of addresses providers
    address[] private _addressesProvidersList;
    // Map of address provider list indexes (addressesProvider => indexInList)
    mapping(address => uint256) private _addressesProvidersIndexes;

    /**
     * @dev Constructor.
     * @param owner The owner address of this contract.
     */
    constructor(address owner) {
        transferOwnership(owner);
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function getAddressesProvidersList()
        external
        view
        override
        returns (address[] memory)
    {
        return _addressesProvidersList;
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function registerAddressesProvider(address provider, uint256 id)
        external
        override
        onlyOwner
    {
        require(id != 0, Errors.INVALID_ADDRESSES_PROVIDER_ID);
        require(provider != address(0x0), Errors.INVALID_ADDRESSES_PROVIDER);

        require(
            _idToAddressesProvider[id] == address(0),
            Errors.INVALID_ADDRESSES_PROVIDER_ID
        );
        require(
            _addressesProviderToId[provider] == 0,
            Errors.ADDRESSES_PROVIDER_ALREADY_ADDED
        );

        _addressesProviderToId[provider] = id;
        _idToAddressesProvider[id] = provider;

        _addToAddressesProvidersList(provider);
        emit AddressesProviderRegistered(provider, id);
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function unregisterAddressesProvider(address provider)
        external
        override
        onlyOwner
    {
        require(
            _addressesProviderToId[provider] != 0,
            Errors.ADDRESSES_PROVIDER_NOT_REGISTERED
        );
        uint256 oldId = _addressesProviderToId[provider];
        _idToAddressesProvider[oldId] = address(0);
        _addressesProviderToId[provider] = 0;

        _removeFromAddressesProvidersList(provider);

        emit AddressesProviderUnregistered(provider, oldId);
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function getAddressesProviderIdByAddress(address addressesProvider)
        external
        view
        override
        returns (uint256)
    {
        return _addressesProviderToId[addressesProvider];
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function getAddressesProviderAddressById(uint256 id)
        external
        view
        override
        returns (address)
    {
        return _idToAddressesProvider[id];
    }

    /**
     * @notice Adds the addresses provider address to the list.
     * @param provider The address of the PoolAddressesProvider
     */
    function _addToAddressesProvidersList(address provider) internal {
        _addressesProvidersIndexes[provider] = _addressesProvidersList.length;
        _addressesProvidersList.push(provider);
    }

    /**
     * @notice Removes the addresses provider address from the list.
     * @param provider The address of the PoolAddressesProvider
     */
    function _removeFromAddressesProvidersList(address provider) internal {
        uint256 index = _addressesProvidersIndexes[provider];

        _addressesProvidersIndexes[provider] = 0;

        // Swap the index of the last addresses provider in the list with the index of the provider to remove
        uint256 lastIndex = _addressesProvidersList.length - 1;
        if (index < lastIndex) {
            address lastProvider = _addressesProvidersList[lastIndex];
            _addressesProvidersList[index] = lastProvider;
            _addressesProvidersIndexes[lastProvider] = index;
        }
        _addressesProvidersList.pop();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title IPoolAddressesProviderRegistry
 *
 * @notice Defines the basic interface for an ParaSpace Pool Addresses Provider Registry.
 **/
interface IPoolAddressesProviderRegistry {
    /**
     * @dev Emitted when a new AddressesProvider is registered.
     * @param addressesProvider The address of the registered PoolAddressesProvider
     * @param id The id of the registered PoolAddressesProvider
     */
    event AddressesProviderRegistered(
        address indexed addressesProvider,
        uint256 indexed id
    );

    /**
     * @dev Emitted when an AddressesProvider is unregistered.
     * @param addressesProvider The address of the unregistered PoolAddressesProvider
     * @param id The id of the unregistered PoolAddressesProvider
     */
    event AddressesProviderUnregistered(
        address indexed addressesProvider,
        uint256 indexed id
    );

    /**
     * @notice Returns the list of registered addresses providers
     * @return The list of addresses providers
     **/
    function getAddressesProvidersList()
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns the id of a registered PoolAddressesProvider
     * @param addressesProvider The address of the PoolAddressesProvider
     * @return The id of the PoolAddressesProvider or 0 if is not registered
     */
    function getAddressesProviderIdByAddress(address addressesProvider)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the address of a registered PoolAddressesProvider
     * @param id The id of the market
     * @return The address of the PoolAddressesProvider with the given id or zero address if it is not registered
     */
    function getAddressesProviderAddressById(uint256 id)
        external
        view
        returns (address);

    /**
     * @notice Registers an addresses provider
     * @dev The PoolAddressesProvider must not already be registered in the registry
     * @dev The id must not be used by an already registered PoolAddressesProvider
     * @param provider The address of the new PoolAddressesProvider
     * @param id The id for the new PoolAddressesProvider, referring to the market it belongs to
     **/
    function registerAddressesProvider(address provider, uint256 id) external;

    /**
     * @notice Removes an addresses provider from the list of registered addresses providers
     * @param provider The PoolAddressesProvider address
     **/
    function unregisterAddressesProvider(address provider) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "../libraries/paraspace-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";

/**
 * @title PoolAddressesProvider
 *
 * @notice Main registry of addresses part of or connected to the protocol, including permissioned roles
 * @dev Acts as factory of proxies and admin of those, so with right to change its implementations
 * @dev Owned by the ParaSpace Governance
 **/
contract PoolAddressesProvider is Ownable, IPoolAddressesProvider {
    // Identifier of the ParaSpace Market
    string private _marketId;

    // Map of registered addresses (identifier => registeredAddress)
    mapping(bytes32 => address) private _addresses;

    // Main identifiers
    bytes32 private constant POOL = "POOL";
    bytes32 private constant POOL_CONFIGURATOR = "POOL_CONFIGURATOR";
    bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 private constant ACL_MANAGER = "ACL_MANAGER";
    bytes32 private constant ACL_ADMIN = "ACL_ADMIN";
    bytes32 private constant PRICE_ORACLE_SENTINEL = "PRICE_ORACLE_SENTINEL";
    bytes32 private constant DATA_PROVIDER = "DATA_PROVIDER";

    /**
     * @dev Constructor.
     * @param marketId The identifier of the market.
     * @param owner The owner address of this contract.
     */
    constructor(string memory marketId, address owner) {
        _setMarketId(marketId);
        transferOwnership(owner);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getMarketId() external view override returns (string memory) {
        return _marketId;
    }

    /// @inheritdoc IPoolAddressesProvider
    function setMarketId(string memory newMarketId)
        external
        override
        onlyOwner
    {
        _setMarketId(newMarketId);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    /// @inheritdoc IPoolAddressesProvider
    function setAddress(bytes32 id, address newAddress)
        external
        override
        onlyOwner
    {
        address oldAddress = _addresses[id];
        _addresses[id] = newAddress;
        emit AddressSet(id, oldAddress, newAddress);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setAddressAsProxy(bytes32 id, address newImplementationAddress)
        external
        override
        onlyOwner
    {
        address proxyAddress = _addresses[id];
        address oldImplementationAddress = _getProxyImplementation(id);
        _updateImpl(id, newImplementationAddress);
        emit AddressSetAsProxy(
            id,
            proxyAddress,
            oldImplementationAddress,
            newImplementationAddress
        );
    }

    /// @inheritdoc IPoolAddressesProvider
    function getPool() external view override returns (address) {
        return getAddress(POOL);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setPoolImpl(address newPoolImpl) external override onlyOwner {
        address oldPoolImpl = _getProxyImplementation(POOL);
        _updateImpl(POOL, newPoolImpl);
        emit PoolUpdated(oldPoolImpl, newPoolImpl);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getPoolConfigurator() external view override returns (address) {
        return getAddress(POOL_CONFIGURATOR);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl)
        external
        override
        onlyOwner
    {
        address oldPoolConfiguratorImpl = _getProxyImplementation(
            POOL_CONFIGURATOR
        );
        _updateImpl(POOL_CONFIGURATOR, newPoolConfiguratorImpl);
        emit PoolConfiguratorUpdated(
            oldPoolConfiguratorImpl,
            newPoolConfiguratorImpl
        );
    }

    /// @inheritdoc IPoolAddressesProvider
    function getPriceOracle() external view override returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setPriceOracle(address newPriceOracle)
        external
        override
        onlyOwner
    {
        address oldPriceOracle = _addresses[PRICE_ORACLE];
        _addresses[PRICE_ORACLE] = newPriceOracle;
        emit PriceOracleUpdated(oldPriceOracle, newPriceOracle);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getACLManager() external view override returns (address) {
        return getAddress(ACL_MANAGER);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setACLManager(address newAclManager) external override onlyOwner {
        address oldAclManager = _addresses[ACL_MANAGER];
        _addresses[ACL_MANAGER] = newAclManager;
        emit ACLManagerUpdated(oldAclManager, newAclManager);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getACLAdmin() external view override returns (address) {
        return getAddress(ACL_ADMIN);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setACLAdmin(address newAclAdmin) external override onlyOwner {
        address oldAclAdmin = _addresses[ACL_ADMIN];
        _addresses[ACL_ADMIN] = newAclAdmin;
        emit ACLAdminUpdated(oldAclAdmin, newAclAdmin);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getPriceOracleSentinel() external view override returns (address) {
        return getAddress(PRICE_ORACLE_SENTINEL);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setPriceOracleSentinel(address newPriceOracleSentinel)
        external
        override
        onlyOwner
    {
        address oldPriceOracleSentinel = _addresses[PRICE_ORACLE_SENTINEL];
        _addresses[PRICE_ORACLE_SENTINEL] = newPriceOracleSentinel;
        emit PriceOracleSentinelUpdated(
            oldPriceOracleSentinel,
            newPriceOracleSentinel
        );
    }

    /// @inheritdoc IPoolAddressesProvider
    function getPoolDataProvider() external view override returns (address) {
        return getAddress(DATA_PROVIDER);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setPoolDataProvider(address newDataProvider)
        external
        override
        onlyOwner
    {
        address oldDataProvider = _addresses[DATA_PROVIDER];
        _addresses[DATA_PROVIDER] = newDataProvider;
        emit PoolDataProviderUpdated(oldDataProvider, newDataProvider);
    }

    /**
     * @notice Internal function to update the implementation of a specific proxied component of the protocol.
     * @dev If there is no proxy registered with the given identifier, it creates the proxy setting `newAddress`
     *   as implementation and calls the initialize() function on the proxy
     * @dev If there is already a proxy registered, it just updates the implementation to `newAddress` and
     *   calls the initialize() function via upgradeToAndCall() in the proxy
     * @param id The id of the proxy to be updated
     * @param newAddress The address of the new implementation
     **/
    function _updateImpl(bytes32 id, address newAddress) internal {
        address proxyAddress = _addresses[id];
        InitializableImmutableAdminUpgradeabilityProxy proxy;
        bytes memory params = abi.encodeWithSignature(
            "initialize(address)",
            address(this)
        );

        if (proxyAddress == address(0)) {
            proxy = new InitializableImmutableAdminUpgradeabilityProxy(
                address(this)
            );
            _addresses[id] = proxyAddress = address(proxy);
            proxy.initialize(newAddress, params);
            emit ProxyCreated(id, proxyAddress, newAddress);
        } else {
            proxy = InitializableImmutableAdminUpgradeabilityProxy(
                payable(proxyAddress)
            );
            proxy.upgradeToAndCall(newAddress, params);
        }
    }

    /**
     * @notice Updates the identifier of the ParaSpace market.
     * @param newMarketId The new id of the market
     **/
    function _setMarketId(string memory newMarketId) internal {
        string memory oldMarketId = _marketId;
        _marketId = newMarketId;
        emit MarketIdSet(oldMarketId, newMarketId);
    }

    /**
     * @notice Returns the the implementation contract of the proxy contract by its identifier.
     * @dev It returns ZERO if there is no registered address with the given id
     * @dev It reverts if the registered address with the given id is not `InitializableImmutableAdminUpgradeabilityProxy`
     * @param id The id
     * @return The address of the implementation contract
     */
    function _getProxyImplementation(bytes32 id) internal returns (address) {
        address proxyAddress = _addresses[id];
        if (proxyAddress == address(0)) {
            return address(0);
        } else {
            address payable payableProxyAddress = payable(proxyAddress);
            return
                InitializableImmutableAdminUpgradeabilityProxy(
                    payableProxyAddress
                ).implementation();
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./BaseAdminUpgradeabilityProxy.sol";
import "./InitializableUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is
    BaseAdminUpgradeabilityProxy,
    InitializableUpgradeabilityProxy
{
    /**
     * Contract initializer.
     * @param logic address of the initial implementation.
     * @param admin Address of the proxy administrator.
     * @param data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    function initialize(
        address logic,
        address admin,
        bytes memory data
    ) public payable {
        require(_implementation() == address(0));
        InitializableUpgradeabilityProxy.initialize(logic, data);
        assert(
            ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
        );
        _setAdmin(admin);
    }

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    function _willFallback()
        internal
        override(BaseAdminUpgradeabilityProxy, Proxy)
    {
        BaseAdminUpgradeabilityProxy._willFallback();
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./UpgradeabilityProxy.sol";

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
     * @dev Emitted when the administration has been transferred.
     * @param previousAdmin Address of the previous admin.
     * @param newAdmin Address of the new admin.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier to check whether the `msg.sender` is the admin.
     * If it is, it will run the function. Otherwise, it will delegate the call
     * to the implementation.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @return The address of the proxy admin.
     */
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

    /**
     * @return The address of the implementation.
     */
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     * Only the current admin can call this function.
     * @param newAdmin Address to transfer proxy administration to.
     */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(
            newAdmin != address(0),
            "Cannot change the admin of a proxy to the zero address"
        );
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy.
     * Only the admin can call this function.
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy and call a function
     * on the new implementation.
     * This is useful to initialize the proxied contract.
     * @param newImplementation Address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifAdmin
    {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @return adm The admin slot.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the proxy admin.
     * @param newAdmin Address of the new proxy admin.
     */
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        //solium-disable-next-line
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    function _willFallback() internal virtual override {
        require(
            msg.sender != _admin(),
            "Cannot call fallback function from the proxy admin"
        );
        super._willFallback();
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./BaseUpgradeabilityProxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with a constructor for initializing
 * implementation and init data.
 */
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
    /**
     * @dev Contract constructor.
     * @param _logic Address of the initial implementation.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(
            IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./BaseAdminUpgradeabilityProxy.sol";

/**
 * @title AdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with a constructor for
 * initializing the implementation, admin, and init data.
 */
contract AdminUpgradeabilityProxy is
    BaseAdminUpgradeabilityProxy,
    UpgradeabilityProxy
{
    /**
     * Contract constructor.
     * @param _logic address of the initial implementation.
     * @param _admin Address of the proxy administrator.
     * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
     */
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) payable UpgradeabilityProxy(_logic, _data) {
        assert(
            ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
        );
        _setAdmin(_admin);
    }

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    function _willFallback()
        internal
        override(BaseAdminUpgradeabilityProxy, Proxy)
    {
        BaseAdminUpgradeabilityProxy._willFallback();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {SafeCast} from "../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {VersionedInitializable} from "../libraries/paraspace-upgradeability/VersionedInitializable.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {IRewardController} from "../../interfaces/IRewardController.sol";
import {IInitializableDebtToken} from "../../interfaces/IInitializableDebtToken.sol";
import {IVariableDebtToken} from "../../interfaces/IVariableDebtToken.sol";
import {EIP712Base} from "./base/EIP712Base.sol";
import {DebtTokenBase} from "./base/DebtTokenBase.sol";
import {ScaledBalanceTokenBaseERC20} from "./base/ScaledBalanceTokenBaseERC20.sol";

/**
 * @title VariableDebtToken
 *
 * @notice Implements a variable debt token to track the borrowing positions of users
 * at variable rate mode
 * @dev Transfer and approve functionalities are disabled since its a non-transferable token
 **/
contract VariableDebtToken is
    DebtTokenBase,
    ScaledBalanceTokenBaseERC20,
    IVariableDebtToken
{
    using WadRayMath for uint256;
    using SafeCast for uint256;

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;

    /**
     * @dev Constructor.
     * @param pool The address of the Pool contract
     */
    constructor(IPool pool)
        DebtTokenBase()
        ScaledBalanceTokenBaseERC20(
            pool,
            "VARIABLE_DEBT_TOKEN_IMPL",
            "VARIABLE_DEBT_TOKEN_IMPL",
            0
        )
    {
        // Intentionally left blank
    }

    /// @inheritdoc IInitializableDebtToken
    function initialize(
        IPool initializingPool,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external override initializer {
        require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
        _setName(debtTokenName);
        _setSymbol(debtTokenSymbol);
        _setDecimals(debtTokenDecimals);

        _underlyingAsset = underlyingAsset;
        _rewardController = incentivesController;

        _domainSeparator = _calculateDomainSeparator();

        emit Initialized(
            underlyingAsset,
            address(POOL),
            address(incentivesController),
            debtTokenDecimals,
            debtTokenName,
            debtTokenSymbol,
            params
        );
    }

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return DEBT_TOKEN_REVISION;
    }

    /// @inheritdoc IERC20
    function balanceOf(address user)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 scaledBalance = super.balanceOf(user);

        if (scaledBalance == 0) {
            return 0;
        }

        return
            scaledBalance.rayMul(
                POOL.getReserveNormalizedVariableDebt(_underlyingAsset)
            );
    }

    /// @inheritdoc IVariableDebtToken
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external virtual override onlyPool returns (bool, uint256) {
        if (user != onBehalfOf) {
            _decreaseBorrowAllowance(onBehalfOf, user, amount);
        }
        return (
            _mintScaled(user, onBehalfOf, amount, index),
            scaledTotalSupply()
        );
    }

    /// @inheritdoc IVariableDebtToken
    function burn(
        address from,
        uint256 amount,
        uint256 index
    ) external virtual override onlyPool returns (uint256) {
        _burnScaled(from, address(0), amount, index);
        return scaledTotalSupply();
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256) {
        return
            super.totalSupply().rayMul(
                POOL.getReserveNormalizedVariableDebt(_underlyingAsset)
            );
    }

    /// @inheritdoc EIP712Base
    function _EIP712BaseId() internal view override returns (string memory) {
        return name();
    }

    /**
     * @dev Being non transferrable, the debt token does not implement any of the
     * standard ERC20 functions for transfer and allowance.
     **/
    function transfer(address, uint256)
        external
        virtual
        override
        returns (bool)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function allowance(address, address)
        external
        view
        virtual
        override
        returns (uint256)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function approve(address, uint256)
        external
        virtual
        override
        returns (bool)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external virtual override returns (bool) {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function increaseAllowance(address, uint256)
        external
        virtual
        override
        returns (bool)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function decreaseAllowance(address, uint256)
        external
        virtual
        override
        returns (bool)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    /// @inheritdoc IVariableDebtToken
    function UNDERLYING_ASSET_ADDRESS()
        external
        view
        override
        returns (address)
    {
        return _underlyingAsset;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Context} from "../../../dependencies/openzeppelin/contracts/Context.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";
import {VersionedInitializable} from "../../libraries/paraspace-upgradeability/VersionedInitializable.sol";
import {ICreditDelegationToken} from "../../../interfaces/ICreditDelegationToken.sol";
import {EIP712Base} from "./EIP712Base.sol";

/**
 * @title DebtTokenBase
 *
 * @notice Base contract for different types of debt tokens, like StableDebtToken or VariableDebtToken
 */
abstract contract DebtTokenBase is
    VersionedInitializable,
    EIP712Base,
    Context,
    ICreditDelegationToken
{
    // Map of borrow allowances (delegator => delegatee => borrowAllowanceAmount)
    mapping(address => mapping(address => uint256)) internal _borrowAllowances;

    // Credit Delegation Typehash
    bytes32 public constant DELEGATION_WITH_SIG_TYPEHASH =
        keccak256(
            "DelegationWithSig(address delegatee,uint256 value,uint256 nonce,uint256 deadline)"
        );

    address internal _underlyingAsset;

    /**
     * @dev Constructor.
     */
    constructor() EIP712Base() {
        // Intentionally left blank
    }

    /// @inheritdoc ICreditDelegationToken
    function approveDelegation(address delegatee, uint256 amount)
        external
        override
    {
        _approveDelegation(_msgSender(), delegatee, amount);
    }

    /// @inheritdoc ICreditDelegationToken
    function delegationWithSig(
        address delegator,
        address delegatee,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(delegator != address(0), Errors.ZERO_ADDRESS_NOT_VALID);
        //solium-disable-next-line
        require(block.timestamp <= deadline, Errors.INVALID_EXPIRATION);
        uint256 currentValidNonce = _nonces[delegator];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        DELEGATION_WITH_SIG_TYPEHASH,
                        delegatee,
                        value,
                        currentValidNonce,
                        deadline
                    )
                )
            )
        );
        require(
            delegator == ecrecover(digest, v, r, s),
            Errors.INVALID_SIGNATURE
        );
        _nonces[delegator] = currentValidNonce + 1;
        _approveDelegation(delegator, delegatee, value);
    }

    /// @inheritdoc ICreditDelegationToken
    function borrowAllowance(address fromUser, address toUser)
        external
        view
        override
        returns (uint256)
    {
        return _borrowAllowances[fromUser][toUser];
    }

    /**
     * @notice Updates the borrow allowance of a user on the specific debt token.
     * @param delegator The address delegating the borrowing power
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The allowance amount being delegated.
     **/
    function _approveDelegation(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal {
        _borrowAllowances[delegator][delegatee] = amount;
        emit BorrowAllowanceDelegated(
            delegator,
            delegatee,
            _underlyingAsset,
            amount
        );
    }

    /**
     * @notice Decreases the borrow allowance of a user on the specific debt token.
     * @param delegator The address delegating the borrowing power
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The amount to subtract from the current allowance
     **/
    function _decreaseBorrowAllowance(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal {
        uint256 newAllowance = _borrowAllowances[delegator][delegatee] - amount;

        _borrowAllowances[delegator][delegatee] = newAllowance;

        emit BorrowAllowanceDelegated(
            delegator,
            delegatee,
            _underlyingAsset,
            newAllowance
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title ICreditDelegationToken
 *
 * @notice Defines the basic interface for a token supporting credit delegation.
 **/
interface ICreditDelegationToken {
    /**
     * @dev Emitted on `approveDelegation` and `borrowAllowance
     * @param fromUser The address of the delegator
     * @param toUser The address of the delegatee
     * @param asset The address of the delegated asset
     * @param amount The amount being delegated
     */
    event BorrowAllowanceDelegated(
        address indexed fromUser,
        address indexed toUser,
        address indexed asset,
        uint256 amount
    );

    /**
     * @notice Delegates borrowing power to a user on the specific debt token.
     * Delegation will still respect the liquidation constraints (even if delegated, a
     * delegatee cannot force a delegator HF to go below 1)
     * @param delegatee The address receiving the delegated borrowing power
     * @param amount The maximum amount being delegated.
     **/
    function approveDelegation(address delegatee, uint256 amount) external;

    /**
     * @notice Returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return The current allowance of `toUser`
     **/
    function borrowAllowance(address fromUser, address toUser)
        external
        view
        returns (uint256);

    /**
     * @notice Delegates borrowing power to a user on the specific debt token via ERC712 signature
     * @param delegator The delegator of the credit
     * @param delegatee The delegatee that can use the credit
     * @param value The amount to be delegated
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v The V signature param
     * @param s The S signature param
     * @param r The R signature param
     */
    function delegationWithSig(
        address delegator,
        address delegatee,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IRewardsController} from "./interfaces/IRewardsController.sol";
import {IUiIncentiveDataProvider} from "./interfaces/IUiIncentiveDataProvider.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IncentivizedERC20} from "../protocol/tokenization/base/IncentivizedERC20.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {IERC20Detailed} from "../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {IEACAggregatorProxy} from "./interfaces/IEACAggregatorProxy.sol";

contract UiIncentiveDataProvider is IUiIncentiveDataProvider {
    using UserConfiguration for DataTypes.UserConfigurationMap;

    constructor() {}

    function getFullReservesIncentiveData(
        IPoolAddressesProvider provider,
        address user
    )
        external
        view
        override
        returns (
            AggregatedReserveIncentiveData[] memory,
            UserReserveIncentiveData[] memory
        )
    {
        return (
            _getReservesIncentivesData(provider),
            _getUserReservesIncentivesData(provider, user)
        );
    }

    function getReservesIncentivesData(IPoolAddressesProvider provider)
        external
        view
        override
        returns (AggregatedReserveIncentiveData[] memory)
    {
        return _getReservesIncentivesData(provider);
    }

    function _getReservesIncentivesData(IPoolAddressesProvider provider)
        private
        view
        returns (AggregatedReserveIncentiveData[] memory)
    {
        IPool pool = IPool(provider.getPool());
        address[] memory reserves = pool.getReservesList();
        AggregatedReserveIncentiveData[]
            memory reservesIncentiveData = new AggregatedReserveIncentiveData[](
                reserves.length
            );
        // Iterate through the reserves to get all the information from the (a/s/v) Tokens
        for (uint256 i = 0; i < reserves.length; i++) {
            AggregatedReserveIncentiveData
                memory reserveIncentiveData = reservesIncentiveData[i];
            reserveIncentiveData.underlyingAsset = reserves[i];

            DataTypes.ReserveData memory baseData = pool.getReserveData(
                reserves[i]
            );

            // Get xTokens rewards information
            // TODO: check that this is deployed correctly on contract and remove casting
            IRewardsController xTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.xTokenAddress)
                        .getIncentivesController()
                )
            );

            RewardInfo[] memory aRewardsInformation;
            if (address(xTokenIncentiveController) != address(0)) {
                address[]
                    memory xTokenRewardAddresses = xTokenIncentiveController
                        .getRewardsByAsset(baseData.xTokenAddress);

                aRewardsInformation = new RewardInfo[](
                    xTokenRewardAddresses.length
                );
                for (uint256 j = 0; j < xTokenRewardAddresses.length; ++j) {
                    RewardInfo memory rewardInformation;
                    rewardInformation
                        .rewardTokenAddress = xTokenRewardAddresses[j];

                    (
                        rewardInformation.tokenIncentivesIndex,
                        rewardInformation.emissionPerSecond,
                        rewardInformation.incentivesLastUpdateTimestamp,
                        rewardInformation.emissionEndTimestamp
                    ) = xTokenIncentiveController.getRewardsData(
                        baseData.xTokenAddress,
                        rewardInformation.rewardTokenAddress
                    );

                    rewardInformation.precision = xTokenIncentiveController
                        .getAssetDecimals(baseData.xTokenAddress);
                    rewardInformation.rewardTokenDecimals = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).decimals();
                    rewardInformation.rewardTokenSymbol = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    rewardInformation
                        .rewardOracleAddress = xTokenIncentiveController
                        .getRewardOracle(rewardInformation.rewardTokenAddress);
                    rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).decimals();
                    rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    aRewardsInformation[j] = rewardInformation;
                }
            }

            reserveIncentiveData.aIncentiveData = IncentiveData(
                baseData.xTokenAddress,
                address(xTokenIncentiveController),
                aRewardsInformation
            );

            // Get vTokens rewards information
            IRewardsController vTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.variableDebtTokenAddress)
                        .getIncentivesController()
                )
            );
            address[] memory vTokenRewardAddresses = vTokenIncentiveController
                .getRewardsByAsset(baseData.variableDebtTokenAddress);
            RewardInfo[] memory vRewardsInformation;

            if (address(vTokenIncentiveController) != address(0)) {
                vRewardsInformation = new RewardInfo[](
                    vTokenRewardAddresses.length
                );
                for (uint256 j = 0; j < vTokenRewardAddresses.length; ++j) {
                    RewardInfo memory rewardInformation;
                    rewardInformation
                        .rewardTokenAddress = vTokenRewardAddresses[j];

                    (
                        rewardInformation.tokenIncentivesIndex,
                        rewardInformation.emissionPerSecond,
                        rewardInformation.incentivesLastUpdateTimestamp,
                        rewardInformation.emissionEndTimestamp
                    ) = vTokenIncentiveController.getRewardsData(
                        baseData.variableDebtTokenAddress,
                        rewardInformation.rewardTokenAddress
                    );

                    rewardInformation.precision = vTokenIncentiveController
                        .getAssetDecimals(baseData.variableDebtTokenAddress);
                    rewardInformation.rewardTokenDecimals = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).decimals();
                    rewardInformation.rewardTokenSymbol = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    rewardInformation
                        .rewardOracleAddress = vTokenIncentiveController
                        .getRewardOracle(rewardInformation.rewardTokenAddress);
                    rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).decimals();
                    rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    vRewardsInformation[j] = rewardInformation;
                }
            }

            reserveIncentiveData.vIncentiveData = IncentiveData(
                baseData.variableDebtTokenAddress,
                address(vTokenIncentiveController),
                vRewardsInformation
            );

            // Get sTokens rewards information
            IRewardsController sTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.stableDebtTokenAddress)
                        .getIncentivesController()
                )
            );
            address[] memory sTokenRewardAddresses = sTokenIncentiveController
                .getRewardsByAsset(baseData.stableDebtTokenAddress);
            RewardInfo[] memory sRewardsInformation;

            if (address(sTokenIncentiveController) != address(0)) {
                sRewardsInformation = new RewardInfo[](
                    sTokenRewardAddresses.length
                );
                for (uint256 j = 0; j < sTokenRewardAddresses.length; ++j) {
                    RewardInfo memory rewardInformation;
                    rewardInformation
                        .rewardTokenAddress = sTokenRewardAddresses[j];

                    (
                        rewardInformation.tokenIncentivesIndex,
                        rewardInformation.emissionPerSecond,
                        rewardInformation.incentivesLastUpdateTimestamp,
                        rewardInformation.emissionEndTimestamp
                    ) = sTokenIncentiveController.getRewardsData(
                        baseData.stableDebtTokenAddress,
                        rewardInformation.rewardTokenAddress
                    );

                    rewardInformation.precision = sTokenIncentiveController
                        .getAssetDecimals(baseData.stableDebtTokenAddress);
                    rewardInformation.rewardTokenDecimals = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).decimals();
                    rewardInformation.rewardTokenSymbol = IERC20Detailed(
                        rewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    rewardInformation
                        .rewardOracleAddress = sTokenIncentiveController
                        .getRewardOracle(rewardInformation.rewardTokenAddress);
                    rewardInformation.priceFeedDecimals = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).decimals();
                    rewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        rewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    sRewardsInformation[j] = rewardInformation;
                }
            }

            reserveIncentiveData.sIncentiveData = IncentiveData(
                baseData.stableDebtTokenAddress,
                address(sTokenIncentiveController),
                sRewardsInformation
            );
        }

        return (reservesIncentiveData);
    }

    function getUserReservesIncentivesData(
        IPoolAddressesProvider provider,
        address user
    ) external view override returns (UserReserveIncentiveData[] memory) {
        return _getUserReservesIncentivesData(provider, user);
    }

    function _getUserReservesIncentivesData(
        IPoolAddressesProvider provider,
        address user
    ) private view returns (UserReserveIncentiveData[] memory) {
        IPool pool = IPool(provider.getPool());
        address[] memory reserves = pool.getReservesList();

        UserReserveIncentiveData[]
            memory userReservesIncentivesData = new UserReserveIncentiveData[](
                user != address(0) ? reserves.length : 0
            );

        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory baseData = pool.getReserveData(
                reserves[i]
            );

            // user reserve data
            userReservesIncentivesData[i].underlyingAsset = reserves[i];

            IRewardsController xTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.xTokenAddress)
                        .getIncentivesController()
                )
            );
            if (address(xTokenIncentiveController) != address(0)) {
                // get all rewards information from the asset
                address[]
                    memory xTokenRewardAddresses = xTokenIncentiveController
                        .getRewardsByAsset(baseData.xTokenAddress);
                UserRewardInfo[]
                    memory aUserRewardsInformation = new UserRewardInfo[](
                        xTokenRewardAddresses.length
                    );
                for (uint256 j = 0; j < xTokenRewardAddresses.length; ++j) {
                    UserRewardInfo memory userRewardInformation;
                    userRewardInformation
                        .rewardTokenAddress = xTokenRewardAddresses[j];

                    userRewardInformation
                        .tokenIncentivesUserIndex = xTokenIncentiveController
                        .getUserAssetIndex(
                            user,
                            baseData.xTokenAddress,
                            userRewardInformation.rewardTokenAddress
                        );

                    userRewardInformation
                        .userUnclaimedRewards = xTokenIncentiveController
                        .getUserAccruedRewards(
                            user,
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation.rewardTokenDecimals = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).decimals();
                    userRewardInformation.rewardTokenSymbol = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    userRewardInformation
                        .rewardOracleAddress = xTokenIncentiveController
                        .getRewardOracle(
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation
                        .priceFeedDecimals = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).decimals();
                    userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    aUserRewardsInformation[j] = userRewardInformation;
                }

                userReservesIncentivesData[i]
                    .xTokenIncentivesUserData = UserIncentiveData(
                    baseData.xTokenAddress,
                    address(xTokenIncentiveController),
                    aUserRewardsInformation
                );
            }

            // variable debt token
            IRewardsController vTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.variableDebtTokenAddress)
                        .getIncentivesController()
                )
            );
            if (address(vTokenIncentiveController) != address(0)) {
                // get all rewards information from the asset
                address[]
                    memory vTokenRewardAddresses = vTokenIncentiveController
                        .getRewardsByAsset(baseData.variableDebtTokenAddress);
                UserRewardInfo[]
                    memory vUserRewardsInformation = new UserRewardInfo[](
                        vTokenRewardAddresses.length
                    );
                for (uint256 j = 0; j < vTokenRewardAddresses.length; ++j) {
                    UserRewardInfo memory userRewardInformation;
                    userRewardInformation
                        .rewardTokenAddress = vTokenRewardAddresses[j];

                    userRewardInformation
                        .tokenIncentivesUserIndex = vTokenIncentiveController
                        .getUserAssetIndex(
                            user,
                            baseData.variableDebtTokenAddress,
                            userRewardInformation.rewardTokenAddress
                        );

                    userRewardInformation
                        .userUnclaimedRewards = vTokenIncentiveController
                        .getUserAccruedRewards(
                            user,
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation.rewardTokenDecimals = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).decimals();
                    userRewardInformation.rewardTokenSymbol = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    userRewardInformation
                        .rewardOracleAddress = vTokenIncentiveController
                        .getRewardOracle(
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation
                        .priceFeedDecimals = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).decimals();
                    userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    vUserRewardsInformation[j] = userRewardInformation;
                }

                userReservesIncentivesData[i]
                    .vTokenIncentivesUserData = UserIncentiveData(
                    baseData.variableDebtTokenAddress,
                    address(xTokenIncentiveController),
                    vUserRewardsInformation
                );
            }

            // stable debt token
            IRewardsController sTokenIncentiveController = IRewardsController(
                address(
                    IncentivizedERC20(baseData.stableDebtTokenAddress)
                        .getIncentivesController()
                )
            );
            if (address(sTokenIncentiveController) != address(0)) {
                // get all rewards information from the asset
                address[]
                    memory sTokenRewardAddresses = sTokenIncentiveController
                        .getRewardsByAsset(baseData.stableDebtTokenAddress);
                UserRewardInfo[]
                    memory sUserRewardsInformation = new UserRewardInfo[](
                        sTokenRewardAddresses.length
                    );
                for (uint256 j = 0; j < sTokenRewardAddresses.length; ++j) {
                    UserRewardInfo memory userRewardInformation;
                    userRewardInformation
                        .rewardTokenAddress = sTokenRewardAddresses[j];

                    userRewardInformation
                        .tokenIncentivesUserIndex = sTokenIncentiveController
                        .getUserAssetIndex(
                            user,
                            baseData.stableDebtTokenAddress,
                            userRewardInformation.rewardTokenAddress
                        );

                    userRewardInformation
                        .userUnclaimedRewards = sTokenIncentiveController
                        .getUserAccruedRewards(
                            user,
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation.rewardTokenDecimals = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).decimals();
                    userRewardInformation.rewardTokenSymbol = IERC20Detailed(
                        userRewardInformation.rewardTokenAddress
                    ).symbol();

                    // Get price of reward token from Chainlink Proxy Oracle
                    userRewardInformation
                        .rewardOracleAddress = sTokenIncentiveController
                        .getRewardOracle(
                            userRewardInformation.rewardTokenAddress
                        );
                    userRewardInformation
                        .priceFeedDecimals = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).decimals();
                    userRewardInformation.rewardPriceFeed = IEACAggregatorProxy(
                        userRewardInformation.rewardOracleAddress
                    ).latestAnswer();

                    sUserRewardsInformation[j] = userRewardInformation;
                }

                userReservesIncentivesData[i]
                    .sTokenIncentivesUserData = UserIncentiveData(
                    baseData.stableDebtTokenAddress,
                    address(xTokenIncentiveController),
                    sUserRewardsInformation
                );
            }
        }

        return (userReservesIncentivesData);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IRewardsDistributor} from "./IRewardsDistributor.sol";
import {ITransferStrategyBase} from "./ITransferStrategyBase.sol";
import {IEACAggregatorProxy} from "../../ui/interfaces/IEACAggregatorProxy.sol";
import {RewardsDataTypes} from "../libraries/RewardsDataTypes.sol";

/**
 * @title IRewardsController
 *
 * @notice Defines the basic interface for a Rewards Controller.
 */
interface IRewardsController is IRewardsDistributor {
    /**
     * @dev Emitted when a new address is whitelisted as claimer of rewards on behalf of a user
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @dev Emitted when rewards are claimed
     * @param user The address of the user rewards has been claimed on behalf of
     * @param reward The address of the token reward is claimed
     * @param to The address of the receiver of the rewards
     * @param claimer The address of the claimer
     * @param amount The amount of rewards claimed
     */
    event RewardsClaimed(
        address indexed user,
        address indexed reward,
        address indexed to,
        address claimer,
        uint256 amount
    );

    /**
     * @dev Emitted when a transfer strategy is installed for the reward distribution
     * @param reward The address of the token reward
     * @param transferStrategy The address of TransferStrategy contract
     */
    event TransferStrategyInstalled(
        address indexed reward,
        address indexed transferStrategy
    );

    /**
     * @dev Emitted when the reward oracle is updated
     * @param reward The address of the token reward
     * @param rewardOracle The address of oracle
     */
    event RewardOracleUpdated(
        address indexed reward,
        address indexed rewardOracle
    );

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Sets a TransferStrategy logic contract that determines the logic of the rewards transfer
     * @param reward The address of the reward token
     * @param transferStrategy The address of the TransferStrategy logic contract
     */
    function setTransferStrategy(
        address reward,
        ITransferStrategyBase transferStrategy
    ) external;

    /**
     * @dev Sets an ParaSpace Oracle contract to enforce rewards with a source of value.
     * @notice At the moment of reward configuration, the Incentives Controller performs
     * a check to see if the reward asset oracle is compatible with IEACAggregator proxy.
     * This check is enforced for integrators to be able to show incentives at
     * the current ParaSpace UI without the need to setup an external price registry
     * @param reward The address of the reward to set the price aggregator
     * @param rewardOracle The address of price aggregator that follows IEACAggregatorProxy interface
     */
    function setRewardOracle(address reward, IEACAggregatorProxy rewardOracle)
        external;

    /**
     * @dev Get the price aggregator oracle address
     * @param reward The address of the reward
     * @return The price oracle of the reward
     */
    function getRewardOracle(address reward) external view returns (address);

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Returns the Transfer Strategy implementation contract address being used for a reward address
     * @param reward The address of the reward
     * @return The address of the TransferStrategy contract
     */
    function getTransferStrategy(address reward)
        external
        view
        returns (address);

    /**
     * @dev Configure assets to incentivize with an emission of rewards per second until the end of distribution.
     * @param config The assets configuration input, the list of structs contains the following fields:
     *   uint104 emissionPerSecond: The emission per second following rewards unit decimals.
     *   uint256 totalSupply: The total supply of the asset to incentivize
     *   uint40 distributionEnd: The end of the distribution of the incentives for an asset
     *   address asset: The asset address to incentivize
     *   address reward: The reward token address
     *   ITransferStrategy transferStrategy: The TransferStrategy address with the install hook and claim logic.
     *   IEACAggregatorProxy rewardOracle: The Price Oracle of a reward to visualize the incentives at the UI Frontend.
     *                                     Must follow Chainlink Aggregator IEACAggregatorProxy interface to be compatible.
     */
    function configureAssets(
        RewardsDataTypes.RewardsConfigInput[] memory config
    ) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param user The address of the user
     * @param userBalance The user balance of the asset
     * @param totalSupply The total supply of the asset
     **/
    function handleAction(
        address user,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
     * @param assets List of assets to check eligible distributions before claiming rewards
     * @param amount The amount of rewards to claim
     * @param to The address that will be receiving the rewards
     * @param reward The address of the reward token
     * @return The amount of rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to,
        address reward
    ) external returns (uint256);

    /**
     * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
     * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param amount The amount of rewards to claim
     * @param user The address to check and claim rewards
     * @param to The address that will be receiving the rewards
     * @param reward The address of the reward token
     * @return The amount of rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to,
        address reward
    ) external returns (uint256);

    /**
     * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param amount The amount of rewards to claim
     * @param reward The address of the reward token
     * @return The amount of rewards claimed
     **/
    function claimRewardsToSelf(
        address[] calldata assets,
        uint256 amount,
        address reward
    ) external returns (uint256);

    /**
     * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param to The address that will be receiving the rewards
     * @return rewardsList List of addresses of the reward tokens
     * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
     **/
    function claimAllRewards(address[] calldata assets, address to)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    /**
     * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @param user The address to check and claim rewards
     * @param to The address that will be receiving the rewards
     * @return rewardsList List of addresses of the reward tokens
     * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
     **/
    function claimAllRewardsOnBehalf(
        address[] calldata assets,
        address user,
        address to
    )
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);

    /**
     * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
     * @param assets The list of assets to check eligible distributions before claiming rewards
     * @return rewardsList List of addresses of the reward tokens
     * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
     **/
    function claimAllRewardsToSelf(address[] calldata assets)
        external
        returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";

interface IUiIncentiveDataProvider {
    struct AggregatedReserveIncentiveData {
        address underlyingAsset;
        IncentiveData aIncentiveData;
        IncentiveData vIncentiveData;
        IncentiveData sIncentiveData;
    }

    struct IncentiveData {
        address tokenAddress;
        address incentiveControllerAddress;
        RewardInfo[] rewardsTokenInformation;
    }

    struct RewardInfo {
        string rewardTokenSymbol;
        address rewardTokenAddress;
        address rewardOracleAddress;
        uint256 emissionPerSecond;
        uint256 incentivesLastUpdateTimestamp;
        uint256 tokenIncentivesIndex;
        uint256 emissionEndTimestamp;
        int256 rewardPriceFeed;
        uint8 rewardTokenDecimals;
        uint8 precision;
        uint8 priceFeedDecimals;
    }

    struct UserReserveIncentiveData {
        address underlyingAsset;
        UserIncentiveData xTokenIncentivesUserData;
        UserIncentiveData vTokenIncentivesUserData;
        UserIncentiveData sTokenIncentivesUserData;
    }

    struct UserIncentiveData {
        address tokenAddress;
        address incentiveControllerAddress;
        UserRewardInfo[] userRewardsInformation;
    }

    struct UserRewardInfo {
        string rewardTokenSymbol;
        address rewardOracleAddress;
        address rewardTokenAddress;
        uint256 userUnclaimedRewards;
        uint256 tokenIncentivesUserIndex;
        int256 rewardPriceFeed;
        uint8 priceFeedDecimals;
        uint8 rewardTokenDecimals;
    }

    function getReservesIncentivesData(IPoolAddressesProvider provider)
        external
        view
        returns (AggregatedReserveIncentiveData[] memory);

    function getUserReservesIncentivesData(
        IPoolAddressesProvider provider,
        address user
    ) external view returns (UserReserveIncentiveData[] memory);

    // generic method with full data
    function getFullReservesIncentiveData(
        IPoolAddressesProvider provider,
        address user
    )
        external
        view
        returns (
            AggregatedReserveIncentiveData[] memory,
            UserReserveIncentiveData[] memory
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @title IRewardsDistributor
 *
 * @notice Defines the basic interface for a Rewards Distributor.
 */
interface IRewardsDistributor {
    /**
     * @dev Emitted when the configuration of the rewards of an asset is updated.
     * @param asset The address of the incentivized asset
     * @param reward The address of the reward token
     * @param oldEmission The old emissions per second value of the reward distribution
     * @param newEmission The new emissions per second value of the reward distribution
     * @param oldDistributionEnd The old end timestamp of the reward distribution
     * @param newDistributionEnd The new end timestamp of the reward distribution
     * @param assetIndex The index of the asset distribution
     */
    event AssetConfigUpdated(
        address indexed asset,
        address indexed reward,
        uint256 oldEmission,
        uint256 newEmission,
        uint256 oldDistributionEnd,
        uint256 newDistributionEnd,
        uint256 assetIndex
    );

    /**
     * @dev Emitted when rewards of an asset are accrued on behalf of a user.
     * @param asset The address of the incentivized asset
     * @param reward The address of the reward token
     * @param user The address of the user that rewards are accrued on behalf of
     * @param assetIndex The index of the asset distribution
     * @param userIndex The index of the asset distribution on behalf of the user
     * @param rewardsAccrued The amount of rewards accrued
     */
    event Accrued(
        address indexed asset,
        address indexed reward,
        address indexed user,
        uint256 assetIndex,
        uint256 userIndex,
        uint256 rewardsAccrued
    );

    /**
     * @dev Emitted when the emission manager address is updated.
     * @param oldEmissionManager The address of the old emission manager
     * @param newEmissionManager The address of the new emission manager
     */
    event EmissionManagerUpdated(
        address indexed oldEmissionManager,
        address indexed newEmissionManager
    );

    /**
     * @dev Sets the end date for the distribution
     * @param asset The asset to incentivize
     * @param reward The reward token that incentives the asset
     * @param newDistributionEnd The end date of the incentivization, in unix time format
     **/
    function setDistributionEnd(
        address asset,
        address reward,
        uint32 newDistributionEnd
    ) external;

    /**
     * @dev Sets the emission per second of a set of reward distributions
     * @param asset The asset is being incentivized
     * @param rewards List of reward addresses are being distributed
     * @param newEmissionsPerSecond List of new reward emissions per second
     */
    function setEmissionPerSecond(
        address asset,
        address[] calldata rewards,
        uint88[] calldata newEmissionsPerSecond
    ) external;

    /**
     * @dev Gets the end date for the distribution
     * @param asset The incentivized asset
     * @param reward The reward token of the incentivized asset
     * @return The timestamp with the end of the distribution, in unix time format
     **/
    function getDistributionEnd(address asset, address reward)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the index of a user on a reward distribution
     * @param user Address of the user
     * @param asset The incentivized asset
     * @param reward The reward token of the incentivized asset
     * @return The current user asset index, not including new distributions
     **/
    function getUserAssetIndex(
        address user,
        address asset,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution reward for a certain asset
     * @param asset The incentivized asset
     * @param reward The reward token of the incentivized asset
     * @return The index of the asset distribution
     * @return The emission per second of the reward distribution
     * @return The timestamp of the last update of the index
     * @return The timestamp of the distribution end
     **/
    function getRewardsData(address asset, address reward)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev Returns the list of available reward token addresses of an incentivized asset
     * @param asset The incentivized asset
     * @return List of rewards addresses of the input asset
     **/
    function getRewardsByAsset(address asset)
        external
        view
        returns (address[] memory);

    /**
     * @dev Returns the list of available reward addresses
     * @return List of rewards supported in this contract
     **/
    function getRewardsList() external view returns (address[] memory);

    /**
     * @dev Returns the accrued rewards balance of a user, not including virtually accrued rewards since last distribution.
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return Unclaimed rewards, not including new distributions
     **/
    function getUserAccruedRewards(address user, address reward)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a single rewards balance of a user, including virtually accrued and unrealized claimable rewards.
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return The rewards amount
     **/
    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @return The list of reward addresses
     * @return The list of unclaimed amount of rewards
     **/
    function getAllUserRewards(address[] calldata assets, address user)
        external
        view
        returns (address[] memory, uint256[] memory);

    /**
     * @dev Returns the decimals of an asset to calculate the distribution delta
     * @param asset The address to retrieve decimals
     * @return The decimals of an underlying asset
     */
    function getAssetDecimals(address asset) external view returns (uint8);

    /**
     * @dev Returns the address of the emission manager
     * @return The address of the EmissionManager
     */
    function getEmissionManager() external view returns (address);

    /**
     * @dev Updates the address of the emission manager
     * @param emissionManager The address of the new EmissionManager
     */
    function setEmissionManager(address emissionManager) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface ITransferStrategyBase {
    event EmergencyWithdrawal(
        address indexed caller,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Perform custom transfer logic via delegate call from source contract to a TransferStrategy implementation
     * @param to Account to transfer rewards
     * @param reward Address of the reward token
     * @param amount Amount to transfer to the "to" address parameter
     * @return Returns true bool if transfer logic succeeds
     */
    function performTransfer(
        address to,
        address reward,
        uint256 amount
    ) external returns (bool);

    /**
     * @return Returns the address of the Incentives Controller
     */
    function getIncentivesController() external view returns (address);

    /**
     * @return Returns the address of the Rewards admin
     */
    function getRewardsAdmin() external view returns (address);

    /**
     * @dev Perform an emergency token withdrawal only callable by the Rewards admin
     * @param token Address of the token to withdraw funds from this contract
     * @param to Address of the recipient of the withdrawal
     * @param amount Amount of the withdrawal
     */
    function emergencyWithdrawal(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {ITransferStrategyBase} from "../interfaces/ITransferStrategyBase.sol";
import {IEACAggregatorProxy} from "../../ui/interfaces/IEACAggregatorProxy.sol";

library RewardsDataTypes {
    struct RewardsConfigInput {
        uint88 emissionPerSecond;
        uint256 totalSupply;
        uint32 distributionEnd;
        address asset;
        address reward;
        ITransferStrategyBase transferStrategy;
        IEACAggregatorProxy rewardOracle;
    }

    struct UserAssetBalance {
        address asset;
        uint256 userBalance;
        uint256 totalSupply;
    }

    struct UserData {
        uint104 index; // matches reward index
        uint128 accrued;
    }

    struct RewardData {
        uint104 index;
        uint88 emissionPerSecond;
        uint32 lastUpdateTimestamp;
        uint32 distributionEnd;
        mapping(address => UserData) usersData;
    }

    struct AssetData {
        mapping(address => RewardData) rewards;
        mapping(uint128 => address) availableRewards;
        uint128 availableRewardsCount;
        uint8 decimals;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "./IERC20Detailed.sol";

interface IMintableERC20 is IERC20Detailed {
    /**
     * @dev Function to mint tokens
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 value) external returns (bool);

    /**
     * @dev Function to mint tokens to address
     * @param account The account to mint tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address account, uint256 value) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "../../dependencies/openzeppelin/contracts/EnumerableSet.sol";
import "../../dependencies/openzeppelin/contracts/Ownable.sol";
import "../../dependencies/openzeppelin/contracts/IMintableERC20.sol";

interface ICryptoPunksMarket {
    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint256 punkIndex) external;

    function getPunk(uint256 punkIndex) external;

    function punksRemainingToAssign() external returns (uint256);

    function punkIndexToAddress(uint256) external returns (address);

    function balanceOf(address user) external returns (uint256);
}

interface IMintERC721 {
    function mint(uint256 _count, address _to) external;
}

contract MockTokenFaucet is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Token {
        string name;
        address addr;
        uint256 mintValue; // based on token decimals
    }

    ICryptoPunksMarket public cryptoPunks;

    mapping(address => Token) public tokenInfo;

    EnumerableSet.AddressSet private _mockERC20Tokens;
    EnumerableSet.AddressSet private _mockERC721Tokens;

    constructor(
        Token[] memory erc20Tokens,
        Token[] memory erc721Tokens,
        Token memory punks
    ) {
        for (uint256 index = 0; index < erc20Tokens.length; index++) {
            Token memory t = erc20Tokens[index];
            _mockERC20Tokens.add(t.addr);
            tokenInfo[t.addr] = t;
        }

        for (uint256 index = 0; index < erc721Tokens.length; index++) {
            Token memory t = erc721Tokens[index];
            _mockERC721Tokens.add(t.addr);
            tokenInfo[t.addr] = t;
        }
        cryptoPunks = ICryptoPunksMarket(punks.addr);
        tokenInfo[punks.addr] = punks;
    }

    function allMockERC20Tokens() public view returns (Token[] memory) {
        uint256 len = _mockERC20Tokens.length();
        Token[] memory tokens = new Token[](len);
        for (uint256 index = 0; index < len; index++) {
            tokens[index] = tokenInfo[_mockERC20Tokens.at(index)];
        }
        return tokens;
    }

    function allMockERC721Tokens() public view returns (Token[] memory) {
        uint256 len = _mockERC721Tokens.length();
        Token[] memory tokens = new Token[](len + 1);
        for (uint256 index = 0; index < len; index++) {
            tokens[index] = tokenInfo[_mockERC721Tokens.at(index)];
        }
        tokens[len] = tokenInfo[address(cryptoPunks)];
        return tokens;
    }

    function addERC20(Token[] calldata _tokens) public onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            Token memory t = _tokens[index];
            tokenInfo[t.addr] = t;
            _mockERC20Tokens.add(t.addr);
        }
    }

    function removeERC20(address[] memory _tokens) public onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            address addr = _tokens[index];
            _mockERC20Tokens.remove(addr);
            delete tokenInfo[addr];
        }
    }

    function addERC721(Token[] calldata _tokens) public onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            Token memory t = _tokens[index];
            tokenInfo[t.addr] = t;
            _mockERC721Tokens.add(t.addr);
        }
    }

    function updatePunk(Token calldata punk) public onlyOwner {
        tokenInfo[punk.addr] = punk;
        cryptoPunks = ICryptoPunksMarket(punk.addr);
    }

    function removeERC721(address[] memory _tokens) public onlyOwner {
        for (uint256 index = 0; index < _tokens.length; index++) {
            address addr = _tokens[index];
            _mockERC721Tokens.remove(addr);
            delete tokenInfo[addr];
        }
    }

    function mintERC20(
        address token,
        address to,
        uint256 mintValue
    ) public {
        IMintableERC20 mintToken = IMintableERC20(token);
        uint256 decimals = mintToken.decimals();
        mintToken.mint(to, mintValue * 10**decimals);
    }

    function mintERC721(
        address token,
        address to,
        uint256 mintValue
    ) public {
        IMintERC721 mintToken = IMintERC721(token);
        mintToken.mint(mintValue, to);
    }

    function mintERC20s(address to) internal {
        for (uint256 index = 0; index < _mockERC20Tokens.length(); index++) {
            Token memory token = tokenInfo[_mockERC20Tokens.at(index)];
            mintERC20(token.addr, to, token.mintValue);
        }
    }

    function mintERC721s(address to) internal {
        for (uint256 index = 0; index < _mockERC721Tokens.length(); index++) {
            Token memory token = tokenInfo[_mockERC721Tokens.at(index)];
            mintERC721(token.addr, to, token.mintValue);
        }
    }

    function mintPunks(address to) internal {
        if (address(cryptoPunks) == address(0)) return;

        Token memory punksToken = tokenInfo[address(cryptoPunks)];

        if (punksToken.mintValue == 0) return;

        for (uint256 count = 0; count < punksToken.mintValue; count++) {
            uint256 punksRemainingToAssign = cryptoPunks
                .punksRemainingToAssign();
            if (punksRemainingToAssign == 0) break;
            uint256 nextPunkIndex = punksRemainingToAssign - 1;

            for (uint256 index = 0; index < 10000; index++) {
                if (
                    cryptoPunks.punkIndexToAddress(nextPunkIndex) == address(0)
                ) {
                    cryptoPunks.getPunk(nextPunkIndex);
                    cryptoPunks.transferPunk(to, nextPunkIndex);
                    break;
                }

                if (nextPunkIndex > 0) {
                    nextPunkIndex--;
                } else {
                    break;
                }
            }
        }
    }

    function mint(address to) public {
        mintERC20s(to);
        mintERC721s(to);
        mintPunks(to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
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
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
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
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {Ownable} from "../../../../contracts/dependencies/openzeppelin/contracts/Ownable.sol";
import {ERC721} from "../../../../contracts/dependencies/openzeppelin/contracts/ERC721.sol";
import {ERC721Enumerable} from "../../../../contracts/dependencies/openzeppelin/contracts/ERC721Enumerable.sol";
import {Pausable} from "../../../../contracts/dependencies/openzeppelin/contracts/Pausable.sol";
import {UserProxy} from "./UserProxy.sol";
import {ICryptoPunk} from "./ICryptoPunk.sol";
import {IWrappedPunks} from "../../../misc/interfaces/IWrappedPunks.sol";

contract WPunk is IWrappedPunks, Ownable, ERC721Enumerable, Pausable {
    event ProxyRegistered(address user, address proxy);

    // Instance of cryptopunk smart contract
    ICryptoPunk private _punkContract;

    // Mapping from user address to proxy address
    mapping(address => address) private _proxies;

    /**
     * @dev Initializes the contract settings
     */
    constructor(address punkContract_) ERC721("Wrapped Cryptopunks", "WPUNKS") {
        _punkContract = ICryptoPunk(punkContract_);
    }

    /**
     * @dev Gets address of cryptopunk smart contract
     */
    function punkContract() public view override returns (address) {
        return address(_punkContract);
    }

    /**
     * @dev Registers proxy
     */
    function registerProxy() public override {
        address sender = _msgSender();

        require(
            _proxies[sender] == address(0),
            "PunkWrapper: caller has registered the proxy"
        );

        address proxy = address(new UserProxy());

        _proxies[sender] = proxy;

        emit ProxyRegistered(sender, proxy);
    }

    /**
     * @dev Gets proxy address
     */
    function proxyInfo(address user) public view override returns (address) {
        return _proxies[user];
    }

    /**
     * @dev Mints a wrapped punk
     */
    function mint(uint256 punkIndex) public override whenNotPaused {
        address sender = _msgSender();

        UserProxy proxy = UserProxy(_proxies[sender]);
        require(
            proxy.transfer(address(_punkContract), punkIndex),
            "PunkWrapper: transfer fail"
        );
        _mint(sender, punkIndex);
    }

    /**
     * @dev Burns a specific wrapped punk
     */
    function burn(uint256 punkIndex) public override whenNotPaused {
        address sender = _msgSender();

        require(
            _isApprovedOrOwner(sender, punkIndex),
            "PunkWrapper: caller is not owner nor approved"
        );

        _burn(punkIndex);

        // Transfers ownership of punk on original cryptopunk smart contract to caller
        _punkContract.transferPunk(sender, punkIndex);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://wrappedpunks.com:3000/api/punks/metadata/";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity 0.8.10;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

contract UserProxy {
    address private immutable _owner;

    /**
     * @dev Initializes the contract settings
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Transfers punk to the smart contract owner
     */
    function transfer(address punkContract, uint256 punkIndex)
        external
        returns (bool)
    {
        if (_owner != msg.sender) {
            return false;
        }

        (bool result, ) = punkContract.call(
            abi.encodeWithSignature(
                "transferPunk(address,uint256)",
                _owner,
                punkIndex
            )
        );

        return result;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface ICryptoPunk {
    function punkIndexToAddress(uint256 punkIndex) external returns (address);

    function punksOfferedForSale(uint256 punkIndex)
        external
        returns (
            bool,
            uint256,
            address,
            uint256,
            address
        );

    function buyPunk(uint256 punkIndex) external payable;

    function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {VersionedInitializable} from "../libraries/paraspace-upgradeability/VersionedInitializable.sol";
import {MathUtils} from "../libraries/math/MathUtils.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IRewardController} from "../../interfaces/IRewardController.sol";
import {IInitializableDebtToken} from "../../interfaces/IInitializableDebtToken.sol";
import {IStableDebtToken} from "../../interfaces/IStableDebtToken.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {EIP712Base} from "./base/EIP712Base.sol";
import {DebtTokenBase} from "./base/DebtTokenBase.sol";
import {IncentivizedERC20} from "./base/IncentivizedERC20.sol";
import {SafeCast} from "../../dependencies/openzeppelin/contracts/SafeCast.sol";

// TODO can we get rid of StableDebtToken completely since we are not using it?
/**
 * @title StableDebtToken
 *
 * @notice Implements a stable debt token to track the borrowing positions of users
 * at stable rate mode
 * @dev Transfer and approve functionalities are disabled since its a non-transferable token
 **/
contract StableDebtToken is DebtTokenBase, IncentivizedERC20, IStableDebtToken {
    using WadRayMath for uint256;
    using SafeCast for uint256;

    uint256 public constant DEBT_TOKEN_REVISION = 0x1;

    // Map of users address and the timestamp of their last update (userAddress => lastUpdateTimestamp)
    mapping(address => uint40) internal _timestamps;

    uint128 internal _avgStableRate;

    // Timestamp of the last update of the total supply
    uint40 internal _totalSupplyTimestamp;

    /**
     * @dev Constructor.
     * @param pool The address of the Pool contract
     */
    constructor(IPool pool)
        DebtTokenBase()
        IncentivizedERC20(
            pool,
            "STABLE_DEBT_TOKEN_IMPL",
            "STABLE_DEBT_TOKEN_IMPL",
            0
        )
    {
        // Intentionally left blank
    }

    /// @inheritdoc IInitializableDebtToken
    function initialize(
        IPool initializingPool,
        address underlyingAsset,
        IRewardController incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external override initializer {
        require(initializingPool == POOL, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
        _setName(debtTokenName);
        _setSymbol(debtTokenSymbol);
        _setDecimals(debtTokenDecimals);

        _underlyingAsset = underlyingAsset;
        _rewardController = incentivesController;

        _domainSeparator = _calculateDomainSeparator();

        emit Initialized(
            underlyingAsset,
            address(POOL),
            address(incentivesController),
            debtTokenDecimals,
            debtTokenName,
            debtTokenSymbol,
            params
        );
    }

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256) {
        return DEBT_TOKEN_REVISION;
    }

    /// @inheritdoc IStableDebtToken
    function getAverageStableRate()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _avgStableRate;
    }

    /// @inheritdoc IStableDebtToken
    function getUserLastUpdated(address user)
        external
        view
        virtual
        override
        returns (uint40)
    {
        return _timestamps[user];
    }

    /// @inheritdoc IStableDebtToken
    function getUserStableRate(address user)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _userState[user].additionalData;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        uint256 accountBalance = super.balanceOf(account);
        uint256 stableRate = _userState[account].additionalData;
        if (accountBalance == 0) {
            return 0;
        }
        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            stableRate,
            _timestamps[account]
        );
        return accountBalance.rayMul(cumulatedInterest);
    }

    struct MintLocalVars {
        uint256 previousSupply;
        uint256 nextSupply;
        uint256 amountInRay;
        uint256 currentStableRate;
        uint256 nextStableRate;
        uint256 currentAvgStableRate;
    }

    /// @inheritdoc IStableDebtToken
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 rate
    )
        external
        virtual
        override
        onlyPool
        returns (
            bool,
            uint256,
            uint256
        )
    {
        MintLocalVars memory vars;

        if (user != onBehalfOf) {
            _decreaseBorrowAllowance(onBehalfOf, user, amount);
        }

        (
            ,
            uint256 currentBalance,
            uint256 balanceIncrease
        ) = _calculateBalanceIncrease(onBehalfOf);

        vars.previousSupply = totalSupply();
        vars.currentAvgStableRate = _avgStableRate;
        vars.nextSupply = _totalSupply = vars.previousSupply + amount;

        vars.amountInRay = amount.wadToRay();

        vars.currentStableRate = _userState[onBehalfOf].additionalData;
        vars.nextStableRate = (vars.currentStableRate.rayMul(
            currentBalance.wadToRay()
        ) + vars.amountInRay.rayMul(rate)).rayDiv(
                (currentBalance + amount).wadToRay()
            );

        _userState[onBehalfOf].additionalData = vars.nextStableRate.toUint128();

        //solium-disable-next-line
        _totalSupplyTimestamp = _timestamps[onBehalfOf] = uint40(
            block.timestamp
        );

        // Calculates the updated average stable rate
        vars.currentAvgStableRate = _avgStableRate = (
            (vars.currentAvgStableRate.rayMul(vars.previousSupply.wadToRay()) +
                rate.rayMul(vars.amountInRay)).rayDiv(
                    vars.nextSupply.wadToRay()
                )
        ).toUint128();

        uint256 amountToMint = amount + balanceIncrease;
        _mint(onBehalfOf, amountToMint, vars.previousSupply);

        emit Transfer(address(0), onBehalfOf, amountToMint);
        emit Mint(
            user,
            onBehalfOf,
            amountToMint,
            currentBalance,
            balanceIncrease,
            vars.nextStableRate,
            vars.currentAvgStableRate,
            vars.nextSupply
        );

        return (
            currentBalance == 0,
            vars.nextSupply,
            vars.currentAvgStableRate
        );
    }

    /// @inheritdoc IStableDebtToken
    function burn(address from, uint256 amount)
        external
        virtual
        override
        onlyPool
        returns (uint256, uint256)
    {
        (
            ,
            uint256 currentBalance,
            uint256 balanceIncrease
        ) = _calculateBalanceIncrease(from);

        uint256 previousSupply = totalSupply();
        uint256 nextAvgStableRate = 0;
        uint256 nextSupply = 0;
        uint256 userStableRate = _userState[from].additionalData;

        // Since the total supply and each single user debt accrue separately,
        // there might be accumulation errors so that the last borrower repaying
        // might actually try to repay more than the available debt supply.
        // In this case we simply set the total supply and the avg stable rate to 0
        if (previousSupply <= amount) {
            _avgStableRate = 0;
            _totalSupply = 0;
        } else {
            nextSupply = _totalSupply = previousSupply - amount;
            uint256 firstTerm = uint256(_avgStableRate).rayMul(
                previousSupply.wadToRay()
            );
            uint256 secondTerm = userStableRate.rayMul(amount.wadToRay());

            // For the same reason described above, when the last user is repaying it might
            // happen that user rate * user balance > avg rate * total supply. In that case,
            // we simply set the avg rate to 0
            if (secondTerm >= firstTerm) {
                nextAvgStableRate = _totalSupply = _avgStableRate = 0;
            } else {
                nextAvgStableRate = _avgStableRate = (
                    (firstTerm - secondTerm).rayDiv(nextSupply.wadToRay())
                ).toUint128();
            }
        }

        if (amount == currentBalance) {
            _userState[from].additionalData = 0;
            _timestamps[from] = 0;
        } else {
            //solium-disable-next-line
            _timestamps[from] = uint40(block.timestamp);
        }
        //solium-disable-next-line
        _totalSupplyTimestamp = uint40(block.timestamp);

        if (balanceIncrease > amount) {
            uint256 amountToMint = balanceIncrease - amount;
            _mint(from, amountToMint, previousSupply);
            emit Transfer(address(0), from, amountToMint);
            emit Mint(
                from,
                from,
                amountToMint,
                currentBalance,
                balanceIncrease,
                userStableRate,
                nextAvgStableRate,
                nextSupply
            );
        } else {
            uint256 amountToBurn = amount - balanceIncrease;
            _burn(from, amountToBurn, previousSupply);
            emit Transfer(from, address(0), amountToBurn);
            emit Burn(
                from,
                amountToBurn,
                currentBalance,
                balanceIncrease,
                nextAvgStableRate,
                nextSupply
            );
        }

        return (nextSupply, nextAvgStableRate);
    }

    /**
     * @notice Calculates the increase in balance since the last user interaction
     * @param user The address of the user for which the interest is being accumulated
     * @return The previous principal balance
     * @return The new principal balance
     * @return The balance increase
     **/
    function _calculateBalanceIncrease(address user)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 previousPrincipalBalance = super.balanceOf(user);

        if (previousPrincipalBalance == 0) {
            return (0, 0, 0);
        }

        uint256 newPrincipalBalance = balanceOf(user);

        return (
            previousPrincipalBalance,
            newPrincipalBalance,
            newPrincipalBalance - previousPrincipalBalance
        );
    }

    /// @inheritdoc IStableDebtToken
    function getSupplyData()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint40
        )
    {
        uint256 avgRate = _avgStableRate;
        return (
            super.totalSupply(),
            _calcTotalSupply(avgRate),
            avgRate,
            _totalSupplyTimestamp
        );
    }

    /// @inheritdoc IStableDebtToken
    function getTotalSupplyAndAvgRate()
        external
        view
        override
        returns (uint256, uint256)
    {
        uint256 avgRate = _avgStableRate;
        return (_calcTotalSupply(avgRate), avgRate);
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual override returns (uint256) {
        return _calcTotalSupply(_avgStableRate);
    }

    /// @inheritdoc IStableDebtToken
    function getTotalSupplyLastUpdated()
        external
        view
        override
        returns (uint40)
    {
        return _totalSupplyTimestamp;
    }

    /// @inheritdoc IStableDebtToken
    function principalBalanceOf(address user)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return super.balanceOf(user);
    }

    /// @inheritdoc IStableDebtToken
    function UNDERLYING_ASSET_ADDRESS()
        external
        view
        override
        returns (address)
    {
        return _underlyingAsset;
    }

    /**
     * @notice Calculates the total supply
     * @param avgRate The average rate at which the total supply increases
     * @return The debt balance of the user since the last burn/mint action
     **/
    function _calcTotalSupply(uint256 avgRate) internal view returns (uint256) {
        uint256 principalSupply = super.totalSupply();

        if (principalSupply == 0) {
            return 0;
        }

        uint256 cumulatedInterest = MathUtils.calculateCompoundedInterest(
            avgRate,
            _totalSupplyTimestamp
        );

        return principalSupply.rayMul(cumulatedInterest);
    }

    /**
     * @notice Mints stable debt tokens to a user
     * @param account The account receiving the debt tokens
     * @param amount The amount being minted
     * @param oldTotalSupply The total supply before the minting event
     **/
    function _mint(
        address account,
        uint256 amount,
        uint256 oldTotalSupply
    ) internal {
        uint128 castAmount = amount.toUint128();
        uint128 oldAccountBalance = _userState[account].balance;
        _userState[account].balance = oldAccountBalance + castAmount;

        if (address(_rewardController) != address(0)) {
            _rewardController.handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    /**
     * @notice Burns stable debt tokens of a user
     * @param account The user getting his debt burned
     * @param amount The amount being burned
     * @param oldTotalSupply The total supply before the burning event
     **/
    function _burn(
        address account,
        uint256 amount,
        uint256 oldTotalSupply
    ) internal {
        uint128 castAmount = amount.toUint128();
        uint128 oldAccountBalance = _userState[account].balance;
        _userState[account].balance = oldAccountBalance - castAmount;

        if (address(_rewardController) != address(0)) {
            _rewardController.handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    /// @inheritdoc EIP712Base
    function _EIP712BaseId() internal view override returns (string memory) {
        return name();
    }

    /**
     * @dev Being non transferrable, the debt token does not implement any of the
     * standard ERC20 functions for transfer and allowance.
     **/
    function transfer(address, uint256)
        external
        virtual
        override
        returns (bool)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function allowance(address, address)
        external
        view
        virtual
        override
        returns (uint256)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function approve(address, uint256)
        external
        virtual
        override
        returns (bool)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external virtual override returns (bool) {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function increaseAllowance(address, uint256)
        external
        virtual
        override
        returns (bool)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }

    function decreaseAllowance(address, uint256)
        external
        virtual
        override
        returns (bool)
    {
        revert(Errors.OPERATION_NOT_SUPPORTED);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VariableDebtToken} from "../../protocol/tokenization/VariableDebtToken.sol";
import {IPool} from "../../interfaces/IPool.sol";

contract MockVariableDebtToken is VariableDebtToken {
    constructor(IPool pool) VariableDebtToken(pool) {}

    function getRevision() internal pure override returns (uint256) {
        return 0x3;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {StableDebtToken} from "../../protocol/tokenization/StableDebtToken.sol";
import {IPool} from "../../interfaces/IPool.sol";

contract MockStableDebtToken is StableDebtToken {
    constructor(IPool pool) StableDebtToken(pool) {}

    function getRevision() internal pure override returns (uint256) {
        return 0x3;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {PToken} from "../../protocol/tokenization/PToken.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {IRewardController} from "../../interfaces/IRewardController.sol";

contract MockPToken is PToken {
    constructor(IPool pool) PToken(pool) {}

    function getRevision() internal pure override returns (uint256) {
        return 0x2;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {AccessControl} from "../../dependencies/openzeppelin/contracts/AccessControl.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {IACLManager} from "../../interfaces/IACLManager.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

/**
 * @title ACLManager
 *
 * @notice Access Control List Manager. Main registry of system roles and permissions.
 */
contract ACLManager is AccessControl, IACLManager {
    bytes32 public constant override POOL_ADMIN_ROLE = keccak256("POOL_ADMIN");
    bytes32 public constant override EMERGENCY_ADMIN_ROLE =
        keccak256("EMERGENCY_ADMIN");
    bytes32 public constant override RISK_ADMIN_ROLE = keccak256("RISK_ADMIN");
    bytes32 public constant override FLASH_BORROWER_ROLE =
        keccak256("FLASH_BORROWER");
    bytes32 public constant override BRIDGE_ROLE = keccak256("BRIDGE");
    bytes32 public constant override ASSET_LISTING_ADMIN_ROLE =
        keccak256("ASSET_LISTING_ADMIN");

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /**
     * @dev Constructor
     * @dev The ACL admin should be initialized at the addressesProvider beforehand
     * @param provider The address of the PoolAddressesProvider
     */
    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        address aclAdmin = provider.getACLAdmin();
        require(aclAdmin != address(0), Errors.ACL_ADMIN_CANNOT_BE_ZERO);
        _setupRole(DEFAULT_ADMIN_ROLE, aclAdmin);
    }

    /// @inheritdoc IACLManager
    function setRoleAdmin(bytes32 role, bytes32 adminRole)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setRoleAdmin(role, adminRole);
    }

    /// @inheritdoc IACLManager
    function addPoolAdmin(address admin) external override {
        grantRole(POOL_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function removePoolAdmin(address admin) external override {
        revokeRole(POOL_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function isPoolAdmin(address admin) external view override returns (bool) {
        return hasRole(POOL_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function addEmergencyAdmin(address admin) external override {
        grantRole(EMERGENCY_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function removeEmergencyAdmin(address admin) external override {
        revokeRole(EMERGENCY_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function isEmergencyAdmin(address admin)
        external
        view
        override
        returns (bool)
    {
        return hasRole(EMERGENCY_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function addRiskAdmin(address admin) external override {
        grantRole(RISK_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function removeRiskAdmin(address admin) external override {
        revokeRole(RISK_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function isRiskAdmin(address admin) external view override returns (bool) {
        return hasRole(RISK_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function addFlashBorrower(address borrower) external override {
        grantRole(FLASH_BORROWER_ROLE, borrower);
    }

    /// @inheritdoc IACLManager
    function removeFlashBorrower(address borrower) external override {
        revokeRole(FLASH_BORROWER_ROLE, borrower);
    }

    /// @inheritdoc IACLManager
    function isFlashBorrower(address borrower)
        external
        view
        override
        returns (bool)
    {
        return hasRole(FLASH_BORROWER_ROLE, borrower);
    }

    /// @inheritdoc IACLManager
    function addBridge(address bridge) external override {
        grantRole(BRIDGE_ROLE, bridge);
    }

    /// @inheritdoc IACLManager
    function removeBridge(address bridge) external override {
        revokeRole(BRIDGE_ROLE, bridge);
    }

    /// @inheritdoc IACLManager
    function isBridge(address bridge) external view override returns (bool) {
        return hasRole(BRIDGE_ROLE, bridge);
    }

    /// @inheritdoc IACLManager
    function addAssetListingAdmin(address admin) external override {
        grantRole(ASSET_LISTING_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function removeAssetListingAdmin(address admin) external override {
        revokeRole(ASSET_LISTING_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IACLManager
    function isAssetListingAdmin(address admin)
        external
        view
        override
        returns (bool)
    {
        return hasRole(ASSET_LISTING_ADMIN_ROLE, admin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IAccessControl.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol)

pragma solidity 0.8.10;

import {ERC721Enumerable} from "../../dependencies/openzeppelin/contracts/ERC721Enumerable.sol";
import {ERC721} from "../../dependencies/openzeppelin/contracts/ERC721.sol";
import {Context} from "../../dependencies/openzeppelin/contracts/Context.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract MintableERC721 is Context, ERC721Enumerable {
    string private _baseTokenURI;

    uint256 private tokenId;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, tokenId);

        tokenId++;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(uint256 count, address to) public virtual {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        for (uint256 index = 0; index < count; index++) {
            _mint(to, tokenId);

            tokenId++;
        }
    }

    function setBaseURI(string memory baseTokenURI) external {
        _baseTokenURI = baseTokenURI;
    }
}

pragma solidity 0.8.10;

import {INFTOracle} from "./interfaces/INFTOracle.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router01} from "./interfaces/IUniswapV2Router01.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IERC165} from "../dependencies/openzeppelin/contracts/IERC165.sol";
import {ERC20} from "../dependencies/openzeppelin/contracts/ERC20.sol";

contract ParaSpaceFallbackOracle {
    address public immutable BEND_DAO;
    address public immutable UNISWAP_FACTORY;
    address public immutable UNISWAP_ROUTER;
    address public immutable WETH;
    address public immutable USDC;

    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;

    constructor(
        address bendDAO,
        address uniswapFactory,
        address uniswapRouter,
        address weth,
        address usdc
    ) {
        BEND_DAO = bendDAO;
        UNISWAP_FACTORY = uniswapFactory;
        UNISWAP_ROUTER = uniswapRouter;
        WETH = weth;
        USDC = usdc;
    }

    function getAssetPrice(address asset) public view returns (uint256) {
        try IERC165(asset).supportsInterface(_InterfaceId_ERC721) returns (
            bool supported
        ) {
            if (supported == true) {
                return INFTOracle(BEND_DAO).getAssetPrice(asset);
            }
        } catch (
            bytes memory /*lowLevelData*/
        ) {
            address pairAddress = IUniswapV2Factory(UNISWAP_FACTORY).getPair(
                WETH,
                asset
            );
            require(pairAddress != address(0x00), "pair not found");
            IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
            (uint256 left, uint256 right, ) = pair.getReserves();
            (uint256 tokenReserves, uint256 ethReserves) = (asset < WETH)
                ? (left, right)
                : (right, left);
            uint8 decimals = ERC20(asset).decimals();
            //returns price in 18 decimals
            return
                IUniswapV2Router01(UNISWAP_ROUTER).getAmountOut(
                    10**decimals,
                    tokenReserves,
                    ethReserves
                );
        }
    }

    function getEthUsdPrice() public view returns (uint256) {
        address pairAddress = IUniswapV2Factory(UNISWAP_FACTORY).getPair(
            USDC,
            WETH
        );
        require(pairAddress != address(0x00), "pair not found");
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 left, uint256 right, ) = pair.getReserves();
        (uint256 usdcReserves, uint256 ethReserves) = (USDC < WETH)
            ? (left, right)
            : (right, left);
        uint8 ethDecimals = ERC20(WETH).decimals();
        uint8 usdcDecimals = ERC20(USDC).decimals();
        //returns price in 6 decimals
        return
            IUniswapV2Router01(UNISWAP_ROUTER).getAmountOut(
                10**ethDecimals,
                ethReserves,
                usdcReserves
            );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/************
@title INFTOracle interface
@notice Interface for NFT price oracle.*/
interface INFTOracle {
    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    // get asset price
    function getAssetPrice(address _nftContract)
        external
        view
        returns (uint256);
}

pragma solidity 0.8.10;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

pragma solidity 0.8.10;

interface IUniswapV2Router01 {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IReserveInterestRateStrategy} from "../../interfaces/IReserveInterestRateStrategy.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
import {WadRayMath} from "../../protocol/libraries/math/WadRayMath.sol";
import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

contract MockReserveInterestRateStrategy is IReserveInterestRateStrategy {
    uint256 public immutable OPTIMAL_USAGE_RATIO;
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    uint256 internal immutable _baseVariableBorrowRate;
    uint256 internal immutable _variableRateSlope1;
    uint256 internal immutable _variableRateSlope2;
    uint256 internal immutable _stableRateSlope1;
    uint256 internal immutable _stableRateSlope2;

    uint256 internal _liquidityRate;
    uint256 internal _stableBorrowRate;
    uint256 internal _variableBorrowRate;

    constructor(
        IPoolAddressesProvider provider,
        uint256 optimalUsageRatio,
        uint256 baseVariableBorrowRate,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2,
        uint256 stableRateSlope1,
        uint256 stableRateSlope2
    ) {
        OPTIMAL_USAGE_RATIO = optimalUsageRatio;
        ADDRESSES_PROVIDER = provider;
        _baseVariableBorrowRate = baseVariableBorrowRate;
        _variableRateSlope1 = variableRateSlope1;
        _variableRateSlope2 = variableRateSlope2;
        _stableRateSlope1 = stableRateSlope1;
        _stableRateSlope2 = stableRateSlope2;
    }

    function setLiquidityRate(uint256 liquidityRate) public {
        _liquidityRate = liquidityRate;
    }

    function setStableBorrowRate(uint256 stableBorrowRate) public {
        _stableBorrowRate = stableBorrowRate;
    }

    function setVariableBorrowRate(uint256 variableBorrowRate) public {
        _variableBorrowRate = variableBorrowRate;
    }

    function calculateInterestRates(
        DataTypes.CalculateInterestRatesParams memory
    )
        external
        view
        override
        returns (
            uint256 liquidityRate,
            uint256 stableBorrowRate,
            uint256 variableBorrowRate
        )
    {
        return (_liquidityRate, _stableBorrowRate, _variableBorrowRate);
    }

    function getVariableRateSlope1() external view returns (uint256) {
        return _variableRateSlope1;
    }

    function getVariableRateSlope2() external view returns (uint256) {
        return _variableRateSlope2;
    }

    function getStableRateSlope1() external view returns (uint256) {
        return _stableRateSlope1;
    }

    function getStableRateSlope2() external view returns (uint256) {
        return _stableRateSlope2;
    }

    function getBaseVariableBorrowRate()
        external
        view
        override
        returns (uint256)
    {
        return _baseVariableBorrowRate;
    }

    function getMaxVariableBorrowRate()
        external
        view
        override
        returns (uint256)
    {
        return
            _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";

contract MockPool {
    // Reserved storage space to avoid layout collisions.
    uint256[100] private ______gap;

    address internal _addressesProvider;
    address[] internal _reserveList;

    function initialize(address provider) external {
        _addressesProvider = provider;
    }

    function addReserveToReservesList(address reserve) external {
        _reserveList.push(reserve);
    }

    function getReservesList() external view returns (address[] memory) {
        address[] memory reservesList = new address[](_reserveList.length);
        for (uint256 i; i < _reserveList.length; i++) {
            reservesList[i] = _reserveList[i];
        }
        return reservesList;
    }
}

import {Pool} from "../../protocol/pool/Pool.sol";

contract MockPoolInherited is Pool {
    uint16 internal _maxNumberOfReserves = 128;

    function getRevision() internal pure override returns (uint256) {
        return 0x3;
    }

    constructor(IPoolAddressesProvider provider) Pool(provider) {}

    function setMaxNumberOfReserves(uint16 newMaxNumberOfReserves) public {
        _maxNumberOfReserves = newMaxNumberOfReserves;
    }

    function MAX_NUMBER_RESERVES() public view override returns (uint16) {
        return _maxNumberOfReserves;
    }

    function dropReserve(address asset) external override {
        _reservesList[_reserves[asset].id] = address(0);
        delete _reserves[asset];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IEACAggregatorProxy} from "../interfaces/IEACAggregatorProxy.sol";
import {Errors} from "../protocol/libraries/helpers/Errors.sol";
import {IACLManager} from "../interfaces/IACLManager.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";

interface NFTOracle {
    function getTwap(address token) external view returns (uint128 price);

    function getLastUpdateTime(address token)
        external
        view
        returns (uint128 timestamp);
}

contract ERC721OracleWrapper is IEACAggregatorProxy {
    NFTOracle private oracleAddress;
    address private immutable asset;
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /**
     * @dev Only asset listing or pool admin can call functions marked by this modifier.
     **/
    modifier onlyAssetListingOrPoolAdmins() {
        _onlyAssetListingOrPoolAdmins();
        _;
    }

    function _onlyAssetListingOrPoolAdmins() internal view {
        IACLManager aclManager = IACLManager(
            ADDRESSES_PROVIDER.getACLManager()
        );
        require(
            aclManager.isAssetListingAdmin(msg.sender) ||
                aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
        );
    }

    constructor(
        IPoolAddressesProvider provider,
        address _oracleAddress,
        address _asset
    ) {
        ADDRESSES_PROVIDER = provider;
        oracleAddress = NFTOracle(_oracleAddress);
        asset = _asset;
    }

    function setOracle(address _oracleAddress)
        external
        onlyAssetListingOrPoolAdmins
    {
        oracleAddress = NFTOracle(_oracleAddress);
    }

    function decimals() external view override returns (uint8) {
        return 18;
    }

    function latestAnswer() external view override returns (int256) {
        return int256(uint256(oracleAddress.getTwap(asset)));
    }

    function latestTimestamp() external view override returns (uint256) {
        return uint256(oracleAddress.getLastUpdateTime(asset));
    }

    function latestRound() external view override returns (uint256) {
        return 0;
    }

    function getAnswer(uint256 roundId)
        external
        view
        override
        returns (int256)
    {
        return int256(uint256(oracleAddress.getTwap(asset)));
    }

    function getTimestamp(uint256 roundId)
        external
        view
        override
        returns (uint256)
    {
        return uint256(oracleAddress.getLastUpdateTime(asset));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

interface IEACAggregatorProxy {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 timestamp
    );
    event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {VersionedInitializable} from "../../protocol/libraries/paraspace-upgradeability/VersionedInitializable.sol";

contract MockInitializableImple is VersionedInitializable {
    uint256 public value;
    string public text;
    uint256[] public values;

    uint256 public constant REVISION = 1;

    /**
     * @dev returns the revision number of the contract
     * Needs to be defined in the inherited class as a constant.
     **/
    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }

    function initialize(
        uint256 val,
        string memory txt,
        uint256[] memory vals
    ) external initializer {
        value = val;
        text = txt;
        values = vals;
    }

    function setValue(uint256 newValue) public {
        value = newValue;
    }

    function setValueViaProxy(uint256 newValue) public {
        value = newValue;
    }
}

contract MockInitializableImpleV2 is VersionedInitializable {
    uint256 public value;
    string public text;
    uint256[] public values;

    uint256 public constant REVISION = 2;

    /**
     * @dev returns the revision number of the contract
     * Needs to be defined in the inherited class as a constant.
     **/
    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }

    function initialize(
        uint256 val,
        string memory txt,
        uint256[] memory vals
    ) public initializer {
        value = val;
        text = txt;
        values = vals;
    }

    function setValue(uint256 newValue) public {
        value = newValue;
    }

    function setValueViaProxy(uint256 newValue) public {
        value = newValue;
    }
}

contract MockInitializableFromConstructorImple is VersionedInitializable {
    uint256 public value;

    uint256 public constant REVISION = 2;

    /**
     * @dev returns the revision number of the contract
     * Needs to be defined in the inherited class as a constant.
     **/
    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }

    constructor(uint256 val) {
        initialize(val);
    }

    function initialize(uint256 val) public initializer {
        value = val;
    }
}

contract MockReentrantInitializableImple is VersionedInitializable {
    uint256 public value;

    uint256 public constant REVISION = 2;

    /**
     * @dev returns the revision number of the contract
     * Needs to be defined in the inherited class as a constant.
     **/
    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }

    function initialize(uint256 val) public initializer {
        value = val;
        if (value < 2) {
            initialize(value + 1);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IRewardController} from "../../interfaces/IRewardController.sol";

contract MockIncentivesController is IRewardController {
    function getAssetData(address)
        external
        pure
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (0, 0, 0);
    }

    function assets(address)
        external
        pure
        override
        returns (
            uint128,
            uint128,
            uint256
        )
    {
        return (0, 0, 0);
    }

    function setClaimer(address, address) external override {}

    function getClaimer(address) external pure override returns (address) {
        return address(1);
    }

    function configureAssets(address[] calldata, uint256[] calldata)
        external
        override
    {}

    function handleAction(
        address,
        uint256,
        uint256
    ) external override {}

    function getRewardsBalance(address[] calldata, address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function claimRewards(
        address[] calldata,
        uint256,
        address
    ) external pure override returns (uint256) {
        return 0;
    }

    function claimRewardsOnBehalf(
        address[] calldata,
        uint256,
        address,
        address
    ) external pure override returns (uint256) {
        return 0;
    }

    function getRewardsByAsset(address asset)
        external
        view
        returns (address[] memory)
    {
        address[] memory rewards;

        return (rewards);
    }

    function getRewardsData(address asset, address reward)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (0, 0, 0, 0);
    }

    function getAssetDecimals(address asset) external view returns (uint8) {
        return 8;
    }

    function getUserUnclaimedRewards(address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function getUserAssetData(address, address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function REWARD_TOKEN() external pure override returns (address) {
        return address(0);
    }

    function PRECISION() external pure override returns (uint8) {
        return 0;
    }

    function DISTRIBUTION_END() external pure override returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {Ownable} from "../../../contracts/dependencies/openzeppelin/contracts/Ownable.sol";

contract CryptoPunksMarket is Ownable {
    // You can use this hash to verify the image file containing all the punks
    string public imageHash =
        "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

    string public standard = "CryptoPunks";
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public nextPunkIndexToAssign = 0;

    // bool public allPunksAssigned = false;
    bool public allPunksAssigned = true;
    uint256 public punksRemainingToAssign = 0;

    //mapping (address => uint) public addressToPunkIndex;
    mapping(uint256 => address) public punkIndexToAddress;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        uint256 minValue; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 punkIndex;
        address bidder;
        uint256 value;
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping(uint256 => Offer) public punksOfferedForSale;

    // A record of the highest punk bid
    mapping(uint256 => Bid) public punkBids;

    mapping(address => uint256) public pendingWithdrawals;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(
        address indexed from,
        address indexed to,
        uint256 punkIndex
    );
    event PunkOffered(
        uint256 indexed punkIndex,
        uint256 minValue,
        address indexed toAddress
    );
    event PunkBidEntered(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event PunkBidWithdrawn(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress
    );
    event PunkBought(
        uint256 indexed punkIndex,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event PunkNoLongerForSale(uint256 indexed punkIndex);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() {
        //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = 10000; // Update total supply
        punksRemainingToAssign = totalSupply;
        name = "CRYPTOPUNKS"; // Set the name for display purposes
        symbol = "\x3FE"; // Set the symbol for display purposes Ͼ
        decimals = 0; // Amount of decimals for display purposes
    }

    function setInitialOwner(address to, uint256 punkIndex) public onlyOwner {
        require(allPunksAssigned, "CryptoPunksMarket:  allPunksAssigned");
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

        if (punkIndexToAddress[punkIndex] != to) {
            if (punkIndexToAddress[punkIndex] != address(0)) {
                balanceOf[punkIndexToAddress[punkIndex]]--;
            } else {
                punksRemainingToAssign--;
            }
            punkIndexToAddress[punkIndex] = to;
            balanceOf[to]++;
            emit Assign(to, punkIndex);
        }
    }

    function setInitialOwners(
        address[] calldata addresses,
        uint256[] calldata indices
    ) public onlyOwner {
        uint256 n = addresses.length;
        for (uint256 i = 0; i < n; i++) {
            setInitialOwner(addresses[i], indices[i]);
        }
    }

    function allInitialOwnersAssigned() public onlyOwner {
        allPunksAssigned = true;
    }

    function getPunk(uint256 punkIndex) public {
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
        require(
            punksRemainingToAssign != 0,
            "CryptoPunksMarket: empty punksRemainingToAssign"
        );
        require(
            punkIndexToAddress[punkIndex] == address(0),
            "CryptoPunksMarket: already got"
        );
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[msg.sender]++;
        punksRemainingToAssign--;

        emit Assign(msg.sender, punkIndex);
    }

    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint256 punkIndex) public {
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
        require(
            punkIndexToAddress[punkIndex] == msg.sender,
            "CryptoPunksMarket: not owner"
        );
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;

        emit Transfer(msg.sender, to, 1);
        emit PunkTransfer(msg.sender, to, punkIndex);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == to) {
            // Kill bid and refund value
            pendingWithdrawals[to] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }
    }

    function punkNoLongerForSale(uint256 punkIndex) public {
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
        require(
            punkIndexToAddress[punkIndex] == msg.sender,
            "CryptoPunksMarket: not owner"
        );
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

        punksOfferedForSale[punkIndex] = Offer(
            false,
            punkIndex,
            msg.sender,
            0,
            address(0)
        );

        emit PunkNoLongerForSale(punkIndex);
    }

    function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei)
        public
    {
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
        require(
            punkIndexToAddress[punkIndex] == msg.sender,
            "CryptoPunksMarket: not owner"
        );
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

        punksOfferedForSale[punkIndex] = Offer(
            true,
            punkIndex,
            msg.sender,
            minSalePriceInWei,
            address(0)
        );

        emit PunkOffered(punkIndex, minSalePriceInWei, address(0));
    }

    function offerPunkForSaleToAddress(
        uint256 punkIndex,
        uint256 minSalePriceInWei,
        address toAddress
    ) public {
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
        require(
            punkIndexToAddress[punkIndex] == msg.sender,
            "CryptoPunksMarket: not owner"
        );
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

        punksOfferedForSale[punkIndex] = Offer(
            true,
            punkIndex,
            msg.sender,
            minSalePriceInWei,
            toAddress
        );

        emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
    }

    function buyPunk(uint256 punkIndex) public payable {
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

        Offer memory offer = punksOfferedForSale[punkIndex];
        require(
            offer.isForSale,
            "CryptoPunksMarket: punk not actually for sale"
        );
        require(
            offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender,
            "CryptoPunksMarket: punk not supposed to be sold to this user"
        );

        require(
            msg.value >= offer.minValue,
            "CryptoPunksMarket: Didn't send enough ETH"
        );
        require(
            offer.seller == punkIndexToAddress[punkIndex],
            "CryptoPunksMarket: Seller no longer owner of punk"
        );

        address seller = offer.seller;

        punkIndexToAddress[punkIndex] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;

        emit Transfer(seller, msg.sender, 1);

        punkNoLongerForSale(punkIndex);
        pendingWithdrawals[seller] += msg.value;

        emit PunkBought(punkIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = punkBids[punkIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        }
    }

    function withdraw() public {
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");

        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;

        _safeTransferETH(msg.sender, amount);
    }

    function enterBidForPunk(uint256 punkIndex) public payable {
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");
        require(
            punkIndexToAddress[punkIndex] != msg.sender,
            "CryptoPunksMarket: can not buy your own punk"
        );
        require(
            punkIndexToAddress[punkIndex] != address(0),
            "CryptoPunksMarket: can not buy unassigned punk"
        );
        require(msg.value > 0, "CryptoPunksMarket: should send eth value");

        Bid memory existing = punkBids[punkIndex];
        require(
            msg.value > existing.value,
            "CryptoPunksMarket: should send more eth value"
        );

        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);

        emit PunkBidEntered(punkIndex, msg.value, msg.sender);
    }

    function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) public {
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
        require(
            punkIndexToAddress[punkIndex] == msg.sender,
            "CryptoPunksMarket: not owner"
        );
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

        address seller = msg.sender;

        Bid memory bid = punkBids[punkIndex];
        require(bid.value >= minPrice, "CryptoPunksMarket: bid value to small");

        punkIndexToAddress[punkIndex] = bid.bidder;
        balanceOf[seller]--;
        balanceOf[bid.bidder]++;

        emit Transfer(seller, bid.bidder, 1);

        punksOfferedForSale[punkIndex] = Offer(
            false,
            punkIndex,
            bid.bidder,
            0,
            address(0)
        );
        uint256 amount = bid.value;
        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
        pendingWithdrawals[seller] += amount;

        emit PunkBought(punkIndex, bid.value, seller, bid.bidder);
    }

    function withdrawBidForPunk(uint256 punkIndex) public {
        require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");
        require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
        require(
            punkIndexToAddress[punkIndex] != address(0),
            "CryptoPunksMarket: punk not assigned"
        );
        require(
            punkIndexToAddress[punkIndex] != msg.sender,
            "CryptoPunksMarket: can not withdraw self"
        );

        Bid memory bid = punkBids[punkIndex];
        require(bid.bidder == msg.sender, "CryptoPunksMakrket: not bid bidder");

        emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);

        uint256 amount = bid.value;

        punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);

        // Refund the bid money
        _safeTransferETH(msg.sender, amount);
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {PoolConfigurator} from "../protocol/pool/PoolConfigurator.sol";
import {Ownable} from "../dependencies/openzeppelin/contracts/Ownable.sol";

/**
 * @title ReservesSetupHelper
 *
 * @notice Deployment helper to setup the assets risk parameters at PoolConfigurator in batch.
 * @dev The ReservesSetupHelper is an Ownable contract, so only the deployer or future owners can call this contract.
 */
contract ReservesSetupHelper is Ownable {
    struct ConfigureReserveInput {
        address asset;
        uint256 baseLTV;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 reserveFactor;
        uint256 borrowCap;
        uint256 supplyCap;
        bool stableBorrowingEnabled;
        bool borrowingEnabled;
    }

    /**
     * @notice External function called by the owner account to setup the assets risk parameters in batch.
     * @dev The Pool or Risk admin must transfer the ownership to ReservesSetupHelper before calling this function
     * @param configurator The address of PoolConfigurator contract
     * @param inputParams An array of ConfigureReserveInput struct that contains the assets and their risk parameters
     */
    function configureReserves(
        PoolConfigurator configurator,
        ConfigureReserveInput[] calldata inputParams
    ) external onlyOwner {
        for (uint256 i = 0; i < inputParams.length; i++) {
            configurator.configureReserveAsCollateral(
                inputParams[i].asset,
                inputParams[i].baseLTV,
                inputParams[i].liquidationThreshold,
                inputParams[i].liquidationBonus
            );

            if (inputParams[i].borrowingEnabled) {
                configurator.setReserveBorrowing(inputParams[i].asset, true);

                configurator.setBorrowCap(
                    inputParams[i].asset,
                    inputParams[i].borrowCap
                );
                configurator.setReserveStableRateBorrowing(
                    inputParams[i].asset,
                    inputParams[i].stableBorrowingEnabled
                );
            }
            configurator.setSupplyCap(
                inputParams[i].asset,
                inputParams[i].supplyCap
            );
            configurator.setReserveFactor(
                inputParams[i].asset,
                inputParams[i].reserveFactor
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {WadRayMath} from "../../protocol/libraries/math/WadRayMath.sol";

contract WadRayMathWrapper {
    function wad() public pure returns (uint256) {
        return WadRayMath.WAD;
    }

    function ray() public pure returns (uint256) {
        return WadRayMath.RAY;
    }

    function halfRay() public pure returns (uint256) {
        return WadRayMath.HALF_RAY;
    }

    function halfWad() public pure returns (uint256) {
        return WadRayMath.HALF_WAD;
    }

    function wadMul(uint256 a, uint256 b) public pure returns (uint256) {
        return WadRayMath.wadMul(a, b);
    }

    function wadDiv(uint256 a, uint256 b) public pure returns (uint256) {
        return WadRayMath.wadDiv(a, b);
    }

    function rayMul(uint256 a, uint256 b) public pure returns (uint256) {
        return WadRayMath.rayMul(a, b);
    }

    function rayDiv(uint256 a, uint256 b) public pure returns (uint256) {
        return WadRayMath.rayDiv(a, b);
    }

    function rayToWad(uint256 a) public pure returns (uint256) {
        return WadRayMath.rayToWad(a);
    }

    function wadToRay(uint256 a) public pure returns (uint256) {
        return WadRayMath.wadToRay(a);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {ReserveConfiguration} from "../../protocol/libraries/configuration/ReserveConfiguration.sol";
import {DataTypes} from "../../protocol/libraries/types/DataTypes.sol";

contract MockReserveConfiguration {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    DataTypes.ReserveConfigurationMap public configuration;

    function setLtv(uint256 ltv) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setLtv(ltv);
        configuration = config;
    }

    function getLtv() external view returns (uint256) {
        return configuration.getLtv();
    }

    function setLiquidationBonus(uint256 bonus) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setLiquidationBonus(bonus);
        configuration = config;
    }

    function getLiquidationBonus() external view returns (uint256) {
        return configuration.getLiquidationBonus();
    }

    function setLiquidationThreshold(uint256 threshold) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setLiquidationThreshold(threshold);
        configuration = config;
    }

    function getLiquidationThreshold() external view returns (uint256) {
        return configuration.getLiquidationThreshold();
    }

    function setDecimals(uint256 decimals) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setDecimals(decimals);
        configuration = config;
    }

    function getDecimals() external view returns (uint256) {
        return configuration.getDecimals();
    }

    function setFrozen(bool frozen) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setFrozen(frozen);
        configuration = config;
    }

    function getFrozen() external view returns (bool) {
        return configuration.getFrozen();
    }

    function setBorrowingEnabled(bool enabled) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setBorrowingEnabled(enabled);
        configuration = config;
    }

    function getBorrowingEnabled() external view returns (bool) {
        return configuration.getBorrowingEnabled();
    }

    function setStableRateBorrowingEnabled(bool enabled) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setStableRateBorrowingEnabled(enabled);
        configuration = config;
    }

    function getStableRateBorrowingEnabled() external view returns (bool) {
        return configuration.getStableRateBorrowingEnabled();
    }

    function setReserveFactor(uint256 reserveFactor) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setReserveFactor(reserveFactor);
        configuration = config;
    }

    function getReserveFactor() external view returns (uint256) {
        return configuration.getReserveFactor();
    }

    function setBorrowCap(uint256 borrowCap) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setBorrowCap(borrowCap);
        configuration = config;
    }

    function getBorrowCap() external view returns (uint256) {
        return configuration.getBorrowCap();
    }

    function setSupplyCap(uint256 supplyCap) external {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setSupplyCap(supplyCap);
        configuration = config;
    }

    function getSupplyCap() external view returns (uint256) {
        return configuration.getSupplyCap();
    }

    function setLiquidationProtocolFee(uint256 liquidationProtocolFee)
        external
    {
        DataTypes.ReserveConfigurationMap memory config = configuration;
        config.setLiquidationProtocolFee(liquidationProtocolFee);
        configuration = config;
    }

    function getLiquidationProtocolFee() external view returns (uint256) {
        return configuration.getLiquidationProtocolFee();
    }

    function getFlags()
        external
        view
        returns (
            bool,
            bool,
            bool,
            bool,
            bool
        )
    {
        return configuration.getFlags();
    }

    function getParams()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return configuration.getParams();
    }

    function getCaps() external view returns (uint256, uint256) {
        return configuration.getCaps();
    }
}