// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account. See {ERC721A-_approve}.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        _approve(to, tokenId, true);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
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

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                       APPROVAL OPERATIONS
    // =============================================================


    /**
     * @dev Equivalent to `_approve(to, tokenId, false)`.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _approve(to, tokenId, false);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId, bool approvalCheck) internal virtual {
        address owner = ownerOf(tokenId);

        if (approvalCheck && _msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

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
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
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

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

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
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
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

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721AQueryable.
 *
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        override
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../lib/solmate/src/utils/MerkleProofLib.sol";
import "../lib/erc721a/contracts/ERC721A.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/solmate/src/utils/ReentrancyGuard.sol";

contract Habibi is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;

    uint256 public maxSupply = 6000;
    uint256 public mintPrice = 0 ether;
    uint256 public maxPerWallet = 5;

    bool public saleActive;

    bytes32 merkleRoot;

    mapping (address => bool) public whiteListClaimed;
    mapping (address => uint256) public publicMints;

    modifier stockCount(uint256 amount_) {
        require(totalSupply() + amount_ <= maxSupply, "Better luck next time, sold out.");
        _;
    }

    constructor() ERC721A("Habibi", "Habibi") {}

    function teamMint(uint256 amount_) external onlyOwner stockCount(amount_) nonReentrant {
        _mint(msg.sender, amount_);
    }

    function setSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function setMerkleRoot(bytes32 newRoot_) external onlyOwner {
        merkleRoot = newRoot_;
    }

    function setBaseURI(string calldata newURI_) external onlyOwner {
        baseURI = newURI_;
    }

    function changeMintPrice(uint256 newPrice_) external onlyOwner {
        mintPrice = newPrice_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// Inspired by Solmate: https://github.com/Rari-Capital/solmate
/// Developed originally by 0xBasset
/// Upgraded by <redacted>
/// Additions by Tsuki Labs: https://tsukiyomigroup.com/ :)
/// OilV2 by SKU, twitter: iamsku_

contract Oil {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    address public impl_;
    address public ruler;
    address public treasury;
    address public uniPair;
    address public weth;

    uint256 public totalSupply;
    uint256 public startingTime;
    uint256 public baseTax;
    uint256 public minSwap;

    bool public paused;
    bool public swapping;

    ERC721Like public habibi;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isMinter;

    mapping(uint256 => uint256) public claims;

    mapping(address => Staker) internal stakers;

    uint256 public sellFee;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    uint256 public doubleBaseTimestamp;

    struct Habibi {
        uint256 stakedTimestamp;
        uint256 tokenId;
    }

    struct Staker {
        Habibi[] habibiz;
        uint256 lastClaim;
    }

    struct Rescueable {
        address revoker;
        bool adminAllowedAsRevoker;
    }

    mapping(address => Rescueable) private rescueable;

    address public sushiswapPair;
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Router02 public sushiswapV2Router;

    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public blockList;

    struct RoyalStaker {
        Royal[] royals;
    }

    struct Royal {
        uint256 stakedTimestamp;
        uint256 tokenId;
    }

    ERC721Like public royals;

    uint256[] public frozenHabibiz;

    mapping(uint256 => address) public claimedRoyals;
    mapping(address => RoyalStaker) internal royalStakers;
    mapping(uint256 => address) public ownerOfRoyal;
    mapping(uint256 => uint256) public royalSwaps;
    mapping(uint256 => uint256) public escrowedOil;
    mapping(address => uint256) public lastUnstakedTimestamp;
    uint256 public swapRoyalsCost;
    uint256 public royalsHabibiRatio;
    bool public swappingActive;

    mapping(address => address) internal stakedTransfers;

    struct UnFrozenHabibi {
        uint256 UnFrozenTimestamp;
        uint256 tokenId;
    }

    struct UnFrozenHabibiz {
        UnFrozenHabibi[] UnfrozenHabibiz;
        uint256 lastClaim;
        uint256 eligbleClaimTimestamp;
    }

    mapping (uint256 => UnFrozenHabibiz) public RoyalsUnFrozen;

    bool public unFreezeActive;

    uint256 public unFreezeOilCost; 
    uint256 public unFreezeTimer; 

    bytes32 public unFreezeMerkleRoot;

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return "OIL";
    }

    function symbol() external pure returns (string memory) {
        return "OIL";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function initialize(address habibi_, address treasury_) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");
        ruler = msg.sender;
        treasury = treasury_;
        habibi = ERC721Like(habibi_);
        _status = _NOT_ENTERED;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        require(!blockList[msg.sender], "Address Blocked");
        _transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external whenNotPaused returns (bool) {
        require(!blockList[msg.sender], "Address Blocked");
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        _transfer(from, to, value);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              STAKING
    //////////////////////////////////////////////////////////////*/

    function _tokensOfStaker(address staker_, bool royals_) internal view returns (uint256[] memory) {
        uint256 i;
        if (royals_) {
            uint256[] memory tokenIds = new uint256[](royalStakers[staker_].royals.length);
            for (i = 0; i < royalStakers[staker_].royals.length; i++) {
                tokenIds[i] = royalStakers[staker_].royals[i].tokenId;
            }
            return tokenIds;
        } else {
            uint256[] memory tokenIds = new uint256[](stakers[staker_].habibiz.length);
            for (i = 0; i < stakers[staker_].habibiz.length; i++) {
                tokenIds[i] = stakers[staker_].habibiz[i].tokenId;
            }
            return tokenIds;
        }
    }

    function habibizOfStaker(address staker_) public view returns (uint256[] memory) {
        return _tokensOfStaker(staker_, false);
    }

    function royalsOfStaker(address staker_) public view returns (uint256[] memory) {
        return _tokensOfStaker(staker_, true);
    }

    function allStakedOfStaker(address staker_) public view returns (uint256[] memory, uint256[] memory) {
        return (habibizOfStaker(staker_), royalsOfStaker(staker_));
    }

    function stake(uint256[] memory habibiz_, uint256[] memory royals_) public whenNotPaused {
        uint256 i;
        for (i = 0; i < habibiz_.length; i++) {
            require(habibi.ownerOf(habibiz_[i]) == msg.sender, "At least one Habibi is not owned by you.");
            habibi.transferFrom(msg.sender, address(this), habibiz_[i]);
            stakers[msg.sender].habibiz.push(Habibi(block.timestamp, habibiz_[i]));
        }

        for (i = 0; i < royals_.length; i++) {
            require(royals.ownerOf(royals_[i]) == msg.sender, "At least one Royals is not owned by you.");
            royals.transferFrom(msg.sender, address(this), royals_[i]);
            royalStakers[msg.sender].royals.push(Royal(block.timestamp, royals_[i]));
        }
    }

    function stakeAll() external whenNotPaused {
        uint256[] memory habibizTokenIds = habibi.walletOfOwner(msg.sender);
        uint256[] memory royalsTokenIds = royals.tokensOfOwner(msg.sender);
        stake(habibizTokenIds, royalsTokenIds);
    }

    function isOwnedByStaker(
        address staker_,
        uint256 tokenId_,
        bool isRoyal_
    ) public view returns (uint256, bool) {
        uint256 i;
        if (isRoyal_) {
            for (i = 0; i < royalStakers[staker_].royals.length; i++) {
                if (tokenId_ == royalStakers[staker_].royals[i].tokenId) {
                    return (i, true);
                }
            }
        } else {
            for (i = 0; i < stakers[staker_].habibiz.length; i++) {
                if (tokenId_ == stakers[staker_].habibiz[i].tokenId) {
                    return (i, true);
                }
            }
        }
        return (0, false);
    }

    function _unstake(bool habibiz_, bool royals_) internal {
        uint256 i;
        uint256 oil;
        lastUnstakedTimestamp[msg.sender] = block.timestamp;
        if (habibiz_) {
            for (i = 0; i < stakers[msg.sender].habibiz.length; i++) {
                Habibi memory _habibi = stakers[msg.sender].habibiz[i];
                habibi.transferFrom(address(this), msg.sender, _habibi.tokenId);
                oil += _calculateOil(msg.sender, _habibi.tokenId, _habibi.stakedTimestamp, false);
            }
            delete stakers[msg.sender].habibiz;
        }

        if (royals_) {
            for (i = 0; i < royalStakers[msg.sender].royals.length; i++) {
                Royal memory _royal = royalStakers[msg.sender].royals[i];
                royals.transferFrom(address(this), msg.sender, _royal.tokenId);
                oil += _calculateOil(msg.sender, _royal.tokenId, _royal.stakedTimestamp, true);
            }
            delete royalStakers[msg.sender].royals;
        }
        if (oil > 0) _claimAmount(msg.sender, oil, false);
    }

    function _unstakeByIds(uint256[] memory habibizIds_, uint256[] memory royalsIds_) internal {
        uint256 i;
        uint256 oil;
        uint256 balanceBonus = holderBonusPercentage(msg.sender);
        uint256 lastClaim = stakers[msg.sender].lastClaim;
        uint256 royalsBase = getRoyalsBase(msg.sender);
        lastUnstakedTimestamp[msg.sender] = block.timestamp;
        if (habibizIds_.length > 0) {
            for (i = 0; i < habibizIds_.length; i++) {
                (uint256 stakedIndex, bool isOwned) = isOwnedByStaker(msg.sender, habibizIds_[i], false);
                require(isOwned, "Habibi not owned by sender");
                oil += calculateOilOfToken(
                    _isAnimated(habibizIds_[i]),
                    lastClaim,
                    stakers[msg.sender].habibiz[stakedIndex].stakedTimestamp,
                    balanceBonus,
                    false,
                    0
                );
                habibi.transferFrom(address(this), msg.sender, habibizIds_[i]);
                _removeTokenFromStakerAtIndex(stakedIndex, msg.sender, false);
            }
        }
        if (royalsIds_.length > 0) {
            for (i = 0; i < royalsIds_.length; i++) {
                (uint256 stakedIndex, bool isOwned) = isOwnedByStaker(msg.sender, royalsIds_[i], true);
                require(isOwned, "Royal not owned by sender");
                oil += calculateOilOfToken(
                    false,
                    lastClaim,
                    royalStakers[msg.sender].royals[stakedIndex].stakedTimestamp,
                    balanceBonus,
                    true,
                    royalsBase
                );
                _removeTokenFromStakerAtIndex(stakedIndex, msg.sender, true);
                royals.transferFrom(address(this), msg.sender, royalsIds_[i]);
            }
        }
        if (oil > 0) _claimAmount(msg.sender, oil, false);
    }

    function unstakeAllHabibiz() external whenNotPaused {
        require(stakers[msg.sender].habibiz.length > 0, "No Habibiz staked");
        _unstake(true, false);
    }

    function unstakeAllRoyals() external whenNotPaused {
        require(royalStakers[msg.sender].royals.length > 0, "No Royals staked");
        _unstake(false, true);
    }

    function unstakeAll() external whenNotPaused {
        require(
            stakers[msg.sender].habibiz.length > 0 || royalStakers[msg.sender].royals.length > 0,
            "No Habibiz or Royals staked"
        );
        _unstake(true, true);
    }

    function unstakeHabibizByIds(uint256[] calldata tokenIds_) external whenNotPaused {
        _unstakeByIds(tokenIds_, new uint256[](0));
    }

    function unstakeRoyalsByIds(uint256[] calldata tokenIds_) external whenNotPaused {
        _unstakeByIds(new uint256[](0), tokenIds_);
    }

    function _removeTokenFromStakerAtIndex(
        uint256 index_,
        address staker_,
        bool isRoyal_
    ) internal {
        if (isRoyal_) {
            royalStakers[staker_].royals[index_] = royalStakers[staker_].royals[
                royalStakers[staker_].royals.length - 1
            ];
            royalStakers[staker_].royals.pop();
        } else {
            stakers[staker_].habibiz[index_] = stakers[staker_].habibiz[stakers[staker_].habibiz.length - 1];
            stakers[staker_].habibiz.pop();
        }
    }

    function _removeRoyalsFromStaker(address staker_, uint256[] memory tokenIds_) internal {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            for (uint256 j = 0; j < royalStakers[staker_].royals.length; j++) {
                if (tokenIds_[i] == royalStakers[staker_].royals[j].tokenId) {
                    _removeTokenFromStakerAtIndex(j, staker_, true);
                }
            }
        }
    }

    function _removeHabibizFromStaker(address staker_, uint256[] memory tokenIds_) internal {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            for (uint256 j = 0; j < stakers[staker_].habibiz.length; j++) {
                if (tokenIds_[i] == stakers[staker_].habibiz[j].tokenId) {
                    _removeTokenFromStakerAtIndex(j, staker_, false);
                }
            }
        }
    }

    function approveRescue(
        address revoker_,
        bool confirm_,
        bool rescueableByAdmin_
    ) external {
        require(confirm_, "Did not confirm");
        require(revoker_ != address(0), "Revoker cannot be null address");
        rescueable[msg.sender] = Rescueable(revoker_, rescueableByAdmin_);
    }

    function setStakedTransferFor(address staker_, address newAddress_) external onlyRuler {
        stakedTransfers[staker_] = newAddress_;
    }

    function stakedTransfer() external {
        address newAddress = stakedTransfers[msg.sender];
        require(newAddress != address(0), "Not approved for staked transfer");
        uint256 i;
        if (stakers[newAddress].habibiz.length == 0 && stakers[msg.sender].habibiz.length > 0) {
            stakers[newAddress].habibiz = stakers[msg.sender].habibiz;
        } else {
            for (i; i < stakers[msg.sender].habibiz.length; i++) {
                stakers[newAddress].habibiz.push(
                    Habibi(stakers[msg.sender].habibiz[i].stakedTimestamp, stakers[msg.sender].habibiz[i].tokenId)
                );
                _removeTokenFromStakerAtIndex(i, msg.sender, false);
            }
        }
        if (royalStakers[newAddress].royals.length == 0 && royalStakers[msg.sender].royals.length > 0) {
            royalStakers[newAddress].royals = royalStakers[msg.sender].royals;
        } else {
            for (i; i < royalStakers[msg.sender].royals.length; i++) {
                royalStakers[msg.sender].royals.push(
                    Royal(
                        royalStakers[msg.sender].royals[i].stakedTimestamp,
                        royalStakers[msg.sender].royals[i].tokenId
                    )
                );
                _cancelSwap(royalStakers[msg.sender].royals[i].tokenId, msg.sender);
                _removeTokenFromStakerAtIndex(i, msg.sender, true);
            }
        }
        stakers[newAddress].lastClaim = stakers[newAddress].lastClaim > stakers[msg.sender].lastClaim
            ? stakers[newAddress].lastClaim
            : stakers[msg.sender].lastClaim;

        delete stakers[msg.sender];
        delete royalStakers[msg.sender];
    }

    function revokeRescue(address rescueable_, bool confirm_) external {
        if (msg.sender == ruler) {
            require(rescueable[rescueable_].adminAllowedAsRevoker, "Admin is not allowed to revoke");
        } else {
            require(rescueable[rescueable_].revoker == msg.sender, "Sender is not revoker");
        }
        require(confirm_, "Did not confirm");

        delete rescueable[rescueable_];
    }

    /*////////////////////////////////////////////////////////////
                        Sacrifice for Royals
    ////////////////////////////////////////////////////////////*/

    function freeze(
        address staker_,
        uint256[] calldata habibizIds_,
        uint256 royalId_
    ) external returns (bool) {
        require(msg.sender == address(royals), "You do not have permission to call this function");
        require(
            royals.ownerOf(royalId_) == address(this) && claimedRoyals[royalId_] == address(0),
            "Invalid or claimed token id"
        );
        uint256 oil;

        for (uint256 i = 0; i < habibizIds_.length; i++) {
            (uint256 index, bool isOwned) = isOwnedByStaker(staker_, habibizIds_[i], false);
            require(isOwned, "Habibi not owned");
            oil += _calculateOil(staker_, habibizIds_[i], stakers[staker_].habibiz[index].stakedTimestamp, false);
            _removeTokenFromStakerAtIndex(index, staker_, false);
        }

        claimedRoyals[royalId_] = staker_;
        royalStakers[staker_].royals.push(Royal(block.timestamp, royalId_));
        _claimAmount(staker_, oil, false);
        return true;
    }


    function unFreeze(
        uint256 royalId_, 
        uint256 habibiz_, 
        bytes32[] calldata proof_
    ) external whenUnFreezeActive {
        // Gather timestamp once so it can be re-used.
        uint256 currentTimestamp = block.timestamp;

        // Ensure that the caller is eligble to unfreeze based on timer. 
        require(RoyalsUnFrozen[royalId_].eligbleClaimTimestamp <= currentTimestamp);

        // Leaf will be composed of the owner address and Habibiz tokenId.
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, habibiz_));

        // Verification if the caller owns the habibiz trying to be unfrozen.
        bool valid = _verify(proof_, unFreezeMerkleRoot, leaf);

        // If proof is not valid, we revert.
        if (!valid) revert("Invalid MerkleProof.");

        // Initiate Oil Transfer or can burn tokens need to discuss, this will be usable when contracts are merged.
        _transfer(msg.sender, address(this), unFreezeOilCost);

        _burn(address(this), unFreezeOilCost);

        // Return the Habibiz to staked array.
        stakers[msg.sender].habibiz.push(Habibi(block.timestamp, habibiz_));

        // Log claim
        RoyalsUnFrozen[royalId_].lastClaim = currentTimestamp;

        // Log timestamp where they can claim based on the timer set.
        RoyalsUnFrozen[royalId_].eligbleClaimTimestamp = currentTimestamp + unFreezeTimer;

        // Log the tokenId the Royal unfroze.
        RoyalsUnFrozen[royalId_].UnfrozenHabibiz.push(UnFrozenHabibi(currentTimestamp, habibiz_));
    }

    function setRoyalOwner(
        address staker_,
        address previousStaker_,
        uint256 royalId_,
        bool force_
    ) external onlyRuler {
        uint256 timestamp = block.timestamp;
        if (!force_) require(claimedRoyals[royalId_] == address(0), "Royal already claimed");
        if (previousStaker_ != address(0)) {
            for (uint256 i = 0; i < royalStakers[previousStaker_].royals.length; i++) {
                if (royalStakers[previousStaker_].royals[i].tokenId == royalId_) {
                    timestamp = royalStakers[previousStaker_].royals[i].stakedTimestamp;
                    _cancelSwap(royalId_, previousStaker_);
                    _removeTokenFromStakerAtIndex(i, previousStaker_, true);
                    break;
                }
            }
        }
        claimedRoyals[royalId_] = staker_;
        ownerOfRoyal[royalId_] = staker_;
        royalStakers[staker_].royals.push(Royal(timestamp, royalId_));
    }

    function swapRoyals(uint256 myRoyalId_, uint256 theirRoyalId_) external whenSwappingActive returns (bool) {
        uint256 cost = swapRoyalsCost == 0 ? swapRoyalsCost : swapRoyalsCost / 2;
        require(swapRoyalsCost == 0 || balanceOf[msg.sender] >= cost, "Not enough OIL");
        (uint256 index, bool isOwned) = isOwnedByStaker(msg.sender, myRoyalId_, true);
        require(isOwned, "You don't own that Royal");
        if (royalSwaps[theirRoyalId_] == myRoyalId_) {
            uint256 stakedTimestamp = royalStakers[msg.sender].royals[index].stakedTimestamp;
            address theirAddress = ownerOfRoyal[theirRoyalId_];
            (uint256 theirIndex, bool theirOwned) = isOwnedByStaker(theirAddress, theirRoyalId_, true);
            if (!theirOwned) {
                delete royalSwaps[theirRoyalId_];
                escrowedOil[theirRoyalId_] = 0;
                return false;
            }
            uint256 theirStakedTimestamp = royalStakers[theirAddress].royals[theirIndex].stakedTimestamp;

            _removeTokenFromStakerAtIndex(index, msg.sender, true);
            _removeTokenFromStakerAtIndex(theirIndex, theirAddress, true);

            royalStakers[msg.sender].royals.push(Royal(stakedTimestamp, theirRoyalId_));
            royalStakers[theirAddress].royals.push(Royal(theirStakedTimestamp, myRoyalId_));

            balanceOf[msg.sender] -= cost;
            escrowedOil[theirRoyalId_] = 0;

            delete royalSwaps[myRoyalId_];
            delete royalSwaps[theirRoyalId_];
            ownerOfRoyal[myRoyalId_] = theirAddress;
            ownerOfRoyal[theirRoyalId_] = msg.sender;
        } else {
            royalSwaps[myRoyalId_] = theirRoyalId_;
            balanceOf[msg.sender] -= cost;
            escrowedOil[myRoyalId_] += cost;
            ownerOfRoyal[myRoyalId_] = msg.sender;
        }
        return true;
    }

    function cancelSwap(uint256 myRoyalId_) external whenSwappingActive {
        require(ownerOfRoyal[myRoyalId_] == msg.sender, "You don't own that Royal");
        _cancelSwap(myRoyalId_, msg.sender);
    }

    function _cancelSwap(uint256 myRoyalId_, address owner_) internal {
        balanceOf[owner_] += escrowedOil[myRoyalId_];
        escrowedOil[myRoyalId_] = 0;
        delete royalSwaps[myRoyalId_];
    }

    /*///////////////////////////////////////////////////////////////
                              CLAIMING
    //////////////////////////////////////////////////////////////*/

    function claim() public whenNotPaused {
        require(!blockList[msg.sender], "Address Blocked");
        _claim(msg.sender);
    }

    function _claim(address to_) internal {
        uint256 oil = calculateOilRewards(to_);
        if (oil > 0) {
            _claimAmount(to_, oil, true);
        }
    }

    function _claimAmount(
        address to_,
        uint256 amount_,
        bool updateLastClaimed_
    ) internal {
        if (updateLastClaimed_) stakers[to_].lastClaim = block.timestamp;
        _mint(to_, amount_);
    }

    function unclaimedRoyals() external view returns (uint256[] memory) {
        uint256[] memory staked = royals.tokensOfOwner(address(this));
        uint256[] memory unclaimed = new uint256[](staked.length);
        uint256 counter;
        for (uint256 i = 0; i < staked.length; i++) {
            if (claimedRoyals[staked[i]] == address(0)) unclaimed[counter++] = staked[i];
        }
        return unclaimed;
    }

    /*///////////////////////////////////////////////////////////////
                            OIL REWARDS
    //////////////////////////////////////////////////////////////*/

    function calculateOilRewards(address staker_) public view returns (uint256 oilAmount) {
        uint256 balanceBonus = holderBonusPercentage(staker_);
        uint256 habibizAmount = stakers[staker_].habibiz.length;
        uint256 royalsAmount = royalStakers[staker_].royals.length;
        uint256 totalStaked = habibizAmount + royalsAmount;
        uint256 royalsBase = getRoyalsBase(staker_);
        uint256 lastClaimTimestamp = stakers[staker_].lastClaim;

        for (uint256 i = 0; i < totalStaked; i++) {
            bool isAnimated;
            uint256 tokenId;
            bool isRoyal;
            uint256 stakedTimestamp;
            if (i < habibizAmount) {
                tokenId = stakers[staker_].habibiz[i].tokenId;
                stakedTimestamp = stakers[staker_].habibiz[i].stakedTimestamp;
                isAnimated = _isAnimated(tokenId);
            } else {
                tokenId = royalStakers[staker_].royals[i - habibizAmount].tokenId;
                stakedTimestamp = royalStakers[staker_].royals[i - habibizAmount].stakedTimestamp;
                isRoyal = true;
            }
            oilAmount += calculateOilOfToken(
                isAnimated,
                lastClaimTimestamp,
                stakedTimestamp,
                balanceBonus,
                isRoyal,
                royalsBase
            );
        }
    }

    function _calculateTimes(uint256 stakedTimestamp_, uint256 lastClaimedTimestamp_)
        internal
        view
        returns (uint256, uint256)
    {
        if (lastClaimedTimestamp_ < stakedTimestamp_) {
            lastClaimedTimestamp_ = stakedTimestamp_;
        }
        return (block.timestamp - stakedTimestamp_, block.timestamp - lastClaimedTimestamp_);
    }

    function _calculateOil(
        address staker_,
        uint256 tokenId_,
        uint256 stakedTimestamp_,
        bool isRoyal_
    ) internal view returns (uint256) {
        uint256 balanceBonus = holderBonusPercentage(staker_);
        uint256 lastClaimTimestamp = stakers[staker_].lastClaim;
        uint256 royalsBase = getRoyalsBase(staker_);
        return
            calculateOilOfToken(
                isRoyal_ ? false : _isAnimated(tokenId_),
                lastClaimTimestamp,
                stakedTimestamp_,
                balanceBonus,
                isRoyal_,
                royalsBase
            );
    }

    function calculateOilOfToken(
        bool isAnimated_,
        uint256 lastClaimedTimestamp_,
        uint256 stakedTimestamp_,
        uint256 balanceBonus_,
        bool isRoyal_,
        uint256 royalsBase
    ) internal view returns (uint256 oil) {
        uint256 bonusPercentage;

        (uint256 stakedTime, uint256 unclaimedTime) = _calculateTimes(stakedTimestamp_, lastClaimedTimestamp_);

        if (stakedTime >= 90 days) {
            bonusPercentage = 100;
        } else {
            for (uint256 i = 2; i < 4; i++) {
                uint256 timeRequirement = 15 days * i;
                if (timeRequirement > 0 && timeRequirement <= stakedTime) {
                    bonusPercentage += 15;
                } else {
                    break;
                }
            }
        }

        if (isRoyal_) {
            oil = (unclaimedTime * royalsBase * 1 ether) / 1 days;
        } else if (isAnimated_) {
            oil = (unclaimedTime * 5000 ether) / 1 days;
        } else {
            bonusPercentage += balanceBonus_;
            oil = (unclaimedTime * 1000 ether) / 1 days;
        }
        oil += ((oil * bonusPercentage) / 100);
    }

    function getRoyalsBase(address staker_) public view returns (uint256 base) {
        if (royalStakers[staker_].royals.length == 1) {
            base = 12000;
        } else if (royalStakers[staker_].royals.length == 2) {
            base = 13500;
        } else if (royalStakers[staker_].royals.length >= 3) {
            base = 15000;
        } else {
            base = 0;
        }
    }

    function staker(address staker_) public view returns (Staker memory, RoyalStaker memory) {
        return (stakers[staker_], royalStakers[staker_]);
    }

    function canSteal(address staker_, uint256 royalId_) public view returns (bool canStealHabibiz) {
        return RoyalsUnFrozen[royalId_].UnfrozenHabibiz.length >= 10 && habibizOfStaker(staker_).length >= 10 ? true : false;
    }
 
    /*///////////////////////////////////////////////////////////////
                            OIL PRIVILEGE
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 value) external onlyMinter {
        _mint(to, value);
    }

    function burn(address from, uint256 value) external onlyMinter {
        _burn(from, value);
    }

    /*///////////////////////////////////////////////////////////////
                         Ruler Function
    //////////////////////////////////////////////////////////////*/

    function setMinter(address minter_, bool canMint_) external onlyRuler {
        isMinter[minter_] = canMint_;
    }

    function setRuler(address ruler_) external onlyRuler {
        ruler = ruler_;
    }

    function setPaused(bool paused_) external onlyRuler {
        paused = paused_;
    }

    function setHabibiAddress(address habibiAddress_) external onlyRuler {
        habibi = ERC721Like(habibiAddress_);
    }

    function setRoyalsAddress(address royalsAddress_) external onlyRuler {
        royals = ERC721Like(royalsAddress_);
    }

    function setSellFee(uint256 fee_) external onlyRuler {
        sellFee = fee_;
    }

    function setUniswapV2Router(address router_) external onlyRuler {
        uniswapV2Router = IUniswapV2Router02(router_);
    }

    function setSushiswapV2Router(address router_) external onlyRuler {
        sushiswapV2Router = IUniswapV2Router02(router_);
    }

    function setV2Routers(address uniswapRouter_, address sushiswapRouter_) external onlyRuler {
        uniswapV2Router = IUniswapV2Router02(uniswapRouter_);
        sushiswapV2Router = IUniswapV2Router02(sushiswapRouter_);
    }

    function setUniPair(address uniPair_) external onlyRuler {
        uniPair = uniPair_;
    }

    function setSushiswapPair(address sushiswapPair_) external onlyRuler {
        sushiswapPair = sushiswapPair_;
    }

    function setPairs(address uniPair_, address sushiswapPair_) external onlyRuler {
        uniPair = uniPair_;
        sushiswapPair = sushiswapPair_;
    }

    function excludeFromFees(address[] calldata addresses_, bool[] calldata excluded_) external onlyRuler {
        for (uint256 i = 0; i < addresses_.length; i++) {
            excludedFromFees[addresses_[i]] = excluded_[i];
        }
    }

    function blockOrUnblockAddresses(address[] calldata addresses_, bool[] calldata blocked_) external onlyRuler {
        for (uint256 i = 0; i < addresses_.length; i++) {
            blockList[addresses_[i]] = blocked_[i];
        }
    }

    function setRoyalSwapCost(uint256 cost_) external onlyRuler {
        swapRoyalsCost = cost_;
    }

    function setSwappingActive(bool active_) external onlyRuler {
        swappingActive = active_;
    }

    function setRoyalsHabibiRatio(uint256 ratio_) external onlyRuler {
        royalsHabibiRatio = ratio_;
    }

     function changeUnFreezePrice(uint256 cost_) external whenUnFreezeActive onlyRuler {
        unFreezeOilCost = cost_;
    }
    
    function changeUnFreezeTimer(uint256 newtime_) external whenUnFreezeActive onlyRuler {
        unFreezeTimer = newtime_;
    }

    function toggleUnfreeze() external onlyRuler {
        unFreezeActive = !unFreezeActive;
    }

    function setUnfreezeMerkleRoot(bytes32 root_) external onlyRuler {
        unFreezeMerkleRoot = root_;
    }

    /// emergency
    function rescue(
        address staker_,
        address to_,
        uint256[] calldata habibiIds_,
        uint256[] calldata royalIds_
    ) external onlyRuler {
        require(rescueable[staker_].revoker != address(0), "User has not opted-in for rescue");
        if (habibiIds_.length > 0) {
            for (uint256 i = 0; i < habibiIds_.length; i++) {
                (uint256 stakedIndex, bool isOwned) = isOwnedByStaker(staker_, habibiIds_[i], false);
                require(isOwned, "Habibi TokenID not found");
                stakers[to_].habibiz.push(Habibi(stakers[staker_].habibiz[stakedIndex].stakedTimestamp, habibiIds_[i]));
                _removeTokenFromStakerAtIndex(stakedIndex, staker_, false);
            }
        }

        if (royalIds_.length > 0) {
            for (uint256 i = 0; i < royalIds_.length; i++) {
                (uint256 stakedIndex, bool isOwned) = isOwnedByStaker(staker_, royalIds_[i], true);
                require(isOwned, "Royal TokenID not found");
                royalStakers[to_].royals.push(
                    Royal(royalStakers[staker_].royals[stakedIndex].stakedTimestamp, royalIds_[i])
                );
                _removeTokenFromStakerAtIndex(stakedIndex, staker_, true);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _getRouterFromPair(address pairAddress_) internal view returns (IUniswapV2Router02) {
        return pairAddress_ == address(uniPair) ? uniswapV2Router : sushiswapV2Router;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(balanceOf[from] >= value, "ERC20: transfer amount exceeds balance");
        uint256 tax;

        bool shouldTax = ((to == uniPair && balanceOf[to] != 0) || (to == sushiswapPair && balanceOf[to] != 0)) &&
            !swapping;
        if (shouldTax && !excludedFromFees[from]) {
            tax = (value * sellFee) / 100_000;
            if (tax > 0) {
                balanceOf[address(this)] += tax;
                swapTokensForEth(to, tax, treasury);
            }
        }
        uint256 taxedAmount = value - tax;
        balanceOf[from] -= value;
        balanceOf[to] += taxedAmount;
        emit Transfer(from, to, taxedAmount);
    }

    function swapTokensForEth(
        address pairAddress_,
        uint256 amountIn_,
        address to_
    ) private lockTheSwap {
        IUniswapV2Router02 router = _getRouterFromPair(pairAddress_);
        IERC20(address(this)).approve(address(router), amountIn_);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH(); // or router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn_, 1, path, to_, block.timestamp);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }

    function holderBonusPercentage(address staker_) public view returns (uint256) {
        uint256 balance = stakers[staker_].habibiz.length + royalStakers[staker_].royals.length * royalsHabibiRatio;

        if (balance < 5) return 0;
        if (balance < 10) return 15;
        if (balance < 20) return 25;
        return 35;
    }

    function _isAnimated(uint256 id_) internal pure returns (bool animated) {
        return
            id_ == 40 ||
            id_ == 108 ||
            id_ == 169 ||
            id_ == 191 ||
            id_ == 246 ||
            id_ == 257 ||
            id_ == 319 ||
            id_ == 386 ||
            id_ == 496 ||
            id_ == 562 ||
            id_ == 637 ||
            id_ == 692 ||
            id_ == 832 ||
            id_ == 942 ||
            id_ == 943 ||
            id_ == 957 ||
            id_ == 1100 ||
            id_ == 1108 ||
            id_ == 1169 ||
            id_ == 1178 ||
            id_ == 1627 ||
            id_ == 1706 ||
            id_ == 1843 ||
            id_ == 1884 ||
            id_ == 2137 ||
            id_ == 2158 ||
            id_ == 2165 ||
            id_ == 2214 ||
            id_ == 2232 ||
            id_ == 2238 ||
            id_ == 2508 ||
            id_ == 2629 ||
            id_ == 2863 ||
            id_ == 3055 ||
            id_ == 3073 ||
            id_ == 3280 ||
            id_ == 3297 ||
            id_ == 3322 ||
            id_ == 3327 ||
            id_ == 3361 ||
            id_ == 3411 ||
            id_ == 3605 ||
            id_ == 3639 ||
            id_ == 3774 ||
            id_ == 4250 ||
            id_ == 4267 ||
            id_ == 4302 ||
            id_ == 4362 ||
            id_ == 4382 ||
            id_ == 4397 ||
            id_ == 4675 ||
            id_ == 4707 ||
            id_ == 4863;
    }

    function _verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }


    /*///////////////////////////////////////////////////////////////
                          MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyMinter() {
        require(isMinter[msg.sender], "FORBIDDEN TO MINT OR BURN");
        _;
    }

    modifier onlyRuler() {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenSwappingActive() {
        require(swappingActive, "Swapping is paused");
        _;
    }

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier whenUnFreezeActive() {
        require(unFreezeActive, "Unfreezing is not active");
        _;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return ERC721Like.onERC721Received.selector;
    }
}

interface ERC721Like {
    function balanceOf(address holder_) external view returns (uint256);

    function ownerOf(uint256 id_) external view returns (address);

    function walletOfOwner(address _owner) external view returns (uint256[] calldata);

    function tokensOfOwner(address owner) external view returns (uint256[] memory);

    function isApprovedForAll(address operator_, address address_) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface UniPairLike {
    function token0() external returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/erc721a/contracts/extensions/ERC721AQueryable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "./Oil.sol";
import "./Habibi.sol";

contract Royals is ERC721AQueryable, Ownable {
    enum SaleState {
        Disabled,
        AllowlistSale,
        PublicSale
    }

    Oil public constant OIL = Oil(0xf369eea446aBCE1AE5f1Eb41B58F5e1F7aDb11C2);
    Habibi public constant HABIBIZ = Habibi(0x9EA65C31A9C055DaD3C5462576EB856B95dA1A46);

    uint256 public constant MAX_SUPPLY = 300;
    uint256 public availableSupply = 100;
    uint256 public maxClaimPerWallet = 1;
    uint256 public amountRequiredToBurn = 8;
    bytes32 public root;
    string public baseURI;
    string public notRevealedUri;

    SaleState public saleState = SaleState.Disabled;

    event SaleStateChanged(uint256 previousState, uint256 nextState, uint256 timestamp);
    event ClaimedRoyal(address indexed staker, uint256[] frozenTokenIds, uint256 indexed royalId);

    // solhint-disable-next-line no-empty-blocks
    constructor(string memory baseURI_) ERC721A("Royals", "ROYALS") {
        baseURI = baseURI_;
    }

    modifier isClaimingActive() {
        require(saleState != SaleState.Disabled, "Claiming is not active");
        _;
    }

    modifier isInAllowlist(address address_, bytes32[] calldata proof_) {
        require(saleState == SaleState.PublicSale || _verify(_leaf(address_), proof_), "Not in allowlist");
        _;
    }

    //++++++++
    // Public functions
    //++++++++

    function sacrificeAndClaim(
        uint256[] calldata habibizTokenIds_,
        uint256 royalTokenId_,
        bytes32[] calldata proof_
    ) external isClaimingActive isInAllowlist(msg.sender, proof_) {
        require(habibizTokenIds_.length >= amountRequiredToBurn, "Must burn at least required amount of habibiz");
        require(
            habibizTokenIds_.length % amountRequiredToBurn == 0,
            "Must burn multiples of required amount of habibiz"
        );
        setApprovalForAll(address(OIL), true);
        // Count number of potential mints
        uint256 numToClaim = habibizTokenIds_.length / amountRequiredToBurn;

        // O(N^2) loop, its more gas efficient to use this than a mapping with addresses, due to lower storage usage
        for (uint256 i = 0; i < habibizTokenIds_.length; i++) {
            for (uint256 j = i + 1; j < habibizTokenIds_.length; j++) {
                require(habibizTokenIds_[i] != habibizTokenIds_[j], "No duplicates allowed");
            }
        }

        // Now that we have amount a user can mint, lets ensure they can mint given maximum mints per wallet, and batch size
        require(numToClaim <= availableSupply, "available supply reached");
        // Ensure user doesn't already exceed maximum number of mints
        require(_getAux(msg.sender) < maxClaimPerWallet, "Not have enough mints available");
        // Ensure user doesn't exceed maxmium allowable number of mints
        require(uint256(_getAux(msg.sender)) + numToClaim <= maxClaimPerWallet, "Would exceed maximum allowable mints");
        // Burns staked habibis and if there was an issue burning, it reverts
        require(OIL.freeze(msg.sender, habibizTokenIds_, royalTokenId_), "Failed to claim Royal");

        _setAux(_msgSender(), uint64(numToClaim) + _getAux(msg.sender)); // Kfish - moved this to happen before mint
        emit ClaimedRoyal(msg.sender, habibizTokenIds_, royalTokenId_);
    }

    //++++++++
    // Owner functions
    //++++++++

    function mintToStakingContract(uint256 quantity_) external onlyOwner {
        require(quantity_ <= availableSupply, "Would exceed available supply");
        _safeMint(address(OIL), quantity_);
    }

    function setRoot(bytes32 root_) external onlyOwner {
        root = root_;
    }

    // Sale functions
    function setSaleState(uint256 state_) external onlyOwner {
        require(state_ < 3, "Invalid state");
        uint256 prevState = uint256(saleState);
        saleState = SaleState(state_);
        emit SaleStateChanged(prevState, state_, block.timestamp);
    }

    function setAvailableSupply(uint256 availableSupply_) external onlyOwner {
        require(availableSupply_ <= MAX_SUPPLY, "Would exceed max supply");
        availableSupply = availableSupply_;
    }

    function setmaxClaimPerWallet(uint256 maxClaimPerWallet_) public onlyOwner {
        maxClaimPerWallet = maxClaimPerWallet_;
    }

    function setBaseURI(string memory newBaseURI_) public onlyOwner {
        baseURI = newBaseURI_;
    }

    function setNotRevealedURI(string memory notRevealedURI_) public onlyOwner {
        notRevealedUri = notRevealedURI_;
    }

    function withdraw() public payable onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function setAmountRequiredToBurn(uint256 amountRequiredToBurn_) public onlyOwner {
        amountRequiredToBurn = amountRequiredToBurn_;
    }

    //++++++++
    // Internal functions
    //++++++++
    function _leaf(address account_) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account_));
    }

    function _verify(bytes32 leaf_, bytes32[] memory proof_) internal view returns (bool) {
        return MerkleProof.verify(proof_, root, leaf_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}