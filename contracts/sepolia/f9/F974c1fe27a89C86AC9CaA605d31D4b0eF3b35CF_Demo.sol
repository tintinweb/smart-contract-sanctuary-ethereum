// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity  ^0.8.16;

import '../libraries/ChainId.sol';

contract Demo {
    function currentChainID() public view returns(uint256) {
        return ChainId.get();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Function for getting the current chain ID
library ChainId {
    /// @dev Gets the current chain ID
    /// @return chainId The current chain ID
    function get() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}