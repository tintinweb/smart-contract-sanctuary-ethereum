// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

/// @author CandideWallet Team

import "IOracle.sol";

contract TokenPriceOracle is IOracle{

    /**
     * return amount of tokens that are required to receive that much eth.
     */
    function getTokenValueOfEth(uint256 ethOutput)  external view returns (uint256 tokenInput){
			return 1;
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.12;

/// @author eth-infinitism/account-abstraction - https://github.com/eth-infinitism/account-abstraction
/// @author modified by CandideWallet Team

interface IOracle {

    /**
     * return amount of tokens that are required to receive that much eth.
     */
    function getTokenValueOfEth(uint256 ethOutput) external view returns (uint256 tokenInput);
}