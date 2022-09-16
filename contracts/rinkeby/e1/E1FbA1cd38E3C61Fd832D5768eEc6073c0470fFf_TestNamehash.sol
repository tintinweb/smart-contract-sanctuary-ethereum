// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import "./Namehash.sol";

contract TestNamehash {
    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes32 public baseNode = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
    bytes32 public a = 0x0;
    address public b = address(0x0);

    // 一级域名的namehash，比如“fil.eth”
    function namehash1(string memory name) public view returns(bytes32, uint256, bytes32) {
        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);
        bytes32 nodehash = keccak256(abi.encodePacked(baseNode, label));
        return (label, tokenId, nodehash);
    }

    // 一级域名的namehash，比如“fil.eth”
    function namehash2(bytes32 baseNode1, string memory name) public pure returns(bytes32, uint256, bytes32) {
        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);
        bytes32 nodehash = keccak256(abi.encodePacked(baseNode1, label));
        return (label, tokenId, nodehash);
    }

    // 顶级域名的namehash，比如“eth”
    function namehash0(string memory name) public pure returns(bytes32, uint256, bytes32) {
        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);
        bytes32 baseNode0 = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes32 nodehash = keccak256(abi.encodePacked(baseNode0, label));
        return (label, tokenId, nodehash);
    }

    function getNamehash(string memory name) pure public returns(bytes32 hash) {
        return Namehash.namehash(name);
    }

    function inteId(string memory name) public pure returns (bytes32) {
        return keccak256(bytes(name));
    }

    function inteId2() public pure returns (bytes4) {
        return bytes4(keccak256(bytes('addr(bytes32, uint)')));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Strings {
    struct slice {
        uint _len;
        uint _ptr;
    }
    
    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }
    
    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }
    
    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }
}

library Namehash {
    using Strings for *;
    
    function namehash(string memory name) pure internal returns(bytes32 hash) {
        hash = bytes32(0);
        Strings.slice memory nameslice = name.toSlice();
        Strings.slice memory delim = ".".toSlice();
        Strings.slice memory token;
        for(nameslice.rsplit(delim, token); !token.empty(); nameslice.rsplit(delim, token)) {
            hash = keccak256(abi.encodePacked(hash, token.keccak()));
        }
        return hash;
    }
}