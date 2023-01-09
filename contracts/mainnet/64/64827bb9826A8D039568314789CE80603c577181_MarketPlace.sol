//SPDX-License-Identifier: Unlicensed
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '../interface/IMarketPlace.sol';
import '../interface/INFT.sol';
import './NFTMarketInfo.sol';
import '../libraries/TokenStructLib.sol';

pragma solidity 0.8.10;

contract MarketPlace is ReentrancyGuard, Ownable, IMarketPlace, IERC721Receiver, Multicall {
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.UintSet;

	using TokenStructLib for TokenStructLib.TokenInfo;

	uint256 public blockNumber;

	uint256 public MAX_FEE = 1500;

	INFT public nft;

	NFTMarketInfo public tokenInfo;

	///@notice checks whether the given address is added as Gallery or not
	mapping(address => bool) public isGallery;

	///@notice checks whether the given address is added as admin or not
	mapping(address => bool) public isAdmin;

	EnumerableSet.UintSet private tokenIdOnSell;

	constructor(address _nft, address _tokenInfo) checkAddress(_nft) checkAddress(_tokenInfo) {
		nft = INFT(_nft);
		tokenInfo = NFTMarketInfo(_tokenInfo);
		isAdmin[msg.sender] = true;
		blockNumber = block.number;
	}

	///@notice to check whether the sender address is owner of given token id or not or the owner of the gallery
	///@dev modifier to check whether the sender address is owner of given token id or not or the owner of the gallery
	modifier onlyGalleryOrTokenOwner(uint256 _tokenId) {
		address owner = address(nft.ownerOf(_tokenId));
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);
		if (!isGallery[msg.sender] && owner != msg.sender && tokenmarketInfo.nftOwner != msg.sender) {
			revert('access-denied');
		}
		_;
	}

	///@notice to check whether the sender address is admin or not
	///@dev modifier to check whether the sender address is admin or not
	modifier onlyAdmin() {
		require(isAdmin[msg.sender], 'admin-access-denied');
		_;
	}
	///@notice to check whether the sender address is admin or owner or not
	///@dev modifier to check whether the sender address is admin ,owner or  not
	modifier onlyAdminOrOwner() {
		require(isAdmin[msg.sender] || owner() == msg.sender, 'Should be owner/admin');
		_;
	}

	///@notice to check whether the sender address is token owner or not
	///@dev modifier to check whether the sender address token owner or not
	modifier onlyTokenOwner(uint256 _tokenId) {
		require(nft.ownerOf(_tokenId) == msg.sender, 'Not-owner');
		_;
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	///@notice  Receive Ether
	receive() external payable {}

	///@notice buy the given token id
	///@param _tokenId token id to be bought by the buyer
	///@param _buyer address of the buyer
	///@dev payable function
	function buy(uint256 _tokenId, address _buyer) public payable override nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;

		tokenmarketInfo = gettokeninfo(_tokenId);
		require(nft.checkNft(_tokenId), 'invalid TokenId');
		require(tokenmarketInfo.onSell, 'Not for sale');
		require(_buyer != tokenmarketInfo.nftOwner, 'owner cannot buy');

		uint256 sellingPrice = tokenmarketInfo.minPrice;
		if (tokenmarketInfo.USD) {
			sellingPrice = tokenInfo.view_nft_price_native(tokenmarketInfo.minPrice);
		}
		checkAmount(sellingPrice, _buyer);

		uint256 _galleryownerfee;
		uint256 _artistfee;
		uint256 _platformfee;
		uint256 _thirdpartyfee;
		uint256 ownerfee;
		address artist;

		(_galleryownerfee, _artistfee, _platformfee, _thirdpartyfee, ownerfee, artist) = tokenInfo.calculateCommissions(
			_tokenId
		);

		transferfees(artist, _artistfee);
		transferfees(tokenInfo.platformAddress(), _platformfee);
		transferfees(tokenmarketInfo.galleryOwner, _galleryownerfee);
		if (_thirdpartyfee > 0) transferfees(tokenmarketInfo.thirdParty, _thirdpartyfee);
		transferfees(tokenmarketInfo.nftOwner, ownerfee);

		nft.safeTransferFrom(address(this), _buyer, _tokenId);
		tokenInfo.updateForBuy(_tokenId, _buyer);
		tokenIdOnSell.remove(_tokenId);
		emit Nftbought(_tokenId, tokenmarketInfo.nftOwner, _buyer, sellingPrice);
	}

	///@notice check amount value send
	///@param sellingPrice selling price of the token
	///@param buyer address of the buyer
	///@dev checks the value sent with selling price and return excessive amount to the buyer address
	function checkAmount(uint256 sellingPrice, address buyer) internal {
		require(msg.value >= sellingPrice, 'Insufficient amount');
		uint256 amountToRefund = msg.value - sellingPrice;
		transferfees(payable(buyer), amountToRefund);
	}

	///@notice transfer the fees/commission rates to different parties
	///@dev internal utility function to transfer fees
	function transferfees(address receiver, uint256 _amount) internal {
		(bool txSuccess, ) = receiver.call{ value: _amount }('');
		require(txSuccess, 'Failed to pay commission rates');
	}

	///@notice set the nft for sell
	///@param _tokenId token id to be listed for sale
	///@param _minprice selling price of the token id
	///@param _artistfee commission rate to be transferred to artist while selling nft
	///@param _galleryownerfee commission rate to be transferred to gallery owner while selling nft
	///@param _thirdpartyfee commission rate to be transferred to thirdparty while selling nft
	///@param _expirytime time limit to pay third party commission fee
	///@param _thirdParty address of the third party asssociated with nft
	///@param _gallery address of the gallery associated  with  nft
	///@param USD boolean value to indicate pricing is in dollar or not
	///@dev function to list nft for sell and can be called only by gallery or tokenOwner
	function sell(
		uint256 _tokenId,
		uint256 _minprice,
		uint256 _artistfee,
		uint256 _galleryownerfee,
		uint256 _thirdpartyfee,
		uint256 _expirytime,
		address _thirdParty,
		address _gallery,
		bool USD
	) public override onlyGalleryOrTokenOwner(_tokenId) nonReentrant {
		require(!gettokeninfo(_tokenId).onSell, 'Already on Sell');
		require(nft.checkNft(_tokenId), 'Invalid tokenId');
		tokenIdOnSell.add(_tokenId);
		address tokenOwner = nft.ownerOf(_tokenId);
		TokenStructLib.TokenInfo memory Token = TokenStructLib.TokenInfo(
			_tokenId,
			0,
			_minprice,
			_thirdpartyfee,
			_galleryownerfee,
			_artistfee,
			_expirytime,
			payable(msg.sender),
			payable(_thirdParty),
			tokenOwner,
			true,
			USD,
			false,
			payable(_gallery)
		);
		tokenInfo.addTokenInfo(Token);

		transferNft(_tokenId);

		emit Nftonsell(_tokenId, _minprice);
	}

	function transferNft(uint256 _tokenId) internal {
		address owner = nft.ownerOf(_tokenId);
		nft.safeTransferFrom(owner, address(this), _tokenId);
	}

	///@notice set the nft for secondary sell
	///@param _tokenId token id to be listed for sale
	///@param _minprice selling price of the token id
	/// @param USD boolean value to indicate pricing is in dollar or not
	///@dev nft is set for sell after first sell
	function SecondarySell(
		uint256 _tokenId,
		uint256 _minprice,
		bool USD
	) public onlyTokenOwner(_tokenId) nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);

		require(!tokenmarketInfo.onSell, 'Already on Sell');
		require(nft.checkNft(_tokenId), 'Invalid tokenId');

		tokenIdOnSell.add(_tokenId);
		tokenInfo.updateForSell(_tokenId, _minprice, USD);
		transferNft(_tokenId);
		emit Nftonsell(_tokenId, _minprice);
	}

	///@notice cancel the nft listed for sell
	///@param _tokenId id of the token to be removed from list
	///@dev only gallery  or token owner can cancel the sell of nft
	function cancelSell(uint256 _tokenId) public override onlyGalleryOrTokenOwner(_tokenId) nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);
		require(tokenmarketInfo.onSell, 'Not on Sell');
		require(nft.checkNft(_tokenId), 'Invalid TokenId');
		tokenIdOnSell.remove(_tokenId);
		tokenInfo.updateForCancelSell(_tokenId);
		nft.safeTransferFrom(address(this), msg.sender, _tokenId);
		emit Cancelnftsell(_tokenId);
	}

	///@notice get token info
	///@param _tokenId token id
	///@dev returns the tuple providing information about token
	function gettokeninfo(uint256 _tokenId) public view returns (TokenStructLib.TokenInfo memory tokenMarketInfo) {
		tokenMarketInfo = tokenInfo.getTokenData(_tokenId);
		return tokenMarketInfo;
	}

	///@notice list  all the token listed for sale
	function listtokensforsale() public view override returns (uint256[] memory) {
		return tokenIdOnSell.values();
	}

	///@notice change the  selling price of the listed nft
	///@param _tokenId id of the token
	///@param _minprice new selling price
	///@dev only gallery  or token owner can change  the artist commission rate for given  nft
	function resale(uint256 _tokenId, uint256 _minprice) public override onlyGalleryOrTokenOwner(_tokenId) nonReentrant {
		TokenStructLib.TokenInfo memory tokenmarketInfo;
		tokenmarketInfo = gettokeninfo(_tokenId);
		require(tokenmarketInfo.onSell, 'Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		tokenInfo.updateForSell(_tokenId, _minprice, tokenmarketInfo.USD);
	}

	///@notice change the  artist commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _artistFee new artist fee commission rate
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function changeArtistFee(uint256 _tokenId, uint256 _artistFee) public override onlyGalleryOrTokenOwner(_tokenId) {
		require(gettokeninfo(_tokenId).onSell, 'Token Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		tokenInfo.updateArtistFee(_tokenId, _artistFee);
	}

	///@notice change the  gallery commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _galleryFee new gallery owner fee commission rate
	///@dev only gallery owner or token owner can change  the gallery owner commission rate for given  nft
	function changeGalleryFee(uint256 _tokenId, uint256 _galleryFee) public override onlyGalleryOrTokenOwner(_tokenId) {
		require(gettokeninfo(_tokenId).onSell, 'Token Not on Sell');
		require(nft.checkNft(_tokenId), 'TokenId doesnot exists');
		tokenInfo.updateGalleryFee(_tokenId, _galleryFee);
	}

	///@notice add the gallery address
	///@param _gallery address of the gallery to be added
	///@param _status status to set
	///@dev only Admin can the gallery
	function addGallery(address _gallery, bool _status) public override onlyAdmin {
		require(_gallery != address(0x0), '0x00 galleryaddress');
		isGallery[_gallery] = _status;
	}

	///@notice add new admins
	///@param _admin address to add as admin
	///@dev onlyOwner can add new admin
	function addAdmin(address _admin) public override onlyOwner {
		isAdmin[_admin] = true;
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}
}

//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

library TokenStructLib {
	using TokenStructLib for TokenInfo;

	struct TokenInfo {
		uint256 tokenId;
		uint256 totalSell;
		uint256 minPrice;
		uint256 thirdPartyFee;
		uint256 galleryOwnerFee;
		uint256 artistFee;
		uint256 thirdPartyFeeExpiryTime;
		address payable gallery;
		address payable thirdParty;
		// address payable artist;
		address nftOwner;
		bool onSell;
		bool USD;
		bool onAuction;
		address payable galleryOwner;
	}
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface INFT {
	function mint(string calldata _tokenURI, address _to) external returns (uint256);

	function burn(uint256 _tokenId) external;

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function ownerOf(uint256 tokenId) external view returns (address);

	function tokenURI(uint256 tokenId) external view returns (string memory);

	function approve(address to, uint256 tokenId) external;

	function setApprovalForAll(address operator, bool approved) external;

	function addManagers(address _manager) external;

	function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address reciever, uint256 _rate);

	function setArtistRoyalty(
		uint256 _tokenId,
		address _receiver,
		uint96 _feeNumerator
	) external;

	function checkNft(uint256 _tokenId) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IMarketPlace {
	event Nftonsell(uint256 indexed _tokenid, uint256 indexed _price);
	event Nftbought(uint256 indexed _tokenid, address indexed _seller, address indexed _buyer, uint256 _price);
	event Cancelnftsell(uint256 indexed _tokenid);

	/*@notice buy the token listed for sell 
     @param _tokenId id of token  */
	function buy(uint256 _tokenId, address _buyer) external payable;

	function addAdmin(address _admin) external;

	function addGallery(address _gallery, bool _status) external;

	/* @notice add token for sale
    @param _tokenId id of token
    @param _minprice minimum price to sell token*/
	function sell(
		uint256 _tokenId,
		uint256 _minprice,
		uint256 _artistfee,
		uint256 _galleryownerfee,
		uint256 _thirdpartyfee,
		uint256 _expirytime,
		address thirdParty,
		address _gallery,
		bool USD
	) external;

	///@notice cancel the sell
	///@param _tokenId id of the token to cancel the sell
	function cancelSell(uint256 _tokenId) external;

	///@notice resale the token
	///@param _tokenId id of the token to resale
	///@param _minPrice amount to be updated
	function resale(uint256 _tokenId, uint256 _minPrice) external;

	///@notice change the artist fee commission rate
	function changeArtistFee(uint256 _tokenId, uint256 _artistFee) external;

	///@notice change the gallery owner commssion rate
	function changeGalleryFee(uint256 _tokenId, uint256 _galleryFee) external;

	/* @notice  list tokena added on sale list */
	function listtokensforsale() external view returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

// import './StructDeclaration.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import '../interface/INFT.sol';
import '../libraries/TokenStructLib.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract NFTMarketInfo is ReentrancyGuard, Ownable {
	using SafeMath for uint256;

	uint256 public platformFee;
	address public platformAddress;

	uint256 public DECIMALS;

	uint256 public MAX_FEE = 1500;

	using TokenStructLib for TokenStructLib.TokenInfo;

	mapping(address => bool) public isManager;
	mapping(uint256 => TokenStructLib.TokenInfo) public TokenMarketInfo;
	INFT public nft;

	AggregatorV3Interface public priceFeed;

	constructor(
		address _nft,
		address _platformFeeAddress,
		address _priceFeed,
		uint256 decimals
	) checkAddress(_nft) checkAddress(_platformFeeAddress) checkAddress(_priceFeed) {
		nft = INFT(_nft);
		priceFeed = AggregatorV3Interface(_priceFeed);
		platformFee = 450; // 4.5%
		platformAddress = _platformFeeAddress;
		DECIMALS = decimals;
	}

	modifier onlyManager() {
		require(isManager[msg.sender], 'NFTInfo:access-denied');
		_;
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	modifier onlyManagerOrOwner() {
		require(isManager[msg.sender] || owner() == msg.sender, 'NFTInfo:access-denied');
		_;
	}

	///@notice function to add token info in a struct
	///@param tokeninfo struct of type TokenStructLib.TokenInfo to store nft/token related info
	///@dev stores all the nft related info and can only be called by managers
	function addTokenInfo(TokenStructLib.TokenInfo calldata tokeninfo) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[tokeninfo.tokenId];
		tokenInfo.tokenId = tokeninfo.tokenId;
		tokenInfo.totalSell = tokeninfo.totalSell;
		tokenInfo.minPrice = tokeninfo.minPrice;
		tokenInfo.thirdPartyFee = tokeninfo.thirdPartyFee;
		tokenInfo.galleryOwnerFee = tokeninfo.galleryOwnerFee;
		tokenInfo.artistFee = tokeninfo.artistFee;
		tokenInfo.thirdPartyFeeExpiryTime = tokeninfo.thirdPartyFeeExpiryTime;
		tokenInfo.gallery = tokeninfo.gallery;
		tokenInfo.thirdParty = tokeninfo.thirdParty;
		tokenInfo.nftOwner = tokeninfo.nftOwner;
		tokenInfo.onSell = tokeninfo.onSell;
		tokenInfo.USD = tokeninfo.USD;
		tokenInfo.galleryOwner = tokeninfo.galleryOwner;
		tokenInfo.onAuction = tokeninfo.onAuction;
	}

	///@notice function to update token info for sell
	///@param _tokenId id of the token to update info
	///@param _minPrice minimum selling price
	///@dev is called from marketplace contract (only managers can call)
	function updateForSell(
		uint256 _tokenId,
		uint256 _minPrice,
		bool USD
	) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.tokenId = _tokenId;
		tokenInfo.minPrice = _minPrice;
		tokenInfo.USD = USD;
		tokenInfo.onSell = true;
	}

	///@notice function to update token info for buy
	///@param _tokenId id of the token to update info
	///@param _owner new owner of nft
	///@dev is called from marketplace contract (only managers can call)
	function updateForBuy(uint256 _tokenId, address _owner) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.tokenId = _tokenId;
		tokenInfo.minPrice = 0;
		tokenInfo.totalSell += 1;
		tokenInfo.onSell = false;
		tokenInfo.nftOwner = _owner;
	}

	///@notice function to update token info for cancel sell
	///@param _tokenId id of the token to update info
	///@dev is called from marketplace contract (only managers can call)
	function updateForCancelSell(uint256 _tokenId) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.minPrice = 0;
		tokenInfo.onSell = false;
		tokenInfo.USD = false;
	}

	///@notice function to update token info after claiming nft in auction
	///@param _tokenId id of the token to update info
	///@param _owner new owner of the nft
	///@dev is called from auction contract(only managers can call)
	function updateForAuction(uint256 _tokenId, address _owner) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.minPrice = 0;
		tokenInfo.USD = false;
		tokenInfo.onAuction = false;
		tokenInfo.totalSell += 1;
		tokenInfo.nftOwner = _owner;
	}

	///@notice function to update token info for cancel auction
	///@param _tokenId id of the token to update info
	///@dev is called from auction contract(only managers can call)
	function updateForAuctionCancel(uint256 _tokenId) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.minPrice = 0;
		tokenInfo.USD = false;
		tokenInfo.onAuction = false;
	}

	///@notice function to provide token related info
	///@param _tokenId id of the token to get info
	///@dev getter function
	function getTokenData(uint256 _tokenId)
		public
		view
		returns (
			TokenStructLib.TokenInfo memory tokenInfo // uint256 _minPrice,
		)
	{
		return TokenMarketInfo[_tokenId];
	}

	///@notice function to change galleryfee of tokenId
	///@param _tokenId id of the token to update info
	///@param _galleryFee new gallery owner fee
	///@dev is called from marketplace contract (only managers can call)
	function updateGalleryFee(uint256 _tokenId, uint256 _galleryFee) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.galleryOwnerFee = _galleryFee;
	}

	///@notice function to change artistfee of tokenId
	///@param _tokenId id of the token to update info
	///@param _artistFee new artist owner fee
	///@dev is called from marketplace contract (only managers can call)
	function updateArtistFee(uint256 _tokenId, uint256 _artistFee) public onlyManager {
		TokenStructLib.TokenInfo storage tokenInfo = TokenMarketInfo[_tokenId];
		tokenInfo.galleryOwnerFee = _artistFee;
	}

	function addManagers(address _manager) public onlyOwner {
		isManager[_manager] = true;
	}

	///@notice change the aggregator contract address
	///@param _newaggregator new address of the aggregator contract
	///@dev change the address of the aggregator contract used for matic/usd conversion  and can only be called  by owner
	function changeAggregatorAddress(address _newaggregator) public checkAddress(_newaggregator) onlyOwner {
		priceFeed = AggregatorV3Interface(_newaggregator);
	}

	///@notice calculate the fees/commission rates to different parties
	///@param tokenId id of the token
	///@dev internal utility function to calculate commission rate for different parties
	function calculateCommissions(uint256 tokenId)
		public
		view
		returns (
			uint256 _galleryOwnerCommission,
			uint256 artistCommssion,
			uint256 platformCommission,
			uint256 thirdPartyCommission,
			uint256 _remainingAmount,
			address artist
		)
	{
		TokenStructLib.TokenInfo memory tokenmarketInfo = TokenMarketInfo[tokenId];

		uint256 sellingPrice = tokenmarketInfo.minPrice;

		if (tokenmarketInfo.USD) {
			sellingPrice = view_nft_price_native(tokenmarketInfo.minPrice);
		}
		platformCommission = cutPer10000(platformFee, sellingPrice);
		uint256 newSellingPrice = sellingPrice.sub(platformCommission);
		thirdPartyCommission;
		artistCommssion;
		uint256 _rate;
		address receiver;
		artist = receiver;
		(receiver, _rate) = nft.getRoyaltyInfo(uint256(tokenId), newSellingPrice);

		if (tokenmarketInfo.totalSell == 0) {
			artistCommssion = cutPer10000(tokenmarketInfo.artistFee, newSellingPrice);
			_galleryOwnerCommission = cutPer10000(tokenmarketInfo.galleryOwnerFee, newSellingPrice);
			_remainingAmount = newSellingPrice.sub(artistCommssion).sub(_galleryOwnerCommission);
		} else {
			artistCommssion = _rate;
			if (block.timestamp <= tokenmarketInfo.thirdPartyFeeExpiryTime) {
				thirdPartyCommission = cutPer10000(tokenmarketInfo.thirdPartyFee, newSellingPrice);
			} else thirdPartyCommission = 0;

			_remainingAmount = newSellingPrice.sub(_rate).sub(thirdPartyCommission);
		}

		return (
			_galleryOwnerCommission,
			artistCommssion,
			platformCommission,
			thirdPartyCommission,
			_remainingAmount,
			artist
		);
	}

	///@notice change the platform address
	///@param _platform new platform address
	///@dev only owner can change the platform address
	function changePlatformAddress(address _platform) public onlyOwner checkAddress(_platform) {
		platformAddress = _platform;
	}

	///@notice change the platform commission rate
	///@param _amount new amount
	///@dev only owner can change the platform commission rate
	function changePlatformFee(uint256 _amount) public onlyOwner {
		require(_amount < MAX_FEE, 'Exceeded max platformfee');
		platformFee = _amount;
	}

	///@notice provides the latest matic/usd rate
	///@return price latest matictodollar rate
	///@dev uses the chain link data feed's function to get latest rate
	function getLatestPrice() public view returns (int256) {
		(, int256 price, , , ) = priceFeed.latestRoundData();
		return price;
	}

	///@notice calculate the equivalent matic from given dollar price
	///@dev uses chainlink data feed's function to get the lateset matic/usd rate and calculate matic( in wei)
	///@param priceindollar price in terms of dollar
	///@return priceinwei returns the value in terms of wei
	function view_nft_price_native(uint256 priceindollar) public view returns (uint256) {
		uint8 priceFeedDecimals = priceFeed.decimals();
		uint256 precision = 1 * 10**18;
		uint256 price = uint256(getLatestPrice());
		uint256 requiredWei = (priceindollar * 10**priceFeedDecimals * precision) / price;
		requiredWei = requiredWei / 10**DECIMALS;
		return requiredWei;
	}

	///@notice calculate percent amount for given percent and total
	///@dev calculates the cut per 10000 fo the given total
	///@param _cut cut to be caculated per 10000, i.e percentAmount * 100
	///@param _total total amount from which cut is to be calculated
	///@return cutAmount percentage amount calculated
	///@dev internal utility function to calculate percentage
	function cutPer10000(uint256 _cut, uint256 _total) internal pure returns (uint256 cutAmount) {
		if (_cut == 0) return 0;
		cutAmount = _total.mul(_cut).div(10000);
		return cutAmount;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}