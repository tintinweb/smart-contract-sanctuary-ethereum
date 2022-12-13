// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { INonTransparentProxy } from "./interfaces/INonTransparentProxy.sol";

contract NonTransparentProxy is INonTransparentProxy {

    bytes32 private constant ADMIN_SLOT          = bytes32(uint256(keccak256("eip1967.proxy.admin"))          - 1);
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    constructor(address admin_, address implementation_) {
        _setAddress(ADMIN_SLOT,          admin_);
        _setAddress(IMPLEMENTATION_SLOT, implementation_);
    }

    /******************************************************************************************************************************/
    /*** Admin Functions                                                                                                        ***/
    /******************************************************************************************************************************/

    function setImplementation(address newImplementation_) override external {
        require(msg.sender == _admin(), "NTP:SI:NOT_ADMIN");
        _setAddress(IMPLEMENTATION_SLOT, newImplementation_);
    }

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    function _admin() internal view returns (address admin_) {
        admin_ = _getAddress(ADMIN_SLOT);
    }

    function _implementation() internal view returns (address implementation_) {
        implementation_ = _getAddress(IMPLEMENTATION_SLOT);
    }

    /******************************************************************************************************************************/
    /*** Utility Functions                                                                                                      ***/
    /******************************************************************************************************************************/

    function _setAddress(bytes32 slot_, address value_) private {
        assembly {
            sstore(slot_, value_)
        }
    }

    function _getAddress(bytes32 slot_) private view returns (address value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    /******************************************************************************************************************************/
    /*** Fallback Function                                                                                                      ***/
    /******************************************************************************************************************************/

    fallback() external {
        address implementation_ = _implementation();

        require(implementation_.code.length != 0, "NTP:F:NO_CODE_ON_IMPLEMENTATION");

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface INonTransparentProxy {

    /**
     *  @dev   Sets the implementation address.
     *  @param newImplementation_ The address to set the implementation to.
     */
    function setImplementation(address newImplementation_) external;

}