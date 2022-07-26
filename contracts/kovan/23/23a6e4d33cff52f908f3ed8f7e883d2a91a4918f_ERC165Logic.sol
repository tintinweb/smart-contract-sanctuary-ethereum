// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC165Logic.sol";
import { ERC165State, ERC165Storage } from "./ERC165Storage.sol";

/**
 * @dev Standalone implementation of a global ERC165 interface detector.
 *
 * Provides ERC165 functionalities to any contract without it needing to
 * implement ERC165 itself.
 * 
 * Allows it to be re-used by both Extensions and Extendables.
 */
contract ERC165Logic is IERC165, IERC165Register {
    /**
     * @dev Records its own contract address during construction
     */
    address private self;
    constructor() {
        self = address(this);
    }

    /**
     * @dev Restricts calls to functions using this modifier to only come from
     * delegatecalls.
     */
    modifier onlyDelegated {
        require(address(this) != self, "ERC165Logic: undelegated calls disallowed");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) override(IERC165) public onlyDelegated virtual returns (bool) {
        ERC165State storage state = ERC165Storage._getState();
        return state._supportedInterfaces[interfaceId] || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     * - should only be callable by other extensions of the same contract
     */
    function registerInterface(bytes4 interfaceId) override(IERC165Register) public onlyDelegated {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");

        ERC165State storage state = ERC165Storage._getState();
        state._supportedInterfaces[interfaceId] = true;
    }
}