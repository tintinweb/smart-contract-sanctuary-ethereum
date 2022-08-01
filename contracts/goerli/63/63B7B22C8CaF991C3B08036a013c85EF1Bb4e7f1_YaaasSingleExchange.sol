// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "./ERC721Validator.sol";
import "./Loyalty.sol";
import "./FeeManager.sol";

import "./interfaces/IYaaasSingleExchange.sol";
import "./interfaces/IERC721Receiver.sol";

import "./libraries/YaaasLibrary.sol";
import "./libraries/TransferHelper.sol";

/// @title Yaaas Exchange ERC721 token contract
/// @notice Yaaas Exchanger for single NFTs
contract YaaasSingleExchange is
    ERC721Validator,
    IYaaasSingleExchange,
    Loyalty,
    FeeManager
{
    // @dev Used to put NFT in sell by holder's address and assetId
    mapping(address => mapping(uint256 => Offer)) public offers;
    // For auctions bid by bider, collection and assetId
    mapping(address => mapping(uint256 => mapping(address => Bid)))
        public bidforAuctions;

    modifier onlyOfferOwner(address collection, uint256 assetId) {
        require(_msgSender() == offers[collection][assetId].seller);
        _;
    }

    function addLoyaltyOffer(
        address _seller,
        address _collection,
        uint256 _assetId,
        address token,
        uint256 _price,
        bool isForSell,
        bool isForAuction,
        uint256 expiresAt,
        uint256 shareIndex,
        uint256 loyaltyPercent
    ) external {
        addLoyalty(_collection, _assetId, _msgSender(), loyaltyPercent);
        _addOffer(
            _seller,
            _collection,
            _assetId,
            token,
            _price,
            isForSell,
            isForAuction,
            expiresAt,
            shareIndex
        );
    }

    function addOffer(
        address _seller,
        address _collection,
        uint256 _assetId,
        address token,
        uint256 _price,
        bool isForSell,
        bool isForAuction,
        uint256 expiresAt,
        uint256 shareIndex
    ) external {
        _addOffer(
            _seller,
            _collection,
            _assetId,
            token,
            _price,
            isForSell,
            isForAuction,
            expiresAt,
            shareIndex
        );
    }

    function _addOffer(
        address _seller,
        address _collection,
        uint256 _assetId,
        address token,
        uint256 _price,
        bool isForSell,
        bool isForAuction,
        uint256 expiresAt,
        uint256 shareIndex
    ) internal {
        require(!offers[_collection][_assetId].exists, "Offer exists already");
        // get NFT asset from seller
        IERC721 singleNFTCollection = _requireERC721(_collection);
        require(
            singleNFTCollection.ownerOf(_assetId) == _msgSender(),
            "Transfer caller is not owner"
        );

        require(_seller == _msgSender(), "Seller should be equals owner");
        require(
            singleNFTCollection.isApprovedForAll(_msgSender(), address(this)),
            "Contract not approved"
        );
        offers[_collection][_assetId] = Offer(
            _seller,
            _collection,
            _assetId,
            token,
            _price,
            isForSell,
            isForAuction,
            expiresAt,
            shareIndex,
            true // offer exists
        );
        singleNFTCollection.safeTransferFrom(_seller, address(this), _assetId);
        emit Listed(_seller, _collection, _assetId, token, _price);
    }

    function setOfferPrice(
        address collection,
        uint256 assetId,
        uint256 price
    ) external {
        Offer storage offer = _getOwnerOffer(collection, assetId);
        offer.price = price;
        emit SetOfferPrice(collection, assetId, price);
    }

    function setForSell(
        address collection,
        uint256 assetId,
        bool isForSell
    ) external {
        Offer storage offer = _getOwnerOffer(collection, assetId);
        offer.isForSell = isForSell;
        emit SetForSell(collection, assetId, isForSell);
    }

    function setForAuction(
        address collection,
        uint256 assetId,
        bool isForAuction
    ) external {
        Offer storage offer = _getOwnerOffer(collection, assetId);
        offer.isForAuction = isForAuction;
        emit SetForAuction(collection, assetId, isForAuction);
    }

    function setExpiresAt(
        address collection,
        uint256 assetId,
        uint256 expiresAt
    ) external onlyOfferOwner(collection, assetId) {
        Offer storage offer = _getOwnerOffer(collection, assetId);
        offer.expiresAt = expiresAt;
        emit SetExpireAt(collection, assetId, expiresAt);
    }

    function cancelOffer(address collection, uint256 assetId)
        external
        onlyOfferOwner(collection, assetId)
    {
        Offer memory offer = _getOwnerOffer(collection, assetId);
        IERC721 singleNFTCollection = _requireERC721(collection);
        require(_msgSender() == offer.seller, "Marketpalce: invalid owner");
        require(offer.expiresAt < block.timestamp, "Offer should be expired");
        delete offers[collection][assetId];
        singleNFTCollection.safeTransferFrom(
            address(this),
            offer.seller,
            offer.assetId
        );
        emit CancelOffer(collection, assetId);
    }

    function _getOwnerOffer(address collection, uint256 assetId)
        internal
        view
        returns (Offer storage)
    {
        Offer storage offer = offers[collection][assetId];
        return offer;
    }

    function buyOffer(address collection, uint256 assetId) external payable {
        Offer memory offer = offers[collection][assetId];
        require(msg.value > 0, "price must be > 0");
        require(offer.isForSell, "Offer not for sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        _buyOffer(offer, _msgSender());
        emit Swapped(
            _msgSender(),
            offer.seller,
            collection,
            assetId,
            msg.value
        );
    }

    /*
        This method is introduced to buy NFT with the help of a delegate.
        It will work as like buyOffer method, but instead transferring NFT to _msgSender address, it will transfer the NFT to buyer address.
        As its a payable method, it's highly unlikely that somebody would call this function for fishing or by mistake.
    */
    function delegateBuy(address collection, uint256 assetId, address buyer) external payable {
        Offer memory offer = offers[collection][assetId];
        require(msg.value > 0, "price must be > 0");
        require(offer.isForSell, "Offer not for sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        _buyOffer(offer, buyer);
        emit Swapped(
            buyer,
            offer.seller,
            collection,
            assetId,
            msg.value
        );
    }

    function _buyOffer(Offer memory offer, address buyer) internal {
        IERC721 singleNFTCollection = _requireERC721(offer.collection);
        (uint256 ownerProfitAmount, uint256 sellerAmount) = YaaasLibrary
            .computePlateformOwnerProfit(
                offer.price,
                msg.value,
                getFeebyIndex(offer.shareIndex)
            );
        require(
            offer.price <= sellerAmount,
            "price should equal or upper to offer price"
        );
        sellerAmount = sendLoyaltyToCreatorFromETH(
            offer.collection,
            offer.assetId,
            offer.seller,
            sellerAmount
        );
        TransferHelper.safeTransferETH(offer.seller, sellerAmount);
        TransferHelper.safeTransferETH(owner(), ownerProfitAmount);
        delete offers[offer.collection][offer.assetId];
        singleNFTCollection.transferFrom(
            address(this),
            buyer,
            offer.assetId
        );
    }

    function safePlaceBid(
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price
    ) public {
        _createBid(_collection, _assetId, _token, _price);
    }

    function _createBid(
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price
    ) internal {
        // Checks order validity
        Offer memory offer = offers[_collection][_assetId];
        // check on expire time
        // Check price if theres previous a bid
        Bid memory bid = bidforAuctions[_collection][_assetId][_msgSender()];
        require(bid.bidder != _msgSender());
        require(_token == offer.token);
        require(_msgSender() != offer.seller, "owner could not place bid");
        require(offer.isForAuction, "NFT Marketplace: NFT token not in sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        require(
            IERC20(_token).allowance(_msgSender(), address(this)) >= _price,
            "NFT Marketplace: Allowance error"
        );
        // Create bid
        bytes32 bidId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, _price)
        );

        // Save Bid for this order
        bidforAuctions[_collection][_assetId][_msgSender()] = Bid({
            id: bidId,
            bidder: _msgSender(),
            token: _token,
            price: _price
        });

        emit BidCreated(
            bidId,
            _collection,
            _assetId,
            _msgSender(), // bidder
            _token,
            _price
        );
    }

    function cancelBid(
        address _collection,
        uint256 _assetId,
        address _bidder
    ) external {
        IERC721 singleNFTCollection = _requireERC721(_collection);
        require(
            _bidder == _msgSender() ||
                _msgSender() == singleNFTCollection.ownerOf(_assetId),
            "Marketplace: Unauthorized operation"
        );
        Bid memory bid = bidforAuctions[_collection][_assetId][_msgSender()];
        delete bidforAuctions[_collection][_assetId][_bidder];
        emit BidCancelled(bid.id);
    }

    function acceptBid(
        address _collection,
        uint256 _assetId,
        address _bidder
    ) external {
        //get offer
        Offer memory offer = offers[_collection][_assetId];
        // get bid to accept
        Bid memory bid = bidforAuctions[_collection][_assetId][_bidder];
        require(
            offer.seller == _msgSender(),
            "Marketplace: unauthorized sender"
        );
        require(offer.isForAuction, "Marketplace: offer not in auction");
        // get service fees
        (uint256 ownerProfitAmount, uint256 sellerAmount) = YaaasLibrary
            .computePlateformOwnerProfit(
                bid.price,
                bid.price,
                getFeebyIndex(offer.shareIndex)
            );
        sellerAmount = sendLoyaltyToCreatorFromETH(
            offer.collection,
            offer.assetId,
            offer.seller,
            sellerAmount
        );
        // check seller
        delete bidforAuctions[_collection][_assetId][_bidder];
        emit BidAccepted(bid.id);

        // transfer escrowed bid amount minus market fee to seller
        IERC20(bid.token).transferFrom(bid.bidder, _msgSender(), sellerAmount);
        IERC20(bid.token).transferFrom(bid.bidder, owner(), ownerProfitAmount);

        delete offers[_collection][_assetId];
        // Transfer NFT asset
        IERC721(_collection).safeTransferFrom(
            address(this),
            bid.bidder,
            _assetId
        );
        // Notify ..
        emit BidSuccessful(
            _collection,
            _assetId,
            bid.token,
            bid.bidder,
            bid.price
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

//  SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// add common transfer

// add ERC721/ERC1155 transfer helper

library YaaasLibrary {
    using SafeMath for uint256;

    // compute the amount that must be sent to the platefom owner
    function computePlateformOwnerProfit(
        uint256 offerPrice,
        uint256 totalSentAmount,
        uint256 profitPercent
    ) internal pure returns (uint256 ownerProfitAmount, uint256 sellerAmount) {
        ownerProfitAmount = offerPrice.mul(profitPercent).div(100);
        sellerAmount = totalSentAmount.sub(ownerProfitAmount);
    }

    // extract the owner profit from the offer total amount
    function extractOwnerProfitFromOfferAmount(
        uint256 offerTotalAmount,
        uint256 ownerProfitAmount
    ) internal pure returns (uint256) {
        return offerTotalAmount.sub(ownerProfitAmount);
    }

    function extractPurshasedAmountFromOfferAmount(
        uint256 offerAmount,
        uint256 bidAmount
    ) internal pure returns (uint256) {
        return offerAmount.sub(bidAmount);
    }

    // compute the amount that must be sent to the platefom owner
    function computePlateformOwnerProfitByAmount(
        uint256 totalSentETH,
        uint256 offerPrice,
        uint256 nftAmount,
        uint256 profitPercent
    ) internal pure returns (uint256 ownerProfitAmount, uint256 sellerAmount) {
        ownerProfitAmount = (offerPrice.mul(nftAmount)).mul(profitPercent).div(
            100
        );
        require(
            totalSentETH >= (offerPrice.mul(nftAmount).add(ownerProfitAmount)),
            "Yaaas: Insufficient funds"
        );
        sellerAmount = totalSentETH.sub(ownerProfitAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

/**
 * @title A DEX for ERC721 tokens (NFTs)
 */
interface IYaaasSingleExchange {
    /**
     * @notice Put a single NFT in the market for sell
     * @dev Emit an ERC721 Token in sell
     * @param _seller the token owner
     * @param _collection the ERC1155 address
     * @param _assetId the NFT id
     * @param _token the sale price
     * @param _price the sale price
     * @param _isForSell if the token in direct sale
     * @param _isForAuction if the token in auctions
     * @param _expiresAt the offer's exprire date.
     * @param _shareIndex the percentage the contract owner earns in every sale
     * @param _loyaltyPercent  the percentage the NFT creator earns in every sale

     */
    function addLoyaltyOffer(
        address _seller,
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex,
        uint256 _loyaltyPercent
    ) external;

    /**
     * @notice Put a single NFT in the market for sell
     * @dev Emit an ERC721 Token in sell
     * @param _seller the token owner
     * @param _collection the ERC1155 address
     * @param _assetId the NFT id
     * @param _token the sale price
     * @param _price the sale price
     * @param _isForSell if the token in direct sale
     * @param _isForAuction if the token in auctions
     * @param _expiresAt the offer's exprire date.
     * @param _shareIndex the percentage the contract owner earns in every sale
     */
    function addOffer(
        address _seller,
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex
    ) external;

    /**
     * @notice Set NFT's sell price in the market
     * @dev Set Offer price
     * @param _collection the token owner
     * @param _assetId the ERC1155 address
     * @param _price new minimun price to sell an NFT
     */
    function setOfferPrice(
        address _collection,
        uint256 _assetId,
        uint256 _price
    ) external;

    /**
     * @notice hide an NFT in direct sell from the market, or enable NFT's purshare in the market in direct sell
     * @dev Enable or disable an offer in direct sell
     * @param _collection the ERC721 collection address
     * @param _assetId the NFT identifant
     * @param _isForSell a boolean to make offer in direct sell or not
     */
    function setForSell(
        address _collection,
        uint256 _assetId,
        bool _isForSell
    ) external;

    /**
     * @notice hide an NFT in auction from the market, or enable NFT's purshare in the market in auction
     * @dev Enable or disable an offer in auction
     * @param _collection the ERC721 collection address
     * @param _assetId the NFT identifant
     * @param _isForAuction a boolean to make offer in auction or not
     */
    function setForAuction(
        address _collection,
        uint256 _assetId,
        bool _isForAuction
    ) external;

    /**
     * @notice Expands NFT offer expire Time
     * @dev set offer expire date
     * @param _collection the ERC721 collection address
     * @param _assetId the NFT identifant
     * @param _expiresAt new expire date
     */
    function setExpiresAt(
        address _collection,
        uint256 _assetId,
        uint256 _expiresAt
    ) external;

    /**
     * @dev Cancel in remore an NFT from the market
     * @param _collection the ERC721 collection address
     * @param _assetId the NFT identifant
     */
    function cancelOffer(address _collection, uint256 _assetId) external;

    /**
     * @dev Buy NFT from the market
     * @param _collection the ERC721 collection address
     * @param _assetId the NFT identifant
     */
    function buyOffer(address _collection, uint256 _assetId) external payable;

    /**
     * @dev accept placed bid
     * @param _collection ERC721 collection address
     * @param _assetId  NFT identifant
     * @param _bidder Accepted bidder address
     */
    function acceptBid(
        address _collection,
        uint256 _assetId,
        address _bidder
    ) external;

    /**
     * @dev cancel bid by owner or bidder
     * @param _collection ERC721 collection address
     * @param _assetId  NFT identifant
     * @param _bidder bidder address
     */
    function cancelBid(
        address _collection,
        uint256 _assetId,
        address _bidder
    ) external;

    event Swapped(
        address buyer,
        address seller,
        address token,
        uint256 assetId,
        uint256 price
    );
    event Listed(
        address seller,
        address collection,
        uint256 assetId,
        address token,
        uint256 price
    );
    struct Offer {
        address seller;
        address collection;
        uint256 assetId;
        address token;
        uint256 price;
        bool isForSell;
        bool isForAuction;
        uint256 expiresAt;
        uint256 shareIndex;
        bool exists;
    }
    struct Bid {
        bytes32 id;
        address bidder;
        address token;
        uint256 price;
    }
    // BID EVENTS
    event BidCreated(
        bytes32 id,
        address indexed collection,
        uint256 indexed assetId,
        address indexed bidder,
        address token,
        uint256 price
    );
    event BidSuccessful(
        address collection,
        uint256 assetId,
        address token,
        address bidder,
        uint256 price
    );
    event BidAccepted(bytes32 id);
    event BidCancelled(bytes32 id);
    event SetForSell(address collection, uint256 assetId, bool isForSell);
    event SetForAuction(address collection, uint256 assetId, bool isForAuction);
    event SetExpireAt(address collection, uint256 assetId, uint256 expiresAt);
    event CancelOffer(address collection, uint256 assetId);
    event AddLoyaltyBid(
        address seller,
        address collection,
        uint256 assetId,
        address token,
        uint256 price
    );
    event SetOfferPrice(address collection, uint256 assetId, uint256 price);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

/// @title Loyalty for Non-fungible token
/// @notice Manage
interface ILoyalty {
    /**
     * @notice loyalty program
     * @dev Get loyalty percentage
     * @param collection The NFT collection address
     * @param assetId the NFT asset identifier
     */
    function getLoyalty(
        address collection,
        uint256 assetId,
        address right_holder
    ) external view returns (uint256);

    /**
     * @notice loyalty program
     * @dev Check loyalty existence
     * @param collection The NFT collection address
     * @param assetId the NFT asset identifier
     */
    function isInLoyalty(address collection, uint256 assetId)
        external
        view
        returns (bool);

    event AddLoyalty(
        address collection,
        uint256 assetId,
        address right_holder,
        uint256 percent
    );
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

/**
 * @title Fee manager
 * @dev Interface to managing DEX fee.
 */
interface IFeeManager {
    /**
     * @notice Manage fee to be paid to each nft sell
     * @dev set fee percentage by index
     * @param index the index of the fee
     * @param newFee the fee percentage
     */
    function setFeeTo(uint256 index, uint256 newFee) external;

    event SetFeeTo(uint256 index, uint256 newFee);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `assetId` token is transferred to this contract via {IERC721-safeTransferFrom}
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
        uint256 assetId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./interfaces/ILoyalty.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Loyalty is ILoyalty {
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public loyalties;
    mapping(address => mapping(uint256 => address)) public creators;
    mapping(address => mapping(uint256 => bool)) public hasLoyalty;

    using SafeMath for uint256;

    function addLoyalty(
        address collection,
        uint256 assetId,
        address right_holder,
        uint256 percent
    ) internal {
        require(
            percent > 0 && percent <= 10,
            "Loyalty percent must be between 0 and 10"
        );
        require(!_isInLoyalty(collection, assetId), "NFT already in loyalty");
        creators[collection][assetId] = right_holder;
        _addLoyalty(collection, assetId, right_holder, percent);
    }

    function sendLoyaltyToCreatorFromERC20Token(
        address collection,
        uint256 assetId,
        address seller,
        uint256 sellerAmount,
        address token,
        address bidder
    ) internal returns (uint256) {
        if (_isInLoyalty(collection, assetId)) {
            address creator = _getLoyaltyCreator(collection, assetId);
            if (creator != seller) {
                uint256 percent = getLoyalty(collection, assetId, creator);
                uint256 creatorBenif = (sellerAmount).mul(percent).div(100);
                IERC20(token).transferFrom(bidder, creator, creatorBenif);
                sellerAmount = sellerAmount.sub(creatorBenif);
            }
        }
        return sellerAmount;
    }

    function sendLoyaltyToCreatorFromETH(
        address collection,
        uint256 assetId,
        address seller,
        uint256 sellerAmount
    ) internal returns (uint256) {
        if (_isInLoyalty(collection, assetId)) {
            address creator = _getLoyaltyCreator(collection, assetId);
            if (creator != seller) {
                uint256 percent = getLoyalty(collection, assetId, creator);
                uint256 creatorBenif = (sellerAmount).mul(percent).div(100);
                (bool sentCreatorBenif, ) = creator.call{value: creatorBenif}(
                    ""
                );
                if (sentCreatorBenif) {
                    sellerAmount = sellerAmount.sub(creatorBenif);
                }
            }
        }
        return sellerAmount;
    }

    function getLoyalty(
        address collection,
        uint256 assetId,
        address right_holder
    ) public view returns (uint256) {
        return loyalties[collection][assetId][right_holder];
    }

    function getLoyaltyCreator(address collection, uint256 assetId)
        external
        view
        returns (address)
    {
        return _getLoyaltyCreator(collection, assetId);
    }

    function _getLoyaltyCreator(address collection, uint256 assetId)
        internal
        view
        returns (address)
    {
        return creators[collection][assetId];
    }

    function isInLoyalty(address collection, uint256 assetId)
        external
        view
        returns (bool)
    {
        return _isInLoyalty(collection, assetId);
    }

    function _isInLoyalty(address collection, uint256 assetId)
        internal
        view
        returns (bool)
    {
        return hasLoyalty[collection][assetId];
    }

    function _addLoyalty(
        address collection,
        uint256 assetId,
        address right_holder,
        uint256 percent
    ) internal {
        loyalties[collection][assetId][right_holder] = percent;
        hasLoyalty[collection][assetId] = true;
        emit AddLoyalty(collection, assetId, right_holder, percent);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "./interfaces/IFeeManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeManager is IFeeManager, Ownable {
    // Each offer has a dedicated share for plateform holder
    mapping(uint256 => uint256) public shares;

    constructor() {
        shares[1] = 1;
        shares[2] = 1;
        shares[3] = 1;
        shares[4] = 1;
        shares[5] = 1;
        shares[6] = 1;
        shares[7] = 1;
        shares[8] = 1;
    }

    function setFeeTo(uint256 index, uint256 newFee) external onlyOwner {
        require(newFee <= 100, "Market Fee must be >= 0 and <= 100");
        shares[index] = newFee;
        emit SetFeeTo(index, newFee);
    }

    function getFeebyIndex(uint256 index) internal view returns (uint256) {
        return shares[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Validator {
    bytes4 constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    function _requireERC721(address _nftAddress)
        internal
        view
        returns (IERC721)
    {
        require(
            IERC721(_nftAddress).supportsInterface(_INTERFACE_ID_ERC721),
            "The NFT contract has an invalid ERC721 implementation"
        );

        return IERC721(_nftAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}