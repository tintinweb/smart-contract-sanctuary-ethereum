// SPDX-License-Identifier: GPL-3.0

/// @title Capsules Typeface

pragma solidity ^0.8.0;

import "./interfaces/ICapsulesToken.sol";
import "./Typeface.sol";

contract CapsulesTypeface is Typeface {
    /// Address of Capsules Token contract
    ICapsulesToken public immutable capsulesToken;

    constructor(
        Font[] memory fonts,
        bytes32[] memory hashes,
        address _capsulesToken
    ) Typeface("Capsules") {
        setFontSrcHash(fonts, hashes);

        capsulesToken = ICapsulesToken(_capsulesToken);
    }

    /// @notice Returns true if byte is supported by this typeface
    function isAllowedByte(bytes1 b) external pure returns (bool) {
        // TODO
        // All basic Latin letters, digits, symbols, punctuation
        return b >= 0x20 && b <= 0x7E;
    }

    /// @notice Mint reserved Capsule token to caller when caller sets fontSrc
    function afterSetFontSrc(Font memory font, bytes memory)
        internal
        override(Typeface)
    {
        // Empty text
        bytes16[8] memory text;

        capsulesToken.mintReservedForFontWeight(msg.sender, font.weight, text);
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Capsules Token

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICapsulesToken {
    event MintCapsule(
        uint256 indexed id,
        address indexed to,
        string indexed color,
        bytes16[8] text,
        uint256 fontWeight
    );
    event ClaimCapsule(
        uint256 indexed id,
        address indexed to,
        string indexed color,
        bytes16[8] text,
        uint256 fontWeight
    );
    event SetCreatorFeeReceiver(address indexed addresses);
    event SetClaimCount(address indexed receiver, uint256 indexed number);
    event SetRoyalty(uint256 indexed royalty);
    event EditCapsule(uint256 indexed id, bytes16[8] text, uint256 fontWeight);
    event Withdraw(address indexed to, uint256 indexed amount);

    function defaultImageOf(uint256 capsuleId)
        external
        view
        returns (string memory);

    function imageOf(
        bytes3 color,
        bytes16[8] memory text,
        uint256 fontWeight
    ) external view returns (string memory);

    function mint(
        bytes3 color,
        bytes16[8] calldata text,
        uint256 fontWeight
    ) external payable returns (uint256);

    function mintReservedForFontWeight(
        address to,
        uint256 fontWeight,
        bytes16[8] calldata text
    ) external returns (uint256 capsuleId);

    function claim(
        bytes3 color,
        bytes16[8] calldata text,
        uint256 fontWeight
    ) external returns (uint256 capsuleId);

    function withdraw() external;

    function editCapsule(
        uint256 capsuleId,
        bytes16[8] calldata text,
        uint256 fontWeight
    ) external;

    function burn(uint256 capsuleId) external;

    function setCreatorFeeReceiver(address _creatorFeeReceiver) external;

    function setClaimable(address[] calldata receivers, uint256 number)
        external;

    function setRoyalty(uint256 _royalty) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ITypeface.sol";

abstract contract Typeface is ITypeface {
    /// Mapping of font src by weight => style
    mapping(uint256 => mapping(string => bytes)) private _fontSrc;

    /// Mapping of keccack256 hash of font src by weight => style
    mapping(uint256 => mapping(string => bytes32)) private _fontSrcHash;

    /// Typeface name
    string private _name;

    /// @notice Return typeface name
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @notice Return font src from mapping
    function fontSrc(Font memory font)
        public
        view
        virtual
        returns (bytes memory src)
    {
        src = _fontSrc[font.weight][font.style];
    }

    /// @notice Return font src hash from mapping
    function fontSrcHash(Font memory font)
        public
        view
        virtual
        returns (bytes32 _hash)
    {
        _hash = _fontSrcHash[font.weight][font.style];
    }

    /// @notice Sets src bytes for Font.
    ///  @dev The keccack256 hash of the src must equal the fontSrcHash of the font.
    ///  @param font Font to set src for
    ///  @param src Bytes data that represents the font source data
    function setFontSrc(Font memory font, bytes memory src) public {
        require(
            _fontSrc[font.weight][font.style].length == 0,
            "Typeface: FontSrc already exists"
        );

        require(
            keccak256(src) == _fontSrcHash[font.weight][font.style],
            "Typeface: Invalid font"
        );

        beforeSetFontSrc(font, src);

        _fontSrc[font.weight][font.style] = src;

        emit SetFontSrc(font, src);

        afterSetFontSrc(font, src);
    }

    /// @notice Sets hash of src for Font.
    /// @dev Length of fonts and hashes arrays must be equal. Each hash from hashes array will be set for the font with matching index in the fonts array.
    /// @param fonts Array of fonts to set hashes for
    /// @param hashes Array of hashes to set for fonts
    function setFontSrcHash(Font[] memory fonts, bytes32[] memory hashes)
        internal
    {
        require(
            fonts.length == hashes.length,
            "Typeface: Unequal number of fonts and hashes"
        );

        for (uint256 i; i < fonts.length; i++) {
            _fontSrcHash[fonts[i].weight][fonts[i].style] = hashes[i];

            emit SetFontSrcHash(fonts[i], hashes[i]);
        }
    }

    constructor(string memory name_) {
        _name = name_;
    }

    /// @notice Function called before setFontSrc
    function beforeSetFontSrc(Font memory font, bytes memory src)
        internal
        virtual
    {}

    /// @notice Function called after setFontSrc
    function afterSetFontSrc(Font memory font, bytes memory src)
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
pragma solidity ^0.8.0;

struct Font {
    uint256 weight;
    string style;
}

interface ITypeface {
    event SetFontSrc(Font indexed font, bytes src);

    event SetFontSrcHash(Font indexed font, bytes32 _hash);

    /**
     * @notice Returns the typeface name.
     */
    function name() external view returns (string memory);

    /**
     * @notice Return true if byte is supported by font.
     */
    function isAllowedByte(bytes1 b) external view returns (bool);

    /**
     * @notice Return src bytes for Font.
     */
    function fontSrc(Font memory font) external view returns (bytes memory);

    function setFontSrc(Font memory font, bytes memory src) external;
}