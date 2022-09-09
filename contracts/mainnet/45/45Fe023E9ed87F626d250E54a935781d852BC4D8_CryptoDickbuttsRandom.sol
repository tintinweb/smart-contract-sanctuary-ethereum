// SPDX-License-Identifier: CC0-1.0

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G?77777J#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJP&&&&&&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@B..7G&@@&G:^775P [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@G  ~&::[email protected] [email protected]@J  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@B..! :[email protected]@B^^775G [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:~&J7J&@@@@@@@& [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:[email protected]@@& [email protected]@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:~&&&&&&&P#@B&& !GGG#@@@BYY&^^@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:[email protected]@@@@@@.J&.Y&.!5YYJ7?JP##[email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:[email protected]@@@@@[email protected]~J#&@@?7!:[email protected]~ [email protected]@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]^:@@@@@@@BYJJJJ&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G:[email protected]@@&G:^!.?#@@@@@@@@# J&@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^[email protected]@@@@&&&@@@@@@@@@#5!#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5 B? B&&&J^@Y^#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5~.&Y &@&Y^[email protected][email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#7Y55#Y^&B7Y5P#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@&YJJJ#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.13;

import "@divergencetech/ethier/contracts/random/PRNG.sol";

import "./lib/interfaces/IRandom.sol";
import "./lib/interfaces/IBuilder.sol";
import "./lib/interfaces/IMetadata.sol";
import "./lib/interfaces/IStrings.sol";
import "./lib/interfaces/ITokenURIBuilder.sol";

import "./lib/graphics/ISVGWrapper.sol";

