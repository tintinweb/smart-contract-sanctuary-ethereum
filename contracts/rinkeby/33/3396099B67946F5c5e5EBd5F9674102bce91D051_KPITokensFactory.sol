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

/// SPDX-License-Identifier: GPL-3.0-or-later
/// @title KPI tokens factory
/// @dev The factory contract acts as an entry point for users wanting to
/// create a KPI token., passing as input the id of the template that is
/// to be used, alongside the description's IPFS cid (pointing to a
/// structured JSON describing what the KPI token is about) and the oracles
/// initialization data (template-specific). Other utility view functions
/// are included to query the storage of the contract.
/// @author Federico Luzzi - <[email protected]>
contract KPITokensFactory is Ownable, IKPITokensFactory {
    address public kpiTokensManager;
    address public oraclesManager;
    address public feeReceiver;
    mapping(address => bool) public allowOraclesCreation;
    address[] internal kpiTokens;

    error ZeroAddressKpiTokensManager();
    error ZeroAddressOraclesManager();
    error ZeroAddressFeeReceiver();
    error InvalidIndices();

    event CreateToken(address token);
    event SetKpiTokensManager(address kpiTokensManager);
    event SetOraclesManager(address oraclesManager);
    event SetFeeReceiver(address feeReceiver);

    constructor(
        address _kpiTokensManager,
        address _oraclesManager,
        address _feeReceiver
    ) {
        if (_kpiTokensManager == address(0))
            revert ZeroAddressKpiTokensManager();
        if (_oraclesManager == address(0)) revert ZeroAddressOraclesManager();
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();

        kpiTokensManager = _kpiTokensManager;
        oraclesManager = _oraclesManager;
        feeReceiver = _feeReceiver;
    }

    /// @dev Creates a KPI token with the input data.
    /// @param _id The id of the KPI token template to be used.
    /// @param _description An IPFS cid pointing to a structured JSON describing what the KPI token is about.
    /// @param _expiration A timestamp indicating the KPI token's expiration (avoids locked funds in case
    /// something happens to an oracle).
    /// @param _initializationData The template-specific ABI-encoded initialization data.
    /// @param _oraclesInitializationData The initialization data required by the template to initialize
    /// the linked oracles.
    function createToken(
        uint256 _id,
        string calldata _description,
        uint256 _expiration,
        bytes calldata _initializationData,
        bytes calldata _oraclesInitializationData
    ) external payable override {
        address _instance = IKPITokensManager1(kpiTokensManager).instantiate(
            msg.sender,
            _id,
            _description,
            _initializationData,
            _oraclesInitializationData
        );
        allowOraclesCreation[_instance] = true;
        IKPIToken(_instance).initialize{value: msg.value}(
            msg.sender,
            kpiTokensManager,
            oraclesManager,
            feeReceiver,
            _id,
            _description,
            _expiration,
            _initializationData,
            _oraclesInitializationData
        );
        allowOraclesCreation[_instance] = false;
        kpiTokens.push(_instance);

        emit CreateToken(_instance);
    }

    /// @dev KPI tokens manager address setter. Can only be called by the contract owner.
    /// @param _kpiTokensManager The new KPI tokens manager address.
    function setKpiTokensManager(address _kpiTokensManager)
        external
        override
        onlyOwner
    {
        if (_kpiTokensManager == address(0))
            revert ZeroAddressKpiTokensManager();
        kpiTokensManager = _kpiTokensManager;
        emit SetKpiTokensManager(_kpiTokensManager);
    }

    /// @dev Oracles manager address setter. Can only be called by the contract owner.
    /// @param _oraclesManager The new oracles manager address.
    function setOraclesManager(address _oraclesManager)
        external
        override
        onlyOwner
    {
        if (_oraclesManager == address(0)) revert ZeroAddressOraclesManager();
        oraclesManager = _oraclesManager;
        emit SetOraclesManager(_oraclesManager);
    }

    /// @dev Fee receiver address setter. Can only be called by the contract owner.
    /// @param _feeReceiver The new fee receiver address.
    function setFeeReceiver(address _feeReceiver) external override onlyOwner {
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        feeReceiver = _feeReceiver;
        emit SetFeeReceiver(_feeReceiver);
    }

    /// @dev Gets the amount of all created KPI tokens.
    /// @return The KPI tokens amount.
    function kpiTokensAmount() external view override returns (uint256) {
        return kpiTokens.length;
    }

    /// @dev Gets a KPI tokens slice based on indexes.
    /// @param _fromIndex The index from which to get KPI tokens (inclusive).
    /// @param _toIndex The maximum index to which to get KPI tokens (the element 
    /// at this index won't be included).
    /// @return An address array representing the slice taken between the given indexes.
    function enumerate(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        override
        returns (address[] memory)
    {
        if (_toIndex > kpiTokens.length || _fromIndex > _toIndex)
            revert InvalidIndices();
        uint256 _range = _toIndex - _fromIndex;
        address[] memory _kpiTokens = new address[](_range);
        for (uint256 _i = 0; _i < _range; _i++)
            _kpiTokens[_i] = kpiTokens[_fromIndex + _i];
        return _kpiTokens;
    }
}