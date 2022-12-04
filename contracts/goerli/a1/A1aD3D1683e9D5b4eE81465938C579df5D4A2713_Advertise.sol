// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SVGRenderer.sol";
import "./DecimalStrings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./solidity-stringutils/strings.sol";

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

		string memory name = string(abi.encodePacked("Advertise #", Strings.toString(tokenId)));
		string memory description = "This is description";
		string memory url = urlByTokenId[tokenId];
		string memory payerAddress = Strings.toHexString(uint256(uint160(payerByTokenId[tokenId])), 20);
		string memory priceStr = DecimalStrings.decimalString(
			(priceByTokenId[tokenId] / 10000000000000) * 10000000000000,
			18,
			false
		);

		bytes memory svg = abi.encodePacked(
			renderer.render(tokenId, payerAddress, address(this), timeByTokenId[tokenId], priceByTokenId[tokenId])
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
			'{"trait_type":"Price","value":"',
			priceStr,
			' ETH"}],',
			'"metadata": {"payer":"',
			payerAddress,
			'","url":"',
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
		uint256 tokenId,
		string memory payerAddress,
		address parent,
		uint256 timestamp,
		uint256 price
	) public view returns (string memory) {
		uint256 seed = uint256(keccak256(abi.encodePacked(timestamp + price)));

		(string memory mainColor, string memory subColor) = getHSLStr(seed);
		string memory contractAddress = Strings.toHexString(uint256(uint160(parent)), 20);

		return
			string(
				abi.encodePacked(
					'<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1080 1080"><style type="text/css">*{--main:hsl(',
					mainColor,
					");--sub:hsl(",
					subColor,
					');}svg{font-family:"din";font-size:28px;fill:var(--main);}.l{stroke:var(--main);}.b{stroke-width:14;}.s{stroke-width:2;}@font-face{font-family:"din";src:url("',
					font.base64(),
					'")format("woff2")};</style><rect width="1080" height="1080" fill="var(--sub)"/><clipPath id="m"><rect width="1080" height="1080"/></clipPath><g clip-path="url(#m)"><text x="35" y="60" font-size="36px" letter-spacing="-0.01em">ADVERTISE</text><text x="1046" y="60" text-anchor="end">#',
					plusZero(tokenId),
					'</text><text x="15" y="462" font-size="320px" letter-spacing="-0.075em">',
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
		return (num < 10) ? string(abi.encodePacked("0", Strings.toString(num))) : Strings.toString(num);
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