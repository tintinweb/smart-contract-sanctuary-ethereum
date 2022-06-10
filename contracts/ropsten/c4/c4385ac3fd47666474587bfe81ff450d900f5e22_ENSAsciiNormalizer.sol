/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ENS {
    function owner(bytes32 node) external view returns (address);
}

contract ENSAsciiNormalizer {
	ENS public ens;

	// Each index in idnamap refers to an ascii code point.
	// If idnamap[char] > 2, char maps to a valid ascii character.
	// Otherwise, idna[char] tells whether char is valid within
	// an ENS domain.
	bytes1[] public idnamap;
	enum Rule { DISALLOWED, VALID }

	constructor (ENS _ens, bytes memory asciimap) {
		ens = _ens;
		for(uint i = 0; i < asciimap.length; i += 2) {
			bytes1 r = asciimap[i+1];
			for(uint8 j = 0; j < uint8(asciimap[i]); j++) {
				idnamap.push(r);
			}
		}
	}

	function lookup(string memory domain) external view returns (address owner, bytes32 node) {
		(,node) = namehash(domain);
		owner = ens.owner(node);
	}

	function namehash(string memory domain) public view returns (string memory, bytes32) {
		// Process labels (in reverse order for namehash).
		uint i = bytes(domain).length;
		uint lastDot = i;
		bytes32 node = bytes32(0);
		for (; i > 0; i--) {
			bytes1 c = bytes(domain)[i-1];

			if (c == '.') {
				node = keccak256(abi.encodePacked(node, labelhash(domain, i, lastDot)));
				lastDot = i-1;
				continue;
			}

			require(c < 0x80);
			bytes1 r = idnamap[uint8(c)];
			require(uint8(r) != uint8(Rule.DISALLOWED));
			if (uint8(r) > 1) {
				bytes(domain)[i-1] = r;
			}
		}
		return (domain, keccak256(abi.encodePacked(node, labelhash(domain, i, lastDot))));
	}

	function labelhash(string memory label) external pure returns (bytes32 hash) {
		return labelhash(label, 0, bytes(label).length);
	}

	function labelhash(string memory domain, uint start, uint end) internal pure returns (bytes32 hash) {
		assembly ("memory-safe") {
			hash := keccak256(add(add(domain, 0x20), start), sub(end, start))
		}
	}
}