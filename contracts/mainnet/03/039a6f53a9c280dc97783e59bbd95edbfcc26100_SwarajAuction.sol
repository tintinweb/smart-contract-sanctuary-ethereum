/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT

//  $$$$$$\  $$\      $$\  $$$$$$\  $$$$$$$\   $$$$$$\     $$$$$\
// $$  __$$\ $$ | $\  $$ |$$  __$$\ $$  __$$\ $$  __$$\    \__$$ |
// $$ /  \__|$$ |$$$\ $$ |$$ /  $$ |$$ |  $$ |$$ /  $$ |      $$ |
// \$$$$$$\  $$ $$ $$\$$ |$$$$$$$$ |$$$$$$$  |$$$$$$$$ |      $$ |
//  \____$$\ $$$$  _$$$$ |$$  __$$ |$$  __$$< $$  __$$ |$$\   $$ |
// $$\   $$ |$$$  / \$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |
// \$$$$$$  |$$  /   \$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |\$$$$$$  |
//  \______/ \__/     \__|\__|  \__|\__|  \__|\__|  \__| \______/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: Auction.sol

pragma solidity ^0.8.7;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

contract SwarajAuction is ReentrancyGuard, IERC721Receiver {
    struct SingleSong {
        mapping(address => uint) bids;
        uint highestBid;
        address highestBidder;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    mapping(uint => SingleSong) public AuctionHouse;

    mapping(address => uint) public totalBidsOnCollection;

    event Start();
    event BidPlaced(uint nftID, address placedBy, uint amount);
    event Withdraw(address withdrawnBy, uint amount);
    event End(uint nftID, address winner, uint winningBid);

    IERC721 public nft;
    uint public totalTokens;
    address payable public seller;
    address[] creatorSplits;

    uint public startingBid;
    uint public endAt;
    bool public started;
    bool public ended;
    uint public totalFundsBidded;
    uint public totalFundsCollected;

    constructor() {
        seller = payable(msg.sender); // initializing
    }

    function start(
        address _nft, // Contract address of NFTs
        uint _totalTokens, // Amount of NFTs
        uint _startingBid, // starting price of NFT
        address[] memory _creatorSplits
    ) external onlySeller {
        require(!started, "Started Already");
        nft = IERC721(_nft);
        totalTokens = _totalTokens;
        startingBid = _startingBid * 1 wei;
        creatorSplits = _creatorSplits;
        started = true;
        endAt = block.timestamp + 7 days;
        emit Start();
    }

    function bid(uint _nftID) external payable onlyAfterStart {
        require(block.timestamp < endAt, "The Auction has Ended");
        require(_nftID < totalTokens, "Wrong NFT ID");

        if (AuctionHouse[_nftID].highestBid == 0) {
            require(AuctionHouse[_nftID].highestBidder == address(0));
            require(msg.value >= startingBid, "Your Bid value is low");

            AuctionHouse[_nftID].highestBidder = msg.sender;
            AuctionHouse[_nftID].highestBid = msg.value;

            AuctionHouse[_nftID].bids[msg.sender] += msg.value;
        } else {
            if (msg.value > AuctionHouse[_nftID].highestBid) {
                AuctionHouse[_nftID].highestBidder = msg.sender;
                AuctionHouse[_nftID].highestBid = msg.value;

                AuctionHouse[_nftID].bids[msg.sender] += msg.value;
            } else {
                require(
                    AuctionHouse[_nftID].bids[msg.sender] + msg.value >
                        AuctionHouse[_nftID].highestBid,
                    "Your Bid is lower"
                );

                AuctionHouse[_nftID].bids[msg.sender] += msg.value;
                AuctionHouse[_nftID].highestBidder = msg.sender;
                AuctionHouse[_nftID].highestBid = AuctionHouse[_nftID].bids[
                    msg.sender
                ];
            }
        }

        totalBidsOnCollection[msg.sender] += msg.value;
        totalFundsBidded += msg.value;
        emit BidPlaced(_nftID, msg.sender, AuctionHouse[_nftID].highestBid);
    }

    function end() external onlySeller onlyAfterStart {
        require(!ended, "Auction has already ended!");
        require(block.timestamp >= endAt, "The auction is still on!");

        ended = true;

        for (uint i = 0; i < totalTokens; i++) {
            if (AuctionHouse[i].highestBidder != address(0)) {
                totalBidsOnCollection[
                    AuctionHouse[i].highestBidder
                ] -= AuctionHouse[i].highestBid;
                nft.safeTransferFrom(
                    address(this),
                    AuctionHouse[i].highestBidder,
                    i
                );
                totalFundsCollected += AuctionHouse[i].highestBid;
                payable(creatorSplits[i]).transfer(AuctionHouse[i].highestBid);
                emit End(
                    i,
                    AuctionHouse[i].highestBidder,
                    AuctionHouse[i].highestBid
                );
            } else {
                nft.safeTransferFrom(address(this), seller, i);
            }
        }
    }

    function withdrawFundsForParticpants() public onlyAfterEnd {
        uint value = totalBidsOnCollection[msg.sender];
        totalBidsOnCollection[msg.sender] = 0;
        payable(msg.sender).transfer(value);
        emit Withdraw(msg.sender, value);
    }

    // Modifiers
    /////////////////////////////////////////

    modifier onlySeller() {
        require(msg.sender == seller, "Can only be called by seller");
        _;
    }

    modifier onlyAfterStart() {
        require(started, "Auction not started yet");
        _;
    }

    modifier onlyAfterEnd() {
        require(ended, "Auction not ended yet or end has not been called");
        _;
    }
}