// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using Address for address;
    using Strings for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.16 <0.9.0;

import {DynamicBuffer} from "./DynamicBuffer.sol";
import {RawData} from "./RawData.sol";

/**
 * @notice Packs raw pixel data into the BMP format.
 * @dev The library assumes row-major, 24-bit BGR pixel encoding.
 */
library BMP {
    using DynamicBuffer for bytes;
    using RawData for bytes;

    error InvalidDimensions(uint256 expected, uint256 actual);
    error InvalidWidth();

    uint8 internal constant _BMP_HEADER_SIZE = 54;

    /**
     * @notice Returns an 24-bit BMP encoding of the pixels.
     * @param pixels BGR tuples
     * @param width Number of horizontal pixels in the image
     * @param height Number of vertical pixels in the image
     */
    function bmp(
        bytes memory pixels,
        uint32 width,
        uint32 height
    ) internal pure returns (bytes memory) {
        (, uint256 paddedLength) = computePadding(width, height);
        bytes memory buf = DynamicBuffer.allocate(
            _BMP_HEADER_SIZE + paddedLength
        );
        appendBMP(buf, pixels, width, height);
        return buf;
    }

    /**
     * @notice Appends the 24-bit BMP encoding of the pixels to a given buffer.
     * @param pixels BGR tuples
     * @param width Number of horizontal pixels in the image
     * @param height Number of vertical pixels in the image
     */
    function appendBMP(
        bytes memory buf,
        bytes memory pixels,
        uint32 width,
        uint32 height
    ) internal pure returns (bytes memory) {
        if (width * height * 3 != pixels.length) {
            revert InvalidDimensions(width * height * 3, pixels.length);
        }

        buf.appendSafe(header(width, height));
        appendPixelsSafe(buf, pixels, width, height);

        return buf;
    }

    /**
     * @notice Returns the header for a 24-bit BMP encoded images
     * @param width Number of horizontal pixels in the image
     * @param height Number of vertical pixels in the image
     * @dev Spec: https://www.digicamsoft.com/bmp/bmp.html
     *
     * Layout description with offsets:
     * http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/2003_w/misc/bmp_file_format/bmp_file_format.htm
     *
     * N.B. Everything is little-endian, hence the assembly for masking and
     * shifting.
     */
    function header(uint32 width, uint32 height)
        internal
        pure
        returns (bytes memory)
    {
        // Each row of the pixel array must be padded to a multiple of 4 bytes.
        (, uint256 paddedLength) = computePadding(width, height);

        // 14 bytes for BITMAPFILEHEADER + 40 for BITMAPINFOHEADER
        bytes memory buf = new bytes(_BMP_HEADER_SIZE);

        // BITMAPFILEHEADER
        buf[0x00] = 0x42;
        buf[0x01] = 0x4d; // bfType = BM

        // bfSize; bytes in the entire buffer
        uint32 bfSize = _BMP_HEADER_SIZE + uint32(paddedLength);
        buf.writeUint32LE(0x02, bfSize);

        // Next 4 bytes are bfReserved1 & 2; both = 0 = initial value

        // bfOffBits; bytes from beginning of file to pixels = 14 + 40
        // (see size above)
        buf.writeUint32LE(0x0a, _BMP_HEADER_SIZE);

        // BITMAPINFOHEADER
        // biSize; bytes in this struct = 40
        buf.writeUint32LE(0x0e, 40);

        // biWidth / biHeight
        buf.writeUint32LE(0x12, width);
        buf.writeUint32LE(0x16, height);

        // biPlanes (must be 1)
        buf.writeUint16LE(0x1a, 0x01);

        // biBitCount: 24 bits per pixel (full BGR)
        buf.writeUint16LE(0x1c, 0x18);

        // biXPelsPerMeter
        buf.writeUint32LE(0x26, 0x01);

        // biYPelsPerMeter
        buf.writeUint32LE(0x2a, 0x01);

        // We use raw pixels instead of run-length encoding for compression
        // as these aren't being stored. It's therefore simpler to
        // avoid the extra computation. Therefore biSize can be 0. Similarly
        // there's no point checking exactly which colours are used, so
        // biClrUsed and biClrImportant can be 0 to indicate all colours. This
        // is therefore the end of BITMAPINFOHEADER. Simples.

        // Further we use full 24 bit BGR color values instead of an indexed
        // palette. RGBQUAD is hence left empty.

        // return abi.encodePacked(buf, pixels);
        return buf;
    }

    /**
     * @notice Appends the pixels with BMP-conform padding to a given buffer.
     * @dev This can be used together with `header` to build a full BMP.
     * @param pixels BGR tuples
     * @param width Number of horizontal pixels in the image
     * @param height Number of vertical pixels in the image
     */
    function appendPixelsSafe(
        bytes memory buffer,
        bytes memory pixels,
        uint32 width,
        uint32 height
    ) internal pure {
        (, uint256 paddedLength) = computePadding(width, height);
        buffer.checkOverflow(paddedLength);

        appendPixelsUnchecked(buffer, pixels, width, height);
    }

    /**
     * @notice Appends the pixels with BMP-conform padding to a given buffer.
     * @dev This can be used together with `header` to build a full BMP.
     * @dev Does not check for out-of-bound writes.
     * @param pixels BGR tuples
     * @param width Number of horizontal pixels in the image
     * @param height Number of vertical pixels in the image
     */
    function appendPixelsUnchecked(
        bytes memory buf,
        bytes memory pixels,
        uint32 width,
        uint32 height
    ) internal pure {
        // pixel data layout
        //
        // | word | word | .. | tail |
        // | word | word | .. | tail |
        // | word | word | .. | tail |
        //
        // buf data layout:
        //
        // | word | word | ..  | tail | padding |
        // | word | word | ..  | tail | padding |
        // | word | word | ..  | tail | padding |
        //

        // Number of full words in a scan line
        uint256 rowWords = (width * 3) / 32;

        // Number of bytes remaining in a line
        uint256 rowTailBytes = (width * 3) % 32;

        // If a scan row can be divided into words without rest, move a full
        // word to the tail to simplify looping.
        if (rowTailBytes == 0) {
            rowWords -= 1;
            rowTailBytes = 32;
        }

        (uint256 padding, ) = computePadding(width, height);

        // If we load a full word at the tail, we can only use the first
        // `rowTailBytes` bytes. The rest needs to be masked
        uint256 tailMaskInv = ((1 << ((32 - rowTailBytes) * 8)) - 1);
        uint256 tailMask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff -
                tailMaskInv;

        assembly {
            let bufPtr := add(add(buf, 0x20), mload(buf))

            // Loop over all rows
            for {
                let y := 0
                let pixelPtr := add(pixels, 0x20)
            } lt(y, height) {
                y := add(y, 1)
            } {
                // Loop over the words in a row
                for {
                    let iWord := 0
                } lt(iWord, rowWords) {
                    iWord := add(iWord, 1)
                    pixelPtr := add(pixelPtr, 0x20)
                    bufPtr := add(bufPtr, 0x20)
                } {
                    mstore(bufPtr, mload(pixelPtr))
                }

                // Tail
                mstore(
                    bufPtr,
                    or(
                        and(mload(pixelPtr), tailMask),
                        // We need to account for the fact that we potentially
                        // write outside the buffer range here. We therefore
                        // load the current data in the remaining bits
                        // and set them again as they are.
                        and(mload(bufPtr), tailMaskInv)
                    )
                )

                pixelPtr := add(pixelPtr, rowTailBytes)
                bufPtr := add(bufPtr, add(rowTailBytes, padding))
            }

            // Update buffer length
            mstore(buf, sub(bufPtr, add(buf, 0x20)))
        }
    }

    /**
     * @notice Computes the BMP-conform padding of a pixel frame.
     * @param width Number of horizontal pixels in the image
     * @param height Number of vertical pixels in the image
     * @return padding Number of bytes added to each row
     * @return paddedLength Length of the padded data
     */
    function computePadding(uint256 width, uint256 height)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 stride = width * 3;
        uint256 padding = (4 - (stride - (((stride) >> 2) << 2))) % 4;
        uint256 paddedLength = height * (stride + padding);
        return (padding, paddedLength);
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
    /// @param capacity_ The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity_ + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity_)
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
                let size := add(capacity_, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity_, 0x40)
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
        checkOverflow(buffer, data.length);
        appendUnchecked(buffer, data);
    }

    /// @notice Appends data encoded as Base64 to buffer.
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// Author: Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
    /// Author: Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
    /// Author: Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos.
    function appendSafeBase64(
        bytes memory buffer,
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure {
        uint256 dataLength = data.length;

        if (data.length == 0) {
            return;
        }

        uint256 encodedLength;
        uint256 r;
        assembly {
            // For each 3 bytes block, we will have 4 bytes in the base64
            // encoding: `encodedLength = 4 * divCeil(dataLength, 3)`.
            // The `shl(2, ...)` is equivalent to multiplying by 4.
            encodedLength := shl(2, div(add(dataLength, 2), 3))

            r := mod(dataLength, 3)
            if noPadding {
                // if r == 0 => no modification
                // if r == 1 => encodedLength -= 2
                // if r == 2 => encodedLength -= 1
                encodedLength := sub(
                    encodedLength,
                    add(iszero(iszero(r)), eq(r, 1))
                )
            }
        }

        checkOverflow(buffer, encodedLength);

        assembly {
            let nextFree := mload(0x40)

            // Store the table into the scratch space.
            // Offsetted by -1 byte so that the `mload` will load the character.
            // We will rewrite the free memory pointer at `0x40` later with
            // the allocated size.
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(
                0x3f,
                sub(
                    "ghijklmnopqrstuvwxyz0123456789-_",
                    // The magic constant 0x0230 will translate "-_" + "+/".
                    mul(iszero(fileSafe), 0x0230)
                )
            )

            // Skip the first slot, which stores the length.
            let ptr := add(add(buffer, 0x20), mload(buffer))
            let end := add(data, dataLength)

            // Run over the input, 3 bytes at a time.
            // prettier-ignore
            // solhint-disable-next-line no-empty-blocks
            for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

            if iszero(noPadding) {
                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
            }

            mstore(buffer, add(mload(buffer), encodedLength))
            mstore(0x40, nextFree)
        }
    }

    /// @notice Returns the capacity of a given buffer.
    function capacity(bytes memory buffer) internal pure returns (uint256) {
        uint256 cap;
        assembly {
            cap := sub(mload(sub(buffer, 0x20)), 0x40)
        }
        return cap;
    }

    /// @notice Reverts if the buffer will overflow after appending a given
    /// number of bytes.
    function checkOverflow(bytes memory buffer, uint256 addedLength)
        internal
        pure
    {
        uint256 cap = capacity(buffer);
        uint256 newLength = buffer.length + addedLength;
        if (cap < newLength) {
            revert("DynamicBuffer: Appending out of bounds.");
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.16 <0.9.0;

import {DynamicBuffer} from "./DynamicBuffer.sol";

/**
 * @notice The rectangle defining a pixel frame in relation to a global
 * index coordinate system.
 */
struct Rectangle {
    uint8 xMin;
    uint8 yMin;
    uint8 xMax;
    uint8 yMax;
}

/**
 * @notice Utilities library to work with raw pixel data.
 * @dev The code assumes (32)24-bit (A)BGR pixel encoding.
 * @dev Frames without any explicit rectangle information are assumed to start
 * at the coordinate origin `xMin = yMin = 0`.
 */
//solhint-disable no-empty-blocks
library Image {
    using DynamicBuffer for bytes;

    /**
     * @notice Fills a pixel buffer with a given RGB color.
     */
    function fill(bytes memory bgrPixels, uint24 rgb) internal pure {
        assembly {
            let bgr := shl(
                // Pushing the BGR tripplet all the way to the left 256 - 24
                232,
                or(
                    and(0x00FF00, rgb),
                    or(shl(16, and(0xFF, rgb)), and(0xFF, shr(16, rgb)))
                )
            )

            bgr := or(bgr, shr(24, bgr))
            {
                let bgr2 := bgr
                bgr := or(bgr, shr(48, bgr))
                bgr := or(bgr, shr(96, bgr))
                bgr := or(bgr, shr(192, bgr2))
            }

            let bufPtr := add(bgrPixels, 0x20)
            let bufPtrEnd := add(bufPtr, mload(bgrPixels))
            for {

            } 1 {

            } {
                // Stopping if we reached the end of the block.
                if iszero(lt(add(bufPtr, 32), bufPtrEnd)) {
                    break
                }

                mstore(bufPtr, bgr)
                bufPtr := add(bufPtr, 30)
            }

            let mask := shr(
                shl(3, sub(bufPtrEnd, bufPtr)),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )

            mstore(bufPtr, or(and(bgr, not(mask)), and(mload(bufPtr), mask)))
        }
    }

    /**
     * @notice Mask the location of the vectorised BGR channels.
     */
    uint256 private constant _VECTORISATION_MASK =
        0xFF0000000000000000FF0000000000000000FF;

    /**
     * @notice Blends two pixels depending on the alpha channel of the latter.
     * @dev An accuracy-focused algorithm that removes bias across color
     * channels. See also https://stackoverflow.com/a/1230272
     * @param bgr BGR encoded pixel.
     * @param abgr ABGR encoded pixel with alpha channel.
     */
    function alphaBlend(uint24 bgr, uint32 abgr)
        internal
        pure
        returns (uint24 res)
    {
        assembly {
            let a := shr(24, abgr)
            let na := sub(0xff, a)

            // Spacing the color channel values across the 256 bit word.
            // | 0 (13B) | R (1B) | 0 (8B) | G (1B) | 0 (8B) | R (1B) |
            // This allows all channels to be blended in a single operation.
            bgr := and(
                or(or(shl(128, bgr), shl(64, bgr)), bgr),
                _VECTORISATION_MASK
            )

            abgr := and(
                or(or(shl(128, abgr), shl(64, abgr)), abgr),
                _VECTORISATION_MASK
            )

            // h = alpha * fg + (255 - alpha) * bg + 128
            let h := add(
                add(mul(a, abgr), mul(na, bgr)),
                // Adds 0x80 to each value
                0x80000000000000000080000000000000000080
            )

            // h = ((h >> 8) + h) >> 8
            h := and(
                shr(8, add(shr(8, h), h)),
                // Bit cleaning
                _VECTORISATION_MASK
            )

            res := or(or(shr(128, h), shr(64, h)), h)
        }
    }

    /**
     * @notice Blends a background frame with foreground one depending on the
     * alpha channel of the latter.
     * @param backBgr BGR encoded pixel frame (background)
     * @param foreAbgr ABGR encoded pixel frame with alpha channel
     * (foreground)
     * @param width of the background frame
     * @param rect The frame rectangle (coordinates) of the foreground
     */
    function alphaBlend(
        bytes memory backBgr,
        bytes memory foreAbgr,
        uint256 width,
        Rectangle memory rect
    ) internal pure {
        uint256 fgStride = (rect.xMax - rect.xMin) * 4;
        uint256 bgStride = width * 3;

        uint256 fgCursor;
        uint256 bgCursor;
        assembly {
            fgCursor := add(foreAbgr, 0x20)
            bgCursor := add(backBgr, 0x20)
        }

        // Adding the offset to the lower left corner of the foreground frame
        bgCursor += rect.xMin * 3 + rect.yMin * bgStride;

        // The background pointer jump going from the end of one row in the
        // foreground frame to the start of the next one.
        uint256 rowJump = bgStride - (rect.xMax - rect.xMin) * 3;

        assembly {
            // This computation kernel has been taken and inlined from
            // `alphaBlend(uint24 bgr, uint32 abgr)` for efficiency.
            function alphaBlend(bgrPtr, abgrPtr) {
                let buf := mload(bgrPtr)
                let bgr := shr(232, buf)
                let abgr := shr(224, mload(abgrPtr))

                let a := shr(24, abgr)
                let na := sub(0xff, a)

                // Spacing the color channel values across the 256 bit word.
                // | 0 (13B) | R (1B) | 0 (8B) | G (1B) | 0 (8B) | R (1B) |
                // This allows all channels to be blended in a single operation.
                bgr := and(
                    or(or(shl(128, bgr), shl(64, bgr)), bgr),
                    _VECTORISATION_MASK
                )

                abgr := and(
                    or(or(shl(128, abgr), shl(64, abgr)), abgr),
                    _VECTORISATION_MASK
                )

                // h = alpha * fg + (255 - alpha) * bg + 128
                let h := add(
                    add(mul(a, abgr), mul(na, bgr)),
                    // Adds 0x80 to each value
                    0x80000000000000000080000000000000000080
                )

                // h = ((h >> 8) + h) >> 8
                h := and(
                    shr(8, add(shr(8, h), h)),
                    // Bit cleaning
                    _VECTORISATION_MASK
                )

                let res := or(or(shr(128, h), shr(64, h)), h)

                mstore(
                    bgrPtr,
                    or(
                        shl(232, res),
                        and(
                            buf,
                            0x000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                        )
                    )
                )
            }

            // Looping over the foreground frame
            let fgEnd := add(fgCursor, mload(foreAbgr))
            let fgIdx := 0

            for {

            } 1 {

            } {
                // Stopping if we reached the end of the foreground frame.
                if iszero(lt(fgCursor, fgEnd)) {
                    break
                }

                alphaBlend(bgCursor, fgCursor)

                fgIdx := add(fgIdx, 4)
                fgCursor := add(fgCursor, 4)
                bgCursor := add(bgCursor, 3)

                // If we are switching rows in the foreground frame, we have to
                // make a larger jump for the background cursor.
                if iszero(mod(fgIdx, fgStride)) {
                    bgCursor := add(bgCursor, rowJump)
                }
            }
        }
    }

    /**
     * @notice Scales a pixel frame.
     * @param bgr BGR encoded pixel frame.
     * @param width of the frame.
     * @param pixelSize The number of bytes in a pixel. e.g. 4 for ABGR.
     * @param scalingFactor The scaling factor.
     */
    function scale(
        bytes memory bgr,
        uint256 width,
        uint256 pixelSize,
        uint256 scalingFactor
    ) internal pure returns (bytes memory) {
        bytes memory buffer = DynamicBuffer.allocate(
            bgr.length * scalingFactor * scalingFactor
        );
        appendSafeScaled(buffer, bgr, width, pixelSize, scalingFactor);
        return buffer;
    }

    /**
     * @notice Scales a pixel frame and appends the rescaled data to a given
     * buffer.
     * @dev This routine is compatible with ethier's `DynamicBuffer`.
     * @param bgr BGR encoded pixel frame.
     * @param width of the frame.
     * @param pixelSize The number of bytes in a pixel. e.g. 4 for ABGR.
     * @param scalingFactor The scaling factor.
     */
    function appendSafeScaled(
        bytes memory buffer,
        bytes memory bgr,
        uint256 width,
        uint256 pixelSize,
        uint256 scalingFactor
    ) internal pure {
        buffer.checkOverflow(bgr.length * scalingFactor * scalingFactor);

        assembly {
            /**
             * @notice Fills a 2D block in memory by repeating linear chunks
             * e.g.
             * | ..................................|
             * | .... | chunk | chunk | tail | ... |
             * | .... | chunk | chunk | tail | ... |
             * | .... | chunk | chunk | tail | ... |
             * | ..................................|
             * where tail is a broken chunk
             * @param bufPtr The memory pointer to the upper left corner of the
             * block
             * @param bufStride The buffer stride, i.e. the number of bytes that
             * need to be added to get from one row of the buffer to the next
             * without changing the column (aka. the buffer width)
             * @param blockWidth The number of columns covered by the block
             * @param blockHeight The number of rows covered by the block
             * @param chunk The bytes that will be used to fill the block
             * (single word, i.e. max 32 bytes). Big endian, i.e.
             * chunk[:chunkSize] will be used.
             * @param chunkSize The size of the chunk. See above.
             * @param tailMask Mask the bits of the chunk that have to be used
             * for the tail of the block.
             */
            function writeBlock(
                bufPtr,
                bufStride,
                blockWidth,
                blockHeight,
                chunk,
                chunkSize,
                tailMask
            ) {
                // The pointer to the lower right corner of the block
                let bufPtrEnd := add(bufPtr, mul(bufStride, blockHeight))

                // Row loop
                for {

                } 1 {

                } {
                    // Stopping if we reached the end of the block.
                    if iszero(lt(bufPtr, bufPtrEnd)) {
                        break
                    }

                    let rowPtr := bufPtr

                    // Column loop
                    // We are going to write chunks as full words for efficiency.
                    // This might result in out-of-bound writes at the row tail
                    // which will thus need special treatment (masking).
                    for {
                        // Stopping a word before the end of the chunk row to
                        // treat the tail separately.
                        let rowEnd := sub(add(rowPtr, blockWidth), 0x20)
                    } 1 {

                    } {
                        if lt(rowEnd, rowPtr) {
                            break
                        }
                        mstore(rowPtr, chunk)
                        rowPtr := add(rowPtr, chunkSize)
                    }

                    // Since writing a full word would affect memory outside of
                    // the block we load the current content and mix it with the
                    // tail data.
                    mstore(
                        rowPtr,
                        or(
                            and(chunk, not(tailMask)),
                            and(mload(rowPtr), tailMask)
                        )
                    )
                    bufPtr := add(bufPtr, bufStride)
                }
            }

            let dataPtr := add(bgr, 0x20)
            let dataPtrEnd := add(dataPtr, mload(bgr))
            let dataIdx := sub(dataPtr, add(bgr, 0x20))
            let dataStride := mul(width, pixelSize)

            let chunkSize := mul(div(32, pixelSize), pixelSize)
            let blockWidth := mul(pixelSize, scalingFactor)

            let bufPtr := add(add(buffer, 0x20), mload(buffer))
            let bufStride := mul(dataStride, scalingFactor)

            let pixelMask := not(
                shr(
                    shl(3, pixelSize), // * 8
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
            )

            // Binary mask for the tail of the block (i.e. the last
            // chunk that will only be partially written)
            let tailMask := shr(
                shl(3, mod(blockWidth, chunkSize)), // * 8
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )

            // Loop over all data pixels
            for {

            } 1 {

            } {
                if iszero(lt(dataPtr, dataPtrEnd)) {
                    break
                }

                // Building the "chunk" by repeatedly appending the pixel data
                // until a 256bit stack word is full
                let chunk := 0
                for {
                    let pixel := and(mload(dataPtr), pixelMask)
                    let size := 0
                    let shift := mul(pixelSize, 8)
                } 1 {

                } {
                    if iszero(lt(size, chunkSize)) {
                        break
                    }

                    chunk := or(chunk, pixel)
                    pixel := shr(shift, pixel)
                    size := add(size, pixelSize)
                }

                // Fill the block with pixel data
                writeBlock(
                    bufPtr,
                    bufStride,
                    blockWidth,
                    scalingFactor,
                    chunk,
                    chunkSize,
                    tailMask
                )

                dataIdx := add(dataIdx, pixelSize)
                dataPtr := add(dataPtr, pixelSize)
                bufPtr := add(bufPtr, blockWidth)

                // If we are switching rows in the block, we have to make a
                // larger jump for the buffer cursor.
                if iszero(mod(dataIdx, dataStride)) {
                    bufPtr := add(
                        bufPtr,
                        mul(sub(bufStride, dataStride), scalingFactor)
                    )
                }
            }

            // Update the length of the buffer
            mstore(
                buffer,
                add(
                    mload(buffer),
                    mul(mload(bgr), mul(scalingFactor, scalingFactor))
                )
            )
        }
    }
}
//solhint-enable no-empty-blocks

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.16 <0.9.0;

/**
 * @notice Utility library to work with raw bytes data.
 */
library RawData {
    /**
     * @notice Return the byte at the given index interpreted as bool.
     * @dev Any non-zero value is interpreted as true.
     */
    function getBool(bytes memory data, uint256 idx)
        internal
        pure
        returns (bool value)
    {
        return data[idx] != 0;
    }

    /**
     * @notice Clones a bytes array.
     */
    function clone(bytes memory data) internal pure returns (bytes memory) {
        uint256 len = data.length;
        bytes memory buf = new bytes(len);

        uint256 nFullWords = (len - 1) / 32;

        // At the end of data we might still have a few bytes that don't make
        // up a full 32-bytes word.
        // ... [nTailBytes | 32 - nTailBytes -> dirty]
        // So if we again copied a full word for efficiency it would also
        // include some dirty bytes that need to be cleaned first.

        uint256 nTailBytes = len - nFullWords * 32;
        uint256 mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff <<
                ((32 - nTailBytes) * 8);

        assembly {
            let src := add(data, 0x20)
            let dst := add(buf, 0x20)
            for {
                let end := add(src, mul(0x20, nFullWords))
            } lt(src, end) {
                src := add(src, 0x20)
                dst := add(dst, 0x20)
            } {
                mstore(dst, mload(src))
            }

            mstore(dst, and(mload(src), mask))
        }

        return buf;
    }

    /**
     * @notice Reads a big-endian-encoded, 16-bit, unsigned interger from a
     * given offset in a bytes array.
     * @param data The bytes array
     * @param offset The index of the byte in the array at which we start reading.
     * @dev Equivalent to `(uint(data[offset]) << 8) + uint(data[offset + 1])`
     */
    function getUint16(bytes memory data, uint256 offset)
        internal
        pure
        returns (uint16 value)
    {
        assembly {
            value := shr(240, mload(add(data, add(0x20, offset))))
        }
    }

    /**
     * @notice Removes and returns the first byte of an array.
     */
    function popByteFront(bytes memory data)
        internal
        pure
        returns (bytes memory, bytes1)
    {
        bytes1 ret = data[0];
        uint256 len = data.length - 1;
        assembly {
            data := add(data, 1)
            mstore(data, len)
        }
        return (data, ret);
    }

    /**
     * @notice Removes and returns the first DWORD (4bytes) of an array.
     */
    function popDWORDFront(bytes memory data)
        internal
        pure
        returns (bytes memory, bytes4)
    {
        bytes4 ret;
        uint256 len = data.length - 4;
        assembly {
            ret := mload(add(data, 0x20))
            data := add(data, 4)
            mstore(data, len)
        }
        return (data, ret);
    }

    /**
     * @notice Writes an uint32 in little-ending encoding to a given location in
     * bytes array.
     */
    function writeUint32LE(
        bytes memory buf,
        uint256 pos,
        uint32 data
    ) internal pure {
        buf[pos] = bytes1(uint8(data));
        buf[pos + 1] = bytes1(uint8(data >> 8));
        buf[pos + 2] = bytes1(uint8(data >> 16));
        buf[pos + 3] = bytes1(uint8(data >> 24));
    }

    /**
     * @notice Writes an uint16 in little-ending encoding to a given location in
     * bytes array.
     */
    function writeUint16LE(
        bytes memory buf,
        uint256 pos,
        uint16 data
    ) internal pure {
        buf[pos] = bytes1(uint8(data));
        buf[pos + 1] = bytes1(uint8(data >> 8));
    }

    /**
     * @notice Returns a slice of a bytes array.
     * @dev The old array can no longer be used.
     * Intended syntax: `data = data.slice(from, len)`
     */
    function slice(
        bytes memory data,
        uint256 from,
        uint256 len
    ) internal pure returns (bytes memory) {
        assembly {
            data := add(data, from)
            mstore(data, len)
        }
        return data;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
@title SignatureChecker
@notice Additional functions for EnumerableSet.Addresset that require a valid
ECDSA signature of a standardized message, signed by any member of the set.
 */
library SignatureChecker {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
    @notice Requires that the message has not been used previously and that the
    recovered signer is contained in the signers AddressSet.
    @dev Convenience wrapper for message generation + signature verification
    + marking message as used
    @param signers Set of addresses from which signatures are accepted.
    @param usedMessages Set of already-used messages.
    @param signature ECDSA signature of message.
     */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        bytes memory data,
        bytes calldata signature,
        mapping(bytes32 => bool) storage usedMessages
    ) internal {
        bytes32 message = generateMessage(data);
        require(
            !usedMessages[message],
            "SignatureChecker: Message already used"
        );
        usedMessages[message] = true;
        requireValidSignature(signers, message, signature);
    }

    /**
    @notice Requires that the message has not been used previously and that the
    recovered signer is contained in the signers AddressSet.
    @dev Convenience wrapper for message generation + signature verification.
     */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        bytes memory data,
        bytes calldata signature
    ) internal view {
        bytes32 message = generateMessage(data);
        requireValidSignature(signers, message, signature);
    }

    /**
    @notice Requires that the message has not been used previously and that the
    recovered signer is contained in the signers AddressSet.
    @dev Convenience wrapper for message generation from address +
    signature verification.
     */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        address a,
        bytes calldata signature
    ) internal view {
        bytes32 message = generateMessage(abi.encodePacked(a));
        requireValidSignature(signers, message, signature);
    }

    /**
    @notice Common validator logic, checking if the recovered signer is
    contained in the signers AddressSet.
    */
    function validSignature(
        EnumerableSet.AddressSet storage signers,
        bytes32 message,
        bytes calldata signature
    ) internal view returns (bool) {
        return signers.contains(ECDSA.recover(message, signature));
    }

    /**
    @notice Requires that the recovered signer is contained in the signers
    AddressSet.
    @dev Convenience wrapper that reverts if the signature validation fails.
    */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        bytes32 message,
        bytes calldata signature
    ) internal view {
        require(
            validSignature(signers, message, signature),
            "SignatureChecker: Invalid signature"
        );
    }

    /**
    @notice Generates a message for a given data input that will be signed
    off-chain using ECDSA.
    @dev For multiple data fields, a standard concatenation using 
    `abi.encodePacked` is commonly used to build data.
     */
    function generateMessage(bytes memory data)
        internal
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(data);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
@title SignerManager
@notice Manges addition and removal of a core set of addresses from which
valid ECDSA signatures can be accepted; see SignatureChecker.
 */
contract SignerManager is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
    @dev Addresses from which signatures can be accepted.
     */
    EnumerableSet.AddressSet internal signers;

    /**
    @notice Add an address to the set of accepted signers.
     */
    function addSigner(address signer) external onlyOwner {
        signers.add(signer);
    }

    /**
    @notice Remove an address previously added with addSigner().
     */
    function removeSigner(address signer) external onlyOwner {
        signers.remove(signer);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
@notice ERC721 extension that overrides the OpenZeppelin _baseURI() function to
return a prefix that can be set by the contract owner.
 */
contract BaseTokenURI is Ownable {
    /// @notice Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor(string memory _baseTokenURI) {
        setBaseTokenURI(_baseTokenURI);
    }

    /// @notice Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
    @notice Concatenates and returns the base token URI and the token ID without
    any additional characters (e.g. a slash).
    @dev This requires that an inheriting contract that also inherits from OZ's
    ERC721 will have to override both contracts; although we could simply
    require that users implement their own _baseURI() as here, this can easily
    be forgotten and the current approach guides them with compiler errors. This
    favours the latter half of "APIs should be easy to use and hard to misuse"
    from https://www.infoq.com/articles/API-Design-Joshua-Bloch/.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721APreApproval.sol";
import "../utils/OwnerPausable.sol";

/**
@notice An ERC721A contract with common functionality:
 - OpenSea gas-free listings
 - Pausable with toggling functions exposed to Owner only
 */
contract ERC721ACommon is ERC721APreApproval, OwnerPausable {
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {} // solhint-disable-line no-empty-blocks

    /// @notice Requires that the token exists.
    modifier tokenExists(uint256 tokenId) {
        require(ERC721A._exists(tokenId), "ERC721ACommon: Token doesn't exist");
        _;
    }

    /// @notice Requires that msg.sender owns or is approved for the token.
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
                getApproved(tokenId) == _msgSender(),
            "ERC721ACommon: Not approved nor owner"
        );
        _;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!paused(), "ERC721ACommon: paused");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "../thirdparty/opensea/OpenSeaGasFreeListing.sol";
import "erc721a/contracts/ERC721A.sol";

/// @notice Pre-approval of OpenSea proxies for gas-less listing
/// @dev This wrapper allows users to revoke the pre-approval of their
/// associated proxy and emits the corresponding events. This is necessary for
/// external tools to index approvals correctly and inform the user.
/// @dev The pre-approval is triggered on a per-wallet basis during the first
/// transfer transactions. It will only be enabled for wallets with an existing
/// proxy. Not having a proxy incurs a gas overhead.
/// @dev This wrapper optimizes for the following scenario:
/// - The majority of users already have a wyvern proxy
/// - Most of them want to transfer tokens via wyvern exchanges
abstract contract ERC721APreApproval is ERC721A {
    /// @dev It is important that Active remains at first position, since this
    /// is the scenario that we are trying to optimize for.
    enum State {
        Active,
        Inactive
    }

    /// @notice The state of the pre-approval for a given owner
    mapping(address => State) private state;

    /// @dev Returns true if either standard `isApprovedForAll()` or if the
    /// `operator` is the OpenSea proxy for the `owner` provided the
    /// pre-approval is active.
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (super.isApprovedForAll(owner, operator)) {
            return true;
        }

        return
            state[owner] == State.Active &&
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator);
    }

    /// @dev Uses the standard `setApprovalForAll` or toggles the pre-approval
    /// state if `operator` is the OpenSea proxy for the sender.
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        address owner = _msgSender();
        if (operator == OpenSeaGasFreeListing.proxyFor(owner)) {
            state[owner] = approved ? State.Active : State.Inactive;
            emit ApprovalForAll(owner, operator, approved);
        } else {
            super.setApprovalForAll(operator, approved);
        }
    }

    /// @dev Checks if the receiver has an existing proxy. If not, the
    /// pre-approval is disabled.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        // Exclude burns and inactive pre-approvals
        if (to == address(0) || state[to] == State.Inactive) {
            return;
        }

        address operator = OpenSeaGasFreeListing.proxyFor(to);

        // Disable if `to` has no proxy
        if (operator == address(0)) {
            state[to] = State.Inactive;
            return;
        }

        // Avoid emitting unnecessary events.
        if (balanceOf(to) == 0) {
            emit ApprovalForAll(to, operator, true);
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
@notice Allows holders of ERC721 tokens to redeem rights to some claim; for
example, the right to mint a token of some other collection.
*/
library ERC721Redeemer {
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    /**
    @notice Storage value to track already-claimed redemptions for a specific
    token collection.
     */
    struct Claims {
        /**
        @dev This field MUST NOT be considered part of the public API. Instead,
        prefer `using ERC721Redeemer for ERC721Redeemer.Claims` and utilise the
        provided functions.
         */
        mapping(uint256 => uint256) _total;
    }

    /**
    @notice Storage value to track already-claimed redemptions for a specific
    token collection, given that there is only a single claim allowed per
    tokenId.
     */
    struct SingleClaims {
        /**
        @dev This field MUST NOT be considered part of the public API. Instead,
        prefer `using ERC721Redeemer for ERC721Redeemer.SingleClaims` and
        utilise the provided functions.
         */
        BitMaps.BitMap _claimed;
    }

    /**
    @notice Emitted when a token's claim is redeemed.
     */
    event Redemption(
        IERC721 indexed token,
        address indexed redeemer,
        uint256 tokenId,
        uint256 n
    );

    /**
    @notice Checks that the redeemer is allowed to redeem the claims for the
    tokenIds by being either the owner or approved address for all tokenIds, and
    updates the Claims to reflect this.
    @dev For more efficient gas usage, recurring values in tokenIds SHOULD be
    adjacent to one another as this will batch expensive operations. The
    simplest way to achieve this is by sorting tokenIds.
    @param tokenIds The token IDs for which the claims are being redeemed. If
    maxAllowance > 1 then identical tokenIds can be passed more than once; see
    dev comments.
    @return The number of redeemed claims; either 0 or tokenIds.length;
     */
    function redeem(
        Claims storage claims,
        uint256 maxAllowance,
        address redeemer,
        IERC721 token,
        uint256[] calldata tokenIds
    ) internal returns (uint256) {
        if (maxAllowance == 0 || tokenIds.length == 0) {
            return 0;
        }

        // See comment for `endSameId`.
        bool multi = maxAllowance > 1;

        for (
            uint256 i = 0;
            i < tokenIds.length; /* note increment at end */

        ) {
            uint256 tokenId = tokenIds[i];
            requireOwnerOrApproved(token, tokenId, redeemer);

            uint256 n = 1;
            if (multi) {
                // If allowed > 1 we can save on expensive operations like
                // checking ownership / remaining allowance by batching equal
                // tokenIds. The algorithm assumes that equal IDs are adjacent
                // in the array.
                uint256 endSameId;
                for (
                    endSameId = i + 1;
                    endSameId < tokenIds.length &&
                        tokenIds[endSameId] == tokenId;
                    endSameId++
                ) {} // solhint-disable-line no-empty-blocks
                n = endSameId - i;
            }

            claims._total[tokenId] += n;
            if (claims._total[tokenId] > maxAllowance) {
                revertWithTokenId(
                    "ERC721Redeemer: over allowance for",
                    tokenId
                );
            }
            i += n;

            emit Redemption(token, redeemer, tokenId, n);
        }

        return tokenIds.length;
    }

    /**
    @notice Checks that the redeemer is allowed to redeem the single claim for
    each of the tokenIds by being either the owner or approved address for all
    tokenIds, and updates the SingleClaims to reflect this.
    @param tokenIds The token IDs for which the claims are being redeemed. Only
    a single claim can be made against a tokenId.
    @return The number of redeemed claims; either 0 or tokenIds.length;
     */
    function redeem(
        SingleClaims storage claims,
        address redeemer,
        IERC721 token,
        uint256[] calldata tokenIds
    ) internal returns (uint256) {
        if (tokenIds.length == 0) {
            return 0;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            requireOwnerOrApproved(token, tokenId, redeemer);

            if (claims._claimed.get(tokenId)) {
                revertWithTokenId(
                    "ERC721Redeemer: over allowance for",
                    tokenId
                );
            }

            claims._claimed.set(tokenId);
            emit Redemption(token, redeemer, tokenId, 1);
        }
        return tokenIds.length;
    }

    /**
    @dev Reverts if neither the owner nor approved for the tokenId.
     */
    function requireOwnerOrApproved(
        IERC721 token,
        uint256 tokenId,
        address redeemer
    ) private view {
        if (
            token.ownerOf(tokenId) != redeemer &&
            token.getApproved(tokenId) != redeemer
        ) {
            revertWithTokenId(
                "ERC721Redeemer: not approved nor owner of",
                tokenId
            );
        }
    }

    /**
    @notice Reverts with the concatenation of revertMsg and tokenId.toString().
    @dev Used to save gas by constructing the revert message only as required,
    instead of passing it to require().
     */
    function revertWithTokenId(string memory revertMsg, uint256 tokenId)
        private
        pure
    {
        revert(string(abi.encodePacked(revertMsg, " ", tokenId.toString())));
    }

    /**
    @notice Returns the number of claimed redemptions for the token.
     */
    function claimed(Claims storage claims, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return claims._total[tokenId];
    }

    /**
    @notice Returns whether the token has had a claim made against it.
     */
    function claimed(SingleClaims storage claims, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return claims._claimed.get(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "./Seller.sol";

/// @notice A Seller with fixed per-item price.
abstract contract FixedPriceSeller is Seller {
    constructor(
        uint256 _price,
        Seller.SellerConfig memory sellerConfig,
        address payable _beneficiary
    ) Seller(sellerConfig, _beneficiary) {
        setPrice(_price);
    }

    /**
    @notice The fixed per-item price.
    @dev Fixed as in not changing with time nor number of items, but not a
    constant.
     */
    uint256 public price;

    /// @notice Sets the per-item price.
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /**
    @notice Override of Seller.cost() with fixed price.
    @dev The second parameter, metadata propagated from the call to _purchase(),
    is ignored.
     */
    function cost(uint256 n, uint256) public view override returns (uint256) {
        return n * price;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "../utils/Monotonic.sol";
import "../utils/OwnerPausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
@notice An abstract contract providing the _purchase() function to:
 - Enforce per-wallet / per-transaction limits
 - Calculate required cost, forwarding to a beneficiary, and refunding extra
 */
abstract contract Seller is OwnerPausable, ReentrancyGuard {
    using Address for address payable;
    using Monotonic for Monotonic.Increaser;
    using Strings for uint256;

    /**
    @dev Note that the address limits are vulnerable to wallet farming.
    @param maxPerAddress Unlimited if zero.
    @param maxPerTex Unlimited if zero.
    @param freeQuota Maximum number that can be purchased free of charge by
    the contract owner.
    @param reserveFreeQuota Whether to excplitly reserve the freeQuota amount
    and not let it be eroded by regular purchases.
    @param lockFreeQuota If true, calls to setSellerConfig() will ignore changes
    to freeQuota. Can be locked after initial setting, but not unlocked. This
    allows a contract owner to commit to a maximum number of reserved items.
    @param lockTotalInventory Similar to lockFreeQuota but applied to
    totalInventory.
    */
    struct SellerConfig {
        uint256 totalInventory;
        uint256 maxPerAddress;
        uint256 maxPerTx;
        uint248 freeQuota;
        bool reserveFreeQuota;
        bool lockFreeQuota;
        bool lockTotalInventory;
    }

    constructor(SellerConfig memory config, address payable _beneficiary) {
        setSellerConfig(config);
        setBeneficiary(_beneficiary);
    }

    /// @notice Configuration of purchase limits.
    SellerConfig public sellerConfig;

    /// @notice Sets the seller config.
    function setSellerConfig(SellerConfig memory config) public onlyOwner {
        require(
            config.totalInventory >= config.freeQuota,
            "Seller: excessive free quota"
        );
        require(
            config.totalInventory >= _totalSold.current(),
            "Seller: inventory < already sold"
        );
        require(
            config.freeQuota >= purchasedFreeOfCharge.current(),
            "Seller: free quota < already used"
        );

        // Overriding the in-memory fields before copying the whole struct, as
        // against writing individual fields, gives a greater guarantee of
        // correctness as the code is simpler to read.
        if (sellerConfig.lockTotalInventory) {
            config.lockTotalInventory = true;
            config.totalInventory = sellerConfig.totalInventory;
        }
        if (sellerConfig.lockFreeQuota) {
            config.lockFreeQuota = true;
            config.freeQuota = sellerConfig.freeQuota;
        }
        sellerConfig = config;
    }

    /// @notice Recipient of revenues.
    address payable public beneficiary;

    /// @notice Sets the recipient of revenues.
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    /**
    @dev Must return the current cost of a batch of items. This may be constant
    or, for example, decreasing for a Dutch auction or increasing for a bonding
    curve.
    @param n The number of items being purchased.
    @param metadata Arbitrary data, propagated by the call to _purchase() that
    can be used to charge different prices. This value is a uint256 instead of
    bytes as this allows simple passing of a set cost (see
    ArbitraryPriceSeller).
     */
    function cost(uint256 n, uint256 metadata)
        public
        view
        virtual
        returns (uint256);

    /**
    @dev Called by both _purchase() and purchaseFreeOfCharge() after all limits
    have been put in place; must perform all contract-specific sale logic, e.g.
    ERC721 minting. When _handlePurchase() is called, the value returned by
    Seller.totalSold() will be the pre-purchase amount.
    @param to The recipient of the item(s).
    @param n The number of items allowed to be purchased, which MAY be less than
    to the number passed to _purchase() but SHALL be greater than zero.
    @param freeOfCharge Indicates that the call originated from
    purchaseFreeOfCharge() and not _purchase().
    */
    function _handlePurchase(
        address to,
        uint256 n,
        bool freeOfCharge
    ) internal virtual;

    /**
    @notice Tracks total number of items sold by this contract, including those
    purchased free of charge by the contract owner.
     */
    Monotonic.Increaser private _totalSold;

    /// @notice Returns the total number of items sold by this contract.
    function totalSold() public view returns (uint256) {
        return _totalSold.current();
    }

    /**
    @notice Tracks the number of items already bought by an address, regardless
    of transferring out (in the case of ERC721).
    @dev This isn't public as it may be skewed due to differences in msg.sender
    and tx.origin, which it treats in the same way such that
    sum(_bought)>=totalSold().
     */
    mapping(address => uint256) private _bought;

    /**
    @notice Returns min(n, max(extra items addr can purchase)) and reverts if 0.
    @param zeroMsg The message with which to revert on 0 extra.
     */
    function _capExtra(
        uint256 n,
        address addr,
        string memory zeroMsg
    ) internal view returns (uint256) {
        uint256 extra = sellerConfig.maxPerAddress - _bought[addr];
        if (extra == 0) {
            revert(string(abi.encodePacked("Seller: ", zeroMsg)));
        }
        return Math.min(n, extra);
    }

    /// @notice Emitted when a buyer is refunded.
    event Refund(address indexed buyer, uint256 amount);

    /// @notice Emitted on all purchases of non-zero amount.
    event Revenue(
        address indexed beneficiary,
        uint256 numPurchased,
        uint256 amount
    );

    /// @notice Tracks number of items purchased free of charge.
    Monotonic.Increaser private purchasedFreeOfCharge;

    /**
    @notice Allows the contract owner to purchase without payment, within the
    quota enforced by the SellerConfig.
     */
    function purchaseFreeOfCharge(address to, uint256 n)
        public
        onlyOwner
        whenNotPaused
    {
        uint256 freeQuota = sellerConfig.freeQuota;
        n = Math.min(n, freeQuota - purchasedFreeOfCharge.current());
        require(n > 0, "Seller: Free quota exceeded");

        uint256 totalInventory = sellerConfig.totalInventory;
        n = Math.min(n, totalInventory - _totalSold.current());
        require(n > 0, "Seller: Sold out");

        _handlePurchase(to, n, true);

        _totalSold.add(n);
        purchasedFreeOfCharge.add(n);
        assert(_totalSold.current() <= totalInventory);
        assert(purchasedFreeOfCharge.current() <= freeQuota);
    }

    /**
    @notice Convenience function for calling _purchase() with empty costMetadata
    when unneeded.
     */
    function _purchase(address to, uint256 requested) internal virtual {
        _purchase(to, requested, 0);
    }

    /**
    @notice Enforces all purchase limits (counts and costs) before calling
    _handlePurchase(), after which the received funds are disbursed to the
    beneficiary, less any required refunds.
    @param to The final recipient of the item(s).
    @param requested The number of items requested for purchase, which MAY be
    reduced when passed to _handlePurchase().
    @param costMetadata Arbitrary data, propagated in the call to cost(), to be
    optionally used in determining the price.
     */
    function _purchase(
        address to,
        uint256 requested,
        uint256 costMetadata
    ) internal nonReentrant whenNotPaused {
        /**
         * ##### CHECKS
         */
        SellerConfig memory config = sellerConfig;

        uint256 n = config.maxPerTx == 0
            ? requested
            : Math.min(requested, config.maxPerTx);

        uint256 maxAvailable;
        uint256 sold;

        if (config.reserveFreeQuota) {
            maxAvailable = config.totalInventory - config.freeQuota;
            sold = _totalSold.current() - purchasedFreeOfCharge.current();
        } else {
            maxAvailable = config.totalInventory;
            sold = _totalSold.current();
        }

        n = Math.min(n, maxAvailable - sold);
        require(n > 0, "Seller: Sold out");

        if (config.maxPerAddress > 0) {
            bool alsoLimitSender = _msgSender() != to;
            // solhint-disable-next-line avoid-tx-origin
            bool alsoLimitOrigin = tx.origin != _msgSender() && tx.origin != to;

            n = _capExtra(n, to, "Buyer limit");
            if (alsoLimitSender) {
                n = _capExtra(n, _msgSender(), "Sender limit");
            }
            if (alsoLimitOrigin) {
                // solhint-disable-next-line avoid-tx-origin
                n = _capExtra(n, tx.origin, "Origin limit");
            }

            _bought[to] += n;
            if (alsoLimitSender) {
                _bought[_msgSender()] += n;
            }
            if (alsoLimitOrigin) {
                // solhint-disable-next-line avoid-tx-origin
                _bought[tx.origin] += n;
            }
        }

        uint256 _cost = cost(n, costMetadata);
        if (msg.value < _cost) {
            revert(
                string(
                    abi.encodePacked(
                        "Seller: Costs ",
                        (_cost / 1e9).toString(),
                        " GWei"
                    )
                )
            );
        }

        /**
         * ##### EFFECTS
         */

        _handlePurchase(to, n, false);
        _totalSold.add(n);
        assert(_totalSold.current() <= config.totalInventory);

        /**
         * ##### INTERACTIONS
         */

        // Ideally we'd be using a PullPayment here, but the user experience is
        // poor when there's a variable cost or the number of items purchased
        // has been capped. We've addressed reentrancy with both a nonReentrant
        // modifier and the checks, effects, interactions pattern.

        if (_cost > 0) {
            beneficiary.sendValue(_cost);
            emit Revenue(beneficiary, n, _cost);
        }

        if (msg.value > _cost) {
            address payable reimburse = payable(_msgSender());
            uint256 refund = msg.value - _cost;

            // Using Address.sendValue() here would mask the revertMsg upon
            // reentrancy, but we want to expose it to allow for more precise
            // testing. This otherwise uses the exact same pattern as
            // Address.sendValue().
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returnData) = reimburse.call{
                value: refund
            }("");
            // Although `returnData` will have a spurious prefix, all we really
            // care about is that it contains the ReentrancyGuard reversion
            // message so we can check in the tests.
            require(success, string(returnData));

            emit Refund(reimburse, refund);
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

// Inspired by BaseOpenSea by Simon Fremaux (@dievardump) but without the need
// to pass specific addresses depending on deployment network.
// https://gist.github.com/dievardump/483eb43bc6ed30b14f01e01842e3339b/

import "./ProxyRegistry.sol";

/// @notice Library to achieve gas-free listings on OpenSea.
library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        address proxy = proxyFor(owner);
        return proxy != address(0) && proxy == operator;
    }

    /**
    @notice Returns the OpenSea proxy address for the owner.
     */
    function proxyFor(address owner) internal view returns (address) {
        address registry;
        uint256 chainId;

        assembly {
            chainId := chainid()
            switch chainId
            // Production networks are placed higher to minimise the number of
            // checks performed and therefore reduce gas. By the same rationale,
            // mainnet comes before Polygon as it's more expensive.
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 137 {
                // polygon
                registry := 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
            case 80001 {
                // mumbai
                registry := 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
            }
            case 1337 {
                // The geth SimulatedBackend iff used with the ethier
                // openseatest package. This is mocked as a Wyvern proxy as it's
                // more complex than the 0x ones.
                registry := 0xE1a2bbc877b29ADBC56D2659DBcb0ae14ee62071
            }
        }

        // Unlike Wyvern, the registry itself is the proxy for all owners on 0x
        // chains.
        if (registry == address(0) || chainId == 137 || chainId == 80001) {
            return registry;
        }

        return address(ProxyRegistry(registry).proxies(owner));
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

/// @notice A minimal interface describing OpenSea's Wyvern proxy registry.
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
@dev This pattern of using an empty contract is cargo-culted directly from
OpenSea's example code. TODO: it's likely that the above mapping can be changed
to address => address without affecting anything, but further investigation is
needed (i.e. is there a subtle reason that OpenSea released it like this?).
 */
// solhint-disable-next-line no-empty-blocks
contract OwnableDelegateProxy {

}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

/**
@notice Provides monotonic increasing and decreasing values, similar to
OpenZeppelin's Counter but (a) limited in direction, and (b) allowing for steps
> 1.
 */
library Monotonic {
    /**
    @notice Holds a value that can only increase.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and add().
     */
    struct Increaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Increaser.
    function current(Increaser storage incr) internal view returns (uint256) {
        return incr.value;
    }

    /// @notice Adds x to the Increaser's value.
    function add(Increaser storage incr, uint256 x) internal {
        incr.value += x;
    }

    /**
    @notice Holds a value that can only decrease.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and subtract().
     */
    struct Decreaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Decreaser.
    function current(Decreaser storage decr) internal view returns (uint256) {
        return decr.value;
    }

    /// @notice Subtracts x from the Decreaser's value.
    function subtract(Decreaser storage decr, uint256 x) internal {
        decr.value -= x;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice A Pausable contract that can only be toggled by the Owner.
contract OwnerPausable is Ownable, Pausable {
    /// @notice Pauses the contract.
    function pause() public onlyOwner {
        Pausable._pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        Pausable._unpause();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
@dev A minimal interface for interaction with the Moonbirds contract.
 */
interface IMoonbirds is IERC721 {
    function nestingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool nesting,
            uint256 current,
            uint256 total
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

// Not actually deployed; added for tests of later contracts, such as Oddities.
import "./IMoonbirds.sol";

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/crypto/SignerManager.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// @author divergence.xyz
contract Moonbirds is
    IMoonbirds,
    ERC721ACommon,
    BaseTokenURI,
    FixedPriceSeller,
    SignerManager,
    ERC2981,
    AccessControlEnumerable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC721Redeemer for ERC721Redeemer.Claims;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    IERC721 public immutable proof;

    /**
    @notice Role of administrative users allowed to expel a Moonbird from the
    nest.
    @dev See expelFromNest().
     */
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        IERC721 _proof,
        address payable beneficiary,
        address payable royaltyReceiver
    )
        ERC721ACommon(name, symbol)
        BaseTokenURI("")
        FixedPriceSeller(
            2.5 ether,
            // Not including a separate pool for PROOF holders, taking the total
            // to 10k. We don't enforce buyer limits here because it's already
            // done by only issuing a single signature per address, and double
            // enforcement would waste gas.
            Seller.SellerConfig({
                totalInventory: 8_000,
                lockTotalInventory: true,
                maxPerAddress: 0,
                maxPerTx: 0,
                freeQuota: 125,
                lockFreeQuota: false,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        proof = _proof;
        _setDefaultRoyalty(royaltyReceiver, 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        _safeMint(to, n);

        // We're using two separate pools (one from Seller, and one for PROOF
        // minting), so add an extra layer of checks for this invariant. This
        // should never fail as each pool has its own restriction, and is in
        // place purely for tests (hence assert).
        assert(totalSupply() <= 10_000);
    }

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Mint as a non-holder of PROOF tokens.
     */
    function mintPublic(
        address to,
        bytes32 nonce,
        bytes calldata sig
    ) external payable {
        signers.requireValidSignature(
            signaturePayload(to, nonce),
            sig,
            usedMessages
        );
        _purchase(to, 1);
    }

    /**
    @notice Returns whether the address has minted with the particular nonce. If
    true, future calls to mint() with the same parameters will fail.
    @dev In production we will never issue more than a single nonce per address,
    but this allows for testing with a single address.
     */
    function alreadyMinted(address to, bytes32 nonce)
        external
        view
        returns (bool)
    {
        return
            usedMessages[
                SignatureChecker.generateMessage(signaturePayload(to, nonce))
            ];
    }

    /**
    @dev Constructs the buffer that is hashed for validation with a minting
    signature.
     */
    function signaturePayload(address to, bytes32 nonce)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(to, nonce);
    }

    /**
    @notice Two guaranteed mints per PROOF holder.
    @dev This is specifically tracked because unclaimed tokens will be minted to
    the PROOF wallet, so the pool guarantees an upper bound.
     */
    uint256 public proofPoolRemaining = 2000;

    ERC721Redeemer.Claims private redeemedPROOF;

    /**
    @dev Used by both PROOF-holder and PROOF-admin minting from the pool.
     */
    modifier reducePROOFPool(uint256 n) {
        require(n <= proofPoolRemaining, "Moonbirds: PROOF pool exhausted");
        proofPoolRemaining -= n;
        _;
    }

    /**
    @notice Flag indicating whether holders of PROOF passes can mint.
     */
    bool public proofMintingOpen = false;

    /**
    @notice Sets whether holders of PROOF passes can mint.
     */
    function setPROOFMintingOpen(bool open) external onlyOwner {
        proofMintingOpen = open;
    }

    /**
    @notice Mint as a holder of a PROOF token.
    @dev Repeat a PROOF token ID twice to redeem both of its claims; recurring
    values SHOULD be adjacent for improved gas (eg [1,1,2,2] not [1,2,1,2]).
     */
    function mintPROOF(uint256[] calldata proofTokenIds)
        external
        reducePROOFPool(proofTokenIds.length)
    {
        require(proofMintingOpen, "Moonbirds: PROOF minting closed");
        uint256 n = redeemedPROOF.redeem(2, msg.sender, proof, proofTokenIds);
        _handlePurchase(msg.sender, n, true);
    }

    /**
    @notice Returns how many additional Moonbirds can be claimed with the PROOF
    token.
     */
    function proofClaimsRemaining(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        require(tokenId < 1000, "Token doesn't exist");
        return 2 - redeemedPROOF.claimed(tokenId);
    }

    /**
    @notice Mint unclaimed tokens from the PROOF-holder pool.
     */
    function mintUnclaimed(address to, uint256 n)
        external
        onlyOwner
        reducePROOFPool(n)
    {
        _handlePurchase(to, n, true);
    }

    /**
    @dev tokenId to nesting start time (0 = not nesting).
     */
    mapping(uint256 => uint256) private nestingStarted;

    /**
    @dev Cumulative per-token nesting, excluding the current period.
     */
    mapping(uint256 => uint256) private nestingTotal;

    /**
    @notice Returns the length of time, in seconds, that the Moonbird has
    nested.
    @dev Nesting is tied to a specific Moonbird, not to the owner, so it doesn't
    reset upon sale.
    @return nesting Whether the Moonbird is currently nesting. MAY be true with
    zero current nesting if in the same block as nesting began.
    @return current Zero if not currently nesting, otherwise the length of time
    since the most recent nesting began.
    @return total Total period of time for which the Moonbird has nested across
    its life, including the current period.
     */
    function nestingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool nesting,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = nestingStarted[tokenId];
        if (start != 0) {
            nesting = true;
            current = block.timestamp - start;
        }
        total = current + nestingTotal[tokenId];
    }

    /**
    @dev MUST only be modified by safeTransferWhileNesting(); if set to 2 then
    the _beforeTokenTransfer() block while nesting is disabled.
     */
    uint256 private nestingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the Moonbird is minting,
    thus not resetting the nesting period.
     */
    function safeTransferWhileNesting(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "Moonbirds: Only owner");
        nestingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        nestingTransfer = 1;
    }

    /**
    @dev Block transfers while nesting.
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                nestingStarted[tokenId] == 0 || nestingTransfer == 2,
                "Moonbirds: nesting"
            );
        }
    }

    /**
    @dev Emitted when a Moonbird begins nesting.
     */
    event Nested(uint256 indexed tokenId);

    /**
    @dev Emitted when a Moonbird stops nesting; either through standard means or
    by expulsion.
     */
    event Unnested(uint256 indexed tokenId);

    /**
    @dev Emitted when a Moonbird is expelled from the nest.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether nesting is currently allowed.
    @dev If false then nesting is blocked, but unnesting is always allowed.
     */
    bool public nestingOpen = false;

    /**
    @notice Toggles the `nestingOpen` flag.
     */
    function setNestingOpen(bool open) external onlyOwner {
        nestingOpen = open;
    }

    /**
    @notice Changes the Moonbird's nesting status.
    */
    function toggleNesting(uint256 tokenId)
        internal
        onlyApprovedOrOwner(tokenId)
    {
        uint256 start = nestingStarted[tokenId];
        if (start == 0) {
            require(nestingOpen, "Moonbirds: nesting closed");
            nestingStarted[tokenId] = block.timestamp;
            emit Nested(tokenId);
        } else {
            nestingTotal[tokenId] += block.timestamp - start;
            nestingStarted[tokenId] = 0;
            emit Unnested(tokenId);
        }
    }

    /**
    @notice Changes the Moonbirds' nesting statuss (what's the plural of status?
    statii? statuses? status? The plural of sheep is sheep; maybe it's also the
    plural of status).
    @dev Changes the Moonbirds' nesting sheep (see @notice).
     */
    function toggleNesting(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleNesting(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a Moonbird from the nest.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has nested and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting bird to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because nesting would then be all-or-nothing for all of a particular owner's
    Moonbirds.
     */
    function expelFromNest(uint256 tokenId) external onlyRole(EXPULSION_ROLE) {
        require(nestingStarted[tokenId] != 0, "Moonbirds: not nested");
        nestingTotal[tokenId] += block.timestamp - nestingStarted[tokenId];
        nestingStarted[tokenId] = 0;
        emit Unnested(tokenId);
        emit Expelled(tokenId);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
    @notice If set, contract to which tokenURI() calls are proxied.
     */
    ITokenURIGenerator public renderingContract;

    /**
    @notice Sets the optional tokenURI override contract.
     */
    function setRenderingContract(ITokenURIGenerator _contract)
        external
        onlyOwner
    {
        renderingContract = _contract;
    }

    /**
    @notice If renderingContract is set then returns its tokenURI(tokenId)
    return value, otherwise returns the standard baseTokenURI + tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (address(renderingContract) != address(0)) {
            return renderingContract.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = 1;

            // compute log10(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 10**64) {
                valueCopy /= 10**64;
                length += 64;
            }
            if (valueCopy >= 10**32) {
                valueCopy /= 10**32;
                length += 32;
            }
            if (valueCopy >= 10**16) {
                valueCopy /= 10**16;
                length += 16;
            }
            if (valueCopy >= 10**8) {
                valueCopy /= 10**8;
                length += 8;
            }
            if (valueCopy >= 10**4) {
                valueCopy /= 10**4;
                length += 4;
            }
            if (valueCopy >= 10**2) {
                valueCopy /= 10**2;
                length += 2;
            }
            if (valueCopy >= 10**1) {
                length += 1;
            }
            // now, length is log10(value) + 1

            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = 1;

            // compute log256(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 1 << 128) {
                valueCopy >>= 128;
                length += 16;
            }
            if (valueCopy >= 1 << 64) {
                valueCopy >>= 64;
                length += 8;
            }
            if (valueCopy >= 1 << 32) {
                valueCopy >>= 32;
                length += 4;
            }
            if (valueCopy >= 1 << 16) {
                valueCopy >>= 16;
                length += 2;
            }
            if (valueCopy >= 1 << 8) {
                valueCopy >>= 8;
                length += 1;
            }
            // now, length is log256(value) + 1

            return toHexString(value, length);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {IBucketStorage} from "solidify-contracts/IBucketStorage.sol";
import {InflateLibWrapper, Compressed} from "solidify-contracts/InflateLibWrapper.sol";
import {IndexedBucketLib} from "solidify-contracts/IndexedBucketLib.sol";
import {LabelledBucketLib} from "solidify-contracts/LabelledBucketLib.sol";

/**
 * @notice Coordinates to identify a bucket inside a storage bundle.
 * @dev These describe a hierarchical storage structure akin to
 * `x.storageId.bucketId`
 */
struct BucketCoordinates {
    uint256 storageId;
    uint256 bucketId;
}

/**
 * @notice Utility library to retrieve data from a storage bundle.
 */
library BucketStorageLib {
    using InflateLibWrapper for Compressed;

    /**
     * @notice Retrieves uncompressed bucket data from a bundle.
     */
    function loadUncompressed(
        IBucketStorage[] storage bundle,
        BucketCoordinates memory coordinates
    ) internal view returns (bytes memory) {
        return loadCompressed(bundle, coordinates).inflate();
    }

    /**
     * @notice Retrieves compressed bucket data from a bundle.
     */
    function loadCompressed(
        IBucketStorage[] storage bundle,
        BucketCoordinates memory coordinates
    ) internal view returns (Compressed memory) {
        return bundle[coordinates.storageId].getBucket(coordinates.bucketId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity ^0.8.16;

/**
 * @notice Generic compressed data.
 * @param uncompressedSize Used for checking correct decompression
 * @param data The compressed data blob.
 */
struct Compressed {
    uint256 uncompressedSize;
    bytes data;
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {Compressed} from "solidify-contracts/Compressed.sol";

/**
 * @notice BucketStorage is used to store a list of compressed buckets in
 * contract code.
 */
interface IBucketStorage {
    /**
     * @notice Thrown if a non-existant bucket should be accessed.
     */
    error InvalidBucketIndex();

    /**
     * @notice Returns the compressed bucket with given index.
     * @param bucketIndex The index of the bucket in the storage.
     * @dev Reverts if the index is out-of-range.
     */
    function getBucket(uint256 bucketIndex)
        external
        pure
        returns (Compressed memory);

    function numBuckets() external pure returns (uint256);

    function numFields() external pure returns (uint256);

    function numFieldsPerBucket() external pure returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {RawData} from "ethier/utils/RawData.sol";

/**
 * @notice Utility library to retrieve indexed fields from decompressed Buckets.
 * @dev This library assumes that the starting offsets of each fields are
 * stored sequentially as big-endian unt16 values at the start of the array
 * with the actual payload afterwards.
 * | uint16 offset field 0 | ... | uint16 offset field N-1 | payload 1 | ... |
 */
// Todo explain time/space complexity tradeoff of lenghtprefixed vs apriori-indexed
library IndexedBucketLib {
    using RawData for bytes;

    /**
     * @notice Thrown if a field index is not contained in a given bucket.
     */
    error FieldIndexOutOfBounds(uint256 fieldIndex, uint256 numFields);

    /**
     * @notice Retrieves the field with a given index.
     * @dev Retrieves the payload data in-memory to avoid reallocations.
     * This implies that the buffer data cannot be reused.
     * Intended syntax: `data = data.getField(idx)`.
     * @param data The decompressed bucket data.
     * @param fieldIdx The index of the field that should be retrieved.
     */
    function getField(bytes memory data, uint256 fieldIdx)
        internal
        pure
        returns (bytes memory)
    {
        // Since each index takes 2 bytes of storage, the number of fields can
        // be determined from the the location of the first field right after
        // the index header ends.
        uint256 numFields = data.getUint16(0) >> 1;
        if (fieldIdx >= numFields) {
            revert FieldIndexOutOfBounds(fieldIdx, numFields);
        }

        // The offset in the array at which the field of interest starts
        uint256 loc = data.getUint16(fieldIdx * 2);

        uint256 length;
        if (fieldIdx + 1 < numFields) {
            // The lenght of a field can be determined from the difference of
            // its starting offset to the one of the following field.
            length = data.getUint16((1 + fieldIdx) * 2) - loc;
        } else {
            // If the field is the last one in the array, we determine its end
            // from the full length of the array instead.
            length = data.length - loc;
        }

        // To save gas, we update the pointer and size in memory instead of
        // allocating new space and copying the content over.
        assembly {
            data := add(data, loc)
            mstore(data, length)
        }
        return data;
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {InflateLib} from "inflate-sol/InflateLib.sol";
import {Compressed} from "solidify-contracts/Compressed.sol";

/**
 * @notice A lightweight convenience wrapper around `inflate-sol/InflateLib` to
 * make it compatible with our types.
 */
library InflateLibWrapper {
    /**
     * @notice Thrown on decompression errors.
     * @dev See `InflateLib.ErrorCode` for more details.
     */
    error InflationError(InflateLib.ErrorCode);

    /**
     * @notice Inflates compressed data.
     * @dev Reverts on decompression errors.
     */
    function inflate(Compressed memory data)
        internal
        pure
        returns (bytes memory)
    {
        (InflateLib.ErrorCode err, bytes memory inflated) = InflateLib.puff(
            data.data,
            data.uncompressedSize
        );

        if (err != InflateLib.ErrorCode.ERR_NONE) revert InflationError(err);

        return inflated;
    }
}

/**
 * @notice Public version of the above library to allow reuse through linking if
 * the performance overhead is not critical.
 */
library PublicInflateLibWrapper {
    using InflateLibWrapper for Compressed;

    function inflate(Compressed memory data)
        public
        pure
        returns (bytes memory)
    {
        return data.inflate();
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {RawData} from "ethier/utils/RawData.sol";

/**
 * @notice Utility library to retrieve label-prefixed fields from decompressed
 * Buckets.
 * @dev This library assumes that all fields have fixed length and start with an
 * strictly monotonically increasing, big-endian, uint16 label.
 * | ... | uint16 label | payload | ... |
 */
library LabelledBucketLib {
    using RawData for bytes;

    /**
     * @notice Thrown if a label is not between the first and last label in a
     * bucket.
     */
    error InvalidBinarySearchBound(
        uint16 label,
        uint16 leftBound,
        uint16 rightBound
    );

    /**
     * @notice Throws if a label cannot be found in the given bucket.
     */
    error LabelNotFound(uint256 label);

    /**
     * @notice Thrown if the bucket size cannot be divided into fields of given
     * length.
     */
    error BucketAndFieldLengthMismatch();

    /**
     * @notice Retrieves the field with a given label.
     * @dev Reverts if the label cannot be found.
     * @dev Retrieves the payload data in-memory to avoid reallocations.
     * This implies that the buffer data cannot be reused.
     * Intended syntax: `data = data.findFieldByLabel(label, fieldLength)`.
     * @param data The decompressed bucket data.
     * @param label The label of the field that should be retrieved.
     * @param fieldLength Number of payload bytes in a field.
     */
    function findFieldByLabel(
        bytes memory data,
        uint16 label,
        uint256 fieldLength
    ) internal pure returns (bytes memory) {
        uint256 chunkLength = fieldLength + 2;
        if (data.length % chunkLength != 0) {
            revert BucketAndFieldLengthMismatch();
        }
        uint256 idx = _binarySearchLabelled16Field(data, label, chunkLength);
        return data.slice(idx * chunkLength + 2, fieldLength);
    }

    /**
     * @notice Retrieves the field with a given label using a binary search.
     * @dev See also `findFieldByLabel`.
     */
    function _binarySearchLabelled16Field(
        bytes memory data,
        uint16 label,
        uint256 chunkLength
    ) private pure returns (uint256) {
        uint256 ia = 0;
        uint256 ib = data.length / chunkLength - 1;

        uint16 a = data.getUint16(ia * chunkLength);
        if (a == label) {
            return ia;
        }

        uint16 b = data.getUint16(ib * chunkLength);
        if (b == label) {
            return ib;
        }

        if (label < a) {
            revert InvalidBinarySearchBound(label, a, b);
        }
        if (b < label) {
            revert InvalidBinarySearchBound(label, a, b);
        }

        while (true) {
            if (ib - ia < 2) {
                // We cannot subdivide any further
                break;
            }

            // Compute new midpoint
            uint256 im = (ia + ib) >> 1;
            uint16 m = data.getUint16(im * chunkLength);

            if (m == label) {
                // Success
                return im;
            }

            if (m < label) {
                // Use the midpoint as new lower bound
                ia = im;
                a = m;
            } else {
                // Use the midpoint as new upper bound
                ib = im;
                b = m;
            }
        }

        revert LabelNotFound(label);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {Attribute, AttributesLib} from "moonbirds-inchain/types/Attribute.sol";
import {Mutators} from "moonbirds-inchain/types/Mutators.sol";

import {Image, Rectangle} from "ethier/utils/Image.sol";
import {RawData} from "ethier/utils/RawData.sol";

import {AssetStorageManager} from "moonbirds-inchain/AssetStorageManager.sol";

import {TraitType} from "moonbirds-inchain/gen/TraitStorageMapping.sol";
import {LayerType} from "moonbirds-inchain/gen/LayerStorageMapping.sol";
import {Features, FeaturesLib} from "moonbirds-inchain/gen/Features.sol";

/**
 * @notice The Moonbirds artwork and attributes assembler.
 * @dev Loads layers or traits from storage based on the provided features and
 * assembles them into the final artwork or list of attributes, respectively.
 */
contract Assembler {
    using RawData for bytes;
    using Image for bytes;
    using AttributesLib for Attribute[];
    using FeaturesLib for Features;

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The handler providing access to stored image layer + trait data.
     */
    AssetStorageManager public immutable assetStorageManger;

    /**
     * @notice The native resolution of Moonbird images (42x42).
     */
    uint32 internal constant _NATIVE_MB_RES = 42;

    // =========================================================================
    //                           Constructor
    // =========================================================================
    constructor(AssetStorageManager assetStorageManger_) {
        assetStorageManger = assetStorageManger_;
    }

    /**
     * @notice Assembles the Moonbird pixel data based on the provided features
     * and mutators.
     * @return Raw pixel data of the moonbird image in row-major, BGR encoding.
     */
    function assembleArtwork(Features memory f, Mutators memory mutators)
        public
        view
        returns (bytes memory)
    {
        f.validate();

        bytes memory canvas = _getBackground(f, mutators.useProofBackground);
        canvas = _addLayerIfPresent(canvas, LayerType.Body, f.body);
        canvas = _addLayerIfPresent(canvas, LayerType.Eyes, f.eyes);
        canvas = _addLayerIfPresent(canvas, LayerType.Beak, f.beak);
        canvas = _addLayerIfPresent(canvas, LayerType.Eyewear, f.eyewear);
        canvas = _addLayerIfPresent(canvas, LayerType.Headwear, f.headwear);
        canvas = _addLayerIfPresent(canvas, LayerType.Outerwear, f.outerwear);

        return canvas;
    }

    /**
     * @notice Assembles the Moonbird pixel data based on the provided features.
     */
    function assembleAttributes(Features memory f)
        public
        view
        returns (Attribute[] memory)
    {
        f.validate();

        Attribute[] memory buffer = AttributesLib.newBuffer();

        if (f.background > 0) {
            buffer.addAttribute(
                "Background",
                assetStorageManger.loadTrait(
                    TraitType.Background,
                    f.background - 1
                )
            );
        }

        if (f.beak > 0) {
            buffer.addAttribute(
                "Beak",
                assetStorageManger.loadTrait(TraitType.Beak, f.beak - 1)
            );
        }

        if (f.body > 0) {
            bytes memory body = bytes(
                assetStorageManger.loadTrait(TraitType.Body, f.body - 1)
            );

            // The feather attribute is stored with the body trait, e.g.
            // "Emperor - Pink". We need to split this for the body and feather
            // attributes.

            bytes memory feathers = body.clone();

            uint256 len = bytes(body).length;
            for (uint256 i; i < len; ++i) {
                if (body[i] == "-") {
                    assembly {
                        mstore(body, sub(i, 1))
                        feathers := add(feathers, add(i, 2))
                        mstore(feathers, sub(len, add(i, 2)))
                    }
                    break;
                }
            }

            buffer.addAttribute("Body", body);
            buffer.addAttribute("Feathers", feathers);
        }

        if (f.eyes > 0) {
            buffer.addAttribute(
                "Eyes",
                assetStorageManger.loadTrait(TraitType.Eyes, f.eyes - 1)
            );
        }

        if (f.eyewear > 0) {
            buffer.addAttribute(
                "Eyewear",
                assetStorageManger.loadTrait(TraitType.Eyewear, f.eyewear - 1)
            );
        }

        if (f.headwear > 0) {
            buffer.addAttribute(
                "Headwear",
                assetStorageManger.loadTrait(TraitType.Headwear, f.headwear - 1)
            );
        }

        if (f.outerwear > 0) {
            buffer.addAttribute(
                "Outerwear",
                assetStorageManger.loadTrait(
                    TraitType.Outerwear,
                    f.outerwear - 1
                )
            );
        }

        return buffer;
    }

    // =========================================================================
    //                            Internals
    // =========================================================================

    /**
     * @notice Initializes a pixel buffer with background data.
     */
    function _getBackground(Features memory f, bool useProofBackground)
        internal
        view
        returns (bytes memory)
    {
        // Load the PROOF background
        if (useProofBackground) {
            // Ignore the alpha info since we know that it will be zero.
            (bytes memory bgrPixelsProof, ) = assetStorageManger
                .loadLayer(LayerType.Special, 0)
                .popByteFront();

            // The layer rectangle information can be ignored for backgrounds
            // because the fill the whole frame.
            (bgrPixelsProof, ) = bgrPixelsProof.popDWORDFront();

            return bgrPixelsProof;
        }

        // Fill with solid color
        if (f.background < 8) {
            bytes memory canvas = new bytes(42 * 42 * 3);
            uint24[8] memory fixedColours = [
                0x000000, // None
                0x99CEFF, // Blue
                0xFF0000, // Glitch Red
                0xCED4D9, // Gray
                0x95DBAD, // Green
                0xFCB5DB, // Pink
                0xABA3FF, // Purple
                0xF5CD71 // Yellow
            ];

            canvas.fill(fixedColours[f.background]);
            return canvas;
        }

        // Load background gradient
        // Ignore the alpha info. See above
        (bytes memory bgrPixels, ) = assetStorageManger
            .loadLayer(LayerType.Gradients, f.background - 8)
            .popByteFront();

        // Ignoring the rectangle info again. See above.
        (bgrPixels, ) = bgrPixels.popDWORDFront();

        return bgrPixels;
    }

    /**
     * @notice Loads a given layer and alpha-blends it with the pixel buffer.
     */
    function _addLayerIfPresent(
        bytes memory canvas,
        LayerType layerType,
        uint8 layerValue
    ) internal view returns (bytes memory) {
        if (layerValue == 0) {
            return canvas;
        }

        (bytes memory data, bytes1 info) = assetStorageManger
            .loadLayer(layerType, layerValue - 1)
            .popByteFront();

        (bytes memory abgrPixels, bytes4 rect_) = data.popDWORDFront();

        bool hasAlpha = uint8(info) > 0;
        if (!hasAlpha) {
            // The full canvas would be overwritten - hence we can just return
            // the new pixels instead.
            return abgrPixels;
        }

        Rectangle memory rect = Rectangle({
            xMin: uint8(bytes1(rect_)),
            yMin: uint8(bytes1(rect_ << 8)),
            xMax: uint8(bytes1(rect_ << 16)),
            yMax: uint8(bytes1(rect_ << 24))
        });

        canvas.alphaBlend(abgrPixels, _NATIVE_MB_RES, rect);
        return canvas;
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {IBucketStorage} from "solidify-contracts/IBucketStorage.sol";
import {Compressed} from "solidify-contracts/Compressed.sol";

import {PublicInflateLibWrapper} from "solidify-contracts/InflateLibWrapper.sol";
import {IndexedBucketLib} from "solidify-contracts/IndexedBucketLib.sol";

import {LayerStorageMapping, LayerType} from "moonbirds-inchain/gen/LayerStorageMapping.sol";
import {LayerStorageDeployer} from "moonbirds-inchain/gen/LayerStorageDeployer.sol";
import {TraitStorageMapping, TraitType} from "moonbirds-inchain/gen/TraitStorageMapping.sol";
import {TraitStorageDeployer} from "moonbirds-inchain/gen/TraitStorageDeployer.sol";

/**
 * @notice Keeps records of all deployed BucketStorages that contain artwork
 * layer or trait data and provides an abstraction layer that allows data to be
 * accessed via (type, index) pairs.
 */
contract AssetStorageManager {
    using IndexedBucketLib for bytes;
    using PublicInflateLibWrapper for Compressed;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Bundle of `BucketStorage`s containing artwork layer data.
     */
    LayerStorageDeployer.Bundle private _layerBundle;

    /**
     * @notice Bundle of `BucketStorage`s containing trait data.
     */
    TraitStorageDeployer.Bundle private _traitBundle;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    /**
     * @dev Intended to be constructed using the bundles returned by the
     * `*StorageDeployer` helper contracts.
     */
    constructor(
        LayerStorageDeployer.Bundle memory layerBundle_,
        TraitStorageDeployer.Bundle memory traitBundle_
    ) {
        _layerBundle = layerBundle_;
        _traitBundle = traitBundle_;
    }

    /**
     * @notice Retrieves a given layer from storage.
     * @dev Uses the generated storage mapping to identify the storage
     * coordinates of the desired (type, index) pair.
     * @return Uncompressed layer BGR pixels.
     */
    function loadLayer(LayerType layerType, uint256 layerID)
        public
        view
        returns (bytes memory)
    {
        LayerStorageMapping.StorageCoordinates
            memory coordinates = LayerStorageMapping.locate(layerType, layerID);

        return
            _layerBundle
                .storages[coordinates.bucket.storageId]
                .getBucket(coordinates.bucket.bucketId)
                .inflate()
                .getField(coordinates.fieldId);
    }

    /**
     * @notice Retrieves a given trait from storage.
     * @dev Uses the generated storage mapping to identify the storage
     * coordinates of the desired (type, index) pair.
     * @return Uncompressed trait string.
     */
    function loadTrait(TraitType traitType, uint256 traitID)
        public
        view
        returns (string memory)
    {
        TraitStorageMapping.StorageCoordinates
            memory coordinates = TraitStorageMapping.locate(traitType, traitID);

        return
            string(
                _traitBundle
                    .storages[coordinates.bucket.storageId]
                    .getBucket(coordinates.bucket.bucketId)
                    .inflate()
                    .getField(coordinates.fieldId)
            );
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @notice Base for moonbirds-related contracts that delegate token-gated
 * actions via EIP712 signatures.
 */
contract MoonbirdAuthBase is EIP712 {
    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if a delegated function is called with invalid signature.
     */
    error NotAuthorised();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The moonbirds contract
     */
    IERC721 private immutable _moonbirds;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Keeps track of addresses that are block from delegation.
     * @dev Delegator => Delegee => BlockFlag
     */
    mapping(address => mapping(address => bool)) private _blocked;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        IERC721 moonbirds,
        string memory name,
        string memory version
    ) EIP712(name, version) {
        _moonbirds = moonbirds;
    }

    // =========================================================================
    //                           External
    // =========================================================================

    /**
     * @notice The EIP712 domain separator of this contract.
     */
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Block future and past authorisations for a given target address.
     */
    function blockAuthorisation(address target, bool toggle) external {
        _blocked[msg.sender][target] = toggle;
    }

    // =========================================================================
    //                           Internal
    // =========================================================================

    /**
     * @notice Checks if a given Authorisation was correctly signed by the
     * moonbird owner.
     * @dev Returns false, if an address is blocked by the Moonbird owner.
     */
    function _isSignedByMoonbirdOwner(
        uint256 tokenId,
        MoonbirdAuthLib.MoonbirdAuthorisation memory auth,
        bytes memory signature
    ) internal view returns (bool) {
        address owner = _moonbirds.ownerOf(tokenId);

        if (_blocked[owner][msg.sender]) {
            return false;
        }

        return
            MoonbirdAuthLib.validate(
                _domainSeparatorV4(),
                auth,
                owner,
                signature
            );
    }

    /**
     * @notice Allows only callers that have been authorised by the moonbird
     * owner.
     * @dev Reverts otherwise.
     */
    modifier onlyMoonbirdOwnerAuthorisedSender(
        uint256 tokenId,
        bytes memory signature
    ) {
        if (
            !_isSignedByMoonbirdOwner(
                tokenId,
                MoonbirdAuthLib.MoonbirdAuthorisation({target: msg.sender}),
                signature
            )
        ) {
            revert NotAuthorised();
        }
        _;
    }
}

/**
 * @notice Helper library to deal with the delegation of token-gated actions.
 */
library MoonbirdAuthLib {
    /**
     * @notice The authorisation struct to be signed by the moonbird owner.
     */
    struct MoonbirdAuthorisation {
        address target;
    }

    /**
     * @notice The authorisation hash
     */
    bytes32 public constant MOONBIRD_AUTHORISATION_HASH =
        keccak256(bytes("MoonbirdAuthorisation(address target)"));

    /**
     * @notice Computes the EIP712 digest that will be signed.
     */
    function digest(bytes32 domainSeparator, MoonbirdAuthorisation memory auth)
        internal
        pure
        returns (bytes32)
    {
        return
            ECDSA.toTypedDataHash(
                domainSeparator,
                keccak256(abi.encode(MOONBIRD_AUTHORISATION_HASH, auth.target))
            );
    }

    /**
     * @notice Checks if a given authorisation struct was correctly signed by a
     * given signer.
     */
    function validate(
        bytes32 domainSeparator,
        MoonbirdAuthorisation memory auth,
        address signer,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = digest(domainSeparator, auth);
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {Base64} from "openzeppelin-contracts/utils/Base64.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {DynamicBuffer} from "ethier/utils/DynamicBuffer.sol";
import {ITokenURIGenerator, IMoonbirds} from "moonbirds/Moonbirds.sol";

import {IFeaturesProvider} from "moonbirds-inchain/types/IFeaturesProvider.sol";
import {Attribute} from "moonbirds-inchain/types/Attribute.sol";
import {Mutators, IMutatorsProvider} from "moonbirds-inchain/types/IMutatorsProvider.sol";

import {BMP} from "ethier/utils/BMP.sol";
import {Image} from "ethier/utils/Image.sol";

import {Assembler} from "moonbirds-inchain/Assembler.sol";
import {ProofBackgroundRegistry} from "moonbirds-inchain/ProofBackgroundRegistry.sol";

import {Features, FeaturesLib} from "moonbirds-inchain/gen/Features.sol";

/**
 * @notice Moonbirds in-chain renderer.
 * @dev The tokenURI falls back to the centralised one if the features of the
 * Moonbird were not yet uploaded to the on-chain registry. After the cutoff
 * date, the missing features will be filled in by PROOF - making the Moonbird
 * collection fully in-chain.
 */
contract MoonbirdsInchainRenderer is
    ITokenURIGenerator,
    Ownable,
    IFeaturesProvider
{
    using FeaturesLib for Features;
    using DynamicBuffer for bytes;
    using Strings for uint256;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the features of a given Moonbird are not registered
     * on-chain yet.
     */
    error NotInchainYet(uint256);

    /**
     * @notice Thrown if a given on-chain scaleup factor is not supported.
     */
    error UnsupportedScalingFactor();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The native resolution of Moonbird images (42x42).
     */
    uint32 internal constant _NATIVE_MB_RES = 42;

    /**
     * @notice Length of the BMP URI prefix (`data:image/bmp;base64,`).
     */
    uint256 internal constant _BMP_URI_PREFIX_LENGTH = 22;

    /**
     * @notice The moonbird token.
     */
    IMoonbirds internal immutable _moonbirds;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The in-chain data assembler.
     */
    Assembler public assembler;

    /**
     * @notice The registry allowing users to store their Moonbird features.
     */
    IFeaturesProvider public userRegistry;

    /**
     * @notice The registry allowing proofers to activate their special
     * background.
     */
    ProofBackgroundRegistry public backgroundRegistry;

    /**
     * @notice The features registry suppplied by PROOF filling in the remaining
     * missing features.
     * @dev This will point to nothing until after the cutoff date.
     */
    IFeaturesProvider public proofRegistry;

    /**
     * @notice The base URL for external links in the metadata (pointing to the
     * nesting site).
     */
    string internal _externalLinkBaseURL;

    /**
     * @notice The fallback base URI pointing to the off-chain renderer.
     * @dev This will no longer be used after the all features are stored on
     * chain.
     */
    string internal _offchainBaseURI;

    /**
     * @notice Factor by which the final image data will be scaled.
     * @dev Although all information is already contained in the image at the
     * native resolution, we scale the images for better appearance on larger
     * screens.
     */
    uint32 internal _bmpScale;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        IMoonbirds moonbirds_,
        IFeaturesProvider userRegistry_,
        ProofBackgroundRegistry backgroundRegistry_,
        Assembler assembler_,
        string memory _offchainBaseURI_
    ) {
        _moonbirds = moonbirds_;
        userRegistry = userRegistry_;
        backgroundRegistry = backgroundRegistry_;
        assembler = assembler_;
        _offchainBaseURI = _offchainBaseURI_;

        _bmpScale = 22;
        _externalLinkBaseURL = "https://proof.xyz/moonbirds/";
    }

    // =========================================================================
    //                           IFeaturesProvider
    // =========================================================================

    /**
     * @notice Checks if the features for a given Moonbird can be found in any
     * registry.
     */
    function hasFeatures(uint256 tokenId) public view returns (bool) {
        if (
            address(userRegistry) != address(0) &&
            userRegistry.hasFeatures(tokenId)
        ) {
            return true;
        }

        if (
            address(proofRegistry) != address(0) &&
            proofRegistry.hasFeatures(tokenId)
        ) {
            return true;
        }

        return false;
    }

    /**
     * @notice Returns the Moonbird features from one of the registries.
     * @dev Reverts if the token is not found in any registry.
     */
    function getFeatures(uint256 tokenId)
        public
        view
        returns (Features memory)
    {
        if (userRegistry.hasFeatures(tokenId)) {
            return userRegistry.getFeatures(tokenId);
        }

        if (address(proofRegistry) == address(0)) {
            revert NotInchainYet(tokenId);
        }

        return proofRegistry.getFeatures(tokenId);
    }

    // =========================================================================
    //                           IMutatorsProvider
    // =========================================================================

    /**
     * @notice Checks if the registry has mutators for a given Moonbird.
     * @dev Always true since the PROOF background registry can always return
     * something.
     */
    function hasMutators(uint256) public pure returns (bool) {
        return true;
    }

    /**
     * @notice Returns the PROOF background mutator for a given Moonbird.
     * @dev Never throws because we can always return zero (i.e. no mutation).
     */
    function getMutators(uint256 tokenId)
        public
        view
        returns (Mutators memory)
    {
        if (address(backgroundRegistry) == address(0)) {
            return Mutators({useProofBackground: false});
        }

        return
            Mutators({
                useProofBackground: backgroundRegistry.usesProofBackground(
                    tokenId
                )
            });
    }

    // =========================================================================
    //                           Token Metadata
    // =========================================================================

    /**
     * @notice Returns the completely on-chain tokenURI if the features of the
     * associated birb have been set in any registy.
     * @dev Falls back to the off-chain tokenURI if no features are set.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (!hasFeatures(tokenId)) {
            return _offchainTokenURI(tokenId);
        }

        Features memory features = getFeatures(tokenId);
        Mutators memory mutators = getMutators(tokenId);

        bytes memory artwork = assembler.assembleArtwork(features, mutators);
        Attribute[] memory attrs = assembler.assembleAttributes(features);

        return _wrapMetadata(tokenId, artwork, attrs);
    }

    // =========================================================================
    //                           Composability
    // =========================================================================

    /**
     * @notice Returns the attributes of a given Moonbird.
     * @dev Intended to be consumed by other contracts for derivatives.
     * @dev Reverts if the Monnbird features cannot be found in any registry.
     */
    function attributes(uint256 tokenId)
        external
        view
        returns (Attribute[] memory)
    {
        Features memory features = getFeatures(tokenId);
        return assembler.assembleAttributes(features);
    }

    /**
     * @notice Returns the raw pixel data of a given Moonbird on the native
     * 42x42 resolution.
     * @dev Intended to be consumed by other contracts for derivatives.
     * @dev Row-major, BGR pixel encoding. The row ordering has been inverted
     * such that the data is directly compatible with the BMP format.
     * @dev Reverts if the Moonbird features cannot be found in any registry.
     */
    function artworkPixels(uint256 tokenId) public view returns (bytes memory) {
        Features memory features = getFeatures(tokenId);
        Mutators memory mutators = getMutators(tokenId);

        return assembler.assembleArtwork(features, mutators);
    }

    /**
     * @notice Returns the BMP data of a given Moonbird on the native
     * 42x42 resolution.
     * @dev Intended to be consumed by other contracts for derivatives.
     * @dev Reverts if the Moonbird features cannot be found in any registry.
     */
    function artworkBMP(uint256 tokenId) external view returns (bytes memory) {
        return BMP.bmp(artworkPixels(tokenId), _NATIVE_MB_RES, _NATIVE_MB_RES);
    }

    /**
     * @notice Computes the MB artwork based on input features and mutators,
     * scales it by a given factor and returns it wrapped as a base64-encoded
     * BMP dataURI.
     * @dev The final resolution is 42 * scaleupFactor.
     */
    function artworkURI(
        Features memory features,
        Mutators memory mutators,
        uint32 scaleupFactor
    ) public view returns (string memory) {
        bytes memory artwork = assembler.assembleArtwork(features, mutators);

        (, uint256 paddedLengthScaled) = BMP.computePadding(
            _NATIVE_MB_RES * scaleupFactor,
            _NATIVE_MB_RES * scaleupFactor
        );

        bytes memory uri = DynamicBuffer.allocate(
            _BMP_URI_PREFIX_LENGTH +
                (4 * (BMP._BMP_HEADER_SIZE + paddedLengthScaled + 2)) /
                3
        );

        _appendArtworkURI(uri, artwork, scaleupFactor);
        return string(uri);
    }

    // =========================================================================
    //                            Steering
    // =========================================================================

    /**
     * @notice Sets the in-chain Moonbird assembler.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setAssembler(Assembler assembler_) external onlyOwner {
        assembler = assembler_;
    }

    /**
     * @notice Sets the Moonbird features registry where holders will store the
     * features of their moonbirds
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setUserRegistry(IFeaturesProvider userRegistry_)
        external
        onlyOwner
    {
        userRegistry = userRegistry_;
    }

    /**
     * @notice Sets the PROOF registry for Moonbird features covering the ones
     * that have not been set by the holders.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setProofRegistry(IFeaturesProvider proofRegistry_)
        external
        onlyOwner
    {
        proofRegistry = proofRegistry_;
    }

    /**
     * @notice Sets the PROOF background registry.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setBackgroundRegistry(ProofBackgroundRegistry backgroundRegistry_)
        external
        onlyOwner
    {
        backgroundRegistry = backgroundRegistry_;
    }

    /**
     * @notice Sets the base URL for external links in the metadata.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setExternalLinkBaseURL(string memory externalLinkBaseURL_)
        external
        onlyOwner
    {
        _externalLinkBaseURL = externalLinkBaseURL_;
    }

    /**
     * @notice Sets the base URI for the off-chain tokenURI fallback.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setOffchainBaseURI(string memory offchainBaseURI_)
        external
        onlyOwner
    {
        _offchainBaseURI = offchainBaseURI_;
    }

    /**
     * @notice Sets the BMP scaleup factor used by the renderer.
     * @dev This is intended for initial setup and can later be locked by
     * renouncing contract ownership.
     */
    function setBmpScale(uint32 bmpScale_) external onlyOwner {
        _bmpScale = bmpScale_;
    }

    // =========================================================================
    //                            Internals
    // =========================================================================

    /**
     * @notice Wraps the metadata into a Marketplace-conforming JSON dataURI.
     */
    // solhint-disable quotes
    function _wrapMetadata(
        uint256 tokenId,
        bytes memory artwork,
        Attribute[] memory attrs
    ) internal view returns (string memory) {
        string memory tokenIdStr = tokenId.toString();

        (, uint256 paddedLengthScaled) = BMP.computePadding(
            _NATIVE_MB_RES * _bmpScale,
            _NATIVE_MB_RES * _bmpScale
        );

        bytes memory uri = DynamicBuffer.allocate(
            _BMP_URI_PREFIX_LENGTH +
                (4 * (BMP._BMP_HEADER_SIZE + paddedLengthScaled + 2)) /
                3 +
                1024
        );

        (bool nesting, , ) = _moonbirds.nestingPeriod(tokenId);

        uri.appendSafe('data:application/json;utf-8,{"name":"');
        uri.appendSafe(
            bytes(string.concat("#", tokenIdStr, nesting ? unicode" 🪺" : ""))
        );

        uri.appendSafe('","external_url":"');
        uri.appendSafe(bytes(string.concat(_externalLinkBaseURL, tokenIdStr)));

        uri.appendSafe('","image":"');
        _appendArtworkURI(uri, artwork, _bmpScale);

        uri.appendSafe('","attributes":[');
        uint256 len = attrs.length;
        for (uint256 i; i < len; ++i) {
            if (i != 0) {
                uri.appendSafe('"},');
            }
            uri.appendSafe('{"trait_type": "');
            uri.appendSafe(bytes(attrs[i].name));
            uri.appendSafe('", "value":"');
            uri.appendSafe(bytes(attrs[i].value));
        }
        uri.appendSafe('"}]}');
        return string(uri);
    }

    /**
     * @notice Scales the artwork and appends it as base64-encoded, BMP URI to
     * a given buffer.
     */
    function _appendArtworkURI(
        bytes memory uri,
        bytes memory artwork,
        uint32 scaleupFactor
    ) internal pure {
        uri.appendSafe("data:image/bmp;base64,");

        if (scaleupFactor == 1) {
            // Don't perform any scaling, just write data as-is.
            uri.appendSafeBase64(
                BMP.bmp(artwork, _NATIVE_MB_RES, _NATIVE_MB_RES),
                false,
                false
            );
            return;
        }

        uint256 scaledImageStride = _NATIVE_MB_RES * 3 * scaleupFactor;
        if (scaledImageStride % 4 > 0) {
            // The following is the cleanest and safest way to append the
            // rescaled and Base64-encoded BMP data to the URI buffer.
            // However, this has the downside that we need to keep an
            // additional copy of the resized data in memory for encoding.
            // Since memory related gas costs scale quadratically in allocated
            // size, this can be quite wasteful.
            uri.appendSafeBase64(
                BMP.bmp(
                    Image.scale(artwork, _NATIVE_MB_RES, 3, scaleupFactor),
                    _NATIVE_MB_RES * scaleupFactor,
                    _NATIVE_MB_RES * scaleupFactor
                ),
                false,
                false
            );
        } else {
            // We optimise this by Base64-encoding the pixel data first and
            // apply the rescaling to that instead. This allows us to write the
            // rescaled data directly to the buffer, thus getting rid of the
            // unnecessary intermediate copy of the scaled dataset.
            // This only works if the rescaled image stride is divisible by 4
            // which will therefore not cause any issues with BMP data padding.
            // Further, both the BMP header and the pixel data length needs to
            // be divisible by 3 (always given in our case). This impliess that
            // the Base64-encoding will not be padded, allowing us to
            // concatenate both base64 strings directly.
            uri.appendSafeBase64(
                BMP.header(
                    _NATIVE_MB_RES * scaleupFactor,
                    _NATIVE_MB_RES * scaleupFactor
                ),
                false,
                false
            );
            Image.appendSafeScaled(
                uri,
                bytes(Base64.encode(artwork)),
                _NATIVE_MB_RES,
                4,
                scaleupFactor
            );
        }
    }

    // solhint-enable quotes

    /**
     * @notice Creates the URL of the off-chain renderer for a given Moonbird.
     */
    function _offchainTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return string.concat(_offchainBaseURI, tokenId.toString());
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IMoonbirds} from "moonbirds/IMoonbirds.sol";

import {MoonbirdAuthBase} from "moonbirds-inchain/MoonbirdAuth.sol";

import {Features, FeaturesLib} from "moonbirds-inchain/gen/Features.sol";

/**
 * @notice Registry that allows Moonbird + PROOF holders to toggle the PROOF
 * background on their Moonbirds.
 */
contract ProofBackgroundRegistry is MoonbirdAuthBase {
    using FeaturesLib for Features;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if somebody else than the Moonbird owner tries to set its
     * background.
     */
    error OnlyMoonbirdOwner();

    /**
     * @notice Thrown if the parameters to set backgrounds for multiple
     * Moonbirds have mismatching lengths.
     */
    error ParameterLengthMismatch();

    // =========================================================================
    //                           Events
    // =========================================================================

    event ProofBackgroundSettingChanged(
        uint256 indexed tokenId,
        bool useProofBackground
    );

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice Entries of the mutator registry.
     */
    struct RegistryEntry {
        // The address that set the entry.
        address proofer;
        // Toggles the PROOF background.
        bool useProofBackground;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The PROOF collective token.
     */
    IERC721 internal immutable _proof;

    /**
     * @notice The moonbird token.
     */
    IMoonbirds internal immutable _moonbirds;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Stores the settings for each moonbird.
     * @dev Enabled backgrounds in the registry do not mean that they will
     * necessarily be shown in the final artwork. See also
     * `_usesProofBackground`.
     */
    mapping(uint256 => RegistryEntry) internal _entries;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(IERC721 proof_, IMoonbirds moonbirds_)
        MoonbirdAuthBase(moonbirds_, "ProofBackgroundRegistry", "1.0")
    {
        _proof = proof_;
        _moonbirds = moonbirds_;
    }

    /**
     * @notice Retrieves the settings for a specific moonbird.
     * @dev Does not check if the token exists. Returns zero as default.
     */
    function getEntry(uint256 tokenId)
        external
        view
        returns (RegistryEntry memory)
    {
        return _entries[tokenId];
    }

    // =========================================================================
    //                           Background activation
    // =========================================================================

    /**
     * @notice Returns if a given Moonbird uses the PROOF background.
     * @dev Next to the stored toggle this also depends on a few other dynamic
     * conditions (see inlined comments below).
     */
    function usesProofBackground(uint256 tokenId) public view returns (bool) {
        RegistryEntry memory entry = _entries[tokenId];
        address owner = _moonbirds.ownerOf(tokenId);

        // Don't show background if the MB was transferred to someone else
        if (owner != entry.proofer) {
            return false;
        }

        // Only show background for nested birds
        (bool nesting, , ) = _moonbirds.nestingPeriod(tokenId);
        if (!nesting) {
            return false;
        }

        // Background is exclusively for PROOF collective holders
        if (_proof.balanceOf(owner) == 0) {
            return false;
        }

        return entry.useProofBackground;
    }

    // =========================================================================
    //                           Background setting
    // =========================================================================

    /**
     * @notice Toggles the PROOF background preference for a given Moonbird.
     * @dev Enabling the background here, does not mean that it will necessarily
     * be shown in the final artwork. See also `_usesProofBackground`.
     * @dev Reverts if the caller is not the Moonbird owner.
     */
    function setProofBackground(uint256 tokenId, bool useProofBackground)
        external
    {
        _setProofBackgroundByOwner(tokenId, useProofBackground);
    }

    /**
     * @notice Convenience function to set the background for multiple moonbirds
     * in a single transaction.
     * @dev See also `setProofBackground`.
     */
    function setMultipleProofBackground(
        uint256[] calldata tokenIds,
        bool[] calldata useProofBackgrounds
    ) external {
        if (tokenIds.length != useProofBackgrounds.length) {
            revert ParameterLengthMismatch();
        }

        for (uint256 i; i < tokenIds.length; ++i) {
            _setProofBackgroundByOwner(tokenIds[i], useProofBackgrounds[i]);
        }
    }

    /**
     * @notice Toggles the PROOF background preference for a given Moonbird via
     * a delegated wallet.
     * @dev The caller has to be authorised by the moonbird owner.
     * @dev See also `setProofBackground`.
     */
    function setProofBackgroundWithSignature(
        uint256 tokenId,
        bool useProofBackground,
        bytes calldata signature
    ) external {
        _setProofBackgroundWithSignature(
            tokenId,
            useProofBackground,
            signature
        );
    }

    /**
     * @notice Convenience function to set the background for multiple moonbirds
     * in a single transaction.
     * @dev See also `setProofBackgroundWithSignature`.
     */
    function setMultipleProofBackgroundWithSignature(
        uint256[] calldata tokenIds,
        bool[] calldata useProofBackgrounds,
        bytes calldata signature
    ) external {
        if (tokenIds.length != useProofBackgrounds.length) {
            revert ParameterLengthMismatch();
        }

        for (uint256 i; i < tokenIds.length; ++i) {
            _setProofBackgroundWithSignature(
                tokenIds[i],
                useProofBackgrounds[i],
                signature
            );
        }
    }

    // =========================================================================
    //                            Internals
    // =========================================================================

    /**
     * @notice Ensures that the caller owns the moonbird before storing the
     * background settings.
     * @dev Reverts otherwise.
     */
    function _setProofBackgroundByOwner(uint256 tokenId, bool toggle) internal {
        address owner = _moonbirds.ownerOf(tokenId);
        if (owner != msg.sender) {
            revert OnlyMoonbirdOwner();
        }

        _entries[tokenId] = RegistryEntry({
            proofer: owner,
            useProofBackground: toggle
        });

        emit ProofBackgroundSettingChanged(tokenId, toggle);
    }

    /**
     * @notice Ensures that the caller is authorised by the moonbirds owner
     * before storing the background settings.
     * @dev Reverts otherwise.
     */
    function _setProofBackgroundWithSignature(
        uint256 tokenId,
        bool toggle,
        bytes calldata signature
    ) internal onlyMoonbirdOwnerAuthorisedSender(tokenId, signature) {
        address owner = _moonbirds.ownerOf(tokenId);

        _entries[tokenId] = RegistryEntry({
            proofer: owner,
            useProofBackground: toggle
        });

        emit ProofBackgroundSettingChanged(tokenId, toggle);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

/**
 * @notice Struct that unambiguously defines the artwork and attributes of a
 * token.
 */
struct Features {
    /// @dev Valid range [0, 11)
    uint8 background;
    /// @dev Valid range [0, 20)
    uint8 beak;
    /// @dev Valid range [0, 113)
    uint8 body;
    /// @dev Valid range [0, 63)
    uint8 eyes;
    /// @dev Valid range [0, 13)
    uint8 eyewear;
    /// @dev Valid range [0, 38)
    uint8 headwear;
    /// @dev Valid range [0, 9)
    uint8 outerwear;
}

/**
 * @notice Enumeration of the fields in the `Features` struct.
 */
enum FeatureType {
    Background,
    Beak,
    Body,
    Eyes,
    Eyewear,
    Headwear,
    Outerwear
}

/**
 * @notice Utility library to work with `Features`
 * @dev This library assumes that `Features` contain <=256 bit of information
 * for efficiency.
 */
library FeaturesLib {
    /**
     * @notice Thrown if the feature validation fails.
     */
    error InvalidFeatures(FeatureType, uint256);

    /**
     * @notice Thrown if a deserialisation from bytes with invalid lenght is
     * attempted.
     */
    error InvalidLength();

    /**
     * @notice The Merkle root of all features
     */
    bytes32 public constant FEATURES_ROOT = hex"f8b43e6d091349677b52df00d4dbec8ac3a71d9a48df3eeece013f20733e8355";

    /**
     * @notice Total number of tokens
     */
    uint16 public constant NUM_TOKENS = 10000;

    /**
     * @notice Number of bytes in the features struct.
     */
    uint8 public constant FEATURES_LENGTH = 7;

    /**
     *  @notice Reverts if the given features are invalid.
     */
    function validate(Features memory features) internal pure {
        if (features.background >= 11) {
            revert InvalidFeatures(FeatureType.Background, features.background);
        }
        if (features.beak >= 20) {
            revert InvalidFeatures(FeatureType.Beak, features.beak);
        }
        if (features.body >= 113) {
            revert InvalidFeatures(FeatureType.Body, features.body);
        }
        if (features.eyes >= 63) {
            revert InvalidFeatures(FeatureType.Eyes, features.eyes);
        }
        if (features.eyewear >= 13) {
            revert InvalidFeatures(FeatureType.Eyewear, features.eyewear);
        }
        if (features.headwear >= 38) {
            revert InvalidFeatures(FeatureType.Headwear, features.headwear);
        }
        if (features.outerwear >= 9) {
            revert InvalidFeatures(FeatureType.Outerwear, features.outerwear);
        }
    }

    /**
     * @notice Serialises given features.
     */
    function serialise(Features memory features) internal pure returns (uint256) {
        uint256 ret;

        ret |= uint256(features.background);
        ret <<= 8;
        ret |= uint256(features.beak);
        ret <<= 8;
        ret |= uint256(features.body);
        ret <<= 8;
        ret |= uint256(features.eyes);
        ret <<= 8;
        ret |= uint256(features.eyewear);
        ret <<= 8;
        ret |= uint256(features.headwear);
        ret <<= 8;
        ret |= uint256(features.outerwear);
        return ret;
    }

    /**
     * @notice Computes the hash of given a feature set together with its
     * tokenId.
     * @dev Used for merkle proofs.
     */
    function hash(Features memory features, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, serialise(features)));
    }

    /**
     * @notice Deserialise features from an unit256.
     */
    function deserialise(uint256 data) internal pure returns (Features memory features) {
        features.outerwear = uint8(data);
        data >>= 8;
        features.headwear = uint8(data);
        data >>= 8;
        features.eyewear = uint8(data);
        data >>= 8;
        features.eyes = uint8(data);
        data >>= 8;
        features.body = uint8(data);
        data >>= 8;
        features.beak = uint8(data);
        data >>= 8;
        features.background = uint8(data);
    }

    /**
     * @notice Deserialise features from a bytes array.
     * @dev Used to deserialise bucket data.
     */
    function deserialise(bytes memory data) internal pure returns (Features memory) {
        if (data.length != 7) {
            revert InvalidLength();
        }

        uint256 data_;
        assembly {
            data_ := shr(200, mload(add(data, 0x20)))
        }

        return deserialise(data_);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import "./storage/LayerBucketStorage0.sol";
import "./storage/LayerBucketStorage1.sol";
import "./storage/LayerBucketStorage2.sol";

library LayerStorageDeployer {
    struct Bundle {
        IBucketStorage[3] storages;
    }

    function deployAsStatic() internal returns (Bundle memory) {
        return Bundle({
            storages: [
                IBucketStorage(new LayerBucketStorage0()),
                IBucketStorage(new LayerBucketStorage1()),
                IBucketStorage(new LayerBucketStorage2())
            ]
        });
    }

    function deployAsDynamic() internal returns (IBucketStorage[] memory bundle) {
        bundle = new IBucketStorage[](3);

        bundle[0] = IBucketStorage(new LayerBucketStorage0());

        bundle[1] = IBucketStorage(new LayerBucketStorage1());

        bundle[2] = IBucketStorage(new LayerBucketStorage2());
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import {BucketCoordinates} from "solidify-contracts/BucketStorageLib.sol";

/**
 * @notice Defines the various types of the lookup.
 */
enum LayerType
/// @dev Valid range [0, 19)
{
    Beak,
    /// @dev Valid range [0, 112)
    Body,
    /// @dev Valid range [0, 62)
    Eyes,
    /// @dev Valid range [0, 12)
    Eyewear,
    /// @dev Valid range [0, 3)
    Gradients,
    /// @dev Valid range [0, 37)
    Headwear,
    /// @dev Valid range [0, 8)
    Outerwear,
    /// @dev Valid range [0, 1)
    Special
}

/**
 * @notice Provides an abstraction layer that allows data to be indexed via
 * (type, index) pairs.
 */
library LayerStorageMapping {
    error InvalidLookup();
    error InvalidLayerType();
    error InvalidLayerIndex(LayerType);

    struct StorageCoordinates {
        BucketCoordinates bucket;
        uint256 fieldId;
    }

    /**
     * @notice Returns the storage coordinates for the given (type, index) pair.
     */
    function locate(LayerType layerType, uint256 index) internal pure returns (StorageCoordinates memory) {
        // See also the definition of `LayerType`.
        uint8[8] memory numLayersPerLayerType = [19, 112, 62, 12, 3, 37, 8, 1];

        if (index >= numLayersPerLayerType[uint256(layerType)]) {
            revert InvalidLayerIndex(layerType);
        }

        // First we need to compute the absolute index of the field that we want
        // to retrieve. This is computed by going over the types in the order
        // that they are defined in `LayerType`
        uint256 fieldIdx;

        for (uint256 i; i < 8; ++i) {
            if (i >= uint256(layerType)) {
                break;
            }
            fieldIdx += numLayersPerLayerType[i];
        }
        fieldIdx += index;

        // Now we need to find the corresponging storage coordinates.
        // The fields in storage follow the same indexing as above if we start
        // our count at the first Bucket of the first BucketStorage. The fields
        // therin will have indices `0.._numFieldsPerBucket(0)[0]`.
        // Then we continue with the second Bucket in the same Storage, and so
        // on. Once we have exhausted all the Buckets in the first Storage, we
        // move on to the next Storage - again starting at the first Bucket.

        StorageCoordinates memory coordinates;

        // With this, it becomes quite easy to find the right coordinates if
        // we know how many fields we have in each BucketStorage ...
        uint8[3] memory numFieldsPerStorage = [64, 81, 109];

        for (uint256 i; i < 3; ++i) {
            uint8 numFields = numFieldsPerStorage[i];
            if (fieldIdx < numFields) {
                coordinates.bucket.storageId = i;
                break;
            }
            fieldIdx -= numFields;
        }

        // ... and Bucket.
        bytes memory numFieldsPerBucket = _numFieldsPerBucket(coordinates.bucket.storageId);
        uint256 numBuckets = numFieldsPerBucket.length;

        for (uint256 i; i < numBuckets; ++i) {
            uint8 numFields = uint8(numFieldsPerBucket[i]);
            if (fieldIdx < numFields) {
                coordinates.bucket.bucketId = i;
                coordinates.fieldId = fieldIdx;
                return coordinates;
            }
            fieldIdx -= numFields;
        }

        revert InvalidLayerType();
    }

    /**
     * @notice Number of fields in each bucket of a given BucketStorage.
     * @dev This has been encoded as `bytes` instead of `uint8[N]` since we
     * cannot return the latter though a common interface without manually
     * converting it to `uint8[]` first.
     */
    function _numFieldsPerBucket(uint256 storageId) private pure returns (bytes memory) {
        if (storageId == 0) {
            return hex"14020202020101010101010202020202020202020101010101010102010101";
        }

        if (storageId == 1) {
            return hex"02010202020202010201020202020202020202020202020202020202020202020202020707";
        }

        if (storageId == 2) {
            return hex"0606060606080a050503010103030304030402020404010302040301";
        }

        revert InvalidLookup();
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import "./storage/TraitBucketStorage0.sol";

library TraitStorageDeployer {
    struct Bundle {
        IBucketStorage[1] storages;
    }

    function deployAsStatic() internal returns (Bundle memory) {
        return Bundle({storages: [IBucketStorage(new TraitBucketStorage0())]});
    }

    function deployAsDynamic() internal returns (IBucketStorage[] memory bundle) {
        bundle = new IBucketStorage[](1);

        bundle[0] = IBucketStorage(new TraitBucketStorage0());
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import {BucketCoordinates} from "solidify-contracts/BucketStorageLib.sol";

/**
 * @notice Defines the various types of the lookup.
 */
enum TraitType
/// @dev Valid range [0, 10)
{
    Background,
    /// @dev Valid range [0, 19)
    Beak,
    /// @dev Valid range [0, 112)
    Body,
    /// @dev Valid range [0, 62)
    Eyes,
    /// @dev Valid range [0, 12)
    Eyewear,
    /// @dev Valid range [0, 37)
    Headwear,
    /// @dev Valid range [0, 8)
    Outerwear
}

/**
 * @notice Provides an abstraction layer that allows data to be indexed via
 * (type, index) pairs.
 */
library TraitStorageMapping {
    error InvalidLookup();
    error InvalidTraitType();
    error InvalidTraitIndex(TraitType);

    struct StorageCoordinates {
        BucketCoordinates bucket;
        uint256 fieldId;
    }

    /**
     * @notice Returns the storage coordinates for the given (type, index) pair.
     */
    function locate(TraitType traitType, uint256 index) internal pure returns (StorageCoordinates memory) {
        // See also the definition of `TraitType`.
        uint8[7] memory numTraitsPerTraitType = [10, 19, 112, 62, 12, 37, 8];

        if (index >= numTraitsPerTraitType[uint256(traitType)]) {
            revert InvalidTraitIndex(traitType);
        }

        // First we need to compute the absolute index of the field that we want
        // to retrieve. This is computed by going over the types in the order
        // that they are defined in `TraitType`
        uint256 fieldIdx;

        for (uint256 i; i < 7; ++i) {
            if (i >= uint256(traitType)) {
                break;
            }
            fieldIdx += numTraitsPerTraitType[i];
        }
        fieldIdx += index;

        // Now we need to find the corresponging storage coordinates.
        // The fields in storage follow the same indexing as above if we start
        // our count at the first Bucket of the first BucketStorage. The fields
        // therin will have indices `0.._numFieldsPerBucket(0)[0]`.
        // Then we continue with the second Bucket in the same Storage, and so
        // on. Once we have exhausted all the Buckets in the first Storage, we
        // move on to the next Storage - again starting at the first Bucket.

        StorageCoordinates memory coordinates;

        // With this, it becomes quite easy to find the right coordinates if
        // we know how many fields we have in each BucketStorage ...
        uint16[1] memory numFieldsPerStorage = [260];

        for (uint256 i; i < 1; ++i) {
            uint16 numFields = numFieldsPerStorage[i];
            if (fieldIdx < numFields) {
                coordinates.bucket.storageId = i;
                break;
            }
            fieldIdx -= numFields;
        }

        // ... and Bucket.
        bytes memory numFieldsPerBucket = _numFieldsPerBucket(coordinates.bucket.storageId);
        uint256 numBuckets = numFieldsPerBucket.length;

        for (uint256 i; i < numBuckets; ++i) {
            uint8 numFields = uint8(numFieldsPerBucket[i]);
            if (fieldIdx < numFields) {
                coordinates.bucket.bucketId = i;
                coordinates.fieldId = fieldIdx;
                return coordinates;
            }
            fieldIdx -= numFields;
        }

        revert InvalidTraitType();
    }

    /**
     * @notice Number of fields in each bucket of a given BucketStorage.
     * @dev This has been encoded as `bytes` instead of `uint8[N]` since we
     * cannot return the latter though a common interface without manually
     * converting it to `uint8[]` first.
     */
    function _numFieldsPerBucket(uint256 storageId) private pure returns (bytes memory) {
        if (storageId == 0) {
            return hex"0a13703e0c2508";
        }

        revert InvalidLookup();
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import {IBucketStorage, Compressed} from "solidify-contracts/IBucketStorage.sol";

/**
 * @notice Stores a list of compressed buckets in contract code.
 */
contract LayerBucketStorage0 is IBucketStorage {
    /**
     * @notice Returns number of buckets stored in this contract.
     */
    function numBuckets() external pure returns (uint256) {
        return 31;
    }

    /**
     * @notice Returns the number of fields stored in this contract.
     */
    function numFields() external pure returns (uint256) {
        return 64;
    }

    /**
     * @notice Returns number of fields in each bucket in this storge.
     */
    function numFieldsPerBucket() external pure returns (uint256[] memory) {
        bytes memory num_ = hex"14020202020101010101010202020202020202020101010101010102010101";

        uint256[] memory num = new uint[](31);
        for (uint256 i; i < 31;) {
            num[i] = uint8(num_[i]);
            unchecked {
                ++i;
            }
        }
        return num;
    }

    /**
     * @notice Returns the bucket with a given index.
     * @dev Reverts if the index is out-of-bounds.
     */
    function getBucket(uint256 idx) external pure returns (Compressed memory) {
        if (idx == 0) {
            return Compressed({
                uncompressedSize: 5860,
                data: hex"e4984d68134114c767db26312aeaa59434422e0abde462bf09828752505cac05c9c59ba0a2222222288810e9a597a2878007a1a02741281404f5e051102f7a118c5fa094484e1efc8a29233bbb6ff6cdcbccee6c120ba50b8fecfbcfbcf77bb3fde783b211f6c439e2d4fa2ef4adf75fefff357065e07bea626a35f53b7d305d49bfc8eccc1ccf5433356770dbf06e165c9c4d5f62e8f272ce9639d67ded4b0b3458f7355f0feb0c5a8337c37a58f37375a0427e4819a8901fe2e5a387b12eb4f3674e81e6622dd0659d495b5aac40bd5c0b7275a0dc585519283756e5f9b36fb12eb4f9a59fa0b9580b745967d22e3ffb0bf5722dc8d5816626279481662627f88dabe7b02eb4fbf76e8306eb420b745967d21a6b35590f6b41ae0e345e2a29038d974afcceea63ac0bedf9fb8fa055b016e8b2cea47dfed3847ab916e4ce6036cad460586a60306cb706ce9a0dec228329f989f9638a3121d7699166cd9acdea2233293998ae6b6366cdc6749171941c0cd6b509b36613bac8244a0e66eada70db73bbf8699617b132eb0fb132ebc7c3e103bcbee79608b8e75375b1874fd5f9b745ee37d9910b4fb0ce7fc0ab17a3cde61cbe775bad39ba4736e1271f31117dbef3bd57117bdf0cc87b6ffd69eb13dd1336115e0f3ffc439f93f78377913db2898b3caef895fa5ae3e9f626d477d49f1a6fb637a1fea13e5bfbf08aee41cf84bdf6c329fbe775ca228ac5a6bcf7d6175e72baa77d126a266a3a8de1449334db5ff03b33c68b23fbb471687ab427e1f562edd7a6642fdcbc266323d9986bc3ef055bc7b499a11bb60d338a9f94ad639a66c44167307023f95097d4f7ba1e49d9bd788f419f4ece8de3ddd7867558fcad23d977971f24e299c2eb9384dd2b2ec466607bdc2dc256f85b959d840ffbe2f62661c7f1610deabc88e227659bde6b9889f782d601dbc8d7714d9ff53003e176cca6e78afb8e81bda4ce8a6d7a96365cca4761cda6d1c9776a82731b99361cf827801750ab7906566cd3ef2e3a8f8e69fa8d69e05b313b8918be919bc027b1cf92f0590cb39757dbf970fe9f98da19307b0398ba67f02f0000ffff"
            });
        }

        if (idx == 1) {
            return Compressed({
                uncompressedSize: 7702,
                data: hex"e4d7af4e43311406f092101c21b96a8e19d4040a4f824501090633c70390b077404ee110b33c04af8044e378884b2a4e393b3b5f7b4ed7dd70b3259fd86edbdf6977ff351c9e1c1f1c85b3d31042e8e7b3ae5fde9eabf97cbe6a9238d67cd605f119a5dd7fdca70c6973d7e2b7b035d352c336b6c5ccf95e5b33518d3cb206e0667deae73defb531bc768b6b8cc6a99937cfd7f78f3986ff3a6bbfbead5c1e4a1cc763b7722963b0a3bb27f69abfafb6c7a776a5b61ebbe4d3b1d88792f3bd36bad6b8c9dbd26f1536f43517ddeba906e156db725ea5670cb515fd4c365a4b8b2b7d16b32d53f34c75cc1b9a16a75fdda4505f650d4c367aef92f568267ac704bec9ac49c187aee33c29aea5f0d3316086869f8df9f1ef3b32d51ab83d80a9adc1df46b89b4cfb8bcb3b35d70f8b2689637593e9463163b49f5ede5386b4b96bf15bd89a69a9611bdb62e67cafad99a8461e590370b33ef5f39ef7da185ebbc53546e3d4cc9bc7f3526ef8afb376cb8db0c76ebd391983bd8b4dd93fb5d7fc7db53dbe7523ecb14b3e1d8b7d2839df6ba36b8d9bbc2dfd5661435f73d1bd9e6a106eb52de7557ac6505bd1cf64a3b5b4b8d26731db3235cf54c7bca169711e17cb14eaabac81c946ef5db21ecd44ef98c037993529f8d0759c27c5b5147e3a06cca69b40393ffe7d47a65a03b70730b535f80d0000ffff"
            });
        }

        if (idx == 2) {
            return Compressed({
                uncompressedSize: 7702,
                data: hex"e4d7bf4a7b311407f0fce0879b387668a19343f1191c05b1f4293a083a0b2e2e8e2eaeba8938b8fb2e0e8ee2e64354329c787a7abec939697af1720bdfa1bd493e27e9fd97f0ff60ffdf5e389c8610c26a3a1eade6a7276a2ecf974d12c79a8e47417c7a69bf3e3fa4746973d7e2b7b035d352c336b6c5ccf95e5b33518d3cb206e0667deae73defb531bc768b6b8cc6a99937cfc7d7b73986ff3a6b3f3ebdb83c94388ec76ee552fa60477720f69a3f54dbe353bb525b8f5df2e958ec43c9f95e1b5d6bdce46de9b70a1bfa9a8beef5548370ab6d39afd23386da8a7e261bada5c5953e8bd996a979a63ae60d4d8b737f779b427d953530d9e8bd4bd6a399e81d13f826b326051fba8ef3a4b896c24fc780191a7e36e6c7bfefc8546be07607a6b606bf1be1d962b23abb395273f176dc2471acd962b2514c1fedebcf654a9736772d7e0b5b332d356c635bcc9cefb53513d5c8236b006ed6a77edef35e1bc36bb7b8c6689c9a79f3785eca0dff75d66eb911f6d8ad37277db077b129fba3f69a3f54dbe35b37c21ebbe4d3b1d88792f3bd36bad6b8c9dbd26f1536f43517ddeba906e156db725ea5670cb515fd4c365a4b8b2b7d16b32d53f34c75cc1b9a16e7ea7d9e427d953530d9e8bd4bd6a399e81d13f826b326051fba8ef3a4b896c24fc780d9741328e7c7bfefc8546be07607a6b6063f010000ffff"
            });
        }

        if (idx == 3) {
            return Compressed({
                uncompressedSize: 7702,
                data: hex"e4d73d4e033110056023213a446e80148932e7e00a5b50d0908b5021d151d1208a74dc800bd053224aba1c0041c1221763269379f68ce3ac586da457246bfb1b3bfbe77078727c7014ce4e4308a1efe65dbfba58a9595faf9b248ed5cdbb203ea3b4bf5e7e5286b4b96bf15bd89a69a96117db62e67cafad99a8461e590370b33ef5f39ef7da185ebbc53546e3d4cc9be7edc31ec37f9db5ef1f572e0f258ee3b15bb99431d8d19d88bde14fd5f6f8d4aed4d663977c3a16fb5072bed746d71a37795bfaadc286bee6a27b3dd520dc6a5bceabf48ca1b6a29fc9466b6971a5cf62b6656a9ea98e7943d3e27c3ef529d4575903938ddebb643d9a89de31816f326b52f0a1eb384f8a6b29fc740c98a1e1676b7efcfb9e4cb5066e0f606a6bf0b7115ece16fdddf9a59ad7ab9b2689632d678bad62c668f70fef2943dadcb5f82d6ccdb4d4b08b6d3173bed7d64c54238fac01b8599ffa79cf7b6d0cafdde21aa3716ae6cde3792937fcd759bbe546d863b7de9c8cc1dec7a6ec9fda1bfe546d8f6fdd087bec924fc7621f4acef7dae85ae3266f4bbf55d8d0d75c74afa71a845b6dcb79959e31d456f433d9682d2daef459ccb64ccd33d5316f685a9cefdbe714eaabac81c946ef5db21ecd44ef98c037993529f8d0759c27c5b5147e3a06cca69b40393ffe7d4fa65a03b70730b535f80d0000ffff"
            });
        }

        if (idx == 4) {
            return Compressed({
                uncompressedSize: 7702,
                data: hex"e4d7b14a33411007f0fde0c34e84e401ac6c6d7c033b1f214f2084b4c167d12228e40df22c22da05c426b56077b2c59c93c9fc6f67369383e316fe4572bbfb9bddbbcb5dd2ff8bf37f67e9ea32a5949ac974d6dc5cafd4dcdd6e4392e79a4c6749b441da0f4f3f6dfab4b96bf1236ccdb4d4708c6d31bb7cafad99a8461e5903703b7d1ae7bdeeb539bc76c43d46f3d4ac9be7e373678ee15c77da8fcf6b978792e7f1d8512e650876764762eff963b53d3ef52bf5f5d8259f8ee531942edf6ba37b8d9bbc2f7d5761435f73d16f3dd520dc6a5baeabf48ca1be629cc9467b6971a5cf62b6656a9ea98e7543d3e22ceebfdbd058650f4c367aef92f568267ac704bec9ac49c187aee33a29eea5f0db63c04c81ed607dfcf3894cb5066ef7606a7bf0f74778b99837eb97959addd7362479aee5627e50cc106ddefab4b5766adbd2a26d6f3bd6d64c54238fac01b89d3e8df35ef7da1c5e3be21ea3796ad6edbdceb4f35d636f369b26a2bdbfbdbaecdc3fb20dc1ceee48ec3d7facb6c7cff72125ca2ef9e4e531942edf6ba37b8d9bbc2f7d5761435f73d16f3dd520dc6a5baeabf48ca1be629cc9467b6971a5cf62b6656a9ea98e7543d3e228e757db03938ddebb643d9a899efdc037993529f8d0755c27c5bd147e7b0c98a17f02e5faf8e713996a0ddceec1d4f6e0370000ffff"
            });
        }

        if (idx == 5) {
            return Compressed({
                uncompressedSize: 5483,
                data: hex"cc97bf4a3b4110c7f7f7d32af80042ac0ca2560a07daa7d117d0cef61a6bc167b0f2110229520b62a320a4b012248d8d8dbd5858598ecc2673cc4d66f7f6cf25e460b83d73ce7cee3bb3b3bbe6ffbf35b3b763d8058fdd53806200a5e95676dfdbadc60f1b47d1f6bc7d0cdfd75b00e32b7bc767f4f555da78a6e19a3295931ad393b99c6382e20e5e37cfe7e2bff7ce9c6cc843e31c26d4e8c38c2badc827f1f038217aa532fddc8065407d90e7f70dec1d9f5f0e8a6006dfbb8bd0491abe23ff86df90903b189e84d75368dd9046c8e9d22a5a27c7bc0bcd5753ce2378bc5cc484f3596391baf9740a60d2f3e76092be7da6f79041b64ef8fddc2f8f897ef1bd392b27d670fed258fa682b77e48b2ca697132ff9c1712c13c6d47852d6168d2d4527c984cfb7eb87d94c64a94c3867dad4c8c304c34e11a553db1a0926e481cffd8b28ae18a6d0353952a72ca6d0b527b29e54a6d0b5a5a9cf6ab90b64536bca1743eb5f2e2ed43c4027994f673fd034e02c5a7fc53172706b5ceff4ba7772c9f83e4df8effc7f658d2b79d4eabec6c4d73d4d07beb795734f722b4c361ef447596b8ce469ea03093a7999a4c91c696725574fa05acaed05bef9c6fb96d489d7335f9b12b96a4cda37f37834467de4dce2bf73fe482e958773a0f13d478c71b640ae1a0f9d8f24c76c3f96649a761ea66a7fc9bfc3b2ccf6afccb749bc9c6caeb31e672216dc53677234b28530d13e7f012cda99c9575332f76649574ccc907d564cdc55f2d34e8e3bc5b4b6fa237b77e825cfcfcbcab359b12bb79e7274fc0b0000ffff"
            });
        }

        if (idx == 6) {
            return Compressed({
                uncompressedSize: 5631,
                data: hex"ec97a14e343110c7fb9dfe2e3cc0624938411097e0ce603885c023d967203c0286572041e01124e4d49dc04042d0183c41a0c095fc0bb3999b6dbbedb67bdc119a4c9aed75bb3ffe339d1954ef5f4f6d6e2831f4b43fd22fa5d2a52a6a76fd7f27c9aed49199e93c7c67da1fa98061b8f4f0bc7a17cf9c0bcfe61bfbcaf97dda03bbdd1ed67ecfc125f5ba2b4aa70ed2c0f47abc5e63eb82eb49cddc7eb2682899b027950b3ad019d0094cef0fdacc78e6fe92e6e36fcd553e46ebe5f265d75c74a68c2f1bbfeddd86bb88dfe6382ef6ec6c6fa7daca45bea3f58f13adf570f6656b6795dd1fa8caf819162eb3fe3c38946c8d9af178a6356209f19be40bd02bd897c4447a84f0c858e47c11b1d5982bc063cbfdbe1cebd22f950b7f336619272996532fe24a65cac9959329804b4f8ab1938bf7140be66ad48cd87e0357c8dd68c145be8df625cf25c8b73ebe5c7a35b171265af3b1c93a64a985415cd4b3524eb4d566ce443514b5d3b637a68f70d56fae99ac2764c47433d8aaf51c555d67351d39a8850fbdbe6c5317b965e0f2b2c93e10fb427ada0c4cad7573e9851e2513538dcdc747dac89e163d66074c736c9ccf7627381f58be796c4cae3a98cc2719113bdc1c3c8b18738cc2627ae41f61cfe0afaa3ee6380b313629c65aef5e9a3951379cb3aa7a45d5da258daf55e20dfd1ffb4faf25d225e28ed0f80c0000ffff"
            });
        }

        if (idx == 7) {
            return Compressed({
                uncompressedSize: 5935,
                data: hex"d498af8e144110c69b0b8a9080e6f0808230c9291406cef0064826e10de0013018b0e7363941825c8141905c08969c058307040a59e4eb494dbaabab7afacf2c0b9354fa6632d3fddbafaaabaacf1d5c3870376f3871d1fbc38744e3398dee903eba133fb26d1f397a77f928b14fee88c83da7df9fc98fb8d7de63e3f968d8603d577079ae5f2fc933fd38a1884dce0f86dcbd34ccc5a3e71acfabb82cbd667d6e0fa66ef2d987abf7a27bfcd659af462e69ccf4f3d9f5884dae0dd37cdeadd7b04998b6eec9a25ea5d61a5f1a97165fe11a4b56c845a70fcab8e0a3dcdc395d428d25678556261bfc96f855c48fb617bfbab3b57c38737d1fdd3c07e2bc441fd8db6b77bd4e60423ec3887b3c0fb9307f8b5ef88ef71e7d791aed41b9ff427f95ead5c325f5aadd77212fff1683ab8431e1e2f8aa6182dfd877bbd2ab34b66a72d77fc8e5d757f2583397568f56d4cb64fb0b7ad1e9a561675c5abc17708189bedd7a9c63abf665495ddc855ec845b9b568389beccaabd9f8fb052eab566b79cdd44b33f04c7dd571c26ccdd118f72a1be2c662b2ea8ee6e30ea645cde23ef4d833a147c6a8e9b6428e48b8644db2625fea256b626b9e177b21d2cbeaedc33e4cea24793aea4f964bf6f6cbfb61e30d73bcbe78c7e7278c85bd847fdff7a8f7df4cb569d22de2dabe7066df89730d0ce74efe1bcfc1c08635f09dc255a357c414d63da905deb38c63b3972b882fd5871c1f01cfe2bee179c0c3f334b0995c41cc36f74dcc86b1e13ca4e6ae0eed13b60eae84ad824beb0b22ae0ea61e2e532fdea39d5cbd6c3a53f9ff4aaaea512b17e7362577979ed3b27bbe952bf32df2b95bf1caf573b5b9bc2776ff85abe40cb04fb67dadfd270000ffff"
            });
        }

        if (idx == 8) {
            return Compressed({
                uncompressedSize: 5607,
                data: hex"e497bf4a3b4110c7f7f7d32af806b1529458291c689f465fc0d2f61ab1147c062b5bbb408abc81850a420a5b49636363af1656962bdf357b4c7667f6cf5d2227090c7b97cbed7cf63b33bb13f5ffdf8adaee29f2d177dd23fd562a5daaae68376bfb5986395fd458bf5f6b33e21ef37c5e6a5c2be1637ea78bc18cefe7cde3ea7ab0d5f37c7d5cac7bbe392670d86bcca5cb49360bb57b759aad0bc7d894059a606d9c3674cd2966588a41360b7c430ff8fb7afa8939ee1f770bcfc7c3c641758dd8366629275e9e847449c973973b9725942ff43bd49d641c97c3e18e1e0feacdce8135b94cd45f282f242e4713adfb23511bcac231d0bce0f285ab6bca843155172e4e5403774fc931cb24f876c78a053e2907d68deff4f8dc8c923e293c42ded2787975cde544135d022cbc2e1196ba7a24e822ee77b13a59229699dee11759f4f0b0352c515d1615a73fc2a2879d22d86bce9b47da5f869d42bfee9c883ce81d2c57687eda4f497d262cd62b381ca23629fd37ce55e9d9d5ea9e7746a7ee33d6bfed1bb8dab27d12ce30d8ad3a33a3ab0fde8b6892c422f50e98db9a1b2bc3469edbfb1a2c2c8fdbd3517da007ed89716f6232d50bd719b59cc4e2f645f0410d1c96c1e68e7d362f16370769ff38138b693cf01bfa9f2093c53b235c16dbb74ce70c1a98288fc3d2288773f608ca823a0b68c2ed27d1791339581e8185db67a5f39ae51158c4f846f2244717efff41469c2b9e9ab59393db8b7a67993fb11cadf35e9ddc5bd8fa5a900f666f30b5d51f99b105fab4a94ee6a9c777000000ffff"
            });
        }

        if (idx == 9) {
            return Compressed({
                uncompressedSize: 5483,
                data: hex"ec97a16e1b411086b72dabda27b816566a890b2c959598d8a0af50d893ca0afb0c7e83b048060e0e08314a14850444a609094f02820227fa2f9ed3dc78766ff776ad0464a5d1e56e9dddeffefd7776cebd7df3ce7dfde244a35535a39bdad1e9e75f54bbaa13e83baf6aba722774bb47cd15f7787ef4e1c7561cb87fe67304c6c33cab6ae67a5acba47938301e7e031ecd72f7ff9397e1ecfbb82813c6934c08e8e39bdf0acd9bca44e3fda04eac550c0bde073c74f9b7b9b25ebb600a05bc98a1132da67e268c633185bcdbe727e62da5936ffff445c69ef372e15e8fcd7df81dc60f85668b60b2d7af5eb76361dff398920511b36e9a6db04ef5bacd439c1ff9b966d1b9c7e777c93684e97e4e5b3a8127d5db21dd86e824fd04c6123c922b87a9a446594c62df95e6319868f17e9cc614b9bf06328187aebffd4ee24a650aedc3813a6533edc04f66cd82bffbe64939b3e5da45b29975948f4bf6cb609d07eaa4d7d35b6f4a2ecd62e9647145e44c9fef835ca13396e3f8e3cfe6cae791fe3fe971631d2ddf6f31c91a98d9348b3cdf0edd9f4e1fe7398f4e449365949f7c67bac5a335c239c95ab55c9b7a2242a7204f68ad742e0203f401cfc3c5533d817b1f5bca778bc521bff99887e62333477a759a8f52f65f8727947364bd1fcad9eca7bebc1ec3155a3bcb43f29b41ceef5b2fe9a9847cdeb2e9d08c7db91d7557930b3675ab112eb379193b1a6c18c053706e8b2549cfc21c317543b9b9a6599a3c476bcebda66e9a2c9b6b41bd72dff325e994eaa7582fbcb6dde9f8180000ffff"
            });
        }

        if (idx == 10) {
            return Compressed({
                uncompressedSize: 5335,
                data: hex"ec97314bc34014c79f1da520ce751104717208b8884b1775d14fe0e060369df52bb8b8daade0d0bd83833a497112a4e0e6d20fa08393e3c93fcdc5cbddbd7b49136c4003c7993479f7bbdfbb9c2fd45a68d1fa1a5987baefeca9c931a9983a4ebb6d6f05dbc3593bf8fbf3ea4ef637e27d5e2a8c47c291631ad28997e9693312f97c4dd1458e49c5e3d24c453d99f3e77e07cfd78b4a7a9c5765829710d31d9d3ad7aeb797654f517f2626f07c9caf64f91ad1bee3e08d1e83aef43ab3d7d3ac4c9c27c4871ff02027e8712ee5b12e26692d719ef08e54e4097285e6ec5b4f9223c44f99ecbe1626d3d1f080bcf7604d324cc998aa3ba8e4891bd76ec8690d9e129eb29eca368fa7dad7d33c98b8f7e7df53e398bc5c45c62a5a2f94605237bbd59874c3734df164f284b898fda9494cfe9c2d462213b72767b5d1d295c3c171094ce051938d23932bdbcbf1bfdbf6e4abb911df37fe2b1d7aafa73cba499e3216cda3e3d8b55ce627eab3ee46d46399f53529879c1b737cbbf958e0073cef3d95f4380fe592e19af2c4638705e372b991ea37ed298b158fd9b9d8b58bc9633e97d682b95a416233eb24ed07df71e9374a6eaddaf3b5f607ef73964f874de243bcf4bb928d65c7349902ef005b63e958ce3a83eb9ff9958d59e4dec27c01c77ff9f0edff7367aa213f662d52d5cff47dee0e92be41be9ab08e6dcf9c9fb275d1aff10bdfb5f3cae9ac9ebe030000ffff"
            });
        }

        if (idx == 11) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ecd6a14a45411006e0150483cd6a1383206230d904df409f400c0631fb20269be13e91d12c1683c9bcb2d73bb26798d9f97767bd170ebbf09703733e36eccc84eddd87ad9d70b01f4308f1e4e850ccc5f95997a47f256758c3aab5b41a2b8a4347f424e3f9656186d7a39664bcbd7f16c34dc4aa354aa665b51a9259b23cf7e1f9f8fa862caf43d1acdece06ad8937578bbc7559a8477dc86b591eefb1e05b86bcf42629daecc8df2f25c8a76abee4b9bfbb5d469a0d413fe67cd19cdc029c26cfe14c3c6e4a0effb6aa6b3991bbdafd1c86e9b220e777d1be39de8b4fd7a7625e1f2fbb24fd2b39c31a56ada5d558519cbfc7237992812cdabc1eb524035d7af37f5956ad51322dabe7a25db27a2fda88d56b99d2acff581237644dbcb95ae4adcb423dea435ecbf2788f05df32e4e5cbb3363ba4455b708a7dd19a4f7171b58c341b140b9a2f9a935b80d3e4399c89c74dc9e1df56754d0b2f99e46af77318a6cb82d4ff040000ffff"
            });
        }

        if (idx == 12) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ecd6a14b05411006f0130483cda2f082e2ff60b7088246a3cda020f6978d1683c966f0af328bc560329fecf3e6b1377cb3f3ddeebef7e0b883af1cccfed8b033d36cef3e6ced34c7b376efe0a83d39bd82b9bc9e5749382b38933559432dabc68be134dd073d64bcbebdbbd1f5ac858c8fcfef64b4c958438d94e959b906325356c97d74be7e7e29abd49158566d678356cf1bab25deba2cd6933e546a799eeeb1e45ba6bcf02625d6ec88dfaf0438c9bee8cda7bbf9cb2268361816355f2c27b60827cb2b707a9e3691a3ff75754dc6b734c5b5ee5760b8ae0a53ffbf681fcef6db8bf33398fbdb9b2a09670567b2266ba865d578319ce5e3411e3298455bd7b31632d8a5373ecbb3861a29d3b36a2eda29abf6a2cd58b59629cb5ac592b821abe78dd5126f5d16eb491f2ab53c4ff758f22d535ebc3c5bb3032ddac049f6456f3e3d3f3d2e8266836151f3c572628b70b2bc02a7e7691339fa5f5797b5f08a29ae75bf02c3755598fabf000000ffff"
            });
        }

        if (idx == 13) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ecd6314ac5401006e008828547d0ea75e219bc8062ff0a4f20585a5a790a3b8b7496dec5c25a6c52588965649f99c766f867e7cfeefa1e8404fe2630fbb1c5ce4c73787c7770d4ac4efab3ebd3fef2e11ce6f6f5a24ac259c159acc59a6a59355e0ca7193ee821e3e9b975a3eb590b19ef1f5d32da64aca946caf4ac5c039929abe43e3a9f5fdf9455ea482cabb6b3476be4cdd5126f5716eb491f2ab53c4ff758f22d535e7893126b76c4ef57029c645ff4e6d3fddbd52668361816355f2c27b60827cb2b70469e3691a3ff0d754dc6b735c5b5ee5760b8ae0a53ffb768af57ebbebd6961bac7ae4ac259c159acc59a6a59355e0c67fb7890870c66d1d6f5ac850c76e98dcff2aca946caf4ac9a8b76caaabd683356ad65cab2fe6349dc9335f2e66a89b72b8bf5a40f955a9ea77b2cf996292f5e9eadd981166de024fba2379f7e5efa4dd06c302c6abe584e6c114e9657e08c3c6d2247ff1beab2165e31c5b5ee5760b8ae0a53ff1b0000ffff"
            });
        }

        if (idx == 14) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ecd6a14a05411406e01504834534daec5a7c038bf808368b5af441049bc922069fc2c730da04b1184cb75856e6bae7327bf8cf9c7f67e6de0bcb2efc65e1ccc78439e7349bdbb71b5bcdc17e7bb573d83e9c5ec0bc5dde5549382b38933559432dabc68be134dd073d643c3ebfb8d1f5ac858cf7cfef64b4c958438d94e959b906325356c97d74be7e669455ea482cabb6b346abe78dd5126f5516eb491f2ab53c4ff758f22d535e7893126b76c4ef57029c645ff4e6d3effdeb3c68361816355f2c27b60827cb2b707a9e3691a3ff75754dc6b730c5b5ee5760b8ae0a53ffbf68efee9db7c7474f3067271f5512ce0ace644dd650cbaaf162388bc7833c64308bb6ae672d64b04b6f7c96670d3552a667d55cb45356ed459bb16a2d5396b58c25714d56cf1bab25deaa2cd6933e546a799eeeb1e45ba6bc7879b666075ab48193ec8bde7cbab99ecd8366836151f3c572628b70b2bc02a7e7691339fa5f5797b5f08a29ae75bf02c3755598fabf000000ffff"
            });
        }

        if (idx == 15) {
            return Compressed({
                uncompressedSize: 6602,
                data: hex"ecd73d4ac5401007f008828547b07b58d85859d979170bc18fd293d8593c10bcc1bb892022d86861e3212203d9908cf3f1df99451f9285695e76f6e70ceb6ed2edeedfecec75ab83fef6fab27f7c588bf1f5f9de24682d72166bb16a2d2dc70bc5e986217a92f1faf2ec06cf472dc9f0063711abd6b04ccf8a1a926959997aa48158ad8666b576fed09a79ffd52ade6f59a857cea1ace579fc8cd5c666b3e15695a7dd1d404deeb9e8dd4fd2df209cbb908738530b70425ec29979dc941cfedb90d705c6681657ab2f61b82e0b249f5eb4573d2d747c7428c6d9e9c9185717e75531cda5b5c8412dd49472a296665a73b3564d6cbba5cd43f22c4b326aea28f30767fce7b16acbf4b2e4239694fff4f66146c4aa3534336221aeb107c396e439fb7db1da59a2b74dd6ddfd7a1619cbf3e87971acb9a8557b5fb6b6ac7b517a2658d019ecddbfce5918ee630b6bea45ef12aadf70667565ee7b72ca3a19cb7b5fe36b783db48c699f7918ef19504dcce8bc9e50f0bd8a58a021aee3783ffa97f9d0e09e65b5f8b029eb0dfd519fb7b482cf437d4cce69e1f0fd9bb284dfbf030000ffff"
            });
        }

        if (idx == 16) {
            return Compressed({
                uncompressedSize: 7358,
                data: hex"ecd7af4efc401007f0fe925f82439c4292b308149e048b0224e61c6fc0bd471d02c513a151bc48c94277b3ddce7ee7afa83892519d994f6633747bc3fff3c3bfb361bf9f0e57bb697cbc26e3f3f5aec4f4f1a08aba36f54a8ed4929a548dd5ea9928d76b6962eb562f4f52872ccad0cc91f3676798ffe06c9eb3ccf5128becf1f58dc360a98d8e69b2246e7f07ed16e5e17d3f597116e96dc91adfde17e1b138ef37275b20576a69efcb680bdd8bd433c212bd83b9fb9779179acf31c2aa3deb5d92e607ce622ecf7d9f9cdcc76371df6bf5b980bd281632722f2ac0778668a6c618c05f31db5d95584283ecc378abf3531ad04396c359f59bcfa7fb3cd2e2f630caeacca4c98970dafd755944fddf8fcbddc5e57473fb44c6fdf3b1c4cb7154455d9b7a25476a494daac66af54c94ebb534b175ab9727a943166568e6c8f9b353fe29d06c9eb3ccf5128baae77ee8592cadd1332d96c4053b68b6288fd9f793156791de96acf6c7a5c7e2bcf43c3b28576a69efcb680bdd8bd433c212bd83b9fb9779179acf31c2aa3deb5d92e607ce622ecf7d9f9cdcc76371df6bf5b980bd281632722f2ac0778668a6c6801fd7d96c775562090db20fe3adce4f69400f590e67d56f3e9feef3488bdbc328ab33932627c269f7d76511f53f010000ffff"
            });
        }

        if (idx == 17) {
            return Compressed({
                uncompressedSize: 7358,
                data: hex"ecd73f4a3d311007f0fdc10fec6c2d1484d78967b014c48787100b416b4b1b4b1b0b3b0b2fe14d2cacacbcc84a7013b2d9c977fe165bbc075325930f13e6edec0efff7afffed0d9bcd787c78306e2fcec9b8bfbd29f1f2fca48a3a379d951ca92535a91cabd533d15eafa589b55bbd7d923c645186a68ebc7f7286e9076bf3dc65ce975854fee7f70f0c8ba5357aa6c592b8a007cd16e531fdbeb3e22cd25b93f5faf63e0b8fc579693d3b68afd4d2cecb680bcd456a8db044cf606efe32cf42f33d4658b5679d25a97ee0cceaf2ccfbe4e4733c16f7be56df0be88b6221239f450578cf10d5d41803f815b3ed55892534c873186f717f4a037ac872388bf3a6fbe9ae475a5c1f46599d9a347b229cb67f5d1691fff771797275345e3e9e9271f77156e2e16bab8a3a379d951ca92535a91cabd533d15eafa589b55bbd7d923c645186a68ebc7f72ca9f02d5e6b9cb9c2fb1a87cee43cf62698d9e69b1242ee841b345794cbfefac388bf4d664b51f971e8bf3d27a76d05ea9a59d97d1169a8bd41a61899ec1dcfc659e85e67b8cb06acf3a4b52fdc099d5e599f7c9c9e7782cee7dadbe17d017c542463e8b0af09e21aaa931e0cb7536db5e955842833c87f116f7a734a0872c87b3386fba9fee7aa4c5f56194d5a949b327c269fbd76511f9bf010000ffff"
            });
        }

        if (idx == 18) {
            return Compressed({
                uncompressedSize: 7358,
                data: hex"ecd72b4e04411006e02121c111ceb09e737085150810701114096e1d02b58e1b708cd528ec1e800433a461bad3d353fdd7538c58925253555faa534ccf0ee797f76717c366336e37db717fbb27e3f8742cf1fd3eaaa2ae4dbd9223b5a4265563b57a26caf55a9a58bbd5cb93d4218b323473e4fcc919a63f389be72c73bdc4a2ea0f9f5f302c96d6e899164be2821d345b94c7ecfbc98ab3486f4dd6eef56d161e8bf3d2f3eca05ca9a5bd2fa32d742f52cf084bf40ee6ee5fe65d683ec708abf6ac77499a1f38b3b93cf77d72721f8fc57dafd5e702f6a258c8c8bda800df19a2991a63007fc56c775562090db20fe32dce4f69400f590e67d16f3a9feef3488bdbc328ab33932627c269f7d76511f5ff3f2e1fafaec7ddcd1d198787e7123f2f1faaa86b53afe4482da949d558ad9e8972bd9626d66ef5f22475c8a20ccd1c397f72ca3f059acd7396b95e62913db81f7b064b6d744c932571fb3b68b7280feffbc98ab3486f4d56fbe3d26371de5f4eb640aed4d2de97d116ba17a96784257a0773f72ff32e349f6384557bd6bb24cd0f9cd95c9efb3e39b98fc7e2bed7ea73017b512c64e45e5480ef0cd14c8d013faeb3d9eeaac4121a641fc65b9c9fd2801eb21ccea2df743edde79116b787515667264d4e84d3eeafcb22ea7f030000ffff"
            });
        }

        if (idx == 19) {
            return Compressed({
                uncompressedSize: 7358,
                data: hex"ecd73d4eec301007f03ce949741470833d000d37a0e308945448685b4e4247b1121237c84da8699682869a3ac822b61c67fc9fcf22c55a9aca1eff3466d60ec3fff3fb7f67c36e375d5cde4dd75707326e6f8e25f60f3faaa873d35ec9915a5293cab15a3d13adf55a9ad8bad55b27c943166568eac8eb67679807accd7396395f6251f9ef1f9f302c96d6e899164be2821e345b94c7f4fbc98ab3486f4bd6f3cb61111e8bf3d27c76d05aa9a57d2fa32df42e52738425ba83b9f797b90bcde71861d59ef52d49f503675197e7bd4f4edec76371df6bf5b980be281632f25e5480ef0c514d8d318051ccb6572596d020f761bcd5f9290de821cbe1acf69bcfa73b1f69717d1865756ad2ac8970dafe755944fedf3f974ffbc7e9edf540c6f7d7b18476d4b969afe4482da949e558ad9e89d67a2d4d6cddeaad93e4218b323475e4f5b3537e14a836cf59e67c89e5ed79a9a5357aa6c592b8a007cd96e6b77cb2c22dd2db92358ee3223c16e7a5f9eca0b5524b7b77445be86f43cd1196e80ee6de5fe62e349f6384557bd6b7240de02ceaf2bcf769e47d3c1637ea73017d512c64e4bda800df19a29a1a037e5c67b3ed55892534c87d186f757e4a037ac87238abfde6f3e9ce475a5c1f46599d9a346b229cb67f5d1691ff1b0000ffff"
            });
        }

        if (idx == 20) {
            return Compressed({
                uncompressedSize: 5479,
                data: hex"ec96cf72db3610c6953e4b67fa7aa9e3c8b6124bcec14e0f76f9e760499628924e9c5eda4ea7b6f3024d5ec07a02dfdb632f044874b058000b085448259dc92198f9660170b1fbc3475bd2e0bb274f063f7c3f080cc1b377a216ff8a2a7a259a75269a07a925447e170b7e1bc3b32a3a41bd6a5987256bc85a3257f6e1d9bb4187217876835c27c8b314cd5a45c9a4b890213ed99c933d79cef22af1db48d40f4bc275d38d6b45b8d696a906ae08ee4b59e41e656131618ad5dd9c7cf0cb72b1ae5cd95be49a28affef9c5f0f1bbc870b05ff7148fd1c45dcbf3c826e7f03c9a400de08a27e8d7db8e7e21573c11cddfc88491dffd0c751583d45854d118e6f219acc91ef044b8f7e71944e082f73b46ae371db9de20d758340f0bf46b01737e77617b43ffe38d39435e1dfd7c7e7b01f5aaf85871adfa721d2baeb592f2ea02f6a518c690ea87f3c0fe58d5ecc724eabf4ac2766dd86ac375219ac76ba797dceb2a7dc6e5badecef4a1a46c82af4ae47a897e5d89e6b1443619cf4132a7ab14df39d49275e17f7155d2fe2d7e15d6af9c725d816a59f3b1747ac9e755fc02f5d293bb67f9ec9d785e0e7a0cc2f5c270e95a966337d17bb15511eeffdb4d67ae76a6510fae91c3c7c35c5bfc2a5ab846a4f628b0b6fb8cb2247efe08df63de932b571cc99168d673643af2a47bf87bdbe291a812cbc576e58ab7711d02b78d380fc5c43b931ca15f2bdbf3f78edf47f90a790ed1bb43a59828698bc842f699be03ae3dae1e9e6586c770511e9fd1e7f3598958acb9b2cfe03a30ef922507b0567d0f826ad633233f97a58766eff3b986a68fe6dcc6433f9f2cdf10a5f387c8b5eccdc5f2c50697651b3aa23c30f719255b3a54c233012e517fc8da7d2a96c433cdf67c83cde120def0fb9f8c68bef2ed39c87c27e50b9f49d41fb34fbfcb82724d3764d9a682dfbf06e9deb43f65abc9395e2cbafae571e1e77cb21fe4a14c55aa79f661ce52e2cbfdeb8d7301aeee7ffbc815f409e7ca23c55da5fb46701f394fd45ab3358e5f573bfc3fba4c218ff8fd99a8d267a87d886a4ff23c7318956f67205a8fe5573dbd9abb9e634dad2add234c4acc5b9bdf69c068f3750debdbbc3713d478af39acfafc56757e4be27996eef56113bc9c11a6d356165ecc2017a2563937735678cf30dfe79377867ae5bcfdb3b450e7f8fb535095fe080ab00c761c8a97f029df4ed53c5cd7e42b9ea784672a9f0dbee010bc9c927e4fd1b3596baef3aee0ec74f03f0ea7674b2fc1cb4b6491f1724badcb2fcc76f9a99edfc6d73304ff63b9d3b9fae3ec6be0ff2f0000ffff"
            });
        }

        if (idx == 21) {
            return Compressed({
                uncompressedSize: 5175,
                data: hex"ecd6cb6ed34c1407707f7d946fc5fb254d93b4b974c586123b42d05c7ce9252d1b0452c313c013d4cfc1924d66ec83e6cc996bec346e23c1a223fd35178f3dbf1c8786e0e8bfa3e0cdff81d780c77750c06fd84ccea1cc63281f4596b2cf63e00f2166331953ce29febc3a7c1de2b3c45e710e8fef823d1af07845ae31799650e64b3db65d625d7b42aff7c714fe3081e27169b956786ef1e366b72bb15cb93115cab50ef1d97516168e817dfb28d77c5738a67a191793ae3dea754bae91a9951561e26be11a9ab33123773e19e9357488f16484f7aab9acd76db563b5f2ea45ae50b81654af0594bfeea1cc17f85c74e19943f2c9b1b8eeac4d46503cca35d5a30bdfff905c37fbd52bb921d7905c64221b5fbfc7c8f307b2b7c68c8caa77bd03e00f17341f4857d2d43530ae5c992e30e21a0b07d8abb55dd984ca3fd86502fee5f313b66b6d2b7263b3cf5163b1efa9d8f7b9aeeba041039e5c91eb8c4c738c7cfe3b8c3a53ec91f538ab885c373e79af5a63c95533576abbe696cbf7889c527cd3e9d6dcbe179de9735da78e4badbd34cac792ecc5ae7a53bf81a9efd8f8d32e287ea6962bab71f5ad67f72be6669dd996c8dfdfa7f79836ac572a1d510fca7c46a69e177586bfb6abefc126322ef65c57b8cbd545b7e9695cd547de3d518fea95ec6fbacbc89690a74bb5ebca8456a2ba9e2cd63a539f81e60d5cc0ef33d5034f63edd12edbe31b7d9f6fb5c242e58a2bbee7498d2da57a29d7897e972c3ac1b93cf7a432fa6f54c55e36edeab50a9732d5d93c5707cafc12e39e576dc271d8a1ef400758d4c167c8a8bd1d722df7ad97beced2c596cbd83a5bc17a4ed5fc58afe9b9b836357b6b5c7bfebb54b6e32d9b1f69b132957ded6f79ba089ed98067b6eb93932d8717ed9d4aa3fa4ceada0b5cf43ee7f48e5c1bfffe569fb989daba3e62ecd6b18dc1cf3255a6797080063ca3dfa1691b23ce28944d9fd9d631b56a9bfad23acfe6def77c79109b3caf4586961539d7fea8e5782a4c876ac0b399e3334619e6385bd6777c0e2c9b1dd632fb50e1bb24e36cf7ff9faf704ff0171a1929e89063965d06afedb5bdb67fae01ffdaf86ffa9f000000ffff"
            });
        }

        if (idx == 22) {
            return Compressed({
                uncompressedSize: 5479,
                data: hex"ec966d56db461486dd762fedf21a88630c24363d2d4d7020fa08c136fe14247401c86c203bb0ba8dfcec1f69a4db33f7def9902dcb92c2e9afea9cf7cc307ae7bdcf5c615bad1f7ff8a9f5cbcf2deb02317b8014fe81d8f90db26806d95a6a8aa3085d108f2ede8b9d339cd791dc2733d2f507dc2feb88d943abe40231fbc23c67cc31852ca2d1e49e91dc33c3c5ac7ab4e6da8f5e07d2f595c5f3a59c676ef1448625451e076b60d67aaa790c97032932489f935b573eea8fe149f6f1cc3e334fdff486256b6036d6e9d1a8d5cfffedf4cd9a9a3b7dcc401eb7cffdf9bca73fcce34a9e09f767c23c1ff8dcaa560fc423add13d965a937d7aa435e2ef191ea7c73cf7ba76faf5ae80e79e797ac4f1ed2fc8a209ce4578b551f70abd55a4fc52322f76dfd0fafcde6681f46bb083e70df7c5e6d8ae2f7d5564b8ae740eb358fd4116486e871b4c775b7b37f3aa72ece2229ebb56850bc43cc8edcba25b10e125b35c42ecbece49ad6f8bd613cda3fc97f4d99a07d57816013f8bd7c822955a7562f754e7d611ed3bd53c625197e754f314e5dadac7b0e9a5fe2c9bf17c7b0011bed7cae79f5875de97f88c57dea3ff9faa3ccb82fea81a2756f649ee6f9b25d53c27107b79bfe6592c2af22c88c73b862c1aa3443840c5ee314be51f6b11cb408fe6bee5f30c4f5297c72de3e922af198fb5c778bbcc90df235603eecfbc55f1925e66ea12cf6a80a21a2c2f3fa2271c18af753f51ececabcf33e367a6782e408417a6bed7cdb3611df2e0b8bac8335b4ac30be69935e039d23ca9ace11d31cf51a1348b5e33dec4ef6a4f739e0e64d108c4ea5d412da35dbfa389d7c10c92627ec73cd3ca3cc96252c0438a73353afc9b32d24aed3966bc82d8ef90bc4e1d1e10cba9d5a389cedb6452d2f536e59b79fe2caf986552e1194d98498f16cf10c4eaad56218325fd3ee2135be2d39976f0ece2532c3cbfb57ee38716479be4ab3eb4f3f77c8b87bd72bf5a178bdb56834bf3c47edbf0f86d92678d6ace327d214eb957e520cff2b978fe84d87fc96ae328d7486fb7e6b9f748dea7d61b30593c2fb77854edb277e6d863761c0f69df93e219d7641933cb21647f0fadb34b9d9b77cee59835b2e66310c1d878f01c8728dd9fa0264f30323cd10d88a7f30d8e91f4ec39d308454ce79a29553d2adfbf83e780b30e5486ac51fe5d3ab9dce2324c077836fcee5ed6e1519f891720567fd43d4f695eca3c35f3ac8c5f79fff079789a6581086ea8af1f5f3c030f658927d5eb9befca49a683a63916cbeffb32649dca7994f5a901cf27f3fe517f7f3177700d22b8fe8ee775dde42cff5fb5fbfcf1bfaef96f000000ffff"
            });
        }

        if (idx == 23) {
            return Compressed({
                uncompressedSize: 5479,
                data: hex"ec96cb6ee3361486d53c4b177dbb36173bbec47602346937892517f05db7244eba295a20765ea0f304d173cc321b933207240fc9635ab2253b3398c510f8717839978f475622e7e8a723e7979f1d6b30ea3fb194bdb365f78aad129faddeb8a6d2263ea32faed0b27b09ba02d9eb6cd1b92b72715f5e87fa4f4e81c1a83f03ae4be099b25532d573ccc5f7358f6b596b4efeeb0b4b5fba2c7d9b22ae99a89bfeffb09d2b405c89614a15d7dc15b9f35808cc053366043fd92fc3452457817e3d0257c7f40a8933d139e76acbba5a1d3d977dec20b68e3cef7644ace0723bd0afc76c8ed9ccea1770b99c6b02fd9ab0d5e767b64a2622afe0121c6de083b952b7add9e4795b5bc125cedac0f550ac5fc10370b5810b98808dceef8464ad16d4ba63f4e556d854701bab7dc19ffbf19c4bb725b982b25c2dc39528a65b219113e65cdc3f4fdc57aa2d73e63331facfdf3bd8ee75ce34316c3487c5d4de94edb7ce75ef94188c0631e4b900a6b110e6e167462d6bbdbe4f2c46be27dec5202ec71562aeb196e169a2da4d6b7d91e183fd9a9a8f86fb72352da6e68749f62b3a886b3b53a3044f638d8beee662e9a7107145195c0da466cedaec13cce2d9fe0d788e61c97e8592c5ab03533d43aa86bdb7cdd6d9d2335c645f2eb7aef936b96ab05f43e7b56ceb5931705f1a06c5999e22600bcc7bedd58c5c242fcf020bda27ea0eb02ec1c5e873a42ca3a1bfc985796c469bcf664522aee2f2337ee7410e5b08fdf281e95cb311ef5cac65ddf38232bea457d37b195c8a298fcde2aa6abb9b017cdcaa9cbb55463c98afc557816b5ab45ffa9c8413c4a3d82aa8c6a6484fcd6dbf0a5bf2b39ec995c355f0bd9c681e9167f127d4a818abe648c20feff7aa7abe4a86c03471f61c8c4613d427c5f68790cd2279e499f2c3ec04dde1702ef85bef9de9bcfa190003967e7f7b954c1ff3fcc6ce01c370f5ce3694f90db8e653c93c4fd9bbf53b9f1ec876ca56c980d1c58db0b2f6299259cbfe183fc3752afb151dd42fe01a6d70a9fc6a5f297dbd11e7b68f5c9f7c25ae13c475a2f7b77edb5b315c926bb43fcff82f69e321aad167f4f5dae48f878c4648f108ee326424b2e216386ee47cc01075e4f3e0b98f85e4bd87f931fa3ec7824bc590fc983db80692e3f51ae51fec8e8b216ef13b5bf67e83bb0c9c0f1cba86ce1f0f4ac4fc5a34e620361af74bc4f4cbc6ecc9d6ff16313fc6f73718fdb7f4ffc02f010000ffff"
            });
        }

        if (idx == 24) {
            return Compressed({
                uncompressedSize: 5047,
                data: hex"ec965d72e24610c795e42aa91cd03136605be087c44e628c44a50c0884247fe500c00d920b985c600fb08ffbc28c345bd3d333d3fae4a3bc557ed8a9fa578f5a3dfdffa9a55decfcf8c34fce2f3f3b64091ebe8a547c11dbe1b5c836a1c8dea4e610f9ca137ce9c1bdedb08fbaaeb9ae96ec217bc95ae9c3c357a766091ebe204b1f19e622dba82839140bfa7afdf2be2a47c4974391becd09cb4b3dcb82b06c2c470a2c4378ae267f4672f26c8ec5ebe35c2c0b6b62099f91a5a766f2f91fc3c45743e051deaef2f290c5eb917d1fce9b9cde0f7bd00358bc1ecee5b9612ec8e2499619ce65862cf7d00bee01870bf794a76b35748db7dabb822fef55942c302f17599e1a589e90c54506d4db4cf0d520e7990287f6bf82c8908b15f9b0862f07d06feb5d2996c53e2c573916359301e4a5184699db2575c6553deb39049b4e308e09cfa3e1490dcb40649f1e0d8bf69175bb4499f22c8fa559b0608c3c0fc89220cb25ce25107c75873def40da47d628becb0aa9bc655267758e2d92ca77831c8a25a22c0128ad6490ba4015392e4ad7f42cb04589b36311960bc3a239acf7f1d24c6c111fc552cfd13d80a39be3e17bb1c4352c5dd2af5b716df38cfafbc5fa2ebea3680f964879fb1d916da6c8d12948f72de69a62476c7dcbc20e61f19a58dac06a23eeaba25f38e377702e0b678f25eb90a18d336a2b79447e5d447f92679a1baf0f63090d8361a10c45ae2253918f88799a25acf26d603937ef89f9e770adbcce4be2eb3f4aa2b56cd436e7098b48ff5dec399733916d2610355b1d43e56fc0fa16ce2ae93367c832d71c4d3c8245b3024b0b043dd6b73999ffbb46dab365fc9bea7934478e708f6f46f3b4c476d4caf150e9bc64ae52e9b71279783473f65c82c7b39c97165fdf80f4bd6c3306e9bc94a91fb5724cf42c8f670771d8f77e93eb031ca35605c329e4d948cff21424efc9dadc7c76b3081e058d7f8f6c47aa3fe5805c4e2d53a7739a8732f12868984750e3ffab917d27bf8354fe94d4284ecb65cf6e7d7b5f33f138a8e0981a6f5d5b25cd60399418f534be3a9ea8f3ffdb3e29e5492a78a2698ea9fc6f4032fc46584e1a459fa1b6673c6dfe669289e0d144c5d8c6629f6cf36005cfacf6a98ed433c13ec994ee9d23d74eb6d233ebfa7872b057fa5f70385b3226cf297dc782c53237763ee8126cfed747e23896e7bd9f43b0f99f0deffac1f9bebecd77c093bfdfb3dfd7000000ffff"
            });
        }

        if (idx == 25) {
            return Compressed({
                uncompressedSize: 5779,
                data: hex"ec96db722237108689df2517793e03c126605c152738364633958a0d03cc101f721fc64f90ec0b98e7d8cbbd1969d096ba5ba74160f0e1626badaabf7a24b5fefed48c0db5831f0e6a3ffd58ab0c29a60fb2945f64313c95abe554ae9e94261045cea45830d82b863dd2e9867958ca4379a95c55474c1f6a3b0e29a6f7c4d623a6895c2d312a2e64eb61643dcbc46cd4e7f59a3aabf3c462284b9a23dbfdee6c33876d69b94a601bc2bd433c7a0deaa9faca83592e88ac477db36c7c1fb6e91db19dd89e7dfe07a2c887501759ba188d4e904be5e44338eff1b11358537b7a8e7dbbdba36fc4c6145b427d4b88ed0aebaa3aa02eec59ae2bd4e2caace11dba2602db72027364bbdd83ed96d8bac4447a4aa4c80758476bd881889fe300b84a60ef4a4eecda4be7ab3ce557b00e9e9bbd84ade3b1614f06b0aec4299a1af9c0a8a8ece173173d3773c9f2bff916aebf75349ea5615baf6b6aff7bb671dfe7abdc07ebed33a498cdc9ef17eadb588afc126aab752db50f717146fb97b066d5b139c4e39ee3b3f9fe6ca9cb3606b9be056b1b7fecdbaf01b6b6c78967db207d4ea4af616b1b2eed1b12be6f9a2dbcefce551ef62d7b67b66329f20b4fdb7291ed82deb76c53fd2d6c99e1c19e5c90efb1f1afce2d13ae719727f2f30d5b9a066aa76e0ced235b74446c7fc8821d55a46b55d7b6c5235944968d6fae6fffaffc9f86d918b13d86d85ac06e233d8762e49f517ed8b7d9d6778bb8027c33fbf7a4d8a2168a398ac251f7dc5de7fa1eacb52b1b71cd027d9d3a6ce73e578893d6918b220be795f939b14d6b2f1841361efd2c0b508ba22fe4aace6d2e8ff159f9bd055bb1a0df8a5133c81364634dc887f73d6ad2597b5e3cf6896df222369e2615b606a91914f4f8b14ff306d4d7eb702e6ea2a2e66bd8a44813107e9e7db95adec8226e58bed846fbb9f71dfe8697efdfad415c5883a7895bf7592e5bef779057b35a63438ef9ae8dfd3b54ef449ccff72b4b4c3df4accb2242f18a9fcf5577fa54f77fab44759b1737cc9a7ad6ebe095255bb8e87bd3e151cf5e9d18d756cb6b592eaf21daba75a335f678b3976647bef156aeb5de646323eb7b48de87c0a719d5dc32fdb6ceaa7c52dfcb650df049918decf9b9661905f3aabec889e2ceb3e6c4f7692c79365af3e2e457a91fe89dca1bedf6779cdde8fcb5fb7b3d9fefe3b973eeeeff6f8093042cf8ccb39bda1b0fc993cb37f72c3f25b58ff1dd0c29b2bf3ebaf031befdf778fee77bfa7f0d0000ffff"
            });
        }

        if (idx == 26) {
            return Compressed({
                uncompressedSize: 4471,
                data: hex"bc585d72c62008a4ed31fad0c7dec0fbdfc27b78013a1ad1054dfccb941927df98041684857cf4f9f145bf3fd4118e2b89230e04574f6ac5c708f6e333b2a2105e1da5557ea7fd294978bef9b291aeeeba0a36d42ff7e31efea60e365cd7737358c477d1a562247838c705fdce7623aed15a894db291e38f71127cb22758713fdd1371d4f85463746f3ffbd4dcc3b3110c04e64aec995bacbefa65736e2177743e1bfde83be66e30672b7994df57ba4b0c5d7de6c239c683b12939ec418f33f9e3b59d00b1b458694f14367576cef898fd145e107ce28be206aebeadd4bbadd160782418ee113be55c11b3d779b910a3ca3f50bfa8db9ec348727e15fd926f3bf98cb97a28a0ffb1e66ff1200fcaf9d97aba8945aff63497302ff70c950b3be26b3de7a531f9f59c7e51ba7cbbd4c7dcab78a2bedd1a6bf2fa9d00b1d13fccebd2dfc197f6cc0f05f3fc84a3b7f2197aab55437b78e671f9c9f801bf0ffa7d53e7b35cd8cc3ef375b61e93010f05e89d81f45cd4c33dc9398f3c74dbd35963293305574eb7b3d3299e607aaa9dbf0275b9b8c422503bcf9fe2c199556c13cca8d4b5d9d6789da1377307662cf1b39c1fcc56f6bcf01da9f78ca7b1937988a763c37a6e55fddd9b3ad43358c5e4a8f9be9cc0f03843a38dfa6db2b624b6c0cf5371517361e1575af1e941b78ee1b07779d5eb8e08ec0ecf240fa9ff125ec672f35d3eef03fd9f88bdbf000000ffff"
            });
        }

        if (idx == 27) {
            return Compressed({
                uncompressedSize: 8066,
                data: hex"c4595b8edd200c65a4e96757307f95da25b0ff5db00fa47ebbcabd311c1f0301925191d0dc64781cec835f099f3fff7e7c86df5f019a1c5de2f157445278f52f391ea4fc7efd2fbec7e1fff47d0ef2ea38a6cc49bafe542b78148beec518cbb34879afcf88e7c052f0e87a633cf2ee277ea9eb18f92458335ab9659c0bef0b8e223fdaefc487bf8f39c77a3ad79c43aafc9b32932aaff7dc39f9eb1e28b7102a964c72464ee413a38e65fdd5f5fcbecc3bc5cebad47dcbde3a2605334ef9886367b957b046d049acba504c015481fc449da91c2ef6ef6332bc056e89987db8a11e910762a90077f68213c8e1045c9f6c81799a3c981186728e68b99149ee86ffa396d086cc63509e3a7bb3db0ae716eea7c0bd5b69c425c63dcd49b22dc8c9bb6d9a0bb37a7e1c42471e0fb7dcb695631bf19800e4b4e5f332f816312cc60edfa48a650cce4f5f9c71e62eaf72127de0f4fe23cc292cf111fd4fb19bbdf513d8a34498e3b2dfecc6b7264603dbe5e2ab6863008c69b77124eb3b30b6633cf5fe5919de9085bb238ac19d3dd9981264e0d69b886984cedff87f9579463d41fe70ee73e7ec436c8823139ed30e3ebdf7041ed377dac78ff0e75733b15185e746474260f2873d77e64e380d1348a951c0c0120366341af89bc7e0fe8a713ad9e40e41121aa2409702e5537e8b34928779e563306b933771019b910f62e60b94f6128f1147acbe211195f1d851f2a7989dc388c1243fd510da40b8e97062e5c748e60e272677d12675cc37cfbb251ef61d45eaf0f3a2b7e4580dfd421126dabb19e8fcfc1eef41207958a7b610e053b26b0a1e91029c746da356929c2bde1b9e759ab3593bc59887db02171c277243af19743ec2cbbe64958b81f7e9e8ba776657d049eb32c8740f46dd2753fd446f47178effb3c5864e5f90810fe0c416c84c91b45398c222e5f9ceac7b61b3dd58d5b1f107bde42ab5ede66490ad3a708534c3bf86ed633930976cc2318c9d9ab8b8f8c9090716667b71d3f2fd4c560fe7b3fb38d0f395fcb161cb5f89e7436e244fce4f72c19e6ccd46d1d605f3bd3841f7617f5d6d8218dc3b058040057afe20c11f5332d9aa10c272458c0b6398d81b3b4871ee698f05f1e7753bdd8d63dd79633bd9321f2fe4160f6a71b06d6fe532698642f3ade203c4728b09adb07d5df457cd18ff6e928c1f3d76e6e7bd73f8a26bdcffa8f34421e7be0cff1b068aa96ee308370a25770b3c33f3ff050000ffff"
            });
        }

        if (idx == 28) {
            return Compressed({
                uncompressedSize: 4103,
                data: hex"c4575b6ec4200c9c56bd457ffad13370ff5b700f2ee06a93d88c1dc80289544b28ec86c5f68c5f8bcf8f2ffcfe80445eab40b6f52db0a724c84ba09f653f837d6b7b80be4fb0558e73688becabfe46f72f5ddb3e635ff48ecf94e3cc66db71166407e664b3c7ee938a87daa2fe282e6e9fbdcf8ca761228a575f7f71f6d7a7da1179525d7a0ec44f94fabee3bbd4dfaa4ec542fd307f08a7cdf7861d6cb3de7589bd6299bc4e8e09be97b92e21f6e2423f16cd77bed7719dc8bf8011630d8ec7e4e36524f614a38a95788e291f5c8eb53e8b8fd9d1f8679f22c6e663831fc38af2d1e2c33818b3a184faa2b15e1adcc7fa63752305db8cdf811a10733c0a639dcf5cc59c9bc400c0856eb2c1c5c685581db21af93e061cc717c2dcf4ecc4581ec890df0b5263663c07b5a63d6bc3441f7a5a2c7fff477fa8bfbed7c55efb2eff426c0f9c9d9e0146f877f52fe10eff55efa8e45a8f0bad3bceb7b8e9dd59026f3c8f454e0aa66c38cd41bdde6eb192430fe2f719b3b3609d4578dea1dec6332bcf87b17f6bed5cc13fce615cc75a4feed7c53d97c46ae1a997a6f3aca418f959ded6b2fef87fc4cd07e91c67ad3377f49bef192dbf9a2bceb077f45bfe254ccd2e70b3d22d71774ecf4f79ed3f9872be12ab78562c0e66797bd886a7cfff050000ffff"
            });
        }

        if (idx == 29) {
            return Compressed({
                uncompressedSize: 4183,
                data: hex"c457518ec4200875778f31d9efbd81f7bf45efe105d858853e105bb5cd0c09699b56793c1068f8fefa097fbfa1239435052a1203bda83ce46bc8b75bb9664d8ee635f91b545eb7bfab1aae65c7a2d6d5fdd856c6746657f0d7abf810c507638fe8124facfc541cb097eccdb6f85e6184f588af6256f63a3c1163452e4654b83471413f040f110dc5a7f87360aeb9827c5bdd6d6c3a2e6c57bd6ff2684a88f1603e08ffd1b73fc0a3c917d4f17c76e383584d1edb677b16d9d5b02e075fd19cb9c8e0cec562b1fe2de1619f09389a11ce73e616f6f1ce94d4aaf2bae2265b37948f580f85372b31dc898d7beea49e3d2026b7c1f7c19c817e911ec2b490cf3a676aecd311d33581ba341b239b2f9fe4c5ad37ce199ee4c6b3359dcbe9617e166ba1e44ff82c1ee1a5d6e0662e7813a61dc7ab7cc57db2f966088fd7d7dcfeb174d6351eacf39d5a8cfdeafaecdfabd56776a0df1cb5b353ab6ef4793d0b79737df467673b1fc9ec313ec7773869e766bce767d553b7a0fab8c2b61e2b5d831cbf718e6db0517fbee63d076b625b0ba39e4bd5bfc3a6ff23147f90fb0a37ac1b8dd1e1c3f9dc8733e969af2d58d50ccd7b2499694772472bfa8a3dcef267e35873c6ea6c1f1bc0492e3e07c33b842e7456fe030000ffff"
            });
        }

        if (idx == 30) {
            return Compressed({
                uncompressedSize: 4003,
                data: hex"ac578b91843008e5b68d2de03ab0ff2eec8306b851037910e299446632ab6b84273c3ea1cfcf877ebf94881c4b3692af5cbf7a7ddeefd73aae8f6d4c62f7e77311fb3ddee37279ead1dfb2684ee45a5527171c54d6611fef4fd9c9f6391c4554df0a26f7fdc51e7eaffa29f30517dc8a19f18fe230db3bd9f7eb3dc6c5b0ec1027d863ef057ff11826c729f53587f839bb7beb9318e32b56957baa770613da77df8b3184678a29e603728c1de6096e839d366f80b3e26d35b1dcc8e5e32ac7911b31d7bc8d8cc7fe3fe7d7795c0d468be716725ebc9f62bca2c49cf8cf2f90dbf6cce53fcad6e619d650bc5ff507da37ce760439def0077958fcb78c4b7c2de84a562b12ec1339e762d8f48d3b8935e366df529f93ca05178b0519f091e1c0798016614cf4b6f13af592d45eba967f4f63c70fb64dd48525bfd8bc7017d2957a3d28d87bdf048433d448aea5334452c35eeb6f8ff851aff9a6a6f15c1ee67cda28ed6db55f2433e5e667383f67d9ead6245dc85186d984c30c9ccd684d1f0a678b89d8b959047408d6050ae716adb1cd2c07fdbb9e134057c0dcc143f84edfafe43884e7184efa11c429d5853a3b7b06fa5038e3843871f5cb88ced7fa4e67cdc85f000000ffff"
            });
        }

        revert InvalidBucketIndex();
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import {IBucketStorage, Compressed} from "solidify-contracts/IBucketStorage.sol";

/**
 * @notice Stores a list of compressed buckets in contract code.
 */
contract LayerBucketStorage1 is IBucketStorage {
    /**
     * @notice Returns number of buckets stored in this contract.
     */
    function numBuckets() external pure returns (uint256) {
        return 37;
    }

    /**
     * @notice Returns the number of fields stored in this contract.
     */
    function numFields() external pure returns (uint256) {
        return 81;
    }

    /**
     * @notice Returns number of fields in each bucket in this storge.
     */
    function numFieldsPerBucket() external pure returns (uint256[] memory) {
        bytes memory num_ = hex"02010202020202010201020202020202020202020202020202020202020202020202020707";

        uint256[] memory num = new uint[](37);
        for (uint256 i; i < 37;) {
            num[i] = uint8(num_[i]);
            unchecked {
                ++i;
            }
        }
        return num;
    }

    /**
     * @notice Returns the bucket with a given index.
     * @dev Reverts if the index is out-of-bounds.
     */
    function getBucket(uint256 idx) external pure returns (Compressed memory) {
        if (idx == 0) {
            return Compressed({
                uncompressedSize: 8146,
                data: hex"ec983f6eeb300cc6152078e3bb40b70eed193274cede93e418be42371f274b4fd1b153d722000bbb512cd11449517492223140f44f227d3f5332ad8f61fdff7db50ecf0f21b9206c76f07600081d40e893f838c0760f630cbf73f1fa05637cc2f729e2f861ae71fecd2e08d79de50c2c9127fedf8da587eb6131e665086f1692a30731228b9263c863f693e2c958fa695e29d2f1ca9c440e968562489f152a3093475e6a19582679afb079b132504c2d2c2df9a0c283c583a385c59be30fb3643c77167e9d5ef6651eea33eefb044b5a6b55cf92a419df53122362c1b55655efe25c69600e8a278d42dde5f2c2f2cc725e383b38ec15d559860b92f1781f4696328f82236369e7209f6f8967418e8c67c64470ccf87ec78505ae13d318dc7a2dc72073e5619d73f52f3c3d5e8351bbeb5fd69c5eda90d6dd7f85f16bd58fdaa9d192f29032d6983dc9e069d6a0c461d52fadbf78d8ab6f00c8665ba18bc325ff150717fcb25a529f62c09f17f4a943e639f5a983e5adddbf6a0fdcba3e5b6fbbdcc4c7bfddf529868e31971d2cd2183e4507a2a1c2632a1a59138341bbf4fe31356812cd74adab8c9c517f0cb4bf246dac6f6866928d0f6daed3fb3eaeb756bf5c07091db1d18dcd536f6c2ef7f499833142d37383f7a0aed19e69c7da8774d586b6429fdefb714deb4dde8ca1b6fe6cf78ecd0f83fed160fb98e6298f55633c1b2ea6fae7a46f6dbe7aac7f6b33af555f31fe270000ffff"
            });
        }

        if (idx == 1) {
            return Compressed({
                uncompressedSize: 4067,
                data: hex"ecd6cdadc2300c077003737065874ec09d493a062b70eb38ecc191135754c9286d121ce37ca795905ae9afa797a7b63f39ee8b61bf3bc0e908ec42e87abc8d88704584e11bb576becf81c718cde585539ef8b699eed5cf82ae87c8b55956b2188f5a132cea6ff467924565018bcfb1585d545ad6c5381ccb80d1184b66af043d8e85d42a167a7f8285d7c76b910cf43b91c24d018bb45fc19e4935044d9575293548a69a7ea9a987941696168e1a4b6bc71f5bac67b3acbb4f359614cf544796a52cc6e3354867a3c79369717a867becff7362f09e8dac46faf726161be3d0f3033dc7e95c41cea0792ddfe2ee3d371087cfa0e29c4103d2679639784c2f30079feb9cfed0f561a63207ed47614fa419933abc09cc0ea177c7fa823bf85aa0b78bf6883b6273b8f43db140e1f5f3ace8ac5bffce363d9efffe4f000000ffff"
            });
        }

        if (idx == 2) {
            return Compressed({
                uncompressedSize: 7142,
                data: hex"dc97bfaad54010c6f7c2053b5fc04644441041108414828d28d889856025161636e7317c85dba5f0617c065bc5e6226261a3075626279333999d999d89d9c831f0712fbb99f97e3bfb2f279d5f7d7d769e6e5d4be4c9a9dbe58b7dcee97dcea93f0ada9e7c3c287ddeebea0ffdcf7fe44197f9d7a42176cc95ba5d329ebfe3408f3eff3b8ef11df0fb967f4f2c9b728cfd9483b3c07b6b7080440ec6806ac521d68330481c94c5c901b1260732681c9441e28830582c9887d7a8c631b0e07eaecf093254e70685e7848ba33ff60f71f6da5039ac71230b6fc73e50d1be8043f3e77e9eb6d61c74ec5a0d9672f0f9a8d684ade1561cb57a4474621cb335b201073d3356e380f32ec0c1cfd02ac743233ff6e1990f7fadf7a3f5a0fb5663a16d9483f7d1f7a3eb8373200b15674051162ac79d2f725877aac6c059500186837fb773af49c99f9eb10a0bca5c9b6b30ccce7ae58c15ea23d6807017e7b6f6cd2ede37fdac06dafe99fa66be02e7c4633014ed562ec255992b75fd0cb27e4fc573a6854f31aee098f8737625ddb89e21f1dddb370b3deaeeab7a70ef4e21eb7dc8370c20e08579dfbd7d53c8f28c78591e1e4f8f57c443f2f47a81a41cd6bc687e35af674f1f8bf9352e5e77ea6779810f48ca7fd17f50c57dc1ebd5cb1779b699881ffa68f93f7db95425f96a5edcc793bfe63dd64ff45acb87fa712f3aa6b57c5092570b9fafdf7f6ee625d530b2de4ec46bf2fb5fbd36581b4de7ccf26abc979bd591ede3a663f37a79fde02e0cfa24eb8e063f88a5a2df30f83fed1ff325af9f74e76bdf6678e7630e688b7aa1b05dfba69162bd5e5a2e4d0a5fd8cbf50360ac1be30bc52d8971f21571a11f37639c936f16b7410c8d5d33e64f000000ffff"
            });
        }

        if (idx == 3) {
            return Compressed({
                uncompressedSize: 6926,
                data: hex"dcd7a14ffb501007f0fe925f82c24c21172c0285988390909010044c203008061ec10c7f00414ee110fb0ff69fe040130c02852eb9d06baef7eeae774b5f936dc9254bb7ef7d5e5fdbbcd7e2ffe6e3bf8d627b585eed0ccad9f96e52aff7876a2dae474959ff877ee0442cec5bcecf92b2cc8865191ed363450cc9f45a50520febba685e9bb5b81b89fdb571f179a79e65810325f57f7e99abc55db0de9e8ec028aa4fc34347ebfffef1a596e46a16773cfddbec6afe44ab2b877adca2e7d495832559399ccfef9fde2c690e23f7db8a58b5b7ae560ff746d66b6659999fe56cf3c89ee3ace7e6b5bc1eac854147b4a809595a740f83dfe9efd53a5c189f8627adf9dade0cd77c5cebe158d4c2c2e3da9e86ef272296d64b2b657c61ab2553e784f18572cb649ce34b72ce4c23e71c5f23d7438666bbccfcbd840db686e5defe38a993cba95a07a793a4acff433f702216f6bd9dce92b2cc8865191ed363450cc9f45a50520febba685e9b753cbe11fb6be3e2f34e3dcb02074aea6fbd847117ac8bc90318f583413d74b4fede9730cc6a1677ba7809abe64fb4ba72a8c72d7a4e5d6fdc242b87031b90be2c690e23f7db8a58b5b7ae560ff746d66b6659999fe56cf3c89ee3ace7e6b5bc1eac854147b4a8c95fc2e81e06bfd3dfab75d8dc50524f5af3b5bd19aef9b8d6c3b1a88585c7b53d0ddf4f442cad9756caf8c2564ba6ce09e30be596c938c797e49c9946ce39be46ae870ccd7699f90d0000ffff"
            });
        }

        if (idx == 4) {
            return Compressed({
                uncompressedSize: 6926,
                data: hex"dcd7214b04511007f0150493d9a0a0d8c4aa51b008e261118378494e103498ae08169b169b6833f80d043f8ac12c1683c97c32b8b3ccce9b999d39f62ddc1d0c1c7bf79fdfdbb7bbbcb7c5ecfcedcc5cb1ba325a5e5c18f5767792ba381ba8d53f3a4ccafa3ff403276261dffbbb9ba42c33625986c7f458114332bd1694d4c3ba2e9ad7649d9ef4c5fedab8f8bc53cfb2c08192fa3f3dbfa8c55db0ae86976014e5a7e6a1a3f5fff8fc564b72358b3b9efe4d76397fa2d596433d6ed1736acbc192ac1cced7cf6f6796348791fb6d42acca9b56ab837b23eb35b3accccf72b67964cf71d673f35a5e0fd6c2a0235ad4842c2dba87c1eff4f7721d2e8c4fcd93d67c6d6f866b3eaef5702c6a61e1716d4fc3f713114beba59532beb0d590a972c2f842b97132cef1253967a696738eaf96eb2043b36d66fe5fc2d6f697467bd7eb499dbf6ea975fcb89194f57fe8074ec4c2bec3f75e529619b12cc3637aac8821995e0b4aea615d17cd6bb20e1e36c5fedab8f8bc53cfb2c08192fa5b2f61dc056bf0b60d46f560500f1dadbff7250cb39ac59d365ec2caf913adb61cea718b9e53db1b37c9cae1c006a42b4b9ac3c8fd362156e54dabd5c1bd91f59a5956e66739db3cb2e738ebb9792daf076b61d0112d6af29730ba87c1eff4f7721d363794d493d67c6d6f866b3eaef5702c6a61e1716d4fc3f713114beba59532beb0d590a972c2f842b97132cef1253967a696738eaf96eb2043b36d66fe020000ffff"
            });
        }

        if (idx == 5) {
            return Compressed({
                uncompressedSize: 6926,
                data: hex"dcd7314b2b411007f07bf0e0550fde4778a4f773f80d24858508dada085a6b15b0112b1bb148276291ce4f903a60a1b5d8a4b012c1e664f0e6989b9d999b09bb074960205cf29fdfdede1dbb57fdfe3bf9f5a71afdafc7a3713ddd9d26b53c5faa353f9a2765fd1ffa8113b1b0efe75d9d9465462ccbf0981e2b6248a6d782927a58d745f3faacfbd399d85f1b179f77ea5916385052ffeb5bbdb80bd6e2f2198caaf9743c74b4fe2faf4bb52457b3b8e3e9df6737f3275ab91cea718b9e532e074bb24a386fef1f8359d21c46eeb735b15a6f53ad01ee8da2d7ccb20a3fcbc5e6913dc745cfcd6b793d580b838e685113b2b4e81e06bfd3df9b75b8323e1d4f5af3b5bd19aef9b8d6c3b1a88585c7b53d0ddf4f442cad9756caf8c2564fa6cd09e30be556c938c797e49c994ece39be4e6e800ccde6ccfcbc841dfedbaaafb6f7925a1c4cd49aed1c2765fd1ffa8113b1b0efd7c563529619b12cc3637aac8821995e0b4aea615d17cdebb31ef6cfc4fedab8f8bc53cfb2c08192fa5b2f61dc05ebe9e4068cf6c1a01e3a5a7fef4b1866358b3b395ec29af913ad5c0ef5b845cf29f7c64db24a38b00119ca92e63072bfad89d57a9b6a0d706f14bd669655f8592e368fec392e7a6e5ecbebc15a1874448b9afc258cee61f03bfdbd5987cd0d25f5a4355fdb9be19a8f6b3d1c8b5a58785cdbd3f0fd44c4d27a69a58c2f6cf564da9c30be506e958c737c49ce99e9e49ce3ebe406c8d06ccecc77000000ffff"
            });
        }

        if (idx == 6) {
            return Compressed({
                uncompressedSize: 6926,
                data: hex"dcd7b14af4401007f07cf081958dbe80f80036365616560a3e8082bd20d7fa103e82cda170a5dd3dc01536963622b13b906baeb0bafa64341b26bbff99cc1cd9805918f888f79fdf6693b0fb15ffb7effe6d15fb7beb9dddcbf5e1c138a9b393b958c747b3a4b4df533f723c56e83bba5e25a5991e4b332ca6c5f218c8b45a54a887f65c24afcd3a3f7d82fda579c5ebce3dcd22870af5bf7f988815bb645d5dbc925154a3e10547eafff1b9140bb992153b96fe6d76b57ed0eacae15e6cf17beaca0985ac1ccee26bd59b85d6d0f3befd11abf6866af5f06e647d669a95f95bceb68ed1779cf5deac96d5a3bdd0e9408b9b94e5c5cf30e1dffcefd53e5c28a3e1a13d5f3a9b853d3fecf574cd6b850ad7a5334d7c9ef058522fa984f9b9ad964c9d03f373e536c918e797e48c9946ce38bf46ae870ccf7699f9fd4fd8ede8663d791c27b55cccc57a799e25a5fd9efa91e3b1425f3434d3636986c5b4581e0399568b0a0dedb9485e9b55bebfc1fed2bce275e79e66914385fa87bfa18a5d1a655992517f18dc4339de4f1bc895ace47786fe6d76b57ed0eacae15e6cf17beaca090359399c3eade974aabe1b03b192f76368560fef46d667a65999bfe5aceb089c6cf766b1ac9e7646101c68a13d1a9d61d0b9a4da87d50325f7d09e2f9dcd22e3e79ad70a15ae4b679af83ce1b1a45e5209f3735b2d993a07e6e7ca6d9231ce2fc919338d9c717e8d5c0f199eed32f31d0000ffff"
            });
        }

        if (idx == 7) {
            return Compressed({
                uncompressedSize: 4223,
                data: hex"ec963d4e033114844da041a24034344854f4dc81025171010e114e8144cb396829b8407a6a240a2a6e800492d1443be131fbecb5f72f0d96469bf5dffb327ef63a2c7676c3d969901217cb10af3fefe2e57d88378fbf42ddd52aac75f2b2d7a9838f8bf8fcfdb611ea3096732d9621577a73b08deddbe040ddc3d7d346789f9383ef888d76882cec4386b13820ebbdf5800c964379a6f0c38b9fe2801f961d73a1ae8403fd94037368ccaefd02d9fe855e643dd1fd50b26fa9ca35a9e2d0dcc9694c0e95971b29e9d8211c78bf5d1dc6f3f7a36a2997e1402e16730c61f0d4709021c5321747951f63330847f119b2458e3f9efc734c9f237d394af70cc6506372e8f70e2cb9f87266ba3c15e77ae7b92a67a3db6679ec99daf00de6c06fc87ae0dd032c0ffac9b86a0e65b0394086dcf7dfb218f5e2f03c20c3feebf13a9e3eedfd58d7a9364fc9e1c5278327c4e76f8ed5751296d437cff5dfe601ee5968c313f1f4c9b1bc8fd9756aeea729961603bdd51c90b52e969d4358d48f168313bb6f69f124eeedb9f86396d67fd5f561db44f193ffdbe39821be17f3270000ffff"
            });
        }

        if (idx == 8) {
            return Compressed({
                uncompressedSize: 7918,
                data: hex"ec99414a2c31108633436f1ebc070f372e7437b8f70e2ec49517f010e32904efe205bcc0ec5d0b2e5c7900c185d052cdd4cc6f4da52a954e3388d350348624df9f6492ae3fa6eedffbac4b6727099e7ebe4cfdf5c75d7f799ffa9b876dfc7dbbe8af566988d3a7ce0caa4bf1f8f9b2092aa7b6d417f53f5fa6dc73d0308106d6c1e5633550ec5b43ed3c50480da4ab4683c697f3a4056bc8cc01e929d6811ab8ec76f5df0d6c2f34305fd391d5a0b1cf5f8fcca07e28b86d661e76deb9f5a0b252b6a525f35bc0f95035303fcad6b4281adc7918337e2d8c3d919d87567350aba135ff0769f8a6e3a061bb1ea51a58f3141af86cf4f8fc1df174d46ae03deaf13d1dc63919d221e3cff3f1c0956fad6e806f7e37341ebe317fe372256fb0be9bae0eea37179843729991b7787c759f626e42fdcb37f3f9ef027e4887d42273366663acdbb57c365a28341d13b25d3d22a2cfac4b8b45d186a0324c2cb5cd272368748ad97810ed8b9dd35061f0aad90d4cd53e0d5d68dc25268a0fee0223e71a383430def8a5466e5f6ba425d3336e5203bd6bd81ad34b7ca40665ad5d9324b9d10490f99e59f4d83272bcdc393066dc25fc5cbd9a0b93037b52b6caffad6c8b2fcf4cab7e2d5beb2f673638d99c8acd5c6b7eb53ca7e6e24506732d6383df5dfa7b8ca9e475b58c0c1a092c0b98c94d02cc6cd4af19177c639ee65cf699e346ae646b81e665bdbed56cc9c57ead4053c37b2fbade38d7389f864951734b275f32b982596c2c718f45d8c8ad305e3bfcc8d942f59d7f4e84f8517603833bf41718c7503f701615b123bff396ece0dad5b4f1fa885cc68cbdd4d0da975e0235bf3881717f050000ffff"
            });
        }

        if (idx == 9) {
            return Compressed({
                uncompressedSize: 4103,
                data: hex"e4963d4e04310c85c3080a240a4443434143cf1d28101517e010cb2990b80b17e002db5323515071030aa420af78c1e3491ce78f1fed484fabd999f87b493c76dcb4b3e7ce4eddd7e5a795f3d7ef77fef2def99b876fd17f576bb7d1c9d3ee42e7af47333d7ebc04e11d1a8b58d3cac5ae7fc997ecbfc08707fe5e0b9f14e3a7d8bdf9a9f94b8f5c729dc0275f1a9f9ec7e61f63deae0f93926389afccddb407580b30b4f58f7969e183ab31735e284e0dbf852d7d94f27bb121c6a75c53f9bdd98c0fb6f4f053fcecfcad79dec0576bc02ff1676bb0edfcc1f967e60ffafeb339d8fb1b34d4ff617b50c01e528794be9fe553ffd63ca05e508fefc08ef22178c0de50ecfde7e38db807fe9c62297c532fe01e787f3c78bb086cfaa57bc135f5fd5c2fe46cc4c43d97e41ace3d45f3e7f1539267bfc2dc5773d05a3ff899b522ff66b1c037c659ec4f253bc4aa8813c635cc7d518f4bf91dd83cdea8319f010000ffff"
            });
        }

        if (idx == 10) {
            return Compressed({
                uncompressedSize: 8190,
                data: hex"ec98b14aec501086cf2ee1c2850b576c6c442bad7d070bb1b2b1f421d647b0127c175fc017d8de5ab0b0b2b3b4102213f6d7c9eccce44c723651d8c0b0249b3dff9739d933f39f54fdbf9955e9e820b1a39e2f527df17e5b9fdda5faeafe3be8daf93235b1ff5899f1eff5b489878fe7afc077f45b8c355f24ebd83214660007ff6e2803c5d40c7df240519201fa9c41e6490bce90a1ef7270065cbb5eee74066729c1c0e7051a272fbb6e4896210c516d8fa52f03f4a3da1a4b1f8621cf2fa3ef5c94ca0122ca505aff1731b438b60cb1f9906b749081ea1bff0cff3756ebce5a04f3c0f5dd754a19af09ad5e691cc6faa0e5a1c561d54fae4dbd02de1f1e9c919de71ecdfdb246535e28302efa35cec6eb3b9e01f707185af30a5d68f3e7b2b4792fc9393219d4f74bcebbd4e7bd8ad6cf626e3272e1ea425beaff7dda6b74f0097d795d86f66e7a9a9a36f479405bbb2ec3a9a1e63c487d3050efaa7d9206f48c31a3c7da18da7f112174cd31c57a309829f88cd6ba34f601fd59958e0f8b1a1d6e2c7a9acec11c301f92654c0e30a04881654c0eadd8d3b9bcaf048765c6ad8683e7648c7c78a644e6a4048765cab55cfc79bb54731230a359a618635bb9e01cc849d014671b63b949e071e03e56e0731654b5f1d5f20f1eebddd03634947c588bba6a02ac06dc62b1f88449cfce478e19a1efe5ffa8a429929b41ded872cdda14c7942671620e9525b2513335070c5317cb108e2e16d41fd491921c72fdf058900b707839d9140731a006f1daaab104ea4bab1127168b01fda764b05832373c5bfa5def83a7cffb63b08067c5e2198bb50d11cb1849066e5ab951c475f42d9cc7c88f6acc2c630d06cfb8e25c31759a4e8bc13163a6b1e52616fa742ef43b8d69d0e866195b43bf6bcc4d98dbed517623a124c34f62891c9f010000ffff"
            });
        }

        if (idx == 11) {
            return Compressed({
                uncompressedSize: 6974,
                data: hex"ecd73d4a04311407f0086267b39da0a0b085b08a8285ac95e00df4048bc8161ec08358d929ec0dbc89a5b5d85858594702fbf0e5cdcbfbc8c6656167e0df0c93f9253399645ed8dc7ed9d80ac3bd10428829c787433697e3b32649f70af9d1bbbdbb54b7d45e8bc1146dce7b7a9ea9a1ed6b5cce7bfff812437dafebf524dfe3d67a9c6f75171927cde7f78fdb5dd48458dcd6e60aba99bd6eaed5a6eb540b57b3e7df6427ceef575c3b98be17d737ce565c75dd8231c2f9fbe92d1bb80f6e53e3e2b1e07de6fcf4280b9c4f365cbfbfbba3b9d97ba21e364b1eee0fb605374ac1fba2e47136f15593dbffada6146a4aff29da732d459877ea73a6a6e672f39ac47274da95c6c0582d8fa8c47afc156793d1203ede9cb0797bb86a9274afc968900da4777b77996ea9bd168329da9c6729ce68fb1a97f3acc511be97c7f57a92ef715b166756b77571e6755bfdbc5bdcff281a56cccdec7573adb6a738b3ba9a3dff263b717ebfe2dac1f4bdb8be71b6e2aaeb168c11cec7d9351be8176e53e3e2b1e07de6f56e9c05ce271bae9f5e1c686ef69ea887cd9287fb836dc165e708ed0335a5ff0bb089af9adcfe6f35a5cc6dd1d1dea31661dea9cf999a9acbcd6b12535144db95c6c0584d8b3369fe39acdf000000ffff"
            });
        }

        if (idx == 12) {
            return Compressed({
                uncompressedSize: 6974,
                data: hex"ecd73d4b33411007f07de0c1ce264d024192424b41845436690441b14a216827a8e017486d69636165a7e0a7b2161b0b2beb93831b9c9d9b9d97cd1a02b9837f7364efb79b9bdbbb09ff375ffe6d84edad1042a87a83713599ced89c5ccc8ba4be566f300ee8e8dcce5daa9b1aafc5608a36e73d3dbfaaa1e3735cce7b7bff14437dafebf524dfe3e67a9c6f75175927cdc7d7b7db5dd48458dcd2e60aba91bd6eaed5a6fb540957b39b67b215e7f32bee1dccdc93fb1b672baeba6fc11ae1fccdfc910dcc0b8fc971f15af07b667a7a1505ced736fc7e67f74073a3fb443d6ca63c3c1f6c0b2e5b23740ed494be2fc026be6a72ef7fab29a5b14547bb8f5a84ba53ff676a6a2e57d724c170b4c6a5d6c058a1e021d69fc3fa6dce46c37e757c74c8e6f6fab248ea6b8d86fd68219ddbb9cb7453e3b5184cd1e63c4b7346c7e7b89c676d8ef0b53caed7937c8f5bb239b3baa59b33af5beae3dde2fe45d3b0626e64af9b6bb53dcd99d5d5ece6996cc5f9fc8a7b0733f7e4fec6d98aabee5bb04638ff707fc706e685c7e4b8782df83d737e368b02e76b1b7e3fd9dfd3dce83e510f9b290fcf07db82cbd6089d0335a5ef0bb089af9adcfbdf6a4a696cd1d1eea316a1eed4ff999a9acbd53589a929a2e3526b60aca2cd99547f0eeb270000ffff"
            });
        }

        if (idx == 13) {
            return Compressed({
                uncompressedSize: 6974,
                data: hex"ecd7bf4afc401007f0fdc10f3bdfe0b4386c0edb6b056be5fa203e819570585af912da29a4b3f421ee0d2cacc5268595584602199c9dccce9fbdf538b804be4db8cd67f732d964c2fffda77f7be1e8208410dad962d29edd1eb3b97a392992ee5ab3c524a063744777a36e6abc168329da9cf7f058aba1e3735cce7b7b6fc450dfeb7a3dc9f7b8b91ee75bdd75d649f3f1f9e576d7352116b7b4b9856e64ef9a6bb5e93e55c2d5ecfe991cc4f9fc8a7b0733f7e4fec6d98aabee5bb046387ff37ace06e685c7e4b8782df83d73713f8f02e73b1b7e3faf0e3537ba4fd4c366cac3f3c1b6e0b23542e7404de9fb026ce2ab26f7feb79a527a5b74b4fba845a83bf57fa6a6e672754d120cc7605c6a0d8c150a1e62fd39acdfe6ac9a566d7d59b369ee9a22e9ae554dab6821a33bba9b7453e3b5184cd1e63c4b7346c7e7b89c676d8ef0b53caed7937c8f5bb239b3baa59b33af5beae3dde2fe45d3b0656e64ef9a6bb53dcd99d5d5ecfe991cc4f9fc8a7b0733f7e4fec6d98aabee5bb04638fffddcb28179e131392e5e0b7ecfacae5751e07c67c3ef97a74bcd8dee13f5b099f2f07cb02db86c8dd0395053fabe009bf8aac9bdffada694de161ded3e6a11ea4efd9fa9a9b95c5d93989a223a2eb506c62ada9c49f5e7b07e020000ffff"
            });
        }

        if (idx == 14) {
            return Compressed({
                uncompressedSize: 6974,
                data: hex"ecd7bf4a3b411007f0fdc10f3b2124b560913616da58596821be8090cec6a4116c7c09c1ceca46147c033b1bdfc1d24e101b0bab3436270737383b373b7f366b08e40ebecd91bdcf6e6e6eef26fc5fbfffb716861b2184504d7aa3eafaf084cdcbe96591d4d79af446011d9ddbb90b7553e3b5184cd1e6bc9bbb0735747c8ecb79afef9f62a8ef75bd9ee47bdc5c8ff3adee3ceba4f9f89ab9dd794d88c52d6d2ea11bd9abe65a6dba4f957035bb79265b713ebfe2dec1cc3db9bf71b6e2aafb16ac11ce7f5f3db18179e131392e5e0b7ecf3c1e5f4481f3b50dbf9f6e1f686e749fa887cd9487e7836dc1656b84ce819ad2f705d8c4574deefd6f35a534b6e868f7518b5077eaff4c4dcde5ea9a24188ed6b8d41a182b143cc4fa7358bfcd597f30ae76b66ed91cedbf15497dadfe601c2da4733b77916e6abc168329da9c6769cee8f81c97f3accd11be96c7f57a92ef714b366756b77473e6754b7dbc5bdcbf681a96cc8dec5573adb6a739b3ba9add3c93ad389f5f71ef60e69edcdf385b71d57d0bd608e7cfa63336302f3c26c7c56bc1ef99bddde72870beb6e1f7c3cd73cd8dee13f5b099f2f07cb02db86c8dd0395053fabe009bf8aac9bdffada694c6161ded3e6a11ea4efd9fa9a9b95c5d93989a223a2eb506c62ada9c49f5e7b07e020000ffff"
            });
        }

        if (idx == 15) {
            return Compressed({
                uncompressedSize: 6518,
                data: hex"ecd73f4a3b411407f009fcf85979036dc433e805bc80b5956d088848ec3c84075008da59e600292cc4038888954d9a1c6265c2bef0f6f17d7f663304c50c3c926c66de67333b3b6f93feed4e06ffd3e17e4a2935e3d1b0799cdcc358ccbfaa44ce351e0d136b5b77eb6ed4d5c67b11304d1b791fef6f6ec8f17d5ce4794dfaa56ea967f9256e5f0ff951779ddf895aa95bab45dcdae60f743bf65f73a3f6743aed440dd7b3b393fbcb28bc7fcdbd039cbbbabf21db71dd7dab1dbf3a6ecce932f8983e2eff2dbccebc3ccf3a41c773a3fe5797179edbb94ed2e3a6e6f1f3e1b6e1c23522cf419ad6f305d9c2774d54ffa3a615ad6d3ade75f422702fab732c4dcf45eb5a440ab4d0bea058a96233d75f8135d849077bcdc9f151f33a7b6acecf4e9b9bebe1f2958ee5cf0f77b7bd228fcf79728ec5fc73f9deb3f26b1fa78f95df538e3cc68bdc8fc6472d9487fa5b21fb5b1605ca13993fde9f72791605cf93fb78c1fb472c2d7f640ea5db3aab9b883c2f3fad2f2b908b2c2f7fc97a176ec7e246697e14743d5ab36371835f3374ff5821fb230bad0f94dbf2f877620d9a96357fe83b79cc9a436bddd7be5e1bb2a0b7b57e97b5ae57db427b097d561cd5b23c5e9328bfdc374a2de4c9da216b3673c2165a2ba826f2e7215e4f44ed821eafdbf2198472cbfd5cd63dc3512dabbea339a57910fbbbea29fdace78cc878cd5beb4f8032fe3b0000ffff"
            });
        }

        if (idx == 16) {
            return Compressed({
                uncompressedSize: 7250,
                data: hex"ec973fcb143110c6b370967e025b111b6daef14f231cc2815c7d22585928d8088285fd7d083b0b6bbfcb3516d6622362758dcdbeccde4d7876769299642f2f1cbc0b0fefbb21c9fcf264929d0b8bdb87ee56b87727c0d3876edb7ff8def78f9efe8fa2776a5715f6c3df5cbf1f7ffb41d42774db603c9141996bd46788cd1a33a873c2bc2e0662c6f9b372f800fd82f3998ca5b9e5feb0a4dfccc3e236e1a56f2fc2de9f0f865fedf36177547aeef9f9709c5f59ff6e2c5fde94e703ae53c6f3c48e63d4f8b456fc6be766425a9eca7ccde4a33f3ede0527e5626798bc3e8cce068acf68eeaccafb15e5cc0988bf9bc4d762e4e26b6db50c9e3557ee879be15cf12f8841e5b861b0f763fbae77b59d83a13456aaff1c06e64059becbfecefba1c9f9e03bc6882fefeca4179e9858b3381952df8e2a2f387eac9b7c1ee4bea19103bf615e0f0ae2bb6b1a8b03fd877a309cf199d41446ed121a3fb9daaa66be6e31f9c11742ffe0fe5d55cf1e2f4d3d593e34fbd05ce642677010c3fbb76f4c96961ccc40fafce96396a51507323007e93a392483c793161c1a83e5c91c8e122f90437ae2607079824a312007498e9bcbf1e5ebb7287a7fb17eeee6c071b51c18ffe7af3f51f49e6379fdeae5201c47ffd77068f13d2cd4961ad78283592836e663ae7f2907ee87c522cf522b8edcbca5ba308ec872a91cbfff1d061f5b727858f8feb7584a394ace0c7bc11cf49e3ae3ad389001bf671a4b29c76abd99b07819522c25773ac5277973325793200bf2708cd57a936490ebe639a43c7511faa2f1502cc1a27ac0dc5a1d90aa3d530ce8b55cd3892532805f134ead1ed01864db699cbaf7c865ec957a8e9029e58b12dfcac9fa1f9769d53c57010000ffff"
            });
        }

        if (idx == 17) {
            return Compressed({
                uncompressedSize: 7358,
                data: hex"d4d7214f23511000e0bda4fac4aa2667aace549c3a71c9894b7aa224d4d04a4c8380041ca2b5087e411586206a5148c29f40a2090681422f996667339d9df7decc6ea7c93699842dfbdefb7676df7626eb7d9f7feb653f7f64e453cc8779b19afe12e379314ac6d3f9dfe43930d77c9867914f2b07188af551d2e2e940c326ee4fa2162fc796a17440ecd351332872e2e1100d899cb4719872411c3c270a832a27348206e280e0e3da3a6eeed655c0f1c3e51fb5838e6beaa0ebbfbcbe5701c731cbe3d56413741cfcddc421adafb1c077a1711e0eb4c0daf4798c9d6f75d0fb91b2f0bde4e588cd6b8d8e392a4b571d6f1f9f9b3c7a3a34167cffa72c568765cf602ed001c7a13deee5a006fa7b2659ac8ed17852b3680d218be59d0eeb43689fc9584d422dd4836b8cc693a0815f37cec1435317d1bc481e588b59c41ca05baa0342b567c80073e07cfc9a4a4b6520f9aa39611eee910cfcbb729c78efa92b71afc47d444da1bc08eba79ec9ace167cbc4a2c97cf5e632ef0f8adfff66621c1e2f93f17f7a913c07e6cafb83e885b67180e16cb94a5a3c1d6880585cdf462d5e0e6a4007c43e1ddca0c989874332a472d2c661c90575f09c280caa9cd00819a803828f6beba0c5081c1fcc4ed50e3aaea923d65cc62cf03f08de5c3671689a4bc9c2d7a7e1e1400bac4d9fc7d8f95687a568e77bc9cbb1cb66aa638ecad25507147990474f87c682efff94c5eab0ec19cc053a62cda597831ae8ef59a8b9b438a090e616ad2164b1bcd32dcd65aa26a116afe6525317d1bc481e6b7329d501a1da3364803976d15cc23cdc2319f877e5b89d3797e84153282fc2fa6ecd2535b16832df57000000ffff"
            });
        }

        if (idx == 18) {
            return Compressed({
                uncompressedSize: 7358,
                data: hex"d4d7314b23511000e03d487d6d8a04d21d84ab8fabae0a07d1b08d9d48d01041309588a58d7616da05b48ae03ff0bf58a4161b0b2bebc884cc324ee6bd37b39b096c60c05df6bdf7edecbe75266bfc1cfd6864bf5a19f92d3aade662d0ff2fc6e4649c8ca3e17ef21a98abd36a66915f250718ee6eae92164f071a201ea6b7518b97831ad001b14d07376872e2e1900ca99c54715872411d3c270a832a27344206ea80e0e3aa3aee674f45c0f1f1e840eda0e3ca3ae8faf3d7f722e03866393f9b2c838e83bfcb38a4f5351638171ae7e1400bac4ddfc7d8f556077d1e290bdf4b5e8ed8bcd6a899a3b0d4d5f1f6f1b9cca3a74363c1ef7fca627558f60ce6021d701cdae35e0e6aa0ffcf248bd5d1ebe76b16ad2164b17cd3617d08ed3b19ab49a8857a708d5e3f0f1af87de31c3c347511cd8be481b59845cc01baa53a20547b860c3007cec7ef6965290c245f6b4e98877b24033fb71a273e7bea4a3c2b711f5153282fc2faa977322bf9fb66625166bef5e6b29bb717bb97bfc5387dfe978cc3c7bfc96b60ae6ede8ede681507182e5e06498ba7030d10d7f361d4e2e5a00674406cd3c10d9a9c783824432a27551c965c5007cf89c2a0ca098d90813a20f8b8aa0e5a8cc0f1def48fda41c79575c49acb98653cdb59066f2ecb3834cda5648173a1711e0eb4c0daf47d8c5d6f75588a76be97bc1c9b6ca66ae6282c757540910779f474682cf8fd4f59ac0ecb9ec15ca023d65c7a39a881fe3f0b3597160714d2dca235842c966fbaa5b94cd524d4e2d55c6aea229a17c9636d2ea53a20547b860c30c7269a4b98877b24033fb71ab7f1e6123d680ae54558dfadb9a4261665e6fb0a0000ffff"
            });
        }

        if (idx == 19) {
            return Compressed({
                uncompressedSize: 7358,
                data: hex"d4d7314b23511000e03d487da4bf2ec575f915292e4dfa85bbe2eec0fc000b11ec140b416c2cc4ce229d88451041b1f02f98ce5a6c525889a2c5ca84cc3a4ee6bd37b39b096c60c05df6bdf7edecbe75266b7dfff7ad95fdfc91915f9177f262f46724c674679a8cc9c624790dcc9577f22cf2abe500c3cb6991b4783ad000f13a8e5bbc1cd4800e88553ab84193130f876448e5a48ec3920beae03951185439a111325007041f57d7717cf219707cb639563be8b8aa0ebafefdc3b40c388e592e76af6741c7c1df551cd2fa1a0b9c0b8df370a005d6a6ef63ec7aab833e8f9485ef252f476c5e6b34cc515a9aea787c7a9ee5d1d3a1b1e0f73f65b13a2c7b0673810e380eed712f0735d0ff6792c5eae8f5070b16ad2164b17cd3617d08ed3b19ab49a8857a708d5e7f1034f0fbc6397868ea229a17c9036b318b9803744b7540a8f60c19600e9c8fdfd3dc521a48be169c300ff748067e6e3e4e7cf6d4957856e23ea2a6505e84f553ef6456f1f7c5c4a2ca7c8bcde5b0dd2d0e7ffd15e36e6d2f1937bfb792d7c05cc376377aa3751c6078dbbf4a5a3c1d6880783fba8d5abc1cd4800e88553ab84193130f876448e5a48ec3920beae03951185439a111325007041f57d7418b11383effbfad76d071551db1e63266b95c3f98056f2eab3834cda5648173a1711e0eb4c0daf47d8c5d6f75588a76be97bc1ccb6ca61ae6282d4d7540910779f474682cf8fd4f59ac0ecb9ec15ca023d65c7a39a881fe3f0b3597160714d2dca235842c966fbaa5b94cd524d4e2d55c6aea229a17c9636d2ea53a20547b860c30c7329a4b98877b24033f371fb7f4e6123d680ae54558dfadb9a4261655e6fb080000ffff"
            });
        }

        if (idx == 20) {
            return Compressed({
                uncompressedSize: 7358,
                data: hex"d4d7b1ce12411000e033a1b680d2ded2c6d20e1a4ce401b030b13221b4d8f82436c44b28edf029682c8c31da91181a0a2b6cf93317e632ff30b333b3c792dc249370c7edee7773b7cb520d9ebe7f32a89e3fab489c87a3f9f9e58bb598afc77b33c7af76e635d0d77034af12d1c90186e587936929e94003e4a78fff9396520e6a4007e43d1ddce0a949098764b06ad2c511a90575f09a380cae9ad0d40cd401c9db75757cfeb269138edf4cbfba1db45dae838effe7efb14d384e59debdfdd6246d079f731cd2f81e0b9cd3da9570a005c6a6ef63eafaa8833e0fcbc2e7522947aadf68f6ccd15afaea38fc3b35752ce9f05870fdb72c514764ce602dd001c7da1c2fe5a006fa7b2659a28ec9747665f11a344b644d87f121bdef646a4f422dd483634ca633d5c0ef1bfbe0e9d917d1ba481e188b59c41aa05bda07687b4fcd007d607ffc9e2e96d640ea75e5847eb84732f0739776e2b3a72ee35989f3889ab4ba08e35bef6495198f4c2c73fabbfe73b95a2ece9b7a2de6f1b037f3c7f79d790df4b55a2e9237dac5010608cb52d281068c94a594831b30eee9d00ca99a947058716b47b4165a4d1c06574d687a83b7ebeaf8fdeb679b70bcdd6edd0eda2ed741c7a701c7294b5dd74dd276f039c7218defb1c039ad5d09075af8dc4845d4419f876589cce72e8e5b46cf1cada5cf0ecffad6c5e1b1e0fa6f59a28ee89cf13802eb589683ff166a961c07b7780d9a25baa6437adfc9d49e44ab0b8ea1989aef22bfa1d6be88d645f2c058cc22d680b8dd7b55cd40fb52e64ffb1dbd5672728f64e0e7527d5197f1acd4f7074d5a5d32faccfe73c9ef2b784f3c1e020000ffff"
            });
        }

        if (idx == 21) {
            return Compressed({
                uncompressedSize: 5630,
                data: hex"ec963f4a44410cc6674150bcc2568a858d9558c836c236dbec153c815ec31b58a88d85f7f01e226261e709b47992c7cb909d4932993f4fd07d0b1fcadbccf79b243379eb76f66f677bee60de9d2d16ddf3eb5b2478cee9e6fec1af79fffa6663381fc1d30d1fef8d0a182ef8780fba07f89faed764c983c4455cfc8eab5d983bf82343a9b3f787e7a1b7b6bf54beb5fdb8bcbaeec5f4c1dc8f617d24f4260c4bdf222edd67e867f1c698c09fcdd15aebc49d52fde95d4069de0a73c31fcf16159e4f54ca338ca7e74ff2e73c347fee99c4b0ec39a35e2ca395ff2f32d89eff1786c6e1bed3e23546ae97149f62e4de756e4deaaed7f481998be67a49f383cb479a8b39b970b34cf18f3896b35ce01fcd798dc3cd34e1bd6162a57eaf1478e7be23536b67bbee70de81c9c9f1d186ee1e9f7abd7c7c56ebe2fcb4f704cec41a8785bc948f654fb5ac90a1317358e84395da038d0316bd3863f50cd60f3989ac9667037c24564b8ec6b2f4e42fb35a71b688e57913ab9e659defb9d25823deafd1ea287022560b9ec22aca0dde4f059c6c1e7050059c9eb55cadcd0c89b75cadcd1cf88ba2e754e2600cae31f03056acad208bcf4f000000ffff"
            });
        }

        if (idx == 22) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ecd6214fc5301007f091902070554b300b760285279999600a24661f000ddf038543f08990681c1f62e4ca6ee9de76ddb5bd4bdecbfa92cb33ddfdd6755dffc5f9e5f3d945717d35f4b519de1e6e66f5fef169ebfbe737b9be5e1adb139c6ce958e86df5e1dc53aa7568f8cc100bfbb8b5750fee38b0fada14e34f6dcde0fa714ea425f96e401fca92747c16674d4ed9927276644d5eb6d22deef73db47c96e2fe527b8e84b3b0243c8f153537389f229c600f1cac08c75a4ddbb10dca6bda8eedc03f969b152807c7e0350c0fc792cf96284e9fffa06dca6ab8bd7b9c95e4cb7ffff46a7b82932d1d0b3d89a09d6a8504ed102b35688365ca6ada105a6b06d78f73222de9c385b2340ecc354b2bfc1e8b251da676604d5eb6d22deef73db47c96e2fe527b8e84b3b0a482366145cd0dcea70827d803072bc261056dd7a0bcd8a0ed6605cac13152411bfbad14a7cf5f000000ffff"
            });
        }

        if (idx == 23) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ecd6414ac5301006e00a820b0fd0450b0577c533b82a4251720a1782e2113c883b17dec0dbb876e7212a93d729e96b279d2433f01ecd83e16dd2f99aa669fee2f2faede2aab8a986a62a87c7fe7e561f9f5fb67e7eff92ebf5f9c9f604275b3a167a5b7d38f7946a1d1b3e33c4c23e6e6ddd833b0eaca62a8bf1a7b66670fd3827d2927c37a00f65493a3e8bb326e76c49393bb2262f5be916f7fb1e5a3e4b717fa93d47c25958129ec78a9a1b9c4f114eb0070e568463adae376c83f2badeb01df8c772b302e5e018bc86e1e158f2d912c5e97308daada98787f7db5949befc2fdf77b62738d9d2b1d09308daa95648d00eb152833658ada9a70da1b56670fd3827d2923e5c284be3c05cb3b4c2efa958d2616a07d6e4652bdde27edf43cb6729ee2fb5e748380b4b2a681356d4dce07c8a70823d70b0221c56d0760dca8b0dda6e56a01c1c2315b4b1df4a71fafc070000ffff"
            });
        }

        if (idx == 24) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ecd6a16e8630100770962c9998c1cfe1790ac430f88a8999e1f61453d35373133cd1e4f41c0fc172c09132b8726def92ef0bfd92cb67cafd28a5f49fdddebfdedc65c5c3600a33744fddaa3ebfa6faf9eda3ab7febc79ee0244bc742efa80fe79e62adff86cbf4b1b08f5d47f7608f03cb14269b7f6a6b06d7cf73222dc97703fa5096a4e3b2386b72cd969473226bf192156f71bfefbee5b214f797da73249c8d25e139aca0b9c1f914e0787be0600538a355d50ddba0bcaa6ed80efc63d9598172700c5ec3f0702cf96c89e2f49982769b97c3c7e3f3aa245ffeef97f7b12738c9d2b1d09308dab1964fd0f6b1628336586d5e2e1b426bcde0fa794ea4257db85096c681b9676985df4bb1a4c3d409acc54b56bcc5fdbefb96cb52dc5f6acf9170369654d026aca0b9c1f914e0787be0600538aca06d1b94171ab4edac403938462a6863bf9de2f4f90b0000ffff"
            });
        }

        if (idx == 25) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ecd6b14ec3301006e0202131b0b5231b0fc0c21bd0a50c7d80be4255c63e0c4b0552df20cf82106c95104b1f22e84cce7293def96cdf0d505bfad5a197fb62274ed25c5e3f5d5c35b737dd64baeceeefb647797ed9b97c7e1d8af3f8b0773dc1a9968d855eac8fe49c4aada1c1992916f609133b87b00eacc974d9f4c3ec9ac1f1fd9c484bf3de803e94a5e97096e49afc654bcb3923cb7bd52ab7a4cff7d47096e1fe325b47c219591a1e6365cd0dde4f194eb2070e26c371d66cbe101b94379b2fc40efc62c26f05cac11a3c46e0612db9b644247d7e3fb437eb55b77bdd1ee5e3fdcd45631cbef7ae2738d5b2b1d08b8db66d5d2cada1c1992916f609133b87b00eaccd7ae537c4294fb23e9235eee7445a9af706f4a12c4d87b3d0f9af96e63813cb7bd52ab7a4cff7d4c15986fbcb6c1d09676469788c953537783f6538c91e38980cc75b5283f2a473ea6b4781fb947286b5020f6bb9ff4e45d2e7270000ffff"
            });
        }

        if (idx == 26) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ccd63b4a04411006e01604033353333110440c8ccc046fa02710030331f6204666067b224363330f3152bab5b4337ffd5d5d35ee030a16a6abbee9d77497ddfda79dbd727438945286b3936318579717663c3edcc3ff28a496383d96d644b5d9b38ce5ed6fc65ae71846236259ed3c79cc42464f3fb4fdd2d11fed5b662c35df63cd314f1e0be57e7c7eb902cc95dbf21ac88cf6cbe31a6b3064318fecadb085bcc63ede8405bd6db25edf167f2263b53c79ae0e6bebb5ac1a7286a098db62671539278bd7d3f09ccbe45b58feeb1bdcb0265ec490be6b6ee1bf1f2b6a48e8bb36aca6339eaf7a0dd66352b76196b59eeb7a28d40039a645a224f37e2fda77a707c3cbed398cf7e76b3386c50dfc8f426a89d363694d549b3dcb58defe66ac758e61342296d5ce93c72c64f4f443db2f9dd526617dcb8ca5e67bac39e6c963a15cefa517cc95db8a5eb423568f6bacc190c53cb2b7c216f21afb781316f4b6c91a5fb43356cb93e7eab0b65ecbaa2167088ab92d76569173727251697d833de732f91686c731694dbc88217dd75ce2acaca821a1efdab09ace78beea35589ff1751b365fd67aaeeba15003e49816093a1e8ebcef000000ffff"
            });
        }

        if (idx == 27) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ccd6bd4ac5500c07f00a82839b8bc21d14dfc1dd4510747474735010f73b3bba3838b939f854ce6e3ec49560538eed3fff939394fb01810b3dc9afe7a34dbbddfda79dbdee74b13a383a599d9ddfc0b8be5d9af1b07c83ff51482d715a2cad896ab36b19cb3bdf8cb5ce358c46c4b2c679f298858c9679e8f8dee9fa1f9d5b662d35df63cdb14f1e0be57e7dffb802ec95dbf21ac88ccecbe31a673064318f3c5b610b7995e7781316f4b6c97afff8fc1719abe6c97575d858af65d5901e82626e8bf52ad227bbd1affa0ef6f465f22e0caf63d29a781143e6aeb9c419aca821a1f75ab1aace78bfca3358f6f8720cdb2feb3c97f550a801724c8b045d0f47dedf87f6f1e27075757901e3f1fece8cd79767f81f85d412a7c5d29aa836bb96b1bcf3cd58eb5cc368442c6b9c278f59c86899878eef9de1216173cbaca5e67bac39f6c963a15cef472fd82bb715fdd08e582dae71064316f3c8b315b69057798e3761416f9bacf18776c6aa79725d1d36d66b5935a487a098db62bd8af4c9c9874aed1dece9cbe45d185ec7a435f12286cc5d73893358514342efb562559df17e9567b0ecf1e518b65fd6792eeba15003e4981609ba1e8ebcdf000000ffff"
            });
        }

        if (idx == 28) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ccd63b4ec4400c06e02021517004a8b6439c810b80e8b7e004489494549c828e221d2577a1a0a6cb0128832ce26836f9fd8f6347fb902cad94b1bfcc23719ad3f3a793b36673d15fdd5ff6b72fd7301e3f6fcc78feba83ff51482d7196585a13d566d7329677be196b9f6b188d88658df3e4310b194be6a1e307a7197e746e99b5d47c8fb5c63e792c94fbfdd3b902ec95dbf21ac88ccecbe31a673064318f3c5b610b7995e7f81016f48ec97a7b6f772263d53cb9ae0e1bebb5ac1ad24350ac6db15e45fa6433f955dfc19ebe4cde85e1754c5a332f62c8dc359738a3153524f45e2b56d599ee577906cb1e5f8e61fb659de7b21e0a35408e6991a0ebe1c8fbffd0de6eb67dfbd0c2e85e3b337e3f7af81f85d4126789a535516d762d6379e79bb1f6b986d18858d6384f1eb390b1641e3a7e70c68784cd2db3969aefb1d6d8278f8572bd1fbd60afdc56f4433b622d718d3318b298479eadb085bcca737c080b7ac7644d3fb43356cd93ebeab0b15ecbaa213d04c5da16eb55a44fce3e546aef604f5f26efc2f03a26ad99173164ee9a4b9cd18a1a127aaf15abea4cf7ab3c83658f2fc7b0fdb2ce73590f851a20c7b448d0f570e4fd050000ffff"
            });
        }

        if (idx == 29) {
            return Compressed({
                uncompressedSize: 5846,
                data: hex"ccd6bd4ac5500c07f00a82838be8e8e6ae8b6fe0223e829b8bbae883086e4e2ee2e053f8188e6e829bb38bcb9560538eed3fff939394fb01810b3dc9afe7a34dbbcdeddb8dadee607f71b573b87838bd80f1767967c6cffd2bfc8f426a89d362694d549b5dcb58def966ac65ae6134229635ce93c72c64b4cc43c7f74ed7ffe8dc326ba9f91e6b8e7df25828f7fdf3cb1560afdc96d74066745e1ed73883218b79e4d90a5bc8ab3cc7abb0a0b74ed6e3f3cbbfc858354faeabc3c67a2dab86f41014735bac57913ed98d7ed577b0a72f937761781d93d6c48b183277cd25ce60450d09bdd78a5575c6fb559ec1b2c79763d87e59e7b9ac87420d90635a24e87a38f2fe3eb477f7ce17c7474f30ce4e3eccb8b9fe86ff51482d715a2cad896ab36b19cb3bdf8cb5cc358c46c4b2c679f298858c9679e8f8de191e1236b7cc5a6abec79a639f3c16caf57ef482bd725bd10fed88d5e21a673064318f3c5b610b7995e7781516f4d6c91a7f6867ac9a27d7d56163bd9655437a088ab92dd6ab489f9c7ca8d4dec19ebe4cde85e1754c5a132f62c8dc35973883153524f45e2b56d519ef577906cb1e5f8e61fb659de7b21e0a35408e6991a0ebe1c8fb0d0000ffff"
            });
        }

        if (idx == 30) {
            return Compressed({
                uncompressedSize: 5954,
                data: hex"ecd6bd4ac4401007f013040b1f412bb1b0b1b2b2b311041fc342f0a3f4616c44e1de2095ad95cf6027c83557585947e6c81c93c97ced6c50212efc315e76e797646fb337dbdcbeddd89aededb4773757edfce941cc72f1ae069a742c056a815362614da9b675aec68ade6f8df593cf309b8ca5f58b8cb32cc928b90fecdf39b3ae99f756f32c717cc41a639e2296f6dd8b3461aec256b665ac1257f90ea62ccb33d656da923c671dff86257a7fc96a9aa6971acbf3e03c3a56dfa855baa6c7b6acb909acaff03b38b22f1befc2f473acb4065ec68086630d676d650d6878ad8ee53a7cbe68a37b3ced63cd97d5b09e14348431aa65c47c1e8171f0437bb785018707fb624e8e8f7ab9bebc08858f835ae04cdd8a3a9237552b3b57dcea9cf52291bc88757e76baca5816fecfebc2f1fde3bc7dfb580e3e87d05a110bfe423d1aac05c7cf2fafaba0879fd3442c74a00e0faf87d1fa7a96365673b5f38bcf2fd38a3ad14cc01a78ff56bd15f5f0dde2ad09cff23cfebe2cb04c0fd6230d77a8c7fb6a3f8aa2fb8bb607f03d8bbd0bab2d6d1f21fba3e9d0fe9e6739c27d0d1c0cbf4fc9f1f6faaecec092ae13cfd33e529c6bee5968d0dad2fd2b11fbe0b52be7c76cbcee77000000ffff"
            });
        }

        if (idx == 31) {
            return Compressed({
                uncompressedSize: 6062,
                data: hex"ecd6214f33411006e0fb922f41e0aa10088245a010381214090a2a3128f008fa3faa7088fe03141685c6812618040a7d648e1b32f7eeccceb4b76edbe44daf777bf3dca6b99d6dfe6fbefedb6876b7dbcbbd493b3fdf57f3727b3c48bb380b05efa35ae4d46e451dcdabd55af5bf42ab779afea37a11ebe1e6b04b298b7f635d3abebb5fb46fef9fc9798aac15b1e89beac9702d3a7e7c7aeec21e9f978958ec501d0cd6e358633dcbbad772adeb1f5fdf592bea44538195786b6bbc15f5786df1de09cff23c5c2f97b0b21ebd8f32e8480fc72a4e76adb26a630fc09e056be168cbea23a23f661d39def3728e32afc4e1e03c35c7ebf57d9dc4d29e93ef9563b46886b836b0d890b5b5f91b51c7f0b31bd79b821facfbbba99f6cedb407475335a717b341ae67f350f03eaa454eed56d4d1bc5aad55ff2bb47ae7ef65d0bc887532bdea52cae2df58978eb9a1e2798aac15b1e81b37d35c0b37f5f2bc4cc462a7c4a6deb34a6eea7356e98d5b0556e2adadf156d4e3b5c57b273ccbf370bd5cc2ca7ab85147477a385671b26b95551b7b00f62c580b475b561f11fd31ebc8f19e97739479250e07e7a9395eafefeb2496f69c7caf1ca34533c4b581c586acadcddf883a869fddb85e74530f757f020000ffff"
            });
        }

        if (idx == 32) {
            return Compressed({
                uncompressedSize: 6062,
                data: hex"ecd6214b04511007f01504831fc0e0816013b3d1288887c56a120541b3d162b4d8049bc16f60b29afc048266b1184ce695397764f6ff66deccddbef6eee0cfededbe9ddf3e8e7df39ac5e5b785a5667dd4aeadaeb4e3dd1d35e7a7c7bddc5c5f8582f7512d726ab7a28ee6d56acdfa5fa1d5394df751bd887572743849298b7f635d3abebb7f68df3fbe92f314592b62d137d593e15a74fcf4fc32097b7c5e2662b1437530588f638df52ceb5ecbb5ae7f7eff64ada8134d0556e2cdade156d4e3b5c57b273ccbf370bd9cc2ca7af43ecaa0233d1cab38d9b5caaa8d3d007b16ac85832dab8f88fe9875e478cfcb39cabc128783f3d41cafd77775124b7b4ebe578ed1a219e25acf6243d6d6e66f441dc3cf6e5c6f0a7eb0eedfa67e637fd4ee5d6eaa397bdceee5e2751c0ade47b5c8a9dd8a3a9a57ab35eb7f8556e7fcbf0c9a17b10e6eb7262965f16fac4bc7dc50f13c45d68a58f48d9b69ae859b7a795e2662b1536253ef592537f539abf4c6ad022bf1e6d6702beaf1dae2bd139ee579b85e4e61653ddca8a3233d1cab38d9b5caaa8d3d007b16ac85832dab8f88fe9875e478cfcb39cabc128783f3d41cafd77775124b7b4ebe578ed1a219e25acf6243d6d6e66f441dc3cf6e5c2fbaa987babf010000ffff"
            });
        }

        if (idx == 33) {
            return Compressed({
                uncompressedSize: 6062,
                data: hex"ecd6a14ef4401007f07ec99720303c00ea3ccfc12b9c40101278063428121c0a8738470802051285c68126980a1421c1944ce990e97f6776e6aeebf62ef9e77aed767edd5cbab3cdffcd977f1bcd6cbb9bcfe6dd626fa1a63d6d47f9baee42c1fba81639b55b5147f36ab556fdafd01a9c66f8a85ec4ba39beeb53cae2df58978e2faf16ddeb5b9b9ca7c85a118bbea99e0cd7a2e3fbc7a73eecf1799988c50ed5c1603d8e35d6b3ac7b2dd7bafefef199b5a24e34155889b7b6a65b518fd716ef9df02ccfc3f572092bebd1fb28838ef470ace264d72aab36f600ec59b0164eb6ac3e22fa63d691e33d2fe728f34a1c0ece5373bc5e3fd4492ced39f95e39468b66886b238b0d595b9bbf11750c3fbb71bd29f8c1babf9bfaa3ad9dee62775fcdf3e1d928dfe70fa1e07d548b9cdaada8a379b55aabfe57680dcedfcba07911ebf6e0a44f298b7f635d3ae6868ae729b256c4a26fdc4c732ddcd4cbf332118b9d129b7acf2ab9a9cf59a5376e155889b7b6a65b518fd716ef9df02ccfc3f572092bebe1461d1de9e158c5c9ae55566dec01d8b3602d9c6c597d44f4c7ac23c77b5ece51e695381c9ca7e678bd7ea89358da73f2bd728c16cd10d746161bb2b6367f23ea187e76e37ad14d3dd4fd090000ffff"
            });
        }

        if (idx == 34) {
            return Compressed({
                uncompressedSize: 6062,
                data: hex"ecd6b14a03411006e013040b3b6dad7c001bdfc04ac117f0090449ebc3d80485947657d95af90222b10b489a1456a94fe6bc0973ffceeccce5aebb5bf8c925bb3bdf2dc9eda6383c5e1e1c15e767d5c9e95d757931577373b56a6576bf0d05e7512d72c66e451dcd1babb5ef778556e3144d53bd88757bfd5a67288bdf635dba7e7a5e54df3f9be4738aac15b1e895eac9702dba7e7bffa8c31e7f2e13b1d8a13a18acc7b1c67a9635d772adfef5ef366b459d68466025de64f5b7a21eef2dde33e1599e87fb65072bebd1f328838ef470ace264f72aab369e017866c15ed8dbb2ce11713e661d39def3728eb2aec4e1e03a35c73beb9b3a89a5dd27cf9563b46886e86b596cc8dadafa8da863f8de8dfe62c08675ffffd43fce1eaac5cb5ccd66bd6a25da701ed52267ec56d73659fb7f576835ceee61d0bc885596659da12c7e8f75e97af9f5b9bb465fd68a58f44af564b8163b68e0f888c58ed6b01ec71aeb59d65ccbcdb59c1575a26d0456e24d567f2bea45f64a7abe3dcbf3a27bb36275f2d0c9798a93ddabacda68e099057b616fcb3a47c4f99875e478cfcb39caba128783ebd41cefac6fea2496769f3c578ed1a219a2af6589df8d4cb27e23ea18be77a37fd03ff550f72f0000ffff"
            });
        }

        if (idx == 35) {
            return Compressed({
                uncompressedSize: 4269,
                data: hex"b496bf6b145110c73782885c0c61235c7181236538a345d258a451e4fcc1ab2c2460712118511bbbd8d8d8696391ce22dcff606767659fda462d056bb15979df7bb3cecece9bd93bbc816ff1663efb9d7d6f87c7166b177e5cdcbbf4ecf2a7d5dedae3952bbdadab458a4ac80b8b476e7fef5a43455104cb4be15bb5e1a0df90e7a5f0755dd63cbf0cbf143f998f61f9197cc83199ef61f12d862918b3d2850f425ee4f895d5de56d938a0c351c9e50eb6c3235fc7e74790e1ebf1b37aca4b65fbdb3c98f393db107d405a1f8ecaa0799e3ebc0129bcea1983f3c3413ff00fae0d65e4a5a7eccb7ccc81e2def1f9b4af797cbaf8c75bf2dfc72a6ebee4f26fc93c8f1cc5cfea0f64785a3c6a9493523c3d7ea62f1554df00699df32ba615a4f0d0eeaf0aa261e0ec70d06ff869c313f9f87cfd7e53d3237b8e8d5b6d3af39bd3c3f36edf42624373bda4c2d78712e3fdbb3790e1ebf1a8535e2ad7dfe1c1bc787a04d15ed83a689e0feede81145ef58cc1f92eb750e4a5a7ecbbc82d949e5fca2dd41aa8edb0c9e50e94c3234ff1eafb1164f87a3cea9497caf5777830cf3fee4374c0b4de0e9b41f3bcff7a0429bcea1983f35d062af2d253f65d64a0e2f3695fcb1fa8e3f51d2e77a01c1ef93acebe4286afc7cfea292f95ed6ff360ce9fbc85eaff9eb43e5edf099ae7e9780229bcea89ff1ec677fa4f1a4f5a9eb2ef42ff49e309ed6bf903556e1c70b903e5f0c8539c7cf80d19be1e8f3ae5a572fd1d1eccbd5bdf203a605a971b0741f3dcbd7e0629bcea1983f35d062af2d253f65d64a0e2f3695fff7ba0fe060000ffff"
            });
        }

        if (idx == 36) {
            return Compressed({
                uncompressedSize: 4461,
                data: hex"bc95316814411486372288894971064404c5ca22a560b0132eed145629acae5d5204345a59a655244d2c44c1522c6c6c259d82552045b8dec65204393846e6edbcbd376fdfbc37b72e0efc243bf3cd3737338fdd6ae3c2d1c5af97ae5faed7de6e3c59595fbb7db58acdef6cdfa3a98ca6f1d03779f4b0cdfb37af3427f081a173220f63cf9fd67c3dec135d0a9ffcef3fdf8728fb4e1c94977c989f3fa6fedb970f595f180b4ceef7510fba3267d89e1d3a993761684aee43e187aa975084a316ba75e31a8d2955783ef638f695ba28cfc72ca7c5ff2f1fc61197fb079f33ee83bb5fb3676b7ea97be50a291a38a083bd9ac62c1c83877ede14afc58be38ab78407e6fcf43b040f199f0ff66a27398f8f5e42045e748646797289622121cf9d7cdd1ec504f3e3be86282abda056c787346641193cf463db3f6fa2782d1ec6b19f27b7bec103b3fd6e0ec103c6e7d5f1a1939c77f63f41045e748646f992820a3c77f275fb1454981ff7357841d1cf9afbe38f694c91c287673ff7bf6934a7c6e358a758324e8da77fc58256e695f2fcb794f4155fde803eeb3e7263a16836db036031df400a0f7dbb0fd2c48acdba04be3376f2a2f2dedfe54cd625f0edb83f6bc629a3f9323cc4cfa64dceaa457e7dccfa147eb1de6cdaac15c7ccdf27f36ec9fb70c67d240c89b3de5406ef584ade7e121f3ead9bc9014db6463466611b3cf4b7ed641732d91a658b7be7e6bac4a7bed8cf935d5fe781397d3686e0a7069f734e834f187646d2fe3bced0c87cc7cebae4d2132726ec3bb3afe2cfa8e4ede9eb7897dc63dfc2ff1b0000ffff"
            });
        }

        revert InvalidBucketIndex();
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import {IBucketStorage, Compressed} from "solidify-contracts/IBucketStorage.sol";

/**
 * @notice Stores a list of compressed buckets in contract code.
 */
contract LayerBucketStorage2 is IBucketStorage {
    /**
     * @notice Returns number of buckets stored in this contract.
     */
    function numBuckets() external pure returns (uint256) {
        return 28;
    }

    /**
     * @notice Returns the number of fields stored in this contract.
     */
    function numFields() external pure returns (uint256) {
        return 109;
    }

    /**
     * @notice Returns number of fields in each bucket in this storge.
     */
    function numFieldsPerBucket() external pure returns (uint256[] memory) {
        bytes memory num_ = hex"0606060606080a050503010103030304030402020404010302040301";

        uint256[] memory num = new uint[](28);
        for (uint256 i; i < 28;) {
            num[i] = uint8(num_[i]);
            unchecked {
                ++i;
            }
        }
        return num;
    }

    /**
     * @notice Returns the bucket with a given index.
     * @dev Reverts if the index is out-of-bounds.
     */
    function getBucket(uint256 idx) external pure returns (Compressed memory) {
        if (idx == 0) {
            return Compressed({
                uncompressedSize: 4462,
                data: hex"bc96bf4b235110c7f73802079b1c211b2e4572e4d25d8a54070729ee8a6b0e8b679f3a18419b8085d676dad85b48fe07ff087b6b1bed44103bc5c29537d989f37ecccedb4774e05bbcc9773f9b99f72d36a97faed55ebe3ca60f5f6f3fd5d3413b219527e339552294e4873ed65dfe0c4ac673c5f27e6efafc060ffbb6b8f70bfee57fbfc841fd6e0784678e29f8c1f3eb3e07593b5a6a913b4cf46b9e2ee3f9455ef63c7b37c840e9b90b661251abff617323790eb7e28c61dc3761df0d3e5e6421112cf85797a8ebe4f810d4ef76d8e07fcb9a3ebfc1c3be2deefd821f3cbbdb5310ce42ce5ea6e0f77a8894c4d445cecadab50ab974ca44e9b999b9424a71dc489ec3ad386308978a0ffe50f5a8c4e50a7ee8631ddc4c4143d56383fffd77dbe73778d8b7c5bd5ff08367e7fc0f08178f678e29f80d8fb523dffc0e5317795e59bb0e0a3e65a2f4dccc5cc101f57123790eb7e28ceb0bfeac39a212972bf8a1bfaab32bd0ac396283ff3ffde1f39bbca26f8b7d7fb91f3c975b47200c329e39a6e0373cd68e7cf33b4c5de47965ed3a28f89489d27333730507d4c78de439dc8a33ae2ff8ad6c42252e57f0431f6bfff409d4ca266cf01b8dbf3ebfc1c3be2deefd821f3c1bffae4118643c734cc16f78ac1df9e67798bac8f3cada7550f02913a5e766e60a0ea88f1bc973b815678c0e7e231d64eff17d6fffb657f44259d4effb462e634afe8fe2957ecf47f054e0ee385e952055bdbf1826f65f030000ffff"
            });
        }

        if (idx == 1) {
            return Compressed({
                uncompressedSize: 4546,
                data: hex"cc94314e2b311086bd7a8a1e64139a205150a0087a4a28912245343e02178852d0e408e9390207421450e52454c1689d1d693c9eb1bd8e7761a491b2f63f9f77667f474dfe8d46df279f93fbb37d35a9e7e70a85d9ac57385524627abb4e63b35ee9108fd107f7195d17bdd5ec3ede6c5e5d5ed884678919d13b1a3223ae7f8fd904aad764d65ac5c361420237e1db72a1256e26cfe376ec31858b13c237fe78b1c5191d6e446fd7219e77871c2fb6a2f1ffdf3e717a8707eb34a5f3237aabb97bdddb0423c3b3c48ce81d0d9911d7bfc76c02d56b32eb24e3632664d3b7d057b241396e26cfe376ec31dbf853647c43323ad880deae2d975f4e92c35916d13bacc797c385787837f637d288ac460b35addee101ab8996a9a45e9a7d5c2331e1dc108feaf16fba877b89f1987ac5edb7cf5a3221e6a05ad5fe5678af4d8df6bc77245a4e474d2ab13093d357a7f5cd2cc7b425f4525dac3e556f12b26bcdb13d8538b9e7fe468f290c73e4b7e8d31b437abe9ad6d7b3632f49a8be94618634566966c9771d6a0e7d9abbb491abba9ecf86ba31a50663fec8872e610c957199fabc24a6c03f6fce3b74f1178d9f000000ffff"
            });
        }

        if (idx == 2) {
            return Compressed({
                uncompressedSize: 4266,
                data: hex"b497bf4a334114c5271f7ca06ca245acec8cf8042953d80ab22016b29d0f2108629337107c0dab54f6d6b1b7164bb151148478656e32e364fedc3b3b3b33706067ee6fcf3a7bcf8e44f4ffcdfe5f6e5c57275b07bd41351a8ad5004bdce0780828d6cfe6a1852764e453bc21c3fb6ca3d4fd77ed512ad386eff58d90967880886866aeb08ac26185c48f4b64f4ecb2cfb61f7cee43a654ce7a55b53fe46eca1164917802e50e484a484b043c070f854ef4368187c2ff5d63eeeb7c920faabd1d0d37a3c6146b4ef0b8a6c6c7d352cda8a9292f0faf6b6a4d6a327eb319c78be0515f7780923525390ff911bcae9b3525ca2fc03b75f33ac6cfe26b7b0f52443f28de610cd5445662f8da123742fc7aa8337e317a7d763b41ade635e765f14eede5f11c5edf2f6c26e8e5e19d9a5a93f3901fc1eb6b73ce9dc804eff53f3e1cb3fb0df0b5c9987f7fa01f14ef6598dec6f23943fdf7c310a68ba54e9fa5d850133cfc7c0380b842dd8b3314e149f1f80cb566cbe3c9f1589f8b1b80ed0738dadc45c96b5c0bf8113ccaace33b51f5e9c2f5a3795d578c947c3f9c1fc1af314a9f7308f796e7f5de5739e0f3e2e77f030000ffff"
            });
        }

        if (idx == 3) {
            return Compressed({
                uncompressedSize: 4202,
                data: hex"ac963b4b634114c7ef865d587693261b48912c61cb9072616159b64a6531588a108b205858a5d3da46b0110bc12f912a9d9556e9f305043b11ec04f1c19539de73338ff3980b77e087cc393fff8c33878b59b371f665efebbf6f57adf34fadefbf7e64c5cadff247974c59926ff78b97fcc245ca947caa27656abedbc7df49cda3fcb05fe57c94cfdd4595bf37f4eb7c8fbae7c50e61a7941a330f3554f0a176f97a036c3e1d03b63699f359845ff6ec7e32cf3c1c27ca127cafbfb1ccf2feea73899647f86cbf7937ae9457f85e1febf65e52f2081feaf627f6acebf4a23cc18f1c17e66d53fdf0bdd4f9637c7fa8a7a3b68b1a2af8502bd7f516301db58d9445f8eb5e510b21cea9f9c0ea600c0c7a5d00f75c9ee0477dbbaae405bed747ecd953f208df700ef31e921f390e46989514df04688bf3fd7f17b2bf331775a8051f6ab8eef36740c8947ce8612d84c8d4fc0f963980438a7b2e4ff081df0f3980438a7b2e4ff0bd3e62cf9e92c7f8a4a3bd87e2d7352ffe97152fb8400d15fcf272ed3a3d390206bdae91b208bfec612d8438a7e603d39d6d80d89379821fededaa9217f85e1fb1674fc9237cc339cc7b487ee438a85f56c5aff3cbba1eeaa1e9bba8432df850c37578bb0b0c4d9f1dea9f7f3a945f66612d8438a7e603fb8bff005e32eeb93cc18ffa7655c90b7caf8fd8b3a7e411bee11ce63d243f721cd4a156fcba86fa3d0000ffff"
            });
        }

        if (idx == 4) {
            return Compressed({
                uncompressedSize: 4202,
                data: hex"e496bd4a73411086f37d2048341012c1c242bc80b406b13336165b58062b0b53841482442bcb1496163682a2780fa9bd00ab74419b343682b58d44763c73dc9ff9d903c7ca8107b2330f2f4b76305696ffcf16c68bdbd5c7dad5bfdad2c64a25ab79afde72a92825f9d0cbebf605e8d55b46ca22fc9f59d60b21eea9f9c0e4e802585f5b05f0cce5097e34b755242ff0bd3962ef9e9247f8867398f790fcc87130c2aea4f826402bcef797bad1ecbaa84b2df8d0c33abbfe001acdae91b2083f9f612f84b8a7e6037b3b33009714cf5c9ee047735b45f202df9b23f6ee2979846f3887790fc98f1c0775a915bfcca56ee65fce6e7bd3455d6ac187dec3cde5fcf0603f47c8947c9865678ff3d33e95a9f9de7c3ede0252f308dffb0cf3f77b354ff0a3cfc8dbebb39ac7f8f9f78b3059d17b087e59fbe22f21fed5c85043053f9c9d64bdd42cd70f675aa6e6ffb5bcb2dfa3ec7df17fde8783be8b1a2af8d00b6b38e81b298bf0d959e0a8598e0f4c274f007e2978e6f2043f9adb2a9217f8de1c4147cb237cc339cc7b487ee438a83fef8aff3bffb3563b231775a9051f7a58c7d36faa9d9191b2083f9f612f84b8a7e603edbb4f009714cf5c9ee047735b45f202df9b23f6ee2979846f3887790fc98f1c0775a915bfaca5fe0a0000ffff"
            });
        }

        if (idx == 5) {
            return Compressed({
                uncompressedSize: 4280,
                data: hex"d496c16b1a4114c6c7524aa95aec5ae8a142f122a878eac9432f2d144ad94b2fc54b41a416da8b2062cfbdb5147a6d020939e43fc82da7e41fc8c1801010420c3905720e22bcb0cf7dbbe38cf3de8648601f7cc8bef7e31b9c6f961d557870f170fae8f4f1e4c9496efcf43893cf969fabb0a05b68e85242713cf6667ff7e1e87d3f52b7d0f0392f070fedba07b0fb0946c37796da75cff21278a8fa25188c3fc2f7bd3796aa7ec9f2137850cd1e6ccc01d4f9dc56b367f9093ca8da00b60e00befc8f1554f0ab6a03db8fe7710fbd620b3ebc3d5b92576cadca23091f319a7ce6ac24e17d4352b9f84c2e5b7e661d084de2c116f8c501a33afc8c627c257e310ffba69cebf33c3274e85fbd7c81925e1a86c700a9ef906f062ef049024ed2536cf8f846c512c31778ec535dc20cc5f84a3ccea96fcab5bec023f3fa0a50b4e1f4ecf26478503b20851930b19fcccb39c47e5c8f0fffb68b0a3cf6a9fefdf985627c251ee7d437e55a5fe091f9f1ad83a2ffa23daff464f8f4bef9c1b7599318bec0639feae7b483627c251ee7d437e55a5fe091a1bb096db874b761f8f486bfc6cb6c348f6a7b82627c257e310ffba69cebf33c32a3afbf51d1373c7c7679327c7ac3376e9a62f8028f7daae1e6358af195789c53df946b7d815fbab1d3866b37f7959e0c9f9af0f35af8ebfcde9bb37ed84beaa5f3ae0d71794afc7df9912a9a57e58e415712f6f4ba090000ffff"
            });
        }

        if (idx == 6) {
            return Compressed({
                uncompressedSize: 4278,
                data: hex"d497312f444110c71f21e4cee18e444122578aa8142834ae52bc5a945c901cc53572be8042e20388422e347a9f404f73dd251a5a8996486465d7dbc9ecbb9d9957ec1626f917b7ff5ffe7676b25e36991dae8e4c8ede8dad8f3f97f6cb9f95cba9fad044b95e4d50a9d39316562294c49bf57c31b912eff599dc22bc61fabd27a3c5f93923fb9bca64f85433769d508af28af0d21cd2826bb806875f6a9c6389c31778b36eabddff13932bf1c6b7eb79517f5fe00db3d6fd31b2076e7f53990cff6f865fa9d46ba6a1bde59a4f5428c54396dd78afd3709431ce610a3cf8bab0a71e77d83c860fd96fbca1241b6dbfba6aa0e9a4ab281eb2ec21af7e284719e3e6f13cf8bab0f7aebed93c860fd92ffb1f8bc82b369402d7b9c8b51ec83a3e6a3af25c798907e9c2defded159bc7f021fb8d775396d2059fc84d123c64d98db71e361d658c7388020fbe2eec9dbd35d93c860fd96fbca11c4eaff8446e92e0210bbe1107178e32c639448107df7c2390a76e5ed83c860fd96fbca1d466767d223749f090650f797bebd551c6388728f0e0ebc25ee7fa8bcd63f890fdc61b4aeefd64456e92e0212bff1e91de310c0fbe2eec716f2d810fd96fbca1e4de3556e426091eb2f2ef04e97dc1f0e0ebc21ef70612f890fd861eca6f000000ffff"
            });
        }

        if (idx == 7) {
            return Compressed({
                uncompressedSize: 4263,
                data: hex"e496bf4a034110c6ef104c3cb510e30b04b40b11042d248d0a62718d4d1e4122b626958d8db59d08565ada5988650a3bab14560aa6b10996825838b2ebed65f6cfecee1d9bca818f536ebef9edccedea46c9d47de569a635771a5793fa626488d4225b14c90547a41686cd273146efc3fcc5a0b7adc9e091d6b7b735d464e3f09a37fb00fdf6df3353c6327258cddee5171c1d7c4aca581243e3282ca2a7bc17c651594e0eee25fbd99783596276a2beb11f8585385aa81cc1b2711cfbc0ca22f601c9091cecb0d6421dbe32f9fc03bfbd3cab4a1d0c93c7c9e8763ab0d66848b2f8b887e5301ff6129e9ca1e65b7c3943c883a5adcbc1d21826966b6d14cb8783fd4566a0cc21c5dfded433f6238ee4a3d685e62049e4502cc33e94bcc40cb47e6c2c9fbd1d40a25e5c496a0ba643ed1bbca99d8d752ef8bea5943720724fba87707d75cedfff0c76011ee7f9138bbd13b942c263ca2fe2195d4c73651e696d523f8a0771e89b093d83b83a6bbe320121e735881099cbff457ebc8ec57eefb7c1c5c87d59bec537cef767c91e03cbc7f3701c7109afcba3e65b3d2827f764727978bed257a1398f3960faf6ea7cb18fda2377672d52213d13509c24f5a52840a425af31de7f193d0f6699e0f59a2bcb9a42ae7d42f5c9da4c9bab4df887f5f11ee4f5591d4a25ea163d64d4b98040fb1a267c3e7e030000ffff"
            });
        }

        if (idx == 8) {
            return Compressed({
                uncompressedSize: 4443,
                data: hex"c498bd6a544114c7e782cae68220b8202218b2fa04f6563636b7080836be864f2021a2f516292cf304365a5858d9588780094402b15852da5d38726667e69e73e6cc97bbe2c041b2f7f79fdf7cdd7bd735fd8ddd5b637f70fb6137eb1773a334c854aafd150f5f5f025c9fafff1595cc204fabc4d37e1557716c6557ec29bbf4b109578de7f36b63abd61378e28a3c976334fee0e0ebc02ac97bcfe538f1afbe83790bd1da6a6b98f3686b88fd52cfd108f0f1f069b6b4f35bca60bf85fba5745fb4f22db9d60cb66eb6b3b893b96fcd20aad45a799f81d5d54f5ac3167996815f5fd8214a64271e39ccb85cc6c5333ec75dd126313e76a90f536d1e1957ec48bbe8de4d1ec784870971e53cec61e5fa11fb160a4e97a16c86fc8dd5cac3e9b2dbe91777ffd7c1b60b78bcbf476bf817bc7c2226729c274fe9e3fdbde45bdbf2dad35acfa9e3119e21e9b83e87dd07f76cf9bc984b34e7c073075c9c9db0834ce74dfb770e0080c062a3f3663c9f377a42b1b98bb79c1f976b26da0bb1be78ede2ec24bd27c253dc43e1c9f02c476a13bebb7ff3f1bce64d00e6d941e54ba389ddb4efdc8d4fd9c1fd4d2bcf7dbae2b56664ce5e0b9b8e0dbf264d3ce7dc75caff7ef742f63fb100fcc6c313aab1ee9ae59c23d52f7e1ec6aab3116f33fe0ee15cc42b6b96da476d2fc2c19cf58fe6a6e1ff39e583d3c6b3dcb7e73f42addeaca09647b6c0b39ce72b7cd1b82a7d21e759e9ab7555f8d4b5c8f8d8d852be967da2bef74f8ea2efdaf859ce973b473e2b7d9aa7e4cb656856d6b6331f9687dbfccd81f6b9e9ef1a2dce3f010000ffff"
            });
        }

        if (idx == 9) {
            return Compressed({
                uncompressedSize: 7365,
                data: hex"b4544d535bc915bda72a957225db59600b4b4220d007020402b24eb2ca2eeb4cc298d86383e5803fc0d8638c300366308c010f3683c17f203f22ebfc81acb2c84fc82655d991bab76ff7ebf778afa5a41cd7e95ba7cf3de7342523e8a73ff9d5b52f70ed67835f50cabfcb8cd3eddf7f9b11cf54a3e1ceeac282e3dd72beb74bc6f993992eefc5723dbe17ccd87be8b3c8caf6f2560fefa57ee6c96caf3f5fda7ba1b7d2decbfa1d4af3a77c26b193f67fe46793fe8b93d7c1cf23f1995c267fbed07b7e7f5a36ebbdc4f7a6eb7b5dbe6b97ffc3f7b9173faefd3cfae371f9ebd9996ea7eb1f8f1e72a2ddfadd6fe530ffc7dfff967a02eff5924b7de7e9d9bf63e737bffca79c8cf76239ebf58fe6e4acaf2ecab119de67bd6777699d69de5edefa9ceff5f2d6e77acf7febaf7ff9b31cfb56b97c123bedbbff8a9de42ee9f733cc93bf1fc9f73ee749fbbdff3f1def995aed82663fd12f64ce1afe0942e071a35bcf0544919583bfbd70559664f57fa499739a3da79973cc9c1bae64e61cb3e76eab86590bdfacf10b7385063f5a04facf68fa23cdf85308433958e72b66ce307d06e3f46c8807c18abd4e87fb7fc4f48fd4134ea9e5663a904682fd1fa8a540eb14d30c23a2f581a6643525bc754a6c30e4034d9dbaa0c529a66cc4f86d5576ff7b46ebbd21b04470e238a6923a1827ca5b9a8571b6de538b5770c1ccfe1f68f20708c8604ae18927b0369a3c715b4a44127ecf93dd7f4ccd639a7c67714c9162f83b4c2a8cc7725d51f318cd776832a1a649f164456d81fe239a38a4e611358f203315681e61520d688a7f2269b0e4189347d43c8c0ca1feb7b27d8b89b714c3a1bc7288a6e16c10cfa1f80f8d478851f40a8d30a24866fff7347140e33227be877287833839608381d8a0a2f3381e2fc9ecdfc7f81b1adf279dfbe07980897d274245e51c1953b317b1db712f3866b6a17e8ced616c8f0496bca1f13d7e62ec8d3ca45b8a7344ce3dcf294adc96ddff1d3576a9f11d9338e04436ec0a57a7ac8437d486b15d34785a65d766c3fdbbd478ad18e589864ea8ee198c38ea56af63d9587c176a0bf7efd0e8368dee586c43afdb54df96abeaccebb2adef78ba028d1dae6a982d13d45d6da07f8beadf52fd5bc8f41157b6a8a6227cf14a8a462303ea5ba887fb5fa1f68a6a5b547f454ccc350278b575d576d549c6e048dd64c3fd1daa76a8ba49b54d5437511352b34a6dd310b2ab0846576707d54daa76503584ab6c4fb8bf83da06aa1bc4e8a0a27e162b1dab6f508581aa6beba85fc906a9b963b8670bf7bf44e52555d6c94e545e5a3165fa8462ca46a4a4c4b3fa5fd0c80b32d310e6eb5459079bd7a9f2020259adc3992b11743ba2410b730df77f831106a5e3390d3fa7916f50f1950489fb479e23ae07fb9fd1f0331a5e43d9906710f88ae0b97162d81763068c64ad02fd4fa9acc0f01a0debe46b59aee5a7eecabcbce645d66878cd92a71832f1a8906c36bb7f958656686815e55537a9bc4ae515ff6ac98ad3598903e51588075218ad42fd2b187a2286278ac12718e4e98b56b1d388de1576fa4ed31cec7f4c833e9e60e81113d61fa1f4186eaa8109eca4d263327ee68f780a4c84b783e1fe87545aa6818734b88cd24394968915052c6850af744531dc29cee621d0bf4c0382d23284a0b464aecc0796686009d6201e556066c9e82c8adfc619a274e9ff1309501452d46b8c3096d833b0143975bba471fe61fc2aa32f75eb7f40c50728b65168c390e2032ab649898781b62128b6add8966bc42d117d20ca66f72f52a14dc5fb54b8ef2684f02cde47c1ae1c0a22ba9583bf8d9470ff02e517a9b0408505e495a3b040f9052a2c3229e856f445521865d18a6ecb59e44d504af2e1febb74f31ee5bd59b8472c5a257f1779b9e6efa1c01cccf96a53acab52902b47ee5943b8ff6bdcfc9a147729ef7816ee507fe6166924d87f9bfa15e8bf839b0c11ef40a6f27ee12a1adc7141774542d1aa40ff1f7d20769da79c12e4e663ce1c3b610cb9db92ba2d8a6b98a7dc3c7289c2abfdb728770b02e1f36eb2784345f4ab8d5711f723bee8fbc3fd5f91434e70638eae3b718e6e7c859cc218948b0176c2c4bdaaa492deff07ba6e3087887b1011bc9dc3f539e1eaf7b24664c53829a52ab5fff7822fd127c44c01747e497d3cd1a75c0d7d31b3cb422392eab3b599fdff090000ffff"
            });
        }

        if (idx == 10) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"948feb72e238108553fb38f366b624db9bc94c2e9000214002c325fbb6adfeb3a556b72eb69199aa53aad347a73fd977ffdcddddfdf801d537d6ffd9caeb5b0ca94ec2acf33de607a295321faa8b4048b53b6190d8d1a41e1b45505dbc8afc8bad5d339c585348ded6ce808c4cabfd78f135eed7d4af2eb29b8c25fe9938e768523988bf3a038d509d28bcc895f89450cb6e2f1cf2ab13ab3ed9fa8cfe2d37e6677d0a9fe17c0c4f71accef46d27101aaf97f8c708611d39ac8e093cd640726f509dc39976e8f638c54ff5271b2b09555839a2ba524e95f4a7f87f588a0dd4871082cf9dfc671cd3662675c517f9b63ed078a0dbc34012ba0f383815fa94207d2d247989af0ea80e50ef2debe05f417590e7f64827f5f71caa7de2b996f98456e4efa1fe22da17bd423eaa37eea9f005f520bfae097e047e2125983c3422977f8e5e415cf98ceb053ea37a12be5fece77987460c8fea1c58e6ab1da8dde07667eb4fab774eaaa74f77c55b3bef79253b7756336a8abf2579f8b6ff5cfe01a0b6bca2d37e7286dcc327f8db28bd1d19b5486dfa793cfd439ca0de812f8f02d3516f9c149d611c88689b580ed279ce1fe9faa036985d8df23f48c1881489af3678add61717d06cf2fe381ff4da3af520ebdcacaf3f47578a206a8d4c8beb653e9a0f1b57debd41f301ea3dcfd3310acd9a9e88b7ce9bb535a150e63b32add0e977f93991c98d499291ce60bdc45f59b302bdb2a9cc3bba27dc95d57f23fa30da7d072deb65be74065a825e5abdc4f81994180f5c86d09a957462c1d26e99cfd2cbe8fdd84b44a0af1556239c69fec29a05e845de5f24b7dc112dc7fcd24682dceac50dfc37306fd479b38d3bb159f018cf6820264e520ecfb9933bc229f0b179a39c4e2f9df8de9579cdaed2b1e9355913fce695e40c3654e6e4d56a3a4d72a62389e0ce8089612827b42b7c33073347c63a6fcddc36737a824cff7c4d4e329263f024905a913f239f18339371e6bc098539adcf400a4809d20a852ef1c6ef6233c51f139897517f8b6ee9279d1727f3cca679c1d685988fb69d8124b78821ed041f9a676c5f6cf3ccbac5df285a29f3a17922ffc46a9d87e89f7d22a2911331a1109b0c014615f88fb67d04773ef913db271792b7ad33202378dfca2d791443fd819fe433cd9bdf6c9c52ff08740559e171a4dce4c032df8d51c81c52f32b9e3df5c28643a01c9ac1d555bee7f44cae261b2118cab1fb1dce0001fe9249fe43ae5ff16c24ec620dbbe1d620e986d86bfc9fa407db7101fc187cf730a2362c923a5258ec1ea22ff26d7b0fed3d13da8142e81ee591d6ef47fa54406a32939a45fe3d7299d4b1b00b7f447e50e00fe0f1a75cf18ae8df32ffff000000ffff"
            });
        }

        if (idx == 11) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"844c895254eb19a4f2383e0973ce9c39eb8c1b44112803312ee046888a8a564a5143c40d8db8e57a45bdefd4fd24b7befffbb7333867aababafaebafbb67fe32333373ecd8103f47fc23e29f4358a8a362a4ecbea376528beab4177e76ef37381cf2fb10df87fc211c830e688951db19b9a215fc619382c329fbf866c16f0d7e1f52c4104e2360c443ebc7791187de09154681c9fb0dbe0ef9b5c16f435aa14e6cc6a730be1ecd84b0f92a7c72d27e832f01fcffd04075832fb1d6afd19129c2768363303ce21cdd6ff0a9e1e7869f0c8c8045ed053f7b1d02b481a16909c38f483eaa4cdcaff1a1c187daa1a1e2a398ca627e8c021f1b86bcaf84d3659ac899b45fe3bdc3414da719f341cd8346f8bd7288b570d0aaa8e6fbeefd0aef2abcadf94e803647a2e1ffac6350e98bef62531d49d26d9a64d73ef66bee57785361bf325a20e2adea0a6f22de77a6d3d8770bae6bd7cc20f7bbf72bbeaef04ab9f6ec81206a3df1ca325fd7e39957aa6bfff2fec4fd97155e387e515244cd9715ad63c197a56111aa9d1fbed154e9a6baf74b3eaff0bce2f31201152d4aee55dc2b5dc0c7b4d22a86e45e85bdcaaf75ef63b7c47f2aee96dc0d8cdd42f8bfe6db42457d49cbc5a21764c13ae135799fcf0a3c2d5b7866f0b4e4330b6f5afdb45047bb630b2653f86ef73e760aec94d829f9a4a4d3ce14e68efa059f14cef1beb60c0b9cffc46dee4cdb7fe451f2717c167cd43a2530ee8cbd8e2c3c9eb6ffef82069800468138c97606edc0184fd8cff1a0c083820f0b18d040cc87d664e47b382737dd9c9217e683d0353b53f6b99d635b39e7fd82db8a1cf79573658302dbad80164378bb80d502f864c7fe5d45412feee5aa7957857578b770011f9e50bf37f69db88f3b39b606c222726e89e0562142115e03460eefb4beea70cb76a99b5bd3f66f0978cb89db0215b8353008a63d0522703bd44d66e003bedbbdcfcd013607fca7b0410ee77053916333e7bfc603302f7a11029261c874ed6363808d0c3707dc08c046c69bf12960c4de31674e978f93b8993b67d27e86eb19ae0f70439896add0176ffc520476c8785d398bfceefd01af65b83ae0b501ae66bc9a391e1853451641cc28266c200b8c6271be6b7f4d40c180eb03ae9b733de37a9f5732ae0947192b60e1f26b19ae78538be6bb366dff721f97857949b59c0a06c4a6e6b338d60e874a247eb9dfc7c53e2e66bc180b7f5ad338192f6572fe23f83228dc77bed12660772e4ddbbfd0e785168bf8bb1346e34266748628a34eabe5ba3e3fb67c749fab7daea65ce963a58fd5142b1957458bb3aa5f9b1173554c87e0e857f35889fdeefd14e7fbfc9be1f3ca7d18e17c0df4f56532fa4d9d7619f73d92e9dc5f4ab99c6239e1528ae53e448b8965f1156889fe11612af6941dfa91a5eefd04e7522c0ad3b2404ca3b168bf584cb994e09cd5f0b1451f73dda07d7ed27e8285940b09cea6b422c142420363266c9f389b622175f9342e5aa1389bea54e77e82bf3a9c496921e7389f11562032d5d793764707c354c73ee6132ae62c633ec15c82b91e54cff7c474a0f3ad984b4d4b384ccdf7a27ac77e0fa7129c0a4cc5e91e4ef578b267cdd32aaca60d9bd6e9908f32ad4ad7fe094582133daa3e6e059de689c4f2493d6d0cb138ee8b1273c569fbc3590c7b1c098cb027ec291cc4c8e6e30aa20c47098f8f8d74eda3eeb199456d4139d554ccfa00eb59efc369d47e21ae84b5cefd3f030000ffff"
            });
        }

        if (idx == 12) {
            return Compressed({
                uncompressedSize: 5337,
                data: hex"dc96bf6adc4010c6f7085cb8220472908404f2e7b82210ee8a148123a489aa23529f84f4e6b0bbc3c68f60fc087e02dba51bbfc4552e5cb9b01fc2852b9911fac4ec6876b53afd292cf8d0c99a99df7eabdd599be1e8c7cb3f83e168f2c1882b7df5f613c9f47065acd9224ef78f4ebb60a266faf1fd9b421df332461c45d6bd2fdec16ad50beffb7cde2b0ffe2e2fce9eda7c96d667fcffb06b9eb5f7a03e784c561ccdb790b36660ace62f13f2682d71c551941863b87cb1aa0fe1b1c8bfbdb94e7f2f9785b096591d2b166b4189f5f268bd628f209f33a9b68cc53bc9cc63bdf32a79924935feed1e97623566eebbf23bba9894fffaebcf8c477bc8c774b02a9924ca25118378748768df6ab1157babc423f1ba60c11b58e0d36f780edcc7c53a70315d3cbab3fdb4558f85a81e24e791fee6e8178dfabb47213506cfc69fbd81b289b471258581f1df5025ca58ea0ab5bcecd99793428b6f5775c6e8ad9973f50fa970b9e47b2efe8e7ef3bc36b8a16a995bf52dd7a853835bc7f33a6770a95ef39ceacd5ac1f5cdb91617e05565bbb821aac16c8dbd05d3c8fe5297cdfa44b306edf97e1df09c7c872a0f87e72f26ef4c8b8d3f74d0494f9c743a3def8397b1369b872e78f2602e7cb5c8d30e508ba5f092868c74f9ebae745883257875ff41b018a4bd9d7bb93154de36873f18b91febfb70163d734f3c0fc258e4d8f00c2ff0831c3997da1c228fc4799a07cee0efe141ae1170f87821ced59e21aac139c297c5e3e3a558ad9e4b88e579c25348936dd2a0f1fe310000ffff"
            });
        }

        if (idx == 13) {
            return Compressed({
                uncompressedSize: 4417,
                data: hex"e4963d4e033110851d895f51110405450a7eaa4820d1d08328408a84a04234a44d4319ce420b3d17804b70036ec00d168db563cd3a6fbcb6e36c0a567a5a63addff76c8f4dccdaeafdfa676f63fb60608c31557fe7816416f858c6c9e91bb3a4d0f72345aa77edd3e0d05bb6013b59d2e779f20b3925dad7173f8d39318f99f4aebfb1efdc76ed17dc23c9cc6d7bfbdc98af9c7781bd097278eeb9020cc88af5e335f219014e16cbe788f58e3abbcc6b6364f8ab3c59ab4805efad505dc58cef6deeee0fd005961d683cecb346caa518e2d8b1dfd3cbeaeb696855fb485fd437339e44edeafd8e7d9c27ff0dfa663cd887457eb29fc6797dce83faa5a487df079806cc1badf34c2ecf2369efc05ce6a90157682b5b47aed0aadbc33d9259c263d9e3b363d232d9ff852ff799f7bdcb3db09c3a83e54eafcead3aaa41b7de2883c811f38bb1041f661039b43ca999780ce2376ac1cff1fa7863e5e5d1326942e3e179403938832fe0a98abeff78995805eaccb1fd2c5a865845b0636ba131a75876c2f982199012d63ff95ed498396b5f8a9fb2cf99ec60860ef9ea9dd0c69e63dd5b73c49ec505fe2f2959eb7f010000ffff"
            });
        }

        if (idx == 14) {
            return Compressed({
                uncompressedSize: 4241,
                data: hex"c496bf4a334114c513f83e5122880826482421853629142160b1606715b1133bc1424802629137b010041b7d00f105042b5f416c7d011b1b4b05cb913bcc5dee4e66eedc193764e130bbc3ccef9c3b7f3495b9ffadf9bbeac24aa75d113efd04c53e2a41d1acbddd1db18667a75ac44bc44aac254a4be75f5a957b55107de05b8f29ae95fe6eacd659c1bc98b572adbf8ffdfcf4c80a6b99e8b73cc6a38197f1f9f1ee15b05defa8f168c07a70ec048fdc877a493c904df9f8383c26bc50522f219ff58cf18ae0b3f53172cdaf2e36db9b62b3ec5289c6a9de35a8d077d052368bf2d4fe9be279dbdfc804168ab2b40c075a0933c8331991a7d67e4edc3cc86778f08e4c6060ebc8e7cb88bc028b300b3981836d209f9e4feb36f9721e655935434bf9945958474fbe9c61985e9ec9679f39d73ed35c76ed36cb7b0e0367c56686ee48e89e54ff2d6f787f8dd4a7a46061ad6e360b4d64e866c7221d0d6f4a95c922ce901d5ee879b55a3f592e9ec9a2057d215d3dbce8b1cdc658abb37ecbaab7f5aa45fb200b65c6e6b0339491c3da1b2d7897e4f8cb9ea0ec0c869d9f11f8f609cf9064ff3861cd165b7c6fe9d972ad6b48584be0deb27f53a837cd12f2f5ac7dd2afa4941ce0c99c81d2b284724c21833707b727f69859e5c0f125e788fd1fe81a2ff1f80d0000ffff"
            });
        }

        if (idx == 15) {
            return Compressed({
                uncompressedSize: 5636,
                data: hex"e4563d4f233110b54f77ba2b4e8a529e94932ecd49b454d0514534a95323d1d150f00f682828101d1df901117dd2a354f003286910a9404291a220237b3df6d863ef3ac96a77a5587ad9dd78debce719ef07fbf5bdffe3fda7e0adf6bf2e8b8c7e00a903e205db3ff591928b729f976226160af25cff9fc697f19acf2e8482c993e54ae22b68be019e73f3583e8db3fc507e9bc7c9e178b63570fe336bcc72d0189407ea89eb6af8be46c0a78af5fa4bf83939343f58b3e85afdb9f01e08f7deab09da4b85393caf65e4a0790a72ac1993c2a77e637b99f279bbf3678726621389b0089b08185e8c9a3bbc12e2e021833cd731ce9c3c02f07caf377762e4b53f0f3170d45e6373c49bce199df7f37931a178bf06a1f3d0757e336d2c6f753affa381aa0fe9c3344f7c3ea5c74ff571c88a78367ea8cf4f581e2f8b791b5ad0eb80ff91fafd7861c6dbe21c694e4d5da4ae8e1f9939c50b717cdeeb99e579633e6b0b71c7a83fe0c9235e07ac2ddeaf900cb96339effe75487bbb06550ea37b7cf40d50a9f6fde36f7179cd152ad6271e6ad0371e500d580dc378a8535ff6a1a61e34a6065bac6f3c6cbb7ec5ef80a6acdf790fd5508346e8c37ba8a67d603c402d1af24d82bf8f36f1939a43f0c158017bc8f1930cd4df24afe0c3f702df0b2990ef55c0aafa58137bd9443fb17f441f83dd8a64dc2c2de4351f8c577e26f86b8af9026f39fb66ede7526abda53eae3bfc5fc67d53e4036b23ddb29e21e45e8ae997ac5be805eed5159e515f010000ffff"
            });
        }

        if (idx == 16) {
            return Compressed({
                uncompressedSize: 5621,
                data: hex"cc56bb4a0341149d0806040b1f412ca2f8481182a5060405d11082e2033bab08162282c4cec60fb04bc01fd0cace0f101b3fc052c897588edc2177b8333bcf4d366be0b0d999398f99b9b3bbac38753bdd294c96d6abccf0e38c7d00d8187fc2b3d9fce57bdf3cd41fc7d910ecd9ea72e18b570b5f6ac3181b40cfe16df4a4f7c45ff1837e3a466f030d87b7e28b63112e6d0a533b7ac37fdb9a512f7aefd3d5fb4cb92d73163ea45f02b93e5d0a9adde1e93a3f897dd73da9b7b69fbebdd57dacbefa5ce87cb4f574f9e23d6d77fa1a74127540fa655fe433c8a5e9cca6e7b2d472b067484d5ad6d5f5dcb19e299fa7678c73ff4cbe21f3d4ea2c761fd3cec1b777a96b2af2bcc76aa4f5f56a44d4f2a8deffc3f0f3f8f6f0ade730790ac59985b21099dfaf51440503ced9eb03df7eba14b85a3ba588e203e7e7fa4b41a80672df1b3d05a139609cce45fe20876d8d2417e74db9f81f35709d8886927d6e7125a163e2c39a0d3412fc52b76fe5038f70153e00b8a0813974bea546441f70e91ec4d642a7cf133510c043ae9225d0b330315b5d95c452a5ac23f393edf0946d1b8dba8e63c6589630795af3e58c98b5cd2b8b35231cb4dad6115faa6cf2e5c74f7145c03df4b9b073722341dbeb076dd04e5d97ff3497cc86802c08da9e022339cb17bd3be3d9498b113c839cb976efcfbd002e00efb3cc15928766ca2097920df3c5e6ca2053e2b9169acd9027cb779b35db61bbc5df5e9ec595b667b046ce6c7aad412668876b0e998cef7bd37a8de99b24f67d3aacee5f000000ffff"
            });
        }

        if (idx == 17) {
            return Compressed({
                uncompressedSize: 4412,
                data: hex"ec95bf4b234114c767e17ec1c1c1e520b9847081701cc75d2736499aa08558c4229da59d58059bd82896e9ec04ad52887f828da8ff838db5a44c6325228127333b6ff376f6cdec64d14d1107beeceeec773edf3733cbacf8125c7dbcfe7c177caf56fe0add40347aa6046961df10401c3e80184d600ccfeacafa1a3df87d011c27e6d31e6169e17899e760c89a248761a9f7271308eb96b58e26d4177baffab547f691faad1e3d7f6f8f5c339b684d16c9f7c1b7726dba69f576c957ec02ca77ed8325a5b5cbfde8d9766f70ace35d57ed6319bbe39bc82385fdc8c70ced4b30e8f8f5957b28fcd85457143e23879b0f9d37e5a0cacbc731758f1e9d6b423954643ea9fbd23f7d52aafd2cb1cf84b107002ce3dff64ea4ac0c53c862e6820c2b878ec5ba8c7db5326c1c633cfbcd179bad288fbb2f365b22a551af8d253c1afad458e69e6bc1d7daaf3ff6d3d02d673131ef00420d1d72fd2970fc007cea9a32a77f94b09f9c9e29f5b3f3902dc143f9d4a5bd84c3af97f6281fcde0f3fcf7c17f1f830f9fea15d8fa5f40891c9bca3cdfa82ae598bd68b966f67b6e3ed973c9cdf9bb9a67f6c27ed339acb399f116ff888e211b5ff5dff657690d521d86e123930370d675e6e2994dceee4c92399287cc5973a570bc8f241fe5919bf847bd766ecab79358afacb90627eb5936ab6cbc97000000ffff"
            });
        }

        if (idx == 18) {
            return Compressed({
                uncompressedSize: 5142,
                data: hex"ecd63d4ec3301407f05701031d51194b84843a21b6a6ea4ea50ae84558e855181818902a3132710266cec1352a3d640747cf8e93d88efd3c504b7f358a9af7f34712078ec79fa393d3ab0248c3f3c9440512b4b6da584ca7d4e6f2a5bb98cf65481f72da297c6d6ea9cb30f6835dd5ceb5deb57db75ac930dfe7399feffafceda2c4f7b767f10b899ab42df5596c61b4d44fe977b9ffd94ee5bbb8da7fbfbf3e62f83e6e4c3fc48de10f7187ac7f0cd7ace59354cf490c737434bebcc0b3eb4205189b346f1eef71b62eb97dcd9ead4b56f7e1e549d9b9e63b8bcb6c6775c91a232cb71b00d870dfd7b0dcaac4f645cd4ef7758f083ba47d30fbe21af37aeb5c375c9a9f7d95665fba23aed961555377dbe7dae6f644d457a9cf3bbae2d8586bbdff3eae7d8e1bf6df3b533ba6f19d67522fc825cf78507af61deb3895d917716faa7701eda7e35e17649b66e0fe5a7f17f4d92de31bba9fd3ef92ce7127fc7ed1fa60c4b5c66f000000ffff"
            });
        }

        if (idx == 19) {
            return Compressed({
                uncompressedSize: 4846,
                data: hex"6260e1cc6464615392fa5f9a9305c30c7404603b77ac5d0ac674b47ba4d98b6ef7a8bdf4b17b40eca573ba1a48bb476c9aa64338a3db815c47f8323030d002e34a4360717969716437501543cdc65b5ea3e3d7cf1e8231482f8c0dc30c1b3e8031ba38b25a9819f8fc0b52834e13b29390dd30b3c8f12fa5f6e2f02f4afac2e65f4ac39988fc428b7405339b915544551d6c091a66a04126c2650f982d2d298682b1a8a50ac6620f0329ea29c138fc8f33e2a98c492e68413822c807c50fc67a1a1818a406990dc33031a4701e72f6b7d6575205936bff68fc8fda3f6affa8fd03653f7a1d468efd204c6e631fbd2e26c57e0aca3e6a94c7c40240000000ffff"
            });
        }

        if (idx == 20) {
            return Compressed({
                uncompressedSize: 5488,
                data: hex"c496b14b234114c6370747eeb86b2e0757dd05ee0877e1345858888828da6811d02ed61629b4b0b1f3af10ac0da417acedd389606317f47f48208dacbc256ff3e6cd7bb333bb59b3f01191f7bdef376f6633893e7db8ff78f9a55af9fae3e7efc8e36913853ee0897f5d6cc4e74f57a0d01ed48bb26aaa0775a89398253fd473afa8ffd787897cfc50473d540ebfd1033ed183bda0deb787e697c4fce27a5cfe9be747670ff4431d9723df5a8f22ac7bbf433c680ee2516f040a3ec4c48bb26a3a7f3a50271e62c10ff5dc2b6ad81926f2f1431df55039fc460ff8440ff6827adf1e9a5f12f38beb71f9270f13670ff4431d9723df5a8fa2f4107faefdadf3439a47a14fbc28ad2c2fa5daddda54853505b2a2d0cc104dd9d4d9e6cddcbb1b272a9ae99b8b795aae2333d75aa52cfa77465ea1cc1c7b5938b740dedc7203f3acef88d0734cdebfbc4f9e77ddf7a954be351a3e00ed68f14fb2c056b351160f1f5e5cfb7ee4e44015b87cd45f5a0a0f65b23808cf3c98da3c43e151391c4ca13232b6d757394fc2d16af693ba7f67b74636d45331a660f1be8425e59058384796d67aafa97c3d120bee51280bcda7ebf7e5f2998b2f87347fbe872e1ec8e3e7657fe7c5e0f1e5e0675baad578a63dacf7e8b43b36785c6b9971f4a773d5e778d23d4e24f51458acd9501ec59fd68107bc523ee188f87e291cd6bb4de7c3cfa1c6e271511abdb238709f507446e6199d718047b94b5c177e26077eff52c1ff39239d5f204b262bbb93c4fb81aa448e20e692388267c7f671611c25e7bf050000ffff"
            });
        }

        if (idx == 21) {
            return Compressed({
                uncompressedSize: 4448,
                data: hex"b4573f6bdb50109736834b0d3658835b0c2d142f1d3b186f5e4a07e3d95fa05d3a78eb37683b752e9904d9927c877c8a6c21c47831384b8640e2085e3859f774ef74273d4bce831f92defdeef7bbd3dfa7a0d5fafc66fa761bb6ba1f3e05d998096832240d138c9712668abf0fa88ef58011c40ceb44f3f7c33ac9758957f0d714015e1ea0c3cea3864f3f92b72fb47e94de6bf7e35e1f7b2f747b0bf3f3c78379dfbf4891d52123367a3c9b078d6e6fc1efc3a2cf3ab1fb1c58b31683edb7e98afb547a400e82fbd01842f12af5e11ac7f229eba5cae7d7c9a305c4cbce5d1d1fd0a53ed893701f58af2cdee8faa00ebba79df75cfa0c8c972957030e2d4e74b4f76cce817a62876b9f0ffb4c0a31fb1ed03da4f7b71c2bd6509577e870ea3e825eb587fff969e4f58a1efc3a1c9213b607c35115e9bbd9fe695498b93ff5d1e73c2d4faa47e2228f6f79cec8dcfdd672a82ee549c79a7e9ddad3f9e7d55553885a26d9897c98e79062be730af63de7fbb63eaee7a145358ae755f6aca355a5df54cb47b3d933e8af1376faef3e96adfa7dfe24a4153cff2bd0bf40b191c1bf70655c374fe66aab5d2d47e16fcdce5d0d733eead155736cf679520ef2f178bec9c1fe869cbf1fc2fffacf5804f34df14bce738a3efadf5d96d3ee453637dd2f5931515fe83bebfd905509e7879dfe40bc512301da8098f93299704465dcff67e7d2d6299cea41fcf2fac601e15b0ed503ce7010a5207c917bfbb44b81f3788cfe908f3100d5a53ec7e223904feb95f8fcdc40edbc679a43798ceb9c532947e08ad78c80725e020000ffff"
            });
        }

        if (idx == 22) {
            return Compressed({
                uncompressedSize: 4767,
                data: hex"ecd4bfadc2301006f0cbd31be18df0948e1616a0651106a0a3640006a0620a3a36a0a3a1a7c90634468e72c2717cfe7bb12391933e5110dff78b85809feab7aaffc1321be6840e9e13ebd59233be9ec1d9fd6edb465c16ede7f9740c4af37cf4a2ed270df259ec3625d521a37e6fb0181df7db9535be0efd1c3e2f5e4d52708fbedfe650bddd9e1a005232f0a0c9f61b51de83da1b3a038f0c6180ee39d7bb71cc5fd715e3e01c9b2397c165998223b781b2500ec8e8287517baa5d45dc839082166c7c7e072c09738d0303bfa06d561fa0f296198922387c5c730b64337d81cbaa59481fb4e4cfdbe0eae3b4935a45a6cfda186508bab1bfb630caa4506f7f8f69afa630d364fee7e9787ca58fd94874accce77000000ffff"
            });
        }

        if (idx == 23) {
            return Compressed({
                uncompressedSize: 4321,
                data: hex"bc56b14a3341109efc84bfb0510b3b0322126c6c05b1130b2dd2049b406a6dc54e7c817b8c08b1f4012c2d8365ca547258d95bc8c1c8de66f676f766f636e436035f713b33df7ceccdcc1dfcfff7d19d76b6f60e7a08137491173e060010423d6782e0993e1f2f748d6c897a2d1714a772546e5e006315b78ea9f2c60b7c1b1d96287d76dd2a1e0286332c0c2847f1e13c439c0e2beef1c28e85154c73e745c53bcf346fbe3217cb5df24e8786774d4ec36d78f53d408b46efad29aeb3dddbefbbcd70762fa1de38e4bb7b97e1e656f1721df2bb392f5fe13aaa29b91c823518646c8e3e63732cbf1f6f9e955d5f7c52bc732edca5ede7ee577cc9015fa7bbdb3f5eb78b061148cd5f6ec8db9d9326c46a8ae11231bb7972f0f3f85a430387d1f07c3a62e1d7680b8c4ef63ecac60a2143174df11e98fbe09b1b001f2eaf640d00787ed42f4167f46c437110acf895b6a9a8450dbfaf232f526888d261e31b7f53e980e03b5e2e4c555f21b22fd6fadad16c4a331583402fb6aa439a4fe5b3e632a996a63dd19286a00e693f25d051dbe11bd6616a5bbd16a5a36d0d4ccf3b3aa47e684907fb2de5b424be0bb63fa9764847c239a9cd4a8c8e041ad899b57b67833aa2f798f74f93ca9c39e67646c33f4d323d91ff54b1f6170000ffff"
            });
        }

        if (idx == 24) {
            return Compressed({
                uncompressedSize: 5122,
                data: hex"cc973d4e033110853702d105a1548968222512e20250d18626e9b8050d35888a3b50c31168b90147082d749c01190df2acc6e319afadb5bd6be9150bf6bc6fe7c7499ac3e3c5e4e0e4ecbc21cbdc2ea6a8a6f0d2bce8dfcdf3c529aa380ff17218023c3bab5c8bc6d378c43c31ed48ac3e0a7974d5d498fb2bf371bdfa57204e92301ec44eec55314eacc04f52cf79c9969788da243141cf5dbefcb6a2bd98a20cf748db4bc844e3c3734cddeef606fb30dbdd854c5c9c01bd91079e4119efd8241ea9a733f3884cb497423c19eb14dd4703f0384c5d3c1558c41c69f5827ea9c0a3f63667293053493cd28c57c84d548e2ad5c9e3811c709e4a7d1c95a38172a3cefec03c4edde8e7ea402c5e1f8d80c7a99bfdfed78c60e5fccd36396a5653b3596fcdfef5cb3cdc3c797a7b7cf7047b37ebad0887b1f8198c67cf8ed613f759050bc1f6467b4ae73ebf7fbafc1c5fd8aff03a9ed4030567c9f9684f7e96f83bf9d0bc12fc3c5f1a8be796fe4f614b1e32fe2eb63e6deea94f4f2ff59da5f7ccec25ce11f52ce4a5ced16cbeac7289cee6cbea9e248fa573cad75f000000ffff"
            });
        }

        if (idx == 25) {
            return Compressed({
                uncompressedSize: 6680,
                data: hex"ec96bf8e133110c61d4070fca9ee0138814e484807579c44bd7420a0a1e11d68909292226f8044c11b502151a4a6a24f859402686910a98244c11683ecf538b3b363c7ebb5972b62e953b2b6e7fbcd78eddd550717df5efe73e3f5e440ddbaaa121abca8147c7ea300e04cffcfdd8c3fac1a46014ee3fff77ba395daeaf7c7219c674c8e636ad8fae3788a2f4c37b5535d37d21c2aec9f6eea5d2ce76be76bf55e4f1bc759ad9cebbace72ef588ea939a7b04ab5c9950bb7afc54eaeac62af539bf600355fc3e9022adff5e902f0baaf774539dc53cdd7a1eb6a47ad15118dc7fc8d3efc0477a3a56bdbc7632bcf1ab56a205ebd371d5b0bd78f79586f9ef3109ef3d4f55a660eef58fe189cc925757cbd053e3c39823b8f1e38dd7ff924a8a7ef5e9998f79f9646fabfee0bc568dfc39323b1f058be6650f6b71fbf8c680e521ee84bf8663e55884fb984edbc680e521e961d64f2be0017d5e2f3b5c03cd05bca0573e4b573aec0f46e629a8bb42facafbb079e71ca4d3e50520e7c0fd031925bd6834df7848f5f88dd6149fcc26ccaf3e5a5fe631ba3f6ee978e3abea91ff77076ef6e47cf1f3f14f5f5cbb235aee3f1bfeed7e33c46f7d362cf3b13c7d01779f88bf9f0f81426f6e17c14e75271bf18269bdf5a43e2ada43ce89cbe4c5e0fe1780f83b40e2cceb70e3c26e930067cf81ab8fb99f36140d6bcc52cc453acde4e9d2c9fd198251eb4d25edf33cb334beedbd0192dc8547ba661cec66666e4ce6298196b9d79f66c4cad54311caad0fb50647ab8b182542679e7e6e44571a56fad480d62f611fbf68ae20e61f5e089df4f09b541a6f741901579ef06f17bec11defe050000ffff"
            });
        }

        if (idx == 26) {
            return Compressed({
                uncompressedSize: 5461,
                data: hex"e457b14a034110dd40d0425139504829a88591d8f807363607a64d65bec1c2c6cad2c6562c2c82858585bd95606995ce8ff01b4ee6b85966676737bb77b717820b8fdcedcdbcf7766677216a6d7d63fbb2d757075baa1ac5749815ef57674ecc6fce0dfcccbf8df932ffe549bfc33788e179c8371d668a8c287de4a6f3a00d1ca9f4292016403de01cd7f67018da8bf43186ae91cc595c529ca0afe7257dcac57bcdea270dd14788bee43742d7eb83d5cc5823d78d5c6f900fb607c5bab7acebf420ad57d8536d0fab170dfbbb92fafccc56faaa8321de7d1dad3dc65717a3d757873bda403e1a14cf9313039fb7e3125f1f6fe5efefec1ae2f200f21c3921077900c09b8f0662117c1e3077953d50ae580fdc4fe5217883d13a502ec651c621589c06f044ea5b3eaa7c27d02b9dc37593dcda078eeb20c8ba7cdf9b687b7bc3ea6a79a859f73abd09f1b7140f09f52d3de97c24ae01dfa3a1de5279f0d5472d79745183ba7dfa0fb5807fd29bda006032be284e8f8f341eeeefbcef00c801407e96659a07b9680e3c57b16211240f21baa88d90b888b657dfe5c1a74b73a917ca8539f0ecd3dfdfdd133d705d829cc18ac13ce0aef8ad35bbf2986eadcd1da2f33a7bb46a4d621a1f30ac3d00b4682da57eb7a42bead3fd20e9a7ba64a807720e0d0f292f39d4677700dda3c92f5a8756dbfd5e74165cdf54471e70fc050000ffff"
            });
        }

        if (idx == 27) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"ec92b10dc0200c04ad8cc3c6ac40c91c19231523d0382d13702ff9a5d3ebdab31c4f44b4f67e690cc29a1b71856a6a8bb7532fb7e6166947b678fb7981cb2ed28ee076d6597274c415aaa92dde4ebd5c8e2ed28e6cf1f6f302975da41dc1edac9b6afc010000ffff"
            });
        }

        revert InvalidBucketIndex();
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import {IBucketStorage, Compressed} from "solidify-contracts/IBucketStorage.sol";

/**
 * @notice Stores a list of compressed buckets in contract code.
 */
contract TraitBucketStorage0 is IBucketStorage {
    /**
     * @notice Returns number of buckets stored in this contract.
     */
    function numBuckets() external pure returns (uint256) {
        return 7;
    }

    /**
     * @notice Returns the number of fields stored in this contract.
     */
    function numFields() external pure returns (uint256) {
        return 260;
    }

    /**
     * @notice Returns number of fields in each bucket in this storge.
     */
    function numFieldsPerBucket() external pure returns (uint256[] memory) {
        bytes memory num_ = hex"0a13703e0c2508";

        uint256[] memory num = new uint[](7);
        for (uint256 i; i < 7;) {
            num[i] = uint8(num_[i]);
            unchecked {
                ++i;
            }
        }
        return num;
    }

    /**
     * @notice Returns the bucket with a given index.
     * @dev Reverts if the index is out-of-bounds.
     */
    function getBucket(uint256 idx) external pure returns (Compressed memory) {
        if (idx == 0) {
            return Compressed({
                uncompressedSize: 100,
                data: hex"621061906050625063d066d0673065b066f0608872ca294d75cfc92c49ce50084a4d712f4aac742f4a4dcd0bc8cccb0e282d2ac8498d4ccdc9c92f77ce2fcecd4c568008b9e6e564a66794a4e6a5a64045bc12535215c01a01010000ffff"
            });
        }

        if (idx == 1) {
            return Compressed({
                uncompressedSize: 113,
                data: hex"625063d062d06330623063b062b0677061f064f0630886c208865886248674861c9ffcbc74741c9c915f548295c84dccc9c14900020000ffff"
            });
        }

        if (idx == 2) {
            return Compressed({
                uncompressedSize: 2167,
                data: hex"74934f68d44c18c63b93cc4cbecf9b1411155c841e548a07115abdb5ca5651ac69b1d45b76f3ba1b9b4d6a36b1aee742c1a322782a05bd089e44911e043d889782a0a83715143d58bd8807ad0799d9cc9f90ecedfdbd4fc2f3e499c9d0c7a1ef43bf1145dbd15e74108da3e3e81c0ad0325a45ebe80dda447ff136bc1b1fc047f1497c01b7f155bc826fe1bbf8017e865fe20f78136f593bad316bce5ab26e5b0fad0debab8dec3df6987dd6be642fdb6bf663fb85fdd6fe62ff22840c931172984c92799290ebe40e79425e914fe427b5e9301da147689d9ea72d9ad21b7495dea38fe853ba41dfd1cff407fdc3fe633bd83e76881d63536c963558875d632bec265b63f7d93a7bce5eb3f7ec1bdb72fe777639fb9d7167ca99775a138977056aa3b589d06b2e68c840cd49bc1449a8275e4fcf004a980e22f5f674962c86ea7d177c39ceb5831426e36e2768d6466ba7a10591ef25bd9ad02bf69309749b10a515d289ce22247152a1d4332ff1032faa90a693f82274bb95afcd782d907eb28e02670599976230efa58000a6ccdb315114642c5cf00d1235e51f28a3989899220fa291e73009c010790a834408cd2ef81afa11a23068b55388c02f1fd720517ec7203df71824cbd31ba4ab231cf4003fc77a18a4cd763973c55ec6ad90f2a4158a0c5921a97c159a8816873e44d511ca928c5056b44f59133e7944797f0a9c15647e830ce657a88000a6cc2f9189e216190b177c83c43d3ae5f9503e8cd256f65012f2164a7be953125439258557a354d94d7191151fe0ed980b5e4f91010a0ff0820a2c1a32372ef8268a8edcb811f37fff0ca45ee8668d5e6d66014248e3e2d14ec411f06f90d1d59ca9350f9ccf3cab1a01e49a2794a30897830b7e3e89484600619b7ac982f25590694138e720acd5ccbd7310e672eebbe7c4edf351f8cf7a8d464f1a6ac8b4c00d2570433d0328811baa59184a72c19763df30f1a2cb59102a4f93b3822c9c350b7313b9bf6611c1c07e0abde04134892cff020000ffff"
            });
        }

        if (idx == 3) {
            return Compressed({
                uncompressedSize: 466,
                data: hex"62a8616861e864e86398cc3083612ec32286e50c6b1836326c63d8c6b097e138c34586db0c4f19de33fc646466e46514679446810a8c2a50a8c1a8c368c068c268c168c3e8c0e8c2e8c1e8c318cc18c598c898c198cf58c658cbd8c2d8cd38897116e322c6558c9b1877311e623ce598925f94989493ea98975e544912e19299989b9f97e292599c9c5a949799974e6d965b6651aa476a6251896f7e7e9e7f412a51382831332f29bf3c283527b12235855c2a3833255537b532955c1a100000ffff"
            });
        }

        if (idx == 4) {
            return Compressed({
                uncompressedSize: 160,
                data: hex"44cc3d0ac2401047f1ff312c83a590464f60fc88085a18493fae63b23ac9849d35a0e021acbdac8504bb57fc7818618c09a658638f1257f478e18dcf6c99e442666cf3de53d46099af9223bb3a1372b734f8a6e1f360560fee28ba3aa7278bb06d482e69a3da2645c72e9213b6ad9e6cf03b6dd5091fd4385da868f8af8a7b5bfdaaf4a6e11b0000ffff"
            });
        }

        if (idx == 5) {
            return Compressed({
                uncompressedSize: 420,
                data: hex"348fb18e13410c86ed969e8e62bae378014ac4264a561c271db948a17566acc4da597bf1ceb20ac5359488868a8257e005e86828a878011a4a0a4a6ab45951d9d6afcfffffc333d84182065e41813b78071fe0137c862ff015bec177f8013fe117fc863ff01701efe17d7c808ff0313ec12b7c8984191deff02dbec78f4f5f0b15f38b3e2ca8ab28362379ea434da5224da45431a970656335c486cba42ca82b243a338ba35b2bbcb0716fa7b3eadc47d612b694a56f4997a451f41056995a5e0ab5a66939381d56e2bcca36b2afccb92f61437a605f3b495e3bb75d16ad295bcd94f6a4699addd194fb9add66fb2b722a1ca6b0cf45a365bdb6238d4d78b87666bdfc7fdd883697d7663a45bc9109ba38d77c31309fabb88dba21d1986d489b61bf670fcb2136b7cd90f3e9b6a3c8a1e6dc72d90a396d454f33b493128ff3b39dbc214ff3fe2f0000ffff"
            });
        }

        if (idx == 6) {
            return Compressed({
                uncompressedSize: 106,
                data: hex"6210609065d06530677066f06408618877cacf4d4a2d52f04a4cce4e2d71c94ccccdcf4b51f04b4dcece494c4e75cfcf495170ce48ccccf3482dca572f560829cdcb4cf6c8cf4fc94c85900a2ef9e5795ea989795013024af3b2a14c40000000ffff"
            });
        }

        revert InvalidBucketIndex();
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

/**
 * @notice Key (name) / value pair for attributes, e.g. 'Body: Professor'
 */
struct Attribute {
    string name;
    string value;
}

/**
 * @notice Utility library to work with multiple attributes.
 */
library AttributesLib {
    /**
     * @notice Thrown if the attribute buffer capacity is exceeded.
     */
    error BufferOverflow();

    /**
     * @notice The capacity of new attribute buffers.
     * @dev We set this to a constant value of 8 because all Moonbirds have max.
     * 8 attributes.
     */
    uint256 internal constant _BUFFER_CAPACITY = 8;

    /**
     * @notice Allocates a new attributes buffer to be appended to.
     */
    function newBuffer() internal pure returns (Attribute[] memory) {
        Attribute[] memory buffer = new Attribute[](_BUFFER_CAPACITY);
        assembly {
            mstore(buffer, 0)
        }
        return buffer;
    }

    /**
     * @notice Adds an attribute to the buffer.
     * @dev Reverts if the buffers capacity is exceeded.
     */
    function addAttribute(
        Attribute[] memory buffer,
        string memory name,
        string memory value
    ) internal pure {
        if (bytes(value).length == 0) {
            return;
        }

        uint256 len = buffer.length;
        if (len == _BUFFER_CAPACITY) {
            revert BufferOverflow();
        }

        assembly {
            mstore(buffer, add(len, 1))
        }

        buffer[len] = Attribute({name: name, value: value});
    }

    /**
     * @notice Convenience overload of `addAttribute` assuming that the value
     * bytes encode a string.
     * @dev See above.
     */
    function addAttribute(
        Attribute[] memory buffer,
        string memory name,
        bytes memory value
    ) internal pure {
        addAttribute(buffer, name, string(value));
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {Features} from "moonbirds-inchain/gen/Features.sol";

/**
 * @notice Interface for Moonbird features providiers (registries).
 */
interface IFeaturesProvider {
    /**
     * @notice Checks if the provider can return features for the given Moonbird.
     */
    function hasFeatures(uint256 tokenId) external view returns (bool);

    /**
     * @notice Fetches the features of a given Moonbird.
     * @dev MUST revert if the provider has no features for the given tokenId.
     */
    function getFeatures(uint256 tokenId)
        external
        view
        returns (Features memory);
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {Mutators} from "moonbirds-inchain/types/Mutators.sol";

/**
 * @notice Interface for Moonbird mutator providiers (e.g. proof background
 * registry).
 */
interface IMutatorsProvider {
    /**
     * @notice Checks if the provider can return mutators for the given Moonbird.
     */
    function hasMutators(uint256 tokenId) external view returns (bool);

    /**
     * @notice Fetches the mutators for a given Moonbird.
     * @dev MUST revert if the provider has no mutators for the given tokenId.
     */
    function getMutators(uint256 tokenId)
        external
        view
        returns (Mutators memory);
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity ^0.8.16;

/**
 * @notice Mutators struct that can change the appearance of the final artwork.
 */
struct Mutators {
    bool useProofBackground;
}