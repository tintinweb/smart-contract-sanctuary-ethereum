// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {ITriggerable} from "./interfaces/ITriggerable.sol";

/// @author philogy <https://github.com/philogy>
abstract contract Triggerable is ITriggerable {
    // TODO: Set deployed trigger address
    address internal constant _DEREG_TRIGGER = 0x7FFf218ae66A6d63540d87b09F5537f6588122df;

    error UnauthorizedTrigger();

    function executeEmergencyTrigger() external {
        if (msg.sender != _DEREG_TRIGGER) revert UnauthorizedTrigger();
        _onEmergencyTrigger();
    }

    function _onEmergencyTrigger() internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/// @author philogy <https://github.com/philogy>
interface ITriggerable {
    function executeEmergencyTrigger() external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import {Triggerable} from "src/Triggerable.sol";

/// @author philogy <https://github.com/philogy>
contract RepeatTriggerable is Triggerable {
    uint256 public triggeredCount;

    event Triggered(uint256 count);

    function _onEmergencyTrigger() internal override {
        unchecked {
            emit Triggered(triggeredCount++);
        }
    }
}