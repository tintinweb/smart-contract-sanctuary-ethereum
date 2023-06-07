// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity  ^0.8.16;

import "./BlockTimestamp.sol";

contract Demo is BlockTimestamp {
    function currentBlockNumber() public view returns(uint256) {
        return _blockTimestamp();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity  ^0.8.16;

/// @title Function for getting block timestamp
/// @dev Base contract that is overridden for tests
abstract contract BlockTimestamp {
    /// @dev Method that exists purely to be overridden for tests
    /// @return The current block timestamp
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}