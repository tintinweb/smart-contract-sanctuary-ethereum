//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IOwnership} from "../../interfaces/IOwnership.sol";
import {LibOwnership} from "../../libraries/LibOwnership.sol";

/// @author Amit Molek
/// @dev Please see `IOwnership` for docs
contract OwnershipFacet is IOwnership {
    function ownershipUnits(address member)
        external
        view
        override
        returns (uint256)
    {
        return LibOwnership._ownershipUnits(member);
    }

    function totalOwnershipUnits() external view override returns (uint256) {
        return LibOwnership._totalOwnershipUnits();
    }

    function totalOwnedOwnershipUnits()
        external
        view
        override
        returns (uint256)
    {
        return LibOwnership._totalOwnedOwnershipUnits();
    }

    function isCompletelyOwned() external view override returns (bool) {
        return LibOwnership._isCompletelyOwned();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Ownership interface
/// @author Amit Molek
interface IOwnership {
    /// @return The ownership units `member` owns
    function ownershipUnits(address member) external view returns (uint256);

    /// @return The total ownership units targeted by the group members
    function totalOwnershipUnits() external view returns (uint256);

    /// @return The total ownership units owned by the group members
    function totalOwnedOwnershipUnits() external view returns (uint256);

    /// @return true if the group members owns all the targeted ownership units
    function isCompletelyOwned() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {StorageOwnershipUnits} from "../storage/StorageOwnershipUnits.sol";
import {LibState} from "../libraries/LibState.sol";
import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Please see `IOwnership` for docs
library LibOwnership {
    /// @dev Can revert:
    ///     - "Ownership: group formed": If the group state is not valid
    function _addOwner(address account, uint256 units) internal {
        // Verify that the group is still open
        require(LibState._state() == StateEnum.OPEN, "Ownership: group formed");

        // Store the owner
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        // Update the member's ownership units and the total ownership units owned
        ds.ownershipUnits[account] = units;
        ds.totalOwnedOwnershipUnits += units;
    }

    /// @dev Can revert:
    ///     - "Ownership: group formed": If the group state is not valid
    ///     - "Ownership: not an owner": If the caller is not a group member
    function _renounceOwnership() internal returns (uint256 refund) {
        // Verify that the group is still open
        require(LibState._state() == StateEnum.OPEN, "Ownership: group formed");

        // Verify that the caller is a member
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();
        require(ds.ownershipUnits[msg.sender] > 0, "Ownership: not an owner");

        // Update the member ownership units and the total units owned
        refund = ds.ownershipUnits[msg.sender];
        ds.totalOwnedOwnershipUnits -= refund;
        delete ds.ownershipUnits[msg.sender];
    }

    function _ownershipUnits(address member) internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits[member];
    }

    function _totalOwnershipUnits() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.totalOwnershipUnits;
    }

    function _smallestUnit() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.smallestOwnershipUnit;
    }

    function _totalOwnedOwnershipUnits() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.totalOwnedOwnershipUnits;
    }

    function _isCompletelyOwned() internal view returns (bool) {
        return _totalOwnedOwnershipUnits() == _totalOwnershipUnits();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {StorageState} from "../storage/StorageState.sol";
import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Contract/Group state
library LibState {
    /// @dev Emits on event change
    /// @param from the previous event
    /// @param to the new event
    event StateChanged(StateEnum from, StateEnum to);

    /// @dev Changes the state of the contract/group
    /// Can revert:
    ///     - "State: same state": When changing the state to the same one
    /// Emits `StateChanged` event
    /// @param state the new state
    function _changeState(StateEnum state) internal {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();
        require(ds.state != state, "State: same state");

        ds.state = state;

        emit StateChanged(ds.state, state);
    }

    /// @return the current state of the contract/group
    function _state() internal view returns (StateEnum) {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();

        return ds.state;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Diamond compatible storage for ownership units of members
library StorageOwnershipUnits {
    struct DiamondStorage {
        /// @dev Smallest ownership unit
        uint256 smallestOwnershipUnit;
        /// @dev Total ownership units
        uint256 totalOwnershipUnits;
        /// @dev Amount of ownership units that are owned by members.
        /// join -> adding | leave -> subtracting
        /// This is used in the join process to know when the group is fully funded
        uint256 totalOwnedOwnershipUnits;
        /// @dev Maps between member and their ownership units
        mapping(address => uint256) ownershipUnits;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.OwnershipUnits");

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

    function _initStorage(
        uint256 smallestOwnershipUnit,
        uint256 totalOwnershipUnits
    ) internal {
        require(
            smallestOwnershipUnit > 0,
            "Storage: smallest ownership unit must be bigger than 0"
        );
        require(
            totalOwnershipUnits % smallestOwnershipUnit == 0,
            "Storage: total units not divisible by smallest unit"
        );

        DiamondStorage storage ds = diamondStorage();

        ds.smallestOwnershipUnit = smallestOwnershipUnit;
        ds.totalOwnershipUnits = totalOwnershipUnits;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

    function _initStorage() internal {
        DiamondStorage storage ds = diamondStorage();
        ds.state = StateEnum.OPEN;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek

/// @dev State of the contract/group
enum StateEnum {
    OPEN,
    FORMED
}