/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

pragma solidity 0.8.15;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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


/// @title Base templates manager interface
/// @dev Interface for the base templates manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IBaseTemplatesManager {
    struct Template {
        uint256 id;
        address addrezz;
        uint256 version;
        string specification;
    }

    function addTemplate(address _template, string calldata _specification)
        external;

    function removeTemplate(uint256 _id) external;

    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        string calldata _newSpecification
    ) external;

    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external;

    function template(uint256 _id) external view returns (Template memory);

    function exists(uint256 _id) external view returns (bool);

    function templatesAmount() external view returns (uint256);

    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (Template[] memory);
}


/// @title KPI tokens manager interface
/// @dev Interface for the KPI tokens manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IKPITokensManager1 is IBaseTemplatesManager {
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _id,
        string memory _description,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external returns (address);
}


/// @title KPI token interface
/// @dev KPI token interface.
/// @author Federico Luzzi - <[email protected]>
interface IKPIToken {
    function initialize(
        address _creator,
        address _kpiTokensManager,
        address _oraclesManager,
        address _feeReceiver,
        uint256 _kpiTokenTemplateId,
        string memory _description,
        uint256 _expiration,
        bytes memory _kpiTokenData,
        bytes memory _oraclesData
    ) external payable;

    function finalize(uint256 _result) external;

    function redeem(bytes memory _data) external;

    function creator() external view returns (address);

    function template()
        external
        view
        returns (IKPITokensManager1.Template memory);

    function description() external view returns (string memory);

    function finalized() external view returns (bool);

    function expiration() external view returns (uint256);

    function expired() external view returns (bool);

    function protocolFee(bytes memory _data)
        external
        view
        returns (bytes memory);

    function data() external view returns (bytes memory);

    function oracles() external view returns (address[] memory);
}


/// @title Oracles manager interface
/// @dev Interface for the oracles manager contract.
/// @author Federico Luzzi - <[email protected]>
interface IOraclesManager1 is IBaseTemplatesManager {
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external view returns (address);

    function instantiate(
        address _creator,
        uint256 _id,
        bytes memory _initializationData
    ) external payable returns (address);
}


/// @title Oracle interface
/// @dev Oracle interface.
/// @author Federico Luzzi - <[email protected]>
interface IOracle {
    function initialize(
        address _kpiToken,
        uint256 _templateId,
        bytes memory _initializationData
    ) external payable;

    function kpiToken() external returns (address);

    function template() external view returns (IOraclesManager1.Template memory);

    function finalized() external returns (bool);

    function data() external view returns (bytes memory);
}


/// @title KPI tokens factory interface
/// @dev Interface for the KPI tokens factory contract.
/// @author Federico Luzzi - <[email protected]>
interface IKPITokensFactory {
    function createToken(
        uint256 _id,
        string memory _description,
        uint256 _expiration,
        bytes memory _initializationData,
        bytes memory _oraclesInitializationData
    ) external payable;

    function allowOraclesCreation(address _address) external returns (bool);

    function setKpiTokensManager(address _kpiTokensManager) external;

    function setOraclesManager(address _oraclesManager) external;

    function setFeeReceiver(address _feeReceiver) external;

    function kpiTokensAmount() external view returns (uint256);

    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (address[] memory);
}


