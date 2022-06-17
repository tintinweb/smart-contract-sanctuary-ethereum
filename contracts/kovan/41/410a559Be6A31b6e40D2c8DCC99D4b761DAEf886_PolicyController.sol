// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IPolicyController.sol";
import "PolicyStorageModel.sol";
import "ModuleController.sol";

contract PolicyController is IPolicyController, PolicyStorageModel, ModuleController {
    bytes32 public constant NAME = "PolicyController";

    constructor(address _registry) WithRegistry(_registry) {}

    /* Metadata */
    function createPolicyFlow(uint256 _productId, bytes32 _bpKey)
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[_bpKey];
        require(
            meta.createdAt == 0,
            "ERROR:POC-001:METADATA_ALREADY_EXISTS_FOR_BPKEY"
        );

        meta.productId = _productId;
        meta.state = PolicyFlowState.Started;
        meta.createdAt = block.timestamp;
        meta.updatedAt = block.timestamp;
        bpKeys.push(_bpKey);

        emit LogNewMetadata(_productId, _bpKey, PolicyFlowState.Started);
    }

    function setPolicyFlowState(bytes32 _bpKey, PolicyFlowState _state)
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[_bpKey];
        require(meta.createdAt > 0, "ERROR:POC-002:METADATA_DOES_NOT_EXIST");

        meta.state = _state;
        meta.updatedAt = block.timestamp;

        emit LogMetadataStateChanged(_bpKey, _state);
    }

    /* Application */
    function createApplication(bytes32 _bpKey, bytes calldata _data)
        external override
        onlyPolicyFlow("Policy")
    {
        Metadata storage meta = metadata[_bpKey];
        require(meta.createdAt > 0, "ERROR:POC-004:METADATA_DOES_NOT_EXIST");

        Application storage application = applications[_bpKey];
        require(
            application.createdAt == 0,
            "ERROR:POC-003:APPLICATION_ALREADY_EXISTS"
        );

        application.state = ApplicationState.Applied;
        application.data = _data;
        application.createdAt = block.timestamp;
        application.updatedAt = block.timestamp;

        assert(meta.createdAt > 0);
        assert(meta.hasApplication == false);

        meta.hasApplication = true;
        meta.updatedAt = block.timestamp;

        emit LogNewApplication(meta.productId, _bpKey);
    }

    function setApplicationState(bytes32 _bpKey, ApplicationState _state)
        external override
        onlyPolicyFlow("Policy")
    {
        Application storage application = applications[_bpKey];
        require(
            application.createdAt > 0,
            "ERROR:POC-005:APPLICATION_DOES_NOT_EXIST"
        );

        application.state = _state;
        application.updatedAt = block.timestamp;

        emit LogApplicationStateChanged(_bpKey, _state);
    }

    /* Policy */
    function createPolicy(bytes32 _bpKey) external override {
        //}onlyPolicyFlow("Policy") {

        Metadata storage meta = metadata[_bpKey];
        require(meta.createdAt > 0, "ERROR:POC-007:METADATA_DOES_NOT_EXIST");
        require(
            meta.hasPolicy == false,
            "ERROR:POC-008:POLICY_ALREADY_EXISTS_FOR_BPKEY"
        );

        Policy storage policy = policies[_bpKey];
        require(
            policy.createdAt == 0,
            "ERROR:POC-006:POLICY_ALREADY_EXISTS_FOR_BPKEY"
        );

        policy.state = PolicyState.Active;
        policy.createdAt = block.timestamp;
        policy.updatedAt = block.timestamp;

        meta.hasPolicy = true;
        meta.updatedAt = block.timestamp;

        emit LogNewPolicy(_bpKey);
    }

    function setPolicyState(bytes32 _bpKey, PolicyState _state)
        external override
        onlyPolicyFlow("Policy")
    {
        Policy storage policy = policies[_bpKey];
        require(policy.createdAt > 0, "ERROR:POC-009:POLICY_DOES_NOT_EXIST");

        policy.state = _state;
        policy.updatedAt = block.timestamp;

        emit LogPolicyStateChanged(_bpKey, _state);
    }

    /* Claim */
    function createClaim(bytes32 _bpKey, bytes calldata _data)
        external override
        onlyPolicyFlow("Policy")
        returns (uint256 _claimId)
    {
        Metadata storage meta = metadata[_bpKey];
        require(meta.createdAt > 0, "ERROR:POC-011:METADATA_DOES_NOT_EXIST");

        Policy storage policy = policies[_bpKey];
        require(policy.createdAt > 0, "ERROR:POC-010:POLICY_DOES_NOT_EXIST");

        _claimId = meta.claimsCount;
        Claim storage claim = claims[_bpKey][_claimId];
        require(claim.createdAt == 0, "ERROR:POC-012:CLAIM_ALREADY_EXISTS");

        meta.claimsCount += 1;
        meta.updatedAt = block.timestamp;

        claim.state = ClaimState.Applied;
        claim.data = _data;
        claim.createdAt = block.timestamp;
        claim.updatedAt = block.timestamp;

        emit LogNewClaim(_bpKey, _claimId, ClaimState.Applied);
    }

    function setClaimState(
        bytes32 _bpKey,
        uint256 _claimId,
        ClaimState _state
    ) external override onlyPolicyFlow("Policy") {
        Claim storage claim = claims[_bpKey][_claimId];
        require(claim.createdAt > 0, "ERROR:POC-013:CLAIM_DOES_NOT_EXIST");

        claim.state = _state;
        claim.updatedAt = block.timestamp;

        emit LogClaimStateChanged(_bpKey, _claimId, _state);
    }

    /* Payout */
    function createPayout(
        bytes32 _bpKey,
        uint256 _claimId,
        bytes calldata _data
    ) external override onlyPolicyFlow("Policy") returns (uint256 _payoutId) {
        Metadata storage meta = metadata[_bpKey];
        require(meta.createdAt > 0, "ERROR:POC-014:METADATA_DOES_NOT_EXIST");

        Claim storage claim = claims[_bpKey][_claimId];
        require(claim.createdAt > 0, "ERROR:POC-015:CLAIM_DOES_NOT_EXIST");

        _payoutId = meta.payoutsCount;
        Payout storage payout = payouts[_bpKey][_payoutId];
        require(payout.createdAt == 0, "ERROR:POC-016:PAYOUT_ALREADY_EXISTS");

        meta.payoutsCount += 1;
        meta.updatedAt = block.timestamp;

        payout.claimId = _claimId;
        payout.data = _data;
        payout.state = PayoutState.Expected;
        payout.createdAt = block.timestamp;
        payout.updatedAt = block.timestamp;

        emit LogNewPayout(_bpKey, _claimId, _payoutId, PayoutState.Expected);
    }

    function payOut(
        bytes32 _bpKey,
        uint256 _payoutId,
        bool _complete,
        bytes calldata _data
    ) external override onlyPolicyFlow("Policy") {
        Metadata storage meta = metadata[_bpKey];
        require(meta.createdAt > 0, "ERROR:POC-017:METADATA_DOES_NOT_EXIST");

        Payout storage payout = payouts[_bpKey][_payoutId];
        require(payout.createdAt > 0, "ERROR:POC-018:PAYOUT_DOES_NOT_EXIST");
        require(
            payout.state == PayoutState.Expected,
            "ERROR:POC-019:PAYOUT_ALREADY_COMPLETED"
        );

        payout.data = _data;
        payout.updatedAt = block.timestamp;

        if (_complete) {
            // Full
            payout.state = PayoutState.PaidOut;
            emit LogPayoutCompleted(_bpKey, _payoutId, payout.state);
        } else {
            // Partial
            emit LogPartialPayout(_bpKey, _payoutId, payout.state);
        }
    }

    function setPayoutState(
        bytes32 _bpKey,
        uint256 _payoutId,
        PayoutState _state
    ) external override onlyPolicyFlow("Policy") {
        Payout storage payout = payouts[_bpKey][_payoutId];
        require(payout.createdAt > 0, "ERROR:POC-020:PAYOUT_DOES_NOT_EXIST");

        payout.state = _state;
        payout.updatedAt = block.timestamp;

        emit LogPayoutStateChanged(_bpKey, _payoutId, _state);
    }

    function getApplication(bytes32 _bpKey)
        external override
        view
        returns (IPolicy.Application memory _application)
    {
        return applications[_bpKey];
    }

    function getPolicy(bytes32 _bpKey)
        external override
        view
        returns (IPolicy.Policy memory _policy)
    {
        return policies[_bpKey];
    }

    function getClaim(bytes32 _bpKey, uint256 _claimId)
        external override
        view
        returns (IPolicy.Claim memory _claim)
    {
        return claims[_bpKey][_claimId];
    }

    function getPayout(bytes32 _bpKey, uint256 _payoutId)
        external override
        view
        returns (IPolicy.Payout memory _payout)
    {
        return payouts[_bpKey][_payoutId];
    }

    function getBpKeyCount() external override view returns (uint256 _count) {
        return bpKeys.length;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IPolicy.sol";

interface IPolicyController {
    function createPolicyFlow(uint256 _productId, bytes32 _bpKey) external;

    function setPolicyFlowState(
        bytes32 _bpKey,
        IPolicy.PolicyFlowState _state
    ) external;

    function createApplication(bytes32 _bpKey, bytes calldata _data) external;

    function setApplicationState(
        bytes32 _bpKey,
        IPolicy.ApplicationState _state
    ) external;

    function createPolicy(bytes32 _bpKey) external;

    function setPolicyState(bytes32 _bpKey, IPolicy.PolicyState _state)
        external;

    function createClaim(bytes32 _bpKey, bytes calldata _data)
        external
        returns (uint256 _claimId);

    function setClaimState(
        bytes32 _bpKey,
        uint256 _claimId,
        IPolicy.ClaimState _state
    ) external;

    function createPayout(
        bytes32 _bpKey,
        uint256 _claimId,
        bytes calldata _data
    ) external returns (uint256 _payoutId);

    function payOut(
        bytes32 _bpKey,
        uint256 _payoutId,
        bool _complete,
        bytes calldata _data
    ) external;

    function setPayoutState(
        bytes32 _bpKey,
        uint256 _payoutId,
        IPolicy.PayoutState _state
    ) external;

    function getApplication(bytes32 _bpKey)
        external
        view
        returns (IPolicy.Application memory _application);

    function getPolicy(bytes32 _bpKey)
        external
        view
        returns (IPolicy.Policy memory _policy);

    function getClaim(bytes32 _bpKey, uint256 _claimId)
        external
        view
        returns (IPolicy.Claim memory _claim);

    function getPayout(bytes32 _bpKey, uint256 _payoutId)
        external
        view
        returns (IPolicy.Payout memory _payout);

    function getBpKeyCount() external view returns (uint256 _count);
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