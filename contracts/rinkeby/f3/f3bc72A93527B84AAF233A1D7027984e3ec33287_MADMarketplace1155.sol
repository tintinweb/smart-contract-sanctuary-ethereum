// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/* 
DISCLAIMER: 
This contract hasn't been audited yet. Most likely contains unexpected bugs. 
Don't trust your funds to be held by this code before the final thoroughly tested and audited version release.
*/

/// @author Modified from NFTEX
/// (https://github.com/TheGreatHB/NFTEX/blob/main/contracts/NFTEX.sol)

import { MAD } from "./MAD.sol";
import { MarketplaceEventsAndErrors1155, FactoryVerifier, IERC1155 } from "./EventsAndErrors.sol";
import { Types } from "./Types.sol";
import { Pausable } from "./lib/security/Pausable.sol";
import { Owned } from "./lib/auth/Owned.sol";
import { ERC1155Holder } from "./lib/tokens/ERC1155/Base/utils/ERC1155Holder.sol";
import { SafeTransferLib } from "./lib/utils/SafeTransferLib.sol";

contract MADMarketplace1155 is
    MAD,
    MarketplaceEventsAndErrors1155,
    ERC1155Holder,
    Owned(msg.sender),
    Pausable
{
    using Types for Types.Order1155;

    /// @dev Function Signature := 0x06fdde03
    function name()
        public
        pure
        override(MAD)
        returns (string memory)
    {
        assembly {
            mstore(0x20, 0x20)
            mstore(0x46, 0x066D61726B6574)
            return(0x20, 0x60)
        }
    }

    ////////////////////////////////////////////////////////////////
    //                           STORAGE                          //
    ////////////////////////////////////////////////////////////////

    // uint256 constant NAME_SLOT =
    // 0x8b30951df380b6b10da747e1167dd8e40bf8604c88c75b245dc172767f3b7320;

    /// @dev token => id => amount => orderID[]
    mapping(IERC1155 => mapping(uint256 => mapping(uint256 => bytes32[])))
        public orderIdByToken;
    /// @dev seller => orderID
    mapping(address => bytes32[]) public orderIdBySeller;
    /// @dev orderID => order details
    mapping(bytes32 => Types.Order1155) public orderInfo;

    uint16 public constant feePercent = 20000;
    uint256 public minOrderDuration;
    uint256 public minAuctionIncrement;
    uint256 public minBidValue;

    address public recipient;
    FactoryVerifier public MADFactory1155;

    ////////////////////////////////////////////////////////////////
    //                         CONSTRUCTOR                        //
    ////////////////////////////////////////////////////////////////

    constructor(
        address _recipient,
        uint256 _minOrderDuration,
        FactoryVerifier _factory
    ) {
        recipient = _recipient;
        minOrderDuration = _minOrderDuration;
        minAuctionIncrement = 300; // 5min
        minBidValue = 20; // 5% (1/20th)

        MADFactory1155 = _factory;
    }

    ////////////////////////////////////////////////////////////////
    //                           USER FX                          //
    ////////////////////////////////////////////////////////////////

    /// @notice Fixed Price listing order public pusher.
    /// @dev Function Signature := 0x40b78b0f
    function fixedPrice(
        IERC1155 _token,
        uint256 _id,
        uint256 _amount,
        uint256 _price,
        uint256 _endBlock
    ) public whenNotPaused {
        _makeOrder(
            0,
            _token,
            _id,
            _amount,
            _price,
            0,
            _endBlock
        );
    }

    /// @notice Dutch Auction listing order public pusher.
    /// @dev Function Signature := 0x205e409c
    function dutchAuction(
        IERC1155 _token,
        uint256 _id,
        uint256 _amount,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _endBlock
    ) public whenNotPaused {
        if (_startPrice <= _endPrice) revert ExceedsMaxEP();
        _makeOrder(
            1,
            _token,
            _id,
            _amount,
            _startPrice,
            _endPrice,
            _endBlock
        );
    }

    /// @notice English Auction listing order public pusher.
    /// @dev Function Signature := 0x47c4be17
    function englishAuction(
        IERC1155 _token,
        uint256 _id,
        uint256 _amount,
        uint256 _startPrice,
        uint256 _endBlock
    ) public whenNotPaused {
        _makeOrder(
            2,
            _token,
            _id,
            _amount,
            _startPrice,
            0,
            _endBlock
        );
    }

    /// @notice Bidding function available for English Auction only.
    /// @dev Function Signature := 0x957bb1e0
    /// @dev By default, bids must be at least 5% higher than the previous one.
    /// @dev By default, auction will be extended in 5 minutes if last bid is placed 5 minutes prior to auction's end.
    /// @dev 5 minutes eq to 300 mined blocks since block mining time is expected to take 1s in the harmony blockchain.
    function bid(bytes32 _order)
        external
        payable
        whenNotPaused
    {
        if (msg.value == 0) revert WrongPrice();

        Types.Order1155 storage order = orderInfo[_order];
        uint256 endBlock = order.endBlock;
        uint256 lastBidPrice = order.lastBidPrice;
        address lastBidder = order.lastBidder;

        if (order.orderType != 2) revert EAOnly();
        if (endBlock == 0) revert CanceledOrder();
        if (block.number > endBlock) revert Timeout();
        if (order.seller == msg.sender)
            revert InvalidBidder();

        if (
            msg.value <
            lastBidPrice + (lastBidPrice / minBidValue)
        ) revert WrongPrice();

        // 1s blocktime
        if (block.number > endBlock - minAuctionIncrement) {
            order.endBlock = endBlock + minAuctionIncrement;
        }

        order.lastBidder = msg.sender;
        order.lastBidPrice = msg.value;

        SafeTransferLib.safeTransferETH(
            lastBidder,
            lastBidPrice
        );

        emit Bid(
            order.token,
            order.tokenId,
            order.amount,
            _order,
            msg.sender,
            msg.value
        );
    }

    /// @notice Enables user to buy an nft for both Fixed Price and Dutch Auction listings
    /// @dev Function Signature := 0x9c9a1061
    function buy(bytes32 _order)
        external
        payable
        whenNotPaused
    {
        Types.Order1155 storage order = orderInfo[_order];
        uint256 endBlock = order.endBlock;
        if (endBlock == 0) revert CanceledOrder();
        if (endBlock <= block.number) revert Timeout();
        if (order.orderType == 2) revert NotBuyable();
        if (order.isSold == true) revert SoldToken();

        uint256 currentPrice = getCurrentPrice(_order);
        // price overrunning not accepted in fixed price and dutch auction
        if (msg.value != currentPrice) revert WrongPrice();

        order.isSold = true;

        // address _seller = order.seller;
        IERC1155 _token = order.token;

        // path for inhouse minted tokens
        if (
            MADFactory1155.creatorAuth(
                address(_token),
                order.seller
            ) == true
        ) {
            // load royalty info query to mem
            address _receiver;
            uint256 _amount;
            (_receiver, _amount) = _token.royaltyInfo(
                order.tokenId,
                currentPrice
            );

            // transfer royalties
            SafeTransferLib.safeTransferETH(
                _receiver,
                _amount
            );

            // transfer remaining value to seller
            SafeTransferLib.safeTransferETH(
                payable(order.seller),
                currentPrice - _amount
            );

            // path for external tokens
        } else {
            // case for external tokens with ERC2981 support
            if (
                _token.supportsInterface(0x2a55205a) == true
            ) {
                // load royalty info query to mem
                address _receiver;
                uint256 _amount;
                (_receiver, _amount) = _token.royaltyInfo(
                    order.tokenId,
                    currentPrice
                );

                // transfer royalties
                SafeTransferLib.safeTransferETH(
                    payable(_receiver),
                    _amount
                );

                // update price and transfer fee to recipient
                currentPrice = currentPrice - _amount;
                uint256 fee = (currentPrice * feePercent) /
                    10000;
                SafeTransferLib.safeTransferETH(
                    payable(recipient),
                    fee
                );

                // transfer remaining value to seller
                SafeTransferLib.safeTransferETH(
                    payable(order.seller),
                    currentPrice - fee
                );

                // case for external tokens without ERC2981 support
            } else {
                uint256 fee = (currentPrice * feePercent) /
                    10000;
                SafeTransferLib.safeTransferETH(
                    payable(recipient),
                    fee
                );
                SafeTransferLib.safeTransferETH(
                    payable(order.seller),
                    currentPrice - fee
                );
            }
        }

        // transfer token and emit event
        order.token.safeTransferFrom(
            address(this),
            msg.sender,
            order.tokenId,
            order.amount,
            ""
        );

        emit Claim(
            order.token,
            order.tokenId,
            order.amount,
            _order,
            order.seller,
            msg.sender,
            currentPrice
        );
    }

    /// @notice Pull method for NFT withdrawing in English Auction.
    /// @dev Function Signature := 0xbd66528a
    /// @dev Callable by both the seller and the auction winner.
    function claim(bytes32 _order) external whenNotPaused {
        Types.Order1155 storage order = orderInfo[_order];

        address seller = order.seller;
        address lastBidder = order.lastBidder;

        if (order.isSold == true) revert SoldToken();
        if (seller != msg.sender || lastBidder != msg.sender)
            revert AccessDenied();
        if (order.orderType != 2) revert EAOnly();
        if (block.number <= order.endBlock)
            revert NeedMoreTime();

        IERC1155 token = order.token;
        uint256 tokenId = order.tokenId;
        uint256 amount = order.amount;
        uint256 lastBidPrice = order.lastBidPrice;

        order.isSold = true;

        // address _seller = order.seller;
        IERC1155 _token = order.token;

        // path for inhouse minted tokens
        if (
            MADFactory1155.creatorAuth(
                address(_token),
                order.seller
            ) == true
        ) {
            // load royalty info query to mem
            address _receiver;
            uint256 _amount;
            (_receiver, _amount) = _token.royaltyInfo(
                order.tokenId,
                lastBidPrice
            );

            // transfer royalties
            SafeTransferLib.safeTransferETH(
                _receiver,
                _amount
            );

            // transfer remaining value to seller
            SafeTransferLib.safeTransferETH(
                payable(order.seller),
                lastBidPrice - _amount
            );

            // path for external tokens
        } else {
            // case for external tokens with ERC2981 support
            if (
                _token.supportsInterface(0x2a55205a) == true
            ) {
                // load royalty info query to mem
                address _receiver;
                uint256 _amount;
                (_receiver, _amount) = _token.royaltyInfo(
                    order.tokenId,
                    lastBidPrice
                );

                // transfer royalties
                SafeTransferLib.safeTransferETH(
                    payable(_receiver),
                    _amount
                );

                // update price and transfer fee to recipient
                uint256 newPrice = lastBidPrice - _amount;
                uint256 fee = (newPrice * feePercent) / 10000;
                SafeTransferLib.safeTransferETH(
                    payable(recipient),
                    fee
                );

                // transfer remaining value to seller
                SafeTransferLib.safeTransferETH(
                    payable(order.seller),
                    newPrice - fee
                );

                // case for external tokens without ERC2981 support
            } else {
                uint256 fee = (lastBidPrice * feePercent) /
                    10000;
                SafeTransferLib.safeTransferETH(
                    payable(recipient),
                    fee
                );
                SafeTransferLib.safeTransferETH(
                    payable(order.seller),
                    lastBidPrice - fee
                );
            }
        }

        token.safeTransferFrom(
            address(this),
            lastBidder,
            tokenId,
            amount,
            ""
        );

        emit Claim(
            token,
            tokenId,
            amount,
            _order,
            seller,
            lastBidder,
            lastBidPrice
        );
    }

    /// @notice Enables sellers to withdraw their tokens.
    /// @dev Function Signature := 0x7489ec23
    /// @dev Cancels order setting endBlock value to 0.
    function cancelOrder(bytes32 _order) external {
        Types.Order1155 storage order = orderInfo[_order];
        if (order.seller != msg.sender) revert AccessDenied();
        if (order.lastBidPrice != 0) revert BidExists();
        if (order.isSold == true) revert SoldToken();

        IERC1155 token = order.token;
        uint256 tokenId = order.tokenId;
        uint256 amount = order.amount;

        order.endBlock = 0;

        token.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );

        emit CancelOrder(
            token,
            tokenId,
            amount,
            _order,
            msg.sender
        );
    }

    receive() external payable {}

    ////////////////////////////////////////////////////////////////
    //                         OWNER FX                           //
    ////////////////////////////////////////////////////////////////

    /// @dev `MADFactory` instance setter.
    /// @dev Function Signature := 0x612990fe
    function setFactory(FactoryVerifier _factory)
        public
        onlyOwner
    {
        MADFactory1155 = _factory;

        emit FactoryUpdated(_factory);
    }

    /// @notice Marketplace config setter.
    /// @dev Function Signature := 0x0465c563
    /// @dev Time tracking criteria based on `blocknumber`.
    /// @param _minAuctionIncrement Min. time threshold for Auction extension.
    /// @param _minOrderDuration Min. order listing duration
    /// @param _minBidValue Min. value for a bid to be considered.
    function updateSettings(
        uint256 _minAuctionIncrement,
        uint256 _minOrderDuration,
        uint256 _minBidValue
    ) public onlyOwner {
        minOrderDuration = _minOrderDuration;
        minAuctionIncrement = _minAuctionIncrement;
        minBidValue = _minBidValue;
        emit AuctionSettingsUpdated(
            minOrderDuration,
            minAuctionIncrement,
            minBidValue
        );
    }

    /// @notice Paused state initializer for security risk mitigation pratice.
    /// @dev Function Signature := 0x8456cb59
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpaused state initializer for security risk mitigation pratice.
    /// @dev Function Signature := 0x3f4ba83a
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Enables the contract's owner to change recipient address.
    /// @dev Function Signature := 0x3bbed4a0
    function setRecipient(address _recipient)
        external
        onlyOwner
    {
        recipient = _recipient;
    }

    /// @dev Function Signature := 0x13af4035
    function setOwner(address newOwner)
        public
        override
        onlyOwner
    {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }

    /// @dev Function Signature := 0x3ccfd60b
    function withdraw() external onlyOwner whenPaused {
        SafeTransferLib.safeTransferETH(
            msg.sender,
            address(this).balance
        );
    }

    /// @notice Delete order function only callabe by contract's owner, when contract is paused, as security measure.
    /// @dev Function Signature := 0x0c026db9
    function delOrder(
        bytes32 hash,
        IERC1155 _token,
        uint256 _id,
        uint256 _amount,
        address _seller
    ) external onlyOwner whenPaused {
        delete orderInfo[hash];
        delete orderIdByToken[_token][_id][_amount];
        delete orderIdBySeller[_seller];

        // test if token is properly transfered back to it's owner
        _token.safeTransferFrom(
            address(this),
            _seller,
            _id,
            _amount,
            ""
        );
    }

    ////////////////////////////////////////////////////////////////
    //                        INTERNAL FX                         //
    ////////////////////////////////////////////////////////////////

    /// @notice Internal order path resolver.
    /// @dev Function Signature := 0x4ac079a6
    /// @param _orderType Values legend:
    /// 0=Fixed Price; 1=Dutch Auction; 2=English Auction.
    /// @param _endBlock Equals to canceled order when value is set to 0.
    function _makeOrder(
        uint8 _orderType,
        IERC1155 _token,
        uint256 _id,
        uint256 _amount,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _endBlock
    ) internal {
        if (
            _endBlock <= block.number &&
            _endBlock - block.number < minOrderDuration
        ) revert NeedMoreTime();
        if (_startPrice == 0) revert WrongPrice();

        bytes32 hash = _hash(
            _token,
            _id,
            _amount,
            msg.sender
        );
        orderInfo[hash] = Types.Order1155(
            _orderType,
            msg.sender,
            _token,
            _id,
            _amount,
            _startPrice,
            _endPrice,
            block.number,
            _endBlock,
            0,
            address(0),
            false
        );
        orderIdByToken[_token][_id][_amount].push(hash);
        orderIdBySeller[msg.sender].push(hash);

        _token.safeTransferFrom(
            msg.sender,
            address(this),
            _id,
            _amount,
            ""
        );

        emit MakeOrder(
            _token,
            _id,
            _amount,
            hash,
            msg.sender
        );
    }

    /// @notice Provides hash of an order used as an order info pointer
    /// @dev Function Signature := 0x3b1ce0d2
    function _hash(
        IERC1155 _token,
        uint256 _id,
        uint256 _amount,
        address _seller
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    block.number,
                    _token,
                    _id,
                    _amount,
                    _seller
                )
            );
    }

    ////////////////////////////////////////////////////////////////
    //                           VIEW FX                          //
    ////////////////////////////////////////////////////////////////

    /// @notice Works as price fetcher of listed tokens
    /// @dev Function Signature := 0x161e444e
    /// @dev Used for price fetching in buy function.
    function getCurrentPrice(bytes32 _order)
        public
        view
        returns (uint256)
    {
        Types.Order1155 storage order = orderInfo[_order];
        uint8 orderType = order.orderType;
        // Fixed Price
        if (orderType == 0) {
            return order.startPrice;
            // English Auction
        } else if (orderType == 2) {
            uint256 lastBidPrice = order.lastBidPrice;
            return
                lastBidPrice == 0
                    ? order.startPrice
                    : lastBidPrice;
        } else {
            // Ductch Auction
            uint256 _startPrice = order.startPrice;
            uint256 _startBlock = order.startBlock;
            uint256 tickPerBlock = (_startPrice -
                order.endPrice) /
                (order.endBlock - _startBlock);
            return
                _startPrice -
                ((block.number - _startBlock) * tickPerBlock);
        }
    }

    /// @notice Everything in storage can be fetch through the
    /// getters natively provided by all public mappings.
    /// @dev This public getter serve as a hook to ease frontend
    /// fetching whilst estimating `orderIdByToken` indexes by length.
    /// @dev Function Signature := 0x8c5ac795
    function tokenOrderLength(
        IERC1155 _token,
        uint256 _id,
        uint256 _amount
    ) external view returns (uint256) {
        return orderIdByToken[_token][_id][_amount].length;
    }

    /// @notice Everything in storage can be fetch through the
    /// getters natively provided by all public mappings.
    /// @dev This public getter serve as a hook to ease frontend
    /// fetching whilst estimating `orderIdBySeller` indexes by length.
    /// @dev Function Signature := 0x8aae982a
    function sellerOrderLength(address _seller)
        external
        view
        returns (uint256)
    {
        return orderIdBySeller[_seller].length;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/* 
DISCLAIMER: 
This contract hasn't been audited yet. Most likely contains unexpected bugs. 
Don't trust your funds to be held by this code before the final thoroughly tested and audited version release.
*/

pragma solidity 0.8.4;

///     ...     ..      ..                    ..
///   x*8888x.:*8888: -"888:                dF
///  X   48888X `8888H  8888               '88bu.
/// X8x.  8888X  8888X  !888>        u     '*88888bu
/// X8888 X8888  88888   "*8%-    us888u.    ^"*8888N
/// '*888!X8888> X8888  xH8>   [email protected] "8888"  beWE "888L
///   `?8 `8888  X888X X888>   9888  9888   888E  888E
///   -^  '888"  X888  8888>   9888  9888   888E  888E
///    dx '88~x. !88~  8888>   9888  9888   888E  888F
///  .8888Xf.888x:!    X888X.: 9888  9888  .888N..888
/// :""888":~"888"     `888*"  "888*""888"  `"888*""
///     "~'    "~        ""     ^Y"   ^Y'      ""     MADNFTs © 2022.

/// GNU AFFERO GENERAL PUBLIC LICENSE
/// Version 3, 19 November 2007
///
/// Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
/// Everyone is permitted to copy and distribute verbatim copies
/// of this license document, but changing it is not allowed.
///
/// (https://spdx.org/licenses/AGPL-3.0-only.html)

abstract contract MAD {
    function name()
        public
        pure
        virtual
        returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { FactoryVerifier } from "./lib/auth/FactoryVerifier.sol";
import { IERC721 } from "./Types.sol";
import { IERC1155 } from "./Types.sol";

interface FactoryEventsAndErrors721 {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event AmbassadorAdded(address indexed whitelistedAmb);
    event AmbassadorDeleted(address indexed removedAmb);
    event MarketplaceUpdated(address indexed newMarket);
    event RouterUpdated(address indexed newRouter);
    event SignerUpdated(address indexed newSigner);

    event SplitterCreated(
        address indexed creator,
        uint256[] shares,
        address[] payees,
        address splitter
    );

    event ERC721MinimalCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC721BasicCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC721WhitelistCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC721LazyCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0x00adecf0
    error SplitterFail();
}

interface FactoryEventsAndErrors1155 {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event AmbassadorAdded(address indexed whitelistedAmb);
    event AmbassadorDeleted(address indexed removedAmb);
    event MarketplaceUpdated(address indexed newMarket);
    event RouterUpdated(address indexed newRouter);
    event SignerUpdated(address indexed newSigner);

    event SplitterCreated(
        address indexed creator,
        uint256[] shares,
        address[] payees,
        address splitter
    );

    event ERC1155MinimalCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC1155BasicCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC1155WhitelistCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );
    event ERC1155LazyCreated(
        address indexed newSplitter,
        address indexed newCollection,
        address indexed newCreator
    );

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0x00adecf0
    error SplitterFail();
}

interface MarketplaceEventsAndErrors721 {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event FactoryUpdated(FactoryVerifier indexed newFactory);

    event AuctionSettingsUpdated(
        uint256 indexed newMinDuration,
        uint256 indexed newIncrement,
        uint256 indexed newMinBidValue
    );

    event MakeOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller
    );
    event CancelOrder(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller
    );
    event Bid(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address bidder,
        uint256 bidPrice
    );
    event Claim(
        IERC721 indexed token,
        uint256 id,
        bytes32 indexed hash,
        address seller,
        address taker,
        uint256 price
    );

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0xf7760f25
    error WrongPrice();
    /// @dev 0x90b8ec18
    error TransferFailed();
    /// @dev 0x0863b103
    error InvalidBidder();
    /// @dev 0xdf9428da
    error CanceledOrder();
    /// @dev 0x70f8f33a
    error ExceedsMaxEP();
    /// @dev 0x4ca88867
    error AccessDenied();
    /// @dev 0x921dbfec
    error NeedMoreTime();
    /// @dev 0x07ae5744
    error NotBuyable();
    /// @dev 0x3e0827ab
    error BidExists();
    /// @dev 0xf88b07a3
    error SoldToken();
    /// @dev 0x2af0c7f8
    error Timeout();
    /// @dev 0xffc96cb0
    error EAOnly();
}

