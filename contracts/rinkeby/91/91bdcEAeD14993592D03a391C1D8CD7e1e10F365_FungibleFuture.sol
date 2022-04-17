//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Fungible Future 
/// @author @takez0_o
/// @notice Time bound P2P NFT liquidity solution.
/// @dev Percentage is original owner's percentage. States are (0-Listed, 1-Invested, 2-Sold, 3-Expired).
contract FungibleFuture is ERC721Holder {

    struct Future {
        address owner;
        address investor;
        address asset;
        uint256 id;
        uint256 expiry;
        uint256 percentage;
        uint256 price;
        uint256 futurePrice;
        uint256 state;
    }
    Future[] public futures;

    function addFuture (
        address _asset,
        uint256 _id,
        uint256 _expiry,
        uint256 _percentage,
        uint256 _price,
        uint256 _futurePrice
    ) public {
        require(block.timestamp < _expiry, "Shan't go to past.");
        require(_percentage < 100, "You shan't do 100%.");
        require(_futurePrice > _price, "Shan't short thyself.");
        futures.push(Future(
            msg.sender,
            address(0),
            _asset,
            _id,
            _expiry,
            _percentage,
            _price,
            _futurePrice,
            0
        ));
        IERC721(_asset).safeTransferFrom(msg.sender,address(this), _id);
    }

    function purchaseFuture (uint256 _index) external payable {
        Future storage future = futures[_index];
        address payable _to = payable(future.owner);
        require(future.state == 0, "Future is sold.");
        require(msg.value == future.price, "Wrong price");
        (bool success, ) = _to.call{value: future.price}("");
        require(success, "Failed payment.");
        future.investor = msg.sender;
        future.state = 1;
    }

    function purchaseAsset (uint256 _index) external payable {
        Future storage future = futures[_index];
        require(future.state == 1, "Asset is not for sale.");
        require(block.timestamp <= future.expiry, "Expired.");
        require(msg.value == future.futurePrice, "Not correct amount");
        address payable _owner = payable(future.owner);
        address payable _investor = payable(future.investor);
        uint256 ownerShare = future.futurePrice * (future.percentage - 1) / 100;
        uint256 investorShare = future.futurePrice - ownerShare;
        (bool r1, ) = _owner.call{value:ownerShare}("");
        require(r1,"Tx failed.");
        (bool r2, ) = _investor.call{value:investorShare}("");
        require(r2,"Tx failed.");
        IERC721(future.asset).safeTransferFrom(address(this),msg.sender, future.id);
        future.state = 2;
    }

    function withdraw (uint256 _index) external {
        Future storage future = futures[_index];
        if (block.timestamp > future.expiry && future.state == 0) {
            require(msg.sender == future.owner, "");
        } else if (block.timestamp > future.expiry && future.state == 1) {
            require(msg.sender == future.investor, "");
        }
        IERC721(future.asset).safeTransferFrom(address(this),msg.sender, future.id);
        future.state = 3;
    }

    function updateFuture (
        uint256 _index,
        address _asset,
        uint256 _id,
        uint256 _expiry,
        uint256 _percentage,
        uint256 _price,
        uint256 _futurePrice) external {
        Future storage future = futures[_index];
        require(future.state == 0, "You shall not change thy deal.");
        future.asset = _asset;
        future.id = _id;
        future.expiry = _expiry;
        future.percentage = _percentage;
        future.price = _price;
        future.futurePrice = _futurePrice;
    }

    function removeFuture (uint256 _index) external {
        Future storage future = futures[_index];
        require(msg.sender == future.owner, "Only owner.");
        require(future.state == 0, "You have an investor onboard.");
        futures[_index] = futures[futures.length -1];
        futures.pop();
    }

    function getFuturesLength() external view returns(uint256){
        return futures.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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