// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library MemoryLib {
    function memcpy(
        uint256 ptr_dest,
        uint256 ptr_src,
        uint256 length
    ) internal pure {
        for (; length >= 0x20; length -= 0x20) {
            assembly {
                mstore(ptr_dest, mload(ptr_src))
                ptr_src := add(ptr_src, 0x20)
                ptr_dest := add(ptr_dest, 0x20)
            }
        }
        assembly {
            let mask := sub(exp(256, sub(32, length)), 1)
            let a := and(mload(ptr_src), not(mask))
            let b := and(mload(ptr_dest), mask)
            mstore(ptr_dest, or(a, b))
        }
    }

    function memcat(uint256 ptr_l, uint256 ptr_r) internal pure returns (uint256) {
        uint256 len_l;
        uint256 len_r;
        uint256 length;
        assembly {
            len_l := mload(ptr_l)
            len_r := mload(ptr_r)
            ptr_l := add(ptr_l, 0x20)
            ptr_r := add(ptr_r, 0x20)
            length := add(len_r, len_l)
        }
        uint256 rt = calloc(length);
        uint256 ptr = rt + 32;
        memcpy(ptr, ptr_l, len_l);
        ptr += len_l;
        memcpy(ptr, ptr_r, len_r);
        assembly {
            length := mload(rt)
        }
        return rt;
    }

    function memcut(
        uint256 ptr,
        uint256 pos,
        uint256 size
    ) internal pure {
        uint256 len;
        assembly {
            len := mload(ptr)
            ptr := add(ptr, 0x20)
        }
        if (len < pos + size) {
            return;
        }
        memcpy(ptr + pos, ptr + pos + size, len - size - pos);
        assembly {
            mstore(sub(ptr, 0x20), sub(len, size))
        }
    }

    function calloc(uint256 size) internal pure returns (uint256 ptr) {
        assembly {
            ptr := mload(0x40)
            mstore(ptr, size)
            mstore(0x40, add(ptr, add(size, 0x20)))
        }
        return ptr;
    }

    function find(
        uint256 ptr,
        uint256 target,
        uint256 pos
    ) internal pure returns (int256) {
        uint256 target_len;
        uint256 ptr_len;

        assembly {
            target_len := mload(target)
            ptr_len := mload(ptr)
            ptr := add(ptr, add(32, pos))
            target := add(target, 0x20)
        }
        if (pos > ptr_len || target_len + pos > ptr_len) {
            return -1;
        }
        uint256 find_end = ptr_len - target_len + 1;
        uint256 target_val;
        uint256 mask = ~(256**(32 - target_len) - 1);
        assembly {
            target_val := and(mload(target), mask)
        }
        uint256 ptr_val;
        for (; pos < find_end; pos++) {
            assembly {
                ptr_val := and(mload(ptr), mask)
                ptr := add(ptr, 1)
            }
            if (target_val == ptr_val) {
                return int256(pos);
            }
        }
        return -1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./MemoryLib.sol";

library StringsLib{
    struct Data {
        mapping (bytes1 => string) encodeMap;
    }
    function concat(string memory r, string memory l) public pure returns(string memory){
        uint ptr_r;
        uint ptr_l;
        assembly{
            ptr_r := r
            ptr_l := l
        }
        uint ptr = MemoryLib.memcat(ptr_r, ptr_l);
        uint len;
        assembly{
            len := mload(ptr)
        }
        string memory rt;
        assembly{
            rt := ptr
        }
        return rt;
    }    
    
    function find(string memory str, string memory target, uint pos) internal pure returns(int){
        uint ptr_str;
        uint ptr_target;
        assembly{
            ptr_str := str
            ptr_target := target
        }
        return MemoryLib.find(ptr_str, ptr_target, pos);
    } 

    function remove(string memory str, string memory target, int count) internal pure returns(string memory){
        uint ptr_str;
        uint ptr_target;
        uint len_target;
        assembly{
            ptr_str := str
            ptr_target := target
            len_target := mload(target)
        }
        for(;;){
            int pos = MemoryLib.find(ptr_str, ptr_target, 0);
            if(pos>=0){
                MemoryLib.memcut(ptr_str, uint(pos), len_target);
                if(count>0){
                    count--;
                    if(count<1){
                        break;
                    }
                }
                continue;
            }
            break;
        }
        return str;
    }    

    function contains(string memory str, string memory target) internal pure returns(bool){
        return find(str, target, 0) > -1;
    }

    function startwith(string memory str, string memory target) internal pure returns(bool){
         return find(str, target, 0) == 0 ;
    }

    function endwith(string memory str, string memory target) internal pure returns(bool){
         uint pos = bytes(str).length-bytes(target).length;
         return find(str, target, pos) == int(pos);  
    }
    
    event P(uint v, string k);
    
    function replace(string memory str, string memory a, string memory b, int count) internal pure returns(string memory){
        uint len_a;
        uint len_b;
        uint len_str;
        uint ptr_str;
        uint ptr_a;
        uint ptr_b;
   
        assembly{
            ptr_str := str
            ptr_a := a
            ptr_b := b
            len_a := mload(a)
            len_b := mload(b)
            len_str := mload(str)
        }
        if(len_b == 0){
            return str;
        }
        if(len_str < len_a){
            return str;
        }
        int pos = MemoryLib.find(ptr_str, ptr_a, 0);
        if(pos<0){
            return str;
        }
        if(len_a>=len_b){
            for(
                uint times =0;
                pos>=0; 
                pos = MemoryLib.find(ptr_str, ptr_a, uint(pos)+len_b)
            ){
                MemoryLib.memcpy(ptr_str+0x20 + uint(pos), ptr_b+0x20, len_b);
                MemoryLib.memcpy(ptr_str+0x20+uint(pos)+len_b, ptr_str+0x20+uint(pos)+len_a, len_str-uint(pos)-len_a);
                len_str = len_str - len_a + len_b; 
                assembly{
                    mstore(ptr_str, len_str)
                }
                if(count>0){
                    count--;
                    if(count==0){
                        break;
                    }
                }
                times++;
            }
            return str;
        }else{
            uint ptr  = MemoryLib.calloc(len_str + (len_str/len_a)*(len_b-len_a));
            uint size = 0;
            int last_cpy_pos = 0;
            for( 
                ;
                pos>=0;
                pos = MemoryLib.find(ptr_str, ptr_a, uint(pos)+len_a)
            ){
                MemoryLib.memcpy(ptr+0x20+size, ptr_str+0x20 + uint(last_cpy_pos), uint(pos-last_cpy_pos));
                size += uint(pos-last_cpy_pos);
                MemoryLib.memcpy(ptr+size+0x20, ptr_b+0x20, len_b);
                last_cpy_pos = pos + int(len_a);
                size += uint(len_b);
                if(count>0){
                    count--;
                    if(count==0){
                        break;
                    }
                }
            }
            MemoryLib.memcpy(ptr+0x20+size, ptr_str+0x20+uint(last_cpy_pos), len_str-uint(last_cpy_pos));
            size += len_str-uint(last_cpy_pos);
            assembly{
                mstore(ptr, size)
                str := ptr
            }
        }
        return str;
    }
    
    function len(string memory str) internal pure returns(uint){
        uint ptr;
        uint len;
        assembly{
            ptr := add(str, 0x20)
            len := mload(str)
        }
        uint val;
        uint pos;
        uint runes = 0;
        for(;pos<len;){
            assembly{
                val := and(0xff, mload(add(ptr, pos)))
            }
            if (val < 0x80) {
                pos += 1;
            } else if(val < 0xE0) {
                pos += 2;
            } else if(val < 0xF0) {
                pos += 3;
            } else if(val < 0xF8) {
                pos += 4;
            } else if(val < 0xFC) {
                pos += 5;
            } else {
                pos += 6;
            }
            runes++;
        }
        return runes;
    }

    function urlEncode(string memory str, Data storage self) internal returns (string memory){
        // Unsafe Characters Encoding
        self.encodeMap[" "]="%20";
        self.encodeMap["\""]="%22";
        self.encodeMap["<"]="%3c";
        self.encodeMap[">"]="%3e";
        self.encodeMap["#"]="%23";
        self.encodeMap["%"]="%25";
        self.encodeMap["{"]="%7b";
        self.encodeMap["}"]="%7d";
        self.encodeMap["|"]="%7c";
        self.encodeMap["\\"]="%5c";
        self.encodeMap["^"]="%5e";
        self.encodeMap["~"]="%7e";
        self.encodeMap["["]="%5b";
        self.encodeMap["]"]="%5d";
        self.encodeMap["`"]="%60";
        // Reserved Characters Encoding
        self.encodeMap["$"]="%24";
        self.encodeMap["&"]="%26";
        self.encodeMap["+"]="%2b";
        self.encodeMap[","]="%2c";
        self.encodeMap["/"]="%2f";
        self.encodeMap[":"]="%3a";
        self.encodeMap[";"]="%3b";
        self.encodeMap["="]="%3d";
        self.encodeMap["?"]="%3f";
        self.encodeMap["@"]="%40";

        bytes memory inputString = bytes(str);
        bytes memory workingString = inputString;
        for (uint i = 0; i< inputString.length; i++){
            bytes1 character = inputString[i];
            string memory substitution = self.encodeMap[character];
            if (len(substitution) != 0) {
                string memory theCharacter = new string(1);
                bytes memory bytesString = bytes(theCharacter);
                bytesString[0] = character;
                workingString = bytes(replace(string(workingString), string(bytesString), substitution, 0));
            }
        }
        return string(workingString);
    }
}