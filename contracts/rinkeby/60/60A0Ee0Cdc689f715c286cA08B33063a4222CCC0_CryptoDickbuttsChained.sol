// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./lib/interfaces/IBuilder.sol";
import "./lib/interfaces/IMetadata.sol";
import "./lib/interfaces/IStrings.sol";
import "./lib/interfaces/IRandom.sol";
import "./lib/interfaces/ITokenURIBuilder.sol";

import "./lib/graphics/IAnimationEncoder.sol";
import "./lib/graphics/IPixelRenderer.sol";

contract CryptoDickbuttsChained is Ownable {
    string constant DESCRIPTION = "Once a utopia, Gooch Island has fallen and CryptoDickbutts have been evacuated. Series 3 features 5200 all new CryptoDickbutts, each with a set of randomly generated traits.";
    string constant EXTERNAL_URL = "https://cryptodickbutts.com/";
    string constant PREFIX = "CryptoDickbutt";

    error URIQueryForNonExistentToken(uint256 tokenId);

    using ERC165Checker for address;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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