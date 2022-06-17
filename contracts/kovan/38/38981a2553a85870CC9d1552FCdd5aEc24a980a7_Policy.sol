// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "PolicyStorageModel.sol";
import "ModuleStorage.sol";

contract Policy is PolicyStorageModel, ModuleStorage {
    bytes32 public constant NAME = "Policy";

    constructor(address _registry) WithRegistry(_registry) {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IPolicy.sol";

contract PolicyStorageModel is IPolicy {
    // Metadata
    mapping(bytes32 => Metadata) public metadata;

    // Applications
    mapping(bytes32 => Application) public applications;

    // Policies
    mapping(bytes32 => Policy) public policies;

    // Claims
    mapping(bytes32 => mapping(uint256 => Claim)) public claims;

    // Payouts
    mapping(bytes32 => mapping(uint256 => Payout)) public payouts;

    bytes32[] public bpKeys;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IPolicy {
    // Events
    event LogNewMetadata(
        uint256 productId,
        bytes32 bpKey,
        PolicyFlowState state
    );

    event LogMetadataStateChanged(bytes32 bpKey, PolicyFlowState state);

    event LogNewApplication(uint256 productId, bytes32 bpKey);

    event LogApplicationStateChanged(bytes32 bpKey, ApplicationState state);

    event LogNewPolicy(bytes32 bpKey);

    event LogPolicyStateChanged(bytes32 bpKey, PolicyState state);

    event LogNewClaim(bytes32 bpKey, uint256 claimId, ClaimState state);

    event LogClaimStateChanged(
        bytes32 bpKey,
        uint256 claimId,
        ClaimState state
    );

    event LogNewPayout(
        bytes32 bpKey,
        uint256 claimId,
        uint256 payoutId,
        PayoutState state
    );

    event LogPayoutStateChanged(
        bytes32 bpKey,
        uint256 payoutId,
        PayoutState state
    );

    event LogPayoutCompleted(
        bytes32 bpKey,
        uint256 payoutId,
        PayoutState state
    );

    event LogPartialPayout(bytes32 bpKey, uint256 payoutId, PayoutState state);

    // Statuses
    enum PolicyFlowState {Started, Paused, Finished}

    enum ApplicationState {Applied, Revoked, Underwritten, Declined}

    enum PolicyState {Active, Expired}

    enum ClaimState {Applied, Confirmed, Declined}

    enum PayoutState {Expected, PaidOut}

    // Objects
    struct Metadata {
        // Lookup
        uint256 productId;
        uint256 claimsCount;
        uint256 payoutsCount;
        bool hasPolicy;
        bool hasApplication;
        PolicyFlowState state;
        uint256 createdAt;
        uint256 updatedAt;
        address tokenContract;
        address registryContract;
        uint256 release;
    }

    struct Application {
        bytes data; // ABI-encoded contract data: premium, currency, payout options etc.
        ApplicationState state;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Policy {
        PolicyState state;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Claim {
        // Data to prove claim, ABI-encoded
        bytes data;
        ClaimState state;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Payout {
        // Data describing the payout, ABI-encoded
        bytes data;
        uint256 claimId;
        PayoutState state;
        uint256 createdAt;
        uint256 updatedAt;
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