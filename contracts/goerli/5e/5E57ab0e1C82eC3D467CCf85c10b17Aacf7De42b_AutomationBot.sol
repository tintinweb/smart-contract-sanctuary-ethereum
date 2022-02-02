//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/ManagerLike.sol";
import "./interfaces/ICommand.sol";
import "./interfaces/BotLike.sol";
import "./ServiceRegistry.sol";

contract AutomationBot {
    string private constant CDP_MANAGER_KEY = "CDP_MANAGER";
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT";
    string private constant AUTOMATION_EXECUTOR_KEY = "AUTOMATION_EXECUTOR";

    mapping(uint256 => bytes32) public existingTriggers;

    uint256 public triggersCounter = 0;

    address public immutable serviceRegistry;

    constructor(address _serviceRegistry) {
        serviceRegistry = _serviceRegistry;
    }

    modifier auth(address caller) {
        require(
            ServiceRegistry(serviceRegistry).getRegisteredService(AUTOMATION_EXECUTOR_KEY) ==
                caller,
            "bot/not-executor"
        );
        _;
    }

    // works correctly in any context
    function validatePermissions(
        uint256 cdpId,
        address operator,
        ManagerLike manager
    ) private view {
        require(isCdpOwner(cdpId, operator, manager), "bot/no-permissions");
    }

    // works correctly in any context
    function isCdpAllowed(
        uint256 cdpId,
        address operator,
        ManagerLike manager
    ) public view returns (bool) {
        address cdpOwner = manager.owns(cdpId);
        return (manager.cdpCan(cdpOwner, cdpId, operator) == 1 || operator == cdpOwner);
    }

    // works correctly in any context
    function isCdpOwner(
        uint256 cdpId,
        address operator,
        ManagerLike manager
    ) private view returns (bool) {
        return (operator == manager.owns(cdpId));
    }

    // works correctly in any context
    function getCommandAddress(uint256 triggerType) public view returns (address) {
        bytes32 commandHash = keccak256(abi.encode("Command", triggerType));

        address commandAddress = ServiceRegistry(serviceRegistry).getServiceAddress(commandHash);

        return commandAddress;
    }

    // works correctly in any context
    function getTriggersHash(
        uint256 cdpId,
        bytes memory triggerData,
        address commandAddress
    ) private view returns (bytes32) {
        bytes32 triggersHash = keccak256(
            abi.encodePacked(cdpId, triggerData, serviceRegistry, commandAddress)
        );

        return triggersHash;
    }

    // works correctly in context of Automation Bot
    function checkTriggersExistenceAndCorrectness(
        uint256 cdpId,
        uint256 triggerId,
        address commandAddress,
        bytes memory triggerData
    ) private view {
        bytes32 triggersHash = existingTriggers[triggerId];

        require(
            triggersHash != bytes32(0) &&
                triggersHash == getTriggersHash(cdpId, triggerData, commandAddress),
            "bot/invalid-trigger"
        );
    }

    // works correctly in context of automationBot
    function addRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        uint256 cdpId,
        uint256 triggerType,
        bytes memory triggerData
    ) external {
        address managerAddress = ServiceRegistry(serviceRegistry).getRegisteredService(
            CDP_MANAGER_KEY
        );

        address commandAddress = getCommandAddress(triggerType);

        validatePermissions(cdpId, msg.sender, ManagerLike(managerAddress));

        triggersCounter = triggersCounter + 1;
        existingTriggers[triggersCounter] = getTriggersHash(cdpId, triggerData, commandAddress);

        emit TriggerAdded(triggersCounter, commandAddress, cdpId, triggerData);
    }

    // works correctly in context of automationBot
    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        uint256 cdpId,
        uint256 triggerId,
        address commandAddress,
        bytes memory triggerData
    ) external {
        address managerAddress = ServiceRegistry(serviceRegistry).getRegisteredService(
            CDP_MANAGER_KEY
        );

        validatePermissions(cdpId, msg.sender, ManagerLike(managerAddress));

        checkTriggersExistenceAndCorrectness(cdpId, triggerId, commandAddress, triggerData);

        existingTriggers[triggerId] = bytes32(0);
        emit TriggerRemoved(cdpId, triggerId);
    }

    //works correctly in context of dsProxy
    function addTrigger(
        uint256 cdpId,
        uint256 triggerType,
        // solhint-disable-next-line no-unused-vars
        bytes memory triggerData
    ) external {
        // TODO: consider adding isCdpAllow add flag in tx payload, make sense from extensibility perspective
        address managerAddress = ServiceRegistry(serviceRegistry).getRegisteredService(
            CDP_MANAGER_KEY
        );
        ManagerLike manager = ManagerLike(managerAddress);
        address automationBot = ServiceRegistry(serviceRegistry).getRegisteredService(
            AUTOMATION_BOT_KEY
        );
        BotLike(automationBot).addRecord(cdpId, triggerType, triggerData);
        if (isCdpAllowed(cdpId, automationBot, manager) == false) {
            manager.cdpAllow(cdpId, automationBot, 1);
            emit ApprovalGranted(cdpId, automationBot);
        }
    }

    //works correctly in context of dsProxy

    // TODO: removeAllowance parameter of this method moves responsibility to decide on this to frontend.
    // In case of a bug on frontend allowance might be revoked by setting this parameter to `true`
    // despite there still be some active triggers which will be disables by this call.
    // One of the solutions is to add counter of active triggers and revoke allowance only if last trigger is being deleted

    function removeTrigger(
        uint256 cdpId,
        uint256 triggerId,
        address commandAddress,
        bool removeAllowence,
        bytes memory triggerData
    ) external {
        address managerAddress = ServiceRegistry(serviceRegistry).getRegisteredService(
            CDP_MANAGER_KEY
        );
        ManagerLike manager = ManagerLike(managerAddress);

        address automationBot = ServiceRegistry(serviceRegistry).getRegisteredService(
            AUTOMATION_BOT_KEY
        );

        BotLike(automationBot).removeRecord(cdpId, triggerId, commandAddress, triggerData);

        if (removeAllowence) {
            manager.cdpAllow(cdpId, automationBot, 0);
            emit ApprovalRemoved(cdpId, automationBot);
        }

        emit TriggerRemoved(cdpId, triggerId);
    }

    //works correctly in context of dsProxy
    function removeApproval(address _serviceRegistry, uint256 cdpId) external {
        address managerAddress = ServiceRegistry(_serviceRegistry).getRegisteredService(
            CDP_MANAGER_KEY
        );
        ManagerLike manager = ManagerLike(managerAddress);
        address automationBot = ServiceRegistry(_serviceRegistry).getRegisteredService(
            AUTOMATION_BOT_KEY
        );
        validatePermissions(cdpId, address(this), manager);
        manager.cdpAllow(cdpId, automationBot, 0);
        emit ApprovalRemoved(cdpId, automationBot);
    }

    //works correctly in context of automationBot
    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId
    ) external auth(msg.sender) {
        checkTriggersExistenceAndCorrectness(cdpId, triggerId, commandAddress, triggerData);
        ICommand command = ICommand(commandAddress);

        require(command.isExecutionLegal(cdpId, triggerData), "bot/trigger-execution-illegal");

        address managerAddress = ServiceRegistry(serviceRegistry).getRegisteredService(
            CDP_MANAGER_KEY
        );
        ManagerLike manager = ManagerLike(managerAddress);
        manager.cdpAllow(cdpId, address(command), 1);
        command.execute(executionData, cdpId, triggerData);
        manager.cdpAllow(cdpId, address(command), 0);

        require(command.isExecutionCorrect(cdpId, triggerData), "bot/trigger-execution-wrong");

        emit TriggerExecuted(triggerId, executionData);
    }

    event ApprovalRemoved(uint256 indexed cdpId, address approvedEntity);

    event ApprovalGranted(uint256 indexed cdpId, address approvedEntity);

    event TriggerRemoved(uint256 indexed cdpId, uint256 indexed triggerId);

    event TriggerAdded(
        uint256 indexed triggerId,
        address indexed commandAddress,
        uint256 indexed cdpId,
        bytes triggerData
    );

    event TriggerExecuted(uint256 indexed triggerId, bytes executionData);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ManagerLike {
    function cdpCan(
        address owner,
        uint256 cdpId,
        address allowedAddr
    ) external view returns (uint256);

    function ilks(uint256) external view returns (bytes32);

    function owns(uint256) external view returns (address);

    function urns(uint256) external view returns (address);

    function cdpAllow(
        uint256 cdp,
        address usr,
        uint256 ok
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICommand {
    function isExecutionCorrect(uint256 cdpId, bytes memory triggerData)
        external
        view
        returns (bool);

    function isExecutionLegal(uint256 cdpId, bytes memory triggerData) external view returns (bool);

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes memory triggerData
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface BotLike {
    function addRecord(
        uint256 cdpId,
        uint256 triggerType,
        bytes memory triggerData
    ) external;

    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        //msg.sender should be dsProxy
        uint256 cdpId,
        uint256 triggerId,
        address commandAddress,
        bytes memory triggerData
    ) external;

    function execute(
        bytes calldata executionData,
        uint256 cdpId,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ServiceRegistry {
    mapping(bytes32 => uint256) public lastExecuted;
    mapping(address => bool) private trustedAddresses;
    mapping(bytes32 => address) private namedService;
    address public owner;

    uint256 public requiredDelay = 1800; // big enough that any power of miner over timestamp does not matter

    modifier validateInput(uint256 len) {
        require(msg.data.length == len, "registry/illegal-padding");
        _;
    }

    modifier delayedExecution() {
        bytes32 operationHash = keccak256(msg.data);
        uint256 reqDelay = requiredDelay;

        /* solhint-disable not-rely-on-time */
        if (lastExecuted[operationHash] == 0 && reqDelay > 0) {
            // not called before, scheduled for execution
            lastExecuted[operationHash] = block.timestamp;
            emit ChangeScheduled(msg.data, operationHash, block.timestamp + reqDelay);
        } else {
            require(
                block.timestamp - reqDelay > lastExecuted[operationHash],
                "registry/delay-too-small"
            );
            emit ChangeApplied(msg.data, block.timestamp);
            _;
            lastExecuted[operationHash] = 0;
        }
        /* solhint-enable not-rely-on-time */
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "registry/only-owner");
        _;
    }

    constructor(uint256 initialDelay) {
        require(initialDelay < type(uint256).max, "registry/risk-of-overflow");
        requiredDelay = initialDelay;
        owner = msg.sender;
    }

    function transferOwnership(address newOwner)
        external
        onlyOwner
        validateInput(36)
        delayedExecution
    {
        owner = newOwner;
    }

    function changeRequiredDelay(uint256 newDelay)
        external
        onlyOwner
        validateInput(36)
        delayedExecution
    {
        requiredDelay = newDelay;
    }

    function addTrustedAddress(address trustedAddress)
        external
        onlyOwner
        validateInput(36)
        delayedExecution
    {
        trustedAddresses[trustedAddress] = true;
    }

    function removeTrustedAddress(address trustedAddress) external onlyOwner validateInput(36) {
        trustedAddresses[trustedAddress] = false;
    }

    function isTrusted(address testedAddress) external view returns (bool) {
        return trustedAddresses[testedAddress];
    }

    function getServiceNameHash(string memory name) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function addNamedService(bytes32 serviceNameHash, address serviceAddress)
        external
        onlyOwner
        validateInput(68)
        delayedExecution
    {
        require(namedService[serviceNameHash] == address(0), "registry/service-override");
        namedService[serviceNameHash] = serviceAddress;
    }

    function updateNamedService(bytes32 serviceNameHash, address serviceAddress)
        external
        onlyOwner
        validateInput(68)
        delayedExecution
    {
        require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
        namedService[serviceNameHash] = serviceAddress;
    }

    function removeNamedService(bytes32 serviceNameHash) external onlyOwner validateInput(36) {
        require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
        namedService[serviceNameHash] = address(0);
        emit RemoveApplied(serviceNameHash);
    }

    function getRegisteredService(string memory serviceName) external view returns (address) {
        return namedService[keccak256(abi.encodePacked(serviceName))];
    }

    function getServiceAddress(bytes32 serviceNameHash) external view returns (address) {
        return namedService[serviceNameHash];
    }

    function clearScheduledExecution(bytes32 scheduledExecution)
        external
        onlyOwner
        validateInput(36)
    {
        require(lastExecuted[scheduledExecution] > 0, "registry/execution-not-scheduled");
        lastExecuted[scheduledExecution] = 0;
        emit ChangeCancelled(scheduledExecution);
    }

    event ChangeScheduled(bytes data, bytes32 dataHash, uint256 firstPossibleExecutionTime);
    event ChangeCancelled(bytes32 data);
    event ChangeApplied(bytes data, uint256 firstPossibleExecutionTime);
    event RemoveApplied(bytes32 nameHash);
}