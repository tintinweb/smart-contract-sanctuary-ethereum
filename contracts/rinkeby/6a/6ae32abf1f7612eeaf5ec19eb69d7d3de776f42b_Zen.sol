/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.11;

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)



// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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
}// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)



// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)



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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
}// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)



// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)





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
}// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)



// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)





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
/// @title Zen
/// @author The Garden
contract Zen {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error InactiveSwap();
    error InvalidInput();
    error InvalidReceipient();
    error AlreadyCompleted();
    error NotAuthorized();
    error NoncompliantTokens();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Create(
        uint256 indexed swapId,
        address indexed sender,
        address indexed recipient
    );

    event Accept(
        uint256 indexed swapId,
        address indexed sender,
        address indexed recipient
    );

    event Cancel(
        uint256 indexed swapId,
        address indexed sender,
        address indexed recipient
    );

    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    struct Token {
        address contractAddress;
        uint256[] tokenIds;
        uint256[] quantities;
    }

    /// @param id The id of the swap
    /// @param recipient The opposing party the swap is interacting with.
    /// @param createdAt The timestamp of swap creation.
    /// @param allotedTime The time allocated for the swap.
    /// @param status The status that determines the state of the swap.
    struct Swap {
        uint256 id;
        address recipient;
        uint64 createdAt;
        uint24 allotedTime;
        SwapStatus status;
    }

    enum SwapStatus {
        ACTIVE,
        COMPLETE,
        INACTIVE
    }

    /// -----------------------------------------------------------------------
    /// Storage
    /// -----------------------------------------------------------------------

    uint256 private _currentSwapId;

    /// @notice Maps user to outgoing Swaps.
    mapping(address => Swap[]) public getSwaps;

    /// @notice Maps Swap id to array of Tokens offered.
    mapping(uint256 => Token[]) public getOfferTokens;

    /// @notice Maps Swap id to array of Tokens requested.
    mapping(uint256 => Token[]) public getRequestTokens;

    /// @notice Maps Swap id to index of Swap within Swap array.
    mapping(uint256 => uint256) public getSwapIndex;

    constructor() {}

    /// @notice Creates a new swap.
    /// @param offerTokens Tokens being offered.
    /// @param requestTokens Tokens being requested.
    /// @param recipient The recipient of the swap request.
    /// @param allotedTime Time allocated for the swap, until it expires and becomes invalid.
    function createSwap(
        Token[] calldata offerTokens,
        Token[] calldata requestTokens,
        address recipient,
        uint256 allotedTime
    ) external {
        if (offerTokens.length == 0 && requestTokens.length == 0)
            revert InvalidInput();
        if (allotedTime == 0) revert InvalidInput();
        if (allotedTime >= 365 days) revert InvalidInput();
        if (recipient == address(0)) revert InvalidInput();

        uint256 offerLength = offerTokens.length;
        uint256 requestLength = requestTokens.length;

        for (uint256 i; i < offerLength; ) {
            getOfferTokens[_currentSwapId].push(offerTokens[i]);

            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < requestLength; ) {
            getRequestTokens[_currentSwapId].push(requestTokens[i]);

            unchecked {
                ++i;
            }
        }

        Swap memory newSwap = Swap(
            _currentSwapId,
            recipient,
            uint64(block.timestamp),
            uint24(allotedTime),
            SwapStatus.ACTIVE
        );

        getSwapIndex[_currentSwapId] = getSwaps[msg.sender].length;
        getSwaps[msg.sender].push(newSwap);

        emit Create(_currentSwapId, msg.sender, recipient);

        _currentSwapId++;
    }

    /// @notice Accepts an existing swap.
    /// @param id The id of the swap to accept.
    /// @param sender The address of the user that sent the swap request
    function acceptSwap(uint256 id, address sender) external {
        uint256 swapIndex = getSwapIndex[id];
        Swap memory swap = getSwaps[sender][swapIndex];

        if (swap.status == SwapStatus.INACTIVE) revert InactiveSwap();
        if (swap.status == SwapStatus.COMPLETE) revert AlreadyCompleted();
        if (swap.recipient != msg.sender) revert InvalidReceipient();
        if (block.timestamp > swap.createdAt + swap.allotedTime)
            revert InactiveSwap();

        getSwaps[sender][swapIndex].status = SwapStatus.COMPLETE;

        _swapTokens(getOfferTokens[swap.id], getRequestTokens[swap.id], sender);

        emit Accept(id, sender, msg.sender);
    }

    function _swapTokens(
        Token[] memory offerTokens,
        Token[] memory requestTokens,
        address to
    ) internal {
        for (uint256 i; i < offerTokens.length; ) {
            uint256 offerTokenLength = offerTokens[i].tokenIds.length;
            for (uint256 j; j < offerTokenLength; ) {
                if (
                    IERC165(offerTokens[i].contractAddress).supportsInterface(
                        0x80ac58cd
                    )
                ) {
                    IERC721(offerTokens[i].contractAddress).transferFrom(
                        msg.sender,
                        to,
                        offerTokens[i].tokenIds[j]
                    );
                } else if (
                    IERC165(offerTokens[i].contractAddress).supportsInterface(
                        0xd9b67a26
                    )
                ) {
                    IERC1155(offerTokens[i].contractAddress).safeTransferFrom(
                        msg.sender,
                        to,
                        offerTokens[i].tokenIds[j],
                        offerTokens[i].quantities[j],
                        ""
                    );
                } else if (
                    IERC165(offerTokens[i].contractAddress).supportsInterface(
                        0x36372b07
                    )
                ) {
                    IERC721(offerTokens[i].contractAddress).transferFrom(
                        msg.sender,
                        to,
                        offerTokens[i].quantities[0]
                    );
                } else {
                    revert NoncompliantTokens();
                }

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < requestTokens.length; ) {
            uint256 offerTokenLength = requestTokens[i].tokenIds.length;
            for (uint256 j; j < offerTokenLength; ) {
                if (
                    IERC165(requestTokens[i].contractAddress).supportsInterface(
                        0x80ac58cd
                    )
                ) {
                    IERC721(requestTokens[i].contractAddress).transferFrom(
                        to,
                        msg.sender,
                        requestTokens[i].tokenIds[j]
                    );
                } else if (
                    IERC165(requestTokens[i].contractAddress).supportsInterface(
                        0xd9b67a26
                    )
                ) {
                    IERC1155(requestTokens[i].contractAddress).safeTransferFrom(
                            to,
                            msg.sender,
                            requestTokens[i].tokenIds[j],
                            requestTokens[i].quantities[j],
                            ""
                        );
                } else if (
                    IERC165(offerTokens[i].contractAddress).supportsInterface(
                        0x36372b07
                    )
                ) {
                    IERC721(offerTokens[i].contractAddress).transferFrom(
                        to,
                        msg.sender,
                        requestTokens[i].quantities[0]
                    );
                } else {
                    revert NoncompliantTokens();
                }

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Gets the details of a single existing Swap.
    function getSwapSingle(uint256 id, address offerer)
        external
        view
        returns (Swap memory singleSwap)
    {
        singleSwap = getSwaps[offerer][getSwapIndex[id]];
    }

    /// @notice Gets all details of outgoing Swaps.
    /// @param user The user to get Swaps for.
    /// @dev Function provided since Solidity converts public array to index getters.
    function getSwapsOutgoing(address user)
        external
        view
        returns (Swap[] memory outgoingSwaps)
    {
        outgoingSwaps = getSwaps[user];
    }

    /// @notice Extends existing swap alloted time
    /// @param allotedTime Amount of time to increase swap alloted time for
    function extendAllotedTime(uint256 id, uint24 allotedTime) external {
        Swap storage swap = getSwaps[msg.sender][getSwapIndex[id]];

        if (swap.status == SwapStatus.INACTIVE) revert InactiveSwap();

        swap.allotedTime = swap.allotedTime + allotedTime;
    }

    /// @notice Manually deletes existing swap.
    function cancelSwap(uint256 id) external {
        Swap storage swap = getSwaps[msg.sender][getSwapIndex[id]];

        if (swap.status == SwapStatus.INACTIVE) revert InvalidInput();

        swap.status = SwapStatus.INACTIVE;

        emit Cancel(id, msg.sender, swap.recipient);
    }
}