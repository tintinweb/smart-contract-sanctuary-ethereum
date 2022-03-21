// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC721Receiver.sol";

contract Auction is IERC721Receiver {
    struct AuctionInfo {
        uint64 startingTimestamp;
        uint64 endingTimestamp;
        uint256 startingPrice;
        uint256 highestBid;
        address highestBidder;
        address seller;
    }
    mapping(address => mapping(uint256 => AuctionInfo)) public allAuctions;
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public auctionBids;

    event AuctionCanceled(address nftContractAddress, uint256 tokenId);

    event AuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 startingPrice,
        uint64 startingTimestamp,
        uint64 endingTimestamp,
        address seller
    );

    event AuctionEnded(
        address nftContractAddress,
        uint256 tokenId,
        uint256 highestBid,
        address highestBidder
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        uint256 amount,
        address bidder
    );

    event BidWithdrawn(
        address nftContractAddress,
        uint256 _tokenId,
        address bidder
    );

    event EndingTimestampUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint64 endingTimestamp
    );

    event StartingPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 startingPrice
    );

    modifier auctionNotStarted(address _nftContractAddress, uint256 _tokenId) {
        require(
            allAuctions[_nftContractAddress][_tokenId].seller == address(0),
            "The auction already started by the owner"
        );
        _;
    }

    modifier checkBidAmount(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) {
        require(
            _amount > allAuctions[_nftContractAddress][_tokenId].highestBid,
            "The amount must be greater than the highest bid!"
        );
        require(
            _amount > allAuctions[_nftContractAddress][_tokenId].startingPrice,
            "The amount must be greater than the starting price!"
        );
        _;
    }

    modifier checkTimestamp(
        uint64 _startingTimestamp,
        uint64 _endingTimestamp
    ) {
        require(
            _startingTimestamp >= block.timestamp,
            "startingTimestamp must be greater than now!"
        );
        require(
            _endingTimestamp > _startingTimestamp,
            "endingTimestamp must be greater than startingTimestamp!"
        );
        _;
    }

    modifier ifEnded(address _nftContractAddress, uint256 _tokenId) {
        require(
            block.timestamp >
                allAuctions[_nftContractAddress][_tokenId].endingTimestamp,
            "The auction is not over!"
        );
        _;
    }

    modifier ifOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(
            block.timestamp <
                allAuctions[_nftContractAddress][_tokenId].endingTimestamp,
            "The auction is over!"
        );
        _;
    }

    modifier onlyBidder(address _nftContractAddress, uint256 _tokenId) {
        require(
            auctionBids[_nftContractAddress][_tokenId][msg.sender] > 0,
            "You did not bid any amount!"
        );
        _;
    }

    modifier onlyNftOwner(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender == IERC721(_nftContractAddress).ownerOf(_tokenId),
            "The sender doesn't own NFT!"
        );
        _;
    }

    modifier onlySeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender == allAuctions[_nftContractAddress][_tokenId].seller,
            "The sender is not the seller!"
        );
        _;
    }

    function bid(address _nftContractAddress, uint256 _tokenId)
        external
        payable
        ifOngoing(_nftContractAddress, _tokenId)
        checkBidAmount(_nftContractAddress, _tokenId, msg.value)
    {
        auctionBids[_nftContractAddress][_tokenId][msg.sender] = msg.value;
        allAuctions[_nftContractAddress][_tokenId].highestBid = msg.value;
        allAuctions[_nftContractAddress][_tokenId].highestBidder = msg.sender;

        emit BidMade(_nftContractAddress, _tokenId, msg.value, msg.sender);
    }

    function cancelAuction(address _nftContractAddress, uint256 _tokenId)
        external
        ifOngoing(_nftContractAddress, _tokenId)
        onlySeller(_nftContractAddress, _tokenId)
    {
        _reset(_nftContractAddress, _tokenId);
        _transferNft(_nftContractAddress, _tokenId, address(this), msg.sender);

        emit AuctionCanceled(_nftContractAddress, _tokenId);
    }

    function createAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint64 _startingTimestamp,
        uint64 _endingTimestamp
    )
        external
        onlyNftOwner(_nftContractAddress, _tokenId)
        auctionNotStarted(_nftContractAddress, _tokenId)
        checkTimestamp(_startingTimestamp, _endingTimestamp)
    {
        IERC721(_nftContractAddress).approve(address(this), _tokenId);

        _transferNft(_nftContractAddress, _tokenId, msg.sender, address(this));

        allAuctions[_nftContractAddress][_tokenId] = AuctionInfo(
            _startingTimestamp,
            _endingTimestamp,
            _startingPrice,
            0,
            address(0),
            msg.sender
        );

        emit AuctionCreated(
            _nftContractAddress,
            _tokenId,
            _startingPrice,
            _startingTimestamp,
            _endingTimestamp,
            msg.sender
        );
    }

    function endAuction(address _nftContractAddress, uint256 _tokenId)
        external
        ifEnded(_nftContractAddress, _tokenId)
    {
        address seller = allAuctions[_nftContractAddress][_tokenId].seller;
        address highestBidder = allAuctions[_nftContractAddress][_tokenId]
            .highestBidder;
        uint256 highestBid = allAuctions[_nftContractAddress][_tokenId]
            .highestBid;
        _reset(_nftContractAddress, _tokenId);

        _transferNft(
            _nftContractAddress,
            _tokenId,
            address(this),
            highestBidder
        );

        _withdraw(_nftContractAddress, _tokenId, seller, highestBid);

        emit AuctionEnded(
            _nftContractAddress,
            _tokenId,
            highestBid,
            highestBidder
        );
    }

    function updateEndingTimestamp(
        address _nftContractAddress,
        uint256 _tokenId,
        uint64 _newEndingTimestamp
    )
        external
        ifOngoing(_nftContractAddress, _tokenId)
        onlySeller(_nftContractAddress, _tokenId)
    {
        allAuctions[_nftContractAddress][_tokenId]
            .endingTimestamp = _newEndingTimestamp;

        emit EndingTimestampUpdated(
            _nftContractAddress,
            _tokenId,
            _newEndingTimestamp
        );
    }

    function updateStartingPrice(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _newStartingPrice
    )
        external
        ifOngoing(_nftContractAddress, _tokenId)
        onlySeller(_nftContractAddress, _tokenId)
    {
        allAuctions[_nftContractAddress][_tokenId]
            .startingPrice = _newStartingPrice;

        emit StartingPriceUpdated(
            _nftContractAddress,
            _tokenId,
            _newStartingPrice
        );
    }

    function withdrawBid(address _nftContractAddress, uint256 _tokenId)
        external
        onlyBidder(_nftContractAddress, _tokenId)
    {
        uint256 amount = auctionBids[_nftContractAddress][_tokenId][msg.sender];
        auctionBids[_nftContractAddress][_tokenId][msg.sender] = 0;
        _withdraw(_nftContractAddress, _tokenId, msg.sender, amount);

        emit BidWithdrawn(_nftContractAddress, _tokenId, msg.sender);
    }

    function _reset(address _nftContractAddress, uint256 _tokenId) private {
        allAuctions[_nftContractAddress][_tokenId] = AuctionInfo(
            0,
            0,
            0,
            0,
            address(0),
            address(0)
        );
    }

    function _transferNft(
        address _nftContractAddress,
        uint256 _tokenId,
        address _from,
        address _to
    ) private {
        IERC721(_nftContractAddress).safeTransferFrom(_from, _to, _tokenId);
    }

    function _withdraw(
        address _nftContractAddress,
        uint256 _tokenId,
        address _to,
        uint256 _amount
    ) private {
        payable(_to).transfer(_amount);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public override returns (bytes4) {
        return 0x150b7a02;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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