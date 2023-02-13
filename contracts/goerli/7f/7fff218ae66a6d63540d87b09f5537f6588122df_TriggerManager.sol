// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import {Owned} from "solmate/auth/Owned.sol";
import {ITriggerable} from "./interfaces/ITriggerable.sol";

/// @author philogy <https://github.com/philogy>
contract TriggerManager is Owned {
    address public trigger;

    event TriggerChanged(address indexed prevTrigger, address indexed newTrigger);

    error NotAuthorizedTrigger();

    constructor(address _initialOwner, address _initialTrigger) Owned(_initialOwner) {
        emit TriggerChanged(address(0), trigger = _initialTrigger);
    }

    function setTrigger(address _newTrigger) external onlyOwner {
        emit TriggerChanged(trigger, _newTrigger);
        trigger = _newTrigger;
    }

    function executeTriggerOf(address _target) external {
        if (msg.sender != trigger && msg.sender != owner) revert NotAuthorizedTrigger();
        ITriggerable(_target).executeEmergencyTrigger();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/// @author philogy <https://github.com/philogy>
interface ITriggerable {
    function executeEmergencyTrigger() external;
}