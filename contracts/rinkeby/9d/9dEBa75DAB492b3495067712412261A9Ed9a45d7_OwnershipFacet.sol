// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GlobalState } from "../libraries/GlobalState.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function owner() external override view returns (address) {
        return GlobalState.getState().owner;
    }

    function isAdmin(address _addr) external view returns (bool) {
        return GlobalState.isAdmin(_addr);
    }

    function toggleAdmins(address[] calldata accounts) external {
        GlobalState.requireCallerIsAdmin();
        GlobalState.toggleAdmins(accounts);
    }

    function transferOwnership(address _newOwner) external override {
        address previousOwner = GlobalState.owner();

        require(msg.sender == previousOwner, "OwnershipFacet: caller must be contract owner");

        GlobalState.setOwner(_newOwner);

        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library GlobalState {
    // GLOBAL STORAGE //

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("globalstate.storage");

    struct state {
        address owner;
        mapping(address => bool) admins;

        bool paused;
    }

    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    // OWNERSHIP FACET // 

    function setOwner(address _newOwner) internal {
        // It is the responsibility of the facet calling
        // this function to follow ERC-173 standard
        getState().owner = _newOwner;
    }

    function owner() internal view returns (address contractOwner_) {
        contractOwner_ = getState().owner;
    }

    function isAdmin(address _addr) internal view returns (bool) {
        state storage ds = getState();
        return ds.owner == _addr || ds.admins[_addr];
    }

    function requireCallerIsAdmin() internal view {
        require(isAdmin(msg.sender), "LibDiamond: caller must be an admin");
    }

    function toggleAdmins(address[] calldata accounts) internal {
        state storage ds = getState();

        for (uint256 i; i < accounts.length; i++) {
            if (ds.admins[accounts[i]]) {
                delete ds.admins[accounts[i]];
            } else {
                ds.admins[accounts[i]] = true;
            }
        }
    }

    // ADMINPAUSE FACET //

    function paused() internal view returns (bool) {
        return getState().paused;
    }

    function togglePause() internal returns (bool) {
        bool priorStatus = getState().paused;
        getState().paused = !priorStatus;
        return !priorStatus;
    }

    function requireContractIsNotPaused() internal view {
        require(!getState().paused);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}