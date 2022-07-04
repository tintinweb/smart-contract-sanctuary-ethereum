//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract EnglishAuction is IERC721Receiver {
    mapping(address => mapping(uint256 => Auction)) public auctionInfo;

    enum Status {
        NOT_ACTIVE,
        WAIT,
        ACTIVE
    }

    struct Auction {
        address seller;
        address ownerNft;
        address erc20Token;
        uint256 minBid;
        uint256 maxBid;
        address bidderWallet;
        uint128 startAt;
        uint128 endAt;
        uint8 status;
    }

    event ERC721Received(
        uint256 indexed nftId,
        address indexed nftContract,
        address from
    );

    event ListOnAuction(
        uint256 indexed nftId,
        address indexed nftContract,
        address seller,
        address erc20Token,
        uint256 minBid,
        uint128 startAt,
        uint128 endAt
    );

    event Bid(
        uint256 indexed nftId,
        address indexed nftContract,
        address bidder,
        uint256 bid
    );

    event Finish(
        uint256 indexed nftId,
        address indexed nftContract,
        address seller,
        address nftOwner
    );

    event Withdraw(
        uint256 indexed nftId,
        address indexed nftContract,
        address to
    );

    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata
    ) external virtual override returns (bytes4) {
        Auction storage auction = auctionInfo[msg.sender][_tokenId];

        require(
            address(this) == IERC721(msg.sender).ownerOf(_tokenId),
            "Auction: NFT not received!"
        );

        auction.seller = _from;
        auction.ownerNft = _from;

        emit ERC721Received(_tokenId, msg.sender, _from);

        return this.onERC721Received.selector;
    }

    function listOnAuction(
        uint256 _nftId,
        address _nftContract,
        address _erc20Token,
        uint256 _minBid,
        uint128 _startAt,
        uint128 _endAt
    ) external returns (Auction memory) {
        require(_nftContract != address(0), "Auction: NFT is zero address!");

        Auction storage auction = auctionInfo[_nftContract][_nftId];

        require(
            auction.status == uint8(Status.NOT_ACTIVE),
            "Auction: NFT listed!"
        );

        require(auction.seller == msg.sender, "Auction: not owner NFT!");

        require(_startAt > block.timestamp, "Auction: start at less than now!");

        require(_startAt < _endAt, "Auction: end at less than start at!");

        auction.erc20Token = _erc20Token;
        auction.minBid = _minBid;
        auction.startAt = _startAt;
        auction.endAt = _endAt;
        auction.status = uint8(Status.WAIT);

        emit ListOnAuction(
            _nftId,
            _nftContract,
            msg.sender,
            _erc20Token,
            _minBid,
            _startAt,
            _endAt
        );

        return auction;
    }

    function placeBid(
        uint256 _nftId,
        address _nftContract,
        uint256 _bid
    ) external returns (bool) {
        Auction storage auction = auctionInfo[_nftContract][_nftId];

        require(msg.sender != auction.seller, "Auction: forbidden for owner!");

        if (
            auction.status == uint8(Status.WAIT) &&
            auction.startAt < block.timestamp &&
            auction.endAt > block.timestamp
        ) {
            auction.status = uint8(Status.ACTIVE);
        }

        require(auction.status == uint8(Status.ACTIVE), "Auction: not active!");

        require(_bid > auction.minBid, "Auction: bid less than minimum!");
        require(_bid > auction.maxBid, "Auction: bid less than maximum!");

        if (auction.bidderWallet != address(0)) {
            IERC20(auction.erc20Token).transfer(
                auction.bidderWallet,
                auction.maxBid
            );
        }

        IERC20(auction.erc20Token).transferFrom(
            msg.sender,
            address(this),
            _bid
        );

        auction.bidderWallet = msg.sender;
        auction.maxBid = _bid;

        emit Bid(_nftId, _nftContract, msg.sender, _bid);

        return true;
    }

    function finishAuction(uint256 _nftId, address _nftContract) external {
        Auction storage auction = auctionInfo[_nftContract][_nftId];

        require(
            (auction.endAt < block.timestamp &&
                (auction.status == uint8(Status.ACTIVE) ||
                    auction.status == uint8(Status.WAIT))),
            "Auction: cannot finish now!"
        );

        auction.status = uint8(Status.NOT_ACTIVE);

        if (auction.maxBid > 0) {
            IERC20(auction.erc20Token).transfer(auction.seller, auction.maxBid);

            auction.ownerNft = auction.bidderWallet;
            auction.maxBid = 0;
            auction.bidderWallet = address(0);
        }

        emit Finish(_nftId, _nftContract, auction.seller, auction.ownerNft);
    }

    function withdrawNft(uint256 _nftId, address _nftContract) external {
        Auction storage auction = auctionInfo[_nftContract][_nftId];

        require(auction.ownerNft != address(0), "Auction: not exist!");

        require(
            auction.status == uint8(Status.NOT_ACTIVE),
            "Auction: not finished!"
        );

        require(auction.ownerNft == msg.sender, "Auction: not owner NFT!");

        delete auctionInfo[_nftContract][_nftId];

        IERC721(_nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            _nftId
        );

        emit Withdraw(_nftId, _nftContract, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
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