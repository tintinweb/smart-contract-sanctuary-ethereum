// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/errors/Exception.sol";

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        if (false) {
            revert Exception(0, 0, 0, address(0), address(0));
        }
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

/// @dev A single custom error capable of indicating a wide range of detected errors by providing
/// an error code value whose string representation is documented <here>, and any possible other values
/// that are pertinent to the error.
error Exception(uint8, uint256, uint256, address, address);