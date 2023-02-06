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