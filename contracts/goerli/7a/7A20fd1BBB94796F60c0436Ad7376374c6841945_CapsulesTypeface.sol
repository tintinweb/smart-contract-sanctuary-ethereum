// SPDX-License-Identifier: GPL-3.0

/**
  @title Capsules Typeface

  @author peri

  @notice Capsules Typeface stored on-chain using the Typeface contract. 7 "normal" fonts are supported, with weights 100-700. All characters require 2 or less bytes to encode.
 */

pragma solidity ^0.8.0;

import "./interfaces/ICapsuleToken.sol";
import "./Typeface.sol";

contract CapsulesTypeface is Typeface {
    /// Address of Capsules Token contract
    ICapsuleToken public immutable capsuleToken;

    constructor(
        Font[] memory fonts,
        bytes32[] memory hashes,
        address _capsuleToken
    ) Typeface("Capsules") {
        _setFontSourceHashes(fonts, hashes);

        capsuleToken = ICapsuleToken(_capsuleToken);
    }

    /// @notice Returns true if bytes1 char is supported by CapsulesTypeface. Requires less gas than checking supported bytes2 chars.
    function isSupportedByte(bytes1 char) external pure returns (bool) {
        // Optimize gas by first checking outer bound of byte ranges
        if (char < 0x20) return false;

        return (char <= 0x7e ||
            (char >= 0xa0 && char <= 0xa8) ||
            (char >= 0xab && char <= 0xac) ||
            (char >= 0xaf && char <= 0xb1) ||
            char == 0xb4 ||
            (char >= 0xb6 && char <= 0xb7) ||
            (char >= 0xba && char <= 0xbb) ||
            (char >= 0xbf && char <= 0xc4) ||
            (char >= 0xc6 && char <= 0xcf) ||
            (char >= 0xd1 && char <= 0xd7) ||
            (char >= 0xd9 && char <= 0xdc) ||
            (char >= 0xe0 && char <= 0xe4) ||
            (char >= 0xe6 && char <= 0xef) ||
            (char >= 0xf1 && char <= 0xfc) ||
            char == 0xff);
    }

    /// @notice Returns true if bytes2 char is supported by CapsulesTypeface. More bytes2 characters are supported than bytes1 characters, due to non-ascii characters requiring more than 1 byte to encode.
    function isSupportedBytes2(bytes2 char) external pure returns (bool) {
        // Optimize gas by first checking outer bounds of byte ranges
        if (char < 0x0020 || char > 0xe069) return false;

        return (char <= 0x007e ||
            (char >= 0x00a0 && char <= 0x00a8) ||
            (char >= 0x00ab && char <= 0x00ac) ||
            (char >= 0x00af && char <= 0x00b1) ||
            char == 0x00b4 ||
            (char >= 0x00b6 && char <= 0x00b7) ||
            (char >= 0x00ba && char <= 0x00bb) ||
            (char >= 0x00bf && char <= 0x00c4) ||
            (char >= 0x00c6 && char <= 0x00cf) ||
            (char >= 0x00d1 && char <= 0x00d7) ||
            (char >= 0x00d9 && char <= 0x00dc) ||
            (char >= 0x00e0 && char <= 0x00e4) ||
            (char >= 0x00e6 && char <= 0x00ef) ||
            (char >= 0x00f1 && char <= 0x00fc) ||
            (char >= 0x00ff && char <= 0x0101) ||
            (char >= 0x0112 && char <= 0x0113) ||
            (char >= 0x0128 && char <= 0x012b) ||
            char == 0x0131 ||
            (char >= 0x014c && char <= 0x014d) ||
            (char >= 0x0168 && char <= 0x016b) ||
            char == 0x0178 ||
            char == 0x0192 ||
            (char >= 0x02c2 && char <= 0x02c3) ||
            char == 0x02c6 ||
            char == 0x02dc ||
            char == 0x039e ||
            char == 0x03c0 ||
            char == 0x0e3f ||
            (char >= 0x2013 && char <= 0x2015) ||
            (char >= 0x2017 && char <= 0x201a) ||
            (char >= 0x201c && char <= 0x201e) ||
            (char >= 0x2020 && char <= 0x2022) ||
            char == 0x2026 ||
            char == 0x2030 ||
            (char >= 0x2032 && char <= 0x2033) ||
            (char >= 0x2039 && char <= 0x203a) ||
            char == 0x203c ||
            char == 0x203e ||
            char == 0x2044 ||
            char == 0x20a8 ||
            char == 0x20ac ||
            char == 0x20b4 ||
            char == 0x20bd ||
            char == 0x20bf ||
            (char >= 0x2190 && char <= 0x2199) ||
            (char >= 0x21ba && char <= 0x21bb) ||
            char == 0x2206 ||
            char == 0x220f ||
            (char >= 0x2211 && char <= 0x2212) ||
            char == 0x221a ||
            char == 0x221e ||
            char == 0x222b ||
            char == 0x2248 ||
            char == 0x2260 ||
            (char >= 0x2264 && char <= 0x2265) ||
            (char >= 0x2302 && char <= 0x2304) ||
            char == 0x231b ||
            char == 0x23cf ||
            (char >= 0x23e9 && char <= 0x23ea) ||
            (char >= 0x23ed && char <= 0x23ef) ||
            (char >= 0x23f8 && char <= 0x23fa) ||
            char == 0x25b2 ||
            char == 0x25b6 ||
            char == 0x25bc ||
            char == 0x25c0 ||
            char == 0x25ca ||
            char == 0x2600 ||
            char == 0x2610 ||
            char == 0x2612 ||
            char == 0x2630 ||
            (char >= 0x2639 && char <= 0x263a) ||
            char == 0x263c ||
            char == 0x2665 ||
            (char >= 0x2680 && char <= 0x2685) ||
            (char >= 0x2690 && char <= 0x2691) ||
            char == 0x26a1 ||
            char == 0x2713 ||
            (char >= 0x2b05 && char <= 0x2b0d) ||
            char == 0x2b95 ||
            (char >= 0xe000 && char <= 0xe02b) ||
            char == 0xe069);
    }

    /// @notice No characters in the Capsules Typeface require more than 2 bytes to encode. bytes3 values should be converted to bytes2 and validated using `isSupportedBytes2()`.
    function isSupportedBytes3(bytes3) external pure returns (bool) {}

    /// @notice No characters in the Capsules Typeface require more than 2 bytes to encode. bytes4 values should be converted to bytes2 and validated using `isSupportedBytes2()`.
    function isSupportedBytes4(bytes4) external pure returns (bool) {}

    /// @notice Mint pure color Capsule token to sender when sender sets fontSrc.
    function _afterSetSource(Font calldata font, bytes calldata)
        internal
        override(Typeface)
    {
        capsuleToken.mintPureColorForFontWeight(msg.sender, font.weight);
    }
}

