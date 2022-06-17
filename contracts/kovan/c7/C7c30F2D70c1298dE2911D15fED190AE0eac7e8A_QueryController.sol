// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "QueryStorageModel.sol";
import "IQueryController.sol";
import "ModuleController.sol";
import "IOracle.sol";

contract QueryController is IQueryController, QueryStorageModel, ModuleController {
    bytes32 public constant NAME = "QueryController";

    modifier isResponsibleOracle(uint256 _requestId, address _responder) {
        require(
            oracles[oracleRequests[_requestId].responsibleOracleId]
                .oracleContract == _responder,
            "ERROR:QUC-001:NOT_RESPONSIBLE_ORACLE"
        );
        _;
    }

    constructor(address _registry) WithRegistry(_registry) {}

    function proposeOracle(bytes32 _name, address _oracleContract)
        external
        override
        onlyOracleOwner
        returns (uint256 _oracleId)
    {
        require(
            oracleIdByAddress[_oracleContract] == 0,
            "ERROR:QUC-008:ORACLE_ALREADY_EXISTS"
        );

        oracleCount += 1;
        _oracleId = oracleCount;

        oracles[_oracleId] = Oracle(
            _name,
            _oracleContract,
            OracleState.Proposed
        );
        oracleIdByAddress[_oracleContract] = _oracleId;

        emit LogOracleProposed(_oracleId, _name, _oracleContract);
    }

    function updateOracleContract(address _newOracleContract, uint256 _oracleId)
        external
        override
        onlyOracleOwner
    {
        require(
            oracleIdByAddress[_newOracleContract] == 0,
            "ERROR:QUC-009:ORACLE_ALREADY_EXISTS"
        );

        address prevContract = oracles[_oracleId].oracleContract;

        oracleIdByAddress[oracles[_oracleId].oracleContract] = 0;
        oracles[_oracleId].oracleContract = _newOracleContract;
        oracleIdByAddress[_newOracleContract] = _oracleId;

        emit LogOracleContractUpdated(
            _oracleId,
            prevContract,
            _newOracleContract
        );
    }

    function setOracleState(uint256 _oracleId, OracleState _state) internal {
        require(
            oracles[_oracleId].oracleContract != address(0),
            "ERROR:QUC-011:ORACLE_DOES_NOT_EXIST"
        );
        oracles[_oracleId].state = _state;
        emit LogOracleSetState(_oracleId, _state);
    }

    function approveOracle(uint256 _oracleId) external override onlyInstanceOperator {
        setOracleState(_oracleId, OracleState.Approved);
    }

    function pauseOracle(uint256 _oracleId) external override onlyInstanceOperator {
        setOracleState(_oracleId, OracleState.Paused);
    }

    function disapproveOracle(uint256 _oracleId) external override onlyInstanceOperator {
        setOracleState(_oracleId, OracleState.Proposed);
    }

    /* Oracle Request */
    // 1->1
    function request(
        bytes32 _bpKey,
        bytes calldata _input,
        string calldata _callbackMethodName,
        address _callbackContractAddress,
        uint256 _responsibleOracleId
    ) 
        external 
        override 
        onlyPolicyFlow("Query") 
        returns (uint256 _requestId) 
    {
        // todo: validate

        _requestId = oracleRequests.length;
        oracleRequests.push();

        // todo: get token from product

        OracleRequest storage req = oracleRequests[_requestId];
        req.bpKey = _bpKey;
        req.data = _input;
        req.callbackMethodName = _callbackMethodName;
        req.callbackContractAddress = _callbackContractAddress;
        req.responsibleOracleId = _responsibleOracleId;
        req.createdAt = block.timestamp;

        IOracle(oracles[_responsibleOracleId].oracleContract).request(
            _requestId,
            _input
        );

        emit LogOracleRequested(_bpKey, _requestId, _responsibleOracleId);
    }

    /* Oracle Response */
    function respond(
        uint256 _requestId,
        address _responder,
        bytes calldata _data
    ) external override onlyOracleService isResponsibleOracle(_requestId, _responder) {
        OracleRequest storage req = oracleRequests[_requestId];

        (bool status, ) =
            req.callbackContractAddress.call(
                abi.encodeWithSignature(
                    string(
                        abi.encodePacked(
                            req.callbackMethodName,
                            "(uint256,bytes32,bytes)"
                        )
                    ),
                    _requestId,
                    req.bpKey,
                    _data
                )
            );

        // todo: send reward

        emit LogOracleResponded(req.bpKey, _requestId, _responder, status);
    }

    function getOracleRequestCount() public view returns (uint256 _count) {
        return oracleRequests.length;
    }

    function getOracleCount() external override view returns (uint256) {
        return oracleCount;
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "IQuery.sol";

contract QueryStorageModel is IQuery {

    // Oracles
    mapping(uint256 => Oracle) public oracles;
    mapping(address => uint256) public oracleIdByAddress;
    uint256 public oracleCount;

    // Requests
    OracleRequest[] public oracleRequests;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// If this interface is changed, the respective interface in the GIF Core Contracts package needs to be changed as well.
interface IOracle {
    function request(uint256 _requestId, bytes calldata _input) external;
}