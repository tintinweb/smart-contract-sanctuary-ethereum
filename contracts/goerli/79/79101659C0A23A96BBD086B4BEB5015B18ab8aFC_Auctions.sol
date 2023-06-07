/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

contract Auctions {
    struct Schema {
        address owner;
        uint256 startBlock;
        uint256 endBlock;
        bool canceled;
        uint256 highestBindingBid;
        address highestBidder;
        bool ownerHasWithdrawn;
    }

    struct Bids {
        address walletAddress;
        uint256 bidAmount;
    }

    mapping(address => mapping(uint256 => Schema)) public _auctions;
    mapping(address => mapping(uint256 => Bids[])) public _bids;
    mapping(address => uint256) public fundsByBidder;

    event LogBid(
        address bidder,
        uint256 bid,
        address highestBidder,
        uint256 highestBid,
        uint256 highestBindingBid
    );
    event LogWithdrawal(
        address withdrawer,
        address withdrawalAccount,
        uint256 amount
    );
    event AuctionSettled(
        address nftContractAddress,
        uint256 tokenId,
        address auctionSettler
    );
    event LogCanceled();

    function Auction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _startBlock,
        uint256 _endBlock
    ) public {
        // require(
        //     _startBlock < _endBlock,
        //     "Start Block should be greater then or equal to End Block"
        // );
        // require(
        //     _startBlock > block.timestamp,
        //     "Start Block should be less then current block"
        // );

        _auctions[_nftContractAddress][_tokenId].owner = msg.sender;
        _auctions[_nftContractAddress][_tokenId].startBlock = _startBlock;
        _auctions[_nftContractAddress][_tokenId].endBlock = _endBlock;
    }

    function getHighestBid(
        uint256 _tokenId,
        address _nftContractAddress
    ) public view returns (uint256) {
        return
            fundsByBidder[
                _auctions[_nftContractAddress][_tokenId].highestBidder
            ];
    }

    function placeBid(
        uint256 _tokenId,
        address _nftContractAddress
    )
        public
        payable
        onlyAfterStart(_auctions[_nftContractAddress][_tokenId].startBlock)
        onlyBeforeEnd(_auctions[_nftContractAddress][_tokenId].endBlock)
        onlyNotCanceled(_auctions[_nftContractAddress][_tokenId].canceled)
        onlyNotOwner(_auctions[_nftContractAddress][_tokenId].owner)
        returns (bool success)
    {
        // reject payments of 0 ETH
        require(msg.value > 0, "Amount shoul be greator then 0");

        // calculate the user's total bid based on the current amount they've sent to the contract
        // plus whatever has been sent with this transaction
        uint256 newBid = fundsByBidder[msg.sender] + msg.value;

        // if the user isn't even willing to overbid the highest binding bid, there's nothing for us
        // to do except revert the transaction.
        require(
            newBid >=
                _auctions[_nftContractAddress][_tokenId].highestBindingBid,
            "New Bid should be greator then or equal to highest bid"
        );

        // grab the previous highest bid (before updating fundsByBidder, in case msg.sender is the
        // highestBidder and is just increasing their maximum bid).
        uint256 highestBid = fundsByBidder[
            _auctions[_nftContractAddress][_tokenId].highestBidder
        ];

        fundsByBidder[msg.sender] = newBid;

        if (newBid <= highestBid) {
            // if the user has overbid the highestBindingBid but not the highestBid, we simply
            // increase the highestBindingBid and leave highestBidder alone.

            // note that this case is impossible if msg.sender == highestBidder because you can never
            // bid less ETH than you've already bid.

            _auctions[_nftContractAddress][_tokenId].highestBindingBid = min(
                newBid,
                highestBid
            );
        } else {
            // if msg.sender is already the highest bidder, they must simply be wanting to raise
            // their maximum bid, in which case we shouldn't increase the highestBindingBid.

            // if the user is NOT highestBidder, and has overbid highestBid completely, we set them
            // as the new highestBidder and recalculate highestBindingBid.

            if (
                msg.sender !=
                _auctions[_nftContractAddress][_tokenId].highestBidder
            ) {
                _auctions[_nftContractAddress][_tokenId].highestBidder = msg
                    .sender;
                _auctions[_nftContractAddress][_tokenId]
                    .highestBindingBid = min(newBid, highestBid);
            }
            highestBid = newBid;
        }
        Bids memory newBids = Bids(msg.sender, msg.value);
        _bids[_nftContractAddress][_tokenId].push(newBids);

        // emit LogBid(
        //     msg.sender,
        //     newBid,
        //     _auctions[_nftContractAddress][_tokenId].highestBidder,
        //     highestBid,
        //     _auctions[_nftContractAddress][_tokenId].highestBindingBid
        // );
        return true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a < b) return a;
        return b;
    }

    function cancelAuction(
        uint256 _tokenId,
        address _nftContractAddress
    )
        public
        onlyOwner(_auctions[_nftContractAddress][_tokenId].owner)
        onlyBeforeEnd(_auctions[_nftContractAddress][_tokenId].endBlock)
        onlyNotCanceled(_auctions[_nftContractAddress][_tokenId].canceled)
        returns (bool success)
    {
        _auctions[_nftContractAddress][_tokenId].canceled = true;
        emit LogCanceled();
        return true;
    }

    function getBids(
        address _nftContractAddress,
        uint256 tokenId
    ) public view returns (Bids[] memory) {
        return _bids[_nftContractAddress][tokenId];
    }

    function settleAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address ownerAddress
    )
        external
        onlyEndedOrCanceled(
            _auctions[_nftContractAddress][_tokenId].endBlock,
            _auctions[_nftContractAddress][_tokenId].canceled
        )
    {
        uint256 withdrawalAmount = _auctions[_nftContractAddress][_tokenId]
            .highestBindingBid;
        _auctions[_nftContractAddress][_tokenId].ownerHasWithdrawn = true;

        // send the funds
        require(
            payable(ownerAddress).send(withdrawalAmount),
            "Withdwawal Amount should be greator then 0"
        );

        IERC721(_nftContractAddress).transferFrom(
            address(ownerAddress),
            _auctions[_nftContractAddress][_tokenId].highestBidder,
            _tokenId
        );

        _resetAuction(_tokenId, _nftContractAddress);
        _resetBids(_tokenId, _nftContractAddress);
        emit AuctionSettled(_nftContractAddress, _tokenId, msg.sender);
    }

    function withdrawBid(
        uint256 _tokenId,
        address _nftContractAddress
    )
        public
        onlyEndedOrCanceled(
            _auctions[_nftContractAddress][_tokenId].endBlock,
            _auctions[_nftContractAddress][_tokenId].canceled
        )
        returns (bool success)
    {
        address withdrawalAccount;
        uint256 withdrawalAmount;

        withdrawalAccount = msg.sender;
        withdrawalAmount = fundsByBidder[withdrawalAccount];
        
        require(
            withdrawalAmount > 0,
            "Withdwawal Amount should be greator then 0"
        );

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;

        // send the funds
        require(
            payable(msg.sender).send(withdrawalAmount),
            "Withdwawal Amount should be greator then 0"
        );

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }

    function _resetAuction(
        uint256 _tokenId,
        address _nftContractAddress
    ) public {
        _auctions[_nftContractAddress][_tokenId].owner = address(0);
        _auctions[_nftContractAddress][_tokenId].startBlock = 0;
        _auctions[_nftContractAddress][_tokenId].endBlock = 0;
        _auctions[_nftContractAddress][_tokenId].canceled = false;
        _auctions[_nftContractAddress][_tokenId].highestBindingBid = 0;
        _auctions[_nftContractAddress][_tokenId].highestBidder = address(0);
        _auctions[_nftContractAddress][_tokenId].ownerHasWithdrawn = false;
    }

    function _resetBids(uint256 _tokenId, address _nftContractAddress) public {
        delete _bids[_nftContractAddress][_tokenId];
    }

    modifier onlyOwner(address owner) {
        require(msg.sender == owner, "Not owner!");
        _;
    }

    modifier onlyNotOwner(address owner) {
        require(msg.sender != owner, "owner!");
        _;
    }

    modifier onlyAfterStart(uint256 startBlock) {
        require(
            block.timestamp > startBlock,
            "Start block should be less then equal to current block!"
        );
        _;
    }

    modifier onlyBeforeEnd(uint256 endBlock) {
        require(
            block.timestamp < endBlock,
            "End block should be greator then equal to current block!"
        );
        _;
    }

    modifier onlyNotCanceled(bool canceled) {
        require(!canceled, "Cancelled!");
        _;
    }

    modifier onlyEndedOrCanceled(uint256 endBlock, bool canceled) {
        require(block.timestamp > endBlock || canceled, "Msg!");
        _;
    }
}