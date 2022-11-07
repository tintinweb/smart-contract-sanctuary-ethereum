// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/DynamicBuffer.sol';
import "../utils/Random.sol";
import "../utils/Palette.sol";
import {Utils} from "../utils/Utils.sol";

contract Grids is Random, Palette {
    function generateLayer(uint256 _seed, uint8 _index) private pure returns (uint256 seed, string memory layer, uint32 noise) {
        seed = _seed;
        (, bytes memory buffer) = DynamicBuffer.allocate(18000);

        seed = prng(seed);
        noise = randBool(seed, 850) ? 0 : randBool(prng(seed), 150) ? 2 : 1;
        DynamicBuffer.appendBytes(buffer, bytes(abi.encodePacked(
          '<g transform-origin=\\"400 600\\" transform=\\"scale(',
          ['1','2','4','.5', '3'][_index],
          ')\\"><g transform=\\"scale(2)\\" ',
          noise == 1 ? 'opacity=\\".7\\" filter=\\"url(#f)\\">' :
          noise == 2 ? 'opacity=\\".7\\" filter=\\"url(#f) url(#f)\\">' : 'opacity=\\".7\\">',
          '<rect width=\\"1600\\" height=\\"2400\\" fill=\\"none\\"/>'
        )));
        
        for (uint32 id = 0; id < 12 * 8;) {
            seed = prng(seed);
            if(randBool(seed, 600)) {
                uint32 scale = randUInt32(seed, 0, 5);
                seed = prng(seed);
                DynamicBuffer.appendBytes(buffer, bytes(abi.encodePacked(
                    '<rect transform=\\"translate(',
                    Utils.uint32ToString((id%8) * 50),
                    ', ',
                    Utils.uint32ToString((id/8) * 50),
                    ') scale(',
                    ['.5', '1', '2.5', '5', '10'][scale],
                    ') translate(',
                    ['50,50', '25,25', '10,10', '5,5', '2.5,2.5'][scale],
                    ') rotate(',
                    ['0', '90', '180', '270'][randUInt32(seed, 0, 4)]
                )));
                DynamicBuffer.appendBytes(buffer, bytes(abi.encodePacked(
                    ') translate(',
                    ['-50,-50', '-25,-25', '-10,-10', '-5,-5', '-2.5,-2.5'][scale],
                    ')\\" width=\\"',
                    ['100', '50', '20', '10', '5'][scale],
                    '\\" height=\\"',
                    ['100', '50', '20', '10', '5'][scale],
                    '\\" fill=\\"url(#p',
                    ['0','1','2','3','4','5','6','7'][randUInt32(prng(seed), 0, 8)],
                    ')\\"/>'
                )));
                seed = prng(seed);
            }

            unchecked {
                id++;
            }
        }

        DynamicBuffer.appendBytes(buffer, bytes(abi.encodePacked(
            '</g></g>'
        )));

        layer = string(buffer);
    }

    function generateSVG(uint256 _seed) public view returns (string memory svg, string memory attributes) {
        uint32 tmp;
        uint32 noise;
        uint256 seed;
        string memory layer;
        string[8] memory paletteRGB;
        (, bytes memory svgBuffer) = DynamicBuffer.allocate(150 + 105 * 800);
        (, bytes memory attrBuffer) = DynamicBuffer.allocate(1000);

        seed = prng(prng(prng(_seed)));
        (paletteRGB, tmp, seed) = getRandomPalette(seed);

        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '{"trait_type":"Shape","value":"Grids"},{"trait_type":"Palette ID","value":',
            Utils.uint2str(tmp)
        )));


        seed = prng(seed);
        tmp = randBool(seed, 700) ? 0 : randUInt32(seed, 1, 3);
        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '},{"trait_type":"Filter","value":"',
            ['None', 'Grayscale', 'Sepia'][tmp],
            '},{"trait_type":"Noise Type","value":"',
            ['Turbulence', 'Fractal'][randUInt32(prng(seed), 0, 2)]
        )));

        seed = prng(seed);
        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '<svg xmlns=\\"http://www.w3.org/2000/svg\\" viewBox=\\"0 0 800 1200\\" style=\\"background:rgb(',
            paletteRGB[0],
            ')\\"><style>g>rect{mix-blend-mode:hard-light;stroke:none}#r{filter:contrast(250%) ',
            ['', 'grayscale(100%) contrast(150%)', 'sepia(100%)'][tmp],
            '}</style><defs><clipPath id=\\"clip\\"><rect width=\\"800\\" height=\\"1200\\"/></clipPath><filter id=\\"f\\"  primitiveUnits=\\"userSpaceOnUse\\"><feTurbulence type=\\"',
            ['turbulence', 'fractalNoise'][randUInt32(seed, 0, 2)],
            '\\" seed=\\"',
            Utils.uint32ToString(randUInt32(seed, 0, 1000)),
            '\\" baseFrequency=\\".005\\" numOctaves=\\"10\\" result=\\"t\\"/><feDisplacementMap in2=\\"t\\" in=\\"SourceGraphic\\" scale=\\"400\\" xChannelSelector=\\"R\\" yChannelSelector=\\"G\\"/></filter><pattern id=\\"p0\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect width=\\"5\\" height=\\"5\\" fill=\\"rgb(',
            paletteRGB[1],
            ')\\"/><rect x=\\"5\\" y=\\"5\\" width=\\"5\\" height=\\"5\\" fill=\\"rgb(',
            paletteRGB[1],
            ')\\"/></pattern><pattern id=\\"p1\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect width=\\"5\\" height=\\"10\\" fill=\\"rgb(',
            paletteRGB[2]
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            ')\\"/></pattern><pattern id=\\"p2\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect width=\\"10\\" height=\\"5\\" fill=\\"rgb(',
            paletteRGB[3],
            ')\\"/></pattern><pattern id=\\"p3\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><path d=\\"M0,0 L10,10 L0,10 Z\\" fill=\\"rgb(',
            paletteRGB[4],
            ')\\"/></pattern><pattern id=\\"p4\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><rect width=\\"2.5\\" height=\\"2.5\\" fill=\\"rgb(',
            paletteRGB[5],
            ')\\"/><rect x=\\"2.5\\" y=\\"2.5\\" width=\\"2.5\\" height=\\"2.5\\" fill=\\"rgb(',
            paletteRGB[5],
            ')\\"/><rect x=\\"5\\" y=\\"5\\" width=\\"2.5\\" height=\\"2.5\\" fill=\\"rgb(',
            paletteRGB[5]
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '\\"/><rect x=\\"7.5\\" y=\\"7.5\\" width=\\"2.5\\" height=\\"2.5\\" fill=\\"rgb(',
            paletteRGB[5],
            ')\\"/></pattern><pattern id=\\"p5\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><circle cx=\\"5\\" cy=\\"5\\" r=\\"5\\" fill=\\"rgb(',
            paletteRGB[6],
            ')\\" stroke=\\"none\\"/></pattern><pattern id=\\"p6\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><path d=\\"M5,0 L10,5 L5,10 L0,5 Z\\" fill=\\"rgb(',
            paletteRGB[6],
            ')\\"/></pattern><pattern id=\\"p7\\" width=\\"10\\" height=\\"10\\" patternUnits=\\"userSpaceOnUse\\"><line x1=\\"-15\\" y1=\\"-5\\" x2=\\"5\\" y2=\\"15\\" stroke=\\"rgb(',
            paletteRGB[7],
            ')\\" stroke-width=\\"5\\"/><line x1=\\"-5\\" y1=\\"-5\\" x2=\\"15\\" y2=\\"15\\" stroke=\\"rgb(',
            paletteRGB[7],
            ')\\" stroke-width=\\"5\\"/><line x1=\\"5\\" y1=\\"-5\\" x2=\\"25\\" y2=\\"15\\" stroke=\\"rgb(',
            paletteRGB[7],
            ')\\" stroke-width=\\"5\\"/></pattern></defs>'
        )));

        seed = prng(seed);
        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '<g id=\\"r\\" clip-path=\\"url(#clip)\\" >'
        )));

        seed = prng(seed);
        noise = 0;
        for (uint8 index = 0; index < 5;) {
            (seed, layer, tmp) = generateLayer(seed, index);
            noise += tmp;
            DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
                layer
            )));
            
            unchecked {
                index++;
            }
        }
        DynamicBuffer.appendBytes(attrBuffer, bytes(abi.encodePacked(
            '},{"trait_type":"Noise Level","value":"',
            Utils.uint2str(noise),
            '}'
        )));

        DynamicBuffer.appendBytes(svgBuffer, bytes(abi.encodePacked(
            '</g></svg>'
        )));

        svg = string(svgBuffer);

        attributes = string(attrBuffer);
    }
}