interface MarketplaceEventsAndErrors1155 {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event FactoryUpdated(FactoryVerifier indexed newFactory);

    event AuctionSettingsUpdated(
        uint256 indexed newMinDuration,
        uint256 indexed newIncrement,
        uint256 indexed newMinBidValue
    );

    event MakeOrder(
        IERC1155 indexed token,
        uint256 id,
        uint256 amount,
        bytes32 indexed hash,
        address seller
    );
    event CancelOrder(
        IERC1155 indexed token,
        uint256 id,
        uint256 amount,
        bytes32 indexed hash,
        address seller
    );
    event Bid(
        IERC1155 indexed token,
        uint256 id,
        uint256 amount,
        bytes32 indexed hash,
        address bidder,
        uint256 bidPrice
    );
    event Claim(
        IERC1155 indexed token,
        uint256 id,
        uint256 amount,
        bytes32 indexed hash,
        address seller,
        address taker,
        uint256 price
    );

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    /// @dev 0xf7760f25
    error WrongPrice();
    /// @dev 0x90b8ec18
    error TransferFailed();
    /// @dev 0x0863b103
    error InvalidBidder();
    /// @dev 0xdf9428da
    error CanceledOrder();
    /// @dev 0x70f8f33a
    error ExceedsMaxEP();
    /// @dev 0x4ca88867
    error AccessDenied();
    /// @dev 0x921dbfec
    error NeedMoreTime();
    /// @dev 0x07ae5744
    error NotBuyable();
    /// @dev 0x3e0827ab
    error BidExists();
    /// @dev 0xf88b07a3
    error SoldToken();
    /// @dev 0x2af0c7f8
    error Timeout();
    /// @dev 0xffc96cb0
    error EAOnly();
}

