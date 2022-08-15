// SPDX-License-Identifier: CC0-1.0

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^~~~~~~^::::^~~~^:::^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^:::~~~^::::^~7JJ7^:::~7J?7^.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~^::::::::^7YPPPPP5555PPPPPPP55PPPPPPP^.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~::~?JJJJJY5PPP5YYJJJ????7777777!!!75PPP5.^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~:.5PPPPPPPPPPPP?!777????JJJJJJYYYYYY55555:.^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~.~PPPP55YJJ??7777!!~~~~~~^^^^^^:::::..:.........~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~.!PPP^............:^^....:......::^~!~...::::. :~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~^.^JJ57..:::::^!???77~^~7??:..:^???7!!!!77::...^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~^..?7YPY^...::!!^:^7???!^:..~:..::.^??7~^:...^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~^::~5!!!YPY!:......:^:....:!YPPJ!^:......:~?Y::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~.:P5JJYY5PPPPY?7~^^::^~!?Y5P555555YJ?777?JJJJ:.^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~:.~Y7!JPY?77!!!!!!~~!!!!~~!~~~!!!!77?????JJ???7~.^~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~^.7YYPPPP!^?7~!!77^^77!:7??!:777~:!!~~~~!7?JYPGYJ~.^~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~^^.^?7!!~~.~~.:~!!^::~~^.~~~^.^^^:.:..    .^!75P7!~~^:^~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~^.^.:~!:.7:.???.^??7 .^::^^::~~:.~^:.:^^!?YPGBBBGGGGP5J::~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~.^?!.!J::7!.^!~.:~!7?P~~GPP^^J?!~?JJY5PP55YJ?77!!!!!:.:^~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~^:::..:..!!77::7^~7JJ?~^!!!!777777!!!!~~!~!??JYY77YPJ ::~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~.YGPPPJ7!!~~~~!7777??JJYY5555PJ!^.YPPY5PY7YP! :^~~~^^^^~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~^.:J~JPPPPP?YPPP!YPPP7JPPP5?PPPPP5:YPP~7PPPY~.^^^^::~~!~::~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~...... ^PPPPJ^5PP5^5PPP~7PPPY:5PPPPP5P55Y?7~:::::^~::5PPPPY.^~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~^^:. ...::..^?Y55555YJ??????????7777!!!^~^^..:^^~:.!5PPP^~P57~~^^^:^~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~^:.....:....:::....::...77 .. ....... .^^^.:~~^^~~~^ YP?JPP!:!:7YPPPPY.^~~~~~~~~~~~~
~~~~~~~~~~~~~~:....:.....:..::::::......~Y .:.....:. ...~~~~~~~~~~~~.~PJ~~~..~5PPPY??~ ^~~~~~~~~~~~~
~~~~~~~~~~~~^...::...:^~~~^ .:....::..:....:..:^^^....:..^~~~~~~~~~:. .7PP5?.JPP?^~7??7::~~~~~~~~~~~
~~~~~~~~~~~^..:::..:~~~~~~~..:..^~~~:.::. .:..:^^:... ::..^~~~~~~~......^YPP?^~^.YP5J5G? ~~~~~~~~~~~
~~~~~~~~~~~..:::..^~~~~~~~~..::......:::.~:.::....::. .::..:~~~~~~. .:::..7PPP57:!!~!?~.^~~~~~~~~~~~
~~~~~~~~~~~..:::..:~~~~~~~~^ .::::::::::....::::::::..:..::...:::...:......^J5PP5J7~::^~~~~~~~~~~~~~
~~~~~~~~~~~..:::: .~~~~~~~~~..:::::::::::...::...:.. :~^................:~~^::^^^::^~~~~~~~~~~~~~~~~
~~~~~~~~~~^. ..... :::^^^:~~............ :7....:. ...~~~~^:........:^~~~~~~~~~~^~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~^..:7JY!7Y5J^5::~^:..^^^^^^:^~???7??7:.~~~~~~~~~~~~^^^~~~~~~~~^^::^~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~.^PPPPPPP5.^.^~~~~:.!JJ??!^^!??7~^^.~~~~~~~~~~~~~~~~~~~~^:.... .^.:~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~^.5PPPPPPPPPP.:~~~~~^.:!????7^:.:~7!.~~~~~~~~~~~~~~~~~^:......:!?J7.^~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~^.JPPPPPP5Y7^.~~~~~~~~^.:~????7~:^7^.~~~~~~~~~~~~~~~:...::.. ^?J??7.^~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~^.~7777~:::^~~~~~~~~~~~^::~?????!^..~^::.::^~~~~~:...::...!7^:~77.:~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~^^^^^^~~~~~~~~~~~~~~~~^:..^7????7~: ........^^..:::....~:7??~..:~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~^:::::.:::.:^~!7~:^!?????~...::::....::....~.. .?!:.~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~^....... ^JJ::J?7!~:..:~7??J!....:::::::..~?^:^ :^:.^~^^~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~ .::::::..^^: ... :~~~^:::~:^7J~ .::::..^???7~~..:^^:. .^~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~..:::::::........:^:..^~~^:.:~:..:::..::~7??7^::^^.::.  .^~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~^^:..:::::.... .:^..:. :..:~~^:......:7J?~:::.:~~~.^~~...::~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~...:^....::::::....:~:::. .:^~~~~~:. :7?7~^::^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~^:.....::::...~~~^^^:..~~~~~~~~^::::^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^::........^~~~^::^~~:.:~~~~~^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^~~~~~~~~~~..^:~~~^.::~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~                                     
*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";

