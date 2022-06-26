// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

library EmojiLib {
 
    struct Emoji {
        mapping (uint256 => uint256) states;
    }

    function upload(Emoji storage self, bytes memory v) public {
        uint256 i;
        uint256 e;
        uint256 x;
        assembly {
            i := v
            e := sub(add(v, mload(v)), 1)
        }
        while (i < e) {
            assembly {
                i := add(i, 6) 
                x := mload(i) 
            }
            self.states[(x >> 16) & 0xFFFFFFFF] = x & 0xFFFF;
        }
    }

    function get(Emoji storage self, uint256 state) public view returns (uint256) {
        return self.states[state];
    }

    function read(Emoji storage self, uint24[] memory cps, uint256 pos, bool skipFE0F) public view returns (uint256) {       
        uint256 state;
        uint256 saved;
        uint256 cp;
        uint256 len;
        while (pos < cps.length) {
            cp = cps[pos++];
            if (skipFE0F && cp == 0xFE0F) {
                len++;                
            } else {
                state = self.states[((state & 0xFF) << 24) | cp];
                if (state == 0) break;
                if ((state & 0x8000) != 0) {
                    if (cp == saved) break;
                } else if ((state & 0x4000) != 0) {
                    saved = cp;
                }
                len += (state >> 8) & 0x3F;
            }
        }
        return len;
    }

    function filter(Emoji storage self, uint24[] memory cps, bool skipFE0F) public view returns (uint24[] memory ret) {  
        uint256 out;
        uint256 pos;
        ret = new uint24[](cps.length);
        unchecked { while (pos < cps.length) {
            uint256 len = read(self, cps, pos, skipFE0F);
            if (len > 0) {
                ret[out] = 0xFFFFFF;
                pos += len;
            } else {
                ret[out] = cps[pos];
                pos++;
            }
            out++;
        } }
        assembly { mstore(ret, out) }
    }
    
}