// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC721.sol";

contract Auction {
    address constant WETH = 0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15;

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

    event BidCanceled(
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

    function bid(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _bidAmount
    )
        external
        ifOngoing(_nftContractAddress, _tokenId)
        checkBidAmount(_nftContractAddress, _tokenId, _bidAmount)
        notSeller(_nftContractAddress, _tokenId, msg.sender)
        ifApprovedWeth(msg.sender, _bidAmount)
    {
        auctionBids[_nftContractAddress][_tokenId][msg.sender] = _bidAmount;
        allAuctions[_nftContractAddress][_tokenId].highestBid = _bidAmount;
        allAuctions[_nftContractAddress][_tokenId].highestBidder = msg.sender;

        emit BidMade(_nftContractAddress, _tokenId, _bidAmount, msg.sender);
    }

    function cancelAuction(address _nftContractAddress, uint256 _tokenId)
        external
        ifOngoing(_nftContractAddress, _tokenId)
        onlySeller(_nftContractAddress, _tokenId)
    {
        _reset(_nftContractAddress, _tokenId);

        emit AuctionCanceled(_nftContractAddress, _tokenId);
    }

    // ------------
    modifier ifApprovedWeth(address _owner, uint256 _amount) {
        require(
            IERC20(WETH).allowance(_owner, address(this)) >= _amount,
            "The amount is not approved!"
        );
        _;
    }

    modifier ifApprovedNft(address _nftContractAddress, uint256 _tokenId) {
        require(
            IERC721(_nftContractAddress).getApproved(_tokenId) == address(this),
            "The NFT is not approved!"
        );
        _;
    }

    modifier notSeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _sender
    ) {
        require(
            _sender != allAuctions[_nftContractAddress][_tokenId].seller,
            "The seller can not bid!"
        );
        _;
    }

    // ------------

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
        //        ifApprovedNft(_nftContractAddress, _tokenId)

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

        if (highestBid != 0 && highestBidder != address(0)) {
            _transferNft(_nftContractAddress, _tokenId, seller, highestBidder);
            _transferWeth(highestBidder, seller, highestBid);
        }

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

    function cancelBid(address _nftContractAddress, uint256 _tokenId)
        external
        onlyBidder(_nftContractAddress, _tokenId)
    {
        auctionBids[_nftContractAddress][_tokenId][msg.sender] = 0;

        emit BidCanceled(_nftContractAddress, _tokenId, msg.sender);
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

    function _transferWeth(
        address _from,
        address _to,
        uint256 _amount
    ) private {
        IERC20(WETH).transferFrom(_from, _to, _amount);
    }

    function _transferNft(
        address _nftContractAddress,
        uint256 _tokenId,
        address _from,
        address _to
    ) private {
        IERC721(_nftContractAddress).safeTransferFrom(_from, _to, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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