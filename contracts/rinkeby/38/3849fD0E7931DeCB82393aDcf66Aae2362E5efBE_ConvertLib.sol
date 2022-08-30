/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// A library is like a contract with reusable code, which can be called by other contracts.
// Deploying common code can reduce gas costs.
library ConvertLib{
	function convert(uint amount, uint conversionRate) public pure returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}
}