// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./IFragAuction.sol";

contract FragAuction is IFragAuction, IERC721Receiver {
    uint256 private auctionId;

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public sharesPerAuction;
    mapping(address => mapping(uint256 => uint256)) public userBidPerAuction;

    function startAuction(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minimalStep,
        uint256 _minimalPrice,
        uint256 _tokenId,
        address _nft,
        address[] calldata _shareholders,
        uint256[] calldata _shareValues
    ) external {
        require(
            _startTime >= block.timestamp &&
                _endTime >= _startTime + 1 hours &&
                _startTime <= block.timestamp + 31 days &&
                _endTime <= _startTime + 31 days,
            "Wrong duration parameters"
        );
        require(_shareholders.length < 10, "Shareholders length must be smaller than 10");
        require(_shareholders.length == _shareValues.length, "Shareholders and values length mismatch");

        uint256 actionId = getNextAndIncrementAuctionId();
        address creator = msg.sender;

        auctions[actionId] = Auction(
            _startTime,
            _endTime,
            _minimalStep,
            _minimalPrice,
            _tokenId,
            _nft,
            address(0),
            false,
            creator
        );

        uint256 sharesSum = 0;
        for (uint256 i = 0; i < _shareholders.length; i++) {
            require(_shareholders[i] != address(0), "Shareholder should be present");
            require(_shareValues[i] != 0, "Shares value should be > 0");

            sharesPerAuction[actionId][_shareholders[i]] += _shareValues[i];
            sharesSum += _shareValues[i];
        }
        require(sharesSum == 10000, "Shares sum different than 100%");

        IERC721(_nft).safeTransferFrom(creator, address(this), _tokenId);

        emit AuctionCreated(actionId, auctions[actionId]);
    }

    function putBid(uint256 _auctionId) external payable {
        require(isAuctionActive(_auctionId) == true, "Auction is nonexistent or not active");

        address user = msg.sender;
        Auction storage currentAuction = auctions[_auctionId];
        uint256 minAmount = getMinimalNextBid(_auctionId);

        uint256 userCurrentBid = userBidPerAuction[user][_auctionId];
        uint256 userTotalBid = userCurrentBid + msg.value;
        require(userTotalBid >= minAmount, "Bid amount too low");

        userBidPerAuction[user][_auctionId] = userTotalBid;
        currentAuction.winner = user;

        // If a user bids 15 minutes before the end of the auction
        // Increase the end with 15 minutes
        if (block.timestamp >= currentAuction.endTime - 15 minutes) {
            currentAuction.endTime += 15 minutes;
            emit DurationIncreased(_auctionId, currentAuction.endTime);
        }

        emit BidPlaced(_auctionId, user, userCurrentBid, userTotalBid);
    }

    function claimBid(uint256 _auctionId) external {
        address user = msg.sender;
        require(user != auctions[_auctionId].winner, "Winner cannot claim bid");

        uint256 userBid = userBidPerAuction[user][_auctionId];

        // Set user's bid to 0
        userBidPerAuction[user][_auctionId] = 0;

        // Transfer back the user's bid
        payable(address(user)).transfer(userBid);

        emit BidClaimed(_auctionId, user, userBid);
    }

    function claimReward(uint256 _auctionId, address _receiver) external {
        address user = msg.sender;
        Auction storage auction = auctions[_auctionId];
        require(auction.endTime < block.timestamp, "Auction must be finished");
        require(auction.rewardClaimed == false, "Reward is already claimed");
        require(user == auction.winner && user != address(0), "Only winner can claim reward");

        auction.rewardClaimed = true;

        // Transfer reward
        IERC721(auction.nft).safeTransferFrom(address(this), _receiver, auction.tokenId);

        emit RewardClaimed(_auctionId, _receiver);
    }

    function getRevenue(uint256 _auctionId) external {
        Auction memory auction = auctions[_auctionId];
        require(auction.endTime < block.timestamp, "Auction must be finished");

        address shareholder = msg.sender;
        uint256 feeValue = (userBidPerAuction[auction.winner][_auctionId] * sharesPerAuction[_auctionId][shareholder]) /
            10000;
        require(feeValue != 0, "Revenue is not available");

        sharesPerAuction[_auctionId][shareholder] = 0;

        payable(shareholder).transfer(feeValue);

        emit RevenueTransfered(_auctionId, shareholder, feeValue);
    }

    function getBackNFT(uint256 _auctionId) external {
        address creator = msg.sender;
        Auction storage auction = auctions[_auctionId];
        require(creator == auction.creator, "Only creator can get back reward");
        require(auction.endTime < block.timestamp, "Auction must be finished");
        require(auction.winner == address(0), "Auction must be unsuccessful");
        require(auction.rewardClaimed == false, "NFT is claimed");

        auction.rewardClaimed = true;

        // Transfer reward
        IERC721(auction.nft).safeTransferFrom(address(this), creator, auction.tokenId);

        emit RewardClaimed(_auctionId, creator);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getMinimalNextBid(uint256 _auctionId) internal view returns (uint256 minBid) {
        Auction memory currentAuction = auctions[_auctionId];
        if (userBidPerAuction[currentAuction.winner][_auctionId] == 0) {
            minBid = currentAuction.minimalPrice;
        } else {
            minBid = userBidPerAuction[currentAuction.winner][_auctionId] + currentAuction.minimalStep;
        }
    }

    function isAuctionActive(uint256 _auctionId) internal view returns (bool) {
        uint256 currentTime = block.timestamp;
        Auction memory currentAuction = auctions[_auctionId];
        if ((currentTime >= currentAuction.startTime) && (currentTime <= currentAuction.endTime)) {
            return true;
        }
        return false;
    }

    function getNextAndIncrementAuctionId() internal returns (uint256) {
        return auctionId++;
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
pragma solidity 0.8.9;

interface IFragAuction {
    struct Auction {
        uint256 startTime;
        uint256 endTime;
        uint256 minimalStep;
        uint256 minimalPrice;
        uint256 tokenId;
        address nft;
        address winner;
        bool rewardClaimed;
        address creator;
    }

    event AuctionCreated(uint256 indexed id, Auction auction);
    event BidPlaced(uint256 indexed id, address indexed user, uint256 oldBid, uint256 newBid);
    event DurationIncreased(uint256 indexed id, uint256 endTime);
    event BidClaimed(uint256 indexed id, address indexed user, uint256 bid);
    event RewardClaimed(uint256 indexed id, address indexed receiver);
    event RevenueTransfered(uint256 indexed id, address indexed shareholder, uint256 amount);

    function startAuction(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minimalStep,
        uint256 _minimalPrice,
        uint256 _tokenId,
        address _nft,
        address[] calldata _shareholders,
        uint256[] calldata _shareValues
    ) external;

    function putBid(uint256 _auctionId) external payable;

    function claimBid(uint256 _auctionId) external;

    function claimReward(uint256 _auctionId, address _receiver) external;

    function getRevenue(uint256 _auctionId) external;

    function getBackNFT(uint256 _auctionId) external;
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