interface RouterEvents {
    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    event TokenFundsWithdrawn(
        bytes32 indexed _id,
        uint8 indexed _type,
        address indexed _payee
    );

    event PublicMintState(
        bytes32 indexed _id,
        uint8 indexed _type,
        bool indexed _state
    );

    event WhitelistMintState(
        bytes32 indexed _id,
        uint8 indexed _type,
        bool indexed _state
    );

    event FreeClaimState(
        bytes32 indexed _id,
        uint8 indexed _type,
        bool indexed _state
    );

    event BaseURI(
        bytes32 indexed _id,
        string indexed _baseURI
    );
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

import { SplitterImpl } from "./lib/splitter/SplitterImpl.sol";
import { IERC721 } from "./lib/tokens/ERC721/Base/interfaces/IERC721.sol";
import { IERC1155 } from "./lib/tokens/ERC1155/Base/interfaces/IERC1155.sol";

// prettier-ignore
library Types {
    enum ERC721Type {
        ERC721Minimal,    // := 0
        ERC721Basic,      // := 1
        ERC721Whitelist,  // := 2
        ERC721Lazy        // := 3
    }
    
    enum ERC1155Type {
        ERC1155Minimal,    // := 0
        ERC1155Basic,      // := 1
        ERC1155Whitelist,  // := 2
        ERC1155Lazy        // := 3
    }

    struct Collection721 {
        address creator;
        Types.ERC721Type colType;
        bytes32 colSalt;
        uint256 blocknumber;
        address splitter;
    }

    struct Collection1155 {
        address creator;
        Types.ERC1155Type colType;
        bytes32 colSalt;
        uint256 blocknumber;
        address splitter;
    }

    struct SplitterConfig {
        address splitter;
        bytes32 splitterSalt;
        address ambassador;
        uint256 ambShare;
        bool valid;
    }

    struct Voucher {
        bytes32 voucherId;
        address[] users;
        uint256 amount;
        uint256 price;
    }

    struct UserBatch {
        bytes32 voucherId;
        uint256[] ids;
        uint256 price;
        address user;
    }

    /// @param orderType Values legend:
    /// 0=Fixed Price; 1=Dutch Auction; 2=English Auction.
    /// @param endBlock Equals to canceled order when value is set to 0.
    struct Order721 {
        uint8 orderType;
        address seller;
        IERC721 token;
        uint256 tokenId;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startBlock;
        uint256 endBlock;
        uint256 lastBidPrice;
        address lastBidder;
        bool isSold;
    }

    /// @param orderType Values legend:
    /// 0=Fixed Price; 1=Dutch Auction; 2=English Auction.
    /// @param endBlock Equals to canceled order when value is set to 0.
    struct Order1155 {
        uint8 orderType;
        address seller;
        IERC1155 token;
        uint256 tokenId;
        uint256 amount;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startBlock;
        uint256 endBlock;
        uint256 lastBidPrice;
        address lastBidder;
        bool isSold;
    }
}

/* 
    ├─ type: ContractDefinition
    ├─ name: Types
    ├─ baseContracts
    ├─ subNodes
    │  ├─ 0
    │  │  ├─ type: EnumDefinition
    │  │  ├─ name: ERC721Type
    │  │  └─ members
    │  │     ├─ 0
    │  │     │  ├─ type: EnumValue
    │  │     │  └─ name: ERC721Minimal
    │  │     ├─ 1
    │  │     │  ├─ type: EnumValue
    │  │     │  └─ name: ERC721Basic
    │  │     ├─ 2
    │  │     │  ├─ type: EnumValue
    │  │     │  └─ name: ERC721Whitelist
    │  │     └─ 3
    │  │        ├─ type: EnumValue
    │  │        └─ name: ERC721Lazy
    │  ├─ 1
    │  │  ├─ type: StructDefinition
    │  │  ├─ name: Collection
    │  │  └─ members
    │  │     ├─ 0
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: address
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: creator
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: creator
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 1
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: UserDefinedTypeName
    │  │     │  │  └─ namePath: Types.ERC721Type
    │  │     │  ├─ name: colType
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: colType
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 2
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: bytes32
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: colSalt
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: colSalt
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 3
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: uint256
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: blocknumber
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: blocknumber
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     └─ 4
    │  │        ├─ type: VariableDeclaration
    │  │        ├─ typeName
    │  │        │  ├─ type: UserDefinedTypeName
    │  │        │  └─ namePath: SplitterImpl
    │  │        ├─ name: splitter
    │  │        ├─ identifier
    │  │        │  ├─ type: Identifier
    │  │        │  └─ name: splitter
    │  │        ├─ storageLocation
    │  │        ├─ isStateVar: false
    │  │        ├─ isIndexed: false
    │  │        └─ expression
    │  ├─ 2
    │  │  ├─ type: StructDefinition
    │  │  ├─ name: SplitterConfig
    │  │  └─ members
    │  │     ├─ 0
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: UserDefinedTypeName
    │  │     │  │  └─ namePath: SplitterImpl
    │  │     │  ├─ name: splitter
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: splitter
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 1
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: bytes32
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: splitterSalt
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: splitterSalt
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 2
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: address
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: ambassador
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: ambassador
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 3
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: uint256
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: ambShare
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: ambShare
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     └─ 4
    │  │        ├─ type: VariableDeclaration
    │  │        ├─ typeName
    │  │        │  ├─ type: ElementaryTypeName
    │  │        │  ├─ name: bool
    │  │        │  └─ stateMutability
    │  │        ├─ name: valid
    │  │        ├─ identifier
    │  │        │  ├─ type: Identifier
    │  │        │  └─ name: valid
    │  │        ├─ storageLocation
    │  │        ├─ isStateVar: false
    │  │        ├─ isIndexed: false
    │  │        └─ expression
    │  ├─ 3
    │  │  ├─ type: StructDefinition
    │  │  ├─ name: Voucher
    │  │  └─ members
    │  │     ├─ 0
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: bytes32
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: voucherId
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: voucherId
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 1
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ArrayTypeName
    │  │     │  │  ├─ baseTypeName
    │  │     │  │  │  ├─ type: ElementaryTypeName
    │  │     │  │  │  ├─ name: address
    │  │     │  │  │  └─ stateMutability
    │  │     │  │  └─ length
    │  │     │  ├─ name: users
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: users
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     ├─ 2
    │  │     │  ├─ type: VariableDeclaration
    │  │     │  ├─ typeName
    │  │     │  │  ├─ type: ElementaryTypeName
    │  │     │  │  ├─ name: uint256
    │  │     │  │  └─ stateMutability
    │  │     │  ├─ name: amount
    │  │     │  ├─ identifier
    │  │     │  │  ├─ type: Identifier
    │  │     │  │  └─ name: amount
    │  │     │  ├─ storageLocation
    │  │     │  ├─ isStateVar: false
    │  │     │  ├─ isIndexed: false
    │  │     │  └─ expression
    │  │     └─ 3
    │  │        ├─ type: VariableDeclaration
    │  │        ├─ typeName
    │  │        │  ├─ type: ElementaryTypeName
    │  │        │  ├─ name: uint256
    │  │        │  └─ stateMutability
    │  │        ├─ name: price
    │  │        ├─ identifier
    │  │        │  ├─ type: Identifier
    │  │        │  └─ name: price
    │  │        ├─ storageLocation
    │  │        ├─ isStateVar: false
    │  │        ├─ isIndexed: false
    │  │        └─ expression
    │  └─ 4
    │     ├─ type: StructDefinition
    │     ├─ name: Order
    │     └─ members
    │        ├─ 0
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint8
    │        │  │  └─ stateMutability
    │        │  ├─ name: orderType
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: orderType
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 1
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: address
    │        │  │  └─ stateMutability
    │        │  ├─ name: seller
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: seller
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 2
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: UserDefinedTypeName
    │        │  │  └─ namePath: IERC721
    │        │  ├─ name: token
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: token
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 3
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: tokenId
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: tokenId
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 4
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: startPrice
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: startPrice
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 5
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: endPrice
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: endPrice
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 6
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: startBlock
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: startBlock
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 7
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: endBlock
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: endBlock
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 8
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: uint256
    │        │  │  └─ stateMutability
    │        │  ├─ name: lastBidPrice
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: lastBidPrice
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        ├─ 9
    │        │  ├─ type: VariableDeclaration
    │        │  ├─ typeName
    │        │  │  ├─ type: ElementaryTypeName
    │        │  │  ├─ name: address
    │        │  │  └─ stateMutability
    │        │  ├─ name: lastBidder
    │        │  ├─ identifier
    │        │  │  ├─ type: Identifier
    │        │  │  └─ name: lastBidder
    │        │  ├─ storageLocation
    │        │  ├─ isStateVar: false
    │        │  ├─ isIndexed: false
    │        │  └─ expression
    │        └─ 10
    │           ├─ type: VariableDeclaration
    │           ├─ typeName
    │           │  ├─ type: ElementaryTypeName
    │           │  ├─ name: bool
    │           │  └─ stateMutability
    │           ├─ name: isSold
    │           ├─ identifier
    │           │  ├─ type: Identifier
    │           │  └─ name: isSold
    │           ├─ storageLocation
    │           ├─ isStateVar: false
    │           ├─ isIndexed: false
    │           └─ expression
    └─ kind: library
 */

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @author Modified from OpenZeppelin Contracts
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol)

