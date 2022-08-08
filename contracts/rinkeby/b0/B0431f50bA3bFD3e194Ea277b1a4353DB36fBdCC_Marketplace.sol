// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

import "./Splitter.sol";

contract Marketplace is Ownable, ReentrancyGuard, IERC777Recipient {
    string public name; // conctract name
    uint16 public totalSupply; // number of NFTs in circulation
    uint16 public royalty; // royalty percentage (expressed in tenthousandths 0-10000, this gives two decimal resolution)

    address public tokenContractAddress; // ERC721 NFT contract address
    IERC721 private tokenContract; // ERC721 NFT token contract

    address public dustContractAddress; // ERC777 NFT token address (DUST)
    IERC777 private dustContract; // DUST ERC777 NFT token contract (DUST)

    address payable public splitterContractAddress; // Splitter contract for splitting royalty address
    Splitter private splitterContract; // Splitter contract for splitting royalty

    IERC1820Registry private _erc1820 =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    struct Offer {
        bool isForSale; // cariable to check sale status
        address seller; // seller address
        uint256 value; // in ether
        address onlySellTo; // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid; // variable to check bid status
        address bidder; // bidder address
        uint256 value; // in ether or DUST
    }

    // map offers and bids for each token
    mapping(uint256 => Offer) public cardsForSaleInETH; // list of cards of for sale in ETH
    mapping(uint256 => Offer) public cardsForSaleInDust; // list of cards of for sale in DUST
    mapping(uint256 => Bid) public etherBids; // list of ether bids on cards
    mapping(uint256 => Bid) public dustBids; // list of DUST bids on cards
    mapping(address => bool) public permitted; // permitted to modify owner royalty
    mapping(address => uint256) private bidsDustReceived; // mapping from bidder address to DUST received from address

    event OfferForSale(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );
    event OfferExecuted(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );
    event OfferRevoked(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );

    event OfferModified(
        address _from,
        uint16 _tokenId,
        uint256 _value,
        address _sellOnlyTo,
        bool _isDust
    );

    event BidReceived(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _newValue,
        uint256 _prevValue,
        bool _isDust
    );

    event BidAccepted(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );

    event BidRevoked(
        address _from,
        uint16 _tokenId,
        uint256 _value,
        bool _isDust
    );

    event RoyaltyChanged(address _from, uint16 _royalty);

    modifier onlyCardOwner(uint16 _tokenId) {
        // need to check before calling ownerOf()
        require(_tokenId < totalSupply, "Invalid token ID!");
        require(
            tokenContract.ownerOf(_tokenId) == msg.sender,
            "Sender does not own this token."
        );
        _;
    }

    constructor(
        string memory _name,
        address _tokenContractAddress,
        address _dustContractAddress,
        address payable _splitterContractAddress,
        uint16 _totalSupply,
        uint16 _royalty
    ) {
        name = _name; // set the name for display purposes
        totalSupply = _totalSupply; // set total supply for token
        setRoyalty(_royalty); // set royalty

        // initialize the 721 NFT contract
        require(
            _tokenContractAddress != address(0),
            "Splitter contract address cannot be ZERO address."
        );
        tokenContractAddress = _tokenContractAddress;
        tokenContract = IERC721(_tokenContractAddress);

        // initialize the Splitter contract
        require(
            _splitterContractAddress != address(0),
            "Splitter contract address cannot be ZERO address."
        );
        splitterContractAddress = _splitterContractAddress;
        splitterContract = Splitter(_splitterContractAddress);

        // initalize DUST contract
        require(
            _dustContractAddress != address(0),
            "Dust contract address cannot be ZERO address."
        );
        dustContractAddress = _dustContractAddress;
        dustContract = IERC777(_dustContractAddress);

        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        ); // register self with IERC1820 registry
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        // handle incoming DUST when bids are made
        require(msg.sender == dustContractAddress, "Invalid token!");
        bidsDustReceived[from] += amount;
    }

    function _split(address _seller, uint256 _amount) internal {
        uint256 royaltyAmount = (_amount * royalty) / 10000;

        bool success;
        (success, ) = splitterContractAddress.call{value: royaltyAmount}("");
        require(success, "Transfer failed!");

        uint256 sellerAmount = _amount - royaltyAmount;
        (success, ) = _seller.call{value: sellerAmount}("");
        require(success, "Transfer failed!");
    }

    function _splitDust(
        address _buyer,
        address _seller,
        uint256 _amount
    ) internal {
        // in case of Dust transaction, send Dust to Splitter's ERC777 account
        uint256 royaltyAmount = (_amount * royalty) / 10000;
        dustContract.operatorSend(
            _buyer,
            splitterContractAddress,
            royaltyAmount,
            "",
            ""
        );

        uint256 sellerAmount = _amount - royaltyAmount;
        dustContract.operatorSend(_buyer, _seller, sellerAmount, "", "");
    }

    function offerCardForSaleSellOnlyTo(
        uint16 _tokenId,
        uint256 _minPrice,
        address _sellOnlyTo
    ) external onlyCardOwner(_tokenId) {
        // check if the contract is approved by token owner
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // check if card id is correct
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        // check if price is set to higher than 0
        require(_minPrice > 0, "Price should be higher than 0.");
        require(
            _sellOnlyTo != address(0),
            "Sell only to address cannot be null."
        );
        require(
            _sellOnlyTo != msg.sender,
            "Sell only to address cannot be self."
        );
        // initialize offer for only 1 buyer - _sellOnlyTo
        cardsForSaleInETH[_tokenId] = Offer(
            true,
            msg.sender,
            _minPrice,
            _sellOnlyTo
        );

        // emit sale event
        emit OfferForSale(msg.sender, _sellOnlyTo, _tokenId, _minPrice, false);
    }

    function offerCardForSale(uint16 _tokenId, uint256 _minPriceInWei)
        external
        onlyCardOwner(_tokenId)
    {
        // check if the contract is approved by token owner
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // check if card id is correct
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        // check if price is set to higher than 0
        require(_minPriceInWei > 0, "Price should be higher than 0.");

        // initialize offer for only 1 buyer - _sellOnlyTo
        cardsForSaleInETH[_tokenId] = Offer(
            true,
            msg.sender,
            _minPriceInWei,
            address(0)
        );

        // emit sale event
        emit OfferForSale(
            msg.sender,
            address(0),
            _tokenId,
            _minPriceInWei,
            false
        );
    }

    function offerCardForSaleInDust(uint16 _tokenId, uint256 _minPrice)
        external
        onlyCardOwner(_tokenId)
    {
        // check if the contract is approved by token owner
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // check if card id is correct
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        // check if price is set to higher than 0
        require(_minPrice > 0, "Price should be higher than 0.");

        // initialize offer for only 1 buyer - _sellOnlyTo
        cardsForSaleInDust[_tokenId] = Offer(
            true,
            msg.sender,
            _minPrice,
            address(0)
        );

        // emit sale event
        emit OfferForSale(msg.sender, address(0), _tokenId, _minPrice, true);
    }

    function offerCardForSaleInDustSellOnlyTo(
        uint16 _tokenId,
        uint256 _minPrice,
        address _sellOnlyTo
    ) external onlyCardOwner(_tokenId) {
        // check if the contract is approved by token owner
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // check if card id is correct
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        // check if price is set to higher than 0
        require(_minPrice > 0, "Price should be higher than 0.");
        // make sure sell only to is not 0x0
        require(
            _sellOnlyTo != address(0),
            "Sell only to address cannot be null."
        );

        // make sure sell only to address is not self
        require(
            _sellOnlyTo != msg.sender,
            "Sell only to address cannot be self."
        );

        // initialize offer for only 1 buyer - _sellOnlyTo
        cardsForSaleInDust[_tokenId] = Offer(
            true,
            msg.sender,
            _minPrice,
            _sellOnlyTo
        );

        // emit sale event
        emit OfferForSale(msg.sender, _sellOnlyTo, _tokenId, _minPrice, true);
    }

    function modifyEtherOffer(
        uint16 _tokenId,
        uint256 _value,
        address _sellOnlyTo
    ) external onlyCardOwner(_tokenId) {
        Offer memory offer = cardsForSaleInETH[_tokenId];

        require(offer.isForSale, "No offer exists for this token!");
        require(_value > 0, "Price should be higher than 0.");
        require(
            _sellOnlyTo != msg.sender,
            "Sell only to address cannot be self!"
        );

        // modify offer
        cardsForSaleInETH[_tokenId] = Offer(
            offer.isForSale,
            offer.seller,
            _value,
            _sellOnlyTo
        );
        emit OfferModified(msg.sender, _tokenId, _value, _sellOnlyTo, false);
    }

    function modifyDustOffer(
        uint16 _tokenId,
        uint256 _value,
        address _sellOnlyTo
    ) external onlyCardOwner(_tokenId) {
        Offer memory offer = cardsForSaleInDust[_tokenId];

        require(offer.isForSale, "No offer exists for this token!");
        require(_value > 0, "Price should be higher than 0.");
        require(
            _sellOnlyTo != msg.sender,
            "Sell only to address cannot be self!"
        );

        // modify offer
        require(_value > 0, "Price should be higher than 0.");
        cardsForSaleInDust[_tokenId] = Offer(
            offer.isForSale,
            offer.seller,
            _value,
            _sellOnlyTo
        );
        emit OfferModified(msg.sender, _tokenId, _value, _sellOnlyTo, true);
    }

    function revokeEtherOffer(uint16 _tokenId)
        external
        onlyCardOwner(_tokenId)
    {
        Offer memory offer = cardsForSaleInETH[_tokenId];
        require(offer.isForSale, "No offer exists for this token.");

        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        emit OfferRevoked(
            offer.seller,
            offer.onlySellTo,
            _tokenId,
            offer.value,
            false
        );
    }

    function revokeDustOffer(uint16 _tokenId) external onlyCardOwner(_tokenId) {
        Offer memory offer = cardsForSaleInDust[_tokenId];
        require(offer.isForSale, "No offer exists for this token.");

        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));
        emit OfferRevoked(
            offer.seller,
            offer.onlySellTo,
            _tokenId,
            offer.value,
            true
        );
    }

    function buyItNowForEther(uint16 _tokenId) external payable nonReentrant {
        Offer memory offer = cardsForSaleInETH[_tokenId];
        // check if the offer is valid
        require(offer.isForSale, "This token is not for sale.");
        require(offer.seller != address(0), "This token is not for sale.");
        require(offer.value > 0, "This token is not for sale.");

        // check if it is for sale for someone specific
        if (offer.onlySellTo != address(0)) {
            // only sell to someone specific
            require(
                offer.onlySellTo == msg.sender,
                "This coin can be sold only for a specific address."
            );
        }

        // make sure buyer is not the owner
        require(
            msg.sender != tokenContract.ownerOf(_tokenId),
            "Buyer already owns this token."
        );

        // check approval status, user may have modified transfer approval
        require(
            tokenContract.isApprovedForAll(offer.seller, address(this)),
            "Contract is not approved."
        );

        // check if offer value and sent values match
        require(
            offer.value == msg.value,
            "Offer ask price and sent ETH mismatch!"
        );

        // make sure the seller is the owner
        require(
            offer.seller == tokenContract.ownerOf(_tokenId),
            "Seller no longer owns this token."
        );

        // save the seller variable
        address seller = offer.seller;

        // reset offers for this card
        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));

        // check if there were any ether bids on this card
        Bid memory bid = etherBids[_tokenId];
        if (bid.hasBid) {
            // save bid values and bidder variables
            address bidder = bid.bidder;
            uint256 amount = bid.value;
            // reset bid
            etherBids[_tokenId] = Bid(false, address(0), 0);
            // send back bid value to bidder
            bool sent;
            (sent, ) = bidder.call{value: amount}("");
            require(sent, "Failed to send back ether to bidder.");
        }

        // check if there were any DUST bids on this card
        Bid memory dustBid = dustBids[_tokenId];
        if (dustBid.hasBid) {
            // save bid values and bidder variables
            address bidder = dustBid.bidder;
            uint256 amount = dustBid.value;
            // reset bid
            etherBids[_tokenId] = Bid(false, address(0), 0);
            // send back bid value to bidder
            dustContract.operatorSend(address(this), bidder, amount, "", "");
        }

        // first send the token to the buyer
        tokenContract.safeTransferFrom(seller, msg.sender, _tokenId);

        // transfer ether to acceptor and pay royalty to the community owner
        _split(seller, offer.value);

        // check if the user recieved the item
        require(tokenContract.ownerOf(_tokenId) == msg.sender);

        // emit event
        emit OfferExecuted(
            offer.seller,
            msg.sender,
            _tokenId,
            offer.value,
            false
        );
    }

    function buyItNowForDust(uint16 _tokenId) external nonReentrant {
        Offer memory offer = cardsForSaleInDust[_tokenId];
        // check if the offer is valid
        require(offer.isForSale, "This token is not for sale.");
        require(offer.seller != address(0), "This token is not for sale.");
        require(offer.value > 0, "This token is not for sale.");

        // check if it is for sale for someone specific
        if (offer.onlySellTo != address(0)) {
            // only sell to someone specific
            require(
                offer.onlySellTo == msg.sender,
                "This coin can be sold only for a specific address."
            );
        }

        // make sure buyer is not the owner
        require(
            msg.sender != tokenContract.ownerOf(_tokenId),
            "Buyer already owns this token."
        );

        // check approval status, user may have modified transfer approval
        require(
            tokenContract.isApprovedForAll(offer.seller, address(this)),
            "Contract is not approved."
        );

        // check if buyer has enough Dust to purchase
        require(
            dustContract.balanceOf(msg.sender) >= offer.value,
            "Not enough DUST!"
        );

        // make sure the seller is the owner
        require(
            offer.seller == tokenContract.ownerOf(_tokenId),
            "Seller no longer owns this token."
        );

        // save the seller variable
        address seller = offer.seller;

        // reset offers for this card
        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));

        // check if there were any ether bids on this card
        Bid memory bid = etherBids[_tokenId];
        if (bid.hasBid) {
            // save bid values and bidder variables
            address bidder = bid.bidder;
            uint256 amount = bid.value;
            // reset bid
            etherBids[_tokenId] = Bid(false, address(0), 0);
            // send back bid value to bidder
            bool sent;
            (sent, ) = bidder.call{value: amount}("");
            require(sent, "Failed to send back ether to bidder.");
        }

        // check if there were any DUST bids on this card
        Bid memory dustBid = dustBids[_tokenId];
        if (dustBid.hasBid) {
            // save bid values and bidder variables
            address bidder = dustBid.bidder;
            uint256 amount = dustBid.value;
            // reset bid
            etherBids[_tokenId] = Bid(false, address(0), 0);
            // send back bid value to bidder
            dustContract.operatorSend(address(this), bidder, amount, "", "");
        }

        // first send the token to the buyer
        tokenContract.safeTransferFrom(seller, msg.sender, _tokenId);

        // transfer dust to acceptor and pay royalty to the community owner
        _splitDust(msg.sender, seller, offer.value);

        // check if the user recieved the item
        require(tokenContract.ownerOf(_tokenId) == msg.sender);

        // emit event
        emit OfferExecuted(
            offer.seller,
            msg.sender,
            _tokenId,
            offer.value,
            true
        );
    }

    function bidOnCardWithEther(uint16 _tokenId) external payable nonReentrant {
        // check if card id is valid
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        address cardOwner = tokenContract.ownerOf(_tokenId);
        // make sure the bidder is not the owner
        require(msg.sender != cardOwner, "Cannot bid on owned card.");
        // check if bid value is valid
        require(msg.value > 0, "Bid price has to be higher than 0.");

        Bid memory bid = etherBids[_tokenId];
        // initialize the bid with the new values
        etherBids[_tokenId] = Bid(true, msg.sender, msg.value);

        // emit event
        emit BidReceived(
            msg.sender,
            cardOwner,
            _tokenId,
            msg.value,
            bid.value,
            false
        );

        // check if there were any bids on this card
        if (bid.hasBid) {
            // the current bid has to be higher than the previous
            require(bid.value < msg.value, "Bid price is below current bid.");
            address previousBidder = bid.bidder;
            uint256 amount = bid.value;
            // pay back the previous bidder's ether
            bool sent;
            (sent, ) = previousBidder.call{value: amount}("");
            require(sent, "Failed to send back ether to previous bidder.");
        }
    }

    function bidOnCardWithDust(uint16 _tokenId, uint256 _bidValue)
        external
        nonReentrant
    {
        require(
            _tokenId < totalSupply,
            "Token ID should be smaller than total supply."
        );
        address cardOwner = tokenContract.ownerOf(_tokenId);
        // make sure the bidder is not the owner
        require(msg.sender != cardOwner, "Cannot bid on owned card.");
        // check if bid value is valid
        require(_bidValue > 0, "Bid price has to be higher than 0.");
        // check if bid value is valid
        require(
            dustContract.balanceOf(msg.sender) >= _bidValue,
            "Not enough DUST!"
        );
        Bid memory bid = dustBids[_tokenId];
        // initialize the bid with the new values
        dustBids[_tokenId] = Bid(true, msg.sender, _bidValue);

        // emit event
        emit BidReceived(
            msg.sender,
            cardOwner,
            _tokenId,
            _bidValue,
            bid.value,
            true
        );

        // check if there were any bids on this card
        if (bid.hasBid) {
            // the current bid has to be higher than the previous
            require(bid.value < _bidValue, "Bid price is below current bid.");
            address previousBidder = bid.bidder;
            uint256 amount = bid.value;
            // pay back the previous bidder's ether
            dustContract.operatorSend(
                address(this),
                previousBidder,
                amount,
                "",
                ""
            );
        }

        // move DUST into marketplace contract
        dustContract.operatorSend(msg.sender, address(this), _bidValue, "", "");
    }

    function acceptEtherBid(uint16 _tokenId) external onlyCardOwner(_tokenId) {
        Bid memory bid = etherBids[_tokenId];

        // make sure there is a valid bid on the card
        require(bid.hasBid, "This token has no bid on it.");
        // check if the contract is still approved for transfer
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // reset offers for this token
        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));

        address buyer = bid.bidder;
        uint256 amount = bid.value;

        Bid memory dustBid = dustBids[_tokenId];

        // reset bids
        etherBids[_tokenId] = Bid(false, address(0), 0);
        dustBids[_tokenId] = Bid(false, address(0), 0);

        // refund dust for bidder if any
        if (dustBid.hasBid) {
            dustContract.send(dustBid.bidder, dustBid.value, "");
        }

        // transfer ether to acceptor and pay royalty to the community owner
        _split(msg.sender, amount);
        // send token from acceptor to the bidder
        tokenContract.safeTransferFrom(msg.sender, buyer, _tokenId);

        // check if the user received the token
        require(tokenContract.ownerOf(_tokenId) == buyer);

        // emit event
        emit BidAccepted(msg.sender, bid.bidder, _tokenId, amount, false);
    }

    function acceptDustBid(uint16 _tokenId)
        external
        onlyCardOwner(_tokenId)
        nonReentrant
    {
        Bid memory bid = dustBids[_tokenId];

        // make sure there is a valid bid on the card
        require(bid.hasBid, "This token has no bid on it.");
        // check if the contract is still approved for transfer
        require(
            tokenContract.isApprovedForAll(msg.sender, address(this)),
            "Contract is not approved."
        );

        // reset offers for this token
        cardsForSaleInETH[_tokenId] = Offer(false, address(0), 0, address(0));
        cardsForSaleInDust[_tokenId] = Offer(false, address(0), 0, address(0));

        address buyer = bid.bidder;
        uint256 amount = bid.value;

        Bid memory etherBid = etherBids[_tokenId];
        // reset bids
        etherBids[_tokenId] = Bid(false, address(0), 0);
        dustBids[_tokenId] = Bid(false, address(0), 0);

        // refund current ether bid if any
        if (etherBid.hasBid) {
            (bool success, ) = etherBid.bidder.call{value: etherBid.value}("");
            require(success, "Transfer failed!");
        }

        // transfer ether to acceptor and pay royalty to the community owner
        _splitDust(address(this), msg.sender, amount);

        // send token from acceptor to the bidder
        tokenContract.safeTransferFrom(msg.sender, buyer, _tokenId);

        // check if the user received the token
        require(tokenContract.ownerOf(_tokenId) == buyer);

        // emit event
        emit BidAccepted(msg.sender, bid.bidder, _tokenId, amount, true);
    }

    function revokeEtherBid(uint16 _tokenId) external {
        Bid memory bid = etherBids[_tokenId];
        // check if the bid exists
        require(bid.hasBid, "This token has no bid on it.");
        // check if the bidder is the sender of the message
        require(
            bid.bidder == msg.sender,
            "Sender is not the current highest bidder."
        );
        // save bid value into a variable
        uint256 amount = bid.value;

        // reset bid
        etherBids[_tokenId] = Bid(false, address(0), 0);

        // emit event
        emit BidRevoked(msg.sender, _tokenId, amount, false);

        // transfer back their ether
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to retrieve ether.");
    }

    function revokeDustBid(uint16 _tokenId) external {
        Bid memory bid = dustBids[_tokenId];
        // check if the bid exists
        require(bid.hasBid, "This token has no bid on it.");
        // check if the bidder is the sender of the message
        require(
            bid.bidder == msg.sender,
            "Sender is not the current highest bidder."
        );
        // save bid value into a variable
        uint256 amount = bid.value;

        // reset bid
        dustBids[_tokenId] = Bid(false, address(0), 0);

        // emit event
        emit BidRevoked(msg.sender, _tokenId, amount, true);

        // refund DUST
        dustContract.send(msg.sender, amount, "");
    }

    // getters

    function getEtherOfferValueForCard(uint16 _tokenId)
        external
        view
        returns (uint256)
    {
        return cardsForSaleInETH[_tokenId].value;
    }

    function getDustOfferValueForCard(uint16 _tokenId)
        external
        view
        returns (uint256)
    {
        return cardsForSaleInDust[_tokenId].value;
    }

    function getSellOnlyToAddressForOffer(uint16 _tokenId, bool _dust)
        internal
        view
        returns (address)
    {
        require(_tokenId < totalSupply, "Invalid token ID!");
        Offer memory offer = cardsForSaleInETH[_tokenId];
        if (_dust) {
            offer = cardsForSaleInDust[_tokenId];
        }
        require(offer.isForSale, "This token is not for sale!");
        return offer.onlySellTo;
    }

    function getSellOnlyToAddressForDustOffer(uint16 _tokenId)
        external
        view
        returns (address)
    {
        return getSellOnlyToAddressForOffer(_tokenId, true);
    }

    function getSellOnlyToAddressForEtherOffer(uint16 _tokenId)
        external
        view
        returns (address)
    {
        return getSellOnlyToAddressForOffer(_tokenId, false);
    }

    function getHighestBidForCard(uint16 _tokenId, bool _dust)
        internal
        view
        returns (uint256)
    {
        require(_tokenId < totalSupply, "Invalid token ID!");
        Bid memory bid = etherBids[_tokenId];
        if (_dust) {
            bid = dustBids[_tokenId];
        }
        require(bid.hasBid, "This token has no bid on it!");
        return bid.value;
    }

    function getHighestEtherBidForCard(uint16 _tokenId)
        external
        view
        returns (uint256)
    {
        return getHighestBidForCard(_tokenId, false);
    }

    function getHighestDustBidForCard(uint16 _tokenId)
        external
        view
        returns (uint256)
    {
        return getHighestBidForCard(_tokenId, true);
    }

    function getHighestBidder(uint16 _tokenId, bool _dust)
        internal
        view
        returns (address)
    {
        require(_tokenId < totalSupply, "Invalid token ID!");
        Bid memory bid = etherBids[_tokenId];
        if (_dust) {
            bid = dustBids[_tokenId];
        }
        require(bid.hasBid, "This token has no bid on it!");
        return bid.bidder;
    }

    function getHighestEtherBidderForCard(uint16 _tokenId)
        external
        view
        returns (address)
    {
        return getHighestBidder(_tokenId, false);
    }

    function getHighestDustBidderForCard(uint16 _tokenId)
        external
        view
        returns (address)
    {
        return getHighestBidder(_tokenId, true);
    }

    function setRoyalty(uint16 _royalty) public onlyOwner {
        require(royalty <= 10000, "Royalty value should be below 10000.");
        royalty = _royalty;
        emit RoyaltyChanged(msg.sender, _royalty);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

contract Splitter is IERC777Recipient, Ownable {
    event ETHPaymentReceived(address from, uint256 amount);
    event DUSTPaymentReceived(address from, uint256 amount);

    event CommunityShareChanged(address _from, uint256 _share);
    event CompanyShareChanged(address _from, uint256 _share);
    event ArtistShareChanged(
        address _from,
        uint256 _share,
        uint256 _artistIndex
    );

    event CommunityOwnerAddressChanged(address _address);
    event CompanyAddressChanged(address _address);
    event ArtistAddressChanged(address _address, uint256 _artistIndex);

    address private tokenContractAddress; // ERC777 NFT contract address
    address private communityOwnerAddress; // community owner, provide in constructor
    address private companyAddress; // company address, provide in constructor
    address[] private artistAddresses;

    uint256 private companyShares;
    uint256 private communityShares;
    uint256[] private artistShares; //index of share corresponding to artist should match index of artis in artistAddresses

    IERC777 private tokenContract; // DUST ERC777 NFT token contract

    IERC1820Registry private _erc1820 =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    constructor(
        address _communityOwnerAddress,
        address _companyAddress,
        uint256 _companyShares,
        uint256 _communityShares,
        address[] memory _artistAddresses,
        uint256[] memory _artistShares,
        address _tokenContractAddress
    ) {
        require(
            _communityOwnerAddress != address(0),
            "Cannot be ZERO address."
        );
        require(_companyAddress != address(0), "Cannot be ZERO address.");
        communityOwnerAddress = _communityOwnerAddress;
        companyAddress = _companyAddress;

        require(
            _artistShares.length <= 5,
            "At most 5 artists in splitter contract"
        );
        require(
            _artistShares.length == _artistAddresses.length,
            "Artist address or artist shares missing"
        );
        for (uint256 i = 0; i < _artistAddresses.length; i++) {
            require(
                _artistAddresses[i] != address(0),
                "Cannot be ZERO address."
            );
            artistAddresses.push(_artistAddresses[i]);
        }
        for (uint256 i = 0; i < _artistShares.length; i++) {
            require(
                _artistShares[i] > 0,
                "Artist shares must be positive integer!"
            );
            artistShares.push(_artistShares[i]);
        }

        require(
            _communityShares > 0,
            "Community shares must be positive integer!"
        );
        communityShares = _communityShares;

        require(_companyShares > 0, "Company shares must be positive integer!");
        companyShares = _companyShares;
        
        require(_tokenContractAddress != address(0), "Token contract cannot be ZERO address.");
        tokenContractAddress = _tokenContractAddress;
        tokenContract = IERC777(_tokenContractAddress); // initialize the NFT contract
        _erc1820.setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        ); // register self with IERC1820 registry
    }

    // split upon receiving ETH payment
    receive() external payable virtual {
        emit ETHPaymentReceived(msg.sender, msg.value);
        bool success;

        uint256 _totalShares = getTotalShares();
        uint256 communityPayment = (communityShares * msg.value) / _totalShares;
        (success, ) = communityOwnerAddress.call{value: communityPayment}("");
        require(success, "Transfer failed.");

        uint256 companyPayment = (companyShares * msg.value) / _totalShares;
        (success, ) = companyAddress.call{value: companyPayment}("");
        require(success, "Transfer failed.");

        for (uint256 i = 0; i < artistShares.length; i++) {
            uint256 artistPayment = (artistShares[i] * msg.value) /
                _totalShares;
            (success, ) = artistAddresses[i].call{value: artistPayment}("");
            require(success, "Transfer failed.");
        }
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        require(msg.sender == tokenContractAddress, "Invalid token!");
        // Tokens were sent to the splitter
        emit DUSTPaymentReceived(from, amount);
        uint256 _totalShares = getTotalShares();
        uint256 communityPayment = (communityShares * amount) / _totalShares;
        tokenContract.send(communityOwnerAddress, communityPayment, "");

        uint256 companyPayment = (companyShares * amount) / _totalShares;
        tokenContract.send(companyAddress, companyPayment, "");
        for (uint256 i = 0; i < artistShares.length; i++) {
            uint256 artistPayment = (artistShares[i] * amount) / _totalShares;
            tokenContract.send(artistAddresses[i], artistPayment, "");
        }
    }

    function getTotalShares() public view returns (uint256) {
        uint256 _totalShares = communityShares + companyShares;
        for (uint256 i = 0; i < artistShares.length; i++) {
            _totalShares = _totalShares + artistShares[i];
        }
        return _totalShares;
    }

    function setCompanyShares(uint256 _shares) external onlyOwner {
        require(_shares > 0, "Company shares must be positive integer!");
        companyShares = _shares;
        emit CompanyShareChanged(msg.sender, _shares);
    }

    function getCompanyShares() external view returns (uint256) {
        return companyShares;
    }

    function setCommunityShares(uint256 _shares) external onlyOwner {
        require(_shares > 0, "Community shares must be positive integer!");
        communityShares = _shares;
        emit CommunityShareChanged(msg.sender, _shares);
    }

    function getCommunityShares() external view returns (uint256) {
        return communityShares;
    }

    function setArtistShares(uint256 _shares, uint256 _artistIndex)
        external
        onlyOwner
    {
        require(_artistIndex < artistAddresses.length, "Invalid index!");
        require(_shares > 0, "Artist shares must be positive integer!");
        artistShares[_artistIndex] = _shares;
        emit ArtistShareChanged(msg.sender, _shares, _artistIndex);
    }

    function getArtistShares() external view returns (uint256[] memory) {
        return artistShares;
    }

    function getCommunityOwnerAddress() external view returns (address) {
        return communityOwnerAddress;
    }

    // change community owner address
    function setCommunityOwnerAddress(address _communityOwnerAddress)
        external
        onlyOwner
    {
        require(
            _communityOwnerAddress != address(0),
            "Cannot be ZERO address."
        );
        communityOwnerAddress = _communityOwnerAddress;
        emit CommunityOwnerAddressChanged(communityOwnerAddress);
    }

    function getCompanyAddress() external view returns (address) {
        return companyAddress;
    }

    // change company address
    function setCompanyAddress(address _companyAddress) external onlyOwner {
        require(_companyAddress != address(0), "Cannot be ZERO address.");
        companyAddress = _companyAddress;
        emit CompanyAddressChanged(companyAddress);
    }

    function getArtistAddresses() external view returns (address[] memory) {
        return artistAddresses;
    }

    function setArtistAddress(address _address, uint256 _artistIndex)
        external
        onlyOwner
    {
        require(_artistIndex < artistAddresses.length, "Invalid index!");
        require(_address != address(0), "Cannot be ZERO address.");
        artistAddresses[_artistIndex] = _address;
        emit ArtistAddressChanged(_address, _artistIndex);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}