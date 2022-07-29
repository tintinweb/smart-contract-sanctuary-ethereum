// SPDX-License-Identifier: AGPL-3.0-or-later

/// AutomationBotAggregator.sol

// Copyright (C) 2022 Oazo Apps Limited

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



contract AutomationBotAggregator {


    function addTriggerGroup(
        uint256 groupId,
        uint16 groupType,
        uint256 cdpId,
        uint256[] memory triggerIds
    ) external  {

emit TriggerAdded(triggerIds[0], 0x000000000000000000000000000000000000dEaD, cdpId, "0x000");
emit TriggerAdded(triggerIds[1], 0x000000000000000000000000000000000000dEaD, cdpId, "0x001");

        emit TriggerGroupAdded(groupId, groupType, cdpId, triggerIds);
    }

    function removeTriggerGroup(
        uint256 cdpId,
        uint256 groupId,
        uint256[] memory triggerIds

    ) external  {
emit TriggerRemoved(cdpId, triggerIds[0]);
emit TriggerRemoved(cdpId, triggerIds[1]);
       emit TriggerGroupRemoved(groupId, cdpId);
    }

    function replaceGroupTrigger(
        uint256 groupId,
        uint256 cdpId,
        
        uint256 newTriggerId,
        uint256 oldTriggerId,
        uint256 triggerType
    ) external  {
        emit TriggerRemoved(cdpId, oldTriggerId);
        emit TriggerAdded(newTriggerId, 0x000000000000000000000000000000000000dEaD, cdpId, "0x000");
   emit TriggerGroupUpdated(groupId, cdpId, newTriggerId, triggerType);
    }


    event TriggerGroupAdded(
        uint256 indexed groupId,
        uint16 indexed groupType,
        uint256 indexed cdpId,
        uint256[] triggerIds
    );

    event TriggerGroupRemoved(uint256 indexed groupId, uint256 indexed cdpId);

    event TriggerGroupUpdated(
        uint256 indexed groupId,
        uint256 indexed cdpId,
        uint256 newTriggerId,
        uint256 triggerType
    );
        event TriggerAdded(
        uint256 indexed triggerId,
        address indexed commandAddress,
        uint256 indexed cdpId,
        bytes triggerData
    );

        event TriggerRemoved(uint256 indexed cdpId, uint256 indexed triggerId);
}