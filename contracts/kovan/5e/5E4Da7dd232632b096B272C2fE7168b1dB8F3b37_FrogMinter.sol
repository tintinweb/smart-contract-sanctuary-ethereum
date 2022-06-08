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

import "./interfaces/IFoundingFrog.sol";
import "./interfaces/IFrogMinter.sol";

contract FrogMinter is IFrogMinter {
    /// @notice merkle root to submit proofs of ownership of the NFT
    bytes32 public immutable merkleRoot;

    /// @notice founding frogs
    IFoundingFrog public immutable frog;

    constructor(bytes32 _merkleRoot, IFoundingFrog _frog) {
        merkleRoot = _merkleRoot;
        frog = _frog;
    }

    /// @inheritdoc IFrogMinter
    function mint(FrogMeta memory meta, bytes32[] memory proof) external {
        require(_isProofValid(meta, proof), "invalid proof");
        frog.mint(meta.beneficiary, meta.tokenId, meta.imageHash);
    }

    function _isProofValid(FrogMeta memory meta, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        bytes32 node = keccak256(abi.encodePacked(msg.sender, meta.tokenId, meta.imageHash));
        uint256 length = proof.length;
        for (uint256 i = 0; i < length; i++) {
            (bytes32 left, bytes32 right) = (node, proof[i]);
            if (left > right) (left, right) = (right, left);
            node = keccak256(abi.encodePacked(left, right));
        }

        return node == merkleRoot;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IFoundingFrog is IERC721 {
    event TransfersEnabled();
    event MinterSet(address indexed minter);
    event Minted(address indexed to, uint256 tokenId, bytes32 imageHash);

    /// @return `true` if the NFTs can be transfered
    function isTransferable() external view returns (bool);

    /// @notice address of the contract allowed to mint NFTs
    function minter() external view returns (address);

    /// @notice mapping from token ID to image hash
    /// this can be used to ensure that the image pointed by the metadata is valid
    function imageHash(uint256 tokenId) external view returns (bytes32);

    /// @notice Enable NFT transfers
    function enableTransfers() external;

    /// @notice Set the minter to the given address
    function setMinter(address _minter) external;

    /// @notice Mints an NFT to the given account
    function mint(
        address to,
        uint256 tokenId,
        bytes32 imageHash
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IFoundingFrog.sol";

interface IFrogMinter {
    struct FrogMeta {
        address beneficiary;
        uint256 tokenId;
        bytes32 imageHash;
    }

    /// @notice Mints a new founding frog given its metadata and a vaild merkle proof
    function mint(FrogMeta memory meta, bytes32[] memory proof) external;
}