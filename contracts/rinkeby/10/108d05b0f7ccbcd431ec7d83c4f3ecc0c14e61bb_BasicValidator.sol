// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./IValidator.sol";

contract BasicValidator is IValidator {
	
    function validate(uint24[] memory cps) public pure {
        unchecked { 
            for (uint256 i; i < cps.length; i++) {
                if (!isValidCodepoint(cps[i])) revert();
            }
        }
    }

    function isValidCodepoint(uint256 x) public pure returns (bool) {
        return (x >= 0x61 && x <= 0x7A) // a-z
            || (x >= 0x30 && x <= 0x39) // 0-9
            || x == 0x2D // -
            || x == 0x2E // .
            || x == 0x5F // _
            || x > 0x10FFFF; // filtered
    }
    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IValidator {
    function validate(uint24[] memory cps) external view;
}