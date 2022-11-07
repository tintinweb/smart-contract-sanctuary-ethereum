// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../dependencies/openzeppelin/contracts/AccessControl.sol";
import "../dependencies/openzeppelin/upgradeability/Initializable.sol";
import "./interfaces/INFTFloorOracle.sol";

//maxSubmissions by default we keep 3 submission at most for each feeder
uint8 constant Default_MaxSubmissions = 3;
//minCountToAggregate to aggregate with,at least the number of feeders
//assume we deploy 3 oracle clients here
uint8 constant Default_MinCountToAggregate = 3;
//expirationPeriod at least the interval of client to feed data(currently 6h=21600s in mainnet)
//we do not accept price lags behind to much
uint64 constant Default_ExpirationPeriod = 21600;
//reject when price increase/decrease 10 times more than original value
uint128 constant Default_MaxPriceDeviation = 10;

struct OracleConfig {
	// Max submissions for each feeder
	uint8 maxSubmissions;
	// Min count to aggregate price with
	uint8 minCountToAggregate;
	// Expiration Period for each feed price
	uint64 expirationPeriod;
	// Maximum deviation allowed between two consecutive oracle prices
	uint128 maxPriceDeviation;
}

struct PriceInformation {
	/// @dev last reported floor price
	uint128 twap;
	uint64 lastUpdateTime;
}

struct PricePriceInformationBuffer {
	/// @dev next index in ring buffer
	uint8 next;
	/// @dev last reported floor price
	PriceInformation[Default_MaxSubmissions] ring;
}

struct FeederRegistrar {
	// if asset not registered,reject the price
	bool registered;
	// index in asset list
	uint8 index;
	// if asset paused,reject the price
	bool paused;
	// feeder -> PricePriceInformationBuffer
	mapping(address => PricePriceInformationBuffer) feederBuffer;
}

