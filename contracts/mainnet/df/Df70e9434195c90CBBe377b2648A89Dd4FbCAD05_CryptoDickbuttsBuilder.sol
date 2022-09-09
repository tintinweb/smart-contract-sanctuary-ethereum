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

import "@openzeppelin/contracts/access/Ownable.sol";

import "./lib/SSTORE2.sol";
import "./lib/graphics/Animation.sol";
import "./lib/graphics/IPixelRenderer.sol";
import "./lib/graphics/IAnimationEncoder.sol";
import "./lib/graphics/ISVGWrapper.sol";

import "./lib/interfaces/IBuilder.sol";

contract CryptoDickbuttsBuilder is Ownable, IBuilder {
    error UnexpectedTraitCount(uint256 traitCount);

    uint8 public constant canonicalSize = 54;

    mapping(uint256 => address) data;
    mapping(uint256 => address) deltas;

    function getCanonicalSize()
        external
        pure
        override
        returns (uint256, uint256)
    {
        return (canonicalSize, canonicalSize);
    }

    function setData(uint256 key, bytes memory imageData) external onlyOwner {
        data[key] = SSTORE2.write(imageData);
    }

    function setDelta(uint256 key, bytes memory imageData) external onlyOwner {
        deltas[key] = SSTORE2.write(imageData);
    }

    /**
    @notice Returns the canonical image for the given metadata buffer, in an encoded data URI format.
     */
    function getImage(
        IPixelRenderer renderer,
        IAnimationEncoder encoder,
        uint8[] memory metadata,
        uint tokenId
    ) external view override returns (string memory) {
        return encoder.getDataUri(_getAnimation(renderer, metadata, tokenId));
    }

    function _getAnimation(IPixelRenderer renderer, uint8[] memory metadata, uint tokenId)
        private
        view
        returns (Animation memory animation)
    {
        animation.width = canonicalSize;
        animation.height = canonicalSize;
        animation.frames = new AnimationFrame[](1);

        AnimationFrame memory frame;
        frame.width = animation.width;
        frame.height = animation.height;
        frame.buffer = new uint32[](frame.width * frame.height);

        DrawFrame memory drawFrame;
        drawFrame.blend = AlphaBlend.Type.Pillow;

        if (metadata.length == 12) {
            _renderAttribute(renderer, frame, drawFrame, metadata[0]);  // background
            _renderAttribute(renderer, frame, drawFrame, metadata[1]);  // skin
            _renderAttribute(renderer, frame, drawFrame, metadata[9]);  // butt
            _renderAttribute(renderer, frame, drawFrame, metadata[3]);  // hat
            _renderAttribute(renderer, frame, drawFrame, metadata[5]);  // mouth
            _renderAttribute(renderer, frame, drawFrame, metadata[2]);  // body
            _renderAttribute(renderer, frame, drawFrame, metadata[10]); // dick
            _renderAttribute(renderer, frame, drawFrame, metadata[8]);  // shoes
            _renderAttribute(renderer, frame, drawFrame, metadata[6]);  // nose
            _renderAttribute(renderer, frame, drawFrame, metadata[4]);  // eyes
            _renderAttribute(renderer, frame, drawFrame, metadata[7]);  // hand
            _renderAttribute(renderer, frame, drawFrame, metadata[11]); // special
        } else if (metadata.length == 1) {
            _renderAttribute(renderer, frame, drawFrame, metadata[0]);  // legendary
        } else {
            revert UnexpectedTraitCount(metadata.length);
        }

        address delta = deltas[tokenId];
        if(delta != address(0)) {
            drawFrame.blend = AlphaBlend.Type.None;
            drawFrame.buffer = SSTORE2.read(delta);
            drawFrame.frame = frame;
            drawFrame.position = 0;
            drawFrame.ox = 0;
            drawFrame.oy = 0;
            _renderFrame(renderer, frame, drawFrame);
        }

        animation.frames[animation.frameCount++] = frame;
    }

    function _renderAttribute(
        IPixelRenderer renderer,
        AnimationFrame memory frame,
        DrawFrame memory drawFrame,
        uint8 attribute
    ) private view {
        uint256 position;
        uint8 offsetX;
        uint8 offsetY;

        address feature = data[attribute];
        if (feature == address(0)) return;

        bytes memory buffer = SSTORE2.read(feature);
        (offsetX, position) = _readByte(position, buffer);
        (offsetY, position) = _readByte(position, buffer);

        drawFrame.buffer = buffer;
        drawFrame.position = position;
        drawFrame.frame = frame;
        drawFrame.ox = offsetX;
        drawFrame.oy = offsetY;

        _renderFrame(renderer, frame, drawFrame);
    }

    function _readByte(uint256 position, bytes memory buffer)
        private
        pure
        returns (uint8, uint256)
    {
        uint8 value = uint8(buffer[position++]);
        return (value, position);
    }

    function _renderFrame(
        IPixelRenderer renderer,
        AnimationFrame memory frame,
        DrawFrame memory drawFrame        
    ) private pure returns (uint256) {
        
        (uint32[] memory colors, uint256 positionAfterColor) = renderer.getColorTable(drawFrame.buffer, drawFrame.position);
        drawFrame.colors = colors;
        drawFrame.position = positionAfterColor;

        (uint32[] memory newBuffer, uint256 positionAfterDraw) = renderer.drawFrameWithOffsets(drawFrame);
        frame.buffer = newBuffer;

        return positionAfterDraw;
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
pragma solidity ^0.8.13;

import "./Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
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

interface ISVGWrapper {
    function getWrappedImage(
        string memory imageUri,
        uint256 canonicalWidth,
        uint256 canonicalHeight
    ) external view returns (string memory imageDataUri);
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
pragma solidity ^0.8.13;

library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
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