/// @title Templates manager
/// @dev The templates manager contract acts as a template
/// registry for oracles/kpi token implementations. Additionally,
/// templates can also only be instantiated by the manager itself,
/// exclusively by request of a KPI token being created. All
/// templates-related functions are governance-gated
/// (addition, removal, upgrade of templates and more) and the
/// governance contract must be the owner of the templates manager.
/// @author Federico Luzzi - <[email protected]>
abstract contract BaseTemplatesManager is Ownable, IBaseTemplatesManager {
    address public factory;
    uint256 internal templateId;
    Template[] internal templates;
    mapping(uint256 => uint256) internal templateIdToIndex;

    error NonExistentTemplate();
    error ZeroAddressFactory();
    error Forbidden();
    error ZeroAddressTemplate();
    error InvalidSpecification();
    error NoKeyForTemplate();
    error InvalidVersionBump();
    error InvalidIndices();
    error AutomationNotSupported();

    event AddTemplate(
        uint256 indexed id,
        address indexed template,
        string specification
    );
    event RemoveTemplate(uint256 indexed id);
    event UpgradeTemplate(
        uint256 indexed id,
        address indexed newTemplate,
        uint256 _newVersion,
        string newSpecification
    );
    event UpdateTemplateSpecification(
        uint256 indexed id,
        string newSpecification
    );

    constructor(address _factory) {
        if (_factory == address(0)) revert ZeroAddressFactory();
        factory = _factory;
    }

    /// @dev Adds a template to the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _template The template's address.
    /// @param _specification An IPFS cid pointing to a structured JSON
    /// describing the template.
    function addTemplate(address _template, string calldata _specification)
        external
        override
        onlyOwner
    {
        if (_template == address(0)) revert ZeroAddressTemplate();
        if (bytes(_specification).length == 0) revert InvalidSpecification();
        uint256 _id = ++templateId;
        templates.push(
            Template({
                id: _id,
                addrezz: _template,
                version: 1,
                specification: _specification
            })
        );
        templateIdToIndex[_id] = templates.length;
        emit AddTemplate(_id, _template, _specification);
    }

    /// @dev Removes a template from the registry. This function can only be called
    /// by the contract owner (governance).
    /// @param _id The id of the template that must be removed.
    function removeTemplate(uint256 _id) external override onlyOwner {
        uint256 _index = templateIdToIndex[_id];
        if (_index == 0) revert NonExistentTemplate();
        Template storage _lastTemplate = templates[templates.length - 1];
        if (_lastTemplate.id != _id) {
            templates[_index - 1] = _lastTemplate;
            templateIdToIndex[_lastTemplate.id] = _index;
        }
        delete templateIdToIndex[_id];
        templates.pop();
        emit RemoveTemplate(_id);
    }

    /// @dev Updates a template specification. The specification is an IPFS cid
    /// pointing to a structured JSON file containing data about the template.
    /// This function can only be called by the contract owner (governance).
    /// @param _id The template's id.
    /// @param _newSpecification the updated specification for the template with id `_id`.
    function updateTemplateSpecification(
        uint256 _id,
        string calldata _newSpecification
    ) external override onlyOwner {
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        storageTemplate(_id).specification = _newSpecification;
        emit UpdateTemplateSpecification(_id, _newSpecification);
    }

    /// @dev Upgrades a template. This function can only be called by the contract owner (governance).
    /// @param _id The id of the template that needs to be upgraded.
    /// @param _newTemplate The new address of the template.
    /// @param _newSpecification The updated specification for the upgraded template.
    function upgradeTemplate(
        uint256 _id,
        address _newTemplate,
        string calldata _newSpecification
    ) external override onlyOwner {
        if (_newTemplate == address(0)) revert ZeroAddressTemplate();
        if (bytes(_newSpecification).length == 0) revert InvalidSpecification();
        Template storage _templateFromStorage = storageTemplate(_id);
        if (
            keccak256(bytes(_templateFromStorage.specification)) ==
            keccak256(bytes(_newSpecification))
        ) revert InvalidSpecification();
        _templateFromStorage.addrezz = _newTemplate;
        _templateFromStorage.specification = _newSpecification;
        _templateFromStorage.version++;
        emit UpgradeTemplate(
            _id,
            _newTemplate,
            _templateFromStorage.version,
            _newSpecification
        );
    }

    /// @dev Gets a template from storage.
    /// @param _id The id of the template that needs to be fetched.
    /// @return The template from storage with id `_id`.
    function storageTemplate(uint256 _id)
        internal
        view
        returns (Template storage)
    {
        if (_id == 0) revert NonExistentTemplate();
        uint256 _index = templateIdToIndex[_id];
        if (_index == 0) revert NonExistentTemplate();
        Template storage _template = templates[_index - 1];
        return _template;
    }

    /// @dev Gets a template by id.
    /// @param _id The id of the template that needs to be fetched.
    /// @return The template with id `_id`.
    function template(uint256 _id)
        external
        view
        override
        returns (Template memory)
    {
        return storageTemplate(_id);
    }

    /// @dev Used to determine whether a template with a certain id exists or not.
    /// @param _id The id of the template that needs to be checked.
    /// @return True if the template exists, false otherwise.
    function exists(uint256 _id) external view override returns (bool) {
        if (_id == 0) return false;
        uint256 _index = templateIdToIndex[_id];
        if (_index == 0) return false;
        return templates[_index - 1].id == _id;
    }

    /// @dev Gets the amount of all registered templates.
    /// @return The templates amount.
    function templatesAmount() external view override returns (uint256) {
        return templates.length;
    }

    /// @dev Gets a templates slice based on indexes. N.B.: the templates are not
    /// ordered and due to how templates are removed, it could happen to have 2
    /// disjointed slices with the same template being in both, even though it
    /// should be rare.
    /// @param _fromIndex The index from which to get templates (inclusive).
    /// @param _toIndex The maximum index to which to get templates (the element at this index won't be included).
    /// @return A templates array representing the slice taken through the given indexes.
    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (Template[] memory)
    {
        if (_toIndex > templates.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        Template[] memory _templates = new Template[](_range);
        for (uint256 _i = 0; _i < _range; _i++)
            _templates[_i] = templates[_fromIndex + _i];
        return _templates;
    }
}

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens manager
/// @dev The KPI token manager contract acts as a template
/// registry for KPI token implementations. Additionally, templates
/// can also only be instantiated by the manager itself,
/// exclusively by request of the factory contract. All
/// templates-related functions are governance-gated
/// (addition, removal, upgrade of templates and more) and the
/// governance contract must be the owner of the KPI tokens manager.
/// @author Federico Luzzi - <[email protected]>
contract KPITokensManager1 is BaseTemplatesManager, IKPITokensManager1 {
    constructor(address _factory) BaseTemplatesManager(_factory) {}

    /// @dev Calculates the salt value used in CREATE2 when
    /// instantiating new templates. the salt is calculated as
    /// keccak256(abi.encodePacked(`_description`, `_initializationData`, `_oraclesInitializationData`)).
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The salt value.
    function salt(
        address _creator,
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _creator,
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            );
    }

    /// @dev Predicts a KPI token template instance address based on the input data.
    /// @param _id The id of the template that is to be instantiated.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The address at which the template with the given input
    /// parameters will be instantiated.
    function predictInstanceAddress(
        address _creator,
        uint256 _id,
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) external view override returns (address) {
        return
            Clones.predictDeterministicAddress(
                storageTemplate(_id).addrezz,
                salt(
                    _creator,
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            );
    }

    /// @dev Instantiates a given template using EIP 1167 minimal proxies.
    /// The input data will both be used to choose the instantiated template
    /// and to feed it initialization data.
    /// @param _id The id of the template that is to be instantiated.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    /// @return The address at which the template with the given input
    /// parameters has been instantiated.
    function instantiate(
        address _creator,
        uint256 _id,
        string calldata _description,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) external override returns (address) {
        if (msg.sender != factory) revert Forbidden();
        return
            Clones.cloneDeterministic(
                storageTemplate(_id).addrezz,
                salt(
                    _creator,
                    _description,
                    _initializationData,
                    _oraclesInitializationData
                )
            );
    }
}