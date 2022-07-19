// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interface/ILionsNotSheep.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// @author: olive


//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                              //
//                                                                                              //
//    ██╗     ███╗   ██╗███████╗     █████╗ ██╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗    //
//    ██║     ████╗  ██║██╔════╝    ██╔══██╗██║   ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║    //
//    ██║     ██╔██╗ ██║███████╗    ███████║██║   ██║██║        ██║   ██║██║   ██║██╔██╗ ██║    //
//    ██║     ██║╚██╗██║╚════██║    ██╔══██║██║   ██║██║        ██║   ██║██║   ██║██║╚██╗██║    //
//    ███████╗██║ ╚████║███████║    ██║  ██║╚██████╔╝╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║    //
//    ╚══════╝╚═╝  ╚═══╝╚══════╝    ╚═╝  ╚═╝ ╚═════╝  ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝    //
//                                                                                              //
//                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////                                                                  

contract LNSAuction is Ownable {
    struct Auction {
        uint256 id;
        string title;
        string description;
        uint256 currentAmount;
        uint256 minimumAmount;
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        uint256 totalBidAmount;
        address auctionOwner;
        address[] highestBidders;
        address[] bidders;
        bool auctionLive;
        uint256[] winnerTokens;
        uint256 numOfWinners;
        mapping(address => uint256[]) bidderToTokens;
        mapping(address => uint256) bidderIndices;
    }

    struct BidState {
        bool state;
        address tokenOwner;
    }

    Auction[] public auctions;

    uint256 public currentAuctionId = 0;
    mapping(address => bool) internal admins;
    mapping(uint256 => BidState) bidState;

    ILionsNotSheep public lionsNotSheep;

    modifier onlyAdmin() {
        require(admins[_msgSender()], "Caller is not the admin");
        _;
    }

    constructor(ILionsNotSheep _lionsNotSheep) {
        lionsNotSheep = _lionsNotSheep;
    }

    function createAuction(
        string memory title,
        string memory description,
        uint256 startTimeStamp,
        uint256 endTimeStamp,
        uint256 minimumAmount,
        uint256 numOfWinners
    ) external onlyAdmin {
        require(
            block.timestamp <= startTimeStamp && endTimeStamp > startTimeStamp,
            "LNSAuction: TimeStamp Error!"
        );

        require(
            minimumAmount >= 1,
            "LNSAuction: The Auction Bid amount should be greater than 1."
        );

        uint256 _id = auctions.length;
        auctions.push();

        Auction storage newAuction = auctions[_id];
        newAuction.id = currentAuctionId;
        newAuction.title = title;
        newAuction.description = description;
        newAuction.currentAmount = minimumAmount;
        newAuction.minimumAmount = minimumAmount;
        newAuction.auctionOwner = _msgSender();
        newAuction.startTimeStamp = startTimeStamp;
        newAuction.endTimeStamp = endTimeStamp;
        newAuction.numOfWinners = numOfWinners;
        newAuction.auctionLive = true;
        currentAuctionId++;
    }

    function flipLiveAuction(uint256 _id, bool _auctionLive) public onlyAdmin {
        require(
            _id < auctions.length,
            "LNSAuction: Auction Id does not exist."
        );
        Auction storage auction = auctions[_id];
        auction.auctionLive = _auctionLive;
    }

    function updateAuction(
        uint256 _id,
        string memory _title,
        string memory _description,
        uint256 _startTimeStamp,
        uint256 _endTimeStamp,
        uint256 _minimumAmount,
        uint256 _numOfWinners
    ) public onlyAdmin {
        require(
            _id < auctions.length,
            "LNSAuction: Auction Id does not exist."
        );
        Auction storage auction = auctions[_id];
        auction.title = _title;
        auction.description = _description;
        auction.startTimeStamp = _startTimeStamp;
        auction.endTimeStamp = _endTimeStamp;
        auction.minimumAmount = _minimumAmount;
        auction.numOfWinners = _numOfWinners;
    }

    function getAuctionInfo(uint256 _id)
        public
        view
        returns (
            uint256[] memory, // [id, minimum, current, start, end, total, numOfWinner]
            string memory, // title
            string memory, //description
            address[] memory, // bidder list
            address[] memory, // highest bidders
            uint256[] memory, //winner Tokens
            bool // auction live
        )
    {
        require(
            _id < auctions.length,
            "LNSAuction: Auction Id does not exist."
        );

        uint256[] memory auctionData = new uint256[](7);
        auctionData[0] = auctions[_id].id;
        auctionData[1] = auctions[_id].minimumAmount;
        auctionData[2] = auctions[_id].currentAmount;
        auctionData[3] = auctions[_id].startTimeStamp;
        auctionData[4] = auctions[_id].endTimeStamp;
        auctionData[5] = auctions[_id].totalBidAmount;
        auctionData[6] = auctions[_id].numOfWinners;

        return (
            auctionData,
            auctions[_id].title,
            auctions[_id].description,
            auctions[_id].bidders,
            auctions[_id].highestBidders,
            auctions[_id].winnerTokens,
            auctions[_id].auctionLive
        );
    }

    function getAuctionBidderInfo(uint256 _id, address _bidder)
        public
        view
        returns (uint256[] memory)
    {
        require(
            _id < auctions.length,
            "LNSAuction: Auction Id does not exist."
        );

        Auction storage auction = auctions[_id];

        return auction.bidderToTokens[_bidder];
    }

    function isBidder(uint256 _id, address bidder) public view returns (bool) {
        Auction storage auction = auctions[_id];
        for (uint256 i = 0; i < auction.bidders.length; i++) {
            if (bidder == auction.bidders[i]) {
                return true;
            }
        }
        return false;
    }

    function bidToAuction(uint256 _id, uint256[] memory tokenIds) external {
        require(
            _id < auctions.length,
            "LNSAuction: Auction Id does not exist."
        );
        require(
            tokenIds.length > 0,
            "LNSAuction: Token ids size should be greater than zero."
        );

        Auction storage auction = auctions[_id];

        require(
            block.timestamp >= auction.startTimeStamp &&
                block.timestamp <= auction.endTimeStamp,
            "LNSAuction: Timestamp Error!"
        );

        require(
            auction.bidderToTokens[_msgSender()].length + tokenIds.length >
                auction.currentAmount,
            "LNSAuction: Token amount should be greater than minimum amount of Auction."
        );

        for (uint256 a = 0; a < tokenIds.length; a++) {
            BidState memory _bidState = bidState[tokenIds[a]];
            require(!_bidState.state, "LNSAuction: Already bidded this token.");
            auction.bidderToTokens[_msgSender()].push(tokenIds[a]);
            IERC721(address(lionsNotSheep)).transferFrom(
                _msgSender(),
                address(this),
                tokenIds[a]
            );
            bidState[tokenIds[a]] = BidState(true, _msgSender());
        }

        auction.totalBidAmount += tokenIds.length;

        if (auction.highestBidders.length > auction.numOfWinners) {
            if (!isHighestBidder(auction.highestBidders, msg.sender)) {
                uint256 minIndices = 0;
                uint256 temp = auction
                    .bidderToTokens[auction.highestBidders[0]]
                    .length;
                for (uint256 i = 1; i < auction.highestBidders.length; i++) {
                    if (
                        temp >
                        auction.bidderToTokens[auction.highestBidders[i]].length
                    ) {
                        temp = auction
                            .bidderToTokens[auction.highestBidders[i]]
                            .length;
                        minIndices = i;
                    }
                }
                address lastHighestBidder = auction.highestBidders[
                    auction.highestBidders.length - 1
                ];
                auction.highestBidders[minIndices] = lastHighestBidder;
                auction.highestBidders.pop();
                auction.highestBidders.push(_msgSender());
            }
        } else {
            if (!isHighestBidder(auction.highestBidders, msg.sender)) {
                auction.highestBidders.push(_msgSender());
            }
        }

        if (!isBidder(_id, _msgSender())) {
            auction.bidderIndices[_msgSender()] = auction.bidders.length;
            auction.bidders.push(_msgSender());
        }
        auction.currentAmount = auction.bidderToTokens[_msgSender()].length;
    }

    function claimFromAuction(uint256 _id) external {
        require(
            _id < auctions.length,
            "LNSAuction: Auction Id does not exist."
        );

        Auction storage auction = auctions[_id];

        uint256[] memory _tokenIds = auction.bidderToTokens[_msgSender()];
        require(
            _tokenIds.length > 0,
            "LNSAuction: You didn't bid any tokens in this auction."
        );

        for (uint256 a = 0; a < _tokenIds.length; a++) {
            BidState memory _bidState = bidState[_tokenIds[a]];
            require(
                _bidState.state,
                "LNSAuction: This token was not bid in any auction."
            );
            IERC721(address(lionsNotSheep)).safeTransferFrom(
                address(this),
                _msgSender(),
                _tokenIds[a]
            );
            bidState[_tokenIds[a]] = BidState(false, address(0));
        }

        auction.totalBidAmount -= _tokenIds.length;

        address lastBidder = auction.bidders[auction.bidders.length - 1];
        auction.bidders[auction.bidderIndices[_msgSender()]] = lastBidder;
        auction.bidderIndices[lastBidder] = auction.bidderIndices[_msgSender()];
        auction.bidders.pop();
        delete auction.bidderIndices[_msgSender()];

        if (isHighestBidder(auction.highestBidders, msg.sender)) {
            resetHighestBidder(_id, msg.sender);
        }
    }

    function resetHighestBidder(uint256 _id, address bidder) private {
        Auction storage auction = auctions[_id];
        uint256 bidderIndices = 0;
        for (uint256 i = 0; i < auction.highestBidders.length; i++) {
            if (auction.highestBidders[i] == bidder) {
                bidderIndices = i;
                break;
            }
        }
        address lastHighestBidder = auction.highestBidders[
            auction.highestBidders.length - 1
        ];
        auction.highestBidders[bidderIndices] = lastHighestBidder;
        auction.highestBidders.pop();
        if (
            auction.highestBidders.length > auction.numOfWinners &&
            auction.bidders.length >= auction.numOfWinners
        ) {
            address newHighestAddress;
            uint256 maxBidAmount = 0;
            for (uint256 j = 0; j < auction.bidders.length; j++) {
                if (
                    maxBidAmount <
                    auction.bidderToTokens[auction.bidders[j]].length &&
                    !isHighestBidder(auction.highestBidders, bidder)
                ) {
                    newHighestAddress = auction.bidders[j];
                    maxBidAmount = auction
                        .bidderToTokens[auction.bidders[j]]
                        .length;
                }
            }
            auction.highestBidders.push(newHighestAddress);
        }
    }

    function isHighestBidder(address[] memory _highestBidders, address _bidder)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _highestBidders.length; i++) {
            if (_highestBidders[i] == _bidder) {
                return true;
            }
        }
        return false;
    }

    function finishAuction(uint256 _id) external onlyAdmin {
        require(
            _id < auctions.length,
            "LNSAuction: Auction Id does not exist."
        );
        Auction storage auction = auctions[_id];
        auction.auctionLive = false;
        uint256 bidAmount = auction
            .bidderToTokens[auction.highestBidders[0]]
            .length;
        if (auction.highestBidders.length > 0) {
            for (uint256 i = 1; i < auction.highestBidders.length; i++) {
                if (
                    bidAmount >
                    auction.bidderToTokens[auction.highestBidders[i]].length
                ) {
                    bidAmount = auction
                        .bidderToTokens[auction.highestBidders[i]]
                        .length;
                }
            }
        }

        for (uint256 i = 0; i < auction.bidders.length; i++) {
            if (isHighestBidder(auction.highestBidders, auction.bidders[i])) {
                for (
                    uint256 j = 0;
                    j < auction.bidderToTokens[auction.bidders[i]].length;
                    j++
                ) {
                    if (j < bidAmount - 1) {
                        lionsNotSheep.burn(
                            auction.bidderToTokens[auction.bidders[i]][j]
                        );
                        bidState[
                            auction.bidderToTokens[auction.bidders[i]][j]
                        ] = BidState(false, address(0));
                    } else {
                        IERC721(address(lionsNotSheep)).safeTransferFrom(
                            address(this),
                            auction.bidders[i],
                            auction.bidderToTokens[auction.bidders[i]][j]
                        );
                        bidState[
                            auction.bidderToTokens[auction.bidders[i]][j]
                        ] = BidState(false, address(0));
                    }
                }
                auction.winnerTokens.push(
                    auction.bidderToTokens[auction.bidders[i]][bidAmount - 1]
                );
            } else {
                for (
                    uint256 k = 0;
                    k < auction.bidderToTokens[auction.bidders[i]].length;
                    k++
                ) {
                    IERC721(address(lionsNotSheep)).safeTransferFrom(
                        address(this),
                        auction.bidders[i],
                        auction.bidderToTokens[auction.bidders[i]][k]
                    );

                    bidState[
                        auction.bidderToTokens[auction.bidders[i]][k]
                    ] = BidState(false, address(0));
                }
            }
        }
    }

    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function hasAdminRole(address _address) external view returns (bool) {
        return admins[_address];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILionsNotSheep {
    function burn(uint256 tokenId) external;

    function giftMint(address[] memory _addrs, uint256[] memory _tokenAmounts)
        external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}