/// @dev Contract module which allows children to implement an emergency stop
/// mechanism that can be triggered by an authorized account.
/// This module is used through inheritance. It will make available the
/// modifiers `whenNotPaused` and `whenPaused`, which can be applied to
/// the functions of your contract. Note that they will not be pausable by
/// simply including this module, only once the modifiers are put in place.

abstract contract Pausable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "PAUSED");
        _;
    }

    modifier whenPaused() {
        require(paused(), "UNPAUSED");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(
        address indexed user,
        address indexed newOwner
    );

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner)
        public
        virtual
        onlyOwner
    {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @author Modified from OpenZeppelin Contracts
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/utils/ERC1155Holder.sol)

import { ERC1155TokenReceiver } from "../ERC1155B.sol";

contract ERC1155Holder is ERC1155TokenReceiver {
    /// @dev Implementation of the {ERC1155TokenReceiver} abstract contract
    /// that allows a contract to hold ERC1155 tokens.
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

import { ERC20 } from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount)
        internal
    {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(
                        eq(mload(0), 1),
                        gt(returndatasize(), 31)
                    ),
                    iszero(returndatasize())
                ),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(
                    gas(),
                    token,
                    0,
                    freeMemoryPointer,
                    100,
                    0,
                    32
                )
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(
                        eq(mload(0), 1),
                        gt(returndatasize(), 31)
                    ),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(
                    gas(),
                    token,
                    0,
                    freeMemoryPointer,
                    68,
                    0,
                    32
                )
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(
                        eq(mload(0), 1),
                        gt(returndatasize(), 31)
                    ),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(
                    gas(),
                    token,
                    0,
                    freeMemoryPointer,
                    68,
                    0,
                    32
                )
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

