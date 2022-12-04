// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./solidity-stringutils/strings.sol";
import "./DecimalStrings.sol";
import "./SVGRenderer.sol";

// import "hardhat/console.sol";

contract Advertise is ERC721, ReentrancyGuard, Ownable {
	using strings for *;

	event update(address indexed from, uint256 timestamp, uint256 tokenId, string url, uint256 price);

	mapping(uint256 => string) urlByTokenId;
	mapping(uint256 => address) payerByTokenId;
	mapping(uint256 => uint256) priceByTokenId;
	mapping(uint256 => uint256) timeByTokenId;

	SVGRenderer private renderer;
	uint256 private count = 0;
	uint256 private constant INIT_PRICE = 0.00001 ether;
	uint256 private constant INCREASE_PERCENTAGE = 110;

	//-------------------------------------------

	constructor() ERC721("Advertise", "ADV") {
		renderer = new SVGRenderer();
	}

	//-------------------------------------------

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

	function getCurrentURL() public view returns (string memory) {
		uint256 tokenId = this.totalSupply();
		return (tokenId > 0) ? urlByTokenId[tokenId] : "";
	}

	function getPrice() public view returns (uint256) {
		return (getLastPrice() * INCREASE_PERCENTAGE) / 100;
	}

	function getPriceById(uint256 tokenId) public view returns (uint256) {
		return (tokenId > 0) ? priceByTokenId[tokenId] : INIT_PRICE;
	}

	function getUrlById(uint256 tokenId) public view returns (string memory) {
		return urlByTokenId[tokenId];
	}

	function getLastPrice() private view returns (uint256) {
		uint256 tokenId = this.totalSupply();
		return (tokenId > 0) ? priceByTokenId[tokenId] : INIT_PRICE;
	}

	//-------------------------------------------

	function mint(string memory url) public payable nonReentrant {
		require(msg.value >= getPrice(), "Incorrect payable amount");
		require(validate(url), "Invalid URL");

		uint256 tokenId = ++count;

		urlByTokenId[tokenId] = url;
		payerByTokenId[tokenId] = msg.sender;
		timeByTokenId[tokenId] = block.timestamp;
		priceByTokenId[tokenId] = msg.value;
		_safeMint(_msgSender(), tokenId);

		emit update(msg.sender, block.timestamp, tokenId, url, msg.value);
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "nonexistent token");

		string memory name = string(abi.encodePacked("#", Strings.toString(tokenId)));
		string memory description = "This is description";
		string memory url = urlByTokenId[tokenId];
		string memory priceStr = DecimalStrings.decimalString(
			(priceByTokenId[tokenId] / 10000000000000) * 10000000000000,
			18,
			false
		);

		bytes memory svg = abi.encodePacked(
			renderer.render(payerByTokenId[tokenId], timeByTokenId[tokenId], priceByTokenId[tokenId])
		);

		bytes memory json = abi.encodePacked(
			'{"name": "',
			name,
			'", "description": "',
			description,
			'", "image": "data:text/svg;base64,',
			Base64.encode(svg),
			'", "attributes": [',
			'{"trait_type":"URL","value":"',
			url,
			'"},',
			'{"trait_type":"Price","value":',
			priceStr,
			"}],",
			'"metadata": {'
			'"url":"',
			url,
			'","price":',
			priceStr,
			"}}"
		);

		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
	}

	function totalSupply() external view returns (uint256) {
		return count;
	}

	function withdraw() public onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

//ref: https://gist.github.com/wilsoncusack/d2e680e0f961e36393d1bf0b6faafba7

library DecimalStrings {
	function decimalString(
		uint256 number,
		uint8 decimals,
		bool isPercent
	) internal pure returns (string memory) {
		uint8 percentBufferOffset = isPercent ? 1 : 0;
		uint256 tenPowDecimals = 10**decimals;

		uint256 temp = number;
		uint8 digits;
		uint8 numSigfigs;
		while (temp != 0) {
			if (numSigfigs > 0) {
				// count all digits preceding least significant figure
				numSigfigs++;
			} else if (temp % 10 != 0) {
				numSigfigs++;
			}
			digits++;
			temp /= 10;
		}

		DecimalStringParams memory params;
		params.isPercent = isPercent;
		if ((digits - numSigfigs) >= decimals) {
			// no decimals, ensure we preserve all trailing zeros
			params.sigfigs = number / tenPowDecimals;
			params.sigfigIndex = digits - decimals;
			params.bufferLength = params.sigfigIndex + percentBufferOffset;
		} else {
			// chop all trailing zeros for numbers with decimals
			params.sigfigs = number / (10**(digits - numSigfigs));
			if (tenPowDecimals > number) {
				// number is less tahn one
				// in this case, there may be leading zeros after the decimal place
				// that need to be added

				// offset leading zeros by two to account for leading '0.'
				params.zerosStartIndex = 2;
				params.zerosEndIndex = decimals - digits + 2;
				params.sigfigIndex = numSigfigs + params.zerosEndIndex;
				params.bufferLength = params.sigfigIndex + percentBufferOffset;
				params.isLessThanOne = true;
			} else {
				// In this case, there are digits before and
				// after the decimal place
				params.sigfigIndex = numSigfigs + 1;
				params.decimalIndex = digits - decimals + 1;
			}
		}
		params.bufferLength = params.sigfigIndex + percentBufferOffset;
		return generateDecimalString(params);
	}

	// With modifications, the below taken
	// from https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol#L189-L231

	struct DecimalStringParams {
		// significant figures of decimal
		uint256 sigfigs;
		// length of decimal string
		uint8 bufferLength;
		// ending index for significant figures (funtion works backwards when copying sigfigs)
		uint8 sigfigIndex;
		// index of decimal place (0 if no decimal)
		uint8 decimalIndex;
		// start index for trailing/leading 0's for very small/large numbers
		uint8 zerosStartIndex;
		// end index for trailing/leading 0's for very small/large numbers
		uint8 zerosEndIndex;
		// true if decimal number is less than one
		bool isLessThanOne;
		// true if string should include "%"
		bool isPercent;
	}

	function generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
		bytes memory buffer = new bytes(params.bufferLength);
		if (params.isPercent) {
			buffer[buffer.length - 1] = "%";
		}
		if (params.isLessThanOne) {
			buffer[0] = "0";
			buffer[1] = ".";
		}

		// add leading/trailing 0's
		for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
			buffer[zerosCursor] = bytes1(uint8(48));
		}
		// add sigfigs
		while (params.sigfigs > 0) {
			if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
				buffer[--params.sigfigIndex] = ".";
			}
			buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
			params.sigfigs /= 10;
		}
		return string(buffer);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./solidity-datetime/DateTime.sol";
