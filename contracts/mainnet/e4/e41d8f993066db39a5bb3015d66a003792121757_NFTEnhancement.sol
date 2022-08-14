// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import {INFTEnhancement} from "src/interfaces/INFTEnhancement.sol";
import {IERC721Metadata} from "src/interfaces/IERC721.sol";
import {IERC1155MetadataURI} from "src/interfaces/IERC1155MetadataURI.sol";
import {IRenderer} from "src/interfaces/IRenderer.sol";
import {ERC721} from "./ERC721.sol";
import "./Base64.sol";

contract NFTEnhancement is INFTEnhancement, ERC721 {
    /*//////////////////////////////////////////////////////////////
                            STORAGE & ERRORS
    //////////////////////////////////////////////////////////////*/
    address public owner;
    /// tokenId => token name
    mapping(uint256 => string) internal names;

    /// tokenId => underlying token contract
    mapping(uint256 => address) internal _underlyingTokenContract;
    /// tokenId => underlying token id
    mapping(uint256 => uint256) internal _underlyingTokenId;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        address underlyingTokenContract = _underlyingTokenContract[tokenId];
        uint256 underlyingTokenId = _underlyingTokenId[tokenId];
        return _getMetadata(tokenId, underlyingTokenContract, underlyingTokenId);
    }

    /*//////////////////////////////////////////////////////////////
                              NFTENHANCEMENT LOGIC
    //////////////////////////////////////////////////////////////*/
    function setUnderlyingToken(
        uint256 tokenId,
        address underlyingContract,
        uint256 underlyingTokenId
    )
        external
        override
    {
        _requireAuthorized(tokenId);
        _underlyingTokenId[tokenId] = underlyingTokenId;
        _underlyingTokenContract[tokenId] = underlyingContract;
    }

    function getUnderlyingToken(uint256 tokenId)
        external
        view
        returns (address underlyingContract, uint256 underlyingTokenId)
    {
        underlyingContract = _underlyingTokenContract[tokenId];
        underlyingTokenId = _underlyingTokenId[tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                              OTHER PUBLIC LOGIC
    //////////////////////////////////////////////////////////////*/
    function mint(
        address to,
        address renderer,
        uint96 counter,
        string calldata name
    )
        external
    {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        uint256 id = composeTokenId(renderer, counter);
        names[id] = name;
        // checks if tokenId has already been minted by checking if ownerOf[id] != 0. works because we cannot burn & transfer reverts to 0
        _mint(to, id);
    }

    function previewTokenURI(
        uint256 tokenId,
        address underlyingTokenContract,
        uint256 underlyingTokenId
    )
        external
        view
        returns (string memory)
    {
        return _getMetadata(tokenId, underlyingTokenContract, underlyingTokenId);
    }

    function composeTokenId(address renderer, uint96 counter)
        public
        pure
        returns (uint256 tokenId)
    {
        tokenId = (uint256(counter) << 160) | uint256(uint160(renderer));
    }

    function decomposeTokenId(uint256 tokenId)
        public
        pure
        returns (address renderer, uint96 counter)
    {
        renderer = address(uint160(tokenId & type(uint160).max));
        counter = uint96(tokenId >> 160);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _getMetadata(
        uint256 id,
        address underlyingTokenContract,
        uint256 underlyingTokenId
    )
        internal
        view
        returns (string memory)
    {
        string memory name = names[id];
        string memory underlyingTokenContractName;
        string memory underlyingTokenContractSymbol;

        // possible XSS but it would just break the token uri
        try IERC721Metadata(underlyingTokenContract).name() returns (
            string memory contractName
        ) {
            underlyingTokenContractName = contractName;
        } catch {}
        try IERC721Metadata(underlyingTokenContract).symbol() returns (
            string memory contractSymbol
        ) {
            underlyingTokenContractSymbol = contractSymbol;
        } catch {}
        string memory description = string(
            abi.encodePacked(
                "Applied to ",
                bytes(underlyingTokenContractSymbol).length > 0
                    ? underlyingTokenContractSymbol
                    :
                        bytes(underlyingTokenContractName).length > 0
                        ? underlyingTokenContractName
                        : "NA",
                "#",
                Strings.toString(underlyingTokenId),
                " (",
                Strings.toHexString(underlyingTokenContract),
                ")"
            )
        );

        string memory html;
        (address renderer,) = decomposeTokenId(id);
        bool ownsUnderlying = false;

        try IERC721Metadata(underlyingTokenContract).ownerOf(underlyingTokenId)
        returns (address underlyingOwner) {
            ownsUnderlying = underlyingOwner == _ownerOf[id];
        } catch {}

        try IERC721Metadata(underlyingTokenContract).tokenURI(underlyingTokenId)
        returns (string memory underlyingTokenURI) {
            html = IRenderer(renderer).render(
                id,
                underlyingTokenContract,
                underlyingTokenId,
                underlyingTokenURI,
                ownsUnderlying
            );
        } catch {
            // try it as an ERC1155
            try IERC1155MetadataURI(underlyingTokenContract).uri(underlyingTokenId)
            returns (string memory underlyingTokenURI) {
                html = IRenderer(renderer).render(
                    id,
                    underlyingTokenContract,
                    underlyingTokenId,
                    underlyingTokenURI,
                    ownsUnderlying
                );
            } catch {}
        }

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        name,
                        '","description":"',
                        description,
                        '","animation_url":"data:text/html;base64,',
                        Base64.encode(bytes(html)),
                        '","attributes":[]}'
                    )
                )
            )
        );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {IERC721Metadata} from "./IERC721.sol";

