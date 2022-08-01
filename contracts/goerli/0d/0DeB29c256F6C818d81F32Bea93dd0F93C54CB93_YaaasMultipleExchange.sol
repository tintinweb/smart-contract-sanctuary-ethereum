// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "./Loyalty.sol";
import "./FeeManager.sol";

import "./interfaces/IYaaasMultipleExchange.sol";

import "./libraries/YaaasLibrary.sol";
import "./libraries/TransferHelper.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract YaaasMultipleExchange is
    IYaaasMultipleExchange,
    Loyalty,
    FeeManager,
    ERC1155Holder
{
    using SafeMath for uint256;

    //ERC1155
    mapping(uint256 => Offer) public offers;
    // For auctions bid by bider, collection and assetId
    mapping(uint256 => mapping(address => Bid)) public bidforAuctions;

    modifier onlyOfferOwner(uint256 offerId) {
        require(_msgSender() == offers[offerId].seller);
        _;
    }

    function addLoyaltyOffer(
        uint256 _id,
        address _seller,
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price,
        uint256 _amount,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex,
        uint256 _loyaltyPercent
    ) external {
        addLoyalty(_collection, _assetId, _msgSender(), _loyaltyPercent);
        _addOffer(
            _id,
            _seller,
            _collection,
            _assetId,
            _token,
            _price,
            _amount,
            _isForSell,
            _isForAuction,
            _expiresAt,
            _shareIndex
        );
    }

    function addOffer(
        uint256 _id,
        address _seller,
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price,
        uint256 _amount,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex
    ) external {
        _addOffer(
            _id,
            _seller,
            _collection,
            _assetId,
            _token,
            _price,
            _amount,
            _isForSell,
            _isForAuction,
            _expiresAt,
            _shareIndex
        );
    }

    function _addOffer(
        uint256 _id,
        address _seller,
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price,
        uint256 _amount,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex
    ) internal {
        require(!offers[_id].exists, "Offer exists already");
        // get NFT asset from seller
        IERC1155 multipleNFTCollection = IERC1155(_collection);
        require(
            multipleNFTCollection.balanceOf(_msgSender(), _assetId) >= _amount,
            "Insufficient token balance"
        );

        require(_seller == _msgSender(), "Seller should be equals owner");
        require(
            multipleNFTCollection.isApprovedForAll(_msgSender(), address(this)),
            "Contract not approved"
        );
        offers[_id] = Offer(
            _seller,
            _collection,
            _assetId,
            _token,
            _price,
            _amount,
            _isForSell,
            _isForAuction,
            _expiresAt,
            _shareIndex,
            true //offer exists
        );
        IERC1155(_collection).safeTransferFrom(
            _seller,
            address(this),
            _assetId,
            _amount,
            ""
        );
        emit Listed(_seller, _collection, _assetId, _amount, _price);
    }

    function setOfferPrice(uint256 offerID, uint256 price)
        external
        onlyOfferOwner(offerID)
    {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.price = price;
        emit SetOfferPrice(offerID, price);
    }

    function setForSell(uint256 offerID, bool isForSell)
        external
        onlyOfferOwner(offerID)
    {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.isForSell = isForSell;
        emit SetForSell(offerID, isForSell);
    }

    function setForAuction(uint256 offerID, bool isForAuction)
        external
        onlyOfferOwner(offerID)
    {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.isForAuction = isForAuction;
        emit SetForAuction(offerID, isForAuction);
    }

    function setExpiresAt(uint256 offerID, uint256 expiresAt)
        external
        onlyOfferOwner(offerID)
    {
        Offer storage offer = _getOwnerOffer(offerID);
        offer.expiresAt = expiresAt;
        emit SetExpireAt(offerID, expiresAt);
    }

    function cancelOffer(uint256 offerID) external onlyOfferOwner(offerID) {
        Offer memory offer = _getOwnerOffer(offerID);
        require(offer.expiresAt < block.timestamp, "Offer should be expired");
        delete offers[offerID];
        IERC1155(offer.collection).safeTransferFrom(
            address(this),
            offer.seller,
            offer.assetId,
            offer.amount,
            ""
        );
        emit CancelOffer(offerID);
    }

    function _getOwnerOffer(uint256 id) internal view returns (Offer storage) {
        Offer storage offer = offers[id];
        return offer;
    }

    function buyOffer(uint256 id, uint256 amount) external payable {
        Offer memory offer = offers[id];
        require(msg.value > 0, "price must be > 0");
        require(offer.isForSell, "Offer not for sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        _buyOffer(offer, id, amount, _msgSender());
        emit Swapped(
            _msgSender(),
            offer.seller,
            offer.collection,
            offer.assetId,
            msg.value
        );
    }

    /*
        This method is introduced to buy NFT with the help of a delegate.
        It will work as like buyOffer method, but instead transferring NFT to _msgSender address, it will transfer the NFT to buyer address.
        As its a payable method, it's highly unlikely that somebody would call this function for fishing or by mistake.
    */
    function delegateBuy(uint256 id, uint256 amount, address buyer) external payable {
        Offer memory offer = offers[id];
        require(msg.value > 0, "price must be > 0");
        require(offer.isForSell, "Offer not for sell");
        require(
            offer.expiresAt > block.timestamp,
            "Marketplace: offer expired"
        );
        _buyOffer(offer, id, amount, buyer);
        emit Swapped(
            buyer,
            offer.seller,
            offer.collection,
            offer.assetId,
            msg.value
        );
    }

    function _buyOffer(
        Offer memory offer,
        uint256 offerId,
        uint256 amount,
        address buyer
    ) internal {
        IERC1155 multipleNFTCollection = IERC1155(offer.collection);
        (uint256 ownerProfitAmount, uint256 sellerAmount) = YaaasLibrary
            .computePlateformOwnerProfitByAmount(
                msg.value,
                offer.price,
                amount,
                getFeebyIndex(offer.shareIndex)
            );
        sellerAmount = sendLoyaltyToCreatorFromETH(
            offer.collection,
            offer.assetId,
            offer.seller,
            sellerAmount
        );
        offers[offerId].amount = YaaasLibrary
            .extractPurshasedAmountFromOfferAmount(offer.amount, amount);
        TransferHelper.safeTransferETH(offer.seller, sellerAmount);
        TransferHelper.safeTransferETH(owner(), ownerProfitAmount);
        if (offer.amount == 0) delete offers[offerId];
        multipleNFTCollection.safeTransferFrom(
            address(this),
            buyer,
            offer.assetId,
            amount,
            new bytes(0)
        );
    }

    function safePlaceBid(
        uint256 _offer_id,
        address _token,
        uint256 _price,
        uint256 _amount
    ) external {
        _createBid(_offer_id, _token, _price, _amount);
    }

    function _createBid(
        uint256 offerID,
        address _token,
        uint256 _price,
        uint256 _amount
    ) internal {
        // Checks order validity
        Offer memory offer = offers[offerID];
        // check on expire time
        Bid memory bid = bidforAuctions[offerID][_msgSender()];
        require(bid.id == 0, "bid already exists");
        require(_token == offer.token);
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
        bidforAuctions[offerID][_msgSender()] = Bid({
            id: bidId,
            bidder: _msgSender(),
            token: _token,
            price: _price,
            amount: _amount
        });

        emit BidCreated(
            bidId,
            offer.collection,
            offer.assetId,
            _msgSender(), // bidder
            _token,
            _price,
            _amount
        );
    }

    function cancelBid(uint256 _offerId, address _bidder) external {
        Offer memory offer = _getOwnerOffer(_offerId);
        require(
            _bidder == _msgSender() || _msgSender() == offer.seller,
            "Marketplace: Unauthorized operation"
        );
        Bid memory bid = bidforAuctions[_offerId][_msgSender()];
        delete bidforAuctions[_offerId][_bidder];
        emit BidCancelled(bid.id);
    }

    function acceptBid(uint256 _offerID, address _bidder)
        external
        onlyOfferOwner(_offerID)
    {
        //get offer
        Offer memory offer = _getOwnerOffer(_offerID);
        // get bid to accept
        Bid memory bid = bidforAuctions[_offerID][_bidder];

        // get service fees
        (uint256 ownerProfitAmount, uint256 sellerAmount) = YaaasLibrary
            .computePlateformOwnerProfit(
                bid.price,
                bid.price,
                getFeebyIndex(offer.shareIndex)
            );
        // check seller
        sellerAmount = sendLoyaltyToCreatorFromERC20Token(
            offer.collection,
            offer.assetId,
            offer.seller,
            sellerAmount,
            bid.token,
            bid.bidder
        );
        require(
            offer.seller == _msgSender(),
            "Marketplace: unauthorized sender"
        );
        require(offer.isForAuction, "Marketplace: offer not in auction");
        require(
            offer.amount >= bid.amount,
            "Marketplace: insufficient balance"
        );

        delete bidforAuctions[_offerID][_bidder];
        emit BidAccepted(bid.id);
        // transfer escrowed bid amount minus market fee to seller
        TransferHelper.safeTransferFrom(
            bid.token,
            bid.bidder,
            _msgSender(),
            sellerAmount
        );
        TransferHelper.safeTransferFrom(
            bid.token,
            bid.bidder,
            owner(),
            ownerProfitAmount
        );

        offer.amount = YaaasLibrary.extractPurshasedAmountFromOfferAmount(
            offer.amount,
            bid.amount
        );

        if (offer.amount == 0) delete offers[_offerID];
        // Transfer NFT asset
        IERC1155(offer.collection).safeTransferFrom(
            address(this),
            bid.bidder,
            offer.assetId,
            bid.amount,
            ""
        );
        // Notify ..
        emit BidSuccessful(
            offer.collection,
            offer.assetId,
            bid.token,
            bid.bidder,
            bid.price,
            bid.amount
        );
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
 * @title A DEX for ERC1155 tokens (NFTs)
 */
interface IYaaasMultipleExchange {
    /**
     * @notice Put a single NFT in the market for sell & define loyalty NFT creator profit percentage
     * @dev Emit an ERC721 Token in sell
     * @param _id the NFT market identifier
     * @param _seller the token owner
     * @param _collection the ERC1155 address
     * @param _assetId the NFT id
     * @param _token the accepted ERC20 token for bid
     * @param _price the sale price
     * @param _amount the amount of NFT to put in sell
     * @param _isForSell  the token in direct sale
     * @param _isForAuction  the token in auctions
     * @param _expiresAt the offer's exprire date.
     * @param _shareIndex the percentage the contract owner earns in every sale
     * @param _loyaltyPercent  the percentage the NFT creator earns in every sale
     */
    function addLoyaltyOffer(
        uint256 _id,
        address _seller,
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price,
        uint256 _amount,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex,
        uint256 _loyaltyPercent
    ) external;

    /**
     * @notice Put a single NFT in the market for sell
     * @dev Emit an ERC721 Token in sell
     * @param _id the NFT market identifier
     * @param _seller the token owner
     * @param _collection the ERC1155 address
     * @param _assetId the NFT id
     * @param _token the accepted ERC20 token for bid
     * @param _price the sale price
     * @param _amount the amount of NFT to put in sell
     * @param _isForSell  the token in direct sale
     * @param _isForAuction  the token in auctions
     * @param _expiresAt the offer's exprire date.
     * @param _shareIndex the percentage the contract owner earns in every sale
     */
    function addOffer(
        uint256 _id,
        address _seller,
        address _collection,
        uint256 _assetId,
        address _token,
        uint256 _price,
        uint256 _amount,
        bool _isForSell,
        bool _isForAuction,
        uint256 _expiresAt,
        uint256 _shareIndex
    ) external;

    /**
     * @notice Set NFT's sell price in the market
     * @dev Set Offer price
     * @param _offerId the market NFT identifier
     * @param _price new minimun price to sell an NFT
     */
    function setOfferPrice(uint256 _offerId, uint256 _price) external;

    /**
     * @notice hide an NFT in direct sell from the market, or enable NFT's purshare in the market in direct sell
     * @dev Enable or disable an offer in direct sell
     * @param _offerId the market NFT identifier
     * @param _isForSell a boolean to make offer in direct sell or not
     */
    function setForSell(uint256 _offerId, bool _isForSell) external;

    /**
     * @notice hide an NFT in auction from the market, or enable NFT's purshare in the market in auction
     * @dev Enable or disable an offer in auction
     * @param _offerId the market NFT identifier
     * @param _isForAuction a boolean to make offer in auction or not
     */
    function setForAuction(uint256 _offerId, bool _isForAuction) external;

    /**
     * @dev set offer expire date
     * @param _offerId the market NFT identifier
     * @param _expiresAt new expire date
     */
    function setExpiresAt(uint256 _offerId, uint256 _expiresAt) external;

    /**
     * @notice Cancel an offer
     * @dev Lets an NFT owner cancel an NFT in sell when some requirements are met.
     * and withdraw  the concerned asset from the contract.
     * @param _offerId the market NFT identifier
     */
    function cancelOffer(uint256 _offerId) external;

    /**
     * @notice buy NFT Token
     * @dev Lets a user buy the NFT from the DEX. Function verifies that the amount
     * sent in wei is equal to that of the sale price. If it is, the contract
     * will accept the ether then compute the owner profit and NFT creator profit then transfer the NFT to the buyer.
     * After it's been transferred, the DEX then transfers the ether minus owner & creator profit
     * Deletes the struct from the mapping after.
     @param _offerId the market NFT identifier
     @param amount the amount user wants to purshase
     */
    function buyOffer(uint256 _offerId, uint256 amount) external payable;

    /**
     * @dev place a bid on an offer
     * @param _offerId the market NFT identifier
     * @param _token erc20 token address
     * @param _price the bid price
     * @param _amount the nft amount
     */
    function safePlaceBid(
        uint256 _offerId,
        address _token,
        uint256 _price,
        uint256 _amount
    ) external;

    /**
     * @dev cancelBid by owner or bidder
     * @param _offerId ERC721 collection address
     * @param _bidder bidder address
     */
    function cancelBid(uint256 _offerId, address _bidder) external;

    /**
     * @dev accept a bid by the offer's owner
     * @param _offerId ERC721 collection address
     * @param _bidder bidder address
     */
    function acceptBid(uint256 _offerId, address _bidder) external;

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
        uint256 price,
        uint256 amount
    );
    struct Offer {
        address seller;
        address collection;
        uint256 assetId;
        address token;
        uint256 price;
        uint256 amount;
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
        uint256 amount;
    }
    // BID EVENTS
    event BidCreated(
        bytes32 id,
        address indexed collection,
        uint256 indexed assetId,
        address indexed bidder,
        address token,
        uint256 price,
        uint256 amount
    );
    event BidSuccessful(
        address collection,
        uint256 assetId,
        address token,
        address bidder,
        uint256 price,
        uint256 amount
    );
    event BidAccepted(bytes32 id);
    event BidCancelled(bytes32 id);
    event SetOfferPrice(uint256 _offerId, uint256 price);
    event SetForSell(uint256 _offerId, bool isForSell);
    event SetForAuction(uint256 _offerId, bool isForAuction);
    event SetExpireAt(uint256 _offerId, uint256 expiresAt);
    event CancelOffer(uint256 _offerId);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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