// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./solidity-stringutils/strings.sol";

// import "hardhat/console.sol";

contract Advertise is ERC721("Advertise", "ADV"), ReentrancyGuard, Ownable {
	using strings for *;

	event update(
		address indexed from,
		uint256 timestamp,
		uint256 tokenId,
		string url,
		string sponcerName,
		uint256 price
	);

	mapping(uint256 => string) urlByTokenId;
	mapping(uint256 => string) sponcerNameByTokenId;
	mapping(uint256 => uint256) priceByTokenId;

	string public currentUrl = "";
	uint256 private lastPrice = 0.001 ether;
	uint256 private count = 0;

	//-------------------------------------------

	function mint(string memory url, string memory sponcerName) public payable nonReentrant {
		require(msg.value >= getPrice(), "Incorrect payable amount");
		require(validate(url), "Invalid URL");

		uint256 tokenId = ++count;

		lastPrice = msg.value;
		priceByTokenId[tokenId] = msg.value;

		currentUrl = url;
		urlByTokenId[tokenId] = url;
		sponcerNameByTokenId[tokenId] = sponcerName;

		_safeMint(_msgSender(), tokenId);

		emit update(msg.sender, block.timestamp, tokenId, url, sponcerName, msg.value);
	}

	function validate(string memory url) private pure returns (bool) {
		strings.slice memory slicee = url.toSlice();
		// Check length of url
		if (slicee.len() < 10 || slicee.len() > 10000) {
			return false;
		}
		//Check url protocol
		if (!slicee.startsWith("http://".toSlice()) && !slicee.startsWith("https://".toSlice())) {
			return false;
		}
		return true;
	}

	function getPrice() public view returns (uint256) {
		return (lastPrice * 110) / 100;
	}

	function getPriceById(uint256 tokenId) public view returns (uint256) {
		return priceByTokenId[tokenId];
	}

	function getUrlById(uint256 tokenId) public view returns (string memory) {
		return urlByTokenId[tokenId];
	}

	function getSponcerNameById(uint256 tokenId) public view returns (string memory) {
		return sponcerNameByTokenId[tokenId];
	}

	//-------------------------------------------

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "nonexistent token");

		string memory name = string(abi.encodePacked("#", Strings.toString(tokenId)));

		string memory description = "This is description";
		string memory sponcerName = sponcerNameByTokenId[tokenId];
		string memory url = urlByTokenId[tokenId];
		string memory priceStr = Strings.toString(priceByTokenId[tokenId]);

		bytes memory html = abi.encodePacked(
			'<!DOCTYPE html><html lang="en"><body><p>tokenId: #',
			Strings.toString(tokenId),
			"</p><p>url: ",
			url,
			"</p></body></html>"
		);

		bytes memory json = abi.encodePacked(
			'{"name": "',
			name,
			'", "description": "',
			description,
			'", "animation_url": "data:text/html;base64,',
			Base64.encode(html),
			'", "attributes": [',
			'{"trait_type":"URL","value":"',
			url,
			'"},',
			'{"trait_type":"Sponcer Name","value":"',
			sponcerName,
			'"},',
			'{"trait_type":"Price (WEI)","value":',
			priceStr,
			"}],",
			'"metadata": {'
			'"url":"',
			url,
			'","sponcer_name":"',
			sponcerName,
			'","price":',
			priceStr,
			"}}"
		);

		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
	}

	//-------------------------------------------

	function totalSupply() external view returns (uint256) {
		return count;
	}

	function withdraw() public onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: Apache-2.0