// import { Types } from "../../Types.sol";

/// @title Factory Verifier
/// @notice Core contract binding interface that connect both
/// `MADMarketplace` and `MADRouter` storage verifications made to `MADFactory`.
interface FactoryVerifier {
    // using Types for Types.ERC721Type;

    /// @dev 0x4ca88867
    error AccessDenied();

    /// @notice Authority validator for no-fee marketplace listing.
    /// @dev Function Sighash := 0x76de0f3d
    /// @dev Binds Marketplace's pull payment methods to Factory storage.
    /// @param _token Address of the traded token.
    /// @param _user Token Seller that must match collection creator for no-fee listing.
    /// @return stdout := 1 as boolean standard output.
    function creatorAuth(address _token, address _user)
        external
        view
        returns (bool stdout);

    /// @notice Authority validator for `MADRouter` creator settings and withdraw functions.
    /// @dev Function Sighash := 0xb64bd5eb
    /// @param _colID 32 bytes collection ID value.
    /// @return creator bb
    /// @return check Boolean output to either approve or reject call's `tx.origin` function access.
    function creatorCheck(bytes32 _colID)
        external
        view
        returns (address creator, bool check);

    // /// @dev Convert `colID` to address (32bytes => 20bytes).
    // /// @dev Function Sighash := 0xc3e15ec0
    // function getColAddress(bytes32 _colID)
    //     external
    //     pure
    //     returns (address colAddress);

