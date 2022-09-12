pragma solidity 0.8.13;
// SPDX-License-Identifier: UNLICENSED

contract AsmCounter {

    constructor() {
        assembly {
            sstore(0, 100)
            sstore(1, 200)
            sstore(2, 300)
        }
    }

    function incr(uint256 _slot, uint256 _amount) public {
        assembly {
            sstore(_slot, add(sload(_slot), _amount))
        }
    }

    function getSlot(uint256 _slot) public view returns (uint256) {
        assembly {
            mstore(0x40, sload(_slot))
            return(0x40, 32)
        }
    }

}