contract CryptoDickbuttsRandom is IRandom {
    function randomImageURI(
        uint64 seed,
        IBuilder builder,
        IPixelRenderer renderer,
        IAnimationEncoder encoder
    )
        external
        view
        override
        returns (string memory imageUri, uint8[] memory metadata)
    {
        metadata = _randomMeta(seed);
        imageUri = builder.getImage(renderer, encoder, metadata, 0);
        return (imageUri, metadata);
    }

    function _randomMeta(uint64 seed)
        private
        pure
        returns (uint8[] memory meta)
    {
        meta = new uint8[](12);
        PRNG.Source src = PRNG.newSource(keccak256(abi.encodePacked(seed)));

        // Background
        meta[0] = uint8(PRNG.readLessThan(src, 8, 8));

        // Skin
        meta[1] = 181 + uint8(PRNG.readLessThan(src, 11, 8));

        // Body
        if (PRNG.readBool(src)) {
            meta[2] = 8 + uint8(PRNG.readLessThan(src, 18, 8));
        } else {
            meta[2] = 194;
        }

        // Hat
        if (PRNG.readBool(src)) {
            meta[3] = 96 + uint8(PRNG.readLessThan(src, 52, 8));
        } else {
            meta[3] = 195;
        }

        // Eyes
        if (PRNG.readBool(src)) {
            meta[4] = 48 + uint8(PRNG.readLessThan(src, 25, 8));
        } else {
            meta[4] = 196;
        }

        // Mouth
        if (PRNG.readBool(src)) {
            meta[5] = 162 + uint8(PRNG.readLessThan(src, 4, 8));
        } else {
            meta[5] = 197;
        }

        // Nose
        if (PRNG.readBool(src)) {
            meta[6] = 166 + uint8(PRNG.readLessThan(src, 3, 8));
        } else {
            meta[6] = 198;
        }

        // Hand
        if (PRNG.readBool(src)) {
            meta[7] = 73 + uint8(PRNG.readLessThan(src, 23, 8));
        } else {
            meta[7] = 199;
        }

        // Shoes
        if (PRNG.readBool(src)) {
            meta[8] = 169 + uint8(PRNG.readLessThan(src, 12, 8));
        } else {
            meta[8] = 200;
        }

        // Butt
        if (PRNG.readBool(src)) {
            meta[9] = 26 + uint8(PRNG.readLessThan(src, 3, 8));
        } else {
            meta[9] = 201;
        }

        // Dick
        if (PRNG.readBool(src)) {
            meta[10] = 29 + uint8(PRNG.readLessThan(src, 19, 8));
        } else {
            meta[10] = 202;
        }

        // Special
        if (PRNG.readBool(src)) {
            meta[11] = 192 + uint8(PRNG.readLessThan(src, 2, 8));
        } else {
            meta[11] = 203;
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.9 <0.9.0;

library PRNG {
    /**
    @notice A source of random numbers.
    @dev Pointer to a 2-word buffer of {carry || number, remaining unread
    bits}. however, note that this is abstracted away by the API and SHOULD NOT
    be used. This layout MUST NOT be considered part of the public API and
    therefore not relied upon even within stable versions.
     */
    type Source is uint256;

    /// @notice The biggest safe prime for modulus 2**128
    uint256 private constant MWC_FACTOR = 2**128 - 10408;

    /// @notice Layout within the buffer. 0x00 is the current (carry || number)
    uint256 private constant REMAIN = 0x20;

    /// @notice Mask for the 128 least significant bits
    uint256 private constant MASK_128_BITS = 0xffffffffffffffffffffffffffffffff;

    /**
    @notice Returns a new deterministic Source, differentiated only by the seed.
    @dev Use of PRNG.Source does NOT provide any unpredictability as generated
    numbers are entirely deterministic. Either a verifiable source of randomness
    such as Chainlink VRF, or a commit-and-reveal protocol MUST be used if
    unpredictability is required. The latter is only appropriate if the contract
    owner can be trusted within the specified threat model.
    @dev The 256bit seed is used to initialize carry || number
     */
    function newSource(bytes32 seed) internal pure returns (Source src) {
        assembly {
            src := mload(0x40)
            mstore(0x40, add(src, 0x40))
            mstore(src, seed)
            mstore(add(src, REMAIN), 128)
        }
        // DO NOT call _refill() on the new Source as newSource() is also used
        // by loadSource(), which implements its own state modifications. The
        // first call to read() on a fresh Source will induce a call to
        // _refill().
    }

    /**
    @dev Computes the next PRN in entropy using a lag-1 multiply-with-carry
    algorithm and resets the remaining bits to 128.
    `nextNumber = (factor * number + carry) mod 2**128`
    `nextCarry  = (factor * number + carry) //  2**128`
     */
    function _refill(Source src) private pure {
        assembly {
            let carryAndNumber := mload(src)
            let rand := and(carryAndNumber, MASK_128_BITS)
            let carry := shr(128, carryAndNumber)
            mstore(src, add(mul(MWC_FACTOR, rand), carry))
            mstore(add(src, REMAIN), 128)
        }
    }

    /**
    @notice Returns the specified number of bits <= 128 from the Source.
    @dev It is safe to cast the returned value to a uint<bits>.
     */
    function read(Source src, uint256 bits)
        internal
        pure
        returns (uint256 sample)
    {
        require(bits <= 128, "PRNG: max 128 bits");

        uint256 remain;
        assembly {
            remain := mload(add(src, REMAIN))
        }
        if (remain > bits) {
            return readWithSufficient(src, bits);
        }

        uint256 extra = bits - remain;
        sample = readWithSufficient(src, remain);
        assembly {
            sample := shl(extra, sample)
        }

        _refill(src);
        sample = sample | readWithSufficient(src, extra);
    }

    /**
    @notice Returns the specified number of bits, assuming that there is
    sufficient entropy remaining. See read() for usage.
     */
    function readWithSufficient(Source src, uint256 bits)
        private
        pure
        returns (uint256 sample)
    {
        assembly {
            let ent := mload(src)
            let rem := add(src, REMAIN)
            let remain := mload(rem)
            sample := shr(sub(256, bits), shl(sub(256, remain), ent))
            mstore(rem, sub(remain, bits))
        }
    }

    /// @notice Returns a random boolean.
    function readBool(Source src) internal pure returns (bool) {
        return read(src, 1) == 1;
    }

    /**
    @notice Returns the number of bits needed to encode n.
    @dev Useful for calling readLessThan() multiple times with the same upper
    bound.
     */
    function bitLength(uint256 n) internal pure returns (uint16 bits) {
        assembly {
            for {
                let _n := n
            } gt(_n, 0) {
                _n := shr(1, _n)
            } {
                bits := add(bits, 1)
            }
        }
    }

    /**
    @notice Returns a uniformly random value in [0,n) with rejection sampling.
    @dev If the size of n is known, prefer readLessThan(Source, uint, uint16) as
    it skips the bit counting performed by this version; see bitLength().
     */
    function readLessThan(Source src, uint256 n)
        internal
        pure
        returns (uint256)
    {
        return readLessThan(src, n, bitLength(n));
    }

    /**
    @notice Returns a uniformly random value in [0,n) with rejection sampling
    from the range [0,2^bits).
    @dev For greatest efficiency, the value of bits should be the smallest
    number of bits required to capture n; if this is not known, use
    readLessThan(Source, uint) or bitLength(). Although rejections are reduced
    by using twice the number of bits, this increases the rate at which the
    entropy pool must be refreshed with a call to `_refill`.

    TODO: benchmark higher number of bits for rejection vs hashing gas cost.
     */
    function readLessThan(
        Source src,
        uint256 n,
        uint16 bits
    ) internal pure returns (uint256 result) {
        // Discard results >= n and try again because using % will bias towards
        // lower values; e.g. if n = 13 and we read 4 bits then {13, 14, 15}%13
        // will select {0, 1, 2} twice as often as the other values.
        // solhint-disable-next-line no-empty-blocks
        for (result = n; result >= n; result = read(src, bits)) {}
    }

    /**
    @notice Returns the internal state of the Source.
    @dev MUST NOT be considered part of the API and is subject to change without
    deprecation nor warning. Only exposed for testing.
     */
    function state(Source src)
        internal
        pure
        returns (uint256 entropy, uint256 remain)
    {
        assembly {
            entropy := mload(src)
            remain := mload(add(src, REMAIN))
        }
    }

    /**
    @notice Stores the state of the Source in a 2-word buffer. See loadSource().
    @dev The layout of the stored state MUST NOT be considered part of the
    public API, and is subject to change without warning. It is therefore only
    safe to rely on stored Sources _within_ contracts, but not _between_ them.
     */
    function store(Source src, uint256[2] storage stored) internal {
        uint256 carryAndNumber;
        uint256 remain;
        assembly {
            carryAndNumber := mload(src)
            remain := mload(add(src, REMAIN))
        }
        stored[0] = carryAndNumber;
        stored[1] = remain;
    }

    /**
    @notice Recreates a Source from the state stored with store().
     */
    function loadSource(uint256[2] storage stored)
        internal
        view
        returns (Source)
    {
        Source src = newSource(bytes32(stored[0]));
        uint256 carryAndNumber = stored[0];
        uint256 remain = stored[1];

        assembly {
            mstore(src, carryAndNumber)
            mstore(add(src, REMAIN), remain)
        }
        return src;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./IBuilder.sol";

interface IRandom { 
    // function randomTokenURI(uint64 seed) external view returns (string memory);
    function randomImageURI(uint64 seed, IBuilder builder, IPixelRenderer renderer, IAnimationEncoder encoder) external view returns (string memory imageUri, uint8[] memory meta);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "../graphics/IPixelRenderer.sol";
import "../graphics/IAnimationEncoder.sol";
import "../graphics/ISVGWrapper.sol";

interface IBuilder {
    function getCanonicalSize() external view returns (uint width, uint height);
    function getImage(IPixelRenderer renderer, IAnimationEncoder encoder, uint8[] memory metadata, uint tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

interface IMetadata {    
    function getMetadata(uint256 tokenId) external view returns (uint8[] memory metadata);
    function getTraitName(uint8 traitValue) external view returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

interface IStrings {
    function getString(uint8 key) external view returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./IMetadata.sol";
import "./IStrings.sol";

interface ITokenURIBuilder {
    function build(
        IMetadata metadata,
        IStrings strings,
        uint256 seedOrTokenId,
        string memory imageUri,
        string memory imageDataUri,
        string memory description,
        string memory externalUrl,
        string memory prefix,
        uint8[] memory meta
    ) external view returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

interface ISVGWrapper {
    function getWrappedImage(
        string memory imageUri,
        uint256 canonicalWidth,
        uint256 canonicalHeight
    ) external view returns (string memory imageDataUri);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./DrawFrame.sol";

interface IPixelRenderer {
    function drawFrameWithOffsets(DrawFrame memory f)
        external
        pure
        returns (uint32[] memory buffer, uint256);

    function getColorTable(bytes memory buffer, uint256 position)
        external
        pure
        returns (uint32[] memory colors, uint256);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./Animation.sol";

interface IAnimationEncoder {
    function getDataUri(Animation memory animation)
        external
        pure
        returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./AnimationFrame.sol";
import "./AlphaBlend.sol";

struct DrawFrame {
    bytes buffer;
    uint256 position;
    AnimationFrame frame;
    uint32[] colors;
    uint8 ox;
    uint8 oy;
    AlphaBlend.Type blend;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

struct AnimationFrame {
    uint32[] buffer;
    uint16 delay;
    uint16 width;
    uint16 height;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

library AlphaBlend {

    enum Type {
        None,
        Default,
        Accurate,
        Fast,
        Pillow
    }

    /**
     @notice A simplicity-focused blend, that over compensates alpha to "good enough" values, with error trending towards saturation.
     */
    function alpha_composite_default(uint32 bg, uint32 fg)
        internal
        pure
        returns (uint32)
    {
        uint32 r1 = bg >> 16;
        uint32 g1 = bg >> 8;
        uint32 b1 = bg;

        uint32 r2 = fg >> 16;
        uint32 g2 = fg >> 8;
        uint32 b2 = fg;

        uint32 a = ((fg >> 24) & 0xFF) + 1;
        uint32 na = 257 - a;

        uint32 r = (a * (r2 & 0xFF) + na * (r1 & 0xFF)) >> 8;
        uint32 g = (a * (g2 & 0xFF) + na * (g1 & 0xFF)) >> 8;
        uint32 b = (a * (b2 & 0xFF) + na * (b1 & 0xFF)) >> 8;

        uint32 rgb;
        rgb |= uint32(0xFF) << 24;
        rgb |= r << 16;
        rgb |= g << 8;
        rgb |= b;

        return rgb;
    }

    /**
     @notice An accuracy-focused blend that removes bias across color channels.
     @dev See: https://stackoverflow.com/a/1230272
     */
    function alpha_composite_accurate(uint32 bg, uint32 fg)
        internal
        pure
        returns (uint32)
    {
        uint32 a = (fg >> 24) & 0xFF;
        uint32 na = 255 - a;

        uint32 rh = uint8(fg >> 16) * a + uint8(bg >> 16) * na + 0x80;
        uint32 gh = uint8(fg >>  8) * a + uint8(bg >>  8) * na + 0x80;
        uint32 bh = uint8(fg >>  0) * a + uint8(bg >>  0) * na + 0x80;

        uint32 r = ((rh >> 8) + rh) >> 8;
        uint32 g = ((gh >> 8) + gh) >> 8;
        uint32 b = ((bh >> 8) + bh) >> 8;
        
        uint32 rgb;
        rgb |= uint32(0xFF) << 24;
        rgb |= r << 16;
        rgb |= g << 8;
        rgb |= b;

        return rgb;
    }

    uint32 public constant ALPHA_MASK = 0xFF000000;
    uint32 public constant RED_BLUE_MASK = 0x00FF00FF;
    uint32 public constant GREEN_MASK = 0x0000FF00;
    uint32 public constant ALPHA_GREEN_MASK = ALPHA_MASK | GREEN_MASK;
    uint32 public constant ONE_OVER_ALPHA_MASK = 0x01000000;

    /**
     @notice A speed-focused blend that calculates red and blue channels simultaneously, with error trending to black.
     @dev Based on: https://stackoverflow.com/a/27141669
     */
    function alpha_composite_fast(uint32 bg, uint32 fg)
        internal
        pure
        returns (uint32)
    {
        uint32 a = (fg & ALPHA_MASK) >> 24;
        uint32 na = 255 - a;
        uint32 rb = ((na * (bg & RED_BLUE_MASK)) + (a * (fg & RED_BLUE_MASK))) >> 8;
        uint32 ag = (na * ((bg & ALPHA_GREEN_MASK) >> 8)) + (a * (ONE_OVER_ALPHA_MASK | ((fg & GREEN_MASK) >> 8)));
        return ((rb & RED_BLUE_MASK) | (ag & ALPHA_GREEN_MASK));
    }

    /**
     @notice An accuracy-focused blend that rounds results after calculating values for each channel using both alpha values.
     @dev Ported from https://github.com/python-pillow/Pillow/blob/main/src/libImaging/AlphaComposite.c
     */
    function alpha_composite_pillow(uint32 bg, uint32 fg)
        internal
        pure
        returns (uint32)    
    {
		/*
			The Python Imaging Library (PIL) is

				Copyright © 1997-2011 by Secret Labs AB
				Copyright © 1995-2011 by Fredrik Lundh

			Pillow is the friendly PIL fork. It is

				Copyright © 2010-2022 by Alex Clark and contributors

			Like PIL, Pillow is licensed under the open source HPND License:

			By obtaining, using, and/or copying this software and/or its associated
			documentation, you agree that you have read, understood, and will comply
			with the following terms and conditions:

			Permission to use, copy, modify, and distribute this software and its
			associated documentation for any purpose and without fee is hereby granted,
			provided that the above copyright notice appears in all copies, and that
			both that copyright notice and this permission notice appear in supporting
			documentation, and that the name of Secret Labs AB or the author not be
			used in advertising or publicity pertaining to distribution of the software
			without specific, written prior permission.

			SECRET LABS AB AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
			SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
			IN NO EVENT SHALL SECRET LABS AB OR THE AUTHOR BE LIABLE FOR ANY SPECIAL,
			INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
			LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
			OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
			PERFORMANCE OF THIS SOFTWARE.
		*/
		
        uint32 m = uint32(0xFF);
        uint32 o = uint8(fg >> 24) * m + uint8(bg >> 24) * (m - uint8(fg >> 24));
        uint64 a = uint8(fg >> 24) * m * 0xFF * (1 << 7) / o;
        uint64 na = m * (1 << 7) - a;

        uint64 r1 = uint8(fg >> 16) * a + uint8(bg >> 16) * na + (0x80 << 7);
        uint64 g1 = uint8(fg >> 8) * a + uint8(bg >> 8) * na + (0x80 << 7);
        uint64 b1 = uint8(fg >> 0) * a + uint8(bg >> 0) * na + (0x80 << 7);

        uint64 r = ((r1 >> 8) + r1) >> 8 >> 7;
        uint64 g = ((g1 >> 8) + g1) >> 8 >> 7;
        uint64 b = ((b1 >> 8) + b1) >> 8 >> 7; 

        uint32 rgb;
        rgb |= uint32(0xFF) << 24;
        rgb |= uint32(r << 16);
        rgb |= uint32(g << 8);
        rgb |= uint32(b);

        return rgb;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./AnimationFrame.sol";

struct Animation {
    uint32 frameCount;
    AnimationFrame[] frames;
    uint16 width;
    uint16 height;
}