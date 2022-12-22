// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * AdminPauseFacet authored by Sibling Labs
 * Version 0.2.0
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";

contract AdminPauseFacet {
    event Paused(address account);
    event Unpaused(address account);

    /**
    * @dev Returns bool indicating whether or not the contract
    *      is paused.
    */
    function paused() external view returns (bool) {
        return GlobalState.getState().paused;
    }

    /**
    * @dev Toggles paused status of contract. Only callable by
    *      admins.
    */
    function togglePause() external {
        GlobalState.requireCallerIsAdmin();
        
        bool prior = GlobalState.getState().paused;
        GlobalState.getState().paused = !prior;
        if (prior) {
            emit Unpaused(msg.sender);
        } else {
            emit Paused(msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Global Storage Library for NFT Smart Contracts
 * Authored by Sibling Labs
 * Version 0.2.1
 * 
 * This library is designed to provide diamond storage and
 * shared functionality to all facets of a diamond used for an
 * NFT collection.
/**************************************************************/

library GlobalState {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("globalstate.storage");

    struct state {
        address owner;
        mapping(address => bool) admins;

        bool paused;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }

    // GLOBAL FUNCTIONS //

    /**
    * @dev Returns true if provided address is an admin or the
    *      contract owner.
    */
    function isAdmin(address _addr) internal view returns (bool) {
        state storage s = getState();
        return s.owner == _addr || s.admins[_addr];
    }

    /**
    * @dev Reverts if caller is not an admin or contract owner.
    */
    function requireCallerIsAdmin() internal view {
        require(isAdmin(msg.sender), "GlobalState: caller is not admin or owner");
    }

    /**
    * @dev Reverts if contract is paused.
    */
    function requireContractIsNotPaused() internal view {
        require(!getState().paused || isAdmin(msg.sender), "GlobalState: contract is paused");
    }
}