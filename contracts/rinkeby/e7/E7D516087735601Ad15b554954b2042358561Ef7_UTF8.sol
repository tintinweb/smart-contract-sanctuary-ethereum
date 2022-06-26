// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

library UTF8 {

    error InvalidUTF8();

    function decode(bytes memory v) public pure returns (uint24[] memory cps) {
        uint256 n = v.length;
		cps = new uint24[](n);
		uint256 i;
		uint256 j;
		unchecked { while (i < n) {
			uint256 cp = uint8(v[i++]);
			if ((cp & 0x80) == 0) { // [1] 0xxxxxxx
				//
			} else if ((cp & 0xE0) == 0xC0) { // [2] 110xxxxx (5)
				if (i >= n) revert InvalidUTF8();
				uint256 a = uint8(v[i++]);
				if ((a & 0xC0) != 0x80) revert InvalidUTF8();
				cp = ((cp & 0x1F) << 6) | a;
				if (cp < 0x80) revert InvalidUTF8();
			} else if ((cp & 0xF0) == 0xE0) { // [3] 1110xxxx (4)
				if (i + 2 > n) revert InvalidUTF8();
				uint256 a = uint8(v[i++]);
				uint256 b = uint8(v[i++]);
				if (((a | b) & 0xC0) != 0x80) revert InvalidUTF8();
				cp = ((cp & 0xF) << 12) | ((a & 0x3F) << 6) | (b & 0x3F);
				if (cp < 0x0800) revert InvalidUTF8();
			} else if ((cp & 0xF8) == 0xF0) { // [4] 11110xxx (3)
				if (i + 3 > n) revert InvalidUTF8();
				uint256 a = uint8(v[i++]);
				uint256 b = uint8(v[i++]);
				uint256 c = uint8(v[i++]);
				if (((a | b | c) & 0xC0) != 0x80) revert InvalidUTF8();
				cp = ((cp & 0x7) << 18) | ((a & 0x3F) << 12) | ((b & 0x3F) << 6) | (c & 0x3F);
				if (cp < 0x10000 || cp > 0x10FFFF) revert InvalidUTF8();
			} else {
				revert InvalidUTF8();
			}
			cps[j++] = uint24(cp);
		} }
		assembly { mstore(cps, j) }
    }

}