    /// @dev Convert address to `colID` (20bytes => 32bytes).
    /// @dev Function Sighash := 0x617d1d3b
    function getColID(address _colAddress)
        external
        pure
        returns (bytes32 colID);

    /// @dev Returns the collection type uint8 value in case token and user are authorized.
    /// @dev Function Sighash := 0xd93cb8fd
    function typeChecker(bytes32 _colID)
        external
        view
        returns (uint8 pointer);
}

// SPDX-License-Identifier: AGPL-3.0-only

/// @title Payment splitter base contract that allows to split Ether payments among a group of accounts.
/// @author Modified from OpenZeppelin Contracts
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/finance/PaymentSplitter.sol)

pragma solidity 0.8.4;

import "../utils/SafeTransferLib.sol";

// import "./Address.sol";

/// @notice The split can be in equal parts or in any other arbitrary proportion.
/// The way this is specified is by assigning each account to a number of shares.
/// Of all the Ether that this contract receives, each account will then be able to claim
/// an amount proportional to the percentage of total shares they were assigned.

/// @dev `PaymentSplitter` follows a _pull payment_ model. This means that payments are not
/// automatically forwarded to the accounts but kept in this contract, and the actual transfer
/// is triggered asa separate step by calling the {release} function.

/// @dev This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether).
/// Rebasing tokens, and tokens that apply fees during transfers, are likely to not be supported
/// as expected. If in doubt, we encourage you to run tests before sending real value to this contract.

