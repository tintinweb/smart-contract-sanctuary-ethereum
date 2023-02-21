/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

/*
    String Slice Functions
    Taken from @Arachnid/src/strings.sol
*/

struct slice {
    uint _len;
    uint _ptr;
}

function slice_join(slice memory self, slice[] memory parts) pure returns (string memory) {
    if (parts.length == 0)
        return "";

    uint length = self._len * (parts.length - 1);
    for(uint i = 0; i < parts.length; i++)
        length += parts[i]._len;

    string memory ret = new string(length);
    uint retptr;
    assembly { retptr := add(ret, 32) }

    for(uint i = 0; i < parts.length; i++) {
        slice_memcpy(retptr, parts[i]._ptr, parts[i]._len);
        retptr += parts[i]._len;
        if (i < parts.length - 1) {
            slice_memcpy(retptr, self._ptr, self._len);
            retptr += self._len;
        }
    }

    return ret;
}

function slice_memcpy(uint dest, uint src, uint len) pure {
    // Copy word-length chunks while possible
    for(; len >= 32; len -= 32) {
        assembly {
            mstore(dest, mload(src))
        }
        dest += 32;
        src += 32;
    }

    // Copy remaining bytes
    uint _mask = type(uint).max;
    if (len > 0) {
        _mask = 256 ** (32 - len) - 1;
    }
    assembly {
        let srcpart := and(mload(src), not(_mask))
        let destpart := and(mload(dest), _mask)
        mstore(dest, or(destpart, srcpart))
    }
}

function slice_toSlice(string memory self) pure returns (slice memory) {
    uint ptr;
    assembly {
        ptr := add(self, 0x20)
    }
    return slice(bytes(self).length, ptr);
}

/*
    Utility Functions
*/

bytes16 constant HEX_SYMBOLS = "0123456789ABCDEF";
function get3Hex(uint256 valueA, uint256 valueB, uint256 valueC) pure returns (string memory) {
    // Each value must be < 256.
    bytes memory buffer = new bytes(7);
    buffer[0] = "#";
    buffer[1] = HEX_SYMBOLS[(valueA & 0xf0) >> 4];
    buffer[2] = HEX_SYMBOLS[valueA & 0xf];
    buffer[3] = HEX_SYMBOLS[(valueB & 0xf0) >> 4];
    buffer[4] = HEX_SYMBOLS[valueB & 0xf];
    buffer[5] = HEX_SYMBOLS[(valueC & 0xf0) >> 4];
    buffer[6] = HEX_SYMBOLS[valueC & 0xf];

    return string(buffer);
}

bytes16 constant DECIMAL_SYMBOLS = "0123456789";
function uint256ToStringFast(uint256 _i) pure returns (string memory) {
    // Only works for values < 1000
    bytes memory buffer;
    if(_i < 10) {
        buffer = new bytes(1);
        buffer[0] = DECIMAL_SYMBOLS[_i];
    }
    else if(_i < 100) {
        buffer = new bytes(2);
        buffer[0] = DECIMAL_SYMBOLS[_i / 10];
        buffer[1] = DECIMAL_SYMBOLS[_i % 10];
    }
    else {
        buffer = new bytes(3);
        buffer[0] = DECIMAL_SYMBOLS[(_i / 10) / 10];
        buffer[1] = DECIMAL_SYMBOLS[(_i / 10) % 10];
        buffer[2] = DECIMAL_SYMBOLS[_i % 10];
    }

    return string(buffer);
}

