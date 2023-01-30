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
        if (owner == address(0)) _revert(BalanceQueryForZeroAddress.selector);
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
        if (!_exists(tokenId)) _revert(URIQueryForNonexistentToken.selector);

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
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256 packed) {
        if (_startTokenId() <= tokenId) {
            packed = _packedOwnerships[tokenId];
            // If not burned.
            if (packed & _BITMASK_BURNED == 0) {
                // If the data at the starting slot does not exist, start the scan.
                if (packed == 0) {
                    if (tokenId >= _currentIndex) _revert(OwnerQueryForNonexistentToken.selector);
                    // Invariant:
                    // There will always be an initialized ownership slot
                    // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                    // before an unintialized ownership slot
                    // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                    // Hence, `tokenId` will not underflow.
                    //
                    // We can directly compare the packed value.
                    // If the address is zero, packed will be zero.
                    for (;;) {
                        unchecked {
                            packed = _packedOwnerships[--tokenId];
                        }
                        if (packed == 0) continue;
                        return packed;
                    }
                }
                // Otherwise, the data exists and is not burned. We can skip the scan.
                // This is possible because we have already achieved the target condition.
                // This saves 2143 gas on transfers of initialized tokens.
                return packed;
            }
        }
        _revert(OwnerQueryForNonexistentToken.selector);
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
        if (!_exists(tokenId)) _revert(ApprovalQueryForNonexistentToken.selector);

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

        // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
        from = address(uint160(uint256(uint160(from)) & _BITMASK_ADDRESS));

        if (address(uint160(prevOwnershipPacked)) != from) _revert(TransferFromIncorrectOwner.selector);

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);

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

        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
        uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;
        assembly {
            // Emit the `Transfer` event.
            log4(
                0, // Start of data (0, since no data).
                0, // End of data (0, since no data).
                _TRANSFER_EVENT_SIGNATURE, // Signature.
                from, // `from`.
                toMasked, // `to`.
                tokenId // `tokenId`.
            )
        }
        if (toMasked == 0) _revert(TransferToZeroAddress.selector);

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
                _revert(TransferToNonERC721ReceiverImplementer.selector);
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
                _revert(TransferToNonERC721ReceiverImplementer.selector);
            }
            assembly {
                revert(add(32, reason), mload(reason))
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
        if (quantity == 0) _revert(MintZeroQuantity.selector);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
            uint256 toMasked = uint256(uint160(to)) & _BITMASK_ADDRESS;

            if (toMasked == 0) _revert(MintToZeroAddress.selector);

            uint256 end = startTokenId + quantity;
            uint256 tokenId = startTokenId;

            do {
                assembly {
                    // Emit the `Transfer` event.
                    log4(
                        0, // Start of data (0, since no data).
                        0, // End of data (0, since no data).
                        _TRANSFER_EVENT_SIGNATURE, // Signature.
                        0, // `address(0)`.
                        toMasked, // `to`.
                        tokenId // `tokenId`.
                    )
                }
                // The `!=` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
            } while (++tokenId != end);

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
        if (to == address(0)) _revert(MintToZeroAddress.selector);
        if (quantity == 0) _revert(MintZeroQuantity.selector);
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) _revert(MintERC2309QuantityExceedsLimit.selector);

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
                        _revert(TransferToNonERC721ReceiverImplementer.selector);
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) _revert(bytes4(0));
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
    function _approve(
        address to,
        uint256 tokenId,
        bool approvalCheck
    ) internal virtual {
        address owner = ownerOf(tokenId);

        if (approvalCheck && _msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                _revert(ApprovalCallerNotOwnerNorApproved.selector);
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
                if (!isApprovedForAll(from, _msgSenderERC721A())) _revert(TransferCallerNotOwnerNorApproved.selector);
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
        if (packed == 0) _revert(OwnershipNotInitializedForExtraData.selector);
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

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import {AccessControlEnumerable} from "../utils/AccessControlEnumerable.sol";

/**
@notice ERC721 extension that overrides the OpenZeppelin _baseURI() function to
return a prefix that can be set by the contract owner.
 */
contract BaseTokenURI is AccessControlEnumerable {
    /// @notice Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor(string memory _baseTokenURI) {
        _setBaseTokenURI(_baseTokenURI);
    }

    /// @notice Sets the base token URI prefix.
    /// @dev Only callable by the contract steerer.
    function setBaseTokenURI(string memory _baseTokenURI)
        public
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _setBaseTokenURI(_baseTokenURI);
    }

    /// @notice Sets the base token URI prefix.
    function _setBaseTokenURI(string memory _baseTokenURI) internal virtual {
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import {IERC165, ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface IERC4906Events {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

/// @title EIP-721 Metadata Update Extension
// solhint-disable-next-line no-empty-blocks
interface IERC4906 is IERC165, IERC4906Events {

}

contract ERC4906 is IERC4906, ERC165 {
    function _refreshMetadata(uint256 tokenId) internal {
        emit MetadataUpdate(tokenId);
    }

    function _refreshMetadata(uint256 fromTokenId, uint256 toTokenId) internal {
        emit BatchMetadataUpdate(fromTokenId, toTokenId);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == bytes4(0x49064906) ||
            ERC165.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {AccessControlEnumerable} from "../utils/AccessControlEnumerable.sol";
import {AccessControlPausable} from "../utils/AccessControlPausable.sol";
import {ERC4906} from "./ERC4906.sol";

/**
@notice An ERC721A contract with common functionality:
 - Pausable with toggling functions exposed to Owner only
 - ERC2981 royalties
 */
contract ERC721ACommon is ERC721A, AccessControlPausable, ERC2981, ERC4906 {
    constructor(
        address admin,
        address steerer,
        string memory name,
        string memory symbol,
        address payable royaltyReciever,
        uint96 royaltyBasisPoints
    ) ERC721A(name, symbol) {
        _setDefaultRoyalty(royaltyReciever, royaltyBasisPoints);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEFAULT_STEERING_ROLE, steerer);
    }

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
        override(ERC721A, AccessControlEnumerable, ERC2981, ERC4906)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            ERC4906.supportsInterface(interfaceId);
    }

    /// @notice Sets the royalty receiver and percentage (in units of basis
    /// points = 0.01%).
    function setDefaultRoyalty(address receiver, uint96 basisPoints)
        public
        virtual
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _setDefaultRoyalty(receiver, basisPoints);
    }

    function emitMetadataUpdateForAll()
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        // EIP4906 is unfortunately quite vague on whether the `toTokenId` in
        // the following event is included or not. We hence use `totalSupply()`
        // to ensure that the last actual `tokenId` is included in any case.
        _refreshMetadata(0, totalSupply());
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2023 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import {AccessControlEnumerable as ACE} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract AccessControlEnumerable is ACE {
    /// @notice The default role intended to perform access-restricted actions.
    /// @dev We are using this instead of DEFAULT_ADMIN_ROLE because the latter
    /// is intended to grant/revoke roles and will be secured differently.
    bytes32 public constant DEFAULT_STEERING_ROLE =
        keccak256("DEFAULT_STEERING_ROLE");

    /// @dev Overrides supportsInterface so that inheriting contracts can
    /// reference this contract instead of OZ's version for further overrides.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ACE)
        returns (bool)
    {
        return ACE.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AccessControlEnumerable} from "./AccessControlEnumerable.sol";

/// @notice A Pausable contract that can only be toggled by a member of the
/// STEERING role.
contract AccessControlPausable is AccessControlEnumerable, Pausable {
    /// @notice Pauses the contract.
    function pause() public onlyRole(DEFAULT_STEERING_ROLE) {
        Pausable._pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyRole(DEFAULT_STEERING_ROLE) {
        Pausable._unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / _feeDenominator();

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
    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal virtual {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";

/**
 * @title Proof of Conference Tickets - Airdrop module
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
abstract contract Airdropper is AccessControlEnumerable {
    // =========================================================================
    //                          Errors
    // =========================================================================

    error ExceedingAirdropLimit();

    // =========================================================================
    //                          Constants
    // =========================================================================

    /**
     * @notice The role allowed to perform airdrops.
     */
    bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");

    // =========================================================================
    //                          Storage
    // =========================================================================

    /**
     * @notice The number of tokens that have already been airdropped.
     */
    uint16 private _numAirdropped;

    /**
     * @notice The maximum number of airdrops.
     */
    uint16 private _maxAirdrops = 250;

    // =========================================================================
    //                          Getter/Setter
    // =========================================================================

    /**
     * @notice Returns the maximum number of airdroppable tickets.
     * @dev For testing.
     */
    function _maxNumAirdrops() internal view returns (uint16) {
        return _maxAirdrops;
    }

    /**
     * @notice Sets the maximum number of airdroppable tickets.
     */
    function setMaxNumAirdrops(uint16 maxNumAirdrops)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _maxAirdrops = maxNumAirdrops;
    }

    // =========================================================================
    //                          Airdrops
    // =========================================================================

    /**
     * @notice Airdrops a number of tickets to a given address.
     */
    function _doAirdrop(address to, uint256 num)
        internal
        onlyRole(AIRDROPPER_ROLE)
    {
        if (_numAirdropped + num > _maxAirdrops) {
            revert ExceedingAirdropLimit();
        }
        _numAirdropped += uint16(num);
        _mintAirdrop(to, num);
    }

    /**
     * @notice Callback that mints the airdropped tokens.
     * @dev Will be provided by `Minter`.
     */
    function _mintAirdrop(address to, uint256 num) internal virtual;
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IDelegationRegistry} from
    "delegatecash/delegation-registry/IDelegationRegistry.sol";
import {TokenRedemption} from "poc-ticket/TokenRedemption.sol";
import {PROOFTokens} from "poc-ticket/PROOFTokens.sol";

/**
 * @title Proof of Conference Tickets - PROOF NFT delegation verification module
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
contract DelegationChecker {
    // =========================================================================
    //                           Errors
    // =========================================================================

    error InvalidTokenDelegation(IERC721 token, uint256 tokenId);
    error InvalidContractDelegation(IERC721 token);
    error InvalidDelegation();
    error NoDelegation();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The PROOF Collective token.
     */
    IERC721 private immutable _proof;

    /**
     * @notice The Moonbirds token.
     */
    IERC721 private immutable _moonbirds;

    /**
     * @notice The Oddities token.
     */
    IERC721 private immutable _oddities;

    /**
     * @notice The delegate.cash delegation registry.
     */
    IDelegationRegistry private immutable _delegationRegistry;

    // =========================================================================
    //                           Construction
    // =========================================================================

    constructor(
        PROOFTokens memory tokens,
        IDelegationRegistry delegationRegistry
    ) {
        _proof = tokens.proof;
        _moonbirds = tokens.moonbirds;
        _oddities = tokens.oddities;
        _delegationRegistry = delegationRegistry;
    }

    // =========================================================================
    //                           Checks
    // =========================================================================

    /**
     * @notice Checks if the delegate has sufficient delegations to redeem PoC
     * tickets using the supplied tokens.
     * @dev Reverts otherwise.
     */
    function _checkDelegation(
        address delegate,
        address delegator,
        IDelegationRegistry.DelegationType delegationType,
        TokenRedemption[] calldata pcRedemptions,
        TokenRedemption[] calldata mbRedemptions,
        TokenRedemption[] calldata oddRedemptions
    ) internal view {
        if (delegationType == IDelegationRegistry.DelegationType.ALL) {
            if (_delegationRegistry.checkDelegateForAll(delegate, delegator)) {
                return;
            }
            revert InvalidDelegation();
        }

        if (delegationType == IDelegationRegistry.DelegationType.CONTRACT) {
            if (pcRedemptions.length > 0) {
                _checkContractDelegation(delegate, delegator, _proof);
            }
            if (mbRedemptions.length > 0) {
                _checkContractDelegation(delegate, delegator, _moonbirds);
            }
            if (oddRedemptions.length > 0) {
                _checkContractDelegation(delegate, delegator, _oddities);
            }
            return;
        }

        if (delegationType == IDelegationRegistry.DelegationType.TOKEN) {
            _checkTokenDelegation(delegate, delegator, _proof, pcRedemptions);
            _checkTokenDelegation(
                delegate, delegator, _moonbirds, mbRedemptions
            );
            _checkTokenDelegation(
                delegate, delegator, _oddities, oddRedemptions
            );
            return;
        }

        revert NoDelegation();
    }

    /**
     * @notice Checks if the delegate has a contract-wide delegation for the
     * specified token if the list of redemptions is not empty.
     * @dev Reverts otherwise.
     */
    function _checkContractDelegation(
        address delegate,
        address delegator,
        IERC721 token
    ) private view {
        if (
            !_delegationRegistry.checkDelegateForContract(
                delegate, delegator, address(token)
            )
        ) {
            revert InvalidContractDelegation(token);
        }
    }

    /**
     * @notice Checks if the delegate has a token-specific delegation for the
     * redeeming tokens
     * @dev Reverts otherwise.
     */
    function _checkTokenDelegation(
        address delegate,
        address delegator,
        IERC721 token,
        TokenRedemption[] calldata redemptions
    ) private view {
        for (uint256 i; i < redemptions.length; ++i) {
            if (
                !_delegationRegistry.checkDelegateForToken(
                    delegate, delegator, address(token), redemptions[i].tokenId
                )
            ) {
                revert InvalidTokenDelegation(token, redemptions[i].tokenId);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {ERC721ATransferRestricted} from
    "poc-ticket/TransferRestriction/ERC721ATransferRestricted.sol";

/**
 * @title Proof of Conference Tickets - Minter module
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
abstract contract Minter is ERC721ATransferRestricted {
    error UnavailableForAirdroppedTokens(uint256);

    /**
     * @dev We use this to reduce the storage requirements for the block number
     * in which the tickets have been minted.
     */
    uint256 private immutable _blockNumberOffset;

    /**
     * @notice The mixHashes at a given block number.
     * @dev Set during purchases.
     */
    mapping(uint256 => uint256) private _mixHashes;

    constructor() {
        // Subtracting 1 guarantees that `block.number - _blockNumberOffset` can
        // never be zero. Hence we can use a zero value to distingish airdropped
        // tokens.
        _blockNumberOffset = block.number - 1;
    }

    /**
     * @notice Callback to mint tokens for a purchase.
     * @dev Store the current `block.number` and `mixHash`, unlike
     * `mintAirdrop`.
     */
    function _mintPurchase(address to, uint256 num) internal {
        uint256 startTokenId = _nextTokenId();
        _mint(to, num);

        // This applies to the entire batch of `num` tokens as per ERC721A
        // default.
        _setExtraDataAt(startTokenId, uint24(block.number - _blockNumberOffset));
        _mixHashes[block.number] = block.difficulty;
    }

    /**
     * @notice Callback to mint tokens during airdrops.
     * @dev Note the difference compared to `_mintPurchase()` as `block.number`
     * and `mixHash` aren't stored.
     */
    function _mintAirdrop(address to, uint256 num) internal virtual {
        _mint(to, num);
    }

    /**
     * @notice ECR721A override to propagate the storage-hitchhiking token info
     * during transfers.
     */
    function _extraData(address, address, uint24 previousExtraData)
        internal
        view
        virtual
        override
        returns (uint24)
    {
        return previousExtraData;
    }

    /**
     * @notice Checks if a given ticket was airdropped.
     * @dev False for purchased tickets.
     */
    function _airdropped(uint256 ticketId)
        internal
        view
        virtual
        returns (bool)
    {
        return _ownershipOf(ticketId).extraData == 0;
    }

    /**
     * @notice Returns the block in which a purchased ticket has been minted.
     * @dev Reverts for airdropped tokens.
     */
    function _mintBlockNumber(uint256 ticketId)
        internal
        view
        virtual
        returns (uint256)
    {
        if (_airdropped(ticketId)) {
            revert UnavailableForAirdroppedTokens(ticketId);
        }

        return uint256(_ownershipOf(ticketId).extraData) + _blockNumberOffset;
    }

    /**
     * @notice Returns the mixHash for a given token.
     * @dev Reverts for airdropped tokens.
     */
    function _mixHashOfTicket(uint256 ticketId)
        internal
        view
        virtual
        returns (uint256)
    {
        return _mixHashes[_mintBlockNumber(ticketId)];
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";

/**
 * @notice Bundle of PROOF ecosystem token addresses.
 */
struct PROOFTokens {
    IERC721 proof;
    IERC721 moonbirds;
    IERC721 oddities;
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";

import {IDelegationRegistry} from
    "delegatecash/delegation-registry/IDelegationRegistry.sol";

import {ERC721ACommon, ERC721A} from "ethier/erc721/ERC721ACommon.sol";
import {BaseTokenURI} from "ethier/erc721/BaseTokenURI.sol";

import {PROOFTokens} from "poc-ticket/PROOFTokens.sol";
import {
    TokenRedemption, TokenRedemptionLib
} from "poc-ticket/TokenRedemption.sol";

import {PurchaseLimiter} from "poc-ticket/PurchaseLimiter.sol";
import {Upgrader, AccessControlEnumerable} from "poc-ticket/Upgrader.sol";
import {DelegationChecker} from "poc-ticket/DelegationChecker.sol";
import {Minter} from "poc-ticket/Minter.sol";
import {Airdropper} from "poc-ticket/Airdropper.sol";
import {UsageTracker} from "poc-ticket/UsageTracker.sol";
import {TransferRestriction} from
    "poc-ticket/TransferRestriction/ERC721ATransferRestricted.sol";

/**
 * @title Proof of Conference Tickets
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
contract PoCTicket is
    Minter,
    Airdropper,
    UsageTracker,
    PurchaseLimiter,
    Upgrader,
    DelegationChecker,
    BaseTokenURI
{
    using Address for address payable;
    using TokenRedemptionLib for TokenRedemption[];

    // =========================================================================
    //                          Errors
    // =========================================================================

    error DisallowedByCurrentStage();
    error TooManyPurchasesRequestedFromToken(
        IERC721 token, uint256 tokenId, uint256 numMax
    );
    error TokenNotOwnedByOrDelegatedToCaller(IERC721, uint256);
    error InvalidPayment(uint256 want);

    error TokenNotOwnedByVault(IERC721 token, uint256 tokenId);

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice The different stages of the ticket sale.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     * @dev The ordering is very important as each stage's permissions are a
     * strict sub set of the next stage and this is assumed when checking.
     */
    enum Stage {
        Closed,
        ProofCollective,
        Moonbirds,
        Oddities,
        GeneralAdmission
    }

    /**
     * @notice Information about a given ticket.
     * @dev Intended to interact with the dApp frontend.
     */
    struct TokenInfo {
        bool upgraded;
        bool airdropped;
        bool upgradable;
        bool upgradedFreeOfCharge;
        uint256 revealBlockNumber;
    }

    /**
     * @notice Helper struct to initialise the contract.
     * @
     */
    struct ERC721MetadataSetup {
        string name;
        string symbol;
        string baseTokenURI;
    }

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The PROOF Collective token.
     */
    IERC721 private immutable _proof;

    /**
     * @notice The Moonbirds token.
     */
    IERC721 private immutable _moonbirds;

    /**
     * @notice The Oddities token.
     */
    IERC721 private immutable _oddities;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The current stage of the contract.
     * @dev Some methods are only accessible for some stages. See also the
     * `Steering` section for more information.
     */
    Stage public stage;

    /**
     * @notice The receiver of primary sales funds.
     */
    address payable internal _salesReceiver;

    /**
     * @notice The reduced price of a ticket for PROOF-ecosystem NFT holders.
     */
    uint128 public reducedTicketPrice;

    /**
     * @notice The price of a ticket during the general admission sale.
     */
    uint128 public fullTicketPrice;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        address admin,
        address steerer,
        ERC721MetadataSetup memory setup,
        PROOFTokens memory tokens,
        IDelegationRegistry delegationRegistry,
        address payable salesReceiver,
        address bnSigner
    )
        ERC721ACommon(
            admin,
            steerer,
            setup.name,
            setup.symbol,
            payable(address(0xdeadface)),
            0
        )
        BaseTokenURI(setup.baseTokenURI)
        Upgrader(125, bnSigner) // 1.25 %
        DelegationChecker(tokens, delegationRegistry)
    {
        _proof = tokens.proof;
        _moonbirds = tokens.moonbirds;
        _oddities = tokens.oddities;

        fullTicketPrice = 1.5 ether;
        reducedTicketPrice = 0.75 ether;

        _salesReceiver = salesReceiver;

        _grantRole(AIRDROPPER_ROLE, steerer);
        _grantRole(PURCHASE_LIMIT_SETTER_ROLE, steerer);
        _grantRole(UPGRADER_ROLE, steerer);

        _setTransferRestriction(TransferRestriction.OnlyMint);
    }

    // =========================================================================
    //                           Metadata
    // =========================================================================

    /**
     * @notice Returns information about a given ticket.
     * @dev Intended to interact with the dApp frontend.
     */
    function tokenInfos(uint256[] calldata tokenIds)
        external
        view
        returns (TokenInfo[] memory infos)
    {
        infos = new TokenInfo[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 ticketId = tokenIds[i];
            bool airdropped = _airdropped(ticketId);
            infos[i] = TokenInfo({
                upgraded: upgraded(ticketId),
                airdropped: airdropped,
                upgradable: _upgradable(ticketId),
                upgradedFreeOfCharge: _upgradedFreeOfCharge(ticketId),
                revealBlockNumber: airdropped ? 0 : _revealBlockNumber(ticketId)
            });
        }
    }

    // =========================================================================
    //                           Mint
    // =========================================================================

    /**
     * @notice Interface to purchase a Proof of Conference ticket.
     * @param vault The vault address if delegation is used. Otherwise has to be
     * the caller.
     * @param delegationType The finest-grained type of delegation that is
     * applicable to all tokens that will be used for redemption.
     * @param pcRedemptions The redemptions via Proof Collective tokens
     * @param mbRedemptions The redemptions via Moonbird tokens
     * @param oddRedemptions The redemptions via Oddity tokens
     * @param numGA The number of general admission purchases.
     */
    function purchase(
        address vault,
        IDelegationRegistry.DelegationType delegationType,
        TokenRedemption[] calldata pcRedemptions,
        TokenRedemption[] calldata mbRedemptions,
        TokenRedemption[] calldata oddRedemptions,
        uint256 numGA
    ) external payable {
        // Checks

        // Checking this first to revert as early as possible in the case of a
        // race for tickets.
        uint256 num = pcRedemptions.totalNum() + mbRedemptions.totalNum()
            + oddRedemptions.totalNum() + numGA;
        _checkAndTrackPurchaseLimits(vault, num, numGA);

        _checkOwnership(vault, pcRedemptions, mbRedemptions, oddRedemptions);
        if (vault != msg.sender) {
            _checkDelegation(
                msg.sender,
                vault,
                delegationType,
                pcRedemptions,
                mbRedemptions,
                oddRedemptions
            );
        }
        if (numGA > 0 && stage != Stage.GeneralAdmission) {
            revert DisallowedByCurrentStage();
        }
        // Not checking other stages here since they are implicitly checked in
        // `purchaseCost`.

        uint256 cost =
            purchaseCost(pcRedemptions, mbRedemptions, oddRedemptions, numGA);
        if (msg.value != cost) {
            revert InvalidPayment(cost);
        }

        // Effects
        _trackTokenUsage(_proof, pcRedemptions);
        _trackTokenUsage(_moonbirds, mbRedemptions);
        _trackTokenUsage(_oddities, oddRedemptions);

        // Interactions
        _salesReceiver.sendValue(msg.value);
        _mintPurchase(msg.sender, num);
    }

    /**
     * @notice The cost for a ticket purchase.
     * @param pcRedemptions The redemptions via Proof Collective tokens
     * @param mbRedemptions The redemptions via Moonbird tokens
     * @param oddRedemptions The redemptions via Oddity tokens
     * @param numGA The number of general admission purchases.
     */
    function purchaseCost(
        TokenRedemption[] calldata pcRedemptions,
        TokenRedemption[] calldata mbRedemptions,
        TokenRedemption[] calldata oddRedemptions,
        uint256 numGA
    ) public view returns (uint256) {
        (
            uint256[] memory pcCosts,
            uint256[] memory mbCosts,
            uint256[] memory oddCosts
        ) = _costsPerTokenRedemption();

        uint256 totalCost = 0;
        totalCost += _redemptionCost(_proof, pcCosts, pcRedemptions);
        totalCost += _redemptionCost(_moonbirds, mbCosts, mbRedemptions);
        totalCost += _redemptionCost(_oddities, oddCosts, oddRedemptions);
        totalCost += numGA * fullTicketPrice;

        return totalCost;
    }

    /**
     * @notice Returns the costs for the n-th ticket purchase using a PROOF
     * ecosystem token.
     * @dev The length of the individual arrays tell how often a token can be
     * used.
     */
    function _costsPerTokenRedemption()
        internal
        view
        returns (
            uint256[] memory pcCosts,
            uint256[] memory mbCosts,
            uint256[] memory oddCosts
        )
    {
        uint256 rPrice = reducedTicketPrice;
        if (stage == Stage.ProofCollective) {
            pcCosts = new uint[](1);
            // pcCosts[0] deliberately left as 0
        }
        if (stage >= Stage.Moonbirds) {
            pcCosts = new uint[](2);
            // pcCosts[0] deliberately left as 0
            pcCosts[1] = rPrice;

            pcCosts = new uint[](2);
            pcCosts[1] = reducedTicketPrice;

            mbCosts = new uint[](2);
            mbCosts[0] = rPrice;
            mbCosts[1] = rPrice;
        }
        if (stage >= Stage.Oddities) {
            oddCosts = new uint[](1);
            oddCosts[0] = rPrice;
        }
    }

    /**
     * @notice Frontend interface to get the number of tickets that can be
     * purchased per token.
     */
    function numTicketsPerToken()
        external
        view
        returns (uint256, uint256, uint256)
    {
        (
            uint256[] memory pcCosts,
            uint256[] memory mbCosts,
            uint256[] memory oddCosts
        ) = _costsPerTokenRedemption();
        return (pcCosts.length, mbCosts.length, oddCosts.length);
    }

    /**
     * @notice Computes the cost for ticket purchases via token redemptions.
     * @param token The token contract.
     * @param costs A list of costs indexed by token usage, e.g. if purchasing
     * via a token costs 10 for the first time and 20 for second time, the list
     * would be `[10,20]`.
     * @param redemptions the list of redeeming tokens and number of
     * redemptions.
     */
    function _redemptionCost(
        IERC721 token,
        uint256[] memory costs,
        TokenRedemption[] calldata redemptions
    ) internal view returns (uint256) {
        if (redemptions.length == 0) {
            return 0;
        }

        // Validating that the tokenIDs are strictly monotonically increasing
        // guarantees that no token is supplied twice, which allows us to write
        // the rest of the view function more efficiently because we don't have
        // to track usage.
        redemptions.checkStrictlyMonotonicallyIncreasing();

        uint256 totalCost;
        for (uint256 i; i < redemptions.length; ++i) {
            uint256 costStart = numTokenUsed(token, redemptions[i].tokenId);
            uint256 costEnd = costStart + redemptions[i].num;

            if (costEnd > costs.length) {
                revert TooManyPurchasesRequestedFromToken(
                    token, redemptions[i].tokenId, costs.length
                );
            }

            for (uint256 usage = costStart; usage < costEnd; ++usage) {
                totalCost += costs[usage];
            }
        }

        return totalCost;
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the stage of the contract.
     * @dev Only callable by an admin.
     */
    function setStage(Stage stage_) external onlyRole(DEFAULT_STEERING_ROLE) {
        stage = stage_;
    }

    /**
     * @notice Sets the ticket purchase prices.
     */
    function setPurchasePrices(
        uint128 reducedTicketPrice_,
        uint128 fullTicketPrice_
    ) external onlyRole(DEFAULT_STEERING_ROLE) {
        reducedTicketPrice = reducedTicketPrice_;
        fullTicketPrice = fullTicketPrice_;
    }

    /**
     * @notice Sets the receiver of funds.
     */

    function setSalesReceiver(address payable salesReceiver)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _salesReceiver = salesReceiver;
    }

    /**
     * @notice Airdrops a number of tickets to a given address.
     */
    function airdrop(address to, uint256 num)
        external
        bypassTransferRestriction
    {
        _doAirdrop(to, num);
    }

    // =========================================================================
    //                           Ownership verification
    // =========================================================================

    /**
     * @notice Convenience overload to check that the given address owns the
     * tokens for all redemptions.
     */
    function _checkOwnership(
        address vault,
        TokenRedemption[] calldata pcRedemptions,
        TokenRedemption[] calldata mbRedemptions,
        TokenRedemption[] calldata oddRedemptions
    ) internal view {
        _checkOwnership(vault, _proof, pcRedemptions);
        _checkOwnership(vault, _moonbirds, mbRedemptions);
        _checkOwnership(vault, _oddities, oddRedemptions);
    }

    /**
     * @notice Checks that a given address own the redeeming tokens of a certain
     * kind.
     */
    function _checkOwnership(
        address vault,
        IERC721 token,
        TokenRedemption[] calldata redemptions
    ) internal view {
        for (uint256 i; i < redemptions.length; ++i) {
            if (token.ownerOf(redemptions[i].tokenId) != vault) {
                revert TokenNotOwnedByVault(token, redemptions[i].tokenId);
            }
        }
    }

    // =========================================================================
    //                           Upgrader Upgrades
    // =========================================================================

    /**
     * @notice Returns the receiver of the upgade sales.
     * @dev Callback required by the `Upgrader`.
     */
    function _upgradeSalesReceiver()
        internal
        view
        virtual
        override(Upgrader)
        returns (address payable)
    {
        return _salesReceiver;
    }

    /**
     * @notice Returns the maximum number of upgradable tokens.
     */
    function _maxUpgradesSellable()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (stage == Stage.ProofCollective) {
            return 400;
        }
        if (stage == Stage.Moonbirds) {
            return 700;
        }
        if (stage == Stage.Oddities || stage == Stage.GeneralAdmission) {
            return 800;
        }

        return 0;
    }

    /**
     * @notice Returns the number of the block that is used to derive the
     * salt for the randomised upgrade of a given ticket.
     */
    function _revealBlockNumber(uint256 ticketId)
        internal
        view
        override
        returns (uint256)
    {
        return _mintBlockNumber(ticketId) + 1;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @dev Inheritance resolution.
     */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721ACommon, AccessControlEnumerable, Upgrader)
        returns (bool)
    {
        return ERC721ACommon.supportsInterface(interfaceId);
        // Deliberately ignoring AccessControlEnumerable and Upgrader here to
        // safe contract bytecode since they wont add any information.
    }

    function _airdropped(uint256 ticketId)
        internal
        view
        override(Minter, Upgrader)
        returns (bool)
    {
        return Minter._airdropped(ticketId);
    }

    function _mixHashOfTicket(uint256 ticketId)
        internal
        view
        override(Minter, Upgrader)
        returns (uint256)
    {
        return Minter._mixHashOfTicket(ticketId);
    }

    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override(ERC721A, Upgrader)
        returns (bool)
    {
        return ERC721A._exists(tokenId);
    }

    function _mintAirdrop(address to, uint256 num)
        internal
        virtual
        override(Minter, Airdropper)
    {
        Minter._mintAirdrop(to, num);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";

struct PurchaseCountsAndLimits {
    uint16 total;
    uint16 totalLimit;
    uint16 generalAdmission;
    uint16 generalAdmissionLimit;
}

/**
 * @title Proof of Conference Tickets - Purchase limit by wallet module
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
contract PurchaseLimiter is AccessControlEnumerable {
    // =========================================================================
    //                           Errors
    // =========================================================================

    error ExceedingAvailableTokens();
    error ExceedingPurchaseLimit();
    error ExceedingGeneralAdmissionPurchaseLimit();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The role allowed to change the purchase limits for a given
     * wallet.
     */
    bytes32 public constant PURCHASE_LIMIT_SETTER_ROLE =
        keccak256("PURCHASE_LIMIT_SETTER_ROLE");

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The number of tickets sold.
     */
    uint16 private _numTicketsSold;

    /**
     * @notice The the number of sellable tickets.
     */
    uint16 private _numTicketsSellable = 4000;

    /**
     * @notice The default total purchase limit for each wallet.
     */
    uint16 private _defaultTotalPurchaseLimit = 10;

    /**
     * @notice The default purchase limit through the general admission sale.
     */
    uint16 private _defaultGeneralAdmissionPurchaseLimit = 2;

    /**
     * @notice Purchase counts and explicit purchase limits by wallet.
     */
    mapping(address => PurchaseCountsAndLimits) private _countsAndLimits;

    // =========================================================================
    //                           Getters
    // =========================================================================

    /**
     * @notice Returns the current number of purchases and limits for a given
     * wallet.
     */
    function purchaseCountsAndLimits(address wallet)
        public
        view
        returns (PurchaseCountsAndLimits memory)
    {
        PurchaseCountsAndLimits memory cl = _countsAndLimits[wallet];
        if (cl.totalLimit == 0) {
            cl.totalLimit = _defaultTotalPurchaseLimit;
        }
        if (cl.generalAdmissionLimit == 0) {
            cl.generalAdmissionLimit = _defaultGeneralAdmissionPurchaseLimit;
        }
        return cl;
    }

    /**
     * @notice The number of tickets that have already been sold.
     */
    function numTicketsSold() external view returns (uint256) {
        return _numTicketsSold;
    }

    /**
     * @notice The total number of tickets that can been sold.
     */
    function numTicketsSellable() external view returns (uint256) {
        return _numTicketsSellable;
    }

    /**
     * @notice Returns the total purchase limit used as default if explicit no
     * limit was set for a given wallet.
     */
    function _defaultTotalLimit() internal view returns (uint16) {
        return _defaultTotalPurchaseLimit;
    }

    /**
     * @notice Returns the general admission purchase limit used as default if
     * no explicit limit was set for a given wallet.
     */
    function _defaultGeneralAdmissionLimit() internal view returns (uint16) {
        return _defaultGeneralAdmissionPurchaseLimit;
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the number of sellable tickets.
     */
    function setNumTicketsSellable(uint16 numSellable)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _numTicketsSellable = numSellable;
    }

    /**
     * @notice Sets the default purchase limits.
     */
    function setDefaultPurchaseLimits(
        uint16 totalLimit,
        uint16 generalAdmissionLimit
    ) external onlyRole(DEFAULT_STEERING_ROLE) {
        _defaultTotalPurchaseLimit = totalLimit;
        _defaultGeneralAdmissionPurchaseLimit = generalAdmissionLimit;
    }

    /**
     * @notice Sets explicit purchase limits for a given wallet.
     */
    function setPurchaseLimits(
        address wallet,
        uint16 totalLimit,
        uint16 generalAdmissionLimit
    ) external onlyRole(PURCHASE_LIMIT_SETTER_ROLE) {
        PurchaseCountsAndLimits storage cl = _countsAndLimits[wallet];
        cl.totalLimit = totalLimit;
        cl.generalAdmissionLimit = generalAdmissionLimit;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Checks if a given buyer is allowed to purchase a given number of
     * tokens and tracks them.
     */
    function _checkAndTrackPurchaseLimits(
        address buyer,
        uint256 numTotal,
        uint256 numGA
    ) internal virtual {
        if (_numTicketsSold + numTotal > _numTicketsSellable) {
            revert ExceedingAvailableTokens();
        }

        PurchaseCountsAndLimits memory countsAndLimits =
            purchaseCountsAndLimits(buyer);
        if (countsAndLimits.total + numTotal > countsAndLimits.totalLimit) {
            revert ExceedingPurchaseLimit();
        }
        if (
            countsAndLimits.generalAdmission + numGA
                > countsAndLimits.generalAdmissionLimit
        ) {
            revert ExceedingGeneralAdmissionPurchaseLimit();
        }

        _numTicketsSold += uint16(numTotal);
        _countsAndLimits[buyer].total += uint16(numTotal);
        _countsAndLimits[buyer].generalAdmission += uint16(numGA);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

/**
 * @notice Encoding a redemption via a token.
 */
struct TokenRedemption {
    // The tokenId used for purchasing a ticket
    uint256 tokenId;
    // The number of tickets requested.
    uint256 num;
}

/**
 * @notice Utility library to work with `TokenRedemption`s.
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
library TokenRedemptionLib {
    error InvalidTokenOrder();

    /**
     * @notice Computes the total number of redemptions from a list of
     * `TokenRedemptions`.
     */
    function totalNum(TokenRedemption[] calldata redemptions)
        internal
        pure
        returns (uint256)
    {
        uint256 num;
        for (uint256 j; j < redemptions.length; ++j) {
            num += redemptions[j].num;
        }
        return num;
    }

    /**
     * @notice Checks if the tokenIds in a list of `TokenRedemptions` is
     * strictly monotonically increasing.
     * @dev Reverts otherwise
     */

    function checkStrictlyMonotonicallyIncreasing(
        TokenRedemption[] calldata redemptions
    ) internal pure {
        if (redemptions.length < 2) {
            return;
        }

        for (uint256 i = 0; i < redemptions.length - 1; ++i) {
            if (redemptions[i].tokenId >= redemptions[i + 1].tokenId) {
                revert InvalidTokenOrder();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16 <0.9.0;

import {
    ERC721ATransferRestrictedBase,
    TransferRestriction
} from "./ERC721ATransferRestrictedBase.sol";

/**
 * @notice Extension of ERC721 transfer restrictions with manual restriction
 * setter.
 */
abstract contract ERC721ATransferRestricted is ERC721ATransferRestrictedBase {
    // =========================================================================
    //                           Error
    // =========================================================================

    error TransferRestrictionLocked();
    error TransferRestrictionCheckFailed(TransferRestriction want);

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The current restrictions.
     */
    TransferRestriction private _transferRestriction;

    /**
     * @notice Flag to lock in the current transfer restriction.
     */
    bool private _locked;

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the transfer restrictions.
     */
    function _setTransferRestriction(TransferRestriction restriction)
        internal
        virtual
    {
        _transferRestriction = restriction;
    }

    /**
     * @notice Sets the transfer restrictions.
     * @dev Only callable by a contract steerer.
     */
    function setTransferRestriction(TransferRestriction restriction)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        if (_locked) {
            revert TransferRestrictionLocked();
        }

        _setTransferRestriction(restriction);
    }

    /**
     * @notice Locks the current transfer restrictions.
     * @dev Only callable by a contract steerer.
     * @param restriction must match the current transfer restriction as
     * additional security measure.
     */
    function lockTransferRestriction(TransferRestriction restriction)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        if (restriction != _transferRestriction) {
            revert TransferRestrictionCheckFailed(_transferRestriction);
        }

        _locked = true;
    }

    /**
     * @notice Returns the stored transfer restrictions.
     */
    function transferRestriction()
        public
        view
        virtual
        override
        returns (TransferRestriction)
    {
        return _transferRestriction;
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {ERC721ACommon} from "ethier/contracts/erc721/ERC721ACommon.sol";

/**
 * @notice Possible transfer restrictions.
 */
enum TransferRestriction {
    None,
    OnlyMint,
    OnlyBurn,
    Frozen
}

/**
 * @notice Implements restrictions for ERC721 transfers.
 * @dev This is intended to facilitate a soft expiry for voucher tokens, having
 * an intermediate stage that still allows voucher to be redeemed but not traded
 * before closing all activity indefinitely.
 * @dev The activation of restrictions is left to the extending contract.
 */
abstract contract ERC721ATransferRestrictedBase is ERC721ACommon {
    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if an action is disallowed by the current transfer
     * restriction.
     */
    error DisallowedByTransferRestriction();

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Flag to bypass the current transfer restriction.
     */
    bool private _bypass;

    // =========================================================================
    //                           Transfer Restriction
    // =========================================================================

    /**
     * @notice Returns the current transfer restriction.
     * @dev Hook to be implemented by the consuming contract (e.g. manual
     * setter, time based, etc.)
     */
    function transferRestriction()
        public
        view
        virtual
        returns (TransferRestriction);

    /**
     * @notice Modifier that allows functions to bypass the transfer
     * restriction.
     */
    modifier bypassTransferRestriction() {
        _bypass = true;
        _;
        _bypass = false;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Blocks transfers depending on the current restrictions.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        if (_bypass) {
            return;
        }

        TransferRestriction restriction = transferRestriction();
        if (restriction == TransferRestriction.None) {
            return;
        }
        if (restriction == TransferRestriction.OnlyMint && from == address(0)) {
            return;
        }
        if (restriction == TransferRestriction.OnlyBurn && to == address(0)) {
            return;
        }

        revert DisallowedByTransferRestriction();
    }

    // =========================================================================
    //                           Approvals
    // =========================================================================

    /**
     * @dev This returns false if all transfers are disabled to indicate to
     * marketplaces that these tokens cannot be sold and should therefore not be
     * listed.
     */
    function isApprovedForAll(address owner_, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (!_bypass && transferRestriction() != TransferRestriction.None) {
            return false;
        }

        return super.isApprovedForAll(owner_, operator);
    }

    /**
     * @notice Reverts if all transfers are disabled to prevent users from
     * approving marketplaces even though the tokens can't be traded.
     */
    function setApprovalForAll(address operator, bool toggle)
        public
        virtual
        override
    {
        if (!_bypass && transferRestriction() != TransferRestriction.None) {
            revert DisallowedByTransferRestriction();
        }

        return super.setApprovalForAll(operator, toggle);
    }

    /**
     * @notice Reverts if all transfers are disabled to prevent users from
     * approving marketplaces even though the tokens can't be traded.
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        virtual
        override
    {
        if (!_bypass && transferRestriction() != TransferRestriction.None) {
            revert DisallowedByTransferRestriction();
        }

        return super.approve(operator, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";
import {ERC4906} from "ethier/erc721/ERC4906.sol";

/**
 * @notice PROOF-issued signatures of block numbers.
 */
struct SignedBlockNumber {
    uint256 blockNumber;
    bytes signature;
}

interface UpgraderEvents {
    event TicketUpgraded(address indexed by, uint256 indexed ticketId);
}

/**
 * @title Proof of Conference Tickets - VIP Upgrades module.
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
abstract contract Upgrader is
    UpgraderEvents,
    AccessControlEnumerable,
    ERC4906
{
    using Address for address payable;
    using ECDSA for bytes;
    using ECDSA for bytes32;

    // =========================================================================
    //                           Errors
    // =========================================================================

    error ExceedingAvailableUpgrades();
    error InvalidPaymentForUpgrade(uint256 want);
    error TicketNotEligibleForUpgrade(uint256);
    error TicketAlreadyUpgraded(uint256);
    error TicketDoesNotExist(uint256);
    error IncorrectSigner();
    error CurrentlyDisabled();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The role allowed to perform manual upgrades.
     */
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /**
     * @notice Unity in fixed-point arithmetic with a 64bit decimal point.
     */
    uint256 private constant _ONE = 1 << 64;

    /**
     * @notice The probability for a free upgrade to VIP.
     * @dev Given as a 256x64bit fixed-point number.
     */
    uint256 private immutable _freeUpgradeProbability;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Flag to enable the upgrades purchase.
     */
    bool private _upgradesPurchaseOpen;

    /**
     * @notice Flag to enable the publishing of block salts to lock in random
     * upgrades.
     */
    bool private _blockSaltPublishingOpen;

    /**
     * @notice The number of upgrades sold.
     */
    uint16 private _numUpgradesSold;

    /**
     * @notice The price to purchase a VIP upgrade.
     */
    uint128 private _upgradePrice;

    /**
     * @notice The address of the PROOF-owned backend to provide salt for the
     * free upgrades randomisation.
     */
    address private _bnSigner;

    /**
     * @notice Stores purchased upgrades.
     */
    mapping(uint256 => bool) private _upgraded;

    /**
     * @notice Stores PROOF-issued salt for the free upgrades randomisation.
     */
    mapping(uint256 => bytes32) private _salts;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    /**
     * @param freeUpgradeProbabilityBasePoints_ the probability to randomly get
     * a free VIP upgrade in basis points (i.e. 1/10k).
     */
    constructor(uint256 freeUpgradeProbabilityBasePoints_, address bnSigner_) {
        _upgradesPurchaseOpen = true;
        _blockSaltPublishingOpen = true;

        _upgradePrice = 0.5 ether;

        _freeUpgradeProbability =
            (freeUpgradeProbabilityBasePoints_ * _ONE) / 10_000;
        _bnSigner = bnSigner_;
    }

    // =========================================================================
    //                           Metadata
    // =========================================================================

    /**
     * @notice Returns if a ticket is upgraded to VIP.
     * @dev Includes both bought and randomly won upgrades.
     */
    function upgraded(uint256 ticketId) public view returns (bool) {
        return _upgraded[ticketId] || _hasFreeUpgrade(ticketId);
    }

    /**
     * @notice Returns if a ticket is upgradable to VIP.
     * @dev Excludes already upgraded, airdropped and inexistant tickets.
     */
    function _upgradable(uint256 ticketId) internal view returns (bool) {
        return !upgraded(ticketId) && !_airdropped(ticketId);
    }

    // =========================================================================
    //                           Purchase Upgrades
    // =========================================================================

    /**
     * @notice Purchases VIP upgrades for a list of tickets.
     * @dev Ticket ownership is not verified. Reverts if a ticket was already
     * upgraded.
     */
    function purchaseUpgrade(uint256[] calldata ticketIds)
        external
        payable
        onlyIf(_upgradesPurchaseOpen)
    {
        uint256 numUpgrades = ticketIds.length;
        // Checking this first to revert as early as possible in the case of a
        // race for tickets.
        if (_numUpgradesSold + numUpgrades > _maxUpgradesSellable()) {
            revert ExceedingAvailableUpgrades();
        }

        uint256 wantValue = numUpgrades * _upgradePrice;
        if (msg.value != wantValue) {
            revert InvalidPaymentForUpgrade(wantValue);
        }

        for (uint256 i; i < numUpgrades; ++i) {
            _doPurchaseUpgrade(ticketIds[i]);
        }
        _numUpgradesSold += uint16(numUpgrades);

        _upgradeSalesReceiver().sendValue(msg.value);
    }

    /**
     * @notice Performs the purchase of an upgrade for a given ticket.
     * @dev Reverts if the given ticket is not eligible for an upgrade according
     * to `_upgradable`.
     */
    function _doPurchaseUpgrade(uint256 ticketId) private {
        // We deliberately don't use `_upgradable` here to provide more context
        // by reverting with different errors depening on the violation.
        if (_airdropped(ticketId)) {
            revert TicketNotEligibleForUpgrade(ticketId);
        }
        _doUpgrade(ticketId);
    }

    /**
     * @notice Returns the price to purchase an upgrade.
     */
    function upgradePrice() external view returns (uint128) {
        return _upgradePrice;
    }

    /**
     * @notice Returns the number of sold VIP upgrades.
     */
    function numUpgradesSold() external view returns (uint256) {
        return _numUpgradesSold;
    }

    /**
     * @notice Returns the maximum number of upgrades that will be sold.
     */
    function maxUpgradesSellable() external view returns (uint256) {
        return _maxUpgradesSellable();
    }

    /**
     * @notice Returns flag to indicate if the upgrades purchase is enabled.
     */
    function upgradesPurchaseOpen() external view returns (bool) {
        return _upgradesPurchaseOpen;
    }

    // =========================================================================
    //                           Owner Upgrades
    // =========================================================================

    /**
     * @notice Manually upgrades a list of tickets to VIP.
     * @dev This bypasses the number of upgradable tickets.
     */
    function upgrade(uint256[] calldata ticketIds)
        external
        onlyRole(UPGRADER_ROLE)
    {
        for (uint256 i; i < ticketIds.length; ++i) {
            _doUpgrade(ticketIds[i]);
        }
    }

    /**
     * @notice Upgrades a ticket to VIP.
     * @dev Reverts if the ticket was already upgraded or does not exist.
     */
    function _doUpgrade(uint256 ticketId) private {
        if (upgraded(ticketId)) {
            revert TicketAlreadyUpgraded(ticketId);
        }
        if (!_exists(ticketId)) {
            revert TicketDoesNotExist(ticketId);
        }

        _upgraded[ticketId] = true;
        emit TicketUpgraded(msg.sender, ticketId);
        emit MetadataUpdate(ticketId);
    }

    // =========================================================================
    //                           Publishing block salts
    // =========================================================================

    /**
     * @notice Stores PROOF-issued block number signatures and locks in randomly
     * assigned free upgrades in the process.
     */
    function publishBlockSalts(SignedBlockNumber[] calldata bns)
        external
        onlyIf(_blockSaltPublishingOpen)
    {
        for (uint256 i; i < bns.length; ++i) {
            _publishBlockSalt(bns[i].blockNumber, bns[i].signature);
        }

        // Publishing block salts locks in randomised upgrades for certain
        // tickets. Since we do not keep book over the tokens that will be
        // affected we would need to trigger a collection-wide metadata refresh
        // to inform marketplaces. This can be abused because one can call this
        // method by only paying gas, which might result in rate limiting. So we
        // refrain from emitting a corresponding ERC4906 event here and emit
        // it manually on a daily basis.
    }

    /**
     * @notice Stores a PROOF-issued block number signature and locks in
     * randomly assigned free upgrades in the process.
     * @dev Reverts if the message or signer is incorrect.
     */
    function _publishBlockSalt(uint256 blockNumber, bytes calldata signature)
        private
    {
        // Already published. Reverting early in the case of multiple user
        // submissions.
        if (_salts[blockNumber] != 0) {
            return;
        }

        if (
            abi.encode(blockNumber, block.chainid).toEthSignedMessageHash()
                .recover(signature) != _bnSigner
        ) {
            revert IncorrectSigner();
        }

        _salts[blockNumber] = keccak256(signature);
    }

    /**
     * @notice Returns the salt for a given block number.
     * @dev Returns zero if nothing has been stored yet.
     */
    function _salt(uint256 blockNumber)
        internal
        view
        virtual
        returns (bytes32)
    {
        return _salts[blockNumber];
    }

    /**
     * @notice Returns flag to indicate if the interface to publish block salts
     * is enabled.
     */
    function blockSaltPublishingOpen() external view returns (bool) {
        return _blockSaltPublishingOpen;
    }

    // =========================================================================
    //                           Random Free Upgrades
    // =========================================================================

    /**
     * @notice Checks if a ticket is upgradable free of charge using a given
     * signature.
     * @dev This method is external because we will exclusively use it to inform
     * the frontend that a given signature unlocks the free upgrade for a token.
     * The eligibility does not need to be verified on the contract because the
     * upgrades are derived on-the-fly from the stored salts, effectively
     * reproducing what is checked here.
     * Once the salt for a revealBlockNumber of a given ticket was stored, this
     * function will return false since the ticket was already upgraded.
     * @param signature The signature of the revealing block number associated
     * to the ticket issued by PROOF.
     */
    function upgradableFreeOfCharge(uint256 ticketId, bytes calldata signature)
        external
        view
        returns (bool)
    {
        if (
            abi.encode(_revealBlockNumber(ticketId), block.chainid)
                .toEthSignedMessageHash().recover(signature) != _bnSigner
        ) {
            revert IncorrectSigner();
        }

        return !_upgraded[ticketId]
            && _isRandomlyUpgradedBy(ticketId, keccak256(signature))
            && _salts[_revealBlockNumber(ticketId)] == 0;
    }

    /**
     * @notice Checks if a given ticket was upgraded via the random lottery.
     */
    function _upgradedFreeOfCharge(uint256 ticketId)
        internal
        view
        returns (bool)
    {
        return !_upgraded[ticketId] && !_airdropped(ticketId)
            && _hasFreeUpgrade(ticketId);
    }

    /**
     * @notice Checks if a ticket is randomly upgraded using a provided salt.
     */
    function _isRandomlyUpgradedBy(uint256 ticketId, bytes32 salt)
        private
        view
        returns (bool)
    {
        bytes32 rand = keccak256(
            abi.encodePacked(salt, _mixHashOfTicket(ticketId), ticketId)
        );
        return uint256(rand) % _ONE < _freeUpgradeProbability;
    }

    /**
     * @notice Checks if a ticket is randomly upgraded using the stored salt.
     */
    function _hasFreeUpgrade(uint256 ticketId) internal view returns (bool) {
        if (_airdropped(ticketId)) {
            return false;
        }

        bytes32 salt = _salts[_revealBlockNumber(ticketId)];
        if (salt == 0) {
            return false;
        }

        return _isRandomlyUpgradedBy(ticketId, salt);
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the PROOF-owned blocknumber signer.
     */
    function setBNSigner(address signer)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _bnSigner = signer;
    }

    /**
     * @notice Sets the price to purchase a VIP upgrade.
     */
    function setUpgradePrice(uint128 price)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _upgradePrice = price;
    }

    /**
     * @notice Enables or disables the upgrades purchase and salt publishing
     * functions.
     */
    function setUpgradesOpen(
        bool upgradesPurchaseOpen_,
        bool blockSaltPublishingOpen_
    ) external onlyRole(DEFAULT_STEERING_ROLE) {
        _upgradesPurchaseOpen = upgradesPurchaseOpen_;
        _blockSaltPublishingOpen = blockSaltPublishingOpen_;
    }

    // =========================================================================
    //                           Internal
    // =========================================================================

    /**
     * @notice Makes a function only executable if a given flag is true.
     */
    modifier onlyIf(bool activationFlag) {
        if (!activationFlag) {
            revert CurrentlyDisabled();
        }
        _;
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC4906)
        returns (bool)
    {
        return AccessControlEnumerable.supportsInterface(interfaceId)
            || ERC4906.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                           Interfacing
    // =========================================================================

    /**
     * @notice Returns the mixHash for a given block number.
     * @dev Will be provided by `Minter`.
     */
    function _mixHashOfTicket(uint256 ticketId)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @notice Returns if the given ticket was airdropped.
     * @dev Will be provided by `Minter`.
     */
    function _airdropped(uint256 ticketId)
        internal
        view
        virtual
        returns (bool);

    /**
     * @notice Returns the block number that is used to derive the salt.
     * @dev Will be provided by `PoCTicket`.
     */
    function _revealBlockNumber(uint256 ticketId)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @notice Returns the reveicer of the upgrades proceeds.
     * @dev Will be provided by `PoCTicket`.
     */
    function _upgradeSalesReceiver()
        internal
        view
        virtual
        returns (address payable);

    /**
     * @notice Returns the maximum number of sellable upgrades.
     * @dev Depends on stage. Will be provided by `PoCTicket`.
     */
    function _maxUpgradesSellable() internal view virtual returns (uint256);

    /**
     * @notice Returns if the given ticket exists.
     */
    function _exists(uint256 ticketId) internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {TokenRedemption} from "poc-ticket/TokenRedemption.sol";

/**
 * @title Proof of Conference Tickets - PROOF token usage tracker (for ticket
 * purchases)
 * @author Dave (@cxkoda)
 * @author KRO's kid
 * @custom:reviewer Arran (@divergencearran)
 */
contract UsageTracker {
    mapping(IERC721 => mapping(uint256 => uint256)) private _numTokenUsed;

    function _trackTokenUsage(
        IERC721 token,
        TokenRedemption[] calldata redemptions
    ) internal {
        for (uint256 i; i < redemptions.length; ++i) {
            _numTokenUsed[token][redemptions[i].tokenId] += redemptions[i].num;
        }
    }

    /**
     * @notice Checks how often a given token was used to redeem a ticket.
     */
    function numTokenUsed(IERC721 token, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _numTokenUsed[token][tokenId];
    }
}