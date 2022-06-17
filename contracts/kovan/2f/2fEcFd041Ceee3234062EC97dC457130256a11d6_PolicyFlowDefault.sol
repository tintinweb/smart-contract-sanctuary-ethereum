// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "WithRegistry.sol";
import "IPolicy.sol";
import "IPolicyController.sol";
import "ILicenseController.sol";
import "IQueryController.sol";

/*
 * PolicyFlowDefault is a delegate of ProductService.sol.
 * Access Control is maintained:
 * 1) by checking condition in ProductService.sol
 * 2) by modifiers "onlyPolicyFlow" in StakeController.sol
 * For all functions here, msg.sender is = address of ProductService.sol which is registered in the Registry.
 * (if not, it reverts in StakeController.sol)
 */

contract PolicyFlowDefault is WithRegistry {
    bytes32 public constant NAME = "PolicyFlowDefault";

    // solhint-disable-next-line no-empty-blocks
    constructor(address _registry) WithRegistry(_registry) {}

    function newApplication(
        bytes32 _bpKey,
        bytes calldata _data // replaces premium, currency, payoutOptions
    ) external {
        IPolicyController policy = getPolicyContract();
        ILicenseController license = getLicenseContract();
        // the calling contract is the Product contract, which needs to have a productId in the license contract.
        uint256 productId = license.getProductId(msg.sender);
        require(!license.isPausedProduct(productId), "ERROR:PFD-006:PRODUCT_IS_PAUSED");
        policy.createPolicyFlow(productId, _bpKey);
        policy.createApplication(_bpKey, _data);
    }

    function underwrite(bytes32 _bpKey) external {
        IPolicyController policy = getPolicyContract();
        require(
            policy.getApplication(_bpKey).state ==
                IPolicy.ApplicationState.Applied,
            "ERROR:PFD-001:INVALID_APPLICATION_STATE"
        );
        policy.setApplicationState(
            _bpKey,
            IPolicy.ApplicationState.Underwritten
        );
        policy.createPolicy(_bpKey);
    }

    function decline(bytes32 _bpKey) external {
        IPolicyController policy = getPolicyContract();
        require(
            policy.getApplication(_bpKey).state ==
                IPolicy.ApplicationState.Applied,
            "ERROR:PFD-002:INVALID_APPLICATION_STATE"
        );

        policy.setApplicationState(_bpKey, IPolicy.ApplicationState.Declined);
    }

    function newClaim(bytes32 _bpKey, bytes calldata _data)
        external
        returns (uint256 _claimId)
    {
        _claimId = getPolicyContract().createClaim(_bpKey, _data);
    }

    function confirmClaim(
        bytes32 _bpKey,
        uint256 _claimId,
        bytes calldata _data
    ) external returns (uint256 _payoutId) {
        IPolicyController policy = getPolicyContract();
        require(
            policy.getClaim(_bpKey, _claimId).state ==
            IPolicy.ClaimState.Applied,
            "ERROR:PFD-003:INVALID_CLAIM_STATE"
        );

        policy.setClaimState(_bpKey, _claimId, IPolicy.ClaimState.Confirmed);

        _payoutId = policy.createPayout(_bpKey, _claimId, _data);
    }

    function declineClaim(bytes32 _bpKey, uint256 _claimId) external {
        IPolicyController policy = getPolicyContract();
        require(
            policy.getClaim(_bpKey, _claimId).state ==
            IPolicy.ClaimState.Applied,
            "ERROR:PFD-004:INVALID_CLAIM_STATE"
        );

        policy.setClaimState(_bpKey, _claimId, IPolicy.ClaimState.Declined);
    }

    function expire(bytes32 _bpKey) external {
        IPolicyController policy = getPolicyContract();
        require(
            policy.getPolicy(_bpKey).state == IPolicy.PolicyState.Active,
            "ERROR:PFD-005:INVALID_POLICY_STATE"
        );

        policy.setPolicyState(_bpKey, IPolicy.PolicyState.Expired);
    }

    function payout(
        bytes32 _bpKey,
        uint256 _payoutId,
        bool _complete,
        bytes calldata _data
    ) external {
        getPolicyContract().payOut(_bpKey, _payoutId, _complete, _data);
    }

    function proposeProduct(bytes32 _productName, bytes32 _policyFlow)
    external
    returns (uint256 _productId)
    {
        _productId = getLicenseContract().proposeProduct(
            _productName,
            msg.sender,
            _policyFlow
        );
    }

    function request(
        bytes32 _bpKey,
        bytes calldata _input,
        string calldata _callbackMethodName,
        address _callbackContractAddress,
        uint256 _responsibleOracleId
    ) external returns (uint256 _requestId) {
        _requestId = getQueryContract().request(
            _bpKey,
            _input,
            _callbackMethodName,
            _callbackContractAddress,
            _responsibleOracleId
        );
    }

    function getApplicationData(bytes32 _bpKey)
        external
        view
        returns (bytes memory _data)
    {
        IPolicyController policy = getPolicyContract();
        return policy.getApplication(_bpKey).data;
    }

    function getClaimData(bytes32 _bpKey, uint256 _claimId)
        external
        view
        returns (bytes memory _data)
    {
        IPolicyController policy = getPolicyContract();
        return policy.getClaim(_bpKey, _claimId).data;
    }

    function getPayoutData(bytes32 _bpKey, uint256 _payoutId)
        external
        view
        returns (bytes memory _data)
    {
        IPolicyController policy = getPolicyContract();
        return policy.getPayout(_bpKey, _payoutId).data;
    }

    function getLicenseContract() internal view returns (ILicenseController) {
        return ILicenseController(getContractFromRegistry("License"));
    }

    function getPolicyContract() internal view returns (IPolicyController) {
        return IPolicyController(getContractFromRegistry("Policy"));
    }

    function getQueryContract() internal view returns (IQueryController) {
        return IQueryController(getContractFromRegistry("Query"));
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