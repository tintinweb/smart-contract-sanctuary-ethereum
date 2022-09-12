// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./StakingPoolCurator.sol";
import "./StakingPoolCreator.sol";
import "../dao-configuration/DaoConfiguration.sol";
import "../Version.sol";
import "../sweep/SweepERC20.sol";

/**
 * @title Mediates between a StakingPool creator and StakingPool curator.
 *
 * @dev Orchestrates a StakingPoolCreator and StakingPoolCurator to provide a single function to aggregate the various calls
 *      providing a single function to create and setup a staking pool for management with the curator.
 */
contract StakingPoolMediator is
    DaoConfiguration,
    StakingPoolCurator,
    SweepERC20,
    UUPSUpgradeable,
    Version
{
    StakingPoolCreator private _creator;

    event StakingPoolCreatorUpdate(
        address indexed previousCreator,
        address indexed updateCreator,
        address indexed instigator
    );

    /**
     * @notice The _msgSender() is given membership of all roles, to allow granting and future renouncing after others
     *      have been setup.
     *
     * @param factory A deployed StakingPoolFactory contract to use when creating bonds.
     * @param treasury Beneficiary of any token sweeping.
     */
    function initialize(StakingPoolCreator factory, address treasury)
        external
        initializer
    {
        require(
            AddressUpgradeable.isContract(address(factory)),
            "SPM: creator not a contract"
        );

        __StakingPoolCurator_init();
        __DaoConfiguration_init();
        __UUPSUpgradeable_init();
        __TokenSweep_init(treasury);

        _creator = factory;
    }

    function createDao(address erc20CapableTreasury)
        external
        atLeastDaoCreatorRole
        returns (uint256)
    {
        uint256 id = _daoConfiguration(erc20CapableTreasury);
        _grantDaoCreatorAdminRoleInTheirDao(id);

        emit CreateDao(id, erc20CapableTreasury, _msgSender());

        return id;
    }

    function createManagedStakingPool(
        StakingPoolLib.Config calldata config,
        bool launchPaused,
        uint32 rewardsAvailableTimestamp
    )
        external
        whenNotPaused
        atLeastDaoMeepleRole(config.daoId)
        returns (address)
    {
        require(_isValidDaoId(config.daoId), "SPM: invalid DAO Id");
        require(
            isAllowedDaoCollateral(config.daoId, address(config.stakeToken)),
            "SPM: collateral not whitelisted"
        );

        // Reentrancy warning from an emitted event, which needs the Bond, created by an external call above.
        //slither-disable-next-line reentrancy-events
        address stakingPool = _creator.createStakingPool(
            config,
            launchPaused,
            rewardsAvailableTimestamp
        );

        _addStakingPool(config.daoId, stakingPool);

        return stakingPool;
    }

    /**
     * @notice Permits updating the meta data for the DAO.
     */
    function setDaoMetaData(uint256 daoId, string calldata replacement)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _setDaoMetaData(daoId, replacement);
    }

    /**
     * @notice Updates the StakingPool creator reference.
     *
     * @param factory Contract address for the new StakingPoolCreator to use from now onwards when creating managed bonds.
     */
    function setStakingPoolCreator(address factory)
        external
        whenNotPaused
        atLeastSysAdminRole
    {
        require(
            AddressUpgradeable.isContract(factory),
            "SPM: creator not a contract"
        );
        address previousCreator = address(_creator);
        require(factory != previousCreator, "SPM: matches existing");

        emit StakingPoolCreatorUpdate(
            address(_creator),
            address(factory),
            _msgSender()
        );
        _creator = StakingPoolCreator(factory);
    }

    /**
     * @notice Permits updating the default DAO treasury address.
     *
     * @dev Only applies for bonds created after the update, previously created bond treasury addresses remain unchanged.
     */
    function setDaoTreasury(uint256 daoId, address replacement)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _setDaoTreasury(daoId, replacement);
    }

    function updateTokenSweepBeneficiary(address newBeneficiary)
        external
        whenNotPaused
        onlySuperUserRole
    {
        _setTokenSweepBeneficiary(newBeneficiary);
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        whenNotPaused
        onlySuperUserRole
    {
        _sweepERC20Tokens(tokens, amount);
    }

    /**
     * @notice Adds an ERC20 token to the collateral whitelist.
     *
     * @dev When a staking pool is created, the tokens used as collateral must have been whitelisted.
     *
     * @param daoId The DAO who is having the collateral token whitelisted.
     * @param erc20CollateralTokens Whitelists the token from now onwards.
     *      On staking pool creation the tokens address used is retrieved by symbol from the whitelist.
     */
    function whitelistCollateral(uint256 daoId, address erc20CollateralTokens)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _whitelistDaoCollateral(daoId, erc20CollateralTokens);
    }

    function stakingPoolCreator() external view returns (address) {
        return address(_creator);
    }

    /**
     * @notice Permits only the relevant admins to perform proxy upgrades.
     *
     * @dev Only applicable when deployed as implementation to a UUPS proxy.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        atLeastSysAdminRole
    {}

    function _grantDaoCreatorAdminRoleInTheirDao(uint256 daoId) private {
        if (_hasGlobalRole(Roles.DAO_CREATOR, _msgSender())) {
            _grantDaoRole(daoId, Roles.DAO_ADMIN, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../RoleAccessControl.sol";
import "./StakingPool.sol";
import "./StakingPoolLib.sol";

/**
 * @title Manages interactions with StakingPool contracts.
 *
 * @notice A central place to discover created StakingPools and apply access control to them.
 *
 * @dev Owns of all StakingPools it manages, guarding function accordingly allows finer access control to be provided.
 */
