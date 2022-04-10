// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

interface INestedAsset is IERC721Enumerable {
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function lastOwnerBeforeBurn(uint256 _tokenId) external view returns (address);
}

interface INestedRecords {
    function tokenHoldings(uint256 _nftId) external view returns (address[] memory, uint256[] memory);
}

/// @title Batcher for NestedAsset
/// @notice Front-end batch calls to minimize interactions.
contract NestedAssetBatcher {
    INestedAsset public immutable nestedAsset;
    INestedRecords public immutable nestedRecords;

    struct Nft {
        uint256 id;
        Asset[] assets;
    }

    struct Asset {
        address token;
        uint256 qty;
    }

    constructor(INestedAsset _nestedAsset, INestedRecords _nestedRecords) {
        nestedAsset = _nestedAsset;
        nestedRecords = _nestedRecords;
    }

    /// @notice Get all NestedAsset tokenURIs owned by a user
    /// @param user The address of the user
    /// @return String array of all tokenURIs
    function getURIs(address user) external view returns (string[] memory) {
        unchecked {
            uint256 numTokens = nestedAsset.balanceOf(user);
            string[] memory uriList = new string[](numTokens);

            for (uint256 i; i < numTokens; i++) {
                uriList[i] = nestedAsset.tokenURI(nestedAsset.tokenOfOwnerByIndex(user, i));
            }

            return (uriList);
        }
    }

    /// @notice Get all NestedAsset IDs owned by a user
    /// @param user The address of the user
    /// @return Array of all IDs
    function getIds(address user) external view returns (uint256[] memory) {
        unchecked {
            uint256 numTokens = nestedAsset.balanceOf(user);
            uint256[] memory ids = new uint256[](numTokens);
            for (uint256 i; i < numTokens; i++) {
                ids[i] = nestedAsset.tokenOfOwnerByIndex(user, i);
            }
            return (ids);
        }
    }

    /// @notice Get all NFTs (with tokens and quantities) owned by a user
    /// @param user The address of the user
    /// @return Array of all NFTs (struct Nft)
    function getNfts(address user) external view returns (Nft[] memory) {
        unchecked {
            uint256 numTokens = nestedAsset.balanceOf(user);
            Nft[] memory nfts = new Nft[](numTokens);
            for (uint256 i; i < numTokens; i++) {
                uint256 nftId = nestedAsset.tokenOfOwnerByIndex(user, i);
                (address[] memory tokens, uint256[] memory amounts) = nestedRecords.tokenHoldings(nftId);
                uint256 tokenLength = tokens.length;
                Asset[] memory nftAssets = new Asset[](tokenLength);
                for (uint256 j; j < tokenLength; j++) {
                    nftAssets[j] = Asset({ token: tokens[j], qty: amounts[j] });
                }
                nfts[i] = Nft({ id: nftId, assets: nftAssets });
            }
            return (nfts);
        }
    }

    /// @notice Require the given tokenID to haven been created and call tokenHoldings.
    /// @param _nftId The token id
    /// @return tokenHoldings returns
    function requireTokenHoldings(uint256 _nftId) external view returns (address[] memory, uint256[] memory) {
        try nestedAsset.ownerOf(_nftId) {} catch {
            // owner == address(0)
            require(nestedAsset.lastOwnerBeforeBurn(_nftId) != address(0), "NAB: NEVER_CREATED");
        }
        return nestedRecords.tokenHoldings(_nftId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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