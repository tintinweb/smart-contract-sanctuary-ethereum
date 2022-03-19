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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarket {
    // owner => contract => id => position in itemList offset by 1
    mapping(address => mapping(address => mapping(uint256 => uint256))) items;
    Item[] itemList;

    struct Item {
        address owner;
        address contractAddress;
        uint256 tokenId;
        uint256 price;
    }

    function deleteItem(uint256 idx) internal {
        Item storage itemToDelete = itemList[idx];
        Item storage itemToMove = itemList[itemList.length - 1];
        items[itemToMove.owner][itemToMove.contractAddress][itemToMove.tokenId] = idx + 1;
        delete items[itemToDelete.owner][itemToDelete.contractAddress][itemToDelete.tokenId];
        itemList[idx] = itemToMove;
        itemList.pop();
    }

    function listItem(address _contractAddress, uint256 _tokenId, uint256 _price) external {
        IERC721 nft = IERC721(_contractAddress);
        require(_price >= 0, "Price cannot be negative");
        require(nft.ownerOf(_tokenId) == msg.sender, "Only owner can list");
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Contract must be approved to list");

        uint256 pos = items[msg.sender][_contractAddress][_tokenId];
        if (pos == 0) {
            if (_price > 0) {
                // Create
                itemList.push(Item(msg.sender, _contractAddress, _tokenId, _price));
                items[msg.sender][_contractAddress][_tokenId] = itemList.length;
            } else {
                // Do nothing
            }
        } else {
            if (_price > 0) {
                // Update
                itemList[pos - 1].price = _price;
            } else {
                // Delete (just move last item to spot)
                deleteItem(pos - 1);
            }
        }
    }

    function buyItem(address _contractAddress, uint256 _tokenId) external payable {
        IERC721 nft = IERC721(_contractAddress);
        address owner = nft.ownerOf(_tokenId);
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(owner, address(this)), "Not available");

        uint256 pos = items[owner][_contractAddress][_tokenId];
        require(pos > 0, "Not available");
        uint256 price = itemList[pos - 1].price;
        require (price == msg.value, "Must send correct amount");

        nft.safeTransferFrom(owner, msg.sender, _tokenId);
        payable(owner).transfer(msg.value);

        deleteItem(pos - 1);
    }

    function priceOf(address _contractAddress, uint256 _tokenId) public view returns (uint256) {
        IERC721 nft = IERC721(_contractAddress);
        address owner = nft.ownerOf(_tokenId);
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(owner, address(this)), "Not available");

        uint256 pos = items[owner][_contractAddress][_tokenId];
        require(pos > 0, "Not available");
        return itemList[pos - 1].price;
    }

    function showItems() public view returns (Item[] memory) {
        Item[] memory list = new Item[](itemList.length);
        uint256 idx = 0;
        for (uint256 i = 0; i < itemList.length; i++) {
            Item storage item = itemList[i];
            IERC721 nft = IERC721(item.contractAddress);
            address owner = nft.ownerOf(item.tokenId);
            if (nft.getApproved(item.tokenId) == address(this) || nft.isApprovedForAll(owner, address(this))) {
                list[idx++] = item;
            }
        }
        if (itemList.length == idx) {
            return list;
        }
        Item[] memory refined = new Item[](idx);
        for (uint256 i = 0; i < refined.length; ++i) {
            refined[i] = list[i];
        }
        return refined;
    }
}