// SPDX-License-Identifier: GPL-3.0

/**
  @title ICapsuleToken

  @author peri

  @notice Interface for CapsuleToken contract
 */

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct Capsule {
    uint256 id;
    bytes3 color;
    uint256 fontWeight;
    bytes2[16][8] text;
    bool isPure;
    bool isLocked;
}

interface ICapsuleToken {
    event MintCapsule(
        uint256 indexed id,
        address indexed to,
        bytes3 indexed color
    );
    event SetDefaultCapsuleRenderer(address renderer);
    event SetCapsuleMetadata(address metadata);
    event SetFeeReceiver(address receiver);
    event SetPureColors(bytes3[] colors);
    event SetRoyalty(uint256 royalty);
    event LockRenderer();
    event LockCapsule(uint256 indexed id);
    event EditCapsule(uint256 indexed id);
    event SetRendererOf(uint256 indexed id, address renderer);
    event Withdraw(address to, uint256 amount);

    function capsuleOf(uint256 capsuleId)
        external
        view
        returns (Capsule memory capsule);

    function isPureColor(bytes3 color) external view returns (bool);

    function pureColorForFontWeight(uint256 fontWeight)
        external
        view
        returns (bytes3 color);

    function htmlSafeTextOf(uint256 capsuleId)
        external
        returns (string[8] memory safeText);

