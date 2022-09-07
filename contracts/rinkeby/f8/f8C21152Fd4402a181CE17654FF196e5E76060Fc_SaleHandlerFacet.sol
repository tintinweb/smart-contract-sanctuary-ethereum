// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * SaleHandlerFacet authored by Sibling Labs
 * Version 0.2.0
/**************************************************************/

import { GlobalState } from "../libraries/GlobalState.sol";
import { SaleHandlerLib } from "../libraries/SaleHandlerLib.sol";

contract SaleHandlerFacet {
    /**
    * @dev Get length of private sale in seconds.
    */
    function privSaleLength() external view returns (uint256) {
        return SaleHandlerLib.getState().privSaleLength;
    }

    /**
    * @dev Get length of public sale in seconds.
    */
    function publicSaleLength() external view returns (uint256) {
        return SaleHandlerLib.getState().publicSaleLength;
    }

    /**
    * @dev Get timestamp when sale begins.
    */
    function saleTimestamp() external view returns (uint256) {
        return SaleHandlerLib.getState().saleTimestamp;
    }

    /**
     * @dev Begin the private sale. The private sale will
     *      automatically begin, and the public sale will
     *      automatically begin after the private sale
     *      has concluded.
     */
    function beginPrivSale() external {
        GlobalState.requireCallerIsAdmin();
        SaleHandlerLib.getState().saleTimestamp = block.timestamp;
    }

    /**
     * @dev Set the exact time when the private sale will begin.
     */
    function setSaleTimestamp(uint256 timestamp) external {
        GlobalState.requireCallerIsAdmin();
        SaleHandlerLib.getState().saleTimestamp = timestamp;
    }

    /**
    * @dev Updates private sale length. Length argument must be
    *      a whole number of hours.
    */
    function setPrivSaleLengthInHours(uint256 length) external {
        GlobalState.requireCallerIsAdmin();
        SaleHandlerLib.getState().privSaleLength = length * 3600;
    }

    /**
    * @dev Updates public sale length. Length argument must be
    *      a whole number of hours.
    */
    function setPublicSaleLengthInHours(uint256 length) external {
        GlobalState.requireCallerIsAdmin();
        SaleHandlerLib.getState().publicSaleLength = length * 3600;
    }

    /**
    * @dev Returns a boolean indicating whether the private sale
    *      phase is currently active.
    */
    function isPrivSaleActive() external view returns (bool) {
        return SaleHandlerLib.isPrivSaleActive();
    }

    /**
    * @dev Returns whether the public sale is currently
    *      active.
    */
    function isPublicSaleActive() external view returns (bool) {
        return SaleHandlerLib.isPublicSaleActive();
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * SaleHandlerLib authored by Sibling Labs
 * Version 0.2.0
 * 
 * This library is designed to work in conjunction with
 * SaleHandlerFacet - it facilitates diamond storage and shared
 * functionality associated with SaleHandlerFacet.
/**************************************************************/

library SaleHandlerLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("salehandlerlibrary.storage");

    struct state {
        uint256 privSaleLength;
        uint256 publicSaleLength;
        uint256 saleTimestamp;
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

    /**
    * @dev Returns a boolean indicating whether the private sale
    *      phase is currently active.
    */
    function isPrivSaleActive() internal view returns (bool) {
        state storage s = getState();
        return
            s.saleTimestamp != 0 &&
            block.timestamp >= s.saleTimestamp &&
            block.timestamp < s.saleTimestamp + s.privSaleLength;
    }

    /**
    * @dev Returns whether the public sale is currently
    *      active. If the publicSaleLength variable is
    *      set to 0, the public sale will continue
    *      forever.
    */
    function isPublicSaleActive() internal view returns (bool) {
        state storage s = getState();
        return
            s.saleTimestamp != 0 &&
            block.timestamp >= s.saleTimestamp + s.privSaleLength &&
            (
                block.timestamp < s.saleTimestamp + s.privSaleLength + s.publicSaleLength ||
                s.publicSaleLength == 0
            );
    }

    /**
    * @dev Reverts if the private sale is not active. Use this
    *      function as needed in other facets to ensure that
    *      particular functions may only be called during the
    *      private sale.
    */
    function requirePrivSaleIsActive() internal view {
        require(isPrivSaleActive(), "SaleHandlerFacet: private sale is not active now");
    }

    /**
    * @dev Reverts if the public sale is not active. Use this
    *      function as needed in other facets to ensure that
    *      particular functions may only be called during the
    *      public sale.
    */
    function requirePublicSaleIsActive() internal view {
        require(isPublicSaleActive(), "SaleHandlerFacet: public sale is not active now");
    }
}