abstract contract StakingPoolCurator is RoleAccessControl, PausableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(uint256 => EnumerableSetUpgradeable.AddressSet)
        private _stakingPools;

    event AddStakingPool(
        uint256 indexed daoId,
        address indexed stakingPool,
        address indexed instigator
    );

    function stakingPoolPause(uint256 daoId, address stakingPool)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).pause();
    }

    function stakingPoolUnpause(uint256 daoId, address stakingPool)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).unpause();
    }

    function stakingPoolInitializeRewardTokens(
        uint256 daoId,
        address stakingPool,
        address benefactor,
        StakingPoolLib.Reward[] calldata rewards
    ) external whenNotPaused atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).initializeRewardTokens(benefactor, rewards);
    }

    function stakingPoolEnableEmergencyMode(uint256 daoId, address stakingPool)
        external
        atLeastDaoMeepleRole(daoId)
    {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).enableEmergencyMode();
    }

    function stakingPoolAdminEmergencyRewardSweep(
        uint256 daoId,
        address stakingPool
    ) external atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).adminEmergencyRewardSweep();
    }

    function stakingPoolSetRewardsAvailableTimestamp(
        uint256 daoId,
        address stakingPool,
        uint32 timestamp
    ) external atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).setRewardsAvailableTimestamp(timestamp);
    }

    function stakingPoolSweepERC20Tokens(
        uint256 daoId,
        address stakingPool,
        address tokens,
        uint256 amount
    ) external atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).sweepERC20Tokens(tokens, amount);
    }

    function stakingPoolUpdateTokenSweepBeneficiary(
        uint256 daoId,
        address stakingPool,
        address newBeneficiary
    ) external atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).updateTokenSweepBeneficiary(newBeneficiary);
    }

    /**
     * @notice Pauses most side affecting functions.
     */
    function pause() external whenNotPaused atLeastSysAdminRole {
        _pause();
    }

    /**
     * @notice Resumes all paused side affecting functions.
     */
    function unpause() external whenPaused atLeastSysAdminRole {
        _unpause();
    }

    function stakingPoolAt(uint256 daoId, uint256 index)
        external
        view
        returns (address)
    {
        require(
            index < EnumerableSetUpgradeable.length(_stakingPools[daoId]),
            "StakingPool: too large"
        );

        return EnumerableSetUpgradeable.at(_stakingPools[daoId], index);
    }

    function stakingPoolCount(uint256 daoId) external view returns (uint256) {
        return EnumerableSetUpgradeable.length(_stakingPools[daoId]);
    }

    function _addStakingPool(uint256 daoId, address stakingPool)
        internal
        whenNotPaused
    {
        require(
            !_stakingPools[daoId].contains(stakingPool),
            "StakingPool: already managing"
        );
        require(
            OwnableUpgradeable(stakingPool).owner() == address(this),
            "StakingPool: not owner"
        );

        emit AddStakingPool(daoId, stakingPool, _msgSender());

        bool added = _stakingPools[daoId].add(stakingPool);
        require(added, "StakingPool: failed to add");
    }

    //slither-disable-next-line naming-convention
    function __StakingPoolCurator_init() internal onlyInitializing {
        __RoleAccessControl_init();
        __Pausable_init();
    }

    function _requireManagingStakingPool(uint256 daoId, address stakingPool)
        private
        view
    {
        require(
            _stakingPools[daoId].contains(stakingPool),
            "StakingPool: not managing"
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./StakingPoolLib.sol";

/**
 * @title Deploys new StakingPools.
 *
 * @notice Creating a StakingPool involves the two steps of deploying and initialising.
 */
interface StakingPoolCreator {
    /**
     * @notice Deploys and initialises a new StakingPool.
     */
    function createStakingPool(
        StakingPoolLib.Config calldata config,
        bool launchPaused,
        uint32 rewardsAvailableTimestamp
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./DaoCollateralWhitelist.sol";

abstract contract DaoConfiguration is DaoCollateralWhitelist {
    struct DaoConfig {
        // Address zero is an invalid address, can be used to identify null structs
        address treasury;
        string metaData;
        CollateralWhitelist whitelist;
    }

    mapping(uint256 => DaoConfig) private _daoConfig;
    uint256 private _daoConfigLastId;

    event DaoTreasuryUpdate(
        uint256 indexed daoId,
        address indexed treasury,
        address indexed instigator
    );

    event CreateDao(
        uint256 indexed id,
        address indexed treasury,
        address indexed instigator
    );

    event DaoMetaDataUpdate(
        uint256 indexed daoId,
        string data,
        address indexed instigator
    );

    function daoTreasury(uint256 daoId) external view returns (address) {
        return _daoConfig[daoId].treasury;
    }

    function daoMetaData(uint256 daoId) external view returns (string memory) {
        return _daoConfig[daoId].metaData;
    }

    function highestDaoId() external view returns (uint256) {
        return _daoConfigLastId;
    }

    /**
     * @notice The _msgSender() is given membership of all roles, to allow granting and future renouncing after others
     *      have been setup.
     */
    //slither-disable-next-line naming-convention
    function __DaoConfiguration_init() internal onlyInitializing {
        __DaoCollateralWhitelist_init();
    }

    function _daoConfiguration(address erc20CapableTreasury)
        internal
        returns (uint256)
    {
        require(
            erc20CapableTreasury != address(0),
            "DAO Treasury: address is zero"
        );

        _daoConfigLastId++;

        _setTreasury(_daoConfigLastId, erc20CapableTreasury);

        return _daoConfigLastId;
    }

    function _setDaoTreasury(uint256 daoId, address replacementTreasury)
        internal
    {
        require(_isValidDaoId(daoId), "DAO Treasury: invalid DAO Id");
        require(
            replacementTreasury != address(0),
            "DAO Treasury: address is zero"
        );
        require(
            _daoConfig[daoId].treasury != replacementTreasury,
            "DAO Treasury: identical address"
        );
        _setTreasury(daoId, replacementTreasury);
    }

    function _setDaoMetaData(uint256 daoId, string calldata replacementMetaData)
        internal
    {
        _daoConfig[daoId].metaData = replacementMetaData;
        emit DaoMetaDataUpdate(daoId, replacementMetaData, _msgSender());
    }

    function _daoCollateralWhitelist(uint256 daoId)
        internal
        view
        override
        returns (CollateralWhitelist storage)
    {
        return _daoConfig[daoId].whitelist;
    }

    function _daoTreasury(uint256 daoId) internal view returns (address) {
        return _daoConfig[daoId].treasury;
    }

    function _isValidDaoId(uint256 daoId)
        internal
        view
        override
        returns (bool)
    {
        return _daoConfig[daoId].treasury != address(0);
    }

    function _setTreasury(uint256 daoId, address treasury) private {
        _daoConfig[daoId].treasury = treasury;
        emit DaoTreasuryUpdate(daoId, treasury, _msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

abstract contract Version {
    string public constant VERSION = "v0.0.1";
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./TokenSweep.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Adds the ability to sweep ERC20 tokens to a beneficiary address
 */
abstract contract SweepERC20 is TokenSweep {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event ERC20Sweep(
        address indexed beneficiary,
        address indexed tokens,
        uint256 amount,
        address indexed instigator
    );

    /**
     * @notice Sweep the erc20 tokens to the beneficiary address
     *
     * @param tokens The registry for the ERC20 token to transfer,
     * @param amount How many tokens, in the ERC20's decimals to transfer.
     **/
    function _sweepERC20Tokens(address tokens, uint256 amount) internal {
        require(tokens != address(this), "SweepERC20: self transfer");
        require(tokens != address(0), "SweepERC20: address zero");

        emit ERC20Sweep(tokenSweepBeneficiary(), tokens, amount, _msgSender());

        IERC20Upgradeable(tokens).safeTransfer(tokenSweepBeneficiary(), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./RoleMembership.sol";
import "./Roles.sol";

/**
 * @title Access control using a predefined set of roles.
 *
 * @notice The roles and their relationship to each other are defined.
 *
 * @dev There are two categories of role:
 * - Global; permissions granted across all DAOs.
 * - Dao; permissions granted only in a single DAO.
 */
abstract contract RoleAccessControl is RoleMembership {
    uint8 private _superUserCounter;

    modifier onlySuperUserRole() {
        if (_isMissingGlobalRole(Roles.SUPER_USER, _msgSender())) {
            revert(
                _revertMessageMissingGlobalRole(Roles.SUPER_USER, _msgSender())
            );
        }
        _;
    }

    modifier atLeastDaoCreatorRole() {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingGlobalRole(Roles.DAO_CREATOR, _msgSender())
        ) {
            revert(
                _revertMessageMissingGlobalRole(Roles.DAO_CREATOR, _msgSender())
            );
        }
        _;
    }

    modifier atLeastSysAdminRole() {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingGlobalRole(Roles.SYSTEM_ADMIN, _msgSender())
        ) {
            revert(
                _revertMessageMissingGlobalRole(
                    Roles.SYSTEM_ADMIN,
                    _msgSender()
                )
            );
        }
        _;
    }

    modifier atLeastDaoAdminRole(uint256 daoId) {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingDaoRole(daoId, Roles.DAO_ADMIN, _msgSender())
        ) {
            revert(
                _revertMessageMissingDaoRole(
                    daoId,
                    Roles.DAO_ADMIN,
                    _msgSender()
                )
            );
        }
        _;
    }

    modifier atLeastDaoMeepleRole(uint256 daoId) {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingDaoRole(daoId, Roles.DAO_ADMIN, _msgSender()) &&
            _isMissingDaoRole(daoId, Roles.DAO_MEEPLE, _msgSender())
        ) {
            revert(
                _revertMessageMissingDaoRole(
                    daoId,
                    Roles.DAO_MEEPLE,
                    _msgSender()
                )
            );
        }
        _;
    }

    function grantSuperUserRole(address account) external onlySuperUserRole {
        _grantGlobalRole(Roles.SUPER_USER, account);
        _superUserCounter++;
    }

    function grantDaoCreatorRole(address account) external onlySuperUserRole {
        _grantGlobalRole(Roles.DAO_CREATOR, account);
    }

    function grantSysAdminRole(address account) external atLeastSysAdminRole {
        _grantGlobalRole(Roles.SYSTEM_ADMIN, account);
    }

    function grantDaoAdminRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _grantDaoRole(daoId, Roles.DAO_ADMIN, account);
    }

    function grantDaoMeepleRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _grantDaoRole(daoId, Roles.DAO_MEEPLE, account);
    }

    function revokeSuperUserRole(address account) external onlySuperUserRole {
        _revokeGlobalRole(Roles.SUPER_USER, account);
        require(_superUserCounter > 1, "RAC: no revoking last SuperUser");
        _superUserCounter--;
    }

    function revokeDaoCreatorRole(address account) external onlySuperUserRole {
        _revokeGlobalRole(Roles.DAO_CREATOR, account);
    }

    function revokeSysAdminRole(address account) external atLeastSysAdminRole {
        _revokeGlobalRole(Roles.SYSTEM_ADMIN, account);
    }

    function revokeDaoAdminRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _revokeDaoRole(daoId, Roles.DAO_ADMIN, account);
    }

    function revokeDaoMeepleRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _revokeDaoRole(daoId, Roles.DAO_MEEPLE, account);
    }

    function hasSuperUserAccess(address account) external view returns (bool) {
        return _hasGlobalRole(Roles.SUPER_USER, account);
    }

    function hasDaoAdminAccess(uint256 daoId, address account)
        external
        view
        returns (bool)
    {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasDaoRole(daoId, Roles.DAO_ADMIN, account);
    }

    function hasDaoCreatorAccess(address account) external view returns (bool) {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasGlobalRole(Roles.DAO_CREATOR, account);
    }

    function hasDaoMeepleAccess(uint256 daoId, address account)
        external
        view
        returns (bool)
    {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasDaoRole(daoId, Roles.DAO_ADMIN, account) ||
            _hasDaoRole(daoId, Roles.DAO_MEEPLE, account);
    }

    function hasSysAdminAccess(address account) external view returns (bool) {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasGlobalRole(Roles.SYSTEM_ADMIN, account);
    }

    /**
     * @notice The _msgSender() is given membership of the SuperUser role.
     *
     * @dev Allows granting and future renouncing after other addresses have been setup.
     */
    //slither-disable-next-line naming-convention
    function __RoleAccessControl_init() internal onlyInitializing {
        __RoleMembership_init();

        _grantGlobalRole(Roles.SUPER_USER, _msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./StakingPoolLib.sol";
import "../Version.sol";
import "../sweep/SweepERC20.sol";

/**
 * @title StakingPool with optional fixed or floating token rewards
 *
 * @notice Users can deposit a stake token into the pool up to the specified pool maximum contribution.
 * If the minimum criteria for the pool to go ahead are met, stake tokens are locked for an epochDuration.
 * After this period expires the user can withdraw their stake token and reward tokens (if available) separately.
 * The amount of rewards is determined by the pools rewardType - a floating reward ratio is updated on each deposit
 * while fixed tokens rewards are calculated once per user.
 */
contract StakingPool is
    PausableUpgradeable,
    ReentrancyGuard,
    OwnableUpgradeable,
    SweepERC20,
    Version
{
    using SafeERC20 for IERC20;

    // Magic Number fixed length rewardsAmounts to fit 3 words. Only used here.
    struct User {
        uint128 depositAmount;
        uint128[5] rewardAmounts;
    }

    struct RewardOwed {
        IERC20 tokens;
        uint128 amount;
    }

    mapping(address => User) private _users;
    mapping(address => bool) private _supportedRewards;

    uint32 private _rewardsAvailableTimestamp;
    bool private _emergencyMode;
    uint128 private _totalStakedAmount;

    StakingPoolLib.Config private _stakingPoolConfig;

    event WithdrawRewards(
        address indexed user,
        address rewardToken,
        uint256 rewards
    );
    event WithdrawStake(address indexed user, uint256 stake);
    event Deposit(address indexed user, uint256 depositAmount);
    event InitializeRewards(address rewardTokens, uint256 amount);
    event RewardsAvailableTimestamp(uint32 rewardsAvailableTimestamp);
    event EmergencyMode(address indexed admin);
    event NoRewards(address indexed user);

    modifier rewardsAvailable() {
        require(_isRewardsAvailable(), "StakingPool: rewards too early");
        _;
    }

    modifier stakingPeriodComplete() {
        require(_isStakingPeriodComplete(), "StakingPool: still stake period");
        _;
    }

    modifier stakingPoolRequirementsUnmet() {
        //slither-disable-next-line timestamp
        require(
            (_totalStakedAmount < _stakingPoolConfig.minTotalPoolStake) &&
                (block.timestamp > _stakingPoolConfig.epochStartTimestamp),
            "StakingPool: requirements unmet"
        );
        _;
    }

    modifier emergencyModeEnabled() {
        require(_emergencyMode, "StakingPool: not emergency mode");
        _;
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /**
     * @notice Only entry point for a user to deposit into the staking pool
     *
     * @param amount Amount of stake tokens to deposit
     */
    function deposit(uint128 amount) external whenNotPaused nonReentrant {
        StakingPoolLib.Config storage _config = _stakingPoolConfig;

        require(
            amount >= _config.minimumContribution,
            "StakingPool: min contribution"
        );
        require(
            _totalStakedAmount + amount <= _config.maxTotalPoolStake,
            "StakingPool: oversubscribed"
        );
        //slither-disable-next-line timestamp
        require(
            block.timestamp < _config.epochStartTimestamp,
            "StakingPool: too late"
        );

        User storage user = _users[_msgSender()];

        user.depositAmount += amount;
        _totalStakedAmount += amount;

        emit Deposit(_msgSender(), amount);

        // calculate/update rewards
        if (_config.rewardType == StakingPoolLib.RewardType.FLOATING) {
            _updateRewardsRatios(_config);
        }
        if (_config.rewardType == StakingPoolLib.RewardType.FIXED) {
            _calculateFixedRewards(_config, user, amount);
        }

        _config.stakeToken.safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
    }

    /**
     * @notice Withdraw both stake and reward tokens when the stake period is complete
     */
    function withdraw()
        external
        whenNotPaused
        stakingPeriodComplete
        rewardsAvailable
        nonReentrant
    {
        User memory user = _users[_msgSender()];
        require(user.depositAmount > 0, "StakingPool: not eligible");

        delete _users[_msgSender()];

        StakingPoolLib.Config storage _config = _stakingPoolConfig;

        //slither-disable-next-line reentrancy-events
        _transferStake(user.depositAmount, _config.stakeToken);

        _withdrawRewards(_config, user);
    }

    /**
     * @notice Withdraw only stake tokens after staking period is complete. Reward tokens may not be available yet.
     */
    function withdrawStake()
        external
        stakingPeriodComplete
        nonReentrant
        whenNotPaused
    {
        _withdrawStake();
    }

    /**
     * @notice Withdraw only reward tokens. Stake must have already been withdrawn.
     */
    function withdrawRewards()
        external
        stakingPeriodComplete
        rewardsAvailable
        whenNotPaused
    {
        StakingPoolLib.Config memory _config = _stakingPoolConfig;

        User memory user = _users[_msgSender()];
        require(user.depositAmount == 0, "StakingPool: withdraw stake");
        delete _users[_msgSender()];

        bool noRewards = true;

        for (uint256 i = 0; i < user.rewardAmounts.length; i++) {
            if (user.rewardAmounts[i] > 0) {
                noRewards = false;
                //slither-disable-next-line calls-loop
                _transferRewards(
                    user.rewardAmounts[i],
                    _config.rewardTokens[i].tokens
                );
            }
        }
        if (noRewards) {
            emit NoRewards(_msgSender());
        }
    }

    /**
     * @notice Withdraw stake tokens when minimum pool conditions to begin are not met
     */
    function earlyWithdraw()
        external
        stakingPoolRequirementsUnmet
        whenNotPaused
    {
        _withdrawWithoutRewards();
    }

    /**
     * @notice Withdraw stake tokens when admin has enabled emergency mode
     */
    function emergencyWithdraw() external emergencyModeEnabled {
        _withdrawStake();
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        whenNotPaused
        onlyOwner
    {
        _sweepERC20Tokens(tokens, amount);
    }

    function initialize(
        StakingPoolLib.Config calldata info,
        bool paused,
        uint32 rewardsTimestamp,
        address beneficiary
    ) external virtual initializer {
        __Context_init_unchained();
        __Pausable_init();
        __Ownable_init();
        __TokenSweep_init(beneficiary);

        //slither-disable-next-line timestamp
        require(
            info.epochStartTimestamp >= block.timestamp,
            "StakingPool: start >= now"
        );

        _enforceUniqueRewardTokens(info.rewardTokens);
        require(
            address(info.stakeToken) != address(0),
            "StakingPool: stake token defined"
        );
        //slither-disable-next-line timestamp
        require(
            rewardsTimestamp > info.epochStartTimestamp + info.epochDuration,
            "StakingPool: init rewards"
        );
        require(info.treasury != address(0), "StakePool: treasury address 0");
        require(info.maxTotalPoolStake > 0, "StakePool: maxTotalPoolStake > 0");
        require(info.epochDuration > 0, "StakePool: epochDuration > 0");
        require(info.minimumContribution > 0, "StakePool: minimumContribution");

        if (paused) {
            _pause();
        }

        _rewardsAvailableTimestamp = rewardsTimestamp;
        emit RewardsAvailableTimestamp(rewardsTimestamp);

        _stakingPoolConfig = info;
    }

    function initializeRewardTokens(
        address benefactor,
        StakingPoolLib.Reward[] calldata rewards
    ) external onlyOwner {
        _initializeRewardTokens(benefactor, rewards);
    }

    function enableEmergencyMode() external onlyOwner {
        _emergencyMode = true;
        emit EmergencyMode(_msgSender());
    }

    function adminEmergencyRewardSweep()
        external
        emergencyModeEnabled
        onlyOwner
    {
        _adminEmergencyRewardSweep();
    }

    function setRewardsAvailableTimestamp(uint32 timestamp) external onlyOwner {
        _setRewardsAvailableTimestamp(timestamp);
    }

    function updateTokenSweepBeneficiary(address newBeneficiary)
        external
        whenNotPaused
        onlyOwner
    {
        _setTokenSweepBeneficiary(newBeneficiary);
    }

    function currentExpectedRewards(address user)
        external
        view
        returns (uint256[] memory)
    {
        User memory _user = _users[user];
        StakingPoolLib.Config memory _config = _stakingPoolConfig;

        uint256[] memory rewards = new uint256[](_config.rewardTokens.length);

        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            rewards[i] = _calculateRewardAmount(_config, _user, i);
        }
        return rewards;
    }

    function stakingPoolData()
        external
        view
        returns (StakingPoolLib.Config memory)
    {
        return _stakingPoolConfig;
    }

    function rewardsAvailableTimestamp() external view returns (uint32) {
        return _rewardsAvailableTimestamp;
    }

    function getUser(address activeUser) external view returns (User memory) {
        return _users[activeUser];
    }

    function emergencyMode() external view returns (bool) {
        return _emergencyMode;
    }

    function totalStakedAmount() external view returns (uint128) {
        return _totalStakedAmount;
    }

    function isRedeemable() external view returns (bool) {
        //slither-disable-next-line timestamp
        return _isRewardsAvailable() && _isStakingPeriodComplete();
    }

    function isRewardsAvailable() external view returns (bool) {
        return _isRewardsAvailable();
    }

    function isStakingPeriodComplete() external view returns (bool) {
        return _isStakingPeriodComplete();
    }

    /**
     * @notice Returns the final amount of reward due for a user
     *
     * @param user address to calculate rewards for
     */
    function currentRewards(address user)
        external
        view
        returns (RewardOwed[] memory)
    {
        User memory _user = _users[user];
        StakingPoolLib.Config memory _config = _stakingPoolConfig;

        RewardOwed[] memory rewards = new RewardOwed[](
            _config.rewardTokens.length
        );

        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            if (_config.rewardType == StakingPoolLib.RewardType.FLOATING) {
                rewards[i] = RewardOwed({
                    amount: _calculateFloatingReward(
                        _config.rewardTokens[i].ratio,
                        _user.depositAmount
                    ),
                    tokens: _config.rewardTokens[i].tokens
                });
            }
            if (_config.rewardType == StakingPoolLib.RewardType.FIXED) {
                rewards[i] = RewardOwed({
                    amount: _user.rewardAmounts[i],
                    tokens: _config.rewardTokens[i].tokens
                });
            }
        }
        return rewards;
    }

    function _initializeRewardTokens(
        address benefactor,
        StakingPoolLib.Reward[] calldata _rewardTokens
    ) internal {
        _enforceUniqueRewardTokens(_rewardTokens);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            emit InitializeRewards(
                address(_rewardTokens[i].tokens),
                _rewardTokens[i].maxAmount
            );

            require(
                _rewardTokens[i].tokens.allowance(benefactor, address(this)) >=
                    _rewardTokens[i].maxAmount,
                "StakingPool: invalid allowance"
            );

            _rewardTokens[i].tokens.safeTransferFrom(
                benefactor,
                address(this),
                _rewardTokens[i].maxAmount
            );
        }
    }

    function _withdrawWithoutRewards() internal {
        User memory user = _users[_msgSender()];
        require(user.depositAmount > 0, "StakingPool: not eligible");

        delete _users[_msgSender()];
        StakingPoolLib.Config memory _config = _stakingPoolConfig;
        _transferStake(uint256((user.depositAmount)), _config.stakeToken);
    }

    function _setRewardsAvailableTimestamp(uint32 timestamp) internal {
        require(!_isStakingPeriodComplete(), "StakePool: already finalized");
        //slither-disable-next-line timestamp
        require(timestamp > block.timestamp, "StakePool: future rewards");

        _rewardsAvailableTimestamp = timestamp;
        emit RewardsAvailableTimestamp(timestamp);
    }

    function _transferStake(uint256 amount, IERC20 stakeToken) internal {
        emit WithdrawStake(_msgSender(), amount);
        _transferToken(amount, stakeToken);
    }

    function _transferRewards(uint256 amount, IERC20 rewardsToken) internal {
        emit WithdrawRewards(_msgSender(), address(rewardsToken), amount);
        _transferToken(amount, rewardsToken);
    }

    function _adminEmergencyRewardSweep() internal {
        StakingPoolLib.Reward[] memory rewards = _stakingPoolConfig
            .rewardTokens;
        address treasury = _stakingPoolConfig.treasury;

        for (uint256 i = 0; i < rewards.length; i++) {
            rewards[i].tokens.safeTransfer(
                treasury,
                rewards[i].tokens.balanceOf(address(this))
            );
        }
    }

    function _withdrawStake() internal {
        User storage user = _users[_msgSender()];
        require(user.depositAmount > 0, "StakingPool: not eligible");

        uint128 currentDepositBalance = user.depositAmount;
        user.depositAmount = 0;

        StakingPoolLib.Config storage _config = _stakingPoolConfig;
        // set users floating reward if applicable
        if (_config.rewardType == StakingPoolLib.RewardType.FLOATING) {
            for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
                user.rewardAmounts[i] = _calculateFloatingReward(
                    _config.rewardTokens[i].ratio,
                    currentDepositBalance
                );
            }
        }
        _transferStake(currentDepositBalance, _config.stakeToken);
    }

    function _isRewardsAvailable() internal view returns (bool) {
        //slither-disable-next-line timestamp
        return block.timestamp >= _rewardsAvailableTimestamp;
    }

    function _isStakingPeriodComplete() internal view returns (bool) {
        //slither-disable-next-line timestamp
        return
            block.timestamp >=
            (_stakingPoolConfig.epochStartTimestamp +
                _stakingPoolConfig.epochDuration);
    }

    function _calculateRewardAmount(
        StakingPoolLib.Config memory _config,
        User memory _user,
        uint256 rewardIndex
    ) internal pure returns (uint256) {
        if (_config.rewardType == StakingPoolLib.RewardType.FIXED) {
            return _user.rewardAmounts[rewardIndex];
        }

        if (_config.rewardType == StakingPoolLib.RewardType.FLOATING) {
            if (_user.depositAmount == 0) {
                // user has already withdrawn stake
                return _user.rewardAmounts[rewardIndex];
            }

            // user has not withdrawn stake yet
            return
                _calculateFloatingReward(
                    _config.rewardTokens[rewardIndex].ratio,
                    _user.depositAmount
                );
        }
        return 0;
    }

    function _calculateFloatingReward(
        uint256 rewardAmountRatio,
        uint128 depositAmount
    ) internal pure returns (uint128) {
        return uint128((rewardAmountRatio * depositAmount) / 1 ether);
    }

    function _computeFloatingRewardsPerShare(
        uint256 availableTokenRewards,
        uint256 total
    ) internal pure returns (uint256) {
        return (availableTokenRewards * 1 ether) / total;
    }

    function _transferToken(uint256 amount, IERC20 token) private {
        //slither-disable-next-line calls-loop
        token.safeTransfer(_msgSender(), amount);
    }

    /**
     * @notice Updates the global reward ratios for each reward token in a floating reward pool
     */
    function _updateRewardsRatios(StakingPoolLib.Config storage _config)
        private
    {
        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            _config.rewardTokens[i].ratio = _computeFloatingRewardsPerShare(
                _config.rewardTokens[i].maxAmount,
                _totalStakedAmount
            );
        }
    }

    /**
     * @notice Calculates and sets the users reward amount for a fixed reward pool
     */
    function _calculateFixedRewards(
        StakingPoolLib.Config memory _config,
        User storage user,
        uint256 amount
    ) private {
        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            user.rewardAmounts[i] += uint128(
                (amount * _config.rewardTokens[i].ratio)
            );
        }
    }

    function _withdrawRewards(
        StakingPoolLib.Config memory _config,
        User memory user
    ) private {
        bool noRewards = true;

        // calculate the rewardAmounts due to the user
        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            uint256 amount = _calculateRewardAmount(_config, user, i);

            if (amount > 0) {
                noRewards = false;
                //slither-disable-next-line calls-loop
                _transferRewards(amount, _config.rewardTokens[i].tokens);
            }
        }
        if (noRewards) {
            emit NoRewards(_msgSender());
        }
    }

    /**
     * @notice Enforces that each of the reward tokens are unique
     */
    function _enforceUniqueRewardTokens(
        StakingPoolLib.Reward[] calldata rewardPools
    ) private {
        for (uint256 i = 0; i < rewardPools.length; i++) {
            // Ensure no prev entries contain the same tokens address
            require(
                !_supportedRewards[address(rewardPools[i].tokens)],
                "StakePool: tokens must be unique"
            );
            _supportedRewards[address(rewardPools[i].tokens)] = true;
        }
        for (uint256 i = 0; i < rewardPools.length; i++) {
            delete _supportedRewards[address(rewardPools[i].tokens)];
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library StakingPoolLib {
    enum RewardType {
        NONE,
        FIXED,
        FLOATING
    }

    struct Reward {
        IERC20 tokens;
        uint256 maxAmount;
        uint256 ratio; // only initialized for fixed
    }

    struct Config {
        uint256 daoId;
        uint128 minTotalPoolStake;
        uint128 maxTotalPoolStake;
        uint128 minimumContribution;
        uint32 epochDuration;
        uint32 epochStartTimestamp;
        address treasury;
        IERC20 stakeToken;
        Reward[] rewardTokens;
        RewardType rewardType;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @title Role based set membership.
 *
 * @notice Encapsulation of tracking, management and validation of role membership of addresses.
 *
 *  A role is a bytes32 value.
 *
 *  There are two distinct classes of roles:
 *  - Global; without scope limit.
 *  - Dao; membership scoped to that of the key (uint256).
 *
 * @dev Meaningful application of role membership is expected to come from derived contracts.
 *      e.g. access control.
 */
abstract contract RoleMembership is ContextUpgradeable {
    // DAOs to their roles to members; scoped to an individual DAO
    mapping(uint256 => mapping(bytes32 => mapping(address => bool)))
        private _daoRoleMembers;

    // Global roles to members; apply across all DAOs
    mapping(bytes32 => mapping(address => bool)) private _globalRoleMembers;

    event GrantDaoRole(
        uint256 indexed daoId,
        bytes32 indexed role,
        address account,
        address indexed instigator
    );
    event GrantGlobalRole(
        bytes32 indexedrole,
        address account,
        address indexed instigator
    );
    event RevokeDaoRole(
        uint256 indexed daoId,
        bytes32 indexed role,
        address account,
        address indexed instigator
    );
    event RevokeGlobalRole(
        bytes32 indexed role,
        address account,
        address indexed instigator
    );

    function hasGlobalRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return _globalRoleMembers[role][account];
    }

    function hasDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _daoRoleMembers[daoId][role][account];
    }

    function _grantDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal {
        if (_hasDaoRole(daoId, role, account)) {
            revert(_revertMessageAlreadyHasDaoRole(daoId, role, account));
        }

        _daoRoleMembers[daoId][role][account] = true;
        emit GrantDaoRole(daoId, role, account, _msgSender());
    }

    function _grantGlobalRole(bytes32 role, address account) internal {
        if (_hasGlobalRole(role, account)) {
            revert(_revertMessageAlreadyHasGlobalRole(role, account));
        }

        _globalRoleMembers[role][account] = true;
        emit GrantGlobalRole(role, account, _msgSender());
    }

    function _revokeDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal {
        if (_isMissingDaoRole(daoId, role, account)) {
            revert(_revertMessageMissingDaoRole(daoId, role, account));
        }

        delete _daoRoleMembers[daoId][role][account];
        emit RevokeDaoRole(daoId, role, account, _msgSender());
    }

    function _revokeGlobalRole(bytes32 role, address account) internal {
        if (_isMissingGlobalRole(role, account)) {
            revert(_revertMessageMissingGlobalRole(role, account));
        }

        delete _globalRoleMembers[role][account];
        emit RevokeGlobalRole(role, account, _msgSender());
    }

    //slither-disable-next-line naming-convention
    function __RoleMembership_init() internal onlyInitializing {}

    function _hasDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return _daoRoleMembers[daoId][role][account];
    }

    function _hasGlobalRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return _globalRoleMembers[role][account];
    }

    function _isMissingDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return !_daoRoleMembers[daoId][role][account];
    }

    function _isMissingGlobalRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return !_globalRoleMembers[role][account];
    }

    /**
     * @dev Override for a custom revert message.
     */
    function _revertMessageAlreadyHasGlobalRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " already has role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            );
    }

    /**
     * @dev Override the function for a custom revert message.
     */
    function _revertMessageAlreadyHasDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " already has role ",
                    StringsUpgradeable.toHexString(uint256(role), 32),
                    " in DAO ",
                    StringsUpgradeable.toHexString(daoId, 32)
                )
            );
    }

    /**
     * @dev Override the function for a custom revert message.
     */
    function _revertMessageMissingGlobalRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            );
    }

    /**
     * @dev Override the function for a custom revert message.
     */
    function _revertMessageMissingDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32),
                    " in DAO ",
                    StringsUpgradeable.toHexString(daoId, 32)
                )
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title Roles within the hierarchical DAO access control schema.
 *
 * @notice Similar to a Linux permission system there is a super user, with some of the other roles being tiered
 *          amongst each other.
 *
 *  SUPER_USER role the manage for DAO_CREATOR roles, in addition to being a super set to to all other roles functions.
 *  DAO_CREATOR role only business is creating DAOs and their configurations.
 *  DAO_ADMIN role can update the DAOs configuration and may intervene to sweep / flush.
 *  DAO_MEEPLE role is deals with the life cycle of the DAOs products.
 *  SYSTEM_ADMIN role deals with tasks such as pause-ability and the upgrading of contract.
 */
