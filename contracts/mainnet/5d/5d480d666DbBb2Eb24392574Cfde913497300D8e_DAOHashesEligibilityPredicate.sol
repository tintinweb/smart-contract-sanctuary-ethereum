// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { ICollectionNFTEligibilityPredicate } from "../../interfaces/ICollectionNFTEligibilityPredicate.sol";
import { IHashes } from "../../interfaces/IHashes.sol";
import { ICollection } from "../../interfaces/ICollection.sol";

/**
 * @title  DAOHashesEligibilityPredicate
 * @author David Matheson
 * @notice This is a helper contract used to determine token eligibility upon instantiating a new
 *         contract from CollectionNFTCloneableV1 to create a new Hashes NFT collection.
 *         This contract includes a function, isTokenEligibleToMint, where a tokenId
 *         and hashesTokenId is provided and the internal logic then determines if hashesTokenId
 *         is a DAO token and not deactivated.
 */
contract DAOHashesEligibilityPredicate is ICollectionNFTEligibilityPredicate, ICollection {
    IHashes hashesToken;

    constructor(IHashes _hashesToken) {
        hashesToken = _hashesToken;
    }

    /**
     * @notice This predicate function is used to determine the mint eligibility of a hashes token Id for
     *          a specified hashes collection by validating if the hashes token Id is a governance token and
     *          has not been deactivated. This function is to be used when instantiating new hashes collections
     *          where only DAO hash holders are eligible to mint.
     * @param _tokenId The token Id of the associated hashes collection contract.
     * @param _hashesTokenId The Hashes token Id being used to mint.
     *
     * @return The boolean result of the validation.
     */
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view override returns (bool) {
        return _hashesTokenId < hashesToken.governanceCap() && !hashesToken.deactivated(_hashesTokenId);
    }

    /**
     * @notice This function is used by the Factory to verify the format of ecosystem settings
     * @param _settings ABI encoded ecosystem settings data. This should be empty for the 'Default' ecosystem.
     *
     * @return The boolean result of the validation.
     */
    function verifyEcosystemSettings(bytes memory _settings) external pure override returns (bool) {
        return _settings.length == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ICollectionNFTEligibilityPredicate {
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHashes is IERC721Enumerable {
    function deactivateTokens(
        address _owner,
        uint256 _proposalId,
        bytes memory _signature
    ) external returns (uint256);

    function deactivated(uint256 _tokenId) external view returns (bool);

    function activationFee() external view returns (uint256);

    function verify(
        uint256 _tokenId,
        address _minter,
        string memory _phrase
    ) external view returns (bool);

    function getHash(uint256 _tokenId) external view returns (bytes32);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function governanceCap() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ICollection {
    function verifyEcosystemSettings(bytes memory _settings) external pure returns (bool);
}

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