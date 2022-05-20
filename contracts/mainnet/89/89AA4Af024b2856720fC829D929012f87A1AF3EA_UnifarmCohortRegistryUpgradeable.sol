// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {UnifarmCohortRegistryUpgradeableStorage} from './storage/UnifarmCohortRegistryUpgradeableStorage.sol';
import {OwnableUpgradeable} from './access/OwnableUpgradeable.sol';
import {Initializable} from './proxy/Initializable.sol';
import {IUnifarmCohortRegistryUpgradeable} from './interfaces/IUnifarmCohortRegistryUpgradeable.sol';

/// @title UnifarmCohortRegistryUpgradeable Contract
/// @author UNIFARM
/// @notice maintain collection of cohorts of unifarm
/// @dev All State mutation function are restricted to only owner access and multicall

contract UnifarmCohortRegistryUpgradeable is
    IUnifarmCohortRegistryUpgradeable,
    Initializable,
    OwnableUpgradeable,
    UnifarmCohortRegistryUpgradeableStorage
{
    /// @notice modifier for vailidate sender
    modifier onlyMulticallOrOwner() {
        onlyOwnerOrMulticall();
        _;
    }

    /**
     * @notice initialize Unifarm Registry contract
     * @param master master role address
     * @param trustedForwarder trusted forwarder address
     * @param  multiCall_ multicall contract address
     */

    function __UnifarmCohortRegistryUpgradeable_init(
        address master,
        address trustedForwarder,
        address multiCall_
    ) external initializer {
        __UnifarmCohortRegistryUpgradeable_init_unchained(multiCall_);
        __Ownable_init(master, trustedForwarder);
    }

    /**
     * @dev internal function to set registry state
     * @param  multiCall_ multicall contract address
     */

    function __UnifarmCohortRegistryUpgradeable_init_unchained(address multiCall_) internal {
        multiCall = multiCall_;
    }

    /**
     * @dev modifier to prevent malicious user
     */

    function onlyOwnerOrMulticall() internal view {
        require(_msgSender() == multiCall || _msgSender() == owner(), 'ONA');
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setTokenMetaData(
        address cohortId,
        uint32 fid_,
        address farmToken_,
        uint256 userMinStake_,
        uint256 userMaxStake_,
        uint256 totalStakeLimit_,
        uint8 decimals_,
        bool skip_
    ) external override onlyMulticallOrOwner {
        require(fid_ > 0, 'WFID');
        require(farmToken_ != address(0), 'IFT');
        require(userMaxStake_ > 0 && totalStakeLimit_ > 0, 'IC');
        require(totalStakeLimit_ > userMaxStake_, 'IC');

        tokenDetails[cohortId][fid_] = TokenMetaData({
            fid: fid_,
            farmToken: farmToken_,
            userMinStake: userMinStake_,
            userMaxStake: userMaxStake_,
            totalStakeLimit: totalStakeLimit_,
            decimals: decimals_,
            skip: skip_
        });

        emit TokenMetaDataDetails(cohortId, farmToken_, fid_, userMinStake_, userMaxStake_, totalStakeLimit_, decimals_, skip_);
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setCohortDetails(
        address cohortId,
        string memory cohortVersion_,
        uint256 startBlock_,
        uint256 endBlock_,
        uint256 epochBlocks_,
        bool hasLiquidityMining_,
        bool hasContainsWrappedToken_,
        bool hasCohortLockinAvaliable_
    ) external override onlyMulticallOrOwner {
        require(cohortId != address(0), 'ICI');
        require(endBlock_ > startBlock_, 'IBR');

        cohortDetails[cohortId] = CohortDetails({
            cohortVersion: cohortVersion_,
            startBlock: startBlock_,
            endBlock: endBlock_,
            epochBlocks: epochBlocks_,
            hasLiquidityMining: hasLiquidityMining_,
            hasContainsWrappedToken: hasContainsWrappedToken_,
            hasCohortLockinAvaliable: hasCohortLockinAvaliable_
        });

        emit AddedCohortDetails(
            cohortId,
            cohortVersion_,
            startBlock_,
            endBlock_,
            epochBlocks_,
            hasLiquidityMining_,
            hasContainsWrappedToken_,
            hasCohortLockinAvaliable_
        );
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function addBoosterPackage(
        address cohortId_,
        address paymentToken_,
        address boosterVault_,
        uint256 bpid_,
        uint256 boosterPackAmount_
    ) external override onlyMulticallOrOwner {
        require(bpid_ > 0, 'WBPID');
        boosterInfo[cohortId_][bpid_] = BoosterInfo({
            cohortId: cohortId_,
            paymentToken: paymentToken_,
            boosterVault: boosterVault_,
            boosterPackAmount: boosterPackAmount_
        });
        emit BoosterDetails(cohortId_, bpid_, paymentToken_, boosterPackAmount_);
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function updateMulticall(address newMultiCallAddress) external override onlyOwner {
        require(newMultiCallAddress != multiCall, 'SMA');
        multiCall = newMultiCallAddress;
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setWholeCohortLock(address cohortId, bool status) external override onlyMulticallOrOwner {
        require(cohortId != address(0), 'ICI');
        wholeCohortLock[cohortId] = status;
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setCohortLockStatus(
        address cohortId,
        bytes4 actionToLock,
        bool status
    ) external override onlyMulticallOrOwner {
        require(cohortId != address(0), 'ICI');
        lockCohort[cohortId][actionToLock] = status;
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function setCohortTokenLockStatus(
        bytes32 cohortSalt,
        bytes4 actionToLock,
        bool status
    ) external override onlyMulticallOrOwner {
        tokenLockedStatus[cohortSalt][actionToLock] = status;
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function validateStakeLock(address cohortId, uint32 farmId) public view override {
        bytes32 salt = keccak256(abi.encodePacked(cohortId, farmId));
        require(!wholeCohortLock[cohortId] && !lockCohort[cohortId][STAKE_MAGIC_VALUE] && !tokenLockedStatus[salt][STAKE_MAGIC_VALUE], 'LC');
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function validateUnStakeLock(address cohortId, uint32 farmId) public view override {
        bytes32 salt = keccak256(abi.encodePacked(cohortId, farmId));
        require(!wholeCohortLock[cohortId] && !lockCohort[cohortId][UNSTAKE_MAGIC_VALUE] && !tokenLockedStatus[salt][UNSTAKE_MAGIC_VALUE], 'LC');
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function getCohortToken(address cohortId, uint32 farmId)
        public
        view
        override
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        )
    {
        TokenMetaData memory token = tokenDetails[cohortId][farmId];
        return (token.fid, token.farmToken, token.userMinStake, token.userMaxStake, token.totalStakeLimit, token.decimals, token.skip);
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function getCohort(address cohortId)
        public
        view
        override
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        )
    {
        CohortDetails memory cohort = cohortDetails[cohortId];
        return (
            cohort.cohortVersion,
            cohort.startBlock,
            cohort.endBlock,
            cohort.epochBlocks,
            cohort.hasLiquidityMining,
            cohort.hasContainsWrappedToken,
            cohort.hasCohortLockinAvaliable
        );
    }

    /**
     * @inheritdoc IUnifarmCohortRegistryUpgradeable
     */

    function getBoosterPackDetails(address cohortId, uint256 bpid)
        public
        view
        override
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        )
    {
        BoosterInfo memory booster = boosterInfo[cohortId][bpid];
        return (booster.cohortId, booster.paymentToken, booster.boosterVault, booster.boosterPackAmount);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU GPLv3

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity =0.8.9;

import {ERC2771ContextUpgradeable} from '../metatx/ERC2771ContextUpgradeable.sol';
import {Initializable} from '../proxy/Initializable.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner
 */

abstract contract OwnableUpgradeable is Initializable, ERC2771ContextUpgradeable {
    address private _owner;
    address private _master;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     */
    function __Ownable_init(address master, address trustedForwarder) internal initializer {
        __Ownable_init_unchained(master);
        __ERC2771ContextUpgradeable_init(trustedForwarder);
    }

    function __Ownable_init_unchained(address masterAddress) internal initializer {
        _transferOwnership(_msgSender());
        _master = masterAddress;
    }

    /**
     * @dev Returns the address of the current owner
     * @return _owner - _owner address
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'ONA');
        _;
    }

    /**
     * @dev Throws if called by any account other than the master
     */
    modifier onlyMaster() {
        require(_master == _msgSender(), 'OMA');
        _;
    }

    /**
     * @dev Transfering the owner ship to master role in case of emergency
     *
     * NOTE: Renouncing ownership will transfer the contract ownership to master role
     */

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(_master);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Can only be called by the current owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'INA');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Internal function without access restriction
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

/// @title IUnifarmCohortRegistryUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm Cohort Registry.

interface IUnifarmCohortRegistryUpgradeable {
    /**
     * @notice set tokenMetaData for a particular cohort farm
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param fid_ farm id
     * @param farmToken_ farm token address
     * @param userMinStake_ user minimum stake
     * @param userMaxStake_ user maximum stake
     * @param totalStakeLimit_ total stake limit
     * @param decimals_ token decimals
     * @param skip_ it can be skip or not during unstake
     */

    function setTokenMetaData(
        address cohortId,
        uint32 fid_,
        address farmToken_,
        uint256 userMinStake_,
        uint256 userMaxStake_,
        uint256 totalStakeLimit_,
        uint8 decimals_,
        bool skip_
    ) external;

    /**
     * @notice a function to set particular cohort details
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param cohortVersion_ cohort version
     * @param startBlock_ start block of a cohort
     * @param endBlock_ end block of a cohort
     * @param epochBlocks_ epochBlocks of a cohort
     * @param hasLiquidityMining_ true if lp tokens can be stake here
     * @param hasContainsWrappedToken_ true if wTokens exist in rewards
     * @param hasCohortLockinAvaliable_ cohort lockin flag
     */

    function setCohortDetails(
        address cohortId,
        string memory cohortVersion_,
        uint256 startBlock_,
        uint256 endBlock_,
        uint256 epochBlocks_,
        bool hasLiquidityMining_,
        bool hasContainsWrappedToken_,
        bool hasCohortLockinAvaliable_
    ) external;

    /**
     * @notice to add a booster pack in a particular cohort
     * @dev only called by owner access or multicall
     * @param cohortId_ cohort address
     * @param paymentToken_ payment token address
     * @param boosterVault_ booster vault address
     * @param bpid_ booster pack Id
     * @param boosterPackAmount_ booster pack amount
     */

    function addBoosterPackage(
        address cohortId_,
        address paymentToken_,
        address boosterVault_,
        uint256 bpid_,
        uint256 boosterPackAmount_
    ) external;

    /**
     * @notice update multicall contract address
     * @dev only called by owner access
     * @param newMultiCallAddress new multicall address
     */

    function updateMulticall(address newMultiCallAddress) external;

    /**
     * @notice lock particular cohort contract
     * @dev only called by owner access or multicall
     * @param cohortId cohort contract address
     * @param status true for lock vice-versa false for unlock
     */

    function setWholeCohortLock(address cohortId, bool status) external;

    /**
     * @notice lock particular cohort contract action. (`STAKE` | `UNSTAKE`)
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortLockStatus(
        address cohortId,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice lock the particular farm action (`STAKE` | `UNSTAKE`) in a cohort
     * @param cohortSalt mixture of cohortId and tokenId
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortTokenLockStatus(
        bytes32 cohortSalt,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice validate cohort stake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice validate cohort unstake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateUnStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice get farm token details in a specific cohort
     * @param cohortId particular cohort address
     * @param farmId farmId of particular cohort
     * @return fid farm Id
     * @return farmToken farm Token Address
     * @return userMinStake amount that user can minimum stake
     * @return userMaxStake amount that user can maximum stake
     * @return totalStakeLimit total stake limit for the specific farm
     * @return decimals farm token decimals
     * @return skip it can be skip or not during unstake
     */

    function getCohortToken(address cohortId, uint32 farmId)
        external
        view
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        );

    /**
     * @notice get specific cohort details
     * @param cohortId cohort address
     * @return cohortVersion specific cohort version
     * @return startBlock start block of a unifarm cohort
     * @return endBlock end block of a unifarm cohort
     * @return epochBlocks epoch blocks in particular cohort
     * @return hasLiquidityMining indicator for liquidity mining
     * @return hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @return hasCohortLockinAvaliable denotes cohort lockin
     */

    function getCohort(address cohortId)
        external
        view
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        );

    /**
     * @notice get booster pack details for a specific cohort
     * @param cohortId cohort address
     * @param bpid booster pack Id
     * @return cohortId_ cohort address
     * @return paymentToken_ payment token address
     * @return boosterVault booster vault address
     * @return boosterPackAmount booster pack amount
     */

    function getBoosterPackDetails(address cohortId, uint256 bpid)
        external
        view
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        );

    /**
     * @notice emit on each farm token update
     * @param cohortId cohort address
     * @param farmToken farm token address
     * @param fid farm Id
     * @param userMinStake amount that user can minimum stake
     * @param userMaxStake amount that user can maximum stake
     * @param totalStakeLimit total stake limit for the specific farm
     * @param decimals farm token decimals
     * @param skip it can be skip or not during unstake
     */

    event TokenMetaDataDetails(
        address indexed cohortId,
        address indexed farmToken,
        uint32 indexed fid,
        uint256 userMinStake,
        uint256 userMaxStake,
        uint256 totalStakeLimit,
        uint8 decimals,
        bool skip
    );

    /**
     * @notice emit on each update of cohort details
     * @param cohortId cohort address
     * @param cohortVersion specific cohort version
     * @param startBlock start block of a unifarm cohort
     * @param endBlock end block of a unifarm cohort
     * @param epochBlocks epoch blocks in particular unifarm cohort
     * @param hasLiquidityMining indicator for liquidity mining
     * @param hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @param hasCohortLockinAvaliable denotes cohort lockin
     */

    event AddedCohortDetails(
        address indexed cohortId,
        string indexed cohortVersion,
        uint256 startBlock,
        uint256 endBlock,
        uint256 epochBlocks,
        bool indexed hasLiquidityMining,
        bool hasContainsWrappedToken,
        bool hasCohortLockinAvaliable
    );

    /**
     * @notice emit on update of each booster pacakge
     * @param cohortId the cohort address
     * @param bpid booster pack id
     * @param paymentToken the payment token address
     * @param boosterPackAmount the booster pack amount
     */

    event BoosterDetails(address indexed cohortId, uint256 indexed bpid, address paymentToken, uint256 boosterPackAmount);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {Initializable} from '../proxy/Initializable.sol';

/**
 * @dev Context variant with ERC2771 support
 */

// solhint-disable
abstract contract ERC2771ContextUpgradeable is Initializable {
    /**
     * @dev holds the trust forwarder
     */

    address public trustedForwarder;

    /**
     * @dev context upgradeable initializer
     * @param tForwarder trust forwarder
     */

    function __ERC2771ContextUpgradeable_init(address tForwarder) internal initializer {
        __ERC2771ContextUpgradeable_init_unchained(tForwarder);
    }

    /**
     * @dev called by initializer to set trust forwarder
     * @param tForwarder trust forwarder
     */

    function __ERC2771ContextUpgradeable_init_unchained(address tForwarder) internal {
        trustedForwarder = tForwarder;
    }

    /**
     * @dev check if the given address is trust forwarder
     * @param forwarder forwarder address
     * @return isForwarder true/false
     */

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * @dev if caller is trusted forwarder will return exact sender.
     * @return sender wallet address
     */

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * @dev returns msg data for called function
     * @return function call data
     */

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity =0.8.9;

import '../utils/AddressUpgradeable.sol';

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered
        require(_initializing ? _isConstructor() : !_initialized, 'CIAI');

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly
     */
    modifier onlyInitializing() {
        require(_initializing, 'CINI');
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

abstract contract UnifarmCohortRegistryUpgradeableStorage {
    /// @notice TokenMetaData struct hold the token information.
    struct TokenMetaData {
        // farm id
        uint32 fid;
        // farm token address.
        address farmToken;
        // user min stake for validation.
        uint256 userMinStake;
        // user max stake for validation.
        uint256 userMaxStake;
        // total stake limit for validation.
        uint256 totalStakeLimit;
        // token decimals
        uint8 decimals;
        // can be skip during unstaking
        bool skip;
    }

    /// @notice CohortDetails struct hold the cohort details
    struct CohortDetails {
        // cohort version of a cohort.
        string cohortVersion;
        // start block of a cohort.
        uint256 startBlock;
        // end block of a cohort.
        uint256 endBlock;
        // epoch blocks of a cohort.
        uint256 epochBlocks;
        // indicator for liquidity mining to seprate UI things.
        bool hasLiquidityMining;
        // true if contains any wrapped token in reward.
        bool hasContainsWrappedToken;
        // true if cohort locking feature available.
        bool hasCohortLockinAvaliable;
    }

    /// @notice struct to hold booster configuration for each cohort
    struct BoosterInfo {
        // cohort contract address
        address cohortId;
        // what will be payment token.
        address paymentToken;
        // booster vault address
        address boosterVault;
        // payable amount in terms of PARENT Chain token or ERC20 Token.
        uint256 boosterPackAmount;
    }

    /// @notice mapping contains each cohort details.
    mapping(address => CohortDetails) public cohortDetails;

    /// @notice contains token details by farmId
    mapping(address => mapping(uint32 => TokenMetaData)) public tokenDetails;

    /// @notice contains booster information for specific cohort.
    mapping(address => mapping(uint256 => BoosterInfo)) public boosterInfo;

    /// @notice holds lock status for whole cohort
    mapping(address => bool) public wholeCohortLock;

    /// @notice hold lock status for specific action in specific cohort.
    mapping(address => mapping(bytes4 => bool)) public lockCohort;

    /// @notice hold lock status for specific farm action in a cohort.
    mapping(bytes32 => mapping(bytes4 => bool)) public tokenLockedStatus;

    /// @notice magic value of stake action
    bytes4 public constant STAKE_MAGIC_VALUE = bytes4(keccak256('STAKE'));

    /// @notice magic value of unstake action
    bytes4 public constant UNSTAKE_MAGIC_VALUE = bytes4(keccak256('UNSTAKE'));

    /// @notice multicall address
    address public multiCall;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity =0.8.9;

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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        require(isContract(target), 'Address: call to non-contract');

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
        return functionStaticCall(target, data, 'Address: low-level static call failed');
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
        require(isContract(target), 'Address: static call to non-contract');

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