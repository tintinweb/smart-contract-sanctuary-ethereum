// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// AutomationBot.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import "./interfaces/ICommand.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/BotLike.sol";
import "./AutomationBotStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AutomationBot is BotLike, ReentrancyGuard {
    struct TriggerRecord {
        bytes32 triggerHash;
        address commandAddress;
        bool continuous;
    }

    uint16 private constant SINGLE_TRIGGER_GROUP_TYPE = 2 ** 16 - 1;
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT_V2";
    string private constant AUTOMATION_EXECUTOR_KEY = "AUTOMATION_EXECUTOR_V2";

    ServiceRegistry public immutable serviceRegistry;
    AutomationBotStorage public immutable automationBotStorage;
    address public immutable self;
    uint256 private lockCount;

    constructor(ServiceRegistry _serviceRegistry, AutomationBotStorage _automationBotStorage) {
        serviceRegistry = _serviceRegistry;
        automationBotStorage = _automationBotStorage;
        self = address(this);
        lockCount = 0;
    }

    modifier auth(address caller) {
        require(
            serviceRegistry.getRegisteredService(AUTOMATION_EXECUTOR_KEY) == caller,
            "bot/not-executor"
        );
        _;
    }

    modifier onlyDelegate() {
        require(address(this) != self, "bot/only-delegate");
        _;
    }

    // works correctly in any context
    function getCommandAddress(uint256 triggerType) public view returns (address) {
        bytes32 commandHash = keccak256(abi.encode("Command", triggerType));

        address commandAddress = serviceRegistry.getServiceAddress(commandHash);

        return commandAddress;
    }

    function getAdapterAddress(
        address commandAddress,
        bool isExecute
    ) public view returns (address) {
        require(commandAddress != address(0), "bot/unknown-trigger-type");
        bytes32 adapterHash = isExecute
            ? keccak256(abi.encode("AdapterExecute", commandAddress))
            : keccak256(abi.encode("Adapter", commandAddress));
        address service = serviceRegistry.getServiceAddress(adapterHash);
        return service;
    }

    function clearLock() external {
        lockCount = 0;
    }

    // works correctly in any context
    function getTriggersHash(
        bytes memory triggerData,
        address commandAddress
    ) private view returns (bytes32) {
        bytes32 triggersHash = keccak256(
            abi.encodePacked(triggerData, serviceRegistry, commandAddress)
        );

        return triggersHash;
    }

    // works correctly in context of Automation Bot
    function checkTriggersExistenceAndCorrectness(
        uint256 triggerId,
        address commandAddress,
        bytes memory triggerData
    ) private view {
        (bytes32 triggersHash, , ) = automationBotStorage.activeTriggers(triggerId);
        require(
            triggersHash != bytes32(0) &&
                triggersHash == getTriggersHash(triggerData, commandAddress),
            "bot/invalid-trigger"
        );
    }

    // works correctly in context of automationBot
    function addRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        uint256 triggerType,
        bool continuous,
        uint256 replacedTriggerId,
        bytes memory triggerData,
        bytes memory replacedTriggerData
    ) external {
        lock();

        address commandAddress = getCommandAddress(triggerType);
        if (replacedTriggerId != 0) {
            (bytes32 replacedTriggersHash, address originalCommandAddress, ) = automationBotStorage
                .activeTriggers(replacedTriggerId);
            ISecurityAdapter originalAdapter = ISecurityAdapter(
                getAdapterAddress(originalCommandAddress, false)
            );
            require(
                originalAdapter.canCall(replacedTriggerData, msg.sender),
                "bot/no-permissions-replace"
            );
            require(
                replacedTriggersHash ==
                    getTriggersHash(replacedTriggerData, originalCommandAddress),
                "bot/invalid-trigger"
            );
        }

        require(
            ICommand(commandAddress).isTriggerDataValid(continuous, triggerData),
            "bot/invalid-trigger-data"
        );

        ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
        require(adapter.canCall(triggerData, msg.sender), "bot/no-permissions");

        automationBotStorage.appendTriggerRecord(
            AutomationBotStorage.TriggerRecord(
                getTriggersHash(triggerData, commandAddress),
                commandAddress,
                continuous
            )
        );

        if (replacedTriggerId != 0) {
            clearTrigger(replacedTriggerId);
            emit TriggerRemoved(replacedTriggerId);
        }

        emit TriggerAdded(
            automationBotStorage.triggersCounter(),
            commandAddress,
            continuous,
            triggerType,
            triggerData
        );
    }

    // works correctly in context of automationBot
    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        // msg.sender should be dsProxy
        bytes memory triggerData,
        uint256 triggerId
    ) external {
        (, address commandAddress, ) = automationBotStorage.activeTriggers(triggerId);
        ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
        require(adapter.canCall(triggerData, msg.sender), "no-permit");
        checkTriggersExistenceAndCorrectness(triggerId, commandAddress, triggerData);

        clearTrigger(triggerId);
        emit TriggerRemoved(triggerId);
    }

    function clearTrigger(uint256 triggerId) private {
        automationBotStorage.updateTriggerRecord(
            triggerId,
            AutomationBotStorage.TriggerRecord(0, 0x0000000000000000000000000000000000000000, false)
        );
    }

    // works correctly in context of dsProxy
    function addTriggers(
        uint16 groupType,
        bool[] memory continuous,
        uint256[] memory replacedTriggerId,
        bytes[] memory triggerData,
        bytes[] memory replacedTriggerData,
        uint256[] memory triggerTypes
    ) external onlyDelegate {
        require(
            replacedTriggerId.length == replacedTriggerData.length &&
                triggerData.length == triggerTypes.length &&
                triggerTypes.length == continuous.length &&
                continuous.length == triggerData.length,
            "bot/invalid-input-length"
        );

        address automationBot = serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
        AutomationBot(automationBot).clearLock();

        if (groupType != SINGLE_TRIGGER_GROUP_TYPE) {
            IValidator validator = getValidatorAddress(groupType);
            require(
                validator.validate(continuous, replacedTriggerId, triggerData),
                "aggregator/validation-error"
            );
        }

        uint256 firstTriggerId = automationBotStorage.triggersCounter() + 1;
        uint256[] memory triggerIds = new uint256[](triggerData.length);

        for (uint256 i = 0; i < triggerData.length; i++) {
            ISecurityAdapter adapter = ISecurityAdapter(
                getAdapterAddress(getCommandAddress(triggerTypes[i]), false)
            );

            if (i == 0) {
                (bool status, ) = address(adapter).delegatecall(
                    abi.encodeWithSelector(
                        adapter.permit.selector,
                        triggerData[i],
                        address(automationBotStorage),
                        true
                    )
                );
                require(status, "bot/permit-failed-add");
                emit ApprovalGranted(triggerData[i], address(automationBotStorage));
            }

            AutomationBot(automationBot).addRecord(
                triggerTypes[i],
                continuous[i],
                replacedTriggerId[i],
                triggerData[i],
                replacedTriggerData[i]
            );

            triggerIds[i] = firstTriggerId + i;
        }

        AutomationBot(automationBot).emitGroupDetails(groupType, triggerIds);
    }

    function unlock() private {
        //To keep addRecord && emitGroupDetails atomic
        require(lockCount > 0, "bot/not-locked");
        lockCount = 0;
    }

    function lock() private {
        //To keep addRecord && emitGroupDetails atomic
        lockCount++;
    }

    function emitGroupDetails(uint16 triggerGroupType, uint256[] memory triggerIds) external {
        require(lockCount == triggerIds.length, "bot/group-inconsistent");
        unlock();

        emit TriggerGroupAdded(
            automationBotStorage.triggersGroupCounter(),
            triggerGroupType,
            triggerIds
        );
        automationBotStorage.increaseGroupCounter();
    }

    function getValidatorAddress(uint16 groupType) public view returns (IValidator) {
        bytes32 validatorHash = keccak256(abi.encode("Validator", groupType));
        return IValidator(serviceRegistry.getServiceAddress(validatorHash));
    }

    //works correctly in context of dsProxy
    function removeTriggers(
        uint256[] memory triggerIds,
        bytes[] memory triggerData,
        bool removeAllowance
    ) external onlyDelegate {
        require(triggerData.length > 0, "bot/remove-at-least-one");
        require(triggerData.length == triggerIds.length, "bot/invalid-input-length");

        address automationBot = serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
        AutomationBot(automationBot).clearLock();
        (, address commandAddress, ) = automationBotStorage.activeTriggers(triggerIds[0]);

        for (uint256 i = 0; i < triggerIds.length; i++) {
            removeTrigger(triggerIds[i], triggerData[i]);
        }

        if (removeAllowance) {
            ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
            (bool status, ) = address(adapter).delegatecall(
                abi.encodeWithSelector(
                    adapter.permit.selector,
                    triggerData[0],
                    address(automationBotStorage),
                    false
                )
            );

            require(status, "bot/permit-removal-failed");
            emit ApprovalRemoved(triggerData[0], address(automationBotStorage));
        }
    }

    function removeTrigger(uint256 triggerId, bytes memory triggerData) private {
        address automationBot = serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY);
        BotLike(automationBot).removeRecord(triggerData, triggerId);
    }

    //works correctly in context of automationBot
    function execute(
        bytes calldata executionData,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 coverageAmount,
        address coverageToken
    ) external auth(msg.sender) nonReentrant {
        checkTriggersExistenceAndCorrectness(triggerId, commandAddress, triggerData);
        ICommand command = ICommand(commandAddress);

        require(command.isExecutionLegal(triggerData), "bot/trigger-execution-illegal");
        ISecurityAdapter adapter = ISecurityAdapter(getAdapterAddress(commandAddress, false));
        IExecutableAdapter executableAdapter = IExecutableAdapter(
            getAdapterAddress(commandAddress, true)
        );

        automationBotStorage.executeCoverage(
            triggerData,
            msg.sender,
            address(executableAdapter),
            coverageToken,
            coverageAmount
        );
        {
            automationBotStorage.executePermit(triggerData, commandAddress, address(adapter), true);
        }
        {
            command.execute(executionData, triggerData); //command must be whitelisted
            (, , bool continuous) = automationBotStorage.activeTriggers(triggerId);
            if (!continuous) {
                clearTrigger(triggerId);
                emit TriggerRemoved(triggerId);
            }
        }
        {
            automationBotStorage.executePermit(
                triggerData,
                commandAddress,
                address(adapter),
                false
            );
            require(command.isExecutionCorrect(triggerData), "bot/trigger-execution-wrong");
        }

        emit TriggerExecuted(triggerId, executionData);
    }

    event ApprovalRemoved(bytes indexed triggerData, address approvedEntity);

    event ApprovalGranted(bytes indexed triggerData, address approvedEntity);

    event TriggerRemoved(uint256 indexed triggerId);

    event TriggerAdded(
        uint256 indexed triggerId,
        address indexed commandAddress,
        bool continuous,
        uint256 triggerType,
        bytes triggerData
    );

    event TriggerExecuted(uint256 indexed triggerId, bytes executionData);
    event TriggerGroupAdded(
        uint256 indexed groupId,
        uint16 indexed groupType,
        uint256[] triggerIds
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// AutomationBotStorage.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

import "./interfaces/IAdapter.sol";
import "./ServiceRegistry.sol";

contract AutomationBotStorage {
    string private constant AUTOMATION_BOT_KEY = "AUTOMATION_BOT_V2";
    uint64 private constant COUNTER_OFFSET = 10 ** 10;

    struct TriggerRecord {
        bytes32 triggerHash;
        address commandAddress; // or type ? do we allow execution of the same command with new contract - waht if contract rev X is broken ? Do we force migration (can we do it)?
        bool continuous;
    }

    struct Counters {
        uint64 triggersCounter;
        uint64 triggersGroupCounter;
    }

    mapping(uint256 => TriggerRecord) public activeTriggers;

    Counters public counter;

    ServiceRegistry public immutable serviceRegistry;

    constructor(ServiceRegistry _serviceRegistry) {
        serviceRegistry = _serviceRegistry;
        counter.triggersCounter = COUNTER_OFFSET;
        counter.triggersGroupCounter = COUNTER_OFFSET + 1;
    }

    modifier auth(address caller) {
        require(
            serviceRegistry.getRegisteredService(AUTOMATION_BOT_KEY) == caller,
            "bot-storage/not-automation-bot"
        );
        _;
    }

    function increaseGroupCounter() external auth(msg.sender) {
        counter.triggersGroupCounter++;
    }

    function triggersCounter() external view returns (uint256) {
        return uint256(counter.triggersCounter);
    }

    function triggersGroupCounter() external view returns (uint256) {
        return uint256(counter.triggersGroupCounter);
    }

    function updateTriggerRecord(
        uint256 id,
        TriggerRecord memory record
    ) external auth(msg.sender) {
        activeTriggers[id] = record;
    }

    function appendTriggerRecord(TriggerRecord memory record) external auth(msg.sender) {
        counter.triggersCounter++;
        activeTriggers[counter.triggersCounter] = record;
    }

    function executePermit(
        bytes memory triggerData,
        address target,
        address adapter,
        bool allowance
    ) external auth(msg.sender) {
        (bool status, ) = adapter.delegatecall(
            abi.encodeWithSelector(ISecurityAdapter.permit.selector, triggerData, target, allowance)
        );
        require(status, "bot-storage/permit-failed");
    }

    function executeCoverage(
        bytes memory triggerData,
        address receiver,
        address adapter,
        address coverageToken,
        uint256 coverageAmount
    ) external auth(msg.sender) {
        (bool status, ) = adapter.delegatecall(
            abi.encodeWithSelector(
                IExecutableAdapter.getCoverage.selector,
                triggerData,
                receiver,
                coverageToken,
                coverageAmount
            )
        );
        require(status, "bot-storage/failed-to-draw-coverage");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface BotLike {
    function addRecord(
        uint256 triggerType,
        bool continuous,
        uint256 replacedTriggerId,
        bytes memory triggerData,
        bytes memory replacedTriggerData
    ) external;

    function removeRecord(
        // This function should be executed allways in a context of AutomationBot address not DsProxy,
        //msg.sender should be dsProxy
        bytes memory triggersData,
        uint256 triggerId
    ) external;

    function execute(
        bytes calldata executionData,
        bytes calldata triggerData,
        address commandAddress,
        uint256 triggerId,
        uint256 coverageAmount,
        address coverageToken
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// IAdapter.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

interface ISecurityAdapter {
    function canCall(bytes memory triggerData, address operator) external returns (bool);

    function permit(bytes memory triggerData, address target, bool allowance) external;
}

interface IExecutableAdapter {
    function getCoverage(
        bytes memory triggerData,
        address receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICommand {
    function isTriggerDataValid(
        bool continuous,
        bytes memory triggerData
    ) external view returns (bool);

    function isExecutionCorrect(bytes memory triggerData) external view returns (bool);

    function isExecutionLegal(bytes memory triggerData) external view returns (bool);

    function execute(bytes calldata executionData, bytes memory triggerData) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IValidator {
    function validate(
        bool[] memory continuous,
        uint256[] memory replacedTriggerId,
        bytes[] memory triggersData
    ) external view returns (bool);

    function decode(
        bytes[] memory triggersData
    ) external view returns (uint256[] calldata cdpIds, uint256[] calldata triggerTypes);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// ServiceRegistry.sol

// Copyright (C) 2021-2021 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.0;

contract ServiceRegistry {
    uint256 public constant MAX_DELAY = 30 days;

    mapping(bytes32 => uint256) public lastExecuted;
    mapping(bytes32 => address) private namedService;
    address public owner;
    uint256 public requiredDelay;

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
            emit ChangeScheduled(operationHash, block.timestamp + reqDelay, msg.data);
        } else {
            require(
                block.timestamp - reqDelay > lastExecuted[operationHash],
                "registry/delay-too-small"
            );
            emit ChangeApplied(operationHash, block.timestamp, msg.data);
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
        require(initialDelay <= MAX_DELAY, "registry/invalid-delay");
        requiredDelay = initialDelay;
        owner = msg.sender;
    }

    function transferOwnership(
        address newOwner
    ) external onlyOwner validateInput(36) delayedExecution {
        owner = newOwner;
    }

    function changeRequiredDelay(
        uint256 newDelay
    ) external onlyOwner validateInput(36) delayedExecution {
        require(newDelay <= MAX_DELAY, "registry/invalid-delay");
        requiredDelay = newDelay;
    }

    function getServiceNameHash(string memory name) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }

    function addNamedService(
        bytes32 serviceNameHash,
        address serviceAddress
    ) external onlyOwner validateInput(68) delayedExecution {
        require(namedService[serviceNameHash] == address(0), "registry/service-override");
        namedService[serviceNameHash] = serviceAddress;
    }

    function updateNamedService(
        bytes32 serviceNameHash,
        address serviceAddress
    ) external onlyOwner validateInput(68) delayedExecution {
        require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
        namedService[serviceNameHash] = serviceAddress;
    }

    function removeNamedService(bytes32 serviceNameHash) external onlyOwner validateInput(36) {
        require(namedService[serviceNameHash] != address(0), "registry/service-does-not-exist");
        namedService[serviceNameHash] = address(0);
        emit NamedServiceRemoved(serviceNameHash);
    }

    function getRegisteredService(string memory serviceName) external view returns (address) {
        return namedService[keccak256(abi.encodePacked(serviceName))];
    }

    function getServiceAddress(bytes32 serviceNameHash) external view returns (address) {
        return namedService[serviceNameHash];
    }

    function clearScheduledExecution(
        bytes32 scheduledExecution
    ) external onlyOwner validateInput(36) {
        require(lastExecuted[scheduledExecution] > 0, "registry/execution-not-scheduled");
        lastExecuted[scheduledExecution] = 0;
        emit ChangeCancelled(scheduledExecution);
    }

    event ChangeScheduled(bytes32 dataHash, uint256 scheduledFor, bytes data);
    event ChangeApplied(bytes32 dataHash, uint256 appliedAt, bytes data);
    event ChangeCancelled(bytes32 dataHash);
    event NamedServiceRemoved(bytes32 nameHash);
}