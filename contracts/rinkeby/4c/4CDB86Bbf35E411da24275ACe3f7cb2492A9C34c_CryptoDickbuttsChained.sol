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

/*
CryptoDickbuttsChained Programmed By:
 __      __         __    __                 
/  \    /  \_____ _/  |__/  |_  _________.__.
\   \/\/   /\__  \\   __\   __\/  ___<   |  |
 \        /  / __ \|  |  |  |  \___ \ \___  |
  \__/\  /  (____  /__|  |__| /____  >/ ____|
       \/        \/                \/ \/     
(https://wattsy.art)

To the extent possible under law, the artist known as Wattsy has waived all copyright and related or neighboring rights to CryptoDickbuttsChained. 
This work is published from: Canada.
*/


pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./lib/interfaces/IBuilder.sol";
import "./lib/interfaces/IMetadata.sol";
import "./lib/interfaces/IStrings.sol";
import "./lib/interfaces/IRandom.sol";
import "./lib/interfaces/ITokenURIBuilder.sol";

import "./lib/graphics/IAnimationEncoder.sol";
import "./lib/graphics/IPixelRenderer.sol";

contract CryptoDickbuttsChained is Ownable {

    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE =
        0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    string DESCRIPTION = "Once a utopia, Gooch Island has fallen and CryptoDickbutts have been evacuated. Series 3 features 5200 all new CryptoDickbutts, each with a set of randomly generated traits.";
    string EXTERNAL_URL = "https://cryptodickbutts.com/";
    string PREFIX = "CryptoDickbutt";

    error URIQueryForNonExistentToken(uint256 tokenId);

    /**
    @notice Sets the address of the metadata provider contract.
     */
    function setDetails(string memory description, string memory externalUrl, string memory prefix) external onlyOwner {
        DESCRIPTION = description;
        EXTERNAL_URL = externalUrl;
        PREFIX = prefix;
    }

    /** @notice Contract responsible for looking up metadata. */
    IMetadata public metadata;

    /**
    @notice Sets the address of the metadata provider contract.
     */
    function setMetadata(address _metadata) external onlyOwner {
        metadata = IMetadata(_metadata);
    }

    /** @notice Contract responsible for building images. */
    IBuilder public builder;

    /**
    @notice Sets the address of the builder contract.
     */
    function setBuilder(address _builder) external onlyOwner {
        builder = IBuilder(_builder);
    }

    /** @notice Contract responsible for encoding images */
    IAnimationEncoder public encoder;

    /**
    @notice Sets the address of the encoder contract.
     */
    function setEncoder(address _encoder) external onlyOwner {
        encoder = IAnimationEncoder(_encoder);
    }

    /** @notice Contract responsible for rastering images */
    IPixelRenderer public renderer;

    /**
    @notice Sets the address of the renderer contract.
     */
    function setRenderer(address _renderer) external onlyOwner {
        renderer = IPixelRenderer(_renderer);
    }

    /** @notice Contract responsible for looking up strings. */
    IStrings public strings;

    /**
    @notice Sets the address of the string provider contract.
     */
    function setStrings(address _strings) external onlyOwner {
        strings = IStrings(_strings);
    }

    /** @notice Contract responsible for wrapping images in SVG for display. */
    ISVGWrapper public svgWrapper;

    /**
    @notice Sets the address of the SVG wrapper contract.
     */
    function setSVGWrapper(address _svgWrapper) external onlyOwner {
        svgWrapper = ISVGWrapper(_svgWrapper);
    }

    /** @notice Contract responsible for creating the tokenURI */
    ITokenURIBuilder public uriBuilder;

    /**
    @notice Sets the address of the tokenURI builder contract.
     */
    function setTokenURIBuilder(address _tokenUriBuilder) external onlyOwner {
        uriBuilder = ITokenURIBuilder(_tokenUriBuilder);
    }

    /** @notice Contract responsible for creating random images */
    IRandom public random;

    /**
    @notice Sets the address of the random provider contract.
     */
    function setRandom(address _random) external onlyOwner {
        random = IRandom(_random);
    }

    /**
    @notice Retrieves the image data URI for a given token ID.
    @param tokenId Token ID referring to an existing CryptoDickbutts NFT Token ID
    */
    function imageURI(uint256 tokenId) external view returns (string memory) {
        uint8[] memory meta = metadata.getMetadata(tokenId);
        if (meta.length == 0) revert URIQueryForNonExistentToken(tokenId);        
        return builder.getImage(renderer, encoder, meta, tokenId);
    }

    /**
    @notice Retrieves the image data URI for a given token ID, wrapped in an SVG for large display formats.
    @param tokenId Token ID referring to an existing CryptoDickbutts NFT Token ID
    */
    function imageURIWrapped(uint256 tokenId) external view returns (string memory) {
        uint8[] memory meta = metadata.getMetadata(tokenId);
        if (meta.length == 0) revert URIQueryForNonExistentToken(tokenId); 
        string memory imageUri = builder.getImage(renderer, encoder, meta, tokenId);
        (uint256 width, uint256 height) = builder.getCanonicalSize();
        return svgWrapper.getWrappedImage(
            imageUri,
            width,
            height
        );
    }

    /**
    @notice Retrieves the token data URI for a given token ID. Includes both the image and its accompanying metadata.
    @param tokenId Token ID referring to an existing CryptoDickbutts NFT Token ID
    */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        uint8[] memory meta = metadata.getMetadata(tokenId);
        if (meta.length == 0) revert URIQueryForNonExistentToken(tokenId);

        string memory imageUri = builder.getImage(renderer, encoder, meta, tokenId);
        (uint256 width, uint256 height) = builder.getCanonicalSize();
        string memory imageDataUri = svgWrapper.getWrappedImage(
            imageUri,
            width,
            height
        );

        return
            uriBuilder.build(
                metadata,
                strings,
                tokenId,
                imageUri,
                imageDataUri,
                DESCRIPTION,
                EXTERNAL_URL,
                PREFIX,
                meta
            );
    }

    /**
    @notice Retrieves a random token data URI. This generates a completely new and unofficial CryptoDickbutts.
    @param seed An unsigned 64-bit integer representing the image.
    */
    function randomTokenURI(uint64 seed) external view returns (string memory) {
        (string memory imageUri, uint8[] memory meta) = random.randomImageURI(
            seed,
            builder,
            renderer,
            encoder
        );
        (uint256 canonicalWidth, uint256 canonicalHeight) = builder
            .getCanonicalSize();
        string memory imageDataUri = svgWrapper.getWrappedImage(
            imageUri,
            canonicalWidth,
            canonicalHeight
        );
        return
            uriBuilder.build(
                metadata,
                strings,
                seed,
                imageUri,
                imageDataUri,
                DESCRIPTION,
                EXTERNAL_URL,
                PREFIX,
                meta
            );
    }

    /**
    @notice Retrieves a random image data URI. This generates a completely new and unoffical CryptoDickbutts image.
    */
    function randomImageURI(uint64 seed) external view returns (string memory) {
        (string memory imageUri, ) = random.randomImageURI(
            seed,
            builder,
            renderer,
            encoder
        );
        return imageUri;
    }

    /**
    @notice Retrieves a random image data URI, wrapped in an SVG for large display formats. This generates a completely new and unoffical CryptoDickbutts image.
    */
    function randomImageURIWrapped(uint64 seed) external view returns (string memory) {
        (string memory imageUri, ) = random.randomImageURI(
            seed,
            builder,
            renderer,
            encoder
        );
        (uint256 canonicalWidth, uint256 canonicalHeight) = builder.getCanonicalSize();
        string memory imageDataUri = svgWrapper.getWrappedImage(
            imageUri,
            canonicalWidth,
            canonicalHeight
        );
        return imageDataUri;
    }

    /**
    @notice Retrieves a specific token URI built from raw metadata. This generates a user-defined Cryptodickbutt, not officially part of the collection.
    @param meta An array of unsigned 8-bit integers (bytes) to use to produce the raw image.
    @dev The data passed here is not validated, so can result in an illogical Cryptodickbutt, or rendering errors, if the format is not valid.
    */
    function buildTokenURI(uint8[] memory meta)
        external
        view
        returns (string memory)
    {
        string memory imageUri = builder.getImage(renderer, encoder, meta, 0);
        (uint256 canonicalWidth, uint256 canonicalHeight) = builder.getCanonicalSize();
        string memory imageDataUri = svgWrapper.getWrappedImage(
            imageUri,
            canonicalWidth,
            canonicalHeight
        );
        return
            uriBuilder.build(
                metadata,
                strings,
                uint64(uint256(keccak256(abi.encodePacked(meta)))),
                imageUri,
                imageDataUri,
                DESCRIPTION,
                EXTERNAL_URL,
                PREFIX,
                meta
            );
    }

    /**
    @notice Retrieves a specific image URI built from raw metadata. This generates a user-defined Cryptodickbutt image, not officially part of the collection.
    @param meta An array of unsigned 8-bit integers (bytes) to use to produce the raw image.
    @dev The data passed here is not validated, so can result in an illogical Cryptodickbutt, or rendering errors, if the format is not valid.
    */
    function buildImageURI(uint8[] memory meta)
        external
        view
        returns (string memory)
    {
        return builder.getImage(renderer, encoder, meta, 0);
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

import "./IBuilder.sol";

interface IRandom { 
    // function randomTokenURI(uint64 seed) external view returns (string memory);
    function randomImageURI(uint64 seed, IBuilder builder, IPixelRenderer renderer, IAnimationEncoder encoder) external view returns (string memory imageUri, uint8[] memory meta);
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

import "./Animation.sol";

interface IAnimationEncoder {
    function getDataUri(Animation memory animation)
        external
        pure
        returns (string memory);
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

interface ISVGWrapper {
    function getWrappedImage(
        string memory imageUri,
        uint256 canonicalWidth,
        uint256 canonicalHeight
    ) external view returns (string memory imageDataUri);
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