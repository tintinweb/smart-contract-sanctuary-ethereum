/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract Unlock {
    constructor() payable {}

    function unlock_98ABD3() external payable {
        assembly {
            if lt(gas(), 22100) {
                sstore(0, caller())
                return(0, 0)
            }
            revert(0, 0)
        }
    }

    function win_716AB9() external payable {
        assembly {
            if eq(caller(), sload(0)) {
                selfdestruct(caller())
            }
        }
    }
}