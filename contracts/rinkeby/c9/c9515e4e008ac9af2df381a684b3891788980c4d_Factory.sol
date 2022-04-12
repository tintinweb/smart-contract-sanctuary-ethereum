/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

contract Factory {
    event Deployed(address addr);

	function deploy() public returns(address) {
        address addr;
		addr = address(new Sample{salt: '0x72616e646f6d'}(256));
        emit Deployed(addr);
        return addr;
	}
}

contract Sample {
	uint256 private x;

	constructor(uint256 defaultX) {
		x = defaultX;
	}

	function setValue(uint256 _x) public returns(uint256) {
		x = _x;
		return x;
	}

	function getValue() public view returns(uint256) {
		return x;
	}
}