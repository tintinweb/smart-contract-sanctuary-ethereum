// Punycode Decoder
// https://datatracker.ietf.org/doc/html/rfc3492    
// https://github.com/adraffy/punycode.js/blob/main/index.js
/// @author raffy.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Punycode {

    // demo
    function decode(string memory s) public pure returns (string memory) {
        return string(unsafeDecodeLabel(bytes(s)));
    }
    
    // https://datatracker.ietf.org/doc/html/rfc3492#section-5
    uint256 constant BASE = 36; // 10 + 26
    uint256 constant BIAS = 72;
    uint256 constant T_MIN = 1;
    uint256 constant T_MAX = 26;
    uint256 constant SKEW = 38;
    uint256 constant DAMP = 700;
    uint256 constant SHIFT_BASE = BASE - T_MIN;
    uint256 constant MAX_DELTA = (SHIFT_BASE * T_MAX) >> 1;
    uint256 constant MIN_CP = 0x80;
    uint256 constant MAX_CP = 0x10FFFF;

    // A decoder MUST recognize the letters in both uppercase and lowercase
    // forms (including mixtures of both forms).
    function _basicFromChar(uint256 ch) private pure returns (uint256) {
        unchecked {
            if (ch <= 90) { 
                if (ch <= 57) {
                    if (ch >= 48) {
                        return ch - 22; // [0-9] => 26-35
                    }
                } else if (ch >= 65) {
                    return ch - 65; // [A-Z] => 0-25
                }
            } else if (ch <= 122) {
                if (ch >= 97) {
                    return ch - 97; // [a-z] => 0-25
                }
            }
            return BASE; 
        }
    }

    // https://datatracker.ietf.org/doc/html/rfc3492#section-6.2
    function unsafeDecodeLabel(bytes memory src) public pure returns (bytes memory ret) {
        unchecked {
            uint256 end = src.length;
            if (end < 4 || bytes4(src) != "xn--") return src; // not needed
            ret = new bytes(end << 2); // treat as packed uint32[]
            uint256 len; // number of codepoints
            // find last hyphen
            uint256 off = end; // work backwards
            uint256 start = 4; // len("xn--")
            while (off > start) {
                if (src[--off] == '-') { // found it
                    len = off - start; // number before hyphen
                    uint256 aligned = 3; // ascii -> uint32 => 000X
                    while (start < off) {
                        bytes1 ch = src[start++];
                        require(uint8(ch) < MIN_CP, "ascii");
                        ret[aligned] = ch;
                        aligned += 4;
                    }
                    start++; // skip hyphen
                    break;
                }
            }
            // decode
            uint256 bias = BIAS;
            uint256 cp = MIN_CP;
            uint256 i;
            while (start < end) {
                uint256 prev = i;
                uint256 w = 1;
                uint256 k;
                while (true) {
                    require(start < end, "overflow");
                    uint256 basic = _basicFromChar(uint8(src[start++]));
                    require(basic < BASE, "basic");
                    i += basic * w;
                    k += BASE;
                    uint256 t = _trimBias(k, bias);
                    if (basic < t) break;
                    w *= BASE - t;
                }    
                bias = _adaptBias(i - prev, ++len, prev == 0);            
                cp += i / len;
                require(cp >= MIN_CP && cp <= MAX_CP, "invalid");
                i %= len;
                // insert
                uint256 head;
                uint256 save;
                uint256 tail;
                assembly {
                    head := add(add(ret, 32), shl(2, i)) 
                    save := mload(head) 
                    tail := add(ret, shl(2, len))
                }
                while (head <= tail) { // work backwards
                    assembly {                
                        mstore(add(tail, 4), mload(tail)) // shift right
                    }
                    tail -= 32;
                }
                assembly {
                   mstore(head, or(shl(224, cp), shr(32, save))) // insert
                }
                i++;
            }
            // encode as utf8
            assembly {
                off := ret
            }
            uint256 n;
            while (len != 0) {
                len--;
                off += 4;
                assembly {
                    cp := and(mload(off), 0xFFFFFFFF) // read uint32
                }
                n = _writeUTF8(ret, n, cp); // encode
            }
            assembly {
                mstore(ret, n) // truncate
            }
        }
    }

    function _trimBias(uint256 k, uint256 bias) private pure returns (uint256) {
        unchecked {        
            if (k <= bias) return T_MIN;
            uint256 delta = k - bias;
            return delta > T_MAX ? T_MAX : delta;
        }
    }
 
    // https://datatracker.ietf.org/doc/html/rfc3492#section-6.1
    function _adaptBias(uint256 delta, uint256 len, bool first) private pure returns (uint256) {       
        unchecked {
            delta = delta / (first ? DAMP : 2);
            delta += (delta / len);
            uint256 k = 0;
            while (delta > MAX_DELTA) {
                delta /= SHIFT_BASE;
                k += BASE;
            }
            return k + ((1 + SHIFT_BASE) * delta / (delta + SKEW));
        }
    }

    // write codepoint as utf8 into buf at pos
    // return new pos
    function _writeUTF8(bytes memory buf, uint256 pos, uint256 cp) private pure returns (uint256) {		
        if (cp < 0x80) {
            buf[pos] = bytes1(uint8(cp));
            return pos + 1;
		}
        if (cp < 0x800) {
            buf[pos++] = bytes1(uint8(0xC0 | (cp >> 6)));
            buf[pos++] = bytes1(uint8(0x80 | (cp & 0x3F)));
    	} else if (cp < 0x10000) {
            buf[pos++] = bytes1(uint8(0xE0 | (cp >> 12)));
            buf[pos++] = bytes1(uint8(0x80 | ((cp >> 6) & 0x3F)));
            buf[pos++] = bytes1(uint8(0x80 | (cp & 0x3F)));
		} else {
			buf[pos++] = bytes1(uint8(0xF0 | (cp >> 18)));
            buf[pos++] = bytes1(uint8(0x80 | ((cp >> 12) & 0x3F)));
            buf[pos++] = bytes1(uint8(0x80 | ((cp >> 6) & 0x3F)));
            buf[pos++] = bytes1(uint8(0x80 | (cp & 0x3F)));
		}
        return pos;
	}

}