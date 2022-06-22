/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ENSEmojiNormalizer {
	// Emoji validation.
	struct Emoji {
		bool valid;
		bool end;
		mapping(uint24 => Emoji) sequence;
	}
	mapping(uint24 => Emoji) emojis;

	// IDNA2008 validation.
	enum Rule { DISALLOWED, VALID, CONTEXTE }
	mapping(uint24 => bytes1) idnamap;

	address public owner;
	modifier onlyOwner() {
		require(owner == msg.sender);
		_;
	}

	constructor () {
		owner = msg.sender;
		bytes memory ascii = "abcdefghijklmnopqrstuvwxyz0123456789";
		bytes memory upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		for (uint i = 0; i < ascii.length; i++) {
			idnamap[uint24(uint8(ascii[i]))] = bytes1(uint8(Rule.VALID));
			if (i < upper.length) {
				idnamap[uint24(uint8(upper[i]))] = ascii[i];
			}
		}
		idnamap[uint24(0xfe0f)] = bytes1(uint8(Rule.CONTEXTE));
	}

	function addEmoji(uint24[] calldata seq) public onlyOwner {
		Emoji storage e = emojis[seq[0]];
		e.valid = true;
		for (uint i = 1; i < seq.length; i++) {
			e = e.sequence[seq[i]];
			e.valid = true;
		}
		e.end = true;
	}

	function addRule(uint24 k, bytes1 rule) public onlyOwner {
		idnamap[k] = rule;
	}

	function namehash(string calldata domain) public view returns (string memory normalized, bytes32 node) {
		/* Process labels (in reverse order for namehash). */
		uint i = bytes(domain).length;
		uint lastDot = i;
		node = bytes32(0);
		bytes32 lh;
		string memory nl;
		for (; i > 0; i--) {
			bytes1 c = bytes(domain)[i-1];

			if (c == '.') {
				(nl, lh) = labelhash(domain[i:lastDot]);
				node = keccak256(abi.encodePacked(node, lh));
				normalized = string.concat(".", nl, normalized);
				lastDot = i-1;
				continue;
			}
		}
		(nl, lh) = labelhash(domain[0:lastDot]);
		return (string.concat(nl, normalized), keccak256(abi.encodePacked(node, lh)));
	}

	function labelhash(string calldata label) public view returns (string memory normalized, bytes32 node) {
		uint24[] memory runes = utf8decode(label);
		mapvalid(runes);

		uint hidx = 0;
		bytes memory hash = new bytes(bytes(label).length);

		uint nidx = 0;
		normalized = new string(bytes(label).length);

		uint n;
		for (uint i = 0; i < runes.length; i++) {
			n = encodeRune(runes[i], normalized, nidx);
			nidx += n;
			if (runes[i] != 0xfe0f) {
				n = encodeRune(runes[i], string(hash), hidx);
				hidx += n;
			}
		}

		assembly {
			mstore(normalized, nidx)
			node := keccak256(add(hash, 0x20), hidx)
		}
	}

	function validEmoji(uint24[] memory sequence, uint i) public view returns (uint) {
		mapping(uint24 => Emoji) storage nextMap = emojis;
		Emoji storage e = emojis[sequence[i]];
		require(e.valid, "invalid start emoji");
		uint nValid;
		for (uint j = i; j < sequence.length; j++) {
			e = nextMap[sequence[j]];
			if (!e.valid) {
				break;
			}
			if (e.end) {
				nValid = j-i+1;
			}
			nextMap = e.sequence;
		}
		require(nValid > 0, "invalid emoji sequence");
		return nValid;
	}

	function utf8decode(string calldata label) public pure returns (uint24[] memory runes) {
		uint bytelen = bytes(label).length;

		uint ridx = 0;
		runes = new uint24[](bytelen); 

		// Decode into runes.
		uint n;
		for(uint i = 0; i < bytelen; ridx++) {
			(runes[ridx], n) = decodeRune(label[i:]);
			i += n;
		}

		assembly { mstore(runes, ridx) } // trim array len
		return runes;
	}

	function utf8encode(uint24[] memory label) public pure returns (string memory s) {
		s = new string(label.length * 4);
		uint sidx = 0;
		uint n;
		for (uint i = 0; i < label.length; i++) {
			n = encodeRune(label[i], s, sidx);
			sidx += n;
		}
		assembly { mstore(s, sidx) } // trim string len
	}

	function decodeRune(string calldata label) internal pure returns (uint24 code, uint8 n) {
		uint8 b = uint8(bytes(label)[0]);
		if(b < 0x80) {
			return (uint24(uint8(b)), 1);
		} else if (b < 0xE0) {
			n = 2;
		} else if (b < 0xF0) {
			n = 3;
		} else if (b < 0xF8) {
			n = 4;
		} else {
			revert("invalid utf8");
		}

		code = uint24((0xff >> (n+1)) & b);
		for (uint i = 1; i < n; i++) {
			b = uint8(bytes(label)[i]);
			require(b & 0xc0 == 0x80, "invalid utf8");
			code = (code << 6) | (0x3f & b);
		}
	}

	function encodeRune(uint24 rune, string memory into, uint sidx) internal pure returns (uint n){
		if (rune < 0x80) {
			bytes(into)[sidx] = bytes1(uint8(rune));
			return 1;
		}
		if (rune < 0x800) {
			n = 2;
		} else if (rune < 0x10000) {
			n = 3;
		} else {
			n = 4;
		}

		bytes(into)[sidx] = bytes1(uint8((0xf0 << (4-n)) | (rune >> (6*(n-1)))));
		for (uint i = 1; i < n; i++) {
			bytes(into)[sidx+i] = bytes1(0x80 | (uint8((rune >> (6*(n-i-1)))) & 0x3f));
		}
	}

	// mapvalid accepts a utf8 decoded label and performs idna and
	// emoji validation, transforming the label in-place if characters
	// in lable are mapped.
	function mapvalid(uint24[] memory label) internal view {
		uint8 rule;
		for(uint i = 0; i < label.length;) {
			rule = uint8(idnamap[label[i]]);
			require(rule > uint8(Rule.DISALLOWED), "invalid character");
			if (rule == uint8(Rule.CONTEXTE)) {
				if (label[i] == 0xfe0f) {
					// If 0xfe0f is encountered, it means the previous
					// rune is to be processed as emoji.
					i--;
				}
				i += validEmoji(label, i); // reverts
			} else {
				if (rule != uint8(Rule.VALID)) {
					label[i] = uint24(rule);
				}
				i++;
			}
		}
	}
}