contract PixelPrismaticaUtils {
    /*
        RNG Variables
    */

    uint256 private constant addend = 0xB;
    uint256 private constant mask = (1 << 48) - 1;
    uint256 private constant multiplier = 0x5DEECE66D;
    
    uint256 private immutable rnd0;

    constructor() {
        // Initialize RNG seed.
        rnd0 = ((uint256(blockhash(block.number - 1))) ^ multiplier) & mask;
    }

    /*
        RNG Functions
    */

    function getInitialSeed() public view returns (uint256) {
        return rnd0;
    }

    function nextInt(uint256 n, uint256[2] memory RND) public pure returns (uint256) {
        // Return a random integer.
        // Only call if n is not a power of 2.
        RND[0] = (RND[0] * multiplier + addend + RND[1]) & mask;
        return (RND[0] >> 17) % n;
    }

    function nextInt2P(uint256 n, uint256[2] memory RND) public pure returns (uint256) {
        // Return a random integer.
        // Only call if n is a power of 2.
        RND[0] = (RND[0] * multiplier + addend + RND[1]) & mask;
        return (n * (RND[0] >> 17)) >> 31;
    }

    /*
        Color Functions
    */

    function getColorString(bytes4 _selector, uint256[2] memory RND) public view returns (string memory, uint256[2] memory) {
        bytes memory data = abi.encodeWithSelector(_selector, RND);
        (bool success, bytes memory returnData) = address(this).staticcall(data);
        assert(success);
        return abi.decode(returnData, (string, uint256[2]));
    }

    function getRainbowLightColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 c = 255;
        uint256 r = nextInt(6, RND);

        string memory s;
        if(r == 0) {
            s = get3Hex(c, 0, 0);
        }
        else if(r == 1) {
            s = get3Hex(0, c, 0);
        }
        else if(r == 2) {
            s = get3Hex(0, 0, c);
        }
        else if(r == 3) {
            s = get3Hex(0, c, c);
        }
        else if(r == 4) {
            s = get3Hex(c, c, 0);
        }
        else if(r == 5) {
            s = get3Hex(c, 0, c);
        }
        else {
            s = "?";
        }

        return (s, RND);
    }

    function getRainbowDarkColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 c = 128;
        uint256 r = nextInt(6, RND);

        string memory s;
        if(r == 0) {
            s = get3Hex(c, 0, 0);
        }
        else if(r == 1) {
            s = get3Hex(0, c, 0);
        }
        else if(r == 2) {
            s = get3Hex(0, 0, c);
        }
        else if(r == 3) {
            s = get3Hex(0, c, c);
        }
        else if(r == 4) {
            s = get3Hex(c, c, 0);
        }
        else if(r == 5) {
            s = get3Hex(c, 0, c);
        }
        else {
            s = "?";
        }

        return (s, RND);
    }

    function getMonochromeColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 c = nextInt2P(256, RND);
        return (get3Hex(c, c, c), RND);
    }

    function getRedColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 c = nextInt2P(256, RND);
        return (get3Hex(c, 0, 0), RND);
    }

    function getGreenColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 c = nextInt2P(256, RND);
        return (get3Hex(0, c, 0), RND);
    }

    function getBlueColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 c = nextInt2P(256, RND);
        return (get3Hex(0, 0, c), RND);
    }

    function getGreenBlueColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 cA = nextInt2P(256, RND);
        uint256 cB = nextInt2P(256, RND);
        return (get3Hex(0, cA, cB), RND);
    }

    function getRedGreenColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 cA = nextInt2P(256, RND);
        uint256 cB = nextInt2P(256, RND);
        return (get3Hex(cA, cB, 0), RND);
    }

    function getRedBlueColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 cA = nextInt2P(256, RND);
        uint256 cB = nextInt2P(256, RND);
        return (get3Hex(cA, 0, cB), RND);
    }

    function getCyanColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 c = nextInt2P(256, RND);
        return (get3Hex(0, c, c), RND);
    }

    function getYellowColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 c = nextInt2P(256, RND);
        return (get3Hex(c, c, 0), RND);
    }

    function getMagentaColorString(uint256[2] memory RND) public pure returns (string memory, uint256[2] memory) {
        uint256 c = nextInt2P(256, RND);
        return (get3Hex(c, 0, c), RND);
    }
}