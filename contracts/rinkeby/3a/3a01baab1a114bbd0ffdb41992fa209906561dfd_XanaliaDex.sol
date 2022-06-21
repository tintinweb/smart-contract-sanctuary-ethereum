//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/IXanaliaDex.sol";
import "./interfaces/IMarketDex.sol";
import "./interfaces/IAuctionDex.sol";
import "./interfaces/IOfferDex.sol";
import "./interfaces/IXanaliaNFT.sol";
import "./interfaces/IXanaliaAddressesStorage.sol";
import "./interfaces/ICollectionDeployer.sol";

/**
 * :> Xanalia Dex
 * :> This contract is a main dex of xanalia's system, responsible of creating & tracking collections, collectibles of user.
 */
contract Manager is Initializable, OwnableUpgradeable, PausableUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using AddressUpgradeable for address payable;

	IXanaliaAddressesStorage public xanaliaAddressesStorage;

	uint256 public constant BASE_DENOMINATOR = 10_000;
	address public xanaliaAddressesStorageAddress;
	uint256 public platformFee;
	uint256 public collectionCount;
	bool internal processing;

	mapping(uint256 => address) public collectionAddresses;
	mapping(address => address[]) public collections;
	mapping(address => bool) public isUserCollection;
	mapping(address => bool) public isUserWhitelisted;
	mapping(address => bool) public isWhitelistApprover;
	mapping(address => bool) public paymentMethod;

	// events collection
	event CollectionCreated(address indexed creator, address indexed collection, string name, string symbol);
	event CollectibleCreated(address indexed owner, uint256 indexed collectibleId);

	// events fixed price
	event OrderCreated(uint256 _orderId, address _collectionAddress, uint256 _tokenId, uint256 _price);
	event Buy(uint256 _itemId, address _paymentToken, uint256 _paymentAmount);
	event OrderCancelled(uint256 indexed _orderId);
	event OrderEdited(uint256 indexed _orderId, uint256 indexed _oldOrderId, uint256 _price);

	// events auction
	event AuctionCreated(uint256 _auctionId, address _collectionAddress, uint256 _tokenId);
	event BidAuctionCreated(
		uint256 indexed _bidAuctionId,
		address _collectionAddress,
		uint256 indexed _tokenId,
		uint256 _price,
		address _paymentToken
	);
	event AuctionCanceled(uint256 indexed _auctionId);
	event BidAuctionCanceled(uint256 indexed _bidAuctionId);
	event BidAuctionClaimed(uint256 indexed _bidAuctionId);
	event AuctionReclaimed(uint256 indexed _auctionId);

	// events offer
	event OfferCreated(
		uint256 indexed _offerId,
		address _collectionAddress,
		uint256 indexed _tokenId,
		uint256 _price,
		address _paymentToken
	);
	event AcceptOffer(uint256 indexed _offerId);
	event OfferCancelled(uint256 indexed _offerId);

	// events setting
	event PlatformFeeChanged(uint256 _platformFee);
	event PaymentMethodChanged(address _paymentToken, bool _accepted);
	event FundsWithdrawed(address _collectionAddress, uint256 _amount);

	// events list
	event WhitelistAddressSet(address indexed admin, uint256 indexed numberAddress);
	event WhitelistApproverSet(address indexed approver, bool indexed status);

	function initialize(uint256 _platformFee, address _xanaliaAddressesStorage) public virtual initializer {
		PausableUpgradeable.__Pausable_init();
		OwnableUpgradeable.__Ownable_init();
		platformFee = _platformFee;
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
		xanaliaAddressesStorageAddress = _xanaliaAddressesStorage;
		processing = false;
	}

	receive() external payable {}

	modifier onlyNotProcessing() {
		require(!processing, "Invalid processing");
		processing = true;
		_;
		processing = false;
	}

	modifier onlyApprover() {
		require(isWhitelistApprover[msg.sender], "Not whitelist approver");
		_;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unPause() public onlyOwner {
		_unpause();
	}

	/**
	 * @notice withdrawFunds
	 */
	function withdrawFunds(address payable _beneficiary, address _tokenAddress) external onlyOwner whenPaused {
		uint256 _withdrawAmount;
		if (_tokenAddress == address(0)) {
			_beneficiary.transfer(address(this).balance);
			_withdrawAmount = address(this).balance;
		} else {
			_withdrawAmount = IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
			IERC20Upgradeable(_tokenAddress).safeTransfer(_beneficiary, _withdrawAmount);
		}
		emit FundsWithdrawed(_tokenAddress, _withdrawAmount);
	}

	function setApproveForAllERC721(address _collectionAddress, address _spender) external {
		IERC721Upgradeable(_collectionAddress).setApprovalForAll(_spender, true);
	}

	function setPlatformFee(uint256 _platformFee) external onlyOwner {
		require(_platformFee <= BASE_DENOMINATOR, "Invalid platform fee");
		platformFee = _platformFee;
		emit PlatformFeeChanged(_platformFee);
	}

	function setPaymentMethod(address _token, bool _status) external onlyOwner returns (bool) {
		require(paymentMethod[_token] != _status, "This status already set");
		paymentMethod[_token] = _status;
		emit PaymentMethodChanged(_token, _status);
		return true;
	}

	/**
	@notice Set approver for whitelist
	@param _user address of approver
	@param _status status of address
	*/
	function setWhitelistApproverRole(address _user, bool _status) external onlyOwner {
		require(isWhitelistApprover[_user] != _status, "This status aldready set");
		isWhitelistApprover[_user] = _status;
		emit WhitelistApproverSet(_user, _status);
	}

	function sendTokenToNewContract(address _token, address _newContract) external onlyOwner whenPaused {
		require(_newContract != address(0), "Invalid-address");
		uint256 amount;
		if (_token == address(0)) {
			amount = address(this).balance;
			payable(_newContract).sendValue(amount);
		} else {
			amount = IERC20Upgradeable(_token).balanceOf(address(this));
			IERC20Upgradeable(_token).safeTransfer(_newContract, amount);
		}

		emit FundsWithdrawed(_token, amount);
	}

	function setAddressesStorage(address _xanaliaAddressesStorage) external onlyOwner {
		xanaliaAddressesStorage = IXanaliaAddressesStorage(_xanaliaAddressesStorage);
		xanaliaAddressesStorageAddress = _xanaliaAddressesStorage;
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes memory
	) public pure returns (bytes4) {
		return this.onERC721Received.selector;
	}

	function _getCreator(address _collectionAddress, uint256 _tokenId) internal view returns (address) {
		try IXanaliaNFT(_collectionAddress).getCreator(_tokenId) returns (address _creator) {
			return _creator;
		} catch {}
		return address(0);
	}

	function _getRoyaltyFee(address _collectionAddress, uint256 _tokenId) internal view returns (uint256) {
		try IXanaliaNFT(_collectionAddress).getRoyaltyFee(_tokenId) returns (uint256 _royaltyFee) {
			return _royaltyFee;
		} catch {}
		return 0;
	}

	function _paid(
		address _token,
		address _to,
		uint256 _amount
	) internal {
		if (_token == address(0)) {
			payable(_to).sendValue(_amount);
		} else {
			IERC20Upgradeable(_token).safeTransfer(_to, _amount);
		}
	}

	/**
	 * @dev Matching order mechanism for buy NFT and accept bid
	 * @param _buyer is address of buyer
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @param _orderOwner address of user who created auction or order
	 * @param _collectionAddress is address of collection that store NFT
	 * @param _tokenId is id of NFT
	 * @param _price is amount token to buy item
	 */

	function _match(
		address _buyer,
		address _paymentToken,
		address _orderOwner,
		address _collectionAddress,
		uint256 _tokenId,
		uint256 _price
	) internal returns (bool) {
		address payable creator = payable(_getCreator(_collectionAddress, _tokenId));

		uint256 royaltyFee = _getRoyaltyFee(_collectionAddress, _tokenId);

		uint256 _totalEarnings = _price;

		if (royaltyFee > 0 || platformFee > 0) {
			_totalEarnings = (_price * (BASE_DENOMINATOR - royaltyFee - platformFee)) / BASE_DENOMINATOR;
		}

		if (creator != address(0) && royaltyFee > 0) {
			_paid(_paymentToken, creator, (_price * royaltyFee) / BASE_DENOMINATOR);
		}

		if (platformFee > 0) {
			_paid(_paymentToken, xanaliaAddressesStorage.xanaliaTreasury(), (_price * platformFee) / BASE_DENOMINATOR);
		}

		_paid(_paymentToken, _orderOwner, _totalEarnings);

		_transferERC721(_collectionAddress, _tokenId, _buyer);

		return true;
	}

	function _transferERC721(
		address _collectionAddress,
		uint256 _tokenId,
		address _recipient
	) internal {
		IERC721Upgradeable(_collectionAddress).safeTransferFrom(address(this), _recipient, _tokenId);
	}

	function _transferAfterAcceptOffer(uint256 _offerId) internal {
		IOfferDex offerDex = IOfferDex(xanaliaAddressesStorage.offerDex());
		address buyer;
		address paymentToken;
		address collectionAddress;
		uint256 tokenId;
		uint256 totalPaymentAmount;

		(buyer, paymentToken, collectionAddress, tokenId, totalPaymentAmount) = offerDex.acceptOffer(_offerId);

		bool sent = _match(buyer, paymentToken, msg.sender, collectionAddress, tokenId, totalPaymentAmount);
		require(sent, "FAILED_NFT_TRANSFER");
	}
}