/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
	struct slice {
		uint256 _len;
		uint256 _ptr;
	}

	function memcpy(
		uint256 dest,
		uint256 src,
		uint256 len_
	) private pure {
		// Copy word-length chunks while possible
		for (; len_ >= 32; len_ -= 32) {
			assembly {
				mstore(dest, mload(src))
			}
			dest += 32;
			src += 32;
		}

		// Copy remaining bytes
		uint256 mask = 256**(32 - len_) - 1;
		assembly {
			let srcpart := and(mload(src), not(mask))
			let destpart := and(mload(dest), mask)
			mstore(dest, or(destpart, srcpart))
		}
	}

	/*
	 * @dev Returns a slice containing the entire string.
	 * @param self The string to make a slice from.
	 * @return A newly allocated slice containing the entire string.
	 */
	function toSlice(string memory self) internal pure returns (slice memory) {
		uint256 ptr;
		assembly {
			ptr := add(self, 0x20)
		}
		return slice(bytes(self).length, ptr);
	}

	/*
	 * @dev Returns the length of a null-terminated bytes32 string.
	 * @param self The value to find the length of.
	 * @return The length of the string, from 0 to 32.
	 */
	function len(bytes32 self) internal pure returns (uint256) {
		uint256 ret;
		if (self == 0) return 0;
		if (uint256(self) & 0xffffffffffffffffffffffffffffffff == 0) {
			ret += 16;
			self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
		}
		if (uint256(self) & 0xffffffffffffffff == 0) {
			ret += 8;
			self = bytes32(uint256(self) / 0x10000000000000000);
		}
		if (uint256(self) & 0xffffffff == 0) {
			ret += 4;
			self = bytes32(uint256(self) / 0x100000000);
		}
		if (uint256(self) & 0xffff == 0) {
			ret += 2;
			self = bytes32(uint256(self) / 0x10000);
		}
		if (uint256(self) & 0xff == 0) {
			ret += 1;
		}
		return 32 - ret;
	}

	/*
	 * @dev Returns a slice containing the entire bytes32, interpreted as a
	 *      null-terminated utf-8 string.
	 * @param self The bytes32 value to convert to a slice.
	 * @return A new slice containing the value of the input argument up to the
	 *         first null.
	 */
	function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
		// Allocate space for `self` in memory, copy it there, and point ret at it
		assembly {
			let ptr := mload(0x40)
			mstore(0x40, add(ptr, 0x20))
			mstore(ptr, self)
			mstore(add(ret, 0x20), ptr)
		}
		ret._len = len(self);
	}

	/*
	 * @dev Returns a new slice containing the same data as the current slice.
	 * @param self The slice to copy.
	 * @return A new slice containing the same data as `self`.
	 */
	function copy(slice memory self) internal pure returns (slice memory) {
		return slice(self._len, self._ptr);
	}

	/*
	 * @dev Copies a slice to a new string.
	 * @param self The slice to copy.
	 * @return A newly allocated string containing the slice's text.
	 */
	function toString(slice memory self) internal pure returns (string memory) {
		string memory ret = new string(self._len);
		uint256 retptr;
		assembly {
			retptr := add(ret, 32)
		}

		memcpy(retptr, self._ptr, self._len);
		return ret;
	}

	/*
	 * @dev Returns the length in runes of the slice. Note that this operation
	 *      takes time proportional to the length of the slice; avoid using it
	 *      in loops, and call `slice.empty()` if you only need to know whether
	 *      the slice is empty or not.
	 * @param self The slice to operate on.
	 * @return The length of the slice in runes.
	 */
	function len(slice memory self) internal pure returns (uint256 l) {
		// Starting at ptr-31 means the LSB will be the byte we care about
		uint256 ptr = self._ptr - 31;
		uint256 end = ptr + self._len;
		for (l = 0; ptr < end; l++) {
			uint8 b;
			assembly {
				b := and(mload(ptr), 0xFF)
			}
			if (b < 0x80) {
				ptr += 1;
			} else if (b < 0xE0) {
				ptr += 2;
			} else if (b < 0xF0) {
				ptr += 3;
			} else if (b < 0xF8) {
				ptr += 4;
			} else if (b < 0xFC) {
				ptr += 5;
			} else {
				ptr += 6;
			}
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

	/*
	 * @dev Returns a positive number if `other` comes lexicographically after
	 *      `self`, a negative number if it comes before, or zero if the
	 *      contents of the two slices are equal. Comparison is done per-rune,
	 *      on unicode codepoints.
	 * @param self The first slice to compare.
	 * @param other The second slice to compare.
	 * @return The result of the comparison.
	 */
	function compare(slice memory self, slice memory other) internal pure returns (int256) {
		uint256 shortest = self._len;
		if (other._len < self._len) shortest = other._len;

		uint256 selfptr = self._ptr;
		uint256 otherptr = other._ptr;
		for (uint256 idx = 0; idx < shortest; idx += 32) {
			uint256 a;
			uint256 b;
			assembly {
				a := mload(selfptr)
				b := mload(otherptr)
			}
			if (a != b) {
				// Mask out irrelevant bytes and check again
				uint256 mask = type(uint256).max; // 0xffff...
				if (shortest < 32) {
					mask = ~(2**(8 * (32 - shortest + idx)) - 1);
				}
				unchecked {
					uint256 diff = (a & mask) - (b & mask);
					if (diff != 0) return int256(diff);
				}
			}
			selfptr += 32;
			otherptr += 32;
		}
		return int256(self._len) - int256(other._len);
	}

	/*
	 * @dev Returns true if the two slices contain the same text.
	 * @param self The first slice to compare.
	 * @param self The second slice to compare.
	 * @return True if the slices are equal, false otherwise.
	 */
	function equals(slice memory self, slice memory other) internal pure returns (bool) {
		return compare(self, other) == 0;
	}

	/*
	 * @dev Extracts the first rune in the slice into `rune`, advancing the
	 *      slice to point to the next rune and returning `self`.
	 * @param self The slice to operate on.
	 * @param rune The slice that will contain the first rune.
	 * @return `rune`.
	 */
	function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
		rune._ptr = self._ptr;

		if (self._len == 0) {
			rune._len = 0;
			return rune;
		}

		uint256 l;
		uint256 b;
		// Load the first byte of the rune into the LSBs of b
		assembly {
			b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
		}
		if (b < 0x80) {
			l = 1;
		} else if (b < 0xE0) {
			l = 2;
		} else if (b < 0xF0) {
			l = 3;
		} else {
			l = 4;
		}

		// Check for truncated codepoints
		if (l > self._len) {
			rune._len = self._len;
			self._ptr += self._len;
			self._len = 0;
			return rune;
		}

		self._ptr += l;
		self._len -= l;
		rune._len = l;
		return rune;
	}

	/*
	 * @dev Returns the first rune in the slice, advancing the slice to point
	 *      to the next rune.
	 * @param self The slice to operate on.
	 * @return A slice containing only the first rune from `self`.
	 */
	function nextRune(slice memory self) internal pure returns (slice memory ret) {
		nextRune(self, ret);
	}

	/*
	 * @dev Returns the number of the first codepoint in the slice.
	 * @param self The slice to operate on.
	 * @return The number of the first codepoint in the slice.
	 */
	function ord(slice memory self) internal pure returns (uint256 ret) {
		if (self._len == 0) {
			return 0;
		}

		uint256 word;
		uint256 length;
		uint256 divisor = 2**248;

		// Load the rune into the MSBs of b
		assembly {
			word := mload(mload(add(self, 32)))
		}
		uint256 b = word / divisor;
		if (b < 0x80) {
			ret = b;
			length = 1;
		} else if (b < 0xE0) {
			ret = b & 0x1F;
			length = 2;
		} else if (b < 0xF0) {
			ret = b & 0x0F;
			length = 3;
		} else {
			ret = b & 0x07;
			length = 4;
		}

		// Check for truncated codepoints
		if (length > self._len) {
			return 0;
		}

		for (uint256 i = 1; i < length; i++) {
			divisor = divisor / 256;
			b = (word / divisor) & 0xFF;
			if (b & 0xC0 != 0x80) {
				// Invalid UTF-8 sequence
				return 0;
			}
			ret = (ret * 64) | (b & 0x3F);
		}

		return ret;
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
	 * @dev Returns true if `self` starts with `needle`.
	 * @param self The slice to operate on.
	 * @param needle The slice to search for.
	 * @return True if the slice starts with the provided text, false otherwise.
	 */
	function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
		if (self._len < needle._len) {
			return false;
		}

		if (self._ptr == needle._ptr) {
			return true;
		}

		bool equal;
		assembly {
			let length := mload(needle)
			let selfptr := mload(add(self, 0x20))
			let needleptr := mload(add(needle, 0x20))
			equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
		}
		return equal;
	}

	/*
	 * @dev If `self` starts with `needle`, `needle` is removed from the
	 *      beginning of `self`. Otherwise, `self` is unmodified.
	 * @param self The slice to operate on.
	 * @param needle The slice to search for.
	 * @return `self`
	 */
	function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
		if (self._len < needle._len) {
			return self;
		}

		bool equal = true;
		if (self._ptr != needle._ptr) {
			assembly {
				let length := mload(needle)
				let selfptr := mload(add(self, 0x20))
				let needleptr := mload(add(needle, 0x20))
				equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
			}
		}

		if (equal) {
			self._len -= needle._len;
			self._ptr += needle._len;
		}

		return self;
	}

	/*
	 * @dev Returns true if the slice ends with `needle`.
	 * @param self The slice to operate on.
	 * @param needle The slice to search for.
	 * @return True if the slice starts with the provided text, false otherwise.
	 */
	function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
		if (self._len < needle._len) {
			return false;
		}

		uint256 selfptr = self._ptr + self._len - needle._len;

		if (selfptr == needle._ptr) {
			return true;
		}

		bool equal;
		assembly {
			let length := mload(needle)
			let needleptr := mload(add(needle, 0x20))
			equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
		}

		return equal;
	}

	/*
	 * @dev If `self` ends with `needle`, `needle` is removed from the
	 *      end of `self`. Otherwise, `self` is unmodified.
	 * @param self The slice to operate on.
	 * @param needle The slice to search for.
	 * @return `self`
	 */
	function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
		if (self._len < needle._len) {
			return self;
		}

		uint256 selfptr = self._ptr + self._len - needle._len;
		bool equal = true;
		if (selfptr != needle._ptr) {
			assembly {
				let length := mload(needle)
				let needleptr := mload(add(needle, 0x20))
				equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
			}
		}

		if (equal) {
			self._len -= needle._len;
		}

		return self;
	}

	// Returns the memory address of the first byte of the first occurrence of
	// `needle` in `self`, or the first byte after `self` if not found.
	function findPtr(
		uint256 selflen,
		uint256 selfptr,
		uint256 needlelen,
		uint256 needleptr
	) private pure returns (uint256) {
		uint256 ptr = selfptr;
		uint256 idx;

		if (needlelen <= selflen) {
			if (needlelen <= 32) {
				bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

				bytes32 needledata;
				assembly {
					needledata := and(mload(needleptr), mask)
				}

				uint256 end = selfptr + selflen - needlelen;
				bytes32 ptrdata;
				assembly {
					ptrdata := and(mload(ptr), mask)
				}

				while (ptrdata != needledata) {
					if (ptr >= end) return selfptr + selflen;
					ptr++;
					assembly {
						ptrdata := and(mload(ptr), mask)
					}
				}
				return ptr;
			} else {
				// For long needles, use hashing
				bytes32 hash;
				assembly {
					hash := keccak256(needleptr, needlelen)
				}

				for (idx = 0; idx <= selflen - needlelen; idx++) {
					bytes32 testHash;
					assembly {
						testHash := keccak256(ptr, needlelen)
					}
					if (hash == testHash) return ptr;
					ptr += 1;
				}
			}
		}
		return selfptr + selflen;
	}

	// Returns the memory address of the first byte after the last occurrence of
	// `needle` in `self`, or the address of `self` if not found.
	function rfindPtr(
		uint256 selflen,
		uint256 selfptr,
		uint256 needlelen,
		uint256 needleptr
	) private pure returns (uint256) {
		uint256 ptr;

		if (needlelen <= selflen) {
			if (needlelen <= 32) {
				bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

				bytes32 needledata;
				assembly {
					needledata := and(mload(needleptr), mask)
				}

				ptr = selfptr + selflen - needlelen;
				bytes32 ptrdata;
				assembly {
					ptrdata := and(mload(ptr), mask)
				}

				while (ptrdata != needledata) {
					if (ptr <= selfptr) return selfptr;
					ptr--;
					assembly {
						ptrdata := and(mload(ptr), mask)
					}
				}
				return ptr + needlelen;
			} else {
				// For long needles, use hashing
				bytes32 hash;
				assembly {
					hash := keccak256(needleptr, needlelen)
				}
				ptr = selfptr + (selflen - needlelen);
				while (ptr >= selfptr) {
					bytes32 testHash;
					assembly {
						testHash := keccak256(ptr, needlelen)
					}
					if (hash == testHash) return ptr + needlelen;
					ptr -= 1;
				}
			}
		}
		return selfptr;
	}

	/*
	 * @dev Modifies `self` to contain everything from the first occurrence of
	 *      `needle` to the end of the slice. `self` is set to the empty slice
	 *      if `needle` is not found.
	 * @param self The slice to search and modify.
	 * @param needle The text to search for.
	 * @return `self`.
	 */
	function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
		uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
		self._len -= ptr - self._ptr;
		self._ptr = ptr;
		return self;
	}

	/*
	 * @dev Modifies `self` to contain the part of the string from the start of
	 *      `self` to the end of the first occurrence of `needle`. If `needle`
	 *      is not found, `self` is set to the empty slice.
	 * @param self The slice to search and modify.
	 * @param needle The text to search for.
	 * @return `self`.
	 */
	function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
		uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
		self._len = ptr - self._ptr;
		return self;
	}

	/*
	 * @dev Splits the slice, setting `self` to everything after the first
	 *      occurrence of `needle`, and `token` to everything before it. If
	 *      `needle` does not occur in `self`, `self` is set to the empty slice,
	 *      and `token` is set to the entirety of `self`.
	 * @param self The slice to split.
	 * @param needle The text to search for in `self`.
	 * @param token An output parameter to which the first token is written.
	 * @return `token`.
	 */
	function split(
		slice memory self,
		slice memory needle,
		slice memory token
	) internal pure returns (slice memory) {
		uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
		token._ptr = self._ptr;
		token._len = ptr - self._ptr;
		if (ptr == self._ptr + self._len) {
			// Not found
			self._len = 0;
		} else {
			self._len -= token._len + needle._len;
			self._ptr = ptr + needle._len;
		}
		return token;
	}

	/*
	 * @dev Splits the slice, setting `self` to everything after the first
	 *      occurrence of `needle`, and returning everything before it. If
	 *      `needle` does not occur in `self`, `self` is set to the empty slice,
	 *      and the entirety of `self` is returned.
	 * @param self The slice to split.
	 * @param needle The text to search for in `self`.
	 * @return The part of `self` up to the first occurrence of `delim`.
	 */
	function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
		split(self, needle, token);
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
	function rsplit(
		slice memory self,
		slice memory needle,
		slice memory token
	) internal pure returns (slice memory) {
		uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
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

	/*
	 * @dev Splits the slice, setting `self` to everything before the last
	 *      occurrence of `needle`, and returning everything after it. If
	 *      `needle` does not occur in `self`, `self` is set to the empty slice,
	 *      and the entirety of `self` is returned.
	 * @param self The slice to split.
	 * @param needle The text to search for in `self`.
	 * @return The part of `self` after the last occurrence of `delim`.
	 */
	function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
		rsplit(self, needle, token);
	}

	/*
	 * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
	 * @param self The slice to search.
	 * @param needle The text to search for in `self`.
	 * @return The number of occurrences of `needle` found in `self`.
	 */
	function count(slice memory self, slice memory needle) internal pure returns (uint256 cnt) {
		uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
		while (ptr <= self._ptr + self._len) {
			cnt++;
			ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
		}
	}

	/*
	 * @dev Returns True if `self` contains `needle`.
	 * @param self The slice to search.
	 * @param needle The text to search for in `self`.
	 * @return True if `needle` is found in `self`, false otherwise.
	 */
	function contains(slice memory self, slice memory needle) internal pure returns (bool) {
		return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
	}

	/*
	 * @dev Returns a newly allocated string containing the concatenation of
	 *      `self` and `other`.
	 * @param self The first slice to concatenate.
	 * @param other The second slice to concatenate.
	 * @return The concatenation of the two strings.
	 */
	function concat(slice memory self, slice memory other) internal pure returns (string memory) {
		string memory ret = new string(self._len + other._len);
		uint256 retptr;
		assembly {
			retptr := add(ret, 32)
		}
		memcpy(retptr, self._ptr, self._len);
		memcpy(retptr + self._len, other._ptr, other._len);
		return ret;
	}

	/*
	 * @dev Joins an array of slices, using `self` as a delimiter, returning a
	 *      newly allocated string.
	 * @param self The delimiter to use.
	 * @param parts A list of slices to join.
	 * @return A newly allocated string containing all the slices in `parts`,
	 *         joined with `self`.
	 */
	function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
		if (parts.length == 0) return "";

		uint256 length = self._len * (parts.length - 1);
		for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

		string memory ret = new string(length);
		uint256 retptr;
		assembly {
			retptr := add(ret, 32)
		}

		for (uint256 i = 0; i < parts.length; i++) {
			memcpy(retptr, parts[i]._ptr, parts[i]._len);
			retptr += parts[i]._len;
			if (i < parts.length - 1) {
				memcpy(retptr, self._ptr, self._len);
				retptr += self._len;
			}
		}

		return ret;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}