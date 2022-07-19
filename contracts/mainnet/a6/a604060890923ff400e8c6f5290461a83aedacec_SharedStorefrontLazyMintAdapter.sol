// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @author emo.eth
 * @title SharedStorefrontLazyMintAdapter
 * @notice SharedStorefrontLazymintAdapter is a stub of an ERC1155 token,
 *         which acts as a safe proxy for lazily minting tokens from the
 *         the underlying Shared Storefront.
 *         The lazy minting functionality of the original Shared Storefront
 *         was built with the assumption that every user would have their own
 *         individual Wyvern-style proxy, which makes an exchange with
 *         a global proxy like Seaport unsafe to add as a shared proxy.
 *         This adapter contract performs the necessary check that lazily
 *         minted tokens are being spent from their creators' address, relying
 *         on the invariant that Seaport will never transfer tokens from an
 *         account that has not signed a valid order.
 */
contract SharedStorefrontLazyMintAdapter {
    IERC1155 immutable ssfToken;
    address private constant SEAPORT =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address private constant CONDUIT =
        0x1E0049783F008A0085193E00003D00cd54003c71;

    error InsufficientBalance();
    error UnauthorizedCaller();

    modifier onlySeaportOrConduit() {
        if (msg.sender != CONDUIT && msg.sender != SEAPORT) {
            revert UnauthorizedCaller();
        }
        _;
    }

    modifier onlyCreatorLazyMint(
        address from,
        uint256 tokenId,
        uint256 amount
    ) {
        // get balance of spender - this will return current balance
        // plus remaining supply if spender is the creator
        // (or this contract itself - which should never be possible,
        // as Seaport will only spend from accts that have signed a valid order)
        uint256 fromBalance = ssfToken.balanceOf(from, tokenId);

        // if insufficient balance, revert
        if (fromBalance < amount) {
            revert InsufficientBalance();
        }
        _;
    }

    /// @dev parameterless constructor allows us to CREATE2 this contract at the same address on each network
    constructor() {
        // can't set immutables within an if statement; use temp var
        address tokenAddress;

        uint256 chainId = block.chainid;
        // use chainId to get network SSF address
        if (chainId == 4) {
            // rinkeby SSF
            tokenAddress = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
        } else if (chainId == 137 || chainId == 80001) {
            // polygon + mumbai SSF
            tokenAddress = 0x2953399124F0cBB46d2CbACD8A89cF0599974963;
        } else {
            // mainnet SSF
            tokenAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
        }

        ssfToken = IERC1155(tokenAddress);
    }

    /**
     * @notice stub method that performs two checks before calling real SSF safeTransferFrom
     *   1. check that the caller is a valid proxy (Seaport or OpenSea conduit)
     *   2. check that the token spender owns enough tokens, or is the creator of
     *      the token and not all tokens have been minted yet
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory
    ) public onlySeaportOrConduit onlyCreatorLazyMint(from, tokenId, amount) {
        // Seaport 1.1 always calls safeTransferFrom with empty data
        ssfToken.safeTransferFrom(from, to, tokenId, amount, "");
    }

    /**
     * @notice pass-through balanceOf method to the SSF for backwards-compatibility with seaport-js
     * @param owner address to check balance of
     * @param tokenId id to check balance of
     * @return uint256 balance of tokenId for owner
     */
    function balanceOf(address owner, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return ssfToken.balanceOf(owner, tokenId);
    }

    /**
     * @notice stub isApprovedForAll method for backwards-compatibility with seaport-js
     * @param operator address to check approval of
     * @return bool if operator is Conduit or Seaport
     */
    function isApprovedForAll(address, address operator)
        public
        pure
        returns (bool)
    {
        return operator == CONDUIT || operator == SEAPORT;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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