contract XanaliaDex is Manager, ReentrancyGuardUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using AddressUpgradeable for address payable;

	function initialize(uint256 _platformFee, address _xanaliaAddressesStorage) public override initializer {
		Manager.initialize(_platformFee, _xanaliaAddressesStorage);
	}

	/***
	@notice this function is for user to create collections.
	@param name_ name of collection
	@param symbol_ symbol of collection
	@param _private is this collection belong to user or public for everyone
	*/
	function createXanaliaCollection(
		string memory name_,
		string memory symbol_,
		bool _private
	) external onlyNotProcessing {
		uint256 collectionCount_ = collectionCount;
		collectionCount += 1;
		address collectionAddress = ICollectionDeployer(xanaliaAddressesStorage.collectionDeployer()).deploy(
			name_,
			symbol_,
			msg.sender,
			xanaliaAddressesStorageAddress
		);
		collections[msg.sender].push(collectionAddress);
		collectionAddresses[collectionCount_] = collectionAddress;
		isUserCollection[collectionAddress] = _private;
		emit CollectionCreated(msg.sender, collectionAddress, name_, symbol_);
	}

	/***
	@notice this function is for user to mint NFT in a collection.
	@param _collectionAddress address of collection that store NFT
	@param _tokenURI URI of NFT
	@param _royaltyFee royalty fee to pay to author when sell NFT
	*/
	function mint(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee
	) external onlyNotProcessing {
		IXanaliaNFT xanaliaNFT = IXanaliaNFT(_collectionAddress);
		if (isUserCollection[_collectionAddress]) {
			require(xanaliaNFT.getContractAuthor() == msg.sender, "Not-author-of-collection");
		}

		uint256 newTokenId = xanaliaNFT.create(_tokenURI, _royaltyFee, msg.sender);

		emit CollectibleCreated(msg.sender, newTokenId);
	}

	/***
	@notice this function is for user to mint NFT and put it on sale.
	@param _collectionAddress address of collection that store NFT
	@param _tokenURI URI of NFT
	@param _royaltyFee royalty fee to pay to author when sell NFT
	@param _paymentToken token address that is used for transaction
	@param _price price when put on sale of NFT
	*/
	function mintAndPutOnSale(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _paymentToken,
		uint256 _price
	) external onlyNotProcessing {
		require(paymentMethod[_paymentToken], "Payment-method-does-not-support");
		IXanaliaNFT xanaliaNFT = IXanaliaNFT(_collectionAddress);
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());
		if (isUserCollection[_collectionAddress]) {
			require(xanaliaNFT.getContractAuthor() == msg.sender, "Not-author-of-collection");
		}
		uint256 newTokenId = xanaliaNFT.create(_tokenURI, _royaltyFee, msg.sender);

		emit CollectibleCreated(msg.sender, newTokenId);

		if (!xanaliaNFT.isApprovedForAll(msg.sender, address(this))) {
			xanaliaNFT.setApprovalForAll(msg.sender, address(this), true);
		}

		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), newTokenId);

		uint256 orderId = marketDex.createOrder(_collectionAddress, _paymentToken, msg.sender, newTokenId, _price);

		emit OrderCreated(orderId, _collectionAddress, newTokenId, _price);
	}

	/***
	@notice this function is for user to mint NFT and put it on auction.
	@param _collectionAddress address of collection that store NFT
	@param _tokenURI URI of NFT
	@param _royaltyFee royalty fee to pay to author when sell NFT
	@param _paymentToken token address that is used for transaction
	@param _startPrice minimum bid for the first bid
	@param _startTime time to start an auction
	@param _endTime time to end an auction
	*/
	function mintAndPutOnAuction(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _paymentToken,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external onlyNotProcessing {
		IXanaliaNFT xanaliaNFT = IXanaliaNFT(_collectionAddress);
		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());
		if (isUserCollection[_collectionAddress]) {
			require(xanaliaNFT.getContractAuthor() == msg.sender, "Not-author-of-collection");
		}
		require(paymentMethod[_paymentToken], "Payment-not-support");
		require(_startTime < _endTime, "Time-invalid");
		require(_paymentToken != address(0), "Auction-only-accept-ERC20-token");
		require(block.timestamp < _endTime, "End-time-must-be-greater-than-current-time");

		uint256 newTokenId = xanaliaNFT.create(_tokenURI, _royaltyFee, msg.sender);

		emit CollectibleCreated(msg.sender, newTokenId);

		if (!xanaliaNFT.isApprovedForAll(msg.sender, address(this))) {
			xanaliaNFT.setApprovalForAll(msg.sender, address(this), true);
		}
		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), newTokenId);

		uint256 auctionId = auctionDex.createAuction(
			_collectionAddress,
			_paymentToken,
			msg.sender,
			newTokenId,
			_startPrice,
			_startTime,
			_endTime
		);

		emit AuctionCreated(auctionId, _collectionAddress, newTokenId);
	}

	/**
	 * @dev Allow user create order on market
	 * @param _collectionAddress address of collection that store NFT
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @param _tokenId is id of NFTs
	 * @param _price is price per item in payment method (example 50 USDT)
	 */
	function createOrder(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _price
	) external {
		require(paymentMethod[_paymentToken], "Payment-method-does-not-support");
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());

		require(IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) == msg.sender, "Not-item-owner");

		if (!IERC721Upgradeable(_collectionAddress).isApprovedForAll(msg.sender, address(this))) {
			IXanaliaNFT(_collectionAddress).setApprovalForAll(msg.sender, address(this), true);
		}
		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

		uint256 orderId = marketDex.createOrder(_collectionAddress, _paymentToken, msg.sender, _tokenId, _price);

		emit OrderCreated(orderId, _collectionAddress, _tokenId, _price);
	}

	/**
	 * @dev Allow user to buy an NFT that are listed on sale
	 * @param _orderId is id of order
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 */
	function buy(uint256 _orderId, address _paymentToken) external payable whenNotPaused nonReentrant {
		require(paymentMethod[_paymentToken], "Payment-method-does-not-support");
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());

		uint256 totalPaymentAmount;
		address collectionAddress;
		uint256 tokenId;
		address orderOwner;

		(totalPaymentAmount, collectionAddress, tokenId, orderOwner) = marketDex.buy(_orderId, _paymentToken);

		if (_paymentToken == address(0)) {
			require(msg.value >= totalPaymentAmount, "Payment-value-invalid");
		} else {
			IERC20Upgradeable(_paymentToken).safeTransferFrom(msg.sender, address(this), totalPaymentAmount);
		}
		bool sent = _match(msg.sender, _paymentToken, orderOwner, collectionAddress, tokenId, totalPaymentAmount);
		require(sent, "FAILED_NFT_TRANSFER");
		emit Buy(_orderId, _paymentToken, totalPaymentAmount);
	}

	/**
	 * @dev Allow user to edit previous order
	 * @param _orderId is id of order that need edited
	 * @param _price is price per item in payment method (example 50 USDT)
	 */
	function editOrder(uint256 _orderId, uint256 _price) external whenNotPaused {
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());

		uint256 orderId;
		uint256 oldOrderId;

		(orderId, oldOrderId) = marketDex.editOrder(msg.sender, _orderId, _price);

		emit OrderEdited(orderId, oldOrderId, _price);
	}

	/**
	 * @dev Owner can cancel an order
	 * @param _orderId is id of sale order
	 */
	function cancelOrder(uint256 _orderId) external whenNotPaused {
		address collectionAddress;
		address orderOwner;
		uint256 tokenId;

		(collectionAddress, orderOwner, tokenId) = IMarketDex(xanaliaAddressesStorage.marketDex()).cancelOrder(
			_orderId,
			msg.sender
		);

		IERC721Upgradeable(collectionAddress).safeTransferFrom(address(this), orderOwner, tokenId);

		emit OrderCancelled(_orderId);
	}

	/**
	 * @dev Allow user create auction on market
	 * @param _collectionAddress address of collection that store NFT
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @param _tokenId is id of NFTs
	 * @param _startTime time to start an auction
	 * @param _endTime time to end an auction
	 */
	function createAuction(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external {
		require(paymentMethod[_paymentToken], "Payment-not-support");
		require(_startTime < _endTime, "Time-invalid");
		require(_paymentToken != address(0), "Auction-only-accept-ERC20-token");
		require(block.timestamp < _endTime, "End-time-must-be-greater-than-current-time");

		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());

		require(IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) == msg.sender, "Not-item-owner");

		if (!IERC721Upgradeable(_collectionAddress).isApprovedForAll(msg.sender, address(this))) {
			IXanaliaNFT(_collectionAddress).setApprovalForAll(msg.sender, address(this), true);
		}
		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

		uint256 auctionId = auctionDex.createAuction(
			_collectionAddress,
			_paymentToken,
			msg.sender,
			_tokenId,
			_startPrice,
			_startTime,
			_endTime
		);

		emit AuctionCreated(auctionId, _collectionAddress, _tokenId);
	}

	/**
	@notice User create a bid for an auction item
	@param _collectionAddress address of collection that store NFT
	@param _paymentToken is payment method (USDT, ETH, ...)
	@param _tokenId is id of NFTs
	@param _auctionId id of an auction
	@param _price bid price
	@param _expireTime end time of this bid
	*/
	function bidAuction(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _auctionId,
		uint256 _price,
		uint256 _expireTime
	) external whenNotPaused {
		require(block.timestamp < _expireTime, "Invalid-expire-time");

		require(_paymentToken != address(0), "Bid-only-accept-ERC20-token");

		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());

		uint256 bidAuctionId = auctionDex.bidAuction(
			_collectionAddress,
			_paymentToken,
			msg.sender,
			_tokenId,
			_auctionId,
			_price,
			_expireTime
		);

		IERC20Upgradeable(_paymentToken).safeTransferFrom(msg.sender, address(this), _price);

		emit BidAuctionCreated(bidAuctionId, _collectionAddress, _tokenId, _price, _paymentToken);
	}

	/**
	@notice Owner of an auction can cancel an auction
	@param _auctionId id of an auction
	*/
	function cancelAuction(uint256 _auctionId) external whenNotPaused {
		uint256 auctionId = IAuctionDex(xanaliaAddressesStorage.auctionDex()).cancelAuction(
			_auctionId,
			msg.sender,
			false
		);

		emit AuctionCanceled(auctionId);
	}

	/**
	@notice Owner of an auction can cancel a previous bid
	@param _bidAuctionId id of a bid
	*/
	function cancelBidAuction(uint256 _bidAuctionId) external whenNotPaused {
		uint256 bidAuctionId;
		uint256 bidPrice;
		address paymentToken;

		(bidAuctionId, bidPrice, paymentToken) = IAuctionDex(xanaliaAddressesStorage.auctionDex()).cancelBidAuction(
			_bidAuctionId,
			msg.sender
		);

		require(paymentToken != address(0), "Invalid-auction");

		IERC20Upgradeable(paymentToken).safeTransfer(msg.sender, bidPrice);

		emit BidAuctionCanceled(bidAuctionId);
	}

	/**
	@notice Owner of an auction can reclaim an item when it's ended or cancelled
	@param _auctionId id of an auction
	*/
	function reclaimAuction(uint256 _auctionId) external whenNotPaused {
		address collectionAddress;
		uint256 tokenId;

		(collectionAddress, tokenId) = IAuctionDex(xanaliaAddressesStorage.auctionDex()).reclaimAuction(
			_auctionId,
			msg.sender
		);

		_transferERC721(collectionAddress, tokenId, msg.sender);

		emit AuctionReclaimed(_auctionId);
	}

	/**
	@notice Owner of an auction can accept a bid that has been placed and available
	@param _bidAuctionId id of a bid that owner want to accept
	*/
	function acceptBidAuction(uint256 _bidAuctionId) external whenNotPaused {
		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());

		uint256 totalPaymentAmount;
		address collectionAddress;
		address paymentToken;
		uint256 tokenId;
		address auctionOwner;
		address bidder;

		(totalPaymentAmount, collectionAddress, paymentToken, tokenId, auctionOwner, bidder) = auctionDex
			.acceptBidAuction(_bidAuctionId, msg.sender);

		bool sent = _match(bidder, paymentToken, auctionOwner, collectionAddress, tokenId, totalPaymentAmount);
		require(sent, "FAILED_NFT_TRANSFER");

		emit BidAuctionClaimed(_bidAuctionId);
	}

	/**
	 * @dev Allow user to make an offer for an NFT that are list on xanalia site
	 * @param _collectionAddress address of collection that store NFT
	 * @param _paymentToken is payment method (USDT, ETH, ...)
	 * @param _tokenId is id of NFTs
	 * @param _price the price that buyer want to offer
	 * @param _expireTime time for an offer to be valid
	 */
	function makeOffer(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _price,
		uint256 _expireTime
	) external payable nonReentrant whenNotPaused {
		IOfferDex offerDex = IOfferDex(xanaliaAddressesStorage.offerDex());
		require(paymentMethod[_paymentToken], "Payment-method-does-not-support");
		require(block.timestamp < _expireTime, "Invalid-expire-time");
		require(_paymentToken != address(0), "Can-only-make-offer-with-ERC-20");

		require(IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) != msg.sender, "Owner-can-not-make-an-offer");

		uint256 offerId = offerDex.makeOffer(
			_collectionAddress,
			_paymentToken,
			msg.sender,
			_tokenId,
			_price,
			_expireTime
		);

		IERC20Upgradeable(_paymentToken).safeTransferFrom(msg.sender, address(this), _price);

		emit OfferCreated(offerId, _collectionAddress, _tokenId, _price, _paymentToken);
	}

	/**
	 * @dev Allow owner of item accept an offer
	 * @param _offerId id of an offer
	 */
	function acceptOfferNotOnSale(
		uint256 _offerId,
		address _collectionAddress,
		uint256 _tokenId
	) external whenNotPaused {
		require(IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) == msg.sender, "Not-item-owner");

		IXanaliaNFT xanaliaNFT = IXanaliaNFT(_collectionAddress);

		if (!xanaliaNFT.isApprovedForAll(msg.sender, address(this))) {
			xanaliaNFT.setApprovalForAll(msg.sender, address(this), true);
		}

		IERC721Upgradeable(_collectionAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

		_transferAfterAcceptOffer(_offerId);

		emit AcceptOffer(_offerId);
	}

	function acceptOfferFixedPrice(uint256 _offerId, uint256 _orderId) external whenNotPaused {
		IMarketDex marketDex = IMarketDex(xanaliaAddressesStorage.marketDex());
		marketDex.cancelOrder(_orderId, msg.sender);

		_transferAfterAcceptOffer(_offerId);

		emit AcceptOffer(_offerId);
	}

	function acceptOfferAuction(uint256 _offerId, uint256 _auctionId) external whenNotPaused {
		IAuctionDex auctionDex = IAuctionDex(xanaliaAddressesStorage.auctionDex());

		auctionDex.cancelAuction(_auctionId, msg.sender, true);

		_transferAfterAcceptOffer(_offerId);

		emit AcceptOffer(_offerId);
	}

	/**
	@notice User cancel an offer
	@param _offerId id of an offer
	*/
	function cancelOffer(uint256 _offerId) external whenNotPaused nonReentrant {
		IOfferDex offerDex = IOfferDex(xanaliaAddressesStorage.offerDex());

		address paymentToken;
		uint256 totalPaymentAmount;

		(paymentToken, totalPaymentAmount) = offerDex.cancelOffer(_offerId, msg.sender);
		require(paymentToken != address(0), "Invalid-offer");

		IERC20Upgradeable(paymentToken).safeTransfer(msg.sender, totalPaymentAmount);

		emit OfferCancelled(_offerId);
	}

	/**
	@notice this function is to set list of whitelisted user
	@param _user array of address of the user whose address get whitelisted
	@param _status status of each address in array
	*/
	function setWhitelistAddress(address[] calldata _user, bool[] calldata _status) external onlyApprover {
		uint256 length = _user.length;
		require(length == _status.length, "Invalid-data");
		for (uint256 i = 0; i < length; i++) {
			isUserWhitelisted[_user[i]] = _status[i];
		}
		emit WhitelistAddressSet(msg.sender, length);
	}

	/**
	@notice this function is to get list of collections created by user
	@param owner_ address of the user whose collections to be fetched
	@return array of addresses of user's collections
	*/
	function getCollections(address owner_) public view returns (address[] memory) {
		return collections[owner_];
	}

	// Test function, remove on production
	function transferCollectionOwnership(address _owner, address _collection) external onlyOwner {
		IXanaliaNFT(_collection).transferOwnership(_owner);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IXanaliaDex {
	/**
	 * User calls to create collection
	 */

	function createXanaliaCollection(
		string memory name_,
		string memory symbol_,
		bool _private
	) external;

	// function collectionCount() external view returns (uint256);

	// function collections(address _userAddress) external view returns (address[] calldata);

	// function collectionAddresses(uint256 _id) external view returns (address);

	// function xanaliaAddressesStorageAddress() external view returns (address);

	// function platformFee() external returns (uint256);

	// function paymentMethod(address _token) external returns (bool);

	// function isUserCollection(address _token) external returns (bool);

	// function isUserWhitelisted(address _token) external returns (bool);

	function setApproveForAllERC721(address _collectionAddress, address _spender) external;

	function mint(
		address _token,
		string calldata _tokenURI,
		uint256 _royaltyFee
	) external;

	function mintAndPutOnSale(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _paymentToken,
		uint256 _price
	) external;

	function mintAndPutOnAuction(
		address _collectionAddress,
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _paymentToken,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external;

	function setPlatformFee(uint256 _platformFee) external;

	function setPaymentMethod(address _token, bool _status) external returns (bool);

	function createOrder(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _price
	) external;

	function buy(uint256 _orderId, address _paymentToken) external payable;

	function editOrder(
		uint256 _orderId,
		uint256 _price
	) external;

	function cancelOrder(uint256 _orderId) external;

	function createAuction(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external;

	function bidAuction(
		address _collectionAddress,
		address _paymentToken,
		uint256 _tokenId,
		uint256 _auctionId,
		uint256 _price,
		uint256 _expireTime
	) external;

	function editBidAuction(
		uint256 _bidAuctionId,
		uint256 _price,
		uint256 _expireTime
	) external;

	function cancelAuction(uint256 _auctionId) external;

	function cancelBidAuction(uint256 _bidAuctionId) external;

	function reclaimAuction(uint256 _auctionId) external;

	function acceptBidAuction(uint256 _bidAuctionId) external;

	function setWhitelistAddress(address[] calldata _user, bool[] calldata _status) external;

	function sendTokenToNewContract(address _token, address _newContract) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMarketDex {
	function createOrder(
		address _collectionAddress,
		address _paymentToken,
		address _itemOwner,
		uint256 _tokenId,
		uint256 _price
	) external returns (uint256 _orderId);

	function buy(uint256 _orderId, address _paymentToken) external returns (uint256, address, uint256, address);

	function editOrder(
		address _orderOwner,
		uint256 _orderId,
		uint256 _price
	) external returns (uint256, uint256);

	function cancelOrder(uint256 _orderId, address _orderOwner) external returns (address, address, uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAuctionDex {
	function createAuction(
		address _collectionAddress,
		address _paymentToken,
		address _itemOwner,
		uint256 _tokenId,
		uint256 _startPrice,
		uint256 _startTime,
		uint256 _endTime
	) external payable returns (uint256 _auctionId);

	function bidAuction(
		address _collectionAddress,
		address _paymentToken,
		address _bidOwner,
		uint256 _tokenId,
		uint256 _auctionId,
		uint256 _price,
		uint256 _expireTime
	) external returns (uint256 _bidAuctionId);

	function cancelAuction(uint256 _auctionId, address _auctionOwner, bool _isAcceptOffer) external returns (uint256);

	function cancelBidAuction(uint256 _bidAuctionId, address _auctionOwner) external returns (uint256, uint256, address);

	function reclaimAuction(uint256 _auctionId, address _auctionOwner) external returns (address, uint256);

	function acceptBidAuction(uint256 _bidAuctionId, address _auctionOwner) external returns (uint256, address, address, uint256, address, address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IOfferDex {
	function makeOffer(
		address _collectionAddress,
		address _paymentToken,
		address _offerOwner,
		uint256 _tokenId,
		uint256 _price,
		uint256 _expireTime
	) external returns (uint256 _offerId);

	function acceptOffer(uint256 _offerId)
		external
		returns (
			address,
			address,
			address,
			uint256,
			uint256
		);

	function cancelOffer(uint256 _offerId, address _offerOwner) external returns (address, uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IXanaliaNFT {
	function setXanaliaUriAddress(address _xanaliaUriAddress) external;

	function getCreator(uint256 _id) external view returns (address);

	function getRoyaltyFee(uint256 _id) external view returns (uint256);

	function create(
		string calldata _tokenURI,
		uint256 _royaltyFee,
		address _owner
	) external returns (uint256);

	function tokenURI(uint256 tokenId_) external view returns (string memory);

	function getContractAuthor() external view returns (address);

	function isApprovedForAll(address owner, address operator) external view returns (bool);

	function setApprovalForAll(
		address owner,
		address operator,
		bool approved
	) external;

	function transferOwnership(address owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IXanaliaAddressesStorage {
	event XNftURIAddressChanged(address xNftURI);
	event AuctionDexChanged(address auctionDex);
	event MarketDexChanged(address marketDex);
	event OfferDexChanged(address offerDex);
	event XanaliaDexChanged(address xanaliaDex);
	event TreasuryChanged(address xanaliaTreasury);
	event DeployerChanged(address collectionDeployer);

	function xNftURI() external view returns (address);

	function auctionDex() external view returns (address);

	function marketDex() external view returns (address);

	function offerDex() external view returns (address);

	function xanaliaDex() external view returns (address);

	function xanaliaTreasury() external view returns (address);

	function collectionDeployer() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ICollectionDeployer {
	function deploy(
		string memory name_,
		string memory symbol_,
		address _creator,
		address _addressesStorage
	) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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
interface IERC165Upgradeable {
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