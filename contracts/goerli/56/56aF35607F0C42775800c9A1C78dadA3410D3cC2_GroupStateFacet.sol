//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibState} from "../../libraries/LibState.sol";
import {IGroupState} from "../../interfaces/IGroupState.sol";
import {StateEnum} from "../../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Please see `IGroupState` for docs
contract GroupStateFacet is IGroupState {
    function state() external view override returns (StateEnum) {
        return LibState._state();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StateEnum} from "../structs/StateEnum.sol";

/// @title Group state interface
/// @author Amit Molek
interface IGroupState {
    /// @dev Emits on event change
    /// @param from the previous event
    /// @param to the new event
    event StateChanged(StateEnum from, StateEnum to);

    /// @return the current state of the contract/group
    function state() external view returns (StateEnum);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageState} from "../storage/StorageState.sol";
import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Contract/Group state
library LibState {
    string public constant INVALID_STATE_ERR = "State: Invalid state";

    event StateChanged(StateEnum from, StateEnum to);

    /// @dev Changes the state of the contract/group
    /// Can revert:
    ///     - "State: same state": When changing the state to the same one
    /// Emits `StateChanged` event
    /// @param state the new state
    function _changeState(StateEnum state) internal {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();
        require(ds.state != state, "State: same state");

        emit StateChanged(ds.state, state);

        ds.state = state;
    }

    function _state() internal view returns (StateEnum) {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();

        return ds.state;
    }

    /// @dev reverts if `state` is not the current contract state
    function _stateGuard(StateEnum state) internal view {
        require(_state() == state, INVALID_STATE_ERR);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for group state
library StorageState {
    struct DiamondStorage {
        /// @dev State of the group
        StateEnum state;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.State");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek

/// @dev State of the contract/group
enum StateEnum {
    UNINITIALIZED,
    OPEN,
    FORMED
}