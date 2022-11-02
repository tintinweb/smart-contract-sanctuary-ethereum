// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {DAORegistry} from "../registry/DAORegistry.sol";
import {DAO} from "../core/DAO.sol";
import {PermissionLib} from "../core/permission/PermissionLib.sol";
import {createERC1967Proxy} from "../utils/Proxy.sol";
import {PluginRepo} from "../plugin/PluginRepo.sol";
import {PluginSetupProcessor} from "../plugin/PluginSetupProcessor.sol";

/// @title DAOFactory
/// @author Aragon Association - 2022
/// @notice This contract is used to create a DAO.
contract DAOFactory {
    /// @notice The DAO base contract, to be used for creating new `DAO`s via `createERC1967Proxy` function.
    address public immutable daoBase;

    /// @notice The DAO registry listing the `DAO` contracts created via this contract.
    DAORegistry public immutable daoRegistry;

    /// @notice The plugin setup processor for installing plugins on the newly created `DAO`s.
    PluginSetupProcessor public immutable pluginSetupProcessor;

    struct DAOSettings {
        address trustedForwarder; // The address of the trusted forwarder required for meta transactions.
        string name; // The name of the DAO.
        bytes metadata; // Meta data of the DAO.
    }

    struct PluginSettings {
        address pluginSetup; // The `PluginSetup` address of the plugin.
        PluginRepo pluginSetupRepo; // The `PluginRepo` of the plugin.
        bytes data; // The `bytes` encoded data containing the input parameters for the installation as specified in the `prepareInstallationDataABI()` function.
    }

    /// @notice Thrown if `PluginSettings` array is empty, and no plugin is provided.
    error NoPluginProvided();

    /// @notice The constructor setting the registry and plugin setup processor and creating the base contracts for the factory.
    /// @param _registry The DAO registry to register the DAO by its name.
    /// @param _pluginSetupProcessor The addres of PluginSetupProcessor.
    constructor(DAORegistry _registry, PluginSetupProcessor _pluginSetupProcessor) {
        daoRegistry = _registry;
        pluginSetupProcessor = _pluginSetupProcessor;

        daoBase = address(new DAO());
    }

    /// @notice Creates a new DAO and setup a number of plugins.
    /// @param _daoSettings The DAO settings containing `trustedForwarder`, `name` and `metadata`.
    /// @param _pluginSettings The list of plugin settings that will be installed after the DAO creation, containing `pluginSetup`, `pluginSetupRepo`, and `data`.
    function createDao(DAOSettings calldata _daoSettings, PluginSettings[] calldata _pluginSettings)
        external
        returns (DAO createdDao)
    {
        // Check if no plugin is provided.
        if (_pluginSettings.length == 0) {
            revert NoPluginProvided();
        }

        // Create DAO.
        createdDao = _createDAO(_daoSettings);

        // Register DAO.
        daoRegistry.register(createdDao, msg.sender, _daoSettings.name);

        // Grant the temporary permissions.
        // Grant Temporarly `ROOT_PERMISSION` to `pluginSetupProcessor`.
        createdDao.grant(
            address(createdDao),
            address(pluginSetupProcessor),
            createdDao.ROOT_PERMISSION_ID()
        );

        // Grant Temporarly `APPLY_INSTALLATION_PERMISSION` on `pluginSetupProcessor` to this `DAOFactory`.
        createdDao.grant(
            address(pluginSetupProcessor),
            address(this),
            pluginSetupProcessor.APPLY_INSTALLATION_PERMISSION_ID()
        );

        // Install plugins on the newly created DAO.
        for (uint256 i = 0; i < _pluginSettings.length; i++) {
            // Prepare plugin.
            (
                address plugin,
                ,
                PermissionLib.ItemMultiTarget[] memory permissions
            ) = pluginSetupProcessor.prepareInstallation(
                    address(createdDao),
                    _pluginSettings[i].pluginSetup,
                    _pluginSettings[i].pluginSetupRepo,
                    _pluginSettings[i].data
                );

            // Apply plugin.
            pluginSetupProcessor.applyInstallation(
                address(createdDao),
                _pluginSettings[i].pluginSetup,
                _pluginSettings[i].pluginSetupRepo,
                plugin,
                permissions
            );
        }

        // Set the rest of DAO's permissions.
        _setDAOPermissions(createdDao);

        // Revoke the temporarly granted permissions.
        // Revoke Temporarly `ROOT_PERMISSION` from `pluginSetupProcessor`.
        createdDao.revoke(
            address(createdDao),
            address(pluginSetupProcessor),
            createdDao.ROOT_PERMISSION_ID()
        );

        // Revoke `APPLY_INSTALLATION_PERMISSION` on `pluginSetupProcessor` from this `DAOFactory` .
        createdDao.revoke(
            address(pluginSetupProcessor),
            address(this),
            pluginSetupProcessor.APPLY_INSTALLATION_PERMISSION_ID()
        );

        // Revoke Temporarly `ROOT_PERMISSION_ID` from `pluginSetupProcessor` that implecitly granted to this `DaoFactory`
        // at the create dao step `address(this)` being the initial owner of the new created DAO.
        createdDao.revoke(address(createdDao), address(this), createdDao.ROOT_PERMISSION_ID());
    }

    /// @notice Creates a new DAO, and initialize it with this contract as intial owner.
    /// @param _daoSettings The trusted forwarder, name and metadata hash of the DAO it creates.
    function _createDAO(DAOSettings calldata _daoSettings) internal returns (DAO dao) {
        // create dao
        dao = DAO(payable(createERC1967Proxy(daoBase, bytes(""))));

        // initialize dao with the `ROOT_PERMISSION_ID` permission as DAOFactory.
        dao.initialize(_daoSettings.metadata, address(this), _daoSettings.trustedForwarder);
    }

    /// @notice Sets the required permissions for the new DAO.
    /// @param _dao The DAO instance just created.
    function _setDAOPermissions(DAO _dao) internal {
        // set permissionIds on the dao itself.
        PermissionLib.ItemSingleTarget[] memory items = new PermissionLib.ItemSingleTarget[](6);

        // Grant DAO all the permissions required
        items[0] = PermissionLib.ItemSingleTarget(
            PermissionLib.Operation.Grant,
            address(_dao),
            _dao.ROOT_PERMISSION_ID()
        );
        items[1] = PermissionLib.ItemSingleTarget(
            PermissionLib.Operation.Grant,
            address(_dao),
            _dao.WITHDRAW_PERMISSION_ID()
        );
        items[2] = PermissionLib.ItemSingleTarget(
            PermissionLib.Operation.Grant,
            address(_dao),
            _dao.UPGRADE_DAO_PERMISSION_ID()
        );
        items[3] = PermissionLib.ItemSingleTarget(
            PermissionLib.Operation.Grant,
            address(_dao),
            _dao.SET_SIGNATURE_VALIDATOR_PERMISSION_ID()
        );
        items[4] = PermissionLib.ItemSingleTarget(
            PermissionLib.Operation.Grant,
            address(_dao),
            _dao.SET_TRUSTED_FORWARDER_PERMISSION_ID()
        );
        items[5] = PermissionLib.ItemSingleTarget(
            PermissionLib.Operation.Grant,
            address(_dao),
            _dao.SET_METADATA_PERMISSION_ID()
        );

        _dao.bulkOnSingleTarget(address(_dao), items);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {ENSSubdomainRegistrar} from "./ens/ENSSubdomainRegistrar.sol";
import {IDAO} from "../core/IDAO.sol";
import {InterfaceBasedRegistry} from "./InterfaceBasedRegistry.sol";

/// @title Register your unique DAO name
/// @author Aragon Association - 2022
/// @notice This contract provides the possiblity to register a DAO.
contract DAORegistry is InterfaceBasedRegistry {
    /// @notice The ID of the permission required to call the `register` function.
    bytes32 public constant REGISTER_DAO_PERMISSION_ID = keccak256("REGISTER_DAO_PERMISSION");

    /// @notice The ENS subdomain registrar registering the DAO names.
    ENSSubdomainRegistrar private subdomainRegistrar;

    // @notice Thrown if the plugin repository name is empty.
    error EmptyDaoName();

    /// @notice Emitted when a new DAO is registered.
    /// @param dao The address of the DAO contract.
    /// @param creator The address of the creator.
    /// @param name The DAO name.
    event DAORegistered(address indexed dao, address indexed creator, string name);

    /// @notice Initializes the contract.
    /// @param _managingDao the managing DAO address.
    function initialize(IDAO _managingDao, ENSSubdomainRegistrar _subdomainRegistrar)
        public
        initializer
    {
        __InterfaceBasedRegistry_init(_managingDao, type(IDAO).interfaceId);
        subdomainRegistrar = _subdomainRegistrar;
    }

    /// @notice Registers a DAO by its address.
    /// @dev A name is unique within the Aragon DAO framework and can get stored here.
    /// @param _dao The address of the DAO contract.
    /// @param _creator The address of the creator.
    /// @param _name The DAO name.
    function register(
        IDAO _dao,
        address _creator,
        string calldata _name
    ) external auth(REGISTER_DAO_PERMISSION_ID) {
        address daoAddr = address(_dao);

        if (!(bytes(_name).length > 0)) {
            revert EmptyDaoName();
        }
        
        _register(daoAddr);

        bytes32 labelhash = keccak256(bytes(_name));

        subdomainRegistrar.registerSubnode(labelhash, daoAddr);

        emit DAORegistered(daoAddr, _creator, _name);
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

import "./component/CallbackHandler.sol";
import "./permission/PermissionManager.sol";
import "./IDAO.sol";

/// @title DAO
/// @author Aragon Association - 2021
/// @notice This contract is the entry point to the Aragon DAO framework and provides our users a simple and easy to use public interface.
/// @dev Public API of the Aragon DAO framework.
contract DAO is
    Initializable,
    IERC1271,
    ERC165StorageUpgradeable,
    IDAO,
    UUPSUpgradeable,
    PermissionManager,
    CallbackHandler
{
    using SafeERC20 for ERC20;
    using Address for address;

    /// @notice The ID of the permission required to call the `_authorizeUpgrade` function.
    bytes32 public constant UPGRADE_DAO_PERMISSION_ID = keccak256("UPGRADE_DAO_PERMISSION");

    /// @notice The ID of the permission required to call the `setMetadata` function.
    bytes32 public constant SET_METADATA_PERMISSION_ID = keccak256("SET_METADATA_PERMISSION");

    /// @notice The ID of the permission required to call the `execute` function.
    bytes32 public constant EXECUTE_PERMISSION_ID = keccak256("EXECUTE_PERMISSION");

    /// @notice The ID of the permission required to call the `withdraw` function.
    bytes32 public constant WITHDRAW_PERMISSION_ID = keccak256("WITHDRAW_PERMISSION");

    /// @notice The ID of the permission required to call the `setSignatureValidator` function.
    bytes32 public constant SET_SIGNATURE_VALIDATOR_PERMISSION_ID =
        keccak256("SET_SIGNATURE_VALIDATOR_PERMISSION");

    /// @notice The ID of the permission required to call the `setTrustedForwarder` function.
    bytes32 public constant SET_TRUSTED_FORWARDER_PERMISSION_ID =
        keccak256("SET_TRUSTED_FORWARDER_PERMISSION");

    /// @notice The ID of the permission required to call the `registerStandardCallback` function.
    bytes32 public constant REGISTER_STANDARD_CALLBACK_PERMISSION_ID =
        keccak256("REGISTER_STANDARD_CALLBACK_PERMISSION");

    /// @notice The [ERC-1271](https://eips.ethereum.org/EIPS/eip-1271) signature validator contract.
    IERC1271 public signatureValidator;

    /// @notice The address of the trusted forwarder verifying meta transactions.
    address private trustedForwarder;

    /// @notice Thrown if action execution has failed.
    error ActionFailed();

    /// @notice Thrown if the deposit or withdraw amount is zero.
    error ZeroAmount();

    /// @notice Thrown if there is a mismatch between the expected and actually deposited amount of native tokens.
    /// @param expected The expected native token amount.
    /// @param actual The actual native token amount deposited.
    error NativeTokenDepositAmountMismatch(uint256 expected, uint256 actual);

    /// @notice Thrown if a native token withdraw fails.
    error NativeTokenWithdrawFailed();

    /// @notice Initializes the DAO by
    /// - registering the [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID
    /// - setting the trusted forwarder for meta transactions
    /// - giving the `ROOT_PERMISSION_ID` permission to the initial owner (that should be revoked and transferred to the DAO after setup).
    /// @dev This method is required to support [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822).
    /// @param _metadata IPFS hash that points to all the metadata (logo, description, tags, etc.) of a DAO.
    /// @param _initialOwner The initial owner of the DAO having the `ROOT_PERMISSION_ID` permission.
    /// @param _trustedForwarder The trusted forwarder responsible for verifying meta transactions.
    function initialize(
        bytes calldata _metadata,
        address _initialOwner,
        address _trustedForwarder
    ) external initializer {
        _registerInterface(type(IDAO).interfaceId);
        _registerInterface(type(IERC1271).interfaceId);

        _setMetadata(_metadata);
        _setTrustedForwarder(_trustedForwarder);
        __PermissionManager_init(_initialOwner);
    }

    /// @notice Internal method authorizing the upgrade of the contract via the [upgradeabilty mechanism for UUPS proxies](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) (see [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822)).
    /// @dev The caller must have the `UPGRADE_DAO_PERMISSION_ID` permission.
    function _authorizeUpgrade(address)
        internal
        virtual
        override
        auth(address(this), UPGRADE_DAO_PERMISSION_ID)
    {}

    /// @inheritdoc IDAO
    function setTrustedForwarder(address _newTrustedForwarder)
        external
        override
        auth(address(this), SET_TRUSTED_FORWARDER_PERMISSION_ID)
    {
        _setTrustedForwarder(_newTrustedForwarder);
    }

    /// @inheritdoc IDAO
    function getTrustedForwarder() public view virtual override returns (address) {
        return trustedForwarder;
    }

    /// @inheritdoc IDAO
    function hasPermission(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes memory _data
    ) external view override returns (bool) {
        return isGranted(_where, _who, _permissionId, _data);
    }

    /// @inheritdoc IDAO
    function setMetadata(bytes calldata _metadata)
        external
        override
        auth(address(this), SET_METADATA_PERMISSION_ID)
    {
        _setMetadata(_metadata);
    }

    /// @inheritdoc IDAO
    function execute(uint256 callId, Action[] calldata _actions)
        external
        override
        auth(address(this), EXECUTE_PERMISSION_ID)
        returns (bytes[] memory)
    {
        bytes[] memory execResults = new bytes[](_actions.length);

        for (uint256 i = 0; i < _actions.length;) {
            (bool success, bytes memory response) = _actions[i].to.call{value: _actions[i].value}(
                _actions[i].data
            );

            if (!success) revert ActionFailed();

            execResults[i] = response;

            unchecked {
                i++;
            }
        }

        emit Executed(msg.sender, callId, _actions, execResults);

        return execResults;
    }

    /// @inheritdoc IDAO
    function deposit(
        address _token,
        uint256 _amount,
        string calldata _reference
    ) external payable override {
        if (_amount == 0) revert ZeroAmount();

        if (_token == address(0)) {
            if (msg.value != _amount)
                revert NativeTokenDepositAmountMismatch({expected: _amount, actual: msg.value});
        } else {
            if (msg.value != 0)
                revert NativeTokenDepositAmountMismatch({expected: 0, actual: msg.value});

            ERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        emit Deposited(msg.sender, _token, _amount, _reference);
    }

    /// @inheritdoc IDAO
    function withdraw(
        address _token,
        address _to,
        uint256 _amount,
        string memory _reference
    ) external override auth(address(this), WITHDRAW_PERMISSION_ID) {
        if (_amount == 0) revert ZeroAmount();

        if (_token == address(0)) {
            (bool ok, ) = _to.call{value: _amount}("");
            if (!ok) revert NativeTokenWithdrawFailed();
        } else {
            ERC20(_token).safeTransfer(_to, _amount);
        }

        emit Withdrawn(_token, _to, _amount, _reference);
    }

    /// @inheritdoc IDAO
    function setSignatureValidator(address _signatureValidator)
        external
        override
        auth(address(this), SET_SIGNATURE_VALIDATOR_PERMISSION_ID)
    {
        signatureValidator = IERC1271(_signatureValidator);

        emit SignatureValidatorSet({signatureValidator: _signatureValidator});
    }

    /// @inheritdoc IDAO
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        override(IDAO, IERC1271)
        returns (bytes4)
    {
        if (address(signatureValidator) == address(0)) return bytes4(0); // invalid magic number
        return signatureValidator.isValidSignature(_hash, _signature); // forward call to set validation contract
    }

    /// @notice Emits the `NativeTokenDeposited` event to track native token deposits that weren't made via the deposit method.
    /// @dev This call is bound by the gas limitations for `send`/`transfer` calls introduced by EIP-2929.
    /// Gas cost increases in future hard forks might break this function. As an alternative, EIP-2930-type transactions using access lists can be employed.
    receive() external payable {
        emit NativeTokenDeposited(msg.sender, msg.value);
    }

    /// @notice Fallback to handle future versions of the [ERC-165](https://eips.ethereum.org/EIPS/eip-165) standard.
    fallback() external {
        _handleCallback(msg.sig); // WARN: does a low-level return, any code below would be unreacheable
    }

    /// @notice Emits the MetadataSet event if new metadata is set.
    /// @param _metadata Hash of the IPFS metadata object.
    function _setMetadata(bytes calldata _metadata) internal {
        emit MetadataSet(_metadata);
    }

    /// @notice Sets the trusted forwarder on the DAO and emits the associated event.
    /// @param _trustedForwarder The trusted forwarder address.
    function _setTrustedForwarder(address _trustedForwarder) internal {
        trustedForwarder = _trustedForwarder;

        emit TrustedForwarderSet(_trustedForwarder);
    }

    /// @inheritdoc IDAO
    function registerStandardCallback(
        bytes4 _interfaceId,
        bytes4 _callbackSelector,
        bytes4 _magicNumber
    ) external override auth(address(this), REGISTER_STANDARD_CALLBACK_PERMISSION_ID) {
        _registerInterface(_interfaceId);
        _registerCallback(_callbackSelector, _magicNumber);
        emit StandardCallbackRegistered(_interfaceId, _callbackSelector, _magicNumber);
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title PermissionLib
/// @author Aragon Association - 2021, 2022
/// @notice A library containing objects for permission processing.
library PermissionLib {
    enum Operation {
        Grant,
        Revoke,
        Freeze,
        GrantWithOracle
    }

    struct ItemSingleTarget {
        Operation operation;
        address who;
        bytes32 permissionId;
    }

    struct ItemMultiTarget {
        Operation operation;
        address where;
        address who;
        address oracle;
        bytes32 permissionId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @notice Free function to create a [ERC-1967](https://eips.ethereum.org/EIPS/eip-1967) proxy contract based on the passed base contract address.
/// @param _logic The base contract address.
/// @param _data The constructor arguments for this contract.
/// @return address The address of the proxy contract created.
/// @dev Initializes the upgradeable proxy with an initial implementation specified by _logic. If _data is non-empty, it’s used as data in a delegate call to _logic. This will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity constructor (see [OpenZepplin ERC1967Proxy-constructor](https://docs.openzeppelin.com/contracts/4.x/api/proxy#ERC1967Proxy-constructor-address-bytes-)).
function createERC1967Proxy(address _logic, bytes memory _data) returns (address) {
    return address(new ERC1967Proxy(_logic, _data));
}

// SPDX-License-Identifier:    MIT

pragma solidity 0.8.10;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {PermissionManager} from "../core/permission/PermissionManager.sol";
import {_uncheckedIncrement} from "../utils/UncheckedMath.sol";
import {PluginSetup} from "./PluginSetup.sol";
import {IPluginSetup} from "./PluginSetup.sol";
import {IPluginRepo} from "./IPluginRepo.sol";

/// @title PluginRepo
/// @author Aragon Association - 2020 - 2022
/// @notice The plugin repository contract required for managing and publishing different plugin versions within the Aragon DAO framework following the [Semantic Versioning 2.0.0](https://semver.org/) convention.
//TODO Rename to PluginSetupRepo?
contract PluginRepo is
    Initializable,
    ERC165Upgradeable,
    IPluginRepo,
    UUPSUpgradeable,
    PermissionManager
{
    using Address for address;

    struct Version {
        uint16[3] semanticVersion;
        address pluginSetup;
        bytes contentURI;
    }

    /// @notice The ID of the permission required to call the `createVersion` function.
    bytes32 public constant CREATE_VERSION_PERMISSION_ID = keccak256("CREATE_VERSION_PERMISSION");

    /// @notice The ID of the permission required to call the `createVersion` function.
    bytes32 public constant UPGRADE_REPO_PERMISSION_ID = keccak256("UPGRADE_REPO_PERMISSION");

    /// @notice The index of the next version to be created.
    uint256 internal nextVersionIndex;

    /// @notice The mapping between version indices and version information.
    mapping(uint256 => Version) internal versions;

    /// @notice A mapping between the semantic version number hash and the version index.
    mapping(bytes32 => uint256) internal versionIndexForSemantic;

    /// @notice A mapping between the `PluginSetup` contract addresses and the version index.
    mapping(address => uint256) internal versionIndexForPluginSetup;

    /// @notice Thrown if a semantic version number bump is invalid.
    /// @param currentVersion The current semantic version number.
    /// @param nextVersion The next semantic version number.
    error InvalidBump(uint16[3] currentVersion, uint16[3] nextVersion);

    /// @notice Thrown if version does not exist.
    /// @param versionIndex The index of the version.
    error VersionIndexDoesNotExist(uint256 versionIndex);

    /// @notice Thrown if a contract does not inherit from `PluginSetup`.
    /// @param invalidPluginSetup The address of the contract missing the `PluginSetup` interface.
    error InvalidPluginSetupInterface(address invalidPluginSetup);

    /// @notice Thrown if a contract is not a `PluginSetup` contract.
    /// @param invalidPluginSetup The address of the contract not being a plugin factory.
    error InvalidPluginSetupContract(address invalidPluginSetup);

    /// @notice Thrown if address is not a contract.
    /// @param invalidContract The address not being a contract.
    error InvalidContractAddress(address invalidContract);

    /// @notice Emitted when a new version is created.
    /// @param versionId The version index.
    /// @param semanticVersion The semantic version number.
    event VersionCreated(uint256 versionId, uint16[3] semanticVersion);

    /// @notice Initializes the contract by
    /// - registering the [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID
    /// - initializing the permission manager
    /// - setting the next version index to 1 and
    /// - giving the `CREATE_VERSION_PERMISSION_ID` permission to the initial owner.
    /// @dev This method is required to support [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822).
    function initialize(address initialOwner) external initializer {
        __PermissionManager_init(initialOwner);

        nextVersionIndex = 1;

        // set permissionIds.
        _grant(address(this), initialOwner, CREATE_VERSION_PERMISSION_ID);
    }

    /// @inheritdoc IPluginRepo
    function createVersion(
        uint16[3] memory _newSemanticVersion,
        address _pluginSetup,
        bytes calldata _contentURI
    ) external auth(address(this), CREATE_VERSION_PERMISSION_ID) {
        // In a case where _pluginSetup doesn't contain supportsInterface,
        // but contains fallback, that doesn't return anything(most cases)
        // the below approach aims to still return custom error which not possible with try/catch..
        // NOTE: also checks if _pluginSetup is a contract and reverts if not.
        bytes memory data = _pluginSetup.functionCall(
            abi.encodeWithSelector(
                ERC165.supportsInterface.selector,
                type(IPluginSetup).interfaceId
            )
        );

        // NOTE: if data contains 32 bytes that can't be decoded with uint256
        // it reverts with solidity's ambigious error.
        if (data.length != 32 || abi.decode(data, (uint256)) != 1) {
            revert InvalidPluginSetupInterface({invalidPluginSetup: _pluginSetup});
        }

        uint256 currentVersionIndex = nextVersionIndex - 1;

        uint16[3] memory currentSemanticVersion;

        if (currentVersionIndex > 0) {
            Version storage currentVersion = versions[currentVersionIndex];
            currentSemanticVersion = currentVersion.semanticVersion;
        }

        if (!isValidBump(currentSemanticVersion, _newSemanticVersion)) {
            revert InvalidBump({
                currentVersion: currentSemanticVersion,
                nextVersion: _newSemanticVersion
            });
        }

        uint256 versionIndex = nextVersionIndex;
        nextVersionIndex = _uncheckedIncrement(nextVersionIndex);
        versions[versionIndex] = Version(_newSemanticVersion, _pluginSetup, _contentURI);
        versionIndexForSemantic[semanticVersionHash(_newSemanticVersion)] = versionIndex;
        versionIndexForPluginSetup[_pluginSetup] = versionIndex;

        emit VersionCreated(versionIndex, _newSemanticVersion);
    }

    /// @notice Gets the version information of the latest version.
    /// @return semanticVersion The semantic version number.
    /// @return pluginSetup The address of the plugin factory associated with the version.
    /// @return contentURI The external URI pointing to the content of the version.
    function getLatestVersion()
        public
        view
        returns (
            uint16[3] memory semanticVersion,
            address pluginSetup,
            bytes memory contentURI
        )
    {
        return getVersionById(nextVersionIndex - 1);
    }

    /// @notice Gets the version information associated with a plugin factory address.
    /// @return semanticVersion The semantic version number.
    /// @return pluginSetup The address of the plugin factory associated with the version.
    /// @return contentURI The external URI pointing to the content of the version.
    function getVersionByPluginSetup(address _pluginSetup)
        public
        view
        returns (
            uint16[3] memory semanticVersion,
            address pluginSetup,
            bytes memory contentURI
        )
    {
        return getVersionById(versionIndexForPluginSetup[_pluginSetup]);
    }

    /// @notice Gets the version information associated with a semantic version number.
    /// @return semanticVersion The semantic version number.
    /// @return pluginSetup The address of the plugin factory associated with the version.
    /// @return contentURI The external URI pointing to the content of the version.
    function getVersionBySemanticVersion(uint16[3] memory _semanticVersion)
        public
        view
        returns (
            uint16[3] memory semanticVersion,
            address pluginSetup,
            bytes memory contentURI
        )
    {
        return getVersionById(versionIndexForSemantic[semanticVersionHash(_semanticVersion)]);
    }

    /// @notice Gets the version information associated with a version index.
    /// @return semanticVersion The semantic version number.
    /// @return pluginSetup The address of the plugin factory associated with the version.
    /// @return contentURI The external URI pointing to the content of the version.
    function getVersionById(uint256 _versionIndex)
        public
        view
        returns (
            uint16[3] memory semanticVersion,
            address pluginSetup,
            bytes memory contentURI
        )
    {
        if (_versionIndex <= 0 || _versionIndex >= nextVersionIndex)
            revert VersionIndexDoesNotExist({versionIndex: _versionIndex});
        Version storage version = versions[_versionIndex];
        return (version.semanticVersion, version.pluginSetup, version.contentURI);
    }

    /// @notice Gets the total number of published versions.
    /// @return uint256 The number of published versions.
    function getVersionCount() public view returns (uint256) {
        return nextVersionIndex - 1;
    }

    /// @notice Checks if a version bump is valid.
    /// @param _oldVersion The old semantic version number.
    /// @param _newVersion The new semantic version number.
    /// @return bool Returns true if the bump is valid.
    function isValidBump(uint16[3] memory _oldVersion, uint16[3] memory _newVersion)
        public
        pure
        returns (bool)
    {
        bool hasBumped;
        uint256 i = 0;
        while (i < 3) {
            if (hasBumped) {
                if (_newVersion[i] != 0) {
                    return false;
                }
            } else if (_newVersion[i] != _oldVersion[i]) {
                if (_oldVersion[i] > _newVersion[i] || _newVersion[i] - _oldVersion[i] != 1) {
                    return false;
                }
                hasBumped = true;
            }
            i = _uncheckedIncrement(i);
        }
        return hasBumped;
    }

    /// @notice Generates a hash from a semantic version number.
    /// @param semanticVersion The semantic version number.
    /// @return bytes32 The hash of the semantic version number.
    function semanticVersionHash(uint16[3] memory semanticVersion) internal pure returns (bytes32) {
        return
            keccak256(abi.encodePacked(semanticVersion[0], semanticVersion[1], semanticVersion[2]));
    }

    /// @notice Internal method authorizing the upgrade of the contract via the [upgradeabilty mechanism for UUPS proxies](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) (see [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822)).
    /// @dev The caller must have the `UPGRADE_REPO_PERMISSION_ID` permission.
    function _authorizeUpgrade(address)
        internal
        virtual
        override
        auth(address(this), UPGRADE_REPO_PERMISSION_ID)
    {}

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param interfaceId The ID of the interace.
    /// @return bool Returns true if the interface is supported.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IPluginRepo).interfaceId ||
            interfaceId == type(UUPSUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {PermissionLib} from "../core/permission/PermissionLib.sol";
import {PluginUUPSUpgradeable} from "../core/plugin/PluginUUPSUpgradeable.sol";
import {IPlugin} from "../core/plugin/IPlugin.sol";
import {DaoAuthorizable} from "../core/component/dao-authorizable/DaoAuthorizable.sol";
import {DAO, IDAO} from "../core/DAO.sol";
import {PluginRepoRegistry} from "../registry/PluginRepoRegistry.sol";
import {PluginSetup} from "./PluginSetup.sol";
import {PluginRepo} from "./PluginRepo.sol";

/// @title PluginSetupProcessor
/// @author Aragon Association - 2022
/// @notice This contract processes the preparation and application of plugin setups (installation, update, uninstallation) on behalf of a requesting DAO.
/// @dev This contract is temporarily granted the `ROOT_PERMISSION_ID` permission on the applying DAO and therefore is highly security critical.
contract PluginSetupProcessor is DaoAuthorizable {
    using ERC165Checker for address;

    /// @notice The ID of the permission required to call the `applyInstallation` function.
    bytes32 public constant APPLY_INSTALLATION_PERMISSION_ID =
        keccak256("APPLY_INSTALLATION_PERMISSION");

    /// @notice The ID of the permission required to call the `applyUpdate` function.
    bytes32 public constant APPLY_UPDATE_PERMISSION_ID = keccak256("APPLY_UPDATE_PERMISSION");

    /// @notice The ID of the permission required to call the `applyUninstallation` function.
    bytes32 public constant APPLY_UNINSTALLATION_PERMISSION_ID =
        keccak256("APPLY_UNINSTALLATION_PERMISSION");

    struct PluginUpdateParams {
        address plugin; // The address of the `Plugin` contract being currently active. This can be a proxy or a concrete instance.
        PluginRepo pluginSetupRepo; // The repository storing the `PluginSetup` contracts of all versions of a plugin.
        address currentPluginSetup; // The `PluginSetup` contract of the version being currently active and to be updated from.
        address newPluginSetup; // The `PluginSetup` contract of the version to be updated to.
    }

    /// @notice A mapping between a plugin's installations `appliedId` (see [`getAppliedId`](#private-function-`getAppliedId`)) and a boolean expressing if it has been applied. This is used to guarantees that a plugin can only be installed once.
    mapping(bytes32 => bool) private isInstallationApplied;

    /// @notice A mapping between a plugin's [`setupId`](#private-function-`getSetupId`) and the hashed, multi-targeted permission operation list obtained from the [`prepareInstallation`](#external-function-`prepareInstallation`) function.
    mapping(bytes32 => bytes32) private installPermissionHashes;

    /// @notice A mapping between a plugin's [`setupId`](#private-function-`getSetupId`) and the hashed, multi-targeted permission operation list obtained from the [`prepareUpdate`](#external-function-`prepareUpdate`) function.
    mapping(bytes32 => bytes32) private updatePermissionHashes;

    /// @notice A mapping between a plugin's [`setupId`](#private-function-`getSetupId`) and the hashed, multi-targeted permission operation list obtained from the [`prepareUninstallation`](#external-function-`prepareUninstallation`) function.
    mapping(bytes32 => bytes32) private uninstallPermissionHashes;

    /// @notice A mapping between a plugin's [`setupId`](#private-function-`getSetupId`) and the array of helper addresses hashed via [`getHelpersHash`](#private-function-`getHelpersHash`).
    mapping(bytes32 => bytes32) private helpersHashes;

    /// @notice The plugin repo registry listing the `PluginRepo` contracts versioning the `PluginSetup` contracts.
    PluginRepoRegistry public repoRegistry;

    /// @notice Thrown if a setup is unauthorized for the associated DAO.
    /// @param dao The address of the dao to which the plugin belongs.
    /// @param caller The address (EOA or contract) that requested the application of a setup on the associated DAO.
    /// @param permissionId The permission identifier.
    error SetupApplicationUnauthorized(address dao, address caller, bytes32 permissionId);

    /// @notice Thrown if a plugin is not upgradeable.
    /// @param plugin The address of the plugin contract.
    error PluginNonupgradeable(address plugin);

    /// @notice Thrown if a contract does not support the `IPlugin` interface.
    /// @param plugin The address of the contract.
    error IPluginNotSupported(address plugin);

    /// @notice Thrown if two permissions hashes obtained via [`getPermissionsHash`](#private-function-`getPermissionsHash`) don't match.
    error PermissionsHashMismatch();

    /// @notice Thrown if two helpers hashes obtained via  [`getHelpersHash`](#private-function-`getHelpersHash`) don't match.
    error HelpersHashMismatch();

    /// @notice Thrown if a plugin repository is empty.
    error EmptyPluginRepo();

    /// @notice Thrown if a plugin setup is not prepared.
    error SetupNotPrepared();

    /// @notice Thrown if a plugin setup was already prepared.
    error SetupAlreadyPrepared();

    /// @notice Thrown if a plugin setup is not applied.
    error SetupNotApplied();

    /// @notice Thrown if a plugin setup was already prepared. This is done in case the `PluginSetup` contract is malicios and always/sometime returns the same addresss.
    error SetupAlreadyApplied();

    /// @notice Emitted with a prepared plugin installation to store data relevant for the application step.
    /// @param sender The sender that prepared the plugin installation.
    /// @param dao The address of the dao to which the plugin belongs.
    /// @param pluginSetup The address of the `PluginSetup` contract used for the installation.
    /// @param data The `bytes` encoded data containing the input parameters for the installation as specified in the `prepareInstallationDataABI()` function in the `pluginSetup` setup contract.
    /// @param plugin The address of the plugin contract.
    /// @param helpers The address array of all helpers (contracts or EOAs) that were prepared for the plugin to be installed.
    /// @param permissions The list of multi-targeted permission operations to be applied to the installing DAO.

    event InstallationPrepared(
        address indexed sender,
        address indexed dao,
        address indexed pluginSetup,
        bytes data,
        address plugin,
        address[] helpers,
        PermissionLib.ItemMultiTarget[] permissions
    );

    /// @notice Emitted after a plugin installation was applied.
    /// @param dao The address of the dao to which the plugin belongs.
    /// @param plugin The address of the plugin contract.
    event InstallationApplied(address dao, address plugin);

    /// @notice Emitted with a prepared plugin update to store data relevant for the application step.
    /// @param sender The sender that prepared the plugin installation.
    /// @param dao The address of the dao to which the plugin belongs.
    /// @param pluginSetup The address of the `PluginSetup` contract used for the update.
    /// @param data The `bytes` encoded data containing the input parameters for the installation as specified in the `prepareInstallationDataABI()` function in the `pluginSetup` setup contract.
    /// @param plugin The address of the plugin contract.
    /// @param updatedHelpers The address array of all helpers (contracts or EOAs) that were prepared for the plugin update.
    /// @param permissions The list of multi-targeted permission operations to be applied to the installing DAO.
    /// @param initData The initialization data to be passed to the upgradeable plugin contract.
    event UpdatePrepared(
        address indexed sender,
        address indexed dao,
        address indexed pluginSetup,
        bytes data,
        address plugin,
        address[] updatedHelpers,
        PermissionLib.ItemMultiTarget[] permissions,
        bytes initData
    );

    /// @notice Emitted after a plugin update was applied.
    /// @param dao The address of the dao to which the plugin belongs.
    /// @param plugin The address of the plugin contract.
    event UpdateApplied(address indexed dao, address indexed plugin);

    /// @notice Emitted with a prepared plugin uninstallation to store data relevant for the application step.
    /// @param sender The sender that prepared the plugin uninstallation.
    /// @param dao The address of the dao to which the plugin belongs.
    /// @param pluginSetup The address of the `PluginSetup` contract used for the uninstallation.
    /// @param data The `bytes` encoded data containing the input parameters for the uninstallation as specified in the `prepareUninstallationDataABI()` function in the `pluginSetup` setup contract.
    /// @param plugin The address of the plugin contract.
    /// @param currentHelpers The address array of all helpers (contracts or EOAs) that were prepared for the plugin to be installed.
    /// @param permissions The list of multi-targeted permission operations to be applied to the installing DAO.
    event UninstallationPrepared(
        address indexed sender,
        address indexed dao,
        address indexed pluginSetup,
        bytes data,
        address plugin,
        address[] currentHelpers,
        PermissionLib.ItemMultiTarget[] permissions
    );

    /// @notice Emitted after a plugin installation was applied.
    /// @param dao The address of the dao to which the plugin belongs.
    /// @param plugin The address of the plugin contract.
    event UninstallationApplied(address indexed dao, address indexed plugin);

    /// @notice A modifier to check if a caller has the permission to apply a prepared setup.
    /// @param _dao The address of the DAO.
    /// @param _permissionId The permission identifier.
    modifier canApply(address _dao, bytes32 _permissionId) {
        _canApply(_dao, _permissionId);
        _;
    }

    /// @notice Constructs the plugin setup processor by setting the managing DAO and the associated plugin repo registry.
    /// @param _managingDao The DAO managing the plugin setup processors permissions.
    /// @param _repoRegistry The plugin repo registry contract.
    constructor(IDAO _managingDao, PluginRepoRegistry _repoRegistry) DaoAuthorizable(_managingDao) {
        repoRegistry = _repoRegistry;
    }

    /// @notice Prepares the installation of a plugin.
    /// @param _dao The address of the installing DAO.
    /// @param _pluginSetup The address of the `PluginSetup` contract.
    /// @param _pluginSetupRepo The repository storing the `PluginSetup` contracts of all versions of a plugin.
    /// @param _data The `bytes` encoded data containing the input parameters for the installation as specified in the `prepareInstallationDataABI()` function in the `pluginSetup` setup contract.
    /// @return plugin The prepared plugin contract address.
    /// @return helpers The prepared list of helper contract addresses, that a plugin might require to operate.
    /// @return permissions The prepared list of multi-targeted permission operations to be applied to the installing DAO.
    function prepareInstallation(
        address _dao,
        address _pluginSetup,
        PluginRepo _pluginSetupRepo,
        bytes memory _data
    )
        external
        returns (
            address plugin,
            address[] memory helpers,
            PermissionLib.ItemMultiTarget[] memory permissions
        )
    {
        // ensure repo for plugin manager exists
        if (!repoRegistry.entries(address(_pluginSetupRepo))) {
            revert EmptyPluginRepo();
        }

        // Reverts if pluginSetup doesn't exist on the repo...
        _pluginSetupRepo.getVersionByPluginSetup(_pluginSetup);

        // prepareInstallation
        (plugin, helpers, permissions) = PluginSetup(_pluginSetup).prepareInstallation(_dao, _data);

        // Important safety measure to include dao + plugin manager in the encoding.
        bytes32 setupId = _getSetupId(_dao, _pluginSetup, address(_pluginSetupRepo), plugin);

        // Check if this plugin installation is already prepared
        if (installPermissionHashes[setupId] != bytes32(0)) {
            revert SetupAlreadyPrepared();
        }

        installPermissionHashes[setupId] = _getPermissionsHash(permissions);

        helpersHashes[setupId] = _getHelpersHash(helpers);

        emit InstallationPrepared({
            sender: msg.sender,
            dao: _dao,
            pluginSetup: _pluginSetup,
            data: _data,
            plugin: plugin,
            helpers: helpers,
            permissions: permissions
        });
    }

    /// @notice Applies the permissions of a prepared installation to a DAO.
    /// @param _dao The address of the installing DAO.
    /// @param _pluginSetup The address of the `PluginSetup` contract.
    /// @param _pluginSetupRepo The repository storing the `PluginSetup` contracts of all versions of a plugin.
    /// @param _plugin The address of the `Plugin` contract.
    /// @param _permissions The list of multi-targeted permission operations to apply to the installing DAO.
    function applyInstallation(
        address _dao,
        address _pluginSetup,
        PluginRepo _pluginSetupRepo,
        address _plugin,
        PermissionLib.ItemMultiTarget[] calldata _permissions
    ) external canApply(_dao, APPLY_INSTALLATION_PERMISSION_ID) {
        bytes32 appliedId = _getAppliedId(_dao, _plugin);

        if (isInstallationApplied[appliedId]) {
            revert SetupAlreadyApplied();
        }

        bytes32 setupId = _getSetupId(_dao, _pluginSetup, address(_pluginSetupRepo), _plugin);

        bytes32 storedPermissionsHash = installPermissionHashes[setupId];

        // check if plugin was actually deployed..
        if (storedPermissionsHash == bytes32(0)) {
            revert SetupNotPrepared();
        }

        bytes32 passedPermissionsHash = _getPermissionsHash(_permissions);

        // check that permissions weren't tempered.
        if (storedPermissionsHash != passedPermissionsHash) {
            revert PermissionsHashMismatch();
        }

        // apply permissions on a dao..
        DAO(payable(_dao)).bulkOnMultiTarget(_permissions);

        // set is installation processed
        isInstallationApplied[appliedId] = true;

        // emit the event to connect plugin to the dao.
        emit InstallationApplied({dao: _dao, plugin: _plugin});

        delete installPermissionHashes[setupId];
    }

    /* TODO: might we need to check when `prepareUpdate` gets called, if plugin actually was installed ?
     * Though problematic, since this check only happens when plugin updates from 1.0 to 1.x
     * and checking it always would cost more... shall we still check it and how ? */
    /// @notice Prepares the update of an UUPS upgradeable plugin.
    /// @param _dao The address of the installing DAO.
    /// @param _updateParams The parameters of the update.
    /// @param _currentHelpers The address array of all current helpers (contracts or EOAs) associated with the plugin that is prepared to be updated.
    /// @param _data The `bytes` encoded data containing the input parameters for the update as specified in the `prepareUpdateDataABI()` function in the `newPluginSetup` setup contract inside `_updateParams`.
    /// @return permissions The list of multi-targeted permission operations to be applied to the updating DAO.
    /// @return initData The initialization data to be passed to upgradeable contracts when the update is applied
    /// @dev The list of `_currentHelpers` has to be specified in the same order as they were returned from previous setups preparation steps (the latest `prepareInstallation` or `prepareUpdate` step that has happend) on which the update is prepared for.
    function prepareUpdate(
        address _dao,
        PluginUpdateParams calldata _updateParams,
        address[] calldata _currentHelpers,
        bytes memory _data
    ) external returns (PermissionLib.ItemMultiTarget[] memory, bytes memory) {
        // check that plugin inherits is PluginUUPSUpgradable.
        if (!_updateParams.plugin.supportsInterface(type(IPlugin).interfaceId)) {
            revert IPluginNotSupported({plugin: _updateParams.plugin});
        }

        if (IPlugin(_updateParams.plugin).pluginType() != IPlugin.PluginType.UUPS) {
            revert PluginNonupgradeable({plugin: _updateParams.plugin});
        }

        // Implicitly confirms plugin setups are valid. // TODO Revisit this as this might not be true.
        // ensure repo for plugin manager exists
        if (!repoRegistry.entries(address(_updateParams.pluginSetupRepo))) {
            revert EmptyPluginRepo();
        }

        // Check if plugin is applied
        bytes32 appliedId = _getAppliedId(_dao, _updateParams.plugin);
        if (!isInstallationApplied[appliedId]) {
            revert SetupNotApplied();
        }

        (uint16[3] memory oldVersion, , ) = _updateParams.pluginSetupRepo.getVersionByPluginSetup(
            _updateParams.currentPluginSetup
        );

        // Reverts if newPluginSetup doesn't exist on the repo...
        _updateParams.pluginSetupRepo.getVersionByPluginSetup(_updateParams.newPluginSetup);

        // Avoid stack too deep compiler error by putting the code into curly braces.
        {
            // Check if helpers are correct...
            // Implicitly checks if plugin was installed in the first place.
            bytes32 oldSetupId = _getSetupId(
                _dao,
                _updateParams.currentPluginSetup,
                address(_updateParams.pluginSetupRepo),
                _updateParams.plugin
            );

            if (helpersHashes[oldSetupId] != _getHelpersHash(_currentHelpers)) {
                revert HelpersHashMismatch();
            }

            delete helpersHashes[oldSetupId];
        }

        // prepare update
        (
            address[] memory updatedHelpers,
            bytes memory initData,
            PermissionLib.ItemMultiTarget[] memory permissions
        ) = PluginSetup(_updateParams.newPluginSetup).prepareUpdate(
                _dao,
                _updateParams.plugin,
                _currentHelpers,
                oldVersion,
                _data
            );

        // Avoid stack too deep compiler error by putting the code into curly braces.
        {
            // add new helpers for the future update checks
            bytes32 newSetupId = _getSetupId(
                _dao,
                _updateParams.newPluginSetup,
                address(_updateParams.pluginSetupRepo),
                _updateParams.plugin
            );
            helpersHashes[newSetupId] = _getHelpersHash(updatedHelpers);

            // Set new update permission hashes.
            updatePermissionHashes[newSetupId] = _getPermissionsHash(permissions);
        }

        emit UpdatePrepared({
            sender: msg.sender,
            dao: _dao,
            pluginSetup: _updateParams.newPluginSetup,
            data: _data,
            plugin: _updateParams.plugin,
            updatedHelpers: updatedHelpers,
            permissions: permissions,
            initData: initData
        });

        return (permissions, initData);
    }

    /// @notice Applies the permissions of a prepared update of an UUPS upgradeable contract to a DAO.
    /// @param _dao The address of the updating DAO.
    /// @param _plugin The address of the `PluginUUPSUpgradeable` proxy contract.
    /// @param _pluginSetup The address of the `PluginSetup` contract.
    /// @param _pluginSetupRepo The repository storing the `PluginSetup` contracts of all versions of a plugin.
    /// @param _initData The initialization data to be passed to the upgradeable plugin contract via `upgradeToAndCall`. // revisit
    /// @param _permissions The list of multi-targeted permission operations to apply to the updating DAO.
    function applyUpdate(
        address _dao,
        address _plugin,
        address _pluginSetup,
        PluginRepo _pluginSetupRepo,
        bytes memory _initData,
        PermissionLib.ItemMultiTarget[] calldata _permissions
    ) external canApply(_dao, APPLY_UPDATE_PERMISSION_ID) {
        bytes32 setupId = _getSetupId(_dao, _pluginSetup, address(_pluginSetupRepo), _plugin);

        if (updatePermissionHashes[setupId] != _getPermissionsHash(_permissions)) {
            revert PermissionsHashMismatch();
        }

        _upgradeProxy(_plugin, PluginSetup(_pluginSetup).getImplementationAddress(), _initData);

        DAO(payable(_dao)).bulkOnMultiTarget(_permissions);

        delete updatePermissionHashes[setupId];

        emit UpdateApplied({dao: _dao, plugin: _plugin});
    }

    /// @notice Prepares the uninstallation of a plugin.
    /// @param _dao The address of the installing DAO.
    /// @param _plugin The address of the `Plugin` contract.
    /// @param _pluginSetup The address of the `PluginSetup` contract.
    /// @param _pluginSetupRepo The repository storing the `PluginSetup` contracts of all versions of a plugin.
    /// @param _currentHelpers The address array of all current helpers (contracts or EOAs) associated with the plugin that is prepared to be uninstalled.
    /// @param _data The `bytes` encoded data containing the input parameters for the uninstallation as specified in the `prepareUninstallationDataABI()` function in the `pluginSetup` setup contract.
    /// @return permissions The list of multi-targeted permission operations to be applied to the uninstalling DAO.
    /// @dev The list of `_currentHelpers` has to be specified in the same order as they were returned from previous setups preparation steps (the latest `prepareInstallation` or `prepareUpdate` step that has happend) on which the uninstallation was prepared for.
    function prepareUninstallation(
        address _dao,
        address _plugin,
        address _pluginSetup,
        PluginRepo _pluginSetupRepo,
        address[] calldata _currentHelpers,
        bytes calldata _data
    ) external returns (PermissionLib.ItemMultiTarget[] memory permissions) {
        // ensure repo for plugin manager exists
        if (!repoRegistry.entries(address(_pluginSetupRepo))) {
            revert EmptyPluginRepo();
        }

        // Reverts if pluginSetup doesn't exist on the repo...
        _pluginSetupRepo.getVersionByPluginSetup(_pluginSetup);

        // check if plugin is applied.
        bytes32 appliedId = _getAppliedId(_dao, _plugin);

        if (!isInstallationApplied[appliedId]) {
            revert SetupNotApplied();
        }

        permissions = PluginSetup(_pluginSetup).prepareUninstallation(
            _dao,
            _plugin,
            _currentHelpers,
            _data
        );

        bytes32 setupId = _getSetupId(_dao, _pluginSetup, address(_pluginSetupRepo), _plugin);

        // check helpers
        if (helpersHashes[setupId] != _getHelpersHash(_currentHelpers)) {
            revert HelpersHashMismatch();
        }

        // Check if this plugin uninstallation is already prepared
        if (uninstallPermissionHashes[setupId] != bytes32(0)) {
            revert SetupAlreadyPrepared();
        }

        // set permission hashes.
        uninstallPermissionHashes[setupId] = _getPermissionsHash(permissions);

        emit UninstallationPrepared({
            sender: msg.sender,
            dao: _dao,
            pluginSetup: _pluginSetup,
            data: _data,
            plugin: _plugin,
            currentHelpers: _currentHelpers,
            permissions: permissions
        });
    }

    /// @notice Applies the permissions of a prepared uninstallation to a DAO.
    /// @param _dao The address of the DAO.
    /// @param _pluginSetup The address of the `PluginSetup` contract.
    /// @param _pluginSetupRepo The repository storing the `PluginSetup` contracts of all versions of a plugin.
    /// @param _plugin The address of the `Plugin` contract.
    /// @param _currentHelpers The address array of all current helpers (contracts or EOAs) associated with the plugin that is uninstalled.
    /// @param _permissions The list of multi-targeted permission operations to apply to the uninstalling DAO.
    /// @dev The list of `_currentHelpers` has to be specified in the same order as they were returned from previous setups preparation steps (the latest `prepareInstallation` or `prepareUpdate` step that has happend) on which the uninstallation was prepared for.
    function applyUninstallation(
        address _dao,
        address _plugin,
        address _pluginSetup,
        PluginRepo _pluginSetupRepo,
        address[] calldata _currentHelpers, // TODO Isn't it sufficient to pass the helpers hash?
        PermissionLib.ItemMultiTarget[] calldata _permissions
    ) external canApply(_dao, APPLY_UNINSTALLATION_PERMISSION_ID) {
        bytes32 setupId = _getSetupId(_dao, _pluginSetup, address(_pluginSetupRepo), _plugin);

        if (helpersHashes[setupId] != _getHelpersHash(_currentHelpers)) {
            revert HelpersHashMismatch();
        }

        bytes32 storedPermissionsHash = uninstallPermissionHashes[setupId];
        bytes32 passedPermissionsHash = _getPermissionsHash(_permissions);

        // check that permissions weren't tempered.
        if (storedPermissionsHash != passedPermissionsHash) {
            revert PermissionsHashMismatch();
        }

        DAO(payable(_dao)).bulkOnMultiTarget(_permissions);

        delete helpersHashes[setupId];

        delete uninstallPermissionHashes[setupId];

        emit UninstallationApplied({dao: _dao, plugin: _plugin});
    }

    /// @notice Returns an identifier for applied installations by hashing the DAO and plugin address.
    /// @param _dao The address of the DAO conducting the setup.
    /// @param _plugin The address of the `Plugin` contract associated with the setup.
    function _getAppliedId(address _dao, address _plugin) private pure returns (bytes32 appliedId) {
        appliedId = keccak256(abi.encode(_dao, _plugin));
    }

    /// @notice Returns an identifier for prepared installations by hashing the DAO and plugin address.
    /// @param _dao The address of the DAO conducting the setup.
    /// @param _pluginSetup The address of the plugin setup.
    /// @param _pluginSetupRepo The address of plugin setup repo.
    /// @param _plugin The address of the `Plugin` contract associated with the setup.
    function _getSetupId(
        address _dao,
        address _pluginSetup,
        address _pluginSetupRepo,
        address _plugin
    ) private pure returns (bytes32 setupId) {
        setupId = keccak256(abi.encode(_dao, _pluginSetup, _pluginSetupRepo, _plugin));
    }

    /// @notice Returns a hash of an array of helper addresses (contracts or EOAs).
    /// @param _helpers The array of helper addresses (contracts or EOAs) to be hashed.
    function _getHelpersHash(address[] memory _helpers) private pure returns (bytes32 helpersHash) {
        helpersHash = keccak256(abi.encode(_helpers));
    }

    /// @notice Returns a hash of an array of multi-targeted permission operations.
    /// @param _permissions The array of of multi-targeted permission operations.
    /// @return bytes The hash of the array of permission operations.
    function _getPermissionsHash(PermissionLib.ItemMultiTarget[] memory _permissions)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_permissions));
    }

    /// @notice Upgrades an UUPSUpgradeable proxy contract (see [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822)).
    /// @param _proxy The address of the UUPSUpgradeable proxy.
    /// @param _implementation The address of the implementation contract.
    /// @param _initData The initialization data to be passed to the upgradeable plugin contract via `upgradeToAndCall`.
    function _upgradeProxy(
        address _proxy,
        address _implementation,
        bytes memory _initData
    ) private {
        if (_initData.length > 0) {
            try
                PluginUUPSUpgradeable(_proxy).upgradeToAndCall(_implementation, _initData)
            {} catch Error(string memory reason) {
                revert(reason);
            } catch (
                bytes memory /*lowLevelData*/
            ) {
                revert PluginNonupgradeable({plugin: _proxy});
            }
        } else {
            try PluginUUPSUpgradeable(_proxy).upgradeTo(_implementation) {} catch Error(
                string memory reason
            ) {
                revert(reason);
            } catch (
                bytes memory /*lowLevelData*/
            ) {
                revert PluginNonupgradeable({plugin: _proxy});
            }
        }
    }

    /// @notice Internal function to check if a caller has the permission to apply a prepared setup.
    /// @param _dao The address of the DAO conducting the setup.
    /// @param _permissionId The permission identifier.
    function _canApply(address _dao, bytes32 _permissionId) private view {
        if (
            msg.sender != _dao &&
            !DAO(payable(_dao)).hasPermission(address(this), msg.sender, _permissionId, bytes(""))
        ) {
            revert SetupApplicationUnauthorized({
                dao: _dao,
                caller: msg.sender,
                permissionId: _permissionId
            });
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IDAO} from "../../core/IDAO.sol";
import {PluginUUPSUpgradeable} from "../../core/plugin/PluginUUPSUpgradeable.sol";
import {DaoAuthorizableUpgradeable} from "../../core/component/dao-authorizable/DaoAuthorizableUpgradeable.sol";

/// @title ENSSubdomainRegistrar
/// @author Aragon Association - 2022
/// @notice This contract registers ENS subdomains under a parent domain specified in the initialization process and maintains ownership of the subdomain since only the resolver address is set. This contract must either be the domain node owner or an approved operator of the node owner. The default resolver being used is the one specified in the parent domain.
contract ENSSubdomainRegistrar is UUPSUpgradeable, DaoAuthorizableUpgradeable {
    /// @notice The ID of the permission required to call the `_authorizeUpgrade` function.
    bytes32 public constant UPGRADE_REGISTRAR_PERMISSION_ID =
        keccak256("UPGRADE_REGISTRAR_PERMISSION");

    /// @notice The ID of the permission required to call the `registerSubnode` and `setDefaultResolver` function.
    bytes32 public constant REGISTER_ENS_SUBDOMAIN_PERMISSION_ID =
        keccak256("REGISTER_ENS_SUBDOMAIN_PERMISSION");

    /// @notice The ENS registry contract
    ENS private ens;

    /// @notice The namehash of the domain on which subdomains are registered.
    bytes32 public node;

    /// @notice The address of the ENS resolver resolving the names to an address.
    address public resolver;

    /// @notice Thrown if the registrar is not authorized and is neither the domain node owner nor an approved operator of the domain node owner.
    /// @param nodeOwner The node owner.
    /// @param here The address of this registry.
    error UnauthorizedRegistrar(address nodeOwner, address here);

    /// @notice Thrown if the subnode is already registered.
    /// @param subnode The subnode namehash.
    /// @param nodeOwner The node owner address.
    error AlreadyRegistered(bytes32 subnode, address nodeOwner);

    /// @notice Initializes the component by
    /// - checking that the contract is the domain node owner or an approved operator
    /// - initializing the underlying component
    /// - registering the [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID
    /// - setting the ENS contract, the domain node hash, and resolver.
    /// @param _managingDao The interface of the DAO managing the components permissions.
    /// @param _ens The interface of the ENS registry to be used.
    /// @param _node The ENS parent domain node under which the subdomains are to be registered.
    function initialize(
        IDAO _managingDao,
        ENS _ens,
        bytes32 _node
    ) external initializer {
        address nodeOwner = _ens.owner(_node); // The `initializer` modifier acts as a re-entrancy guard so doing an external calls early is ok.

        // This contract must either be the domain node owner or an approved operator of the node owner.
        if (nodeOwner != address(this) && !_ens.isApprovedForAll(nodeOwner, address(this))) {
            revert UnauthorizedRegistrar({nodeOwner: nodeOwner, here: address(this)});
        }

        __DaoAuthorizableUpgradeable_init(_managingDao);

        ens = _ens;
        node = _node;
        resolver = ens.resolver(_node);
    }

    /// @notice Internal method authorizing the upgrade of the contract via the [upgradeabilty mechanism for UUPS proxies](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) (see [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822)).
    /// @dev The caller must have the `UPGRADE_REGISTRAR_PERMISSION_ID` permission.
    function _authorizeUpgrade(address)
        internal
        virtual
        override
        auth(UPGRADE_REGISTRAR_PERMISSION_ID)
    {}

    /// @notice Registers a new subdomain with this registrar as the owner and set the target address in the resolver.
    /// @param _label The labelhash of the subdomain name.
    /// @param _targetAddress The address to which the subdomain resolves.
    function registerSubnode(bytes32 _label, address _targetAddress)
        external
        auth(REGISTER_ENS_SUBDOMAIN_PERMISSION_ID)
    {
        bytes32 subnode = keccak256(abi.encodePacked(node, _label));
        address currentOwner = ens.owner(subnode);

        if (currentOwner != address(0)) {
            revert AlreadyRegistered(subnode, currentOwner);
        }

        ens.setSubnodeOwner(node, _label, address(this));
        ens.setResolver(subnode, resolver);
        Resolver(resolver).setAddr(subnode, _targetAddress);
    }

    /// @notice Sets the default resolver contract address that the subdomains being registered will use.
    /// @param _resolver The resolver contract to be used.
    function setDefaultResolver(Resolver _resolver)
        external
        auth(REGISTER_ENS_SUBDOMAIN_PERMISSION_ID)
    {
        resolver = address(_resolver);
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title IDAO
/// @author Aragon Association - 2022
/// @notice The interface required for DAOs within the Aragon App DAO framework.
abstract contract IDAO {
    struct Action {
        address to; // Address to call
        uint256 value; // Value to be sent with the call (for example ETH if on mainnet)
        bytes data; // Function selector + arguments
    }

    /// @notice Checks if an address has permission on a contract via a permission identifier and considers if `ANY_ADDRESS` was used in the granting process.
    /// @param _where The address of the contract.
    /// @param _who The address of a EOA or contract to give the permissions.
    /// @param _permissionId The permission identifier.
    /// @param _data The optional data passed to the `PermissionOracle` registered.
    /// @return bool Returns true if the address has permission, false if not.
    function hasPermission(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes memory _data
    ) external view virtual returns (bool);

    /// @notice Updates the DAO metadata (e.g., an IPFS hash).
    /// @param _metadata The IPFS hash of the new metadata object.
    function setMetadata(bytes calldata _metadata) external virtual;

    /// @notice Emitted when the DAO metadata is updated.
    /// @param metadata The IPFS hash of the new metadata object.
    event MetadataSet(bytes metadata);

    /// @notice Executes a list of actions.
    /// @dev Runs a loop through the array of actions and executes them one by one. If one action fails, all will be reverted.
    /// @param callId The id of the call. The definition of the value of callId is up to the calling contract and can be used, e.g., as a nonce.
    /// @param _actions The array of actions.
    /// @return bytes[] The array of results obtained from the executed actions in `bytes`.
    function execute(uint256 callId, Action[] memory _actions)
        external
        virtual
        returns (bytes[] memory);

    /// @notice Emitted when a proposal is executed.
    /// @param actor The address of the caller.
    /// @param callId The id of the call.
    /// @dev The value of callId is defined by the component/contract calling the execute function.
    ///      A `Plugin` implementation can use it, for example, as a nonce.
    /// @param actions Array of actions executed.
    /// @param execResults Array with the results of the executed actions.
    event Executed(address indexed actor, uint256 callId, Action[] actions, bytes[] execResults);

    /// @notice Emitted when a standard callback is registered.
    /// @param interfaceId The ID of the interface.
    /// @param callbackSelector The selector of the callback function.
    /// @param magicNumber The magic number to be registered for the callback function selector.
    event StandardCallbackRegistered(
        bytes4 interfaceId,
        bytes4 callbackSelector,
        bytes4 magicNumber
    );

    /// @notice Deposits (native) tokens to the DAO contract with a reference string.
    /// @param _token The address of the token or address(0) in case of the native token.
    /// @param _amount The amount of tokens to deposit.
    /// @param _reference The reference describing the deposit reason.
    function deposit(
        address _token,
        uint256 _amount,
        string calldata _reference
    ) external payable virtual;

    /// @notice Emitted when a token deposit has been made to the DAO.
    /// @param sender The address of the sender.
    /// @param token The address of the deposited token.
    /// @param amount The amount of tokens deposited.
    /// @param _reference The reference describing the deposit reason.
    event Deposited(
        address indexed sender,
        address indexed token,
        uint256 amount,
        string _reference
    );

    /// @notice Emitted when a native token deposit has been made to the DAO.
    /// @dev This event is intended to be emitted in the `receive` function and is therefore bound by the gas limitations for `send`/`transfer` calls introduced by [ERC-2929](https://eips.ethereum.org/EIPS/eip-2929).
    /// @param sender The address of the sender.
    /// @param amount The amount of native tokens deposited.
    event NativeTokenDeposited(address sender, uint256 amount);

    /// @notice Withdraw (native) tokens from the DAO with a withdraw reference string.
    /// @param _token The address of the token and address(0) in case of the native token.
    /// @param _to The target address to send (native) tokens to.
    /// @param _amount The amount of (native) tokens to withdraw.
    /// @param _reference The reference describing the withdrawal reason.
    function withdraw(
        address _token,
        address _to,
        uint256 _amount,
        string memory _reference
    ) external virtual;

    /// @notice Emitted when a (native) token withdrawal has been made from the DAO.
    /// @param token The address of the withdrawn token or address(0) in case of the native token.
    /// @param to The address of the withdrawer.
    /// @param amount The amount of tokens withdrawn.
    /// @param _reference The reference describing the withdrawal reason.
    event Withdrawn(address indexed token, address indexed to, uint256 amount, string _reference);

    /// @notice Setter for the trusted forwarder verifying the meta transaction.
    /// @param _trustedForwarder The trusted forwarder address.
    function setTrustedForwarder(address _trustedForwarder) external virtual;

    /// @notice Getter for the trusted forwarder verifying the meta transaction.
    /// @return The trusted forwarder address.
    function getTrustedForwarder() external virtual returns (address);

    /// @notice Emitted when a new TrustedForwarder is set on the DAO.
    /// @param forwarder the new forwarder address.
    event TrustedForwarderSet(address forwarder);

    /// @notice Setter for the [ERC-1271](https://eips.ethereum.org/EIPS/eip-1271) signature validator contract.
    /// @param _signatureValidator The address of the signature validator.
    function setSignatureValidator(address _signatureValidator) external virtual;

    /// @notice Emitted when the signature validator address is updated.
    /// @param signatureValidator The address of the signature validator.
    event SignatureValidatorSet(address signatureValidator);

    /// @notice Checks whether a signature is valid for the provided data.
    /// @param _hash The keccak256 hash of arbitrary length data signed on the behalf of `address(this)`.
    /// @param _signature Signature byte array associated with _data.
    /// @return magicValue Returns the `bytes4` magic value `0x1626ba7e` if the signature is valid.
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        virtual
        returns (bytes4);

    /// @notice Registers an ERC standard having a callback by registering its [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID and callback function signature.
    /// @param _interfaceId The ID of the interface.
    /// @param _callbackSelector The selector of the callback function.
    /// @param _magicNumber The magic number to be registered for the function signature.
    function registerStandardCallback(
        bytes4 _interfaceId,
        bytes4 _callbackSelector,
        bytes4 _magicNumber
    ) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "../core/component/dao-authorizable/DaoAuthorizableUpgradeable.sol";

/// @title InterfaceBasedRegistry
/// @author Aragon Association - 2022
/// @notice An [ERC-165](https://eips.ethereum.org/EIPS/eip-165)-based registry for contracts
//TODO Make this PluginUUPSUpgradeable
abstract contract InterfaceBasedRegistry is UUPSUpgradeable, DaoAuthorizableUpgradeable {
    /// @notice The ID of the permission required to call the `_authorizeUpgrade` function.
    bytes32 public constant UPGRADE_REGISTRY_PERMISSION_ID =
        keccak256("UPGRADE_REGISTRY_PERMISSION");

    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID that the target contracts being registered must support.
    bytes4 public targetInterfaceId;

    /// @notice The mapping containing the registry entries returning true for registererd contract addresses.
    mapping(address => bool) public entries;

    /// @notice Thrown if the contract is already registered.
    /// @param registrant The address of the contract to be registered.
    error ContractAlreadyRegistered(address registrant);

    /// @notice Thrown if the contract does not support the required interface.
    /// @param registrant The address of the contract to be registered.
    error ContractInterfaceInvalid(address registrant);

    /// @notice Thrown if the address is not a contract.
    /// @param registrant The address of the contract to be registered.
    error ContractAddressInvalid(address registrant);

    /// @notice Thrown if the contract do not support ERC165.
    /// @param registrant The address of the contract.
    error ContractERC165SupportInvalid(address registrant);

    /// @notice Initializes the component.
    /// @dev This is required for the UUPS upgradability pattern.
    /// @param _managingDao The interface of the DAO managing the components permissions.
    /// @param _targetInterfaceId The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface id of the contracts to be registered.
    function __InterfaceBasedRegistry_init(IDAO _managingDao, bytes4 _targetInterfaceId)
        internal
        virtual
        onlyInitializing
    {
        __DaoAuthorizableUpgradeable_init(_managingDao);

        targetInterfaceId = _targetInterfaceId;
    }

    /// @notice Internal method authorizing the upgrade of the contract via the [upgradeabilty mechanism for UUPS proxies](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) (see [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822)).
    /// @dev The caller must have the `UPGRADE_REGISTRY_PERMISSION_ID` permission.
    function _authorizeUpgrade(address)
        internal
        virtual
        override
        auth(UPGRADE_REGISTRY_PERMISSION_ID)
    {}

    /// @notice Register an [ERC-165](https://eips.ethereum.org/EIPS/eip-165) contract address.
    /// @dev The managing DAO needs to grant REGISTER_PERMISSION_ID to registrar.
    /// @param _registrant The address of an [ERC-165](https://eips.ethereum.org/EIPS/eip-165) contract.
    function _register(address _registrant) internal {
        if (!Address.isContract(_registrant)) {
            revert ContractAddressInvalid({registrant: _registrant});
        }

        if (entries[_registrant]) revert ContractAlreadyRegistered({registrant: _registrant});

        try IERC165(_registrant).supportsInterface(targetInterfaceId) returns (bool result) {
            if (!result) revert ContractInterfaceInvalid(_registrant);
        } catch {
            revert ContractERC165SupportInvalid({registrant: _registrant});
        }

        entries[_registrant] = true;
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[48] private __gap;
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./profiles/IABIResolver.sol";
import "./profiles/IAddressResolver.sol";
import "./profiles/IAddrResolver.sol";
import "./profiles/IContentHashResolver.sol";
import "./profiles/IDNSRecordResolver.sol";
import "./profiles/IDNSZoneResolver.sol";
import "./profiles/IInterfaceResolver.sol";
import "./profiles/INameResolver.sol";
import "./profiles/IPubkeyResolver.sol";
import "./profiles/ITextResolver.sol";
import "./ISupportsInterface.sol";
/**
 * A generic resolver interface which includes all the functions including the ones deprecated
 */
interface Resolver is ISupportsInterface, IABIResolver, IAddressResolver, IAddrResolver, IContentHashResolver, IDNSRecordResolver, IDNSZoneResolver, IInterfaceResolver, INameResolver, IPubkeyResolver, ITextResolver {
    /* Deprecated events */
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);

    /* Deprecated functions */
    function content(bytes32 node) external view returns (bytes32);
    function multihash(bytes32 node) external view returns (bytes memory);
    function setContent(bytes32 node, bytes32 hash) external;
    function setMultihash(bytes32 node, bytes calldata hash) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC1822ProxiableUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/draft-IERC1822Upgradeable.sol";

import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {DaoAuthorizableUpgradeable} from "../component/dao-authorizable/DaoAuthorizableUpgradeable.sol";
import {IDAO} from "../IDAO.sol";
import {IPlugin} from "./IPlugin.sol";

/// @title PluginUUPSUpgradeable
/// @author Aragon Association - 2022
/// @notice An abstract, upgradeable contract to inherit from when creating a plugin being deployed via the UUPS pattern (see [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822)).
abstract contract PluginUUPSUpgradeable is
    IPlugin,
    ERC165Upgradeable,
    UUPSUpgradeable,
    DaoAuthorizableUpgradeable
{
    // NOTE: When adding new state variables to the contract, the size of `_gap` has to be adapted below as well.

    /// @inheritdoc IPlugin
    function pluginType() public pure override returns (PluginType) {
        return PluginType.UUPS;
    }

    /// @notice The ID of the permission required to call the `_authorizeUpgrade` function.
    bytes32 public constant UPGRADE_PLUGIN_PERMISSION_ID = keccak256("UPGRADE_PLUGIN_PERMISSION");

    /// @notice Initializes the plugin by storing the associated DAO.
    /// @param _dao The DAO contract.
    function __PluginUUPSUpgradeable_init(IDAO _dao) internal virtual onlyInitializing {
        __DaoAuthorizableUpgradeable_init(_dao);
    }

    /// @notice Checks if an interface is supported by this or its parent contract.
    /// @param _interfaceId The ID of the interace.
    /// @return bool Returns true if the interface is supported.
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IPlugin).interfaceId ||
            _interfaceId == type(IERC1822ProxiableUpgradeable).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Returns the address of the implementation contract in the [proxy storage slot](https://eips.ethereum.org/EIPS/eip-1967) slot the [UUPS proxy](https://eips.ethereum.org/EIPS/eip-1822) is pointing to.
    /// @return implementation The address of the implementation contract.
    function getImplementationAddress() public view returns (address implementation) {
        implementation = _getImplementation();
    }

    /// @notice Internal method authorizing the upgrade of the contract via the [upgradeabilty mechanism for UUPS proxies](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) (see [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822)).
    /// @dev The caller must have the `UPGRADE_PLUGIN_PERMISSION_ID` permission.
    function _authorizeUpgrade(address)
        internal
        virtual
        override
        auth(UPGRADE_PLUGIN_PERMISSION_ID)
    {}

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {IDAO} from "../../IDAO.sol";
import {DaoAuthorizableBaseUpgradeable} from "./bases/DaoAuthorizableBaseUpgradeable.sol";

/// @title DaoAuthorizableUpgradeable
/// @author Aragon Association - 2022
/// @notice An abstract contract providing a meta-transaction compatible modifier for upgradeable contracts to authorize function calls through an associated DAO.
/// @dev Make sure to call `__DaoAuthorizableUpgradeable_init` during initialization of the inheriting contract.
abstract contract DaoAuthorizableUpgradeable is
    Initializable,
    ContextUpgradeable,
    DaoAuthorizableBaseUpgradeable
{
    /// @notice Initializes the contract by setting the associated DAO.
    /// @param _dao The associated DAO address.
    function __DaoAuthorizableUpgradeable_init(IDAO _dao) internal onlyInitializing {
        dao = _dao;
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSRecordResolver {
    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(bytes32 indexed node, bytes name, uint16 resource, bytes record);
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);
    // DNSZoneCleared is emitted whenever a given node's zone information is cleared.
    event DNSZoneCleared(bytes32 indexed node);

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSZoneResolver {
    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(bytes32 indexed node, bytes lastzonehash, bytes zonehash);

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IInterfaceResolver {
    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) external pure returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SupportsInterface.sol";

abstract contract ResolverBase is SupportsInterface {
    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ISupportsInterface.sol";

abstract contract SupportsInterface is ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ISupportsInterface).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
library StorageSlot {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IPlugin {
    enum PluginType {
        UUPS,
        Cloneable,
        Constructable
    }

    /// @notice returns the plugin's type
    function pluginType() external view returns (PluginType);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import {_auth} from "../../../../utils/auth.sol";
import {IDAO} from "../../../IDAO.sol";

/// @title DaoAuthorizableBase
/// @author Aragon Association - 2022
/// @notice An abstract contract providing a meta transaction compatible modifier for upgradeable contracts to authorize function calls through an associated DAO.
abstract contract DaoAuthorizableBaseUpgradeable is ContextUpgradeable {
    /// @notice The associated DAO managing the permissions of inheriting contracts.
    IDAO internal dao;

    /// @notice Returns the DAO contract.
    /// @return IDAO The DAO contract.
    function getDAO() external view returns (IDAO) {
        return dao;
    }

    /// @notice A modifier to be used to check permissions on a target contract via the associated DAO.
    /// @param _permissionId The permission identifier required to call the method this modifier is applied to.
    modifier auth(bytes32 _permissionId) {
        _auth(dao, address(this), _msgSender(), _permissionId, _msgData());
        _;
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IDAO} from "../core/IDAO.sol";

/// @notice Thrown if a call is unauthorized in the associated DAO.
/// @param dao The associated DAO.
/// @param here The context in which the authorization reverted.
/// @param where The contract requiring the permission.
/// @param who The address (EOA or contract) missing the permission.
/// @param permissionId The permission identifier.
error DaoUnauthorized(address dao, address here, address where, address who, bytes32 permissionId);

/// @notice Free function to to be used by the auth modifier to check permissions on a target contract via the associated DAO.
/// @param _permissionId The permission identifier.
function _auth(
    IDAO _dao,
    address addressThis,
    address _msgSender,
    bytes32 _permissionId,
    bytes calldata _msgData
) view {
    if (!_dao.hasPermission(addressThis, _msgSender, _permissionId, _msgData))
        revert DaoUnauthorized({
            dao: address(_dao),
            here: addressThis,
            where: addressThis,
            who: _msgSender,
            permissionId: _permissionId
        });
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal onlyInitializing {
    }

    function __ERC165Storage_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title CallbackHandler
/// @author Aragon Association - 2022
/// @notice This contract handles callbacks by registering a magic number together with the callback function's selector. It provides the `_handleCallback` function that inherting have to call inside their `fallback()` function  (`_handleCallback(msg.callbackSelector, msg.data)`).  This allows to adaptively register ERC standards (e.g., [ERC-721](https://eips.ethereum.org/EIPS/eip-721), [ERC-1115](https://eips.ethereum.org/EIPS/eip-1155), or future versions of [ERC-165](https://eips.ethereum.org/EIPS/eip-165)) and returning the required magic numbers for the associated callback functions for the inheriting contract so that it doesn't need to be upgraded.
/// @dev This callback handling functionality is intented to be used by executor contracts (i.e., `DAO.sol`).
contract CallbackHandler {
    /// @notice A mapping between callback function selectors and magic return numbers.
    mapping(bytes4 => bytes32) internal callbackMagicNumbers;

    /// @notice The magic number refering to unregistered callbacks.
    bytes32 internal constant UNREGISTERED_CALLBACK = bytes32(0);

    /// @notice Thrown if the callback function is not registered.
    /// @param callbackSelector The selector of the callback function.
    /// @param magicNumber The magic number to be registered for the callback function selector.
    error UnkownCallback(bytes4 callbackSelector, bytes32 magicNumber);

    /// @notice Handles callbacks to adaptively support ERC standards.
    /// @param _callbackSelector The selector of the callback function.
    /// @dev This function is supposed to be called via `_handleCallback(msg.sig, msg.data)` in the `fallback()` function of the inheriting contract.
    function _handleCallback(bytes4 _callbackSelector) internal view {
        bytes32 magicNumber = callbackMagicNumbers[_callbackSelector];
        if (magicNumber == UNREGISTERED_CALLBACK) {
            revert UnkownCallback({callbackSelector: _callbackSelector, magicNumber: magicNumber});
        }
        // low-level return magic number
        assembly {
            mstore(0x00, magicNumber)
            return(0x00, 0x20)
        }
    }

    /// @notice Registers a magic number for a callback function selector.
    /// @param _callbackSelector The selector of the callback function.
    /// @param _magicNumber The magic number to be registered for the callback function selector.
    function _registerCallback(bytes4 _callbackSelector, bytes4 _magicNumber) internal {
        callbackMagicNumbers[_callbackSelector] = _magicNumber;
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IPermissionOracle.sol";
import "./PermissionLib.sol";

/// @title PermissionManager
/// @author Aragon Association - 2021, 2022
/// @notice The permission manager used in a DAO and its associated components.
contract PermissionManager is Initializable {
    /// @notice The ID of the permission required to call the `grant`, `grantWithOracle`, `revoke`, `freeze`, and `bulk` function.
    bytes32 public constant ROOT_PERMISSION_ID = keccak256("ROOT_PERMISSION");

    /// @notice A special address encoding permissions that are valid for any address.
    address internal constant ANY_ADDR = address(type(uint160).max);

    /// @notice A special address encoding if a permissions is not set and therefore not allowed.
    address internal constant UNSET_FLAG = address(0);

    /// @notice A special address encoding if a permission is allowed.
    address internal constant ALLOW_FLAG = address(2);

    /// @notice A mapping storing permissions as hashes (i.e., `permissionHash(where, who, permissionId)`) and their status (unset, allowed, or redirect to a `PermissionOracle`).
    mapping(bytes32 => address) internal permissionsHashed;

    /// @notice A mapping storing frozen permissions as hashes (i.e., `frozenPermissionHash(where, permissionId)`) and their status (`true` = frozen (immutable), `false` = not frozen (mutable)).
    mapping(bytes32 => bool) internal frozenPermissionsHashed;

    /// @notice Thrown if a call is unauthorized.
    /// @param here The context in which the authorization reverted.
    /// @param where The contract requiring the permission.
    /// @param who The address (EOA or contract) missing the permission.
    /// @param permissionId The permission identifier.
    error Unauthorized(address here, address where, address who, bytes32 permissionId);

    /// @notice Thrown if a permission has been already granted.
    /// @param where The address of the target contract to grant `who` permission to.
    /// @param who The address (EOA or contract) to which the permission has already been granted.
    /// @param permissionId The permission identifier.
    error PermissionAlreadyGranted(address where, address who, bytes32 permissionId);

    /// @notice Thrown if a permission has been already revoked.
    /// @param where The address of the target contract to revoke `who`s permission from.
    /// @param who The address (EOA or contract) from which the permission has already been revoked.
    /// @param permissionId The permission identifier.
    error PermissionAlreadyRevoked(address where, address who, bytes32 permissionId);

    /// @notice Thrown if a permission is frozen.
    /// @param where The address of the target contract for which the permission is frozen.
    /// @param permissionId The permission identifier.
    error PermissionFrozen(address where, bytes32 permissionId);

    /// @notice Thrown if a Root permission is set on ANY_ADDR.
    error RootPermissionForAnyAddressDisallowed();

    /// @notice Thrown if a freeze happens on ANY_ADDR.
    error FreezeOnAnyAddressDisallowed();

    // Events

    /// @notice Emitted when a permission `permission` is granted in the context `here` to the address `who` for the contract `where`.
    /// @param permissionId The permission identifier.
    /// @param here The address of the context in which the permission is granted.
    /// @param who The address (EOA or contract) receiving the permission.
    /// @param where The address of the target contract for which `who` receives permission.
    /// @param oracle The address `ALLOW_FLAG` for regular permissions or, alternatively, the `PermissionOracle` to be used.
    event Granted(
        bytes32 indexed permissionId,
        address indexed here,
        address indexed who,
        address where,
        IPermissionOracle oracle
    );

    /// @notice Emitted when a permission `permission` is revoked in the context `here` from the address `who` for the contract `where`.
    /// @param permissionId The permission identifier.
    /// @param here The address of the context in which the permission is revoked.
    /// @param who The address (EOA or contract) losing the permission.
    /// @param where The address of the target contract for which `who` loses permission
    event Revoked(
        bytes32 indexed permissionId,
        address indexed here,
        address indexed who,
        address where
    );

    /// @notice Emitted when a `permission` is made frozen to the address `here` by the contract `where`.
    /// @param permissionId The permission identifier.
    /// @param here The address of the context in which the permission is frozen.
    /// @param where The address of the target contract for which the permission is frozen.
    event Frozen(bytes32 indexed permissionId, address indexed here, address where);

    /// @notice A modifier to be used to check permissions on a target contract.
    /// @param _where The address of the target contract for which the permission is required.
    /// @param _permissionId The permission identifier required to call the method this modifier is applied to.
    modifier auth(address _where, bytes32 _permissionId) {
        _auth(_where, _permissionId);
        _;
    }

    /// @notice Initialization method to set the initial owner of the permission manager.
    /// @dev The initial owner is granted the `ROOT_PERMISSION_ID` permission.
    /// @param _initialOwner The initial owner of the permission manager.
    function __PermissionManager_init(address _initialOwner) internal onlyInitializing {
        _initializePermissionManager(_initialOwner);
    }

    /// @notice Grants permission to an address to call methods in a contract guarded by an auth modifier with the specified permission identifier.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) receiving the permission.
    /// @param _permissionId The permission identifier.
    function grant(
        address _where,
        address _who,
        bytes32 _permissionId
    ) external auth(_where, ROOT_PERMISSION_ID) {
        _grant(_where, _who, _permissionId);
    }

    /// @notice Grants permission to an address to call methods in a target contract guarded by an auth modifier with the specified permission identifier if the referenced oracle permits it.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) receiving the permission.
    /// @param _permissionId The permission identifier.
    /// @param _oracle The `PermissionOracle` that will be asked for authorization on calls connected to the specified permission identifier.
    function grantWithOracle(
        address _where,
        address _who,
        bytes32 _permissionId,
        IPermissionOracle _oracle
    ) external auth(_where, ROOT_PERMISSION_ID) {
        _grantWithOracle(_where, _who, _permissionId, _oracle);
    }

    /// @notice Revokes permission from an address to call methods in a target contract guarded by an auth modifier with the specified permission identifier.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission.
    /// @param _where The address of the target contract for which `who` loses permission.
    /// @param _who The address (EOA or contract) losing the permission.
    /// @param _permissionId The permission identifier.
    function revoke(
        address _where,
        address _who,
        bytes32 _permissionId
    ) external auth(_where, ROOT_PERMISSION_ID) {
        _revoke(_where, _who, _permissionId);
    }

    /// @notice Freezes the current permission settings of a target contract. This is a permanent operation and permissions on the specified contract with the specified permission identifier can never be granted or revoked again.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission.
    /// @param _where The address of the target contract for which the permission are frozen.
    /// @param _permissionId The permission identifier.
    function freeze(address _where, bytes32 _permissionId)
        external
        auth(_where, ROOT_PERMISSION_ID)
    {
        _freeze(_where, _permissionId);
    }

    /// @notice Processes bulk items on the permission manager.
    /// @dev Requires the `ROOT_PERMISSION_ID` permission.
    /// @param _where The address of the contract.
    /// @param items The array of bulk items to process.
    function bulkOnSingleTarget(address _where, PermissionLib.ItemSingleTarget[] calldata items)
        external
        auth(_where, ROOT_PERMISSION_ID)
    {
        for (uint256 i = 0; i < items.length; ) {
            PermissionLib.ItemSingleTarget memory item = items[i];

            if (item.operation == PermissionLib.Operation.Grant) {
                _grant(_where, item.who, item.permissionId);
            } else if (item.operation == PermissionLib.Operation.Revoke) {
                _revoke(_where, item.who, item.permissionId);
            } else if (item.operation == PermissionLib.Operation.Freeze) {
                _freeze(_where, item.permissionId);
            }

            unchecked {
                i++;
            }
        }
    }

    /// @notice Processes bulk items on the permission manager.
    /// @dev Requires that msg.sender has each permissionId on the where.
    /// @param items The array of bulk items to process.
    function bulkOnMultiTarget(PermissionLib.ItemMultiTarget[] calldata items) external {
        for (uint256 i = 0; i < items.length; ) {
            PermissionLib.ItemMultiTarget memory item = items[i];

            // TODO: Optimize
            _auth(item.where, ROOT_PERMISSION_ID);

            if (item.operation == PermissionLib.Operation.Grant) {
                _grant(item.where, item.who, item.permissionId);
            } else if (item.operation == PermissionLib.Operation.Revoke) {
                _revoke(item.where, item.who, item.permissionId);
            } else if (item.operation == PermissionLib.Operation.Freeze) {
                _freeze(item.where, item.permissionId);
            } else if (item.operation == PermissionLib.Operation.GrantWithOracle) {
                _grantWithOracle(
                    item.where,
                    item.who,
                    item.permissionId,
                    IPermissionOracle(item.oracle)
                );
            }

            unchecked {
                i++;
            }
        }
    }

    /// @notice Checks if an address has permission on a contract via a permission identifier and considers if `ANY_ADDRESS` was used in the granting process.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) for which the permission is checked.
    /// @param _permissionId The permission identifier.
    /// @param _data The optional data passed to the `PermissionOracle` registered.
    /// @return bool Returns true if `who` has the permissions on the target contract via the specified permission identifier.
    function isGranted(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes memory _data
    ) public view returns (bool) {
        return
            _isGranted(_where, _who, _permissionId, _data) || // check if _who has permission for _permissionId on _where
            _isGranted(_where, ANY_ADDR, _permissionId, _data) || // check if anyone has permission for _permissionId on _where
            _isGranted(ANY_ADDR, _who, _permissionId, _data); // check if _who has permission for _permissionId on any contract
    }

    /// @notice This method is used to check if permissions for a given permission identifier on a contract are frozen.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _permissionId The permission identifier.
    /// @return bool Returns true if the permission identifier is frozen for the contract address.
    function isFrozen(address _where, bytes32 _permissionId) public view returns (bool) {
        return frozenPermissionsHashed[frozenPermissionHash(_where, _permissionId)];
    }

    /// @notice Grants the `ROOT_PERMISSION_ID` permission to the initial owner during initialization of the permission manager.
    /// @param _initialOwner The initial owner of the permission manager.
    function _initializePermissionManager(address _initialOwner) internal {
        _grant(address(this), _initialOwner, ROOT_PERMISSION_ID);
    }

    /// @notice This method is used in the public `grant` method of the permission manager.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    function _grant(
        address _where,
        address _who,
        bytes32 _permissionId
    ) internal {
        _grantWithOracle(_where, _who, _permissionId, IPermissionOracle(ALLOW_FLAG));
    }

    /// @notice This method is used in the internal `_grant` method of the permission manager.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    /// @param _oracle The PermissionOracle to be used or it is just the ALLOW_FLAG.
    function _grantWithOracle(
        address _where,
        address _who,
        bytes32 _permissionId,
        IPermissionOracle _oracle
    ) internal {
        if (_permissionId == ROOT_PERMISSION_ID && (_who == ANY_ADDR || _where == ANY_ADDR)) {
            revert RootPermissionForAnyAddressDisallowed();
        }

        if (isFrozen(_where, _permissionId)) {
            revert PermissionFrozen({where: _where, permissionId: _permissionId});
        }

        bytes32 permHash = permissionHash(_where, _who, _permissionId);

        if (permissionsHashed[permHash] != UNSET_FLAG) {
            revert PermissionAlreadyGranted({
                where: _where,
                who: _who,
                permissionId: _permissionId
            });
        }
        permissionsHashed[permHash] = address(_oracle);

        emit Granted(_permissionId, msg.sender, _who, _where, _oracle);
    }

    /// @notice This method is used in the public `revoke` method of the permission manager.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    function _revoke(
        address _where,
        address _who,
        bytes32 _permissionId
    ) internal {
        if (isFrozen(_where, _permissionId)) {
            revert PermissionFrozen({where: _where, permissionId: _permissionId});
        }

        bytes32 permHash = permissionHash(_where, _who, _permissionId);
        if (permissionsHashed[permHash] == UNSET_FLAG) {
            revert PermissionAlreadyRevoked({
                where: _where,
                who: _who,
                permissionId: _permissionId
            });
        }
        permissionsHashed[permHash] = UNSET_FLAG;

        emit Revoked(_permissionId, msg.sender, _who, _where);
    }

    /// @notice This method is used in the public `freeze` method of the permission manager.
    /// @param _where The address of the target contract for which the permission is frozen.
    /// @param _permissionId The permission identifier.
    function _freeze(address _where, bytes32 _permissionId) internal {
        if (_where == ANY_ADDR) {
            revert FreezeOnAnyAddressDisallowed();
        }

        bytes32 frozenPermHash = frozenPermissionHash(_where, _permissionId);
        if (frozenPermissionsHashed[frozenPermHash]) {
            revert PermissionFrozen({where: _where, permissionId: _permissionId});
        }

        frozenPermissionsHashed[frozenPermHash] = true;

        emit Frozen(_permissionId, msg.sender, _where);
    }

    /// @notice Checks if a caller is granted permissions on a contract via a permission identifier and redirects the approval to an `PermissionOracle` if this was specified in the setup.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    /// @param _data The optional data passed to the `PermissionOracle` registered..
    /// @return bool Returns true if `who` has the permissions on the contract via the specified permissionId identifier.
    function _isGranted(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes memory _data
    ) internal view returns (bool) {
        address accessFlagOrAclOracle = permissionsHashed[
            permissionHash(_where, _who, _permissionId)
        ];

        if (accessFlagOrAclOracle == UNSET_FLAG) return false;
        if (accessFlagOrAclOracle == ALLOW_FLAG) return true;

        // Since it's not a flag, assume it's an PermissionOracle and try-catch to skip failures
        try
            IPermissionOracle(accessFlagOrAclOracle).isGranted(_where, _who, _permissionId, _data)
        returns (bool allowed) {
            if (allowed) return true;
        } catch {}

        return false;
    }

    /// @notice A private function to be used to check permissions on a target contract.
    /// @param _where The address of the target contract for which the permission is required.
    /// @param _permissionId The permission identifier required to call the method this modifier is applied to.
    function _auth(address _where, bytes32 _permissionId) private view {
        if (
            !(isGranted(_where, msg.sender, _permissionId, msg.data) ||
                isGranted(address(this), msg.sender, _permissionId, msg.data))
        )
            revert Unauthorized({
                here: address(this),
                where: _where,
                who: msg.sender,
                permissionId: _permissionId
            });
    }

    /// @notice Generates the hash for the `permissionsHashed` mapping obtained from the word "PERMISSION", the contract address, the address owning the permission, and the permission identifier.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _who The address (EOA or contract) owning the permission.
    /// @param _permissionId The permission identifier.
    /// @return bytes32 The permission hash.
    function permissionHash(
        address _where,
        address _who,
        bytes32 _permissionId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("PERMISSION", _who, _where, _permissionId));
    }

    /// @notice Generates the hash for the `frozenPermissionsHashed` mapping obtained from the word "IMMUTABLE", the contract address, and the permission identifier.
    /// @param _where The address of the target contract for which `who` recieves permission.
    /// @param _permissionId The permission identifier.
    /// @return bytes32 The hash used in the `frozenPermissions` mapping.
    function frozenPermissionHash(address _where, bytes32 _permissionId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("IMMUTABLE", _where, _permissionId));
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[48] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

pragma solidity 0.8.10;

/// @title IPermissionOracle
/// @author Aragon Association - 2021
/// @notice This interface can be implemented to support more customary permissions depending on on- or off-chain state, e.g., by querying token ownershop or a secondary oracle, respectively.
interface IPermissionOracle {
    /// @notice This method is used to check if a call is permitted.
    /// @param _where The address of the target contract.
    /// @param _who The address (EOA or contract) for which the permission are checked.
    /// @param _permissionId The permission identifier.
    /// @param _data Optional data passed to the `PermissionOracle` implementation.
    /// @return allowed Returns true if the call is permitted.
    function isGranted(
        address _where,
        address _who,
        bytes32 _permissionId,
        bytes calldata _data
    ) external view returns (bool allowed);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

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
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Increments an unsigned integer by one without checking the result for overflow errors (using safe math).
/// @param i The number to be incremented.
/// @return The number incremented by one.
function _uncheckedIncrement(uint256 i) pure returns (uint256) {
    unchecked {
        ++i;
    }
    return i;
}

/// @notice Add two unsigned integers without checking the result for overflow errors (using safe math).
/// @param a The first summand.
/// @param b The second summand.
/// @return The sum.
function _uncheckedAdd(uint256 a, uint256 b) pure returns (uint256) {
    unchecked {
        return a + b;
    }
}

/// @notice Subtracts two unsigned integers without checking the result for overflow errors (using safe math).
/// @param a The minuend.
/// @param b The subtrahend.
/// @return The difference.
function _uncheckedSub(uint256 a, uint256 b) pure returns (uint256) {
    unchecked {
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {createERC1967Proxy as createERC1967} from "../utils/Proxy.sol";
import {IPluginSetup} from "./IPluginSetup.sol";
import {PermissionLib} from "../core/permission/PermissionLib.sol";

/// @title PluginSetup
/// @author Aragon Association - 2022
/// @notice An abstract contract that developers have to inherit from to write the setup of a plugin.
abstract contract PluginSetup is ERC165, IPluginSetup {
    /// @inheritdoc IPluginSetup
    function prepareUpdateDataABI() external view virtual override returns (string memory) {}

    /// @inheritdoc IPluginSetup
    function prepareUpdate(
        address _dao,
        address _plugin,
        address[] memory _currentHelpers,
        uint16[3] calldata _oldVersion,
        bytes memory _data
    )
        external
        virtual
        override
        returns (
            address[] memory updatedHelpers,
            bytes memory initData,
            PermissionLib.ItemMultiTarget[] memory permissions
        )
    {}

    /// @notice A convenience function to create an [ERC-1967](https://eips.ethereum.org/EIPS/eip-1967) proxy contract pointing to an implementation and being associated to a DAO.
    /// @param _implementation The address of the implementation contract to which the proxy is pointing to.
    /// @param _data The data to initialize the storage of the proxy contract.
    /// @return address The address of the created proxy contract.
    function createERC1967Proxy(address _implementation, bytes memory _data)
        internal
        returns (address)
    {
        return createERC1967(_implementation, _data);
    }

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param interfaceId The ID of the interace.
    /// @return bool Returns true if the interface is supported.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IPluginSetup).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier:    MIT

pragma solidity 0.8.10;

/// @title IPluginRepo
/// @author Aragon Association - 2022
/// @notice The interface required for a plugin repository.
interface IPluginRepo {
    /// @notice Creates a new version with contract `_pluginSetupAddress` and content `@fromHex(_contentURI)`.
    /// @param _semanticVersion The semantic version number for the version to be created.
    /// @param _pluginSetupAddress The address of the plugin setup contract.
    /// @param _contentURI External URI where the plugin metadata and subsequent resources can be fetched from
    function createVersion(
        uint16[3] memory _semanticVersion,
        address _pluginSetupAddress,
        bytes calldata _contentURI
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {PermissionLib} from "../core/permission/PermissionLib.sol";

interface IPluginSetup {
    /// @notice The ABI required to decode the `bytes` data in `prepareInstallation()`.
    /// @return The ABI in string format.
    function prepareInstallationDataABI() external view returns (string memory);

    /// @notice Prepares the installation of a plugin.
    /// @param _dao The address of the installing DAO.
    /// @param _data The `bytes` encoded data containing the input parameters for the installation as specified in the `prepareInstallationDataABI()` function.
    /// @return plugin The address of the `Plugin` contract being prepared for installation.
    /// @return helpers The address array of all helpers (contracts or EOAs) associated with the plugin after the installation.
    /// @return permissions The array of multi-targeted permission operations to be applied by the `PluginSetupProcessor` to the installing DAO.
    function prepareInstallation(address _dao, bytes memory _data)
        external
    
        returns (
            address plugin,
            address[] memory helpers,
            PermissionLib.ItemMultiTarget[] memory permissions
        );

    /// @notice The ABI required to decode the `bytes` data in `prepareUpdate()`.
    /// @return The ABI in string format.
    /// @dev The empty implemention is provided here so that this doesn't need to be overriden and implemented. This is relevant, for example, for the initial version of a plugin for which no update exists.
    function prepareUpdateDataABI() external view returns (string memory);

    /// @notice Prepares the update of a plugin.
    /// @param _dao The address of the updating DAO.
    /// @param _plugin The address of the `Plugin` contract to update from.
    /// @param _currentHelpers The address array of all current helpers (contracts or EOAs) associated with the plugin to update from.
    /// @param _oldVersion The semantic version of the plugin to update from.
    /// @param _data The `bytes` encoded data containing the input parameters for the update as specified in the `prepareUpdateDataABI()` function.
    /// @return updatedHelpers The address array of helpers (contracts or EOAs) associated with the plugin after the update.
    /// @return initData The initialization data to be passed to upgradeable contracts when the update is applied in the `PluginSetupProcessor`.
    /// @return permissions The array of multi-targeted permission operations to be applied by the `PluginSetupProcessor` to the updating DAO.
    /// @dev The array of `_currentHelpers` has to be specified in the same order as they were returned from previous setups preparation steps (the latest `prepareInstallation` or `prepareUpdate` step that has happend) on which this update is prepared for.
    function prepareUpdate(
        address _dao,
        address _plugin,
        address[] memory _currentHelpers,
        uint16[3] calldata _oldVersion,
        bytes memory _data
    )
        external
    
        returns (
            address[] memory updatedHelpers,
            bytes memory initData,
            PermissionLib.ItemMultiTarget[] memory permissions
        );

    /// @notice The ABI required to decode the `bytes` data in `prepareUninstallation()`.
    /// @return The ABI in string format.
    function prepareUninstallationDataABI() external view returns (string memory);

    /// @notice Prepares the uninstallation of a plugin.
    /// @param _dao The address of the uninstalling DAO.
    /// @param _plugin The address of the `Plugin` contract to update from.
    /// @param _currentHelpers The address array of all current helpers (contracts or EOAs) associated with the plugin to update from.
    /// @param _data The `bytes` encoded data containing the input parameters for the uninstalltion as specified in the `prepareUninstallationDataABI()` function.
    /// @return permissions The array of multi-targeted permission operations to be applied by the `PluginSetupProcessor` to the uninstalling DAO.
    /// @dev The array of `_currentHelpers` has to be specified in the same order as they were returned from previous setups preparation steps (the latest `prepareInstallation` or `prepareUpdate` step that has happend) on which this update is prepared for.
    function prepareUninstallation(
        address _dao,
        address _plugin,
        address[] calldata _currentHelpers,
        bytes calldata _data
    ) external returns (PermissionLib.ItemMultiTarget[] memory permissions);

    /// @notice Returns the plugin's base implementation.
    /// @return address The address of the plugin implementation contract.
    /// @dev The implementation can be instantiated via the `new` keyword, cloned via the minimal clones pattern (see [ERC-1167](https://eips.ethereum.org/EIPS/eip-1167)), or proxied via the UUPS pattern (see [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822)).
    function getImplementationAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IDAO} from "../../IDAO.sol";
import {DaoAuthorizableBase} from "./bases/DaoAuthorizableBase.sol";

/// @title DaoAuthorizable
/// @author Aragon Association - 2022
/// @notice An abstract contract providing a meta transaction compatible modifier for constructable contracts instantiated via the `new` keyword to authorize function calls through an associated DAO.
abstract contract DaoAuthorizable is DaoAuthorizableBase {
    /// @notice Constructs the contract by setting the associated DAO.
    /// @param _dao The associated DAO address.
    constructor(IDAO _dao) {
        dao = _dao;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {ENSSubdomainRegistrar} from "./ens/ENSSubdomainRegistrar.sol";
import {IDAO} from "../core/IDAO.sol";
import {InterfaceBasedRegistry} from "./InterfaceBasedRegistry.sol";
import {IPluginRepo} from "../plugin/IPluginRepo.sol";

/// @title PluginRepoRegistry
/// @author Aragon Association - 2022
/// @notice This contract maintains an address-based registery of plugin repositories in the Aragon App DAO framework.
contract PluginRepoRegistry is InterfaceBasedRegistry {
    /// @notice The ID of the permission required to call the `register` function.
    bytes32 public constant REGISTER_PLUGIN_REPO_PERMISSION_ID = keccak256("REGISTER_PLUGIN_REPO_PERMISSION");
    
    /// @notice The ENS subdomain registrar registering the PluginRepo names.
    ENSSubdomainRegistrar public subdomainRegistrar;

    /// @notice Emitted if a new plugin repository is registered.
    /// @param name The name of the plugin repository.
    /// @param pluginRepo The address of the plugin repository.
    event PluginRepoRegistered(string name, address pluginRepo);

    /// @notice Initializes the contract by setting calling the `InterfaceBasedRegistry` base class initialize method.
    /// @param _dao The address of the managing DAO.
    function initialize(IDAO _dao, ENSSubdomainRegistrar _subdomainRegistrar) public initializer {
        bytes4 pluginRepoInterfaceId = type(IPluginRepo).interfaceId;
        __InterfaceBasedRegistry_init(_dao, pluginRepoInterfaceId);

        subdomainRegistrar = _subdomainRegistrar;
    }

    /// @notice Registers a plugin repository with a name and address.
    /// @param name The name of the PluginRepo.
    /// @param registrant The address of the PluginRepo contract.
    function registerPluginRepo(string calldata name, address registrant)
        external
        auth(REGISTER_PLUGIN_REPO_PERMISSION_ID)
    {
        // The caller(PluginRepoFactory) explicitly checks
        // if the name is empty and reverts.

        bytes32 labelhash = keccak256(bytes(name));
        subdomainRegistrar.registerSubnode(labelhash, registrant);

        _register(registrant);

        emit PluginRepoRegistered(name, registrant);
    }

    /// @notice This empty reserved space is put in place to allow future versions to add new variables without shifting down storage in the inheritance chain (see [OpenZepplins guide about storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps)).
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {_auth} from "../../../../utils/auth.sol";
import {IDAO} from "../../../IDAO.sol";

/// @title DaoAuthorizableBase
/// @author Aragon Association - 2022
/// @notice An abstract contract providing a meta transaction compatible modifier to authorize function calls through an associated DAO.
abstract contract DaoAuthorizableBase is Context {
    /// @notice The associated DAO managing the permissions of inheriting contracts.
    IDAO internal dao;

    /// @notice Returns the DAO contract.
    /// @return IDAO The DAO contract.
    function getDAO() external view returns (IDAO) {
        return dao;
    }

    /// @notice A modifier to be used to check permissions on a target contract via the associated DAO.
    /// @param _permissionId The permission identifier required to call the method this modifier is applied to.
    modifier auth(bytes32 _permissionId) {
        _auth(dao, address(this), _msgSender(), _permissionId, _msgData());
        _;
    }
}