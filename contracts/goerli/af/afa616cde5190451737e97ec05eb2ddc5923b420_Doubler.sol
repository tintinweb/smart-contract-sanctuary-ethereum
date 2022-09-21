// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./Counter.sol";
import "src/errors/Exception.sol";

//error Exception(uint8, uint256, uint256, address, address);

contract Doubler {
    Counter c;
    uint256 public number;

    constructor(uint256 n) {
        c = new Counter();
        number = n;
    }

    function double() external authorized(address(0)) {
        if (number == 431) {
            revert Exception(10, 0, number, address(this), address(0));
        }
        number = number * 2;
    }

    /// @notice ensures that only a certain address can call the function
    /// @param a address that msg.sender must be to be authorized
    modifier authorized(address a) {
        if (msg.sender != a) {
            revert Exception(0, 0, 0, msg.sender, a);
        }
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "src/errors/Exception.sol";

contract Counter {
    uint256 public number;

    constructor() {
        number = 100;
    }

    function setNumber(uint256 newNumber) public {
        if (true) {
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