    function colorOf(uint256 capsuleId) external view returns (bytes3 color);

    function textOf(uint256 capsuleId)
        external
        view
        returns (bytes2[16][8] memory text);

    function fontWeightOf(uint256 capsuleId)
        external
        view
        returns (uint256 fontWeight);

    function isLocked(uint256 capsuleId) external view returns (bool locked);

    function svgOf(uint256 capsuleId) external view returns (string memory);

    function mint(bytes3 color, uint256 fontWeight)
        external
        payable
        returns (uint256);

    function mintWithText(
        bytes3 color,
        uint256 fontWeight,
        bytes2[16][8] calldata text
    ) external payable returns (uint256);

    function mintWithValidText(
        bytes3 color,
        uint256 fontWeight,
        bytes2[16][8] calldata text
    ) external payable returns (uint256);

    function mintPureColorForFontWeight(address to, uint256 fontWeight)
        external
        returns (uint256 capsuleId);

    function lockCapsule(uint256 capsuleId) external;

    function editCapsule(
        uint256 capsuleId,
        bytes2[16][8] calldata text,
        uint256 fontWeight,
        bool lock
    ) external;

    function editCapsuleWithValidText(
        uint256 capsuleId,
        bytes2[16][8] calldata text,
        uint256 fontWeight,
        bool lock
    ) external;

    function setRendererOf(uint256 capsuleId, address renderer) external;

    function burn(uint256 capsuleId) external;

    function setDefaultCapsuleRenderer(address _capsuleRenderer) external;

    function isValidText(bytes2[16][8] memory text)
        external
        view
        returns (bool);

    function withdraw() external;

    function setFeeReceiver(address _feeReceiver) external;