/// @title A simple on-chain price oracle mechanism
/// @author github.com/drbh,github.com/yrong
/// @notice Offchain clients can update the prices in this contract. The public can read prices
/// aggeregate prices which are not expired from different feeders, if number of valid/unexpired prices
/// not enough, we do not aggeregate and just use previous price
contract NFTFloorOracle is Initializable, AccessControl, INFTFloorOracle {
	event AssetAdded(address indexed asset);
	event AssetRemoved(address indexed asset);
	event SetAssetData(address indexed asset, uint128 price, uint64 timestamp);
	event OracleNodesSet(address[] indexed nodes);
	event OracleConfigSet(
		uint8 maxSubmissions,
		uint8 minCountToAggregate,
		uint64 expirationPeriod,
		uint128 maxPriceDeviation
	);
	event OracleNftPaused(address indexed asset, bool paused);

	bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

	/// @dev Aggregated price with address
	// the NFT contract -> price information
	mapping(address => PriceInformation) internal priceMap;

	/// @dev All valid feeders
	address[] internal feeders;

	/// @dev All asset list
	address[] internal nfts;

	/// @dev Original raw value to aggregate with
	// contract address -> FeederRegistrar
	mapping(address => FeederRegistrar) internal priceFeederMap;

	/// @dev storage for oracle configurations
	OracleConfig internal config;

	modifier whenNotPaused(address _nftContract) {
		if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
			_whenNotPaused(_nftContract);
		}
		_;
	}

	function _whenNotPaused(address _nftContract) internal view {
		bool _paused = priceFeederMap[_nftContract].paused;
		require(!_paused, "NFTOracle: nft price feed paused");
	}

	function setPause(address _nftContract, bool val)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		priceFeederMap[_nftContract].paused = val;
		emit OracleNftPaused(_nftContract, val);
	}

	modifier onlyWhenKeyExisted(address _nftContract) {
		require(isExistedKey(_nftContract), "NFTOracle: asset not existed");
		_;
	}

	modifier onlyWhenKeyNotExisted(address _nftContract) {
		require(!isExistedKey(_nftContract), "NFTOracle: asset existed");
		_;
	}

	function isExistedKey(address _nftContract) private view returns (bool) {
		return priceFeederMap[_nftContract].registered;
	}

	function _addAsset(address _nftContract)
		internal
		onlyWhenKeyNotExisted(_nftContract)
	{
		priceFeederMap[_nftContract].registered = true;
		nfts.push(_nftContract);
		priceFeederMap[_nftContract].index = uint8(nfts.length - 1);
		emit AssetAdded(_nftContract);
	}

	function _removeAsset(address _nftContract)
		internal
		onlyWhenKeyExisted(_nftContract)
	{
		delete priceMap[_nftContract];
		if (nfts[priceFeederMap[_nftContract].index] == _nftContract) {
			delete nfts[priceFeederMap[_nftContract].index];
		}
		delete priceFeederMap[_nftContract];
		emit AssetRemoved(_nftContract);
	}

	function addAssets(address[] calldata _nftContracts)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		for (uint256 i = 0; i < _nftContracts.length; i++) {
			_addAsset(_nftContracts[i]);
		}
	}

	function removeAsset(address _nftContract)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
		onlyWhenKeyExisted(_nftContract)
	{
		_removeAsset(_nftContract);
	}

	/// @notice set nft assets.
	/// @param assets assets to set
	function _setAssets(address[] memory assets) internal {
		for (uint256 i = 0; i < assets.length; i++) {
			_addAsset(assets[i]);
		}
	}

	/// @notice Allow contract creator to set admin and first updater
	/// @param admin The admin who can change roles
	/// @param updaters The initial updaters
	/// @param assets The initial nft assets
	function initialize(
		address admin,
		address[] memory updaters,
		address[] memory assets
	) public initializer {
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
		_setupRole(UPDATER_ROLE, admin);
		_setAssets(assets);
		_setOracles(updaters);
		_setConfig(
			Default_MinCountToAggregate,
			Default_ExpirationPeriod,
			Default_MaxPriceDeviation
		);
	}

	/// @notice set oracle configs
	/// @param expirationPeriod only prices not expired will be aggregated with
	/// @param minCountToAggregate the minimum number of valid price to aggregate with
	/// @param maxPriceDeviation use to reject when price increase/decrease more than this value
	function _setConfig(
		uint8 minCountToAggregate,
		uint64 expirationPeriod,
		uint128 maxPriceDeviation
	) internal {
		// since we use ring buffer, to keep it simple not allow to change maxSubmissions here
		// or need extra steps to reallocate storage
		config.maxSubmissions = Default_MaxSubmissions;
		config.minCountToAggregate = minCountToAggregate;
		config.expirationPeriod = expirationPeriod;
		config.maxPriceDeviation = maxPriceDeviation;
		emit OracleConfigSet(
			Default_MaxSubmissions,
			minCountToAggregate,
			expirationPeriod,
			maxPriceDeviation
		);
	}

	/// @notice set oracles.
	/// @param nodes feeders to set
	function _setOracles(address[] memory nodes) internal {
		for (uint256 i = 0; i < feeders.length; i++) {
			revokeRole(UPDATER_ROLE, feeders[i]);
		}
		for (uint256 i = 0; i < nodes.length; i++) {
			_setupRole(UPDATER_ROLE, nodes[i]);
		}
		feeders = nodes;
		emit OracleNodesSet(nodes);
	}

	/// @notice Allows owner to change oracles.
	/// @param nodes feeders to set
	function setOracles(address[] calldata nodes)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		_setOracles(nodes);
	}

	/// @notice Allows owner to update oracle configs
	function setConfig(
		uint8 minCountToAggregate,
		uint64 expirationPeriod,
		uint128 maxPriceDeviation
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_setConfig(minCountToAggregate, expirationPeriod, maxPriceDeviation);
	}

	function checkValidityOfPrice(address _nftContract, uint128 _price)
		private
		view
		returns (bool)
	{
		require(_price > 0, "NFTOracle: price should be more than 0");
		PriceInformation memory priceMapEntry = priceMap[_nftContract];
		uint128 price = priceMapEntry.twap;
		uint64 timestamp = priceMapEntry.lastUpdateTime;
		uint256 percentDeviation;
		//first price is always valid
		if (price == 0 || timestamp == 0) {
			return true;
		}
		if (_price > price) {
			percentDeviation = _price / price;
		} else {
			percentDeviation = price / _price;
		}
		if (percentDeviation >= config.maxPriceDeviation) {
			return false;
		}
		return true;
	}

	/// @notice Allows updater to set new price on PriceInformation and updates the
	/// internal TWAP cumulativePrice.
	/// @param token The nft contracts to set a floor price for
	/// @param twap The last floor twap
	function setPrice(address token, uint128 twap)
		public
		onlyRole(UPDATER_ROLE)
		onlyWhenKeyExisted(token)
		whenNotPaused(token)
	{
		bool dataValidity = false;
		if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
			finalizePrice(token, twap);
			return;
		}
		dataValidity = checkValidityOfPrice(token, twap);
		require(dataValidity, "NFTOracle: invalid price data");
		// add price to raw feeder storage
		addRawValue(token, twap);
		uint128 medianPrice;
		// set twap price only when median value is valid
		(dataValidity, medianPrice) = combine(token, twap);
		if (dataValidity) {
			finalizePrice(token, medianPrice);
		}
	}

	function finalizePrice(address token, uint128 twap) internal {
		PriceInformation storage priceMapEntry = priceMap[token];
		priceMapEntry.twap = twap;
		priceMapEntry.lastUpdateTime = uint64(block.timestamp);
		emit SetAssetData(
			token,
			priceMapEntry.twap,
			priceMapEntry.lastUpdateTime
		);
	}

	function addRawValue(address token, uint128 twap) internal {
		FeederRegistrar storage feederRegistrar = priceFeederMap[token];
		PricePriceInformationBuffer storage priceBuffer = feederRegistrar
			.feederBuffer[msg.sender];
		if (priceBuffer.next >= config.maxSubmissions) {
			priceBuffer.next -= config.maxSubmissions;
		}
		priceBuffer.ring[priceBuffer.next] = PriceInformation({
			twap: twap,
			lastUpdateTime: uint64(block.timestamp)
		});
		priceBuffer.next += 1;
	}

	function combine(address token, uint128 twap)
		internal
		view
		returns (bool, uint128)
	{
		FeederRegistrar storage feederRegistrar = priceFeederMap[token];
		uint64 _timestamp = uint64(block.timestamp);
		//first time just use the feeding value
		if (priceMap[token].twap == 0) {
			return (true, twap);
		}
		//use memory here so allocate with maximum length
		uint128[] memory validPriceList = new uint128[](
			feeders.length * config.maxSubmissions
		);
		uint256 validNum = 0;
		//aggeregate with feed prices from all feeders
		for (uint256 i = 0; i < feeders.length; i++) {
			PricePriceInformationBuffer memory priceBuffer = feederRegistrar
				.feederBuffer[feeders[i]];
			for (uint256 j = 0; j < priceBuffer.ring.length; j++) {
				PriceInformation memory priceInfo = priceBuffer.ring[j];
				if (priceInfo.lastUpdateTime > 0) {
					uint64 laggingTimestamp = _timestamp -
						priceInfo.lastUpdateTime;
					if (laggingTimestamp <= config.expirationPeriod) {
						//since it is memory array we can not push here
						validPriceList[validNum] = priceInfo.twap;
						validNum++;
					}
				}
			}
			//break earlier if we have enough valid prices
			if (validNum >= config.minCountToAggregate) {
				break;
			}
		}

		// only calculate median value when number of valid data greater than minCountToAggregate
		if (validNum >= config.minCountToAggregate) {
			// ignore sort for saving gas, we just pick fixed element from validPriceList
			// sort(validPriceList, 0, validNum);
			return (true, validPriceList[config.minCountToAggregate / 2]);
		}
		// or use the previous twap instead
		return (false, priceMap[token].twap);
	}

	/// @notice Allows owner to set new price on PriceInformation and updates the
	/// internal TWAP cumulativePrice.
	/// @param tokens The nft contract to set a floor price for
	function setMultiplePrices(
		address[] calldata tokens,
		uint128[] calldata twaps
	) external onlyRole(UPDATER_ROLE) {
		require(
			tokens.length == twaps.length,
			"Tokens and price length differ"
		);
		for (uint256 i = 0; i < tokens.length; i++) {
			setPrice(tokens[i], twaps[i]);
		}
	}

	/// @param token The nft contract
	/// @return twap The most recent twap on chain
	function getTwap(address token) external view returns (uint128 twap) {
		return priceMap[token].twap;
	}

	/// @param token The nft contract
	/// @return timestamp The timestamp of the last update for an asset
	function getLastUpdateTime(address token)
		external
		view
		returns (uint128 timestamp)
	{
		return priceMap[token].lastUpdateTime;
	}

	function getFeeders() external view returns (address[] memory) {
		return feeders;
	}

	function getFeederPriceList(address token, address feeder)
		external
		view
		returns (PriceInformation[Default_MaxSubmissions] memory)
	{
		FeederRegistrar storage feederRegistrar = priceFeederMap[token];
		PriceInformation[Default_MaxSubmissions]
			memory pricesList = feederRegistrar.feederBuffer[feeder].ring;
		return pricesList;
	}

	function getConfig() external view returns (OracleConfig memory) {
		return config;
	}

	function getAssets() external view returns (address[] memory) {
		return nfts;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface INFTFloorOracle {
	function getTwap(address token) external view returns (uint128 price);

	function getLastUpdateTime(address token)
		external
		view
		returns (uint128 timestamp);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.10;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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