contract SplitterImpl {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event ERC20PaymentReleased(
        ERC20 indexed token,
        address to,
        uint256 amount
    );

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(ERC20 => uint256) private _erc20TotalReleased;
    mapping(ERC20 => mapping(address => uint256))
        private _erc20Released;

    /// @dev Creates an instance of `PaymentSplitter` where each account in `payees`
    /// is assigned the number of shares at the matching position in the `shares` array.
    /// @dev All addresses in `payees` must be non-zero. Both arrays must have the same
    /// non-zero length, and there must be no duplicates in `payees`.
    constructor(
        address[] memory payees,
        uint256[] memory shares_
    ) payable {
        require(
            payees.length == shares_.length,
            "LENGTH_MISMATCH"
        );
        require(
            payees.length != 0, /* > 0 */
            "NO_PAYEES"
        );
        uint256 i;
        uint256 len = payees.length;
        for (i; i < len; ) {
            _addPayee(payees[i], shares_[i]);
            unchecked {
                ++i;
            }
        }
        // no risk of loop overflow since payees are bounded by factory parameters
    }

    /// @dev The Ether received will be logged with {PaymentReceived} events.
    /// Note that these events are not fully reliable: it's possible for a contract
    /// to receive Ether without triggering this function. This only affects the
    /// reliability of the events, and not the actual splitting of Ether.
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /// @dev Getter for the total shares held by payees.
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /// @dev Getter for the total amount of Ether already released.
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /// @dev Getter for the total amount of `token` already released.
    /// `token` should be the address of an ERC20 contract.
    function totalReleased(ERC20 token)
        public
        view
        returns (uint256)
    {
        return _erc20TotalReleased[token];
    }

    /// @dev Getter for the amount of shares held by an account.
    function shares(address account)
        public
        view
        returns (uint256)
    {
        return _shares[account];
    }

    /// @dev Getter for the amount of Ether already released to a payee.
    function released(address account)
        public
        view
        returns (uint256)
    {
        return _released[account];
    }

    /// @dev Getter for the amount of `token` tokens already released to a payee.
    /// `token` should be the address of an ERC20 contract.
    function released(ERC20 token, address account)
        public
        view
        returns (uint256)
    {
        return _erc20Released[token][account];
    }

    /// @dev Getter for the address of the payee number `index`.
    function payee(uint256 index)
        public
        view
        returns (address)
    {
        return _payees[index];
    }

    /// @dev Getter for the amount of payee's releasable Ether.
    function releasable(address account)
        public
        view
        returns (uint256)
    {
        uint256 totalReceived = address(this).balance +
            totalReleased();
        return
            _pendingPayment(
                account,
                totalReceived,
                released(account)
            );
    }

    /// @dev Getter for the amount of payee's releasable `token` tokens.
    /// `token` should be the address of an ERC20 contract.
    function releasable(ERC20 token, address account)
        public
        view
        returns (uint256)
    {
        uint256 totalReceived = token.balanceOf(
            address(this)
        ) + totalReleased(token);
        return
            _pendingPayment(
                account,
                totalReceived,
                released(token, account)
            );
    }

    /// @dev Triggers a transfer to `account` of the amount of Ether they are owed,
    /// according to their percentage of the total shares and their previous withdrawals.
    function release(address payable account) public virtual {
        require(
            _shares[account] != 0, /* > 0 */
            "NO_SHARES"
        );

        uint256 payment = releasable(account);

        require(payment != 0, "DENIED_ACCOUNT");
        // require(
        //     address(this).balance >= payment,
        //     "INSUFFICIENT_BALANCE"
        // );

        _released[account] += payment;
        _totalReleased += payment;

        // Address.sendValue(account, payment);
        SafeTransferLib.safeTransferETH(account, payment);
        emit PaymentReleased(account, payment);
    }

    /// @dev Triggers a transfer to `account` of the amount of `token` tokens
    /// they are owed, according to their percentage of the total shares and
    /// their previous withdrawals. `token` must be the address of an ERC20 contract.
    function release(ERC20 token, address account)
        public
        virtual
    {
        require(
            _shares[account] != 0, /* > 0 */
            "NO_SHARES"
        );

        uint256 payment = releasable(token, account);

        require(payment != 0, "DENIED_ACCOUNT");
        // require(
        //     token.balanceOf(address(this)) >= payment,
        //     "INSUFFICIENT_BALANCE"
        // );

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeTransferLib.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /// @dev internal logic for computing the pending payment of an `account`,
    /// given the token historical balances and already released amounts.
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) /
            _totalShares -
            alreadyReleased;
    }

    /// @dev Add a new payee to the contract.
    /// @param account The address of the payee to add.
    /// @param shares_ The number of shares owned by the payee.
    function _addPayee(address account, uint256 shares_)
        private
    {
        require(account != address(0), "DEAD_ADDRESS");
        require(
            shares_ != 0, /* > 0 */
            "INVALID_SHARE"
        );
        require(_shares[account] == 0, "ALREADY_PAYEE");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @title Required interface of an ERC721 compliant contract.
interface IERC721 {
    /// @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /// @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /// @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @return balance Returns the number of tokens in ``owner``'s account.
    function balanceOf(address owner)
        external
        view
        returns (uint256 balance);

    /// @return owner Returns the owner of the `tokenId` token.
    /// @dev Requirements: `tokenId` must exist.
    function ownerOf(uint256 tokenId)
        external
        view
        returns (address owner);

    /// @notice Safely transfers `tokenId` token from `from` to `to`.
    /// @dev Emits a {Transfer} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /// @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
    /// are aware of the ERC721 protocol to prevent tokens from being forever locked.
    /// @dev Emits a {Transfer} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Transfers `tokenId` token from `from` to `to`.
    /// @dev Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
    /// @dev Emits a {Transfer} event.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Gives permission to `to` to transfer `tokenId` token to another account.
    /// The approval is cleared when the token is transferred. Only a single account can be
    /// approved at a time, so approving the zero address clears previous approvals.
    /// @dev Emits an {Approval} event.
    function approve(address to, uint256 tokenId) external;

    /// @notice Approve or remove `operator` as an operator for the caller.
    /// @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
    /// @dev Emits an {ApprovalForAll} event.
    function setApprovalForAll(
        address operator,
        bool _approved
    ) external;

    /// @notice Returns the account approved for `tokenId` token.
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /// @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /// @notice Queries EIP2981 royalty info for marketplace royalty payment enforcement.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

/// @title Required interface of an ERC1155 compliant contract.
interface IERC1155 {
    /// @dev Emitted when `value` tokens of token type `id` are transferred
    /// from `from` to `to` by `operator`.
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /// @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from`
    /// and `to` are the same for all transfers.
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /// @dev Emitted when `account` grants or revokes permission to `operator` to
    /// transfer their tokens, according to `approved`.
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /// @return Returns the amount of tokens of token type `id` owned by `account`.
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /// @dev Batched version of {balanceOf}.
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /// @notice Transfers `amount` tokens of token type `id` from `from` to `to`,
    /// making sure the recipient can receive the tokens.
    /// @dev Emits a {TransferSingle} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /// @dev Batched version of {safeTransferFrom}.
    /// @dev Emits a {TransferBatch} event.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /// @notice Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`.
    /// @dev `operator` cannot be the caller.
    /// @dev Emits an {ApprovalForAll} event.
    function setApprovalForAll(
        address operator,
        bool approved
    ) external;

    /// @notice Returns true if `operator` is approved to transfer ``account``'s tokens.
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /// @notice Queries EIP2981 royalty info for marketplace royalty payment enforcement.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    /// @notice Queries for ERC165 introspection support.
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256))
        public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(
            deadline >= block.timestamp,
            "PERMIT_DEADLINE_EXPIRED"
        );

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(
                recoveredAddress != address(0) &&
                    recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR()
        public
        view
        virtual
        returns (bytes32)
    {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator()
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount)
        internal
        virtual
    {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount)
        internal
        virtual
    {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.4;

// import { ERC1155TokenReceiver } from "./ERC1155.sol";

/// @notice Minimalist and gas efficient ERC1155 implementation optimized for single supply ids.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155B.sol)
abstract contract ERC1155B {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(address => bool))
        public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                            ERC1155B STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public ownerOf;

    function balanceOf(address owner, uint256 id)
        public
        view
        virtual
        returns (uint256 bal)
    {
        address idOwner = ownerOf[id];

        assembly {
            // We avoid branching by using assembly to take
            // the bool output of eq() and use it as a uint.
            bal := eq(idOwner, owner)
        }
    }

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id)
        public
        view
        virtual
        returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        require(from == ownerOf[id], "WRONG_FROM"); // Can only transfer from the owner.

        // Can only transfer 1 with ERC1155B.
        require(amount == 1, "INVALID_AMOUNT");

        ownerOf[id] = to;

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) ==
                    ERC1155TokenReceiver
                        .onERC1155Received
                        .selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(
            ids.length == amounts.length,
            "LENGTH_MISMATCH"
        );

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                id = ids[i];
                amount = amounts[i];

                // Can only transfer from the owner.
                require(from == ownerOf[id], "WRONG_FROM");

                // Can only transfer 1 with ERC1155B.
                require(amount == 1, "INVALID_AMOUNT");

                ownerOf[id] = to;
            }
        }

        emit TransferBatch(
            msg.sender,
            from,
            to,
            ids,
            amounts
        );

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to)
                    .onERC1155BatchReceived(
                        msg.sender,
                        from,
                        ids,
                        amounts,
                        data
                    ) ==
                    ERC1155TokenReceiver
                        .onERC1155BatchReceived
                        .selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    )
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(
            owners.length == ids.length,
            "LENGTH_MISMATCH"
        );

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf(owners[i], ids[i]);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        // Minting twice would effectively be a force transfer.
        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        ownerOf[id] = to;

        emit TransferSingle(
            msg.sender,
            address(0),
            to,
            id,
            1
        );

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    1,
                    data
                ) ==
                    ERC1155TokenReceiver
                        .onERC1155Received
                        .selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                // Minting twice would effectively be a force transfer.
                require(
                    ownerOf[id] == address(0),
                    "ALREADY_MINTED"
                );

                ownerOf[id] = to;

                amounts[i] = 1;
            }
        }

        emit TransferBatch(
            msg.sender,
            address(0),
            to,
            ids,
            amounts
        );

        if (to.code.length != 0) {
            require(
                ERC1155TokenReceiver(to)
                    .onERC1155BatchReceived(
                        msg.sender,
                        address(0),
                        ids,
                        amounts,
                        data
                    ) ==
                    ERC1155TokenReceiver
                        .onERC1155BatchReceived
                        .selector,
                "UNSAFE_RECIPIENT"
            );
        } else require(to != address(0), "INVALID_RECIPIENT");
    }

    function _batchBurn(address from, uint256[] memory ids)
        internal
        virtual
    {
        // Burning unminted tokens makes no sense.
        require(from != address(0), "INVALID_FROM");

        uint256 idsLength = ids.length; // Saves MLOADs.

        // Generate an amounts array locally to use in the event below.
        uint256[] memory amounts = new uint256[](idsLength);

        uint256 id; // Storing outside the loop saves ~7 gas per iteration.

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < idsLength; ++i) {
                id = ids[i];

                require(ownerOf[id] == from, "WRONG_FROM");

                ownerOf[id] = address(0);

                amounts[i] = 1;
            }
        }

        emit TransferBatch(
            msg.sender,
            from,
            address(0),
            ids,
            amounts
        );
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        ownerOf[id] = address(0);

        emit TransferSingle(
            msg.sender,
            owner,
            address(0),
            id,
            1
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return
            ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return
            ERC1155TokenReceiver
                .onERC1155BatchReceived
                .selector;
    }
}