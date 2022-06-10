/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface ENS {
    function owner(bytes32 node) external view returns (address);
}

/**
 * @title ENSAsciiNormalizer
 * @author royalfork.eth
 * @notice UTS-46 normalization for ENS domains.
 */
contract ENSAsciiNormalizer {
	ENS public ens;

	// Each index in idnamap refers to an ascii code point.
	// If idnamap[char] > 2, char maps to a valid ascii character.
	// Otherwise, idna[char] returns Rule.DISALLOWED or
	// Rule.VALID.
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

    /**
     * @notice Find ENS owner of domain.
     * @param domain Domain to lookup.
	 * @return domainOwner Owner of domain.
	 * @return node Namehash of domain.
	 */
	function owner(string memory domain) external view returns (address domainOwner, bytes32 node) {
		(,node) = namehash(domain);
		return (ens.owner(node), node);
	}

    /**
     * @notice Compute namehash of domain after UTS-46 validation and
     *         normalization.  Reverts if domain is invalid, or not ASCII.
     * @param domain Domain to namehash.
	 * @return normalized Normalized domain.
	 * @return node Namehash of domain.
	 */
	function namehash(string memory domain) public view returns (string memory normalized, bytes32 node) {
		// Process labels (in reverse order for namehash).
		uint i = bytes(domain).length;
		uint lastDot = i;
		node = bytes32(0);
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

    /**
     * @notice Compute labelhash of label. This function does not perform validation/normalization.
     * @param label Label to hash.
	 * @return hash Labelhash of label.
	 */
	function labelhash(string memory label) external pure returns (bytes32 hash) {
		return labelhash(label, 0, bytes(label).length);
	}

	function labelhash(string memory domain, uint start, uint end) internal pure returns (bytes32 hash) {
		assembly ("memory-safe") {
			hash := keccak256(add(add(domain, 0x20), start), sub(end, start))
		}
	}
}