// taken from https://github.com/dievardump/solidity-dynamic-buffer

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump)
///         this library is just putting together code created by David Huber
///         that you can find in https://github.com/cxkoda/strange-attractors/
///         he gave me the authorization to put it together into a single library
/// @notice This library is used to allocate a big amount of memory and then always update the buffer content
///         without needing to reallocate memory. This allows to save a lot of gas when manipulating bytes/strings
///         tests have allowed to return a bite more than 800k bytes within one call
/// @dev First, allocate memory. Then use DynamicBuffer.appendBytes(buffer, theBytes);
library DynamicBuffer {
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory container, bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                let size := add(capacity, 0x40)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return (container, buffer);
    }

    /// @notice Appends data_ to buffer_, and update buffer_ length
    /// @param buffer_ the buffer to append the data to
    /// @param data_ the data to append
    function appendBytes(bytes memory buffer_, bytes memory data_)
        internal
        pure
    {
        assembly {
            let length := mload(data_)
            for {
                let data := add(data_, 32)
                let dataEnd := add(data, length)
                let buf := add(buffer_, add(mload(buffer_), 32))
            } lt(data, dataEnd) {
                data := add(data, 32)
                buf := add(buf, 32)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length.
                mstore(buf, mload(data))
            }

            // Update buffer length
            mstore(buffer_, add(mload(buffer_), length))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Random {

  /*
  * Compute x[n + 1] = (7^5 * x[n]) mod (2^31 - 1).
  * From "Random number generators: good ones are hard to find",
  * Park and Miller, Communications of the ACM, vol. 31, no. 10,
  * October 1988, p. 1195.
  */
  function prng (uint256 _seed) public pure returns (uint256 seed) {
    seed = (16807 * _seed) % 2147483647;
  }

  function randUInt32 (
    uint256 _seed, 
    uint32 _min, 
    uint32 _max
    ) public pure returns (uint32 rnd) {
      rnd = uint32(_min + _seed % (_max - _min));
  }

   function randBool(
    uint256 _seed, 
    uint32 _threshold
  ) public pure returns (bool rnd) {
    rnd = (_seed % 1000) < _threshold;
  }

  function expRandUInt32(
    uint256 _seed, 
    uint32 _min, 
    uint32 _max
  ) public pure returns (uint32 rnd) {
    uint32 diff = _max - _min; 
    rnd = _min + randUInt32(_seed, 0, diff) * randUInt32(_seed * 7, 0, diff) / diff;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Random.sol';
import {Utils} from "./Utils.sol";

contract Palette is Random {

    uint32 constant PALETTE_COUNT = 48;

    uint32[5][PALETTE_COUNT] palettes = [
      [0x101010,0xc5c3c6,0x46494c,0x4c5c68,0x1985a1],
      [0x20bf55,0x0b4f6c,0x292a73,0xfbfbff,0x757575],
      [0x06aed5,0x086788,0x303030,0xcccccc,0xdd1c1a],
      [0x909090,0xf2dc9b,0x6b6b6b,0x260101,0x0d0d0d],
      [0xffa822,0x3a9efd,0x3e4491,0x292a73,0x1a1b4b],
      [0x1b3da6,0x26488c,0x2372d9,0x62abd9,0xf2f557],
      [0x2d3142,0x4f5d75,0xbfc0c0,0xffffff,0x292a73],
      [0xf6511d,0xffb400,0x00a6ed,0x292a73,0x0d2c54],
      [0xdddddd,0x404099,0x929bac,0x013d6f,0x071e44],
      [0x3f0259,0xf2e205,0x606060,0xf2ebdc,0xf6511d],
      [0x302840,0x1f1d59,0x3e518c,0x808080,0xdddddd],
      [0x606060,0xbfc0c0,0x348aa7,0x525174,0x513b56],
      [0xef476f,0xffd166,0x06d6a0,0x118ab2,0x073b4c],
      [0x0b132b,0x1c2541,0x3a506b,0x5bc0be,0x6fffe9],
      [0xbce784,0x5dd39e,0x348aa7,0x525174,0x513b56],
      [0x000000,0x14213d,0xfca311,0xe5e5e5,0xffffff],
      [0x114b5f,0x028090,0xe4fde1,0x456990,0xf45b69],
      [0xdcdcdd,0xc5c3c6,0x46494c,0x4c5c68,0x1985a1],
      [0x22223b,0x4a4e69,0x9a8c98,0xc9ada7,0xf2e9e4],
      [0x3d5a80,0x98c1d9,0xe0fbfc,0xee6c4d,0x293241],
      [0x06aed5,0x086788,0xf0c808,0xfff1d0,0xdd1c1a],
      [0x011627,0xf71735,0x41ead4,0xfdfffc,0xff9f1c],
      [0x13293d,0x006494,0x247ba0,0x1b98e0,0xe8f1f2],
      [0xcfdbd5,0xe8eddf,0xf5cb5c,0x242423,0x333533],
      [0xffbf00,0xe83f6f,0x2274a5,0x32936f,0xffffff],
      [0x540d6e,0xee4266,0xffd23f,0x3bceac,0x0ead69],
      [0xffa69e,0xfaf3dd,0xb8f2e6,0xaed9e0,0x5e6472],
      [0x8a00d4,0xd527b7,0xf782c2,0xf9c46b,0xe3e3e3],
      [0x272643,0xffffff,0xe3f6f5,0xbae8e8,0x2c698d],
      [0x361d32,0x543c52,0xf55951,0xedd2cb,0xf1e8e6],
      [0x122c91,0x2a6fdb,0x48d6d2,0x81e9e6,0xfefcbf],
      [0x27104e,0x64379f,0x9854cb,0xddacf5,0x75e8e7],
      [0xe0f0ea,0x95adbe,0x574f7d,0x503a65,0x3c2a4d],
      [0xffa822,0x134e6f,0xff6150,0x1ac0c6,0xdee0e6],
      [0xd9d9d9,0xa6a6a6,0x8c8c8c,0x595959,0x262626],
      [0xa6032f,0x022873,0x035aa6,0x04b2d9,0x05dbf2],
      [0xa6a6a6,0x737373,0x404040,0x262626,0x0d0d0d],
      [0x0f5cbf,0x072b59,0x0f6dbf,0x042940,0x72dbf2],
      [0x0b132b,0x1c2541,0x3a506b,0x5bc0be,0x6fffe9],
      [0x000000,0x14213d,0xfca311,0xe5e5e5,0xffffff],
      [0x22223b,0x4a4e69,0x9a8c98,0xc9ada7,0xf2e9e4],
      [0x3d5a80,0x98c1d9,0xe0fbfc,0xee6c4d,0x293241],
      [0x011627,0xf71735,0x41ead4,0xfdfffc,0xff9f1c],
      [0xd8dbe2,0xa9bcd0,0x58a4b0,0x373f51,0x1b1b1e],
      [0x13293d,0x006494,0x247ba0,0x1b98e0,0xe8f1f2],
      [0xcfdbd5,0xe8eddf,0xf5cb5c,0x242423,0x333533],
      [0x97151f,0xdfe5e5,0x176c6a,0x013b44,0x212220],
      [0xfef7ee,0xfef000,0xfb0002,0x1c82eb,0x190c28]
    ];

    function hexToRgb(uint32 _c) public pure returns(string memory)  {
      return string(
        abi.encodePacked(
          Utils.uint32ToString(_c >> 16 & 0xff),
          ",",
          Utils.uint32ToString(_c >> 8 & 0xff),
          ",",
          Utils.uint32ToString(_c & 0xff)
        )
      );
    }

    function getRandomPalette(uint256 _seed) 
    view public
    returns (
      string[8] memory paletteRGB,
      uint32 paletteId,
      uint256 seed
    )
    {
      seed = prng(_seed);
      paletteId = randUInt32(seed, 0, PALETTE_COUNT);

      for(uint8 i = 0; i < 5; i++) {
        paletteRGB[i] = hexToRgb(palettes[paletteId][i]);
      }

      paletteRGB[5] = hexToRgb(0x222222); // add blackish
      paletteRGB[6] = hexToRgb(0xffffff); // add white

      seed = prng(seed);
      paletteRGB[7] = hexToRgb([0xff0000, 0xffff00][randUInt32(seed, 0, 2)]); // add red or yellow

      string memory temp;
      // limit to 6 in order to avoid too many white/red/yellow backgrounds
      for (uint8 i = 0; i < 6; i++) {
        seed = prng(seed);
        uint32 n = randUInt32(seed, i, 6);
        temp = paletteRGB[n];
        paletteRGB[n] = paletteRGB[i];
        paletteRGB[i] = temp;
      }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Utils {
  // convert a uint to str
  function uint2str(uint _i) internal pure returns (string memory str) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    j = _i;
    while (j != 0) {
        bstr[--k] = bytes1(uint8(48 + j % 10));
        j /= 10;
    }
    str = string(bstr);
    }

  function uint32ToString(uint32 v) pure internal returns (string memory str) {
    if (v == 0) {
        return "0";
    }
    // max uint32 4294967295 so 10 digits
    uint maxlength = 10;
    bytes memory reversed = new bytes(maxlength);
    uint i = 0;
    while (v != 0) {
        uint remainder = v % 10;
        v = v / 10;
        reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i);
    for (uint j = 0; j < i; j++) {
        s[j] = reversed[i - j - 1];
    }
    str = string(s);
  }

  function addressToString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
   }

   function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}