// these functions would be part of a spec
interface IERCNFTEnhancement is IERC721Metadata {
    function setUnderlyingToken(
        uint256 tokenId,
        address underlyingContract,
        uint256 underlyingTokenId
    )
        external;
    function getUnderlyingToken(uint256 tokenId)
        external
        view
        returns (address underlyingContract, uint256 underlyingTokenId);
}

// this includes custom functions that would not be part of the spec but our NFTEnhancement instance exposes
interface INFTEnhancement is IERCNFTEnhancement {
    /// returns the tokenURI of tokenId as if the underlying was set to the parameters
    function previewTokenURI(
        uint256 tokenId,
        address underlyingTokenContract,
        uint256 underlyingTokenId
    )
        external
        view
        returns (string memory tokenURI);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

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
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner, address indexed operator, bool approved
    );

    // /**
    //  * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    //  */
    // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // /**
    //  * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    //  */
    // event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // /**
    //  * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    //  */
    // event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    )
        external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId)
        external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC1155MetadataURI {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IRenderer {
    function render(
        uint256 tokenId,
        address underlyingTokenContract,
        uint256 underlyingTokenId,
        string calldata underlyingTokenURI,
        bool ownsUnderlying
    )
        external
        pure
        returns (string memory html);
}

// from solmate but changed to implement the actual IERC721.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC721Metadata} from "src/interfaces/IERC721.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is IERC721Metadata {
    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC & ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();

    string public name;
    string public symbol;

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id)
        external
        view
        virtual
        returns (address owner)
    {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external virtual {
        address owner = _ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved)
        external
        virtual
    {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id)
        external
        virtual
    {
        _transferFrom(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
        external
        virtual
    {
        _transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    )
        external
        virtual
    {
        _transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        return interfaceId == 0x01ffc9a7
            || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd
            || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transferFrom(address from, address to, uint256 id) private {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        _requireAuthorized(id);
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(address to, uint256 id, bytes memory data)
        internal
        virtual
    {
        _mint(to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _requireAuthorized(uint256 tokenId) internal virtual {
        address owner = _ownerOf[tokenId];
        if (
            !(
                msg.sender == owner || isApprovedForAll[owner][msg.sender]
                    || msg.sender == getApproved[tokenId]
            )
        ) {
            revert Unauthorized();
        }
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz012345678" "9+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) {
            return "";
        }
        string memory table = TABLE;
        uint256 encodedLength = ((data.length + 2) / 3) << 2;
        string memory result = new string(encodedLength + 0x20);

        assembly {
            mstore(result, encodedLength)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 0x20)
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(
                    resultPtr,
                    shl(0xF8, mload(add(tablePtr, and(shr(0x12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(0xF8, mload(add(tablePtr, and(shr(0xC, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(0xF8, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr, shl(0xF8, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(0xF0, 0x3D3D)) }
            case 2 { mstore(sub(resultPtr, 1), shl(0xF8, 0x3D)) }
        }

        return result;
    }
}