// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * ERC165Lib authored by Sibling Labs
 * Version 0.1.0
 * 
 * This library is designed to work in conjunction with
 * ERC165Facet - it facilitates diamond storage and shared
 * functionality associated with ERC165Facet.
/**************************************************************/

library ERC165Lib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("erc165.storage");

    struct state {
        mapping(bytes4 => bool) supportedInterfaces;
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
}

/**************************************************************\
 * ERC165Facet authored by Sibling Labs
 * Version 0.1.0
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";

contract ERC165Facet {
    /**
    * @dev Called by marketplaces to query support for smart
    *      contract interfaces. Required by ERC165.
    */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return ERC165Lib.getState().supportedInterfaces[_interfaceId];
    }

    /**
    * @dev Toggle support for bytes4 interface selector.
    */
    function toggleInterfaceSupport(bytes4 selector) external {
        GlobalState.requireCallerIsAdmin();

        if (ERC165Lib.getState().supportedInterfaces[selector]) {
            delete ERC165Lib.getState().supportedInterfaces[selector];
        } else {
            ERC165Lib.getState().supportedInterfaces[selector] = true;
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