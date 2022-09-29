// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * AdminPrivilegesFacet authored by Sibling Labs
 * Version 0.1.0
 * 
 * Adheres to ERC-173
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";

contract AdminPrivilegesFacet {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Returns address of contract owner. Required by
     *      ERC-173.
     */
    function owner() public view returns (address) {
        return GlobalState.getState().owner;
    }

    /**
     * @dev Transfer ownership status of this smart contract to
     *      another address. Can only be called by the current
     *      owner.
     */
    function transferOwnership(address newOwner) external {
        address previousOwner = owner();
        require(
            msg.sender == previousOwner,
            "AdminPrivilegesFacet: caller must be contract owner"
        );

        GlobalState.getState().owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @dev Returns true is the caller is the contract owner or
     *      an admin.
     */
    function isAdmin(address _addr) external view returns (bool) {
        return GlobalState.isAdmin(_addr);
    }

    /**
     * @dev Toggle admin status of a provided address.
     */
    function toggleAdmins(address[] calldata accounts) external {
        GlobalState.requireCallerIsAdmin();
        GlobalState.state storage _state = GlobalState.getState();

        for (uint256 i; i < accounts.length; i++) {
            if (_state.admins[accounts[i]]) {
                delete _state.admins[accounts[i]];
            } else {
                _state.admins[accounts[i]] = true;
            }
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