import "./DecimalStrings.sol";
import "./Font.sol";

contract SVGRenderer {
	Font private font;

	constructor() {
		font = new Font();
	}

	function render(
		address payer,
		uint256 timestamp,
		uint256 price
	) public view returns (string memory) {
		uint256 seed = uint256(keccak256(abi.encodePacked(timestamp + price)));

		(string memory mainColor, string memory subColor) = getHSLStr(seed);
		string memory payerAddress = Strings.toHexString(uint256(uint160(address(payer))), 20);
		string memory contractAddress = Strings.toHexString(uint256(uint160(address(this))), 20);

		return
			string(
				abi.encodePacked(
					'<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1080 1080"><style type="text/css">*{--main:hsl(',
					mainColor,
					");--sub:hsl(",
					subColor,
					');}svg{font-family:"din";font-size:28px;fill:var(--main);}.l{stroke:var(--main);}.b{stroke-width:14;}.s{stroke-width:2;}@font-face{font-family:"din";src:url("',
					font.base64(),
					'")format("woff2")};</style><rect width="1080" height="1080" fill="var(--sub)"/><clipPath id="m"><rect width="1080" height="1080"/></clipPath><g clip-path="url(#m)"><text x="35" y="60" font-size="36px" letter-spacing="-0.01em">ADVERTISE</text><text x="15" y="462" font-size="320px" letter-spacing="-0.075em">',
					DecimalStrings.decimalString((price / 10000000000000) * 10000000000000, 18, false),
					'</text><text x="27" y="587" font-size="110px">ETH</text><text x="34" y="779">PAYER ADDRESS:</text><text x="34" y="819">',
					payerAddress,
					'</text><text x="34" y="910">CONTRACT ADDRESS:</text><text x="34" y="952">',
					contractAddress,
					'</text><text x="34" y="1044">',
					getDateStr(timestamp),
					'</text><line class="l b" x1="36" y1="104" x2="1044" y2="104"/><line class="l b" x1="36" y1="723" x2="1044" y2="723"/><line class="l s" x1="36" y1="855" x2="1044" y2="855"/><line class="l s" x1="36" y1="989" x2="1044" y2="989"/></g></svg>'
				)
			);
	}

	function getDateStr(uint256 timestamp) private pure returns (string memory) {
		uint256 newTimestamp = timestamp + 9 * 3600;
		(uint256 y, uint256 m, uint256 d, uint256 h, uint256 min, uint256 sec) = DateTime.timestampToDateTime(
			newTimestamp
		);
		return
			string(
				abi.encodePacked(
					Strings.toString(y),
					".",
					plusZero(m),
					".",
					plusZero(d),
					" ",
					plusZero(h),
					":",
					plusZero(min),
					":",
					plusZero(sec)
				)
			);
	}

	function plusZero(uint256 num) private pure returns (string memory) {
		return num >= 10 ? Strings.toString(num) : string(abi.encodePacked("0", Strings.toString(num)));
	}

	function getHSLStr(uint256 seed) private pure returns (string memory main, string memory sub) {
		uint256 count = 0;

		uint256 maxMainHue = 360;
		uint256 minMainHue = 0;

		uint256 mainHue = randomRange(seed, ++count, minMainHue, maxMainHue);
		string memory satStr = randomRangeStr(seed, ++count, 80, 100);
		string memory lumStr = randomRangeStr(seed, ++count, 40, 60);

		uint256 maxOffsetHue = 200;
		uint256 minOffsetHue = 160;
		uint256 offsetHue = minOffsetHue + (random(seed, count) % (maxOffsetHue - minOffsetHue));
		uint256 subHue = mainHue + offsetHue;

		main = string(abi.encodePacked(Strings.toString(mainHue), ",", satStr, "%,", lumStr, "%"));
		sub = string(abi.encodePacked(Strings.toString(subHue), ",", satStr, "%,", lumStr, "%"));
	}

	function randomRangeStr(
		uint256 seed0,
		uint256 seed1,
		uint256 min,
		uint256 max
	) private pure returns (string memory) {
		return Strings.toString(randomRange(seed0, seed1, min, max));
	}

	function randomRange(
		uint256 seed0,
		uint256 seed1,
		uint256 min,
		uint256 max
	) private pure returns (uint256) {
		return min + (random(seed0, seed1) % (max - min));
	}

	function random(uint256 seed0, uint256 seed1) private pure returns (uint256) {
		return uint256(keccak256(abi.encodePacked(seed0, seed1)));
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
pragma solidity ^0.8.4;

contract Font {
	function base64() public pure returns (string memory) {
		return
			"data:application/font-woff;charset=utf-8;base64,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";
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
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