library Roles {
    bytes32 public constant DAO_ADMIN = "DAO_ADMIN";
    bytes32 public constant DAO_CREATOR = "DAO_CREATOR";
    bytes32 public constant DAO_MEEPLE = "DAO_MEEPLE";
    bytes32 public constant SUPER_USER = "SUPER_USER";
    bytes32 public constant SYSTEM_ADMIN = "SYSTEM_ADMIN";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
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
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title Abstract upgradeable contract providing the ability to sweep tokens to a nominated beneficiary address.
 *
 * @dev Access control implementation is required for many functions by design.
 */
abstract contract TokenSweep is ContextUpgradeable {
    address private _beneficiary;

    event BeneficiaryUpdate(
        address indexed beneficiary,
        address indexed instigator
    );

    function tokenSweepBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    //slither-disable-next-line naming-convention
    function __TokenSweep_init(address beneficiary) internal onlyInitializing {
        __Context_init();
        _setTokenSweepBeneficiary(beneficiary);
    }

    /**
     * @notice Sets the beneficiary of the token sweep.
     *
     * @dev Needs access control implemented in the inheriting contract.
     *
     * @param newBeneficiary The address to replace as the nominated beneficiary of any sweeping.
     */
    function _setTokenSweepBeneficiary(address newBeneficiary) internal {
        require(newBeneficiary != address(0), "TokenSweep: beneficiary zero");
        require(newBeneficiary != address(this), "TokenSweep: self address");
        require(newBeneficiary != _beneficiary, "TokenSweep: beneficiary same");

        _beneficiary = newBeneficiary;
        emit BeneficiaryUpdate(newBeneficiary, _msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
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
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract DaoCollateralWhitelist is ContextUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct CollateralWhitelist {
        // Token symbols to ERC20 Token contract addresses
        EnumerableSetUpgradeable.AddressSet tokens;
        // Token symbols to ERC20 Token contract addresses
        mapping(address => string) symbols;
    }

    event AddCollateralWhitelist(
        uint256 indexed daoId,
        address indexed collateralTokens,
        address indexed instigator
    );
    event RemoveCollateralWhitelist(
        uint256 indexed daoId,
        address indexed collateralTokens,
        address indexed instigator
    );

    /**
     * @notice Returns a list of the whitelisted tokens' symbols.
     *
     * @dev NOTE This is a convenience getter function, due to looking an unknown gas cost,
     *             never call within a transaction, only use a call from an EOA.
     *
     * @param daoId Internal ID of the DAO whose collateral symbol list is wanted.
     */
    function daoCollateralSymbolWhitelist(uint256 daoId)
        external
        view
        returns (string[] memory)
    {
        address[] memory keys = _daoCollateralWhitelist(daoId).tokens.values();
        string[] memory symbols = new string[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            symbols[i] = _daoCollateralWhitelist(daoId).symbols[keys[i]];
        }
        return symbols;
    }

    /**
     * @notice The whitelisted ERC20 token address associated for a symbol.
     *
     * @param daoId Internal ID of the DAO whose collateral whitelist list will be checked.
     * @return When present in the whitelist, the token address, otherwise address zero.
     */
    function isAllowedDaoCollateral(
        uint256 daoId,
        address erc20CollateralTokens
    ) public view returns (bool) {
        return _isDaoCollateralWhitelisted(daoId, erc20CollateralTokens);
    }

    //slither-disable-next-line naming-convention
    function __DaoCollateralWhitelist_init() internal onlyInitializing {}

    /**
     * @notice Performs whitelisting of the ERC20 collateral token.
     *
     * @dev Whitelists the collateral token, expecting the symbol is not already whitelisted.
     *
     * @param daoId Internal ID of the DAO whose collateral whitelist will be updated.
     * @param  erc20CollateralTokens IERC20MetadataUpgradeable contract to whitelist.
     */
    function _whitelistDaoCollateral(
        uint256 daoId,
        address erc20CollateralTokens
    ) internal {
        require(_isValidDaoId(daoId), "DAO Collateral: invalid DAO id");
        require(
            erc20CollateralTokens != address(0),
            "DAO Collateral: zero address"
        );
        require(
            !_isDaoCollateralWhitelisted(daoId, erc20CollateralTokens),
            "DAO Collateral: already present"
        );
        require(
            _daoCollateralWhitelist(daoId).tokens.add(erc20CollateralTokens),
            "DAO Collateral: failed to add"
        );
        _daoCollateralWhitelist(daoId).symbols[
            erc20CollateralTokens
        ] = IERC20MetadataUpgradeable(erc20CollateralTokens).symbol();

        emit AddCollateralWhitelist(daoId, erc20CollateralTokens, _msgSender());
    }

    /**
     * @notice Deletes a collateral token entry from the whitelist.
     *
     * @dev Expects the symbol to be an existing entry, otherwise reverts.
     *
     * @param daoId Internal ID of the DAO whose collateral whitelist will be updated.
     * @param  erc20CollateralTokens ERC20 contract to remove from the whitelist.
     */
    function _removeWhitelistedDaoCollateral(
        uint256 daoId,
        address erc20CollateralTokens
    ) internal {
        require(_isValidDaoId(daoId), "DAO Collateral: invalid DAO id");
        require(
            _isDaoCollateralWhitelisted(daoId, erc20CollateralTokens),
            "DAO Collateral: not whitelisted"
        );
        require(
            _daoCollateralWhitelist(daoId).tokens.remove(erc20CollateralTokens),
            "DAO Collateral: failed to remove"
        );

        delete _daoCollateralWhitelist(daoId).symbols[erc20CollateralTokens];

        emit RemoveCollateralWhitelist(
            daoId,
            erc20CollateralTokens,
            _msgSender()
        );
    }

    /**
     * @notice Provides access to the internal storage for the whitelist of collateral tokens for a single DAO.
     *
     * @dev Although a view modifier, the underlying storage may be altered, as in this case the view restriction
     *         applies to the reference rather than the addresses.
     *
     * @param daoId Internal ID of the DAO whose collateral whitelist will be retrieved.
     */
    //slither-disable-next-line dead-code
    function _daoCollateralWhitelist(uint256 daoId)
        internal
        view
        virtual
        returns (CollateralWhitelist storage);

    /**
     * @notice Whether a given DAO ID is currently associated with a currently live DAO.
     *
     * @dev At any moment, expect a range of IDs that have been assigned, with the possibility some DAOs within being
     *          deleted.
     *
     * @param daoId Internal ID of the DAO whose existence is to be determined.
     */
    //slither-disable-next-line dead-code
    function _isValidDaoId(uint256 daoId) internal view virtual returns (bool);

    /**
     * @notice Whether a contract address is a member of the set of whitelisted tokens for a DAO.
     *
     * @param daoId Internal ID of the DAO whose whitelist will be checked.
     * @param  erc20CollateralTokens address to determine whitelist membership.
     */
    function _isDaoCollateralWhitelisted(
        uint256 daoId,
        address erc20CollateralTokens
    ) private view returns (bool) {
        return
            _daoCollateralWhitelist(daoId).tokens.contains(
                erc20CollateralTokens
            );
    }
}