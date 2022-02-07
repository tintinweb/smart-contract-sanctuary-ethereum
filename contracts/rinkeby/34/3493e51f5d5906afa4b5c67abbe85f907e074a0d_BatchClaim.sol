/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract BatchClaim {
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
	bytes miniProxy;			  // = 0x363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3;
    address private immutable original;
	
	constructor() {
		miniProxy = bytes.concat(bytes10(0x363d3d373d3d3d363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
        original = address(this);
	}

	function batchClaim(address token, uint times) external {
		bytes memory bytecode = miniProxy;
		address proxy;
		for(uint i=0; i<times; i++) {
			assembly {
				proxy := create(0, add(bytecode, 32), mload(bytecode))
			}
			BatchClaim(proxy).claim(token);
		}
	}

	function claim(address token) external {
		IClaimableToken(token).claim();
		IClaimableToken(token).transfer(tx.origin, IClaimableToken(token).balanceOf(address(this)));
		if(address(this) != original)			// proxy delegatecall
			selfdestruct(payable(tx.origin));
	}

}

interface IClaimableToken {
	function claim() external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}