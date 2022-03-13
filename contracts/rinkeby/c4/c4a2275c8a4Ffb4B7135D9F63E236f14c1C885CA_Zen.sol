/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/interfaces/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: contracts/ZenSwap.sol


pragma solidity 0.8.7;



error NonexistentTrade();
error TimeExpired();
error InvalidAction();
error DeniedOwnership();

/// @title Zen (Red Bean Swap)
/// @author The Garden
contract Zen {
    /// >>>>>>>>>>>>>>>>>>>>>>>>>  METADATA   <<<<<<<<<<<<<<<<<<<<<<<<< ///

    event SwapCreated(address indexed user, ZenSwap);

    event SwapAccepted(address indexed user, ZenSwap);

    event SwapUpdated(address indexed user, ZenSwap);

    event SwapCanceled(address indexed user, ZenSwap);

    event RequesterAdded(ZenSwap);

    /// @notice Azuki contract on mainnet
    IERC721 private immutable azuki;

    /// @notice BOBU contract on mainnet
    IERC1155 private immutable bobu;

    /// @dev Packed struct of swap data.
    /// @param offerTokens List of token IDs offered
    /// @param offerTokens List of token IDs requested in exchange
    /// @param counterParty Opposing party the swap is initiated with.
    /// @param createdAt UNIX Timestamp of swap creation.
    /// @param allotedTime Time allocated for the swap, until it expires and becomes invalid.
    struct ZenSwap {
        uint256[] offerTokens721;
        uint256 offerTokens1155;
        uint256[] counterTokens721;
        uint256 counterTokens1155;
        address counterParty;
        uint64 createdAt;
        uint32 allotedTime;
    }

    /// @notice Maps offering party to their respective active swap
    mapping(address => ZenSwap) public activeSwaps;

    /// @notice Maps user to addresses requesting swap
    mapping(address => address[]) public incomingRequesters;

    /// @notice Maps user's requester to index within above array
    mapping(address => mapping(address => uint256)) public indexOfRequester;

    constructor(IERC721 _azuki, IERC1155 _bobu) {
        azuki = _azuki;
        bobu = _bobu;
    }

    /// @notice Creates a new swap.
    /// @param offerTokens721 ERC721 Token IDs offered by the offering party (caller).
    /// @param offerTokens1155 ERC1155 quantity of Bobu Token ID #1
    /// @param counterParty Opposing party the swap is initiated with.
    /// @param counterTokens721 ERC721 Token IDs requested from the counter party.
    /// @param counterTokens1155 ERC1155 quantity of Bobu Token ID #1 request from the counter party.
    /// @param allotedTime Time allocated for the swap, until it expires and becomes invalid.
    function createSwap(
        uint256[] calldata offerTokens721,
        uint256 offerTokens1155,
        address counterParty,
        uint256[] calldata counterTokens721,
        uint256 counterTokens1155,
        uint32 allotedTime
    ) external {
        if (offerTokens721.length == 0 && counterTokens721.length == 0)
            revert InvalidAction();
        if (allotedTime == 0) revert InvalidAction();
        if (allotedTime >= 365 days) revert InvalidAction();
        if (counterParty == address(0)) revert InvalidAction();
        if (!_verifyOwnership721(msg.sender, offerTokens721))
            revert DeniedOwnership();
        if (!_verifyOwnership721(counterParty, counterTokens721))
            revert DeniedOwnership();
        if (
            offerTokens1155 != 0 &&
            !_verifyOwnership1155(msg.sender, offerTokens1155)
        ) revert DeniedOwnership();
        if (
            counterTokens1155 != 0 &&
            !_verifyOwnership1155(counterParty, counterTokens1155)
        ) revert DeniedOwnership();

        ZenSwap memory swap = ZenSwap(
            offerTokens721,
            offerTokens1155,
            counterTokens721,
            counterTokens1155,
            counterParty,
            uint64(block.timestamp),
            allotedTime
        );

        activeSwaps[msg.sender] = swap;

        /// Check if swap being pair already exists
        if (activeSwaps[msg.sender].counterParty != address(0)) {
            incomingRequesters[counterParty].push(msg.sender);
        }

        emit SwapCreated(msg.sender, swap);
    }

    /// @notice Accepts an existing swap.
    /// @param offerer Address of the offering party that initiated the swap
    function acceptSwap(address offerer) external {
        ZenSwap memory swap = activeSwaps[offerer];

        if (swap.counterParty != msg.sender) revert NonexistentTrade();
        if (block.timestamp > swap.createdAt + swap.allotedTime)
            revert TimeExpired();

        delete activeSwaps[offerer];

        _swapERC721(swap, offerer);
        _swapERC1155(swap, offerer);

        _removeRequester(msg.sender);

        emit SwapAccepted(msg.sender, swap);
    }

    function _removeRequester(address requester) internal {
        uint256 index = indexOfRequester[msg.sender][requester];

        uint256 length = incomingRequesters[requester].length;
        incomingRequesters[requester][index] = incomingRequesters[requester][
            length - 1
        ];
        incomingRequesters[requester].pop();
    }

    /// @notice Swaps ERC721 contents
    /// @param swap ZenSwap object containing all swap data
    /// @param offerer User that created the swap
    /// @dev `msg.sender` is the user accepting the swap
    function _swapERC721(ZenSwap memory swap, address offerer) internal {
        uint256 offererLength721 = swap.offerTokens721.length;
        uint256 counterLength721 = swap.counterTokens721.length;

        uint256[] memory offerTokens721 = swap.offerTokens721;
        uint256[] memory counterTokens721 = swap.counterTokens721;

        for (uint256 i; i < offererLength721; ) {
            azuki.transferFrom(offerer, msg.sender, offerTokens721[i]);

            unchecked {
                i++;
            }
        }

        for (uint256 i; i < counterLength721; ) {
            azuki.transferFrom(msg.sender, offerer, counterTokens721[i]);

            unchecked {
                i++;
            }
        }
    }

    /// @notice Swaps ERC1155 contents
    /// @param swap ZenSwap object containing all swap data
    /// @param offerer User that created the swap
    /// @dev `msg.sender` is the user accepting the swap
    function _swapERC1155(ZenSwap memory swap, address offerer) internal {
        uint256 offererQuantity1155 = swap.offerTokens1155;
        uint256 counterQuantity1155 = swap.counterTokens1155;

        if (offererQuantity1155 != 0) {
            bobu.safeTransferFrom(
                offerer,
                msg.sender,
                1,
                offererQuantity1155,
                ""
            );
        }

        if (counterQuantity1155 != 0) {
            bobu.safeTransferFrom(
                msg.sender,
                offerer,
                1,
                counterQuantity1155,
                ""
            );
        }
    }

    /// @notice Batch verifies that the specified owner is the owner of all ERC721 tokens.
    /// @param owner Specified owner of tokens.
    /// @param tokenIds List of token IDs.
    function _verifyOwnership721(address owner, uint256[] memory tokenIds)
        internal
        view
        returns (bool)
    {
        uint256 length = tokenIds.length;

        for (uint256 i = 0; i < length; ) {
            if (azuki.ownerOf(tokenIds[i]) != owner) return false;

            unchecked {
                i++;
            }
        }

        return true;
    }

    /// @notice Batch verifies that the specified owner is the owner of all ERC1155 tokens.
    /// @param owner Specified owner of tokens.
    /// @param tokenQuantity Amount of Bobu tokens
    function _verifyOwnership1155(address owner, uint256 tokenQuantity)
        internal
        view
        returns (bool)
    {
        return bobu.balanceOf(owner, 1) >= tokenQuantity;
    }

    /// @notice Gets the details of an existing swap.
    function getSwap(address offerer)
        external
        view
        returns (
            uint256[] memory offerTokens721,
            uint256 offerTokens1155,
            uint256[] memory counterTokens721,
            uint256 counterTokens1155,
            address counterParty,
            uint64 createdAt,
            uint32 allotedTime
        )
    {
        ZenSwap memory swap = activeSwaps[offerer];

        offerTokens721 = swap.offerTokens721;
        offerTokens1155 = swap.offerTokens1155;
        counterTokens721 = swap.counterTokens721;
        counterTokens1155 = swap.counterTokens1155;
        counterParty = swap.counterParty;
        createdAt = swap.createdAt;
        allotedTime = swap.allotedTime;
    }

    /// @notice Extends existing swap alloted time
    /// @param allotedTime Amount of time to increase swap alloted time for
    function extendAllotedTime(uint32 allotedTime) external {
        ZenSwap storage swap = activeSwaps[msg.sender];

        if (swap.counterParty == address(0)) revert InvalidAction();

        swap.allotedTime = swap.allotedTime + allotedTime;

        emit SwapUpdated(msg.sender, swap);
    }

    /// @notice Manually deletes existing swap.
    function cancelSwap() external {
        ZenSwap memory swap = activeSwaps[msg.sender];

        if (swap.counterParty == address(0)) revert InvalidAction();

        delete activeSwaps[msg.sender];

        emit SwapCanceled(msg.sender, activeSwaps[msg.sender]);
    }
}