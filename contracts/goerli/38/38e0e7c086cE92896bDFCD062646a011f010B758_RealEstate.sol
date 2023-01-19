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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NotInspector();
error YouAreNotBuyer();

contract RealEstate {
    struct List {
        uint256 tokenId;
        address nftAddress;
        address buyer;
        address seller;
        address inspector;
        uint256 purchasePrice;
        uint256 escrowAmount;
        uint256 inspectionStatus;
        string tokenURI;
    }

    event Listed(
        uint256 indexed tokenId,
        address indexed nftAddress,
        address buyer,
        address seller,
        address inspector,
        uint256 indexed purchasePrice,
        uint256 escrowAmount,
        uint256 inspectionStatus,
        string tokenURI
    );

    event UpdateInspection(
        uint256 indexed tokenId,
        address indexed nftAddress,
        uint256 indexed pruchasePrice
    );
    event Deposited(uint256 indexed tokenId, address indexed buyer, address indexed nftAddress);
    event Sold(uint256 indexed tokenId);
    event Canceled(uint256 indexed tokenId, address indexed nftAddress, uint256 indexed purchasePrice);

    mapping(uint256 => List) private s_lists;

    modifier onlyBuyer(uint256 tokenId) {
        List memory list = s_lists[tokenId];
        if (msg.sender != list.buyer) {
            revert YouAreNotBuyer();
        }
        _;
    }

    function list(
        uint256 tokenId,
        address nftAddress,
        address buyer,
        address inspector,
        uint256 purchasePrice,
        uint256 escrowAmount,
        string memory tokenURI
    ) external {
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        s_lists[tokenId] = List(
            tokenId,
            nftAddress,
            buyer,
            msg.sender,
            inspector,
            purchasePrice,
            escrowAmount,
            0,
            tokenURI
        );
        emit Listed(
            tokenId,
            nftAddress,
            buyer,
            msg.sender,
            inspector,
            purchasePrice,
            escrowAmount,
            0,
            tokenURI
        );
    }

    function inspectionStatus(uint256 tokenId) external {
        List memory list = s_lists[tokenId];
        if (msg.sender != list.inspector) {
            revert NotInspector();
        }
        list.inspectionStatus = 1;
        emit UpdateInspection(tokenId, list.nftAddress, list.purchasePrice);
    }

    function deposit(uint256 tokenId) external payable onlyBuyer(tokenId) {
        List memory list = s_lists[tokenId];
        require(msg.value >= list.escrowAmount);
        emit Deposited(tokenId, msg.sender, list.nftAddress);
    }

    function finalize(uint256 tokenId) external payable onlyBuyer(tokenId) {
        List memory list = s_lists[tokenId];
        require(msg.value >= list.purchasePrice);
        if (address(this).balance > list.purchasePrice) {
            delete(list);
            (bool success, ) = payable(list.seller).call{value: list.purchasePrice}("");
            require(success);
        }
        IERC721(list.nftAddress).transferFrom(address(this), list.buyer, tokenId);
        emit Sold(tokenId);
    }

    function cancel(uint256 tokenId) external {
        List memory list = s_lists[tokenId];
        if(list.inspectionStatus == 0) {
            (bool success, ) = payable(list.buyer).call{value: list.escrowAmount}("");
            require(success);
        }
        emit Canceled(tokenId, list.nftAddress, list.purchasePrice);
    }

    function getList(uint256 tokenId) external view returns(List memory) {
        return s_lists[tokenId];
    }
}