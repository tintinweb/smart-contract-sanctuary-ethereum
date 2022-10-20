/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File contracts/v1.5/Fractions.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

contract Fractions
{
	fallback () external payable
	{
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), 0x55F35C41fd9bA8227Ea33E1590C2DD59945ADF6B, 0, calldatasize(), 0, 0) // replace 2nd parameter by FractionsImpl address on deploy
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}
}