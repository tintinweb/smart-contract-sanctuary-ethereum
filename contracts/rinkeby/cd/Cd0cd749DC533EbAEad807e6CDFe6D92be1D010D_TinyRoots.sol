// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

import {Owned} from "@rari-capital/solmate/src/auth/Owned.sol";
import {ERC1155} from "@rari-capital/solmate/src/tokens/ERC1155.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DynamicBuffer} from "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {XQSTGFX} from "@exquisite-graphics/contracts/contracts/XQSTGFX.sol";
import {Base64} from "./Base64.sol";

contract TinyRoots is ERC1155, Owned, XQSTGFX {
    using Strings for uint256;
    using DynamicBuffer for bytes;

    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /* DEPENDENCIES -------------------------------------------------------- */

    IERC721 public roots;

    /* SALE DATA ----------------------------------------------------------- */

    uint256 public immutable maxTokenId = 40;
    uint256 public immutable maxEditions = 50;
    uint256 public immutable editionPrice = 0.02 ether;
    mapping(uint256 => bool) public originalsClaimed;
    mapping(uint256 => uint256) public editionsPurchased;

    /* ON-CHAIN IMAGE DATA ------------------------------------------------- */

    uint256 private immutable _photoDataByteSize = 2120;
    uint256 private immutable _photoDataChunkSize = 5;
    mapping(uint256 => address) private _photoDataChunks;

    /* ------------------------------------------------------------------------
                                    E V E N T S
    ------------------------------------------------------------------------ */

    event ReservedEditionClaimed(uint256 id);

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    /* MINT ---------------------------------------------------------------- */

    error AlreadyOwnerOfEdition();
    error NotEnoughEth();
    error EditionSoldOut();
    error NotOwnerOfOriginal();
    error ReservedEditionAlreadyClaimed();

    /* ADMIN --------------------------------------------------------------- */

    error InvalidPhotoData();
    error InvalidToken();
    error PaymentFailed();

    /* BURN ---------------------------------------------------------------- */

    error NotOwner();

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    modifier onlyValidToken(uint256 id) {
        if (id == 0 || id > maxTokenId) revert InvalidToken();
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    constructor(address owner, address rootsAddress) ERC1155() Owned(owner) {
        roots = IERC721(rootsAddress);
    }

    /* ------------------------------------------------------------------------
                                P U R C H A S I N G
    ------------------------------------------------------------------------ */

    function purchaseEdition(uint256 id) external payable onlyValidToken(id) {
        if (balanceOf[msg.sender][id] > 0) revert AlreadyOwnerOfEdition();
        if (msg.value != editionPrice) revert NotEnoughEth();
        if (editionsPurchased[id] == maxEditions - 1) revert EditionSoldOut();
        _mint(msg.sender, id, 1, "");
        ++editionsPurchased[id];
    }

    function claimReservedEdition(uint256 id) external onlyValidToken(id) {
        if (roots.ownerOf(id) != msg.sender) revert NotOwnerOfOriginal();
        if (originalsClaimed[id]) revert ReservedEditionAlreadyClaimed();
        _mint(msg.sender, id, 1, "");
        originalsClaimed[id] = true;
        emit ReservedEditionClaimed(id);
    }

    function hasReservedEditionBeenClaimed(uint256 id) external view returns (bool) {
        return originalsClaimed[id];
    }

    /* ------------------------------------------------------------------------
                                    P H O T O S
    ------------------------------------------------------------------------ */

    function storePhoto(uint256 chunkId, bytes calldata data) external onlyOwner {
        if (data.length != _photoDataByteSize * _photoDataChunkSize) revert InvalidPhotoData();
        _photoDataChunks[chunkId] = SSTORE2.write(data);
    }

    function getRawPhotoData(uint256 id) external view onlyValidToken(id) returns (bytes memory) {
        return _getRawPhotoData(id);
    }

    function getPhotoSVG(uint256 id) public view onlyValidToken(id) returns (string memory) {
        bytes memory data = _getRawPhotoData(id);
        return _drawSVGToString(data);
    }

    function _getRawPhotoData(uint256 id) internal view returns (bytes memory) {
        uint256 chunkId = ((id - 1) / _photoDataChunkSize) + 1;
        uint256 chunkIndex = (id - 1) % _photoDataChunkSize;
        uint256 startBytes = chunkIndex * _photoDataByteSize;
        return SSTORE2.read(_photoDataChunks[chunkId], startBytes, startBytes + _photoDataByteSize);
    }

    function _drawSVGToString(bytes memory data) internal pure returns (string memory) {
        return string(_drawSVGToBytes(data));
    }

    function _drawSVGToBytes(bytes memory data) internal pure returns (bytes memory) {
        string memory rects = drawRectsUnsafe(data);
        bytes memory svg = DynamicBuffer.allocate(2**19);

        svg.appendSafe(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" width="100%" height="100%" version="1.1" viewBox="0 0 128 128" fill="#fff"><g transform="translate(32,32)">',
                rects,
                "</g></svg>"
            )
        );

        return svg;
    }

    /* ------------------------------------------------------------------------
                                  E R C - 1 1 5 5
    ------------------------------------------------------------------------ */

    function burn(uint256 id) external {
        if (balanceOf[msg.sender][id] == 0) revert NotOwner();
        _burn(msg.sender, id, 1);
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        onlyValidToken(id)
        returns (string memory)
    {
        bytes memory data = _getRawPhotoData(id);

        bytes memory json = DynamicBuffer.allocate(2**19);
        bytes memory jsonBase64 = DynamicBuffer.allocate(2**19);

        string memory idString = id.toString();

        json.appendSafe(
            abi.encodePacked(
                '{"name":"Tiny Roots #',
                idString,
                '","description":"A tiny edition of Roots #',
                idString,
                ". Edition of ",
                maxEditions.toString(),
                ", 64x64px in size, stored fully on-chain. Roots is a collection of photographs that explore Sam King",
                "'",
                's connection to the Scottish Highlands. Being in the Highlands gives Sam a sense of wonder that these are the lands his ancestors once traveled through. The effect is calming but also strangely primal, a subtle undertone of anxiousness. The images try to capture that feeling while showing the rugged beauty of the amazing landscape. Being both in awe and swarmed by the mountains and fog. An inviting yet hostile place.","image": "',
                bytes(Base64.encode(_drawSVGToBytes(data))),
                '","external_url":"https://tinyroots.samking.photo/photo/',
                idString,
                '","attributes":[]}'
            )
        );

        jsonBase64.appendSafe("data:application/json;base64,");
        jsonBase64.appendSafe(bytes(Base64.encode(json)));

        return string(jsonBase64);
    }

    /* ------------------------------------------------------------------------
                                     A D M I N
    ------------------------------------------------------------------------ */

    function withdrawBalance() external {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        if (!success) revert PaymentFailed();
    }

    function withdrawToken(IERC20 tokenAddress) external {
        tokenAddress.transfer(owner, tokenAddress.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import 'hardhat/console.sol';
import './interfaces/IGraphics.sol';
import './interfaces/IRenderContext.sol';
import {XQSTHelpers as helpers} from './XQSTHelpers.sol';
import {XQSTDecode as decode} from './XQSTDecode.sol';
import {XQSTValidate as v} from './XQSTValidate.sol';
import '@divergencetech/ethier/contracts/utils/DynamicBuffer.sol';

contract XQSTGFX is IGraphics, IRenderContext {
  using DynamicBuffer for bytes;

  enum DrawType {
    SVG,
    RECTS
  }

  /// @notice Draw an SVG from the provided data
  /// @param data Binary data in the .xqst format.
  /// @return string the <svg>
  function draw(bytes memory data) public pure returns (string memory) {
    return _draw(data, DrawType.SVG, true);
  }

  /// @notice Draw an SVG from the provided data. No validation
  /// @param data Binary data in the .xqst format.
  /// @return string the <svg>
  function drawUnsafe(bytes memory data) public pure returns (string memory) {
    return _draw(data, DrawType.SVG, false);
  }

  /// @notice Draw the <rect> elements of an SVG from the data
  /// @param data Binary data in the .xqst format.
  /// @return string the <rect> elements
  function drawRects(bytes memory data) public pure returns (string memory) {
    return _draw(data, DrawType.RECTS, true);
  }

  /// @notice Draw the <rect> elements of an SVG from the data. No validation
  /// @param data Binary data in the .xqst format.
  /// @return string the <rect> elements
  function drawRectsUnsafe(bytes memory data)
    public
    pure
    returns (string memory)
  {
    return _draw(data, DrawType.RECTS, false);
  }

  /// @notice validates if the given data is a valid .xqst file
  /// @param data Binary data in the .xqst format.
  /// @return bool true if the data is valid
  function valid(bytes memory data) public pure returns (bool) {
    return v._validate(data);
  }

  // basically use this to check if something is even XQST Graphics Compatible
  /// @notice validates the header for some data is a valid .xqst header
  /// @param data Binary data in the .xqst format.
  /// @return bool true if the header is valid
  function validHeader(bytes memory data) public pure returns (bool) {
    return v._validateHeader(decode._decodeHeader(data));
  }

  // TODO is this really necessary to be public?
  //      does decode, decodeHeader, decodePalette, decodeData, all belong
  //      in a xqstgfx utils library/contract?
  //      I would want to also provide the splice options there. Replace palette/Replace Data - to do the blitmap thing.
  // function decodeData(bytes memory data)
  //   public
  //   view
  //   returns (Context memory ctx)
  // {
  //   _init(ctx, data, true);
  // }

  /// @notice Decodes the header from a binary .xqst blob
  /// @param data Binary data in the .xqst format.
  /// @return Header the decoded header
  function decodeHeader(bytes memory data) public pure returns (Header memory) {
    return decode._decodeHeader(data);
  }

  /// @notice Decodes the palette from a binary .xqst blob
  /// @param data Binary data in the .xqst format.
  /// @return bytes8[] the decoded palette
  function decodePalette(bytes memory data)
    public
    pure
    returns (bytes8[] memory)
  {
    return decode._decodePalette(data, decode._decodeHeader(data));
  }

  /// Initializes the Render Context from the given data
  /// @param ctx Render Context to initialize
  /// @param data Binary data in the .xqst format.
  /// @param safe bool whether to validate the data
  function _init(
    Context memory ctx,
    bytes memory data,
    bool safe
  ) private pure {
    ctx.header = decode._decodeHeader(data);
    if (safe) {
      v._validateHeader(ctx.header);
      v._validateDataLength(ctx.header, data);
    }

    ctx.palette = decode._decodePalette(data, ctx.header);
    ctx.pixelColorLUT = decode._getPixelColorLUT(data, ctx.header);
    ctx.numberLUT = helpers._getNumberLUT(ctx.header);
  }

  /// Draws the SVG or <rect> elements from the given data
  /// @param data Binary data in the .xqst format.
  /// @param t The SVG or Rectangles to draw
  /// @param safe bool whether to validate the data
  function _draw(
    bytes memory data,
    DrawType t,
    bool safe
  ) private pure returns (string memory) {
    // uint256 startGas = gasleft();
    Context memory ctx;
    bytes memory buffer = DynamicBuffer.allocate(2**18);

    _init(ctx, data, safe);

    t == DrawType.RECTS ? _writeSVGRects(ctx, buffer) : _writeSVG(ctx, buffer);

    // console.log('Gas Used Result', startGas - gasleft());
    // console.log('Gas Left Result', gasleft());

    return string(buffer);
  }

  /// Writes the entire SVG to the given buffer
  /// @param ctx The Render Context
  /// @param buffer The buffer to write the SVG to
  function _writeSVG(Context memory ctx, bytes memory buffer) private pure {
    _writeSVGHeader(ctx, buffer);

    if (ctx.header.numColors == 0 || ctx.header.numColors > 1)
      _writeSVGRects(ctx, buffer);

    buffer.appendSafe('</svg>');
  }

  /// Writes the SVG header to the given buffer
  /// @param ctx The Render Context
  /// @param buffer The buffer to write the SVG header to
  function _writeSVGHeader(Context memory ctx, bytes memory buffer)
    internal
    pure
  {
    uint256 scale = uint256(ctx.header.scale);
    // default scale to >=512px.
    if (scale == 0) {
      scale =
        512 /
        (
          ctx.header.width > ctx.header.height
            ? ctx.header.width
            : ctx.header.height
        ) +
        1;
    }

    buffer.appendSafe(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" viewBox="0 0 ',
        helpers.toBytes(ctx.header.width),
        ' ',
        helpers.toBytes(ctx.header.height),
        '" width="',
        helpers.toBytes(ctx.header.width * scale),
        '" height="',
        helpers.toBytes(ctx.header.height * scale),
        '">'
      )
    );
  }

  /// Writes the SVG <rect> elements to the given buffer
  /// @param ctx The Render Context
  /// @param buffer The buffer to write the SVG <rect> elements to
  function _writeSVGRects(Context memory ctx, bytes memory buffer)
    internal
    pure
  {
    uint256 colorIndex;
    uint256 c;
    uint256 pixelNum;

    // create a rect that fills the entirety of the svg as the background
    if (ctx.header.hasBackground) {
      buffer.appendSafe(
        abi.encodePacked(
          '"<rect fill="#',
          ctx.palette[ctx.header.backgroundColorIndex],
          '" height="',
          ctx.numberLUT[ctx.header.height],
          '" width="',
          ctx.numberLUT[ctx.header.width],
          '"/>'
        )
      );
    }

    // Write every pixel into the buffer
    while (pixelNum < ctx.header.totalPixels) {
      colorIndex = ctx.pixelColorLUT[pixelNum];

      // Check if we need to write a new rect to the buffer at all
      if (helpers._canSkipPixel(ctx, colorIndex)) {
        pixelNum++;
        continue;
      }

      // Calculate the width of a continuous rect with the same color
      c = 1;
      while ((pixelNum + c) % ctx.header.width != 0) {
        if (colorIndex == ctx.pixelColorLUT[pixelNum + c]) {
          c++;
        } else break;
      }

      // write rect out to the buffer
      buffer.appendSafe(
        abi.encodePacked(
          '<rect fill="#',
          ctx.palette[colorIndex],
          '" x="',
          ctx.numberLUT[pixelNum % ctx.header.width],
          '" y="',
          ctx.numberLUT[pixelNum / ctx.header.width],
          '" height="1" width="',
          ctx.numberLUT[c],
          '"/>'
        )
      );

      unchecked {
        pixelNum += c;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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
pragma solidity ^0.8.0;


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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGraphics {
  struct Header {
    /* HEADER START */
    uint8 version; // 8 bits
    uint16 width; // 8 bits
    uint16 height; // 8 bits
    uint16 numColors; // 16 bits
    uint8 backgroundColorIndex; // 8 bits
    uint16 scale; // 10 bits
    uint8 reserved; // 4 bits
    bool alpha; // 1 bit
    bool hasBackground; // 1 bit
    /* HEADER END */

    /* CALCULATED DATA START */
    uint16 totalPixels; // total pixels in the image
    uint8 bpp; // bits per pixel
    uint8 ppb; // pixels per byte
    uint16 paletteStart; // number of the byte where the palette starts
    uint16 dataStart; // number of the byte where the data starts
    /* CALCULATED DATA END */
  }

  error ExceededMaxPixels(); // TODO: change to: MaxPixelsOutOfRange? Or generic OutOfRange?
  error ExceededMaxRows();
  error ExceededMaxColumns();
  error ExceededMaxColors();
  error BackgroundColorIndexOutOfRange();
  error PixelColorIndexOutOfRange();
  error MissingHeader();
  error NotEnoughData();

  /// @notice Draw an SVG from the provided data
  /// @param data Binary data in the .xqst format.
  /// @return string the <svg>
  function draw(bytes memory data) external pure returns (string memory);

  /// @notice Draw an SVG from the provided data. No validation
  /// @param data Binary data in the .xqst format.
  /// @return string the <svg>
  function drawUnsafe(bytes memory data) external pure returns (string memory);

  /// @notice Draw the <rect> elements of an SVG from the data
  /// @param data Binary data in the .xqst format.
  /// @return string the <rect> elements
  function drawRects(bytes memory data) external pure returns (string memory);

  /// @notice Draw the <rect> elements of an SVG from the data. No validation
  /// @param data Binary data in the .xqst format.
  /// @return string the <rect> elements
  function drawRectsUnsafe(bytes memory data)
    external
    pure
    returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './IGraphics.sol';

interface IRenderContext {
  struct Context {
    bytes data; // the binary data in .xqst format
    IGraphics.Header header; // the header of the data
    bytes8[] palette; // hex color for each color in the image
    uint8[] pixelColorLUT; // lookup the color index for a pixel
    bytes[] numberLUT; // lookup the string representation of a number
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interfaces/IGraphics.sol';
import './interfaces/IRenderContext.sol';

library XQSTHelpers {
  /// Gets a table of numbers
  /// @dev index 0 is the string '0' and index 255 is the string '255'
  /// @param header used to figure out how many numbers we need to store
  /// @return lookup the table of numbers
  function _getNumberLUT(IGraphics.Header memory header)
    internal
    pure
    returns (bytes[] memory lookup)
  {
    uint256 max;

    max = (header.width > header.height ? header.width : header.height) + 1;
    max = header.numColors > max ? header.numColors : max;

    lookup = new bytes[](max);
    for (uint256 i = 0; i < max; i++) {
      lookup[i] = toBytes(i);
    }
  }

  /// Determines if we can skip rendering a pixel
  /// @dev Can skip rendering a pixel under 3 Conditions
  /// @dev 1. The pixel's color is the same as the background color
  /// @dev 2. We are rendering in 0-color mode, and the pixel is a 0
  /// @dev 3. The pixel's color doesn't exist in the palette
  /// @param ctx the render context
  /// @param colorIndex the index of the color for this pixel
  function _canSkipPixel(IRenderContext.Context memory ctx, uint256 colorIndex)
    internal
    pure
    returns (bool)
  {
    //      (note: maybe this is better as an error? not sure.
    //       it's a nice way of adding transparency to the image)
    return ((ctx.header.hasBackground &&
      colorIndex == ctx.header.backgroundColorIndex) ||
      (ctx.header.numColors == 0 && colorIndex == 0) ||
      colorIndex >= ctx.header.numColors);
  }

  /// Returns the bytes representation of a number
  /// @param value the number to convert to bytes
  /// @return bytes representation of the number
  function toBytes(uint256 value) internal pure returns (bytes memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
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
    return buffer;
  }

  /// Gets the ascii hex character for a byte
  /// @param char the byte to get the ascii hex character for
  /// @return uint8 ascii hex character for the byte
  function _getHexChar(bytes1 char) internal pure returns (uint8) {
    return
      (uint8(char) > 9)
        ? (uint8(char) + 87) // ascii a-f
        : (uint8(char) + 48); // ascii 0-9
  }

  /// Converts 3 bytes to a RGBA hex string
  /// @param b the bytes to convert to a color
  /// @return bytes8 the color in RBGA hex format
  function _toColor(bytes3 b) internal pure returns (bytes8) {
    uint64 b6 = 0x0000000000006666;
    for (uint256 i = 0; i < 3; i++) {
      b6 |= (uint64(_getHexChar(b[i] & 0x0F)) << uint64((6 - (i * 2)) * 8));
      b6 |= (uint64(_getHexChar(b[i] >> 4)) << uint64((6 - (i * 2) + 1) * 8));
    }

    return bytes8(b6);
  }

  /// Converts 4 bytes to a RGBA hex string
  /// @param b the bytes to convert to a color
  /// @return bytes8 the color in RBGA hex format
  function _toHexBytes8(bytes4 b) internal pure returns (bytes8) {
    uint64 b8;

    for (uint256 i = 0; i < 4; i++) {
      b8 = b8 | (uint64(_getHexChar(b[i] & 0x0F)) << uint64((6 - (i * 2)) * 8));
      b8 =
        b8 |
        (uint64(_getHexChar(b[i] >> 4)) << uint64((6 - (i * 2) + 1) * 8));
    }

    return bytes8(b8);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import 'hardhat/console.sol';
import './interfaces/IGraphics.sol';
import {XQSTHelpers as helpers} from './XQSTHelpers.sol';

library XQSTDecode {
  // TODO it would be good to add a ASCII representation of the header format here.
  /// Decode the header from raw binary data into a Header struct
  /// @param data Binary data in the .xqst format.
  /// @return header the header decoded from the data
  function _decodeHeader(bytes memory data)
    internal
    pure
    returns (IGraphics.Header memory header)
  {
    if (data.length < 8) revert IGraphics.MissingHeader();

    // Fetch the 8 Bytes representing the header from the data
    uint64 h;
    assembly {
      h := mload(add(data, 8))
    }

    header.version = uint8(h >> 56);
    header.width = uint16((h >> 48) & 0xFF);
    header.height = uint16((h >> 40) & 0xFF);
    header.numColors = uint16(h >> 24);
    header.backgroundColorIndex = uint8(h >> 16);
    header.scale = uint16((h >> 6) & 0x3F);
    header.reserved = uint8((h >> 2) & 0x0F);
    header.alpha = ((h >> 1) & 0x1) == 1 ? true : false;
    header.hasBackground = (h & 0x1) == 1 ? true : false;

    header.totalPixels = header.width * header.height;
    header.paletteStart = 8;
    header.dataStart = header.alpha
      ? (header.numColors * 4) + 8
      : (header.numColors * 3) + 8;

    _setColorDepthParams(header);
  }

  /// Decode the palette from raw binary data into a palette array
  /// @dev Each element of the palette array is a hex color with alpha channel
  /// @param data Binary data in the .xqst format.
  /// @return palette the palette from the data
  function _decodePalette(bytes memory data, IGraphics.Header memory header)
    internal
    pure
    returns (bytes8[] memory palette)
  {
    if (header.numColors > 0) {
      if (data.length < header.dataStart) revert IGraphics.NotEnoughData();

      // the first 32 bytes of `data` represents `data.length` using assembly.
      // we offset 32 bytes to get to the actual data
      uint256 offset = 32 + header.paletteStart;

      if (header.alpha) {
        // read 4 bytes at a time if alpha
        bytes4 d;
        palette = new bytes8[](header.numColors);
        for (uint256 i = 0; i < header.numColors; i++) {
          // load 4 bytes of data at the offset into d
          assembly {
            d := mload(add(data, offset))
          }

          palette[i] = helpers._toHexBytes8(d); // TODO might be good to give this consistent naming as below.
          unchecked {
            offset += 4;
          }
        }
      } else {
        // read 3 bytes at a time if no alpha
        bytes3 d;
        palette = new bytes8[](header.numColors);
        for (uint256 i = 0; i < header.numColors; i++) {
          // load 3 bytes of data at the offset into d
          assembly {
            d := mload(add(data, offset))
          }

          palette[i] = helpers._toColor(d);
          unchecked {
            offset += 3;
          }
        }
      }
    } else {
      palette = new bytes8[](2);
      palette[1] = bytes8('');
    }
  }

  /// Get a table of the color values (index) for each pixel in the image
  /// @param data Binary data in the .xqst format.
  /// @param header the header of the image
  /// @return table table of color index for each pixel
  function _getPixelColorLUT(bytes memory data, IGraphics.Header memory header)
    internal
    pure
    returns (uint8[] memory table)
  {
    // TODO it might be worth testing if we can get the bytes8[] for each pixel directly.
    // ^ first attempt at this didnt look great, mostly bytes8 is a pain to work with
    // uint256 startGas = gasleft();
    uint8 workingByte;
    table = new uint8[](header.totalPixels + 8); // add extra byte for safety
    if (header.bpp == 1) {
      for (uint256 i = 0; i < header.totalPixels; i += 8) {
        workingByte = uint8(data[i / 8 + header.dataStart]);
        table[i] = workingByte >> 7;
        table[i + 1] = (workingByte >> 6) & 0x01;
        table[i + 2] = (workingByte >> 5) & 0x01;
        table[i + 3] = (workingByte >> 4) & 0x01;
        table[i + 4] = (workingByte >> 3) & 0x01;
        table[i + 5] = (workingByte >> 2) & 0x01;
        table[i + 6] = (workingByte >> 1) & 0x01;
        table[i + 7] = workingByte & 0x01;
      }
    } else if (header.bpp == 2) {
      for (uint256 i = 0; i < header.totalPixels; i += 4) {
        workingByte = uint8(data[i / 4 + header.dataStart]);
        table[i] = workingByte >> 6;
        table[i + 1] = (workingByte >> 4) & 0x03;
        table[i + 2] = (workingByte >> 2) & 0x03;
        table[i + 3] = workingByte & 0x03;
      }
    } else if (header.bpp == 4) {
      for (uint256 i = 0; i < header.totalPixels; i += 2) {
        workingByte = uint8(data[i / 2 + header.dataStart]);
        table[i] = workingByte >> 4;
        table[i + 1] = workingByte & 0x0F;
      }
    } else {
      for (uint256 i = 0; i < header.totalPixels; i++) {
        table[i] = uint8(data[i + header.dataStart]);
      }
    }

    // console.log('color lut builing gas used', startGas - gasleft());
  }

  /// Set the color depth of the image in the header provided
  /// @param header the header of the image
  function _setColorDepthParams(IGraphics.Header memory header) internal pure {
    if (header.numColors > 16) {
      // 8 bit Color Depth: images with 16 < numColors <= 256
      header.bpp = 8;
      header.ppb = 1;
    } else if (header.numColors > 4) {
      // 4 bit Color Depth: images with 4 < numColors <= 16
      header.bpp = 4;
      header.ppb = 2;
    } else if (header.numColors > 2) {
      // 2 bit Color Depth: images with 2 < numColors <= 4
      header.bpp = 2;
      header.ppb = 4;
    } else {
      // 1 bit Color Depth: images with 0 <= numColors <= 2
      header.bpp = 1;
      header.ppb = 8;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interfaces/IGraphics.sol';
import './interfaces/IRenderContext.sol';
import {XQSTHelpers as helpers} from './XQSTHelpers.sol';
import {XQSTDecode as decode} from './XQSTDecode.sol';

library XQSTValidate {
  uint16 public constant MAX_COLORS = 256;
  uint16 public constant MAX_PIXELS = 10000; // TODO
  uint8 public constant MAX_ROWS = 255; // TODO
  uint8 public constant MAX_COLS = 255; // TODO

  /// @notice validates if the given data is a valid .xqst file
  /// @param data Binary data in the .xqst format.
  /// @return bool true if the data is valid
  function _validate(bytes memory data) internal pure returns (bool) {
    IRenderContext.Context memory ctx;

    ctx.header = decode._decodeHeader(data);
    _validateHeader(ctx.header);
    _validateDataLength(ctx.header, data);
    ctx.palette = decode._decodePalette(data, ctx.header);

    return true;
  }

  /// @notice checks if the given data contains a valid .xqst header
  /// @param header the header of the data
  /// @return bool true if the header is valid
  function _validateHeader(IGraphics.Header memory header)
    internal
    pure
    returns (bool)
  {
    if (header.width * header.height > MAX_PIXELS)
      revert IGraphics.ExceededMaxPixels();
    if (header.height > MAX_ROWS) revert IGraphics.ExceededMaxRows();
    if (header.width > MAX_COLS) revert IGraphics.ExceededMaxColumns();
    if (header.numColors > MAX_COLORS) revert IGraphics.ExceededMaxColors();

    if (
      header.hasBackground && header.backgroundColorIndex >= header.numColors
    ) {
      revert IGraphics.BackgroundColorIndexOutOfRange();
    }

    return true;
  }

  /// @notice checks if the given data is long enough to render an .xqst image
  /// @param header the header of the data
  /// @param data the data to validate
  /// @return bool true if the data is long enough
  function _validateDataLength(
    IGraphics.Header memory header,
    bytes memory data
  ) internal pure returns (bool) {
    // if 0 - palette has no data. data is binary data of length of the number of pixels
    // if 1 color - palette
    // if > 1 color

    // if (header.numColors > 1 || !header.hasBackground) {
    uint256 pixelDataLen = (header.totalPixels % 2 == 0) || header.ppb == 1
      ? (header.totalPixels / header.ppb)
      : (header.totalPixels / header.ppb) + 1;

    if (data.length < header.dataStart + pixelDataLen)
      revert IGraphics.NotEnoughData();
    // }
    return true;
  }

  // TODO: remove this and below function? not used if we allow blank (non rendered) pixels
  // function _validateDataContents(
  //   bytes memory data,
  //   IGraphics.Header memory header
  // ) internal view returns (bool) {
  //   uint8[] memory pixelColorLUT = decode._getPixelColorLUT(data, header);
  //   for (uint256 i = 0; i < header.totalPixels; i++) {
  //     if (pixelColorLUT[i] >= header.numColors)
  //       revert IGraphics.PixelColorIndexOutOfRange();
  //   }

  //   return true;
  // }

  // function _validateDataContents(IRenderContext.Context memory ctx)
  //   internal
  //   pure
  //   returns (bool)
  // {
  //   for (uint256 i = 0; i < ctx.header.totalPixels; i++) {
  //     if (ctx.pixelColorLUT[i] >= ctx.header.numColors)
  //       revert IGraphics.PixelColorIndexOutOfRange();
  //   }

  //   return true;
  // }
}