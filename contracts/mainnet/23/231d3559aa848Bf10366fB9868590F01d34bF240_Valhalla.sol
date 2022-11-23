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
 * @title ERC721V is a slight improvement upon ERC721A for a few select purposes.
 * 
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. It is optimized for lower gas during batch mints through the ERC721A implementation 
 * by Chiru Labs (https://github.com/chiru-labs/ERC721A)
 *
 * ERC2309 was removed because it will not be used. 
 * Token burning was also removed, but left the reserved bit there.
 * 
 * Ownership's extraData field was modified to be writable without ownership initialized. This allows for multiple
 * mints with different extraData values. A token's extraData will be used as a transfer lockup period and will
 * therefore NOT need to be persisted during a token transfer.
 * 
 * Both token operator approval methods will call a beforeApproval hook that can be overwritten.
 * 
 * Assumptions:
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 * 
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721V is IERC721A {
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

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // Burning disabled.
    // uint256 private _burnCounter;

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
            return _currentIndex - _startTokenId();
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
     * Burning disabled.
     * @dev Returns the total number of tokens burned.
     */
    // function _totalBurned() internal view virtual returns (uint256) {
    //     return _burnCounter;
    // }

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
     * @dev Verifies if the address has been set a given ownership value.
     */
    function _ownershipNotInitialized(uint256 ownership) internal pure returns (bool) {
        return ownership & _BITMASK_EXTRA_DATA_COMPLEMENT == 0;
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_ownershipNotInitialized(_packedOwnerships[index])) {
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
                    // Burning disabled so we can remove the burned check.
                    // if (packed & _BITMASK_BURNED == 0) {
                    
                    // Invariant:
                    // There will always be an initialized ownership slot
                    // (i.e. `ownership.addr != address(0))
                    // before an unintialized ownership slot
                    // (i.e. `ownership.addr == address(0))
                    // Hence, `curr` will not underflow.
                    //
                    // We can directly compare the packed value.
                    // If the address is zero, packed will be zero.
                    while (_ownershipNotInitialized(packed)) {
                        packed = _packedOwnerships[--curr];
                    }
                    return packed;
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
        // Burning disabled
        // ownership.burned = packed & _BITMASK_BURNED != 0;
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
    function approve(address to, uint256 tokenId) public payable virtual override {
        _beforeApproval(to);
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
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
        _beforeApproval(operator);
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
            tokenId < _currentIndex; // If within bounds,
            // Burning disabled so we can remove the burned check.
            // _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; 
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
            // - `extraData` to `0` because we use it for token lockup timestamp.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_ownershipNotInitialized(_packedOwnerships[nextTokenId])) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = 
                            (prevOwnershipPacked & _BITMASK_EXTRA_DATA_COMPLEMENT) | 
                            (_packedOwnerships[nextTokenId] & ~_BITMASK_EXTRA_DATA_COMPLEMENT);
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
     * @dev Hook that is called before any approval for a token or wallet
     *      
     * `approvedAddr` - the address a wallet is trying to grant approval to.
     */
    function _beforeApproval(address approvedAddr) internal virtual {}

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
                _nextInitializedFlag(quantity)
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
    //                        BURN OPERATIONS
    // =============================================================

    // /**
    //  * @dev Equivalent to `_burn(tokenId, false)`.
    //  */
    // function _burn(uint256 tokenId) internal virtual {
    //     _burn(tokenId, false);
    // }

    // /**
    //  * @dev Destroys `tokenId`.
    //  * The approval is cleared when the token is burned.
    //  *
    //  * Requirements:
    //  *
    //  * - `tokenId` must exist.
    //  *
    //  * Emits a {Transfer} event.
    //  */
    // function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
    //     uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    //     address from = address(uint160(prevOwnershipPacked));

    //     (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

    //     if (approvalCheck) {
    //         // The nested ifs save around 20+ gas over a compound boolean condition.
    //         if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
    //             if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
    //     }

    //     _beforeTokenTransfers(from, address(0), tokenId, 1);

    //     // Clear approvals from the previous owner.
    //     assembly {
    //         if approvedAddress {
    //             // This is equivalent to `delete _tokenApprovals[tokenId]`.
    //             sstore(approvedAddressSlot, 0)
    //         }
    //     }

    //     // Underflow of the sender's balance is impossible because we check for
    //     // ownership above and the recipient's balance can't realistically overflow.
    //     // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    //     unchecked {
    //         // Updates:
    //         // - `balance -= 1`.
    //         // - `numberBurned += 1`.
    //         //
    //         // We can directly decrement the balance, and increment the number burned.
    //         // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
    //         _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

    //         // Updates:
    //         // - `address` to the last owner.
    //         // - `startTimestamp` to the timestamp of burning.
    //         // - `burned` to `true`.
    //         // - `nextInitialized` to `true`.
    //         _packedOwnerships[tokenId] = _packOwnershipData(
    //             from,
    //             (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED)
    //         );

    //         // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
    //         if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
    //             uint256 nextTokenId = tokenId + 1;
    //             // If the next slot's address is zero and not burned (i.e. packed value is zero).
    //             if (_ownershipNotInitialized(_packedOwnerships[nextTokenId])) {
    //                 // If the next slot is within bounds.
    //                 if (nextTokenId != _currentIndex) {
    //                     // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
    //                     _packedOwnerships[nextTokenId] = prevOwnershipPacked;
    //                 }
    //             }
    //         }
    //     }

    //     emit Transfer(from, address(0), tokenId);
    //     _afterTokenTransfers(from, address(0), tokenId, 1);

    //     // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
    //     unchecked {
    //         _burnCounter++;
    //     }
    // }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev gets the extra data for the ownership data `index`. This can differ from the
     * _packedOwnershipOf(index).extraData because if the address is not initialized it will return
     * the extraData of a different index.
     */
    function _getExtraDataAt(uint256 index) internal virtual returns (uint256) {
      return _packedOwnerships[index] >> _BITPOS_EXTRA_DATA;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC2981.sol";
import "./ERC165.sol";

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
pragma solidity ^0.8.9;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * ERC165 bytes to add to interface array - set in parent contract
     * implementing this standard
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     * bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
     * _registerInterface(_INTERFACE_ID_ERC2981);
     */

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

error CallerNotOwner();
error OwnerNotZero();

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
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        if (owner() != _msgSender()) revert CallerNotOwner();
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
        if (newOwner == address(0)) revert OwnerNotZero();
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./token/ERC721V.sol";
import "./utils/ERC2981.sol";
import "./utils/IERC165.sol";
import "./utils/Ownable.sol";
import "./utils/ECDSA.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    ██╗░░░██╗░█████╗░██╗░░░░░██╗░░██╗░█████╗░██╗░░░░░██╗░░░░░░█████╗░    //
//    ██║░░░██║██╔══██╗██║░░░░░██║░░██║██╔══██╗██║░░░░░██║░░░░░██╔══██╗    //
//    ╚██╗░██╔╝███████║██║░░░░░███████║███████║██║░░░░░██║░░░░░███████║    //
//    ░╚████╔╝░██╔══██║██║░░░░░██╔══██║██╔══██║██║░░░░░██║░░░░░██╔══██║    //
//    ░░╚██╔╝░░██║░░██║███████╗██║░░██║██║░░██║███████╗███████╗██║░░██║    //
//    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝    //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

/**
 * Subset of a Presale with only the methods that the main minting contract will call.
 */
interface Presale {
    function selectedBids(address presaleAddr) external view returns (uint256);
}

/**
 * Subset of the IOperatorFilterRegistry with only the methods that the main minting contract will call.
 * The owner of the collection is able to manage the registry subscription on the contract's behalf
 */
interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external returns (bool);
}

contract Valhalla is ERC721V, Ownable, ERC2981 {
    using ECDSA for bytes32;

    // =============================================================
    //                            Structs
    // =============================================================

    // Compiler will pack this into one 256-bit word
    struct AuctionParams {
        // auctionNumber; also tracks which bidIndexes are currently live
        uint16 index;
        // Following 2 values will be multiplied by 1 GWEI or 0.000000001 ETH
        // Bid values with GWEI lower than this denomination do NOT add to a bid.
        uint56 startPrice;
        uint56 minStackedBidIncrement;
        // new bids must beat the lowest bid by this percentage. This is a whole
        // percentage number, a value of 10 means new bids must beat old ones by 10%
        uint8 minBidIncrementPercentage;
        // Optional parameter for if a bid was submitted within seconds of ending,
        // endTimestamp will extend to block.timestamp+timeBuffer if that value is greater.
        uint16 timeBuffer;
        // When the auction can start getting bidded on
        uint48 startTimestamp;
        // When the auction can no longer get bidded on
        uint48 endTimestamp;
        // How many tokens are up for auction. If 0, there is NO auction live.
        uint8 numTokens;
    }

    struct Bid {
        address bidder;
        uint192 amount;
        uint64 bidTime;
    }

    struct BidIndex {
        uint8 index;
        bool isSet;
    }

    // =============================================================
    //                            Constants
    // =============================================================

    // Set on contract initialization
    address public immutable PRESALE_ADDRESS;

    // Proof of hash will be given after reveal.
    string public MINT_PROVENANCE_HASH = "037226b21636376001dbfd22f52d1dd72845efa9613baf51a6a011ac731b2327";
    // Owner will be minting this amount to the treasury which happens before
    // any presale or regular sale. Once totalSupply() is over this amount,
    // no more can get minted by {mintDev}
    uint256 public constant TREASURY_SUPPLY = 300;
    // Maximum tokens that can be minted from {mintTier} and {mintPublic}
    uint256 public constant MINT_CAP = 9000;

    // Public mint is unlikely to be enabled as it will get botted, but if
    // is needed this will make it a tiny bit harder to bot the entire remaining.
    uint256 public constant MAX_PUBLIC_MINT_TXN_SIZE = 5;

    // Proof of hash will be given after all tokens are auctioned.
    string public AUCTION_PROVENANCE_HASH = "eb8c88969a4b776d757de962a194f5b4ffaaadb991ecfbb24d806c7bc6397d30";
    // Multiplier for minBidPrice and minBidIncrement to verify bids are large enough
    // Is used so that we can save storage space and fit the auctionParams into one uint256
    uint256 public constant AUCTION_PRICE_MULTIPLIER = 1 gwei;
    uint256 public constant AUCTION_SUPPLY = 1000;
    // At most 5 tokens can be bid on at once
    uint256 public constant MAX_NUM_BIDS = 5;

    // Cheaper gaswise to set this as 10000 instead of MINT_CAP + AUCTION_SUPPLY
    uint256 public constant TOTAL_SUPPLY = 10000;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // Address that houses the implemention to check if operators are allowed or not
    address public operatorFilterRegistryAddress;
    // Address this contract verifies with the registryAddress for allowed operators.
    address public filterRegistrant;

    // Address that will link to the tokenDNA which the metadata relies on.
    address public dnaContractAddress;

    /**
     * Lockup timestamps are saved in uint24 to fit into the _extraData for the _packedOwnerships
     * mapping of ERC721A tokens. In order to still represent a large range of times, we will
     * be saving the hour the token gets unlocked.
     *
     * In {_beforeTokenTransfers}, _extraData * 3600 will be compared with the current block.timestamp.
     */
    uint24 public firstUnlockTime;
    uint24 public secondUnlockTime;
    uint24 public thirdUnlockTime;

    // Determines whether a presale address has already gotten its presale tokens
    mapping(address => bool) public presaleMinted;
    // If a presale address wants their tokens to land in a different wallet
    mapping(address => address) public presaleDelegation;

    string public tokenUriBase;

    // Address used for {mintTier} which will be a majority of the transactions
    address public signer;
    // Used to quickly invalidate batches of signatures if needed.
    uint256 public signatureVersion;
    // Mapping that shows if a tier is active or not
    mapping(string => bool) public isTierActive;
    mapping(bytes32 => bool) public signatureUsed;

    // Price of a single public mint, {mintPublic} is NOT enabled while this value is 0.
    uint256 public publicMintPrice;

    // Address that is permitted to start and stop auctions
    address public auctioneer;
    // The current highest bids made in the auction
    Bid[MAX_NUM_BIDS] public activeBids;
    // The mapping between an address and its active bid. The isSet flag differentiates the default
    // uint value 0 from an actual 0 value.
    mapping(uint256 => mapping(address => BidIndex)) public bidIndexes;

    // All parameters needed to run an auction
    AuctionParams public auctionParams;
    // ETH reserved due to a live auction, cannot be withdrawn by the owner until the
    // owner calls {endAuction} which also mints out the tokens.
    uint256 public reserveAuctionETH;

    // =============================================================
    //                            Events
    // =============================================================

    event TokenLocked(uint256 indexed tokenId, uint256 unlockTimeHr);
    event TokenUnlocked(uint256 indexed tokenId);

    event AuctionStarted(uint256 indexed index);
    event NewBid(
        uint256 indexed auctionIndex,
        address indexed bidder,
        uint256 value
    );
    event BidIncreased(
        uint256 indexed auctionIndex,
        address indexed bidder,
        uint256 oldValue,
        uint256 increment
    );
    event AuctionExtended(uint256 indexed index);

    // =============================================================
    //                          Constructor
    // =============================================================

    constructor(address initialPresale) ERC721V("Valhalla", "VAL") {
        PRESALE_ADDRESS = initialPresale;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721V, ERC2981) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            ERC721V.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // =============================================================
    //                           IERC2981
    // =============================================================

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =============================================================
    //                        Token Metadata
    // =============================================================

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(tokenUriBase, _toString(tokenId)));
    }

    /**
     * @notice Allows the owner to set the base token URI.
     */
    function setTokenURI(string memory newUriBase) external onlyOwner {
        tokenUriBase = newUriBase;
    }

    /**
     * @notice Allows the owner to set the dna contract address.
     */
    function setDnaContract(address dnaAddress) external onlyOwner {
        dnaContractAddress = dnaAddress;
    }

    // =============================================================
    //                 Operator Filter Registry
    // =============================================================
    /**
     * @dev Stops operators from being added as an approved address to transfer.
     * @param operator the address a wallet is trying to grant approval to.
     */
    function _beforeApproval(address operator) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, operator)
            ) {
                revert OperatorNotAllowed();
            }
        }
        super._beforeApproval(operator);
    }

    /**
     * @dev Stops operators that are not approved from doing transfers.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, msg.sender)
            ) {
                revert OperatorNotAllowed();
            }
        }
        // expiration time represented in hours. multiply by 60 * 60, or 3600.
        if (_getExtraDataAt(tokenId) * 3600 > block.timestamp)
            revert TokenTransferLocked();
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /**
     * @notice Allows the owner to set a new registrant contract.
     */
    function setOperatorFilterRegistryAddress(
        address registryAddress
    ) external onlyOwner {
        operatorFilterRegistryAddress = registryAddress;
    }

    /**
     * @notice Allows the owner to set a new registrant address.
     */
    function setFilterRegistrant(address newRegistrant) external onlyOwner {
        filterRegistrant = newRegistrant;
    }

    // =============================================================
    //                          Presale
    // =============================================================

    /**
     * @notice Allows the owner to mint from treasury supply.
     */
    function mintDev(
        address[] memory mintAddresses,
        uint256[] memory mintQuantities
    ) external onlyOwner {
        for (uint256 i = 0; i < mintAddresses.length; ++i) {
            _mint(mintAddresses[i], mintQuantities[i]);
            if (totalSupply() > TREASURY_SUPPLY) revert OverDevSupplyLimit();
        }
    }

    /**
     * @notice Allows the owner to set the presale unlock times.
     */
    function setUnlockTimes(
        uint24 first,
        uint24 second,
        uint24 third
    ) external onlyOwner {
        firstUnlockTime = first;
        secondUnlockTime = second;
        thirdUnlockTime = third;
    }

    /**
     * @notice Allows selected presale addresses to assign wallet address to receive presale mints.
     * @dev This does not do anything for addresses that were not selected on the presale contract.
     */
    function setPresaleMintAddress(address addr) external {
        presaleDelegation[msg.sender] = addr;
    }

    /**
     * @notice Allows owner to mint presale tokens. The ordering is randomzied on-chain so
     * that the owner does not have control over which users get which tokens when uploading
     * an array of presaleUsers
     * @dev Presale contract already guarantees a cap on the # of presale tokens, so
     * we will not check supply against the MINT_CAP in order to save gas.
     */
    function mintPresale(address[] memory presaleUsers) external onlyOwner {
        uint256 nextId = _nextTokenId();

        uint256 supplyLeft = presaleUsers.length;
        while (supplyLeft > 0) {
            // generate a random index less than the supply left
            uint256 randomIndex = uint256(
                keccak256(abi.encodePacked(block.timestamp, supplyLeft))
            ) % supplyLeft;
            address presaleUser = presaleUsers[randomIndex];

            if (presaleMinted[presaleUser])
                revert PresaleAddressAlreadyMinted();
            presaleMinted[presaleUser] = true;

            uint256 tokensOwed = Presale(PRESALE_ADDRESS).selectedBids(
                presaleUser
            );
            _mintPresaleAddress(presaleUser, nextId, tokensOwed);

            unchecked {
                --supplyLeft;
                // Replace the chosen address with the last address not chosen
                presaleUsers[randomIndex] = presaleUsers[supplyLeft];
                nextId += tokensOwed;
            }
        }
    }

    /**
     * @dev mints a certain amount of tokens to the presale address or its delegation
     * if it has delegated another wallet. These tokens will be locked up and released
     * 1/3rd of the amounts at a time.
     */
    function _mintPresaleAddress(
        address presale,
        uint256 nextId,
        uint256 amount
    ) internal {
        if (presaleDelegation[presale] != address(0)) {
            _mint(presaleDelegation[presale], amount);
        } else {
            _mint(presale, amount);
        }

        unchecked {
            // Cheaper gas wise to do every 3 tokens and deal with the remainder afterwards
            // than to do if statements within the loop.
            for (uint256 j = 0; j < amount / 3; ) {
                uint256 start = nextId + j * 3;

                _setExtraDataAt(start, thirdUnlockTime);
                _setExtraDataAt(start + 1, secondUnlockTime);
                _setExtraDataAt(start + 2, firstUnlockTime);
                emit TokenLocked(start, thirdUnlockTime);
                emit TokenLocked(start + 1, secondUnlockTime);
                emit TokenLocked(start + 2, firstUnlockTime);

                ++j;
            }

            // temporarily adjust nextId to do minimal subtractions
            // when setting `extraData` field
            nextId += amount - 1;
            if (amount % 3 == 2) {
                _setExtraDataAt(nextId - 1, thirdUnlockTime);
                emit TokenLocked(nextId - 1, thirdUnlockTime);

                _setExtraDataAt(nextId, secondUnlockTime);
                emit TokenLocked(nextId, secondUnlockTime);
            } else if (amount % 3 == 1) {
                _setExtraDataAt(nextId, thirdUnlockTime);
                emit TokenLocked(nextId, thirdUnlockTime);
            }
        }
    }

    // =============================================================
    //                   External Mint Methods
    // =============================================================

    /**
     * @notice Allows the owner to change the active version of their signatures, this also
     * allows a simple invalidation of all signatures they have created on old versions.
     */
    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /**
     * @notice Allows the owner to change the active version of their signatures, this also
     * allows a simple invalidation of all signatures they have created on old versions.
     */
    function setSignatureVersion(uint256 version) external onlyOwner {
        signatureVersion = version;
    }

    /**
     * @notice Allows owner to sets if a certain tier is active or not.
     */
    function setIsTierActive(
        string memory tier,
        bool active
    ) external onlyOwner {
        isTierActive[tier] = active;
    }

    /**
     * @notice Tiered mint for allegiants, immortals, and presale bidders.
     * @dev After a tier is activated by the owner, users with the proper signature for that
     * tier are able to mint based on what the owner has approved for their wallet.
     */
    function mintTier(
        string memory tier,
        uint256 price,
        uint256 version,
        uint256 allowedAmount,
        uint256 buyAmount,
        bytes memory sig
    ) external payable {
        if (totalSupply() + buyAmount > MINT_CAP) revert OverMintLimit();
        if (!isTierActive[tier]) revert TierNotActive();
        if (version != signatureVersion) revert InvalidSignatureVersion();

        if (buyAmount > allowedAmount) revert InvalidSignatureBuyAmount();
        if (msg.value != price * buyAmount) revert IncorrectMsgValue();

        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encode(
                    tier,
                    address(this),
                    price,
                    version,
                    allowedAmount,
                    msg.sender
                )
            )
        );
        if (signatureUsed[hash]) revert SignatureAlreadyUsed();
        signatureUsed[hash] = true;
        if (hash.recover(sig) != signer) revert InvalidSignature();

        _mint(msg.sender, buyAmount);
    }

    /**
     * @notice Allows the owner to set the public mint price.
     * @dev If this is 0, it is assumed that the public mint is not active.
     */
    function setPublicMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;
    }

    /**
     * @notice Public mint method. Will not work while {publicMintPrice} is 0.
     * Unlikely to be enabled because it can be easily botted.
     */
    function mintPublic(uint256 amount) external payable {
        if (tx.origin != msg.sender) revert NotEOA();
        if (totalSupply() + amount > MINT_CAP) revert OverMintLimit();
        if (publicMintPrice == 0) revert PublicMintNotLive();
        if (amount > MAX_PUBLIC_MINT_TXN_SIZE) revert OverMintLimit();

        if (msg.value != amount * publicMintPrice) revert IncorrectMsgValue();
        _mint(msg.sender, amount);
    }

    // =============================================================
    //                       Auction Methods
    // =============================================================

    /**
     * @notice Allows the owner to set the auction parameters
     */
    function setOverallAuctionParams(
        uint40 startPrice_,
        uint40 minStackedBidIncrement_,
        uint8 minBidIncrementPercentage_,
        uint16 timeBuffer_
    ) external onlyOwner {
        auctionParams.startPrice = startPrice_;
        auctionParams.minStackedBidIncrement = minStackedBidIncrement_;
        auctionParams.minBidIncrementPercentage = minBidIncrementPercentage_;
        auctionParams.timeBuffer = timeBuffer_;
    }

    /**
     * @notice Allows the owner to set the auctioneer address.
     */
    function setAuctioneer(address auctioneer_) external onlyOwner {
        auctioneer = auctioneer_;
    }

    /**
     * @notice Allows the autioneer to start the auction of `numTokens` from `startTime` to `endTime`.
     * @dev Auctions can only start after all minting has terminated. We cannot auction more than
     * MAX_NUM_BIDS at a time. Only one auction can be live at a time.
     */
    function startAuction(
        uint8 numTokens,
        uint48 startTime,
        uint48 endTime
    ) external {
        if (auctioneer != msg.sender) revert CallerNotAuctioneer();
        if (totalSupply() < MINT_CAP) revert MintingNotFinished();
        if (totalSupply() + numTokens > TOTAL_SUPPLY) revert OverTokenLimit();
        if (numTokens > MAX_NUM_BIDS) revert OverMaxBids();
        if (auctionParams.numTokens != 0) revert AuctionStillLive();
        if (auctionParams.startPrice == 0) revert AuctionParamsNotInitialized();

        auctionParams.numTokens = numTokens;
        auctionParams.startTimestamp = startTime;
        auctionParams.endTimestamp = endTime;

        emit AuctionStarted(auctionParams.index);
    }

    /**
     * @notice Allows the auctioneer to end the auction.
     * @dev Auctions can end at any time by the owner's discretion and when it ends all
     * current bids are accepted. The owner is also now able to withdraw the funds
     * that were reserved for the auction, and active bids data id reset.
     */
    function endAuction() external {
        if (auctioneer != msg.sender) revert CallerNotAuctioneer();
        if (auctionParams.numTokens == 0) revert AuctionNotLive();

        uint256 lowestPrice = activeBids[getBidIndexToUpdate()].amount;
        for (uint256 i = 0; i < auctionParams.numTokens; ) {
            if (activeBids[i].bidder == address(0)) {
                break;
            }

            _mint(activeBids[i].bidder, 1);

            // getBidIndex to update gaurantees no activeBids[i] is less than lowestPrice.
            unchecked {
                _transferETH(
                    activeBids[i].bidder,
                    activeBids[i].amount - lowestPrice
                );
                ++i;
            }
        }

        unchecked {
            ++auctionParams.index;
        }
        auctionParams.numTokens = 0;
        delete activeBids;
        reserveAuctionETH = 0;
    }

    /**
     * @notice Gets the index of the entry in activeBids to update
     * @dev The index to return will be decided by the following rules:
     * If there are less than auctionTokens bids, the index of the first empty slot is returned.
     * If there are auctionTokens or more bids, the index of the lowest value bid is returned. If
     * there is a tie, the most recent bid with the low amount will be returned. If there is a tie
     * among bidTimes, the highest index is chosen.
     */
    function getBidIndexToUpdate() public view returns (uint8) {
        uint256 minAmount = activeBids[0].amount;
        // If the first value is 0 then we can assume that no bids have been submitted
        if (minAmount == 0) {
            return 0;
        }

        uint8 minIndex = 0;
        uint64 minBidTime = activeBids[0].bidTime;

        for (uint8 i = 1; i < auctionParams.numTokens; ) {
            uint256 bidAmount = activeBids[i].amount;
            uint64 bidTime = activeBids[i].bidTime;

            // A zero bidAmount means the slot is empty because we enforce non-zero bid amounts
            if (bidAmount == 0) {
                return i;
            } else if (
                bidAmount < minAmount ||
                (bidAmount == minAmount && bidTime >= minBidTime)
            ) {
                minAmount = bidAmount;
                minIndex = i;
                minBidTime = bidTime;
            }

            unchecked {
                ++i;
            }
        }

        return minIndex;
    }

    /**
     * @notice Handle users' bids
     * @dev Bids must be made while the auction is live. Bids must meet a minimum reserve price.
     *
     * The first {auctionParams.numTokens} bids made will be accepted as valid. Subsequent bids must be a percentage
     * higher than the lowest of the active bids. When a low bid is replaced, the ETH will
     * be refunded back to the original bidder.
     *
     * If a valid bid comes in within the last `timeBuffer` seconds, the auction will be extended
     * for another `timeBuffer` seconds. This will continue until no new active bids come in.
     *
     * If a wallet makes a bid while it still has an active bid, the second bid will
     * stack on top of the first bid. If the second bid doesn't meet the `minStackedBidIncrement`
     * threshold, an error will be thrown. A wallet will only have one active bid at at time.
     */
    function bid() external payable {
        if (msg.sender != tx.origin) revert NotEOA();
        if (auctionParams.numTokens == 0) {
            revert AuctionNotInitialized();
        }
        if (
            block.timestamp < auctionParams.startTimestamp ||
            block.timestamp > auctionParams.endTimestamp
        ) {
            revert AuctionNotLive();
        }

        BidIndex memory existingIndex = bidIndexes[auctionParams.index][
            msg.sender
        ];
        if (existingIndex.isSet) {
            // Case when the user already has an active bid
            if (
                msg.value <
                auctionParams.minStackedBidIncrement * AUCTION_PRICE_MULTIPLIER
            ) {
                revert BidIncrementTooLow();
            }

            uint192 oldValue = activeBids[existingIndex.index].amount;
            unchecked {
                reserveAuctionETH += msg.value;
                activeBids[existingIndex.index].amount =
                    oldValue +
                    uint192(msg.value);
            }
            activeBids[existingIndex.index].bidTime = uint64(block.timestamp);

            emit BidIncreased(
                auctionParams.index,
                msg.sender,
                oldValue,
                msg.value
            );
        } else {
            if (
                msg.value < auctionParams.startPrice * AUCTION_PRICE_MULTIPLIER
            ) {
                revert ReservePriceNotMet();
            }

            uint8 lowestBidIndex = getBidIndexToUpdate();
            uint256 lowestBidAmount = activeBids[lowestBidIndex].amount;
            address lowestBidder = activeBids[lowestBidIndex].bidder;

            unchecked {
                if (
                    msg.value <
                    lowestBidAmount +
                        (lowestBidAmount *
                            auctionParams.minBidIncrementPercentage) /
                        100
                ) {
                    revert IncrementalPriceNotMet();
                }
                reserveAuctionETH += msg.value - lowestBidAmount;
            }

            // Refund lowest bidder and remove bidIndexes entry
            if (lowestBidder != address(0)) {
                delete bidIndexes[auctionParams.index][lowestBidder];
                _transferETH(lowestBidder, lowestBidAmount);
            }

            activeBids[lowestBidIndex] = Bid({
                bidder: msg.sender,
                amount: uint192(msg.value),
                bidTime: uint64(block.timestamp)
            });

            bidIndexes[auctionParams.index][msg.sender] = BidIndex({
                index: lowestBidIndex,
                isSet: true
            });

            emit NewBid(auctionParams.index, msg.sender, msg.value);
        }

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        if (
            auctionParams.endTimestamp - block.timestamp <
            auctionParams.timeBuffer
        ) {
            unchecked {
                auctionParams.endTimestamp = uint48(
                    block.timestamp + auctionParams.timeBuffer
                );
            }
            emit AuctionExtended(auctionParams.index);
        }
    }

    // =============================================================
    //                        Miscellaneous
    // =============================================================

    /**
     * @notice Allows owner to emit TokenUnlocked events
     * @dev This method does NOT need to be called for locked tokens to be unlocked.
     * It is here to emit unlock events for marketplaces to know when tokens are
     * eligible for trade. The burden to call this method on the right tokens at the
     * correct timestamp is on the owner of the contract.
     */
    function emitTokensUnlocked(uint256[] memory tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; ) {
            emit TokenUnlocked(tokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows owner to withdraw a specified amount of ETH to a specified address.
     */
    function withdraw(
        address withdrawAddress,
        uint256 amount
    ) external onlyOwner {
        unchecked {
            if (amount > address(this).balance - reserveAuctionETH) {
                amount = address(this).balance - reserveAuctionETH;
            }
        }

        if (!_transferETH(withdrawAddress, amount)) revert WithdrawFailed();
    }

    /**
     * @notice Internal function to transfer ETH to a specified address.
     */
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30000 }(new bytes(0));
        return success;
    }

    error AuctionNotInitialized();
    error AuctionNotLive();
    error AuctionParamsNotInitialized();
    error AuctionStillLive();
    error BidIncrementTooLow();
    error CallerNotAuctioneer();
    error IncorrectMsgValue();
    error IncrementalPriceNotMet();
    error InvalidSignatureBuyAmount();
    error InvalidSignature();
    error InvalidSignatureVersion();
    error MintingNotFinished();
    error NotEOA();
    error OverDevSupplyLimit();
    error OverMintLimit();
    error OverTokenLimit();
    error OverMaxBids();
    error OperatorNotAllowed();
    error PublicMintNotLive();
    error PresaleAddressAlreadyMinted();
    error ReservePriceNotMet();
    error SignatureAlreadyUsed();
    error TierNotActive();
    error TokenTransferLocked();
    error WithdrawFailed();
}