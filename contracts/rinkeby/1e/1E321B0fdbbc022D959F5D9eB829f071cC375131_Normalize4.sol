// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";

contract Normalize4 is Ownable {

	error InvalidCodepoint(uint256 cp);

	uint256 constant STOP = 0x2E;
	uint256 constant EMOJI_STATE_MASK  = 0x07FF; 
	uint256 constant EMOJI_STATE_QUIRK = 0x0800;
	uint256 constant EMOJI_STATE_VALID = 0x1000;
	uint256 constant EMOJI_STATE_SAVE  = 0x2000;
	uint256 constant EMOJI_STATE_CHECK = 0x4000;
	uint256 constant EMOJI_STATE_FE0F  = 0x8000;

	mapping (uint256 => uint256) _emoji;
	mapping (uint256 => uint256) _valid;   // bitmap
	mapping (uint256 => uint256) _ignored; // bitmap
	mapping (uint256 => uint256) _small; // 1-2 cp
	mapping (uint256 => uint256) _large; // 3-6 cp
	mapping (uint256 => uint256) _class;
	mapping (uint256 => uint256) _cm;
	mapping (uint256 => uint256) _recomp;
	mapping (uint256 => uint256) _decomp;

	function debugDestroy() onlyOwner public {
		selfdestruct(payable(msg.sender));
	}

	function normhash(string memory name) public view returns (bytes32 node) {
		string[] memory labels = normalize(name);
		uint256 i = labels.length;
		while (i > 0) {
			bytes32 label = keccak256(bytes(labels[--i]));
			node = keccak256(abi.encodePacked(node, label));
		}
	}

	function normalize(string memory name) public view returns (string[] memory labels) {
        (uint256[] memory values, uint256 label_count) = process(decodeUTF8(bytes(name)), false);
		//n = label_count;
		//v = values;
		values = nfd(values);
		labels = new string[](label_count);
		uint256 prev;
		for (uint256 i; i < label_count; i++) {
			uint256 end = prev;
			while (end < values.length && values[end] != STOP) end++;
			labels[i] = string(post_check_label(values, prev, end));
			prev = end + 1;
		}
	}

	function beautify(string memory name) public view returns (string memory) {
		(uint256[] memory values, ) = process(decodeUTF8(bytes(name)), true);
		return string(nfc(nfd(values)));
	}


	function updateMapping(mapping (uint256 => uint256) storage map, bytes calldata data, uint256 key_bytes) private {
		uint256 i;
		uint256 e;
	    uint256 mask = ~(type(uint256).max << (key_bytes << 3));
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
	function updateIgnored(bytes calldata data) public onlyOwner {
		updateMapping(_ignored, data, 2);
	}
	function updateSmall(bytes calldata data) public onlyOwner {
		updateMapping(_small, data, 3);
	}
	function updateLarge(bytes calldata data) public onlyOwner {
		updateMapping(_large, data, 3);
	}
	function updateClass(bytes calldata data) public onlyOwner {
		updateMapping(_class, data, 2);
	}
	function updateCM(bytes calldata data) public onlyOwner {
		updateMapping(_cm, data, 2);
	}
	function updateDecomp(bytes calldata data) public onlyOwner {
		updateMapping(_decomp, data, 3);
	}
	function updateRecomp(bytes calldata data) public onlyOwner {
		updateMapping(_recomp, data, 5);
	}

	// bitmaps
	function isCM(uint256 cp) public view returns (bool) {
		return ((_cm[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}
	function isValid(uint256 cp) public view returns (bool) {
		return ((_valid[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}
	function isIgnored(uint256 cp) public view returns (bool) {
		return ((_ignored[cp >> 8] & (1 << (cp & 0xFF))) != 0);
	}

 	function getDecomp(uint256 cp) public view returns (uint256) {
        return (_decomp[cp >> 2] >> ((cp & 0x3) << 6)) & 0xFFFFFFFFFFFFFFFF;
    }
	function getRecomp(uint256 a, uint256 b) public view returns (uint256) {
		return (_recomp[(b << 29) | (a >> 3)] >> ((a & 0x7) << 5)) & 0xFFFFFFFF;
	}
	function getClass(uint256 cp) public view returns (uint256) {
		return (_class[cp >> 5] >> ((cp & 0x1F) << 3)) & 0xFF;
	}

	function getSmall(uint256 cp) public view returns (uint256) {
		return (_small[cp >> 2] >> ((cp & 0x3) << 6)) & 0xFFFFFFFFFFFFFFFF;
	}
	function getLarge(uint256 cp) public view returns (uint256) {
		return (_large[cp >> 1] >> ((cp & 0x1) << 7)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
	}

	function getEmoji(uint256 s0, uint256 cp) private view returns (uint256) {
		return (_emoji[(s0 << 20) | (cp >> 4)] >> ((cp & 0xF) << 4)) & 0xFFFF;
	}

	
	function debugEmojiState(uint256 s0, uint256 cp) public view returns (uint256 value, bool fe0f, bool check, bool save, bool valid, bool quirk, uint256 s1) {
		// (state0, Floor[cp/16]) => array: uint32[16]
		// array[cp%16] => [flags: (4 bits), state1: (12 bits)]
		value = getEmoji(s0, cp);
		fe0f = (value & EMOJI_STATE_FE0F) != 0;
		check = (value & EMOJI_STATE_CHECK) != 0;
		save = (value & EMOJI_STATE_SAVE) != 0;
		valid = (value & EMOJI_STATE_VALID) != 0;
		quirk = (value & EMOJI_STATE_QUIRK) != 0;
		s1 = value & EMOJI_STATE_MASK; // next state
	}

	function isOneEmoji(string memory s) public view returns (bool) {
		uint256[] memory cps = decodeUTF8(bytes(s));
		uint256[] memory ret = new uint256[](cps.length);
		(uint256 pos, uint256 len) = consumeEmoji(cps, 0, ret, 0, false);
		return pos == cps.length && len > 0;
	}

	// https://www.unicode.org/versions/Unicode14.0.0/ch03.pdf
	uint256 constant S0 = 0xAC00;
	uint256 constant L0 = 0x1100;
	uint256 constant V0 = 0x1161;
	uint256 constant T0 = 0x11A7;
	uint256 constant L_COUNT = 19;
	uint256 constant V_COUNT = 21;
	uint256 constant T_COUNT = 28;
	uint256 constant N_COUNT = V_COUNT * T_COUNT;
	uint256 constant S_COUNT = L_COUNT * N_COUNT;
	uint256 constant S1 = S0 + S_COUNT;
	uint256 constant L1 = L0 + L_COUNT;
	uint256 constant V1 = V0 + V_COUNT;
	uint256 constant T1 = T0 + T_COUNT;
	uint256 constant CP_MASK = 0xFFFFFF;

	function isHangul(uint256 cp) private pure returns (bool) {
		return cp >= S0 && cp < S1;
	}
	function getComposed(uint256 a, uint256 b) private view returns (uint256) {
		if (a >= L0 && a < L1 && b >= V0 && b < V1) { // LV
			return S0 + (a - L0) * N_COUNT + (b - V0) * T_COUNT;
		} else if (isHangul(a) && b > T0 && b < T1 && (a - S0) % T_COUNT == 0) {
			return a + (b - T0);
		} else {
			return getRecomp(a, b);
		}
	}

	function decodeUTF8(bytes memory src) private pure returns (uint256[] memory ret) {
		ret = new uint256[](src.length);
		uint256 ptr;
		assembly {
			ptr := src
		}
		uint256 len;
		uint256 end = ptr + src.length;
		while (ptr < end) {
			(uint256 cp, uint256 step) = readUTF8(ptr);
			ret[len++] = cp;
			ptr += step;
		}
		assembly {
			mstore(ret, len) // truncate
		}
	}

	// read one cp from memory at ptr
	// step is number of encoded bytes (1-4)
	// raw is encoded bytes
	// warning: assumes valid UTF8
	function readUTF8(uint256 ptr) private pure returns (uint256 cp, uint256 step) {
		// 0xxxxxxx => 1 :: 0aaaaaaa ???????? ???????? ???????? =>                   0aaaaaaa
		// 110xxxxx => 2 :: 110aaaaa 10bbbbbb ???????? ???????? =>          00000aaa aabbbbbb
		// 1110xxxx => 3 :: 1110aaaa 10bbbbbb 10cccccc ???????? => 000000aa aaaabbbb bbcccccc
		// 11110xxx => 4 :: 11110aaa 10bbbbbb 10cccccc 10dddddd => 000aaabb bbbbcccc ccdddddd
		uint256 raw;
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

	function encodeUTF8(uint256[] memory cps) private pure returns (bytes memory ret) {
		ret = new bytes(cps.length << 2);
		uint256 ret_off;
		assembly {
			ret_off := add(ret, 32)
		}
		uint256 ret_end = ret_off;
		for (uint256 i; i < cps.length; i++) {
			ret_end = writeUTF8(ret_end, cps[i] & CP_MASK);
		}
		assembly {
			mstore(ret, sub(ret_end, ret_off))
		}
	}

    function writeUTF8(uint256 ptr, uint256 cp) private pure returns (uint256) {
		if (cp < 0x80) {
            assembly {
                mstore8(ptr, cp)
            }
            return ptr + 1;
		} else if (cp < 0x800) {
            assembly {
                mstore8(ptr,         or(0xC0, shr(6, cp)))
                mstore8(add(ptr, 1), or(0x80, and(cp, 0x3F)))
            }
            return ptr + 2;
		} else if (cp < 0x10000) {
            assembly {
                mstore8(ptr,         or(0xE0, shr(12, cp)))
                mstore8(add(ptr, 1), or(0x80, and(shr(6, cp), 0x3F)))
                mstore8(add(ptr, 2), or(0x80, and(cp, 0x3F)))
            }
            return ptr + 3;
		} else {
            assembly {
                mstore8(ptr,         or(0xF0, shr(18, cp)))
                mstore8(add(ptr, 1), or(0x80, and(shr(12, cp), 0x3F)))
                mstore8(add(ptr, 2), or(0x80, and(shr(6, cp), 0x3F)))
                mstore8(add(ptr, 3), or(0x80, and(cp, 0x3F)))
            }
            return ptr + 4;
		}
	}

	function process(uint256[] memory cps, bool pretty) public view returns (uint256[] memory ret, uint256 label_count) {
		ret = new uint256[](cps.length * 6); // maximum expansion factor
		label_count = 1;
		uint256 len;
		uint256 i;
		while(i < cps.length) {
			(uint256 new_i, uint256 new_len) = consumeEmoji(cps, i, ret, len, pretty);
			if (new_i > i) {
				i = new_i;
				if (pretty && (new_len & VALUE_EMOJI) != 0) {
					len = (new_len ^ VALUE_EMOJI) - 1;
					for (uint256 j = i + 1; j < len; j++) {
						ret[j] = ret[j+1];
					}
				} else {
					len = new_len;
				}
				continue;
			}
			uint256 cp = cps[i++];
			uint256 mapped = getMapped(cp); 
			if (mapped != 0) {
				ret[len++] = mapped;
				continue;
			}
			if (isValid(cp)) {		
				if (cp == STOP) label_count++;		
 				ret[len++] = cp;
				continue;
			}
			if (isIgnored(cp)) { 
				continue;
			}
			mapped = getSmall(cp);
			if (mapped != 0) {
				if (mapped < 0xFFFFFF) {
					ret[len++] = mapped;
				} else {
					ret[len++] = mapped >> 24;
					ret[len++] = mapped & 0xFFFFFF;
				}
				continue;
			}
			mapped = getLarge(cp);
			if (mapped == 0) revert InvalidCodepoint(cp);
			while (mapped != 0) {
				ret[len++] = mapped & 0x1FFFFF;
				mapped >>= 21;
			}
		}
		assembly {
			mstore(ret, len)
		}
	}

    function addClass(uint256 cp) private view returns (uint256) {
        return (getClass(cp) << 24) | cp;
    }
	function nfd(uint256[] memory cps) private view returns (uint256[] memory ret) {
        ret = new uint256[](cps.length * 3); // growth factor
        uint256 len;
        uint256 has_nz_class;
        for (uint256 i; i < cps.length; i++) {
            uint256 buf = cps[i];
            uint256 width = 32;
            while (width != 0) {
                uint256 cp = buf & 0xFFFFFFFF;
                buf >>= 32;
                width -= 32;
                if (cp < 0x80 || cp >= CP_MASK) {
                    ret[len++] = cp;
                } else if (isHangul(cp)) {
                    uint256 s_index = cp - S0;
                    uint256 l_index = s_index / N_COUNT | 0;
                    uint256 v_index = (s_index % N_COUNT) / T_COUNT | 0;
                    uint256 t_index = s_index % T_COUNT;
                    uint256 l_cp = addClass(L0 + l_index);
                    uint256 v_cp = addClass(V0 + v_index);
                    ret[len++] = l_cp;
                    ret[len++] = v_cp;
                    if (has_nz_class == 0 && (l_cp | v_cp) > CP_MASK) has_nz_class = 1;
                    if (t_index != 0) {
                        uint256 t_cp = addClass(T0 + t_index);
                        if (has_nz_class == 0 && t_cp > CP_MASK) has_nz_class = 1;
                        ret[len++] = t_cp;
                    }
                } else {
                    uint256 decomp = getDecomp(cp);
                    if (decomp != 0) {
                        buf |= (decomp << width);
                        width += (decomp >> 32) == 0 ? 32 : 64;
                    } else {
                        uint256 x_cp = addClass(cp);
                        if (has_nz_class == 0 && x_cp > CP_MASK) has_nz_class = 1;
                        ret[len++] = x_cp;
                    }
                }
            }
        }
        if (has_nz_class != 0) {
            uint256 prev = ret[0] >> 24;
            for (uint256 i = 1; i < len; i++) {
                uint256 rank = ret[i] >> 24;
                if (prev == 0 || rank == 0 || prev <= rank) {
                    prev = rank;
                    continue;
                }
                uint256 j = i - 1;
                while (true) {
                    (ret[j+1], ret[j]) = (ret[j], ret[j+1]);
                    if (j == 0) break;
                    prev = ret[--j] >> 24;
                    if (prev <= rank) break;
                }
                prev = ret[i] >> 24;
            }
        }
        assembly {
            mstore(ret, len) // truncate
        }
    }

	
	function nfc(uint256[] memory values) private view returns (bytes memory utf8) {
		utf8 = new bytes(values.length << 4);
		uint256 utf_off;
		assembly {
			utf_off := add(utf8, 32)
		}
		uint256 utf_end = utf_off;
		uint256 prev_cp;
		for (uint256 i; i < values.length; i++) {
			uint256 cp = values[i] & CP_MASK;
			if (prev_cp != 0) {
				if (cp >= 0x80) {
					uint256 composed = getComposed(prev_cp, cp);
					if (composed != 0) {
						prev_cp = composed;
						continue;
					}
				}
				utf_end = writeUTF8(utf_end, prev_cp);	
			}
			prev_cp = cp;	
		}
		if (prev_cp != 0) {
			utf_end = writeUTF8(utf_end, prev_cp);
		}
		assembly {
			mstore(utf8, sub(utf_end, utf_off))
		}
	}


	function post_check_label(uint256[] memory values, uint256 start, uint256 end) private view returns (bytes memory utf8) {
		uint256 len = end - start;
		if (len == 0) return ('');
		uint256 non_ascii;
		uint256 fail_if_underscore;
		uint256 fail_if_cm = 1;
		utf8 = new bytes(len << 4);
		uint256 utf_off;
		assembly {
			utf_off := add(utf8, 32)
		}
		uint256 utf_end = utf_off;
		uint256 prev_cp;
		while (start < end) {
			uint256 value = values[start++];
			uint256 cp = value & 0xFFFFFF;
			if (cp < 0x80) { // ascii
				if (cp == 0x5F) { // underscore
					require(fail_if_underscore == 0, "underscore");
				} else {
					fail_if_underscore = 1;
				}
				if (prev_cp != 0) {
					utf_end = writeUTF8(utf_end, prev_cp);	
				}
				prev_cp = cp;
				fail_if_cm = 0;
				continue;
			}
			non_ascii = 1;
			if (isCM(cp)) {
				require(fail_if_cm == 0, "cm");
				fail_if_cm = 1;
			} else if ((value & VALUE_EMOJI) != 0) {
				fail_if_cm = 1;
			} else {
				fail_if_cm = 0;
			}
			if (prev_cp != 0) {
				uint256 composed = getComposed(prev_cp, cp);
				if (composed != 0) {
					prev_cp = composed;
					continue;
				}
				utf_end = writeUTF8(utf_end, prev_cp);	
			}
			prev_cp = cp;	
		}
		utf_end = writeUTF8(utf_end, prev_cp);	
		// label extension
		if (len >= 4 && non_ascii == 0 && utf8[2] == '-' && utf8[3] == '-') {
			revert("label extension");
		}
		assembly {
			mstore(utf8, sub(utf_end, utf_off))
		}
	}

	uint256 constant VALUE_EMOJI = 0x80000000;

	function consumeEmoji(uint256[] memory cps, uint256 pos, uint256[] memory ret, uint256 len, bool add_fe0f) private view returns (uint256 out_pos, uint256 out_len) {
		uint256 state;
		uint256 saved;
		while (pos < cps.length) {
			uint256 cp = cps[pos++];
			state = getEmoji(state & EMOJI_STATE_MASK, cp);
			if (state == 0) break;
			if ((state & EMOJI_STATE_SAVE) != 0) { 
				saved = cp; 
			} else if ((state & EMOJI_STATE_CHECK) != 0) { 
				if (cp == saved) break;
			}
			ret[len++] = cp | VALUE_EMOJI;
			if ((state & EMOJI_STATE_FE0F) != 0) {
				if (add_fe0f) ret[len++] = 0xFE0F | VALUE_EMOJI;
				if (pos < cps.length && cps[pos] == 0xFE0F) pos++;
			}
			if ((state & EMOJI_STATE_VALID) != 0) {
				out_pos = pos;
				out_len = len;
				if (add_fe0f && (state & EMOJI_STATE_QUIRK) != 0) {
					out_len |= VALUE_EMOJI;
				}			
			}
		}
	}

/*
	function getMapped(uint256 cp) public pure returns (uint256 ret) {
        return 0;
    }*/

	// auto-generated
	function getMapped(uint256 cp) public pure returns (uint256 ret) {
		if (cp <= 0x1D734) {
			if (cp <= 0xFFB3) {
				if (cp <= 0x2099) {
					if (cp <= 0x1CBA) {
						if (cp <= 0x3FF) {
							if (cp <= 0xDE) {
								if (cp >= 0x41 && cp <= 0x5A) { // Mapped11: 26
									ret = cp + 0x20;
								} else if (cp >= 0xC0 && cp <= 0xD6) { // Mapped11: 23
									ret = cp + 0x20;
								} else if (cp >= 0xD8 && cp <= 0xDE) { // Mapped11: 7
									ret = cp + 0x20;
								}
							} else {
								if (cp >= 0x388 && cp <= 0x38A) { // Mapped11: 3
									ret = cp + 0x25;
								} else if (cp >= 0x391 && cp <= 0x3A1) { // Mapped11: 17
									ret = cp + 0x20;
								} else if (cp >= 0x3A3 && cp <= 0x3AB) { // Mapped11: 9
									ret = cp + 0x20;
								} else if (cp >= 0x3FD && cp <= 0x3FF) { // Mapped11: 3
									ret = cp - 0x82;
								}
							}
						} else {
							if (cp <= 0x556) {
								if (cp >= 0x400 && cp <= 0x40F) { // Mapped11: 16
									ret = cp + 0x50;
								} else if (cp >= 0x410 && cp <= 0x42F) { // Mapped11: 32
									ret = cp + 0x20;
								} else if (cp >= 0x531 && cp <= 0x556) { // Mapped11: 38
									ret = cp + 0x30;
								}
							} else {
								if (cp >= 0x6F0 && cp <= 0x6F3) { // Mapped11: 4
									ret = cp - 0x90;
								} else if (cp >= 0x6F7 && cp <= 0x6F9) { // Mapped11: 3
									ret = cp - 0x90;
								} else if (cp >= 0x13F8 && cp <= 0x13FD) { // Mapped11: 6
									ret = cp - 0x8;
								} else if (cp >= 0x1C90 && cp <= 0x1CBA) { // Mapped11: 43
									ret = cp - 0xBC0;
								}
							}
						}
					} else {
						if (cp <= 0x1F0F) {
							if (cp <= 0x1D5F) {
								if (cp >= 0x1CBD && cp <= 0x1CBF) { // Mapped11: 3
									ret = cp - 0xBC0;
								} else if (cp >= 0x1D33 && cp <= 0x1D3A) { // Mapped11: 8
									ret = cp - 0x1CCC;
								} else if (cp >= 0x1D5D && cp <= 0x1D5F) { // Mapped11: 3
									ret = cp - 0x19AB;
								}
							} else {
								if (cp >= 0x1DA4 && cp <= 0x1DA6) { // Mapped11: 3
									ret = cp - 0x1B3C;
								} else if (cp >= 0x1DAE && cp <= 0x1DB1) { // Mapped11: 4
									ret = cp - 0x1B3C;
								} else if (cp >= 0x1DBC && cp <= 0x1DBE) { // Mapped11: 3
									ret = cp - 0x1B2C;
								} else if (cp >= 0x1F08 && cp <= 0x1F0F) { // Mapped11: 8
									ret = cp - 0x8;
								}
							}
						} else {
							if (cp <= 0x1F4D) {
								if (cp >= 0x1F18 && cp <= 0x1F1D) { // Mapped11: 6
									ret = cp - 0x8;
								} else if (cp >= 0x1F28 && cp <= 0x1F2F) { // Mapped11: 8
									ret = cp - 0x8;
								} else if (cp >= 0x1F38 && cp <= 0x1F3F) { // Mapped11: 8
									ret = cp - 0x8;
								} else if (cp >= 0x1F48 && cp <= 0x1F4D) { // Mapped11: 6
									ret = cp - 0x8;
								}
							} else {
								if (cp >= 0x1F68 && cp <= 0x1F6F) { // Mapped11: 8
									ret = cp - 0x8;
								} else if (cp >= 0x2074 && cp <= 0x2079) { // Mapped11: 6
									ret = cp - 0x2040;
								} else if (cp >= 0x2080 && cp <= 0x2089) { // Mapped11: 10
									ret = cp - 0x2050;
								} else if (cp >= 0x2096 && cp <= 0x2099) { // Mapped11: 4
									ret = cp - 0x202B;
								}
							}
						}
					}
				} else {
					if (cp <= 0x32E9) {
						if (cp <= 0x313F) {
							if (cp <= 0x24CF) {
								if (cp >= 0x2135 && cp <= 0x2138) { // Mapped11: 4
									ret = cp - 0x1B65;
								} else if (cp >= 0x2460 && cp <= 0x2468) { // Mapped11: 9
									ret = cp - 0x242F;
								} else if (cp >= 0x24B6 && cp <= 0x24CF) { // Mapped11: 26
									ret = cp - 0x2455;
								}
							} else {
								if (cp >= 0x24D0 && cp <= 0x24E9) { // Mapped11: 26
									ret = cp - 0x246F;
								} else if (cp >= 0x2C00 && cp <= 0x2C2F) { // Mapped11: 48
									ret = cp + 0x30;
								} else if (cp >= 0x3137 && cp <= 0x3139) { // Mapped11: 3
									ret = cp - 0x2034;
								} else if (cp >= 0x313A && cp <= 0x313F) { // Mapped11: 6
									ret = cp - 0x1F8A;
								}
							}
						} else {
							if (cp <= 0x317C) {
								if (cp >= 0x3141 && cp <= 0x3143) { // Mapped11: 3
									ret = cp - 0x203B;
								} else if (cp >= 0x3145 && cp <= 0x314E) { // Mapped11: 10
									ret = cp - 0x203C;
								} else if (cp >= 0x314F && cp <= 0x3163) { // Mapped11: 21
									ret = cp - 0x1FEE;
								} else if (cp >= 0x3178 && cp <= 0x317C) { // Mapped11: 5
									ret = cp - 0x204D;
								}
							} else {
								if (cp >= 0x3184 && cp <= 0x3186) { // Mapped11: 3
									ret = cp - 0x202D;
								} else if (cp >= 0x3263 && cp <= 0x3265) { // Mapped11: 3
									ret = cp - 0x215E;
								} else if (cp >= 0x3269 && cp <= 0x326D) { // Mapped11: 5
									ret = cp - 0x215B;
								} else if (cp >= 0x32E4 && cp <= 0x32E9) { // Mapped11: 6
									ret = cp - 0x21A;
								}
							}
						}
					} else {
						if (cp <= 0xFF19) {
							if (cp <= 0x32FE) {
								if (cp >= 0x32EE && cp <= 0x32F2) { // Mapped11: 5
									ret = cp - 0x210;
								} else if (cp >= 0x32F5 && cp <= 0x32FA) { // Mapped11: 6
									ret = cp - 0x20D;
								} else if (cp >= 0x32FB && cp <= 0x32FE) { // Mapped11: 4
									ret = cp - 0x20C;
								}
							} else {
								if (cp >= 0xAB70 && cp <= 0xABBF) { // Mapped11: 80
									ret = cp - 0x97D0;
								} else if (cp >= 0xFB24 && cp <= 0xFB26) { // Mapped11: 3
									ret = cp - 0xF549;
								} else if (cp >= 0xFE41 && cp <= 0xFE44) { // Mapped11: 4
									ret = cp - 0xCE35;
								} else if (cp >= 0xFF10 && cp <= 0xFF19) { // Mapped11: 10
									ret = cp - 0xFEE0;
								}
							}
						} else {
							if (cp <= 0xFF93) {
								if (cp >= 0xFF21 && cp <= 0xFF3A) { // Mapped11: 26
									ret = cp - 0xFEC0;
								} else if (cp >= 0xFF41 && cp <= 0xFF5A) { // Mapped11: 26
									ret = cp - 0xFEE0;
								} else if (cp >= 0xFF85 && cp <= 0xFF8A) { // Mapped11: 6
									ret = cp - 0xCEBB;
								} else if (cp >= 0xFF8F && cp <= 0xFF93) { // Mapped11: 5
									ret = cp - 0xCEB1;
								}
							} else {
								if (cp >= 0xFF96 && cp <= 0xFF9B) { // Mapped11: 6
									ret = cp - 0xCEAE;
								} else if (cp >= 0xFFA7 && cp <= 0xFFA9) { // Mapped11: 3
									ret = cp - 0xEEA4;
								} else if (cp >= 0xFFAA && cp <= 0xFFAF) { // Mapped11: 6
									ret = cp - 0xEDFA;
								} else if (cp >= 0xFFB1 && cp <= 0xFFB3) { // Mapped11: 3
									ret = cp - 0xEEAB;
								}
							}
						}
					}
				}
			} else {
				if (cp <= 0x1D503) {
					if (cp <= 0x118BF) {
						if (cp <= 0x10427) {
							if (cp <= 0xFFCF) {
								if (cp >= 0xFFB5 && cp <= 0xFFBE) { // Mapped11: 10
									ret = cp - 0xEEAC;
								} else if (cp >= 0xFFC2 && cp <= 0xFFC7) { // Mapped11: 6
									ret = cp - 0xEE61;
								} else if (cp >= 0xFFCA && cp <= 0xFFCF) { // Mapped11: 6
									ret = cp - 0xEE63;
								}
							} else {
								if (cp >= 0xFFD2 && cp <= 0xFFD7) { // Mapped11: 6
									ret = cp - 0xEE65;
								} else if (cp >= 0xFFDA && cp <= 0xFFDC) { // Mapped11: 3
									ret = cp - 0xEE67;
								} else if (cp >= 0xFFE9 && cp <= 0xFFEC) { // Mapped11: 4
									ret = cp - 0xDE59;
								} else if (cp >= 0x10400 && cp <= 0x10427) { // Mapped11: 40
									ret = cp + 0x28;
								}
							}
						} else {
							if (cp <= 0x1058A) {
								if (cp >= 0x104B0 && cp <= 0x104D3) { // Mapped11: 36
									ret = cp + 0x28;
								} else if (cp >= 0x10570 && cp <= 0x1057A) { // Mapped11: 11
									ret = cp + 0x27;
								} else if (cp >= 0x1057C && cp <= 0x1058A) { // Mapped11: 15
									ret = cp + 0x27;
								}
							} else {
								if (cp >= 0x1058C && cp <= 0x10592) { // Mapped11: 7
									ret = cp + 0x27;
								} else if (cp >= 0x107B6 && cp <= 0x107B8) { // Mapped11: 3
									ret = cp - 0x105F6;
								} else if (cp >= 0x10C80 && cp <= 0x10CB2) { // Mapped11: 51
									ret = cp + 0x40;
								} else if (cp >= 0x118A0 && cp <= 0x118BF) { // Mapped11: 32
									ret = cp + 0x20;
								}
							}
						}
					} else {
						if (cp <= 0x1D481) {
							if (cp <= 0x1D433) {
								if (cp >= 0x16E40 && cp <= 0x16E5F) { // Mapped11: 32
									ret = cp + 0x20;
								} else if (cp >= 0x1D400 && cp <= 0x1D419) { // Mapped11: 26
									ret = cp - 0x1D39F;
								} else if (cp >= 0x1D41A && cp <= 0x1D433) { // Mapped11: 26
									ret = cp - 0x1D3B9;
								}
							} else {
								if (cp >= 0x1D434 && cp <= 0x1D44D) { // Mapped11: 26
									ret = cp - 0x1D3D3;
								} else if (cp >= 0x1D44E && cp <= 0x1D454) { // Mapped11: 7
									ret = cp - 0x1D3ED;
								} else if (cp >= 0x1D456 && cp <= 0x1D467) { // Mapped11: 18
									ret = cp - 0x1D3ED;
								} else if (cp >= 0x1D468 && cp <= 0x1D481) { // Mapped11: 26
									ret = cp - 0x1D407;
								}
							}
						} else {
							if (cp <= 0x1D4B9) {
								if (cp >= 0x1D482 && cp <= 0x1D49B) { // Mapped11: 26
									ret = cp - 0x1D421;
								} else if (cp >= 0x1D4A9 && cp <= 0x1D4AC) { // Mapped11: 4
									ret = cp - 0x1D43B;
								} else if (cp >= 0x1D4AE && cp <= 0x1D4B5) { // Mapped11: 8
									ret = cp - 0x1D43B;
								} else if (cp >= 0x1D4B6 && cp <= 0x1D4B9) { // Mapped11: 4
									ret = cp - 0x1D455;
								}
							} else {
								if (cp >= 0x1D4BD && cp <= 0x1D4C3) { // Mapped11: 7
									ret = cp - 0x1D455;
								} else if (cp >= 0x1D4C5 && cp <= 0x1D4CF) { // Mapped11: 11
									ret = cp - 0x1D455;
								} else if (cp >= 0x1D4D0 && cp <= 0x1D4E9) { // Mapped11: 26
									ret = cp - 0x1D46F;
								} else if (cp >= 0x1D4EA && cp <= 0x1D503) { // Mapped11: 26
									ret = cp - 0x1D489;
								}
							}
						}
					}
				} else {
					if (cp <= 0x1D621) {
						if (cp <= 0x1D550) {
							if (cp <= 0x1D51C) {
								if (cp >= 0x1D507 && cp <= 0x1D50A) { // Mapped11: 4
									ret = cp - 0x1D4A3;
								} else if (cp >= 0x1D50D && cp <= 0x1D514) { // Mapped11: 8
									ret = cp - 0x1D4A3;
								} else if (cp >= 0x1D516 && cp <= 0x1D51C) { // Mapped11: 7
									ret = cp - 0x1D4A3;
								}
							} else {
								if (cp >= 0x1D51E && cp <= 0x1D537) { // Mapped11: 26
									ret = cp - 0x1D4BD;
								} else if (cp >= 0x1D53B && cp <= 0x1D53E) { // Mapped11: 4
									ret = cp - 0x1D4D7;
								} else if (cp >= 0x1D540 && cp <= 0x1D544) { // Mapped11: 5
									ret = cp - 0x1D4D7;
								} else if (cp >= 0x1D54A && cp <= 0x1D550) { // Mapped11: 7
									ret = cp - 0x1D4D7;
								}
							}
						} else {
							if (cp <= 0x1D5B9) {
								if (cp >= 0x1D552 && cp <= 0x1D56B) { // Mapped11: 26
									ret = cp - 0x1D4F1;
								} else if (cp >= 0x1D56C && cp <= 0x1D585) { // Mapped11: 26
									ret = cp - 0x1D50B;
								} else if (cp >= 0x1D586 && cp <= 0x1D59F) { // Mapped11: 26
									ret = cp - 0x1D525;
								} else if (cp >= 0x1D5A0 && cp <= 0x1D5B9) { // Mapped11: 26
									ret = cp - 0x1D53F;
								}
							} else {
								if (cp >= 0x1D5BA && cp <= 0x1D5D3) { // Mapped11: 26
									ret = cp - 0x1D559;
								} else if (cp >= 0x1D5D4 && cp <= 0x1D5ED) { // Mapped11: 26
									ret = cp - 0x1D573;
								} else if (cp >= 0x1D5EE && cp <= 0x1D607) { // Mapped11: 26
									ret = cp - 0x1D58D;
								} else if (cp >= 0x1D608 && cp <= 0x1D621) { // Mapped11: 26
									ret = cp - 0x1D5A7;
								}
							}
						}
					} else {
						if (cp <= 0x1D6C0) {
							if (cp <= 0x1D66F) {
								if (cp >= 0x1D622 && cp <= 0x1D63B) { // Mapped11: 26
									ret = cp - 0x1D5C1;
								} else if (cp >= 0x1D63C && cp <= 0x1D655) { // Mapped11: 26
									ret = cp - 0x1D5DB;
								} else if (cp >= 0x1D656 && cp <= 0x1D66F) { // Mapped11: 26
									ret = cp - 0x1D5F5;
								}
							} else {
								if (cp >= 0x1D670 && cp <= 0x1D689) { // Mapped11: 26
									ret = cp - 0x1D60F;
								} else if (cp >= 0x1D68A && cp <= 0x1D6A3) { // Mapped11: 26
									ret = cp - 0x1D629;
								} else if (cp >= 0x1D6A8 && cp <= 0x1D6B8) { // Mapped11: 17
									ret = cp - 0x1D2F7;
								} else if (cp >= 0x1D6BA && cp <= 0x1D6C0) { // Mapped11: 7
									ret = cp - 0x1D2F7;
								}
							}
						} else {
							if (cp <= 0x1D6FA) {
								if (cp >= 0x1D6C2 && cp <= 0x1D6D2) { // Mapped11: 17
									ret = cp - 0x1D311;
								} else if (cp >= 0x1D6D4 && cp <= 0x1D6DA) { // Mapped11: 7
									ret = cp - 0x1D311;
								} else if (cp >= 0x1D6E2 && cp <= 0x1D6F2) { // Mapped11: 17
									ret = cp - 0x1D331;
								} else if (cp >= 0x1D6F4 && cp <= 0x1D6FA) { // Mapped11: 7
									ret = cp - 0x1D331;
								}
							} else {
								if (cp >= 0x1D6FC && cp <= 0x1D70C) { // Mapped11: 17
									ret = cp - 0x1D34B;
								} else if (cp >= 0x1D70E && cp <= 0x1D714) { // Mapped11: 7
									ret = cp - 0x1D34B;
								} else if (cp >= 0x1D71C && cp <= 0x1D72C) { // Mapped11: 17
									ret = cp - 0x1D36B;
								} else if (cp >= 0x1D72E && cp <= 0x1D734) { // Mapped11: 7
									ret = cp - 0x1D36B;
								}
							}
						}
					}
				}
			}
		} else {
			if (cp <= 0xFB69) {
				if (cp <= 0x1DB) {
					if (cp <= 0x1D7F5) {
						if (cp <= 0x1D7A0) {
							if (cp <= 0x1D766) {
								if (cp >= 0x1D736 && cp <= 0x1D746) { // Mapped11: 17
									ret = cp - 0x1D385;
								} else if (cp >= 0x1D748 && cp <= 0x1D74E) { // Mapped11: 7
									ret = cp - 0x1D385;
								} else if (cp >= 0x1D756 && cp <= 0x1D766) { // Mapped11: 17
									ret = cp - 0x1D3A5;
								}
							} else {
								if (cp >= 0x1D768 && cp <= 0x1D76E) { // Mapped11: 7
									ret = cp - 0x1D3A5;
								} else if (cp >= 0x1D770 && cp <= 0x1D780) { // Mapped11: 17
									ret = cp - 0x1D3BF;
								} else if (cp >= 0x1D782 && cp <= 0x1D788) { // Mapped11: 7
									ret = cp - 0x1D3BF;
								} else if (cp >= 0x1D790 && cp <= 0x1D7A0) { // Mapped11: 17
									ret = cp - 0x1D3DF;
								}
							}
						} else {
							if (cp <= 0x1D7C2) {
								if (cp >= 0x1D7A2 && cp <= 0x1D7A8) { // Mapped11: 7
									ret = cp - 0x1D3DF;
								} else if (cp >= 0x1D7AA && cp <= 0x1D7BA) { // Mapped11: 17
									ret = cp - 0x1D3F9;
								} else if (cp >= 0x1D7BC && cp <= 0x1D7C2) { // Mapped11: 7
									ret = cp - 0x1D3F9;
								}
							} else {
								if (cp >= 0x1D7CE && cp <= 0x1D7D7) { // Mapped11: 10
									ret = cp - 0x1D79E;
								} else if (cp >= 0x1D7D8 && cp <= 0x1D7E1) { // Mapped11: 10
									ret = cp - 0x1D7A8;
								} else if (cp >= 0x1D7E2 && cp <= 0x1D7EB) { // Mapped11: 10
									ret = cp - 0x1D7B2;
								} else if (cp >= 0x1D7EC && cp <= 0x1D7F5) { // Mapped11: 10
									ret = cp - 0x1D7BC;
								}
							}
						}
					} else {
						if (cp <= 0x1F149) {
							if (cp <= 0x1EE0D) {
								if (cp >= 0x1D7F6 && cp <= 0x1D7FF) { // Mapped11: 10
									ret = cp - 0x1D7C6;
								} else if (cp >= 0x1E900 && cp <= 0x1E921) { // Mapped11: 34
									ret = cp + 0x22;
								} else if (cp >= 0x1EE0A && cp <= 0x1EE0D) { // Mapped11: 4
									ret = cp - 0x1E7C7;
								}
							} else {
								if (cp >= 0x1EE2A && cp <= 0x1EE2D) { // Mapped11: 4
									ret = cp - 0x1E7E7;
								} else if (cp >= 0x1EE8B && cp <= 0x1EE8D) { // Mapped11: 3
									ret = cp - 0x1E847;
								} else if (cp >= 0x1EEAB && cp <= 0x1EEAD) { // Mapped11: 3
									ret = cp - 0x1E867;
								} else if (cp >= 0x1F130 && cp <= 0x1F149) { // Mapped11: 26
									ret = cp - 0x1F0CF;
								}
							}
						} else {
							if (cp <= 0x147) {
								if (cp >= 0x1FBF0 && cp <= 0x1FBF9) { // Mapped11: 10
									ret = cp - 0x1FBC0;
								} else if (cp >= 0x100 && cp < 0x130 && (cp & 1 == 0)) { // Mapped22: 24
									ret = cp + 1;
								} else if (cp >= 0x139 && cp < 0x13F && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x141 && cp < 0x149 && (cp & 1 == 0)) { // Mapped22: 4
									ret = cp + 1;
								}
							} else {
								if (cp >= 0x14A && cp < 0x178 && (cp & 1 == 0)) { // Mapped22: 23
									ret = cp + 1;
								} else if (cp >= 0x179 && cp < 0x17F && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x1A0 && cp < 0x1A6 && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x1CD && cp < 0x1DD && (cp & 1 == 0)) { // Mapped22: 8
									ret = cp + 1;
								}
							}
						}
					}
				} else {
					if (cp <= 0xA69A) {
						if (cp <= 0x4BE) {
							if (cp <= 0x232) {
								if (cp >= 0x1DE && cp < 0x1F0 && (cp & 1 == 0)) { // Mapped22: 9
									ret = cp + 1;
								} else if (cp >= 0x1F8 && cp < 0x220 && (cp & 1 == 0)) { // Mapped22: 20
									ret = cp + 1;
								} else if (cp >= 0x222 && cp < 0x234 && (cp & 1 == 0)) { // Mapped22: 9
									ret = cp + 1;
								}
							} else {
								if (cp >= 0x246 && cp < 0x250 && (cp & 1 == 0)) { // Mapped22: 5
									ret = cp + 1;
								} else if (cp >= 0x3D8 && cp < 0x3F0 && (cp & 1 == 0)) { // Mapped22: 12
									ret = cp + 1;
								} else if (cp >= 0x460 && cp < 0x482 && (cp & 1 == 0)) { // Mapped22: 17
									ret = cp + 1;
								} else if (cp >= 0x48A && cp < 0x4C0 && (cp & 1 == 0)) { // Mapped22: 27
									ret = cp + 1;
								}
							}
						} else {
							if (cp <= 0x1EFE) {
								if (cp >= 0x4C1 && cp < 0x4CF && (cp & 1 == 0)) { // Mapped22: 7
									ret = cp + 1;
								} else if (cp >= 0x4D0 && cp < 0x530 && (cp & 1 == 0)) { // Mapped22: 48
									ret = cp + 1;
								} else if (cp >= 0x1E00 && cp < 0x1E96 && (cp & 1 == 0)) { // Mapped22: 75
									ret = cp + 1;
								} else if (cp >= 0x1EA0 && cp < 0x1F00 && (cp & 1 == 0)) { // Mapped22: 48
									ret = cp + 1;
								}
							} else {
								if (cp >= 0x2C67 && cp < 0x2C6D && (cp & 1 == 0)) { // Mapped22: 3
									ret = cp + 1;
								} else if (cp >= 0x2C80 && cp < 0x2CE4 && (cp & 1 == 0)) { // Mapped22: 50
									ret = cp + 1;
								} else if (cp >= 0xA640 && cp < 0xA66E && (cp & 1 == 0)) { // Mapped22: 23
									ret = cp + 1;
								} else if (cp >= 0xA680 && cp < 0xA69C && (cp & 1 == 0)) { // Mapped22: 14
									ret = cp + 1;
								}
							}
						}
					} else {
						if (cp <= 0x210E) {
							if (cp <= 0xA786) {
								if (cp >= 0xA722 && cp < 0xA730 && (cp & 1 == 0)) { // Mapped22: 7
									ret = cp + 1;
								} else if (cp >= 0xA732 && cp < 0xA770 && (cp & 1 == 0)) { // Mapped22: 31
									ret = cp + 1;
								} else if (cp >= 0xA77E && cp < 0xA788 && (cp & 1 == 0)) { // Mapped22: 5
									ret = cp + 1;
								}
							} else {
								if (cp >= 0xA796 && cp < 0xA7AA && (cp & 1 == 0)) { // Mapped22: 10
									ret = cp + 1;
								} else if (cp >= 0xA7B4 && cp < 0xA7C4 && (cp & 1 == 0)) { // Mapped22: 8
									ret = cp + 1;
								} else if (cp >= 0x2010 && cp <= 0x2015) { // Mapped10: 6
									ret = 0x2D;
								} else if (cp >= 0x210B && cp <= 0x210E) { // Mapped10: 4
									ret = 0x68;
								}
							}
						} else {
							if (cp <= 0xFB59) {
								if (cp >= 0x211B && cp <= 0x211D) { // Mapped10: 3
									ret = 0x72;
								} else if (cp >= 0x23BA && cp <= 0x23BD) { // Mapped10: 4
									ret = 0x2D;
								} else if (cp >= 0xFB52 && cp <= 0xFB55) { // Mapped10: 4
									ret = 0x67B;
								} else if (cp >= 0xFB56 && cp <= 0xFB59) { // Mapped10: 4
									ret = 0x67E;
								}
							} else {
								if (cp >= 0xFB5A && cp <= 0xFB5D) { // Mapped10: 4
									ret = 0x680;
								} else if (cp >= 0xFB5E && cp <= 0xFB61) { // Mapped10: 4
									ret = 0x67A;
								} else if (cp >= 0xFB62 && cp <= 0xFB65) { // Mapped10: 4
									ret = 0x67F;
								} else if (cp >= 0xFB66 && cp <= 0xFB69) { // Mapped10: 4
									ret = 0x679;
								}
							}
						}
					}
				}
			} else {
				if (cp <= 0xFECC) {
					if (cp <= 0xFBE7) {
						if (cp <= 0xFB91) {
							if (cp <= 0xFB75) {
								if (cp >= 0xFB6A && cp <= 0xFB6D) { // Mapped10: 4
									ret = 0x6A4;
								} else if (cp >= 0xFB6E && cp <= 0xFB71) { // Mapped10: 4
									ret = 0x6A6;
								} else if (cp >= 0xFB72 && cp <= 0xFB75) { // Mapped10: 4
									ret = 0x684;
								}
							} else {
								if (cp >= 0xFB76 && cp <= 0xFB79) { // Mapped10: 4
									ret = 0x683;
								} else if (cp >= 0xFB7A && cp <= 0xFB7D) { // Mapped10: 4
									ret = 0x686;
								} else if (cp >= 0xFB7E && cp <= 0xFB81) { // Mapped10: 4
									ret = 0x687;
								} else if (cp >= 0xFB8E && cp <= 0xFB91) { // Mapped10: 4
									ret = 0x6A9;
								}
							}
						} else {
							if (cp <= 0xFBA3) {
								if (cp >= 0xFB92 && cp <= 0xFB95) { // Mapped10: 4
									ret = 0x6AF;
								} else if (cp >= 0xFB96 && cp <= 0xFB99) { // Mapped10: 4
									ret = 0x6B3;
								} else if (cp >= 0xFB9A && cp <= 0xFB9D) { // Mapped10: 4
									ret = 0x6B1;
								} else if (cp >= 0xFBA0 && cp <= 0xFBA3) { // Mapped10: 4
									ret = 0x6BB;
								}
							} else {
								if (cp >= 0xFBA6 && cp <= 0xFBA9) { // Mapped10: 4
									ret = 0x6C1;
								} else if (cp >= 0xFBAA && cp <= 0xFBAD) { // Mapped10: 4
									ret = 0x6BE;
								} else if (cp >= 0xFBD3 && cp <= 0xFBD6) { // Mapped10: 4
									ret = 0x6AD;
								} else if (cp >= 0xFBE4 && cp <= 0xFBE7) { // Mapped10: 4
									ret = 0x6D0;
								}
							}
						}
					} else {
						if (cp <= 0xFEA4) {
							if (cp <= 0xFE92) {
								if (cp >= 0xFBFC && cp <= 0xFBFF) { // Mapped10: 4
									ret = 0x6CC;
								} else if (cp >= 0xFE89 && cp <= 0xFE8C) { // Mapped10: 4
									ret = 0x626;
								} else if (cp >= 0xFE8F && cp <= 0xFE92) { // Mapped10: 4
									ret = 0x628;
								}
							} else {
								if (cp >= 0xFE95 && cp <= 0xFE98) { // Mapped10: 4
									ret = 0x62A;
								} else if (cp >= 0xFE99 && cp <= 0xFE9C) { // Mapped10: 4
									ret = 0x62B;
								} else if (cp >= 0xFE9D && cp <= 0xFEA0) { // Mapped10: 4
									ret = 0x62C;
								} else if (cp >= 0xFEA1 && cp <= 0xFEA4) { // Mapped10: 4
									ret = 0x62D;
								}
							}
						} else {
							if (cp <= 0xFEBC) {
								if (cp >= 0xFEA5 && cp <= 0xFEA8) { // Mapped10: 4
									ret = 0x62E;
								} else if (cp >= 0xFEB1 && cp <= 0xFEB4) { // Mapped10: 4
									ret = 0x633;
								} else if (cp >= 0xFEB5 && cp <= 0xFEB8) { // Mapped10: 4
									ret = 0x634;
								} else if (cp >= 0xFEB9 && cp <= 0xFEBC) { // Mapped10: 4
									ret = 0x635;
								}
							} else {
								if (cp >= 0xFEBD && cp <= 0xFEC0) { // Mapped10: 4
									ret = 0x636;
								} else if (cp >= 0xFEC1 && cp <= 0xFEC4) { // Mapped10: 4
									ret = 0x637;
								} else if (cp >= 0xFEC5 && cp <= 0xFEC8) { // Mapped10: 4
									ret = 0x638;
								} else if (cp >= 0xFEC9 && cp <= 0xFECC) { // Mapped10: 4
									ret = 0x639;
								}
							}
						}
					}
				} else {
					if (cp <= 0xD7A3) {
						if (cp <= 0xFEE8) {
							if (cp <= 0xFED8) {
								if (cp >= 0xFECD && cp <= 0xFED0) { // Mapped10: 4
									ret = 0x63A;
								} else if (cp >= 0xFED1 && cp <= 0xFED4) { // Mapped10: 4
									ret = 0x641;
								} else if (cp >= 0xFED5 && cp <= 0xFED8) { // Mapped10: 4
									ret = 0x642;
								}
							} else {
								if (cp >= 0xFED9 && cp <= 0xFEDC) { // Mapped10: 4
									ret = 0x643;
								} else if (cp >= 0xFEDD && cp <= 0xFEE0) { // Mapped10: 4
									ret = 0x644;
								} else if (cp >= 0xFEE1 && cp <= 0xFEE4) { // Mapped10: 4
									ret = 0x645;
								} else if (cp >= 0xFEE5 && cp <= 0xFEE8) { // Mapped10: 4
									ret = 0x646;
								}
							}
						} else {
							if (cp <= 0x167F) {
								if (cp >= 0xFEE9 && cp <= 0xFEEC) { // Mapped10: 4
									ret = 0x647;
								} else if (cp >= 0xFEF1 && cp <= 0xFEF4) { // Mapped10: 4
									ret = 0x64A;
								} else if (cp >= 0x2F831 && cp <= 0x2F833) { // Mapped10: 3
									ret = 0x537F;
								} else if (cp >= 0x1400 && cp <= 0x167F) { // Valid
									ret = cp;
								}
							} else {
								if (cp >= 0x2801 && cp <= 0x2933) { // Valid
									ret = cp;
								} else if (cp >= 0x3400 && cp <= 0xA48C) { // Valid
									ret = cp;
								} else if (cp >= 0xA4D0 && cp <= 0xA62B) { // Valid
									ret = cp;
								} else if (cp >= 0xAC00 && cp <= 0xD7A3) { // Valid
									ret = cp;
								}
							}
						}
					} else {
						if (cp <= 0x18CD5) {
							if (cp <= 0x1342E) {
								if (cp >= 0x10600 && cp <= 0x10736) { // Valid
									ret = cp;
								} else if (cp >= 0x11FFF && cp <= 0x12399) { // Valid
									ret = cp;
								} else if (cp >= 0x13000 && cp <= 0x1342E) { // Valid
									ret = cp;
								}
							} else {
								if (cp >= 0x14400 && cp <= 0x14646) { // Valid
									ret = cp;
								} else if (cp >= 0x16800 && cp <= 0x16A38) { // Valid
									ret = cp;
								} else if (cp >= 0x17000 && cp <= 0x187F7) { // Valid
									ret = cp;
								} else if (cp >= 0x18800 && cp <= 0x18CD5) { // Valid
									ret = cp;
								}
							}
						} else {
							if (cp <= 0x2A6DF) {
								if (cp >= 0x1B000 && cp <= 0x1B122) { // Valid
									ret = cp;
								} else if (cp >= 0x1B170 && cp <= 0x1B2FB) { // Valid
									ret = cp;
								} else if (cp >= 0x1D800 && cp <= 0x1DA8B) { // Valid
									ret = cp;
								} else if (cp >= 0x20000 && cp <= 0x2A6DF) { // Valid
									ret = cp;
								}
							} else {
								if (cp >= 0x2A700 && cp <= 0x2B738) { // Valid
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
				}
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