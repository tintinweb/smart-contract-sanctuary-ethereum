// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "ILicenseController.sol";
import "IAccessController.sol";
import "IRegistryController.sol";
import "IQueryController.sol";
import "WithRegistry.sol";
import "IModuleController.sol";
import "IModuleStorage.sol";
import "IInstanceOperatorService.sol";
import "Ownable.sol";

contract InstanceOperatorService is IInstanceOperatorService, WithRegistry, Ownable {
    bytes32 public constant NAME = "InstanceOperatorService";

    // solhint-disable-next-line no-empty-blocks
    constructor(address _registry) WithRegistry(_registry) {}

    function assignController(address _storage, address _controller)
        external override
        onlyOwner
    {
        IModuleStorage(_storage).assignController(_controller);
    }

    function assignStorage(address _controller, address _storage)
        external override
        onlyOwner
    {
        IModuleController(_controller).assignStorage(_storage);
    }

    /* License */
    function approveProduct(uint256 _productId) external override {
        license().approveProduct(_productId);
    }

    function disapproveProduct(uint256 _productId) external override {
        license().disapproveProduct(_productId);
    }

    function pauseProduct(uint256 _productId) external override {
        license().pauseProduct(_productId);
    }

    /* Access */
    function createRole(bytes32 _role) external override onlyOwner {
        access().createRole(_role);
    }

    function addRoleToAccount(address _address, bytes32 _role)
        external override
        onlyOwner
    {
        access().addRoleToAccount(_address, _role);
    }

    function cleanRolesForAccount(address _address) external override onlyOwner {
        access().cleanRolesForAccount(_address);
    }

    /* Registry */
    function registerInRelease(
        bytes32 _release,
        bytes32 _contractName,
        address _contractAddress
    ) external override onlyOwner {
        registry.registerInRelease(_release, _contractName, _contractAddress);
    }

    function register(bytes32 _contractName, address _contractAddress)
        external override
        onlyOwner
    {
        registry.register(_contractName, _contractAddress);
    }

    function deregisterInRelease(bytes32 _release, bytes32 _contractName)
        external override
        onlyOwner
    {
        registry.deregisterInRelease(_release, _contractName);
    }

    function deregister(bytes32 _contractName) external override onlyOwner {
        registry.deregister(_contractName);
    }

    function prepareRelease(bytes32 _newRelease) external override onlyOwner {
        registry.prepareRelease(_newRelease);
    }

    /* Query */
    function approveOracle(uint256 _oracleId) external override onlyOwner {
        query().approveOracle(_oracleId);
    }

    function disapproveOracle(uint256 _oracleId) external override onlyOwner {
        query().disapproveOracle(_oracleId);
    }

    /* Inventory */
    function products() external override view returns(uint256) {
        return license().getProductCount();
    }

    function oracles() external override view returns(uint256) {
        return query().getOracleCount();
    }

    /* Lookup */
    function license() internal view returns (ILicenseController) {
        return ILicenseController(registry.getContract("License"));
    }

    function access() internal view returns (IAccessController) {
        return IAccessController(registry.getContract("Access"));
    }

    function query() internal view returns (IQueryController) {
        return IQueryController(registry.getContract("Query"));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ILicenseController {
    function proposeProduct(
        bytes32 _name,
        address _productContract,
        bytes32 _policyFlow
    ) external returns (uint256 _id);

    function approveProduct(uint256 _id) external;

    function pauseProduct(uint256 _id) external;

    function disapproveProduct(uint256 _id) external;

    function isApprovedProduct(uint256 _id)
        external
        view
        returns (bool _approved);

    function isPausedProduct(uint256 _id) external view returns (bool _paused);

    function isValidCall(uint256 _id) external view returns (bool _valid);

    function authorize(address _sender)
        external
        view
        returns (bool _authorized, address _policyFlow);

    function getProductId(address _addr)
        external
        view
        returns (uint256 _productId);

    function getProductCount() 
        external 
        view 
        returns (uint256 _products);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IAccessController {
    function createRole(bytes32 _role) external;

    function addRoleToAccount(address _address, bytes32 _role) external;

    function cleanRolesForAccount(address _address) external;

    function hasRole(address _address, bytes32 _role)
        external
        view
        returns (bool _hasRole);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRegistryController {
    function registerInRelease(
        bytes32 _release,
        bytes32 _contractName,
        address _contractAddress
    ) external;

    function register(bytes32 _contractName, address _contractAddress) external;

    function deregisterInRelease(bytes32 _release, bytes32 _contractName)
        external;

    function deregister(bytes32 _contractName) external;

    function prepareRelease(bytes32 _newRelease) external;

    function getContractInRelease(bytes32 _release, bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getContract(bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getRelease() external view returns (bytes32 _release);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IQuery.sol";

interface IQueryController {

    function proposeOracle(bytes32 _name, address _oracleContract)
        external
        returns (uint256 _oracleId);

    function updateOracleContract(address _newOracleContract, uint256 _oracleId)
        external;

    function approveOracle(uint256 _oracleId) external;
    function pauseOracle(uint256 _oracleId) external;

    function disapproveOracle(uint256 _oracleId) external;

    function request(
        bytes32 _bpKey,
        bytes calldata _input,
        string calldata _callbackMethodName,
        address _callbackContractAddress,
        uint256 _responsibleOracleId
    ) external returns (uint256 _requestId);

    function respond(
        uint256 _requestId,
        address _responder,
        bytes calldata _data
    ) external;

    function getOracleCount() 
        external 
        view 
        returns (uint256 _oracles);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IQuery {
    enum OracleState {Proposed, Approved, Paused}
    enum OracleAssignmentState {Unassigned, Proposed, Assigned}

    struct Oracle {
        bytes32 name;
        address oracleContract;
        OracleState state;
    }

    struct OracleRequest {
        bytes data;
        bytes32 bpKey;
        string callbackMethodName;
        address callbackContractAddress;
        uint256 responsibleOracleId;
        uint256 createdAt;
    }

    /* Logs */
    event LogOracleProposed(
        uint256 oracleId,
        bytes32 name,
        address oracleContract
    );
    event LogOracleSetState(uint256 oracleId, OracleState state);
    event LogOracleContractUpdated(
        uint256 oracleId,
        address oldContract,
        address newContract
    );
    event LogOracleRequested(
        bytes32 bpKey,
        uint256 requestId,
        uint256 responsibleOracleId
    );
    event LogOracleResponded(
        bytes32 bpKey,
        uint256 requestId,
        address responder,
        bool status
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IRegistryController.sol";
import "AccessModifiers.sol";

contract WithRegistry is AccessModifiers {
    IRegistryController public registry;

    constructor(address _registry) {
        registry = IRegistryController(_registry);
    }

    function assignRegistry(address _registry) external onlyInstanceOperator {
        registry = IRegistryController(_registry);
    }

    function getContractFromRegistry(bytes32 _contractName)
        public
        override
        view
        returns (address _addr)
    {
        _addr = registry.getContract(_contractName);
    }

    function getContractInReleaseFromRegistry(bytes32 _release, bytes32 _contractName)
        internal
        view
        returns (address _addr)
    {
        _addr = registry.getContractInRelease(_release, _contractName);
    }

    function getReleaseFromRegistry() internal view returns (bytes32 _release) {
        _release = registry.getRelease();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IRegistryAccess.sol";


abstract contract AccessModifiers is IRegistryAccess {

    // change visibility to public to allow access from withhin this contract
    function getContractFromRegistry(bytes32 _contractName)
        public
        view
        virtual
        override
        returns (address _addr);

    modifier onlyInstanceOperator() {
        require(
            msg.sender == getContractFromRegistry("InstanceOperatorService"),
            "ERROR:ACM-001:NOT_INSTANCE_OPERATOR"
        );
        _;
    }

    modifier onlyPolicyFlow(bytes32 _module) {
        // Allow only from delegator
        require(
            address(this) == getContractFromRegistry(_module),
            "ERROR:ACM-002:NOT_ON_STORAGE"
        );

        // Allow only ProductService (it delegates to PolicyFlow)
        require(
            msg.sender == getContractFromRegistry("ProductService"),
            "ERROR:ACM-003:NOT_PRODUCT_SERVICE"
        );
        _;
    }

    modifier onlyOracleService() {
        require(
            msg.sender == getContractFromRegistry("OracleService"),
            "ERROR:ACM-004:NOT_ORACLE_SERVICE"
        );
        _;
    }

    modifier onlyOracleOwner() {
        require(
            msg.sender == getContractFromRegistry("OracleOwnerService"),
            "ERROR:ACM-005:NOT_ORACLE_OWNER"
        );
        _;
    }

    modifier onlyProductOwner() {
        require(
            msg.sender == getContractFromRegistry("ProductOwnerService"),
            "ERROR:ACM-006:NOT_PRODUCT_OWNER"
        );
        _;
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRegistryAccess {
    
    function getContractFromRegistry(bytes32 _contractName) 
        external 
        view 
        returns (address _contractAddress);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IModuleController {
    function assignStorage(address _storage) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IModuleStorage {
    function assignController(address _controller) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IInstanceOperatorService {
    function assignController(address _storage, address _controller) external;
    function assignStorage(address _controller, address _storage) external;

    // License
    function approveProduct(uint256 _productId) external;
    function disapproveProduct(uint256 _productId) external;
    function pauseProduct(uint256 _productId) external;

    // Access
    function createRole(bytes32 _role) external;
    function addRoleToAccount(address _address, bytes32 _role) external;
    function cleanRolesForAccount(address _address) external;

    // Registry
    function registerInRelease(
        bytes32 _release,
        bytes32 _contractName,
        address _contractAddress
    ) external;

    function register(bytes32 _contractName, address _contractAddress) external;
    function deregisterInRelease(bytes32 _release, bytes32 _contractName) external;
    function deregister(bytes32 _contractName) external;
    function prepareRelease(bytes32 _newRelease) external;

    // Query
    function approveOracle(uint256 _oracleId) external;
    function disapproveOracle(uint256 _oracleId) external;

    function products() external view returns(uint256 products);
    function oracles() external view returns(uint256 oracles);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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