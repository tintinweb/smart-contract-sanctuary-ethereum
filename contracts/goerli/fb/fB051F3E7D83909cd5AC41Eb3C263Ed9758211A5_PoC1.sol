// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* CHEATSHEET FOR EXPLOIT */
//address attacker = address(0xDEAD);
//vm.deal(1 ether);
//import "src/token.sol"; replace with the following contracts
//bytes32[] memory proofs = new bytes32[](2);
//proofs[0] = 0xbc36789e7a1e281436464229828f817d6612f7b477d66591ff96a9e064bcc98a;
//proofs[1] = 0xb5eee5709f4ddc918174ebd471ea5bc9c054287866f66749ec91441ffdf9c308;
//	(bool sent, bytes memory data) = address(0).call{ value: s.value }("");
//emit log_string(" ----------------------- Attack Timeline ----------------------------------");
//emit log_named_address("1. The Attacker deployed MevSec Token to this address ", address(T));
//bytes memory innerPayload = abi.encodeWithSelector(bytes4(0xa9059cbb), bytes32(uint256(uint160(address(address(this))))), bytes32(uint256(3 ether)));

contract PoC1 {
	address owner;
	address constant test = 0x2222222222222222222222222222222222222222;

	constructor() {
		owner = 0x1111111111111111111111111111111111111111;
	}
}