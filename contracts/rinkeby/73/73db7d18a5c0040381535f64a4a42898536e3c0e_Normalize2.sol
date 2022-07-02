// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";

error InvalidCodepoint(uint256 cp);

contract Normalize2 is Ownable {

	mapping (uint256 => uint256) _emoji;
	mapping (uint256 => uint256) _valid;
	mapping (uint256 => uint256) _small; // 1-2 cp
	mapping (uint256 => uint256) _large; // 3-6 cp

	function updateMapping(mapping (uint256 => uint256) storage map, bytes calldata data, uint256 key_bytes) private {
		uint256 i;
		uint256 e;
		uint256 mask = (1 << (key_bytes << 3)) - 1;
		assembly {
			i := data.offset
			e := add(i, data.length)
		}
		while (i < e) {
			uint256 k;
			uint256 v;
			assembly {
				// key-value pairs are packed in reverse 
				// eg. [value1][key1][value2][key2]...
				v := calldataload(i)
				i := add(i, key_bytes)
				k := and(calldataload(i), mask)
				i := add(i, 32)
			}
			map[k] = v;
		}
	}

	function uploadEmoji(bytes calldata data) public onlyOwner {
		updateMapping(_emoji, data, 4);
	}
	function updateValid(bytes calldata data) public onlyOwner {
		updateMapping(_valid, data, 2);
	}
	function updateSmall(bytes calldata data) public onlyOwner {
		updateMapping(_small, data, 3);
	}
	function updateLarge(bytes calldata data) public onlyOwner {
		updateMapping(_large, data, 3);
	}

	function isValid(uint256 cp) private view returns (bool) {
		// Floor[cp/256] => array: bit[256]
		// array[cp%256] => bit: valid
		return ((_valid[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}

	function getSmall(uint256 cp) private view returns (uint256) {
		// Floor[cp/4] => array: uint32[4]
		// array[cp%4] => [unused: (16 bits), cps1: (24 bits), cps0: (24 bits)]
		// eg. "B"  => [0, B]
		// eg. "XY" => [X, Y]  
		return (_small[cp >> 2] >> ((cp & 0x3) << 6)) & 0xFFFFFFFFFFFFFFFF;
	}

	function getLarge(uint256 cp) private view returns (uint256) {
		// Floor[cp/2] => array: uint128[2] 
		// array[cp%2] => [extra_len: (2 bits), cps: 6x(21 bits)]
		// where len = 3 + extra_len
		// where cps = codepoints stored backwards
		// eg. "ABCD" => [0b01, [0, 0, D, C, B, A]] , 3 + 1 = 4 
		return (_large[cp >> 1] >> ((cp & 0x1) << 7)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
	}
	
	function debugEmoji(uint256 s0, uint256 cp) public view returns (uint256 value, bool fe0f, bool check, bool save, bool valid, uint256 s1) {
		// (state0, Floor[cp/16]) => array: uint32[16]
		// array[cp%16] => [flags: (4 bits), state1: (12 bits)]
		value = (_emoji[((s0 & 0xFFF) << 20) | (cp >> 4)] >> ((cp & 0xF) << 4)) & 0xFFFF;
		fe0f  = (value & 0x8000) != 0; // can an FE0F follow
		check = (value & 0x4000) != 0; // should we compare to saved cp
		save  = (value & 0x2000) != 0; // should we save cp
		valid = (value & 0x1000) != 0; // is the sequence valid so far
		s1 = value & 0xFFF; // next state
	}

	function debugMapping(uint256 cp) public view returns (uint24[] memory cps) {
		if (isValid(cp)) {
			cps = new uint24[](1);
			cps[0] = uint24(cp);
		} else if (isIgnored(cp)) {
			// ignored
		} else {
			uint256 mapped = getMapped(cp);
			if (mapped != 0) {
				cps = new uint24[](1);
				cps[0] = uint24(cp);
			} else {
				mapped = getSmall(cp);
				if (mapped != 0) {
					if (mapped < 0xFFFFFF) {
						cps = new uint24[](1);
						cps[0] = uint24(mapped);
					} else {
						cps = new uint24[](2);
						cps[0] = uint24(mapped >> 24);
						cps[1] = uint24(mapped);
					}
				} else {
					mapped = getLarge(cp);
					if (mapped != 0) {
						uint256 len = 3 + (mapped >> 126);
						cps = new uint24[](len);
						for (uint256 i; i < len; i++) {
							cps[i] = uint24(mapped & 0x1FFFFF);
							mapped >>= 21;
						}
					} else {
						revert InvalidCodepoint(cp);
					}
				}
			}
		}
	}

	// read one cp from memory at ptr
	// step is number of encoded bytes (1-4)
	// raw is encoded bytes
	// warning: assumes valid UTF8
	function readUTF8(uint256 ptr) private pure returns (uint256 cp, uint256 step, uint256 raw) {
		// 0xxxxxxx => 1 :: 0aaaaaaa ???????? ???????? ???????? => 00aaaaaa
		// 110xxxxx => 2 :: 110aaaaa 10bbbbbb ???????? ???????? => 00000aaa aabbbbbb
		// 1110xxxx => 3 :: 1110aaaa 10bbbbbb 10cccccc ???????? => 000000aa aaaabbbb bbcccccc
		// 11110xxx => 4 :: 11110aaa 10bbbbbb 10cccccc 10dddddd => 000aaabb bbbbcccc ccdddddd
		assembly {
			raw := and(mload(add(ptr, 4)), 0xFFFFFFFF)
		}
		uint256 upper = raw >> 28;
		if (upper < 0x8) {
			step = 1;
			raw >>= 24;
			cp = raw;
		} else if (upper < 0xE) {
			step = 2;
			raw >>= 16;
			cp = ((raw & 0x1F00) >> 2) | (raw & 0x3F);
		} else if (upper < 0xF) {
			step = 3;
			raw >>= 8;
			cp = ((raw & 0x0F0000) >> 4) | ((raw & 0x3F00) >> 2) | (raw & 0x3F);
		} else {
			step = 4;
			cp = ((raw & 0x07000000) >> 6) | ((raw & 0x3F0000) >> 4) | ((raw & 0x3F00) >> 2) | (raw & 0x3F);
		}
	}

	// write len lower-bytes of buf at ptr
	// return ptr advanced by len
	function appendBytes(uint256 ptr, uint256 buf, uint256 len) private pure returns (uint256 ptr1) {
		assembly {
			ptr1 := add(ptr, len) // advance by len bytes
			let word := mload(ptr1) // load right-aligned word
			let mask := sub(shl(shl(3, len), 1), 1) // compute len-byte mask: 1 << (len << 3) - 1
			mstore(ptr1, or(and(word, not(mask)), and(buf, mask))) // merge and store
		}
	}

	// encode cp as utf8 into buf at len, shifting old input left
	// returns new buf and len
	// warning: buf is only 32 bytes
	function appendUTF8(uint256 buf0, uint256 len0, uint256 cp) private pure returns (uint256 buf, uint256 len) {
		if (cp < 0x80) {
			buf = (buf0 << 8) | cp;
			len = len0 + 1;
		} else if (cp < 0x800) {
			buf = (buf0 << 16) | (0xC080 | (((cp << 2) & 0x1F00) | (cp & 0x003F)));
			len = len0 + 2;
		} else if (cp < 0x10000) {
			buf = (buf0 << 24) | (0xE08080 | (((cp << 4) & 0x0F0000) | ((cp << 2) & 0x003F00) | (cp & 0x00003F)));
			len = len0 + 3;
		} else {
			buf = (buf0 << 32) | (0xF0808080 | (((cp << 6) & 0x07000000) | ((cp << 4) & 0x003F0000) | ((cp << 2) & 0x00003F00) | (cp & 0x0000003F)));
			len = len0 + 4;
		}
	}

	// restore FE0F in emoji sequences at proper locations
	function beautify(string memory name) public view returns (string memory nice) {
		bytes memory buf = new bytes(bytes(name).length * 3); // FE0F as UTF is 3 bytes
		uint256 src;
		uint256 end;
		uint256 dst;
		assembly {
			src := name
			end := add(name, mload(name))
			dst := buf
		}
		while (src < end) {
			(uint256 src1, uint256 dst1) = processEmoji(src, end, dst, true);
			if (dst != dst1) {
				src = src1;
				dst = dst1;
			} else {
				(, uint256 step, uint256 raw) = readUTF8(src);
				dst = appendBytes(dst, raw, step);
				src += step;
			}
		}
		assembly {
			mstore(buf, sub(dst, buf))
		}
		nice = string(buf);
	}

	function normalize(string memory name) public view returns (string memory norm) {
		bytes memory buf = new bytes(bytes(name).length * 6); // largest expansion factor is 6x
		uint256 src;
		uint256 end;
		uint256 dst;
		assembly {
			src := name
			end := add(name, mload(name))
			dst := buf
		}
		while (src < end) {
			(uint256 src1, uint256 dst1) = processEmoji(src, end, dst, false);
			if (dst != dst1) { // valid emoji
				src = src1;
				dst = dst1; 
				continue;
			}
			(uint256 cp, uint256 step, uint256 raw) = readUTF8(src);
			if (isValid(cp)) {
				src += step;
				dst = appendBytes(dst, raw, step);
				continue;
			}
			if (isIgnored(cp)) {
				src += step;
				continue;
			}
			uint256 mapped = getMapped(cp);
			if (mapped != 0) {
				src += step;                
				(raw, step) = appendUTF8(0, 0, mapped);
				dst = appendBytes(dst, raw, step);
				continue;
			}
			mapped = getSmall(cp);
			if (mapped != 0) {
				src += step;
				(raw, step) = appendUTF8(0, 0, mapped & 0xFFFFFF);
				if (mapped > 0xFFFFFF) {
					(raw, step) = appendUTF8(raw, step, mapped);
				}
				dst = appendBytes(dst, raw, step);
				continue;
			}
			mapped = getLarge(cp);
			if (mapped == 0) revert InvalidCodepoint(cp);
			src += step;
			uint256 len = 2 + (mapped >> 126);
			(raw, step) = appendUTF8(0, 0, mapped & 0x1FFFFF);
			while (--len > 0) {
				mapped >>= 21;
				(raw, step) = appendUTF8(raw, step, mapped & 0x1FFFFF);
			}
		}
		assembly {
			mstore(buf, sub(dst, buf))
		}
		norm = string(buf);
	}

	function processEmoji(uint256 pos, uint256 end, uint256 dst0, bool include_fe0f) private view returns (uint256 valid_pos, uint256 dst) {
		unchecked {
			uint256 state;
			uint256 fe0f;
			uint256 saved;
			uint256 buf; // the largest emoji is 35 bytes, which exceeds 32-byte buf
			uint256 len; // but the largest non-valid emoji sequence is only 27-bytes
			dst = dst0;
			while (pos < end) {
				(uint256 cp, uint256 step, uint256 raw) = readUTF8(pos);
				if (cp == 0xFE0F) {
					if (fe0f == 0) break; // invalid FEOF
					fe0f = 0; // clear flag to prevent more
					pos += step; // skip over FE0F
					if (len == 0) { // last was valid so
						valid_pos = pos; // consume FE0F as well
					}
				} else {
					state = (_emoji[((state & 0xFFF) << 20) | (cp >> 4)] >> ((cp & 0xF) << 4)) & 0xFFFF;
					if (state == 0) break;
					pos += step; 
					len += step; 
					buf = (buf << (step << 3)) | raw; // use raw instead of converting cp back to UTF8
					fe0f = state & 0x8000; // allow FEOF next?
					if (include_fe0f && fe0f != 0) { // forcibily insert a FE0F
						// (buf, len) = appendUTF8(buf, len, 0xFE0F);
						buf = (buf << 24) | 0xEFB88F; // UTF8-encoded
						len += 3;
					}
					if ((state & 0x1000) != 0) { // valid
						dst = appendBytes(dst, buf, len);
						buf = 0;
						len = 0;
						valid_pos = pos; // everything output so far is valid
					} 
					if ((state & 0x4000) != 0) { // check?
						if (cp == saved) break;
					} else if ((state & 0x2000) != 0) { // save?
						saved = cp; // save cp for later
					}
				}
			}
		}
	}

	function debugDecode(string memory s) public pure returns (uint24[] memory cps) {   
		uint256 src;
		uint256 end;
		assembly {
			src := s
			end := add(s, mload(s))
		}
		uint256 len;
		cps = new uint24[](bytes(s).length);
		while (src < end) {
			(uint256 cp, uint256 step, ) = readUTF8(src);
			cps[len++] = uint24(cp);
			src += step;
		}
		assembly {
			mstore(cps, len)
		}
	}

	// auto-generated
	function isIgnored(uint256 cp) private pure returns (bool) {
		if (cp < 0x2064) {
			return cp == 0xAD || cp == 0x200B || cp == 0x2060 || cp == 0x2064;
		} else if (cp < 0x1BCA0) {
			return cp == 0xFE0E || cp == 0xFE0F || cp == 0xFEFF;
		} else {
			return cp >= 0x1BCA0 && cp <= 0x1BCA3;
		}
	}

	// auto-generated
	function getMapped(uint256 cp) private pure returns (uint256 ret) {
		if (cp <= 0x556) {
			if (cp >= 0x41 && cp <= 0x5A) { // Mapped11: 26
				ret = cp + 0x20;
			} else if (cp >= 0x246 && cp < 0x250 && (cp & 1 == 0)) { // Mapped22: 5
				ret = cp + 1;
			} else if (cp >= 0x391 && cp <= 0x3A1) { // Mapped11: 17
				ret = cp + 0x20;
			} else if (cp >= 0x3A3 && cp <= 0x3A9) { // Mapped11: 7
				ret = cp + 0x20;
			} else if (cp >= 0x3D8 && cp < 0x3F0 && (cp & 1 == 0)) { // Mapped22: 12
				ret = cp + 1;
			} else if (cp >= 0x3FD && cp <= 0x3FF) { // Mapped11: 3
				ret = cp - 0x82;
			} else if (cp >= 0x404 && cp <= 0x406) { // Mapped11: 3
				ret = cp + 0x50;
			} else if (cp >= 0x408 && cp <= 0x40B) { // Mapped11: 4
				ret = cp + 0x50;
			} else if (cp >= 0x410 && cp <= 0x418) { // Mapped11: 9
				ret = cp + 0x20;
			} else if (cp >= 0x41A && cp <= 0x42F) { // Mapped11: 22
				ret = cp + 0x20;
			} else if (cp >= 0x460 && cp < 0x476 && (cp & 1 == 0)) { // Mapped22: 11
				ret = cp + 1;
			} else if (cp >= 0x478 && cp < 0x482 && (cp & 1 == 0)) { // Mapped22: 5
				ret = cp + 1;
			} else if (cp >= 0x48A && cp < 0x4C0 && (cp & 1 == 0)) { // Mapped22: 27
				ret = cp + 1;
			} else if (cp >= 0x4C3 && cp < 0x4CF && (cp & 1 == 0)) { // Mapped22: 6
				ret = cp + 1;
			} else if (cp >= 0x4FA && cp < 0x530 && (cp & 1 == 0)) { // Mapped22: 27
				ret = cp + 1;
			} else if (cp >= 0x531 && cp <= 0x556) { // Mapped11: 38
				ret = cp + 0x30;
			}
		} else if (cp <= 0x2138) {
			if (cp >= 0x13F8 && cp <= 0x13FD) { // Mapped11: 6
				ret = cp - 0x8;
			} else if (cp >= 0x1400 && cp <= 0x167F) { // Valid
				ret = cp;
			} else if (cp >= 0x1C90 && cp <= 0x1CBA) { // Mapped11: 43
				ret = cp - 0xBC0;
			} else if (cp >= 0x1CBD && cp <= 0x1CBF) { // Mapped11: 3
				ret = cp - 0xBC0;
			} else if (cp >= 0x1D33 && cp <= 0x1D3A) { // Mapped11: 8
				ret = cp - 0x1CCC;
			} else if (cp >= 0x1D5D && cp <= 0x1D5F) { // Mapped11: 3
				ret = cp - 0x19AB;
			} else if (cp >= 0x1DA4 && cp <= 0x1DA6) { // Mapped11: 3
				ret = cp - 0x1B3C;
			} else if (cp >= 0x1DAE && cp <= 0x1DB1) { // Mapped11: 4
				ret = cp - 0x1B3C;
			} else if (cp >= 0x1DBC && cp <= 0x1DBE) { // Mapped11: 3
				ret = cp - 0x1B2C;
			} else if (cp >= 0x1EFA && cp < 0x1F00 && (cp & 1 == 0)) { // Mapped22: 3
				ret = cp + 1;
			} else if (cp >= 0x2074 && cp <= 0x2079) { // Mapped11: 6
				ret = cp - 0x2040;
			} else if (cp >= 0x2080 && cp <= 0x2089) { // Mapped11: 10
				ret = cp - 0x2050;
			} else if (cp >= 0x2096 && cp <= 0x2099) { // Mapped11: 4
				ret = cp - 0x202B;
			} else if (cp >= 0x210B && cp <= 0x210E) { // Mapped10: 4
				ret = 0x68;
			} else if (cp >= 0x211B && cp <= 0x211D) { // Mapped10: 3
				ret = 0x72;
			} else if (cp >= 0x2135 && cp <= 0x2138) { // Mapped11: 4
				ret = cp - 0x1B65;
			}
		} else if (cp <= 0x326D) {
			if (cp >= 0x2460 && cp <= 0x2468) { // Mapped11: 9
				ret = cp - 0x242F;
			} else if (cp >= 0x24B6 && cp <= 0x24CF) { // Mapped11: 26
				ret = cp - 0x2455;
			} else if (cp >= 0x24D0 && cp <= 0x24E9) { // Mapped11: 26
				ret = cp - 0x246F;
			} else if (cp >= 0x27C0 && cp <= 0x2933) { // Valid
				ret = cp;
			} else if (cp >= 0x2C00 && cp <= 0x2C2F) { // Mapped11: 48
				ret = cp + 0x30;
			} else if (cp >= 0x2C67 && cp < 0x2C6D && (cp & 1 == 0)) { // Mapped22: 3
				ret = cp + 1;
			} else if (cp >= 0x2C80 && cp < 0x2CE4 && (cp & 1 == 0)) { // Mapped22: 50
				ret = cp + 1;
			} else if (cp >= 0x3137 && cp <= 0x3139) { // Mapped11: 3
				ret = cp - 0x2034;
			} else if (cp >= 0x313A && cp <= 0x313F) { // Mapped11: 6
				ret = cp - 0x1F8A;
			} else if (cp >= 0x3141 && cp <= 0x3143) { // Mapped11: 3
				ret = cp - 0x203B;
			} else if (cp >= 0x3145 && cp <= 0x314E) { // Mapped11: 10
				ret = cp - 0x203C;
			} else if (cp >= 0x314F && cp <= 0x3163) { // Mapped11: 21
				ret = cp - 0x1FEE;
			} else if (cp >= 0x3178 && cp <= 0x317C) { // Mapped11: 5
				ret = cp - 0x204D;
			} else if (cp >= 0x3184 && cp <= 0x3186) { // Mapped11: 3
				ret = cp - 0x202D;
			} else if (cp >= 0x3263 && cp <= 0x3265) { // Mapped11: 3
				ret = cp - 0x215E;
			} else if (cp >= 0x3269 && cp <= 0x326D) { // Mapped11: 5
				ret = cp - 0x215B;
			}
		} else if (cp <= 0xFB55) {
			if (cp >= 0x32E4 && cp <= 0x32E9) { // Mapped11: 6
				ret = cp - 0x21A;
			} else if (cp >= 0x32EE && cp <= 0x32F2) { // Mapped11: 5
				ret = cp - 0x210;
			} else if (cp >= 0x32F5 && cp <= 0x32FA) { // Mapped11: 6
				ret = cp - 0x20D;
			} else if (cp >= 0x32FB && cp <= 0x32FE) { // Mapped11: 4
				ret = cp - 0x20C;
			} else if (cp >= 0x3400 && cp <= 0xA48C) { // Valid
				ret = cp;
			} else if (cp >= 0xA4D0 && cp <= 0xA62B) { // Valid
				ret = cp;
			} else if (cp >= 0xA640 && cp < 0xA66E && (cp & 1 == 0)) { // Mapped22: 23
				ret = cp + 1;
			} else if (cp >= 0xA680 && cp < 0xA69C && (cp & 1 == 0)) { // Mapped22: 14
				ret = cp + 1;
			} else if (cp >= 0xA722 && cp < 0xA730 && (cp & 1 == 0)) { // Mapped22: 7
				ret = cp + 1;
			} else if (cp >= 0xA732 && cp < 0xA770 && (cp & 1 == 0)) { // Mapped22: 31
				ret = cp + 1;
			} else if (cp >= 0xA77E && cp < 0xA788 && (cp & 1 == 0)) { // Mapped22: 5
				ret = cp + 1;
			} else if (cp >= 0xA796 && cp < 0xA7AA && (cp & 1 == 0)) { // Mapped22: 10
				ret = cp + 1;
			} else if (cp >= 0xA7B4 && cp < 0xA7C4 && (cp & 1 == 0)) { // Mapped22: 8
				ret = cp + 1;
			} else if (cp >= 0xAB70 && cp <= 0xABBF) { // Mapped11: 80
				ret = cp - 0x97D0;
			} else if (cp >= 0xFB24 && cp <= 0xFB26) { // Mapped11: 3
				ret = cp - 0xF549;
			} else if (cp >= 0xFB52 && cp <= 0xFB55) { // Mapped10: 4
				ret = 0x67B;
			}
		} else if (cp <= 0xFBA3) {
			if (cp >= 0xFB56 && cp <= 0xFB59) { // Mapped10: 4
				ret = 0x67E;
			} else if (cp >= 0xFB5A && cp <= 0xFB5D) { // Mapped10: 4
				ret = 0x680;
			} else if (cp >= 0xFB5E && cp <= 0xFB61) { // Mapped10: 4
				ret = 0x67A;
			} else if (cp >= 0xFB62 && cp <= 0xFB65) { // Mapped10: 4
				ret = 0x67F;
			} else if (cp >= 0xFB66 && cp <= 0xFB69) { // Mapped10: 4
				ret = 0x679;
			} else if (cp >= 0xFB6A && cp <= 0xFB6D) { // Mapped10: 4
				ret = 0x6A4;
			} else if (cp >= 0xFB6E && cp <= 0xFB71) { // Mapped10: 4
				ret = 0x6A6;
			} else if (cp >= 0xFB72 && cp <= 0xFB75) { // Mapped10: 4
				ret = 0x684;
			} else if (cp >= 0xFB76 && cp <= 0xFB79) { // Mapped10: 4
				ret = 0x683;
			} else if (cp >= 0xFB7A && cp <= 0xFB7D) { // Mapped10: 4
				ret = 0x686;
			} else if (cp >= 0xFB7E && cp <= 0xFB81) { // Mapped10: 4
				ret = 0x687;
			} else if (cp >= 0xFB8E && cp <= 0xFB91) { // Mapped10: 4
				ret = 0x6A9;
			} else if (cp >= 0xFB92 && cp <= 0xFB95) { // Mapped10: 4
				ret = 0x6AF;
			} else if (cp >= 0xFB96 && cp <= 0xFB99) { // Mapped10: 4
				ret = 0x6B3;
			} else if (cp >= 0xFB9A && cp <= 0xFB9D) { // Mapped10: 4
				ret = 0x6B1;
			} else if (cp >= 0xFBA0 && cp <= 0xFBA3) { // Mapped10: 4
				ret = 0x6BB;
			}
		} else if (cp <= 0xFEC0) {
			if (cp >= 0xFBA6 && cp <= 0xFBA9) { // Mapped10: 4
				ret = 0x6C1;
			} else if (cp >= 0xFBAA && cp <= 0xFBAD) { // Mapped10: 4
				ret = 0x6BE;
			} else if (cp >= 0xFBD3 && cp <= 0xFBD6) { // Mapped10: 4
				ret = 0x6AD;
			} else if (cp >= 0xFBE4 && cp <= 0xFBE7) { // Mapped10: 4
				ret = 0x6D0;
			} else if (cp >= 0xFBFC && cp <= 0xFBFF) { // Mapped10: 4
				ret = 0x6CC;
			} else if (cp >= 0xFE41 && cp <= 0xFE44) { // Mapped11: 4
				ret = cp - 0xCE35;
			} else if (cp >= 0xFE8F && cp <= 0xFE92) { // Mapped10: 4
				ret = 0x628;
			} else if (cp >= 0xFE95 && cp <= 0xFE98) { // Mapped10: 4
				ret = 0x62A;
			} else if (cp >= 0xFE99 && cp <= 0xFE9C) { // Mapped10: 4
				ret = 0x62B;
			} else if (cp >= 0xFE9D && cp <= 0xFEA0) { // Mapped10: 4
				ret = 0x62C;
			} else if (cp >= 0xFEA1 && cp <= 0xFEA4) { // Mapped10: 4
				ret = 0x62D;
			} else if (cp >= 0xFEA5 && cp <= 0xFEA8) { // Mapped10: 4
				ret = 0x62E;
			} else if (cp >= 0xFEB1 && cp <= 0xFEB4) { // Mapped10: 4
				ret = 0x633;
			} else if (cp >= 0xFEB5 && cp <= 0xFEB8) { // Mapped10: 4
				ret = 0x634;
			} else if (cp >= 0xFEB9 && cp <= 0xFEBC) { // Mapped10: 4
				ret = 0x635;
			} else if (cp >= 0xFEBD && cp <= 0xFEC0) { // Mapped10: 4
				ret = 0x636;
			}
		} else if (cp <= 0xFF8A) {
			if (cp >= 0xFEC1 && cp <= 0xFEC4) { // Mapped10: 4
				ret = 0x637;
			} else if (cp >= 0xFEC5 && cp <= 0xFEC8) { // Mapped10: 4
				ret = 0x638;
			} else if (cp >= 0xFEC9 && cp <= 0xFECC) { // Mapped10: 4
				ret = 0x639;
			} else if (cp >= 0xFECD && cp <= 0xFED0) { // Mapped10: 4
				ret = 0x63A;
			} else if (cp >= 0xFED1 && cp <= 0xFED4) { // Mapped10: 4
				ret = 0x641;
			} else if (cp >= 0xFED5 && cp <= 0xFED8) { // Mapped10: 4
				ret = 0x642;
			} else if (cp >= 0xFED9 && cp <= 0xFEDC) { // Mapped10: 4
				ret = 0x643;
			} else if (cp >= 0xFEDD && cp <= 0xFEE0) { // Mapped10: 4
				ret = 0x644;
			} else if (cp >= 0xFEE1 && cp <= 0xFEE4) { // Mapped10: 4
				ret = 0x645;
			} else if (cp >= 0xFEE5 && cp <= 0xFEE8) { // Mapped10: 4
				ret = 0x646;
			} else if (cp >= 0xFEE9 && cp <= 0xFEEC) { // Mapped10: 4
				ret = 0x647;
			} else if (cp >= 0xFEF1 && cp <= 0xFEF4) { // Mapped10: 4
				ret = 0x64A;
			} else if (cp >= 0xFF10 && cp <= 0xFF19) { // Mapped11: 10
				ret = cp - 0xFEE0;
			} else if (cp >= 0xFF21 && cp <= 0xFF3A) { // Mapped11: 26
				ret = cp - 0xFEC0;
			} else if (cp >= 0xFF41 && cp <= 0xFF5A) { // Mapped11: 26
				ret = cp - 0xFEE0;
			} else if (cp >= 0xFF85 && cp <= 0xFF8A) { // Mapped11: 6
				ret = cp - 0xCEBB;
			}
		} else if (cp <= 0x10592) {
			if (cp >= 0xFF8F && cp <= 0xFF93) { // Mapped11: 5
				ret = cp - 0xCEB1;
			} else if (cp >= 0xFF96 && cp <= 0xFF9B) { // Mapped11: 6
				ret = cp - 0xCEAE;
			} else if (cp >= 0xFFA7 && cp <= 0xFFA9) { // Mapped11: 3
				ret = cp - 0xEEA4;
			} else if (cp >= 0xFFAA && cp <= 0xFFAF) { // Mapped11: 6
				ret = cp - 0xEDFA;
			} else if (cp >= 0xFFB1 && cp <= 0xFFB3) { // Mapped11: 3
				ret = cp - 0xEEAB;
			} else if (cp >= 0xFFB5 && cp <= 0xFFBE) { // Mapped11: 10
				ret = cp - 0xEEAC;
			} else if (cp >= 0xFFC2 && cp <= 0xFFC7) { // Mapped11: 6
				ret = cp - 0xEE61;
			} else if (cp >= 0xFFCA && cp <= 0xFFCF) { // Mapped11: 6
				ret = cp - 0xEE63;
			} else if (cp >= 0xFFD2 && cp <= 0xFFD7) { // Mapped11: 6
				ret = cp - 0xEE65;
			} else if (cp >= 0xFFDA && cp <= 0xFFDC) { // Mapped11: 3
				ret = cp - 0xEE67;
			} else if (cp >= 0xFFE9 && cp <= 0xFFEC) { // Mapped11: 4
				ret = cp - 0xDE59;
			} else if (cp >= 0x10400 && cp <= 0x10427) { // Mapped11: 40
				ret = cp + 0x28;
			} else if (cp >= 0x104B0 && cp <= 0x104D3) { // Mapped11: 36
				ret = cp + 0x28;
			} else if (cp >= 0x10570 && cp <= 0x1057A) { // Mapped11: 11
				ret = cp + 0x27;
			} else if (cp >= 0x1057C && cp <= 0x1058A) { // Mapped11: 15
				ret = cp + 0x27;
			} else if (cp >= 0x1058C && cp <= 0x10592) { // Mapped11: 7
				ret = cp + 0x27;
			}
		} else if (cp <= 0x1D44D) {
			if (cp >= 0x10600 && cp <= 0x10736) { // Valid
				ret = cp;
			} else if (cp >= 0x107B6 && cp <= 0x107B8) { // Mapped11: 3
				ret = cp - 0x105F6;
			} else if (cp >= 0x10C80 && cp <= 0x10CB2) { // Mapped11: 51
				ret = cp + 0x40;
			} else if (cp >= 0x118A0 && cp <= 0x118BF) { // Mapped11: 32
				ret = cp + 0x20;
			} else if (cp >= 0x11FFF && cp <= 0x12399) { // Valid
				ret = cp;
			} else if (cp >= 0x13000 && cp <= 0x1342E) { // Valid
				ret = cp;
			} else if (cp >= 0x14400 && cp <= 0x14646) { // Valid
				ret = cp;
			} else if (cp >= 0x16800 && cp <= 0x16A38) { // Valid
				ret = cp;
			} else if (cp >= 0x16E40 && cp <= 0x16E5F) { // Mapped11: 32
				ret = cp + 0x20;
			} else if (cp >= 0x17000 && cp <= 0x187F7) { // Valid
				ret = cp;
			} else if (cp >= 0x18800 && cp <= 0x18CD5) { // Valid
				ret = cp;
			} else if (cp >= 0x1B000 && cp <= 0x1B122) { // Valid
				ret = cp;
			} else if (cp >= 0x1B170 && cp <= 0x1B2FB) { // Valid
				ret = cp;
			} else if (cp >= 0x1D400 && cp <= 0x1D419) { // Mapped11: 26
				ret = cp - 0x1D39F;
			} else if (cp >= 0x1D41A && cp <= 0x1D433) { // Mapped11: 26
				ret = cp - 0x1D3B9;
			} else if (cp >= 0x1D434 && cp <= 0x1D44D) { // Mapped11: 26
				ret = cp - 0x1D3D3;
			}
		} else if (cp <= 0x1D53E) {
			if (cp >= 0x1D44E && cp <= 0x1D454) { // Mapped11: 7
				ret = cp - 0x1D3ED;
			} else if (cp >= 0x1D456 && cp <= 0x1D467) { // Mapped11: 18
				ret = cp - 0x1D3ED;
			} else if (cp >= 0x1D468 && cp <= 0x1D481) { // Mapped11: 26
				ret = cp - 0x1D407;
			} else if (cp >= 0x1D482 && cp <= 0x1D49B) { // Mapped11: 26
				ret = cp - 0x1D421;
			} else if (cp >= 0x1D4A9 && cp <= 0x1D4AC) { // Mapped11: 4
				ret = cp - 0x1D43B;
			} else if (cp >= 0x1D4AE && cp <= 0x1D4B5) { // Mapped11: 8
				ret = cp - 0x1D43B;
			} else if (cp >= 0x1D4B6 && cp <= 0x1D4B9) { // Mapped11: 4
				ret = cp - 0x1D455;
			} else if (cp >= 0x1D4BD && cp <= 0x1D4C3) { // Mapped11: 7
				ret = cp - 0x1D455;
			} else if (cp >= 0x1D4C5 && cp <= 0x1D4CF) { // Mapped11: 11
				ret = cp - 0x1D455;
			} else if (cp >= 0x1D4D0 && cp <= 0x1D4E9) { // Mapped11: 26
				ret = cp - 0x1D46F;
			} else if (cp >= 0x1D4EA && cp <= 0x1D503) { // Mapped11: 26
				ret = cp - 0x1D489;
			} else if (cp >= 0x1D507 && cp <= 0x1D50A) { // Mapped11: 4
				ret = cp - 0x1D4A3;
			} else if (cp >= 0x1D50D && cp <= 0x1D514) { // Mapped11: 8
				ret = cp - 0x1D4A3;
			} else if (cp >= 0x1D516 && cp <= 0x1D51C) { // Mapped11: 7
				ret = cp - 0x1D4A3;
			} else if (cp >= 0x1D51E && cp <= 0x1D537) { // Mapped11: 26
				ret = cp - 0x1D4BD;
			} else if (cp >= 0x1D53B && cp <= 0x1D53E) { // Mapped11: 4
				ret = cp - 0x1D4D7;
			}
		} else if (cp <= 0x1D6B8) {
			if (cp >= 0x1D540 && cp <= 0x1D544) { // Mapped11: 5
				ret = cp - 0x1D4D7;
			} else if (cp >= 0x1D54A && cp <= 0x1D550) { // Mapped11: 7
				ret = cp - 0x1D4D7;
			} else if (cp >= 0x1D552 && cp <= 0x1D56B) { // Mapped11: 26
				ret = cp - 0x1D4F1;
			} else if (cp >= 0x1D56C && cp <= 0x1D585) { // Mapped11: 26
				ret = cp - 0x1D50B;
			} else if (cp >= 0x1D586 && cp <= 0x1D59F) { // Mapped11: 26
				ret = cp - 0x1D525;
			} else if (cp >= 0x1D5A0 && cp <= 0x1D5B9) { // Mapped11: 26
				ret = cp - 0x1D53F;
			} else if (cp >= 0x1D5BA && cp <= 0x1D5D3) { // Mapped11: 26
				ret = cp - 0x1D559;
			} else if (cp >= 0x1D5D4 && cp <= 0x1D5ED) { // Mapped11: 26
				ret = cp - 0x1D573;
			} else if (cp >= 0x1D5EE && cp <= 0x1D607) { // Mapped11: 26
				ret = cp - 0x1D58D;
			} else if (cp >= 0x1D608 && cp <= 0x1D621) { // Mapped11: 26
				ret = cp - 0x1D5A7;
			} else if (cp >= 0x1D622 && cp <= 0x1D63B) { // Mapped11: 26
				ret = cp - 0x1D5C1;
			} else if (cp >= 0x1D63C && cp <= 0x1D655) { // Mapped11: 26
				ret = cp - 0x1D5DB;
			} else if (cp >= 0x1D656 && cp <= 0x1D66F) { // Mapped11: 26
				ret = cp - 0x1D5F5;
			} else if (cp >= 0x1D670 && cp <= 0x1D689) { // Mapped11: 26
				ret = cp - 0x1D60F;
			} else if (cp >= 0x1D68A && cp <= 0x1D6A3) { // Mapped11: 26
				ret = cp - 0x1D629;
			} else if (cp >= 0x1D6A8 && cp <= 0x1D6B8) { // Mapped11: 17
				ret = cp - 0x1D2F7;
			}
		} else if (cp <= 0x1D7A0) {
			if (cp >= 0x1D6BA && cp <= 0x1D6C0) { // Mapped11: 7
				ret = cp - 0x1D2F7;
			} else if (cp >= 0x1D6C2 && cp <= 0x1D6D2) { // Mapped11: 17
				ret = cp - 0x1D311;
			} else if (cp >= 0x1D6D4 && cp <= 0x1D6DA) { // Mapped11: 7
				ret = cp - 0x1D311;
			} else if (cp >= 0x1D6E2 && cp <= 0x1D6F2) { // Mapped11: 17
				ret = cp - 0x1D331;
			} else if (cp >= 0x1D6F4 && cp <= 0x1D6FA) { // Mapped11: 7
				ret = cp - 0x1D331;
			} else if (cp >= 0x1D6FC && cp <= 0x1D70C) { // Mapped11: 17
				ret = cp - 0x1D34B;
			} else if (cp >= 0x1D70E && cp <= 0x1D714) { // Mapped11: 7
				ret = cp - 0x1D34B;
			} else if (cp >= 0x1D71C && cp <= 0x1D72C) { // Mapped11: 17
				ret = cp - 0x1D36B;
			} else if (cp >= 0x1D72E && cp <= 0x1D734) { // Mapped11: 7
				ret = cp - 0x1D36B;
			} else if (cp >= 0x1D736 && cp <= 0x1D746) { // Mapped11: 17
				ret = cp - 0x1D385;
			} else if (cp >= 0x1D748 && cp <= 0x1D74E) { // Mapped11: 7
				ret = cp - 0x1D385;
			} else if (cp >= 0x1D756 && cp <= 0x1D766) { // Mapped11: 17
				ret = cp - 0x1D3A5;
			} else if (cp >= 0x1D768 && cp <= 0x1D76E) { // Mapped11: 7
				ret = cp - 0x1D3A5;
			} else if (cp >= 0x1D770 && cp <= 0x1D780) { // Mapped11: 17
				ret = cp - 0x1D3BF;
			} else if (cp >= 0x1D782 && cp <= 0x1D788) { // Mapped11: 7
				ret = cp - 0x1D3BF;
			} else if (cp >= 0x1D790 && cp <= 0x1D7A0) { // Mapped11: 17
				ret = cp - 0x1D3DF;
			}
		} else if (cp <= 0x1FBF9) {
			if (cp >= 0x1D7A2 && cp <= 0x1D7A8) { // Mapped11: 7
				ret = cp - 0x1D3DF;
			} else if (cp >= 0x1D7AA && cp <= 0x1D7BA) { // Mapped11: 17
				ret = cp - 0x1D3F9;
			} else if (cp >= 0x1D7BC && cp <= 0x1D7C2) { // Mapped11: 7
				ret = cp - 0x1D3F9;
			} else if (cp >= 0x1D7CE && cp <= 0x1D7D7) { // Mapped11: 10
				ret = cp - 0x1D79E;
			} else if (cp >= 0x1D7D8 && cp <= 0x1D7E1) { // Mapped11: 10
				ret = cp - 0x1D7A8;
			} else if (cp >= 0x1D7E2 && cp <= 0x1D7EB) { // Mapped11: 10
				ret = cp - 0x1D7B2;
			} else if (cp >= 0x1D7EC && cp <= 0x1D7F5) { // Mapped11: 10
				ret = cp - 0x1D7BC;
			} else if (cp >= 0x1D7F6 && cp <= 0x1D7FF) { // Mapped11: 10
				ret = cp - 0x1D7C6;
			} else if (cp >= 0x1D800 && cp <= 0x1D9FF) { // Valid
				ret = cp;
			} else if (cp >= 0x1E900 && cp <= 0x1E921) { // Mapped11: 34
				ret = cp + 0x22;
			} else if (cp >= 0x1EE0A && cp <= 0x1EE0D) { // Mapped11: 4
				ret = cp - 0x1E7C7;
			} else if (cp >= 0x1EE2A && cp <= 0x1EE2D) { // Mapped11: 4
				ret = cp - 0x1E7E7;
			} else if (cp >= 0x1EE8B && cp <= 0x1EE8D) { // Mapped11: 3
				ret = cp - 0x1E847;
			} else if (cp >= 0x1EEAB && cp <= 0x1EEAD) { // Mapped11: 3
				ret = cp - 0x1E867;
			} else if (cp >= 0x1F130 && cp <= 0x1F149) { // Mapped11: 26
				ret = cp - 0x1F0CF;
			} else if (cp >= 0x1FBF0 && cp <= 0x1FBF9) { // Mapped11: 10
				ret = cp - 0x1FBC0;
			}
		} else {
			if (cp >= 0x20000 && cp <= 0x2A6DF) { // Valid
				ret = cp;
			} else if (cp >= 0x2A700 && cp <= 0x2B738) { // Valid
				ret = cp;
			} else if (cp >= 0x2B820 && cp <= 0x2CEA1) { // Valid
				ret = cp;
			} else if (cp >= 0x2CEB0 && cp <= 0x2EBE0) { // Valid
				ret = cp;
			} else if (cp >= 0x30000 && cp <= 0x3134A) { // Valid
				ret = cp;
			}
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}