    function setRoyalty(uint256 _royalty) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ITypeface.sol";

/**
  @title Typeface

  @author peri

  @notice The Typeface contract allows storing and retrieving font source data. Font sources can be large and cost large amounts of gas to store. To save gas or avoid surpassing gas limits while deploying a contract containing font source data, only a hash of the data is stored when the contract is deployed. This allows font data to be stored in later transactions, provided the data matches the corresponding hash. Fonts are identified by the Font struct, which includes "style" and "weight" properties.

  Four functions allow specifying which characters are supported by a typeface. ASCII characters can be encoded in a single byte, so typefaces using only this charset can override `isSupportedByte(bytes1)` to determine if a character is supported. For more complex characters requiring more than 1 byte to encode, `isSupportedBytes2(bytes2)`, `isSupportedBytes3(bytes3)`, or `isSupportedBytes4(bytes4)` should be used.
 */

abstract contract Typeface is ITypeface {
    /// @notice Mapping of weight => style => font source data as bytes.
    mapping(uint256 => mapping(string => bytes)) private _source;

    /// @notice Mapping of weight => style => keccack256 hash of font source data as bytes.
    mapping(uint256 => mapping(string => bytes32)) private _sourceHash;

    /// @notice Mapping of weight => style => true if font source has been stored. This serves as a gas-efficient way to check if a font source has been stored without getting the entire source data.
    mapping(uint256 => mapping(string => bool)) private _hasSource;

    /// @notice Typeface name
    string private _name;

    /// @notice Return typeface name.
    /// @return name Name of typeface
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @notice Return source bytes for font.
    /// @param font Font to check source of.
    /// @return source Font source data as bytes.
    function sourceOf(Font memory font)
        public
        view
        virtual
        returns (bytes memory)
    {
        return _source[font.weight][font.style];
    }

    /// @notice Return true if font source exists.
    /// @param font Font to check if source exists for.
    /// @return true True if font source exists.
    function hasSource(Font memory font) public view virtual returns (bool) {
        return _hasSource[font.weight][font.style];
    }

    /// @notice Return hash of source bytes for font.
    /// @param font Font to return source hash of.
    /// @return sourceHash Hash of source for font.
    function sourceHash(Font memory font)
        public
        view
        virtual
        returns (bytes32)
    {
        return _sourceHash[font.weight][font.style];
    }

    /// @notice Sets source for Font.
    /// @dev The keccack256 hash of the source must equal the sourceHash of the font.
    /// @param font Font to set source for.
    /// @param source Font source as bytes.
    function setSource(Font calldata font, bytes calldata source) public {
        require(
            _hasSource[font.weight][font.style] == false,
            "Typeface: font source already exists"
        );

        require(
            keccak256(source) == _sourceHash[font.weight][font.style],
            "Typeface: Invalid font"
        );

        _beforeSetSource(font, source);

        _source[font.weight][font.style] = source;
        _hasSource[font.weight][font.style] = true;

        emit SetSource(font);

        _afterSetSource(font, source);
    }

    /// @notice Sets hash of source data for each font in a list.
    /// @dev Length of fonts and hashes arrays must be equal. Each hash from hashes array will be set for the font with matching index in the fonts array.
    /// @param fonts Array of fonts to set hashes for.
    /// @param hashes Array of hashes to set for fonts.
    function _setFontSourceHashes(Font[] memory fonts, bytes32[] memory hashes)
        internal
    {
        require(
            fonts.length == hashes.length,
            "Typeface: Unequal number of fonts and hashes"
        );

        for (uint256 i; i < fonts.length; i++) {
            _sourceHash[fonts[i].weight][fonts[i].style] = hashes[i];

            emit SetSourceHash(fonts[i], hashes[i]);
        }
    }

    constructor(string memory __name) {
        _name = __name;
    }

    /// @notice Function called before setSource() is called.
    function _beforeSetSource(Font calldata font, bytes calldata src)
        internal
        virtual
    {}

    /// @notice Function called after setSource() is called.
    function _afterSetSource(Font calldata font, bytes calldata src)
        internal
        virtual
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

/**
  @title ITypeface

  @author peri

  @notice Interface for Typeface contract
 */

pragma solidity ^0.8.0;

struct Font {
    uint256 weight;
    string style;
}

interface ITypeface {
    /// @notice Emitted when the source is set for a font.
    /// @param font The font the source has been set for.
    event SetSource(Font font);

    /// @notice Emitted when the source hash is set for a font.
    /// @param font The font the source hash has been set for.
    /// @param sourceHash The source hash that was set.
    event SetSourceHash(Font font, bytes32 sourceHash);

    /// @notice Returns the typeface name.
    function name() external view returns (string memory);

    /// @notice Return true if bytes1 char is supported by font.
    /// @param char 1-byte character to check if allowed.
    /// @return true True if allowed.
    function isSupportedByte(bytes1 char) external view returns (bool);

    /// @notice Return true if bytes2 char is supported by font.
    /// @param char 2-byte character to check if allowed.
    /// @return true True if allowed.
    function isSupportedBytes2(bytes2 char) external view returns (bool);

    /// @notice Return true if bytes3 char is supported by font.
    /// @param char 3-byte character to check if allowed.
    /// @return true True if allowed.
    function isSupportedBytes3(bytes3 char) external view returns (bool);

    /// @notice Return true if bytes4 char is supported by font.
    /// @param char 4-byte character to check if allowed.
    /// @return true True if allowed.
    function isSupportedBytes4(bytes4 char) external view returns (bool);

    /// @notice Return source data of Font.
    /// @param font Font to return source data for.
    /// @return source Source data of font.
    function sourceOf(Font memory font) external view returns (bytes memory);

    /// @notice Checks if source data has been stored for font.
    /// @param font Font to check if source data exists for.
    /// @return true True if source exists.
    function hasSource(Font memory font) external view returns (bool);

    /// @notice Stores source data for a font.
    /// @param font Font to store source data for.
    /// @param source Source data of font.
    function setSource(Font memory font, bytes memory source) external;
}