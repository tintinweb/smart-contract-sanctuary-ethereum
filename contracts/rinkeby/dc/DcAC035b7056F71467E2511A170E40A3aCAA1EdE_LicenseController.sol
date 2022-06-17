// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "ILicenseController.sol";
import "LicenseStorageModel.sol";
import "ModuleController.sol";

contract LicenseController is ILicenseController, LicenseStorageModel, ModuleController {
    bytes32 public constant NAME = "LicenseController";

    constructor(address _registry) WithRegistry(_registry) {}

    /**
     * @dev Register new product
     * _productContract the address of the calling contract, i.e. the product contract to register.
     */
    function proposeProduct(
        bytes32 _name,
        address _productContract,
        bytes32 _policyFlow
    ) external override returns (uint256 _productId) {
        // todo: add restriction, allow only ProductOwners
        require(
            productIdByAddress[_productContract] == 0,
            "ERROR:LIC-001:PRODUCT_IS_ACTIVE"
        );

        productCount += 1;
        _productId = productCount;
        productIdByAddress[_productContract] = _productId;

        // todo: check required policyFlow existence

        products[_productId] = Product(
            _name,
            _productContract,
            _policyFlow,
            getReleaseFromRegistry(),
            ProductState.Proposed
        );

        emit LogProductProposed(
            _productId,
            _name,
            _productContract,
            _policyFlow
        );
    }

    function setProductState(uint256 _id, ProductState _state) internal {
        require(
            products[_id].productContract != address(0),
            "ERROR:LIC-001:PRODUCT_DOES_NOT_EXIST"
        );
        products[_id].state = _state;
        if (_state == ProductState.Approved) {
            productIdByAddress[products[_id].productContract] = _id;
        }

        emit LogProductSetState(_id, _state);
    }

    function approveProduct(uint256 _id) external override onlyInstanceOperator {
        setProductState(_id, ProductState.Approved);
    }

    function pauseProduct(uint256 _id) external override onlyInstanceOperator {
        setProductState(_id, ProductState.Paused);
    }

    function disapproveProduct(uint256 _id) external override onlyInstanceOperator {
        setProductState(_id, ProductState.Proposed);
    }

    /**
     * @dev Check if contract is approved product
     */
    function isApprovedProduct(uint256 _id)
        public override
        view
        returns (bool _approved)
    {
        Product storage product = products[_id];
        _approved =
            product.state == ProductState.Approved ||
            product.state == ProductState.Paused;
    }

    /**
     * @dev Check if contract is paused product
     */
    function isPausedProduct(uint256 _id) public override view returns (bool _paused) {
        _paused = products[_id].state == ProductState.Paused;
    }

    function isValidCall(uint256 _id) public override view returns (bool _valid) {
        _valid = products[_id].state != ProductState.Proposed;
    }

    function authorize(address _sender)
        public override
        view
        returns (bool _authorized, address _policyFlow)
    {
        uint256 productId = productIdByAddress[_sender];
        _authorized = isValidCall(productId);
        _policyFlow = getContractInReleaseFromRegistry(
            products[productId].release,
            products[productId].policyFlow
        );
    }

    function getProductId(address _productContract)
        public override
        view
        returns (uint256 _productId)
    {
        require(
            productIdByAddress[_productContract] > 0,
            "ERROR:LIC-002:PRODUCT_NOT_APPROVED_OR_DOES_NOT_EXIST"
        );

        _productId = productIdByAddress[_productContract];
    }

    function getProductCount() external override view returns (uint256) { 
        return productCount; 
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

import "ILicense.sol";

contract LicenseStorageModel is ILicense {
    mapping(uint256 => Product) public products;
    mapping(address => uint256) public productIdByAddress;
    uint256 public productCount;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ILicense {
    enum ProductState {Proposed, Approved, Paused}

    event LogProductProposed(
        uint256 productId,
        bytes32 name,
        address productContract,
        bytes32 policyFlow
    );

    event LogProductSetState(uint256 productId, ProductState state);

    struct Product {
        bytes32 name;
        address productContract;
        bytes32 policyFlow;
        bytes32 release;
        ProductState state;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "BaseModuleController.sol";
import "WithRegistry.sol";

abstract contract ModuleController is WithRegistry, BaseModuleController {
    /* solhint-disable payable-fallback */
    fallback() external {
        revert("ERROR:MOC-001:FALLBACK_FUNCTION_NOW_ALLOWED");
    }

    /* solhint-enable payable-fallback */

    function assignStorage(address _storage) external onlyInstanceOperator {
        _assignStorage(_storage);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract BaseModuleController {
    address public delegator;

    function _assignStorage(address _storage) internal {
        delegator = _storage;
    }
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