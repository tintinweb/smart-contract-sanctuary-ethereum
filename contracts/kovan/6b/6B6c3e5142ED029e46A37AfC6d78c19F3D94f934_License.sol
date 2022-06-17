// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "LicenseStorageModel.sol";
import "ModuleStorage.sol";

contract License is LicenseStorageModel, ModuleStorage {
    bytes32 public constant NAME = "License";

    constructor(address _registry) WithRegistry(_registry) {
        // Empty
    }
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

import "BaseModuleStorage.sol";
import "WithRegistry.sol";

abstract contract ModuleStorage is WithRegistry, BaseModuleStorage {
    /* solhint-disable payable-fallback */
    fallback() external override {
        // todo: restrict to controllers
        _delegate(controller);
    }

    /* solhint-enable payable-fallback */

    function assignController(address _controller)
        external
        onlyInstanceOperator
    {
        _assignController(_controller);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "Delegator.sol";

contract BaseModuleStorage is Delegator {
    address public controller;

    /* solhint-disable payable-fallback */
    fallback() external virtual {
        _delegate(controller);
    }

    /* solhint-enable payable-fallback */

    function _assignController(address _controller) internal {
        controller = _controller;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract Delegator {
    function _delegate(address _implementation) internal {
        require(
            _implementation != address(0),
            "ERROR:DEL-001:UNKNOWN_IMPLEMENTATION"
        );

        bytes memory data = msg.data;

        /* solhint-disable no-inline-assembly */
        assembly {
            let result := delegatecall(
                gas(),
                _implementation,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
        /* solhint-enable no-inline-assembly */
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