import "../ICrypToadzCustomAnimations.sol";
import "../ICrypToadzCustomImageBank.sol";
import "../BufferUtils.sol";
import "../CrypToadzCustomImageBank.sol";

contract CrypToadzCustomAnimations is Ownable, ICrypToadzCustomAnimations {

    mapping(uint256 => address) customImageBank;

    function isCustomAnimation(uint256 tokenId) external view returns (bool) {        
        address bank = customImageBank[tokenId];
        if (bank == address(0)) {
            return false;
        }
        return ICrypToadzCustomImageBank(bank).isCustomImage(tokenId);
    }

    function getCustomAnimation(uint256 tokenId)
        external
        view
        returns (bytes memory buffer)
    {
        return ICrypToadzCustomImageBank(customImageBank[tokenId]).getCustomImage();
    }

    struct Addresses {
        address _37;
        address _318;
        address _466;
        address _1519;
        address _1943;
        address _2208;
        address _3250;
        address _3661;
        address _4035;
        address _4911;
        address _5086;
        address _5844;
        address _6131;
        address _43000000;
        address _48000000;
    }

    function setAddresses(Addresses memory a) external onlyOwner {
        customImageBank[37] = a._37;
        customImageBank[318] = a._318;
        customImageBank[466] = a._466;
        customImageBank[1519] = a._1519;
        customImageBank[1943] = a._1943;
        customImageBank[2208] = a._2208;
        customImageBank[3250] = a._3250;
        customImageBank[3661] = a._3661;
        customImageBank[4035] = a._4035;
        customImageBank[4911] = a._4911;
        customImageBank[5086] = a._5086;
        customImageBank[5844] = a._5844;
        customImageBank[6131] = a._6131;
        customImageBank[43000000] = a._43000000;
        customImageBank[48000000] = a._48000000;
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
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
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

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIFEncoder.sol";

interface ICrypToadzCustomAnimations {
    function isCustomAnimation(uint256 tokenId) external view returns (bool);
    function getCustomAnimation(uint256 tokenId) external view returns (bytes memory buffer);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

interface ICrypToadzCustomImageBank {
    function isCustomImage(uint256 tokenId) external view returns (bool);

    function getCustomImage()
        external
        view
        returns (bytes memory buffer);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./lib/InflateLib.sol";
import "./lib/SSTORE2.sol";
import "./Errors.sol";

library BufferUtils {
    function decompress(address compressed, uint256 decompressedLength)
        internal
        view
        returns (bytes memory)
    {
        (InflateLib.ErrorCode code, bytes memory buffer) = InflateLib.puff(
            SSTORE2.read(compressed),
            decompressedLength
        );
        if (code != InflateLib.ErrorCode.ERR_NONE)
            revert FailedToDecompress(uint256(code));
        if (buffer.length != decompressedLength)
            revert InvalidDecompressionLength(
                decompressedLength,
                buffer.length
            );
        return buffer;
    }

    function advanceToTokenPosition(uint256 tokenId, bytes memory buffer)
        internal
        pure
        returns (uint256 position, uint8 length)
    {
        uint256 id;
        while (id != tokenId) {
            (id, position) = BufferUtils.readUInt32(position, buffer);
            (length, position) = BufferUtils.readByte(position, buffer);
            if (id != tokenId) {
                position += length;
                if (position >= buffer.length) return (position, 0);
            }
        }
        return (position, length);
    }

    function advanceToTokenPositionDelta(uint256 tokenId, bytes memory buffer)
        internal
        pure
        returns (uint256 position, uint32 length)
    {
        uint256 id;
        while (id != tokenId) {
            (id, position) = BufferUtils.readUInt32(position, buffer);
            (length, position) = BufferUtils.readUInt32(position, buffer);
            if (id != tokenId) {
                position += length;
                if (position >= buffer.length) return (position, 0);
            }
        }
        return (position, length);
    }

    function readUInt32(uint256 position, bytes memory buffer)
        internal
        pure
        returns (uint32, uint256)
    {
        uint8 d1 = uint8(buffer[position++]);
        uint8 d2 = uint8(buffer[position++]);
        uint8 d3 = uint8(buffer[position++]);
        uint8 d4 = uint8(buffer[position++]);
        return ((16777216 * d4) + (65536 * d3) + (256 * d2) + d1, position);
    }

    function readByte(uint256 position, bytes memory buffer)
        internal
        pure
        returns (uint8, uint256)
    {
        uint8 value = uint8(buffer[position++]);
        return (value, position);
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "./BufferUtils.sol";

library CrypToadzCustomImageBank {
    function getCustomImageCompressed(mapping(uint8 => uint16) storage lengths, mapping(uint8 => address) storage data)
        internal
        view
        returns (bytes memory buffer)
    {
        uint256 size;
        uint8 count;
        while (lengths[count] != 0) {
            size += lengths[count++];
        }
        buffer = DynamicBuffer.allocate(size);
        for (uint8 i = 0; i < count; i++) {
            bytes memory chunk = BufferUtils.decompress(
                data[i],
                lengths[i]
            );            
            DynamicBuffer.appendUnchecked(buffer, chunk);
        }
    }

    function getCustomImageUncompressed(mapping(uint8 => uint16) storage lengths, mapping(uint8 => address) storage data)
        internal
        view
        returns (bytes memory buffer)
    {
        uint256 size;
        uint8 count;
        while (lengths[count] != 0) {
            size += lengths[count++];
        }
        buffer = DynamicBuffer.allocate(size);
        for (uint8 i = 0; i < count; i++) {
            bytes memory chunk = SSTORE2.read(data[i]);            
            DynamicBuffer.appendUnchecked(buffer, chunk);
        }
    }

    function getCustomImageSingleCompressed(uint16 length, address data)
        internal
        view
        returns (bytes memory buffer)
    {
        return BufferUtils.decompress(data, length);
    }

    function getCustomImageSingleUncompressed(address data)
        internal
        view
        returns (bytes memory buffer)
    {
        return SSTORE2.read(data);
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

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./lib/Base64.sol";
import "./IGIFEncoder.sol";
import "./GIF.sol";

/** @notice Encodes image data in GIF format. GIF is much more compact than SVG, allows for animation (SVG does as well), and also represents images that are already rastered. 
            This is important if the art shouldn't change fundamentally depending on which process is doing the SVG rendering, such as a browser or custom application.
 */
contract GIFEncoder is IGIFEncoder {
    
    uint32 private constant MASK = (1 << 12) - 1;
    uint32 private constant CLEAR_CODE = 256;
    uint32 private constant END_CODE = 257;
    uint16 private constant CODE_START = 258;
    uint16 private constant TREE_TABLE_LENGTH = 4096;
    uint16 private constant CODE_TABLE_LENGTH = TREE_TABLE_LENGTH - CODE_START;

    bytes private constant HEADER = hex"474946383961";
    bytes private constant NETSCAPE = hex"21FF0b4E45545343415045322E300301000000";
    bytes private constant GIF_URI_PREFIX = "data:image/gif;base64,";

    struct GCT {
        uint32 start;
        uint32 count;
    }

    struct LZW {
        uint16 codeCount;
        int32 codeBitsUsed;
        uint32 activePrefix;
        uint32 activeSuffix;
        uint32[CODE_TABLE_LENGTH] codeTable;
        uint16[TREE_TABLE_LENGTH] treeRoots;
        Pending pending;
    }

    struct Pending {
        uint32 value;
        int32 bits;
        uint32 chunkSize;
    }

    function getDataUri(GIF memory gif) external pure returns (string memory) {
        (bytes memory buffer, uint length) = encode(gif);
        string memory base64 = Base64.encode(buffer, length);
        return string(abi.encodePacked(GIF_URI_PREFIX, base64));
    }

    function encode(GIF memory gif) private pure returns (bytes memory buffer, uint length) {
        buffer = new bytes(gif.width * gif.height * 3);
        uint32 position = 0;

        // header
        position = writeBuffer(buffer, position, HEADER);

        // logical screen descriptor
        {
            position = writeUInt16(buffer, position, gif.width);
            position = writeUInt16(buffer, position, gif.height);

            uint8 packed = 0;
            packed |= 1 << 7;
            packed |= 7 << 4;
            packed |= 0 << 3;
            packed |= 7 << 0;

            position = writeByte(buffer, position, packed);
            position = writeByte(buffer, position, 0);
            position = writeByte(buffer, position, 0);
        }

        // global color table
        GCT memory gct;
        gct.start = position;
        gct.count = 1;
        {
            for (uint256 i = 0; i < 768; i++) {
                position = writeByte(buffer, position, 0);
            }
        }

        if (gif.frameCount > 1) {
            // netscape extension block
            position = writeBuffer(buffer, position, NETSCAPE);
        }

        uint32[CODE_TABLE_LENGTH] memory codeTable;

        for (uint256 i = 0; i < gif.frameCount; i++) {
            // graphic control extension
            {
                position = writeByte(buffer, position, 0x21);
                position = writeByte(buffer, position, 0xF9);
                position = writeByte(buffer, position, 0x04);

                uint8 packed = 0;
                packed |= (gif.frameCount > 1 ? 2 : 0) << 2;
                packed |= 0 << 1;
                packed |= 1 << 0;
                position = writeByte(buffer, position, packed);

                position = writeUInt16(buffer, position, gif.frameCount > 1 ? gif.frames[i].delay : uint16(0));                
                position = writeByte(buffer, position, 0);
                position = writeByte(buffer, position, 0);
            }

            // image descriptor
            {
                position = writeByte(buffer, position, 0x2C);
                position = writeUInt16(buffer, position, uint16(0));
                position = writeUInt16(buffer, position, uint16(0));
                position = writeUInt16(buffer, position, gif.frames[i].width);
                position = writeUInt16(buffer, position, gif.frames[i].height);

                uint8 packed = 0;
                packed |= 0 << 7;
                packed |= 0 << 6;
                packed |= 0 << 5;
                packed |= 0 << 0;
                position = writeByte(buffer, position, packed);
            }

            // image data
            {
                uint16[TREE_TABLE_LENGTH] memory treeRoots;

                (uint32 p, uint32 c) = writeImageData(
                    buffer,
                    position,
                    gct,
                    gif.frames[i],
                    LZW(0, 9, 0, 0, codeTable, treeRoots, Pending(0, 0, 0))
                );
                position = p;
                gct.count = c;
            }
        }

        // trailer
        position = writeByte(buffer, position, 0x3B);

        return (buffer, position);
    }

    function writeBuffer(
        bytes memory buffer,
        uint32 position,
        bytes memory value
    ) private pure returns (uint32) {
        for (uint256 i = 0; i < value.length; i++)
            buffer[position++] = bytes1(value[i]);
        return position;
    }

    function writeByte(
        bytes memory buffer,
        uint32 position,
        uint8 value
    ) private pure returns (uint32) {
        buffer[position++] = bytes1(value);
        return position;
    }

    function writeUInt16(
        bytes memory buffer,
        uint32 position,
        uint16 value
    ) private pure returns (uint32) {
        buffer[position++] = bytes1(uint8(uint16(value >> 0)));
        buffer[position++] = bytes1(uint8(uint16(value >> 8)));
        return position;
    }

    function writeImageData(
        bytes memory buffer,
        uint32 position,
        GCT memory gct,
        GIFFrame memory frame,
        LZW memory lzw
    ) private pure returns (uint32, uint32) {
                
        position = writeByte(buffer, position, 8);
        position = writeByte(buffer, position, 0);

        lzw.codeCount = 0;
        lzw.codeBitsUsed = 9;

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                CLEAR_CODE,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        {
            (uint32 c, uint32 p) = getColorTableIndex(
                buffer,
                gct.start,
                gct.count,
                frame.buffer[0]
            );
            gct.count = c;
            lzw.activePrefix = p;
        }        

        for (uint32 i = 1; i < frame.width * frame.height; i++) {

            (uint32 c, uint32 p) = getColorTableIndex(
                buffer,
                gct.start,
                gct.count,
                frame.buffer[i]
            );
            gct.count = c;
            lzw.activeSuffix = p;

            position = writeColor(buffer, position, lzw);
        }

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                lzw.activePrefix,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                END_CODE,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        if (lzw.pending.bits > 0) {
            position = writeChunked(
                buffer,
                position,
                uint8(lzw.pending.value & 0xFF),
                lzw.pending
            );
            lzw.pending.value = 0;
            lzw.pending.bits = 0;
        }

        if (lzw.pending.chunkSize > 0) {
            buffer[position - lzw.pending.chunkSize - 1] = bytes1(
                uint8(uint32(lzw.pending.chunkSize))
            );
            lzw.pending.chunkSize = 0;
            position = writeByte(buffer, position, 0);
        }

        return (position, gct.count);
    }

    function writeColor(bytes memory buffer, uint32 position, LZW memory lzw) private pure returns (uint32) {
        uint32 lastTreePosition = 0;
        uint32 foundSuffix = 0;

        bool found = false;
        {
            uint32 treePosition = lzw.treeRoots[lzw.activePrefix];
            while (treePosition != 0) {
                lastTreePosition = treePosition;
                foundSuffix = lzw.codeTable[treePosition - CODE_START] & 0xFF;

                if (lzw.activeSuffix == foundSuffix) {
                    lzw.activePrefix = treePosition;
                    found = true;
                    break;
                } else if (lzw.activeSuffix < foundSuffix) {
                    treePosition = (lzw.codeTable[treePosition - CODE_START] >> 8) & MASK;
                } else {
                    treePosition = lzw.codeTable[treePosition - CODE_START] >> 20;
                }
            }
        }

        if (!found) {
            {
                (
                    uint32 p,
                    Pending memory pending
                ) = writeVariableBitsChunked(
                        buffer,
                        position,
                        lzw.activePrefix,
                        lzw.codeBitsUsed,
                        lzw.pending
                    );
                position = p;
                lzw.pending = pending;
            }

            if (lzw.codeCount == CODE_TABLE_LENGTH) {
                {
                    (
                        uint32 p,
                        Pending memory pending
                    ) = writeVariableBitsChunked(
                            buffer,
                            position,
                            CLEAR_CODE,
                            lzw.codeBitsUsed,
                            lzw.pending
                        );
                    position = p;
                    lzw.pending = pending;
                }

                for (uint16 j = 0; j < TREE_TABLE_LENGTH; j++) {
                    lzw.treeRoots[j] = 0;
                }
                lzw.codeCount = 0;
                lzw.codeBitsUsed = 9;
            } else {
                if (lastTreePosition == 0)
                    lzw.treeRoots[lzw.activePrefix] = uint16(CODE_START + lzw.codeCount);
                else if (lzw.activeSuffix < foundSuffix)
                    lzw.codeTable[lastTreePosition - CODE_START] = (lzw.codeTable[lastTreePosition - CODE_START] & ~(MASK << 8)) | (uint32(CODE_START + lzw.codeCount) << 8);
                else {
                    lzw.codeTable[lastTreePosition - CODE_START] = (lzw.codeTable[lastTreePosition - CODE_START] & ~(MASK << 20)) | (uint32(CODE_START + lzw.codeCount) << 20);
                }

                if (uint32(CODE_START + lzw.codeCount) == (uint32(1) << uint32(lzw.codeBitsUsed))) {
                    lzw.codeBitsUsed++;
                }

                lzw.codeTable[lzw.codeCount++] = lzw.activeSuffix;
            }

            lzw.activePrefix = lzw.activeSuffix;
        }

        return position;
    }    

    function writeVariableBitsChunked(
        bytes memory buffer,
        uint32 position,
        uint32 value,
        int32 bits,
        Pending memory pending
    ) private pure returns (uint32, Pending memory) {
        while (bits > 0) {
            int32 takeBits = min(bits, 8 - pending.bits);
            uint32 takeMask = uint32((uint32(1) << uint32(takeBits)) - 1);

            pending.value |= ((value & takeMask) << uint32(pending.bits));

            pending.bits += takeBits;
            bits -= takeBits;
            value >>= uint32(takeBits);

            if (pending.bits == 8) {
                position = writeChunked(
                    buffer,
                    position,
                    uint8(pending.value & 0xFF),
                    pending
                );
                pending.value = 0;
                pending.bits = 0;
            }
        }

        return (position, pending);
    }

    function writeChunked(
        bytes memory buffer,
        uint32 position,
        uint8 value,
        Pending memory pending
    ) private pure returns (uint32) {
        position = writeByte(buffer, position, value);
        pending.chunkSize++;

        if (pending.chunkSize == 255) {
            buffer[position - 256] = bytes1(uint8(255));
            pending.chunkSize = 0;
            position = writeByte(buffer, position, 0);
        }

        return position;
    }

    function getColorTableIndex(
        bytes memory buffer,
        uint32 colorTableStart,
        uint32 colorCount,
        uint32 target
    ) private pure returns (uint32, uint32) {
        if (target >> 24 != 0xFF) return (colorCount, 0);

        uint32 i = 1;
        for (; i < colorCount; i++) {
            if (uint8(buffer[colorTableStart + i * 3 + 0]) != uint8(target >> 16)
            ) continue;
            if (uint8(buffer[colorTableStart + i * 3 + 1]) != uint8(target >> 8)
            ) continue;
            if (uint8(buffer[colorTableStart + i * 3 + 2]) != uint8(target >> 0)
            ) continue;
            return (colorCount, i);
        }

        if (colorCount == 256) {
            return (
                colorCount,
                getColorTableBestMatch(
                    buffer,
                    colorTableStart,
                    colorCount,
                    target
                )
            );
        } else {
            buffer[colorTableStart + colorCount * 3 + 0] = bytes1(uint8(target >> 16));
            buffer[colorTableStart + colorCount * 3 + 1] = bytes1(uint8(target >> 8));
            buffer[colorTableStart + colorCount * 3 + 2] = bytes1(uint8(target >> 0));
            return (colorCount + 1, colorCount);
        }
    }

    function getColorTableBestMatch(
        bytes memory buffer,
        uint32 colorTableStart,
        uint32 colorCount,
        uint32 target
    ) private pure returns (uint32) {
        uint32 bestDistance = type(uint32).max;
        uint32 bestIndex = 0;

        for (uint32 i = 1; i < colorCount; i++) {
            uint32 distance;
            {
                uint8 rr = uint8(buffer[colorTableStart + i * 3 + 0]) - uint8(target >> 16);
                uint8 gg = uint8(buffer[colorTableStart + i * 3 + 1]) - uint8(target >> 8);
                uint8 bb = uint8(buffer[colorTableStart + i * 3 + 2]) - uint8(target >> 0);
                distance = rr * rr + gg * gg + bb * bb;
            }
            if (distance < bestDistance) {
                bestDistance = distance;
                bestIndex = i;
            }
        }

        return bestIndex;
    }

    function max(uint32 val1, uint32 val2) private pure returns (uint32) {
        return (val1 >= val2) ? val1 : val2;
    }

    function min(uint32 val1, uint32 val2) private pure returns (uint32) {
        return (val1 <= val2) ? val1 : val2;
    }

    function min(int32 val1, int32 val2) private pure returns (int32) {
        return (val1 <= val2) ? val1 : val2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data, uint length) internal pure returns (string memory) {
        if (data.length == 0 || length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIF.sol";

interface IGIFEncoder {
    function getDataUri(GIF memory gif) external pure returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIFFrame.sol";

struct GIF {
    uint32 frameCount;
    GIFFrame[] frames;
    uint16 width;
    uint16 height;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

struct GIFFrame {
    uint32[] buffer;
    uint16 delay;
    uint16 width;
    uint16 height;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
library InflateLib {
    // Maximum bits in a code
    uint256 constant MAXBITS = 15;
    // Maximum number of literal/length codes
    uint256 constant MAXLCODES = 286;
    // Maximum number of distance codes
    uint256 constant MAXDCODES = 30;
    // Maximum codes lengths to read
    uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
    // Number of fixed literal/length codes
    uint256 constant FIXLCODES = 288;

    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    // Input and output state
    struct State {
        //////////////////
        // Output state //
        //////////////////
        // Output buffer
        bytes output;
        // Bytes written to out so far
        uint256 outcnt;
        /////////////////
        // Input state //
        /////////////////
        // Input buffer
        bytes input;
        // Bytes read so far
        uint256 incnt;
        ////////////////
        // Temp state //
        ////////////////
        // Bit buffer
        uint256 bitbuf;
        // Number of bits in bit buffer
        uint256 bitcnt;
        //////////////////////////
        // Static Huffman codes //
        //////////////////////////
        Huffman lencode;
        Huffman distcode;
    }

    // Huffman code decoding tables
    struct Huffman {
        uint256[] counts;
        uint256[] symbols;
    }

    function bits(State memory s, uint256 need)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Bit accumulator (can use up to 20 bits)
        uint256 val;

        // Load at least need bits into val
        val = s.bitbuf;
        while (s.bitcnt < need) {
            if (s.incnt == s.input.length) {
                // Out of input
                return (ErrorCode.ERR_NOT_TERMINATED, 0);
            }

            // Load eight bits
            val |= uint256(uint8(s.input[s.incnt++])) << s.bitcnt;
            s.bitcnt += 8;
        }

        // Drop need bits and update buffer, always zero to seven bits left
        s.bitbuf = val >> need;
        s.bitcnt -= need;

        // Return need bits, zeroing the bits above that
        uint256 ret = (val & ((1 << need) - 1));
        return (ErrorCode.ERR_NONE, ret);
    }

    function _stored(State memory s) private pure returns (ErrorCode) {
        // Length of stored block
        uint256 len;

        // Discard leftover bits from current byte (assumes s.bitcnt < 8)
        s.bitbuf = 0;
        s.bitcnt = 0;

        // Get length and check against its one's complement
        if (s.incnt + 4 > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        len = uint256(uint8(s.input[s.incnt++]));
        len |= uint256(uint8(s.input[s.incnt++])) << 8;

        if (
            uint8(s.input[s.incnt++]) != (~len & 0xFF) ||
            uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)
        ) {
            // Didn't match complement!
            return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
        }

        // Copy len bytes from in to out
        if (s.incnt + len > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        if (s.outcnt + len > s.output.length) {
            // Not enough output space
            return ErrorCode.ERR_OUTPUT_EXHAUSTED;
        }
        while (len != 0) {
            // Note: Solidity reverts on underflow, so we decrement here
            len -= 1;
            s.output[s.outcnt++] = s.input[s.incnt++];
        }

        // Done with a valid stored block
        return ErrorCode.ERR_NONE;
    }

    function _decode(State memory s, Huffman memory h)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Current number of bits in code
        uint256 len;
        // Len bits being decoded
        uint256 code = 0;
        // First code of length len
        uint256 first = 0;
        // Number of codes of length len
        uint256 count;
        // Index of first code of length len in symbol table
        uint256 index = 0;
        // Error code
        ErrorCode err;

        for (len = 1; len <= MAXBITS; len++) {
            // Get next bit
            uint256 tempCode;
            (err, tempCode) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, 0);
            }
            code |= tempCode;
            count = h.counts[len];

            // If length len, return symbol
            if (code < first + count) {
                return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
            }
            // Else update for next length
            index += count;
            first += count;
            first <<= 1;
            code <<= 1;
        }

        // Ran out of codes
        return (ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE, 0);
    }

    function _construct(
        Huffman memory h,
        uint256[] memory lengths,
        uint256 n,
        uint256 start
    ) private pure returns (ErrorCode) {
        // Current symbol when stepping through lengths[]
        uint256 symbol;
        // Current length when stepping through h.counts[]
        uint256 len;
        // Number of possible codes left of current length
        uint256 left;
        // Offsets in symbol table for each length
        uint256[MAXBITS + 1] memory offs;

        // Count number of codes of each length
        for (len = 0; len <= MAXBITS; len++) {
            h.counts[len] = 0;
        }
        for (symbol = 0; symbol < n; symbol++) {
            // Assumes lengths are within bounds
            h.counts[lengths[start + symbol]]++;
        }
        // No codes!
        if (h.counts[0] == n) {
            // Complete, but decode() will fail
            return (ErrorCode.ERR_NONE);
        }

        // Check for an over-subscribed or incomplete set of lengths

        // One possible code of zero length
        left = 1;

        for (len = 1; len <= MAXBITS; len++) {
            // One more bit, double codes left
            left <<= 1;
            if (left < h.counts[len]) {
                // Over-subscribed--return error
                return ErrorCode.ERR_CONSTRUCT;
            }
            // Deduct count from possible codes

            left -= h.counts[len];
        }

        // Generate offsets into symbol table for each length for sorting
        offs[1] = 0;
        for (len = 1; len < MAXBITS; len++) {
            offs[len + 1] = offs[len] + h.counts[len];
        }

        // Put symbols in table sorted by length, by symbol order within each length
        for (symbol = 0; symbol < n; symbol++) {
            if (lengths[start + symbol] != 0) {
                h.symbols[offs[lengths[start + symbol]]++] = symbol;
            }
        }

        // Left > 0 means incomplete
        return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
    }

    function _codes(
        State memory s,
        Huffman memory lencode,
        Huffman memory distcode
    ) private pure returns (ErrorCode) {
        // Decoded symbol
        uint256 symbol;
        // Length for copy
        uint256 len;
        // Distance for copy
        uint256 dist;
        // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
        // Size base for length codes 257..285
        uint16[29] memory lens =
            [
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                13,
                15,
                17,
                19,
                23,
                27,
                31,
                35,
                43,
                51,
                59,
                67,
                83,
                99,
                115,
                131,
                163,
                195,
                227,
                258
            ];
        // Extra bits for length codes 257..285
        uint8[29] memory lext =
            [
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                1,
                1,
                2,
                2,
                2,
                2,
                3,
                3,
                3,
                3,
                4,
                4,
                4,
                4,
                5,
                5,
                5,
                5,
                0
            ];
        // Offset base for distance codes 0..29
        uint16[30] memory dists =
            [
                1,
                2,
                3,
                4,
                5,
                7,
                9,
                13,
                17,
                25,
                33,
                49,
                65,
                97,
                129,
                193,
                257,
                385,
                513,
                769,
                1025,
                1537,
                2049,
                3073,
                4097,
                6145,
                8193,
                12289,
                16385,
                24577
            ];
        // Extra bits for distance codes 0..29
        uint8[30] memory dext =
            [
                0,
                0,
                0,
                0,
                1,
                1,
                2,
                2,
                3,
                3,
                4,
                4,
                5,
                5,
                6,
                6,
                7,
                7,
                8,
                8,
                9,
                9,
                10,
                10,
                11,
                11,
                12,
                12,
                13,
                13
            ];
        // Error code
        ErrorCode err;

        // Decode literals and length/distance pairs
        while (symbol != 256) {
            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return err;
            }

            if (symbol < 256) {
                // Literal: symbol is the byte
                // Write out the literal
                if (s.outcnt == s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                s.output[s.outcnt] = bytes1(uint8(symbol));
                s.outcnt++;
            } else if (symbol > 256) {
                uint256 tempBits;
                // Length
                // Get and compute length
                symbol -= 257;
                if (symbol >= 29) {
                    // Invalid fixed code
                    return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
                }

                (err, tempBits) = bits(s, lext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                len = lens[symbol] + tempBits;

                // Get and check distance
                (err, symbol) = _decode(s, distcode);
                if (err != ErrorCode.ERR_NONE) {
                    // Invalid symbol
                    return err;
                }
                (err, tempBits) = bits(s, dext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                dist = dists[symbol] + tempBits;
                if (dist > s.outcnt) {
                    // Distance too far back
                    return ErrorCode.ERR_DISTANCE_TOO_FAR;
                }

                // Copy length bytes from distance bytes back
                if (s.outcnt + len > s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                while (len != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    len -= 1;
                    s.output[s.outcnt] = s.output[s.outcnt - dist];
                    s.outcnt++;
                }
            } else {
                s.outcnt += len;
            }
        }

        // Done with a valid fixed or dynamic block
        return ErrorCode.ERR_NONE;
    }

    function _build_fixed(State memory s) private pure returns (ErrorCode) {
        // Build fixed Huffman tables
        // TODO this is all a compile-time constant
        uint256 symbol;
        uint256[] memory lengths = new uint256[](FIXLCODES);

        // Literal/length table
        for (symbol = 0; symbol < 144; symbol++) {
            lengths[symbol] = 8;
        }
        for (; symbol < 256; symbol++) {
            lengths[symbol] = 9;
        }
        for (; symbol < 280; symbol++) {
            lengths[symbol] = 7;
        }
        for (; symbol < FIXLCODES; symbol++) {
            lengths[symbol] = 8;
        }

        _construct(s.lencode, lengths, FIXLCODES, 0);

        // Distance table
        for (symbol = 0; symbol < MAXDCODES; symbol++) {
            lengths[symbol] = 5;
        }

        _construct(s.distcode, lengths, MAXDCODES, 0);

        return ErrorCode.ERR_NONE;
    }

    function _fixed(State memory s) private pure returns (ErrorCode) {
        // Decode data until end-of-block code
        return _codes(s, s.lencode, s.distcode);
    }

    function _build_dynamic_lengths(State memory s)
        private
        pure
        returns (ErrorCode, uint256[] memory)
    {
        uint256 ncode;
        // Index of lengths[]
        uint256 index;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Error code
        ErrorCode err;
        // Permutation of code length codes
        uint8[19] memory order =
            [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

        (err, ncode) = bits(s, 4);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lengths);
        }
        ncode += 4;

        // Read code length code lengths (really), missing lengths are zero
        for (index = 0; index < ncode; index++) {
            (err, lengths[order[index]]) = bits(s, 3);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lengths);
            }
        }
        for (; index < 19; index++) {
            lengths[order[index]] = 0;
        }

        return (ErrorCode.ERR_NONE, lengths);
    }

    function _build_dynamic(State memory s)
        private
        pure
        returns (
            ErrorCode,
            Huffman memory,
            Huffman memory
        )
    {
        // Number of lengths in descriptor
        uint256 nlen;
        uint256 ndist;
        // Index of lengths[]
        uint256 index;
        // Error code
        ErrorCode err;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Length and distance codes
        Huffman memory lencode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
        Huffman memory distcode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));
        uint256 tempBits;

        // Get number of lengths in each table, check lengths
        (err, nlen) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        nlen += 257;
        (err, ndist) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        ndist += 1;

        if (nlen > MAXLCODES || ndist > MAXDCODES) {
            // Bad counts
            return (
                ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES,
                lencode,
                distcode
            );
        }

        (err, lengths) = _build_dynamic_lengths(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }

        // Build huffman table for code lengths codes (use lencode temporarily)
        err = _construct(lencode, lengths, 19, 0);
        if (err != ErrorCode.ERR_NONE) {
            // Require complete code set here
            return (
                ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE,
                lencode,
                distcode
            );
        }

        // Read length/literal and distance code length tables
        index = 0;
        while (index < nlen + ndist) {
            // Decoded value
            uint256 symbol;
            // Last length to repeat
            uint256 len;

            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return (err, lencode, distcode);
            }

            if (symbol < 16) {
                // Length in 0..15
                lengths[index++] = symbol;
            } else {
                // Repeat instruction
                // Assume repeating zeros
                len = 0;
                if (symbol == 16) {
                    // Repeat last length 3..6 times
                    if (index == 0) {
                        // No last length!
                        return (
                            ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH,
                            lencode,
                            distcode
                        );
                    }
                    // Last length
                    len = lengths[index - 1];
                    (err, tempBits) = bits(s, 2);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else if (symbol == 17) {
                    // Repeat zero 3..10 times
                    (err, tempBits) = bits(s, 3);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else {
                    // == 18, repeat zero 11..138 times
                    (err, tempBits) = bits(s, 7);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 11 + tempBits;
                }

                if (index + symbol > nlen + ndist) {
                    // Too many lengths!
                    return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
                }
                while (symbol != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    symbol -= 1;

                    // Repeat last or zero symbol times
                    lengths[index++] = len;
                }
            }
        }

        // Check for end-of-block code -- there better be one!
        if (lengths[256] == 0) {
            return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
        }

        // Build huffman table for literal/length codes
        err = _construct(lencode, lengths, nlen, 0);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                nlen != lencode.counts[0] + lencode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        // Build huffman table for distance codes
        err = _construct(distcode, lengths, ndist, nlen);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                ndist != distcode.counts[0] + distcode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        return (ErrorCode.ERR_NONE, lencode, distcode);
    }

    function _dynamic(State memory s) private pure returns (ErrorCode) {
        // Length and distance codes
        Huffman memory lencode;
        Huffman memory distcode;
        // Error code
        ErrorCode err;

        (err, lencode, distcode) = _build_dynamic(s);
        if (err != ErrorCode.ERR_NONE) {
            return err;
        }

        // Decode data until end-of-block code
        return _codes(s, lencode, distcode);
    }

    function puff(bytes memory source, uint256 destlen)
        internal
        pure
        returns (ErrorCode, bytes memory)
    {
        // Input/output state
        State memory s =
            State(
                new bytes(destlen),
                0,
                source,
                0,
                0,
                0,
                Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
                Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
            );
        // Temp: last bit
        uint256 last;
        // Temp: block type bit
        uint256 t;
        // Error code
        ErrorCode err;

        // Build fixed Huffman tables
        err = _build_fixed(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, s.output);
        }

        // Process blocks until last block or error
        while (last == 0) {
            // One if last block
            (err, last) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            // Block type 0..3
            (err, t) = bits(s, 2);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            err = (
                t == 0
                    ? _stored(s)
                    : (
                        t == 1
                            ? _fixed(s)
                            : (
                                t == 2
                                    ? _dynamic(s)
                                    : ErrorCode.ERR_INVALID_BLOCK_TYPE
                            )
                    )
            );
            // type == 3, invalid

            if (err != ErrorCode.ERR_NONE) {
                // Return with error
                break;
            }
        }

        return (err, s.output);
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

error UnsupportedDrawInstruction(uint8 instructionType);
error DoNotAddBlackToColorTable();
error InvalidDrawOrder(uint8 featureId);
error FailedToDecompress(uint errorCode);
error InvalidDecompressionLength(uint expected, uint actual);
error ImageFileOutOfRange(uint value);
error TraitOutOfRange(uint value);
error BadTraitCount(uint8 value);
error BadTraitChoice(uint8 value);

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